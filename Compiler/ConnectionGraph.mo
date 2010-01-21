/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package ConnectionGraph
" file:	 ConnectionGraph.mo
  package:      ConnectionGraph
  description: Constant propagation of expressions

  RCS: $Id$

  This module contains a connection breaking algorithm and  
  related data structures. The input of the algorithm is
  collected to ConnectionGraph record during instantiation.
  The entry point to the algorithm is findResultGraph. 
  
  The algorithm is implemented using a disjoint-set
  data structure that represents the components of
  elements so far connected. Each component has
  an unique canonical element. The data structure is
  implemented by a hash table, that contains an entry
  for each non-canonical element so that a path beginning
  from some element eventually ends to the canonical element
  of the same component.
  
  Roots are represented as connections to dummy root
  element. In this way, all elements will be in the
  same component after the algorithm finishes assuming
  that the model is valid."
      
public import Absyn;
public import DAE;
public import DAEUtil;
public import HashTableCG;
public import Util;

/* A list of edges 
 */
type Edges = list<tuple<DAE.ComponentRef,DAE.ComponentRef>>;
/* A list of edges, each edge associated with two lists of DAE elements
 * (these elements represent equations to be added if the edge
 * is preserved or broken) 
 */
type DaeEdges = list<tuple<DAE.ComponentRef,DAE.ComponentRef,list<DAE.Element>>>;

uniontype ConnectionGraph "Input structure for connection breaking algorithm. It is collected during instantiation phase."
    record GRAPH
      Boolean updateGraph;
      list<DAE.ComponentRef> definiteRoots "Roots defined with Connection.root";
      list<tuple<DAE.ComponentRef,Real>> potentialRoots "Roots defined with Connection.potentialRoot";
      Edges branches "Edges defined with Connection.branch";
      DaeEdges connections "Edges defined with connect statement";
    end GRAPH;
end ConnectionGraph;

/* 
 * Initial connection graph with no edges in it.
 */
public constant ConnectionGraph EMPTY = GRAPH( true, {}, {}, {}, {} );
/* 
 * Initial connection graph with updateGraph set to false.
 */
public constant ConnectionGraph NOUPDATE_EMPTY = GRAPH( false, {}, {}, {}, {} );

protected import Exp;
protected import Debug;
protected import Print;

public
function printEdges
"Prints a list of edges to stdout."
  input Edges inEdges;
algorithm
  _ := matchcontinue(inEdges)
    local
      DAE.ComponentRef c1, c2;
      Edges tail;

    case ({}) then ();            
    case ((c1, c2) :: tail)
      equation
        print("    ");
        print(Exp.printComponentRefStr(c1));
        print(" -- ");
        print(Exp.printComponentRefStr(c2));
        print("\n");
        printEdges(tail);
      then ();
  end matchcontinue;
end printEdges;

function printDaeEdges
"Prints a list of dae edges to stdout."
  input DaeEdges inEdges;
algorithm
  _ := matchcontinue(inEdges)
    local
      DAE.ComponentRef c1, c2;
      DaeEdges tail;

    case ({}) then ();

    case ((c1, c2, _) :: tail)
      equation
        print("    ");
        print(Exp.printComponentRefStr(c1));
        print(" -- ");
        print(Exp.printComponentRefStr(c2));
        print("\n");
        printDaeEdges(tail);
      then ();
  end matchcontinue;
end printDaeEdges;

function printConnectionGraph
  "Prints the content of ConnectionGraph structure."
  input ConnectionGraph inGraph;
algorithm
  _ := matchcontinue(inGraph)
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
  end matchcontinue;
end printConnectionGraph;

function getDefiniteRoots
"Accessor for ConnectionGraph.definititeRoots."
  input ConnectionGraph inGraph;
  output list<DAE.ComponentRef> outResult;
algorithm
  outResult := matchcontinue(inGraph)
    local 
      list<DAE.ComponentRef> result;
    case (GRAPH(_,result,_,_,_)) then result;
  end matchcontinue;
end getDefiniteRoots;

function getPotentialRoots
"Accessor for ConnectionGraph.potentialRoots."
  input ConnectionGraph inGraph;
  output list<tuple<DAE.ComponentRef,Real>> outResult;
algorithm
  outResult := matchcontinue(inGraph)
    local list<tuple<DAE.ComponentRef,Real>> result;
    case (GRAPH(_,_,result,_,_)) then result;
  end matchcontinue;
end getPotentialRoots;

function getBranches
"Accessor for ConnectionGraph.branches."
  input ConnectionGraph inGraph;
  output Edges outResult;
algorithm
  outResult := matchcontinue(inGraph)
    local Edges result;
    case (GRAPH(_,_,_,result,_))
    then result;
  end matchcontinue;
end getBranches;

function getConnections
"Accessor for ConnectionGraph.connections."
  input ConnectionGraph inGraph;
  output DaeEdges outResult;
algorithm
  outResult := matchcontinue(inGraph)
    local DaeEdges result;
    case (GRAPH(_,_,_,_,result)) then result;
  end matchcontinue;
end getConnections;

function addDefiniteRoot 
"Adds a new definite root to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.ComponentRef inRoot;
  output ConnectionGraph outGraph;
algorithm
/*  outGraph := GRAPH(inRoot::getDefiniteRoots(inGraph),
                    getPotentialRoots(inGraph),
                    getBranches(branches),
                    getConnections(inGraph));
*/
  outGraph := matchcontinue(inGraph, inRoot)
    local 
      Boolean updateGraph;
      ConnectionGraph graph;
      DAE.ComponentRef root;
      list<DAE.ComponentRef> definiteRoots;
      list<tuple<DAE.ComponentRef,Real>> potentialRoots;
      Edges branches;
      DaeEdges connections;
      
    case (GRAPH(updateGraph = updateGraph,definiteRoots = definiteRoots,potentialRoots = potentialRoots,branches = branches,connections = connections), root)
      equation
        Debug.fprintln("cgraph", "- ConnectionGraph.addDefiniteRoot(" +& 
            Exp.printComponentRefStr(root) +& ")");
      then 
        GRAPH(updateGraph,root::definiteRoots,potentialRoots,branches,connections);
  end matchcontinue;
end addDefiniteRoot;

function addPotentialRoot 
"Adds a new potential root to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.ComponentRef inRoot;
  input Real inPriority;
  output ConnectionGraph outGraph;
algorithm
/*  outGraph := GRAPH(inGraph.definiteRoots,
                    (inRoot, inPriority)::inGraph.potentialRoots,
                    inGraph.branches,
                    inGraph.connections);
*/
  outGraph := matchcontinue(inGraph, inRoot, inPriority)
    local 
      Boolean updateGraph;
      ConnectionGraph graph;
      DAE.ComponentRef root;
      Real priority;
      list<DAE.ComponentRef> definiteRoots;
      list<tuple<DAE.ComponentRef,Real>> potentialRoots;
      Edges branches;
      DaeEdges connections;

    case (GRAPH(updateGraph = updateGraph,definiteRoots = definiteRoots,potentialRoots = potentialRoots,branches = branches,connections = connections), root, priority)
      equation
        Debug.fprintln("cgraph", "- ConnectionGraph.addPotentialRoot(" +& 
            Exp.printComponentRefStr(root) +& ", " +& realString(priority) +& ")");
      then 
        GRAPH(updateGraph,definiteRoots,(root,priority)::potentialRoots,branches,connections);
  end matchcontinue;
end addPotentialRoot;

function addBranch
"Adds a new branch to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  output ConnectionGraph outGraph;
algorithm
/*  outGraph := GRAPH(inGraph.definiteRoots,
                    inGraph.potentialRoots,
                    (inRef1,inRef2)::inGraph.branches,
                    inGraph.connections);
*/
  outGraph := matchcontinue(inGraph, inRef1, inRef2)
    local 
      Boolean updateGraph;
      ConnectionGraph graph;
      DAE.ComponentRef ref1;
      DAE.ComponentRef ref2;
      list<DAE.ComponentRef> definiteRoots;
      list<tuple<DAE.ComponentRef,Real>> potentialRoots;
      Edges branches;
      DaeEdges connections;

    case (GRAPH(updateGraph = updateGraph, definiteRoots = definiteRoots,potentialRoots = potentialRoots,branches = branches,connections = connections), ref1, ref2)
      equation
        Debug.fprintln("cgraph", "- ConnectionGraph.addBranch(" +& 
            Exp.printComponentRefStr(ref1) +& ", " +& 
            Exp.printComponentRefStr(ref2) +& ")");
      then 
        GRAPH(updateGraph, definiteRoots,potentialRoots,(ref1,ref2)::branches,connections);
  end matchcontinue;
end addBranch;

function addConnection
"Adds a new connection to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  input list<DAE.Element> inDae;
  output ConnectionGraph outGraph;
algorithm
/*  outGraph := GRAPH(inGraph.definiteRoots,
                    inGraph.potentialRoots,
                    inGraph.branches,
                    (inRef1,inRef2)::inGraph.connections);
*/
  outGraph := matchcontinue(inGraph, inRef1, inRef2,inDae)
    local 
      Boolean updateGraph;
      ConnectionGraph graph;
      DAE.ComponentRef ref1;
      DAE.ComponentRef ref2;
      list<DAE.Element> dae;
      list<DAE.ComponentRef> definiteRoots;
      list<tuple<DAE.ComponentRef,Real>> potentialRoots;
      Edges branches;
      DaeEdges connections;
      
    case (GRAPH(updateGraph = updateGraph, definiteRoots = definiteRoots,potentialRoots = potentialRoots,branches = branches,connections = connections), ref1, ref2, dae)
      equation
        Debug.fprintln("cgraph", "- ConnectionGraph.addConnection(" +& 
            Exp.printComponentRefStr(ref1) +& ", " +& 
            Exp.printComponentRefStr(ref2) +& ")");
    then GRAPH(updateGraph, definiteRoots,potentialRoots,branches,(ref1,ref2,dae)::connections);
  end matchcontinue;
end addConnection;

function canonical
"Returns the canonical element of the component where input element belongs to. 
 See explanation at the top of file."
  input HashTableCG.HashTable inPartition;
  input DAE.ComponentRef inRef;
//output HashTableCG.HashTable outPartition;
  output DAE.ComponentRef outCanonical;
algorithm
  (/*outPartition,*/outCanonical) := matchcontinue(inPartition, inRef)
    local
      HashTableCG.HashTable partition, partition2;
      DAE.ComponentRef ref, parent, parentCanonical;

    case (partition, ref)
      equation
        parent = HashTableCG.get(ref, partition);
        parentCanonical = canonical(partition, parent);
        //partition2 = HashTableCG.add((ref, parentCanonical), partition);
      then parentCanonical;
         
    case (partition,ref) then ref;
  end matchcontinue;
end canonical;

function areInSameComponent
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
        //print("canon1: " +& Exp.printComponentRefStr(canon1));
        //print("\tcanon2: " +& Exp.printComponentRefStr(canon2) +& "\n");
        true = Exp.crefEqual(canon1, canon2);
      then true;
    case(_,_,_) then false;
  end matchcontinue;
end areInSameComponent;

function connectComponents
  "Tries to connect two components whose elements are given. Depending
  on wheter the connection success or not (i.e are the components already
  connected), adds either inConnectionDae or inBreakDae to the list of
  DAE elements."
  input HashTableCG.HashTable inPartition;
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  input list<DAE.Element> inBreakDae;
  input list<DAE.Element> inFullDae;
  output HashTableCG.HashTable outPartition;
  output list<DAE.Element> outDae;
algorithm
  (outPartition,outDae) := matchcontinue(inPartition,inRef1,inRef2,inBreakDae,inFullDae)
    local
      HashTableCG.HashTable partition;
      DAE.ComponentRef ref1, ref2, canon1, canon2;
      list<DAE.Element> dae, breakDAE;
      
    // leave the DAE as it is as we already added the equations from connect(ref1,ref2)
    case(partition,ref1,ref2,_,dae)
      equation
        failure(canon1 = canonical(partition,ref1)); // no parent
      then (partition, dae);
      
    // leave the DAE as it is as we already added the equations from connect(ref1,ref2)
    case(partition,ref1,ref2,_,dae)
      equation
        failure(canon2 = canonical(partition,ref2)); // no parent
      then (partition, dae);      
      
    // leave the DAE as it is as we already added the equations from connect(ref1,ref2)    
    case(partition,ref1,ref2,_,dae)
      equation
        canon1 = canonical(partition,ref1);
        canon2 = canonical(partition,ref2);
        //print(Exp.printComponentRefStr(canon1));
        //print(" -cc- ");
        //print(Exp.printComponentRefStr(canon2));
        //print("\n");        
        (partition, true) = connectCanonicalComponents(partition,canon1,canon2);        
        //print(Exp.printComponentRefStr(ref1));
        //print(" -- ");
        //print(Exp.printComponentRefStr(ref2));
        //print("\n");
      then (partition, dae);
    case(partition,ref1,ref2,breakDAE,dae)
      equation
        // remove the added equations from the DAE then add the breakDAE
        // dae = listAppend(dae, breakDAE); // removed for now as the algorithm doesn't work correctly.
        //print(Exp.printComponentRefStr(ref1));
        //print(" -/- ");
        //print(Exp.printComponentRefStr(ref2));
        //print("\n");
      then (partition, dae);
  end matchcontinue;
end connectComponents;

function connectCanonicalComponents
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

    case(partition,ref1,ref2)
      equation 
        true = Exp.crefEqual(ref1, ref2);
      then (partition, false);
    case(partition,ref1,ref2)
      equation 
        partition = HashTableCG.add((ref1,ref2), partition);
      then (partition, true);
  end matchcontinue;
end connectCanonicalComponents;

function addRootsToTable
"Adds a root the the graph. This is implemented by connecting the root to inFirstRoot element."
  input HashTableCG.HashTable inTable;
  input list<DAE.ComponentRef> inRoots;
  input DAE.ComponentRef inFirstRoot;
  output HashTableCG.HashTable outTable;
algorithm
  outTable := matchcontinue(inTable, inRoots, inFirstRoot)
    local
      HashTableCG.HashTable table;
      DAE.ComponentRef root, firstRoot;
      list<DAE.ComponentRef> tail;

    case(table, (root::tail), firstRoot)
      equation
        table = HashTableCG.add((root,firstRoot), table);
        table = addRootsToTable(table, tail, firstRoot);
      then table; 
    case(table, {}, _) then table;
  end matchcontinue;
end addRootsToTable;

function resultGraphWithRoots
"Creates an initial graph with given definite roots."
  input list<DAE.ComponentRef> roots;
  output HashTableCG.HashTable outTable;
  HashTableCG.HashTable table0;
  DAE.ComponentRef dummyRoot;
algorithm
  dummyRoot := DAE.CREF_IDENT("__DUMMY_ROOT", DAE.ET_INT, {});
  table0 := HashTableCG.emptyHashTable();
  outTable := addRootsToTable(table0, roots, dummyRoot);
end resultGraphWithRoots;

function addBranchesToTable
"Adds all branches to the graph."
  input HashTableCG.HashTable inTable;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> inBranches;
  output HashTableCG.HashTable outTable;
algorithm
  outTable := matchcontinue(inTable, inBranches)
    local
      HashTableCG.HashTable table, table1, table2;
      DAE.ComponentRef ref1, ref2;
      list<tuple<DAE.ComponentRef, DAE.ComponentRef>> tail;

    case(table, ((ref1,ref2)::tail))
      equation
        (table1,_) = connectComponents(table, ref1, ref2, {}, {});
        table2 = addBranchesToTable(table, tail);
      then table2;
    case(table, {}) then table;
  end matchcontinue;
end addBranchesToTable;

function ord
"An ordering function for potential roots."
  input tuple<DAE.ComponentRef,Real> inEl1;
  input tuple<DAE.ComponentRef,Real> inEl2;
  output Boolean outBoolean;
algorithm 
  outBoolean := matchcontinue(inEl1, inEl2)
    local Real r1, r2;
    case((_,r1), (_,r2))
    then r1 >. r2;
  end matchcontinue;
end ord;

function addPotentialRootsToTable
"Adds all potential roots to graph."
  input HashTableCG.HashTable inTable;
  input list<tuple<DAE.ComponentRef,Real>> inPotentialRoots;
  input list<DAE.ComponentRef> inRoots;
  input DAE.ComponentRef inFirstRoot;
  output HashTableCG.HashTable outTable;
  output list<DAE.ComponentRef> outRoots;
algorithm
  (outTable,outRoots) := matchcontinue(inTable, inPotentialRoots, inRoots, inFirstRoot)
    local
      HashTableCG.HashTable table;
      DAE.ComponentRef root, firstRoot, canon1, canon2;
      list<DAE.ComponentRef> roots;
      list<tuple<DAE.ComponentRef,Real>> tail;

    case(table, {}, roots, _) then (table,roots);
    case(table, ((root,_)::tail), roots, firstRoot)
      equation
        canon1 = canonical(table,root);
        canon2 = canonical(table,firstRoot);
        (table, true) = connectCanonicalComponents(table,canon1,canon2);
        (table, roots) = addPotentialRootsToTable(table, tail, root::roots, firstRoot);
      then (table,roots);
    case(table, (_::tail), roots, firstRoot)
      equation
        (table,roots) = addPotentialRootsToTable(table, tail, roots, firstRoot);
      then (table,roots);
  end matchcontinue;
end addPotentialRootsToTable;

function addConnections
"Adds all connections to graph."
  input HashTableCG.HashTable inTable;
  input DaeEdges inConnections;
  input list<DAE.Element> inDae;  
  output HashTableCG.HashTable outTable;
  output list<DAE.Element> outDae;
algorithm
  (outTable,outDae) := matchcontinue(inTable, inConnections, inDae)
    local
      HashTableCG.HashTable table;
      DAE.ComponentRef ref1, ref2;
      DaeEdges tail;
      list<DAE.Element> breakDAE, dae;

    case(table, {}, dae) then (table, dae);
    case(table, ((ref1,ref2,breakDAE)::tail), dae)
    equation
      (table,dae) = connectComponents(table, ref1, ref2,breakDAE,dae);
      (table,dae) = addConnections(table, tail, dae);
    then (table,dae); 
  end matchcontinue;
end addConnections;

function findResultGraph
"Given ConnectionGraph structure, breaks all connections, determines roots and generates a list of dae elements."
  input ConnectionGraph inGraph;
  output list<DAE.ComponentRef> outRoots;
  output list<DAE.Element> outDae;
algorithm
  (outRoots, outDae) := matchcontinue(inGraph)
    local
      list<DAE.ComponentRef> definiteRoots, finalRoots;
      list<tuple<DAE.ComponentRef,Real>> potentialRoots;
      list<tuple<DAE.ComponentRef,Real>> orderedPotentialRoots;
      Edges branches;
      DaeEdges connections;
      HashTableCG.HashTable table;
      DAE.ComponentRef dummyRoot;
      Edges brokenConnections, normalConnections;
      list<DAE.Element> dae;

    // deal with empty connection graph
    case (GRAPH(_, definiteRoots = {}, potentialRoots = {}, branches = {}, connections = {})) then ({}, {});
      
    // we have something in the connection graph
    case (GRAPH(_, definiteRoots = definiteRoots, potentialRoots = potentialRoots, 
                   branches = branches, connections = connections))
      equation
        table = resultGraphWithRoots(definiteRoots);
        table = addBranchesToTable(table, branches);
        orderedPotentialRoots = Util.sort(potentialRoots, ord);
        dummyRoot = DAE.CREF_IDENT("__DUMMY_ROOT", DAE.ET_INT, {});
        (table, dae) = addConnections(table, connections, {});
        (table, finalRoots) = addPotentialRootsToTable(table, orderedPotentialRoots, definiteRoots, dummyRoot);  
      then (finalRoots, dae);
  end matchcontinue;
end findResultGraph;

function evalIsRoot  
"Replaces all Connections.isRoot calls by true or false depending on wheter the parameter is in the list of roots."
  input list<DAE.ComponentRef> inRoots;
  input list<DAE.Element> inDae;
  output list<DAE.Element> outDae;
algorithm
  outDae := matchcontinue(inRoots, inDae)
    case ({}, {}) then {};
    case ({}, inDae) then inDae;
    case (inRoots, inDae) 
      equation 
        (outDae, _) = DAEUtil.traverseDAE(inDae, evalIsRootHelper, inRoots);
      then outDae; 
  end matchcontinue;
end evalIsRoot;

function evalIsRootHelper
"Helper function for evalIsRoot."
  input DAE.Exp inExp; 
  input list<DAE.ComponentRef> inRoots; 
  output DAE.Exp outExp; 
  output list<DAE.ComponentRef> outRoots;
algorithm  
  (outExp,outRoots) := matchcontinue(inExp,inRoots)
    local  
      DAE.Exp exp; 
      list<DAE.ComponentRef> roots;
      DAE.ComponentRef cref;
      Boolean result;
    
    // no roots, same exp
    case (exp, {}) then (exp, {});    
    // deal with Connections.isRoot
    case (DAE.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), 
          expLst={DAE.CREF(componentRef = cref)}), roots)
      equation
        result = Util.listContainsWithCompareFunc(cref, roots, Exp.crefEqual);
        //Debug.fprintln("cgraph", Exp.printExpStr(inExp) +& " is found in roots:");
      then (DAE.BCONST(result), roots);
    // deal with NOT Connections.isRoot
    case (DAE.LUNARY(DAE.NOT(), DAE.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), 
          expLst={DAE.CREF(componentRef = cref)})), roots)
      equation
        result = Util.listContainsWithCompareFunc(cref, roots, Exp.crefEqual);
        result = boolNot(result);
        //Debug.fprintln("cgraph", Exp.printExpStr(inExp) +& " is found in roots!");
      then (DAE.BCONST(result), roots);
    // no replacement needed        
    case (exp, roots)
      equation
        //Debug.fprintln("cgraph", Exp.printExpStr(exp) +& " not found in roots!");
      then (exp, roots);
  end matchcontinue;
end evalIsRootHelper;

public function handleOverconstrainedConnections
"author: adrpo
 this function gets the connection graph and adds the
 new connections to the DAE given as input and returns
 a new DAE"
 input ConnectionGraph inGraph;
 input list<DAE.Element> inDAE;
 output list<DAE.Element> outDAE;
algorithm
  outDAE := matchcontinue(inGraph, inDAE)
    local
      ConnectionGraph graph;
      list<DAE.Element> dae, daeConnections;
      list<DAE.ComponentRef> roots;
    // empty graph gives you the same dae
    case (GRAPH(_, {}, {}, {}, {}), dae) then dae;
    // no dae
    case (graph, {}) then {};
    // handle the connection braking
    case (graph, dae)
      equation
        (roots,daeConnections) = findResultGraph(graph);
        Debug.fprintln("cgraph", "Extra equations from connection graph: " +& intString(listLength(daeConnections)));
        Debug.fprintln("cgraph", "Roots:\n" +& Util.stringDelimitList(Util.listMap(roots, Exp.printComponentRefStr), ",\n"));
        Debug.fcall("cgraph", DAEUtil.dumpElements, daeConnections);
        Debug.fprintln("cgraph", Print.getString());
        Debug.fprintln("cgraph", "\n");
        dae = evalIsRoot(roots, dae);
        dae = Util.listAppendNoCopy(dae, daeConnections);
      then
        dae;
    // handle the connection braking 
    case (graph, dae)
      equation
        Debug.fprintln("cgraph", "- ConnectionGraph.handleOverconstrainedConnections failed");
      then 
        fail();        
  end matchcontinue;
end handleOverconstrainedConnections;

end ConnectionGraph;
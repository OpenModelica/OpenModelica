/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

  RCS: $Id: Ceval.mo 4018 2009-05-07 01:06:33Z adrpo $

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
  that the model is valid. 
 "
      
public import Absyn;
public import DAE;
public import Exp;
public import HashTableCG;
public import Util;
public import DAEUtil;

/* A list of edges 
 */
type Edges = list<tuple<Exp.ComponentRef,Exp.ComponentRef>>;
/* A list of edges, each edge associated with two lists of DAE elements
 * (these elements represent equations to be added if the edge
 * is preserved or broken) 
 */
type DaeEdges = list<tuple<Exp.ComponentRef,Exp.ComponentRef,list<DAE.Element>,list<DAE.Element>>>;

uniontype ConnectionGraph
  "Input structure for connection breaking algorithm. It is collected during instantiation phase."
    record GRAPH
      Boolean updateGraph;
      list<Exp.ComponentRef> definiteRoots "Roots defined with Connection.root";
      list<tuple<Exp.ComponentRef,Real>> potentialRoots "Roots defined with Connection.potentialRoot";
      Edges branches "Edges defined with Connection.branch";
      DaeEdges connections "Edges defined with connect statement";
    end GRAPH;
end ConnectionGraph;

/* Initial connection graph with no edges in it.
 */
public constant ConnectionGraph EMPTY = GRAPH( true, {}, {}, {}, {} );
/* Initial connection graph with updateGraph set to false.
 */
public constant ConnectionGraph NOUPDATE_EMPTY = GRAPH( false, {}, {}, {}, {} );

function printEdges
  "Prints a list of edges to stdout."
  input Edges inEdges;
algorithm
  _ := matchcontinue(inEdges)
    local
      Exp.ComponentRef c1, c2;
      Edges tail;
    case ({})
    equation
    then ();
            
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
      Exp.ComponentRef c1, c2;
      DaeEdges tail;
    case ({})
    equation
    then ();
            
    case ((c1, c2, _, _) :: tail)
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
  output list<Exp.ComponentRef> outResult;
algorithm
  outResult := matchcontinue(inGraph)
    local list<Exp.ComponentRef> result;
    case (GRAPH(_,result,_,_,_))
    then result;
  end matchcontinue;
end getDefiniteRoots;

function getPotentialRoots
  "Accessor for ConnectionGraph.potentialRoots."
  input ConnectionGraph inGraph;
  output list<tuple<Exp.ComponentRef,Real>> outResult;
algorithm
  outResult := matchcontinue(inGraph)
    local list<tuple<Exp.ComponentRef,Real>> result;
    case (GRAPH(_,_,result,_,_))
    then result;
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
    case (GRAPH(_,_,_,_,result))
    then result;
  end matchcontinue;
end getConnections;

function addDefiniteRoot 
  "Adds a new definite root to ConnectionGraph"
  input ConnectionGraph inGraph;
  input Exp.ComponentRef inRoot;
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
      Exp.ComponentRef root;
      list<Exp.ComponentRef> definiteRoots;
      list<tuple<Exp.ComponentRef,Real>> potentialRoots;
      Edges branches;
      DaeEdges connections;
    case (GRAPH(updateGraph = updateGraph,definiteRoots = definiteRoots,potentialRoots = potentialRoots,branches = branches,connections = connections), root)
    then GRAPH(updateGraph,root::definiteRoots,potentialRoots,branches,connections);
  end matchcontinue;
end addDefiniteRoot;

function addPotentialRoot 
  "Adds a new potential root to ConnectionGraph"
  input ConnectionGraph inGraph;
  input Exp.ComponentRef inRoot;
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
      Exp.ComponentRef root;
      Real priority;
      list<Exp.ComponentRef> definiteRoots;
      list<tuple<Exp.ComponentRef,Real>> potentialRoots;
      Edges branches;
      DaeEdges connections;
    case (GRAPH(updateGraph = updateGraph,definiteRoots = definiteRoots,potentialRoots = potentialRoots,branches = branches,connections = connections), root, priority)
    then GRAPH(updateGraph,definiteRoots,(root,priority)::potentialRoots,branches,connections);
  end matchcontinue;
end addPotentialRoot;

function addBranch
  "Adds a new branch to ConnectionGraph"
  input ConnectionGraph inGraph;
  input Exp.ComponentRef inRef1;
  input Exp.ComponentRef inRef2;
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
      Exp.ComponentRef ref1;
      Exp.ComponentRef ref2;
      list<Exp.ComponentRef> definiteRoots;
      list<tuple<Exp.ComponentRef,Real>> potentialRoots;
      Edges branches;
      DaeEdges connections;
    case (GRAPH(updateGraph = updateGraph, definiteRoots = definiteRoots,potentialRoots = potentialRoots,branches = branches,connections = connections), ref1, ref2)
    then GRAPH(updateGraph, definiteRoots,potentialRoots,(ref1,ref2)::branches,connections);
  end matchcontinue;
end addBranch;

function addConnection
  "Adds a new connection to ConnectionGraph"
  input ConnectionGraph inGraph;
  input Exp.ComponentRef inRef1;
  input Exp.ComponentRef inRef2;
  input list<DAE.Element> inDae;
  input list<DAE.Element> inDae2;
  output ConnectionGraph outGraph;
algorithm
/*  outGraph := GRAPH(inGraph.definiteRoots,
                    inGraph.potentialRoots,
                    inGraph.branches,
                    (inRef1,inRef2)::inGraph.connections);
*/
  outGraph := matchcontinue(inGraph, inRef1, inRef2,inDae,inDae2)
    local 
      Boolean updateGraph;
      ConnectionGraph graph;
      Exp.ComponentRef ref1;
      Exp.ComponentRef ref2;
      list<DAE.Element> dae,dae2;
      list<Exp.ComponentRef> definiteRoots;
      list<tuple<Exp.ComponentRef,Real>> potentialRoots;
      Edges branches;
      DaeEdges connections;
    case (GRAPH(updateGraph = updateGraph, definiteRoots = definiteRoots,potentialRoots = potentialRoots,branches = branches,connections = connections), ref1, ref2, dae,dae2)
    then GRAPH(updateGraph, definiteRoots,potentialRoots,branches,(ref1,ref2,dae,dae2)::connections);
  end matchcontinue;
end addConnection;

function canonical
  "Returns the canonical element of the component where input element belongs to. 
   See explanation at the top of file."
  input HashTableCG.HashTable inPartition;
  input Exp.ComponentRef inRef;
//  output HashTableCG.HashTable outPartition;
  output Exp.ComponentRef outCanonical;
algorithm
  /*outPartition,*/ outCanonical := matchcontinue(inPartition, inRef)
    local
      HashTableCG.HashTable partition, partition2;
      Exp.ComponentRef ref, parent, parentCanonical;
    case (partition, ref)
    equation
      parent = HashTableCG.get(ref, partition);
      parentCanonical = canonical(partition, parent);
      //partition2 = HashTableCG.add((ref, parentCanonical), partition);
    then parentCanonical; 
    case (partition,ref)
    then ref;
  end matchcontinue;
end canonical;

function areInSameComponent
  "Tells whether the elements belong to the same component. 
   See explanation at the top of file."
  input HashTableCG.HashTable inPartition;
  input Exp.ComponentRef inRef1;
  input Exp.ComponentRef inRef2;
  output Boolean outResult;
algorithm
  // canonical(inPartition,inRef1) = canonical(inPartition,inRef2);
  outResult := matchcontinue(inPartition,inRef1,inRef2)
    local
      HashTableCG.HashTable partition;
      Exp.ComponentRef ref1, ref2, canon;
    case(partition,ref1,ref2)
    equation
      canon = canonical(partition,ref1);
      canon = canonical(partition,ref2);
    then true;
    case(_,_,_)
    then false;
  end matchcontinue;
end areInSameComponent;

function connectComponents
  "Tries to connect two components whose elements are given. Depending
  on wheter the connection success or not (i.e are the components already
  connected), adds either inConnectionDae or inBreakDae to the list of
  DAE elements."
  input HashTableCG.HashTable inPartition;
  input Exp.ComponentRef inRef1;
  input Exp.ComponentRef inRef2;
  input list<DAE.Element> inConnectionDae;
  input list<DAE.Element> inBreakDae;
  input list<DAE.Element> inDae;
  output HashTableCG.HashTable outPartition;
  output list<DAE.Element> outDae;
algorithm
  (outPartition,outDae) :=
   matchcontinue(inPartition,inRef1,inRef2,inConnectionDae,inBreakDae,inDae)
    local
      HashTableCG.HashTable partition;
      Exp.ComponentRef ref1, ref2, canon1, canon2;
      list<DAE.Element> connectionDae, dae;
    case(partition,ref1,ref2,connectionDae,_,dae)
    equation      
      canon1 = canonical(partition,ref1);
      canon2 = canonical(partition,ref2);
      (partition, true) = connectCanonicalComponents(partition,canon1,canon2);
      dae = listAppend(dae, connectionDae);
      /*print(Exp.printComponentRefStr(ref1));
      print(" -- ");
      print(Exp.printComponentRefStr(ref2));
      print("\n");*/
    then (partition, dae);
    case(partition,ref1,ref2,_,connectionDae,dae)
    equation
      dae = listAppend(dae, connectionDae);
      /*print(Exp.printComponentRefStr(ref1));
      print(" -/- ");
      print(Exp.printComponentRefStr(ref2));
      print("\n");*/
    then (partition, dae);
  end matchcontinue;
end connectComponents;

function connectCanonicalComponents
  "Tries to connect two components whose canonical elements are given.
  Helper function for connectionComponents."
  input HashTableCG.HashTable inPartition;
  input Exp.ComponentRef inRef1;
  input Exp.ComponentRef inRef2;
  output HashTableCG.HashTable outPartition;
  output Boolean outReallyConnected;
algorithm
  (outPartition,outReallyConnected) := 
  matchcontinue(inPartition,inRef1,inRef2)
    local
      HashTableCG.HashTable partition;
      Exp.ComponentRef ref1, ref2;
      list<DAE.Element> connectionDae, dae;
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
  "Adds a root the the graph. This is implemented by connecting
  the root to inFirstRoot element."
  input HashTableCG.HashTable inTable;
  input list<Exp.ComponentRef> inRoots;
  input Exp.ComponentRef inFirstRoot;
  output HashTableCG.HashTable outTable;
algorithm
  outTable := matchcontinue(inTable, inRoots, inFirstRoot)
    local
      HashTableCG.HashTable table;
      Exp.ComponentRef root, firstRoot;
      list<Exp.ComponentRef> tail;
    case(table, (root::tail), firstRoot)
    equation
      table = HashTableCG.add((root,firstRoot), table);
      table = addRootsToTable(table, tail, firstRoot);
    then table; 
    case(table, {}, _)
    then table;
  end matchcontinue;
end addRootsToTable;

function resultGraphWithRoots
  "Creates an initial graph with given definite roots."
  input list<Exp.ComponentRef> roots;
  output HashTableCG.HashTable outTable;
  HashTableCG.HashTable table0;
  Exp.ComponentRef dummyRoot;
algorithm
  dummyRoot := Exp.CREF_IDENT("__DUMMY_ROOT", Exp.ET_INT, {});
  table0 := HashTableCG.emptyHashTable();
  outTable := addRootsToTable(table0, roots, dummyRoot);
end resultGraphWithRoots;

function addBranchesToTable
  "Adds all branches to the graph."
  input HashTableCG.HashTable inTable;
  input list<tuple<Exp.ComponentRef, Exp.ComponentRef>> inBranches;
  output HashTableCG.HashTable outTable;
algorithm
  outTable := matchcontinue(inTable, inBranches)
    local
      HashTableCG.HashTable table, table1, table2;
      Exp.ComponentRef ref1, ref2;
      list<tuple<Exp.ComponentRef, Exp.ComponentRef>> tail;
    case(table, ((ref1,ref2)::tail))
    equation
      (table1,_) = connectComponents(table, ref1, ref2, {}, {}, {});
      table2 = addBranchesToTable(table, tail);
    then table2;
    case(table, {})
    then table;
  end matchcontinue;
end addBranchesToTable;

function ord
  "An ordering function for potential roots."
  input tuple<Exp.ComponentRef,Real> inEl1;
  input tuple<Exp.ComponentRef,Real> inEl2;
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
  input list<tuple<Exp.ComponentRef,Real>> inPotentialRoots;
  input list<Exp.ComponentRef> inRoots;
  input Exp.ComponentRef inFirstRoot;
  output HashTableCG.HashTable outTable;
  output list<Exp.ComponentRef> outRoots;
algorithm
  (outTable,outRoots) := matchcontinue(inTable, inPotentialRoots, inRoots, inFirstRoot)
    local
      HashTableCG.HashTable table;
      Exp.ComponentRef root, firstRoot, canon1, canon2;
      list<Exp.ComponentRef> roots;
      list<tuple<Exp.ComponentRef,Real>> tail;
    case(table, {}, roots, _)
    then (table,roots);
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
  (outTable,outDae) := 
    matchcontinue(inTable, inConnections, inDae)
    local
      HashTableCG.HashTable table;
      Exp.ComponentRef ref1, ref2;
      DaeEdges tail;
      list<DAE.Element> connectionDae, breakDae, dae;
    case(table, {}, dae)
    then (table, dae);
    case(table, ((ref1,ref2,connectionDae,breakDae)::tail), dae)
    equation
      (table,dae) = connectComponents(table, ref1, ref2,connectionDae,breakDae,dae);
      (table,dae) = addConnections(table, tail, dae);
    then (table,dae); 
  end matchcontinue;
end addConnections;

function findResultGraph
  "Given ConnectionGraph structure, breaks all connections, determines
  roots and generates a list of dae elements."
  input ConnectionGraph inGraph;
  output list<Exp.ComponentRef> outRoots;
  output list<DAE.Element> outDae;
  list<Exp.ComponentRef> definiteRoots, finalRoots;
  list<tuple<Exp.ComponentRef,Real>> potentialRoots;
  list<tuple<Exp.ComponentRef,Real>> orderedPotentialRoots;
  Edges branches;
  DaeEdges connections;
  HashTableCG.HashTable table;
  Exp.ComponentRef dummyRoot;
  Edges brokenConnections, normalConnections;
  list<DAE.Element> dae;
algorithm
  definiteRoots := getDefiniteRoots(inGraph);
  potentialRoots := getPotentialRoots(inGraph);
  branches := getBranches(inGraph);
  connections := getConnections(inGraph);

  table := resultGraphWithRoots(definiteRoots);
  table := addBranchesToTable(table, branches);
  orderedPotentialRoots := Util.sort(potentialRoots, ord);
  dummyRoot := Exp.CREF_IDENT("__DUMMY_ROOT", Exp.ET_INT, {});
  (table, dae) := addConnections(table, connections, {});
  (table, finalRoots) := addPotentialRootsToTable(table, orderedPotentialRoots, definiteRoots, dummyRoot);  
  outRoots := finalRoots;
  outDae := dae;
end findResultGraph;

function evalIsRoot  
  "Replaces all Connections.isRoot calls by true or false depending on
  wheter the parameter is in the list of roots."
  input list<Exp.ComponentRef> inRoots;
  input list<DAE.Element> inDae;
  output list<DAE.Element> outDae;
algorithm
  (outDae, _) := DAEUtil.traverseDAE(inDae, evalIsRootHelper, inRoots);
end evalIsRoot;

function evalIsRootHelper
  "Helper function for evalIsRoot."
  input Exp.Exp inExp; 
  input list<Exp.ComponentRef> inRoots; 
  output Exp.Exp outExp; 
  output list<Exp.ComponentRef> outRoots;
algorithm  
  (outExp,outRoots) := matchcontinue(inExp,inRoots)
  local  
    Exp.Exp exp; 
    list<Exp.ComponentRef> roots;
    Exp.ComponentRef cref;
    Boolean result;
    case (Exp.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), 
          expLst={Exp.CREF(componentRef = cref)}), roots)
      equation
        result = Util.listContainsWithCompareFunc(cref, roots, Exp.crefEqual);
      then (Exp.BCONST(result), roots);
    case (exp, roots)
      then (exp, roots);
  end matchcontinue;
end evalIsRootHelper;

end ConnectionGraph;
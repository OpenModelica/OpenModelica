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
  elements so far connected.  
  Each component has an unique canonical element. 
  The data structure is implemented by a hash table, that 
  contains an entry for each non-canonical element so that 
  a path beginning from some element eventually ends to the 
  canonical element of the same component.

  Roots are represented as connections to dummy root
  element. In this way, all elements will be in the
  same component after the algorithm finishes assuming
  that the model is valid."

public import Absyn;
public import DAE;
public import DAEUtil;
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

public type PotentialRoot = tuple<DAE.ComponentRef,Real> "potential root defined with Connections.potentialRoot";
public type PotentialRoots = list<tuple<DAE.ComponentRef,Real>> "potential roots defined with Connections.potentialRoot";

public 
uniontype ConnectionGraph "Input structure for connection breaking algorithm. It is collected during instantiation phase."
    record GRAPH
      Boolean updateGraph;
      DefiniteRoots definiteRoots "Roots defined with Connection.root";
      PotentialRoots potentialRoots "Roots defined with Connection.potentialRoot";
      Edges branches "Edges defined with Connection.branch";
      DaeEdges connections "Edges defined with connect statement";
    end GRAPH;
end ConnectionGraph;

public constant ConnectionGraph EMPTY = GRAPH( true, {}, {}, {}, {} ) "Initial connection graph with no edges in it.";

public constant ConnectionGraph NOUPDATE_EMPTY = GRAPH( false, {}, {}, {}, {} ) "Initial connection graph with updateGraph set to false.";

public function handleOverconstrainedConnections
"author: adrpo
 this function gets the connection graph and adds the
 new connections to the DAE given as input and returns
 a new DAE"
 input ConnectionGraph inGraph;
 input DAE.DAElist inDAE;
 input String modelNameQualified;
 output DAE.DAElist outDAE;
algorithm
  outDAE := matchcontinue(inGraph, inDAE, modelNameQualified)
    local
      ConnectionGraph graph;
      list<DAE.Element> daeConnections;
      list<DAE.Element> elts;
      DAE.AvlTree funcs;
      list<DAE.ComponentRef> roots;
      DAE.DAElist dae;
      list<tuple<DAE.ComponentRef, DAE.ComponentRef>> broken;

    // empty graph gives you the same dae
    case (GRAPH(_, {}, {}, {}, {}), dae, modelNameQualified) then dae;
    // no dae
    // case (graph, DAE.DAE({},_)) then DAEUtil.emptyDae;
    // handle the connection braking
    case (graph, DAE.DAE(elts), modelNameQualified)
      equation

        Debug.fprintln("cgraph", "Summary: \n\t" +& 
           "Nr Roots:           " +& intString(listLength(getDefiniteRoots(graph))) +& "\n\t" +&
           "Nr Potential Roots: " +& intString(listLength(getPotentialRoots(graph))) +& "\n\t" +&
           "Nr Branches:        " +& intString(listLength(getBranches(graph))) +& "\n\t" +&
           "Nr Connections:     " +& intString(listLength(getConnections(graph))));

        (roots, elts, broken) = findResultGraph(graph, elts, modelNameQualified);

        Debug.fprintln("cgraph", "Roots: " +& Util.stringDelimitList(Util.listMap(roots, Exp.printComponentRefStr), ", "));
        Debug.fprintln("cgraph", "Broken connections: " +& Util.stringDelimitList(Util.listMap(broken, printConnectionStr), ", "));

        elts = evalIsRoot(roots, elts);
      then
        DAE.DAE(elts);
    // handle the connection braking
    case (graph, dae, modelNameQualified)
      equation
        Debug.fprintln("cgraph", "- ConnectionGraph.handleOverconstrainedConnections failed for model: " +& modelNameQualified);
      then
        fail();
  end matchcontinue;
end handleOverconstrainedConnections;

public function handleOverconstrainedConnectionsInSets
"author: adrpo
 this function gets the connection graph and adds the
 new connections to the DAE given as input and returns
 a new DAE"
 input ConnectionGraph inGraph;
 input Connect.Sets inSets;
 input Boolean isTopScope;
 output Connect.Sets outSets;
 output list<DAE.Element> outDAEElements;
algorithm
  (outSets,outDAEElements) := matchcontinue(inGraph, inSets, isTopScope)
    local
      ConnectionGraph graph;
      list<DAE.Element> elts;
      DAE.AvlTree funcs;
      list<DAE.ComponentRef> roots;
      DAE.DAElist dae;
      Connect.Sets sets;
      list<tuple<DAE.ComponentRef, DAE.ComponentRef>> broken;

    // if not top scope, do not do the connection graph!
    case (graph, sets, false) then (sets, {});

    // empty graph gives you the same connection graph!
    case (GRAPH(_, {}, {}, {}, {}), sets, isTopScope) then (inSets, {});
    // handle the connection braking
    case (graph, sets, isTopScope)
      equation
        (roots, elts, broken) = findResultGraph(graph, {}, "");
       
        Debug.fprintln("cgraph", "Roots: " +& Util.stringDelimitList(Util.listMap(roots, Exp.printComponentRefStr), ", "));
        Debug.fprintln("cgraph", "Broken connections: " +& Util.stringDelimitList(Util.listMap(broken, printConnectionStr), ", "));
        
        // remove the broken connects from connection set!
        sets = removeBrokenConnectionsFromSets(sets, broken);
        
      then
        (sets,elts);

    // handle the connection braking
    case (graph, sets, isTopScope)
      equation
        Debug.fprintln("cgraph", "- ConnectionGraph.handleOverconstrainedConnectionsInSets failed");
      then
        fail();
  end matchcontinue;
end handleOverconstrainedConnectionsInSets;

public function addDefiniteRoot
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

public function addPotentialRoot
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

public function addBranch
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

public function addConnection
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

// ************************************* //
// ********* protected section ********* //
// ************************************* //

protected import Exp;
protected import Debug;
protected import DAEDump;
protected import Util;
protected import System;
protected import IOStream;
protected import RTOpts;
protected import Settings;
protected import ComponentReference;

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
      HashTableCG.HashTable partition, partition2;
      DAE.ComponentRef ref, parent, parentCanonical;

    case (partition, ref)
      equation
        parent = HashTableCG.get(ref, partition);
        parentCanonical = canonical(partition, parent);
        //Debug.fprintln("cgraph", 
        //  "- ConnectionGraph.canonical_case1(" +& Exp.printComponentRefStr(ref) +& ") = " +&
        //  Exp.printComponentRefStr(parentCanonical));        
        //partition2 = HashTableCG.add((ref, parentCanonical), partition);
      then parentCanonical;

    case (partition,ref)
      equation
        //Debug.fprintln("cgraph", 
        //  "- ConnectionGraph.canonical_case2(" +& Exp.printComponentRefStr(ref) +& ") = " +&
        //  Exp.printComponentRefStr(ref));
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
        //print("canon1: " +& Exp.printComponentRefStr(canon1));
        //print("\tcanon2: " +& Exp.printComponentRefStr(canon2) +& "\n");
        true = ComponentReference.crefEqual(canon1, canon2);
      then true;
    case(_,_,_) then false;
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
    case(partition,ref1,ref2)
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
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  input list<DAE.Element> inBreakDae;
  input list<DAE.Element> inFullDae;
  output HashTableCG.HashTable outPartition;
  output list<DAE.Element> outDae;
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef>> outBrokenConnections;
algorithm
  (outPartition,outDae,outBrokenConnections) := matchcontinue(inPartition,inRef1,inRef2,inBreakDae,inFullDae)
    local
      HashTableCG.HashTable partition;
      DAE.ComponentRef ref1, ref2, canon1, canon2;
      list<DAE.Element> dae, breakDAE;

    // empty case!
    // case(partition,ref1,ref2,{},dae as {}) then (partition, dae);

    // leave the DAE as it is as we already added the equations from connect(ref1,ref2)
    case(partition,ref1,ref2,_,dae)
      equation
        failure(canon1 = canonical(partition,ref1)); // no parent
      then (partition, dae, {});

    // leave the DAE as it is as we already added the equations from connect(ref1,ref2)
    case(partition,ref1,ref2,_,dae)
      equation
        failure(canon2 = canonical(partition,ref2)); // no parent
      then (partition, dae, {});

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
      then (partition, dae, {});
    
    // remove the added equations from the DAE then add the breakDAE
    case(partition,ref1,ref2,breakDAE,dae)
      equation
        // debug print
        Debug.fprintln("cgraph", "- ConnectionGraph.connectComponents: should remove equations generated from: connect(" +& 
           Exp.printComponentRefStr(ref1) +& ", " +& 
           Exp.printComponentRefStr(ref2) +& ") and add {0, ..., 0} = equalityConstraint(cr1, cr2) instead.");        
        // remove the added equations from the DAE 
        dae = removeEquationsWithOrigin(dae, ref1, ref2);
        // then add the breakDAE which comes from {0} = equalityConstraint(A, B);
        dae = listAppend(dae, breakDAE);
      then (partition, dae, {(ref1,ref2)});
  end matchcontinue;
end connectComponents;

protected function removeEquationsWithOrigin 
"@author: adrpo
 this function *removes* the equations generated from 
 the connect component references given as input."
  input list<DAE.Element> inFullDAE;
  input DAE.ComponentRef left;
  input DAE.ComponentRef right;
  output list<DAE.Element> outDAE;
algorithm
  outDAE := matchcontinue(inFullDAE, left, right)
    local
      list<DAE.Element> rest, elements;
      DAE.Element el;
      DAE.ComponentRef cr1, cr2;
    
    // handle the empty case
    case ({}, cr1, cr2) then {};
    
    // if this element came from this connect, remove it! 
    case (el::rest, cr1, cr2)
      equation
        true = originInConnect(el, cr1, cr2);
        Debug.fprintln("cgraph", "- ConnectionGraph.removeEquationsWithOrigin: removed " +&
          DAEDump.dumpDAEElementsStr(DAE.DAE({el})) +& 
          "\t generated from: connect(" +& 
          Exp.printComponentRefStr(cr1) +& ", " +& 
          Exp.printComponentRefStr(cr2) +& ")");
        elements = removeEquationsWithOrigin(rest, cr1, cr2);
      then
        elements;
        
    // if this element DID NOT came from this connect, let it be! 
    case (el::rest, cr1, cr2)
      local 
        String str1, str2, str3;
      equation
        false = originInConnect(el, cr1, cr2);
        elements = removeEquationsWithOrigin(rest, cr1, cr2);
      then
        el::elements;
  end matchcontinue;
end removeEquationsWithOrigin;

protected function originInConnect
"@author: adrpo
 this function returns true if the given element came from 
 the connect of the component references given as input"
  input DAE.Element inElement;
  input DAE.ComponentRef left;
  input DAE.ComponentRef right;
  output Boolean hasOriginInConnect;  
algorithm
  hasOriginInConnect := matchcontinue(inElement, left, right)
    local
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectOptLst;
      Boolean b;
  
     // var
    case (DAE.VAR(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right); 
      then
        b;
     // define
    case (DAE.DEFINE(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
     // initial define
    case (DAE.INITIALDEFINE(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // equation
    case (DAE.EQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // initial equation
    case (DAE.INITIALEQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // equequation
    case (DAE.EQUEQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // array equation
    case (DAE.ARRAY_EQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // initial array equation
    case (DAE.INITIAL_ARRAY_EQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // complex equation
    case (DAE.COMPLEX_EQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // initial complex equation
    case (DAE.INITIAL_COMPLEX_EQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // when equation
    case (DAE.WHEN_EQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // if equation
    case (DAE.IF_EQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // initial if equation
    case (DAE.INITIAL_IF_EQUATION(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // algorithm
    case (DAE.ALGORITHM(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // initial algorithm
    case (DAE.INITIALALGORITHM(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // a component
    case (DAE.COMP(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // external object
    case (DAE.EXTOBJECTCLASS(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // assert
    case (DAE.ASSERT(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // terminate
    case (DAE.TERMINATE(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // reinit
    case (DAE.REINIT(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // no return call
    case (DAE.NORETCALL(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), left, right)
      equation
        b = isInConnectionList(connectOptLst, left, right);
      then
        b;
    // TODO! FIXME! CHECK THIS! anything else could not have come from a connect, ignore!
    case (inElement, left, right)
      equation
         //debug_print("element", inElement);
         //debug_print("left", left);
         //debug_print("right", right);
      then false;
  end matchcontinue;
end originInConnect;

protected function isInConnectionList
"@author: adrpo
 searches the given connect list for the matching connect given as component refence inputs"
  input list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> inConnectEquationOptLst;
  input DAE.ComponentRef left;
  input DAE.ComponentRef right;
  output Boolean isPresent;
algorithm
  isPresent := matchcontinue(inConnectEquationOptLst, left, right)
    local
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> rest;
      DAE.ComponentRef crLeft, crRight;
      Boolean b, b1, b2;

    // handle empty case
    case ({}, left, right) then false;

    // try direct match
    case (SOME((crLeft, crRight))::rest, left, right)
      equation
        b1 = ComponentReference.crefPrefixOf(left, crLeft);
        b2 = ComponentReference.crefPrefixOf(right, crRight);
        true = boolAnd(b1, b2);
        // print("connect: " +& Exp.printComponentRefStr(left) +& ", " +& Exp.printComponentRefStr(right) +& "\n");
        // print("origin: " +& Exp.printComponentRefStr(crLeft) +& ", " +& Exp.printComponentRefStr(crRight) +& "\n");
      then
        true;
    // try inverse match
    case (SOME((crLeft, crRight))::rest, left, right)      
      equation
        b1 = ComponentReference.crefPrefixOf(right, crLeft);
        b2 = ComponentReference.crefPrefixOf(left, crRight);
        true = boolAnd(b1, b2);
        // print("connect: " +& Exp.printComponentRefStr(left) +& ", " +& Exp.printComponentRefStr(right) +& "\n");
        // print("origin: " +& Exp.printComponentRefStr(crRight) +& ", " +& Exp.printComponentRefStr(crLeft) +& "\n");        
      then
        true;
    // try the rest
    case (_::rest, left, right)      
      equation
        b = isInConnectionList(rest, left, right);
      then
        b;
    // failure
    case (_, left, right)
      equation
        Debug.fprintln("cgraph", "- ConnectionGrap.isInConnectionList failed!");
      then
        fail();
  end matchcontinue;
end isInConnectionList;

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
        partition = HashTableCG.add((ref1,ref2), partition);
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

protected function resultGraphWithRoots
"Creates an initial graph with given definite roots."
  input list<DAE.ComponentRef> roots;
  output HashTableCG.HashTable outTable;
  HashTableCG.HashTable table0;
  DAE.ComponentRef dummyRoot;
algorithm
  dummyRoot := ComponentReference.makeCrefIdent("__DUMMY_ROOT", DAE.ET_INT(), {});
  table0 := HashTableCG.emptyHashTable();
  outTable := addRootsToTable(table0, roots, dummyRoot);
end resultGraphWithRoots;

protected function addBranchesToTable
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
        table1 = connectBranchComponents(table, ref1, ref2);
        table2 = addBranchesToTable(table1, tail);
      then table2;
    case(table, {}) then table;
  end matchcontinue;
end addBranchesToTable;

protected function ord
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

protected function addPotentialRootsToTable
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
      DAE.ComponentRef potentialRoot, firstRoot, canon1, canon2;
      list<DAE.ComponentRef> roots, finalRoots;
      list<tuple<DAE.ComponentRef,Real>> tail;

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
  input list<DAE.Element> inDae;
  output HashTableCG.HashTable outTable;
  output list<DAE.Element> outDae;
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef>> outBrokenConnections;
algorithm
  (outTable,outDae,outBrokenConnections) := matchcontinue(inTable, inConnections, inDae)
    local
      HashTableCG.HashTable table;
      DAE.ComponentRef ref1, ref2;
      DaeEdges tail;
      list<DAE.Element> breakDAE, dae;
      list<tuple<DAE.ComponentRef, DAE.ComponentRef>> broken1,broken2,broken;      

    // empty case
    case(table, {}, dae) then (table, dae, {});
    // normal case
    case(table, ((ref1,ref2,breakDAE)::tail), dae)
      equation
        (table,dae,broken1) = connectComponents(table, ref1, ref2, breakDAE, dae);
        (table,dae,broken2) = addConnections(table, tail, dae);
        broken = listAppend(broken1, broken2);
      then (table,dae,broken);
  end matchcontinue;
end addConnections;

protected function findResultGraph
"Given ConnectionGraph structure, breaks all connections, 
 determines roots and generates a list of dae elements."
  input  ConnectionGraph inGraph;
  input  list<DAE.Element> inDAE;
  input  String modelNameQualified;
  output list<DAE.ComponentRef> outRoots;  
  output list<DAE.Element> outDAE;
  output list<tuple<DAE.ComponentRef, DAE.ComponentRef>> outBrokenConnections;
algorithm
  (outRoots, outDAE, outBrokenConnections) := matchcontinue(inGraph, inDAE, modelNameQualified)
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
      list<tuple<DAE.ComponentRef, DAE.ComponentRef>> broken;
      String brokenConnectsViaGraphViz;
      list<String> userBrokenLst;
      list<list<String>> userBrokenLstLst;
      list<tuple<String,String>> userBrokenTplLst;

    // deal with empty connection graph
    case (GRAPH(_, definiteRoots = {}, potentialRoots = {}, branches = {}, connections = {}), inDAE, modelNameQualified) 
      then ({}, inDAE, {});

    // we have something in the connection graph
    case (GRAPH(_, definiteRoots = definiteRoots, potentialRoots = potentialRoots,
                   branches = branches, connections = connections), inDAE, modelNameQualified)
      equation
        // reverse the conenction list to have them as in the model
        connections = listReverse(connections);
        // add definite roots to the table
        table = resultGraphWithRoots(definiteRoots);
        // add branches to the table
        table = addBranchesToTable(table, branches);
        // order potential roots in the order or priority
        orderedPotentialRoots = Util.sort(potentialRoots, ord);
        
        Debug.fprintln("cgraph", "Ordered Potential Roots: " +& 
          Util.stringDelimitList(Util.listMap(orderedPotentialRoots, printPotentialRootTuple), ", "));
        
        // add connections to the table and return the broken connections
        (table, dae, broken) = addConnections(table, connections, inDAE);
        // create a dummy root
        dummyRoot = ComponentReference.makeCrefIdent("__DUMMY_ROOT", DAE.ET_INT(), {});
        // select final roots
        (table, finalRoots) = addPotentialRootsToTable(table, orderedPotentialRoots, definiteRoots, dummyRoot);
        
        // generate the graphviz representation and display
        // if brokenConnectsViaGraphViz is empty, the user wants to use the current breaking!
        (brokenConnectsViaGraphViz as "") = generateGraphViz(
              modelNameQualified, 
              definiteRoots, 
              potentialRoots,
              branches,
              connections,
              finalRoots,
              broken);
      then 
        (finalRoots, dae, broken);
        
    // we have something in the connection graph
    case (GRAPH(_, definiteRoots = definiteRoots, potentialRoots = potentialRoots,
                   branches = branches, connections = connections), inDAE, modelNameQualified)
      equation
        // reverse the conenction list to have them as in the model
        connections = listReverse(connections);
        // add definite roots to the table
        table = resultGraphWithRoots(definiteRoots);
        // add branches to the table
        table = addBranchesToTable(table, branches);
        // order potential roots in the order or priority
        orderedPotentialRoots = Util.sort(potentialRoots, ord);
        
        Debug.fprintln("cgraph", "Ordered Potential Roots: " +& 
          Util.stringDelimitList(Util.listMap(orderedPotentialRoots, printPotentialRootTuple), ", "));
        
        // add connections to the table and return the broken connections
        (table, dae, broken) = addConnections(table, connections, inDAE);
        // create a dummy root
        dummyRoot = ComponentReference.makeCrefIdent("__DUMMY_ROOT", DAE.ET_INT(), {});
        // select final roots
        (table, finalRoots) = addPotentialRootsToTable(table, orderedPotentialRoots, definiteRoots, dummyRoot);
        
        // generate the graphviz representation and display
        // interpret brokenConnectsViaGraphViz and pass it to the breaking algorithm again
        brokenConnectsViaGraphViz = generateGraphViz(
              modelNameQualified, 
              definiteRoots, 
              potentialRoots,
              branches,
              connections,
              finalRoots,
              broken);
        // graphviz returns the broken connects as: cr1|cr2#cr3|cr4#
        userBrokenLst = Util.stringSplitAtChar(brokenConnectsViaGraphViz, "#");
        userBrokenLstLst = Util.listMap1(userBrokenLst, Util.stringSplitAtChar, "|");
        userBrokenTplLst = makeTuple(userBrokenLstLst);
        Debug.traceln("User selected the following connect edges for breaking:\n\t" +& 
           Util.stringDelimitList(Util.listMap(userBrokenTplLst, printTupleStr), "\n\t"));
        // print("\nBefore ordering:\n");
        printDaeEdges(connections);
        // order the connects with the input given by the user!
        connections = orderConnectsGuidedByUser(connections, userBrokenTplLst);
        // reverse the reverse! uh oh!
        connections = listReverse(connections);
        print("\nAfer ordering:\n");
        // printDaeEdges(connections);
        // call findResultGraph again with ordered connects!
        (finalRoots, dae, broken) = 
           findResultGraph(GRAPH(false, definiteRoots, potentialRoots, branches, connections), 
                           inDAE, modelNameQualified);
      then 
        (finalRoots, dae, broken);
  end matchcontinue;
end findResultGraph;

protected function orderConnectsGuidedByUser
  input DaeEdges inConnections; 
  input list<tuple<String,String>> inUserSelectedBreaking;
  output DaeEdges outOrderedConnections;
algorithm
  outOrderedConnections := matchcontinue(inConnections, inUserSelectedBreaking)
    local 
      String sc1,sc2;
      Exp.ComponentRef c1, c2;
      DaeEdge e;
      list<DAE.Element> els;
      DaeEdges rest, ordered;
      Boolean isUserBroken, b1, b2;
    
    // handle empty case
    case ({}, _) then {};
    // handle match
    case ((e as (c1, c2, els))::rest, inUserSelectedBreaking) 
      equation
        sc1 = Exp.printComponentRefStr(c1);
        sc2 = Exp.printComponentRefStr(c2);
        ordered = orderConnectsGuidedByUser(rest, inUserSelectedBreaking);
        // see both ways!
        b1 = listMember((sc1, sc2), inUserSelectedBreaking);
        b2 = listMember((sc2, sc1), inUserSelectedBreaking);
        true = boolOr(b1, b2);
        // put them at the end to be tried last (more chance to be broken) 
        ordered = listAppend(ordered, {e});
      then
        ordered;
    // handle miss
    case ((e as (c1, c2, els))::rest, inUserSelectedBreaking) 
      equation
        sc1 = Exp.printComponentRefStr(c1);
        sc2 = Exp.printComponentRefStr(c2);
        ordered = orderConnectsGuidedByUser(rest, inUserSelectedBreaking);
        // see both ways        
        b1 = listMember((sc1, sc2), inUserSelectedBreaking);
        b2 = listMember((sc2, sc1), inUserSelectedBreaking);
        false = boolOr(b1, b2);
        // put them at the front to be tried first (less chance to be broken)
        ordered = e::ordered;
      then
        ordered;
  end matchcontinue;
end orderConnectsGuidedByUser;

protected function printTupleStr
  input tuple<String,String> inTpl;
  output String out;
algorithm
  out := matchcontinue(inTpl)
    local 
      String c1,c2;
    case ((c1,c2)) then c1 +& " -- " +& c2;
  end matchcontinue;
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
        Debug.traceln("The following output from GraphViz OpenModelica assistant cannot be parsed:" +&
            Util.stringDelimitList(bad, ", ") +& 
            "\nExpected format from GrapViz: cref1|cref2#cref3|cref4#. Ignoring malformed input.");
        lst = makeTuple(rest);
      then
        lst;
  end matchcontinue;
end makeTuple;

protected function printPotentialRootTuple
  input tuple<DAE.ComponentRef,Real> potentialRoot;
  output String outStr;
algorithm
  outStr := matchcontinue(potentialRoot) 
    local
      DAE.ComponentRef cr;
      Real priority;
      String str;  
    case ((cr, priority))
      equation
        str = Exp.printComponentRefStr(cr) +& "(" +& realString(priority) +& ")";
      then str;
  end matchcontinue;
end printPotentialRootTuple;

protected function evalIsRoot
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
        (outDae, _) = DAEUtil.traverseDAE2(inDae, evalIsRootHelper, inRoots);
      then outDae;
  end matchcontinue;
end evalIsRoot;

protected function evalIsRootHelper
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
        result = Util.listContainsWithCompareFunc(cref, roots, ComponentReference.crefEqual);
        Debug.fprintln("cgraph", "- ConnectionGraph.evalIsRootHelper: " +& 
           Exp.printExpStr(inExp) +& " = " +& Util.if_(result, "true", "false"));
      then (DAE.BCONST(result), roots);
    // deal with NOT Connections.isRoot
    case (DAE.LUNARY(DAE.NOT(), DAE.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")),
          expLst={DAE.CREF(componentRef = cref)})), roots)
      equation
        result = Util.listContainsWithCompareFunc(cref, roots, ComponentReference.crefEqual);
        result = boolNot(result);
        Debug.fprintln("cgraph", "- ConnectionGraph.evalIsRootHelper: " +& 
           Exp.printExpStr(inExp) +& " = " +& Util.if_(result, "true", "false"));
      then (DAE.BCONST(result), roots);
    // no replacement needed
    case (exp, roots)
      equation
        // Debug.fprintln("cgraph", Exp.printExpStr(exp) +& " not found in roots!");
      then (exp, roots);
  end matchcontinue;
end evalIsRootHelper;

protected function printConnectionStr
"prints the connection str"
  input tuple<DAE.ComponentRef, DAE.ComponentRef> connectTuple;
  output String outStr;
algorithm
  outStr := matchcontinue(connectTuple)
    local
      DAE.ComponentRef c1, c2;
      String str;

    case ((c1, c2))
      equation
        str = "BROKEN(" +& 
          Exp.printComponentRefStr(c1) +& 
          ", " +& 
          Exp.printComponentRefStr(c2) +&
          ")";
      then str;
  end matchcontinue;
end printConnectionStr;

protected function printEdges
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

protected function printDaeEdges
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

protected function printConnectionGraph
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

protected function getDefiniteRoots
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

protected function getPotentialRoots
"Accessor for ConnectionGraph.potentialRoots."
  input ConnectionGraph inGraph;
  output list<tuple<DAE.ComponentRef,Real>> outResult;
algorithm
  outResult := matchcontinue(inGraph)
    local list<tuple<DAE.ComponentRef,Real>> result;
    case (GRAPH(_,_,result,_,_)) then result;
  end matchcontinue;
end getPotentialRoots;

protected function getBranches
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

protected function getConnections
"Accessor for ConnectionGraph.connections."
  input ConnectionGraph inGraph;
  output DaeEdges outResult;
algorithm
  outResult := matchcontinue(inGraph)
    local DaeEdges result;
    case (GRAPH(_,_,_,_,result)) then result;
  end matchcontinue;
end getConnections;

protected function removeBrokenConnectionsFromSets
"@author: adrpo
 This function gets a list of connects and the connections sets
 and it will remove all component refences from the connection sets
 that have the origin in the given list of connects."
  input Connect.Sets inSets;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> inBrokenConnects;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(inSets, inBrokenConnects)
    local
      list<Connect.Set> setLst "the connection set";
      list<DAE.ComponentRef> connection "connection_set connect_refs";
      list<DAE.ComponentRef> deletedComponents "list of components with conditional declaration = false";
      list<Connect.OuterConnect> outerConnects "connect statements to propagate upwards";
      list<tuple<DAE.ComponentRef, DAE.ComponentRef>> broken;
      
    case (Connect.SETS(setLst, connection, deletedComponents, outerConnects), broken)
      equation
        setLst = removeBrokenConnectionsFromSetLst(setLst, broken);        
        outerConnects = Util.listSelect1(outerConnects, broken, outerConenctNOTFromConnect);
      then 
        Connect.SETS(setLst, connection, deletedComponents, outerConnects);
  end matchcontinue;
end removeBrokenConnectionsFromSets;

protected function removeBrokenConnectionsFromSetLst
"@author: adrpo
 This function gets a list of connects and the connections sets
 and it will remove all component refences from the connection sets
 that have the origin in the given list of connects."
  input list<Connect.Set> inSetLst;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> inBrokenConnects;
  output list<Connect.Set> outSetLst;
algorithm
  outSetLst := matchcontinue(inSetLst, inBrokenConnects)
    local
      list<Connect.Set> rest, sets;
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> expComponentRefLst;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> tplExpComponentRefFaceLst;
      list<tuple<DAE.ComponentRef, DAE.ComponentRef>> broken;

    // handle empty case
    case ({}, _) then {};

    // handle potential equality
    case (Connect.EQU(expComponentRefLst)::rest, broken)
      equation
        // keep all that did not came from broken connections!
        expComponentRefLst = 
          Util.listSelect1(expComponentRefLst, broken, equNOTFromConnect);
         sets = removeBrokenConnectionsFromSetLst(rest, broken);
      then Connect.EQU(expComponentRefLst)::sets;

    // handle flows
    case (Connect.FLOW(tplExpComponentRefFaceLst)::rest, broken)
      equation  
        // keep all that did not came from broken connections!        
        tplExpComponentRefFaceLst = 
          Util.listSelect1(tplExpComponentRefFaceLst, broken, flowNOTFromConnect);
        sets = removeBrokenConnectionsFromSetLst(rest, broken);
      then Connect.FLOW(tplExpComponentRefFaceLst)::sets;
  end matchcontinue;
end removeBrokenConnectionsFromSetLst;

protected function equNOTFromConnect
"@author: adrpo
  This function returns true if the cref has an element source in the given broken connects"
  input tuple<DAE.ComponentRef, DAE.ElementSource> equConnect;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> inBrokenConnects;
  output Boolean isNotPresent;
algorithm
  isNotPresent := matchcontinue(equConnect, inBrokenConnects)
    local
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectOptLst;
    
    // return true if the origin is not in the broken connects
    case ((_, DAE.SOURCE(connectEquationOptLst = connectOptLst)), inBrokenConnects)
      equation 
        false = elementSourceInBrokenConnects(connectOptLst, inBrokenConnects);
     then true;
    
    // return false if the origin is in the broken connects    
    case ((_, DAE.SOURCE(connectEquationOptLst = connectOptLst)), inBrokenConnects)
      equation 
        true = elementSourceInBrokenConnects(connectOptLst, inBrokenConnects);
     then false;
  end matchcontinue;
end equNOTFromConnect;

protected function flowNOTFromConnect
"@author: adrpo
  This function returns true if the cref has an element source in the given broken connects"
  input tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource> flowConnect;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> inBrokenConnects;
  output Boolean isNotPresent;
algorithm
  isNotPresent := matchcontinue(flowConnect, inBrokenConnects)
    local
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectOptLst;
    
    // return true if the origin is not in the broken connects
    case ((_, _, DAE.SOURCE(connectEquationOptLst = connectOptLst)), inBrokenConnects)
      equation 
        false = elementSourceInBrokenConnects(connectOptLst, inBrokenConnects);
     then true;
    
    // return false if the origin is in the broken connects    
    case ((_, _, DAE.SOURCE(connectEquationOptLst = connectOptLst)), inBrokenConnects)
      equation 
        true = elementSourceInBrokenConnects(connectOptLst, inBrokenConnects);
     then false;
  end matchcontinue;
end flowNOTFromConnect;

protected function outerConenctNOTFromConnect
"@author: adrpo
  This function returns true if the cref has an element source in the given broken connects"
  input Connect.OuterConnect outerConnects;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> inBrokenConnects;
  output Boolean isNotPresent;
algorithm
  isNotPresent := matchcontinue(outerConnects, inBrokenConnects)
    local
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectOptLst;
    
    // return true if the origin is not in the broken connects
    case (Connect.OUTERCONNECT(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), inBrokenConnects)
      equation 
        false = elementSourceInBrokenConnects(connectOptLst, inBrokenConnects);
     then true;
    
    // return false if the origin is in the broken connects    
    case (Connect.OUTERCONNECT(source = DAE.SOURCE(connectEquationOptLst = connectOptLst)), inBrokenConnects)
      equation 
        true = elementSourceInBrokenConnects(connectOptLst, inBrokenConnects);
     then false;
  end matchcontinue;
end outerConenctNOTFromConnect;

protected function elementSourceInBrokenConnects
"@author: adrpo 
  "
  input list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> inBrokenConnects;
  output Boolean presentInBrokenConnects;
algorithm
  presentInBrokenConnects := matchcontinue(connectEquationOptLst, inBrokenConnects)
    local
      list<tuple<DAE.ComponentRef, DAE.ComponentRef>> rest;
      DAE.ComponentRef left, right;
      Boolean b;

    // empty case
    case (connectEquationOptLst, {}) then false;      
    
    // current element is in connection list
    case (connectEquationOptLst, (left, right)::rest)
      equation
        true = isInConnectionList(connectEquationOptLst, left, right);
        // print("Found it!\n"); 
      then true;

    // current element is NOT in connection list
    case (connectEquationOptLst, (left, right)::rest)
      equation
        false = isInConnectionList(connectEquationOptLst, left, right);
        b = elementSourceInBrokenConnects(connectEquationOptLst, rest);
      then b;        
  end matchcontinue;
end elementSourceInBrokenConnects;

public function merge
"merge two ConnectionGraphs"
  input ConnectionGraph inGraph1;
  input ConnectionGraph inGraph2;
  output ConnectionGraph outGraph;
algorithm
  outGraph := matchcontinue(inGraph1, inGraph2)
    local
      Boolean updateGraph, updateGraph1, updateGraph2;
      list<DAE.ComponentRef> definiteRoots, definiteRoots1, definiteRoots2;
      list<tuple<DAE.ComponentRef,Real>> potentialRoots, potentialRoots1, potentialRoots2;
      Edges branches, branches1, branches2;
      DaeEdges connections, connections1, connections2;

    // left is empty, return right
    case (inGraph1, GRAPH(updateGraph = _,definiteRoots = {},potentialRoots = {},branches = {},connections = {}))
      then
        inGraph1;
    
    // right is empty, return left
    case (GRAPH(updateGraph = _,definiteRoots = {},potentialRoots = {},branches = {},connections = {}), inGraph2)
      then
        inGraph2;

    // they are equal, return any
    case (inGraph1, inGraph2)
      equation
        equality(inGraph1 = inGraph2);
      then
        inGraph1;

    // they are NOT equal, merge them
    case (GRAPH(updateGraph = updateGraph1,definiteRoots = definiteRoots1,potentialRoots = potentialRoots1,branches = branches1,connections = connections1), 
          GRAPH(updateGraph = updateGraph2,definiteRoots = definiteRoots2,potentialRoots = potentialRoots2,branches = branches2,connections = connections2))
      equation
        Debug.fprintln("cgraph", "- ConnectionGraph.merge()");
        updateGraph    = boolOr(updateGraph1, updateGraph2);
        definiteRoots  = Util.listUnion(definiteRoots1, definiteRoots2);
        potentialRoots = Util.listUnion(potentialRoots1, potentialRoots2);
        branches       = Util.listUnion(branches1, branches2);
        connections    = Util.listUnion(connections1, connections2);
      then
        GRAPH(updateGraph,definiteRoots,potentialRoots,branches,connections);
  end matchcontinue;
end merge;


/***********************************************************************************************************************/
/******************************************* GraphViz generation *******************************************************/
/***********************************************************************************************************************/

protected function graphVizEdge
  input  Edge inEdge;
  output String out; 
algorithm
  out := matchcontinue(inEdge)
    local DAE.ComponentRef c1, c2; String strEdge;
    case ((c1, c2))
      equation
        strEdge = "\"" +& Exp.printComponentRefStr(c1) +& "\" -- \"" +& Exp.printComponentRefStr(c2) +& "\"" +&
        " [color = blue, dir = \"none\", fontcolor=blue, label = \"branch\"];\n\t";
      then strEdge;
  end matchcontinue;
end graphVizEdge;

protected function graphVizDaeEdge
  input  DaeEdge inDaeEdge;
  input  Edges inBrokenDaeEdges;
  output String out; 
algorithm
  out := matchcontinue(inDaeEdge, inBrokenDaeEdges)
    local DAE.ComponentRef c1, c2; String sc1, sc2, strDaeEdge, label, labelFontSize, decorate, color, style, fontColor; Boolean isBroken;
    case ((c1, c2, _), inBrokenDaeEdges)
      equation
        isBroken = listMember((c1,c2), inBrokenDaeEdges);
        label = Util.if_(isBroken, "[[broken connect]]", "connect");
        color = Util.if_(isBroken, "red", "green");
        style = Util.if_(isBroken, "\"bold, dashed\"", "solid");
        decorate = Util.if_(isBroken, "true", "false");
        fontColor = Util.if_(isBroken, "red", "green");
        labelFontSize = Util.if_(isBroken, "labelfontsize = 20.0, ", "");
        sc1 = Exp.printComponentRefStr(c1);
        sc2 = Exp.printComponentRefStr(c2);
        strDaeEdge = System.stringAppendList({
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
  end matchcontinue;
end graphVizDaeEdge;

protected function graphVizDefiniteRoot
  input  DefiniteRoot  inDefiniteRoot;
  input  DefiniteRoots inFinalRoots;
  output String out; 
algorithm
  out := matchcontinue(inDefiniteRoot, inFinalRoots)
    local DAE.ComponentRef c; String strDefiniteRoot; Boolean isSelectedRoot;
    case (c, inFinalRoots)
      equation
        isSelectedRoot = listMember(c, inFinalRoots);
        strDefiniteRoot = "\"" +& Exp.printComponentRefStr(c) +& "\"" +& 
           " [fillcolor = red, rank = \"source\", label = " +& "\"" +& Exp.printComponentRefStr(c) +& "\", " +&
           Util.if_(isSelectedRoot, "shape=polygon, sides=8, distortion=\"0.265084\", orientation=26, skew=\"0.403659\"", "shape=box") +&           
           "];\n\t";
      then strDefiniteRoot;
  end matchcontinue;
end graphVizDefiniteRoot;

protected function graphVizPotentialRoot
  input  PotentialRoot inPotentialRoot;
  input  DefiniteRoots inFinalRoots;
  output String out; 
algorithm
  out := matchcontinue(inPotentialRoot, inFinalRoots)
    local DAE.ComponentRef c; Real priority; String strPotentialRoot; Boolean isSelectedRoot;
    case ((c, priority), inFinalRoots)
      equation
        isSelectedRoot = listMember(c, inFinalRoots);
        strPotentialRoot = "\"" +& Exp.printComponentRefStr(c) +& "\"" +&  
           " [fillcolor = orangered, rank = \"min\" label = " +& "\"" +& Exp.printComponentRefStr(c) +& "\\n" +& realString(priority) +& "\", " +&
           Util.if_(isSelectedRoot, "shape=ploygon, sides=7, distortion=\"0.265084\", orientation=26, skew=\"0.403659\"", "shape=box") +&  
           "];\n\t";
      then strPotentialRoot;
  end matchcontinue;
end graphVizPotentialRoot;

protected function generateGraphViz
"@author: adrpo
  Generate a graphviz file out of the connection graph"
  input String modelNameQualified;
  input list<DAE.ComponentRef> definiteRoots;
  input list<tuple<DAE.ComponentRef,Real>> potentialRoots;
  input Edges branches;
  input DaeEdges connections;
  input list<DAE.ComponentRef> finalRoots;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> broken;
  output String brokenConnectsViaGraphViz;
algorithm
  brokenConnectsViaGraphViz := matchcontinue(modelNameQualified, definiteRoots, potentialRoots, branches, connections, finalRoots, broken)
    local
      String fileName, i, nrDR, nrPR, nrBR, nrCO, nrFR, nrBC, timeStr, leftyCMD, infoNodeStr, brokenConnects;
      Real tStart, tEnd, t;
      IOStream.IOStream graphVizStream;
      Integer leftyExitStatus;
      list<String> infoNode; 
    
    // don't do anything if we don't have +d=cgraphGraphVizFile or +d=cgraphGraphVizShow
    case(modelNameQualified, definiteRoots, potentialRoots, branches, connections, finalRoots, broken)
      equation
        false = boolOr(RTOpts.debugFlag("cgraphGraphVizFile"), RTOpts.debugFlag("cgraphGraphVizShow"));
      then
        "";
      
    case(modelNameQualified, definiteRoots, potentialRoots, branches, connections, finalRoots, broken)
      equation
        tStart = clock();
        i = "\t"; 
        fileName = stringAppend(modelNameQualified, ".gv");
        // create a stream
        graphVizStream = IOStream.create(fileName, IOStream.LIST());
        nrDR = intString(listLength(definiteRoots));
        nrPR = intString(listLength(potentialRoots));
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
          "//   Branches:           ", nrBR, "\n",
          "//   Connections:        ", nrCO, "\n",
          "//   Final Roots:        ", nrFR, "\n",
          "//   Broken Connections: ", nrBC, "\n"
        };
        infoNodeStr = System.stringAppendList(infoNode);
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
        graphVizStream = IOStream.appendList(graphVizStream, {i, "ovelap=false;\n"});
        graphVizStream = IOStream.appendList(graphVizStream, {i, "layout=dot;\n\n"});        
         
        // output settings for nodes
        graphVizStream = IOStream.appendList(graphVizStream, {i, "node [\n", i, 
           "fillcolor = \"lightsteelblue1\"\n",i, 
           "shape = box\n",i, 
           "style = \"bold, filled\"\n",i,
           "rank = \"max\"",
           i, "]\n\n"});
        // output settings for edges
        graphVizStream = IOStream.appendList(graphVizStream, {i, "edge [\n", i, 
           "color = \"black\"\n", i, 
           "style = bold\n", i,
           "]\n\n"});
        
        // output summary node
        graphVizStream = IOStream.appendList(graphVizStream, {i, "graph [fontsize=20, fontname = \"Courier Bold\" label= \"\\n\\n", infoNodeStr, "\", size=\"6,6\"];\n", i});        
        
        // output definite roots
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Definite Roots (Connections.root)", "\n", i});        
        graphVizStream = IOStream.appendList(graphVizStream, Util.listMap1(definiteRoots, graphVizDefiniteRoot, finalRoots));
        // output potential roots
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Potential Roots (Connections.potentialRoot)", "\n", i});        
        graphVizStream = IOStream.appendList(graphVizStream, Util.listMap1(potentialRoots, graphVizPotentialRoot, finalRoots));        

        // output branches        
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Branches (Connections.branch)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, Util.listMap(branches, graphVizEdge));
        
        // output connections
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Connections (connect)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, Util.listMap1(connections, graphVizDaeEdge, broken));
        
        // output graphviz footer
        graphVizStream = IOStream.appendList(graphVizStream, {"\n}\n"});
        tEnd = clock();
        t = tEnd -. tStart;
        timeStr = realString(t);
        graphVizStream = IOStream.appendList(graphVizStream, {"\n\n\n// graph generation took: ", timeStr, " seconds\n"});
        System.writeFile(fileName, IOStream.string(graphVizStream));
        Debug.traceln("GraphViz with connection graph for model: " +& modelNameQualified +& " was writen to file: " +& fileName);
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
    case (fileNameGraphViz, modelNameQualified)
      equation
        false = RTOpts.debugFlag("cgraphGraphVizShow");
      then
        "";
        
    case (fileNameGraphViz, modelNameQualified)
      equation
        fileNameTraceRemovedConnections = modelNameQualified +& "_removed_connections.txt";  
        Debug.traceln("Tyring to start GraphViz *lefty* to visualize the graph. You need to have lefty in your PATH variable");
        Debug.traceln("Make sure you quit GraphViz *lefty* via Right Click->quit to be sure the process will be exited.");
        Debug.traceln("If you quit the GraphViz *lefty* window via X, please kill the process in task manager to continue.");
        omhome = Settings.getInstallationDirectoryPath();
        omhome = System.stringReplace(omhome, "\"", "");
        // omhome = System.stringReplace(omhome, "\\", "/");
        
        // create a lefty command and execute it
        leftyCMD = "load('" +& omhome +& "/share/omc/scripts/openmodelica.lefty');" +& "openmodelica.init();openmodelica.createviewandgraph('" +& 
            fileNameGraphViz +& "','file',null,null);txtview('off');";
        Debug.traceln("Running command: " +& "lefty -e " +& leftyCMD +& " > " +& fileNameTraceRemovedConnections);
        // execute lefty
        leftyExitStatus = System.systemCall("lefty -e " +& leftyCMD +& " > " +& fileNameTraceRemovedConnections);
        // show the exit status
        Debug.traceln("GraphViz *lefty* exited with status:" +& intString(leftyExitStatus));
        brokenConnects = System.readFile(fileNameTraceRemovedConnections);
        Debug.traceln("GraphViz OpenModelica assistant returned the following broken connects: " +& brokenConnects);
      then 
        brokenConnects;
  end matchcontinue;
end showGraphViz;
  
end ConnectionGraph;

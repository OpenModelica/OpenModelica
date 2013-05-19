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

encapsulated package FGraphDump
" file:        FGraphDump.mo
  package:     FGraphDump
  description: A graph for instantiation

  RCS: $Id: FGraphDump.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module builds a graph out of SCode 
"

public import Absyn;
public import SCode;
public import Util;
public import FNode;
public import DAE;
public import FGraph;

public type Ident = FNode.Ident;
public type NodeId = FNode.NodeId;
public type Name = FNode.Name;
public type Type = DAE.Type;
public type Types = list<DAE.Type>;
public type Node = FNode.Node; 
public type NodeData = FNode.NodeData;
public type Graph = FGraph.Graph;

protected import System;
protected import List;
protected import Flags;
protected import Error;
protected import Dump;
protected import GraphML;

public function dumpGraph
  input Graph inGraph;
  input String fileName;
  input NodeId inNodeId "start with this node forward";
algorithm  
  _ := matchcontinue(inGraph, fileName, inNodeId)
    local
      GraphML.Graph g;
      FGraph.AvlTree nodes;
      list<FNode.Node> nlist;
    
    case (_, _, _)
      equation
        false = Flags.isSet(Flags.GEN_GRAPH());
      then
        ();
    
    case (FGraph.G(nodes = nodes), _, _)
      equation
        g = GraphML.getGraph("G", false);
        nlist = FGraph.getNodes(SOME(nodes), {});
        g = addNodes(g, nlist, inGraph, inNodeId);
        print("Dumping graph file: " +& fileName +& " ....\n");
        GraphML.dumpGraph(g, fileName);
        print("Dumped\n");
      then
        ();
  
  end matchcontinue;
end dumpGraph;

protected function addNodes
  input GraphML.Graph gin;
  input list<Node> nodes;
  input Graph inGraph;
  input NodeId inNodeId "start with this node forward";
  output GraphML.Graph gout;
algorithm
  gout := matchcontinue(gin, nodes, inGraph, inNodeId)
    local 
      GraphML.Graph g;
      list<Node> rest;
      Node n;
      NodeId id;
    
    case (_, {}, _, _) then gin;
        
    // skip all less than inNodeId!
    case (g, FNode.N(id=id)::rest, _, _)
      equation
        false = intLt(id, 0);
        true = FGraph.keyCompare(id, inNodeId) <= 0;
        g = addNodes(g, rest, inGraph, inNodeId);
      then
        g;

    case (g, n::rest, _, _)
      equation
        g = addNode(g, n, inGraph);
        g = addNodes(g, rest, inGraph, inNodeId);
      then
        g;
  
  end matchcontinue;
end addNodes;

protected function addNode
  input GraphML.Graph gin;
  input Node node;
  input Graph inGraph;
  output  GraphML.Graph gout;
algorithm
  gout := matchcontinue(gin, node, inGraph)
    local 
      GraphML.Graph g;
      FNode.AvlTree kids;
      NodeId id, pid;
      Name n;
      NodeData nd;
      String nds;
      String color;
      GraphML.ShapeType shape;
    
    case (g, FNode.N(id, pid, n, kids, nd), _)
      equation
        (color, shape, nds) = graphml(node);
        g = GraphML.addNode("n" +& FGraph.keyToStr(id), nds +& ": " +& n, color,shape, g);
        g = GraphML.addEgde("e" +& FGraph.keyToStr(id), "n" +& FGraph.keyToStr(id), "n" +& FGraph.keyToStr(pid), GraphML.COLOR_BLACK,GraphML.LINE(),NONE(),(NONE(),NONE()),g);
      then
        g;
          
  end matchcontinue;
end addNode;

protected function graphml
  input Node node;
  output String color;
  output GraphML.ShapeType shape;
  output String name;
algorithm
  (color, shape, name) := matchcontinue(node)
    local
      FNode.AvlTree kids;
      NodeId id, pid;
      Name n;
      NodeData nd;
      SCode.Element e;
    
    // redeclare class
    case (FNode.N(id, pid, n, kids, nd as FNode.CL(e = e)))
      equation
        true = SCode.isElementRedeclare(e); 
      then 
        (GraphML.COLOR_YELLOW, GraphML.HEXAGON(), "RDCL");
    
    // replaceable class
    case (FNode.N(id, pid, n, kids, nd as FNode.CL(e = e)))
      equation
        true = SCode.isElementReplaceable(e); 
      then 
        (GraphML.COLOR_RED, GraphML.RECTANGLE(), "RPCL");
    
    // redeclare component
    case (FNode.N(id, pid, n, kids, nd as FNode.CO(e = e)))
      equation
        true = SCode.isElementRedeclare(e); 
      then 
        (GraphML.COLOR_YELLOW, GraphML.ELLIPSE(), "RDCO");
    
    // replaceable component
    case (FNode.N(id, pid, n, kids, nd as FNode.CO(e = e)))
      equation
        true = SCode.isElementReplaceable(e); 
      then 
        (GraphML.COLOR_RED, GraphML.ELLIPSE(), "RPCO");
    
    // class
    case (FNode.N(id, pid, n, kids, nd as FNode.CL(e = _))) then (GraphML.COLOR_GRAY, GraphML.RECTANGLE(), "CL");
    // component
    case (FNode.N(id, pid, n, kids, nd as FNode.CO(e =_ ))) then (GraphML.COLOR_WHITE, GraphML.ELLIPSE(), "CO");
    // extends
    case (FNode.N(id, pid, n, kids, nd as FNode.EX(e = _))) then (GraphML.COLOR_GREEN, GraphML.ROUNDRECTANGLE(), "EX");
    // enum
    case (FNode.N(id, pid, n, kids, nd as FNode.EN(_))) then (GraphML.COLOR_BLUE, GraphML.ELLIPSE(), "EN");
    // import
    case (FNode.N(id, pid, n, kids, nd as FNode.IM(e = _))) then (GraphML.COLOR_BLUE, GraphML.ELLIPSE(), "IM");
    // all others
    case (FNode.N(id, pid, n, kids, nd)) then (GraphML.COLOR_BLUE, GraphML.ELLIPSE(), FNode.nodeDataStr(nd));
  end matchcontinue;
end graphml;

end FGraphDump;

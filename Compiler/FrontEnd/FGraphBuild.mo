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

encapsulated package FGraphBuild
" file:        FGraphBuild.mo
  package:     FGraphBuild
  description: A node builder for Modelica constructs  

  RCS: $Id: FGraphBuild.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module builds nodes out of SCode 
"

public import Absyn;
public import SCode;
public import Util;
public import FGraph;
public import FNode;
public import DAE;

type Graph    = FGraph.Graph;
type Node     = FGraph.Node;
type NodeId   = FGraph.NodeId;
type Name     = FGraph.Name;
type NodeData = FGraph.NodeData;

protected import System;
protected import List;
protected import Flags;
protected import Dump;
protected import SCodeDump;
protected import FRef;

public function mkProgramGraph
"builds nodes out of classes"
  input SCode.Program inProgram;
  input NodeId inParentId;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  System.startTimer();
  outGraph := List.fold1(inProgram, mkClassGraph, inParentId, inGraph);
  System.stopTimer();
  print("FGraphBuild.mkProgramGraph took: " +& realString(System.getTimerIntervalTime()) +& " seconds. Nodes: " +& FGraph.keyToStr(FGraph.getLastNodeId(outGraph)) +& "\n");
end mkProgramGraph;

protected function mkClassGraph
"Extends the graph with a class."
  input SCode.Element inClass;
  input NodeId inParentId;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inClass, inParentId, inGraph)
    local
      String name;
      Graph graph;
      SCode.ClassDef cdef;
      Absyn.Info info;

    // class (we don't care here if is replaceable or not we can get that from the class)
    case (SCode.CLASS(name = name, classDef = cdef), _, _)
      equation
        graph = mkClassNode(inClass, inParentId, inGraph);
      then
        graph;
  
  end match;
end mkClassGraph;

public function mkClassNode
  input SCode.Element inClass;
  input NodeId inParentId;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inClass, inParentId, inGraph)
    local
      SCode.ClassDef cdef;
      SCode.Element cls;
      String name;
      Graph graph;
      Node pnode, cnode;
      Absyn.Info info;
    
    case (_, _, _)
      equation
        SCode.CLASS(name = name, classDef = cdef, info = info) = inClass;
        (graph, cnode) = FGraph.mkChildNode(inGraph, name, inParentId, FNode.CL(inClass,{},{}));
        graph = mkClassChildren(cdef, FNode.getNodeId(cnode), graph);
      then
        graph;
  
  end matchcontinue;
end mkClassNode;

protected function mkClassChildren
"Extends the graph with a class's components."
  input SCode.ClassDef inClassDef;
  input NodeId inParentId;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inClassDef, inParentId, inGraph)
    local
      list<SCode.Element> el;
      list<SCode.Enum> enums;
      Absyn.TypeSpec ts;
      SCode.Mod mods;
      Absyn.Path path;
      Graph graph;
      Node pnode, enode, rnode, mnode, unode;
      Name name;
      SCode.Element c;
      NodeData nd;

    case (SCode.PARTS(elementLst = el), _, _)
      equation
        graph = List.fold1(el, mkElementNode, inParentId, inGraph);
      then
        graph;

    case (SCode.DERIVED(typeSpec = ts, modifications = mods), _, _)
      equation
        // make a class out of derived
        c = SCode.CLASS(
               "$derived", 
               SCode.defaultPrefixes, 
               SCode.NOT_ENCAPSULATED(),
               SCode.NOT_PARTIAL(),
               SCode.R_CLASS(),
               inClassDef,
               SCode.noComment,
               Absyn.dummyInfo);
        // the derived is saved as an extends child inside FNode.CL.exts
        name = Absyn.refString(Absyn.RTS(ts));
        (graph, enode) = FGraph.mkNode(inGraph, name, inParentId, FNode.EX(c));
        pnode = FGraph.getNode(graph, inParentId); 
        pnode = FNode.addExtendsIds(pnode, FNode.getNodeId(enode));
        graph = FGraph.setNode(graph, inParentId, pnode);
      then
        graph;

    case (SCode.ENUMERATION(enumLst = enums), _, _)
      equation
        graph = List.fold1(enums, mkEnumNode, inParentId, inGraph);
      then
        graph;

    else inGraph;
  end match;
end mkClassChildren;

public function mkEnumNode
  input SCode.Enum inEnum;
  input NodeId inParentId;
  input Graph inGraph;
  output Graph outGraph;
protected
  String name;
  Graph graph;
  Node pnode, cnode;
algorithm
  SCode.ENUM(literal = name) := inEnum;
  (graph, cnode) := FGraph.mkChildNode(inGraph, name, inParentId, FNode.EN(inEnum));
  outGraph := graph;
end mkEnumNode;

public function mkElementNode
"Extends the graph with an element."
  input SCode.Element inElement;
  input NodeId inParentId;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inElement, inParentId, inGraph)
    local
      Graph graph;
      SCode.Ident name;
      Absyn.Path p;
      Node pnode, enode, inode, unode;
      Absyn.TypeSpec ts;
      NodeData nd;

    // component
    case (SCode.COMPONENT(name = _), _, _)
      equation
        graph = mkCompNode(inElement, inParentId, inGraph);
      then
        graph;

    // class
    case (SCode.CLASS(name = _), _, _)
      equation
        graph = mkClassNode(inElement, inParentId, inGraph);
      then
        graph;

    case (SCode.EXTENDS(baseClassPath = p), _, _)
      equation
        // the extends is saved inside the node data FNode.CL.exts
        ts = Absyn.TPATH(p, NONE());
        name = Absyn.refString(Absyn.RTS(ts));
        (graph, enode) = FGraph.mkNode(inGraph, name, inParentId, FNode.EX(inElement));
        pnode = FGraph.getNode(graph, inParentId); 
        pnode = FNode.addExtendsIds(pnode, FNode.getNodeId(enode));
        graph = FGraph.setNode(graph, inParentId, pnode);
      then
        graph;

    case (SCode.IMPORT(imp = _), _, _)
      equation
        // the import is saved as a child in the parent class in FNode.CL.imps as it does not have a name
        name = SCodeDump.unparseElementStr(inElement);
        (graph, inode) = FGraph.mkNode(inGraph, name, inParentId, FNode.IM(inElement));
        pnode = FGraph.getNode(graph, inParentId); 
        pnode = FNode.addImportIds(pnode, FNode.getNodeId(inode));
        graph = FGraph.setNode(graph, inParentId, pnode);
      then
        graph;

    case (SCode.DEFINEUNIT(name = name), _, _)
      equation
        // the define unit is saved as a child with its name
        (graph, enode) = FGraph.mkChildNode(inGraph, name, inParentId, FNode.DU(inElement));
      then 
        graph;

  end matchcontinue;
end mkElementNode;

public function mkCompNode
"Extends the graph with a component"
  input SCode.Element inComp;
  input NodeId inParentId;
  input Graph inGraph;
  output Graph outGraph;
protected
  String name;
  Graph graph;
  Node pnode, cnode;
algorithm
  SCode.COMPONENT(name = name) := inComp;
  (graph, cnode) := FGraph.mkChildNode(inGraph, name, inParentId, FNode.CO(inComp));
  outGraph := graph;
end mkCompNode;

public function mkRefNode
  input NodeData inRef;
  input NodeId inParentId;
  input Graph inGraph;
  output Graph outGraph;
protected
  String name;
  Graph graph;
  Node pnode, cnode;
algorithm
  name := FNode.refName(inRef);
  (graph, cnode) := FGraph.mkChildNode(inGraph, name, inParentId, inRef);
  outGraph := graph;
end mkRefNode;

public function mkTypeNode
  input DAE.Type inType "the type to add";
  input Name inName "name to search for";
  input NodeId inParentId "where to start the search for the name";
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inType, inName, inParentId, inGraph)
    local
      SCode.ClassDef cdef;
      SCode.Element cls;
      Graph graph;
      Node pnode, cnode, tnode;
      NodeId id, pid;
      Name name;
      FNode.AvlTree children;
      FGraph.Types tys;
    
    case (_, _, _, _) then inGraph;
    
    // type node present, update
    case (_, _, _, _)
      equation
        // search in the parent node for a child with name inName
        cnode = FGraph.getChild(inGraph, inParentId, inName);
        // see if we don't have already a type child
        tnode = FGraph.getChild(inGraph, FNode.getNodeId(cnode), FNode.tyNodeName);
        // we do have it
        FNode.N(id, pid, name, children, FNode.TY(tys)) = tnode;
        // update the child
        tnode = FNode.N(id, pid, name, children, FNode.TY(inType::tys));
        graph = FGraph.addNodeChild(inGraph, id, tnode, FNode.tyNodeName);
      then
        graph;
    
    // type node not present, add
    case (_, _, _, _)
      equation
        // search in the parent node for a child with name inName
        cnode = FGraph.getChild(inGraph, inParentId, inName);
        // see if we don't have already a type child
        failure(_ = FGraph.getChild(inGraph, FNode.getNodeId(cnode), FNode.tyNodeName));
        // add it
        (graph, cnode) = FGraph.mkChildNode(inGraph, FNode.tyNodeName, FNode.getNodeId(cnode), FNode.TY({inType}));
      then
        graph;
    
    // name node not present, add the type directly in parentId
    case (_, _, _, _)
      equation
        // search in the parent node for a child with name inName
        failure(_ = FGraph.getChild(inGraph, inParentId, inName));
        // add it
        (graph, cnode) = FGraph.mkChildNode(inGraph, inName, inParentId, FNode.TY({inType}));
      then
        graph;
    
    // name node present, add the type directly to it if is a type
    case (_, _, _, _)
      equation
        // search in the parent node for a child with name inName
        FNode.N(id, pid, name, children, FNode.TY(tys)) = FGraph.getChild(inGraph, inParentId, inName);
        // update the child
        tnode = FNode.N(id, pid, name, children, FNode.TY(inType::tys));
        graph = FGraph.addNodeChild(inGraph, id, tnode, FNode.tyNodeName);
      then
        graph;
    
    else
      equation
        print("FGraphBuild.mkTypeNode: Error making type node: " +& inName +& " in parent: " +& FGraph.keyToStr(inParentId) +& "\n");
      then
        fail();
  
  end matchcontinue;
end mkTypeNode;

end FGraphBuild;

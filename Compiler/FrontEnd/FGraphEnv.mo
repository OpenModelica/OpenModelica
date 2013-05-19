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

encapsulated package FGraphEnv
" file:        FGraphEnv.mo
  package:     FGraphEnv
  description: A graph for instantiation

  RCS: $Id: FGraphEnv.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module builds a graph out of SCode 
"

public import Absyn;
public import SCode;
public import Util;
public import FGraph;
public import FNode;
public import DAE;

public type Ident = FGraph.Ident;
public type NodeId = FGraph.NodeId;
public type Name = FGraph.Ident;
public type Graph = FGraph.Graph;
public type Node = FGraph.Node;
public type Scope = list<NodeId>;

public constant Env emptyEnv = ENV({}, FGraph.emptyGraph, FNode.topNodeId);

public uniontype Env
  record ENV
    Scope scope        "flattening scope;
                        note that you only need one nodeId to find out where 
                        you are via the parent relationship saved in the graph;
                        this scope tells you how the instantiation progresses
                        jumping from one node to another when for example 
                        following the type of a component or an extends, etc.";
    
    FGraph.Graph graph "the graph with all the SCode nodes plus their relationships;
                        note that no information is ever removed from the graph,
                        only added, i.e. redeclares are not applied anywhere,
                        simply a new node is created that points to the old one
                        and to the new one plus the modifications";
    
    NodeId builtinMark "the last node added that is builtin. call setBuiltinMark after loading all the builtins";
  end ENV;
end Env;

protected import FGraphBuild;
protected import List;

public function openScope
  input NodeId inNodeId;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inNodeId, inEnv)
    local
      Env env;
      Scope scope;
      Graph graph;
      NodeId bm;
      
    case (_, _)
      equation
        ENV(scope, graph, bm) = inEnv;
        // check that we have the node in the graph!
        _ = FGraph.getNode(graph, inNodeId);
        // add it to the front of the list
        env = ENV(inNodeId::scope, graph, bm);
      then
        env;
    
  end matchcontinue;
end openScope;

public function closeScope
  input NodeId inNodeId;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inNodeId, inEnv)
    local
      Env env;
      Scope scope;
      Graph graph;
      NodeId bm, i;
      
    case (_, _)
      equation
        ENV(scope, graph, bm) = inEnv;
        // check that we have the node in the graph!
        _ = FGraph.getNode(graph, inNodeId);
        i::scope = scope; 
        // add it to the front of the list
        env = ENV(scope, graph, bm);
      then
        env;
    
  end matchcontinue;
end closeScope;

public function extendEnvWithProgram
  input SCode.Program inProgram;
  input NodeId inParentId;
  input Env inEnv;
  output Env outEnv;
protected
  Scope s;
  Graph g;
  NodeId b;   
algorithm
  ENV(s, g, b) := inEnv;
  g := FGraphBuild.mkProgramGraph(inProgram, inParentId, g);
  outEnv := ENV(s, g, b);
end extendEnvWithProgram;

public function extendEnvWithComponent
  input SCode.Element inElement;
  input NodeId inParentId;
  input Env inEnv;
  output Env outEnv;
protected
  Scope s;
  Graph g;
  NodeId b;   
algorithm
  ENV(s, g, b) := inEnv;
  g := FGraphBuild.mkCompNode(inElement, inParentId, g);
  outEnv := ENV(s, g, b);
end extendEnvWithComponent;

public function extendEnvWithType
  input DAE.Type inType "the type to add";
  input Name inName "name to search for. if not found in the graph we add it as a child of inParentId";
  input NodeId inParentId "where to start the search for the name";
  input Env inEnv;
  output Env outEnv;
protected
  Scope s;
  Graph g;
  NodeId b;
algorithm
  ENV(s, g, b) := inEnv;
  g := FGraphBuild.mkTypeNode(inType, inName, inParentId, g);
  outEnv := ENV(s, g, b);
end extendEnvWithType;

public function setBuiltinMark
  input Env inEnv;
  output Env outEnv;
protected
  Scope s;
  Graph g;
  NodeId b;   
algorithm
  ENV(s, g, _) := inEnv;
  b := FGraph.getLastNodeId(g);
  outEnv := ENV(s, g, b);
end setBuiltinMark;

public function getGraph
  input Env inEnv;
  output Graph outGraph;
algorithm
  ENV(graph = outGraph) := inEnv;
end getGraph;

public function getScope
  input Env inEnv;
  output Scope outScope;
algorithm
  ENV(scope = outScope) := inEnv;
end getScope;

public function getScopeHead
  input Env inEnv;
  output NodeId outId;
algorithm
  ENV(scope = outId::_) := inEnv;
end getScopeHead;

public function getNode
  input Env inEnv;
  input NodeId inNodeId;
  output Node outNode;
protected
  Graph g;
algorithm
  ENV(graph = g) := inEnv;
  outNode := FGraph.getNode(g, inNodeId);
end getNode;

public function setGraph
  input Env inEnv;
  input Graph inGraph;
  output Env outEnv;
protected
  Scope s;
  Graph g;
  NodeId b;   
algorithm
  ENV(s, _, b) := inEnv;
  outEnv := ENV(s, inGraph, b);
end setGraph;

public function setScope
  input Env inEnv;
  input Scope inScope;
  output Env outEnv;
protected
  Scope s;
  Graph g;
  NodeId b;   
algorithm
  ENV(_, g, b) := inEnv;
  outEnv := ENV(inScope, g, b);
end setScope;

public function name
  input Env inEnv;
  output String str;
protected
  Scope s;
  Graph g;
  list<Node> ns;
algorithm
  ENV(scope = s, graph = g) := inEnv;
  ns := List.map1r(s, FGraph.getNode, g);
  str := stringDelimitList(List.map(ns, FNode.getNodeIdName), "/"); 
end name;

end FGraphEnv;

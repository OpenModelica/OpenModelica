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

encapsulated package FGraph
" file:        FGraph.mo
  package:     FGraph
  description: Graph of program

  RCS: $Id: FGraph.mo 19292 2014-02-25 06:23:22Z adrpo $

"

// public imports
public
import Absyn;
import FCore;
import FNode;
import FVisit;

protected
import System;
import Debug;
import FGraphStream;

public
type Name = FCore.Name;
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Data = FCore.Data;
type Kind = FCore.Kind;
type Ref = FCore.Ref;
type Refs = FCore.Refs;
type Children = FCore.Children;
type Parents = FCore.Parents;
type Graph = FCore.Graph;
type Extra = FCore.Extra;
type Visited = FCore.Visited;

public function top
"get the top node ref from the graph"
  input Graph inGraph;
  output Ref outRef;
algorithm
  FCore.G(top = outRef) := inGraph;
end top;

public function extra
"get the extra from the graph"
  input Graph inGraph;
  output Extra outExtra;
algorithm
  FCore.G(extra = outExtra) := inGraph;
end extra;

public function visited
"get the visited info from the graph"
  input Graph inGraph;
  output Visited outVisited;
algorithm
  FCore.G(visited = outVisited) := inGraph;
end visited;

public function new
"make a new graph"
  input Absyn.Path path;
  output Graph outGraph;
protected
  Node n;
  Visited v;
  Ref nr;
  Next next;
algorithm
  n := FNode.new(".", FCore.firstId, {}, FCore.TOP());
  nr := FNode.toRef(n);
  v := FVisit.new();
  next := FCore.firstId;
  outGraph := FCore.G(nr,v,FCore.EXTRA(path),next);
end new;

public function visit
"@autor: adrpo
 add the node to visited"
  input Graph inGraph;
  input Ref inRef;
  output Graph outGraph;
protected
  Ref t;
  Visited v;
  Extra e;
  Next next;
algorithm
  FCore.G(t, v, e, next) := inGraph;
  v := FVisit.visit(v, inRef);
  outGraph := FCore.G(t, v, e, next);
end visit;

public function nextId
  input Graph inGraph;
  output Graph outGraph;
  output Id id;
protected
  Ref top;
  Visited visited;
  Extra extra;
  Next next;
algorithm
  FCore.G(top = top, visited = visited, extra = extra, next = next) := inGraph;
  id := next;
  next := FCore.next(next);
  outGraph := FCore.G(top, visited, extra, next);
end nextId;

public function lastId
"get the last id from the graph"
  input Graph graph;
  output Next next;
algorithm
  FCore.G(next = next) := graph;
end lastId;

public function node
"make a new node in the graph"
  input Graph inGraph;
  input Name inName;
  input Parents inParents;
  input Data inData;
  output Graph outGraph;
  output Node outNode;
algorithm
  (outGraph, outNode) := match(inGraph, inName, inParents, inData)
    local
      Integer i;
      Boolean b;
      Id id;
      Graph g;
      Node n;

    case (g, _, _, _)
      equation
        (g, id) = nextId(g);
        n = FNode.new(inName, id, inParents, inData);
        FGraphStream.node(n);
        // uncomment this if unique node id's are not unique!
        /*
        i = System.tmpTickIndex(21);
        b = (id == i);
        Debug.bcall1(not b, print, "Next: " +& intString(id) +& " <-> " +& intString(i) +& " node: " +& FNode.toStr(n) +& "\n");
        true = b;
        */
     then
       (g, n);

  end match;
end node;

end FGraph;

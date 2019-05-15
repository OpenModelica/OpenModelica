

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

encapsulated package FGraphStream
" file:        FGraphStream.mo
  package:     FGraphStream
  description: FGraphStream deals with visualizaion of the node using GraphStream


"

// public imports
public
import FCore;
import FNode;

protected
import Flags;
import GraphStream;
import FGraphDump;
import Values;

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


public function start
algorithm
  if Flags.isSet(Flags.GRAPH_INST_SHOW_GRAPH) then
    GraphStream.startExternalViewer("localhost", 2001);
    GraphStream.newStream("default", "localhost", 2001, false);
    GraphStream.addGraphAttribute("default", "omc", -1, "stylesheet", Values.STRING("node{fill-mode:plain;fill-color:#567;size:6px;}"));
    // GraphStream.addGraphAttribute("default", "omc", -1, "ui.antialias", Values.BOOL(true));
    // GraphStream.addGraphAttribute("default", "omc", -1, "layout.stabilization-limit", Values.INTEGER(0));
  end if;
end start;

public function finish
algorithm
  if Flags.isSet(Flags.GRAPH_INST_SHOW_GRAPH) then
    GraphStream.cleanup();
  end if;
end finish;


public function node
  input Node n;
algorithm
  _ := matchcontinue(n)
    local
      String color, nds, id;

    case (_)
      equation
        true = Flags.isSet(Flags.GRAPH_INST_SHOW_GRAPH);
        // filter basic types, builtins and things in sections, modifers or dimensions
        false = FNode.isBasicType(n);
        false = FNode.isIn(n, FNode.isRefBasicType);

        false = FNode.isBuiltin(n);
        false = FNode.isIn(n, FNode.isRefBuiltin);

        false = FNode.isIn(n, FNode.isRefSection);
        false = FNode.isIn(n, FNode.isRefMod);
        false = FNode.isIn(n, FNode.isRefDims);

        id = intString(FNode.id(n));
        (_, _, nds) = FGraphDump.graphml(n, false);
        GraphStream.addNode("default", "omc", -1, id);
        GraphStream.addNodeAttribute("default", "omc", -1, id, "ui.label", Values.STRING(nds));
      then
        ();

    else ();

  end matchcontinue;
end node;

public function edge
  input Name name;
  input Node source;
  input Node target;
algorithm
  _ := matchcontinue(name, source, target)

    case (_, _, _)
      equation
        true = Flags.isSet(Flags.GRAPH_INST_SHOW_GRAPH);

        // filter basic types, builtins and things in sections, modifers or dimensions
        false = FNode.isBasicType(source);
        false = FNode.isBasicType(target);
        false = FNode.isIn(source, FNode.isRefBasicType);
        false = FNode.isIn(target, FNode.isRefBasicType);

        false = FNode.isBuiltin(source);
        false = FNode.isBuiltin(target);
        false = FNode.isIn(source, FNode.isRefBuiltin);
        false = FNode.isIn(target, FNode.isRefBuiltin);

        false = FNode.isIn(source, FNode.isRefSection);
        false = FNode.isIn(source, FNode.isRefMod);
        false = FNode.isIn(source, FNode.isRefDims);
        false = FNode.isIn(target, FNode.isRefSection);
        false = FNode.isIn(target, FNode.isRefMod);
        false = FNode.isIn(target, FNode.isRefDims);

        GraphStream.addEdge("default", "omc", -1, intString(FNode.id(source)), intString(FNode.id(target)), false);
        GraphStream.addEdgeAttribute("default", "omc", -1, intString(FNode.id(source)), intString(FNode.id(target)), "ui.label", Values.STRING(name));
      then
        ();

    else ();

  end matchcontinue;
end edge;


annotation(__OpenModelica_Interface="frontend");
end FGraphStream;

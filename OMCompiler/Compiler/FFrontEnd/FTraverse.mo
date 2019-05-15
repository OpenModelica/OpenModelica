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

encapsulated package FTraverse
" file:        FTraverse.mo
  package:     FTraverse
  description: Graph of program management


"

// public imports
public import Absyn;
public import FNode;
public import FVisit;
public import FGraph;

// protected imports
protected

public
type Ident = String " An identifier is just a string " ;
type Import = Absyn.Import;

type Node = FNode.Node;
type Ref = FNode.Ref;
type Data = FNode.Data;
type Visited = FVisit.Visited;
type Graph = FGraph.Graph;

replaceable type Extra subtypeof Any;

uniontype WalkOptions
  record BFS "breadth first search" end BFS;
  record DFS "depth first search" end DFS;
end WalkOptions;

uniontype VisitOptions
  record VISIT "mark node as visited and report an error if already visited" end VISIT;
  record NO_VISIT "do not mark as visited" end NO_VISIT;
end VisitOptions;

uniontype Options
  record NO_OPTIONS end NO_OPTIONS;
  record OPTIONS
    WalkOptions ws;
    VisitOptions vs;
  end OPTIONS;
end Options;

public function walk
"walk each node in the graph"
  input Graph inGraph;
  input Walker inWalker;
  input Extra inExtra;
  input Options inOptions;
  output Graph outGraph;
  output Extra outExtra;

  partial function Walker
    input tuple<Graph, Ref, Extra> inData;
    output tuple<Graph, Ref, Extra> outData;
  end Walker;
algorithm
  (outGraph, outExtra) := match(inGraph, inWalker, inExtra, inOptions)
    case (_, _, _, _)
      equation
      then
        (inGraph, inExtra);
  end match;
end walk;

annotation(__OpenModelica_Interface="frontend");
end FTraverse;

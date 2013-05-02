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

encapsulated package Edge
" file:  Edge.mo
  package:     Edge
  description: Edge represents an edge in a graph.
  @author:     adrpo

  RCS: $Id: Edge.mo 8980 2011-05-13 09:12:21Z adrpo $


  The Edge has a pool of edges."

public
import Pool;

public
constant Integer v  = 0 "void, no assignment yet";
constant Integer cb = 1 "created by node";
constant Integer co = 2 "child of node";
constant Integer cr = 3 "composite reference";

uniontype Edge
"the edges in the graph"
  record E "an edge links two nodes"
    Integer id "its own id";
    Integer sourceId;
    Integer targetId;
    Integer kind "the edge kind, use constants in this package";
  end E;
end Edge;

type Edges = Pool.Pool<Edge> "an array of edges";

constant Integer defaultPoolSizeEdges = 100000;

public function pool
  output Edges outEdges;
algorithm
  outEdges := Pool.create("Edges", defaultPoolSizeEdges);
end pool;

public function get
  input Edges inEdges;
  input Integer inID;
  output Edge outEdge;
algorithm
  outEdge := Pool.get(inEdges, inID);
end get;

public function add
  input Edges inEdges;
  input Edge inEdge;
  output Edges outEdges;
  output Integer outID;
algorithm
  (outEdges, outID) := Pool.add(inEdges, inEdge, NONE());
end add;

public function addAutoUpdateId
  input Edges inEdges;
  input Edge inEdge;
  output Edges outEdges;
  output Integer outID;
algorithm
  (outEdges, outID) := Pool.add(inEdges, inEdge, SOME(updateId));
end addAutoUpdateId;

public function set
  input Edges inEdges;
  input Integer inID;
  input Edge inEdge;
  output Edges outEdges;
algorithm
  outEdges := Pool.set(inEdges, inID, inEdge);
end set;

public function updateId
"@this function will update the node id
  is mostly used in conjunction with the pool"
  input Edge inEdge;
  input Integer updateEdgeId;
  output Edge outEdge;
protected
  Integer id, sourceId, targetId, kind;
algorithm
  E(id, sourceId, targetId, kind) := inEdge;
  outEdge := E(updateEdgeId, sourceId, targetId, kind);
end updateId;

public function id
"@returns the id from the edge"
  input Edge inEdge;
  output Integer id;
algorithm
  E(id = id) := inEdge;
end id;

public function sourceId
"@returns the sourceId from the edge"
  input Edge inEdge;
  output Integer id;
algorithm
  E(sourceId = id) := inEdge;
end sourceId;

public function targetId
"@returns the targetId from the edge"
  input Edge inEdge;
  output Integer id;
algorithm
  E(targetId = id) := inEdge;
end targetId;

public function kind
"@returns the kind from the edge"
  input Edge inEdge;
  output Integer kind;
algorithm
  E(kind = kind) := inEdge;
end kind;

end Edge;


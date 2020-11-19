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

encapsulated uniontype AdjacencyList<VertexT, EdgeT>
  import Vector;

protected
  import List;

public
  partial function VertexEq
    input VertexT v1;
    input VertexT v2;
    output Boolean equal;
  end VertexEq;

  partial function EdgeEq
    input EdgeT e1;
    input EdgeT e2;
    output Boolean equal;
  end EdgeEq;

  type VertexDescriptor = Integer;

  record ADJACENCY_LIST
    Vector<VertexT> vertices;
    Vector<EdgeT> edges;
    Vector<list<Integer>> graph;
    VertexEq vertEqFn;
    EdgeEq edgeEqFn;
  end ADJACENCY_LIST;

  function new
    input VertexEq vertexEq;
    input EdgeEq edgeEq;
    output AdjacencyList<VertexT, EdgeT> al;
  protected
    type Indices = list<Integer>;
  algorithm
    al := ADJACENCY_LIST(Vector.new<VertexT>(), Vector.new<EdgeT>(), Vector.new<Indices>(), vertexEq, edgeEq);
  end new;

  function addVertex
    input AdjacencyList<VertexT, EdgeT> al;
    input VertexT v;
    output VertexDescriptor d;
  algorithm
    Vector.push(al.vertices, v);
    Vector.push(al.graph, {});
    d := Vector.size(al.vertices);
  end addVertex;

  function findVertex
    input AdjacencyList<VertexT, EdgeT> al;
    input PredFn predFn;
    output Option<VertexDescriptor> od;

    partial function PredFn
      input VertexT e;
      output Boolean res;
    end PredFn;
  protected
    Integer index;
  algorithm
    (_, index) := Vector.find(al.vertices, predFn);
    od := if index > 0 then SOME(index) else NONE();
  end findVertex;

  function getVertex
    input AdjacencyList<VertexT, EdgeT> al;
    input VertexDescriptor d;
    output VertexT v;
  algorithm
    v := Vector.get(al.vertices, d);
  end getVertex;

  function addEdge
    input AdjacencyList<VertexT, EdgeT> al;
    input VertexDescriptor d1;
    input VertexDescriptor d2;
    input EdgeT e;
  protected
    function edge_finder
      input Integer index;
      input EdgeT e;
      input Vector<EdgeT> edges;
      input EdgeEq eqFn;
      output Boolean matching = eqFn(e, Vector.get(edges, index));
    end edge_finder;
  protected
    list<Integer> eil;
    Integer ei;
  algorithm
    eil := Vector.get(al.graph, d1);

    ei := List.positionOnTrue(eil,
      function edge_finder(e = e, edges = al.edges, eqFn = al.edgeEqFn));

    if ei == -1 then
      Vector.push(al.edges, e);
      ei := Vector.size(al.edges);
      Vector.update(al.graph, d1, ei :: eil);
      Vector.update(al.graph, d2, ei :: Vector.get(al.graph, d2));
    else
      Vector.update(al.edges, ei, e);
    end if;
  end addEdge;

  function isEmpty
    input AdjacencyList<VertexT, EdgeT> al;
    output Boolean empty = Vector.size(al.vertices) == 0;
  end isEmpty;

  function vertexCount
    input AdjacencyList<VertexT, EdgeT> al;
    output Integer count = Vector.size(al.vertices);
  end vertexCount;

  function edgeCount
    input AdjacencyList<VertexT, EdgeT> al;
    output Integer count = Vector.size(al.edges);
  end edgeCount;

  function vertices
    input AdjacencyList<VertexT, EdgeT> al;
    output list<VertexT> vl = Vector.toList(al.vertices);
  end vertices;

  function edges
    input AdjacencyList<VertexT, EdgeT> al;
    output list<EdgeT> el = Vector.toList(al.edges);
  end edges;

annotation(__OpenModelica_Interface="util");
end AdjacencyList;

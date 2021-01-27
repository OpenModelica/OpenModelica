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

encapsulated package SBGraph<VertexT, EdgeT>
  import Vector;

protected
  import Error;
  import List;
  import SBSet;
  import StringUtil;

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

  partial function VertexStr
    input VertexT v;
    output String str;
  end VertexStr;

  partial function EdgeStr
    input EdgeT e;
    output String str;
  end EdgeStr;

  type VertexDescriptor = Integer;

  // types of sets
  // V - generic vertex set (F u U)
  // F - function/equation vertex set
  // U - unknown/variable vertex set
  // E - edge set
  type SetType = enumeration(V, F, U, E);

  function edge_finder
    input Integer index;
    input EdgeT e;
    input Vector<EdgeT> edges;
    input EdgeEq eqFn;
    output Boolean matching = eqFn(e, Vector.get(edges, index));
  end edge_finder;

  uniontype IncidenceList<VertexT, EdgeT>

  public
    record INCIDENCE_LIST
      Vector<VertexT> vertices;
      Vector<EdgeT> edges;
      Vector<list<Integer>> graph;
      VertexEq vertEqFn;
      EdgeEq edgeEqFn;
      VertexStr vertToString;
      EdgeStr edgeToString;
    end INCIDENCE_LIST;

    function new
      input VertexEq vertexEq;
      input EdgeEq edgeEq;
      input VertexStr vertexStr;
      input EdgeStr edgeStr;
      output IncidenceList<VertexT, EdgeT> il;
    protected
      type Indices = list<Integer>;
    algorithm
      il := INCIDENCE_LIST(Vector.new<VertexT>(), Vector.new<EdgeT>(), Vector.new<Indices>(), vertexEq, edgeEq, vertexStr, edgeStr);
    end new;

    function getRow
      input IncidenceList<VertexT, EdgeT> il;
      input VertexDescriptor d;
      output list<Integer> row;
    algorithm
      row := Vector.get(il.graph, d);
    end getRow;

    function addVertex
      input IncidenceList<VertexT, EdgeT> il;
      input VertexT v;
      output VertexDescriptor d;
    algorithm
      Vector.push(il.vertices, v);
      Vector.push(il.graph, {});
      d := Vector.size(il.vertices);
    end addVertex;

    function findVertex
      input IncidenceList<VertexT, EdgeT> il;
      input PredFn predFn;
      output Option<VertexDescriptor> od;

      partial function PredFn
        input VertexT e;
        output Boolean res;
      end PredFn;
    protected
      Integer index;
    algorithm
      (_, index) := Vector.find(il.vertices, predFn);
      od := if index > 0 then SOME(index) else NONE();
    end findVertex;

    function getVertex
      input IncidenceList<VertexT, EdgeT> il;
      input VertexDescriptor d;
      output VertexT v;
    algorithm
      v := Vector.get(il.vertices, d);
    end getVertex;

    function getVerticesFromSet
      "kabdelhak: seems inefficient. There has to be a better solution"
      input IncidenceList<VertexT, EdgeT> il;
      input SBSet set;
      input getSetFn getSet;
      output list<VertexT> set_vertices = {};
      partial function getSetFn
        input VertexT v;
        output SBSet s;
      end getSetFn;
    algorithm
      for v in vertices(il) loop
        if not SBSet.isEmpty(SBSet.intersection(getSet(v), set)) then
          set_vertices := v :: set_vertices;
        end if;
      end for;
    end getVerticesFromSet;

    function addEdge
      input IncidenceList<VertexT, EdgeT> il;
      input VertexDescriptor d1;
      input VertexDescriptor d2;
      input EdgeT e;
      output Integer ei;
    protected
      list<Integer> eil;
    algorithm
      eil := Vector.get(il.graph, d1);

      ei := List.positionOnTrue(eil,
        function edge_finder(e = e, edges = il.edges, eqFn = il.edgeEqFn));

      if ei == -1 then
        Vector.push(il.edges, e);
        ei := Vector.size(il.edges);
        Vector.update(il.graph, d1, ei :: eil);
        Vector.update(il.graph, d2, ei :: Vector.get(il.graph, d2));
      else
        Vector.update(il.edges, ei, e);
      end if;
    end addEdge;

    function getEdge
      input IncidenceList<VertexT, EdgeT> il;
      input Integer d;
      output EdgeT e;
    algorithm
      e := Vector.get(il.edges, d);
    end getEdge;

    function isEmpty
      input IncidenceList<VertexT, EdgeT> il;
      output Boolean empty = Vector.size(il.vertices) == 0;
    end isEmpty;

    function vertexCount
      input IncidenceList<VertexT, EdgeT> il;
      output Integer count = Vector.size(il.vertices);
    end vertexCount;

    function edgeCount
      input IncidenceList<VertexT, EdgeT> il;
      output Integer count = Vector.size(il.edges);
    end edgeCount;

    function vertices
      input IncidenceList<VertexT, EdgeT> il;
      output list<VertexT> vl = Vector.toList(il.vertices);
    end vertices;

    function edges
      input IncidenceList<VertexT, EdgeT> il;
      output list<EdgeT> el = Vector.toList(il.edges);
    end edges;

    function toString
      input IncidenceList<VertexT, EdgeT> il;
      output String str;
    protected
      // somehow this is needed and can't be applied directly
      VertexStr vertToString = il.vertToString;
      EdgeStr edgeToString = il.edgeToString;
    algorithm
      str := StringUtil.headline_2("Set-Based Graph") + "\n";
      str := str + stringDelimitList(list(vertToString(v) for v in Vector.toList(il.vertices)), "\n") + "\n";
      str := str + stringDelimitList(list(edgeToString(e) for e in Vector.toList(il.edges)), "\n") + "\n";
    end toString;

  end IncidenceList;

  uniontype BipartiteIncidenceList<VertexT, EdgeT>

  public
    record BIPARTITE_INCIDENCE_LIST
      Vector<VertexT> F_vertices;
      Vector<VertexT> U_vertices;
      Vector<EdgeT> edges;
      Vector<list<Integer>> graph;
      VertexEq vertEqFn;
      EdgeEq edgeEqFn;
      VertexStr vertToString;
      EdgeStr edgeToString;
    end BIPARTITE_INCIDENCE_LIST;

    function new
      input VertexEq vertexEq;
      input EdgeEq edgeEq;
      input VertexStr vertexStr;
      input EdgeStr edgeStr;
      output BipartiteIncidenceList<VertexT, EdgeT> il;
    protected
      type Indices = list<Integer>;
    algorithm
      il := BIPARTITE_INCIDENCE_LIST(Vector.new<VertexT>(), Vector.new<VertexT>(), Vector.new<EdgeT>(), Vector.new<Indices>(), vertexEq, edgeEq, vertexStr, edgeStr);
    end new;

    function getRow
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input VertexDescriptor d;
      output list<Integer> row = Vector.get(il.graph, d);
    end getRow;

    function addVertex
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input VertexT v;
      input SetType ST;
      output VertexDescriptor d;
    algorithm
      d := match ST

        case SetType.F algorithm
          Vector.push(il.F_vertices, v);
          Vector.push(il.graph, {});
        then Vector.size(il.F_vertices);

        case SetType.U algorithm
          Vector.push(il.U_vertices, v);
          Vector.push(il.graph, {});
        then Vector.size(il.U_vertices);

        else algorithm
          Error.assertion(false, getInstanceName() + " failed for wrong SetType: " + setTypeString(ST) + "\nAllowed: F,U", sourceInfo());
        then fail();
      end match;
    end addVertex;

    function findVertex
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input SetType ST;
      input PredFn predFn;
      output Option<VertexDescriptor> od;
      partial function PredFn
        input VertexT e;
        output Boolean res;
      end PredFn;
    protected
      Integer index;
    algorithm
      index := match ST
        case SetType.F algorithm (_, index) := Vector.find(il.F_vertices, predFn); then index;
        case SetType.U algorithm (_, index) := Vector.find(il.U_vertices, predFn); then index;
        else algorithm
          Error.assertion(false, getInstanceName() + " failed for wrong SetType: " + setTypeString(ST) + "\nAllowed: F,U", sourceInfo());
        then fail();
      end match;
      od := if index > 0 then SOME(index) else NONE();
    end findVertex;

    function getVertex
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input VertexDescriptor d;
      input SetType ST;
      output VertexT v;
    algorithm
      v := match ST
        case SetType.F  then Vector.get(il.F_vertices, d);
        case SetType.U  then Vector.get(il.U_vertices, d);
        else algorithm
          Error.assertion(false, getInstanceName() + " failed for wrong SetType: " + setTypeString(ST) + "\nAllowed: F,U", sourceInfo());
        then fail();
      end match;
    end getVertex;

    function getVerticesFromSet
      "kabdelhak: seems inefficient. There has to be a better solution"
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input SBSet set;
      input SetType ST;
      input getSetFn getSet;
      output list<VertexT> set_vertices = {};
      partial function getSetFn
        input VertexT v;
        output SBSet s;
      end getSetFn;
    algorithm
      for v in vertices(il, ST) loop
        if not SBSet.isEmpty(SBSet.intersection(getSet(v), set)) then
          set_vertices := v :: set_vertices;
        end if;
      end for;
    end getVerticesFromSet;

    function addEdge
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input VertexDescriptor d1;
      input VertexDescriptor d2;
      input EdgeT e;
      output Integer ei;
    protected
      list<Integer> eil;
    algorithm
      eil := getRow(il, d1);
      ei := List.positionOnTrue(eil,
        function edge_finder(e = e, edges = il.edges, eqFn = il.edgeEqFn));

      if ei == -1 then
        Vector.push(il.edges, e);
        ei := Vector.size(il.edges);
        Vector.update(il.graph, d1, ei :: eil);
        Vector.update(il.graph, d2, ei :: Vector.get(il.graph, d2));
      else
        Vector.update(il.edges, ei, e);
      end if;
    end addEdge;

    function getEdgesFromSet
      "kabdelhak: seems inefficient. There has to be a better solution"
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input SBSet set;
      input getSetFn getSet;
      output list<EdgeT> set_edges = {};
      partial function getSetFn
        input EdgeT e;
        output SBSet s;
      end getSetFn;
    algorithm
      for e in edges(il) loop
        if not SBSet.isEmpty(SBSet.intersection(getSet(e), set)) then
          set_edges := e :: set_edges;
        end if;
      end for;
    end getEdgesFromSet;

    function getEdge
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input Integer d;
      output EdgeT e = Vector.get(il.edges, d);
    end getEdge;

    function isEmpty
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      output Boolean empty = (Vector.size(il.F_vertices) == 0) and (Vector.size(il.U_vertices) == 0);
    end isEmpty;

    function vertexCount
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input SetType ST = SetType.V;
      output Integer count;
    algorithm
      count := match ST
        case SetType.V then Vector.size(il.F_vertices) + Vector.size(il.U_vertices);
        case SetType.F then Vector.size(il.F_vertices);
        case SetType.U then Vector.size(il.U_vertices);
        else algorithm
          Error.assertion(false, getInstanceName() + " failed for wrong SetType: " + setTypeString(ST) + "\nAllowed: V,F,U", sourceInfo());
        then fail();
      end match;
    end vertexCount;

    function edgeCount
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      output Integer count = Vector.size(il.edges);
    end edgeCount;

    function vertices
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      input SetType ST;
      output list<VertexT> vl;
    algorithm
      vl := match ST
        case SetType.V then listAppend(Vector.toList(il.F_vertices), Vector.toList(il.U_vertices));
        case SetType.F then Vector.toList(il.F_vertices);
        case SetType.U then Vector.toList(il.U_vertices);
        else algorithm
          Error.assertion(false, getInstanceName() + " failed for wrong SetType: " + setTypeString(ST) + "\nAllowed: V,F,U", sourceInfo());
        then fail();
      end match;
    end vertices;

    function edges
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      output list<EdgeT> el = Vector.toList(il.edges);
    end edges;

    function toString
      input BipartiteIncidenceList<VertexT, EdgeT> il;
      output String str;
    protected
      VertexStr vertToString;
      EdgeStr edgeToString;
    algorithm
      BIPARTITE_INCIDENCE_LIST(vertToString = vertToString, edgeToString = edgeToString) := il;
      str := StringUtil.headline_2("Set-Based Graph") + "\n"
             + StringUtil.headline_3("F-Vertices") + "\n"
             + stringDelimitList(list(vertToString(v) for v in Vector.toList(il.F_vertices)), "\n") + "\n"
             + StringUtil.headline_3("U-Vertices") + "\n"
             + stringDelimitList(list(vertToString(v) for v in Vector.toList(il.U_vertices)), "\n") + "\n"
             + StringUtil.headline_3("Edges") + "\n"
             + stringDelimitList(list(edgeToString(e) for e in Vector.toList(il.edges)), "\n") + "\n";
    end toString;

    function setTypeString
      input SetType ST;
      output String str;
    algorithm
      str := match ST
        case SetType.V    then "V (generic vertex set)";
        case SetType.F    then "F (function vertex set)";
        case SetType.U    then "U (unknown vertex set)";
        case SetType.E    then "E (edge set)";
        else getInstanceName() + " ERROR";
      end match;
    end setTypeString;

  end BipartiteIncidenceList;

  annotation(__OpenModelica_Interface="util");
end SBGraph;
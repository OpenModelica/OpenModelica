/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFArrayConnections
  import Connection = NFConnection;
  import Connector = NFConnector;
  import FlatModel = NFFlatModel;
  import ComponentRef = NFComponentRef;
  import Equation = NFEquation;
  import Connections = NFConnections;
  import Expression = NFExpression;

  import SBSet;
  import SBPWLinearMap;

protected
  import SBGraph.IncidenceList;
  import SBGraph.VertexDescriptor;
  import Array;
  import Call = NFCall;
  import Ceval = NFCeval;
  import Class = NFClass;
  import NFClassTree.ClassTree;
  import Component = NFComponent;
  import DAE;
  import Dimension = NFDimension;
  import ElementSource;
  import MetaModelica.Dangerous.*;
  import NFInstNode.InstNode;
  import NFInstNode;
  import NFPrefixes.ConnectorType;
  import NFPrefixes.Purity;
  import NFPrefixes.Variability;
  import NFBuiltin;
  import Operator = NFOperator;
  import Op = NFOperator.Op;
  import SBFunctions;
  import SBGraphUtil = NFSBGraphUtil;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;
  import UnorderedSet;
  import UnorderedMap;

  uniontype SetVertex
    record SET_VERTEX
      Connector name;
      SBSet vs;
    end SET_VERTEX;

    function isEqual
      input SetVertex v1;
      input SetVertex v2;
      output Boolean equal = Connector.isEqual(v1.name, v2.name);
    end isEqual;

    function toString
      input SetVertex v;
      output String str = Connector.toString(v.name) + "\n" + SBSet.toString(v.vs) + "\n";
    end toString;
  end SetVertex;

  uniontype SetEdge
    record SET_EDGE
      String name;
      SBPWLinearMap es1;
      SBPWLinearMap es2;
    end SET_EDGE;

    function isEqual
      input SetEdge e1;
      input SetEdge e2;
      output Boolean equal = e1.name == e2.name;
    end isEqual;

    function toString
      input SetEdge e;
      output String str = e.name + "\n" + "SetVertex 1:\t" + SBPWLinearMap.toString(e.es1) + "\nSetVertex 2:\t" + SBPWLinearMap.toString(e.es2) + "\n";
    end toString;
  end SetEdge;

public
  type NameVertexTable = UnorderedMap<String, VertexDescriptor>;
  type SBGraph = IncidenceList<SetVertex, SetEdge>;
  type ConnVar = tuple<ComponentRef, Integer, String, Boolean> "variable, dimensions of its connector, path inside the connector, outside connector";
  type VertexList = list<VertexDescriptor>;
  type VertexSets = UnorderedMap<SBAtomicSet, VertexDescriptor>;

  function resolve
    input output FlatModel flatModel;
  protected
    Integer max_dim = 1;
    Vector<Integer> v_count, e_count;
    list<Equation> conns;
    list<list<Equation>> eqll = {};
    SBGraph graph;
    SBPWLinearMap res;
    NameVertexTable nmv_table;
    array<list<VertexDescriptor>> comp_vertices;
    array<list<Integer>> comp_edges;
    array<list<ConnVar>> pot_vars, flow_vars;
    array<InstNode> iterators;
    list<Expression> iter_expl;
  algorithm
    for var in flatModel.variables loop
      max_dim := max(max_dim, Type.dimensionCount(var.ty));
    end for;

    v_count := Vector.newFill(max_dim, 1);
    e_count := Vector.newFill(max_dim, 1);

    (flatModel, conns) := collect(flatModel);

    graph := IncidenceList.new(SetVertex.isEqual, SetEdge.isEqual, SetVertex.toString, SetEdge.toString);
    nmv_table := UnorderedMap.new<VertexDescriptor>(stringHashDjb2, stringEq);
    createGraph(flatModel.variables, conns, graph, v_count, e_count, nmv_table);

    if Flags.isSet(Flags.DUMP_SET_BASED_GRAPHS) then
      print(IncidenceList.toString(graph));
    end if;

    iterators := arrayCreate(Vector.size(v_count), InstNode.EMPTY_NODE());
    for i in 1:arrayLength(iterators) loop
      iterators[i] := InstNode.newUniqueIterator();
    end for;
    iter_expl := list(Expression.fromCref(ComponentRef.makeIterator(i, Type.INTEGER())) for i in iterators);

    (pot_vars, flow_vars) := vertexVars(flatModel.variables, graph);
    (comp_vertices, comp_edges) := components(graph);

    for i in 1:arrayLength(comp_vertices) loop
      res := componentMap(comp_vertices[i], comp_edges[i], graph);
      eqll := generateEquations(res, vertexSets(comp_vertices[i], graph), iterators, iter_expl, pot_vars, flow_vars) :: eqll;
    end for;

    if Flags.isSet(Flags.DUMP_SET_BASED_GRAPHS) then
      print(IncidenceList.toString(graph));
    end if;

    flatModel.equations := listAppend(flatModel.equations, List.flatten(listReverseInPlace(eqll)));
  end resolve;

protected
  function collect
    input output FlatModel flatModel;
          output list<Equation> conns = {};
  protected
    list<Equation> eql = {};
  algorithm
    (conns, eql) := List.splitOnTrue(flatModel.equations, isConnection);
    flatModel.equations := eql;
  end collect;

  function isConnection
    input Equation eq;
    output Boolean isConn;
  algorithm
    isConn := match eq
      local
        Equation e;

      case Equation.CONNECT() then true;
      case Equation.FOR(body = e :: _) then isConnection(e);
      else false;
    end match;
  end isConnection;

  function createGraph
    input list<Variable> variables;
    input list<Equation> equations;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input Vector<Integer> eCount;
    input NameVertexTable nmvTable;
  algorithm
    addFlowsToGraph(variables, graph, vCount, nmvTable);
    addConnectionsToGraph(equations, graph, vCount, eCount, nmvTable);
  end createGraph;

  function addFlowsToGraph
    input list<Variable> variables;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input NameVertexTable nmvTable;
  protected
    Connector conn;
    ComponentRef parent_cr;
  algorithm
    for var in variables loop
      if Variable.isFlow(var) then
        parent_cr := ComponentRef.rest(var.name);
        conn := Connector.fromFacedCref(parent_cr, ComponentRef.nodeType(parent_cr), NFConnector.Face.INSIDE,
          ElementSource.createElementSource(var.info));
        createVertex(conn, graph, vCount, nmvTable);
      end if;
    end for;
  end addFlowsToGraph;

  function addConnectionsToGraph
    input list<Equation> equations;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input Vector<Integer> eCount;
    input NameVertexTable nmvTable;
  protected
    Expression range;
    list<Equation> body;
  algorithm
    for eq in equations loop
      () := match eq
        case Equation.CONNECT()
          algorithm
            createConnection(eq.lhs, eq.rhs, eq.source, graph, vCount, eCount, nmvTable);
          then
            ();

        case Equation.FOR(range = SOME(range))
          algorithm
            range := Ceval.evalExp(range, Ceval.EvalTarget.new(Equation.info(eq), NFInstContext.ITERATION_RANGE));

            if not Type.isEmptyArray(Expression.typeOf(range)) then
              body := Equation.replaceIteratorList(eq.body, eq.iterator, range);
              addConnectionsToGraph(body, graph, vCount, eCount, nmvTable);
            end if;
          then
            ();

        else
          algorithm
            Error.terminate(getInstanceName() + " got unknown equation " +
                                   Equation.toString(eq) + "\n", sourceInfo());
          then
            fail();
      end match;
    end for;
  end addConnectionsToGraph;

  function createConnection
    input Expression lhs;
    input Expression rhs;
    input DAE.ElementSource source;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input Vector<Integer> eCount;
    input NameVertexTable nmvTable;
  protected
    ComponentRef lhs_cr, rhs_cr;
    list<Subscript> lhs_subs, rhs_subs;
    SBMultiInterval mi1, mi2;
    VertexDescriptor d1, d2;
    Connector lhs_conn, rhs_conn;
  algorithm
    (lhs_cr, lhs_subs) := separate(Expression.toCref(lhs));
    (rhs_cr, rhs_subs) := separate(Expression.toCref(rhs));

    lhs_conn := Connector.fromCref(lhs_cr, ComponentRef.nodeType(lhs_cr), source);
    rhs_conn := Connector.fromCref(rhs_cr, ComponentRef.nodeType(rhs_cr), source);

    (mi1, d1) := getConnectIntervals(lhs_conn, lhs_subs, graph, vCount, nmvTable);
    (mi2, d2) := getConnectIntervals(rhs_conn, rhs_subs, graph, vCount, nmvTable);

    updateGraph(d1, d2, mi1, mi2, graph, eCount);
  end createConnection;

  function separate
    input output ComponentRef cref;
          output list<Subscript> subs;
  algorithm
    cref := ComponentRef.fillSubscripts(cref);
    cref := ComponentRef.replaceWholeSubscripts(cref);
    subs := ComponentRef.subscriptsAllFlat(cref);
    cref := ComponentRef.stripSubscriptsAll(cref);
  end separate;

  function getConnectIntervals
    input Connector conn;
    input list<Subscript> subs;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input NameVertexTable nmvTable;
    output SBMultiInterval outMI;
    output VertexDescriptor d;
  algorithm
    (outMI, d) := createVertex(conn, graph, vCount, nmvTable);
    outMI := SBGraphUtil.multiIntervalFromSubscripts(subs, vCount, outMI);
  end getConnectIntervals;

  function createVertex
    input Connector conn;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input NameVertexTable nmvTable;
    output SBMultiInterval mi;
    output VertexDescriptor d;
  protected
    Option<VertexDescriptor> od;
    SetVertex v;
    list<Dimension> dims;
    SBSet s;
    String name;
  algorithm
    name := Connector.toString(conn) + "$" + Connector.faceString(conn);
    od := UnorderedMap.get(name, nmvTable);

    if isSome(od) then
      SOME(d) := od;
      mi := vertexInterval(IncidenceList.getVertex(graph, d));
      return;
    end if;

    dims := crefDims(Connector.name(conn));
    mi := SBGraphUtil.multiIntervalFromDimensions(dims, vCount);

    s := SBSet.newEmpty();
    s := SBSet.addAtomicSet(SBAtomicSet.new(mi), s);

    v := SET_VERTEX(conn, s);
    d := IncidenceList.addVertex(graph, v);
    UnorderedMap.addUnique(name, d, nmvTable);
  end createVertex;

  function vertexInterval
    input SetVertex v;
    output SBMultiInterval mi = SBAtomicSet.aset(UnorderedSet.first(SBSet.asets(v.vs)));
  end vertexInterval;

  function vertexSets
    input list<VertexDescriptor> vertices;
    input SBGraph graph;
    output VertexSets sets = UnorderedMap.new<VertexDescriptor>(SBAtomicSet.hash, SBAtomicSet.isEqual);
  protected
    SetVertex v;
  algorithm
    for d in vertices loop
      v := IncidenceList.getVertex(graph, d);
      UnorderedMap.add(UnorderedSet.first(SBSet.asets(v.vs)), d, sets);
    end for;
  end vertexSets;

  function crefDims
    input ComponentRef cr;
    output list<Dimension> dims = {};
  protected
    ComponentRef c = cr;
  algorithm
    while not ComponentRef.isEmpty(c) loop
      dims := listAppend(Type.arrayDims(ComponentRef.nodeType(c)), dims);
      c := ComponentRef.rest(c);
    end while;
  end crefDims;

  function updateGraph
    input VertexDescriptor d1;
    input VertexDescriptor d2;
    input SBMultiInterval mi1;
    input SBMultiInterval mi2;
    input SBGraph graph;
    input Vector<Integer> eCount;
  protected
    SBPWLinearMap pw1, pw2;
    String name;
    SetEdge se;
  algorithm
    (name, pw1, pw2) := SBGraphUtil.linearMapFromIntervals(d1, d2, mi1, mi2, eCount);
    se := SET_EDGE(name, pw1, pw2);
    IncidenceList.addEdge(graph, d1, d2, se);
  end updateGraph;

  function components
    "The vertices and edges of each connected component of the graph, ignoring
     which elements an edge connects."
    input SBGraph graph;
    output array<list<VertexDescriptor>> vertices;
    output array<list<Integer>> edges;
  protected
    Integer nv = IncidenceList.vertexCount(graph);
    Integer ne = IncidenceList.edgeCount(graph);
    Integer count = 0, r, c;
    array<Integer> parent = listArray(List.intRange(nv));
    array<Integer> edge_vertex = arrayCreate(ne, 0);
    array<Integer> comp = arrayCreate(nv, 0);
  algorithm
    for d in 1:nv loop
      for e in IncidenceList.getRow(graph, d) loop
        if edge_vertex[e] == 0 then
          edge_vertex[e] := d;
        else
          joinRoots(parent, d, edge_vertex[e]);
        end if;
      end for;
    end for;

    for d in 1:nv loop
      r := findRoot(parent, d);
      if comp[r] == 0 then
        count := count + 1;
        comp[r] := count;
      end if;
    end for;

    vertices := arrayCreate(count, {});
    edges := arrayCreate(count, {});

    for d in nv:-1:1 loop
      c := comp[findRoot(parent, d)];
      vertices[c] := d :: vertices[c];
    end for;

    for e in ne:-1:1 loop
      c := comp[findRoot(parent, edge_vertex[e])];
      edges[c] := e :: edges[c];
    end for;
  end components;

  function findRoot
    input array<Integer> parent;
    input output Integer i;
  protected
    Integer p;
  algorithm
    while parent[i] <> i loop
      p := parent[parent[i]];
      arrayUpdate(parent, i, p);
      i := p;
    end while;
  end findRoot;

  function joinRoots
    input array<Integer> parent;
    input Integer i1;
    input Integer i2;
  protected
    Integer r1 = findRoot(parent, i1), r2 = findRoot(parent, i2);
  algorithm
    if r1 < r2 then
      arrayUpdate(parent, r2, r1);
    elseif r2 < r1 then
      arrayUpdate(parent, r1, r2);
    end if;
  end joinRoots;

  function componentMap
    "Maps each element of the vertices of a component of the graph to the
     smallest element it is connected to."
    input list<VertexDescriptor> vertices;
    input list<Integer> edges;
    input SBGraph graph;
    output SBPWLinearMap res;
  protected
    SBSet vss = SBSet.newEmpty();
    SetVertex v;
    Boolean scalar = true;
    SBPWLinearMap emap1, emap2;
    array<Real> offset;
  algorithm
    for d in vertices loop
      v := IncidenceList.getVertex(graph, d);
      vss := SBSet.addAtomicSets(SBSet.asets(v.vs), vss);
      scalar := scalar and UnorderedSet.size(SBSet.asets(v.vs)) == 1 and
                SBMultiInterval.size(vertexInterval(v)) == 1;
    end for;

    if listEmpty(edges) then
      res := SBPWLinearMap.newIdentity(vss);
    elseif scalar then
      offset := Array.map(SBSet.minElem(vss), intReal);
      res := SBPWLinearMap.newScalar(vss, SBLinearMap.new(arrayCreate(arrayLength(offset), 0.0), offset));
    else
      (emap1, emap2) := createMaps(list(IncidenceList.getEdge(graph, e) for e in edges));
      res := SBFunctions.connectedComponents(vss, emap1, emap2);
    end if;
  end componentMap;

  function createMaps
    input list<SetEdge> edges;
    output SBPWLinearMap emap1;
    output SBPWLinearMap emap2;
  protected
    SetEdge e;
    list<SetEdge> es;
  algorithm
    e :: es := edges;
    emap1 := e.es1;
    emap2 := e.es2;

    for e in es loop
      emap1 := SBPWLinearMap.combine(e.es1, emap1);
      emap2 := SBPWLinearMap.combine(e.es2, emap2);
    end for;
  end createMaps;

  function vertexVars
    "The potential and flow variables of the connector of each vertex, with the
     number of dimensions of the connector and their path inside it."
    input list<Variable> variables;
    input SBGraph graph;
    output array<list<ConnVar>> potVars;
    output array<list<ConnVar>> flowVars;
  protected
    Integer nv = IncidenceList.vertexCount(graph);
    UnorderedMap<ComponentRef, VertexList> names;
    SetVertex v;
    ComponentRef name;
    list<VertexDescriptor> candidates;
    Boolean is_pot;
    ConnVar cv;
  algorithm
    potVars := arrayCreate(nv, {});
    flowVars := arrayCreate(nv, {});
    names := UnorderedMap.new<VertexList>(ComponentRef.hashStrip, ComponentRef.isEqualStrip);

    for d in 1:nv loop
      v := IncidenceList.getVertex(graph, d);
      name := Connector.name(v.name);
      UnorderedMap.add(name, d :: UnorderedMap.getOrDefault(name, names, {}), names);
    end for;

    for var in variables loop
      is_pot := Variable.isPotential(var);

      if is_pot or Variable.isFlow(var) then
        // ComponentRef.isPrefix only matches the variable itself or its parent.
        candidates := UnorderedMap.getOrDefault(var.name, names, {});
        if ComponentRef.isCref(var.name) then
          candidates := listAppend(UnorderedMap.getOrDefault(ComponentRef.rest(var.name), names, {}), candidates);
        end if;

        for d in candidates loop
          v := IncidenceList.getVertex(graph, d);
          name := Connector.name(v.name);

          if ComponentRef.isPrefix(name, var.name) then
            for field in recordFields(var.name) loop
              cv := (field, listLength(crefDims(name)), memberName(field, name), Connector.isOutside(v.name));

              if is_pot then
                potVars[d] := cv :: potVars[d];
              else
                flowVars[d] := cv :: flowVars[d];
              end if;
            end for;
          end if;
        end for;
      end if;
    end for;

    for d in 1:nv loop
      potVars[d] := listReverseInPlace(potVars[d]);
      flowVars[d] := listReverseInPlace(flowVars[d]);
    end for;
  end vertexVars;

  function recordFields
    "The scalar fields of a record variable, or the variable itself if it is
     not a record."
    input ComponentRef cref;
    input output list<ComponentRef> fields = {};
  protected
    Type ty = Type.arrayElementType(ComponentRef.nodeType(cref));
    array<InstNode> comps;
    Component c;
  algorithm
    if Type.isRecord(ty) then
      comps := ClassTree.getComponents(Class.classTree(InstNode.getClass(Type.complexNode(ty))));

      for i in arrayLength(comps):-1:1 loop
        c := InstNode.component(comps[i]);

        if not ConnectorType.isPotentiallyPresent(Component.connectorType(c)) then
          fields := recordFields(ComponentRef.append(ComponentRef.fromNode(comps[i], Component.getType(c)), cref), fields);
        end if;
      end for;
    else
      fields := cref :: fields;
    end if;
  end recordFields;

  function generateEquations
    input SBPWLinearMap pw;
    input VertexSets vertexSets;
    input array<InstNode> iterators;
    input list<Expression> iterExps;
    input array<list<ConnVar>> potVars;
    input array<list<ConnVar>> flowVars;
    output list<Equation> equations = {};
  protected
    SBSet vc_im, aux_s, vc_domi, vc_domi_aux;
    list<ConnVar> vars;
  algorithm
    vc_im := SBPWLinearMap.fullImage(pw);

    for aset in UnorderedSet.toArray(SBSet.asets(vc_im)) loop
      aux_s := SBSet.newEmpty();
      aux_s := SBSet.addAtomicSet(aset, aux_s);
      vc_domi := SBPWLinearMap.preImage(pw, aux_s);
      vc_domi_aux := SBSet.complement(vc_domi, aux_s);
      vars := getVars(aset, vertexSets, potVars);

      equations := generatePotentialEquations(aset, vc_domi_aux, vars, iterators,
        iterExps, vertexSets, potVars, equations);
      equations := generateFlowEquation(aset, vc_domi, iterators, vertexSets, flowVars, equations);
    end for;

    equations := listReverseInPlace(equations);
  end generateEquations;

  function intervalToRange
    input SBInterval interval;
    output Expression range;
  protected
    Integer lo = SBInterval.lowerBound(interval);
    Integer hi = SBInterval.upperBound(interval);
  algorithm
    if lo == hi then
      range := Expression.INTEGER(lo);
    else
      range := Expression.makeIntegerRange(lo, SBInterval.stepValue(interval), hi);
    end if;
  end intervalToRange;

  function generatePotentialEquations
    input SBAtomicSet aset;
    input SBSet dom;
    input list<ConnVar> vars;
    input array<InstNode> iterators;
    input list<Expression> iterExps;
    input VertexSets vertexSets;
    input array<list<ConnVar>> potVars;
    input output list<Equation> equations;
  protected
    SBMultiInterval mi, mi_range, aux_mi;
    array<SBInterval> inters;
    array<Expression> ranges;
    list<ConnVar> vars1;
    list<Equation> eql;
    list<Expression> inds;
  algorithm
    for auxi in UnorderedSet.toArray(SBSet.asets(dom)) loop
      mi := SBAtomicSet.aset(auxi);
      mi_range := applyOffset(mi, getOffset(auxi, vertexSets));
      inters := SBMultiInterval.intervals(mi_range);
      ranges := Array.map(inters, intervalToRange);

      vars1 := getVars(auxi, vertexSets, potVars);

      mi := SBAtomicSet.aset(aset);
      aux_mi := applyOffset(mi, getOffset(aset, vertexSets));
      inds := transMulti(mi_range, aux_mi, iterators, false);

      eql := generatePotentialEquations2(vars1, vars, iterExps, inds);
      equations := generateForLoop(eql, iterators, ranges, equations);
    end for;
  end generatePotentialEquations;

  function generatePotentialEquations2
    input list<ConnVar> vars1;
    input list<ConnVar> vars2;
    input list<Expression> inds1;
    input list<Expression> inds2;
    output list<Equation> equations = {};
  protected
    ComponentRef var1, var2;
    Integer n1, n2;
    String m1, m2;
    Expression l, r;
    Type ty;
    Equation eq;
  algorithm
    for v1 in vars1 loop
      (var1, n1, m1, _) := v1;
      for v2 in vars2 loop
        (var2, n2, m2, _) := v2;
        // the same member of both connectors: a connector can have several
        // potential variables of the same type (e.g. v and an angle theta)
        // (the element types: the dimensions of a node can belong to the
        // connector, e.g. u[3] for an array of input connectors)
        if m1 == m2 and
           Type.isEqual(Type.arrayElementType(ComponentRef.nodeType(var1)), Type.arrayElementType(ComponentRef.nodeType(var2))) then
          l := generateConnector(var1, inds1, n1);
          r := generateConnector(var2, inds2, n2);
          ty := Expression.typeOf(l);
          if ComponentRef.variability(var1) > Variability.PARAMETER and ComponentRef.variability(var2) > Variability.PARAMETER then
            eq := Equation.makeEquality(l, r, ty, scalarizeMode = NFEquation.ScalarizeMode.DONT_SCALARIZE);
          else
            // connected constants and parameters are checked, like the classic connection handler does
            eq := makeEqualityAssert(l, r, ty);
          end if;
          equations := eq :: equations;
        end if;
      end for;
    end for;

    equations := listReverseInPlace(equations);
  end generatePotentialEquations2;

  function makeEqualityAssert
    "assert(abs(l - r) <= 0) for Reals, assert(l == r) else; like
     NFConnectEquations.makeEqualityAssert, for array connections"
    input Expression l;
    input Expression r;
    input Type ty;
    output Equation eq;
  protected
    Type elem_ty = Type.arrayElementType(ty);
    Expression exp;
  algorithm
    if Type.isArray(ty) then
      Error.addInternalError(getInstanceName() + ": connected parameters of array type are not supported with array connections yet: "
        + Expression.toString(l) + ", " + Expression.toString(r), sourceInfo());
      fail();
    end if;
    if Type.isReal(elem_ty) then
      exp := Expression.BINARY(l, Operator.makeSub(elem_ty), r);
      exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.ABS_REAL, {exp}, Expression.variability(exp), Purity.PURE));
      exp := Expression.RELATION(exp, Operator.makeLessEq(elem_ty), Expression.REAL(0.0), -1);
    else
      exp := Expression.RELATION(l, Operator.makeEqual(elem_ty), r, -1);
    end if;
    eq := Equation.ASSERT(exp, Expression.STRING("Connected constants/parameters must be equal"),
      NFBuiltin.ASSERTIONLEVEL_ERROR, NFInstNode.NO_SCOPE, DAE.emptyElementSource);
  end makeEqualityAssert;

  function generateFlowEquation
    input SBAtomicSet aset;
    input SBSet dom;
    input array<InstNode> iterators;
    input VertexSets vertexSets;
    input array<list<ConnVar>> flowVars;
    input output list<Equation> equations;
  protected
    SBMultiInterval mi, mi_range, mi_range2;
    array<SBInterval> inters;
    array<Expression> ranges;
    list<Expression> expl, inds;
    Boolean is_sum, outside;
    list<ConnVar> vars;
    ComponentRef var;
    Integer n;
    String m;
    Expression e, sum_exp;
    Type ty;
    Equation eq;
    UnorderedMap<String, ExpList> named_expl = UnorderedMap.new<ExpList>(stringHashDjb2, stringEq) "the terms of each sum, in reverse order";
    UnorderedSet<String> elementwise = UnorderedSet.new(stringHashDjb2, stringEq);
    list<tuple<ComponentRef, Integer, String, Boolean, list<Expression>, Boolean>> terms = {};
    Integer sz;
  algorithm
    mi := SBAtomicSet.aset(aset);
    mi_range := applyOffset(mi, getOffset(aset, vertexSets));
    inters := SBMultiInterval.intervals(mi_range);
    ranges := Array.map(inters, intervalToRange);
    expl := {};

    // collect the flow variables of all connectors of the set with their indices
    for auxi in UnorderedSet.toArray(SBSet.asets(dom)) loop
      mi := SBAtomicSet.aset(auxi);
      mi_range2 := applyOffset(mi, getOffset(auxi, vertexSets));
      (inds, is_sum) := transMulti(mi_range, mi_range2, iterators, true);
      vars := getVars(auxi, vertexSets, flowVars);

      for v in vars loop
        (var, n, m, outside) := v;
        terms := (var, n, m, outside, inds, is_sum) :: terms;
        // a flow variable that is an array in its connector (e.g. i[3]) summed
        // over a range of connectors has to be summed element by element
        if is_sum and Type.isArray(ComponentRef.nodeType(var)) then
          UnorderedSet.add(m, elementwise);
        end if;
      end for;
    end for;

    for t in listReverse(terms) loop
      (var, n, m, outside, inds, is_sum) := t;
      if UnorderedSet.contains(m, elementwise) then
        sz := memberSize(var);
        for k in 1:sz loop
          e := flowTerm(ComponentRef.setSubscripts({Subscript.INDEX(Expression.INTEGER(k))}, var), inds, n, is_sum, outside);
          addNamed(m + "[" + intString(k) + "]", e, named_expl);
        end for;
      else
        e := flowTerm(var, inds, n, is_sum, outside);
        addNamed(m, e, named_expl);
      end if;
    end for;

    // one sum for each flow variable of the connectors (a connector can have several),
    // in the order of their first terms
    for name in UnorderedMap.keyList(named_expl) loop
      expl := UnorderedMap.getOrFail(name, named_expl);
      sum_exp :: expl := expl;

      while not listEmpty(expl) loop
        e :: expl := expl;
        sum_exp := Expression.BINARY(e, Operator.makeAdd(Expression.typeOf(e)), sum_exp);
      end while;

      ty := Expression.typeOf(sum_exp);
      eq := Equation.makeEquality(sum_exp, Expression.makeZero(ty), ty);
      equations := generateForLoop({eq}, iterators, ranges, equations);
    end for;
  end generateFlowEquation;

  function flowTerm
    "A flow variable of a connector in the flow equation of its set, summed if a
     range of connectors is connected to one."
    input ComponentRef var;
    input list<Expression> inds;
    input Integer connectorDims;
    input Boolean isSum;
    input Boolean outside;
    output Expression e;
  algorithm
    e := generateConnector(var, inds, connectorDims);
    if isSum then
      if Type.isArray(Expression.typeOf(e)) and Type.dimensionCount(Expression.typeOf(e)) > 1 then
        Error.addInternalError(getInstanceName() + ": the flow variable " + ComponentRef.toString(var) +
          " has several dimensions inside its connector, connecting a range of such connectors to one is not supported yet.", sourceInfo());
        fail();
      end if;
      e := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.SUM,
        {e}, Expression.variability(e), Purity.PURE, Type.arrayElementType(Expression.typeOf(e))));
    end if;

    if outside then
      e := Expression.negate(e);
    end if;
  end flowTerm;

  function memberSize
    "The size of a flow variable that is a vector in its connector."
    input ComponentRef var;
    output Integer sz;
  protected
    list<Dimension> dims = Type.arrayDims(ComponentRef.nodeType(var));
  algorithm
    if listLength(dims) <> 1 or not Dimension.isKnown(listHead(dims)) then
      Error.addInternalError(getInstanceName() + ": the flow variable " + ComponentRef.toString(var) +
        " has to be a vector of known size inside its connector to connect a range of connectors to one.", sourceInfo());
      fail();
    end if;
    sz := Dimension.size(listHead(dims));
  end memberSize;

  type ExpList = list<Expression>;

  function addNamed
    "adds a term to the sum of the flow variable name"
    input String name;
    input Expression e;
    input UnorderedMap<String, ExpList> namedExpl;
  algorithm
    UnorderedMap.addUpdate(name, function prependTerm(e = e), namedExpl);
  end addNamed;

  function prependTerm
    input Option<list<Expression>> old;
    input Expression e;
    output list<Expression> res = e :: Util.getOptionOrDefault(old, {});
  end prependTerm;

  function generateConnector
    "The variable of a connector, subscripted with the indices of the connector.
     Dimensions of the variable inside the connector (e.g. v[3] in the connector)
     stay whole."
    input ComponentRef cr;
    input list<Expression> indices;
    input Integer connectorDims "the number of dimensions of the connector";
    output Expression outExp;
  protected
    list<Subscript> subs;
  algorithm
    outExp := Expression.fromCref(cr);

    if Type.isArray(Expression.typeOf(outExp)) and connectorDims > 0 then
      subs := list(Subscript.fromTypedExp(i) for i in indices);
      subs := List.firstN(subs, intMin(connectorDims, Type.dimensionCount(Expression.typeOf(outExp))));
      outExp := Expression.applySubscripts(subs, outExp);
    end if;
  end generateConnector;

  function generateForLoop
    input list<Equation> connects;
    input array<InstNode> iterators;
    input array<Expression> ranges;
    input output list<Equation> equations;
  protected
    list<Equation> body = connects;
  algorithm
    for i in arrayLength(iterators):-1:1 loop
      if Expression.isInteger(ranges[i]) then
        // Scalar range means the interval had the same lower and upper bound,
        // in which case the iterator can be replaced with the scalar expression
        // instead of creating an unnecessary for loop here.
        body := Equation.replaceIteratorList(body, iterators[i], ranges[i]);
      else
        body := {Equation.FOR(iterators[i], SOME(ranges[i]), body, NFInstNode.NO_SCOPE, DAE.emptyElementSource)};
      end if;
    end for;

    equations := List.append_reverse(body, equations);
  end generateForLoop;

  function getOffset
    "The smallest element of the vertex containing aset."
    input SBAtomicSet aset;
    input VertexSets vertexSets;
    output array<Integer> res = listArray({});
  protected
    SBAtomicSet vset;
  algorithm
    if UnorderedMap.contains(aset, vertexSets) then
      res := SBAtomicSet.minElem(aset);
      return;
    end if;

    for i in 1:UnorderedMap.size(vertexSets) loop
      vset := UnorderedMap.keyAt(vertexSets, i);

      if not SBAtomicSet.isEmpty(SBAtomicSet.intersection(aset, vset)) then
        res := SBAtomicSet.minElem(vset);
        return;
      end if;
    end for;
  end getOffset;

  function applyOffset
    input SBMultiInterval mi;
    input array<Integer> off;
    output SBMultiInterval outMI;
  protected
    array<SBInterval> ints, res;
    SBInterval i;
    Integer o;
  algorithm
    if SBMultiInterval.ndim(mi) <> arrayLength(off) or arrayEmpty(off) then
      outMI := SBMultiInterval.newEmpty();
    else
      ints := SBMultiInterval.intervals(mi);
      res := arrayCreateNoInit(arrayLength(ints), ints[1]);

      for j in 1:arrayLength(ints) loop
        i := ints[j];
        o := off[j];
        res[j] := SBInterval.new(SBInterval.lowerBound(i) - o + 1,
                                 SBInterval.stepValue(i),
                                 SBInterval.upperBound(i) - o + 1);
      end for;

      outMI := SBMultiInterval.fromArray(res);
    end if;
  end applyOffset;

  function memberName
    "The path of a connector variable inside its connector, e.g. v for line.a.v
     of the connector line.a, empty if the connector is the variable itself
     (connector RealInput = input Real)."
    input ComponentRef var;
    input ComponentRef conn;
    output String name;
  protected
    list<String> var_names = crefNames(var);
  algorithm
    for i in 1:listLength(crefNames(conn)) loop
      var_names := List.restOrEmpty(var_names);
    end for;
    name := stringDelimitList(var_names, ".");
  end memberName;

  function crefNames
    "The identifiers of a cref from the outermost one, without subscripts."
    input ComponentRef cref;
    output list<String> names = {};
  protected
    ComponentRef c = cref;
  algorithm
    while not ComponentRef.isEmpty(c) loop
      names := ComponentRef.firstName(c) :: names;
      c := ComponentRef.rest(c);
    end while;
  end crefNames;

  function getVars
    "The variables of the connectors of the vertices that intersect aset, with
     the number of dimensions of their connector and their path inside it."
    input SBAtomicSet aset;
    input VertexSets vertexSets;
    input array<list<ConnVar>> vertexVars;
    output list<ConnVar> res;
  protected
    Option<VertexDescriptor> od;
    VertexDescriptor d;
    list<list<ConnVar>> varsl = {};
  algorithm
    od := UnorderedMap.get(aset, vertexSets);

    if isSome(od) then
      SOME(d) := od;
      res := vertexVars[d];
      return;
    end if;

    for i in 1:UnorderedMap.size(vertexSets) loop
      if not SBAtomicSet.isEmpty(SBAtomicSet.intersection(aset, UnorderedMap.keyAt(vertexSets, i))) then
        varsl := vertexVars[UnorderedMap.valueAt(vertexSets, i)] :: varsl;
      end if;
    end for;

    res := List.flatten(listReverseInPlace(varsl));
  end getVars;

  function transMulti
    input SBMultiInterval mi1;
    input SBMultiInterval mi2;
    input array<InstNode> iterators;
    input Boolean forFlow;
    output list<Expression> outExpl = {};
    output Boolean flowRange = false;
  protected
    array<SBInterval> ints1, ints2;
    SBInterval i1, i2;
    Integer i1_sz, i2_sz, m_int;
    Expression x, m, h, e;
  algorithm
    if SBMultiInterval.ndim(mi1) <> SBMultiInterval.ndim(mi2) then
      return;
    end if;

    ints1 := SBMultiInterval.intervals(mi1);
    ints2 := SBMultiInterval.intervals(mi2);

    for i in 1:arrayLength(ints1) loop
      i1 := ints1[i];
      i2 := ints2[i];
      i1_sz := SBInterval.size(i1);
      i2_sz := SBInterval.size(i2);

      x := Expression.fromCref(ComponentRef.makeIterator(iterators[i], Type.INTEGER()));

      if i1_sz == i2_sz then
        m_int := intDiv(SBInterval.stepValue(i2), SBInterval.stepValue(i1));
        m := Expression.INTEGER(m_int);
        h := Expression.INTEGER(-m_int * SBInterval.lowerBound(i1) + SBInterval.lowerBound(i2));

        // m * x + h
        e := Expression.BINARY(
          Expression.BINARY(m, Operator.makeMul(Type.INTEGER()), x),
          Operator.makeAdd(Type.INTEGER()),
          h
        );

        outExpl := e :: outExpl;
      elseif i2_sz == 1 and not forFlow then
        outExpl := Expression.INTEGER(SBInterval.lowerBound(i2)) :: outExpl;
      elseif i1_sz == 1 and forFlow then
        e := Expression.makeIntegerRange(
          SBInterval.lowerBound(i2), SBInterval.stepValue(i2), SBInterval.upperBound(i2));
        outExpl := e :: outExpl;
        flowRange := true;
      else
        Error.terminate(getInstanceName() + " got invalid intervals.", sourceInfo());
      end if;
    end for;

    outExpl := listReverseInPlace(outExpl);
  end transMulti;

  annotation(__OpenModelica_Interface="nf_frontend");
end NFArrayConnections;

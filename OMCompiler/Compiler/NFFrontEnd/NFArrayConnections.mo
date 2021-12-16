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
  import AbsynUtil;
  import AdjacencyList;
  import Array;
  import BaseHashTable;
  import Call = NFCall;
  import Ceval = NFCeval;
  import Component = NFComponent;
  import Dimension = NFDimension;
  import ElementSource;
  import MetaModelica.Dangerous.*;
  import NFInstNode.InstNode;
  import NFPrefixes.Purity;
  import NFPrefixes.Variability;
  import Operator = NFOperator;
  import Op = NFOperator.Op;
  import SBFunctions;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import System;
  import Type = NFType;
  import Variable = NFVariable;

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

    function isNamed
      input SetVertex v;
      input Connector name;
      output Boolean equal = Connector.isEqual(v.name, name);
    end isNamed;
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
  end SetEdge;

  // TODO: Implement better hash table and get rid of this.
  encapsulated package NameVertexTable
    import BaseHashTable;
    import SBMultiInterval;

    type Key = String;
    type Value = SBMultiInterval;

    type Table = tuple<
      array<list<tuple<Key, Integer>>>,
      tuple<Integer, Integer, array<Option<tuple<Key, Value>>>>,
      Integer,
      tuple<FuncHash, FuncEq, FuncKeyStr, FuncValueStr>>;

    partial function FuncHash
      input Key key;
      input Integer mod;
      output Integer res;
    end FuncHash;

    partial function FuncEq
      input Key key1;
      input Key key2;
      output Boolean res;
    end FuncEq;

    partial function FuncKeyStr
      input Key key;
      output String res;
    end FuncKeyStr;

    partial function FuncValueStr
      input Value value;
      output String res;
    end FuncValueStr;

    function new
      input Integer size = 257;
      output Table table;
    algorithm
      table := BaseHashTable.emptyHashTableWork(size,
        (stringHashDjb2Mod, stringEq, Util.id, SBMultiInterval.toString));
    end new;
  end NameVertexTable;
public
  type SBGraph = AdjacencyList<SetVertex, SetEdge>;

  function resolve
    input output FlatModel flatModel;
  protected
    Integer max_dim = 1;
    Vector<Integer> v_count, e_count;
    list<Equation> conns, eql;
    SBGraph graph;
    SBSet vss;
    SBPWLinearMap res, emap1, emap2;
    NameVertexTable.Table nmv_table;
  algorithm
    for var in flatModel.variables loop
      max_dim := max(max_dim, Type.dimensionCount(var.ty));
    end for;

    v_count := Vector.newFill(max_dim, 1);
    e_count := Vector.newFill(max_dim, 1);

    (flatModel, conns) := collect(flatModel);

    graph := AdjacencyList.new(SetVertex.isEqual, SetEdge.isEqual);
    nmv_table := NameVertexTable.new();
    nmv_table := createGraph(flatModel.variables, conns, graph, v_count, e_count, nmv_table);

    (vss, emap1, emap2) := createMaps(graph);
    res := SBFunctions.connectedComponents(vss, emap1, emap2);

    conns := generateEquations(res, flatModel, graph, v_count, nmv_table);
    eql := listAppend(flatModel.equations, conns);
    flatModel.equations := eql;
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
    input output NameVertexTable.Table nmvTable;
  algorithm
    nmvTable := addFlowsToGraph(variables, graph, vCount, nmvTable);
    nmvTable := addConnectionsToGraph(equations, graph, vCount, eCount, nmvTable);
  end createGraph;

  function addFlowsToGraph
    input list<Variable> variables;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input output NameVertexTable.Table nmvTable;
  protected
    Connector conn;
    ComponentRef parent_cr;
  algorithm
    for var in variables loop
      if Variable.isFlow(var) then
        parent_cr := ComponentRef.rest(var.name);
        conn := Connector.fromFacedCref(parent_cr, ComponentRef.nodeType(parent_cr), NFConnector.Face.INSIDE,
          ElementSource.createElementSource(var.info));
        (_, _, nmvTable) := createVertex(conn, graph, vCount, nmvTable);
      end if;
    end for;
  end addFlowsToGraph;

  function addConnectionsToGraph
    input list<Equation> equations;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input Vector<Integer> eCount;
    input output NameVertexTable.Table nmvTable;
  protected
    Expression range;
    list<Equation> body;
  algorithm
    for eq in equations loop
      () := match eq
        case Equation.CONNECT()
          algorithm
            nmvTable := createConnection(eq.lhs, eq.rhs, eq.source, graph, vCount, eCount, nmvTable);
          then
            ();

        case Equation.FOR(range = SOME(range))
          algorithm
            range := Ceval.evalExp(range, Ceval.EvalTarget.RANGE(Equation.info(eq)));
            body := Equation.replaceIteratorList(eq.body, eq.iterator, range);
            nmvTable := addConnectionsToGraph(body, graph, vCount, eCount, nmvTable);
          then
            ();

        else
          algorithm
            Error.assertion(false, getInstanceName() + " got unknown equation " +
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
    input output NameVertexTable.Table nmvTable;
  protected
    ComponentRef lhs_cr, rhs_cr;
    list<Subscript> lhs_subs, rhs_subs;
    SBMultiInterval mi1, mi2;
    AdjacencyList.VertexDescriptor d1, d2;
    SourceInfo info = ElementSource.getInfo(source);
    list<Connector> lhs_conns, rhs_conns;
    Connector lhs_conn, rhs_conn;
  algorithm
    (lhs_cr, lhs_subs) := separate(Expression.toCref(lhs));
    (rhs_cr, rhs_subs) := separate(Expression.toCref(rhs));

    lhs_conn := Connector.fromCref(lhs_cr, ComponentRef.nodeType(lhs_cr), source);
    rhs_conn := Connector.fromCref(rhs_cr, ComponentRef.nodeType(rhs_cr), source);

    (mi1, d1, nmvTable) := getConnectIntervals(lhs_conn, lhs_subs, graph, vCount, nmvTable, info);
    (mi2, d2, nmvTable) := getConnectIntervals(rhs_conn, rhs_subs, graph, vCount, nmvTable, info);

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
    input NameVertexTable.Table nmvTable;
    input SourceInfo info;
    output SBMultiInterval outMI;
    output AdjacencyList.VertexDescriptor d;
    output NameVertexTable.Table outNmvTable = nmvTable;
  protected
    function make_lo_interval
      input SBInterval i;
      output SBInterval res;
    protected
      Integer lo = SBInterval.lowerBound(i);
    algorithm
      res := SBInterval.new(lo, 1, lo);
    end make_lo_interval;
  protected
    array<SBInterval> mi, miv;
    SBInterval int;
    Integer index, aux_lo;
    Expression sub_exp;
  algorithm
    (outMI, d, outNmvTable) := createVertex(conn, graph, vCount, nmvTable);
    miv := SBMultiInterval.intervals(outMI);

    if listEmpty(subs) then
      mi := Array.map(miv, make_lo_interval);
    else
      index := 1;
      mi := arrayCopy(miv);

      for s in subs loop
        sub_exp := evalCrefs(Subscript.toExp(s));
        int := intervalFromExp(sub_exp);
        aux_lo := SBInterval.lowerBound(miv[index]) - 1;
        int := SBInterval.new(aux_lo + SBInterval.lowerBound(int),
                              SBInterval.stepValue(int),
                              aux_lo + SBInterval.upperBound(int));

        if not SBInterval.isEmpty(int) then
          mi[index] := int;
        else
          mi := listArray({});
          break;
        end if;

        index := index + 1;
      end for;

      for i in listLength(subs)+1:arrayLength(mi) loop
        aux_lo := SBInterval.lowerBound(miv[i]);
        mi[index] := SBInterval.new(aux_lo, 1, aux_lo);
      end for;
    end if;

    outMI := SBMultiInterval.fromArray(mi);
  end getConnectIntervals;

  function createVertex
    input Connector conn;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input NameVertexTable.Table nmvTable;
    output SBMultiInterval mi;
    output AdjacencyList.VertexDescriptor d;
    output NameVertexTable.Table outNmvTable = nmvTable;
  protected
    Option<AdjacencyList.VertexDescriptor> od;
    SetVertex v;
    list<Dimension> dims;
    Integer vc, dim_size, index;
    SBSet s;
    array<SBInterval> ints;
    Vector<Integer> new_vc;
    SBInterval int;
    String name;
  algorithm
    od := AdjacencyList.findVertex(graph, function SetVertex.isNamed(name = conn));

    if isSome(od) then
      SOME(d) := od;
      v := AdjacencyList.getVertex(graph, d);
      mi := SBAtomicSet.aset(UnorderedSet.first(SBSet.asets(v.vs)));
      return;
    end if;

    dims := crefDims(Connector.name(conn));

    if listEmpty(dims) then
      vc := Vector.get(vCount, 1);
      Vector.update(vCount, 1, vc + 1);

      mi := SBMultiInterval.fromArray(arrayCreate(Vector.size(vCount), SBInterval.new(vc, 1, vc)));
    else
      ints := arrayCreate(Vector.size(vCount), SBInterval.newEmpty());
      new_vc := Vector.copy(vCount);
      index := 1;

      for dim in dims loop
        if not Dimension.isKnown(dim) then
          Error.assertion(false, getInstanceName() + ": unknown dimension " + Dimension.toString(dim),
                                 sourceInfo());
        end if;

        dim_size := Dimension.size(dim);
        vc := Vector.get(vCount, index);
        int := SBInterval.new(vc, 1, vc + dim_size - 1);

        if SBInterval.isEmpty(int) then
          ints := listArray({});
          break;
        else
          ints[index] := int;
          Vector.update(new_vc, index, vc + dim_size);
        end if;

        index := index + 1;
      end for;

      for i in listLength(dims)+1:Vector.size(vCount) loop
        vc := Vector.get(vCount, 1);
        ints[i] := SBInterval.new(vc, 1, vc);
      end for;

      mi := SBMultiInterval.fromArray(ints);

      if not SBMultiInterval.isEmpty(mi) then
        Vector.swap(new_vc, vCount);
      end if;
    end if;

    s := SBSet.newEmpty();
    s := SBSet.addAtomicSet(SBAtomicSet.new(mi), s);

    v := SET_VERTEX(conn, s);
    d := AdjacencyList.addVertex(graph, v);

    name := Connector.toString(conn) + "$" + Connector.faceString(conn);
    outNmvTable := BaseHashTable.addUnique((name, mi), nmvTable);
  end createVertex;

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

  function evalCrefs
    input output Expression e;
  protected
    function evalCref
      input Expression e;
      output Expression outExp;
    algorithm
      if Expression.isCref(e) then
        outExp := Ceval.evalExp(e, Ceval.EvalTarget.RANGE(AbsynUtil.dummyInfo));
      else
        outExp := e;
      end if;
    end evalCref;
  algorithm
    e := Expression.map(e, evalCref);
  end evalCrefs;

  function intervalFromExp
    input Expression e;
    output SBInterval i;
  algorithm
    i := match e
      case Expression.INTEGER() then SBInterval.new(e.value, 1, e.value);
      case Expression.BOOLEAN() then SBInterval.new(Util.boolInt(e.value), 1, Util.boolInt(e.value));
      case Expression.REAL() then SBInterval.new(realInt(e.value), 1, realInt(e.value));
      case Expression.BINARY() then intervalFromBinaryExp(e.exp1, e.operator, e.exp2);
      case Expression.UNARY() then intervalFromUnaryExp(e.exp);
      case Expression.RANGE() then intervalFromRange(e);
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown expression " +
                                 Expression.toString(e), sourceInfo());
        then
          fail();
    end match;
  end intervalFromExp;

  function intervalFromBinaryExp
    input Expression lhs;
    input Operator op;
    input Expression rhs;
    output SBInterval i;
  protected
    SBInterval lhs_i, rhs_i;
    Integer lhs_sz, rhs_sz, res;
    Integer llo, rlo, lhi, rhi, step;
  algorithm
    lhs_i := intervalFromExp(lhs);
    rhs_i := intervalFromExp(rhs);

    lhs_sz := SBInterval.size(lhs_i);
    rhs_sz := SBInterval.size(rhs_i);

    llo := SBInterval.lowerBound(lhs_i);
    rlo := SBInterval.lowerBound(rhs_i);

    if lhs_sz == 1 and rhs_sz == 1 then
      Expression.INTEGER(value = res) :=
        Ceval.evalBinaryOp_dispatch(Expression.INTEGER(llo), op, Expression.INTEGER(rlo));
      i := SBInterval.new(res, 1, res);
    elseif lhs_sz == 1 or rhs_sz == 1 then
      lhi := SBInterval.upperBound(lhs_i);
      rhi := SBInterval.upperBound(rhs_i);
      step := SBInterval.stepValue(if lhs_sz == 1 then rhs_i else lhs_i);

      i := match op.op
        case Op.ADD then SBInterval.new(llo + rlo, step, lhi + rhi);
        case Op.SUB then SBInterval.new(llo - rlo, step, lhi - rhi);
        case Op.MUL then SBInterval.new(llo * rlo, llo * step, lhi * rhi);
        else
          algorithm
            Error.assertion(false, getInstanceName() +
              " got unknown operator " + Operator.symbol(op), sourceInfo());
          then
            fail();
      end match;
    else
      Error.assertion(false, getInstanceName() + " got unknown expression " +
        Expression.toString(Expression.BINARY(lhs, op, rhs)) + "\n", sourceInfo());
    end if;
  end intervalFromBinaryExp;

  function intervalFromUnaryExp
    input Expression e;
    output SBInterval i;
  algorithm
    i := intervalFromExp(e);
    i := SBInterval.new(-SBInterval.lowerBound(i), 1, -SBInterval.upperBound(i));
  end intervalFromUnaryExp;

  function intervalFromRange
    input Expression e;
    output SBInterval i;
  protected
    Expression start, stop;
    Option<Expression> ostep;
    Integer lo, step, hi;
  algorithm
    Expression.RANGE(start = start, step = ostep, stop = stop) := SimplifyExp.simplify(e);
    lo := Expression.toInteger(start);
    hi := Expression.toInteger(stop);

    if isSome(ostep) then
      step := Expression.toInteger(Util.getOption(ostep));
    else
      step := 1;
    end if;

    i := SBInterval.new(lo, step, hi);
  end intervalFromRange;

  function updateGraph
    input AdjacencyList.VertexDescriptor d1;
    input AdjacencyList.VertexDescriptor d2;
    input SBMultiInterval mi1;
    input SBMultiInterval mi2;
    input SBGraph graph;
    input Vector<Integer> eCount;
  protected
    array<SBInterval> ints1, ints2, mi;
    Integer mi1_sz, mi2_sz, sz, sz1, sz2;
    Integer count, aux_ec;
    array<Real> g1, g2, o1, o2;
    Real g1i, g2i, o1i, o2i;
    SBInterval i1, i2;
    Vector<Integer> new_ec;
    SBSet s;
    SBLinearMap lm1, lm2;
    SBPWLinearMap pw1, pw2;
    String name;
    SetEdge se;
  algorithm
    ints1 := SBMultiInterval.intervals(mi1);
    mi1_sz := SBMultiInterval.size(mi1);

    ints2 := SBMultiInterval.intervals(mi2);
    mi2_sz := SBMultiInterval.size(mi2);

    if SBMultiInterval.ndim(mi1) <> SBMultiInterval.ndim(mi2) and
       mi1_sz <> 1 and mi2_sz <> 1 then
      Error.assertion(false, getInstanceName() + " got incompatible connect", sourceInfo());
    end if;

    sz := arrayLength(ints1);
    g1 := arrayCreateNoInit(sz, 0.0);
    g2 := arrayCreateNoInit(sz, 0.0);
    o1 := arrayCreateNoInit(sz, 0.0);
    o2 := arrayCreateNoInit(sz, 0.0);
    mi := arrayCreateNoInit(sz, ints1[1]);
    new_ec := Vector.new<Integer>();

    for i in 1:sz loop
      sz1 := SBInterval.size(ints1[i]);
      sz2 := SBInterval.size(ints2[i]);

      if sz1 <> sz2 and sz1 <> 1 and sz2 <> 1 then
        Error.assertion(false, getInstanceName() + " got incompatible connect", sourceInfo());
      end if;

      count := max(sz1, sz2);
      aux_ec := Vector.get(eCount, i);
      mi[i] := SBInterval.new(aux_ec, 1, aux_ec + count - 1);

      i1 := ints1[i];
      i2 := ints2[i];

      if sz1 == 1 then
        g1[i] := 0.0;
        o1[i] := SBInterval.lowerBound(i1);
      else
        g1i := SBInterval.stepValue(i1);
        o1i := -g1i * aux_ec + SBInterval.lowerBound(i1);
        g1[i] := g1i;
        o1[i] := o1i;
      end if;

      if sz2 == 1 then
        g2[i] := 0.0;
        o2[i] := SBInterval.lowerBound(i2);
      else
        g2i := SBInterval.stepValue(i2);
        o2i := -g2i * aux_ec + SBInterval.lowerBound(i2);
        g2[i] := g2i;
        o2[i] := o2i;
      end if;

      Vector.push(new_ec, aux_ec + count);
    end for;

    Vector.swap(eCount, new_ec);

    s := SBSet.newEmpty();
    s := SBSet.addAtomicSet(SBAtomicSet.new(SBMultiInterval.fromArray(mi)), s);

    lm1 := SBLinearMap.new(g1, o1);
    lm2 := SBLinearMap.new(g2, o2);

    pw1 := SBPWLinearMap.newScalar(s, lm1);
    pw2 := SBPWLinearMap.newScalar(s, lm2);

    name := "E" + String(System.tmpTick());
    se := SET_EDGE(name, pw1, pw2);
    AdjacencyList.addEdge(graph, d1, d2, se);
  end updateGraph;

  function createMaps
    input SBGraph graph;
    output SBSet vss;
    output SBPWLinearMap emap1;
    output SBPWLinearMap emap2;
  protected
    list<SetVertex> vs;
    list<SetEdge> es;
    SetEdge e;
  algorithm
    vss := SBSet.newEmpty();
    for v in AdjacencyList.vertices(graph) loop
      vss := SBSet.union(vss, v.vs);
    end for;

    es := AdjacencyList.edges(graph);

    if listEmpty(es) then
      emap1 := SBPWLinearMap.newEmpty();
      emap2 := SBPWLinearMap.newEmpty();
    else
      e :: es := AdjacencyList.edges(graph);
      emap1 := e.es1;
      emap2 := e.es2;

      for e in es loop
        emap1 := SBPWLinearMap.combine(e.es1, emap1);
        emap2 := SBPWLinearMap.combine(e.es2, emap2);
      end for;
    end if;
  end createMaps;

  function generateEquations
    input SBPWLinearMap pw;
    input FlatModel flatModel;
    input SBGraph graph;
    input Vector<Integer> vCount;
    input NameVertexTable.Table nmvTable;
    output list<Equation> equations = {};
  protected
    SBSet vc_dom, vc_im, aux_s, vc_domi, vc_domi_aux;
    array<InstNode> iterators;
    list<Variable> pot_vars, flow_vars;
    list<ComponentRef> vars;
    list<Expression> iter_expl;
  algorithm
    vc_dom := SBPWLinearMap.wholeDom(pw);
    vc_im := SBPWLinearMap.image(pw, vc_dom);

    iterators := arrayCreate(Vector.size(vCount), InstNode.EMPTY_NODE());
    for i in 1:arrayLength(iterators) loop
      iterators[i] := InstNode.newIndexedIterator(i);
    end for;

    iter_expl := list(Expression.fromCref(ComponentRef.makeIterator(i, Type.INTEGER())) for i in iterators);

    (pot_vars, flow_vars) := getConnectors(flatModel);

    for aset in UnorderedSet.toArray(SBSet.asets(vc_im)) loop
      aux_s := SBSet.newEmpty();
      aux_s := SBSet.addAtomicSet(aset, aux_s);
      vc_domi := SBPWLinearMap.preImage(pw, aux_s);
      vc_domi_aux := SBSet.complement(vc_domi, aux_s);
      vars := getVars(pot_vars, aux_s, graph);

      equations := generatePotentialEquations(aset, vc_domi_aux, vars, iterators,
        iter_expl, pot_vars, graph, nmvTable, equations);
      equations := generateFlowEquation(aset, vc_domi, iterators, flow_vars, graph, nmvTable, equations);
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
    input list<ComponentRef> vars;
    input array<InstNode> iterators;
    input list<Expression> iterExps;
    input list<Variable> potVars;
    input SBGraph graph;
    input NameVertexTable.Table nmvTable;
    input output list<Equation> equations;
  protected
    SBSet aux_s, sauxi, vc_domi, vc_domi_aux;
    SBMultiInterval mi, mi_range, aux_mi;
    array<SBInterval> inters;
    array<Expression> ranges;
    list<ComponentRef> vars1, vars2;
    list<Equation> eql;
    list<Expression> inds, iter_expl;
  algorithm
    for auxi in UnorderedSet.toArray(SBSet.asets(dom)) loop
      mi := SBAtomicSet.aset(auxi);
      mi_range := applyOffset(mi, getOffset(mi, nmvTable));
      inters := SBMultiInterval.intervals(mi_range);
      ranges := Array.map(inters, intervalToRange);

      sauxi := SBSet.newEmpty();
      sauxi := SBSet.addAtomicSet(auxi, sauxi);
      vars1 := getVars(potVars, sauxi, graph);

      mi := SBAtomicSet.aset(aset);
      aux_mi := applyOffset(mi, getOffset(mi, nmvTable));
      inds := transMulti(mi_range, aux_mi, iterators, false);

      eql := generatePotentialEquations2(vars1, vars, iterExps, inds);
      equations := generateForLoop(eql, iterators, ranges, equations);
    end for;
  end generatePotentialEquations;

  function generatePotentialEquations2
    input list<ComponentRef> vars1;
    input list<ComponentRef> vars2;
    input list<Expression> inds1;
    input list<Expression> inds2;
    output list<Equation> equations = {};
  protected
    Expression l, r;
    Type ty;
    Equation eq;
    DAE.ElementSource src;
  algorithm
    for var1 in vars1 loop
      for var2 in vars2 loop
        if ComponentRef.firstName(var1) == ComponentRef.firstName(var2) then
          l := generateConnector(var1, inds1);
          r := generateConnector(var2, inds2);
          ty := Expression.typeOf(l);

          if Type.isArray(ty) then
            eq := Equation.ARRAY_EQUALITY(l, r, ty, DAE.emptyElementSource);
          else
            eq := Equation.EQUALITY(l, r, ty, DAE.emptyElementSource);
          end if;

          equations := eq :: equations;
        end if;
      end for;
    end for;

    equations := listReverseInPlace(equations);
  end generatePotentialEquations2;

  function generateFlowEquation
    input SBAtomicSet aset;
    input SBSet dom;
    input array<InstNode> iterators;
    input list<Variable> flowVars;
    input SBGraph graph;
    input NameVertexTable.Table nmvTable;
    input output list<Equation> equations;
  protected
    SBMultiInterval mi, mi_range, mi_range2;
    SBSet sauxi;
    array<SBInterval> inters;
    array<Expression> ranges;
    list<Expression> expl, inds;
    Boolean is_sum;
    list<ComponentRef> vars;
    Expression e, sum_exp;
    Type ty;
    Equation eq;
  algorithm
    mi := SBAtomicSet.aset(aset);
    mi_range := applyOffset(mi, getOffset(mi, nmvTable));
    inters := SBMultiInterval.intervals(mi_range);
    ranges := Array.map(inters, intervalToRange);
    expl := {};

    for auxi in UnorderedSet.toArray(SBSet.asets(dom)) loop
      mi := SBAtomicSet.aset(auxi);
      mi_range2 := applyOffset(mi, getOffset(mi, nmvTable));
      (inds, is_sum) := transMulti(mi_range, mi_range2, iterators, true);

      sauxi := SBSet.newEmpty();
      sauxi := SBSet.addAtomicSet(auxi, sauxi);
      vars := getVars(flowVars, sauxi, graph);

      for var in vars loop
        e := generateConnector(var, inds);

        if is_sum then
          e := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.SUM,
            {e}, Expression.variability(e), Purity.PURE, Type.arrayElementType(Expression.typeOf(e))));
        end if;

        expl := e :: expl;
      end for;
    end for;

    if not listEmpty(expl) then
      sum_exp :: expl := expl;

      while not listEmpty(expl) loop
        e :: expl := expl;
        sum_exp := Expression.BINARY(e, Operator.makeAdd(Expression.typeOf(e)), sum_exp);
      end while;

      ty := Expression.typeOf(sum_exp);
      eq := Equation.EQUALITY(sum_exp, Expression.makeZero(ty), ty, DAE.emptyElementSource);
      equations := generateForLoop({eq}, iterators, ranges, equations);
    end if;
  end generateFlowEquation;

  function generateConnector
    input ComponentRef cr;
    input list<Expression> indices;
    output Expression outExp;
  protected
    list<Subscript> subs;
  algorithm
    outExp := Expression.fromCref(cr);

    if Type.isArray(Expression.typeOf(outExp)) then
      subs := list(Subscript.fromTypedExp(i) for i in indices);
      subs := List.firstN(subs, Type.dimensionCount(Expression.typeOf(outExp)));
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
        body := {Equation.FOR(iterators[i], SOME(ranges[i]), body, DAE.emptyElementSource)};
      end if;
    end for;

    equations := List.append_reverse(body, equations);
  end generateForLoop;

  function getConnectors
    input FlatModel flatModel;
    output list<Variable> effVars = {};
    output list<Variable> flowVars = {};
  algorithm
    for v in flatModel.variables loop
      if Variable.isPotential(v) then
        effVars := v :: effVars;
      elseif Variable.isFlow(v) then
        flowVars := v :: flowVars;
      end if;
    end for;

    effVars := listReverseInPlace(effVars);
    flowVars := listReverseInPlace(flowVars);
  end getConnectors;

  function getOffset
    input SBMultiInterval mi;
    input NameVertexTable.Table nmvTable;
    output array<Integer> res;
  protected
    SBMultiInterval i, aux;
  algorithm
    res := listArray({});

    // TODO: Surely this isn't the best way to do this.
    for i in BaseHashTable.hashTableValueList(nmvTable) loop
      aux := SBMultiInterval.intersection(mi, i);

      if not SBMultiInterval.isEmpty(aux) then
        res := SBMultiInterval.minElem(i);
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

  function getVars
    input list<Variable> vars;
    input SBSet sauxi;
    input SBGraph graph;
    output list<ComponentRef> res = {};
  protected
    list<SetVertex> vl;
  algorithm
    vl := AdjacencyList.vertices(graph);
    for v in vl loop
      if not SBSet.isEmpty(SBSet.intersection(v.vs, sauxi)) then
        for var in vars loop
          if ComponentRef.isPrefix(Connector.name(v.name), var.name) then
            res := var.name :: res;
          end if;
        end for;
      end if;
    end for;

    res := listReverseInPlace(res);
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
    Integer i1_sz, i2_sz, m_int, h_int;
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
        Error.assertion(false, getInstanceName() + " got invalid intervals.", sourceInfo());
      end if;
    end for;

    outExpl := listReverseInPlace(outExpl);
  end transMulti;

  annotation(__OpenModelica_Interface="frontend");
end NFArrayConnections;

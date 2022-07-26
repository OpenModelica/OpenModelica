/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBGraphUtil
"file:        NBGraphUtil.mo
 package:     NBGraphUtil
 description: This file contains the functions which perform the causalization process;
"

protected
  // NF import
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import InstNode = NFInstNode.InstNode;
  import Subscript = NFSubscript;
  import Variable = NFVariable;

  // NB import
  import NBEquation.Equation;
  import BVariable = NBVariable;

  // SetBased Graph imports
  import SBGraphUtil = NFSBGraphUtil;
  import SBGraph.BipartiteIncidenceList;
  import SBGraph.VertexDescriptor;
  import SBGraph.SetType;
  import NBAdjacency.BipartiteGraph;
  import SBInterval;
  import SBMultiInterval;
  import SBPWLinearMap;
  import SBSet;
  import NBGraphUtil.{SetVertex, SetEdge};

public
  uniontype SetVertex
    record SET_VERTEX
      Pointer<Variable> name  "can represent variables as well as equations (residual var)";
      SBSet vs                "corresponding set of vertices";
    end SET_VERTEX;

    function hash
      input SetVertex v;
      input Integer mod;
      output Integer i = Variable.hash(Pointer.access(v.name), i);
    end hash;

    function isEqual
      input SetVertex v1;
      input SetVertex v2;
      output Boolean equal = ComponentRef.isEqual(BVariable.getVarName(v1.name), BVariable.getVarName(v2.name));
    end isEqual;

    function isNamed
      input SetVertex v;
      input Pointer<Variable> name;
      output Boolean equal = ComponentRef.isEqual(BVariable.getVarName(v.name), BVariable.getVarName(name));
    end isNamed;

    function getSet
      input SetVertex v;
      output SBSet s = v.vs;
    end getSet;

    function create
      input Pointer<Variable> var_ptr;
      input BipartiteGraph graph;
      input Vector<Integer> vCount;
      input SetType ST;
      input UnorderedMap<SetVertex, Integer> vertexMap;
      output SBMultiInterval mi;
      output Integer d;
    protected
      Option<Integer> od;
      list<Dimension> dims;
      SBSet set;
      SetVertex vertex;
    algorithm
      od := BipartiteIncidenceList.findVertex(graph, ST, function SetVertex.isNamed(name = var_ptr));

      if isSome(od) then
        // vertex already exists
        SOME(d) := od;
        vertex := BipartiteIncidenceList.getVertex(graph, d, ST);
        mi := SBAtomicSet.aset(UnorderedSet.first(SBSet.asets(vertex.vs)));
      else
        // create new vertex
        dims := BVariable.getDimensions(var_ptr);
        mi := SBGraphUtil.multiIntervalFromDimensions(dims, vCount);

        set := SBSet.newEmpty();
        set := SBSet.addAtomicSet(SBAtomicSet.new(mi), set);

        vertex := SET_VERTEX(var_ptr, set);
        d := BipartiteIncidenceList.addVertex(graph, vertex, ST);
        UnorderedMap.add(vertex, d, vertexMap);
      end if;
    end create;

    function createTraverse
      input Pointer<Variable> var_ptr;
      input BipartiteGraph graph;
      input Vector<Integer> vCount;
      input SetType ST;
      input UnorderedMap<SetVertex, Integer> vertexMap;
    algorithm
      (_, _) := create(var_ptr, graph, vCount, ST, vertexMap);
    end createTraverse;

    function toString
      input SetVertex v;
      output String str = Variable.toString(Pointer.access(v.name)) + "\n\t" + SBSet.toString(v.vs);
    end toString;
  end SetVertex;

  uniontype SetEdge
    record SET_EDGE
      String name         "is always E_ + String(System.tmpTick())";
      SBPWLinearMap F;
      SBPWLinearMap U;
    end SET_EDGE;

    function hash
      input SetEdge e;
      input Integer mod;
      output Integer i = stringHashDjb2Mod(e.name, mod);
    end hash;

    function isEqual
      input SetEdge e1;
      input SetEdge e2;
      output Boolean equal = e1.name == e2.name;
    end isEqual;

    function getDomain
      input SetEdge e;
      output array<SBSet> domain = SBPWLinearMap.dom(e.F);
    end getDomain;

    function fromEquation
      input output Equation eqn;
      input BipartiteGraph graph;
      input Vector<Integer> vCount;
      input Vector<Integer> eCount;
      input UnorderedMap<SetVertex, Integer> vertexMap;
      input UnorderedMap<SetEdge, Integer> edgeMap;
      input UnorderedMap<ComponentRef, Integer> map       "unordered map to check for relevance";
      input Option<tuple<SBMultiInterval, Integer>> eqn_tpl_opt;
    protected
      SBMultiInterval eqn_mi;
      Integer eqn_d;
    algorithm
      // only get top level residual var
      if not Util.isSome(eqn_tpl_opt) then
        (eqn_mi, eqn_d) := SetVertex.create(Equation.getResidualVar(Pointer.create(eqn)), graph, vCount, SetType.F, vertexMap);
      else
        SOME((eqn_mi, eqn_d)) := eqn_tpl_opt;
      end if;

      _ := match eqn
        local
          Expression range;
          Equation body;

        case Equation.SCALAR_EQUATION() algorithm
          _ := Equation.map(eqn, function fromExpression(
            eqn_tpl     = (eqn_mi, eqn_d),
            graph       = graph,
            vCount      = vCount,
            eCount      = eCount,
            vertexMap   = vertexMap,
            edgeMap     = edgeMap,
            map         = map)
          );
        then ();

        case Equation.ARRAY_EQUATION() algorithm
          _ := Equation.map(eqn, function fromExpression(
            eqn_tpl     = (eqn_mi, eqn_d),
            graph       = graph,
            vCount      = vCount,
            eCount      = eCount,
            vertexMap   = vertexMap,
            edgeMap     = edgeMap,
            map         = map)
          );
        then ();

        case Equation.FOR_EQUATION() algorithm
          //body := applyIterator(eqn.iter, eqn.range, eqn.body);
          for body in eqn.body loop
            fromEquation(body, graph, vCount, eCount, vertexMap, edgeMap, map, SOME((eqn_mi, eqn_d)));
          end for;
        then ();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed for " + Equation.toString(eqn)});
        then fail();
      end match;
    end fromEquation;

/*
    function applyIterator
      input InstNode iterator;
      input Expression range;
      input output Equation body;
    algorithm
      body := Equation.map(body, function Expression.replaceIterator(iterator = iterator, iteratorValue = range));
    end applyIterator;
*/

    function fromExpression
      input output Expression exp;
      input tuple<SBMultiInterval, Integer> eqn_tpl;
      input BipartiteGraph graph;
      input Vector<Integer> vCount;
      input Vector<Integer> eCount;
      input UnorderedMap<SetVertex, Integer> vertexMap;
      input UnorderedMap<SetEdge, Integer> edgeMap;
      input UnorderedMap<ComponentRef, Integer> map    "unordered map to check for relevance";
    algorithm
      _ := match exp
        local
          ComponentRef cref;
          SBMultiInterval eqn_mi, var_mi;
          VertexDescriptor eqn_d, var_d;

        case Expression.CREF(cref = cref)
          guard(UnorderedMap.contains(ComponentRef.stripSubscriptsAll(cref), map))
          algorithm
            (eqn_mi, eqn_d) := eqn_tpl;
            (var_mi, var_d) := getVariableIntervals(
              var_ptr     = BVariable.getVarPointer(cref),
              subs        = ComponentRef.subscriptsAllFlat(cref), // mby wrong because of empty subs!
              graph       = graph,
              vCount      = vCount,
              ST          = SetType.U,
              vertexMap   = vertexMap
            );
            updateGraph(eqn_d, var_d, eqn_mi, var_mi, graph, eCount, edgeMap);
        then ();

        else ();
      end match;
    end fromExpression;

    function getVariableIntervals
      input Pointer<Variable> var_ptr;
      input list<Subscript> subs;
      input BipartiteGraph graph;
      input Vector<Integer> vCount;
      input SetType ST;
      input UnorderedMap<SetVertex, Integer> vertexMap;
      output SBMultiInterval outMI;
      output VertexDescriptor d;
    algorithm
      (outMI, d) := SetVertex.create(var_ptr, graph, vCount, ST, vertexMap);
      // if there are no subscripts just use full multi interval
      if not listEmpty(subs) then
        outMI := SBGraphUtil.multiIntervalFromSubscripts(subs, vCount, outMI);
      end if;
    end getVariableIntervals;

    function updateGraph
      input VertexDescriptor d1;
      input VertexDescriptor d2;
      input SBMultiInterval mi1;
      input SBMultiInterval mi2;
      input BipartiteGraph graph;
      input Vector<Integer> eCount;
      input UnorderedMap<SetEdge, Integer> edgeMap;
    protected
      SBPWLinearMap pw1, pw2;
      String name;
      SetEdge se;
      Integer edge_i;
    algorithm
      (name, pw1, pw2) := SBGraphUtil.linearMapFromIntervals(d1, d2, mi1, mi2, eCount);
      se := SET_EDGE(name, pw1, pw2);
      edge_i := BipartiteIncidenceList.addEdge(graph, d1, d2, se);
      UnorderedMap.add(se, edge_i, edgeMap);
    end updateGraph;

    function unmatchedU
      "returns unmatched variable vertices U"
      input SetEdge edge                          "edge for which to return vertices";
      input SBSet E_M                             "global matched edges";
      output SBSet unmatched_U = SBSet.newEmpty() "all matched F vertices of this edge";
    protected
      SBPWLinearMap U = edge.U;
      SBSet unmatched_edge;
    algorithm
      for i in 1:U.ndim loop
        // find all edges from the i_th domain that are not matched
        unmatched_edge := SBSet.complement(U.dom[i], E_M);
        // apply map and add to unmatched U vertices
        unmatched_U := SBSet.union(unmatched_U, SBLinearMap.apply(unmatched_edge,U.lmap[i]));
      end for;
    end unmatchedU;

    function minInvU
      input SetEdge E                         "edge for which to return vertices";
      input SBSet U                           "Path vertex set to maximize";
      output SBSet P_max = SBSet.newEmpty()   "Maximized path vertex set";
    protected
      SBPWLinearMap invU = SBPWLinearMap.minInvCompact(E.U);
      SBSet U_tmp;
    algorithm
      for i in 1:invU.ndim loop
        // only consider indices from the current inverse domain
        U_tmp := SBSet.intersection(invU.dom[i], U);
        P_max := SBSet.union(P_max, SBLinearMap.apply(U_tmp, invU.lmap[i]));
      end for;
    end minInvU;

    function matchedF
      "returns matched equation vertices F"
      input SetEdge E                             "edge for which to return vertices";
      input SBSet E_M                             "global matched edges";
      output SBSet matched_F = SBSet.newEmpty()   "all matched F vertices of this edge";
    protected
      SBPWLinearMap F = E.F;
      SBSet matched_E;
    algorithm
      for i in 1:F.ndim loop
        // find all matched indices that are part of i_th domain
        matched_E := SBSet.intersection(F.dom[i], E_M);
        // apply map and add to matched F vertices
        matched_F := SBSet.union(matched_F, SBLinearMap.apply(matched_E, F.lmap[i]));
      end for;
    end matchedF;

    function maxPath
      input SetEdge E                         "edge for which to return vertices";
      input SBSet P1                          "Path index set to maximize";
      input SetType ST          "set type tow know which maps to use";
      output SBSet P1_max = SBSet.newEmpty()  "Maximized path index set";
    algorithm
      P1_max := match ST
        case SetType.U then maxPathU(E, P1);
        case SetType.F then maxPathF(E, P1);
        else algorithm
          Error.assertion(false, getInstanceName() + " failed for unknown SetType: "
             + BipartiteIncidenceList.setTypeString(ST) + ". Allowed: U, F", sourceInfo());
        then fail();
      end match;
    end maxPath;

    function maxPathU
      input SetEdge E                         "edge for which to return vertices";
      input SBSet P1                          "Path index set to maximize";
      output SBSet P1_max = SBSet.newEmpty()  "Maximized path index set";
    protected
      SBPWLinearMap U = E.U;
      SBPWLinearMap invU = SBPWLinearMap.minInvCompact(U);
      SBSet P1_tmp;
    algorithm
      for i in 1:U.ndim loop
        // find all indices that are part of i_th domain
        P1_tmp := SBSet.intersection(U.dom[i], P1);
        // apply map and minimal inverse map
        P1_tmp := SBLinearMap.apply(P1_tmp, U.lmap[i]);
        P1_tmp := SBLinearMap.apply(P1_tmp, invU.lmap[i]);
        // add to maximum path
        P1_max := SBSet.union(P1_max, P1_tmp);
      end for;
    end maxPathU;

    function maxPathF
      input SetEdge E                         "edge for which to return vertices";
      input SBSet P1                          "Path index set to maximize";
      output SBSet P1_max = SBSet.newEmpty()  "Maximized path index set";
    protected
      SBPWLinearMap F = E.F;
      SBPWLinearMap invF = SBPWLinearMap.minInvCompact(F);
      SBSet P1_tmp;
    algorithm
      for i in 1:F.ndim loop
        // find all indices that are part of i_th domain
        P1_tmp := SBSet.intersection(F.dom[i], P1);
        // apply map and minimal inverse map
        P1_tmp := SBLinearMap.apply(P1_tmp, F.lmap[i]);
        P1_tmp := SBLinearMap.apply(P1_tmp, invF.lmap[i]);
        // add to maximum path
        P1_max := SBSet.union(P1_max, P1_tmp);
      end for;
    end maxPathF;

    function toString
      input SetEdge e;
      output String str = e.name
        + "\nmap F:\t" + SBPWLinearMap.toString(e.F)
        + "\nmap U:\t" + SBPWLinearMap.toString(e.U) + "\n";
    end toString;
  end SetEdge;

  annotation(__OpenModelica_Interface="backend");
end NBGraphUtil;
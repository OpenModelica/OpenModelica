/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package NFOCConnectionGraph
" file:        NFOCConnectionGraph.mo
  package:     NFOCConnectionGraph
  description: Constant propagation of expressions


  This module contains a connection breaking algorithm and
  related data structures. The input of the algorithm is
  collected to NFOCConnectionGraph record during instantiation.
  The entry point to the algorithm is findResultGraph.

  The algorithm is implemented using a disjoint-set
  data structure that represents the components of
  elements so far connected.
  Each component has an unique canonical element.
  The data structure is implemented by a hash table, that
  contains an entry for each non-canonical element so that
  a path beginning from some element eventually ends to the
  canonical element of the same component.

  Roots are represented as connections to dummy root
  element. In this way, all elements will be in the
  same component after the algorithm finishes assuming
  that the model is valid.

  TODO! FIXME! adrpo 2014-10-05
  - non standard operators: Connections.uniqueRoot and Connections.uniqueRootIndices are only partially implemented
  - Connections.uniqueRoot currently does nothing, only collects information
  - Connections.uniqueRootIndices needs to be implemented, it returns an array of ones (1) of size of first input
  - See specification for these here (Modelica_StateGraph2):
    https://github.com/modelica/Modelica_StateGraph2 and
    https://trac.modelica.org/Modelica/ticket/984 and
    http://www.ep.liu.se/ecp/043/041/ecp09430108.pdf
  - any takers for the actual implementation? :)

"

public
import FlatModel = NFFlatModel;
import ComponentRef = NFComponentRef;
import Equation = NFEquation;
import NFConnections;

type FlatEdge = NFConnections.BrokenEdge
"a tuple with two crefs and equation(s) for calling the equalityConstraint function call";
type FlatEdges = NFConnections.BrokenEdges
"a lit of broken edges";


protected
import Absyn;
import NFBuiltin;
import Call = NFCall;
import Ceval = NFCeval;
import Class = NFClass;
import Dimension = NFDimension;
import NFFunction.Function;
import NFInstNode.InstNode;
import Operator = NFOperator;
import NFOperator.Op;
import DAE.Connect;
import Expression = NFExpression;
import Type = NFType;
import MetaModelica.Dangerous.listReverseInPlace;
import Connector = NFConnector;
import ElementSource;
import Typing = NFTyping;
import NFPrefixes.Variability;
import Error;
import Connections = NFConnections;
import Connection = NFConnection;
import InstContext = NFInstContext;
import UnorderedMap;

type Edge  = tuple<ComponentRef,ComponentRef> "an edge is a tuple with two component references";
type Edges = list<Edge> "A list of edges";

type DefiniteRoot  = ComponentRef "root defined with Connection.root";
type DefiniteRoots = list<ComponentRef> "roots defined with Connection.root";
type UniqueRoots = list<tuple<ComponentRef,Expression>> "roots defined with Connection.uniqueRoot";

type PotentialRoot = tuple<ComponentRef,Real> "potential root defined with Connections.potentialRoot";
type PotentialRoots = list<tuple<ComponentRef,Real>> "potential roots defined with Connections.potentialRoot";

uniontype NFOCConnectionGraph "Input structure for connection breaking algorithm. It is collected during instantiation phase."
  record GRAPH
    Boolean updateGraph;
    DefiniteRoots definiteRoots "Roots defined with Connection.root";
    PotentialRoots potentialRoots "Roots defined with Connection.potentialRoot";
    UniqueRoots uniqueRoots "Roots defined with Connection.uniqueRoot";
    Edges branches "Edges defined with Connection.branch";
    FlatEdges connections "Edges defined with connect statement";
  end GRAPH;
end NFOCConnectionGraph;

constant NFOCConnectionGraph EMPTY = GRAPH( true, {}, {}, {}, {}, {} ) "Initial connection graph with no edges in it.";

constant NFOCConnectionGraph NOUPDATE_EMPTY = GRAPH( false, {}, {}, {}, {}, {} ) "Initial connection graph with updateGraph set to false.";

type ConnectionsOperator = enumeration(
  BRANCH,
  ROOT,
  POTENTIAL_ROOT,
  IS_ROOT,
  ROOTED,
  UNIQUE_ROOT,
  UNIQUE_ROOT_INDICES,
  NOT_OPERATOR
);

type CrefCrefTable = UnorderedMap<ComponentRef, ComponentRef>;
type CrefIndexTable = UnorderedMap<ComponentRef, Integer>;
type CrefRootsTable = UnorderedMap<ComponentRef, DefiniteRoots>;

public
function handleOverconstrainedConnections
"@author: adrpo
 goes over all equations from the FlatModel and:
 1. builds the overconstrained connection graph from:
   - connect, Connections.branch
   - Connections.root, Connections.potentialRoot
 2. Breaks the overconstrained connection graph
    and replaces the broken connects with a call
    to the equalityConstraint function
 3. using the graph evaluates:
   - Connections.isRoot, Connections.rooted, rooted
 4. partially handles non-standard
   - Connections.uniqueRoot
   - Connections.uniqueRootIndices"
  input output FlatModel flatModel;
  input Connections conns;
  input IsDeleted isDeleted;
  output FlatEdges outBroken;

  partial function IsDeleted
    input ComponentRef cref;
    output Boolean res;
  end IsDeleted;
protected
  ComponentRef lhs, rhs, cref;
  DAE.ElementSource source;
  NFOCConnectionGraph graph = EMPTY;
  list<Equation> eql = {}, eqlBroken, ieql;
  FlatEdges broken, connected;
  Call call;
  list<Expression> lst;
  Integer priority;
  Expression root, msg, arg1, arg2;
  Connector c1, c2;
  list<ComponentRef> lhs_crefs, rhs_crefs;
  Boolean print_trace = Flags.isSet(Flags.CGRAPH);
  InstContext.Type context;
  String name;
algorithm
  context := intBitOr(NFInstContext.EQUATION, NFInstContext.CONNECT);

  // go over all equations, connect, Connection.branch
  for conn in conns.connections loop
    Connection.CONNECTION(lhs = c1, rhs = c2) := conn;

    lhs_crefs := getOverconstrainedCrefs(c1, isDeleted);
    rhs_crefs := getOverconstrainedCrefs(c2, isDeleted);

    if not listEmpty(lhs_crefs) then
      eqlBroken := generateEqualityConstraintEquation(c1.name, c1.ty, c2.name, c2.ty, context, c1.source, isDeleted);
      graph := List.threadFold(lhs_crefs, rhs_crefs,
        function addConnection(brokenEquations = eqlBroken, printTrace = print_trace), graph);
    end if;
  end for;

  for eq in flatModel.equations loop
    eql := match eq
      case Equation.NORETCALL(exp = Expression.CALL(call as Call.TYPED_CALL(arguments = lst)), source = source)
        then match identifyConnectionsOperator(Function.name(call.fn))
          case ConnectionsOperator.ROOT
            algorithm
              {Expression.CREF(cref = cref)} := lst;
              graph := addDefiniteRoot(cref, print_trace, graph);
            then eql;

          case ConnectionsOperator.POTENTIAL_ROOT
            algorithm
              {arg1, arg2} := lst;
              Expression.CREF(cref = cref) := arg1;
              Expression.INTEGER(value = priority) := Ceval.evalExp(arg2);
              graph := addPotentialRoot(cref, priority, print_trace, graph);
            then
              eql;

          case ConnectionsOperator.UNIQUE_ROOT
            algorithm
              graph := match lst
                case {root as Expression.CREF(cref = cref)}
                  then addUniqueRoots(root, Expression.STRING(""), print_trace, graph);
                case {root as Expression.CREF(cref = cref), msg}
                  then addUniqueRoots(root, msg, print_trace, graph);
              end match;
            then eql;

          case ConnectionsOperator.BRANCH
            algorithm
              {Expression.CREF(cref = lhs), Expression.CREF(cref = rhs)} := lst;
              graph := addBranch(lhs, rhs, print_trace, graph);
            then eql;

          else eq :: eql;
        end match;

      else eq::eql;
    end match;
  end for;

  // now we have the graph, remove the broken connects and evaluate the equation operators
  eql := listReverseInPlace(eql);
  ieql := flatModel.initialEquations;
  (eql, ieql, connected, broken) := handleOverconstrainedConnections_dispatch(graph, flatModel.name, eql, ieql);

  eql := removeBrokenConnects(eql, connected, broken, isDeleted);

  flatModel.equations := eql;
  flatModel.initialEquations := ieql;
  outBroken := broken;

end handleOverconstrainedConnections;

function generateEqualityConstraintEquation
  input ComponentRef clhs;
  input Type lhs_ty;
  input ComponentRef crhs;
  input Type rhs_ty;
  input InstContext.Type context;
  input DAE.ElementSource source;
  input IsDeleted isDeleted;
  output list<Equation> eqsEqualityConstraint = {};

  partial function IsDeleted
    input ComponentRef cref;
    output Boolean res;
  end IsDeleted;
protected
  ComponentRef lhs, rhs, fcref_rhs, fcref_lhs, lhsArr, rhsArr;
  Type ty, ty1, ty2;
  Integer priority;
  list<Connection> conns;
  Expression root, msg;
  Equation replaceEq;
  Expression expLHS, expRHS;
  InstNode fn_node_lhs, fn_node_rhs;
  Variability var;
algorithm
  if not System.getHasOverconstrainedConnectors() then
    return;
  end if;

  conns := NFConnections.makeConnections(clhs, lhs_ty, crhs, rhs_ty, source, isDeleted);

  for c in conns loop
    for sconn in Connection.split(c) loop
      for conn in Connection.scalarizePrefix(sconn) loop
        lhs := Connector.name(conn.lhs);
        rhs := Connector.name(conn.rhs);

        if isOverconstrainedCref(lhs) and isOverconstrainedCref(rhs) then
          lhs := getOverconstrainedCref(lhs);
          rhs := getOverconstrainedCref(rhs);

          lhsArr := ComponentRef.stripSubscripts(lhs);
          rhsArr := ComponentRef.stripSubscripts(rhs);

          ty1 := ComponentRef.getComponentType(lhsArr);
          ty2 := ComponentRef.getComponentType(rhsArr);

          fcref_rhs := Function.lookupFunctionSimple("equalityConstraint", InstNode.classScope(ComponentRef.node(lhs)), context);
          (fcref_rhs, fn_node_rhs, _) := Function.instFunctionRef(fcref_rhs, context, ElementSource.getInfo(source));
          expRHS := Expression.CALL(Call.UNTYPED_CALL(fcref_rhs, {Expression.CREF(ty1, lhsArr), Expression.CREF(ty2, rhsArr)}, {}, fn_node_rhs));

          (expRHS, ty, var) := Typing.typeExp(expRHS, context, ElementSource.getInfo(source));

          fcref_lhs := Function.lookupFunctionSimple("fill", InstNode.topScope(ComponentRef.node(lhs)), context);
          (fcref_lhs, fn_node_lhs, _) := Function.instFunctionRef(fcref_lhs, context, ElementSource.getInfo(source));
          expLHS := Expression.CALL(Call.UNTYPED_CALL(fcref_lhs, Expression.REAL(0.0)::List.map(Type.arrayDims(ty), Dimension.sizeExp), {}, fn_node_lhs));

          (expLHS, ty, var) := Typing.typeExp(expLHS, context, ElementSource.getInfo(source));

          replaceEq := Equation.EQUALITY(expRHS, expLHS, ty, InstNode.EMPTY_NODE(), source);

          eqsEqualityConstraint := {replaceEq};

          return;
        end if;
      end for;
    end for;
  end for;
end generateEqualityConstraintEquation;

protected

function getOverconstrainedCrefs
  input Connector conn;
  input IsDeleted isDeleted;
  output list<ComponentRef> crefs;

  partial function IsDeleted
    input ComponentRef cref;
    output Boolean res;
  end IsDeleted;
protected
  list<Connector> conns;
algorithm
  conns := Connector.split(conn);
  conns := List.mapFlat(conns, Connector.scalarizePrefix);
  crefs := list(getOverconstrainedCref(c.name) for c
    guard not isDeleted(c.name) and isOverconstrainedCref(c.name) in conns);
  crefs := List.uniqueOnTrue(crefs, ComponentRef.isEqual);
end getOverconstrainedCrefs;

function isOverconstrainedCref
  input ComponentRef cref;
  output Boolean b = false;
protected
  InstNode node;
  ComponentRef rest;
algorithm
    b := match cref
      case ComponentRef.CREF(node = node, origin = NFComponentRef.Origin.CREF, restCref = rest)
        then Class.isOverdetermined(InstNode.getClass(node)) or isOverconstrainedCref(rest);
      else false;
    end match;
end isOverconstrainedCref;

function getOverconstrainedCref
  input ComponentRef cref;
  output ComponentRef c;
protected
  InstNode node;
  ComponentRef rest;
algorithm
    c := match cref
      case ComponentRef.CREF(node = node, origin = NFComponentRef.Origin.CREF, restCref = rest)
        then
          if Class.isOverdetermined(InstNode.getClass(node)) then cref else getOverconstrainedCref(rest);
    end match;
end getOverconstrainedCref;

function handleOverconstrainedConnections_dispatch
"author: adrpo
 this function gets the connection graph and the existing DAE and:
 - returns a list of broken connects and one list of connected connects
 - evaluates Connections.isRoot in the input DAE
 - evaluates Connections.uniqueRootIndices in the input DAE
 - evaluates the rooted operator in the input DAE"
  input NFOCConnectionGraph inGraph;
  input String modelNameQualified;
  input list<Equation> inEquations;
  input list<Equation> inInitialEquations;
  output list<Equation> outEquations;
  output list<Equation> outInitialEquations;
  output FlatEdges outConnected;
  output FlatEdges outBroken;
algorithm
  (outEquations, outInitialEquations, outConnected, outBroken) := matchcontinue(inGraph, modelNameQualified, inEquations, inInitialEquations)
    local
      NFOCConnectionGraph graph;
      list<Equation> eqs, ieqs;
      list<ComponentRef> roots;
      FlatEdges broken, connected;

    // handle the connection breaking
    case (graph, _, eqs, ieqs)
      algorithm
        if Flags.isSet(Flags.CGRAPH) then
          print("Summary: \n\t" +
           "Nr Roots:           " + intString(listLength(getDefiniteRoots(graph))) + "\n\t" +
           "Nr Potential Roots: " + intString(listLength(getPotentialRoots(graph))) + "\n\t" +
           "Nr Unique Roots:    " + intString(listLength(getUniqueRoots(graph))) + "\n\t" +
           "Nr Branches:        " + intString(listLength(getBranches(graph))) + "\n\t" +
           "Nr Connections:     " + intString(listLength(getConnections(graph))) + "\n");
        end if;

        (roots, connected, broken) := findResultGraph(graph, modelNameQualified);

        if Flags.isSet(Flags.CGRAPH) then
          print("Roots: " + stringDelimitList(List.map(roots, ComponentRef.toString), ", ") + "\n");
          print("Broken connections: " + stringDelimitList(List.map1(broken, printConnectionStr, "broken"), ", ") + "\n");
          print("Allowed connections: " + stringDelimitList(List.map1(connected, printConnectionStr, "allowed"), ", ") + "\n");
        end if;

        eqs := evalConnectionsOperators(roots, graph, eqs);
        ieqs := evalConnectionsOperators(roots, graph, ieqs);
      then
        (eqs, ieqs, connected, broken);

    // handle the connection breaking
    else
      algorithm
        true := Flags.isSet(Flags.CGRAPH);
        print("- NFOCConnectionGraph.handleOverconstrainedConnections failed for model: " + modelNameQualified + "\n");
      then
        fail();
  end matchcontinue;
end handleOverconstrainedConnections_dispatch;

function addDefiniteRoot
  "Adds a new definite root to NFOCConnectionGraph"
  input ComponentRef root;
  input Boolean printTrace;
  input output NFOCConnectionGraph graph;
algorithm
  if printTrace then
    print("- NFOCConnectionGraph.addDefiniteRoot(" + ComponentRef.toString(root) + ")\n");
  end if;

  graph.definiteRoots := root :: graph.definiteRoots;
end addDefiniteRoot;

function addPotentialRoot
  "Adds a new potential root to NFOCConnectionGraph"
  input ComponentRef root;
  input Real priority;
  input Boolean printTrace;
  input output NFOCConnectionGraph graph;
algorithm
  if printTrace then
    print("- NFOCConnectionGraph.addPotentialRoot(" + ComponentRef.toString(root) +
          ", " + realString(priority) + ")" + "\n");
  end if;

  graph.potentialRoots := (root, priority) :: graph.potentialRoots;
end addPotentialRoot;

function addUniqueRoots
  "Adds a new unique root to NFOCConnectionGraph"
  input Expression roots;
  input Expression message;
  input Boolean printTrace;
  input output NFOCConnectionGraph graph;
protected
  UniqueRoots unique_roots = graph.uniqueRoots;
algorithm
  for root in Expression.arrayScalarElements(roots) loop
    unique_roots := match root
      case Expression.CREF()
        algorithm
          if printTrace then
            print("- NFOCConnectionGraph.addUniqueRoots(" + Expression.toString(root) +
                  ", " + Expression.toString(message) + ")\n");
          end if;
        then
          (root.cref, message) :: unique_roots;

      else
        algorithm
          // TODO! FIXME! print some meaningful error message here that the input is not an array of roots or a cref
        then
          unique_roots;

    end match;
  end for;
end addUniqueRoots;

function addBranch
  input ComponentRef ref1;
  input ComponentRef ref2;
  input Boolean printTrace;
  input output NFOCConnectionGraph graph;
algorithm
  if printTrace then
    print("- NFOCConnectionGraph.addBranch(" + ComponentRef.toString(ref1) + ", " + ComponentRef.toString(ref2) + ")\n");
  end if;

  graph.branches := (ref1, ref2) :: graph.branches;
end addBranch;

function addConnection
  "Adds a new connection to NFOCConnectionGraph"
  input ComponentRef ref1;
  input ComponentRef ref2;
  input list<Equation> brokenEquations;
  input Boolean printTrace;
  input output NFOCConnectionGraph graph;
algorithm
  if printTrace then
    print("- NFOCConnectionGraph.addConnection(" + ComponentRef.toString(ref1) + ", " + ComponentRef.toString(ref2) + ")\n");
  end if;

  graph.connections := (ref1, ref2, brokenEquations) :: graph.connections;
end addConnection;

// ************************************* //
// ********* protected section ********* //
// ************************************* //

protected import Debug;
protected import Flags;
protected import List;
protected import Util;
protected import System;
protected import IOStream;
protected import Settings;

protected function canonical
"Returns the canonical element of the component where input element belongs to.
 See explanation at the top of file."
  input CrefCrefTable inPartition;
  input ComponentRef inRef;
  output ComponentRef outCanonical;
protected
  Option<ComponentRef> cref_opt;

  ComponentRef parent, parentCanonical;
algorithm
  cref_opt := UnorderedMap.get(inRef, inPartition);

  outCanonical := match cref_opt
    case SOME(outCanonical) then canonical(inPartition, outCanonical);
    else inRef;
  end match;
end canonical;

protected function areInSameComponent
"Tells whether the elements belong to the same component.
 See explanation at the top of file."
  input CrefCrefTable partition;
  input ComponentRef ref1;
  input ComponentRef ref2;
  output Boolean outResult;
algorithm
  outResult := ComponentRef.isEqual(canonical(partition, ref1),
                                    canonical(partition, ref2));
end areInSameComponent;


protected function connectBranchComponents
"Tries to connect two components whose elements are given. Depending
 on wheter the connection success or not (i.e are the components already
 connected), adds either inConnectionDae or inBreakDae to the list of
 DAE elements."
  input CrefCrefTable partition;
  input ComponentRef ref1;
  input ComponentRef ref2;
algorithm
  connectCanonicalComponents(partition,
    canonical(partition, ref1), canonical(partition, ref2));
end connectBranchComponents;

protected function connectComponents
"Tries to connect two components whose elements are given. Depending
 on wheter the connection success or not (i.e are the components already
 connected), adds either inConnectionDae or inBreakDae to the list of
 DAE elements."
  input CrefCrefTable partition;
  input FlatEdge inFlatEdge;
  output FlatEdges outConnectedConnections;
  output FlatEdges outBrokenConnections;
algorithm
  (outConnectedConnections,outBrokenConnections) := matchcontinue inFlatEdge
    local
      ComponentRef ref1, ref2, canon1, canon2;

    // leave the connect(ref1,ref2)
    case ((ref1,_,_))
      equation
        failure(_ = canonical(partition,ref1)); // no parent
      then ({inFlatEdge}, {});

    // leave the connect(ref1,ref2)
    case ((_,ref2,_))
      equation
        failure(_ = canonical(partition,ref2)); // no parent
      then ({inFlatEdge}, {});

    // leave the connect(ref1,ref2)
    case ((ref1,ref2,_))
      equation
        canon1 = canonical(partition,ref1);
        canon2 = canonical(partition,ref2);
        true = connectCanonicalComponents(partition,canon1,canon2);
      then ({inFlatEdge}, {});

    // break the connect(ref1, ref2)
    case ((ref1,ref2,_))
      equation
        // debug print
        if Flags.isSet(Flags.CGRAPH) then
          Debug.trace("- NFOCConnectionGraph.connectComponents: should remove equations generated from: connect(" +
             ComponentRef.toString(ref1) + ", " +
             ComponentRef.toString(ref2) + ") and add {0, ..., 0} = equalityConstraint(cr1, cr2) instead.\n");
        end if;
      then ({}, {inFlatEdge});
  end matchcontinue;
end connectComponents;

protected function connectCanonicalComponents
"Tries to connect two components whose canonical elements are given.
 Helper function for connectionComponents."
  input CrefCrefTable inPartition;
  input ComponentRef inRef1;
  input ComponentRef inRef2;
  output Boolean outReallyConnected;
algorithm
  outReallyConnected := not ComponentRef.isEqual(inRef1, inRef2);

  if outReallyConnected then
    UnorderedMap.add(inRef1, inRef2, inPartition);
  end if;
end connectCanonicalComponents;

protected function addRootsToTable
"Adds a root the the graph. This is implemented by connecting the root to inFirstRoot element."
  input CrefCrefTable table;
  input list<ComponentRef> roots;
  input ComponentRef firstRoot;
protected
  ComponentRef root;
  list<ComponentRef> rest_roots;
algorithm
  for root in roots loop
    UnorderedMap.add(root, firstRoot, table);
  end for;
end addRootsToTable;

protected function resultGraphWithRoots
"Creates an initial graph with given definite roots."
  input list<ComponentRef> roots;
  output CrefCrefTable outTable;
protected
  ComponentRef dummyRoot;
algorithm
  dummyRoot := NFBuiltin.TIME_CREF;
  outTable := newCrefCrefTable();
  addRootsToTable(outTable, roots, dummyRoot);
end resultGraphWithRoots;

protected function addBranchesToTable
"Adds all branches to the graph."
  input CrefCrefTable table;
  input Edges branches;
protected
  ComponentRef ref1, ref2;
algorithm
  for branch in branches loop
    (ref1, ref2) := branch;
    connectBranchComponents(table, ref1, ref2);
  end for;
end addBranchesToTable;

protected function ord
"An ordering function for potential roots."
  input PotentialRoot inEl1;
  input PotentialRoot inEl2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inEl1, inEl2)
    local
      Real r1, r2;
      ComponentRef c1, c2;
      String s1, s2;

    case((c1,r1), (c2,r2)) // if equal order by cref
      equation
        true = realEq(r1, r2);
        s1 = ComponentRef.toString(c1);
        s2 = ComponentRef.toString(c2);
        1 = stringCompare(s1, s2);
      then
        true;

    case((_,r1), (_,r2))
      then r1 > r2;
  end matchcontinue;
end ord;

protected function addPotentialRootsToTable
"Adds all potential roots to graph."
  input CrefCrefTable table;
  input PotentialRoots potentialRoots;
  input DefiniteRoots roots;
  input ComponentRef firstRoot;
  output DefiniteRoots outRoots;
algorithm
  outRoots := matchcontinue potentialRoots
    local
      ComponentRef potentialRoot, canon1, canon2;
      DefiniteRoots finalRoots;
      PotentialRoots tail;

    case {} then roots;
    case ((potentialRoot,_)::tail)
      algorithm
        canon1 := canonical(table, potentialRoot);
        canon2 := canonical(table, firstRoot);
        true := connectCanonicalComponents(table, canon1, canon2);
        finalRoots := addPotentialRootsToTable(table, tail, potentialRoot::roots, firstRoot);
      then finalRoots;
    case _::tail
      algorithm
        finalRoots := addPotentialRootsToTable(table, tail, roots, firstRoot);
      then finalRoots;
  end matchcontinue;
end addPotentialRootsToTable;

protected function addConnections
"Adds all connections to graph."
  input CrefCrefTable inTable;
  input FlatEdges inConnections;
  output FlatEdges outConnectedConnections;
  output FlatEdges outBrokenConnections;
algorithm
  (outConnectedConnections, outBrokenConnections) := match(inTable, inConnections)
    local
      CrefCrefTable table;
      FlatEdges tail;
      FlatEdges broken1,broken2,broken,connected1,connected2,connected;
      FlatEdge e;

    // empty case
    case(table, {}) then ({}, {});
    // normal case
    case(table, e::tail)
      equation
        (connected1, broken1) = connectComponents(table, e);
        (connected2, broken2) = addConnections(table, tail);
        connected = listAppend(connected1, connected2);
        broken = listAppend(broken1, broken2);
      then (connected, broken);
  end match;
end addConnections;

protected function findResultGraph
"Given NFOCConnectionGraph structure, breaks all connections,
 determines roots and generates a list of dae elements."
  input  NFOCConnectionGraph inGraph;
  input  String modelNameQualified;
  output DefiniteRoots outRoots;
  output FlatEdges outConnectedConnections;
  output FlatEdges outBrokenConnections;
algorithm
  (outRoots, outConnectedConnections, outBrokenConnections) := matchcontinue(inGraph, modelNameQualified)
    local
      DefiniteRoots definiteRoots, finalRoots;
      PotentialRoots potentialRoots, orderedPotentialRoots;
      UniqueRoots uniqueRoots;
      Edges branches;
      FlatEdges connections, broken, connected;
      CrefCrefTable table;
      ComponentRef dummyRoot;
      String brokenConnectsViaGraphViz;
      list<String> userBrokenLst;
      list<list<String>> userBrokenLstLst;
      list<tuple<String,String>> userBrokenTplLst;

    // deal with empty connection graph
    case (GRAPH(definiteRoots = {}, potentialRoots = {}, uniqueRoots = {}, branches = {}, connections = {}), _)
      then ({}, {}, {});

    // we have something in the connection graph
    case (GRAPH(definiteRoots = definiteRoots, potentialRoots = potentialRoots, uniqueRoots = uniqueRoots,
                   branches = branches, connections = connections), _)
      equation
        // reverse the conenction list to have them as in the model
        connections = listReverse(connections);
        // add definite roots to the table
        table = resultGraphWithRoots(definiteRoots);
        // add branches to the table
        addBranchesToTable(table, branches);
        // order potential roots in the order or priority
        orderedPotentialRoots = List.sort(potentialRoots, ord);

        if Flags.isSet(Flags.CGRAPH) then
          print("Ordered Potential Roots: " + stringDelimitList(List.map(orderedPotentialRoots, printPotentialRootTuple), ", ") + "\n");
        end if;

        // add connections to the table and return the broken/connected connections
        (connected, broken) = addConnections(table, connections);

        // create a dummy root
        dummyRoot = NFBuiltin.TIME_CREF;
        // select final roots
        finalRoots = addPotentialRootsToTable(table, orderedPotentialRoots, definiteRoots, dummyRoot);

        // generate the graphviz representation and display
        brokenConnectsViaGraphViz = generateGraphViz(modelNameQualified, definiteRoots, potentialRoots, uniqueRoots, branches, connections, finalRoots, broken);

        if stringEq(brokenConnectsViaGraphViz, "")
        then
          // if brokenConnectsViaGraphViz is empty, the user wants to use the current breaking!
        else
          // interpret brokenConnectsViaGraphViz and pass it to the breaking algorithm again
          // graphviz returns the broken connects as: cr1|cr2#cr3|cr4#
          userBrokenLst = Util.stringSplitAtChar(brokenConnectsViaGraphViz, "#");
          userBrokenLstLst = List.map1(userBrokenLst, Util.stringSplitAtChar, "|");
          userBrokenTplLst = makeTuple(userBrokenLstLst);
          print("User selected the following connect edges for breaking:\n\t" + stringDelimitList(List.map(userBrokenTplLst, printTupleStr), "\n\t") + "\n");
          // print("\nBefore ordering:\n");
          printFlatEdges(connections);
          // order the connects with the input given by the user!
          connections = orderConnectsGuidedByUser(connections, userBrokenTplLst);
          // reverse the reverse! uh oh!
          connections = listReverse(connections);
          print("\nAfer ordering:\n");
          // printFlatEdges(connections);
          // call findResultGraph again with ordered connects!
          (finalRoots, connected, broken) =
             findResultGraph(GRAPH(false, definiteRoots, potentialRoots, uniqueRoots, branches, connections), modelNameQualified);
        end if;

      then
        (finalRoots, connected, broken);

  end matchcontinue;
end findResultGraph;

protected function orderConnectsGuidedByUser
  input FlatEdges inConnections;
  input list<tuple<String,String>> inUserSelectedBreaking;
  output FlatEdges outOrderedConnections;
protected
  FlatEdges front = {};
  FlatEdges back = {};
  ComponentRef c1, c2;
  String sc1,sc2;
algorithm
  for e in inConnections loop
    (c1, c2, _) := e;
    sc1 := ComponentRef.toString(c1);
    sc2 := ComponentRef.toString(c2);

    if listMember((sc1, sc2), inUserSelectedBreaking) or listMember((sc2, sc1), inUserSelectedBreaking) then
      // put them at the end to be tried last (more chance to be broken)
      back := e::back;
    else
      // put them at the front to be tried first (less chance to be broken)
      front := e::front;
    end if;
  end for;
  outOrderedConnections := List.append_reverse(front, back);
end orderConnectsGuidedByUser;

protected function printTupleStr
  input tuple<String,String> inTpl;
  output String out;
algorithm
  out := match(inTpl)
    local
      String c1,c2;
    case ((c1,c2)) then c1 + " -- " + c2;
  end match;
end printTupleStr;

protected function makeTuple
  input list<list<String>> inLstLst;
  output list<tuple<String,String>> outLst;
algorithm
  outLst := matchcontinue(inLstLst)
    local
      String c1,c2;
      list<list<String>> rest;
      list<tuple<String,String>> lst;
      list<String> bad;

    // empty case
    case ({}) then {};
    // somthing case
    case ({c1,c2}::rest)
      equation
        lst = makeTuple(rest);
      then
        (c1,c2)::lst;
    // ignore empty strings
    case ({""}::rest)
      equation
        lst = makeTuple(rest);
      then
        lst;
    // ignore empty list
    case ({}::rest)
      equation
        lst = makeTuple(rest);
      then
        lst;
    // somthing case
    case (bad::rest)
      equation
        print("The following output from GraphViz OpenModelica assistant cannot be parsed:" +
            stringDelimitList(bad, ", ") +
            "\nExpected format from GrapViz: cref1|cref2#cref3|cref4#. Ignoring malformed input.\n");
        lst = makeTuple(rest);
      then
        lst;
  end matchcontinue;
end makeTuple;

protected function printPotentialRootTuple
  input PotentialRoot potentialRoot;
  output String outStr;
algorithm
  outStr := match(potentialRoot)
    local
      ComponentRef cr;
      Real priority;
      String str;
    case ((cr, priority))
      equation
        str = ComponentRef.toString(cr) + "(" + realString(priority) + ")";
      then str;
  end match;
end printPotentialRootTuple;

protected function setRootDistance
  input list<ComponentRef> finalRoots;
  input CrefRootsTable table;
  input Integer distance;
  input list<ComponentRef> nextLevel;
  input CrefIndexTable rooted;
algorithm
  () := matchcontinue(finalRoots,nextLevel)
    local
      list<ComponentRef> rest,next;
      ComponentRef cr;
    case({},{}) then ();
    case({},_)
      algorithm
        setRootDistance(nextLevel,table,distance+1,{},rooted);
      then
        ();
    case(cr::rest,_)
      equation
        false = UnorderedMap.contains(cr, rooted);
        UnorderedMap.add(cr,distance,rooted);
        next = UnorderedMap.getOrFail(cr, table);
        //print("- NFOCConnectionGraph.setRootDistance: Set Distance " +
        //   ComponentRef.toString(cr) + " , " + intString(distance) + "\n");
        //print("- NFOCConnectionGraph.setRootDistance: add " +
        //   stringDelimitList(List.map(next,ComponentRef.toString),"\n") + " to the queue\n");
        next = listAppend(nextLevel,next);
        setRootDistance(rest,table,distance,next,rooted);
      then
        ();
    case(cr::rest,_)
      equation
        false = UnorderedMap.contains(cr, rooted);
        UnorderedMap.add(cr,distance,rooted);
        //print("- NFOCConnectionGraph.setRootDistance: Set Distance " +
        //   ComponentRef.toString(cr) + " , " + intString(distance) + "\n");
        setRootDistance(rest,table,distance,nextLevel,rooted);
      then
        ();
/*    case(cr::rest,_,_,_,_)
      equation
        print("- NFOCConnectionGraph.setRootDistance: found " +
           ComponentRef.toString(cr) + " twice, value is " + intString(i) + "\n");
      then
        setRootDistance(rest,table,distance,nextLevel,rooted);
*/
    case (_::rest,_)
      algorithm
      //  print("- NFOCConnectionGraph.setRootDistance: cannot found " + ComponentRef.toString(cr) + "\n");
        setRootDistance(rest,table,distance,nextLevel,rooted);
      then
        ();
  end matchcontinue;
end setRootDistance;

protected function addBranches
  input Edge edge;
  input CrefRootsTable table;
protected
  ComponentRef cref1,cref2;
algorithm
  (cref1,cref2) := edge;
  addConnectionRooted(cref1,cref2,table);
  addConnectionRooted(cref2,cref1,table);
end addBranches;

protected function addConnectionsRooted
  input FlatEdge connection;
  input CrefRootsTable table;
protected
  ComponentRef cref1,cref2;
algorithm
  (cref1,cref2,_) := connection;
  addConnectionRooted(cref1,cref2,table);
  addConnectionRooted(cref2,cref1,table);
end addConnectionsRooted;

protected function addConnectionRooted
  input ComponentRef cref1;
  input ComponentRef cref2;
  input CrefRootsTable table;

  function updateRooted
    input Option<DefiniteRoots> roots;
    input ComponentRef newRoot;
    output DefiniteRoots outRoots;
  algorithm
    outRoots := match roots
      case SOME(outRoots) then newRoot :: outRoots;
      else {newRoot};
    end match;
  end updateRooted;
algorithm
  UnorderedMap.addUpdate(cref1, function updateRooted(newRoot = cref2), table);
end addConnectionRooted;

protected function evalConnectionsOperators
"evaluation of Connections.rooted, Connections.isRoot, Connections.uniqueRootIndices
 - replaces all [Connections.]rooted calls by true or false depending on wheter branche frame_a or frame_b is closer to root
 - return true or false for Connections.isRoot operator if is a root or not
 - return an array of indices for Connections.uniqueRootIndices, see Modelica_StateGraph2
   See Modelica_StateGraph2:
    https://github.com/modelica/Modelica_StateGraph2 and
    https://trac.modelica.org/Modelica/ticket/984 and
    http://www.ep.liu.se/ecp/043/041/ecp09430108.pdf
   for a specification of this operator"
  input list<ComponentRef> inRoots;
  input NFOCConnectionGraph graph;
  input list<Equation> inEquations;
  output list<Equation> outEquations;
algorithm
  outEquations := matchcontinue(inRoots,graph,inEquations)
    local
      CrefIndexTable rooted;
      CrefRootsTable table;
      Edges branches;
      FlatEdges connections;

    case (_,_, {}) then {};

    else
      equation
        // built table
        table = newCrefRootsTable();
        // add branches to table
        branches = getBranches(graph);
        List.map1_0(branches, addBranches, table);
        // add connections to table
        connections = getConnections(graph);
        List.map1_0(connections, addConnectionsRooted, table);
        // get distance to root
        //  print("Roots: " + stringDelimitList(List.map(inRoots,ComponentRef.toString),"\n") + "\n");
        rooted = newCrefIndexTable();
        setRootDistance(inRoots, table, 0, {}, rooted);
        outEquations = list(Equation.mapExp(eq,
            function evaluateOperators(rooted = rooted, roots = inRoots, graph = graph, info = Equation.info(eq)))
          for eq in inEquations);
      then outEquations;

  end matchcontinue;
end evalConnectionsOperators;

function evaluateOperators
  input output Expression exp;
  input CrefIndexTable rooted;
  input list<ComponentRef> roots;
  input NFOCConnectionGraph graph;
  input SourceInfo info;
algorithm
  exp := Expression.map(exp,
    function evalConnectionsOperatorsHelper(rooted = rooted, roots = roots, graph = graph, info = info));
end evaluateOperators;

protected function evalConnectionsOperatorsHelper
"Helper function for evaluation of Connections.rooted, Connections.isRoot, Connections.uniqueRootIndices"
  input Expression exp;
  input CrefIndexTable rooted;
  input list<ComponentRef> roots;
  input NFOCConnectionGraph graph;
  input SourceInfo info;
  output Expression outExp;
algorithm
  outExp := match exp
    local
      Expression uroots, nodes, message, res;
      ComponentRef cref,cref1;
      Boolean result;
      Edges branches;
      list<Expression> lst;
      Call call;
      String str;
      Dimension dim;

    case Expression.CALL(call = call as Call.TYPED_CALL())
      then match identifyConnectionsOperator(Function.name(call.fn))
        // handle rooted - with zero size array or the normal call
        case ConnectionsOperator.ROOTED
          algorithm
            res := match call.arguments
              // zero size array TODO! FIXME! check how zero size arrays are handled in the NF
              case _ guard Expression.isEmptyArray(listHead(call.arguments))
                equation
                  if Flags.isSet(Flags.CGRAPH) then
                    print("- NFOCConnectionGraph.evalConnectionsOperatorsHelper: " + Expression.toString(exp) + " = false\n");
                  end if;
                then
                  Expression.BOOLEAN(false);

              // normal call
              case {Expression.CREF(cref = cref)}
                algorithm
                  // find partner in branches
                  branches := getBranches(graph);
                  cref := ComponentRef.stripIteratorSubscripts(cref);

                  try
                    cref1 := getEdge(cref,branches);
                    // print("- NFOCConnectionGraph.evalConnectionsOperatorsHelper: Found Branche Partner " +
                    //   ComponentRef.toString(cref) + ", " + ComponentRef.toString(cref1) + "\n");
                    if Flags.isSet(Flags.CGRAPH) then
                      print("- NFOCConnectionGraph.evalConnectionsOperatorsHelper: Found Branche Partner " +
                        ComponentRef.toString(cref) + ", " + ComponentRef.toString(cref1) + "\n");
                    end if;
                    result := getRooted(cref,cref1,rooted);
                    //print("- NFOCConnectionGraph.evalRootedAndIsRootHelper: " +
                    //   ComponentRef.toString(cref) + " is " + boolString(result) + " rooted\n");
                    if Flags.isSet(Flags.CGRAPH) then
                      print("- NFOCConnectionGraph.evalConnectionsOperatorsHelper: " + Expression.toString(exp) + " = " + boolString(result) + "\n");
                    end if;
                  else // add an error message:
                    str := ComponentRef.toString(cref);
                    Error.addSourceMessage(Error.OCG_MISSING_BRANCH, {str, str, str}, info);
                    result := false;
                  end try;
                then
                  Expression.BOOLEAN(result);
            end match;
          then
            res;

        // deal with Connections.isRoot - with zero size array and normal
        case ConnectionsOperator.IS_ROOT
          algorithm
            res := match call.arguments
              // zero size array TODO! FIXME! check how zero size arrays are handled in the NF
              case _ guard Expression.isEmptyArray(listHead(call.arguments))
                algorithm
                  if Flags.isSet(Flags.CGRAPH) then
                    print("- NFOCConnectionGraph.evalConnectionsOperatorsHelper: " + Expression.toString(exp) + " = false\n");
                  end if;
                then
                  Expression.BOOLEAN(false);

              // normal call
              case {Expression.CREF(cref = cref)}
                algorithm
                  cref := ComponentRef.stripIteratorSubscripts(cref);
                  result := List.isMemberOnTrue(cref, roots, ComponentRef.isEqual);
                  if Flags.isSet(Flags.CGRAPH) then
                    print("- NFOCConnectionGraph.evalConnectionsOperatorsHelper: " + Expression.toString(exp) + " = " + boolString(result) + "\n");
                  end if;
                then
                  Expression.BOOLEAN(result);
            end match;
          then
            res;

        // deal with Connections.uniqueRootIndices, TODO! FIXME! actually implement this
        case ConnectionsOperator.UNIQUE_ROOT_INDICES
          algorithm
            res := match call.arguments
              // normal call
              case {uroots,nodes,message}
                algorithm
                  if Flags.isSet(Flags.CGRAPH) then
                    print("- NFOCConnectionGraph.evalConnectionsOperatorsHelper: Connections.uniqueRootsIndices(" +
                      Expression.toString(uroots) + "," +
                      Expression.toString(nodes) + "," +
                      Expression.toString(message) + ")\n");
                  end if;

                  dim := Type.nthDimension(Expression.typeOf(uroots), 1);

                  if not Dimension.isKnown(dim) then
                    Error.addSourceMessage(Error.DIMENSION_NOT_KNOWN,
                      {Expression.toString(exp)}, info);
                    fail();
                  end if;
                then
                  Expression.fillArray(Dimension.size(dim), Expression.INTEGER(1)); // TODO! FIXME! actually implement this correctly
            end match;
          then
            res;

        else exp;
      end match;

    // no replacement needed
    else exp;
  end match;
end evalConnectionsOperatorsHelper;

protected function getRooted
  input ComponentRef cref1;
  input ComponentRef cref2;
  input CrefIndexTable rooted;
  output Boolean result;
algorithm
  result := matchcontinue(cref1,cref2,rooted)
    local
      Integer i1,i2;
    case(_,_,_)
      equation
        i1 = UnorderedMap.getOrFail(cref1,rooted);
        i2 = UnorderedMap.getOrFail(cref2,rooted);
      then
        intLt(i1,i2);
    // in fail case return true
    else true;
  end matchcontinue;
end getRooted;

protected function getEdge
"return the Edge partner of a edge, fails if not found"
  input ComponentRef cr;
  input Edges edges;
  output ComponentRef ocr;
protected
  ComponentRef cref1, cref2;
algorithm
  for edge in edges loop
    (cref1, cref2) := edge;

    if ComponentRef.isEqual(cr, cref1) then
      ocr := cref2;
      return;
    elseif ComponentRef.isEqual(cr, cref2) then
      ocr := cref1;
      return;
    end if;
  end for;

  fail();
end getEdge;

protected function printConnectionStr
"prints the connection str"
  input FlatEdge connectTuple;
  input String ty;
  output String outStr;
algorithm
  outStr := match(connectTuple, ty)
    local
      ComponentRef c1, c2;
      String str;

    case ((c1, c2, _), _)
      equation
        str = ty + "(" +
          ComponentRef.toString(c1) +
          ", " +
          ComponentRef.toString(c2) +
          ")";
      then str;
  end match;
end printConnectionStr;

protected function printEdges
"Prints a list of edges to stdout."
  input Edges inEdges;
algorithm
  _ := match(inEdges)
    local
      ComponentRef c1, c2;
      Edges tail;

    case ({}) then ();
    case ((c1, c2) :: tail)
      equation
        print("    ");
        print(ComponentRef.toString(c1));
        print(" -- ");
        print(ComponentRef.toString(c2));
        print("\n");
        printEdges(tail);
      then ();
  end match;
end printEdges;

protected function printFlatEdges
"Prints a list of dae edges to stdout."
  input FlatEdges inEdges;
algorithm
  _ := match(inEdges)
    local
      ComponentRef c1, c2;
      FlatEdges tail;

    case ({}) then ();

    case ((c1, c2, _) :: tail)
      equation
        print("    ");
        print(ComponentRef.toString(c1));
        print(" -- ");
        print(ComponentRef.toString(c2));
        print("\n");
        printFlatEdges(tail);
      then ();
  end match;
end printFlatEdges;

protected function printNFOCConnectionGraph
  "Prints the content of NFOCConnectionGraph structure."
  input NFOCConnectionGraph inGraph;
algorithm
  _ := match(inGraph)
    local
      FlatEdges connections;
      Edges branches;

    case (GRAPH(connections = connections, branches = branches))
      equation
        print("Connections:\n");
        printFlatEdges(connections);
        print("Branches:\n");
        printEdges(branches);
      then ();
  end match;
end printNFOCConnectionGraph;

protected function getDefiniteRoots
"Accessor for NFOCConnectionGraph.definiteRoots."
  input NFOCConnectionGraph inGraph;
  output DefiniteRoots outResult;
algorithm
  outResult := match(inGraph)
    local
      DefiniteRoots result;
    case (GRAPH(definiteRoots = result)) then result;
  end match;
end getDefiniteRoots;

protected function getUniqueRoots
"Accessor for NFOCConnectionGraph.uniqueRoots."
  input NFOCConnectionGraph inGraph;
  output UniqueRoots outResult;
algorithm
  outResult := match(inGraph)
    local
      UniqueRoots result;
    case (GRAPH(uniqueRoots = result)) then result;
  end match;
end getUniqueRoots;

protected function getPotentialRoots
"Accessor for NFOCConnectionGraph.potentialRoots."
  input NFOCConnectionGraph inGraph;
  output PotentialRoots outResult;
algorithm
  outResult := match(inGraph)
    local PotentialRoots result;
    case (GRAPH(potentialRoots = result)) then result;
  end match;
end getPotentialRoots;

protected function getBranches
"Accessor for NFOCConnectionGraph.branches."
  input NFOCConnectionGraph inGraph;
  output Edges outResult;
algorithm
  outResult := match(inGraph)
    local Edges result;
    case (GRAPH(branches = result)) then result;
  end match;
end getBranches;

protected function getConnections
"Accessor for NFOCConnectionGraph.connections."
  input NFOCConnectionGraph inGraph;
  output FlatEdges outResult;
algorithm
  outResult := match(inGraph)
    local FlatEdges result;
    case (GRAPH(connections = result)) then result;
  end match;
end getConnections;

function merge
"merge two NFOCConnectionGraphs"
  input NFOCConnectionGraph inGraph1;
  input NFOCConnectionGraph inGraph2;
  output NFOCConnectionGraph outGraph;
algorithm
  outGraph := matchcontinue(inGraph1, inGraph2)
    local
      Boolean updateGraph, updateGraph1, updateGraph2;
      DefiniteRoots definiteRoots, definiteRoots1, definiteRoots2;
      UniqueRoots uniqueRoots, uniqueRoots1, uniqueRoots2;
      PotentialRoots potentialRoots, potentialRoots1, potentialRoots2;
      Edges branches, branches1, branches2;
      FlatEdges connections, connections1, connections2;

    // left is empty, return right
    case (_, GRAPH(definiteRoots = {},potentialRoots = {},uniqueRoots = {},branches = {},connections = {}))
      then
        inGraph1;

    // right is empty, return left
    case (GRAPH(definiteRoots = {},potentialRoots = {},uniqueRoots = {},branches = {},connections = {}), _)
      then
        inGraph2;

    // they are equal, return any
    case (_, _)
      equation
        equality(inGraph1 = inGraph2);
      then
        inGraph1;

    // they are NOT equal, merge them
    case (GRAPH(updateGraph = updateGraph1, definiteRoots = definiteRoots1, potentialRoots = potentialRoots1, uniqueRoots=uniqueRoots1,
                branches = branches1, connections = connections1),
          GRAPH(updateGraph = updateGraph2, definiteRoots = definiteRoots2, potentialRoots = potentialRoots2, uniqueRoots=uniqueRoots2,
                branches = branches2,connections = connections2))
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.trace("- NFOCConnectionGraph.merge()\n");
        end if;
        updateGraph    = boolOr(updateGraph1, updateGraph2);
        definiteRoots  = List.union(definiteRoots1, definiteRoots2);
        potentialRoots = List.union(potentialRoots1, potentialRoots2);
        uniqueRoots    = List.union(uniqueRoots1, uniqueRoots2);
        branches       = List.union(branches1, branches2);
        connections    = List.union(connections1, connections2);
      then
        GRAPH(updateGraph,definiteRoots,potentialRoots,uniqueRoots,branches,connections);
  end matchcontinue;
end merge;

/***********************************************************************************************************************/
/******************************************* GraphViz generation *******************************************************/
/***********************************************************************************************************************/

protected function graphVizEdge
  input  Edge inEdge;
  output String out;
algorithm
  out := match(inEdge)
    local ComponentRef c1, c2; String strEdge;
    case ((c1, c2))
      equation
        strEdge = "\"" + ComponentRef.toString(c1) + "\" -- \"" + ComponentRef.toString(c2) + "\"" +
        " [color = blue, dir = \"none\", fontcolor=blue, label = \"branch\"];\n\t";
      then strEdge;
  end match;
end graphVizEdge;

protected function graphVizFlatEdge
  input  FlatEdge inFlatEdge;
  input  FlatEdges inBrokenFlatEdges;
  output String out;
algorithm
  out := match(inFlatEdge, inBrokenFlatEdges)
    local
      ComponentRef c1, c2;
      String sc1, sc2, strFlatEdge, label, labelFontSize, decorate, color, style, fontColor;
      Boolean isBroken;

    case ((c1, c2, _), _)
      equation
        isBroken = List.isMemberOnTrue(inFlatEdge, inBrokenFlatEdges, FlatEdgeIsEqual);
        label = if isBroken then "[[broken connect]]" else "connect";
        color = if isBroken then "red" else "green";
        style = if isBroken then "\"bold, dashed\"" else "solid";
        decorate = boolString(isBroken);
        fontColor = if isBroken then "red" else "green";
        labelFontSize = if isBroken then "labelfontsize = 20.0, " else "";
        sc1 = ComponentRef.toString(c1);
        sc2 = ComponentRef.toString(c2);
        strFlatEdge = stringAppendList({
          "\"", sc1, "\" -- \"", sc2, "\" [",
          "dir = \"none\", ",
          "style = ", style,  ", ",
          "decorate = ", decorate,  ", ",
          "color = ", color ,  ", ",
          labelFontSize,
          "fontcolor = ", fontColor ,  ", ",
          "label = \"", label ,"\"",
          "];\n\t"});
      then strFlatEdge;
  end match;
end graphVizFlatEdge;

protected function FlatEdgeIsEqual
  input FlatEdge inEdge1;
  input FlatEdge inEdge2;
  output Boolean isEqual;
algorithm
  isEqual := ComponentRef.isEqual(Util.tuple31(inEdge1), Util.tuple31(inEdge2)) and ComponentRef.isEqual(Util.tuple32(inEdge1), Util.tuple32(inEdge2));
end FlatEdgeIsEqual;

protected function graphVizDefiniteRoot
  input  DefiniteRoot  inDefiniteRoot;
  input  DefiniteRoots inFinalRoots;
  output String out;
algorithm
  out := match(inDefiniteRoot, inFinalRoots)
    local ComponentRef c; String strDefiniteRoot; Boolean isSelectedRoot;
    case (c, _)
      equation
        isSelectedRoot = List.isMemberOnTrue(c, inFinalRoots, ComponentRef.isEqual);
        strDefiniteRoot = "\"" + ComponentRef.toString(c) + "\"" +
           " [fillcolor = red, rank = \"source\", label = " + "\"" + ComponentRef.toString(c) + "\", " +
           (if isSelectedRoot then "shape=polygon, sides=8, distortion=\"0.265084\", orientation=26, skew=\"0.403659\"" else "shape=box") +
           "];\n\t";
      then strDefiniteRoot;
  end match;
end graphVizDefiniteRoot;

protected function graphVizPotentialRoot
  input  PotentialRoot inPotentialRoot;
  input  DefiniteRoots inFinalRoots;
  output String out;
algorithm
  out := match(inPotentialRoot, inFinalRoots)
    local ComponentRef c; Real priority; String strPotentialRoot; Boolean isSelectedRoot;
    case ((c, priority), _)
      equation
        isSelectedRoot = List.isMemberOnTrue(c, inFinalRoots, ComponentRef.isEqual);
        strPotentialRoot = "\"" + ComponentRef.toString(c) + "\"" +
           " [fillcolor = orangered, rank = \"min\" label = " + "\"" + ComponentRef.toString(c) + "\\n" + realString(priority) + "\", " +
           (if isSelectedRoot then "shape=ploygon, sides=7, distortion=\"0.265084\", orientation=26, skew=\"0.403659\"" else "shape=box") +
           "];\n\t";
      then strPotentialRoot;
  end match;
end graphVizPotentialRoot;

protected function generateGraphViz
"@author: adrpo
  Generate a graphviz file out of the connection graph"
  input String modelNameQualified;
  input DefiniteRoots definiteRoots;
  input PotentialRoots potentialRoots;
  input UniqueRoots uniqueRoots;
  input Edges branches;
  input FlatEdges connections;
  input DefiniteRoots finalRoots;
  input FlatEdges broken;
  output String brokenConnectsViaGraphViz;
algorithm
  brokenConnectsViaGraphViz := matchcontinue(modelNameQualified, definiteRoots, potentialRoots, uniqueRoots, branches, connections, finalRoots, broken)
    local
      String fileName, i, nrDR, nrPR, nrUR, nrBR, nrCO, nrFR, nrBC, timeStr,  infoNodeStr, brokenConnects;
      Real tStart, tEnd, t;
      IOStream.IOStream graphVizStream;
      list<String> infoNode;

    // don't do anything if we don't have -d=cgraphGraphVizFile or -d=cgraphGraphVizShow
    case(_, _, _, _, _, _, _, _)
      equation
        false = boolOr(Flags.isSet(Flags.CGRAPH_GRAPHVIZ_FILE), Flags.isSet(Flags.CGRAPH_GRAPHVIZ_SHOW));
      then
        "";

    case(_, _, _, _, _, _, _, _)
      equation
        tStart = clock();
        i = "\t";
        fileName = stringAppend(modelNameQualified, ".gv");
        // create a stream
        graphVizStream = IOStream.create(fileName, IOStream.LIST());
        nrDR = intString(listLength(definiteRoots));
        nrPR = intString(listLength(potentialRoots));
        nrUR = intString(listLength(uniqueRoots));
        nrBR = intString(listLength(branches));
        nrCO = intString(listLength(connections));
        nrFR = intString(listLength(finalRoots));
        nrBC = intString(listLength(broken));

        infoNode =
        {
          "// Generated by OpenModelica. \n",
          "// Overconstrained connection graph for model: \n//    ", modelNameQualified, "\n",
          "// \n",
          "// Summary: \n",
          "//   Roots:              ", nrDR, "\n",
          "//   Potential Roots:    ", nrPR, "\n",
          "//   Unique Roots:       ", nrUR, "\n",
          "//   Branches:           ", nrBR, "\n",
          "//   Connections:        ", nrCO, "\n",
          "//   Final Roots:        ", nrFR, "\n",
          "//   Broken Connections: ", nrBC, "\n"
        };
        infoNodeStr = stringAppendList(infoNode);
        // replace \n with \\l (left align), replace \t with " "
        infoNodeStr = System.stringReplace(infoNodeStr, "\n", "\\l"); infoNodeStr = System.stringReplace(infoNodeStr, "\t", " ");
        // replace / with ""
        infoNodeStr = System.stringReplace(infoNodeStr, "/", "");

        // output header
        graphVizStream = IOStream.appendList(graphVizStream,infoNode);
        // output command to be used
        // output graphviz header
        graphVizStream = IOStream.appendList(graphVizStream,{"\n\n"});
        graphVizStream = IOStream.appendList(graphVizStream, {"graph \"", modelNameQualified, "\"\n{\n\n"});

        // output global settings
        graphVizStream = IOStream.appendList(graphVizStream, {i, "overlap=false;\n"});
        graphVizStream = IOStream.appendList(graphVizStream, {i, "layout=dot;\n\n"});

        // output settings for nodes
        graphVizStream = IOStream.appendList(graphVizStream, {i, "node [",
           "fillcolor = \"lightsteelblue1\", ",
           "shape = box, ",
           "style = \"bold, filled\", ",
           "rank = \"max\"","]\n\n"});
        // output settings for edges
        graphVizStream = IOStream.appendList(graphVizStream, {i, "edge [",
           "color = \"black\", ",
           "style = bold",
           "]\n\n"});

        // output summary node
        graphVizStream = IOStream.appendList(graphVizStream, {i, "graph [fontsize=20, fontname = \"Courier Bold\" label= \"\\n\\n", infoNodeStr, "\", size=\"6,6\"];\n", i});

        // output definite roots
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Definite Roots (Connections.root)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, List.map1(definiteRoots, graphVizDefiniteRoot, finalRoots));
        // output potential roots
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Potential Roots (Connections.potentialRoot)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, List.map1(potentialRoots, graphVizPotentialRoot, finalRoots));

        // output branches
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Branches (Connections.branch)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, List.map(branches, graphVizEdge));

        // output connections
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Connections (connect)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, List.map1(connections, graphVizFlatEdge, broken));

        // output graphviz footer
        graphVizStream = IOStream.appendList(graphVizStream, {"\n}\n"});
        tEnd = clock();
        t = tEnd - tStart;
        timeStr = realString(t);
        graphVizStream = IOStream.appendList(graphVizStream, {"\n\n\n// graph generation took: ", timeStr, " seconds\n"});
        System.writeFile(fileName, IOStream.string(graphVizStream));
        print("GraphViz with connection graph for model: " + modelNameQualified + " was writen to file: " + fileName + "\n");
        brokenConnects = showGraphViz(fileName, modelNameQualified);
      then
        brokenConnects;

  end matchcontinue;
end generateGraphViz;

protected function showGraphViz
  input String fileNameGraphViz;
  input String modelNameQualified;
  output String brokenConnectsViaGraphViz;
algorithm
  brokenConnectsViaGraphViz := matchcontinue(fileNameGraphViz, modelNameQualified)
    local
      String leftyCMD, fileNameTraceRemovedConnections, omhome, brokenConnects;
      Integer leftyExitStatus;

    // do not start graphviz if we don't have -d=cgraphGraphVizShow
    case (_, _)
      equation
        false = Flags.isSet(Flags.CGRAPH_GRAPHVIZ_SHOW);
      then
        "";

    else
      equation
        fileNameTraceRemovedConnections = modelNameQualified + "_removed_connections.txt";
        print("Tyring to start GraphViz *lefty* to visualize the graph. You need to have lefty in your PATH variable\n");
        print("Make sure you quit GraphViz *lefty* via Right Click->quit to be sure the process will be exited.\n");
        print("If you quit the GraphViz *lefty* window via X, please kill the process in task manager to continue.\n");
        omhome = Settings.getInstallationDirectoryPath();
        omhome = System.stringReplace(omhome, "\"", "");
        // omhome = System.stringReplace(omhome, "\\", "/");

        // create a lefty command and execute it
        leftyCMD = "load('" + omhome + "/share/omc/scripts/openmodelica.lefty');" + "openmodelica.init();openmodelica.createviewandgraph('" +
            fileNameGraphViz + "','file',null,null);txtview('off');";
        print("Running command: " + "lefty -e " + leftyCMD + " > " + fileNameTraceRemovedConnections + "\n");
        // execute lefty
        leftyExitStatus = System.systemCall("lefty -e " + leftyCMD, fileNameTraceRemovedConnections);
        // show the exit status
        print("GraphViz *lefty* exited with status:" + intString(leftyExitStatus) + "\n");
        brokenConnects = System.readFile(fileNameTraceRemovedConnections);
        print("GraphViz OpenModelica assistant returned the following broken connects: " + brokenConnects + "\n");
      then
        brokenConnects;
  end matchcontinue;
end showGraphViz;

function removeBrokenConnects
"@author adrpo:
 this function removes the BROKEN connects from the equation list
 and keeps the CONNECTED ones."
  input list<Equation> inEquations;
  input FlatEdges inConnected;
  input FlatEdges inBroken;
  input IsDeleted isDeleted;
  output list<Equation> outEquations;

  partial function IsDeleted
    input ComponentRef cref;
    output Boolean res;
  end IsDeleted;
algorithm
  outEquations := match(inEquations, inConnected, inBroken)
    local
      list<ComponentRef> toRemove, toKeep, intersect;
      ComponentRef c1, c2, lhs, rhs;
      list<Equation> eql = {};
      Boolean isThere;
      String str;
      Type ty1, ty2;
      DAE.ElementSource source;

    // if we have no broken then we don't care!
    case (_, _, {}) then inEquations;

    // if we have nothing toRemove then we don't care!
    case (_, _, _)
      algorithm
        for eq in inEquations loop
          eql := match eq
            case Equation.CONNECT(lhs = Expression.CREF(ty = ty1, cref = lhs),
                                  rhs = Expression.CREF(ty = ty2, cref = rhs), source = source)
              algorithm
                if not (isDeleted(lhs) or isDeleted(rhs)) then
                  // check for equality
                  isThere := false;
                  for tpl in inBroken loop
                    c1 := Util.tuple31(tpl);
                    c2 := Util.tuple32(tpl);
                    if ComponentRef.isEqual(c1, lhs) and ComponentRef.isEqual(c2, rhs) or
                       ComponentRef.isEqual(c2, lhs) and ComponentRef.isEqual(c1, rhs)
                    then
                      isThere := true;
                      break;
                    end if;
                  end for;
                end if;
                if not isThere then
                 eql := eq :: eql;
                end if;
              then
                eql;

            else eq :: eql;
          end match;

        end for;

        eql := listReverseInPlace(eql);

        if Flags.isSet(Flags.CGRAPH)
        then
          str := "";
          for tpl in inBroken loop
            c1 := Util.tuple31(tpl);
            c2 := Util.tuple32(tpl);
            str := str + "connect(" +
              ComponentRef.toString(c1) + ", " +
              ComponentRef.toString(c2) + ")\n";
          end for;
          print("- NFOCConnectionGraph.removeBrokenConnects:\n" + str + "\n");
        end if;
      then
        eql;

  end match;
end removeBrokenConnects;

function addBrokenEqualityConstraintEquations
"@author: adrpo
 adds all the equalityConstraint equations from broken connections"
  input list<Equation> inEquations;
  input FlatEdges inBroken;
  output list<Equation> outEquations;
algorithm
  outEquations := matchcontinue(inEquations, inBroken)
    local
      list<Equation> equalityConstraintElements, eqs;

    case (_, {}) then inEquations;

    else
      equation
        equalityConstraintElements = List.flatten(List.map(inBroken, Util.tuple33));
        eqs = listAppend(equalityConstraintElements, inEquations);
      then
        eqs;

  end matchcontinue;
end addBrokenEqualityConstraintEquations;

function identifyConnectionsOperator
  input Absyn.Path functionName;
  output ConnectionsOperator call;
algorithm
  call := match functionName
    local
      String name;

    case Absyn.QUALIFIED(name = "Connections", path = Absyn.IDENT(name = name))
      then match name
        case "branch" then ConnectionsOperator.BRANCH;
        case "root" then ConnectionsOperator.ROOT;
        case "potentialRoot" then ConnectionsOperator.POTENTIAL_ROOT;
        case "isRoot" then ConnectionsOperator.IS_ROOT;
        case "rooted" then ConnectionsOperator.ROOTED;
        case "uniqueRoot" then ConnectionsOperator.UNIQUE_ROOT;
        case "uniqueRootIndices" then ConnectionsOperator.UNIQUE_ROOT_INDICES;
        else ConnectionsOperator.NOT_OPERATOR;
      end match;

    case Absyn.IDENT(name = "rooted") then ConnectionsOperator.ROOTED;
    else ConnectionsOperator.NOT_OPERATOR;
  end match;
end identifyConnectionsOperator;

function newCrefCrefTable
  output CrefCrefTable table;
algorithm
  table := UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
end newCrefCrefTable;

function newCrefIndexTable
  output CrefIndexTable table;
algorithm
  table := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
end newCrefIndexTable;

function newCrefRootsTable
  output CrefRootsTable table;
algorithm
  table := UnorderedMap.new<DefiniteRoots>(ComponentRef.hash, ComponentRef.isEqual);
end newCrefRootsTable;

annotation(__OpenModelica_Interface="frontend");
end NFOCConnectionGraph;

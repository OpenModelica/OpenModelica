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

encapsulated package SCodeGraph
" file:        SCodeGraph.mo
  package:     SCodeGraph
  description: SCodeGraph is a representation of SCode as a Graph.
  @author:     adrpo

  RCS: $Id: SCodeGraph.mo 8980 2011-05-13 09:12:21Z adrpo $

  The SCodeGraph representation is used to build a Modelica code graph."

public import Absyn;
public import SCode;
public import Pool;
public import Name;
public import Scope;
public import Reference;
public import Instance;
public import Element;
public import Visited;
public import Relation;
public import Edge;
public import Node;

protected import List;
protected import SCodeDump;

public
type Scope2Node  = .Relation.Relation<tuple<Integer,Integer>,Integer> "scopeId + valueConstructor(node) -> node";
type Node2Edge   = .Relation.Relation<tuple<Integer,Integer>,tuple<Integer,Integer>> "sourceId+edgeKind  -> edge,target";
type Node2Kids   = .Relation.Relation<tuple<Integer,Integer>,list<Integer>> "sourceId+nodeKind -> list of targets";
type Node        = .Node.Node;
type Edge        = .Edge.Edge;
type Nodes       = .Node.Nodes;
type Edges       = .Edge.Edges;
type Names       = .Name.Names;
type Scopes      = .Scope.Scopes;
type Segment     = .Scope.Segment;
type SegmentKind = .Scope.Kind;
type Reference   = .Reference.Reference;
type Instance    = .Instance.Instance;
type Element     = .Element.Element;

type VisitedScopes = .Visited.Visited      "an array of unique scope ids visited during lookup, the integer points to the previous scope";

uniontype LookupStatus
  record LS
    VisitedScopes visited "the scopes visited during lookup";
    Integer ureferencesNumber "the number of unresolved references before the lookup started";
    Integer ireferencesNumber "the number of resolved references before the lookup started";
  end LS;
end LookupStatus;

uniontype Relations "relations in the graph other than the edges; add more if you need"
  record RELS "relations in the graph other than the edges"
    Scope2Node scope2node "fast access from scope+node type to node";
    Node2Edge  node2edge  "fast access from source node+edge type to target node";
    Node2Kids  node2kids  "fast access from nodes+children node type to their children";
  end RELS;
end Relations;

uniontype Graph "the graph"
  record GRAPH "the graph"
    Nodes          nodes "the nodes in the graph";
    Edges          edges "the edges in the graph";
    // additional info
    Names          names  "the names in the scopes";
    Scopes         scopes "the scopes";
    Relations      relations "other relations in the graph for fast access";
    LookupStatus   lookupStatus "structure to help us do lookup";
  end GRAPH;
end Graph;

constant String  rootName        = "$/";
constant Integer rootScopeId     = 1;
constant Scope.Scope   rootScope       = {Scope.S(rootScopeId, virtualId, 1, Scope.TY())};
constant Integer rootParentId    = 1;
constant Integer rootInstanceId  = 2;

constant Integer virtualId = 0 "an id for the parent of the root, etc, when we do not have any info";
constant Integer autoId = Pool.autoId "an dummy id that will be auto-updated on insert in a pool";

public function emptyGraph
  input  SCode.Element rootElement;
  output Graph outGraph;
protected
  Nodes          nodes "the nodes in the graph";
  Edges          edges "the edges in the graph";
  Names          names;
  Scopes         scopes;
  Scope2Node     scope2node;
  Node2Edge      node2edge;
  Node2Kids      node2kids;
  LookupStatus   lookupStatus;
  VisitedScopes  visited;
  Integer        nodeId, nameId, scopeId, instanceId, edgeId;
  Graph g;
algorithm
  // create names, scopes, nodes and edges pools
  nodes   := Node.pool();
  edges   := Edge.pool();
  names   := Name.pool();
  scopes  := Scope.pool();
  visited := Visited.pool();

  // create relations
  scope2node := Relation.bidirectional("scope2node",
                  Relation.intPairCompare, Relation.intCompare, // comparison functions
                  SOME(Relation.intPairStr), SOME(intString), // printing functions
                  NONE(), NONE() // no update check functions
                  );
  node2edge  := Relation.bidirectional("node2edge",
                  Relation.intPairCompare, Relation.intPairCompare, // comparison functions
                  SOME(Relation.intPairStr), SOME(Relation.intPairStr), // printing functions
                  NONE(), NONE() // no update check function
                );
  node2kids  := Relation.unidirectional("node2kids",
                  Relation.intPairCompare, // comparison
                  SOME(Relation.intPairStr), SOME(Relation.intListStr), // printing functions
                  NONE()// no update check function
                );
  // setup lookup status
  lookupStatus   := LS(visited, 0, 0);

  g := GRAPH(nodes, edges, names, scopes, RELS(scope2node, node2edge, node2kids), lookupStatus);

  // add the root name, will get ID 1
  (g, nameId) := newName(g, rootName);
  // add the root scope, will get ID 1
  (g, scopeId) := addScope(g, rootScope);

  // add the root node, ID 1
  (g, nodeId) := addNode(g, Node.N(autoId, scopeId, Node.E(Element.E(rootElement, 0))));
  // create a root instance, ID 2
  (g, instanceId) := addNode(g, Node.N(autoId, scopeId, Node.I(Instance.initialTI)));

  // add the edge, ID 1
  (g, edgeId) := addEdge(g, Edge.E(autoId, instanceId, nodeId, Edge.cb));

  outGraph := g;
end emptyGraph;

public
uniontype Context "extra information that is passed along for the ride to all the functions, updated and returned back, like a hitchhiker"
  record CONTEXT "the extra info"
    Integer sID "current scope";
    Integer nID "the parent node id";
    Integer iID "the parent instance id";
  end CONTEXT;
end Context;


public function create
"populates the SCodeGraph and expands the nodes on the path we want to instantiate"
  input SCode.Program inSCodeProgram;
  input Absyn.Path inClassPath;
  input Context inContext;
  output Graph outGraph;
  output Context outContext;
algorithm
  (outGraph, outContext) := matchcontinue(inSCodeProgram, inClassPath, inContext)
    local
      SCode.Program program;
      SCode.Element rootElement, el;
      Context iContext, oContext;
      Absyn.Path path;
      Graph graph;
      Integer instanceId, order;

    // handle something
    case (program, path, iContext)
      equation
        // build an root package element from a program
        rootElement =
          SCode.CLASS(
            "",
            SCode.defaultPrefixes,
            SCode.ENCAPSULATED(),
            SCode.NOT_PARTIAL(),
            SCode.R_PACKAGE(),
            SCode.PARTS(program, {}, {}, {}, {}, {}, {}, NONE(), {}, NONE()),
            Absyn.dummyInfo);
        graph = emptyGraph(rootElement);

        // expand nodes on path
        (graph, oContext) = expandNodesOnPath(graph, iContext, path);
      then
        (graph, oContext);

    // failure
    case(_, path, _)
      equation
        print("Failure in SCodeGraph.createGraph for path: " +& Absyn.pathString(path) +& "!\n");
      then
        fail();

  end matchcontinue;
end create;

protected function expandNodesOnPath
"expands nodes in graph on the path we want to instantiate"
  input Graph inGraph;
  input Context inContext;
  input Absyn.Path inClassPath;
  output Graph outGraph;
  output Context outContext "contains the last instance on the path";
algorithm
  (outGraph, outContext) := matchcontinue(inGraph, inContext, inClassPath)
    local
      SCode.Program program;
      SCode.Element rootElement;
      Context iContext, oContext;
      Absyn.Path path, rest;
      Graph g;
      Integer scopeId, nodeParentId, nodeId, instanceParentId, instanceId, edgeId;
      Nodes nodes;
      Node parentNode;
      String name;
      Element el;

    // nothing more to expand than this node Absyn.IDENT
    case (g, iContext as CONTEXT(scopeId, nodeParentId, instanceParentId), path as Absyn.IDENT(name))
      equation
        (g, scopeId) = newScope(g, name, scopeId, Scope.TY());
        el = getElementByScopeId(g, scopeId);
        // this will try to make a new scope, but will get the same id!
        //(g, oContext) = createElementNodeAndInstance(g, iContext, el);
        (g, oContext) = analyzeClass(g, iContext, el, Element.order(el));
      then
        (g, oContext);

    // handle qualified Absyn.QUALIFIED
    case (g, iContext as CONTEXT(scopeId, nodeParentId, instanceParentId), path as Absyn.QUALIFIED(name, rest))
      equation
        (g, scopeId) = newScope(g, name, scopeId, Scope.TY());
        el = getElementByScopeId(g, scopeId);
        // this will try to make a new scope, but will get the same id!
        (g, oContext) = createElementNodeAndInstance(g, iContext, el);
        // expand nodes on the rest of the path
        (g, oContext) = expandNodesOnPath(g, oContext, rest);
      then
        (g, oContext);

    // failure
    case(g, iContext, path)
      equation
        print("Failure in SCodeGraph.expandNodesOnPath for path: " +& Absyn.pathString(path) +& "!\n");
      then
        fail();
  end matchcontinue;
end expandNodesOnPath;

protected function getLastNameFromScope
  input Graph graph;
  input Scope.Scope scope;
  output String name;
algorithm
  name := matchcontinue(graph, scope)
    local
      Integer nameId;
      String n;

    // fine
    case (graph, scope)
      equation
        n = Scope.lastSegmentName(getNames(graph), scope);
      then
        n;

  end matchcontinue;
end getLastNameFromScope;

protected function getElementByScopeId
  input Graph graph;
  input Integer scopeId;
  output Element outElement;
algorithm
  outElement := matchcontinue(graph, scopeId)
    local
      SCode.Element element;
      Integer order,nodeId,nameId;
      Scope.Scope scope, scopeNotExpanded;
      String name;
      Names names;

    // see if we have an expanded node with this scope
    case(graph, scopeId)
      equation
        nodeId = getNodeIdByScopeId(graph, scopeId);
        // did we find it?
        true = intNe(nodeId, 0);
        Node.N(content = Node.E(Element.E(element = element, order = order))) = getNodeById(graph, nodeId);
      then
        Element.E(element, order);

    // no expanded node with this scope, find the last expanded one
    case(graph, scopeId)
      equation
        nodeId = getNodeIdByScopeId(graph, scopeId);
        // did we find it?
        false = intNe(nodeId, 0);
        // TODO! CHEK if we have more non-expanded nodes!!
        (Node.N(content = Node.E(Element.E(element = element, order = order))), scopeNotExpanded) = getLastExpandedNodeFromScopeId(graph, scopeId);
        name = getLastNameFromScope(graph, scopeNotExpanded);
        (element, order) = getElementByName(name, element);
      then
        Element.E(element, order);

    case(graph, scopeId)
      equation
        names = getNames(graph);
        print("Failure in SCodeGraph.getElementByScopeId for scopeId: " +& intString(scopeId) +& ": " +& scopeStr(graph, scopeId) +& "!\n");
        printGraph(graph);
      then
        fail();

  end matchcontinue;
end getElementByScopeId;

protected function getLastExpandedNodeFromScopeId
  input Graph graph;
  input Integer scopeId;
  output Node node;
  output Scope.Scope scopeNotExpanded "the scope that was not expanded after the last expanded node";
algorithm
  (node, scopeNotExpanded) := matchcontinue(graph, scopeId)
    local
      Integer order;
      Integer nodeId;
      Scope.Scope scope, s;
      Node node;

    // see if we have an expanded node with this scope
    case(graph, scopeId)
      equation
        scope = getScopeById(graph, scopeId);
        // revese it, so we have the top scope first
        scope = listReverse(scope);

        (node, s) = getLastExpandedNodeFromScope(graph, scope);
      then
        (node, s);

    case(graph, scopeId)
      equation
        print("Failure in SCodeGraph.getLastExpandedNodeFromScopeId for scopeId: " +& intString(scopeId) +& "!\n");
      then
        fail();
  end matchcontinue;
end getLastExpandedNodeFromScopeId;

protected function getLastExpandedNodeFromScope
  input Graph graph;
  input Scope.Scope inScope "this scope is top down";
  output Node node;
  output Scope.Scope scopeNotExpanded "the scope that was not expanded after the last expanded node";
algorithm
  (node, scopeNotExpanded) := matchcontinue(graph, inScope)
    local
      Integer order,nodeId,scopeId, parentId;
      Scope.Scope scope, rest;
      Node node;
      Segment s;

    // root node??
    case(graph, {})
      equation
        print("Damn, this should not happen!!\n");
      then
        fail();

    // parent expanded, current not expanded
    case(graph, Scope.S(id = parentId)::(s as Scope.S(id = scopeId))::rest)
      equation
        // not expanded one preceeded by an expanded
        0 = getNodeIdByScopeId(graph, scopeId);
        true = intNe(parentId, 0);
        nodeId = getNodeIdByScopeId(graph, parentId);
        true = intNe(nodeId, 0);
        node = getNodeById(graph, nodeId);
      then
        (node, listReverse(s::rest));

    //
    case(graph, Scope.S(id = scopeId, parentId = parentId)::rest)
      equation
        nodeId = getNodeIdByScopeId(graph, scopeId);
        true = intNe(nodeId, 0);
        // this one is expanded
        (node, rest) = getLastExpandedNodeFromScope(graph, rest);
      then
        (node, rest);

    //
    case(graph, _)
      equation
        print("Failure in SCodeGraph.getLastExpandedNodeFromScope \n");
      then
        fail();
  end matchcontinue;
end getLastExpandedNodeFromScope;

protected function getNodeIdByScopeId
"@fetches the node ID with this scope id or returns 0 if is not there"
  input Graph graph;
  input Integer scopeId;
  output Integer outNodeId;
algorithm
  outNodeId := matchcontinue(graph, scopeId)
    local
      Integer nodeId;
      Nodes nodes;
      Scope2Node scope2node;

    // do we already have a node, return it!
    case(graph, scopeId)
      equation
        scope2node = getScope2Node(graph);
        nodeId = Relation.getTargetFromSource(scope2node, (scopeId,Node.e));
        //print("Scope: [" +& intString(scopeId) +& "]" +& scopeStr(graph,scopeId) +& " node id: " +& intString(nodeId) +& "\n");
      then
        nodeId;

    // failure above, return 0
    case(graph, scopeId)
      equation
        //print("Scope: [" +& intString(scopeId) +& "]" +& scopeStr(graph, scopeId) +& " node id: 0\n");
        //print("Scope2Node: \n" +& Relation.printRelationStr(getScope2Node(graph)) +& "\n");
      then
        virtualId;

  end matchcontinue;
end getNodeIdByScopeId;

protected function getNodeById
"@fetches the node with this id or fails"
  input Graph graph;
  input Integer inNodeId;
  output Node outNode;
algorithm
  outNode := matchcontinue(graph, inNodeId)
    local
      Integer nodeId;
      Nodes nodes;
      Node node;

    // fetch the node!
    case(graph, nodeId)
      equation
        nodes = getNodes(graph);
        node = Node.get(nodes, nodeId);
      then
        node;

    case(graph, nodeId)
      equation
        print("Failure in SCodeGraph.getNodeById for nodeId: " +& intString(nodeId) +& "!\n");
      then
        fail();

  end matchcontinue;
end getNodeById;

protected function getScopeById
"@fetches the node with this id or fails"
  input Graph graph;
  input Integer inScopeId;
  output Scope.Scope outScope;
algorithm
  outScope := matchcontinue(graph, inScopeId)
    local
      Integer scopeId;
      Scopes scopes;
      Scope.Scope scope;

    // fetch the scope!
    case(graph, scopeId)
      equation
        scopes = getScopes(graph);
        scope = Scope.get(scopes, scopeId);
      then
        scope;
  end matchcontinue;
end getScopeById;

protected function getNameById
"@fetches the node with this id or fails"
  input Graph graph;
  input Integer inNameId;
  output String outName;
algorithm
  outName := matchcontinue(graph, inNameId)
    local
      Integer nameId;
      Names names;
      String name;

    // fetch the name!
    case(graph, nameId)
      equation
        names = getNames(graph);
        name = Name.get(names, nameId);
      then
        name;
  end matchcontinue;
end getNameById;

protected function newName
  input Graph inGraph;
  input String inName;
  output Graph outGraph;
  output Integer outIndex;
protected
  Names names;
algorithm
  names := getNames(inGraph);
  (names, outIndex) := Name.new(names, inName);
  outGraph := setNames(inGraph, names);
end newName;

protected function newScope
  input Graph inGraph;
  input String inName;
  input Integer inParentId;
  input SegmentKind kind;
  output Graph outGraph;
  output Integer outIndex;
protected
  Graph graph;
  Scopes scopes;
  Names names;
algorithm
  scopes := getScopes(inGraph);
  names := getNames(inGraph);

  (scopes, names, outIndex) := Scope.new(scopes, names, inName, inParentId, kind);

  graph := setScopes(inGraph, scopes);
  outGraph := setNames(graph, names);
end newScope;

protected function addScope
  input Graph inGraph;
  input Scope.Scope inScope;
  output Graph outGraph;
  output Integer outIndex;
protected
  Graph graph;
  Scopes scopes;
  Names names;
algorithm
  scopes := getScopes(inGraph);
  (scopes, outIndex) := Scope.addAutoUpdateId(scopes, inScope);
  graph := setScopes(inGraph, scopes);
  outGraph := graph;
end addScope;

protected function getNodes
  input Graph inGraph;
  output Nodes nodes;
algorithm
  GRAPH(nodes = nodes) := inGraph;
end getNodes;

function setNodes
  input Graph inGraph;
  input Nodes inNodes;
  output Graph outGraph;
protected
  Nodes nodes; Edges edges; Names names; Scopes scopes;
  Scope2Node s2n; Node2Edge n2e; Node2Kids n2k; LookupStatus lookupStatus;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := inGraph;
  outGraph := GRAPH(inNodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus);
end setNodes;

protected function getScope2Node
  input Graph inGraph;
  output Scope2Node scope2node;
algorithm
  GRAPH(relations = RELS(scope2node = scope2node)) := inGraph;
end getScope2Node;

function setScope2Node
  input Graph inGraph;
  input Scope2Node inS2N;
  output Graph outGraph;
protected
  Nodes nodes; Edges edges; Names names; Scopes scopes;
  Scope2Node s2n; Node2Edge n2e; Node2Kids n2k; LookupStatus lookupStatus;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := inGraph;
  outGraph := GRAPH(nodes, edges, names, scopes, RELS(inS2N, n2e, n2k), lookupStatus);
end setScope2Node;

protected function getNode2Edge
  input Graph inGraph;
  output Node2Edge node2edge;
algorithm
  GRAPH(relations = RELS(node2edge = node2edge)) := inGraph;
end getNode2Edge;

function setNode2Edge
  input Graph inGraph;
  input Node2Edge inN2E;
  output Graph outGraph;
protected
  Nodes nodes; Edges edges; Names names; Scopes scopes;
  Scope2Node s2n; Node2Edge n2e; Node2Kids n2k; LookupStatus lookupStatus;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := inGraph;
  outGraph := GRAPH(nodes, edges, names, scopes, RELS(s2n, inN2E, n2k), lookupStatus);
end setNode2Edge;

protected function getNode2Kids
  input Graph inGraph;
  output Node2Kids node2kids;
algorithm
  GRAPH(relations = RELS(node2kids = node2kids)) := inGraph;
end getNode2Kids;

function setNode2Kids
  input Graph inGraph;
  input Node2Kids inN2K;
  output Graph outGraph;
protected
  Nodes nodes; Edges edges; Names names; Scopes scopes;
  Scope2Node s2n; Node2Edge n2e; Node2Kids n2k; LookupStatus lookupStatus;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := inGraph;
  outGraph := GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, inN2K), lookupStatus);
end setNode2Kids;

protected function getNames
  input Graph inGraph;
  output Names names;
algorithm
  GRAPH(names = names) := inGraph;
end getNames;

function setNames
  input Graph inGraph;
  input Names inNames;
  output Graph outGraph;
protected
  Nodes nodes; Edges edges; Names names; Scopes scopes;
  Scope2Node s2n; Node2Edge n2e; Node2Kids n2k; LookupStatus lookupStatus;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := inGraph;
  outGraph := GRAPH(nodes, edges, inNames, scopes, RELS(s2n, n2e, n2k), lookupStatus);
end setNames;

protected function getEdges
  input Graph inGraph;
  output Edges edges;
algorithm
  GRAPH(edges = edges) := inGraph;
end getEdges;

function setEdges
  input Graph inGraph;
  input Edges inEdges;
  output Graph outGraph;
protected
  Nodes nodes; Edges edges; Names names; Scopes scopes;
  Scope2Node s2n; Node2Edge n2e; Node2Kids n2k; LookupStatus lookupStatus;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := inGraph;
  outGraph := GRAPH(nodes, inEdges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus);
end setEdges;

protected function getScopes
  input Graph inGraph;
  output Scopes scopes;
algorithm
  GRAPH(scopes = scopes) := inGraph;
end getScopes;

function setScopes
  input Graph inGraph;
  input Scopes inScopes;
  output Graph outGraph;
protected
  Nodes nodes; Edges edges; Names names; Scopes scopes;
  Scope2Node s2n; Node2Edge n2e; Node2Kids n2k; LookupStatus lookupStatus;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := inGraph;
  outGraph := GRAPH(nodes, edges, names, inScopes, RELS(s2n, n2e, n2k), lookupStatus);
end setScopes;

public
function printGraph
"prints the graph to the standard out"
  input Graph inGraph;
algorithm
  () := matchcontinue(inGraph)
    local
      Nodes nodes; Edges edges; Names names; Scopes scopes;
      LookupStatus lookupStatus; Scope2Node s2n; Node2Edge n2e;
      Node2Kids n2k;

    case GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus)
      equation
        print("Graph stats:" +&
              "\n\tnames     [" +& intString(Name.next(names)) +& "]" +&
              "\n\tscopes    [" +& intString(Pool.next(scopes)) +& "]" +&
              "\n\tnodes     [" +& intString(Pool.next(nodes)) +& "]" +&
              "\n\tedges     [" +& intString(Pool.next(edges)) +& "]");
        print("\n--------------------------\n\n");
        print("Scopes:\n");
        Scope.dumpPool(scopes, names);
        print("\n--------------------------\n\n");
        /*
        print("Names:\n" +& Name.toString(names));
        print("\n--------------------------\n\n");
        print("Scope2Node: \n" +& Relation.printRelationStr(s2n));
        print("\n--------------------------\n\n");
        print("Node2Edge: \n" +& Relation.printRelationStr(n2e));
        print("\n--------------------------\n\n");
        print("Node2Kids: \n" +& Relation.printRelationStr(n2k));
        print("\n--------------------------\n\n");
        */
      then
        ();
  end matchcontinue;
end printGraph;

public function getInstance2Element
  input Graph g;
  input Integer instanceID;
  output Integer elementID;
protected
  Edges e;
  Node2Edge n2e;
algorithm
  // search in edges for an edge starting at instanceID and ending up at elementID
  e := getEdges(g);
  n2e := getNode2Edge(g);
  // go via the edge type relation
  ((_, elementID)) := Relation.getTargetFromSource(n2e, (instanceID, Edge.cb));
end getInstance2Element;

public function getNodeKids
"retrieve the id's of all children of a specific kind"
  input Graph g;
  input Integer nodeID;
  input Integer nodeKind;
  output list<Integer> kids;
protected
  Edges e;
  Node2Kids n2k;
algorithm
  // search in edges for all incomming edges of type co
  e := getEdges(g);
  n2k := getNode2Kids(g);
  // go via the node type relation
  kids := Relation.getTargetFromSource(n2k, (nodeID, nodeKind));
end getNodeKids;

public function analyzeInstance
  input Graph inG;
  input Context inContext;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext)
    local
      Graph g;
      Integer sID, nID, iID;
      Context iContext, oContext;

    // get the instance and see its status: initial
    case (g, iContext as CONTEXT(sID, nID, iID))
      equation
        // get the node that created this instance from instance2node relation.
        // nID = getInstance2Element(g, iID);
        // Node.N(scopeId = sID) = getNodeById(g, nID);
        // analyze node element and add all unresolved references to the graph
        (g, oContext) = analyzeNode(g, iContext);
      then
        (g, oContext);

    case(g, iContext)
      equation
        print("Failure in SCodeGraph.resolveInstance for context: " +& printContextStr(g, iContext) +& "!\n");
        printGraph(g);
      then
        fail();
  end matchcontinue;
end analyzeInstance;

public function analyzeNode
  input Graph inG;
  input Context inContext;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext)
    local
      Graph g;
      Scope.Scope s;
      Instance i;
      Element e;
      list<Integer> kids;
      Integer sID, iID, nID;
      Context iContext, oContext;

    // see if this node has element kids, if so, do nothing
    case (g, iContext as CONTEXT(sID, nID, iID))
      equation
        (kids as _::_) = getNodeKids(g, nID, Node.e);
        oContext = iContext;
      then
        (g, oContext);

    // get the element and analyze it
    case (g, iContext as CONTEXT(sID, nID, iID))
      equation
        // analyze element
        Node.N(content = Node.E(e)) = getNodeById(g, nID);
        // we can only start from classes!
        (g, oContext) = analyzeElement(g, iContext, e, 1);
      then
        (g, oContext);

    // fail
    case(g, iContext)
      equation
        print("Failure in SCodeGraph.analyzeNode for scope/instance/node: " +&
               intString(contextSID(iContext)) +& "/" +&
               intString(contextNID(iContext)) +& "/" +&
               intString(contextIID(iContext)) +& "!\n");
        printGraph(g);
      then
        fail();
  end matchcontinue;
end analyzeNode;

public function analyzeElement
  input Graph inG;
  input Context inContext;
  input Element inEl;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inEl, order)
    local
      Graph g;
      Context iContext, oContext;

    // import
    case (g, iContext, inEl as Element.E(element = SCode.IMPORT(imp = _)), order)
      equation
        (g, oContext) = analyzeImport(g, iContext, inEl, order);
      then
        (g, oContext);

    // extends
    case (g, iContext, inEl as Element.E(element = SCode.EXTENDS(baseClassPath = _)), order)
      equation
        (g, oContext) = analyzeExtends(g, iContext, inEl, order);
      then
        (g, oContext);

    // class
    case (g, iContext, inEl as Element.E(element = SCode.CLASS(name = _)), order)
      equation
        (g, oContext) = analyzeClass(g, iContext, inEl, order);
      then
        (g, oContext);

    // component
    case (g, iContext, inEl as Element.E(element = SCode.COMPONENT(name = _)), order)
      equation
        (g, oContext) = analyzeComponent(g, iContext, inEl, order);
      then
        (g, oContext);

    // unit
    case (g, iContext, inEl as Element.E(element = SCode.DEFINEUNIT(name = _)), order)
      equation
        (g, oContext) = analyzeUnit(g, iContext, inEl, order);
      then
        (g, oContext);

    // fail
    case(g, iContext, inEl, order)
      equation
        print("Failure in SCodeGraph.analyzeElement for scope/instance/node/element: " +&
               intString(contextSID(iContext)) +& "/" +&
               intString(contextNID(iContext)) +& "/" +&
               intString(contextIID(iContext)) +& "/\n" +&
               SCodeDump.unparseElementStr(Element.element(inEl)) +&
               "\n");
        printGraph(g);
      then
        fail();
  end matchcontinue;
end analyzeElement;

public function analyzeImport
  input Graph inG;
  input Context inContext;
  input Element inEl;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inEl, order)
    local
      Graph g;
      Absyn.Import imp;
      Context iContext, oContext;
      Element e;

    // import
    case (g, iContext, inEl as Element.E(element = SCode.IMPORT(imp = imp)), order)
      equation
        // make a new element node and instance node for this element
        e = Element.setOrder(inEl, order);
        (g, oContext) = createElementNodeAndInstance(g, iContext, e); // set the new order
      then
        (g, oContext);
  end matchcontinue;
end analyzeImport;

public function analyzeExtends
  input Graph inG;
  input Context inContext;
  input Element inEl;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inEl, order)
    local
      Graph g;
      Absyn.Path path;
      Context iContext, oContext;

    // extends
    case (g, iContext, inEl as Element.E(element = SCode.EXTENDS(baseClassPath=path)), order)
      equation
        // make a new element node and instance node for this element
        (g, oContext) = createElementNodeAndInstance(g, iContext, Element.setOrder(inEl, order)); // set the new order
      then
        (g, oContext);
  end matchcontinue;
end analyzeExtends;

public function analyzeClass
  input Graph inG;
  input Context inContext;
  input Element inEl;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inEl, order)
    local
      Graph g;
      Scope.Scope s;
      Instance i;
      Node n;
      Integer scopeId, nodeId, instanceId, edgeId, sID, nID, iID;
      SCode.Element e;
      String name;
      Context iContext, oContext;
      SCode.ClassDef cdef;

    // class
    case (g, iContext as CONTEXT(sID, nID, iID), inEl as Element.E(element = SCode.CLASS(name = name, classDef = cdef)), order)
      equation
        // make a new element node and instance node for this class
        (g, oContext) = createElementNodeAndInstance(g, iContext, Element.setOrder(inEl, order)); // set the new order
        // dive into parts with new input
        (g, oContext) = analyzeClassDef(g, iContext, cdef, order);
      then
        (g, oContext);

  end matchcontinue;
end analyzeClass;

public function analyzeClassDef
  input Graph inG;
  input Context inContext;
  input SCode.ClassDef inCDef;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inCDef, order)
    local
      Graph g;
      Scope.Scope s;
      Instance i;
      Node n;
      Integer scopeId, nodeId, instanceId, edgeId, sID, nID, iID;
      SCode.Element e;
      Reference ureferences;
      String name;
      Absyn.Path path;
      list<SCode.Element> els;
      list<SCode.Equation> nel, iel;
      list<SCode.AlgorithmSection> nal,ial;
      list<SCode.ConstraintSection> nc;
      list<Absyn.NamedArg> clats "class attributes. currently for optimica extensions";
      Option<SCode.ExternalDecl> exd;
      list<SCode.Annotation> anl;
      Option<SCode.Comment> cmt;
      Context iContext, oContext;
      SCode.Prefixes prefixes;
      Absyn.TypeSpec typeSpec;
      SCode.Mod modifications;
      SCode.Attributes attributes;
      Option<SCode.Comment> comment;
      SCode.Ident baseClassName;
      list<SCode.Enum> enumLst;
      SCode.ClassDef cdef;

    // class
    case (g, iContext as CONTEXT(sID, nID, iID), SCode.PARTS(els,nel,iel,nal,ial,nc,clats,exd,anl,cmt), order)
      equation
        // dive into parts with new input
        (g, oContext) = analyzeElements(g, iContext, els, 1);
        (g, oContext) = analyzeEquations(g, iContext, nel, 1);
        (g, oContext) = analyzeEquations(g, iContext, iel, 1);
        /*
        (g, oContext) = analyzeAlgorithms(g, oContext, nal, 1);
        (g, oContext) = analyzeAlgorithms(g, oContext, ial, 1);
        (g, oContext) = analyzeExternal(g, oContext, exd, 1);
        (g, oContext) = analyzeAnnotations(g, oContext, anl, 1);
        (g, oContext) = analyzeComment(g, oContext, cmt, 1);
        */
        oContext = iContext;
      then
        (g, oContext);

    // derived class
    case (g, iContext as CONTEXT(sID, nID, iID), SCode.DERIVED(typeSpec, modifications, attributes, comment), order)
      equation
        // already handled above in createElementNodeAndInstance
        oContext = iContext;
      then
        (g, oContext);

    // class extends
    case (g, iContext as CONTEXT(sID, nID, iID), SCode.CLASS_EXTENDS(baseClassName, modifications, cdef), order)
      equation
        // dive into parts with new input
        (g, oContext) = analyzeClassDef(g, iContext, cdef, order);
      then
        (g, oContext);

    // enumeration
    case (g, iContext as CONTEXT(sID, nID, iID), SCode.ENUMERATION(enumLst, comment), order)
      equation
         //(g, oContext) = analyzeEnumList(g, oContext, enumLst, 1);
         oContext = iContext;
      then
        (g, oContext);
  end matchcontinue;
end analyzeClassDef;

public function analyzeEquations
  input Graph inG;
  input Context inContext;
  input list<SCode.Equation> inEqs;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inEqs, order)
    local
      Graph g;
      String name;
      Context iContext, oContext;
      Integer o;
      SCode.EEquation eEquation;
      list<SCode.Equation> rest;

    // empty
    case (g, iContext, {}, order) then (g, iContext);

    case (g, iContext, SCode.EQUATION(eEquation)::rest, o)
      equation
        //(g, _) = analyzeEquation(g, iContext, eEquation, o);
        (g, oContext) = analyzeEquations(g, iContext, rest, o + 1);
      then
        (g, oContext);

    case (g, iContext, inEqs, o)
      equation
        print("Failed in SCodeGraph.analyzeEquations\n");
      then
        fail();
  end matchcontinue;
end analyzeEquations;

public function analyzeElements
  input Graph inG;
  input Context inContext;
  input list<SCode.Element> inEls;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inEls, order)
    local
      Graph g;
      String name;
      Context iContext, oContext;
      Integer o;
      SCode.Element e;
      list<SCode.Element> rest;

    // empty
    case (g, iContext, {}, order) then (g, iContext);

    case (g, iContext, e::rest, o)
      equation
        (g, _) = analyzeElement(g, iContext, Element.E(e, o), o);
        (g, oContext) = analyzeElements(g, iContext, rest, o + 1);
      then
        (g, oContext);

    case (g, iContext, inEls, o)
      equation
        print("Failed in SCodeGrap.analyzeElements for: " +&
          stringDelimitList(List.map(inEls, SCodeDump.printElementStr), "\n") +&
          "\n--------------------\n");
      then
        fail();
  end matchcontinue;
end analyzeElements;

public function analyzeComponent
  input Graph inG;
  input Context inContext;
  input Element inEl;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inEl, order)
    local
      Graph g;
      String name;
      Context iContext, oContext;

    // component
    case (g, iContext, inEl as Element.E(element = SCode.COMPONENT(name = name)), order)
      equation
        // make a new element node and instance node for this component
        (g, oContext) = createElementNodeAndInstance(g, iContext, Element.setOrder(inEl, order)); // set the new order
      then
        (g, oContext);
  end matchcontinue;
end analyzeComponent;

public function analyzeUnit
  input Graph inG;
  input Context iContext;
  input Element inEl;
  input Integer order;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, iContext, inEl, order)
    local
      Graph g;
      String name;
      Context oContext;

    // unit
    case (g, iContext, inEl as Element.E(element = SCode.DEFINEUNIT(name = name)), order)
      equation
        // make a new element node and instance node for this class
        (g, oContext) = createElementNodeAndInstance(g, iContext, Element.setOrder(inEl, order)); // set the new order
      then
        (g, oContext);
  end matchcontinue;
end analyzeUnit;

public function getElementByName
"function: getElementByName
  Return the Element and its order with the name given in class"
  input String inIdent;
  input SCode.Element inClass;
  output SCode.Element outElement;
  output Integer order;
algorithm
  (outElement, order) := matchcontinue (inIdent,inClass)
    local
      SCode.Element elt;
      String id;
      list<SCode.Element> elts;
      Integer o;

    // class
    case (id, SCode.CLASS(classDef = SCode.PARTS(elementLst = elts)))
      equation
        (elt, o) = getElementNamedFromElts(id, elts, 1);
      then
        (elt, o);

    // class extends
    case (id, SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = SCode.PARTS(elementLst = elts))))
      equation
        (elt,o) = getElementNamedFromElts(id, elts, 1);
      then
        (elt,o);

    // failure
    case (id, inClass)
      equation
        print("Failure in SCodeGraph.getElementByName for name: " +&
          id +& " class:\n" +& SCodeDump.unparseElementStr(inClass) +& "\n");
      then
        fail();
  end matchcontinue;
end getElementByName;

protected function getElementNamedFromElts
"function: getElementNamedFromElts
  Helper function to getElementByName"
  input String inIdent;
  input list<SCode.Element> inElementLst;
  input Integer startAt;
  output SCode.Element outElement;
  output Integer order;
algorithm
  (outElement, order) := matchcontinue (inIdent,inElementLst,startAt)
    local
      SCode.Element elt;
      String byName,id;
      list<SCode.Element> rest;
      Integer o;

    // fail if the list is empty
    case (byName,{},startAt)
      then fail();

    case (byName, (elt as SCode.COMPONENT(name = id)) :: _, startAt)
      equation
        true = stringEq(id, byName);
      then
        (elt, startAt);

    case (byName, (elt as SCode.CLASS(name = id)) :: _, startAt)
      equation
        true = stringEq(id, byName);
      then
        (elt, startAt);

    // try next as we only handle component and classes
    case (byName, _:: rest, startAt)
      equation
        (elt, o) = getElementNamedFromElts(byName, rest, startAt + 1);
      then
        (elt, o);

  end matchcontinue;
end getElementNamedFromElts;

public
function addNode
"adds the node to the graph and returns the update graph and the node id"
  input Graph ig;
  input Node n;
  output Graph og;
  output Integer id;
protected
  Nodes nodes;
  Edges edges;
  Names names;
  Scopes scopes;
  Scope2Node s2n;
  Node2Edge n2e;
  Node2Kids n2k;
  LookupStatus lookupStatus;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := ig;
  // add the node
  (nodes, id) := Node.addAutoUpdateId(nodes, n);
  // add the relation scope+node type->node
  s2n := addScope2Name(s2n, Node.get(nodes, id));
  og := GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus);
  // print("Added node: " +& intString(id) +& " scope:" +& scopeStr(og, Node.scopeId(n)) +& " kind: " +& intString(Node.kind(n)) +& "\n");
end addNode;

protected function addScope2Name
  input Scope2Node is2n;
  input Node node;
  output Scope2Node os2n;
algorithm
  os2n := matchcontinue(is2n, node)
    local
      Node n;
      Scope2Node s2n;

    // only add element nodes
    case (is2n, n /*as Node.N(content = Node.E(_))*/)
      equation
        s2n = Relation.add(is2n, ((Node.scopeId(n),Node.kind(n))), Node.id(n));
      then
        s2n;

    // ignore other node types
    case (is2n, n) then is2n;

  end matchcontinue;
end addScope2Name;

public function addEdge
"adds the edge to the graph and returns the update graph and the edge id"
  input Graph ig;
  input Edge e;
  output Graph og;
  output Integer id;
protected
  Nodes nodes;
  Edges edges;
  Names names;
  Scopes scopes;
  Scope2Node s2n;
  Node2Edge n2e;
  Node2Kids n2k;
  LookupStatus lookupStatus;
  Node nSource, nTarget;
algorithm
  GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus) := ig;
  // add the edge
  (edges, id) := Edge.addAutoUpdateId(edges, e);
  n2e := Relation.add(n2e, (Edge.sourceId(e), Edge.kind(e)), (id, Edge.targetId(e)));
  // get the nodes and add the child relation
  nSource := getNodeById(ig, Edge.sourceId(e));
  nTarget := getNodeById(ig, Edge.targetId(e));
  n2k := addKidsRelation(n2k, nSource, nTarget, Edge.kind(e));
  // update the graph
  og := GRAPH(nodes, edges, names, scopes, RELS(s2n, n2e, n2k), lookupStatus);
end addEdge;

protected function addKidsRelation
  input Node2Kids inN2K;
  input Node source;
  input Node target;
  input Integer edgeKind;
  output Node2Kids outN2K;
algorithm
  outN2K := matchcontinue(inN2K, source, target, edgeKind)
    local
      list<Integer> kids;
      Node2Kids n2k;
      Integer sourceID, targetID, sourceKind;

    // see if target already has some children
    case (n2k, source, target, edgeKind)
      equation
        sourceID = Node.id(source);
        targetID = Node.id(target);
        sourceKind = Node.kind(source);
        // will fail if there are none
        kids = Relation.getTargetFromSource(n2k, (targetID, sourceKind));
        // if they are some, add the new source to them
        n2k = Relation.add(n2k, (targetID, sourceKind), sourceID::kids);
      then
        n2k;

    // no children yet, add this one
    case (n2k, source, target, edgeKind)
      equation
        sourceID = Node.id(source);
        targetID = Node.id(target);
        sourceKind = Node.kind(source);
        n2k = Relation.add(n2k, (targetID, sourceKind), {sourceID});
      then
        n2k;

  end matchcontinue;
end addKidsRelation;

function createElementNodeAndInstance
"@creates an element node and an instance node for it
  with the given parents"
  input Graph inGraph;
  input Context inContext "context info (parent scope id, parent element node id, parent instance node id)";
  input Element inEl;
  output Graph outGraph "the changed graph";
  output Context outContext "returns the new context";
algorithm
  (outGraph, outContext) := matchcontinue(inGraph, inContext, inEl)
    local
      Integer scopeId, nodeId, instanceId, edgeId, sID, nID, iID;
      String name;
      SegmentKind segmentKind;
      Instance i;
      Context context;
      Graph g;

    case (g, CONTEXT(sID, nID, iID), inEl)
      equation
        (name, segmentKind) = Element.properties(inEl);

        // make a new scope for this element
        (g, scopeId) = newScope(g, name, sID, segmentKind);

        // make new node containing this element
        (g, nodeId) = addNode(g, Node.N(autoId, scopeId, Node.E(inEl)));

        // make a void node for the instance to get an id
        (g, instanceId) = addNode(g, Node.N(autoId, scopeId, Node.V()));

        // no changes in the context from now on!
        context = CONTEXT(scopeId, nodeId, instanceId);

        // create an instance node, references, etc
        (g, context) = elementInstance(g, context, inEl);

        // create an edge between the node and the instance
        (g, edgeId) = addEdge(g, Edge.E(autoId, instanceId, nodeId, Edge.cb));

        // add parent edges
        (g, edgeId) = addEdge(g, Edge.E(autoId, nodeId, nID, Edge.co));
        (g, edgeId) = addEdge(g, Edge.E(autoId, instanceId, iID, Edge.co));

        // create reference nodes for refs

        // add edges from refs to the instance

      then
        (g, context);

  end matchcontinue;
end createElementNodeAndInstance;

public function elementInstance "returns the element properties and the instance"
  input Graph inG;
  input Context inContext;
  input Element inEl;
  output Graph outG;
  output Context outContext;
algorithm
  (outG, outContext) := matchcontinue(inG, inContext, inEl)
    local
      String id;
      Absyn.Path p;
      Absyn.Import imp;
      Context iContext, oContext;
      Graph g;
      Node iNode;
      Instance i;

    case (g, iContext, Element.E(element = SCode.IMPORT(imp = imp)))
      equation
        id = Absyn.printImportString(imp);
        // get the void instance node
        iNode = Node.get(getNodes(g), contextIID(iContext));
        // make the new instance
        i = Instance.I(Instance.II(Instance.UIM(0)), Instance.INI());
        // set the node contents
        iNode = Node.setContent(iNode, Node.I(i));
        // update the node in graph
        g = setNodes(g, Node.set(getNodes(g), contextIID(iContext), iNode));
        oContext = iContext;
      then
        (g, oContext);

    case (g, iContext, Element.E(element = SCode.EXTENDS(baseClassPath = p)))
      equation
        id = Absyn.pathString(p);
        // get the void instance node
        iNode = Node.get(getNodes(g), contextIID(iContext));
        // make the new instance
        i = Instance.I(Instance.EI(0), Instance.INI());
        // set the node contents
        iNode = Node.setContent(iNode, Node.I(i));
        // update the node in graph
        g = setNodes(g, Node.set(getNodes(g), contextIID(iContext), iNode));
        oContext = iContext;
      then
        (g, oContext);

    case (g, iContext, Element.E(element = SCode.CLASS(name = id)))
      equation
        // get the void instance node
        iNode = Node.get(getNodes(g), contextIID(iContext));
        // make the new instance
        i = Instance.I(Instance.TI(Instance.LOCD(0)), Instance.INI());
        // set the node contents
        iNode = Node.setContent(iNode, Node.I(i));
        // update the node in graph
        g = setNodes(g, Node.set(getNodes(g), contextIID(iContext), iNode));
        oContext = iContext;
      then
        (g, oContext);

    case (g, iContext, Element.E(element = SCode.COMPONENT(name = id)))
      equation
        // get the void instance node
        iNode = Node.get(getNodes(g), contextIID(iContext));
        // make the new instance
        i = Instance.I(Instance.CI(0, 0), Instance.INI());
        // set the node contents
        iNode = Node.setContent(iNode, Node.I(i));
        // update the node in graph
        g = setNodes(g, Node.set(getNodes(g), contextIID(iContext), iNode));
        oContext = iContext;
      then
        (g, oContext);

    case (g, iContext, Element.E(element = SCode.DEFINEUNIT(name = id)))
      equation
        // get the void instance node
        iNode = Node.get(getNodes(g), contextIID(iContext));
        // make the new instance
        i = Instance.I(Instance.UI(), Instance.INI());
        // set the node contents
        iNode = Node.setContent(iNode, Node.I(i));
        // update the node in graph
        g = setNodes(g, Node.set(getNodes(g), contextIID(iContext), iNode));
        oContext = iContext;
      then
        (g, oContext);

  end matchcontinue;
end elementInstance;

function printContextStr
  input Graph g;
  input Context c;
  output String s;
protected
  Integer sID, nID, iID;
algorithm
  CONTEXT(sID, nID, iID) := c;
  s := "Context( S[" +& intString(sID) +& "," +& scopeStr(g, sID) +& "] / N[" +& intString(nID) +& "] / I[" +& intString(iID) +& "] )";
end printContextStr;

function scopeStr
  input Graph g;
  input Integer sID;
  output String s;
algorithm
 s := Scope.scopeStr(getNames(g), getScopeById(g, sID));
end scopeStr;

function contextSID
"get scope id from context"
  input Context c;
  output Integer sID;
algorithm
  CONTEXT(sID = sID) := c;
end contextSID;

function contextNID
"get element node id from context"
  input Context c;
  output Integer nID;
algorithm
  CONTEXT(nID = nID) := c;
end contextNID;

function contextIID
"get instance node id from context"
  input Context c;
  output Integer iID;
algorithm
  CONTEXT(iID = iID) := c;
end contextIID;

end SCodeGraph;


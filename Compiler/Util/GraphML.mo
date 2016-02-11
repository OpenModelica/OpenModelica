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

encapsulated package GraphML
" file:        GraphML
  package:     GraphML
  description: GraphML contains functions to generate a gaphML file for yED. The implementation is based on the GraphML-Package of Jens Frenkel.


"

protected import List;
protected import GraphMLDumpTpl;
protected import Tpl;
protected import Util;

//TODO: Use HashTable for nodes to prevent duplicates

// -------------------------
// Constant types
// -------------------------

public constant String COLOR_BLACK      = "000000";
public constant String COLOR_BLUE      = "0000FF";
public constant String COLOR_GREEN      = "339966";
public constant String COLOR_RED      = "FF0000";
public constant String COLOR_DARKRED  = "800000";
public constant String COLOR_WHITE      = "FFFFFF";
public constant String COLOR_YELLOW      = "FFFF00";
public constant String COLOR_GRAY      = "C0C0C0";
public constant String COLOR_PURPLE   = "993366";
public constant String COLOR_ORANGE   = "FFCC00";
public constant String COLOR_DARKGRAY      = "666666";
public constant String COLOR_RED2      = "F0988E";
public constant String COLOR_GREEN2      = "98B954";
public constant String COLOR_ORANGE2      = "FFA851";
public constant String COLOR_CYAN       = "46BED8";
public constant String COLOR_PINK       = "CF8CB7";


public constant Real LINEWIDTH_STANDARD   = 2.0;
public constant Real LINEWIDTH_BOLD   = 4.0;

public constant Integer FONTSIZE_STANDARD   = 12;
public constant Integer FONTSIZE_BIG   = 20;
public constant Integer FONTSIZE_SMALL   = 8;


// -------------------------
// Data structures
// -------------------------

public uniontype GraphInfo
  record GRAPHINFO
    list<Graph> graphs;
    Integer graphCount; //number of graphs in the graphs list
    list<Node> nodes;
    Integer nodeCount; //number of nodes in the nodes list
    list<Edge> edges;
    Integer edgeCount; //number of edges in the edge list
    list<Attribute> attributes;
    String graphNodeKey;
    String graphEdgeKey;
  end GRAPHINFO;
  record GRAPHINFOARR //This structure is used by Susan
    array<Graph> graphs;
    array<Node> nodes;
    list<Edge> edges;
    array<Attribute> attributes;
    String graphNodeKey;
    String graphEdgeKey;
  end GRAPHINFOARR;
end GraphInfo;

public uniontype Graph
  record GRAPH
    String id;
    Boolean directed;
    list<Integer> nodeIdc; //attention: reversed indices --> to get real idx for value i, calculate graph.nodeCount - i
    list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPHINFO definition). <attributeIndex,attributeValue>
  end GRAPH;
end Graph;

public uniontype Node
  record NODE
    String id;
    String color;
    list<NodeLabel> nodeLabels;
    ShapeType shapeType;
    Option<String> optDesc;
    list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPH definition). <attributeIndex,attributeValue>
  end NODE;
  record GROUPNODE
    String id;
    Integer internalGraphIdx;
    Boolean isFolded;
    String header;
  end GROUPNODE;
end Node;

public uniontype Edge
  record EDGE
    String id;
    String target;
    String source;
    String color;
    LineType lineType;
    Real lineWidth;
    Boolean smooth;
    list<EdgeLabel> edgeLabels;
    tuple<ArrowType,ArrowType> arrows;
    list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPH definition). <attributeIndex,attributeValue>
  end EDGE;
end Edge;

public uniontype Attribute
  record ATTRIBUTE
    Integer attIdx;
    String defaultValue;
    String name;
    AttributeType attType;
    AttributeTarget attTarget;
  end ATTRIBUTE;
end Attribute;

public uniontype NodeLabel
  record NODELABEL_INTERNAL
    String text;
    Option<String> backgroundColor;
    FontStyle fontStyle;
  end NODELABEL_INTERNAL;
  record NODELABEL_CORNER
    String text;
    Option<String> backgroundColor;
    FontStyle fontStyle;
    String position; //for example "se" for south east
  end NODELABEL_CORNER;
end NodeLabel;

public uniontype EdgeLabel
  record EDGELABEL
    String text;
    Option<String> backgroundColor;
    Integer fontSize;
  end EDGELABEL;
end EdgeLabel;

public uniontype FontStyle
  record FONTPLAIN end FONTPLAIN;
  record FONTBOLD end FONTBOLD;
  record FONTITALIC end FONTITALIC;
  record FONTBOLDITALIC end FONTBOLDITALIC;
end FontStyle;

public uniontype ShapeType
  record RECTANGLE end RECTANGLE;
  record ROUNDRECTANGLE end ROUNDRECTANGLE;
  record ELLIPSE end ELLIPSE;
  record PARALLELOGRAM end PARALLELOGRAM;
  record HEXAGON end HEXAGON;
  record TRIANGLE end TRIANGLE;
  record OCTAGON end OCTAGON;
  record DIAMOND end DIAMOND;
  record TRAPEZOID end TRAPEZOID;
  record TRAPEZOID2 end TRAPEZOID2;
end ShapeType;

public uniontype LineType
  record LINE end LINE;
  record DASHED end DASHED;
  record DASHEDDOTTED end DASHEDDOTTED;
end LineType;

public uniontype ArrowType
  record ARROWSTANDART end ARROWSTANDART;
  record ARROWNONE end ARROWNONE;
  record ARROWCONCAVE end ARROWCONCAVE;
end ArrowType;

public uniontype AttributeType
  record TYPE_STRING end TYPE_STRING;
  record TYPE_BOOLEAN end TYPE_BOOLEAN;
  record TYPE_INTEGER end TYPE_INTEGER;
  record TYPE_DOUBLE end TYPE_DOUBLE;
end AttributeType;

public uniontype AttributeTarget
  record TARGET_NODE end TARGET_NODE;
  record TARGET_EDGE end TARGET_EDGE;
  record TARGET_GRAPH end TARGET_GRAPH;
end AttributeTarget;

// -------------------------
// Logic
// -------------------------

public function createGraphInfo "author: marcusw
  Creates a new and empty graphInfo."
  output GraphInfo oGraphInfo;
algorithm
  oGraphInfo := GRAPHINFO({},0,{},0,{},0,{}, "gi1", "gi2");
end createGraphInfo;

public function addGraph "author: marcusw
  Adds a new graph to the given graphInfo."
  input String id; //graph id -> must be unique in the graphinfo!
  input Boolean directed; //directed edges
  input GraphInfo iGraphInfo;
  output GraphInfo oGraphInfo;
  output tuple<Graph,Integer> oGraph; //graph with graphIdx
protected
  Graph tmpGraph;
  list<Graph> graphs;
  Integer graphCount; //number of graphs in the graphs list
  list<Node> nodes;
  Integer nodeCount; //number of nodes in the nodes list
  list<Edge> edges;
  Integer edgeCount; //number of edges in the edge list
  list<Attribute> attributes;
  String graphNodeKey;
  String graphEdgeKey;
algorithm
  GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey) := iGraphInfo;
  graphCount := graphCount + 1;
  tmpGraph := GRAPH(id, directed, {}, {});
  graphs := tmpGraph :: graphs;
  oGraphInfo := GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey);
  oGraph := (tmpGraph, graphCount);
end addGraph;

public function addNode "author: marcusw
  Adds a new node to the given graph which is part of the given graphInfo."
  input String id; //node id -> must be unique in the graphinfo!
  input String backgroundColor;
  input list<NodeLabel> nodeLabels; //a list of labels that should be displayed in or along the node
  input ShapeType shapeType;
  input Option<String> optDesc;
  input list<tuple<Integer,String>> attValues; //a key-value list of additional values -> the keys have to be registered in the graphinfo-structure first

  input Integer iGraphIdx; //the parent-graph of the new node -> with this additional information, nested graphs are supported now
  input GraphInfo iGraphInfo;
  output GraphInfo oGraphInfo;
  output tuple<Node,Integer> oNode; //node with nodeIdx
protected
  Node tmpNode;
  //values of graphinfo
  list<Graph> graphs;
  Integer graphCount; //number of graphs in the graphs list
  list<Node> nodes;
  Integer nodeCount; //number of nodes in the nodes list
  list<Edge> edges;
  Integer edgeCount; //number of edges in the edge list
  list<Attribute> attributes;
  String graphNodeKey;
  String graphEdgeKey;

  //values of graph
  Graph iGraph;
  String gid;
  Boolean directed;
  list<Integer> nodeIdc;
  list<tuple<Integer,String>> gAttValues;
algorithm
  GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey) := iGraphInfo;
  iGraph := listGet(graphs,graphCount-iGraphIdx+1);
  GRAPH(gid,directed,nodeIdc,gAttValues) := iGraph;
  nodeCount := nodeCount + 1;
  tmpNode := NODE(id, backgroundColor, nodeLabels, shapeType, optDesc, attValues);
  nodes := tmpNode :: nodes;
  nodeIdc := nodeCount :: nodeIdc;
  iGraph := GRAPH(gid,directed,nodeIdc,gAttValues);
  graphs := List.set(graphs,graphCount-iGraphIdx+1,iGraph);
  oGraphInfo := GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey);
  oNode := (tmpNode, nodeCount);
end addNode;

public function addGroupNode "author: marcusw
  Adds a new group node to the given graphInfo. The created node contains a new graph which is returned as second output-argument."
  input String id; //node id -> must be unique in the graphinfo!
  input Integer iGraphIdx;
  input Boolean isFolded; //true if the group-node should be folded by default
  input String iHeader; //header text which should be displayed on top of the group
  input GraphInfo iGraphInfo;
  output GraphInfo oGraphInfo;
  output tuple<Node,Integer> oNode; //node with nodeIdx
  output tuple<Graph,Integer> oGraph; //subgraph with graphIdx
protected
  GraphInfo tmpGraphInfo;
  Node tmpNode;
  //values of graphinfo
  list<Graph> graphs;
  Integer graphCount; //number of graphs in the graphs list
  list<Node> nodes;
  Integer nodeCount; //number of nodes in the nodes list
  list<Edge> edges;
  Integer edgeCount; //number of edges in the edge list
  list<Attribute> attributes;
  String graphNodeKey;
  String graphEdgeKey;

  //values of graph
  Graph iGraph, newGraph;
  String gid;
  Boolean directed;
  Integer newGraphIdx;
  list<Integer> nodeIdc;
  list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPHINFO definition). <attributeIndex,attributeValue>
algorithm
  GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey) := iGraphInfo;
  iGraph := listGet(graphs,graphCount-iGraphIdx+1);
  GRAPH(gid,directed,nodeIdc,attValues) := iGraph;
  //Add new sub graph
  (tmpGraphInfo,(newGraph,newGraphIdx)) := addGraph("g" + id, directed, iGraphInfo);
  GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey) := tmpGraphInfo;
  //Append node to graph
  nodeCount := nodeCount + 1;
  tmpNode := GROUPNODE(id, newGraphIdx,isFolded,iHeader);
  nodes := tmpNode :: nodes;
  nodeIdc := nodeCount :: nodeIdc;

  iGraph := GRAPH(gid,directed,nodeIdc,attValues);
  graphs := List.set(graphs,graphCount-iGraphIdx+1,iGraph);
  oGraphInfo := GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey);
  oNode := (tmpNode, nodeCount);
  oGraph := (newGraph,newGraphIdx);
end addGroupNode;

public function addEdge "author: marcusw
  Adds a new edge to the graphInfo-structure. Edges are always added to the top-level graph."
  input String id;
  input String target;
  input String source;
  input String color;
  input LineType lineType;
  input Real lineWidth;
  input Boolean smooth;
  input list<EdgeLabel> labels;
  input tuple<ArrowType,ArrowType> arrows;
  input list<tuple<Integer,String>> attValues;

  input GraphInfo iGraphInfo;
  output GraphInfo oGraphInfo;
  output tuple<Edge,Integer> oEdge; //edge with edgeIdx
protected
  Edge tmpEdge;
  //values of graphinfo
  list<Graph> graphs;
  Integer graphCount; //number of graphs in the graphs list
  list<Node> nodes;
  Integer nodeCount; //number of nodes in the nodes list
  list<Edge> edges;
  Integer edgeCount; //number of edges in the edge list
  list<Attribute> attributes;
  String graphNodeKey;
  String graphEdgeKey;

algorithm
  GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey) := iGraphInfo;
  edgeCount := edgeCount + 1;
  tmpEdge := EDGE(id, target, source, color, lineType, lineWidth, smooth, labels, arrows, attValues);
  edges := tmpEdge :: edges;
  oGraphInfo := GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey);
  oEdge := (tmpEdge, edgeCount);
end addEdge;

public function addAttribute "author: marcusw
  Adds a new attribute to the given graphInfo.
  These attributes can be used by graphs, nodes and edges to display some additional informations."
  input String defaultValue;
  input String name;
  input AttributeType attType;
  input AttributeTarget attTarget;

  input GraphInfo iGraphInfo;
  output GraphInfo oGraphInfo;
  output tuple<Attribute,Integer> oAttribute; //attribute with attributeIdx
protected
  Attribute tmpAttribute;
  Integer attIdx;
  //values of graphinfo
  list<Graph> graphs;
  Integer graphCount; //number of graphs in the graphs list
  list<Node> nodes;
  Integer nodeCount; //number of nodes in the nodes list
  list<Edge> edges;
  Integer edgeCount; //number of edges in the edge list
  list<Attribute> attributes;
  String graphNodeKey;
  String graphEdgeKey;
algorithm
  GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey) := iGraphInfo;
  attIdx := listLength(attributes)+1;
  tmpAttribute := ATTRIBUTE(attIdx,defaultValue,name,attType,attTarget);
  attributes := tmpAttribute :: attributes;
  oGraphInfo := GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey);
  oAttribute := (tmpAttribute,attIdx);
end addAttribute;

public function addGraphAttributeValue "author: marcusw
  Adds a new value for a given attribute to the graph."
  input tuple<Integer,String> iValue; //attributeIdx, attributeValue
  input Integer iGraphIdx;
  input GraphInfo iGraphInfo;
  output GraphInfo oGraphInfo;
protected
  //values of graphinfo
  list<Graph> graphs;
  Integer graphCount; //number of graphs in the graphs list
  list<Node> nodes;
  Integer nodeCount; //number of nodes in the nodes list
  list<Edge> edges;
  Integer edgeCount; //number of edges in the edge list
  list<Attribute> attributes;
  String graphNodeKey;
  String graphEdgeKey;
  //values of graph
  Graph iGraph;
  String gid;
  Boolean directed;
  Integer newGraphIdx;
  list<Integer> nodeIdc;
  list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPHINFO definition). <attributeIndex,attributeValue>
algorithm
  GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey) := iGraphInfo;
  iGraph := listGet(graphs,graphCount-iGraphIdx+1);
  GRAPH(gid,directed,nodeIdc,attValues) := iGraph;

  //Append attribute to graph
  attValues := iValue :: attValues;

  iGraph := GRAPH(gid,directed,nodeIdc,attValues);
  graphs := List.set(graphs,graphCount-iGraphIdx+1,iGraph);
  oGraphInfo := GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey);
end addGraphAttributeValue;

// -------------------------
// Helper
// -------------------------
public function getMainGraph "author: marcusw
  This function will return the top-level graph (usually with index 1) if there is one in the graphInfo-structure.
  Otherwise it will return NONE()."
  input GraphInfo iGraphInfo;
  output Option<tuple<Integer,Graph>> oGraph;
protected
  list<Graph> graphs;
  Graph firstGraph;
algorithm
  oGraph := match(iGraphInfo)
    case(GRAPHINFO(graphCount=0))
      then NONE();
    case(GRAPHINFO(graphs=graphs))
      equation
        firstGraph = listHead(graphs);
      then SOME((1,firstGraph));
  end match;
end getMainGraph;

public function getAttributeByNameAndTarget
  input String iAttributeName;
  input AttributeTarget iAttributeTarget;
  input GraphInfo iGraphInfo;
  output Option<tuple<Attribute,Integer>> oAttribute; //SOME(<%attIdx,attribute%>) if the attribute was found in graphInfo
protected
  list<Attribute> attributes;
  Option<tuple<Attribute,Integer>> tmpRes;
algorithm
  oAttribute := match(iAttributeName,iAttributeTarget,iGraphInfo)
    case(_,_,GRAPHINFO(attributes=attributes))
      equation
        tmpRes = getAttributeByNameAndTargetTail(attributes, iAttributeName, iAttributeTarget);
      then tmpRes;
    case(_,_,GRAPHINFO(attributes=attributes))
      equation
        tmpRes = getAttributeByNameAndTargetTail(attributes, iAttributeName, iAttributeTarget);
      then tmpRes;
   end match;
end getAttributeByNameAndTarget;

protected function getAttributeByNameAndTargetTail
  input list<Attribute> iList;
  input String iAttributeName;
  input AttributeTarget iAttributeTarget;
  output Option<tuple<Attribute,Integer>> oAttribute;
protected
  list<Attribute> rest;
  Integer attIdx;
  String name;
  Attribute head;
  AttributeTarget attTarget;
   Option<tuple<Attribute,Integer>> tmpAttribute;
algorithm
  oAttribute := matchcontinue(iList,iAttributeName,iAttributeTarget)
    case((head as ATTRIBUTE(attIdx=attIdx,name=name,attTarget=attTarget))::rest,_,_)
      equation
        true = stringEq(name, iAttributeName);
        true = compareAttributeTargets(iAttributeTarget,attTarget);
      then SOME((head,attIdx));
    case(head::rest,_,_)
      equation
        tmpAttribute = getAttributeByNameAndTargetTail(rest,iAttributeName,iAttributeTarget);
      then tmpAttribute;
    else
      then NONE();
  end matchcontinue;
end getAttributeByNameAndTargetTail;

protected function compareAttributeTargets
  input AttributeTarget iTarget1;
  input AttributeTarget iTarget2;
  output Boolean oEqual;
protected
  Integer tarInt1, tarInt2;
algorithm
  tarInt1 := compareAttributeTarget0(iTarget1);
  tarInt2 := compareAttributeTarget0(iTarget2);
  oEqual := intEq(tarInt1,tarInt2);
end compareAttributeTargets;

protected function compareAttributeTarget0
  input AttributeTarget iTarget;
  output Integer oCodec;
algorithm
  oCodec := match(iTarget)
    case(TARGET_NODE()) then 0;
    case(TARGET_EDGE()) then 1;
    case(TARGET_GRAPH()) then 1;
  end match;
end compareAttributeTarget0;

// -------------------------
// Dump
// -------------------------


public function dumpGraph "author: marcusw
  Dumps the graph into a *.graphml-file."
  input GraphInfo iGraphInfo;
  input String iFileName;
protected
  GraphInfo iGraphInfoArr;
algorithm
  iGraphInfoArr := convertToGraphInfoArr(iGraphInfo);
  Tpl.tplNoret2(GraphMLDumpTpl.dumpGraphInfo, iGraphInfoArr, iFileName);
end dumpGraph;

protected function convertToGraphInfoArr "author: marcusw
  Converts the given GRAPHINFO-object into a GRAPHINFOARR-object."
  input GraphInfo iGraphInfo;
  output GraphInfo oGraphInfo;
protected
  //values of graphinfo
  list<Graph> graphs;
  array<Graph> graphsArr;
  Integer graphCount; //number of graphs in the graphs list
  list<Node> nodes;
  array<Node> nodesArr;
  Integer nodeCount; //number of nodes in the nodes list
  list<Edge> edges;
  Integer edgeCount; //number of edges in the edge list
  list<Attribute> attributes;
  array<Attribute> attributesArr;
  String graphNodeKey;
  String graphEdgeKey;
algorithm
  GRAPHINFO(graphs,graphCount,nodes,nodeCount,edges,edgeCount,attributes,graphNodeKey,graphEdgeKey) := iGraphInfo;
  graphsArr := listArray(graphs);
  nodesArr := listArray(nodes);
  attributesArr := listArray(listReverse(attributes));
  oGraphInfo := GRAPHINFOARR(graphsArr,nodesArr,edges,attributesArr,graphNodeKey,graphEdgeKey);
end convertToGraphInfoArr;

// -------------------------
// debug prints
// -------------------------
public function printGraphInfo
  input GraphInfo iGraphInfo;
protected
    list<Graph> graphs;
    Integer graphCount; //number of graphs in the graphs list
    list<Node> nodes;
    Integer nodeCount; //number of nodes in the nodes list
    list<Edge> edges;
    Integer edgeCount; //number of edges in the edge list
    list<Attribute> attributes;
    String graphNodeKey;
    String graphEdgeKey;
algorithm
  GRAPHINFO(graphs=graphs,graphCount=graphCount,nodes=nodes,nodeCount=nodeCount,attributes=attributes,graphNodeKey=graphNodeKey,graphEdgeKey=graphEdgeKey) := iGraphInfo;
  List.map_0(nodes,printNode);
  print("nodeCount: "+intString(nodeCount)+"\n");
  print("graphCount: "+intString(graphCount)+"\n");
end printGraphInfo;

protected function printNode
  input Node node;
protected
    String id,atts;
    String color;
    list<NodeLabel> nodeLabels;
    ShapeType shapeType;
    Option<String> optDesc;
    list<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPH definition). <attributeIndex,attributeValue>
algorithm
  NODE(id=id,optDesc=optDesc,attValues=attValues) := node;
  atts := stringDelimitList(List.map(attValues,Util.tuple22)," | ");
  print("node: "+id+" desc: "+Util.getOption(optDesc)+"\n\tatts: "+atts+"\n");
end printNode;

annotation(__OpenModelica_Interface="susan");
end GraphML;

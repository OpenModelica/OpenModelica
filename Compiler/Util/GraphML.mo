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

encapsulated package GraphML
" file:         GraphML
  package:     GraphML
  description: GraphML contains functions to generate a gaphML file for yED


  RCS: $Id: GraphML 9566 2011-08-01 07:04:56Z perost $
"

protected import Util;
protected import List;
protected import System;
protected import IOStream;

/*************************************************
 * types
 ************************************************/

public constant String COLOR_BLACK      = "000000";
public constant String COLOR_BLUE      = "0000FF";
public constant String COLOR_GREEN      = "339966";
public constant String COLOR_RED      = "FF0000";
public constant String COLOR_DARKRED  = "800000";
public constant String COLOR_WHITE      = "FFFFFF";
public constant String COLOR_YELLOW      = "FFCC00";
public constant String COLOR_GRAY      = "C0C0C0";
public constant String COLOR_PURPLE   = "993366";


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
end ArrowType;

public uniontype Node
  record NODE
    String id;
    String text;
    String color;
    ShapeType shapeType;
    Option<String> optDesc;
    List<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPH definition). <attributeIndex,attributeValue>
  end NODE;
end Node;

public uniontype EdgeLabel
  record EDGELABEL
    String text;
    String color;
  end EDGELABEL;
end EdgeLabel;

public uniontype Edge
  record EDGE
    String id;
    String target;
    String source;
    String color;
    LineType lineType;
    Option<EdgeLabel> label;
    tuple<Option<ArrowType>,Option<ArrowType>> arrows;
    List<tuple<Integer,String>> attValues; //values of custom attributes (see GRAPH definition). <attributeIndex,attributeValue>
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

public uniontype Graph
  record GRAPH
    String id;
    Boolean directed;
    list<Node> nodes;
    list<Edge> edges;
    list<Attribute> attributes;
  end GRAPH;
end Graph;

/*************************************************
 * public
 ************************************************/

public function getGraph
"function getGraph
 author: Frenkel TUD 2011-08
 get a empty graph"
  input String id;
  input Boolean directed;
  output Graph g;
algorithm
  g := GRAPH(id,directed,{},{},{});
end getGraph;

public function addNode
"function addNode
 author: Frenkel TUD 2011-08
 add a node"
  input String id;
  input String text;
  input String color;
  input ShapeType shapeType;
  input Option<String> optDesc;
  input List<tuple<Integer,String>> attValues;
  input Graph inG;
  output Graph outG;
protected
  String gid;
  Boolean d;
  list<Node> n;
  list<Edge> e;
  list<Attribute> a;
algorithm
  GRAPH(gid,d,n,e,a) := inG;
  outG := GRAPH(gid,d,NODE(id,text,color,shapeType,optDesc,attValues)::n,e,a);
end addNode;

public function addEgde
"function addEgde
 author: Frenkel TUD 2011-08
 add a edge"
  input String id;
  input String target;
  input String source;
  input String color;
  input LineType lineType;
  input Option<EdgeLabel> label;
  input tuple<Option<ArrowType>,Option<ArrowType>> arrows;
  input List<tuple<Integer,String>> attValues;
  input Graph inG;
  output Graph outG;
protected
  String gid;
  Boolean d;
  list<Node> n;
  list<Edge> e;
  list<Attribute> a;
algorithm
  GRAPH(gid,d,n,e,a) := inG;
  outG := GRAPH(gid,d,n,EDGE(id,target,source,color,lineType,label,arrows,attValues)::e,a);
end addEgde;

public function addAttribute
  input String defaultValue;
  input String name;
  input AttributeType attType;
  input AttributeTarget attTarget;
  input Graph inG;
  output Integer oAttIdx;
  output Graph outG;

protected
  String gid;
  Boolean d;
  list<Node> n;
  list<Edge> e;
  list<Attribute> a;
  Integer attIdx;
algorithm
  GRAPH(gid,d,n,e,a) := inG;
  attIdx := listLength(a)+1;
  oAttIdx := attIdx;
  outG := GRAPH(gid,d,n,e,ATTRIBUTE(attIdx,defaultValue,name,attType,attTarget)::a);

end addAttribute;

public function dumpGraph
"function dumpGraph
 author: Frenkel TUD 2011-08
 print the graph"
  input Graph inGraph;
  input String name;
protected
  String str;
  IOStream.IOStream is;
algorithm
  is := IOStream.create(name, IOStream.LIST());
  is := dumpStart(is);
  is := dumpGraph_Internal(inGraph,"  ",is);
  is := dumpEnd(is);
  str := IOStream.string(is);
  System.writeFile(name,str);
end dumpGraph;

public function printGraph
"function printGraph
 author: Frenkel TUD 2011-08
 print the graph"
  input Graph inGraph;
  input String name;
algorithm
protected
  String str;
  IOStream.IOStream is;
algorithm
  is := IOStream.create(name, IOStream.LIST());
  is := dumpStart(is);
  is := dumpGraph_Internal(inGraph,"  ",is);
  is := dumpEnd(is);
  IOStream.print(is, IOStream.stdOutput);
end printGraph;

/*************************************************
 * protected
 ************************************************/

protected function dumpStart
  input IOStream.IOStream is;
  output IOStream.IOStream os;
algorithm
  os := IOStream.appendList(is, {
   "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n",
   "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:y=\"http://www.yworks.com/xml/graphml\" xmlns:yed=\"http://www.yworks.com/xml/yed/3\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://www.yworks.com/xml/schema/graphml/1.1/ygraphml.xsd\">\n",
   "  <!--Created by yFiles for Java 2.8-->\n",
   "  <key for=\"graphml\" id=\"d0\" yfiles.type=\"resources\"/>\n",
   "  <key for=\"port\" id=\"d1\" yfiles.type=\"portgraphics\"/>\n",
   "  <key for=\"port\" id=\"d2\" yfiles.type=\"portgeometry\"/>\n",
   "  <key for=\"port\" id=\"d3\" yfiles.type=\"portuserdata\"/>\n",
   "  <key attr.name=\"url\" attr.type=\"string\" for=\"node\" id=\"d4\"/>\n",
   "  <key attr.name=\"description\" attr.type=\"string\" for=\"node\" id=\"d5\"/>\n",
   "  <key for=\"node\" id=\"d6\" yfiles.type=\"nodegraphics\"/>\n",
   "  <key attr.name=\"Beschreibung\" attr.type=\"string\" for=\"graph\" id=\"d7\"/>\n",
   "  <key attr.name=\"url\" attr.type=\"string\" for=\"edge\" id=\"d8\"/>\n",
   "  <key attr.name=\"description\" attr.type=\"string\" for=\"edge\" id=\"d9\"/>\n",
   "  <key for=\"edge\" id=\"d10\" yfiles.type=\"edgegraphics\"/>\n"});
end dumpStart;

protected function dumpEnd
  input IOStream.IOStream is;
  output IOStream.IOStream os;
algorithm
  os := IOStream.appendList(is, {
   "  <data key=\"d0\">\n",
   "    <y:Resources/>\n",
   "  </data>\n",
   "</graphml>\n"});
end dumpEnd;

protected function appendString
  input String inString;
  output String outString;
algorithm
  outString := stringAppend(inString,"  ");
end appendString;

protected function dumpGraph_Internal
  input Graph inGraph;
  input String inStringDelemiter;
  input IOStream.IOStream inIOs;
  output IOStream.IOStream outIOs;
algorithm
  outIOs := match (inGraph,inStringDelemiter,inIOs)
    local
      String id,sd,t,s;
      Boolean directed;
      list<Node> nodes;
      list<Edge> edges;
      list<Attribute> attributes;
      IOStream.IOStream is;
      
     case(GRAPH(id=id,directed=directed,nodes=nodes,edges=edges,attributes=attributes),_,is)
       equation
         sd = Util.if_(directed,"directed","undirected");
         t = appendString(inStringDelemiter);
         is = List.fold(attributes, dumpAttributeDefinition, is);
         is = IOStream.appendList(is, {inStringDelemiter, "<graph edgedefault=\"", sd, "\" id=\"", id, "\">\n"});
         is = List.fold1(nodes, dumpNode, t, is);
         is = List.fold1(edges, dumpEdge, t, is);
         is = IOStream.appendList(is, {t, "<data key=\"d7\"/>\n"});
         is = IOStream.appendList(is, {inStringDelemiter , "</graph>\n"});
       then
        is;
   
   end match;
end dumpGraph_Internal;

protected function dumpAttributeDefinition
  input Attribute inAttribute;
  input IOStream.IOStream iIos;
  output IOStream.IOStream oIos;  
  
algorithm
  oIos := match(inAttribute,iIos)
    local 
      Integer attIdx;
      String name, defaultValue, typeString, targetString, idxString;
      AttributeType attType;
      AttributeTarget attTarget;
      IOStream.IOStream tmpStream;
    case(ATTRIBUTE(attIdx=attIdx,name=name,defaultValue=defaultValue,attType=attType,attTarget=attTarget), tmpStream)
      equation
        typeString = dumpAttributeType(attType);
        targetString = dumpAttributeTarget(attTarget);
        idxString = intString(attIdx + 15);
        tmpStream = IOStream.appendList(tmpStream, {"  <key attr.name=\"", name, "\" attr.type=\"", 
        typeString, "\" for=\"", targetString, "\" id=\"d", idxString, "\">\n",
        "    <default>", defaultValue, "</default>\n", "  </key>\n"});
    then tmpStream;
  end match;
end dumpAttributeDefinition;

protected function dumpAttributeType
  input AttributeType attType;
  output String oString;
  
algorithm
  oString := match(attType)
    case(TYPE_STRING()) then "string";
    case(TYPE_BOOLEAN()) then "boolean";
    case(TYPE_INTEGER()) then "int";
    case(TYPE_DOUBLE()) then "double";
    else then fail();
  end match;
end dumpAttributeType;

protected function dumpAttributeTarget
  input AttributeTarget attTarget;
  output String oString;
  
algorithm
  oString := match(attTarget)
    case(TARGET_EDGE()) then "edge";
    case(TARGET_NODE()) then "node";
    case(TARGET_GRAPH()) then "graph";
    else then fail();
  end match;
end dumpAttributeTarget;

protected function dumpNode
  input Node inNode;
  input String inString;
  input IOStream.IOStream iAcc;
  output IOStream.IOStream oAcc;
algorithm
  oAcc := match (inNode,inString,iAcc)
    local
      String id,t,text,st_str,color,s,desc;
      List<String> attributeStrings;
      List<tuple<Integer,String>> nodeAttributes;
      ShapeType st;
      IOStream.IOStream is;
     
    case(NODE(id=id,text=text,color=color,shapeType=st,attValues=nodeAttributes), _, _)
      equation
        t = appendString(inString);
        attributeStrings = List.map1(nodeAttributes, createAttributeString, 15);
        st_str = getShapeTypeString(st);
        desc = getNodeDesc(inNode);
        is = IOStream.appendList(iAcc, {inString, "<node id=\"", id, "\">\n"});
        is = IOStream.appendList(is, attributeStrings);
        is = IOStream.appendList(is, {
          t, "<data key=\"d5\">", desc, "</data>\n",
          t, "<data key=\"d6\">\n",
          "        <y:ShapeNode>\n",
          "          <y:Geometry height=\"30.0\" width=\"30.0\" x=\"17.0\" y=\"60.0\"/>\n",
          "          <y:Fill color=\"#", color, "\" transparent=\"false\"/>\n",
          "          <y:BorderStyle color=\"#000000\" type=\"line\" width=\"1.0\"/>\n",
          "          <y:NodeLabel alignment=\"center\" autoSizePolicy=\"content\" fontFamily=\"Dialog\" fontSize=\"12\" fontStyle=\"plain\" hasBackgroundColor=\"false\" hasLineColor=\"false\" height=\"18.701171875\" modelName=\"internal\" modelPosition=\"c\" textColor=\"#000000\" visible=\"true\" width=\"228.806640625\" x=\"1\" y=\"1\">", text, "</y:NodeLabel>\n",
          "          <y:Shape type=\"", st_str, "\"/>\n",
          "        </y:ShapeNode>\n",
          t, "</data>\n",
          inString ,"</node>\n"});
      then
        is;
  end match;
end dumpNode;

protected function createAttributeString
  input tuple<Integer,String> iAttValue;
  input Integer idOffset;
  output String oString;
  
protected
  Integer attIdx;
  String attValue;
  
algorithm
  (attIdx,attValue) := iAttValue;
  attIdx := attIdx + idOffset;
  oString := "      <data key=\"d" +& intString(attIdx) +& "\">" +& attValue +& "</data>\n";
end createAttributeString;

protected function getNodeDesc
"Returns the description of the node. The string is empty if no value was assigned."
  input Node node;
  output String desc_out;

algorithm
  desc_out := match(node)
    local
      String desc;
    case(NODE(optDesc=SOME(desc)))
    then desc;
    else
    then "";
  end match;
end getNodeDesc;

protected function getShapeTypeString
  input ShapeType st;
  output String str;
algorithm
  str := match (st)
    case RECTANGLE() then "rectangle";
    case ROUNDRECTANGLE() then "roundrectangle";
    case ELLIPSE() then "ellipse";
    case PARALLELOGRAM() then "parallelogram";
    case HEXAGON() then "hexagon";
    case TRIANGLE() then "triangle";
    case OCTAGON() then "octagon";
    case DIAMOND() then "diamond";
    case TRAPEZOID() then "trapezoid";
    case TRAPEZOID2() then "trapezoid2";
   end match;
end getShapeTypeString;

protected function dumpEdge
  input Edge inEdge;
  input String inString;
  input IOStream.IOStream iAcc;
  output IOStream.IOStream oAcc;
algorithm
  oAcc := match (inEdge,inString,iAcc)
    local
      String id,t,target,source,color,lt_str,sa_str,ta_str,sl_str,s;
      List<String> attributeStrings;
      LineType lt;
      Option<ArrowType> sarrow,tarrow;
      Option<EdgeLabel> label;
      IOStream.IOStream is;
      List<tuple<Integer,String>> edgeAttributes;
    
    case(EDGE(id=id,target=target,source=source,color=color,lineType=lt,label=label,arrows=(sarrow,tarrow),attValues=edgeAttributes),_,_)
      equation
        t = appendString(inString);
        attributeStrings = List.map1(edgeAttributes, createAttributeString, 15);
        lt_str = getLineTypeString(lt);
        sl_str = getEdgeLabelString(label);
        sa_str = getArrowTypeString(sarrow);
        ta_str = getArrowTypeString(tarrow);
        
        is = IOStream.appendList(iAcc, {inString, "<edge id=\"", id, "\" source=\"", source, "\" target=\"", target, "\">\n"});
        is = IOStream.appendList(is, attributeStrings);
        is = IOStream.appendList(is, {
          t, "<data key=\"d8\"/>\n",
          t, "<data key=\"d9\"><![CDATA[UMLuses]]></data>\n",
          t, "<data key=\"d10\">\n",
          "        <y:PolyLineEdge>\n",
          "          <y:Path sx=\"0.0\" sy=\"0.0\" tx=\"0.0\" ty=\"0.0\"/>\n",
          "          <y:LineStyle color=\"#", color, "\" type=\"", lt_str, "\" width=\"2.0\"/>\n",
          sl_str,
          "          <y:Arrows source=\"", sa_str, "\" target=\"", ta_str, "\"/>\n",
          "          <y:BendStyle smoothed=\"false\"/>\n",
          "        </y:PolyLineEdge>\n",
          t, "</data>\n",
          inString, "</edge>\n"});
      then
        is;
  
  end match;
end dumpEdge;

protected function getEdgeLabelString
  input Option<EdgeLabel> label;
  output String outStr;
algorithm
  outStr := match(label)
    local
      String text,color;
    case (NONE()) then "";
    case (SOME(EDGELABEL(text=text,color=color)))
      then
        stringAppendList({"          <y:EdgeLabel alignment=\"center\" distance=\"2.0\" fontFamily=\"Dialog\" fontSize=\"20\" fontStyle=\"plain\" hasBackgroundColor=\"false\" hasLineColor=\"false\" height=\"28.501953125\" modelName=\"six_pos\" modelPosition=\"tail\" preferredPlacement=\"anywhere\" ratio=\"0.5\" textColor=\"",color,"\" visible=\"true\" width=\"15.123046875\" x=\"47.36937571050203\" y=\"17.675232529529524\">",text,"</y:EdgeLabel>\n"});
  end match;
end getEdgeLabelString;

protected function getArrowTypeString
  input Option<ArrowType> inArrow;
  output String outString;
algorithm
  outString := match(inArrow)
    case NONE() then "none";
    case SOME(ARROWSTANDART()) then "standard";
  end match;
end getArrowTypeString;

protected function getLineTypeString
  input LineType lt;
  output String str;
algorithm
  str := match (lt)
    case LINE() then "line";
    case DASHED() then "dashed";
    case DASHEDDOTTED() then "dashed_dotted";
   end match;
end getLineTypeString;

end GraphML;

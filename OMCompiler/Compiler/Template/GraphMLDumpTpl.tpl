// This file defines templates for transforming a GraphML-Graph into a Yed *.graphml-File.
//
// 2014-02-04 mwalther

package GraphMLDumpTpl

import interface GraphMLDumpTplTV;


template dumpGraphInfo(GraphML.GraphInfo graphInfo, String fileName)
::=
  let()= textFile(dumpGraphInfoInternal(graphInfo), fileName)
  ""
end dumpGraphInfo;

template dumpGraphInfoInternal(GraphML.GraphInfo graphInfo)
::=
    match graphInfo
        case graphInfo as GRAPHINFOARR(__) then
            let attDefDump = arrayList(attributes) |> att => dumpAttDef(att) ; separator="\n"
            let edgeDump = edges |> edge => dumpEdge(edge, graphInfo.graphEdgeKey,attributes) ; separator="\n"
            <<
            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:y="http://www.yworks.com/xml/graphml" xmlns:yed="http://www.yworks.com/xml/yed/3" xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns http://www.yworks.com/xml/schema/graphml/1.1/ygraphml.xsd">

                <key for="node" id="<%graphNodeKey%>" yfiles.type="nodegraphics"/>
                <key attr.name="description" attr.type="string" for="node" id="ddesc" />
                <key for="edge" id="<%graphEdgeKey%>" yfiles.type="edgegraphics"/>

                <%attDefDump%>

                <!-- Graph Idx: <%arrayLength(graphs)%> -->
                <%dumpGraph(arrayGet(graphs,arrayLength(graphs)), graphs, nodes, edgeDump, graphNodeKey,attributes)%>
            </graphml>
            >>
    end match
end dumpGraphInfoInternal;

template dumpGraph(GraphML.Graph graph, array<GraphML.Graph> allGraphs, array<GraphML.Node> allNodes, String edgeDesc, String graphNodeKey, array<Attribute> graphAttributes)
::=
    match graph
        case GRAPH() then
            let graphNodes = nodeIdc |> idc => dumpNode(arrayGet(allNodes,intAdd(1,intSub(arrayLength(allNodes),idc))),allGraphs,allNodes,graphNodeKey,graphAttributes) ; separator="\n"
            let attKeys = attValues |> val => dumpAttKey(val,graphAttributes) ; separator="\n"
            <<
            <graph edgedefault="<%dumpDirected(directed)%>" id="<%id%>">
                <%attKeys%>
                <%graphNodes%>

                <%edgeDesc%>
            </graph>
            >>
    end match
end dumpGraph;

template dumpNode(GraphML.Node node, array<GraphML.Graph> allGraphs, array<GraphML.Node> allNodes, String graphNodeKey, array<Attribute> graphAttributes)
::=
    match node
        case NODE() then
            let nodeLabelDump = nodeLabels |> label => dumpNodeLabel(label) ; separator="\n"
            let attKeys = attValues |> val => dumpAttKey(val, graphAttributes) ; separator="\n"
            <<
            <node id="<%id%>">
                <%attKeys%>
                <data key="ddesc"><![CDATA[<%optDesc%>]]></data>
                <data key="<%graphNodeKey%>">
                    <y:ShapeNode>
                      <y:Fill color="#<%color%>" transparent="false"/>
                      <y:BorderStyle color="#000000" type="line" width="<%border%>"/>
                      <%nodeLabelDump%>
                      <y:Shape type="<%dumpShapeType(shapeType)%>"/>
                    </y:ShapeNode>
                </data>
            </node>
            >>
        case GROUPNODE() then
            let folderType = if isFolded then 'folder' else 'group'
            let activeType = if isFolded then '1' else '0'
            <<
            <node id="<%id%>" yfiles.foldertype="<%folderType%>">
              <data key="<%graphNodeKey%>">
                <y:ProxyAutoBoundsNode>
                  <y:Realizers active="<%activeType%>">
                    <y:GroupNode>
                      <y:Fill color="#F5F5F5" transparent="false"/>
                      <y:NodeLabel alignment="right" autoSizePolicy="node_width" backgroundColor="#EBEBEB" borderDistance="0.0" fontFamily="Dialog" fontSize="15" fontStyle="plain" hasLineColor="false" modelName="internal" modelPosition="t" textColor="#000000" visible="true"><%header%></y:NodeLabel>
                      <y:Shape type="roundrectangle"/>
                      <y:State closed="false" closedHeight="50.0" closedWidth="50.0" innerGraphDisplayEnabled="false"/>
                      <y:Insets bottom="15" bottomF="15.0" left="15" leftF="15.0" right="15" rightF="15.0" top="15" topF="15.0"/>
                      <y:BorderInsets bottom="0" bottomF="0.0" left="0" leftF="0.0" right="0" rightF="0.0" top="0" topF="0.0"/>
                    </y:GroupNode>
                    <y:GroupNode>
                      <y:Geometry height="50.0" width="50.0" x="0.0" y="60.0"/>
                      <y:Fill color="#F5F5F5" transparent="false"/>
                      <y:BorderStyle color="#000000" type="dashed" width="1.0"/>
                      <y:NodeLabel alignment="right" autoSizePolicy="node_width" backgroundColor="#EBEBEB" borderDistance="0.0" fontFamily="Dialog" fontSize="15" fontStyle="plain" hasLineColor="false" height="22.37646484375" modelName="internal" modelPosition="t" textColor="#000000" visible="true"><%header%></y:NodeLabel>
                      <y:Shape type="roundrectangle"/>
                      <y:State closed="true" closedHeight="50.0" closedWidth="50.0" innerGraphDisplayEnabled="false"/>
                      <y:Insets bottom="5" bottomF="5.0" left="5" leftF="5.0" right="5" rightF="5.0" top="5" topF="5.0"/>
                      <y:BorderInsets bottom="0" bottomF="0.0" left="0" leftF="0.0" right="0" rightF="0.0" top="0" topF="0.0"/>
                    </y:GroupNode>
                  </y:Realizers>
                </y:ProxyAutoBoundsNode>
              </data>
              <!-- Graph Idx: <%intAdd(1,intSub(arrayLength(allGraphs), internalGraphIdx))%> -->
              <%dumpGraph(arrayGet(allGraphs,intAdd(1,intSub(arrayLength(allGraphs), internalGraphIdx))), allGraphs, allNodes, "", graphNodeKey, graphAttributes)%>
            </node>
            >>
    end match
end dumpNode;

template dumpEdge(GraphML.Edge edge, String graphEdgeKey, array<Attribute> graphAttributes)
::=
    match edge
        case EDGE() then
            let edgeLabelDump = edgeLabels |> label => dumpEdgeLabel(label) ; separator="\n"
            let attKeys = attValues |> val => dumpAttKey(val,graphAttributes) ; separator="\n"
            <<
            <edge id="<%id%>" source="<%source%>" target="<%target%>">
              <%attKeys%>
              <data key="<%graphEdgeKey%>">
                <y:PolyLineEdge>
                  <y:Path sx="0.0" sy="0.0" tx="0.0" ty="0.0"/>
                  <y:LineStyle color="#<%color%>" type="<%dumpLineType(lineType)%>" width="<%lineWidth%>"/>
                  <y:Arrows source="<%dumpArrowType(Util.tuple21(arrows))%>" target="<%dumpArrowType(Util.tuple22(arrows))%>"/>
                  <y:BendStyle smoothed="<%smooth%>"/>
                  <%edgeLabelDump%>
                </y:PolyLineEdge>
              </data>
            </edge>
            >>
    end match
end dumpEdge;

template dumpEdgeLabel(GraphML.EdgeLabel edgeLabel)
::=
    match edgeLabel
        case EDGELABEL() then
            let bgColor = dumpColorOpt(backgroundColor)
            <<
            <y:EdgeLabel alignment="center" distance="2.0" fontFamily="Dialog" <%bgColor%> fontSize="<%fontSize%>" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="side_slider" preferredPlacement="anywhere" visible="true"><%text%></y:EdgeLabel>
            >>
    end match
end dumpEdgeLabel;

template dumpNodeLabel(GraphML.NodeLabel nodeLabel)
::=
    match nodeLabel
        case NODELABEL_INTERNAL() then
            let bgColor = dumpColorOpt(backgroundColor)
            <<
            <y:NodeLabel alignment="center" autoSizePolicy="content" <%bgColor%> fontFamily="Dialog" fontSize="12" fontStyle="<%dumpFontStyle(fontStyle)%>" hasLineColor="false" modelName="internal" modelPosition="c" textColor="#000000" visible="true"><%text%></y:NodeLabel>
            >>
        case NODELABEL_CORNER() then
            let bgColor = dumpColorOpt(backgroundColor)
            <<
            <y:NodeLabel alignment="center" autoSizePolicy="content" <%bgColor%> fontFamily="Dialog" fontSize="12" fontStyle="<%dumpFontStyle(fontStyle)%>" hasLineColor="false" modelName="corners" modelPosition="<%position%>" textColor="#000000" visible="true"><%text%></y:NodeLabel>
            >>
    end match
end dumpNodeLabel;

template dumpAttKey(tuple<Integer,String> key, array<Attribute> graphAttributes)
/*  author: marcusw
    Prints a attribute key-value-pair in a data element. If the attribute is a string, a CDATA-tag is added around the value. */
::=
    match key
        case(idx,val) then
            match arrayGet(graphAttributes, idx)
                case ATTRIBUTE(attType=TYPE_STRING(__)) then
                <<
                <data key="cust<%idx%>"><![CDATA[<%val%>]]></data>
                >>
                else
                <<
                <data key="cust<%idx%>"><%val%></data>
                >>
            end match
    end match
end dumpAttKey;

template dumpAttDef(GraphML.Attribute attribute)
::=
    match attribute
        case ATTRIBUTE() then
            <<
            <key attr.name="<%name%>" attr.type="<%dumpAttType(attType)%>" for="<%dumpAttTarget(attTarget)%>" id="cust<%attIdx%>">
                <default><%defaultValue%></default>
            </key>
            >>
    end match
end dumpAttDef;

template dumpAttType(GraphML.AttributeType type)
::=
    match type
        case TYPE_STRING() then
            <<
            string
            >>
        case TYPE_BOOLEAN() then
            <<
            boolean
            >>
        case TYPE_INTEGER() then
            <<
            int
            >>
        case TYPE_DOUBLE() then
            <<
            double
            >>
    end match
end dumpAttType;

template dumpAttTarget(GraphML.AttributeTarget target)
::=
    match target
        case TARGET_NODE() then
            <<
            node
            >>
        case TARGET_EDGE() then
            <<
            edge
            >>
        case TARGET_GRAPH() then
            <<
            graph
            >>
    end match
end dumpAttTarget;

template dumpDirected(Boolean directed)
::=
    match directed
        case true then
            <<
            directed
            >>
        case false then
            <<
            undirected
            >>
    end match
end dumpDirected;

template dumpColorOpt(Option<String> colorOpt)
::=
    match colorOpt
        case SOME(col) then
            <<
            backgroundColor="#<%col%>"
            >>
    end match
end dumpColorOpt;

template dumpFontStyle(GraphML.FontStyle fontStyle)
::=
    match fontStyle
        case FONTPLAIN() then
            <<
            plain
            >>
        case FONTBOLD() then
            <<
            bold
            >>
        case FONTITALIC() then
            <<
            italic
            >>
        case FONTBOLDITALIC() then
            <<
            bolditalic
            >>
    end match
end dumpFontStyle;

template dumpLineType(GraphML.LineType lineType)
::=
    match lineType
        case LINE() then
            <<
            line
            >>
        case DASHED() then
            <<
            dashed
            >>
        case DASHEDDOTTED() then
            <<
            dasheddotted
            >>
    end match
end dumpLineType;

template dumpArrowType(GraphML.ArrowType arrowType)
::=
    match arrowType
        case ARROWSTANDART() then
            <<
            standard
            >>
        case ARROWNONE() then
            <<
            none
            >>
        case ARROWCONCAVE() then
            <<
            concave
            >>
    end match
end dumpArrowType;

template dumpShapeType(GraphML.ShapeType shape)
::=
    match shape
        case RECTANGLE() then
            <<
            rectangle
            >>
        case ROUNDRECTANGLE() then
            <<
            roundrectangle
            >>
        case ELLIPSE() then
            <<
            ellipse
            >>
        case PARALLELOGRAM() then
            <<
            parallelogram
            >>
        case HEXAGON() then
            <<
            hexagon
            >>
        case TRIANGLE() then
            <<
            triangle
            >>
        case OCTAGON() then
            <<
            octagon
            >>
        case DIAMOND() then
            <<
            diamond
            >>
        case TRAPEZOID() then
            <<
            trapezoid
            >>
        case TRAPEZOID2() then
            <<
            trapezoid2
            >>
    end match
end dumpShapeType;

annotation(__OpenModelica_Interface="susan");
end GraphMLDumpTpl;

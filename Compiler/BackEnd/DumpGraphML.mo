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

encapsulated package DumpGraphML
" file:        DumpGraphML.mo
  package:     DumpGraphML
  description: DumpGraphML contains dump GraphML stuff

"

public import BackendDAE;
public import DAE;

protected import Array;
protected import BackendDump;
protected import BackendEquation;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import ComponentReference;
protected import GraphML;
protected import List;
protected import Util;

// =============================================================================
// dump GraphML stuff
//
// =============================================================================
public function dumpSystem
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input Option<array<Integer>> inids;
  input String filename;
  input Boolean numberMode; //If you set this value to true, the node-text will only contain the variable number. The expression will be moved to the description-tag.
algorithm
  _ := match(inSystem,inShared,inids,filename,numberMode)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      GraphML.GraphInfo graphInfo;
      Integer graph;
      list<Integer> eqnsids;
      Integer neqns;
      array<Integer> vec1,vec2,vec3,mapIncRowEqn;
      array<Boolean> eqnsflag;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree funcs;
      BackendDAE.StrongComponents comps;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.NO_MATCHING()),_,NONE(),_,_)
      equation
        vars = BackendVariable.daeVars(inSystem);
        eqns = BackendEquation.getEqnsFromEqSystem(inSystem);
        funcs = BackendDAEUtil.getFunctions(inShared);
        (_,m,_) = BackendDAEUtil.getIncidenceMatrix(inSystem,BackendDAE.NORMAL(),SOME(funcs));
        mapIncRowEqn = Array.createIntRange(arrayLength(m));
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(numberMode,1,(graphInfo,graph)));
        neqns = BackendDAEUtil.equationArraySize(eqns);
        //neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraph,eqns,mapIncRowEqn,numberMode,(graphInfo,graph));
        ((_,_,graphInfo)) = List.fold(eqnsids,addEdgesGraph,(1,m,graphInfo));
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(_),matching=BackendDAE.NO_MATCHING()),_,NONE(),_,_)
      equation
        vars = BackendVariable.daeVars(inSystem);
        eqns = BackendEquation.getEqnsFromEqSystem(inSystem);
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(numberMode,1,(graphInfo,graph)));
        neqns = BackendDAEUtil.equationArraySize(eqns);
        //neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        mapIncRowEqn = Array.createIntRange(arrayLength(m));
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraph,eqns,mapIncRowEqn,numberMode,(graphInfo,graph));
        ((_,_,graphInfo)) = List.fold(eqnsids,addEdgesGraph,(1,m,graphInfo));
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2,comps={})),_,NONE(),_,_)
      equation
        vars = BackendVariable.daeVars(inSystem);
        eqns = BackendEquation.getEqnsFromEqSystem(inSystem);
        funcs = BackendDAEUtil.getFunctions(inShared);
        //(_,m,mt) = BackendDAEUtil.getIncidenceMatrix(inSystem, BackendDAE.NORMAL(), SOME(funcs));
        //mapIncRowEqn = Array.createIntRange(arrayLength(m));
        //(_,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(inSystem,BackendDAE.SOLVABLE(), SOME(funcs)));
        (_,m,_,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(inSystem,BackendDAE.NORMAL(), SOME(funcs));
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraphMatch,(numberMode,1,vec1,(graphInfo,graph)));
        //neqns = BackendDAEUtil.equationArraySize(eqns);
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        eqnsflag = arrayCreate(neqns,false);
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraphMatch,eqns,(vec2,mapIncRowEqn,eqnsflag),numberMode,(graphInfo,graph));
        //graph = List.fold3(eqnsids,addEqnGraphMatch,eqns,vec2,mapIncRowEqn,graph);
        ((_,_,_,_,graphInfo)) = List.fold(eqnsids,addDirectedEdgesGraph,(1,m,vec2,mapIncRowEqn,graphInfo));
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass2=vec2,comps={})),_,SOME(vec3),_,_)
      equation
        vars = BackendVariable.daeVars(inSystem);
        eqns = BackendEquation.getEqnsFromEqSystem(inSystem);
        funcs = BackendDAEUtil.getFunctions(inShared);
        (_,m,_,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(inSystem,BackendDAE.NORMAL(), SOME(funcs));
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(numberMode,1,(graphInfo,graph)));
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraph,eqns,mapIncRowEqn,numberMode,(graphInfo,graph));
        ((_,_,_,_,graphInfo)) = List.fold(eqnsids,addDirectedNumEdgesGraph,(1,m,vec2,vec3,graphInfo));
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)),_,NONE(),_,_)
      equation
        vars = BackendVariable.daeVars(inSystem);
        _ = BackendEquation.getEqnsFromEqSystem(inSystem);
        funcs = BackendDAEUtil.getFunctions(inShared);
        (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(inSystem, BackendDAE.NORMAL(), SOME(funcs));
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        // generate a node for each component and get the edges
        vec3 = arrayCreate(arrayLength(mt),-1);
        ((graphInfo,graph)) = addCompsGraph(comps,vars,vec3,1,(graphInfo,graph));
        // generate edges
        mapIncRowEqn = arrayCreate(arrayLength(mt),-1);
        graphInfo = addCompsEdgesGraph(comps,m,vec3,1,1,mapIncRowEqn,1,graphInfo);
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
  end match;
end dumpSystem;

protected function addVarGraph
 input BackendDAE.Var inVar;
 input tuple<Boolean,Integer,tuple<GraphML.GraphInfo,Integer>> inTpl;
 output BackendDAE.Var outVar;
 output tuple<Boolean,Integer,tuple<GraphML.GraphInfo,Integer>> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      GraphML.GraphInfo graphInfo;
      GraphML.NodeLabel label;
      Integer graph;
      DAE.ComponentRef cr;
      Integer id;
      Boolean b;
      String color,desc,labelText;
    case (v as BackendDAE.VAR(varName=cr),(true,id,(graphInfo,graph)))
      equation
        true = BackendVariable.isStateVar(v);
        //g = GraphML.addNode("v" + intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" + intString(id),intString(id),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
        labelText = intString(id);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        desc = ComponentReference.printComponentRefStr(cr);
        (graphInfo,_) = GraphML.addNode("v" + intString(id),GraphML.COLOR_BLUE, {label}, GraphML.ELLIPSE(),SOME(desc),{}, graph, graphInfo);
      then (v,(true,id+1,(graphInfo,graph)));

    case (v as BackendDAE.VAR(varName=cr),(false,id,(graphInfo,graph)))
      equation
        true = BackendVariable.isStateVar(v);
        labelText = intString(id) + ": " + ComponentReference.printComponentRefStr(cr);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("v" + intString(id),GraphML.COLOR_BLUE,{label},GraphML.ELLIPSE(),NONE(),{}, graph, graphInfo);
      then (v,(false,id+1,(graphInfo,graph)));

    case (v as BackendDAE.VAR(varName=cr),(true,id,(graphInfo,graph)))
      equation
        b = BackendVariable.isVarDiscrete(v);
        color = if b then GraphML.COLOR_PURPLE else GraphML.COLOR_RED;
        labelText = intString(id);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        desc = ComponentReference.printComponentRefStr(cr);
        //g = GraphML.addNode("v" + intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" + intString(id),intString(id),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
        (graphInfo,_) = GraphML.addNode("v" + intString(id),color,{label},GraphML.ELLIPSE(),SOME(desc),{}, graph, graphInfo);
      then (v,(true,id+1,(graphInfo,graph)));

    case (v as BackendDAE.VAR(varName=cr),(false,id,(graphInfo,graph)))
      equation
        b = BackendVariable.isVarDiscrete(v);
        color = if b then GraphML.COLOR_PURPLE else GraphML.COLOR_RED;
        labelText = intString(id) + ": " + ComponentReference.printComponentRefStr(cr);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("v" + intString(id),color, {label}, GraphML.ELLIPSE(),NONE(),{},graph, graphInfo);
      then (v,(false,id+1,(graphInfo,graph)));

    else (inVar,inTpl);
  end matchcontinue;
end addVarGraph;

protected function addVarGraphMatch
"author: Frenkel TUD 2012-05"
 input BackendDAE.Var inVar;
 input tuple<Boolean,Integer,array<Integer>,tuple<GraphML.GraphInfo,Integer>> inTpl;
 output BackendDAE.Var outVar;
 output tuple<Boolean,Integer,array<Integer>,tuple<GraphML.GraphInfo,Integer>> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      GraphML.GraphInfo graphInfo;
      GraphML.NodeLabel label;
      Integer graph;
      DAE.ComponentRef cr;
      Integer id;
      array<Integer> vec1;
      String color,desc;
      String labelText;
    case (v as BackendDAE.VAR(varName=cr),(false,id,vec1,(graphInfo,graph)))
      equation
        true = BackendVariable.isStateVar(v);
        color = if intGt(vec1[id],0) then GraphML.COLOR_BLUE else GraphML.COLOR_YELLOW;
        labelText = intString(id) + ": " + ComponentReference.printComponentRefStr(cr);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        //g = GraphML.addNode("v" + intString(id),ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" + intString(id),intString(id),color,GraphML.ELLIPSE(),g);
        (graphInfo,_) = GraphML.addNode("v" + intString(id),color, {label}, GraphML.ELLIPSE(),NONE(),{},graph, graphInfo);
      then (v,(false,id+1,vec1,(graphInfo,graph)));

    case (v as BackendDAE.VAR(varName=cr),(true,id,vec1,(graphInfo,graph)))
      equation
        true = BackendVariable.isStateVar(v);
        color = if intGt(vec1[id],0) then GraphML.COLOR_BLUE else GraphML.COLOR_YELLOW;
        desc = ComponentReference.printComponentRefStr(cr);
        labelText = intString(id);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("v" + intString(id),color, {label}, GraphML.ELLIPSE(),SOME(desc),{},graph, graphInfo);
      then (v,(true,id+1,vec1,(graphInfo,graph)));

    case (v as BackendDAE.VAR(varName=cr),(false,id,vec1,(graphInfo,graph)))
      equation
        color = if intGt(vec1[id],0) then GraphML.COLOR_RED else GraphML.COLOR_YELLOW;
        labelText = intString(id) + ": " + ComponentReference.printComponentRefStr(cr);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        //g = GraphML.addNode("v" + intString(id),ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" + intString(id),intString(id),color,GraphML.ELLIPSE(),g);
        (graphInfo,_) = GraphML.addNode("v" + intString(id),color,{label},GraphML.ELLIPSE(),NONE(),{},graph, graphInfo);
      then (v,(false,id+1,vec1,(graphInfo,graph)));

    case (v as BackendDAE.VAR(varName=cr),(true,id,vec1,(graphInfo,graph)))
      equation
        color = if intGt(vec1[id],0) then GraphML.COLOR_RED else GraphML.COLOR_YELLOW;
        desc = ComponentReference.printComponentRefStr(cr);
        labelText = intString(id);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("v" + intString(id),color,{label},GraphML.ELLIPSE(),SOME(desc),{},graph, graphInfo);
      then (v,(true,id+1,vec1,(graphInfo,graph)));

    else (inVar,inTpl);
  end matchcontinue;
end addVarGraphMatch;

protected function addEqnGraph
  input Integer inNode;
  input BackendDAE.EquationArray eqns;
  input array<Integer> mapIncRowEqn;
  input Boolean numberMode;
  input tuple<GraphML.GraphInfo,Integer> inGraph;
  output tuple<GraphML.GraphInfo,Integer> outGraph;
protected
  BackendDAE.Equation eqn;
  String str;
  GraphML.GraphInfo graphInfo;
  Integer graph;
  GraphML.NodeLabel label;
  String labelText;
algorithm
  outGraph := match(inNode, eqns, mapIncRowEqn, numberMode, inGraph)
    case(_,_,_,false,(graphInfo,graph))
      equation
        eqn = BackendEquation.equationNth1(eqns, mapIncRowEqn[inNode]);
        str = BackendDump.equationString(eqn);
        //str := intString(inNode);
        str = intString(inNode) + ": " + BackendDump.equationString(eqn);
        str = Util.xmlEscape(str);
        label = GraphML.NODELABEL_INTERNAL(str,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("n" + intString(inNode),GraphML.COLOR_GREEN,{label},GraphML.RECTANGLE(),NONE(),{},graph,graphInfo);
      then ((graphInfo,graph));
    case(_,_,_,true,(graphInfo,graph))
      equation
        eqn = BackendEquation.equationNth1(eqns, mapIncRowEqn[inNode]);
        str = BackendDump.equationString(eqn);
        //str := intString(inNode);
        //str = intString(inNode) + ": " + BackendDump.equationString(eqn);
        str = Util.xmlEscape(str);
        labelText = intString(inNode);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("n" + intString(inNode),GraphML.COLOR_GREEN, {label},GraphML.RECTANGLE(),SOME(str),{},graph,graphInfo);
      then ((graphInfo,graph));
  end match;
end addEqnGraph;

protected function addEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,GraphML.GraphInfo> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,GraphML.GraphInfo> outTpl;
protected
  Integer id;
  GraphML.GraphInfo graph;
  BackendDAE.IncidenceMatrix m;
  list<Integer> vars;
algorithm
  (id,m,graph) := inTpl;
  vars := List.select(m[e], Util.intPositive);
  vars := m[e];
  ((id,graph)) := List.fold1(vars,addEdgeGraph,e,(id,graph));
  outTpl := (id,m,graph);
end addEdgesGraph;

protected function addEqnGraphMatch
  input Integer inNode;
  input BackendDAE.EquationArray eqns;
  input tuple<array<Integer>,array<Integer>,array<Boolean>> atpl;
//  input array<Integer> vec2;
//  input array<Integer> mapIncRowEqn;
  input Boolean numberMode;
  input tuple<GraphML.GraphInfo,Integer> inGraph;
  output tuple<GraphML.GraphInfo,Integer> outGraph;
algorithm
  outGraph := matchcontinue(inNode,eqns,atpl,numberMode,inGraph)
    local
      BackendDAE.Equation eqn;
      String str,color;
      Integer e;
      Integer graph;
      GraphML.GraphInfo graphInfo;
      GraphML.NodeLabel label;
      array<Integer> vec2,mapIncRowEqn;
      array<Boolean> eqnsflag;
      String labelText;
    case(_,_,(vec2,mapIncRowEqn,eqnsflag),false,(graphInfo,graph))
      equation
        e = mapIncRowEqn[inNode];
        false = eqnsflag[e];
       eqn = BackendEquation.equationNth1(eqns, mapIncRowEqn[inNode]);
       str = BackendDump.equationString(eqn);
       str = intString(e) + ": " +  str;
       //str = intString(inNode);
       str = Util.xmlEscape(str);
       color = if intGt(vec2[inNode],0) then GraphML.COLOR_GREEN else GraphML.COLOR_PURPLE;
       label = GraphML.NODELABEL_INTERNAL(str,NONE(),GraphML.FONTPLAIN());
       (graphInfo,_) = GraphML.addNode("n" + intString(e),color, {label}, GraphML.RECTANGLE(),NONE(),{},graph,graphInfo);
     then ((graphInfo,graph));
    case(_,_,(vec2,mapIncRowEqn,eqnsflag),true,(graphInfo,graph))
      equation
        e = mapIncRowEqn[inNode];
        false = eqnsflag[e];
       eqn = BackendEquation.equationNth1(eqns, mapIncRowEqn[inNode]);
       str = BackendDump.equationString(eqn);
       //str = intString(e) + ": " +  str;
       //str = intString(inNode);
       str = Util.xmlEscape(str);
       color = if intGt(vec2[inNode],0) then GraphML.COLOR_GREEN else GraphML.COLOR_PURPLE;
       labelText = intString(e);
       label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
       (graphInfo,_) = GraphML.addNode("n" + intString(e),color, {label}, GraphML.RECTANGLE(),SOME(str),{},graph,graphInfo);
     then ((graphInfo,graph));
    case(_,_,(_,mapIncRowEqn,eqnsflag),_,_)
      equation
        e = mapIncRowEqn[inNode];
        true = eqnsflag[e];
     then
        inGraph;
  end matchcontinue;
end addEqnGraphMatch;

protected function addEdgeGraph
  input Integer V;
  input Integer e;
  input tuple<Integer,GraphML.GraphInfo> inTpl;
  output tuple<Integer,GraphML.GraphInfo> outTpl;
protected
  Integer id,v;
  GraphML.GraphInfo graph;
  GraphML.LineType ln;
algorithm
  (id,graph) := inTpl;
  v := intAbs(V);
  ln := if intGt(V,0) then GraphML.LINE() else GraphML.DASHED();
  (graph,_) := GraphML.addEdge("e" + intString(id),"n" + intString(e),"v" + intString(v),GraphML.COLOR_BLACK,ln,GraphML.LINEWIDTH_STANDARD, false, {},(GraphML.ARROWNONE(),GraphML.ARROWNONE()),{},graph);
  outTpl := ((id+1,graph));
end addEdgeGraph;

protected function addDirectedEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.GraphInfo> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.GraphInfo> outTpl;
protected
  Integer id,v,n;
  GraphML.GraphInfo graph;
  BackendDAE.IncidenceMatrix m;
  list<Integer> vars;
  array<Integer> vec2;
  array<Integer> mapIncRowEqn;
algorithm
  (id,m,vec2,mapIncRowEqn,graph) := inTpl;
  //vars := List.select(m[e], Util.intPositive);
  vars := m[e];
  v := vec2[e];
  ((id,_,graph)) := List.fold1(vars,addDirectedEdgeGraph,mapIncRowEqn[e],(id,v,graph));
  outTpl := (id,m,vec2,mapIncRowEqn,graph);
end addDirectedEdgesGraph;

protected function addDirectedEdgeGraph
  input Integer v;
  input Integer e;
  input tuple<Integer,Integer,GraphML.GraphInfo> inTpl;
  output tuple<Integer,Integer,GraphML.GraphInfo> outTpl;
protected
  Integer id,r,absv;
  GraphML.GraphInfo graph;
  tuple<GraphML.ArrowType,GraphML.ArrowType> arrow;
  GraphML.LineType lt;
algorithm
  (id,r,graph) := inTpl;
  absv := intAbs(v);
  arrow := if intEq(r,absv) then (GraphML.ARROWSTANDART(),GraphML.ARROWNONE()) else (GraphML.ARROWNONE(),GraphML.ARROWSTANDART());
  lt := if intGt(v,0) then GraphML.LINE() else GraphML.DASHED();
  (graph,_) := GraphML.addEdge("e" + intString(id),"n" + intString(e),"v" + intString(absv),GraphML.COLOR_BLACK,lt,GraphML.LINEWIDTH_STANDARD, false, {},arrow,{},graph);
  outTpl := ((id+1,r,graph));
end addDirectedEdgeGraph;


protected function addDirectedNumEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.GraphInfo> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.GraphInfo> outTpl;
protected
  Integer id,v;
  GraphML.GraphInfo graph;
  BackendDAE.IncidenceMatrix m;
  list<Integer> vars;
  array<Integer> vec2,vec3,mapIncRowEqn;
  String text;
algorithm
  (id,m,vec2,vec3,graph) := inTpl;
  vars := List.select(m[e], Util.intPositive);
  v := vec2[e];
  text := intString(vec3[e]);
  ((id,_,_,graph)) := List.fold1(vars,addDirectedNumEdgeGraph,e,(id,v,text,graph));
  outTpl := (id,m,vec2,vec3,graph);
end addDirectedNumEdgesGraph;

protected function addDirectedNumEdgeGraph
  input Integer v;
  input Integer e;
  input tuple<Integer,Integer,String,GraphML.GraphInfo> inTpl;
  output tuple<Integer,Integer,String,GraphML.GraphInfo> outTpl;
protected
  Integer id,r,n;
  GraphML.GraphInfo graph;
  tuple<GraphML.ArrowType,GraphML.ArrowType> arrow;
  String text;
  List<GraphML.EdgeLabel> labels;
algorithm
  (id,r,text,graph) := inTpl;
  arrow := if intEq(r,v) then (GraphML.ARROWSTANDART(),GraphML.ARROWNONE()) else (GraphML.ARROWNONE(),GraphML.ARROWSTANDART());
  labels := if intEq(r,v) then {GraphML.EDGELABEL(text,SOME("#0000FF"),GraphML.FONTSIZE_STANDARD)} else {};
  (graph,_) := GraphML.addEdge("e" + intString(id),"n" + intString(e),"v" + intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),GraphML.LINEWIDTH_STANDARD,false,labels,arrow,{},graph);
  outTpl := ((id+1,r,text,graph));
end addDirectedNumEdgeGraph;

protected function addCompsGraph "author: Frenkel TUD 2013-02,
  add for each component a node to the graph and strore
  varcomp[var] = comp."
  input BackendDAE.StrongComponents iComps;
  input BackendDAE.Variables vars;
  input array<Integer> varcomp;
  input Integer iN;
  input tuple<GraphML.GraphInfo,Integer> iGraph;
  output tuple<GraphML.GraphInfo,Integer> oGraph;
algorithm
  oGraph := match(iComps,vars,varcomp,iN,iGraph)
    local
      BackendDAE.StrongComponents rest;
      BackendDAE.StrongComponent comp;
      list<Integer> vlst;
      Integer graph;
      GraphML.GraphInfo graphInfo;
      GraphML.NodeLabel label;
      array<Integer> varcomp1;
      String text;
      list<BackendDAE.Var> varlst;
    case ({},_,_,_,_) then iGraph;
    case (comp::rest,_,_,_,(graphInfo,graph))
      equation
        (_,vlst) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        varcomp1 = List.fold1r(vlst,arrayUpdate,iN,varcomp);
        varlst = List.map1r(vlst,BackendVariable.getVarAt,vars);
        text = intString(iN) + ":" + stringDelimitList(List.mapMap(varlst,BackendVariable.varCref,ComponentReference.printComponentRefStr),"\n");
        label = GraphML.NODELABEL_INTERNAL(text,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("n" + intString(iN),GraphML.COLOR_GREEN,{label},GraphML.RECTANGLE(),NONE(),{},graph,graphInfo);
      then
        addCompsGraph(rest,vars,varcomp1,iN+1,(graphInfo,graph));
  end match;
end addCompsGraph;

protected function addCompsEdgesGraph "author: Frenkel TUD 2013-02,
  add for each component the edges to the graph."
  input BackendDAE.StrongComponents iComps;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> varcomp;
  input Integer iN;
  input Integer id;
  input array<Integer> markarray;
  input Integer mark;
  input GraphML.GraphInfo iGraph;
  output GraphML.GraphInfo oGraph;
algorithm
  oGraph := match(iComps,m,varcomp,iN,id,markarray,mark,iGraph)
    local
      BackendDAE.StrongComponents rest;
      BackendDAE.StrongComponent comp;
      list<Integer> elst,vlst,usedvlst;
      Integer n;
      GraphML.GraphInfo graph;
    case ({},_,_,_,_,_,_,_) then iGraph;
    case (comp::rest,_,_,_,_,_,_,_)
      equation
        // get eqns and vars of comps
        (elst,vlst) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        // get used vars of comp
        _ = List.fold1r(vlst,arrayUpdate,mark,markarray) "set assigned visited";
        vlst = getUsedVarsComp(elst,m,markarray,mark,{});
        (n,graph) = addCompEdgesGraph(vlst,varcomp,markarray,mark+1,iN,id,iGraph);
      then
        addCompsEdgesGraph(rest,m,varcomp,iN+1,n,markarray,mark+2,graph);
  end match;
end addCompsEdgesGraph;

protected function getUsedVarsComp "author: Frenkel TUD 2013-02,
  get all used var of the comp."
  input list<Integer> iEqns;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> markarray;
  input Integer mark;
  input list<Integer> iVars;
  output list<Integer> oVars;
algorithm
  oVars := match(iEqns,m,markarray,mark,iVars)
    local
      list<Integer> rest,vlst;
      Integer e;
    case ({},_,_,_,_) then iVars;
    case (e::rest,_,_,_,_)
      equation
        vlst = List.select1(m[e], intGt, 0);
        vlst = List.select1r(vlst, isUnMarked, (markarray,mark));
        _ = List.fold1r(vlst,arrayUpdate,mark,markarray) "set visited";
        vlst = listAppend(vlst,iVars);
      then
        getUsedVarsComp(rest,m,markarray,mark,vlst);
  end match;
end getUsedVarsComp;

protected function addCompEdgesGraph "author: Frenkel TUD 2013-02,
  add for eqach used var of the comp an edge."
  input list<Integer> iVars;
  input array<Integer> varcomp;
  input array<Integer> markarray;
  input Integer mark;
  input Integer iN;
  input Integer id;
  input GraphML.GraphInfo iGraph;
  output Integer oN;
  output GraphML.GraphInfo oGraph;
algorithm
  (oN,oGraph) := matchcontinue(iVars,varcomp,markarray,mark,iN,id,iGraph)
    local
      list<Integer> rest;
      Integer v,n,c;
      GraphML.GraphInfo graph;
      String text;
      GraphML.EdgeLabel label;
    case ({},_,_,_,_,_,_) then (id,iGraph);
    case (v::rest,_,_,_,_,_,_)
      equation
        c = varcomp[v];
        false = intEq(markarray[c],mark);
        arrayUpdate(markarray,c,mark);
        (graph,_) = GraphML.addEdge("e" + intString(id),"n" + intString(c),"n" + intString(iN),GraphML.COLOR_BLACK,GraphML.LINE(),GraphML.LINEWIDTH_STANDARD,false,{},(GraphML.ARROWSTANDART(),GraphML.ARROWNONE()),{},iGraph);
        (n,graph) = addCompEdgesGraph(rest,varcomp,markarray,mark,iN,id+1,graph);
      then
        (n,graph);
    case (_::rest,_,_,_,_,_,_)
      equation
        (n,graph) = addCompEdgesGraph(rest,varcomp,markarray,mark,iN,id,iGraph);
      then
        (n,graph);
  end matchcontinue;
end addCompEdgesGraph;

protected function isUnMarked
"author: Frenkel TUD 2012-05"
  input tuple<array<Integer>,Integer> ass;
  input Integer indx;
  output Boolean b;
protected
  array<Integer> arr;
  Integer mark;
algorithm
  (arr,mark) := ass;
  b := not intEq(arr[intAbs(indx)],mark);
end isUnMarked;

annotation(__OpenModelica_Interface="backend");
end DumpGraphML;

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

encapsulated package ConnectUtil2
" file:        ConnectUtil.mo
  package:     ConnectUtil
  description: Connection set utility functions

  RCS: $Id$
"

public import Absyn;
public import Connect2;
public import DAE;
public import ConnectionSets;
public import InstTypes;
public import SCode;
public import Types;

protected import ComponentReference;
protected import ConnectCheck;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import Flags;
protected import InstUtil;
protected import List;
protected import Util;

public type Connections = Connect2.Connections;
public type Connection = Connect2.Connection;
public type Connector = Connect2.Connector;
public type ConnectorType = Connect2.ConnectorType;
public type Face = Connect2.Face;
public type Root = Connect2.Root;

public type Class = InstTypes.Class;
public type Component = InstTypes.Component;
public type Element = InstTypes.Element;

protected type DisjointSets = ConnectionSets.DisjointSets;

public function makeBranch
  input DAE.ComponentRef inNode1;
  input DAE.ComponentRef inNode2;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  ConnectCheck.crefIsValidNode(inNode1, "Connections.branch", true, inInfo);
  ConnectCheck.crefIsValidNode(inNode2, "Connections.branch", false, inInfo);
  outConnections := Connect2.NO_CONNECTIONS();
end makeBranch;

public function makeRoot
  input DAE.ComponentRef inNode;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  ConnectCheck.crefIsValidNode(inNode, "Connections.root", true, inInfo);
  outConnections := Connect2.NO_CONNECTIONS();
end makeRoot;

public function makePotentialRoot
  input DAE.ComponentRef inNode;
  input DAE.Exp inPriority;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  ConnectCheck.crefIsValidNode(inNode, "Connections.potentialRoot", true, inInfo);
  outConnections := Connect2.NO_CONNECTIONS();
end makePotentialRoot;

protected function makeConnector
  input DAE.ComponentRef inName;
  input Face inFace;
  input ConnectorType inConnectorType;
  output Connector outConnector;
algorithm
  outConnector := Connect2.CONNECTOR(inName, inFace, inConnectorType);
end makeConnector;

public function connectorEqual
  input Connector inConnector1;
  input Connector inConnector2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := matchcontinue(inConnector1, inConnector2)
    local
      DAE.ComponentRef name1, name2;
      Face face1, face2;

    case (Connect2.CONNECTOR(name = name1, face = face1),
          Connect2.CONNECTOR(name = name2, face = face2))
      equation
        true = faceEqual(face1, face2);
        true = ComponentReference.crefEqualNoStringCompare(name1, name2);
      then
        true;

    else false;

  end matchcontinue;
end connectorEqual;

protected function faceEqual
  input Face inFace1;
  input Face inFace2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inFace1, inFace2)
    case (Connect2.INSIDE(), Connect2.INSIDE()) then true;
    case (Connect2.OUTSIDE(), Connect2.OUTSIDE()) then true;
    case (Connect2.NO_FACE(), Connect2.NO_FACE()) then true;
    else false;
  end match;
end faceEqual;

public function connectorTypeEqual
  input ConnectorType inType1;
  input ConnectorType inType2;
  output Boolean outEqual;
algorithm
  outEqual := match(inType1, inType2)
    case (Connect2.POTENTIAL(), Connect2.POTENTIAL()) then true;
    case (Connect2.FLOW(), Connect2.FLOW()) then true;
    case (Connect2.STREAM(_), Connect2.STREAM(_)) then true;
    else false;
  end match;
end connectorTypeEqual;

public function isPotential
  input ConnectorType inType;
  output Boolean outIsPotential;
algorithm
  outIsPotential := match(inType)
    case Connect2.POTENTIAL() then true;
    else false;
  end match;
end isPotential;

public function connectorStr
  input Connector inConnector;
  output String outString;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType cty;
  String name_str, face_str, cty_str;
algorithm
  Connect2.CONNECTOR(name, face, cty) := inConnector;
  name_str := ComponentReference.printComponentRefStr(name);
  face_str := faceStr(face);
  cty_str := connectorTypeStr(cty);
  outString := cty_str +& " " +& name_str +& "<" +& face_str +& ">";
end connectorStr;
  
protected function faceStr
  input Face inFace;
  output String outString;
algorithm
  outString := match(inFace)
    case Connect2.INSIDE() then "inside";
    case Connect2.OUTSIDE() then "outside";
    case Connect2.NO_FACE() then "no_face";
  end match;
end faceStr;

public function connectorTypeStr
  input ConnectorType inConnectorType;
  output String outString;
algorithm
  outString := match(inConnectorType)
    local
      DAE.ComponentRef cref;
      String cref_str;

    case Connect2.POTENTIAL() then "";
    case Connect2.FLOW() then "flow";
    case Connect2.STREAM(NONE()) then "stream()";
    case Connect2.STREAM(SOME(cref))
      equation
        cref_str = ComponentReference.printComponentRefStr(cref);
      then
        "stream(" +& cref_str +& ")";
    else "NO_TYPE";
  end match;
end connectorTypeStr;

public function translateDaeConnectorType
  input DAE.ConnectorType inConnectorType;
  output ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType)
    case DAE.POTENTIAL() then Connect2.POTENTIAL();
    case DAE.FLOW() then Connect2.FLOW();
    case DAE.STREAM() then Connect2.STREAM(NONE());
    case DAE.NON_CONNECTOR() then Connect2.POTENTIAL();
  end match;
end translateDaeConnectorType;

public function translateSCodeConnectorType
  input SCode.ConnectorType inConnectorType;
  output ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType)
    case SCode.POTENTIAL() then Connect2.POTENTIAL();
    case SCode.FLOW() then Connect2.FLOW();
    case SCode.STREAM() then Connect2.STREAM(NONE());
  end match;
end translateSCodeConnectorType;

protected function makeConnection
  input Connector inLhs;
  input Connector inRhs;
  input Absyn.Info inInfo;
  output Connection outConnection;
algorithm
  outConnection := Connect2.CONNECTION(inLhs, inRhs, inInfo);
end makeConnection;

public function addConnectionCond
  input Boolean inIsDeleted;
  input DAE.ComponentRef inLhsName;
  input Face inLhsFace;
  input ConnectorType inLhsConnectorType;
  input DAE.ComponentRef inRhsName;
  input Face inRhsFace;
  input ConnectorType inRhsConnectorType;
  input Absyn.Info inInfo;
  input Connections inConnections;
  output Connections outConnections;
algorithm
  outConnections := match(inIsDeleted, inLhsName, inLhsFace, inLhsConnectorType,
      inRhsName, inRhsFace, inRhsConnectorType, inInfo, inConnections)
    case (true, _, _, _, _, _, _, _, _) then inConnections;

    else addConnection(inLhsName, inLhsFace, inLhsConnectorType,
      inRhsName, inRhsFace, inRhsConnectorType, inInfo, inConnections);

  end match;
end addConnectionCond;

public function addConnection
  input DAE.ComponentRef inLhsName;
  input Face inLhsFace;
  input ConnectorType inLhsConnectorType;
  input DAE.ComponentRef inRhsName;
  input Face inRhsFace;
  input ConnectorType inRhsConnectorType;
  input Absyn.Info inInfo;
  input Connections inConnections;
  output Connections outConnections;
protected
  Connector lhs, rhs;
  Connection conn;
algorithm
  ConnectCheck.connectorCompatibility(inLhsName, inLhsConnectorType,
    inRhsName, inRhsConnectorType, inInfo);
  lhs := makeConnector(inLhsName, inLhsFace, inLhsConnectorType);
  rhs := makeConnector(inRhsName, inRhsFace, inRhsConnectorType);
  conn := makeConnection(lhs, rhs, inInfo);
  outConnections := consConnection(conn, inConnections);
end addConnection;

protected function consConnection
  input Connection inConnection;
  input Connections inConnections;
  output Connections outConnections;
algorithm
  outConnections := match(inConnection, inConnections)
    local
      list<Connection> connl;
      list<Connection> branches;
      list<Root> roots;

    case (_, Connect2.CONNECTIONS(connl, branches, roots))
      equation
        connl = inConnection :: connl;
      then
        Connect2.CONNECTIONS(connl, branches, roots);

    else
      equation
        connl = {inConnection};
      then
        Connect2.CONNECTIONS(connl, {}, {});

  end match;
end consConnection;

public function collectFlowConnectors
  input Class inClass;
  output list<Connector> outFlows;
algorithm
  outFlows := collectFlowConnectors2(inClass, {});
end collectFlowConnectors;

protected function collectFlowConnectors2
  input Class inClass;
  input list<Connector> inAccumFlows;
  output list<Connector> outFlows;
algorithm
  outFlows := match(inClass, inAccumFlows)
    local
      list<Element> comps;

    case (InstTypes.COMPLEX_CLASS(components = comps), _)
      then List.fold(comps, collectFlowConnectors3, inAccumFlows);

    else inAccumFlows;
  end match;
end collectFlowConnectors2;

protected function collectFlowConnectors3
  input Element inElement;
  input list<Connector> inAccumFlows;
  output list<Connector> outFlows;
algorithm
  outFlows := matchcontinue(inElement, inAccumFlows)
    local
      Component comp;
      DAE.Type ty;
      Class cls;
      list<Element> sub_comps;
      list<Connector> flows;

    case (InstTypes.ELEMENT(component = comp as InstTypes.TYPED_COMPONENT(ty = ty),
        cls = cls as InstTypes.COMPLEX_CLASS(components = sub_comps)), flows)
      equation
        true = InstUtil.isConnectorComponent(comp);
        flows = collectFlowConnectors2(cls, flows);
        flows = List.fold(sub_comps, collectFlowConnector, flows);
      then
        flows;

    case (InstTypes.ELEMENT(cls = cls as InstTypes.COMPLEX_CLASS(components = _)), _)
      then collectFlowConnectors2(cls, inAccumFlows);

    case (InstTypes.EXTENDED_ELEMENTS(cls = cls), _)
      then collectFlowConnectors2(cls, inAccumFlows);

    else inAccumFlows;
  end matchcontinue;
end collectFlowConnectors3;

protected function collectFlowConnector
  input Element inElement;
  input list<Connector> inAccumFlows;
  output list<Connector> outFlows;
algorithm
  outFlows := matchcontinue(inElement, inAccumFlows)
    local
      Absyn.Path name;
      Component comp;
      DAE.ComponentRef cref;
      Connector c;

    case (InstTypes.ELEMENT(component = comp as InstTypes.TYPED_COMPONENT(
        name = _)), _)
      equation
        true = InstUtil.isFlowComponent(comp);
        cref = InstUtil.makeTypedComponentCref(comp);
        c = Connect2.CONNECTOR(cref, Connect2.INSIDE(), Connect2.FLOW());
      then
        c :: inAccumFlows;

    else inAccumFlows;
  end matchcontinue;
end collectFlowConnector;

protected function connectionCount
  input Connections inConnections;
  output Integer outCount;
algorithm
  outCount := match(inConnections)
    local
      list<Connection> connl;

    case Connect2.NO_CONNECTIONS() then 0;
    case Connect2.CONNECTIONS(connections = connl) then listLength(connl);

  end match;
end connectionCount;

protected function getConnections
  input Connections inConnections;
  output list<Connection> outConnections;
algorithm
  outConnections := match(inConnections)
    local
      list<Connection> connections;

    case Connect2.CONNECTIONS(connections = connections) then connections;
    else {};

  end match;
end getConnections;

public function generateEquations
  input Connections inConnections;
  input list<Connector> inFlowVariables;
  output DAE.DAElist outEquations;
algorithm
  outEquations := matchcontinue(inConnections, inFlowVariables)
    local
      DisjointSets disjoint_sets;
      Integer set_size;
      DAE.DAElist eql;
      list<list<Connector>> sets;
      list<Connector> flows;
      list<Connection> connections;

    case (Connect2.NO_CONNECTIONS(), {}) then DAEUtil.emptyDae;

    case (_, _)
      equation
        // Create set structure. TODO: Better set size?
        set_size = connectionCount(inConnections) + listLength(inFlowVariables);
        set_size = intMax(set_size, 3);
        disjoint_sets = ConnectionSets.emptySets(set_size);

        // Add flow variables to the set structure.
        flows = listReverse(inFlowVariables);
        disjoint_sets = List.fold(flows, ConnectionSets.add, disjoint_sets);

        // Add connections to the set structure.
        connections = getConnections(inConnections);
        connections = listReverse(connections);
        disjoint_sets = List.fold(connections, addConnectionToSet, disjoint_sets);

        // Extract the sets and generate equations for them.
        sets = ConnectionSets.extractSets(disjoint_sets);
        eql = List.fold(sets, generateEquation, DAEUtil.emptyDae);
      then
        eql;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- ConnectUtil.generateEquations failed to generate connect equations.");
      then
        fail();

  end matchcontinue;
end generateEquations;

protected function addConnectionToSet
  input Connection inConnection;
  input DisjointSets inSets;
  output DisjointSets outSets;
algorithm
  outSets := match(inConnection, inSets)
    local
      Connector lhs, rhs;
      Absyn.Info info;
      DisjointSets sets;
      list<Connector> lhs_connl, rhs_connl;

    case (Connect2.CONNECTION(lhs = lhs, rhs = rhs, info = info), sets)
      equation
        lhs_connl = expandConnector(lhs);
        rhs_connl = expandConnector(rhs);
        sets = List.threadFold(lhs_connl, rhs_connl, ConnectionSets.merge, sets);
      then
        sets;

  end match;
end addConnectionToSet;

protected function expandConnector
  input Connector inConnector;
  output list<Connector> outConnectors;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType cty;
  list<DAE.ComponentRef> prefixes;
  DAE.Type ty;
  list<Connector> connl;
algorithm
  Connect2.CONNECTOR(name, face, cty) := inConnector;
  prefixes := expandConnectorPrefix(name);
  name := ComponentReference.crefLastCref(name);
  ty := ComponentReference.crefType(name);
  connl := expandConnector2(name, ty, face, cty);
  outConnectors := List.productMap(prefixes, connl, prefixConnector);
end expandConnector;

protected function prefixConnector
  input DAE.ComponentRef inPrefix;
  input Connector inConnector;
  output Connector outConnector;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType cty;
algorithm
  Connect2.CONNECTOR(name, face, cty) := inConnector;
  name := ComponentReference.joinCrefs(inPrefix, name);
  outConnector := Connect2.CONNECTOR(name, face, cty);
end prefixConnector;

protected function expandConnectorPrefix
  input DAE.ComponentRef inCref;
  output list<DAE.ComponentRef> outPrefixes;
algorithm
  outPrefixes := ComponentReference.expandCref(inCref, false);
end expandConnectorPrefix;

protected function varToConnector
  input DAE.Var inVar;
  input Face inFace;
  output Connector outConnector;
protected
  DAE.Ident name;
  DAE.Type ty;
  DAE.ComponentRef cref;
  SCode.ConnectorType scty;
  ConnectorType cty;
algorithm
  DAE.TYPES_VAR(name = name, ty = ty,
    attributes = DAE.ATTR(connectorType = scty)) := inVar;
  cref := DAE.CREF_IDENT(name, ty, {});
  cty := translateSCodeConnectorType(scty);
  outConnector := Connect2.CONNECTOR(cref, inFace, cty);
end varToConnector;
  
protected function expandConnector2
  input DAE.ComponentRef inCref;
  input DAE.Type inType;
  input Face inFace;
  input ConnectorType inConnectorType;
  output list<Connector> outConnectors;
algorithm
  outConnectors := match(inCref, inType, inFace, inConnectorType)
    local
      list<DAE.Var> vars;
      list<DAE.ComponentRef> crefs;
      list<Connector> connl;

    case (_, DAE.T_ARRAY(ty = _), _, _)
      equation
        crefs = ComponentReference.expandCref(inCref, false);
        connl = List.map2(crefs, makeConnector, inFace, inConnectorType);
      then
        connl;

    case (_, DAE.T_COMPLEX(varLst = vars), _, _)
      then List.map1(vars, varToConnector, inFace);

    else {Connect2.CONNECTOR(inCref, inFace, inConnectorType)};

  end match;
end expandConnector2;
  
protected function generateEquation
  input list<Connector> inSet;
  input DAE.DAElist inAccumEql;
  output DAE.DAElist outEquations;
protected
  ConnectorType cty;
  DAE.DAElist dae;
algorithm
  cty := getSetType(inSet);
  dae := generateEquation_dispatch(inSet, cty);
  outEquations := DAEUtil.joinDaes(inAccumEql, dae);
end generateEquation;

protected function getSetType
  input list<Connector> inSet;
  output ConnectorType outType;
algorithm
  // All connectors in a set should have the same type, so pick the first.
  Connect2.CONNECTOR(ty = outType) :: _ := inSet;
end getSetType;

protected function generateEquation_dispatch
  input list<Connector> inSet;
  input ConnectorType inType;
  output DAE.DAElist outEquations;
algorithm
  outEquations := matchcontinue(inSet, inType)
    local
      DAE.DAElist dae;

    case (_, Connect2.POTENTIAL()) then generatePotentialEquations(inSet);
    case (_, Connect2.FLOW()) then generateFlowEquations(inSet);
    case (_, Connect2.STREAM(_)) then generateStreamEquations(inSet);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"ConnectUtil.generateEquation_dispatch failed because of unknown reason."});
      then
        fail();

  end matchcontinue;
end generateEquation_dispatch;

protected function generatePotentialEquations
  "A non-flow connection set contains a number of components. Generating the
   equations from this set means equating all the components. For n components,
   this will give n-1 equations. For example, if the set contains the components
   X, Y.A and Z.B, the equations generated will be X = Y.A and X = Z.B. The
   order of the equations depends on whether the compiler flag orderConnections
   is true or false."
  input list<Connector> inElements;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(inElements)
    local
      DAE.ComponentRef x, y;
      list<Connector> rest_el;
      Connector e1, e2;
      list<DAE.Element> eq;
      String str;
      DAE.ElementSource src;

    case ((e1 as Connect2.CONNECTOR(name = x)) ::
          (e2 as Connect2.CONNECTOR(name = y)) :: rest_el)
      equation
        e1 = Util.if_(Config.orderConnections(), e1, e2);
        DAE.DAE(eq) = generatePotentialEquations(e1 :: rest_el);
        src = DAE.emptyElementSource;
      then
        DAE.DAE(DAE.EQUEQUATION(x, y, src) :: eq);

    case {_} then DAEUtil.emptyDae;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = stringDelimitList(List.map(inElements, connectorStr), ", ");
        Debug.traceln("- ConnectUtil.generatePotentialEquations failed on {" +& str +& "}");
      then
        fail();

  end matchcontinue;
end generatePotentialEquations;

protected function generateFlowEquations
  "Generating equations from a flow connection set is a little trickier that
   from a non-flow set. Only one equation is generated, but it has to consider
   whether the components were inside or outside connectors. This function
   creates a sum expression of all components (some of which will be negated),
   and the returns the equation where this sum is equal to 0.0."
  input list<Connector> inElements;
  output DAE.DAElist outDae;
protected
  DAE.Exp sum;
  DAE.ElementSource src;
algorithm
  sum := List.reduce(List.map(inElements, makeFlowExp), Expression.makeRealAdd);
  src := DAE.emptyElementSource;
  outDae := DAE.DAE({DAE.EQUATION(sum, DAE.RCONST(0.0), src)});
end generateFlowEquations;

protected function makeFlowExp
  "Creates an expression from a connector element, which is the element itself
   if it's an inside connector, or negated if it's outside."
  input Connector inElement;
  output DAE.Exp outExp;
algorithm
  outExp := match(inElement)
    local
      DAE.ComponentRef name;

    case Connect2.CONNECTOR(name = name, face = Connect2.INSIDE())
      then Expression.crefExp(name);

    case Connect2.CONNECTOR(name = name, face = Connect2.OUTSIDE())
      then Expression.negateReal(Expression.crefExp(name));

  end match;
end makeFlowExp;
  
protected function generateStreamEquations
  "Generates the equations for a stream connection set."
  input list<Connector> inElements;
  output DAE.DAElist outDae;
algorithm
  outDae := match(inElements)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource src;
      DAE.DAElist dae;
      Face f1, f2;
      DAE.Exp cref1, cref2, e1, e2;
      list<Connector> inside, outside;

    // Unconnected stream connector, do nothing!
    case ({Connect2.CONNECTOR(face = Connect2.INSIDE())})
      then DAEUtil.emptyDae;

    // Both inside, do nothing!
    case ({Connect2.CONNECTOR(face = Connect2.INSIDE()),
           Connect2.CONNECTOR(face = Connect2.INSIDE())})
      then DAEUtil.emptyDae;

    // Both outside:
    // cr1 = inStream(cr2);
    // cr2 = inStream(cr1);
    case ({Connect2.CONNECTOR(name = cr1, face = Connect2.OUTSIDE()),
           Connect2.CONNECTOR(name = cr2, face = Connect2.OUTSIDE())})
      equation
        cref1 = Expression.crefExp(cr1);
        cref2 = Expression.crefExp(cr2);
        e1 = makeInStreamCall(cref2);
        e2 = makeInStreamCall(cref1);
        src = DAE.emptyElementSource;
        dae = DAE.DAE({
          DAE.EQUATION(cref1, e1, src),
          DAE.EQUATION(cref2, e2, src)});
      then
        dae;

    // One inside, one outside:
    // cr1 = cr2;
    case ({Connect2.CONNECTOR(name = cr1, face = f1),
           Connect2.CONNECTOR(name = cr2, face = f2)})
      equation
        e1 = Expression.crefExp(cr1);
        e2 = Expression.crefExp(cr2);
        src = DAE.emptyElementSource;
        dae = DAE.DAE({DAE.EQUATION(e1, e2, src)});
      then
        dae;

    // The general case with N inside connectors and M outside:
    case (_)
      equation
        (outside, inside) = List.splitOnTrue(inElements, isOutsideStream);
        dae = List.fold2(outside, streamEquationGeneral,
          outside, inside, DAEUtil.emptyDae);
      then
        dae;

  end match;
end generateStreamEquations;

protected function isOutsideStream
  "Returns true if the stream connector element belongs to an outside connector."
  input Connector inElement;
  output Boolean isOutside;
algorithm
  isOutside := match(inElement)
    case Connect2.CONNECTOR(face = Connect2.OUTSIDE()) then true;
    else false;
  end match;
end isOutsideStream;

protected function streamEquationGeneral
  "Generates an equation for an outside stream connector element."
  input Connector inElement;
  input list<Connector> inOutsideElements;
  input list<Connector> inInsideElements;
  input DAE.DAElist inDae;
  output DAE.DAElist outDae;
protected
  list<Connector> outside;
  DAE.ComponentRef stream_cr;
  DAE.Exp cref_exp, outside_sum1, outside_sum2, inside_sum1, inside_sum2, res;
  DAE.ElementSource src;
  DAE.DAElist dae;
algorithm
  Connect2.CONNECTOR(name = stream_cr) := inElement;
  src := DAE.emptyElementSource;
  cref_exp := Expression.crefExp(stream_cr);
  outside := removeStreamSetElement(stream_cr, inOutsideElements);
  res := streamSumEquationExp(outside, inInsideElements);
  dae := DAE.DAE({DAE.EQUATION(cref_exp, res, src)});
  outDae := DAEUtil.joinDaes(dae, inDae);
end streamEquationGeneral;

protected function streamSumEquationExp
  "Generates the sum expression used by stream connector equations, given M
  outside connectors and N inside connectors:

    (sum(max(-flow_exp[i], eps) * stream_exp[i] for i in N) +
     sum(max( flow_exp[i], eps) * inStream(stream_exp[i]) for i in M)) /
    (sum(max(-flow_exp[i], eps) for i in N) +
     sum(max( flow_exp[i], eps) for i in M))
  "
  input list<Connector> inOutsideElements;
  input list<Connector> inInsideElements;
  output DAE.Exp outSumExp;
protected
  DAE.Exp outside_sum1, outside_sum2, inside_sum1, inside_sum2, res;
algorithm
  outSumExp := match(inOutsideElements, inInsideElements)
    // No outside components.
    case ({}, _)
      equation
        inside_sum1 = sumMap(inInsideElements, sumInside1);
        inside_sum2 = sumMap(inInsideElements, sumInside2);
        res = Expression.expDiv(inside_sum1, inside_sum2);
      then
        res;
    // No inside components.
    case (_, {})
      equation
        outside_sum1 = sumMap(inOutsideElements, sumOutside1);
        outside_sum2 = sumMap(inOutsideElements, sumOutside2);
        res = Expression.expDiv(outside_sum1, outside_sum2);
      then
        res;
    // Both outside and inside components.
    else
      equation
        outside_sum1 = sumMap(inOutsideElements, sumOutside1);
        outside_sum2 = sumMap(inOutsideElements, sumOutside2);
        inside_sum1 = sumMap(inInsideElements, sumInside1);
        inside_sum2 = sumMap(inInsideElements, sumInside2);
        res = Expression.expDiv(Expression.expAdd(outside_sum1, inside_sum1),
                                Expression.expAdd(outside_sum2, inside_sum2));
      then
        res;
  end match;
end streamSumEquationExp;

protected function sumMap
  "Creates a sum expression by applying the given function on the list of
  elements and summing up the resulting expressions."
  input list<SetElement> inElements;
  input FuncType inFunc;
  output DAE.Exp outExp;
  
  replaceable type SetElement subtypeof Any;

  partial function FuncType
    input SetElement inElement;
    output DAE.Exp outExp;
  end FuncType;
algorithm
  outExp := match(inElements, inFunc)
    local
      SetElement elem;
      list<SetElement> rest_elem;
      DAE.Exp e1, e2;

    case ({elem}, _)
      equation
        e1 = inFunc(elem);
      then
        e1;

    case (elem :: rest_elem, _)
      equation
        e1 = inFunc(elem);
        e2 = sumMap(rest_elem, inFunc);
      then
        Expression.expAdd(e1, e2);
  end match;
end sumMap;

protected function streamFlowExp
  "Returns the stream and flow component in a stream set element as expressions."
  input Connector inElement;
  output DAE.Exp outStreamExp;
  output DAE.Exp outFlowExp;
protected
  DAE.ComponentRef stream_cr, flow_cr;
algorithm
  Connect2.CONNECTOR(name = stream_cr, ty = Connect2.STREAM(SOME(flow_cr))) := inElement;
  outStreamExp := Expression.crefExp(stream_cr);
  outFlowExp := Expression.crefExp(flow_cr);
end streamFlowExp;

protected function flowExp
  "Returns the flow component in a stream set element as an expression."
  input Connector inElement;
  output DAE.Exp outFlowExp;
protected
  DAE.ComponentRef flow_cr;
algorithm
  Connect2.CONNECTOR(ty = Connect2.STREAM(SOME(flow_cr))) := inElement;
  outFlowExp := Expression.crefExp(flow_cr);
end flowExp;

protected function sumOutside1
  "Helper function to streamSumEquationExp. Returns the expression 
    max(flow_exp, eps) * inStream(stream_exp)
  given a stream set element."
  input Connector inElement;
  output DAE.Exp outExp;
protected
  DAE.Exp stream_exp, flow_exp;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(inElement);
  outExp := Expression.expMul(makePositiveMaxCall(flow_exp),
                              makeInStreamCall(stream_exp));
end sumOutside1;

protected function sumInside1
  "Helper function to streamSumEquationExp. Returns the expression 
    max(-flow_exp, eps) * stream_exp
  given a stream set element."
  input Connector inElement;
  output DAE.Exp outExp;
protected
  DAE.Exp stream_exp, flow_exp;
algorithm
  (stream_exp, flow_exp) := streamFlowExp(inElement);
  flow_exp := DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT), flow_exp);
  outExp := Expression.expMul(makePositiveMaxCall(flow_exp), stream_exp);
end sumInside1;

protected function sumOutside2
  "Helper function to streamSumEquationExp. Returns the expression 
    max(flow_exp, eps)
  given a stream set element."
  input Connector inElement;
  output DAE.Exp outExp;
protected
  DAE.Exp flow_exp;
algorithm
  flow_exp := flowExp(inElement);
  outExp := makePositiveMaxCall(flow_exp);
end sumOutside2;

protected function sumInside2
  "Helper function to streamSumEquationExp. Returns the expression 
    max(-flow_exp, eps)
  given a stream set element."
  input Connector inElement;
  output DAE.Exp outExp;
protected
  DAE.Exp flow_exp;
algorithm
  flow_exp := flowExp(inElement);
  flow_exp := DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT), flow_exp);
  outExp := makePositiveMaxCall(flow_exp);
end sumInside2;

protected function makeInStreamCall
  "Creates an inStream call expression."
  input DAE.Exp inStreamExp;
  output DAE.Exp outInStreamCall;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outInStreamCall := DAE.CALL(Absyn.IDENT("inStream"), {inStreamExp},
    DAE.CALL_ATTR(DAE.T_UNKNOWN_DEFAULT, false, false, DAE.NO_INLINE(), DAE.NO_TAIL()));
end makeInStreamCall;

protected function makePositiveMaxCall
  "Generates a max(flow_exp, eps) call."
  input DAE.Exp inFlowExp;
  output DAE.Exp outPositiveMaxCall;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outPositiveMaxCall := DAE.CALL(Absyn.IDENT("max"), 
    {inFlowExp, DAE.RCONST(1e-15)}, DAE.CALL_ATTR(DAE.T_REAL_DEFAULT, false, true, DAE.NO_INLINE(), DAE.NO_TAIL()));
end makePositiveMaxCall;

protected function removeStreamSetElement
  "This function removes the given cref from a connection set."
  input DAE.ComponentRef inCref;
  input list<Connector> inElements;
  output list<Connector> outElements;
algorithm
  (outElements, _) := List.deleteMemberOnTrue(inCref, inElements, compareCrefStreamSet);
end removeStreamSetElement;
        
protected function compareCrefStreamSet
  "Helper function to removeStreamSetElement. Checks if the cref in a stream set
  element matches the given cref."
  input DAE.ComponentRef inCref;
  input Connector inElement;
  output Boolean outRes;
algorithm
  outRes := matchcontinue(inCref, inElement)
    local
      DAE.ComponentRef cr;
    case (_, Connect2.CONNECTOR(name = cr))
      equation
        true = ComponentReference.crefEqualNoStringCompare(inCref, cr);
      then
        true;
    else then false;
  end matchcontinue;
end compareCrefStreamSet;


end ConnectUtil2;

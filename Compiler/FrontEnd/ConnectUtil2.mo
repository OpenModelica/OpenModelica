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
protected import ConnectEquations;
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
public type ConnectorAttr = Connect2.ConnectorAttr;
public type Face = Connect2.Face;
public type Root = Connect2.Root;

public type Class = InstTypes.Class;
public type Component = InstTypes.Component;
public type Element = InstTypes.Element;
public type Equation = InstTypes.Equation;
public type DaePrefixes = InstTypes.DaePrefixes;

protected type DisjointSets = ConnectionSets.DisjointSets;

public function makeBranch
  input DAE.ComponentRef inNode1;
  input DAE.ComponentRef inNode2;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  ConnectCheck.crefIsValidNode(inNode1, "Connections.branch", true, inInfo);
  ConnectCheck.crefIsValidNode(inNode2, "Connections.branch", false, inInfo);
  outConnections := Connect2.emptyConnections;
end makeBranch;

public function makeRoot
  input DAE.ComponentRef inNode;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  ConnectCheck.crefIsValidNode(inNode, "Connections.root", true, inInfo);
  outConnections := Connect2.emptyConnections;
end makeRoot;

public function makePotentialRoot
  input DAE.ComponentRef inNode;
  input DAE.Exp inPriority;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  ConnectCheck.crefIsValidNode(inNode, "Connections.potentialRoot", true, inInfo);
  outConnections := Connect2.emptyConnections;
end makePotentialRoot;

public function makeConnector
  input DAE.ComponentRef inName;
  input Face inFace;
  input Option<Component> inComponent;
  output Connector outConnector;
protected
  DAE.Type ty;
  ConnectorType cty;
  ConnectorAttr attr;
algorithm
  (ty, cty, attr) := extractConnectorTypesFromComp(inComponent);
  outConnector := makeConnector2(inName, ty, inFace, cty, attr);
end makeConnector;

protected function makeConnector2
  input DAE.ComponentRef inName;
  input DAE.Type inType;
  input Face inFace;
  input ConnectorType inConnectorType;
  input ConnectorAttr inConnectorAttr;
  output Connector outConnector;
algorithm
  outConnector := Connect2.CONNECTOR(inName, inType, inFace,
    inConnectorType, inConnectorAttr);
end makeConnector2;

protected function extractConnectorTypesFromComp
  input Option<Component> inComponent;
  output DAE.Type outType;
  output ConnectorType outConnectorType;
  output ConnectorAttr outConnectorAttr;
algorithm
  (outType, outConnectorType, outConnectorAttr) := match(inComponent)
    local
      DAE.Type ty;
      DAE.ConnectorType dcty;
      ConnectorType cty;
      DaePrefixes prefs;
      ConnectorAttr attr;

    case SOME(InstTypes.TYPED_COMPONENT(ty = ty, prefixes = prefs))
      equation
        (attr, dcty) = extractConnectorAttrFromPrefs(prefs);
        cty = translateDaeConnectorType(dcty);
      then
        (ty, cty, attr);

    else (DAE.T_UNKNOWN_DEFAULT, Connect2.NO_TYPE(),
          Connect2.CONN_ATTR(DAE.VARIABLE(), DAE.PUBLIC(), DAE.BIDIR()));

  end match;
end extractConnectorTypesFromComp;

public function renameConnector
  input DAE.ComponentRef inName;
  input Connector inConnector;
  output Connector outConnector;
protected
  DAE.Type ty;
  Face face;
  ConnectorType cty;
  ConnectorAttr attr;
algorithm
  Connect2.CONNECTOR(_, ty, face, cty, attr) := inConnector;
  outConnector := Connect2.CONNECTOR(inName, ty, face, cty, attr);
end renameConnector;
  
public function updateConnectorType
  input DAE.Type inType;
  input Connector inConnector;
  output Connector outConnector;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType cty;
  ConnectorAttr attr;
algorithm
  Connect2.CONNECTOR(name, _, face, cty, attr) := inConnector;
  outConnector := Connect2.CONNECTOR(name, inType, face, cty, attr);
end updateConnectorType;
  
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

public function faceEqual
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
  Connect2.CONNECTOR(name = name, face = face, cty = cty) := inConnector;
  name_str := ComponentReference.printComponentRefStr(name);
  face_str := faceStr(face);
  cty_str := connectorTypeStr(cty);
  outString := cty_str +& " " +& name_str +& "<" +& face_str +& ">";
end connectorStr;
  
public function faceStr
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

public function unparseConnectorType
  input ConnectorType inConnectorType;
  output String outString;
algorithm
  outString := match(inConnectorType)
    case Connect2.FLOW() then "flow";
    case Connect2.STREAM(_) then "stream";
    else "";
  end match;
end unparseConnectorType;

public function getConnectorPrefixes
  input DaePrefixes inPrefixes;
  output ConnectorType outConnectorType;
  output DAE.VarKind outVariability;
algorithm
  (outConnectorType, outVariability) := match(inPrefixes)
    local
      DAE.ConnectorType dcty;
      ConnectorType cty;
      DAE.VarKind var;

    case InstTypes.DAE_PREFIXES(connectorType = dcty, variability = var)
      equation
        cty = translateDaeConnectorType(dcty);
      then
        (cty, var);

    else (Connect2.POTENTIAL(), DAE.VARIABLE());

  end match;
end getConnectorPrefixes;

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

public function translateConnectorTypeToSCode
  input ConnectorType inConnectorType;
  output SCode.ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType)
    case Connect2.POTENTIAL() then SCode.POTENTIAL();
    case Connect2.FLOW() then SCode.FLOW();
    case Connect2.STREAM(_) then SCode.STREAM();
  end match;
end translateConnectorTypeToSCode;

public function makeConnection
  input Connector inLhs;
  input Connector inRhs;
  input Absyn.Info inInfo;
  output Connection outConnection;
algorithm
  outConnection := Connect2.CONNECTION(inLhs, inRhs, inInfo);
end makeConnection;

public function addConnectionCond
  input Boolean inAdd;
  input Connector inLhsConnector;
  input Connector inRhsConnector;
  input Absyn.Info inInfo;
  input Connections inConnections;
  output Connections outConnections;
algorithm
  outConnections :=
  match(inAdd, inLhsConnector, inRhsConnector, inInfo, inConnections)
    case (true, _, _, _, _)
      then addConnection(inLhsConnector, inRhsConnector, inInfo, inConnections);

    else inConnections;
  end match;
end addConnectionCond;

public function addConnection
  input Connector inLhsConnector;
  input Connector inRhsConnector;
  input Absyn.Info inInfo;
  input Connections inConnections;
  output Connections outConnections;
protected
  Connection conn;
algorithm
  conn := makeConnection(inLhsConnector, inRhsConnector, inInfo);
  outConnections := consConnection(conn, inConnections);
end addConnection;

protected function consConnection
  input Connection inConnection;
  input Connections inConnections;
  output Connections outConnections;
algorithm
  outConnections := matchcontinue(inConnection, inConnections)
    local
      list<Connection> connl, expconnl, branches;
      list<Root> roots;
      Connector lhs, rhs;

    case (Connect2.CONNECTION(lhs = lhs, rhs = rhs),
        Connect2.CONNECTIONS(connl, expconnl, branches, roots))
      equation
        true = isExpandableConnector(lhs) or
               isUndeclaredConnector(lhs) or
               isUndeclaredConnector(rhs);
        expconnl = inConnection :: connl;
      then
        Connect2.CONNECTIONS(connl, expconnl, branches, roots);

    case (_, Connect2.CONNECTIONS(connl, expconnl, branches, roots))
      equation
        connl = inConnection :: connl;
      then
        Connect2.CONNECTIONS(connl, expconnl, branches, roots);

  end matchcontinue;
end consConnection;

public function isEmptyConnections
  input Connections inConnections;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match(inConnections)
    case Connect2.CONNECTIONS({}, {}, {}, {}) then true;
    else false;
  end match;
end isEmptyConnections;

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
      Component comp;
      DAE.ComponentRef cref;
      Connector c;

    case (InstTypes.ELEMENT(component = comp), _)
      equation
        true = InstUtil.isFlowComponent(comp);
        cref = InstUtil.makeTypedComponentCref(comp);
        c = makeConnector(cref, Connect2.INSIDE(), SOME(comp));
      then
        c :: inAccumFlows;

    else inAccumFlows;
  end matchcontinue;
end collectFlowConnector;

protected function extractConnectorAttrFromPrefs
  input DaePrefixes inPrefixes;
  output ConnectorAttr outAttributes;
  output DAE.ConnectorType outConnectorType;
algorithm
  (outAttributes, outConnectorType) := match(inPrefixes)
    local
      DAE.VarKind var;
      DAE.VarVisibility vis;
      DAE.VarDirection dir;
      DAE.ConnectorType cty;

    case InstTypes.DAE_PREFIXES(visibility = vis, variability = var,
        direction = dir, connectorType = cty)
      then (Connect2.CONN_ATTR(var, vis, dir), cty);

    else (Connect2.CONN_ATTR(DAE.VARIABLE(), DAE.PUBLIC(), DAE.BIDIR()),
            DAE.POTENTIAL());

  end match;
end extractConnectorAttrFromPrefs;

public function connectionCount
  input Connections inConnections;
  output Integer outCount;
protected
  list<Connection> connl;
algorithm
  Connect2.CONNECTIONS(connections = connl) := inConnections;
  outCount := listLength(connl);
end connectionCount;

public function expandConnector
  input Connector inConnector;
  output list<Connector> outConnectors;
algorithm
  outConnectors := match(inConnector)
    local
      DAE.ComponentRef name;
      Face face;
      ConnectorType cty;
      list<DAE.ComponentRef> prefixes;
      DAE.Type ty;
      list<Connector> connl;
      ConnectorAttr attr;

    case Connect2.CONNECTOR(name as DAE.CREF_IDENT(ident = _), ty, face, cty, attr)
      then expandConnector2(name, ty, face, cty, attr);

    case Connect2.CONNECTOR(name, ty, face, cty, attr)
      equation
        (prefixes, name) = expandConnectorPrefix(name);
        connl = expandConnector2(name, ty, face, cty, attr);
        connl = List.productMap(prefixes, connl, prefixConnector);
      then
        connl;

  end match;
end expandConnector;

protected function expandConnectorPrefix
  input DAE.ComponentRef inCref;
  output list<DAE.ComponentRef> outPrefixes;
  output DAE.ComponentRef outLastCref;
algorithm
  (outPrefixes, outLastCref) := match(inCref)
    local
      list<DAE.ComponentRef> prefixes;
      DAE.ComponentRef pre_cr, last_cr;

    case DAE.CREF_IDENT(ident = _) then ({}, inCref);
    else
      equation
        (pre_cr, last_cr) = ComponentReference.splitCrefLast(inCref);
        prefixes = ComponentReference.expandCref(pre_cr, false);
      then
        (prefixes, last_cr);

  end match;
end expandConnectorPrefix;

public function prefixConnector
  input DAE.ComponentRef inPrefix;
  input Connector inConnector;
  output Connector outConnector;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType cty;
  DAE.Type ty;
  ConnectorAttr attr;
algorithm
  Connect2.CONNECTOR(name, ty, face, cty, attr) := inConnector;
  name := ComponentReference.joinCrefs(inPrefix, name);
  outConnector := Connect2.CONNECTOR(name, ty, face, cty, attr);
end prefixConnector;

public function varToConnector
  input DAE.Var inVar;
  input DAE.ComponentRef inPrefixCref;
  input Face inFace;
  output Connector outConnector;
protected
  DAE.Ident name;
  DAE.Type ty;
  DAE.ComponentRef cref;
  SCode.ConnectorType scty;
  ConnectorType cty;
  SCode.Variability svar;
  DAE.VarKind var;
  Absyn.Direction sdir;
  DAE.VarDirection dir;
  SCode.Visibility svis;
  DAE.VarVisibility vis;
  ConnectorAttr attr;
algorithm
  DAE.TYPES_VAR(name = name, ty = ty, attributes = DAE.ATTR(connectorType = scty,
    variability = svar, direction = sdir, visibility = svis)) := inVar;
  cref := ComponentReference.makeCrefIdent(name, ty, {});
  cref := ComponentReference.joinCrefs(inPrefixCref, cref);
  cty := translateSCodeConnectorType(scty);
  var := InstUtil.translateVariability(svar);
  dir := InstUtil.translateDirection(sdir);
  vis := InstUtil.translateVisibility(svis);
  attr := Connect2.CONN_ATTR(var, vis, dir);
  outConnector := makeConnector2(cref, ty, inFace, cty, attr);
end varToConnector;
  
protected function expandConnector2
  input DAE.ComponentRef inCref;
  input DAE.Type inType;
  input Face inFace;
  input ConnectorType inConnectorType;
  input ConnectorAttr inConnectorAttr;
  output list<Connector> outConnectors;
algorithm
  outConnectors := match(inCref, inType, inFace, inConnectorType, inConnectorAttr)
    local
      list<DAE.Var> vars;
      list<DAE.ComponentRef> crefs;
      list<Connector> connl;
      Connector conn;

    case (_, DAE.T_ARRAY(ty = _), _, _, _)
      equation
        crefs = ComponentReference.expandCref(inCref, false);
        connl = List.map4(crefs, makeConnector2, inType, inFace, inConnectorType,
          inConnectorAttr);
      then
        connl;

    case (_, DAE.T_COMPLEX(varLst = vars), _, _, _)
      equation
        vars = List.filterOnTrueReverse(vars, DAEUtil.isNotParamOrConstVar);
      then
        List.map2(vars, varToConnector, inCref, inFace);

    else
      equation
        conn = makeConnector2(inCref, inType, inFace, inConnectorType, inConnectorAttr);
      then
        {conn};

  end match;
end expandConnector2;

public function getConnectorFace
  "Determines the face of a connector element, i.e. inside or outside. A
   connector element is outside if the first identifier in the cref is a
   connector, otherwise inside."
  input DAE.ComponentRef inCref;
  input Component inComponent;
  output Face outFace;
algorithm
  outFace := match(inCref, inComponent)
    local
      Component comp;
      Boolean is_conn;
      Face face;

    // Non-qualified connector crefs are always outside.
    case (DAE.CREF_IDENT(ident = _), _) then Connect2.OUTSIDE();

    // Qualified connector crefs are allowed to be on two forms: m.c or
    // c1.c2.c3..., where m is a non-connector component and cN a connector.
    // To determine the face of a connector we only need to look at the parent
    // of the given connector element.
    case (DAE.CREF_QUAL(ident = _), _)
      equation
        SOME(comp) = InstUtil.getComponentParent(inComponent);
        is_conn = InstUtil.isConnectorComponent(comp);
        // Connector => outside, not connector => inside.
        face = Util.if_(is_conn, Connect2.OUTSIDE(), Connect2.INSIDE());
      then
        face;

  end match;
end getConnectorFace;
        
public function isConstOrComplexConnector
  input Connector inConnector;
  output Boolean outIsConstOrComplex;
algorithm
  outIsConstOrComplex := match(inConnector)
    local
      DAE.VarKind var;

    case Connect2.CONNECTOR(ty = DAE.T_COMPLEX(varLst = _)) then true;
    case Connect2.CONNECTOR(attr = Connect2.CONN_ATTR(variability = var))
      then DAEUtil.isParamOrConstVarKind(var);

  end match;
end isConstOrComplexConnector;
    
public function isExpandableConnector
  "Returns true if the connector is an expandable connector."
  input Connector inConnector;
  output Boolean outIsExpandable;
protected
  DAE.Type ty;
algorithm
  Connect2.CONNECTOR(ty = ty) := inConnector;
  outIsExpandable := Types.isComplexExpandableConnector(ty);
end isExpandableConnector;

public function isUndeclaredConnector
  "Returns true if the connector is undeclared, i.e. a connector that will be
   added to an expandable connector, otherwise false."
  input Connector inConnector;
  output Boolean outIsUndeclared;
algorithm
  outIsUndeclared := match(inConnector)
    case Connect2.CONNECTOR(ty = DAE.T_UNKNOWN(source = _)) then true;
    else false;
  end match;
end isUndeclaredConnector;

end ConnectUtil2;

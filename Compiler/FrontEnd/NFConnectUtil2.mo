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

encapsulated package NFConnectUtil2
" file:        NFConnectUtil2.mo
  package:     NFConnectUtil2
  description: Connection set utility functions

"

public import Absyn;
public import NFConnect2;
public import DAE;
public import NFConnectionSets;
public import NFInstTypes;
public import SCode;
public import Types;

protected import ComponentReference;
protected import NFConnectCheck;
protected import DAEUtil;
protected import NFInstUtil;
protected import List;
protected import Util;

protected type Connections = NFConnect2.Connections;
protected type Connection = NFConnect2.Connection;
protected type Connector = NFConnect2.Connector;
protected type ConnectorType = NFConnect2.ConnectorType;
protected type ConnectorAttr = NFConnect2.ConnectorAttr;
protected type Face = NFConnect2.Face;
protected type Root = NFConnect2.Root;

protected type Class = NFInstTypes.Class;
protected type Component = NFInstTypes.Component;
protected type Element = NFInstTypes.Element;
protected type Equation = NFInstTypes.Equation;
protected type DaePrefixes = NFInstTypes.DaePrefixes;

protected type DisjointSets = NFConnectionSets.DisjointSets;

public function makeBranch
  input DAE.ComponentRef inNode1;
  input DAE.ComponentRef inNode2;
  input SourceInfo inInfo;
  output NFConnect2.Connections outConnections;
algorithm
  NFConnectCheck.crefIsValidNode(inNode1, "Connections.branch", true, inInfo);
  NFConnectCheck.crefIsValidNode(inNode2, "Connections.branch", false, inInfo);
  outConnections := NFConnect2.emptyConnections;
end makeBranch;

public function makeRoot
  input DAE.ComponentRef inNode;
  input SourceInfo inInfo;
  output NFConnect2.Connections outConnections;
algorithm
  NFConnectCheck.crefIsValidNode(inNode, "Connections.root", true, inInfo);
  outConnections := NFConnect2.emptyConnections;
end makeRoot;

public function makePotentialRoot
  input DAE.ComponentRef inNode;
  input DAE.Exp inPriority;
  input SourceInfo inInfo;
  output NFConnect2.Connections outConnections;
algorithm
  NFConnectCheck.crefIsValidNode(inNode, "Connections.potentialRoot", true, inInfo);
  outConnections := NFConnect2.emptyConnections;
end makePotentialRoot;

public function makeConnector
  input DAE.ComponentRef inName;
  input NFConnect2.Face inFace;
  input Option<NFInstTypes.Component> inComponent;
  output NFConnect2.Connector outConnector;
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
  input NFConnect2.Face inFace;
  input NFConnect2.ConnectorType inConnectorType;
  input NFConnect2.ConnectorAttr inConnectorAttr;
  output NFConnect2.Connector outConnector;
algorithm
  outConnector := NFConnect2.CONNECTOR(inName, inType, inFace,
    inConnectorType, inConnectorAttr);
end makeConnector2;

protected function extractConnectorTypesFromComp
  input Option<NFInstTypes.Component> inComponent;
  output DAE.Type outType;
  output NFConnect2.ConnectorType outConnectorType;
  output NFConnect2.ConnectorAttr outConnectorAttr;
algorithm
  (outType, outConnectorType, outConnectorAttr) := match(inComponent)
    local
      DAE.Type ty;
      DAE.ConnectorType dcty;
      ConnectorType cty;
      DaePrefixes prefs;
      ConnectorAttr attr;

    case SOME(NFInstTypes.TYPED_COMPONENT(ty = ty, prefixes = prefs))
      equation
        (attr, dcty) = extractConnectorAttrFromPrefs(prefs);
        cty = translateDaeConnectorType(dcty);
      then
        (ty, cty, attr);

    else (DAE.T_UNKNOWN_DEFAULT, NFConnect2.NO_TYPE(),
          NFConnect2.CONN_ATTR(DAE.VARIABLE(), DAE.PUBLIC(), DAE.BIDIR()));

  end match;
end extractConnectorTypesFromComp;

public function renameConnector
  input DAE.ComponentRef inName;
  input NFConnect2.Connector inConnector;
  output NFConnect2.Connector outConnector;
protected
  DAE.Type ty;
  Face face;
  ConnectorType cty;
  ConnectorAttr attr;
algorithm
  NFConnect2.CONNECTOR(_, ty, face, cty, attr) := inConnector;
  outConnector := NFConnect2.CONNECTOR(inName, ty, face, cty, attr);
end renameConnector;

public function updateConnectorType
  input DAE.Type inType;
  input NFConnect2.Connector inConnector;
  output NFConnect2.Connector outConnector;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType cty;
  ConnectorAttr attr;
algorithm
  NFConnect2.CONNECTOR(name, _, face, cty, attr) := inConnector;
  outConnector := NFConnect2.CONNECTOR(name, inType, face, cty, attr);
end updateConnectorType;

public function connectorEqual
  input NFConnect2.Connector inConnector1;
  input NFConnect2.Connector inConnector2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inConnector1, inConnector2)
    local
      DAE.ComponentRef name1, name2;
      Face face1, face2;

    case (NFConnect2.CONNECTOR(name = name1, face = face1),
          NFConnect2.CONNECTOR(name = name2, face = face2))
        guard faceEqual(face1, face2) and ComponentReference.crefEqualNoStringCompare(name1, name2)
      then
        true;

    else false;

  end match;
end connectorEqual;

public function faceEqual
  input NFConnect2.Face inFace1;
  input NFConnect2.Face inFace2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := match(inFace1, inFace2)
    case (NFConnect2.INSIDE(), NFConnect2.INSIDE()) then true;
    case (NFConnect2.OUTSIDE(), NFConnect2.OUTSIDE()) then true;
    case (NFConnect2.NO_FACE(), NFConnect2.NO_FACE()) then true;
    else false;
  end match;
end faceEqual;

public function connectorTypeEqual
  input NFConnect2.ConnectorType inType1;
  input NFConnect2.ConnectorType inType2;
  output Boolean outEqual;
algorithm
  outEqual := match(inType1, inType2)
    case (NFConnect2.POTENTIAL(), NFConnect2.POTENTIAL()) then true;
    case (NFConnect2.FLOW(), NFConnect2.FLOW()) then true;
    case (NFConnect2.STREAM(_), NFConnect2.STREAM(_)) then true;
    else false;
  end match;
end connectorTypeEqual;

public function isPotential
  input NFConnect2.ConnectorType inType;
  output Boolean outIsPotential;
algorithm
  outIsPotential := match(inType)
    case NFConnect2.POTENTIAL() then true;
    else false;
  end match;
end isPotential;

public function connectorStr
  input NFConnect2.Connector inConnector;
  output String outString;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType cty;
  String name_str, face_str, cty_str;
algorithm
  NFConnect2.CONNECTOR(name = name, face = face, cty = cty) := inConnector;
  name_str := ComponentReference.printComponentRefStr(name);
  face_str := faceStr(face);
  cty_str := connectorTypeStr(cty);
  outString := cty_str + " " + name_str + "<" + face_str + ">";
end connectorStr;

public function faceStr
  input NFConnect2.Face inFace;
  output String outString;
algorithm
  outString := match(inFace)
    case NFConnect2.INSIDE() then "inside";
    case NFConnect2.OUTSIDE() then "outside";
    case NFConnect2.NO_FACE() then "no_face";
  end match;
end faceStr;

public function connectorTypeStr
  input NFConnect2.ConnectorType inConnectorType;
  output String outString;
algorithm
  outString := match(inConnectorType)
    local
      DAE.ComponentRef cref;
      String cref_str;

    case NFConnect2.POTENTIAL() then "";
    case NFConnect2.FLOW() then "flow";
    case NFConnect2.STREAM(NONE()) then "stream()";
    case NFConnect2.STREAM(SOME(cref))
      equation
        cref_str = ComponentReference.printComponentRefStr(cref);
      then
        "stream(" + cref_str + ")";
    else "NO_TYPE";
  end match;
end connectorTypeStr;

public function unparseConnectorType
  input NFConnect2.ConnectorType inConnectorType;
  output String outString;
algorithm
  outString := match(inConnectorType)
    case NFConnect2.FLOW() then "flow";
    case NFConnect2.STREAM(_) then "stream";
    else "";
  end match;
end unparseConnectorType;

public function getConnectorPrefixes
  input NFInstTypes.DaePrefixes inPrefixes;
  output NFConnect2.ConnectorType outConnectorType;
  output DAE.VarKind outVariability;
algorithm
  (outConnectorType, outVariability) := match(inPrefixes)
    local
      DAE.ConnectorType dcty;
      ConnectorType cty;
      DAE.VarKind var;

    case NFInstTypes.DAE_PREFIXES(connectorType = dcty, variability = var)
      equation
        cty = translateDaeConnectorType(dcty);
      then
        (cty, var);

    else (NFConnect2.POTENTIAL(), DAE.VARIABLE());

  end match;
end getConnectorPrefixes;

public function translateDaeConnectorType
  input DAE.ConnectorType inConnectorType;
  output NFConnect2.ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType)
    case DAE.POTENTIAL() then NFConnect2.POTENTIAL();
    case DAE.FLOW() then NFConnect2.FLOW();
    case DAE.STREAM() then NFConnect2.STREAM(NONE());
    case DAE.NON_CONNECTOR() then NFConnect2.POTENTIAL();
  end match;
end translateDaeConnectorType;

public function translateSCodeConnectorType
  input SCode.ConnectorType inConnectorType;
  output NFConnect2.ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType)
    case SCode.POTENTIAL() then NFConnect2.POTENTIAL();
    case SCode.FLOW() then NFConnect2.FLOW();
    case SCode.STREAM() then NFConnect2.STREAM(NONE());
  end match;
end translateSCodeConnectorType;

public function translateConnectorTypeToSCode
  input NFConnect2.ConnectorType inConnectorType;
  output SCode.ConnectorType outConnectorType;
algorithm
  outConnectorType := match(inConnectorType)
    case NFConnect2.POTENTIAL() then SCode.POTENTIAL();
    case NFConnect2.FLOW() then SCode.FLOW();
    case NFConnect2.STREAM(_) then SCode.STREAM();
  end match;
end translateConnectorTypeToSCode;

public function makeConnection
  input NFConnect2.Connector inLhs;
  input NFConnect2.Connector inRhs;
  input SourceInfo inInfo;
  output NFConnect2.Connection outConnection;
algorithm
  outConnection := NFConnect2.CONNECTION(inLhs, inRhs, inInfo);
end makeConnection;

public function addConnectionCond
  input Boolean inAdd;
  input NFConnect2.Connector inLhsConnector;
  input NFConnect2.Connector inRhsConnector;
  input SourceInfo inInfo;
  input NFConnect2.Connections inConnections;
  output NFConnect2.Connections outConnections;
algorithm
  outConnections :=
  match(inAdd, inLhsConnector, inRhsConnector, inInfo, inConnections)
    case (true, _, _, _, _)
      then addConnection(inLhsConnector, inRhsConnector, inInfo, inConnections);

    else inConnections;
  end match;
end addConnectionCond;

public function addConnection
  input NFConnect2.Connector inLhsConnector;
  input NFConnect2.Connector inRhsConnector;
  input SourceInfo inInfo;
  input NFConnect2.Connections inConnections;
  output NFConnect2.Connections outConnections;
protected
  Connection conn;
algorithm
  conn := makeConnection(inLhsConnector, inRhsConnector, inInfo);
  outConnections := consConnection(conn, inConnections);
end addConnection;

protected function consConnection
  input NFConnect2.Connection inConnection;
  input NFConnect2.Connections inConnections;
  output NFConnect2.Connections outConnections;
algorithm
  outConnections := matchcontinue(inConnection, inConnections)
    local
      list<Connection> connl, expconnl, branches;
      list<Root> roots;
      Connector lhs, rhs;

    case (NFConnect2.CONNECTION(lhs = lhs, rhs = rhs),
        NFConnect2.CONNECTIONS(connl, expconnl, branches, roots))
      equation
        true = isExpandableConnector(lhs) or
               isUndeclaredConnector(lhs) or
               isUndeclaredConnector(rhs);
        expconnl = inConnection :: connl;
      then
        NFConnect2.CONNECTIONS(connl, expconnl, branches, roots);

    case (_, NFConnect2.CONNECTIONS(connl, expconnl, branches, roots))
      equation
        connl = inConnection :: connl;
      then
        NFConnect2.CONNECTIONS(connl, expconnl, branches, roots);

  end matchcontinue;
end consConnection;

public function isEmptyConnections
  input NFConnect2.Connections inConnections;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match(inConnections)
    case NFConnect2.CONNECTIONS({}, {}, {}, {}) then true;
    else false;
  end match;
end isEmptyConnections;

public function collectFlowConnectors
  input NFInstTypes.Class inClass;
  output list<NFConnect2.Connector> outFlows;
algorithm
  outFlows := collectFlowConnectors2(inClass, {});
end collectFlowConnectors;

protected function collectFlowConnectors2
  input NFInstTypes.Class inClass;
  input list<NFConnect2.Connector> inAccumFlows;
  output list<NFConnect2.Connector> outFlows;
algorithm
  outFlows := match(inClass, inAccumFlows)
    local
      list<Element> comps;

    case (NFInstTypes.COMPLEX_CLASS(components = comps), _)
      then List.fold(comps, collectFlowConnectors3, inAccumFlows);

    else inAccumFlows;
  end match;
end collectFlowConnectors2;

protected function collectFlowConnectors3
  input Element inElement;
  input list<NFConnect2.Connector> inAccumFlows;
  output list<NFConnect2.Connector> outFlows;
algorithm
  outFlows := matchcontinue(inElement, inAccumFlows)
    local
      Component comp;
      DAE.Type ty;
      Class cls;
      list<Element> sub_comps;
      list<NFConnect2.Connector> flows;

    case (NFInstTypes.ELEMENT(component = comp as NFInstTypes.TYPED_COMPONENT(),
        cls = cls as NFInstTypes.COMPLEX_CLASS(components = sub_comps)), flows)
      equation
        true = NFInstUtil.isConnectorComponent(comp);
        flows = collectFlowConnectors2(cls, flows);
        flows = List.fold(sub_comps, collectFlowConnector, flows);
      then
        flows;

    case (NFInstTypes.ELEMENT(cls = cls as NFInstTypes.COMPLEX_CLASS()), _)
      then collectFlowConnectors2(cls, inAccumFlows);

    else inAccumFlows;
  end matchcontinue;
end collectFlowConnectors3;

protected function collectFlowConnector
  input Element inElement;
  input list<NFConnect2.Connector> inAccumFlows;
  output list<NFConnect2.Connector> outFlows;
algorithm
  outFlows := matchcontinue(inElement, inAccumFlows)
    local
      Component comp;
      DAE.ComponentRef cref;
      Connector c;

    case (NFInstTypes.ELEMENT(component = comp), _)
      equation
        true = NFInstUtil.isFlowComponent(comp);
        cref = NFInstUtil.makeTypedComponentCref(comp);
        c = makeConnector(cref, NFConnect2.INSIDE(), SOME(comp));
      then
        c :: inAccumFlows;

    else inAccumFlows;
  end matchcontinue;
end collectFlowConnector;

protected function extractConnectorAttrFromPrefs
  input NFInstTypes.DaePrefixes inPrefixes;
  output NFConnect2.ConnectorAttr outAttributes;
  output DAE.ConnectorType outConnectorType;
algorithm
  (outAttributes, outConnectorType) := match(inPrefixes)
    local
      DAE.VarKind var;
      DAE.VarVisibility vis;
      DAE.VarDirection dir;
      DAE.ConnectorType cty;

    case NFInstTypes.DAE_PREFIXES(visibility = vis, variability = var,
        direction = dir, connectorType = cty)
      then (NFConnect2.CONN_ATTR(var, vis, dir), cty);

    else (NFConnect2.CONN_ATTR(DAE.VARIABLE(), DAE.PUBLIC(), DAE.BIDIR()),
            DAE.POTENTIAL());

  end match;
end extractConnectorAttrFromPrefs;

public function connectionCount
  input NFConnect2.Connections inConnections;
  output Integer outCount;
protected
  list<Connection> connl;
algorithm
  NFConnect2.CONNECTIONS(connections = connl) := inConnections;
  outCount := listLength(connl);
end connectionCount;

public function expandConnector
  input NFConnect2.Connector inConnector;
  output list<NFConnect2.Connector> outConnectors;
algorithm
  outConnectors := match(inConnector)
    local
      DAE.ComponentRef name;
      Face face;
      ConnectorType cty;
      list<DAE.ComponentRef> prefixes;
      DAE.Type ty;
      list<NFConnect2.Connector> connl;
      ConnectorAttr attr;

    case NFConnect2.CONNECTOR(name as DAE.CREF_IDENT(), ty, face, cty, attr)
      then expandConnector2(name, ty, face, cty, attr);

    case NFConnect2.CONNECTOR(name, ty, face, cty, attr)
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

    case DAE.CREF_IDENT() then ({}, inCref);
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
  input NFConnect2.Connector inConnector;
  output NFConnect2.Connector outConnector;
protected
  DAE.ComponentRef name;
  Face face;
  ConnectorType cty;
  DAE.Type ty;
  ConnectorAttr attr;
algorithm
  NFConnect2.CONNECTOR(name, ty, face, cty, attr) := inConnector;
  name := ComponentReference.joinCrefs(inPrefix, name);
  outConnector := NFConnect2.CONNECTOR(name, ty, face, cty, attr);
end prefixConnector;

public function varToConnector
  input DAE.Var inVar;
  input DAE.ComponentRef inPrefixCref;
  input NFConnect2.Face inFace;
  output NFConnect2.Connector outConnector;
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
  var := NFInstUtil.translateVariability(svar);
  dir := NFInstUtil.translateDirection(sdir);
  vis := NFInstUtil.translateVisibility(svis);
  attr := NFConnect2.CONN_ATTR(var, vis, dir);
  outConnector := makeConnector2(cref, ty, inFace, cty, attr);
end varToConnector;

protected function expandConnector2
  input DAE.ComponentRef inCref;
  input DAE.Type inType;
  input NFConnect2.Face inFace;
  input NFConnect2.ConnectorType inConnectorType;
  input NFConnect2.ConnectorAttr inConnectorAttr;
  output list<NFConnect2.Connector> outConnectors;
algorithm
  outConnectors := match(inCref, inType, inFace, inConnectorType, inConnectorAttr)
    local
      list<DAE.Var> vars;
      list<DAE.ComponentRef> crefs;
      list<NFConnect2.Connector> connl;
      Connector conn;

    case (_, DAE.T_ARRAY(), _, _, _)
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
  input NFInstTypes.Component inComponent;
  output NFConnect2.Face outFace;
algorithm
  outFace := match(inCref, inComponent)
    local
      Component comp;
      Boolean is_conn;
      Face face;

    // Non-qualified connector crefs are always outside.
    case (DAE.CREF_IDENT(), _) then NFConnect2.OUTSIDE();

    // Qualified connector crefs are allowed to be on two forms: m.c or
    // c1.c2.c3..., where m is a non-connector component and cN a connector.
    // To determine the face of a connector we only need to look at the parent
    // of the given connector element.
    case (DAE.CREF_QUAL(), _)
      equation
        SOME(comp) = NFInstUtil.getComponentParent(inComponent);
        is_conn = NFInstUtil.isConnectorComponent(comp);
        // Connector => outside, not connector => inside.
        face = if is_conn then NFConnect2.OUTSIDE() else NFConnect2.INSIDE();
      then
        face;

  end match;
end getConnectorFace;

public function isConstOrComplexConnector
  input NFConnect2.Connector inConnector;
  output Boolean outIsConstOrComplex;
algorithm
  outIsConstOrComplex := match(inConnector)
    local
      DAE.VarKind var;

    case NFConnect2.CONNECTOR(ty = DAE.T_COMPLEX()) then true;
    case NFConnect2.CONNECTOR(attr = NFConnect2.CONN_ATTR(variability = var))
      then DAEUtil.isParamOrConstVarKind(var);

  end match;
end isConstOrComplexConnector;

public function isExpandableConnector
  "Returns true if the connector is an expandable connector."
  input NFConnect2.Connector inConnector;
  output Boolean outIsExpandable;
protected
  DAE.Type ty;
algorithm
  NFConnect2.CONNECTOR(ty = ty) := inConnector;
  outIsExpandable := Types.isComplexExpandableConnector(ty);
end isExpandableConnector;

public function isUndeclaredConnector
  "Returns true if the connector is undeclared, i.e. a connector that will be
   added to an expandable connector, otherwise false."
  input NFConnect2.Connector inConnector;
  output Boolean outIsUndeclared;
algorithm
  outIsUndeclared := match(inConnector)
    case NFConnect2.CONNECTOR(ty = DAE.T_UNKNOWN()) then true;
    else false;
  end match;
end isUndeclaredConnector;

annotation(__OpenModelica_Interface="frontend");
end NFConnectUtil2;

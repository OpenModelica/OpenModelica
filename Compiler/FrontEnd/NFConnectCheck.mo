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

encapsulated package NFConnectCheck
" file:        NFConnectCheck.mo
  package:     NFConnectCheck
  description: Connection checking functions

  RCS: $Id$
"

public import Absyn;
public import NFConnect2;
public import DAE;
public import NFInstTypes;

protected import ComponentReference;
protected import NFConnectUtil2;
protected import DAEUtil;
protected import DAEDump;
protected import Error;
protected import NFInstUtil;
protected import List;
protected import SCode;
protected import Types;
protected import Util;

public type Connections = NFConnect2.Connections;
public type Connection = NFConnect2.Connection;
public type Connector = NFConnect2.Connector;
public type ConnectorType = NFConnect2.ConnectorType;
public type Face = NFConnect2.Face;
public type Root = NFConnect2.Root;

public type Component = NFInstTypes.Component;

public type TupleErrorInfo = tuple<DAE.ComponentRef, DAE.ComponentRef, SourceInfo>;
public type ConnectorTuple = tuple<DAE.Type, ConnectorType, DAE.VarKind, DAE.VarDirection>;

protected uniontype ConnectorStatus
  record POTENTIALLY_PRESENT end POTENTIALLY_PRESENT;
  record EXPANDABLE_CONNECTOR end EXPANDABLE_CONNECTOR;
  record SIMPLE_CONNECTOR end SIMPLE_CONNECTOR;
end ConnectorStatus;

public function crefIsValidNode
  "A node given as argument to branch, root or potentialRoot must be on the form
   A.R, where A is a connector and R and overdetermined type/record. This
   function checks that a cref is a valid node."
  input DAE.ComponentRef inNode;
  input String inFuncName;
  input Boolean isFirst;
  input SourceInfo inInfo;
algorithm
  _ := match(inNode, inFuncName, isFirst, inInfo)
    local
      DAE.Type ty1, ty2;

    /*-----------------------------------------------------------------------*/
    // TODO: This is actually not working as it should, since the cref will have
    // been prefixed already. Need to check this before prefixing somehow.
    /*-----------------------------------------------------------------------*/
    case (DAE.CREF_QUAL(identType = ty1,
        componentRef = DAE.CREF_IDENT(identType = ty2)), _, _, _)
      equation
        crefIsValidNode2(ty1, ty2, inFuncName, isFirst, inInfo);
      then
        ();

    else
      equation
        Error.addSourceMessage(if isFirst then Error.INVALID_ARGUMENT_TYPE_BRANCH_FIRST else Error.INVALID_ARGUMENT_TYPE_BRANCH_SECOND, {inFuncName}, inInfo);
      then
        ();

  end match;
end crefIsValidNode;

protected function crefIsValidNode2
  input DAE.Type inType1;
  input DAE.Type inType2;
  input String inFuncName;
  input Boolean isFirst;
  input SourceInfo inInfo;
algorithm
  _ := match(inType1, inType2, inFuncName, isFirst, inInfo)
    case (_, _, _, _, _) guard Types.isConnector(inType1) and Types.isOverdeterminedType(inType2)
      then
        ();

    else
      equation
        Error.addSourceMessage(if isFirst then Error.INVALID_ARGUMENT_TYPE_OVERDET_FIRST else Error.INVALID_ARGUMENT_TYPE_OVERDET_SECOND,
          {inFuncName}, inInfo);
      then
        fail();

  end match;
end crefIsValidNode2;

public function checkComponentIsConnector
  input Component inComponent;
  input Option<Component> inPrefixComponent;
  input DAE.ComponentRef inCref;
  input SourceInfo inInfo;
algorithm
  _ := match(inComponent, inPrefixComponent, inCref, inInfo)
    local
      String cref_str, ty_str;
      DAE.Type ty;
      Component comp;

    case (_, _, _, _) guard NFInstUtil.isConnectorComponent(inComponent)
      then
        ();

    // A component in an expandable connector is seen as a connector.
    case (_, SOME(comp), _, _)
      guard Types.isComplexExpandableConnector(NFInstUtil.getComponentType(comp))
      then
        ();

    else
      equation
        ty = NFInstUtil.getComponentType(inComponent);
        ty_str = Types.unparseType(ty);
        cref_str = ComponentReference.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.INVALID_CONNECTOR_TYPE,
          {cref_str, ty_str}, inInfo);
      then
        fail();

  end match;
end checkComponentIsConnector;

public function compatibleConnectors
  "Checks that two connectors are compatible with each other for the purpose of
   connecting them."
  input Connector inLhsConnector;
  input Connector inRhsConnector;
  input SourceInfo inInfo;
protected
  DAE.ComponentRef lhs_name, rhs_name;
  ConnectorTuple lhs_conn, rhs_conn;
  TupleErrorInfo info;
algorithm
  (lhs_conn, lhs_name) := makeConnectorTuple(inLhsConnector);
  (rhs_conn, rhs_name) := makeConnectorTuple(inRhsConnector);
  info := (lhs_name, rhs_name, inInfo);
  compatibleConnectors2(lhs_conn, rhs_conn, info);
end compatibleConnectors;

protected function makeConnectorTuple
  input Connector inConnector;
  output ConnectorTuple outTuple;
  output DAE.ComponentRef outName;
protected
  DAE.Type ty;
  ConnectorType cty;
  DAE.VarKind var;
  DAE.VarDirection dir;
algorithm
  NFConnect2.CONNECTOR(name = outName, ty = ty, cty = cty, attr =
    NFConnect2.CONN_ATTR(variability = var, direction = dir)) := inConnector;
  outTuple := (ty, cty, var, dir);
end makeConnectorTuple;

protected function compatibleConnectors2
  "Helper function to compatibleConnectors3. Calls the different check function."
  input ConnectorTuple inLhsConnector;
  input ConnectorTuple inRhsConnector;
  input TupleErrorInfo inErrorInfo;
protected
  ConnectorStatus cs1, cs2;
algorithm
  cs1 := connectorStatus(inLhsConnector);
  cs2 := connectorStatus(inRhsConnector);
  compatibleConnectors3(inLhsConnector, cs1, inRhsConnector, cs2, inErrorInfo);
end compatibleConnectors2;

protected function connectorStatus
  input ConnectorTuple inConnector;
  output ConnectorStatus outStatus;
algorithm
  outStatus := match(inConnector)
    local
      DAE.Type ty;

    case ((ty, _, _, _)) guard Types.isComplexExpandableConnector(ty)
      then
        EXPANDABLE_CONNECTOR();

    case ((_, NFConnect2.NO_TYPE(), _, _)) then POTENTIALLY_PRESENT();
    else SIMPLE_CONNECTOR();

  end match;
end connectorStatus;

protected function compatibleConnectors3
  "Helper function to compatibleConnectors2. Calls the different check function."
  input ConnectorTuple inLhsConnector;
  input ConnectorStatus inLhsConnectorStatus;
  input ConnectorTuple inRhsConnector;
  input ConnectorStatus inRhsConnectorStatus;
  input TupleErrorInfo inErrorInfo;
algorithm
  _ := match(inLhsConnector, inLhsConnectorStatus, inRhsConnector,
      inRhsConnectorStatus, inErrorInfo)
    local
      DAE.Type lhs_ty, rhs_ty;
      ConnectorType lhs_cty, rhs_cty;
      DAE.VarKind lhs_var, rhs_var;
      DAE.VarDirection lhs_dir, rhs_dir;
      TupleErrorInfo err_info;
      DAE.ComponentRef lhs_cref, rhs_cref;
      SourceInfo info;
      String cref_str1, cref_str2;

    // Both connectors are non-expandable, check them.
    case ((lhs_ty, lhs_cty, lhs_var, lhs_dir), SIMPLE_CONNECTOR(),
        (rhs_ty, rhs_cty, rhs_var, rhs_dir), SIMPLE_CONNECTOR(), err_info)
      equation
        compatibleConnectorTypes(lhs_cty, rhs_cty, err_info);
        compatibleDirection(lhs_dir, rhs_dir, err_info);
        compatibleVariability(lhs_var, lhs_ty, lhs_cty, rhs_var, rhs_ty, rhs_cty, err_info);
        complexConnectorTypeCompatibility(lhs_ty, rhs_ty, err_info);
      then
        ();

    // Both connectors are undeclared, show error.
    case (_, POTENTIALLY_PRESENT(), _, POTENTIALLY_PRESENT(),
        (lhs_cref, rhs_cref, info))
      equation
        cref_str1 = ComponentReference.printComponentRefStr(lhs_cref);
        cref_str2 = ComponentReference.printComponentRefStr(rhs_cref);
        Error.addSourceMessage(Error.UNDECLARED_CONNECTION,
          {cref_str1, cref_str2}, info);
      then
        fail();

    // One of the connectors is only potentially present
    case (_, POTENTIALLY_PRESENT(), _, _, _) then ();
    case (_, _, _, POTENTIALLY_PRESENT(), _) then ();

    // Both connectors are expandable, check them later.
    /*-----------------------------------------------------------------------*/
    // TODO: Check that none of them contains flow components.
    /*-----------------------------------------------------------------------*/
    case (_, EXPANDABLE_CONNECTOR(), _, EXPANDABLE_CONNECTOR(), _) then ();

    // One is expandable and one is non-expandable, show error.
    case (_, _, _, _, (lhs_cref, rhs_cref, info))
      equation
        cref_str1 = ComponentReference.printComponentRefStr(lhs_cref);
        cref_str2 = ComponentReference.printComponentRefStr(rhs_cref);
        (cref_str1, cref_str2) =
          Util.swap(isExpandableStatus(inRhsConnectorStatus), cref_str1, cref_str2);
        Error.addSourceMessage(Error.EXPANDABLE_NON_EXPANDABLE_CONNECTION,
          {cref_str1, cref_str2}, info);
      then
        fail();

  end match;
end compatibleConnectors3;

protected function isExpandableStatus
  input ConnectorStatus inConnectorStatus;
  output Boolean outIsExpandable;
algorithm
  outIsExpandable := match(inConnectorStatus)
    case EXPANDABLE_CONNECTOR() then true;
    else false;
  end match;
end isExpandableStatus;

protected function compatibleConnectorTypes
  "Check that two connector types (flow/stream) are compatible with each other,
   i.e. that they are equal. Anything else is an error."
  input ConnectorType inLhsType;
  input ConnectorType inRhsType;
  input TupleErrorInfo inErrorInfo;
algorithm
  _ := match(inLhsType, inRhsType, inErrorInfo)
    local
      DAE.ComponentRef lhs_cref, rhs_cref;
      SourceInfo info;
      String cref_str1, cref_str2, cty_str1, cty_str2;
      list<String> err_strl;

    // Equal connector types => ok.
    case (_, _, _) guard NFConnectUtil2.connectorTypeEqual(inLhsType, inRhsType)
      then
        ();

    // Nonequal connector types => error.
    case (_, _, (lhs_cref, rhs_cref, info))
      equation
        cref_str1 = ComponentReference.printComponentRefStr(lhs_cref);
        cref_str2 = ComponentReference.printComponentRefStr(rhs_cref);
        cty_str1 = NFConnectUtil2.unparseConnectorType(inLhsType);
        cty_str2 = NFConnectUtil2.unparseConnectorType(inRhsType);
        err_strl = if NFConnectUtil2.isPotential(inLhsType)
          then {cty_str2, cref_str2, cref_str1}
          else {cty_str1, cref_str1, cref_str2};
        Error.addSourceMessage(Error.CONNECT_PREFIX_MISMATCH, err_strl, info);
      then
        fail();

  end match;
end compatibleConnectorTypes;

protected function compatibleDirection
  "Check that two connector directions are compatible, i.e. that either none or
   both of them have an input/output prefix."
  input DAE.VarDirection inLhsDirection;
  input DAE.VarDirection inRhsDirection;
  input TupleErrorInfo inErrorInfo;
algorithm
  _ := match(inLhsDirection, inRhsDirection, inErrorInfo)
    local
      DAE.ComponentRef lhs_cref, rhs_cref;
      String cref_str1, cref_str2, dir_str1, dir_str2;
      list<String> err_strl;
      SourceInfo info;

    // None or both are input/output => ok.
    case (_, _, _) guard boolEq(DAEUtil.isBidirVarDirection(inLhsDirection),
                                DAEUtil.isBidirVarDirection(inRhsDirection))
      then
        ();

    // One is input/output, the other bidirectional => error.
    case (_, _, (lhs_cref, rhs_cref, info))
      equation
        cref_str1 = ComponentReference.printComponentRefStr(lhs_cref);
        cref_str2 = ComponentReference.printComponentRefStr(rhs_cref);
        dir_str1 = DAEDump.unparseVarDirection(inLhsDirection);
        dir_str2 = DAEDump.unparseVarDirection(inRhsDirection);
        err_strl = if DAEUtil.isBidirVarDirection(inLhsDirection)
          then {dir_str2, cref_str2, cref_str1}
          else {dir_str1, cref_str1, cref_str2};
        Error.addSourceMessage(Error.CONNECT_PREFIX_MISMATCH, err_strl, info);
      then
        fail();

  end match;
end compatibleDirection;

public function compatibleVariability
  "Checks that the variability of two connectors are compatible, and also that
   the variability of each connector is valid considering the type and connector
   type of the connector."
  input DAE.VarKind inLhsVariability;
  input DAE.Type inLhsType;
  input ConnectorType inLhsConnectorType;
  input DAE.VarKind inRhsVariability;
  input DAE.Type inRhsType;
  input ConnectorType inRhsConnectorType;
  input TupleErrorInfo inErrorInfo;
algorithm
  _ := match(inLhsVariability, inLhsType, inLhsConnectorType,
      inRhsVariability, inRhsType, inRhsConnectorType, inErrorInfo)
    local
      Boolean ipc;
      DAE.ComponentRef lhs_cref, rhs_cref;
      SourceInfo info;
      ConnectorType lhs_cty, rhs_cty;
      DAE.VarKind lhs_var, rhs_var;

    case (lhs_var, _, lhs_cty, rhs_var, _, rhs_cty, (lhs_cref, rhs_cref, info))
      equation
        ipc = connectorVariabilityEq(lhs_var, rhs_var, inErrorInfo);
        compatibleVariability2(ipc, inLhsType, lhs_cty, lhs_var, lhs_cref, info);
        compatibleVariability2(ipc, inRhsType, rhs_cty, rhs_var, rhs_cref, info);
      then
        ();

  end match;
end compatibleVariability;

protected function connectorVariabilityEq
  "Checks that the variability of two connectors are compatiable. Returns true
   of both of them are parameter/constant, false if neither is, and otherwise
   fails with an error message."
  input DAE.VarKind inVariability1;
  input DAE.VarKind inVariability2;
  input TupleErrorInfo inErrorInfo;
  output Boolean outIsParamOrConst;
algorithm
  outIsParamOrConst := matchcontinue(inVariability1, inVariability2, inErrorInfo)
    local
      Boolean ipc1, ipc2;
      DAE.ComponentRef cref1, cref2;
      SourceInfo info;
      String lhs_str, rhs_str, lhs_var_str, rhs_var_str;
      list<String> tokens;

    // Both must be either constant/parameter or non-constant/parameter.
    case (_, _, _)
      equation
        ipc1 = DAEUtil.isParamOrConstVarKind(inVariability1);
        ipc2 = DAEUtil.isParamOrConstVarKind(inVariability2);
        true = boolEq(ipc1, ipc2);
      then
        ipc1;

    // Different variability => error.
    case (_, _, (cref1, cref2, info))
      equation
        lhs_str = ComponentReference.printComponentRefStr(cref1);
        rhs_str = ComponentReference.printComponentRefStr(cref2);
        lhs_var_str = DAEDump.unparseVarKind(inVariability1);
        rhs_var_str = DAEDump.unparseVarKind(inVariability2);
        tokens = if DAEUtil.isParamOrConstVarKind(inVariability1)
          then {lhs_var_str, lhs_str, rhs_str}
          else {rhs_var_str, rhs_str, lhs_str};
        Error.addSourceMessage(Error.INCOMPATIBLE_CONNECTOR_VARIABILITY,
          tokens, info);
      then
        fail();

  end matchcontinue;
end connectorVariabilityEq;

protected function compatibleVariability2
  "Helper function to compatibleVariability, check that the variability is
   compatible with the type and connector type of a connector."
  input Boolean inIsParamOrConst;
  input DAE.Type inType;
  input ConnectorType inConnectorType;
  input DAE.VarKind inVariability;
  input DAE.ComponentRef inCref;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inIsParamOrConst, inType, inConnectorType,
      inVariability, inCref, inInfo)
    local
      String cref_str, var_str, cty_str;

    // A connector which is a variable can be whatever it wants to be.
    case (false, _, _, _, _, _) then ();

    // A connector which is constant/parameter should be non-complex and
    // potential.
    case (true, _, _, _, _, _)
      equation
        false = Types.isComplexConnector(inType);
        true = NFConnectUtil2.isPotential(inConnectorType);
      then
        ();

    // A connector which is constant/parameter and complex is an error.
    case (true, _, _, _, _, _)
      equation
        true = Types.isComplexConnector(inType);
        cref_str = ComponentReference.printComponentRefStr(inCref);
        var_str = DAEDump.unparseVarKind(inVariability);
        Error.addSourceMessage(Error.INVALID_COMPLEX_CONNECTOR_VARIABILITY,
          {cref_str, var_str}, inInfo);
      then
        fail();

    // A connector which is constant/parameter and not potential is an error.
    case (true, _, _, _, _, _)
      equation
        false = NFConnectUtil2.isPotential(inConnectorType);
        cref_str = ComponentReference.printComponentRefStr(inCref);
        var_str = DAEDump.unparseVarKind(inVariability);
        cty_str = NFConnectUtil2.unparseConnectorType(inConnectorType);
        Error.addSourceMessage(Error.INVALID_CONNECTOR_PREFIXES,
          {cref_str, var_str, cty_str}, inInfo);
      then
        fail();

  end matchcontinue;
end compatibleVariability2;

protected function complexConnectorTypeCompatibility
  "Checks that two complex connectors defined by DAE.Type are compatible."
  input DAE.Type inLhsType;
  input DAE.Type inRhsType;
  input TupleErrorInfo inErrorInfo;
algorithm
  _ := match(inLhsType, inRhsType, inErrorInfo)
    local
      list<DAE.Var> vars1, vars2;

    // Two complex connectors, check their components.
    case (DAE.T_COMPLEX(varLst = vars1), DAE.T_COMPLEX(varLst = vars2), _)
      equation
        _ = List.threadMap1(vars1, vars2, varConnectorTypeCompatibility, inErrorInfo);
      then
        ();

    // Non-complex connectors, nothing to do.
    else ();

  end match;
end complexConnectorTypeCompatibility;

protected function varConnectorTypeCompatibility
  "Checks that two connector elements defined by DAE.Var are compatible."
  input DAE.Var inLhsVar;
  input DAE.Var inRhsVar;
  input TupleErrorInfo inErrorInfo;
  output Integer outDummy;
algorithm
  outDummy := match(inLhsVar, inRhsVar, inErrorInfo)
    local
      DAE.ComponentRef lhs_cref, rhs_cref;
      ConnectorTuple lhs_conn, rhs_conn;
      SourceInfo info;
      TupleErrorInfo err_info;

    case (_, _, (lhs_cref, rhs_cref, info))
      equation
        (lhs_cref, lhs_conn) = varConnectorTuple(inLhsVar, lhs_cref);
        (rhs_cref, rhs_conn) = varConnectorTuple(inRhsVar, rhs_cref);
        err_info = (lhs_cref, rhs_cref, info);
        compatibleConnectors2(lhs_conn, rhs_conn, err_info);
      then
        0;

  end match;
end varConnectorTypeCompatibility;

protected function varConnectorTuple
  "Helper function to varConnectorTypeCompatibility, extracts the relevant
   fields from a DAE.Var."
  input DAE.Var inVar;
  input DAE.ComponentRef inPrefix;
  output DAE.ComponentRef outName;
  output ConnectorTuple outTuple;
protected
  DAE.Ident name;
  DAE.Type ty;
  SCode.ConnectorType scty;
  ConnectorType cty;
  SCode.Variability svar;
  DAE.VarKind var;
  Absyn.Direction adir;
  DAE.VarDirection dir;
algorithm
  DAE.TYPES_VAR(name = name, ty = ty, attributes = DAE.ATTR(
    connectorType = scty, variability = svar, direction = adir)) := inVar;
  cty := NFConnectUtil2.translateSCodeConnectorType(scty);
  var := NFInstUtil.translateVariability(svar);
  dir := NFInstUtil.translateDirection(adir);
  // Prefix the name with the given prefix.
  outName := ComponentReference.crefPrependIdent(inPrefix, name, {}, ty);
  outTuple := (ty, cty, var, dir);
end varConnectorTuple;

annotation(__OpenModelica_Interface="frontend");
end NFConnectCheck;

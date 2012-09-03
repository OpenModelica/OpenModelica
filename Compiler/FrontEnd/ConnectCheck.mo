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

encapsulated package ConnectCheck
" file:        ConnectCheck.mo
  package:     ConnectCheck
  description: Connection checking functions

  RCS: $Id$
"

public import Absyn;
public import Connect2;
public import DAE;

protected import ComponentReference;
protected import ConnectUtil2;
protected import Error;
protected import List;
protected import SCode;
protected import Types;
protected import Util;

public type Connections = Connect2.Connections;
public type Connection = Connect2.Connection;
public type Connector = Connect2.Connector;
public type ConnectorType = Connect2.ConnectorType;
public type Face = Connect2.Face;
public type Root = Connect2.Root;

public function crefIsValidNode
  "A node given as argument to branch, root or potentialRoot must be on the form
   A.R, where A is a connector and R and overdetermined type/record. This
   function checks that a cref is a valid node."
  input DAE.ComponentRef inNode;
  input String inFuncName;
  input Boolean isFirst;
  input Absyn.Info inInfo;
algorithm
  _ := match(inNode, inFuncName, isFirst, inInfo)
    local
      DAE.Type ty1, ty2;
      
    // TODO: This is actually not working as it should, since the cref will have
    // been prefixed already. Need to check this before prefixing somehow.
    case (DAE.CREF_QUAL(identType = ty1, 
        componentRef = DAE.CREF_IDENT(identType = ty2)), _, _, _)
      equation
        crefIsValidNode2(ty1, ty2, inFuncName, isFirst, inInfo);
      then
        ();

    else
      equation
        Error.addSourceMessage(Util.if_(isFirst,Error.INVALID_ARGUMENT_TYPE_BRANCH_FIRST,Error.INVALID_ARGUMENT_TYPE_BRANCH_SECOND), {inFuncName}, inInfo);
      then
        ();

  end match;
end crefIsValidNode;

protected function crefIsValidNode2
  input DAE.Type inType1;
  input DAE.Type inType2;
  input String inFuncName;
  input Boolean isFirst;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inType1, inType2, inFuncName, isFirst, inInfo)
    case (_, _, _, _, _)
      equation
        true = Types.isComplexConnector(inType1);
        true = Types.isOverdeterminedType(inType2);
      then
        ();

    else
      equation
        Error.addSourceMessage(Util.if_(isFirst,Error.INVALID_ARGUMENT_TYPE_OVERDET_FIRST,Error.INVALID_ARGUMENT_TYPE_OVERDET_SECOND),
          {inFuncName}, inInfo);
      then
        fail();

  end matchcontinue;
end crefIsValidNode2;

public function connectorCompatibility
  input DAE.ComponentRef inLhsName;
  input ConnectorType inLhsType;
  input DAE.ComponentRef inRhsName;
  input ConnectorType inRhsType;
  input Absyn.Info inInfo;
protected
  ConnectorType lhs_cty, rhs_cty;
  DAE.Type lhs_ty, rhs_ty;
algorithm
  connectorTypeCompatibility(inLhsType, inRhsType, inLhsName, inRhsName, inInfo);
  lhs_ty := ComponentReference.crefLastType(inLhsName);
  rhs_ty := ComponentReference.crefLastType(inRhsName);
  complexConnectorTypeCompatibility(lhs_ty, rhs_ty, inLhsName, inRhsName, inInfo);
end connectorCompatibility;
        
protected function connectorTypeCompatibility
  input ConnectorType inLhsType;
  input ConnectorType inRhsType;
  input DAE.ComponentRef inLhsName;
  input DAE.ComponentRef inRhsName;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inLhsType, inRhsType, inLhsName, inRhsName, inInfo)
    local
      String cref_str1, cref_str2, cty_str1, cty_str2;
      list<String> err_strl;

    case (_, _, _, _, _)
      equation
        true = ConnectUtil2.connectorTypeEqual(inLhsType, inRhsType);
      then
        ();

    else
      equation
        cref_str1 = ComponentReference.printComponentRefStr(inLhsName);
        cref_str2 = ComponentReference.printComponentRefStr(inRhsName);
        cty_str1 = ConnectUtil2.connectorTypeStr(inLhsType);
        cty_str2 = ConnectUtil2.connectorTypeStr(inRhsType);
        err_strl = Util.if_(ConnectUtil2.isPotential(inLhsType),
          {cty_str2, cref_str2, cref_str1}, {cty_str1, cref_str1, cref_str2});
        Error.addSourceMessage(Error.CONNECT_PREFIX_MISMATCH, err_strl, inInfo);
      then
        fail();

  end matchcontinue;
end connectorTypeCompatibility;

protected function complexConnectorTypeCompatibility
  input DAE.Type inLhsType;
  input DAE.Type inRhsType;
  input DAE.ComponentRef inLhsName;
  input DAE.ComponentRef inRhsName;
  input Absyn.Info inInfo;
algorithm
  _ := match(inLhsType, inRhsType, inLhsName, inRhsName, inInfo)
    local
      list<DAE.Var> vars1, vars2;
      
    case (DAE.T_COMPLEX(varLst = vars1), DAE.T_COMPLEX(varLst = vars2), _, _, _)
      equation
        _ = List.threadMap3(vars1, vars2, varConnectorTypeCompatibility,
          inLhsName, inRhsName, inInfo);
      then
        ();

    else ();

  end match;
end complexConnectorTypeCompatibility;

protected function varConnectorTypeCompatibility
  input DAE.Var inLhsVar;
  input DAE.Var inRhsVar;
  input DAE.ComponentRef inLhsName;
  input DAE.ComponentRef inRhsName;
  input Absyn.Info inInfo;
  output Integer outDummy;
algorithm
  outDummy := match(inLhsVar, inRhsVar, inLhsName, inRhsName, inInfo)
    local
      SCode.ConnectorType lhs_scty, rhs_scty;
      ConnectorType lhs_cty, rhs_cty;
      DAE.Type lhs_ty, rhs_ty;
      DAE.Ident lhs_name, rhs_name;
      DAE.ComponentRef lhs_cref, rhs_cref;

    case (DAE.TYPES_VAR(name = lhs_name, ty = lhs_ty, attributes =
            DAE.ATTR(connectorType = lhs_scty)),
          DAE.TYPES_VAR(name = rhs_name, ty = rhs_ty, attributes =
            DAE.ATTR(connectorType = rhs_scty)), _, _, _)
      equation
        lhs_cty = ConnectUtil2.translateSCodeConnectorType(lhs_scty);
        rhs_cty = ConnectUtil2.translateSCodeConnectorType(rhs_scty);
        lhs_cref = ComponentReference.crefPrependIdent(inLhsName, lhs_name, {}, lhs_ty);
        rhs_cref = ComponentReference.crefPrependIdent(inRhsName, rhs_name, {}, rhs_ty);
        connectorTypeCompatibility(lhs_cty, rhs_cty, lhs_cref, rhs_cref, inInfo);
        complexConnectorTypeCompatibility(lhs_ty, rhs_ty, lhs_cref, rhs_cref, inInfo);
      then
        0;

  end match;
end varConnectorTypeCompatibility;
      
end ConnectCheck;

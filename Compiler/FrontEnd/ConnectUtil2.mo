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
" file:        Connect.mo
  package:     Connect
  description: Connection set utility functions

  RCS: $Id$
"

public import Absyn;
public import Connect2;
public import DAE;
public import Types;

protected import Error;

public type Connections = Connect2.Connections;
public type Connection = Connect2.Connection;
public type Connector = Connect2.Connector;
public type Face = Connect2.Face;
public type Root = Connect2.Root;

public function makeBranch
  input DAE.ComponentRef inNode1;
  input DAE.ComponentRef inNode2;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  checkCrefIsValidNode(inNode1, "Connections.branch", "first ", inInfo);
  checkCrefIsValidNode(inNode2, "Connections.branch", "second ", inInfo);
  outConnections := Connect2.NO_CONNECTIONS();
end makeBranch;

public function makeRoot
  input DAE.ComponentRef inNode;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  checkCrefIsValidNode(inNode, "Connections.root", "", inInfo);
  outConnections := Connect2.NO_CONNECTIONS();
end makeRoot;

public function makePotentialRoot
  input DAE.ComponentRef inNode;
  input DAE.Exp inPriority;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  checkCrefIsValidNode(inNode, "Connections.potentialRoot", "", inInfo);
  outConnections := Connect2.NO_CONNECTIONS();
end makePotentialRoot;

protected function checkCrefIsValidNode
  "A node given as argument to branch, root or potentialRoot must be on the form
   A.R, where A is a connector and R and overdetermined type/record. This
   function checks that a cref is a valid node."
  input DAE.ComponentRef inNode;
  input String inFuncName;
  input String inArgNumber;
  input Absyn.Info inInfo;
algorithm
  _ := match(inNode, inFuncName, inArgNumber, inInfo)
    local
      DAE.Type ty1, ty2;
      
    // TODO: This is actually not working as it should, since the cref will have
    // been prefixed already. Need to check this before prefixing somehow.
    case (DAE.CREF_QUAL(identType = ty1, 
        componentRef = DAE.CREF_IDENT(identType = ty2)), _, _, _)
      equation
        checkCrefIsValidNode2(ty1, ty2, inFuncName, inArgNumber, inInfo);
      then
        ();

    else
      equation
        Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE, {inArgNumber, inFuncName,
        "on the form A.R, where A is a connector and R an overdetermined type/record."}, inInfo);
      then
        fail();

  end match;
end checkCrefIsValidNode;

protected function checkCrefIsValidNode2
  input DAE.Type inType1;
  input DAE.Type inType2;
  input String inFuncName;
  input String inArgNumber;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inType1, inType2, inFuncName, inArgNumber, inInfo)
    case (_, _, _, _, _)
      equation
        true = Types.isComplexConnector(inType1);
        true = Types.isOverdeterminedType(inType2);
      then
        ();

    else
      equation
        Error.addSourceMessage(Error.INVALID_ARGUMENT_TYPE,
          {inArgNumber, inFuncName, "an overdetermined type or record"}, inInfo);
      then
        fail();

  end matchcontinue;
end checkCrefIsValidNode2;

protected function makeConnector
  input DAE.ComponentRef inName;
  input Face inFace;
  output Connector outConnector;
algorithm
  outConnector := Connect2.CONNECTOR(inName, inFace);
end makeConnector;

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
  input DAE.ComponentRef inRhsName;
  input Face inRhsFace;
  input Absyn.Info inInfo;
  input Connections inConnections;
  output Connections outConnections;
algorithm
  outConnections := match(inIsDeleted, inLhsName, inLhsFace, inRhsName,
      inRhsFace, inInfo, inConnections)
    case (true, _, _, _, _, _, _) then inConnections;

    else addConnection(inLhsName, inLhsFace, inRhsName, inRhsFace, inInfo,
      inConnections);

  end match;
end addConnectionCond;

public function addConnection
  input DAE.ComponentRef inLhsName;
  input Face inLhsFace;
  input DAE.ComponentRef inRhsName;
  input Face inRhsFace;
  input Absyn.Info inInfo;
  input Connections inConnections;
  output Connections outConnections;
protected
  Connector lhs, rhs;
  Connection conn;
algorithm
  lhs := makeConnector(inLhsName, inLhsFace);
  rhs := makeConnector(inRhsName, inRhsFace);
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

end ConnectUtil2;

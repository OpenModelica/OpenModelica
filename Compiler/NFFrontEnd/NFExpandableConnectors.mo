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

encapsulated package NFExpandableConnectors
" file:        NFExpandableConnectors.mo
  package:     NFExpandableConnectors
  description: NFExpandableConnectors translates Absyn to SCode intermediate form


  This module contains functions to handle expandable connectors:

PHASE_1
  A partial instantiation (only components) from all classes appearing in
  connect(expandable, non-expandable) should be done first in their correct
  environment. This should be done without flattening of arrays or structural
  components because you need to go from an instantiated component in the environment
  back to an SCode.COMPONENT definition.

PHASE_2
  The connect equations referring to expandable connectors should be collected.
  The expandable connectors should be patched with the new components from connects
  (that connect(expandable, non-expandable))

PHASE_3
  The expandable connectors should be patched so that a union of all expandable connectors
  connected via connect(expandable, expandable) is achieved.

PHASE_4
  The expandable connectors should be patched so that a union of all expandable connectors
  connected via inner-outer is achieved.

PHASE_5
  Generate a new program that has the new expandable connectors."

public import NFConnect2;

protected import Absyn;
protected import ClassInf;
protected import ComponentReference;
protected import NFConnectionSets;
protected import NFConnectUtil2;
protected import DAE;
protected import Error;
protected import NFInstUtil;
protected import List;
protected import SCode;
protected import Util;

public type Connection = NFConnect2.Connection;
public type Connector = NFConnect2.Connector;
public type ConnectorType = NFConnect2.ConnectorType;
public type ConnectorAttr = NFConnect2.ConnectorAttr;
public type Face = NFConnect2.Face;

protected type DisjointSets = NFConnectionSets.DisjointSets;

public function elaborate
  input list<Connection> inConnections;
  output list<Connection> outConnections;
algorithm
  outConnections := matchcontinue(inConnections)
    local
      list<Connection> expl, nonexpl, connl;
      list<list<Connector>> expsets;
      DisjointSets sets;

    case ({}) then inConnections;

    case (_)
      equation
        (expl, nonexpl) = List.splitOnTrue(inConnections, isExpandableConnection);
        // TODO: Better set size?
        sets = NFConnectionSets.emptySets(listLength(inConnections));
        sets = List.fold(expl, NFConnectionSets.expandAddConnection, sets);
        (nonexpl, sets) = List.mapFold(nonexpl, elaborateNonExpandable, sets);

        expsets = NFConnectionSets.extractSets(sets);
        sets = List.fold(expsets, elaborateExpandable, sets);
        (expl, _) = List.mapFold(expl, updateExpandableConnection, sets);

        connl = listAppend(nonexpl, expl);
      then
        connl;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Elaboration of expandable connectors failed!."});
      then
        fail();

  end matchcontinue;
end elaborate;

protected function isExpandableConnection
  input Connection inConnection;
  output Boolean outIsExpandable;
protected
  Connector lhs, rhs;
algorithm
  NFConnect2.CONNECTION(lhs = lhs, rhs = rhs) := inConnection;
  outIsExpandable := NFConnectUtil2.isExpandableConnector(lhs) and
                     NFConnectUtil2.isExpandableConnector(rhs);
end isExpandableConnection;

protected function elaborateNonExpandable
  input Connection inConnection;
  input DisjointSets inSets;
  output Connection outConnection;
  output DisjointSets outSets;
protected
  Connector conn1, conn2;
  SourceInfo info;
  Boolean ipp;
algorithm
  NFConnect2.CONNECTION(lhs = conn1, rhs = conn2, info = info) := inConnection;
  // Assume that only one of the connectors can be undeclared (since it's
  // checked during typing), and swap them if it's the second one so that we
  // always get the same order.
  ipp := NFConnectUtil2.isUndeclaredConnector(conn2);
  (conn1, conn2) := Util.swap(ipp, conn1, conn2);
  (conn1, outSets) := elaborateNonExpandable2(conn1, conn2, info, inSets);
  outConnection := NFConnect2.CONNECTION(conn1, conn2, info);
end elaborateNonExpandable;

protected function elaborateNonExpandable2
  input Connector inUndeclared;
  input Connector inDeclared;
  input SourceInfo inInfo;
  input DisjointSets inSets;
  output Connector outNewConnector;
  output DisjointSets outSets;
algorithm
  (outNewConnector, outSets) := match(inUndeclared, inDeclared, inInfo, inSets)
    local
      DAE.ComponentRef name, exp_name;
      DisjointSets sets;
      Connector exp_conn, new_conn;

    case (NFConnect2.CONNECTOR(name = name), _, _, sets)
      equation
        // Look up the parent of the undeclared connector in the sets.
        // Do we need to care about face here?
        (exp_name, _) = ComponentReference.splitCrefLast(name);
        (exp_conn, sets) = findConnectorByName(exp_name, sets);

        // Augment the expandable connector with a new component with the same
        // name as the undeclared but the same attributes as the declared, if
        // it doesn't already exist.
        (exp_conn, new_conn) = augmentConnector(exp_conn, name, inDeclared);

        // Update the expandable connector in the sets with the new value.
        sets = NFConnectionSets.update(exp_conn, sets);
      then
        (new_conn, sets);

  end match;
end elaborateNonExpandable2;

protected function findConnectorByName
  input DAE.ComponentRef inName;
  input DisjointSets inSets;
  output Connector outExpandableConnector;
  output DisjointSets outSets;
protected
  Connector conn;
  DAE.Type ty;
algorithm
  //ty := ComponentReference.crefLastType(inName);
  ty := DAE.T_UNKNOWN_DEFAULT;
  conn := NFConnect2.CONNECTOR(inName, ty, NFConnect2.OUTSIDE(), NFConnect2.NO_TYPE(),
    NFConnect2.DEFAULT_ATTR);
  (outExpandableConnector, outSets) := NFConnectionSets.findConnector(conn, inSets);
end findConnectorByName;

protected function augmentConnector
  input Connector inExpandable;
  input DAE.ComponentRef inUndeclaredName;
  input Connector inDeclared;
  output Connector outExpandable;
  output Connector outNewConnector;
algorithm
  (outExpandable, outNewConnector) :=
  match(inExpandable, inUndeclaredName, inDeclared)
    local
      DAE.ComponentRef exp_name;
      DAE.Type exp_ty;
      Face exp_face;
      ConnectorType exp_cty;
      ConnectorAttr exp_attr;
      DAE.Var var;
      Connector exp_conn, conn;

    case (NFConnect2.CONNECTOR(exp_name, exp_ty, exp_face, exp_cty, exp_attr), _, _)
      equation
        (conn, var) = makeNewConnector(inUndeclaredName, inDeclared);
        exp_ty = augmentType(var, exp_ty);
        exp_conn = NFConnect2.CONNECTOR(exp_name, exp_ty, exp_face, exp_cty, exp_attr);
      then
        (exp_conn, conn);

  end match;
end augmentConnector;

protected function makeNewConnector
  input DAE.ComponentRef inUndeclaredName;
  input Connector inDeclared;
  output Connector outConnector;
  output DAE.Var outVar;
algorithm
  (outConnector, outVar) := match(inUndeclaredName, inDeclared)
    local
      DAE.ComponentRef name;
      Connector conn;
      DAE.Var var;

    case (_, NFConnect2.CONNECTOR())
      equation
        conn = NFConnectUtil2.renameConnector(inUndeclaredName, inDeclared);
        name = ComponentReference.crefLastCref(inUndeclaredName);
        var = connectorToVar(name, conn);
      then
        (conn, var);

  end match;
end makeNewConnector;

protected function connectorToVar
  input DAE.ComponentRef inNewName;
  input Connector inConnector;
  output DAE.Var outVar;
algorithm
  outVar := match(inNewName, inConnector)
    local
      DAE.Ident id;
      DAE.Attributes attr;
      DAE.Type ty;
      ConnectorType cty;
      DAE.VarKind var;
      DAE.VarVisibility vis;
      DAE.VarDirection dir;
      SCode.ConnectorType scty;
      SCode.Variability svar;
      Absyn.Direction adir;
      SCode.Visibility svis;

    case (DAE.CREF_IDENT(ident = id, subscriptLst = {}),
        NFConnect2.CONNECTOR(ty = ty, cty = cty,
          attr = NFConnect2.CONN_ATTR(var, vis, dir)))
      equation
        scty = NFConnectUtil2.translateConnectorTypeToSCode(cty);
        svar = NFInstUtil.daeToSCodeVariability(var);
        adir = NFInstUtil.daeToAbsynDirection(dir);
        svis = NFInstUtil.daeToSCodeVisibility(vis);
        attr = DAE.ATTR(scty, SCode.NON_PARALLEL(), svar, adir,
          Absyn.NOT_INNER_OUTER(), svis);
      then
        DAE.TYPES_VAR(id, attr, ty, DAE.UNBOUND(), NONE());

  end match;
end connectorToVar;

protected function augmentType
  input DAE.Var inVar;
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inVar, inType)
    local
      ClassInf.State state;
      list<DAE.Var> vars;
      DAE.EqualityConstraint eq;
      DAE.TypeSource source;

    case (_, DAE.T_COMPLEX(state, vars, eq, source))
      equation
        /*********************************************************************/
        // Check if the variable already exists or not.
        /*********************************************************************/
        vars = inVar :: vars;
      then
        DAE.T_COMPLEX(state, vars, eq, source);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFExpandableConnectors.augmentType got an unknown type."});
      then
        fail();

  end match;
end augmentType;

protected function elaborateExpandable
  input list<Connector> inSet;
  input DisjointSets inSets;
  output DisjointSets outSets;
algorithm
  outSets := match(inSet, inSets)
    local
      list<DAE.Var> vars;
      list<Connector> connl;
      DisjointSets sets;

    case (_, sets)
      equation
        print("1\n");
        // Extract a list of all variables that should be merged, together with info.
        /*********************************************************************/
        // TODO: Propagate info here so that we can print good errors.
        /*********************************************************************/
        vars = List.mapFlat(inSet, extractVarsFromConnector);
        print("2\n");

        // Merge the variables into one set of unique variables.
        /*********************************************************************/
        // TODO: Implement this.
        /*********************************************************************/

        // Update the type of all connectors to have the same type (what about
        // input/output?)
        connl = List.map1(inSet, updateExpandableConnectorType, vars);
        print("3\n");
        // Update the connectors in the sets.
        sets = List.fold(connl, NFConnectionSets.update, sets);
        print("4\n");
      then
        sets;

  end match;
end elaborateExpandable;

protected function extractVarsFromConnector
  input Connector inConnector;
  output list<DAE.Var> outVars;
algorithm
  outVars := match(inConnector)
    local
      list<DAE.Var> vars;

    case NFConnect2.CONNECTOR(ty = DAE.T_COMPLEX(varLst = vars)) then vars;
    else
      equation
        print("Got unknown type in NFExpandableConnectors.extractVarsFromConnector.\n");
      then
        fail();

  end match;
end extractVarsFromConnector;

protected function updateExpandableConnectorType
  input Connector inConnector;
  input list<DAE.Var> inVars;
  output Connector outConnector;
algorithm
  outConnector := match(inConnector, inVars)
    local
      ClassInf.State state;
      DAE.EqualityConstraint eq;
      DAE.TypeSource source;
      DAE.Type ty;

    case (NFConnect2.CONNECTOR(ty = DAE.T_COMPLEX(state, _, eq, source)), _)
      equation
        ty = DAE.T_COMPLEX(state, inVars, eq, source);
      then
        NFConnectUtil2.updateConnectorType(ty, inConnector);

  end match;
end updateExpandableConnectorType;

protected function updateExpandableConnection
  input Connection inConnection;
  input DisjointSets inSets;
  output Connection outConnection;
  output DisjointSets outSets;
algorithm
  (outConnection, outSets) := match(inConnection, inSets)
    local
      Connector lhs, rhs;
      SourceInfo info;
      DisjointSets sets;

    case (NFConnect2.CONNECTION(lhs, rhs, info), sets)
      equation
        (lhs, sets) = NFConnectionSets.findConnector(lhs, sets);
        (rhs, sets) = NFConnectionSets.findConnector(rhs, sets);
      then
        (NFConnect2.CONNECTION(lhs, rhs, info), sets);

  end match;
end updateExpandableConnection;

annotation(__OpenModelica_Interface="frontend");
end NFExpandableConnectors;

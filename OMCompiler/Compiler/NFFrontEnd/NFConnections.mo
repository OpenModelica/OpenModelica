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

encapsulated uniontype NFConnections
  import Connection = NFConnection;
  import Connector = NFConnector;
  import FlatModel = NFFlatModel;
  import ComponentRef = NFComponentRef;
  import Equation = NFEquation;

protected
  import Connections = NFConnections;
  import ElementSource;
  import ExpandExp = NFExpandExp;
  import Expression = NFExpression;
  import Flags;
  import MetaModelica.Dangerous.listReverseInPlace;
  import Component = NFComponent;
  import NFInstNode.InstNode;
  import Type = NFType;

public
  type BrokenEdge = tuple<ComponentRef, ComponentRef, list<Equation>>;
  type BrokenEdges = list<BrokenEdge>;

  record CONNECTIONS
    list<Connection> connections;
    list<Connector> flows;
    BrokenEdges broken;
  end CONNECTIONS;

  function new
    output Connections conns = CONNECTIONS({}, {}, {});
  end new;

  function fromConnectionList
    input list<Connection> connl;
    output Connections conns;
  algorithm
    conns := CONNECTIONS(connl, {}, {});
  end fromConnectionList;

  function addConnection
    input Connection conn;
    input output Connections conns;
  algorithm
    conns.connections := conn :: conns.connections;
  end addConnection;

  function addFlow
    input Connector conn;
    input output Connections conns;
  algorithm
    conns.flows := conn :: conns.flows;
  end addFlow;

  function addBroken
    input BrokenEdges broken;
    input output Connections conns;
  algorithm
    conns.broken := broken;
  end addBroken;

  function collect
    input output FlatModel flatModel;
    input IsDeleted isDeleted;
          output Connections conns = new();

    partial function IsDeleted
      input ComponentRef cref;
      output Boolean res;
    end IsDeleted;
  protected
    Component comp;
    ComponentRef cr, lhs, rhs;
    Connector c1, c2;
    DAE.ElementSource source;
    list<Equation> eql = {};
    list<Connector> cl1, cl2;
    Expression e1, e2;
    Type ty1, ty2;
    Boolean b1, b2;
  algorithm
    // Collect all flow variables.
    for var in flatModel.variables loop
      comp := InstNode.component(ComponentRef.node(var.name));

      if Component.isFlow(comp) then
        c1 := Connector.fromFacedCref(var.name, var.ty,
          NFConnector.Face.INSIDE, ElementSource.createElementSource(Component.info(comp)));
        conns := addFlow(c1, conns);
      end if;
    end for;

    // Collect all connects.
    for eq in flatModel.equations loop
      eql := match eq
        case Equation.CONNECT(lhs = Expression.CREF(ty = ty1, cref = lhs),
                              rhs = Expression.CREF(ty = ty2, cref = rhs), source = source)
          algorithm
            lhs := ComponentRef.evaluateSubscripts(lhs);
            rhs := ComponentRef.evaluateSubscripts(rhs);
            conns.connections := makeConnections(lhs, ty1, rhs, ty2, source, isDeleted, conns.connections);
          then
            eql;

        else eq :: eql;
      end match;
    end for;

    if not listEmpty(conns.connections) then
      flatModel.equations := listReverseInPlace(eql);
    end if;
  end collect;

  function makeConnections
    input ComponentRef lhsCref;
    input Type lhsType;
    input ComponentRef rhsCref;
    input Type rhsType;
    input DAE.ElementSource source;
    input IsDeleted isDeleted;
    input output list<Connection> connections = {};

    partial function IsDeleted
      input ComponentRef cref;
      output Boolean res;
    end IsDeleted;
  protected
    list<Connector> cl1, cl2;
    Connector c2;
  algorithm
    if isDeleted(lhsCref) or isDeleted(rhsCref) then
      return;
    end if;

    cl1 := makeConnectors(lhsCref, lhsType, source);
    cl2 := makeConnectors(rhsCref, rhsType, source);

    for c1 in cl1 loop
      c2 :: cl2 := cl2;

      if not (isDeleted(c1.name) or isDeleted(c2.name)) then
        connections := Connection.CONNECTION(c1, c2) :: connections;
      end if;
    end for;
  end makeConnections;

  function makeConnectors
    input ComponentRef cref;
    input Type ty;
    input DAE.ElementSource source;
    output list<Connector> connectors;
  protected
    Expression cref_exp;
    ComponentRef cr;
    Boolean expanded;
  algorithm
    if not Flags.isSet(Flags.NF_SCALARIZE) then
      connectors := {Connector.fromCref(cref, ComponentRef.getSubscriptedType(cref), source)};
      return;
    end if;

    cref_exp := Expression.CREF(ComponentRef.getSubscriptedType(cref), cref);
    (cref_exp, expanded) := ExpandExp.expand(cref_exp);

    if expanded then
      connectors := Connector.fromExp(cref_exp, source);
    else
      // Connectors should only have structural parameter subscripts, so it
      // should always be possible to expand them.
      Error.assertion(false, getInstanceName() + " failed to expand connector `" +
        ComponentRef.toString(cref) + "\n", ElementSource.getInfo(source));
    end if;
  end makeConnectors;

  function toString
    input Connections conns;
    output String str;
  protected
    list<String> strl = {};
  algorithm
    strl := "FLOWS:" :: strl;
    for f in conns.flows loop
      strl := Connector.toString(f) :: strl;
    end for;

    strl := "\nCONNECTIONS:" :: strl;
    for c in conns.connections loop
      strl := Connection.toString(c) :: strl;
    end for;

    strl := listReverseInPlace(strl);
    str := stringDelimitList(strl, "\n");
  end toString;

  annotation(__OpenModelica_Interface="frontend");
end NFConnections;

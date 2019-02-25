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
  import NFComponent.Component;
  import NFInstNode.InstNode;
  import Expression = NFExpression;
  import Type = NFType;
  import MetaModelica.Dangerous.listReverseInPlace;
  import ElementSource;
  import ExpandExp = NFExpandExp;

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
          output Connections conns = new();
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
            if not (ComponentRef.isDeleted(lhs) or ComponentRef.isDeleted(rhs)) then
              cl1 := makeConnectors(lhs, ty1, source);
              cl2 := makeConnectors(rhs, ty2, source);

              for c1 in cl1 loop
                c2 :: cl2 := cl2;
                conns := addConnection(Connection.CONNECTION(c1, c2), conns);
              end for;
            end if;
          then
            eql;

        else eq :: eql;
      end match;
    end for;

    if not listEmpty(conns.connections) then
      flatModel.equations := listReverseInPlace(eql);
    end if;
  end collect;

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
    cr := ComponentRef.evaluateSubscripts(cref);

    if not Flags.isSet(Flags.NF_SCALARIZE) then
      connectors := {Connector.fromCref(cr, ComponentRef.getSubscriptedType(cr), source)};
      return;
    end if;

    cref_exp := Expression.CREF(ComponentRef.getSubscriptedType(cr), cr);
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


  annotation(__OpenModelica_Interface="frontend");
end NFConnections;

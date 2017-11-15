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
  import NFFlatten.Elements;

protected
  import Equation = NFEquation;
  import ComponentRef = NFComponentRef;
  import Connections = NFConnections;
  import NFComponent.Component;
  import NFInstNode.InstNode;
  import Expression = NFExpression;
  import Type = NFType;
  import MetaModelica.Dangerous.listReverseInPlace;

public
  record CONNECTIONS
    list<Connection> connections;
    list<Connector> flows;
  end CONNECTIONS;

  function new
    output Connections conns = CONNECTIONS({}, {});
  end new;

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

  function collect
    input output Elements elements;
          output Connections conns = new();
  protected
    Component comp;
    ComponentRef cr, lhs, rhs;
    Connector c1, c2;
    Type ty1, ty2;
    SourceInfo info;
    list<Equation> eql = {};
  algorithm
    // Collect all flow variables.
    for c in elements.components loop
      () := match c
        case (cr, _)
          algorithm
            comp := InstNode.component(ComponentRef.node(cr));

            if Component.isFlow(comp) then
              c1 := Connector.fromFacedCref(cr, Component.getType(comp),
                NFConnector.Face.INSIDE, Component.info(comp));
              conns := addFlow(c1, conns);
            end if;
          then
            ();

        else ();
      end match;
    end for;

    // Collect all connects.
    for eq in elements.equations loop
      eql := match eq
        case Equation.CONNECT(lhs = Expression.CREF(cref = lhs, ty = ty1),
                              rhs = Expression.CREF(cref = rhs, ty = ty2), info = info)
          algorithm
            c1 := Connector.fromCref(lhs, ty1, info);
            c2 := Connector.fromCref(rhs, ty2, info);
            conns := addConnection(Connection.CONNECTION(c1, c2), conns);
          then
            eql;

        else eq :: eql;
      end match;
    end for;

    if not listEmpty(conns.connections) then
      elements.equations := listReverseInPlace(eql);
    end if;
  end collect;

  annotation(__OpenModelica_Interface="frontend");
end NFConnections;

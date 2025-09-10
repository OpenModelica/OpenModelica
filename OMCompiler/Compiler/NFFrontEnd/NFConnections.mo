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
  import NFPrefixes.ConnectorType;

protected
  import Component = NFComponent;
  import Connections = NFConnections;
  import ElementSource;
  import ExpandExp = NFExpandExp;
  import Expression = NFExpression;
  import Flags;
  import MetaModelica.Dangerous.listReverseInPlace;
  import NFInstNode.InstNode;
  import Structural = NFStructural;
  import Type = NFType;

public
  uniontype BrokenEdge
    record BROKEN_EDGE
      ComponentRef lhs;
      ComponentRef rhs;
      DAE.ElementSource source;
      list<Equation> brokenEquations;
    end BROKEN_EDGE;
  end BrokenEdge;

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

  function collectConnections
    input output FlatModel flatModel;
    input IsDeleted isDeleted;
          output Connections conns = new();

    partial function IsDeleted
      input ComponentRef cref;
      output Boolean res;
    end IsDeleted;
  protected
    ComponentRef lhs, rhs;
    DAE.ElementSource source;
    list<Equation> eql = {};
    Type ty1, ty2;
  algorithm
    // Collect all connects.
    for eq in flatModel.equations loop
      eql := match eq
        case Equation.CONNECT(lhs = Expression.CREF(ty = ty1, cref = lhs),
                              rhs = Expression.CREF(ty = ty2, cref = rhs), source = source)
          algorithm
            Structural.markCrefSubscripts(lhs);
            lhs := ComponentRef.evaluateSubscripts(lhs);
            Structural.markCrefSubscripts(rhs);
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
  end collectConnections;

  function collectFlows
    input FlatModel flatModel;
    input output Connections conns;
  protected
    Component comp;
    Connector c;
    DAE.ElementSource src;
  algorithm
    // Collect all flow variables.
    for var in flatModel.variables loop
      comp := InstNode.component(ComponentRef.node(var.name));

      if Component.isFlow(comp) then
        // Add all flow variables as inside connectors, to generate default
        // equations if they're not connected.
        src := ElementSource.createElementSource(Component.info(comp));
        c := Connector.fromFacedCref(var.name, var.ty, NFConnector.Face.INSIDE, src);
        conns := addFlow(c, conns);

        // Also add outside connectors for flow variables that were added during
        // augmentation of expandable connectors.
        if ConnectorType.isAugmented(var.attributes.connectorType) then
          c := Connector.fromFacedCref(var.name, var.ty, NFConnector.Face.OUTSIDE, src);
          conns := addFlow(c, conns);
        end if;
      end if;
    end for;
  end collectFlows;

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

    if InstNode.isName(ComponentRef.node(lhsCref)) or InstNode.isName(ComponentRef.node(rhsCref)) then
      // Keep the connectors unexpanded if either connector refers to a not
      // declared component in an expandable connector, since we can't expand
      // such connectors here.
      cl1 := {Connector.fromCref(lhsCref, lhsType, source)};
      cl2 := {Connector.fromCref(rhsCref, rhsType, source)};
    else
      cl1 := makeConnectors(lhsCref, lhsType, source);
      cl2 := makeConnectors(rhsCref, rhsType, source);
    end if;

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

  function split
    input output Connections conns;
  algorithm
    conns.flows := List.mapFlat(conns.flows, Connector.split);
    conns.connections := List.mapFlat(conns.connections, Connection.split);
  end split;

  function connectCount
    input Connector conn;
    input UnorderedMap<Connector, Integer> connectCounts;
    output Integer count;
  algorithm
    count := UnorderedMap.getOrDefault(conn, connectCounts, 0);
  end connectCount;

  function scalarize
    input output Connections conns;
    input Boolean keepSingleConnectedArrays;
  protected
    UnorderedMap<Connector, Integer> connect_counts;
    list<Connector> flows = {};
    list<Connection> connections = {};
    Integer count;
  algorithm
    if keepSingleConnectedArrays then
      connect_counts := analyseArrayConnections(conns);

      for f in conns.flows loop
        count := connectCount(f, connect_counts);

        if count == 0 then
          flows := f :: flows;
        elseif count > 1 or count == -1 then
          flows := listAppend(Connector.scalarize(f), flows);
        end if;
      end for;

      for c in conns.connections loop
        if not ConnectorType.isStream(c.lhs.cty) and
           connectCount(c.lhs, connect_counts) == 1 and connectCount(c.rhs, connect_counts) == 1 then
          connections := c :: connections;
        else
          connections := listAppend(Connection.scalarize(c), connections);
        end if;
      end for;

      conns.flows := listReverseInPlace(flows);
      conns.connections := listReverseInPlace(connections);
    else
      conns.flows := List.mapFlat(conns.flows, Connector.scalarize);
      conns.connections := List.mapFlat(conns.connections, Connection.scalarize);
    end if;
  end scalarize;

  function analyseArrayConnections
    input Connections conns;
    output UnorderedMap<Connector, Integer> connectCounts;
  algorithm
    connectCounts := UnorderedMap.new<Integer>(Connector.hashNoSubs, Connector.isEqualNoSubs,
      listLength(conns.connections));

    for conn in conns.connections loop
      analyseArrayConnector(conn.lhs, connectCounts);
      analyseArrayConnector(conn.rhs, connectCounts);
    end for;
  end analyseArrayConnections;

  function analyseArrayConnector
    input Connector conn;
    input UnorderedMap<Connector, Integer> connectCounts;
  protected
    function update
      input Option<Integer> count;
      output Integer outCount;
    algorithm
      outCount := match count
        case SOME(outCount) then if outCount >= 0 then outCount + 1 else -1;
        else 1;
      end match;
    end update;
  algorithm
    if Connector.isArray(conn) then
      UnorderedMap.addUpdate(conn, update, connectCounts);
    elseif ComponentRef.hasSubscripts(conn.name) then
      // Always scalarize connector arrays that are partially connected.
      UnorderedMap.add(conn, -1, connectCounts);
    end if;
  end analyseArrayConnector;

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

  function toStringList
    input Connections conns;
    output list<list<String>> strl = {};
  algorithm
    strl := list({Connector.toString(c.lhs), Connector.toString(c.rhs)} for c in conns.connections);
  end toStringList;

  annotation(__OpenModelica_Interface="frontend");
end NFConnections;

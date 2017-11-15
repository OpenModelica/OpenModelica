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

encapsulated package NFConnectionSets
import DisjointSets;
import Connector = NFConnector;
import Connection = NFConnection;
import Connections = NFConnections;

protected
import Flags;
import List;

public
package ConnectionSets
  extends DisjointSets(redeclare type Entry = Connector);

  redeclare function extends EntryHash
  algorithm
    hash := Connector.hash(entry, mod);
  end EntryHash;

  redeclare function extends EntryEqual
  algorithm
    isEqual := Connector.isEqual(entry1, entry2);
  end EntryEqual;

  redeclare function extends EntryString
  algorithm
    str := Connector.toString(entry);
  end EntryString;

  function fromConnections
    "Creates a new DisjointSets from a list of connection and flow variables."
    input Connections connections;
    output ConnectionSets.Sets sets;
  algorithm
    // Approximate the size of the sets using the connections and flow variables.
    sets := ConnectionSets.emptySets(
      listLength(connections.connections) + listLength(connections.flows));

    // Add flow variable to the sets, unless disabled by flag.
    if not Flags.isSet(Flags.DISABLE_SINGLE_FLOW_EQ) then
      sets := List.fold(connections.flows, addConnector, sets);
    end if;

    // Add the connections.
    sets := List.fold(connections.connections, addConnection, sets);
  end fromConnections;

  function addScalarConnector
    "Adds a single connector to the connection sets."
    input Connector conn;
    input output ConnectionSets.Sets sets;
  algorithm
    sets := add(conn, sets);
  end addScalarConnector;

  function addConnector
    input Connector conn;
    input output ConnectionSets.Sets sets;
  algorithm
    sets := addList(Connector.split(conn), sets);
  end addConnector;

  function addConnection
    "Adds a connection to the sets, which means merging the two sets that the
     connectors belong to, unless they already belong to the same set."
    input Connection connection;
    input output ConnectionSets.Sets sets;
  protected
    Connector lhs, rhs, c2;
    list<Connector> lhsl, rhsl;
  algorithm
    Connection.CONNECTION(lhs = lhs, rhs = rhs) := connection;
    lhsl := Connector.split(lhs);
    rhsl := Connector.split(rhs);

    for c1 in lhsl loop
      c2 :: rhsl := rhsl;
      sets := merge(c1, c2, sets);
    end for;
  end addConnection;

  annotation(__OpenModelica_Interface="frontend");
end ConnectionSets;

annotation(__OpenModelica_Interface="frontend");
end NFConnectionSets;

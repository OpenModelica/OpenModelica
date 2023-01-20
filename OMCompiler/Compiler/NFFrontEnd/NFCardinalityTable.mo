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

encapsulated package NFCardinalityTable
  import System;
  import Connections = NFConnections;
  import Connection = NFConnection;
  import Connector = NFConnector;
  import Expression = NFExpression;
  import UnorderedMap;
  import Util;

  type Table = UnorderedMap<String, Integer>;

  function emptyCardinalityTable
    input Integer size;
    output Table table;
  algorithm
    table := UnorderedMap.new<Integer>(stringHashDjb2, stringEq, size);
  end emptyCardinalityTable;

  function fromConnections
    input Connections conns;
    output Table table;
  algorithm
    if System.getUsesCardinality() then
      // Use the number of connections as the bucket size. The worst case is
      // that each connector in the connections is unique, which would result in
      // twice as many entries in the hash table as buckets. That should be
      // fine, and real models usually have a higher degree of connectivity.
      table := emptyCardinalityTable(max(1, Util.nextPrime(listLength(conns.connections))));

      for conn in conns.connections loop
        addConnector(conn.lhs, table);
        addConnector(conn.rhs, table);
      end for;
    else
      table := emptyCardinalityTable(1);
    end if;
  end fromConnections;

  function addConnector
    input Connector conn;
    input Table table;
  protected
    String conn_str;

    function update
      input Option<Integer> count;
      output Integer outCount;
    algorithm
      outCount := match count
        case SOME(outCount) then outCount + 1;
        else 1;
      end match;
    end update;
  algorithm
    conn_str := Connector.toString(conn);
    UnorderedMap.addUpdate(conn_str, update, table);
  end addConnector;

  function evaluateCardinality
    input Expression arg;
    input Table table;
    output Expression res;
  protected
    Integer count;
  algorithm
    count := UnorderedMap.getOrDefault(Expression.toString(arg), table, 0);
    res := Expression.INTEGER(count);
  end evaluateCardinality;

  function print
    input Table table;
  algorithm
    for e in UnorderedMap.toList(table) loop
      print(Util.tuple21(e) + ": " + String(Util.tuple22(e)) + "\n");
    end for;
  end print;

  annotation(__OpenModelica_Interface="frontend");
end NFCardinalityTable;


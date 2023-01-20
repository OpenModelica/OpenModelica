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

encapsulated uniontype NFConnection
  import Connector = NFConnector;
protected
  import Error;
  import MetaModelica.Dangerous.listReverseInPlace;
  import Connection = NFConnection;
  import List;

public
  record CONNECTION
    // TODO: This should be Connector, but the import above doesn't work due to some compiler bug.
    NFConnector lhs;
    NFConnector rhs;
  end CONNECTION;

  function split
    input Connection conn;
    output list<Connection> conns = {};
  protected
    list<Connector> cls, crs;
    Connector cr;
  algorithm
    cls := Connector.split(conn.lhs);
    crs := Connector.split(conn.rhs);
    checkBalance(cls, crs, conn);

    for cl in cls loop
      cr :: crs := crs;

      // Connections involving deleted conditional connectors are filtered out
      // when collecting the connections, but if the connectors themselves
      // contain connectors that have been deleted we need to remove them here.
      if not (Connector.isDeleted(cl) or Connector.isDeleted(cr)) then
        conns := CONNECTION(cl, cr) :: conns;
      end if;
    end for;

    conns := listReverseInPlace(conns);
  end split;

  function scalarize
    input Connection conn;
    output list<Connection> conns = {};
  protected
    list<Connector> cls, crs;
    Connector cr;
  algorithm
    if not Connector.isArray(conn.lhs) then
      conns := {conn};
      return;
    end if;

    cls := Connector.scalarize(conn.lhs);
    crs := Connector.scalarize(conn.rhs);
    checkBalance(cls, crs, conn);

    for cl in cls loop
      cr :: crs := crs;
      conns := CONNECTION(cl, cr) :: conns;
    end for;

    conns := listReverseInPlace(conns);
  end scalarize;

  function scalarizePrefix
    input Connection conn;
    output list<Connection> conns = {};
  protected
    list<Connector> cls, crs;
    Connector cr;
  algorithm
    if not Connector.isArray(conn.lhs) then
      conns := {conn};
      return;
    end if;

    cls := Connector.scalarizePrefix(conn.lhs);
    crs := Connector.scalarizePrefix(conn.rhs);
    checkBalance(cls, crs, conn);

    for cl in cls loop
      cr :: crs := crs;
      conns := CONNECTION(cl, cr) :: conns;
    end for;

    conns := listReverseInPlace(conns);
  end scalarizePrefix;

  function toString
    input Connection conn;
    output String str;
  algorithm
    str := "connect(" + Connector.toString(conn.lhs) + ", " + Connector.toString(conn.rhs) + ")";
  end toString;

protected
  function checkBalance
    input list<Connector> leftConnectors;
    input list<Connector> rightConnectors;
    input Connection conn;
  algorithm
    if listLength(leftConnectors) <> listLength(rightConnectors) then
      Error.assertion(false, getInstanceName() + " got unbalanced connection " + toString(conn) + ":" +
        List.toString(leftConnectors, Connector.toString, "\n  lhs: ", "{", ", ", "}", true) +
        List.toString(rightConnectors, Connector.toString, "\n  rhs: ", "{", ", ", "}", true), sourceInfo());
      fail();
    end if;
  end checkBalance;

  annotation(__OpenModelica_Interface="frontend");
end NFConnection;

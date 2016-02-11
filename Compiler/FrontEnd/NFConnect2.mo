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

encapsulated package NFConnect2
" file:        NFConnect2.mo
  package:     NFConnect2
  description: Connection set management

"

public import DAE;

public uniontype Face
  record INSIDE end INSIDE;
  record OUTSIDE end OUTSIDE;
  record NO_FACE end NO_FACE;
end Face;

public uniontype ExpandableConnector
  record EXPANDABLE_CONNECTOR
    //list<...> potentialVars;
    //list<...> presentVars;
  end EXPANDABLE_CONNECTOR;
end ExpandableConnector;

public uniontype ConnectorType
  "The type of a connector element."
  record POTENTIAL end POTENTIAL;
  record FLOW end FLOW;
  record STREAM
    Option<DAE.ComponentRef> associatedFlow;
  end STREAM;
  record NO_TYPE end NO_TYPE;
end ConnectorType;

public uniontype Connector
  record CONNECTOR
    DAE.ComponentRef name;
    DAE.Type ty;
    Face face;
    ConnectorType cty;
    ConnectorAttr attr;
  end CONNECTOR;
end Connector;

public uniontype ConnectorAttr
  record CONN_ATTR
    DAE.VarKind variability;
    DAE.VarVisibility visibility;
    DAE.VarDirection direction;
  end CONN_ATTR;
end ConnectorAttr;

public constant ConnectorAttr DEFAULT_ATTR =
  CONN_ATTR(DAE.VARIABLE(), DAE.PUBLIC(), DAE.BIDIR());

public uniontype Connection
  record CONNECTION
    Connector lhs;
    Connector rhs;
    SourceInfo info;
  end CONNECTION;
end Connection;

public uniontype Branch
  record BRANCH
    Connector lhs;
    Connector rhs;
    Boolean breakable;
    SourceInfo info;
  end BRANCH;
end Branch;

public uniontype Root
  record ROOT
    DAE.ComponentRef name;
    SourceInfo info;
  end ROOT;

  record POTENTIAL_ROOT
    DAE.ComponentRef name;
    Integer priority;
    SourceInfo info;
  end POTENTIAL_ROOT;
end Root;

public uniontype Connections
  record CONNECTIONS
    list<Connection> connections;
    list<Connection> expandableConnections;
    list<Connection> branches;
    list<Root> roots;
  end CONNECTIONS;
end Connections;

public constant Connections emptyConnections = CONNECTIONS({}, {}, {}, {});

annotation(__OpenModelica_Interface="frontend");
end NFConnect2;

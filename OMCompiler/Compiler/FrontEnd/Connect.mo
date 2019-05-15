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

encapsulated package Connect
" file:        Connect.mo
  package:     Connect
  description: Connection set management


  Connections generate connection sets which are stored in the Sets type, which
  is then used to generate equations and evaluate stream operators during
  instantiation.

  Whenever a connection is instantiated by InstSection.connectComponents it is
  added to the connection sets with addConnection or addArrayConnection. The
  connector elements are stored in a trie, a.k.a. a prefix tree, where each node
  represents a part of the elements component reference. The connection sets
  are not stored explicitly, but each element keeps track of which set it
  belongs to. Adding a new element to a set simply means assigning the element a
  set index. Sets are not merged while connections are added either, instead a
  list of set connections are kept.

  The sets are collected and merged only when it's time to generate equations
  from them in Inst.instClass. The elements are then bucket sorted into an
  array, with pointers between buckets representing the set connections, and
  then equations are generated for each resulting set. The stream operators
  inStream and actualStream are also evaluated in the DAE at the same time,
  since they need the same data as the equation generation.
"

public import DAE;
public import Prefix;
public import Absyn;

public constant Integer NEW_SET = -1 "The index used for new sets which have not
  yet been assigned a set index.";

public uniontype Face
  "This type indicates whether a connector is an inside or an outside connector.
   Note: this is not the same as inner and outer references.
   A connector is inside if it connects from the outside into a component and it
   is outside if it connects out from the component.  This is important when
   generating equations for flow variables, where outside connectors are
   multiplied with -1 (since flow is always into a component)."
  record INSIDE "This is an inside connection" end INSIDE;
  record OUTSIDE "This is an outside connection" end OUTSIDE;
  record NO_FACE end NO_FACE;
end Face;

public uniontype ConnectorType
  "The type of a connector element."
  record EQU end EQU;
  record FLOW end FLOW;
  record STREAM
    Option<DAE.ComponentRef> associatedFlow;
  end STREAM;
  record NO_TYPE end NO_TYPE;
end ConnectorType;

public uniontype ConnectorElement
  record CONNECTOR_ELEMENT
    DAE.ComponentRef name;
    Face face;
    ConnectorType ty;
    DAE.ElementSource source;
    Integer set "Which set this element belongs to.";
  end CONNECTOR_ELEMENT;
end ConnectorElement;

public uniontype SetTrieNode
  record SET_TRIE_NODE
    "A trie node has a name and contains a list of child nodes."
    String name;
    DAE.ComponentRef cref;
    list<SetTrieNode> nodes;
    Integer connectCount;
  end SET_TRIE_NODE;

  record SET_TRIE_LEAF
    "A trie leaf contains information about a connector element. Each connector
     might be connected as both inside and outside, and stream connector
     elements have an associated flow element."
    String name;
    Option<ConnectorElement> insideElement "The inside element.";
    Option<ConnectorElement> outsideElement "The outside element.";
    Option<DAE.ComponentRef> flowAssociation "The name of the associated flow
      variable, if the leaf represents a stream variable.";
    Integer connectCount "How many times this connector has been connected.";
  end SET_TRIE_LEAF;
end SetTrieNode;

public type SetTrie = SetTrieNode "A trie, a.k.a. prefix tree, that maps crefs to sets.";

public type SetConnection = tuple<Integer, Integer> "A connection between two sets.";

public uniontype OuterConnect
  record OUTERCONNECT
    Prefix.Prefix scope "the scope where this connect was created";
    DAE.ComponentRef cr1 "the lhs component reference";
    Absyn.InnerOuter io1 "inner/outer attribute for cr1 component";
    Face f1 "the face of the lhs component";
    DAE.ComponentRef cr2 "the rhs component reference";
    Absyn.InnerOuter io2 "inner/outer attribute for cr2 component";
    Face f2 "the face of the rhs component";
    DAE.ElementSource source "the element origin";
  end OUTERCONNECT;
end OuterConnect;

public uniontype Sets
  record SETS
    SetTrie sets;
    Integer setCount "How many sets the trie contains.";
    list<SetConnection> connections;
    list<OuterConnect> outerConnects "Connect statements to propagate upwards.";
  end SETS;
end Sets;

public uniontype Set
  "A set of connection elements."

  record SET
    "A set with a type and a list of elements."
    ConnectorType ty;
    list<ConnectorElement> elements;
  end SET;

  record SET_POINTER
    "A pointer to another set."
    Integer index;
  end SET_POINTER;
end Set;

public constant Sets emptySet = SETS(SET_TRIE_NODE("", DAE.WILD(), {}, 0), 0, {}, {});

annotation(__OpenModelica_Interface="frontend");
end Connect;


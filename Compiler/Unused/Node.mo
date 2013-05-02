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

encapsulated package Node
" file:  Node.mo
  package:     Node
  description: Node represents an node in our graph.
  @author:     adrpo

  RCS: $Id: Node.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Node has a pool of nodes"

public
import Pool;
import Name;
import Scope;
import Instance;
import Reference;
import Element;

type Name      = .Name.Name;
type Scope     = .Scope.Scope;
type Instance  = .Instance.Instance;
type Reference = .Reference.Reference;
type Element   = .Element.Element;

constant Integer v = 0;
constant Integer e = 1;
constant Integer i = 2;
constant Integer r = 3;

uniontype Content "the content of the node"
  record V "void, no contents" end V;
  record E "element" Element e; end E;
  record I "instance" Instance i; end I;
  record R "reference" Reference r; end R;
end Content;

uniontype Node
"the nodes in the graph"
  record N "a node has an unique id and a scope id"
    Integer id;
    Integer scopeId;
    Content content;
  end N;
end Node;

type Nodes = .Pool.Pool<Node> "an array of nodes";

constant Integer defaultPoolSizeNodes = 100000;

public function pool
  output Nodes outNodes;
algorithm
  outNodes := Pool.create("Nodes", defaultPoolSizeNodes);
end pool;

public function get
  input Nodes inNodes;
  input Integer inID;
  output Node outNode;
algorithm
  outNode := Pool.get(inNodes, inID);
end get;

public function add
  input Nodes inNodes;
  input Node inNode;
  output Nodes outNodes;
  output Integer outID;
algorithm
  (outNodes, outID) := Pool.add(inNodes, inNode, NONE());
end add;

public function addAutoUpdateId
  input Nodes inNodes;
  input Node inNode;
  output Nodes outNodes;
  output Integer outID;
algorithm
  (outNodes, outID) := Pool.add(inNodes, inNode, SOME(updateId));
end addAutoUpdateId;

public function set
  input Nodes inNodes;
  input Integer inID;
  input Node inNode;
  output Nodes outNodes;
algorithm
  outNodes := Pool.set(inNodes, inID, inNode);
end set;

public function updateId
"@this function will update the node id
  is mostly used in conjunction with the pool"
  input Node inNode;
  input Integer updateNodeId;
  output Node outNode;
protected
  Integer id "the id of this node";
  Integer scopeId "the default scope, points into Scopes. the last entry in the Scope gives the element name!";
  Content content;
algorithm
  N(id, scopeId, content) := inNode;
  outNode := N(updateNodeId, scopeId, content);
end updateId;

public function id
"@returns the id from the node"
  input Node inNode;
  output Integer id;
algorithm
  N(id = id) := inNode;
end id;

public function scopeId
"@returns the scopeId from the node"
  input Node inNode;
  output Integer scopeId;
algorithm
  N(scopeId = scopeId) := inNode;
end scopeId;

public function content
"@returns the contents from the node"
  input Node inNode;
  output Content content;
algorithm
  N(content = content) := inNode;
end content;

public function kind
"@returns the contents from the node"
  input Node inNode;
  output Integer kind;
algorithm
  kind := match(inNode)
    case N(content = V( )) then v;
    case N(content = E(_)) then e;
    case N(content = I(_)) then i;
    case N(content = R(_)) then r;
  end match;
end kind;

public function setContent
"@update the contents of the node"
  input Node inNode;
  input Content inContent;
  output Node outNode;
protected
  Integer id, scopeId;
  Content content;
algorithm
  N(id, scopeId, content) := inNode;
  outNode := N(id, scopeId, inContent);
end setContent;

end Node;


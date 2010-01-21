/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Graphviz
"
  file:	       Graphviz.mo
  package:     Graphviz
  description: Graphviz is a tool for drawing graphs from a textual
  representation. This module generates the textual input to graphviz from a
  tree defined using the data structures defined here, e.g. Node for tree
  nodes. See http://www.research.att.com/sw/tools/graphviz/ .

  RCS: $Id$

  Input: The tree constructed from data structures in Graphviz
  Output: Textual input to graphviz, written to stdout."

public
type Type = String;

public
type Ident = String;

public
type Label = String;

public
uniontype Node "A graphviz Node is a node of the graph.
	  It has a type and attributes and children.
	  It can also have a list of labels, provided by the LNODE
	  constructor.
	"
  record NODE
    Type type_;
    Attributes attributes;
    Children children;
  end NODE;

  record LNODE
    Type type_;
    list<Label> labelLst;
    Attributes attributes;
    Children children;
  end LNODE;

end Node;

public
type Children = list<Node>;

public
type Attributes = list<Attribute>;

public
uniontype Attribute "an Attribute is a pair of name an value."
  record ATTR
    String name "name" ;
    String value "value" ;
  end ATTR;

end Attribute;

public constant Attribute box=ATTR("shape","box");

public function dump "Relations
  function: dump

  Dumps a Graphviz Node on stdout.
"
  input Node node;
  Label nm;
algorithm
  print("graph AST {\n");
  nm := dumpNode(node);
  print("}\n");
end dump;

protected function dumpNode "function dumpNode

  Dumps a node to a string.
"
  input Node inNode;
  output Ident outIdent;
algorithm
  outIdent:=
  matchcontinue (inNode)
    local
      Label nm,typlbl,out,typ,lblstr;
      Attributes newattr,attr;
      Children children;
      list<Label> lbl_1,lbl;
    case (NODE(type_ = typ,attributes = attr,children = children))
      equation
        nm = nodename(typ);
        typlbl = makeLabel({typ});
        newattr = listAppend({ATTR("label",typlbl)}, attr);
        out = makeNode(nm, newattr);
        print(out);
        dumpChildren(nm, children);
      then
        nm;
    case (LNODE(type_ = typ,labelLst = lbl,attributes = attr,children = children))
      equation
        nm = nodename(typ);
        lbl_1 = listAppend({typ}, lbl);
        lblstr = makeLabel(lbl_1);
        newattr = listAppend({ATTR("label",lblstr)}, attr);
        out = makeNode(nm, newattr);
        print(out);
        dumpChildren(nm, children);
      then
        nm;
  end matchcontinue;
end dumpNode;

protected function makeLabel "function: makeLabel

  Creates a label from a list of strings.
"
  input list<String> sl;
  output String s2;
  Label s0,s1;
algorithm
  s0 := makeLabelReq(sl);
  s1 := stringAppend("\"", s0);
  s2 := stringAppend(s1, "\"");
end makeLabel;

protected function makeLabelReq "function: makeLabelReq

  Helper function to make_label
"
  input list<String> inStringLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inStringLst)
    local
      Label s,res,s1,s2,old;
      list<Label> rest;
    case {s} then s;
    case {s1,s2}
      equation
        s = stringAppend(s1, "\\n");
        res = stringAppend(s, s2);
      then
        res;
    case (s1 :: rest)
      equation
        old = makeLabelReq(rest);
        s = stringAppend(s1, "\\n");
        res = stringAppend(s, old);
      then
        res;
  end matchcontinue;
end makeLabelReq;

protected function dumpChildren "function: dumpChildren

  Helper function to dump_node
"
  input Ident inIdent;
  input Children inChildren;
algorithm
  _:=
  matchcontinue (inIdent,inChildren)
    local
      Label nm,parent;
      Node node;
      Children rest;
    case (_,{}) then ();
    case (parent,(node :: rest))
      equation
        nm = dumpNode(node);
        printEdge(nm, parent);
        dumpChildren(parent, rest);
      then
        ();
  end matchcontinue;
end dumpChildren;

protected function nodename "function: nodename

  Creates a unique node name,
  changed use of str as part of nodename, since it may contain spaces
"
  input String str;
  output String s;
  Integer i;
  Label is;
algorithm
  i := tick();
  is := intString(i);
  s := stringAppend("GVNOD", is);
end nodename;

protected function printEdge "function: printEdge

  Prints an edge between two nodes.
"
  input Ident n1;
  input Ident n2;
  Label str;
algorithm
  str := makeEdge(n1, n2);
  print(str);
  print(";\n");
end printEdge;

protected function makeEdge "function: makeEdge

  Creates a string representing an edge between two nodes.
"
  input Ident n1;
  input Ident n2;
  output String str;
  Label s;
algorithm
  s := stringAppend(n1, " -- ");
  str := stringAppend(s, n2);
end makeEdge;

protected function makeNode "function: makeNode

  Creates string from a node.
"
  input Ident nm;
  input Attributes attr;
  output String str;
  Label s,s_1;
algorithm
  s := makeAttr(attr);
  s_1 := stringAppend(nm, s);
  str := stringAppend(s_1, ";");
end makeNode;

protected function makeAttr "function: makeAttr

  Creates a string from an Attribute list.
"
  input list<Attribute> l;
  output String str;
  Label res,s;
algorithm
  res := makeAttrReq(l);
  s := stringAppend("[", res);
  str := stringAppend(s, "]");
end makeAttr;

protected function makeAttrReq "function: makeAttrReq

  Helper function to make_attr_req.
"
  input list<Attribute> inAttributeLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAttributeLst)
    local
      Label s,str,name,v,old,s_1,s_2;
      list<Attribute> rest;
    case {ATTR(name = name,value = v)}
      equation
        s = stringAppend(name, "=");
        str = stringAppend(s, v);
      then
        str;
    case ((ATTR(name = name,value = v) :: rest))
      equation
        old = makeAttrReq(rest);
        s = stringAppend(name, "=");
        s_1 = stringAppend(s, v);
        s_2 = stringAppend(s_1, ",");
        str = stringAppend(s_2, old);
      then
        str;
  end matchcontinue;
end makeAttrReq;
end Graphviz;


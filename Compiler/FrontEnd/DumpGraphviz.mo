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

encapsulated package DumpGraphviz
" file:  DumpGraphviz.mo
  package:     DumpGraphviz
  description: Dumps the AST to a graph representation that can be read by the graphviz tool.

  RCS: $Id$

"

public import Absyn;
public import Graphviz;

public
type Ident = String " An identifier is just a string " ;

public
type Node = Graphviz.Node;

protected import Dump;

public function dump "function: dump
  Dumps a Program to a Graphviz graph."
  input Absyn.Program p;
protected
  Graphviz.Node r;
algorithm
  r := buildGraphviz(p);
  Graphviz.dump(r);
end dump;

protected function buildGraphviz "function: buildGraphviz
  Build the graphviz graph for a Program."
  input Absyn.Program inProgram;
  output Node outNode;
algorithm
  outNode := match (inProgram)
    local
      list<Node> nl;
      list<Absyn.Class> cs;

    case (Absyn.PROGRAM(classes = cs))
      equation
  nl = printClasses(cs);
      then
  Graphviz.NODE("ROOT",{},nl);
  end match;
end buildGraphviz;

protected function printClasses "function: printClasses
  Creates Nodes from a Class list."
  input list<Absyn.Class> inAbsynClassLst;
  output list<Node> outNodeLst;
algorithm
  outNodeLst := match (inAbsynClassLst)
    local
      Graphviz.Node node;
      list<Node> nl;
      Absyn.Class c;
      list<Absyn.Class> cs;

    case {} then {};

    case (c :: cs)
      equation
  node = printClass(c);
  nl = printClasses(cs);
      then
  (node :: nl);
  end match;
end printClasses;

protected function printClass "function: printClass
  Creates a Node for a Class."
  input Absyn.Class inClass;
  output Node outNode;
algorithm
  outNode := match (inClass)
    local
      Ident rs,n;
      list<Node> nl;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;

    case (Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = Absyn.PARTS(classParts = parts)))
      equation
  rs = Absyn.restrString(r);
  nl = printParts(parts);
      then
  Graphviz.NODE(rs,{},nl);
  end match;
end printClass;

protected function printParts "function: printParts
  Creates a Node list from a ClassPart list."
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Node> outNodeLst;
algorithm
  outNodeLst := match (inAbsynClassPartLst)
    local
      Graphviz.Node node;
      list<Node> nl;
      Absyn.ClassPart c;
      list<Absyn.ClassPart> cs;

    case {} then {};

    case (c :: cs)
      equation
  node = printClassPart(c);
  nl = printParts(cs);
      then
  (node :: nl);
  end match;
end printParts;

protected function printClassPart "function: printClassPart
  Creates a Node from A ClassPart."
  input Absyn.ClassPart inClassPart;
  output Node outNode;
algorithm
  outNode := matchcontinue (inClassPart)
    local
      list<Node> nl;
      list<Absyn.ElementItem> el;
      list<Absyn.EquationItem> eqs;
      list<Absyn.AlgorithmItem> als;

    case (Absyn.PUBLIC(contents = el))
      equation
  nl = printElementitems(el);
      then
  Graphviz.NODE("PUBLIC",{},nl);

    case (Absyn.PROTECTED(contents = el))
      equation
  nl = printElementitems(el);
      then
  Graphviz.NODE("PROTECTED",{},nl);

    case (Absyn.EQUATIONS(contents = eqs))
      equation
  nl = printEquations(eqs);
      then
  Graphviz.NODE("EQUATIONS",{},nl);

    case (Absyn.ALGORITHMS(contents = als))
      equation
  nl = printAlgorithms(als);
      then
  Graphviz.NODE("ALGORITHMS",{},nl);

    case (_) then Graphviz.NODE(" DumpGraphViz.printClassPart PART_ERROR",{},{});
  end matchcontinue;
end printClassPart;

protected function printElementitems "function: printElementitems
  Creates a Node list from ElementItem list."
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Node> outNodeLst;
algorithm
  outNodeLst := match (inAbsynElementItemLst)
    local
      list<Node> nl;
      list<Absyn.ElementItem> el;
      Graphviz.Node node;
      Absyn.Element e;

    case {} then {};

    case ((Absyn.ELEMENTITEM(element = e) :: el))
      equation
  node = printElement(e);
  nl = printElementitems(el);
      then
  (node :: nl);
  end match;
end printElementitems;

protected function makeBoolAttr "function: makeBoolAttr
  Create an Attribute from a bool value and a description string."
  input String str;
  input Boolean flag;
  output Graphviz.Attribute outAttribute;
protected
  Ident s;
algorithm
  s := Dump.selectString(flag, "true", "false");
  outAttribute := Graphviz.ATTR(str,s);
end makeBoolAttr;

protected function makeLeaf "function: makeLeaf
  Create a leaf Node from a string an a list of attributes."
  input String str;
  input list<Graphviz.Attribute> al;
  output Node outNode;
algorithm
  outNode := Graphviz.NODE(str,al,{});
end makeLeaf;

protected function printElement "function: printElement
  Create a Node from an Element."
  input Absyn.Element inElement;
  output Node outNode;
algorithm
  outNode := match (inElement)
    local
      Graphviz.Attribute fa;
      Graphviz.Node elsp;
      Boolean finalPrefix;
      Absyn.ElementSpec spec;

    case (Absyn.ELEMENT(finalPrefix = finalPrefix,specification = spec))
      equation
  fa = makeBoolAttr("final", finalPrefix);
  elsp = printElementspec(spec);
      then
  Graphviz.NODE("ELEMENT",{fa},{elsp});
  end match;
end printElement;

protected function printPath "function printPath
  Create a Node from a Path."
  input Absyn.Path p;
  output Node pn;
protected
  Ident s;
algorithm
  s := Absyn.pathString(p);
  pn := makeLeaf(s, {});
end printPath;

protected function printElementspec "function: printElementspec
  Create a Node from an ElementSpec"
  input Absyn.ElementSpec inElementSpec;
  output Node outNode;
algorithm
  outNode := matchcontinue (inElementSpec)
    local
      Graphviz.Node nl,en,pn;
      Graphviz.Attribute ra;
      Boolean repl;
      Absyn.Class cl;
      Absyn.Path p;
      list<Absyn.ElementArg> l;
      list<Node> cns;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec tspec;
      list<Absyn.ComponentItem> cs;
      String s;

    case (Absyn.CLASSDEF(replaceable_ = repl,class_ = cl))
      equation
  nl = printClass(cl);
  ra = makeBoolAttr("replaceable", repl);
      then
  Graphviz.NODE("CLASSDEF",{ra},{});

    case (Absyn.EXTENDS(path = p,elementArg = l))
      equation
  en = printPath(p);
      then
  Graphviz.NODE("EXTENDS",{},{en});

    case (Absyn.COMPONENTS(attributes = attr,typeSpec = tspec,components = cs))
      equation
  s = Dump.unparseTypeSpec(tspec);
  pn = makeLeaf(s, {});
  cns = printComponents(cs);
      then
  Graphviz.NODE("COMPONENTS",{},(pn :: cns));

    case (_)
      then
  Graphviz.NODE(" DumpGraphviz.printElementspec ELSPEC_ERROR",{},{});
  end matchcontinue;
end printElementspec;

protected function printComponents "function: printComponents
  Create a Node list from a ComponentItem list."
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output list<Node> outNodeLst;
algorithm
  outNodeLst := match (inAbsynComponentItemLst)
    local
      Graphviz.Node n;
      list<Node> nl;
      Absyn.ComponentItem c;
      list<Absyn.ComponentItem> cs;

    case {} then {};

    case (c :: cs)
      equation
  n = printComponentitem(c);
  nl = printComponents(cs);
      then
  (n :: nl);
  end match;
end printComponents;

protected function printComponentitem "function: printComponentitem
  Create a Node from a ComponentItem."
  input Absyn.ComponentItem inComponentItem;
  output Node outNode;
algorithm
  outNode := match (inComponentItem)
    local
      Graphviz.Node nn;
      Ident n;
      list<Absyn.Subscript> a;
      Option<Absyn.Modification> m;

    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = n,arrayDim = a,modification = m)))
      equation
  nn = Graphviz.NODE(n,{},{});
      then
  Graphviz.LNODE("COMPONENT",{n},{},{nn});
  end match;
end printComponentitem;

protected function printEquations "function: printEquations
  Create a Node list from an EquationItem list."
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Node> outNodeLst;
algorithm
  outNodeLst := match (inAbsynEquationItemLst)
    local
      Graphviz.Node node;
      list<Node> nl;
      Absyn.Equation eq;
      Option<Absyn.Comment> ann;
      list<Absyn.EquationItem> el;

    case {} then {};

    case (Absyn.EQUATIONITEM(equation_ = eq,comment = ann) :: el)
      equation
  node = printEquation(eq);
  nl = printEquations(el);
      then
  (node :: nl);
  end match;
end printEquations;

protected function printEquation
"function: printEquation
 Create a Node from an Equation."
  input Absyn.Equation inEquation;
  output Node outNode;
algorithm
  outNode := matchcontinue (inEquation)
    local
      Ident s1,s2,s,s_1,s_2,es;
      Absyn.Exp e1,e2;
      Absyn.ComponentRef c1,c2;
      list<Node> eqn;
      list<Absyn.EquationItem> eqs;
      Absyn.ForIterators iterators;

    case (Absyn.EQ_EQUALS(leftSide = e1,rightSide = e2))
      equation
  s1 = Dump.printExpStr(e1);
  s2 = Dump.printExpStr(e2);
  s = stringAppend(s1, " = ");
  s_1 = stringAppend(s, s2);
      then
  Graphviz.LNODE("EQ_EQUALS",{s_1},{},{});

    case (Absyn.EQ_CONNECT(connector1 = c1,connector2 = c2))
      equation
  s1 = Dump.printComponentRefStr(c1);
  s2 = Dump.printComponentRefStr(c2);
  s = stringAppend("connect(", s1);
  s_1 = stringAppend(s, s2);
  s_2 = stringAppend(s_1, ")");
      then
  Graphviz.LNODE("EQ_CONNECT",{s_2},{},{});

    case (Absyn.EQ_FOR(iterators=iterators,forEquations = eqs))
      equation
  eqn = printEquations(eqs);
  es = Dump.printIteratorsStr(iterators);
      then
  Graphviz.LNODE("EQ_FOR",{es},{},eqn);

    case (_) then Graphviz.NODE("EQ_ERROR",{},{});

  end matchcontinue;
end printEquation;

protected function printAlgorithms "function: printAlgorithms
  Create a Node list from an AlgorithmItem list."
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output list<Node> outNodeLst;
algorithm
  outNodeLst := match (inAbsynAlgorithmItemLst)
    local
      Graphviz.Node node;
      list<Node> nl;
      Absyn.AlgorithmItem e;
      list<Absyn.AlgorithmItem> el;

    case {} then {};

    case (e :: el)
      equation
  node = printAlgorithmitem(e);
  nl = printAlgorithms(el);
      then
  (node :: nl);
  end match;
end printAlgorithms;

protected function printAlgorithmitem "function: printAlgorithmitem
  Create a Node from an AlgorithmItem."
  input Absyn.AlgorithmItem inAlgorithmItem;
  output Node outNode;
algorithm
  outNode := matchcontinue (inAlgorithmItem)
    local
      Graphviz.Node node;
      Absyn.Algorithm alg;

    case (Absyn.ALGORITHMITEM(algorithm_ = alg))
      equation
  node = printAlgorithm(alg);
      then
  node;
    case (_) then Graphviz.NODE("ALG_ERROR",{},{});
  end matchcontinue;
end printAlgorithmitem;

protected function printAlgorithm "function: printAlgorithm
  Create a Node from an Algorithm."
  input Absyn.Algorithm inAlgorithm;
  output Node outNode;
algorithm
  outNode := matchcontinue (inAlgorithm)
    local
      Absyn.Exp e;

    case (Absyn.ALG_ASSIGN(assignComponent = _,value = e)) then Graphviz.NODE("ALG_ASSIGN",{},{});
    case (_) then Graphviz.NODE(" DumpGraphviz.printAlgorithm ALG_ERROR",{},{});
  end matchcontinue;
end printAlgorithm;

protected function variabilitySymbol "function: variabilitySymbol
  Return Variability as a string."
  input Absyn.Variability inVariability;
  output String outString;
algorithm
  outString := matchcontinue (inVariability)
    case (Absyn.VAR()) then "";
    case (Absyn.DISCRETE()) then "DISCRETE";
    case (Absyn.PARAM()) then "PARAM";
    case (Absyn.CONST()) then "CONST";
  end matchcontinue;
end variabilitySymbol;

protected function directionSymbol "function: directionSymbol
  Return direction as a string."
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString := matchcontinue (inDirection)
    case (Absyn.BIDIR()) then "";
    case (Absyn.INPUT()) then "INPUT";
    case (Absyn.OUTPUT()) then "OUTPUT";
  end matchcontinue;
end directionSymbol;

end DumpGraphviz;


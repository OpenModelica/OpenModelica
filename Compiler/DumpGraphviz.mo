package DumpGraphviz "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 DumpGraphviz.rml
  module:      DumpGraphviz
  description: Dumps the AST to a graph representation that can be read
 		 by the graphviz tool.
 
  RCS: $Id$
 
"

public import OpenModelica.Compiler.Absyn;

public import OpenModelica.Compiler.Graphviz;

public 
type Ident = String "adrpo -- not used
  with \"Debug.rml\"
" ;

public 
type Node = Graphviz.Node;

protected import OpenModelica.Compiler.Dump;

public function dump "adrpo -- not used
with \"ClassInf.rml\"

  Relations
  function: dump
 
  Dumps a Program to a Graphviz graph.
"
  input Absyn.Program p;
  Graphviz.Node r;
algorithm 
  r := buildGraphviz(p) "print \"> Beginning of rule dump\\n\" &" ;
  Graphviz.dump(r) "& print \"> End of rule dump\\n\"" ;
end dump;

protected function buildGraphviz "function: buildGraphviz
 
  Build the graphviz graph for a Program.
"
  input Absyn.Program inProgram;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inProgram)
    local
      list<Node> nl;
      list<Absyn.Class> cs;
    case (Absyn.PROGRAM(classes = cs))
      equation 
        nl = printClasses(cs) "print \"> Beginning of rule build_graphviz\\n\" & & print \"> End of rule build_graphviz\\n\"" ;
      then
        Graphviz.NODE("ROOT",{},nl);
  end matchcontinue;
end buildGraphviz;

protected function printClasses "function: printClasses
 
  Creates Nodes from a Class list.
"
  input list<Absyn.Class> inAbsynClassLst;
  output list<Node> outNodeLst;
algorithm 
  outNodeLst:=
  matchcontinue (inAbsynClassLst)
    local
      Graphviz.Node node;
      list<Node> nl;
      Absyn.Class c;
      list<Absyn.Class> cs;
    case {} then {}; 
    case (c :: cs)
      equation 
        node = printClass(c) "print \"> Beginning of rule print_classes\\n\" &" ;
        nl = printClasses(cs) "& print \"> End of rule print_classes\\n\"" ;
      then
        (node :: nl);
  end matchcontinue;
end printClasses;

protected function printClass "function: printClass
 
  Creates a Node for a Class.
"
  input Absyn.Class inClass;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inClass)
    local
      Ident rs,n;
      list<Node> nl;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
    case (Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts)))
      equation 
        rs = Absyn.restrString(r) "print \"> Beginning of rule print_class\\n\" &" ;
        nl = printParts(parts) "& print \"> End of rule print_class\\n\"" ;
      then
        Graphviz.NODE(rs,{},nl);
  end matchcontinue;
end printClass;

protected function printParts "function: printParts
 
  Creates a Node list from a ClassPart list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Node> outNodeLst;
algorithm 
  outNodeLst:=
  matchcontinue (inAbsynClassPartLst)
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
  end matchcontinue;
end printParts;

protected function printClassPart "function: printClassPart
  
  Creates a Node from A ClassPart.
"
  input Absyn.ClassPart inClassPart;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inClassPart)
    local
      list<Node> nl;
      list<Absyn.ElementItem> el;
      list<Absyn.EquationItem> eqs;
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
    case (Absyn.ALGORITHMS(contents = eqs))
      local list<Absyn.AlgorithmItem> eqs;
      equation 
        nl = printAlgorithms(eqs);
      then
        Graphviz.NODE("ALGORITHMS",{},nl);
    case (_)
      equation 
        print("") "print \"> Error in print_class_part\\n\"" ;
      then
        Graphviz.NODE("PART_ERROR",{},{});
  end matchcontinue;
end printClassPart;

protected function printElementitems "function: printElementitems
 
  Creates a Node list from ElementItem list.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Node> outNodeLst;
algorithm 
  outNodeLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Node> nl;
      list<Absyn.ElementItem> el;
      Graphviz.Node node;
      Absyn.Element e;
    case {} then {}; 
    case ((Absyn.ANNOTATIONITEM(annotation_ = _) :: el))
      equation 
        nl = printElementitems(el);
      then
        nl;
    case ((Absyn.ELEMENTITEM(element = e) :: el))
      equation 
        node = printElement(e);
        nl = printElementitems(el);
      then
        (node :: nl);
  end matchcontinue;
end printElementitems;

protected function makeBoolAttr "function: makeBoolAttr
 
  Create an Attribute from a bool value and a description string.
"
  input String str;
  input Boolean flag;
  output Graphviz.Attribute outAttribute;
  Ident s;
algorithm 
  s := Dump.selectString(flag, "true", "false");
  outAttribute := Graphviz.ATTR(str,s);
end makeBoolAttr;

protected function makeLeaf "function: makeLeaf
 
  Create a leaf Node from a string an a list of attributes.
"
  input String inString;
  input list<Graphviz.Attribute> inGraphvizAttributeLst;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inString,inGraphvizAttributeLst)
    local
      Ident str;
      list<Graphviz.Attribute> al;
    case (str,al) then Graphviz.NODE(str,al,{}); 
  end matchcontinue;
end makeLeaf;

protected function printElement "function: printElement
 
  Create a Node from an Element.
"
  input Absyn.Element inElement;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inElement)
    local
      Graphviz.Attribute fa;
      Graphviz.Node elsp;
      Boolean final_;
      Absyn.ElementSpec spec;
    case (Absyn.ELEMENT(final_ = final_,specification = spec))
      equation 
        fa = makeBoolAttr("final", final_) "print \"> Beginning of rule print_element\\n\" &" ;
        elsp = printElementspec(spec) "& print \"> End of rule print_element\\n\"" ;
      then
        Graphviz.NODE("ELEMENT",{fa},{elsp});
  end matchcontinue;
end printElement;

protected function printPath "function printPath
 
  Create a Node from a Path.
"
  input Absyn.Path p;
  output Node pn;
  Ident s;
algorithm 
  s := Absyn.pathString(p);
  pn := makeLeaf(s, {});
end printPath;

protected function printElementspec "function: printElementspec
 
  Create a Node from an ElementSpec
"
  input Absyn.ElementSpec inElementSpec;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inElementSpec)
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
      equation 
        print("");
      then
        Graphviz.NODE("ELSPEC_ERROR",{},{});
  end matchcontinue;
end printElementspec;

protected function printComponents "function: printComponents
 
  Create a Node list from a ComponentItem list.
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output list<Node> outNodeLst;
algorithm 
  outNodeLst:=
  matchcontinue (inAbsynComponentItemLst)
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
  end matchcontinue;
end printComponents;

protected function printComponentitem "function: printComponentitem
 
  Create a Node from a ComponentItem.
"
  input Absyn.ComponentItem inComponentItem;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inComponentItem)
    local
      Graphviz.Node nn;
      Ident n;
      list<Absyn.Subscript> a;
      Option<Absyn.Modification> m;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = n,arrayDim = a,modification = m)))
      equation 
        print("");
        nn = Graphviz.NODE(n,{},{});
      then
        Graphviz.LNODE("COMPONENT",{n},{},{nn});
  end matchcontinue;
end printComponentitem;

protected function printEquations "function: printEquations
  
  Create a Node list from an EquationItem list.
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Node> outNodeLst;
algorithm 
  outNodeLst:=
  matchcontinue (inAbsynEquationItemLst)
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
  end matchcontinue;
end printEquations;

protected function printEquation "function: printEquation
 
 Create a Node from an Equation.
"
  input Absyn.Equation inEquation;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inEquation)
    local
      Ident s1,s2,s,s_1,s_2,es,n;
      Absyn.Exp e1,e2,e;
      Absyn.ComponentRef c1,c2;
      list<Node> eqn;
      list<Absyn.EquationItem> eqs;
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
    case (Absyn.EQ_FOR(forVariable = n,forExp = e,forEquations = eqs))
      equation 
        eqn = printEquations(eqs);
        es = Dump.printExpStr(e);
      then
        Graphviz.LNODE("EQ_FOR",{n,es},{},eqn);
    case (_) then Graphviz.NODE("EQ_ERROR",{},{}); 
  end matchcontinue;
end printEquation;

protected function printAlgorithms "function: printAlgorithms
 
  Create a Node list from an AlgorithmItem list.
"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output list<Node> outNodeLst;
algorithm 
  outNodeLst:=
  matchcontinue (inAbsynAlgorithmItemLst)
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
  end matchcontinue;
end printAlgorithms;

protected function printAlgorithmitem "function: printAlgorithmitem
 
  Create a Node from an AlgorithmItem.
"
  input Absyn.AlgorithmItem inAlgorithmItem;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inAlgorithmItem)
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
 
  Create a Node from an Algorithm.
"
  input Absyn.Algorithm inAlgorithm;
  output Node outNode;
algorithm 
  outNode:=
  matchcontinue (inAlgorithm)
    local
      Absyn.ComponentRef cr;
      Absyn.Exp e;
    case (Absyn.ALG_ASSIGN(assignComponent = cr,value = e))
      equation 
        print("");
      then
        Graphviz.NODE("ALG_ASSIGN",{},{});
    case (_)
      equation 
        print("");
      then
        Graphviz.NODE("ALG_ERROR",{},{});
  end matchcontinue;
end printAlgorithm;

protected function variabilitySymbol "function: variabilitySymbol
 
  Return Variability as a string.
"
  input Absyn.Variability inVariability;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVariability)
    case (Absyn.VAR()) then ""; 
    case (Absyn.DISCRETE()) then "DISCRETE"; 
    case (Absyn.PARAM()) then "PARAM"; 
    case (Absyn.CONST()) then "CONST"; 
  end matchcontinue;
end variabilitySymbol;

protected function directionSymbol "function: directionSymbol
 
  Return direction as a string.
"
  input Absyn.Direction inDirection;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inDirection)
    case (Absyn.BIDIR()) then ""; 
    case (Absyn.INPUT()) then "INPUT"; 
    case (Absyn.OUTPUT()) then "OUTPUT"; 
  end matchcontinue;
end directionSymbol;
end DumpGraphviz;


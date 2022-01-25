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

encapsulated package FGraphBuildEnv
" file:        FGraphBuildEnv.mo
  package:     FGraphBuildEnv
  description: A node builder for Modelica constructs


  This module builds nodes out of SCode.
  The only difference between this and FGraphBuild.mo is that
  it doesn't expand all nodes and is better suited for usage
  in the old instantiation.
"

public import Absyn;
public import AbsynUtil;
public import SCode;
public import FCore;
public import FNode;
public import FGraph;
public import DAE;
public
type Name = FCore.Name;
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Data = FCore.Data;
type Kind = FCore.Kind;
type Ref = FCore.Ref;
type Refs = FCore.Refs;
type Children = FCore.Children;
type Parents = FCore.Parents;
type ImportTable = FCore.ImportTable;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;
type Graph = FCore.Graph;
type Scope = FCore.Scope;

protected
import Dump;
import List;
import AbsynToSCode;
import SCodeDump;
import SCodeInstUtil;
import SCodeUtil;
import Util;

public function mkProgramGraph
"builds nodes out of classes"
  input SCode.Program inProgram;
  input Kind inKind;
  input output Graph graph;
protected
  Ref topRef;
algorithm
  topRef := FGraph.top(graph);

  for cls in inProgram loop
    graph := mkClassGraph(cls, topRef, inKind, graph, true);
  end for;
end mkProgramGraph;

protected function mkClassGraph
"Extends the graph with a class."
  input SCode.Element inClass;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  input Boolean checkDuplicate = false;
  output Graph outGraph;
algorithm
  outGraph := match(inClass, inParentRef, inKind, inGraph)
    local
      String name;
      Graph g;
      SCode.ClassDef cdef;
      SourceInfo info;

    // class (we don't care here if is replaceable or not we can get that from the class)
    case (SCode.CLASS(), _, _, g)
      equation
        g = mkClassNode(inClass, DAE.NOPRE(), DAE.NOMOD(), inParentRef,
          inKind, g, checkDuplicate);
      then
        g;

  end match;
end mkClassGraph;

public function mkClassNode
  input SCode.Element inClass;
  input DAE.Prefix inPrefix;
  input DAE.Mod inMod;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  input Boolean checkDuplicate = false;
  output Graph outGraph;
algorithm
  outGraph := match(inClass, inPrefix, inMod, inParentRef, inKind, inGraph)
    local
      SCode.ClassDef cdef;
      SCode.Element cls;
      String name;
      Graph g;
      SourceInfo info;
      Node n;
      Ref nr;

    case (_, _, _, _, _, g)
      equation
        cls = SCodeInstUtil.expandEnumerationClass(inClass);
        SCode.CLASS(name = name) = cls;
        (g, n) = FGraph.node(g, name, {inParentRef}, FCore.CL(cls, inPrefix, inMod, inKind, FCore.CLS_UNTYPED()));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, name, nr, checkDuplicate);
        // g = mkRefNode(FNode.refNodeName, {}, nr, g);
      then
        g;

  end match;
end mkClassNode;

public function mkConstrainClass
  input SCode.Element inElement;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inElement, inParentRef, inKind, inGraph)
    local
      Graph g;
      Node n;
      Ref nr;
      SCode.ConstrainClass cc;

    case (SCode.CLASS(prefixes = SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(SOME(cc)))), _, _, g)
      equation
        (g, n) = FGraph.node(g, FNode.ccNodeName, {inParentRef}, FCore.CC(cc));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, FNode.ccNodeName, nr);
      then
        g;

    case (SCode.COMPONENT(prefixes = SCode.PREFIXES(replaceablePrefix = SCode.REPLACEABLE(SOME(cc)))), _, _, g)
      equation
        (g, n) = FGraph.node(g, FNode.ccNodeName, {inParentRef}, FCore.CC(cc));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, FNode.ccNodeName, nr);
      then
        g;

    // no cc found in element!
    else inGraph;

  end matchcontinue;
end mkConstrainClass;

public function mkModNode
  input Name inName "a name for this mod so we can call it from sub-mods";
  input SCode.Mod inMod;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inName, inMod, inParentRef, inKind, inGraph)
    local
      Name name;
      Graph g;
      Node n;
      Ref nr;
      SCode.Element e;
      list<SCode.SubMod> sm;
      Option<Absyn.Exp> b;

    // no mods
    case (_, SCode.NOMOD(), _, _, g) then g;

    // no binding no sub-mods
    case (_, SCode.MOD(subModLst = {}, binding = NONE()), _, _, g)
      then
        g;

    // just a binding
    case (name, SCode.MOD(subModLst = {}, binding = b as SOME(_)), _, _, g)
      equation
        (g, n) = FGraph.node(g, name, {inParentRef}, FCore.MO(inMod));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, name, nr);
        g = mkBindingNode(b, nr, inKind, g);
      then
        g;

    // yeha, some mods for sure and a possible binding
    case (name, SCode.MOD(subModLst = sm, binding = b), _, _, g)
      equation
        (g, n) = FGraph.node(g, name, {inParentRef}, FCore.MO(inMod));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, name, nr);
        g = mkSubMods(sm, nr, inKind, g);
        g = mkBindingNode(b, nr, inKind, g);
      then
        g;

    // ouch, a redeclare :)
    case (name, SCode.REDECL(element = e), _, _, g)
      equation
        (g, n) = FGraph.node(g, name, {inParentRef}, FCore.MO(inMod));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, name, nr);
        g = mkElementNode(e, nr, inKind, g);
      then
        g;

    // something bad happened!
    case (name, _, _, _, g)
      equation
        print("FGraphBuildEnv.mkModNode failed with: " + name + " mod: " + SCodeDump.printModStr(inMod, SCodeDump.defaultOptions) + "\n");
      then
        g;

  end matchcontinue;
end mkModNode;

public function mkSubMods
  input list<SCode.SubMod> inSubMod;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inSubMod, inParentRef, inKind, inGraph)
    local
      list<SCode.SubMod> rest;
      SCode.SubMod s;
      Name id;
      SCode.Mod m;
      Graph g;

    // no more, we're done!
    case ({}, _, _, g) then g;

    // some sub-mods!
    case (SCode.NAMEMOD(id, m)::rest, _, _, g)
      equation
        g = mkModNode(id, m, inParentRef, inKind, g);
        g = mkSubMods(rest, inParentRef, inKind, g);
      then
        g;

  end match;
end mkSubMods;

public function mkBindingNode
  input Option<Absyn.Exp> inBinding;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inBinding, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      SCode.Mod m;
      Absyn.Exp e;
      Graph g;

    // no binding
    case (NONE(), _, _, g) then g;

    // some binding
    case (SOME(e), _, _, g)
      equation
        g = mkExpressionNode(FNode.bndNodeName, e, inParentRef, inKind, g);
      then
        g;

  end match;
end mkBindingNode;

protected function mkClassChildren
"Extends the graph with a class's components."
  input SCode.ClassDef inClassDef;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inClassDef, inParentRef, inKind, inGraph)
    local
      list<SCode.Element> el;
      Graph g;
      SCode.Element c;
      SCode.ClassDef cdef;
      Node n;
      Ref nr;
      Absyn.TypeSpec ts;
      Absyn.Path p;
      Name name;
      SCode.Mod m;
      Absyn.ArrayDim ad;
      list<SCode.Equation> eqs, ieqs;
      list<SCode.AlgorithmSection> als, ials;
      list<SCode.ConstraintSection> constraintLst;
      list<Absyn.NamedArg> clsattrs;
      Option<SCode.ExternalDecl> externalDecl;
      list<Absyn.Path> pathlst;

    case (SCode.PARTS(
            elementLst = el,
            normalEquationLst = eqs,
            initialEquationLst = ieqs,
            normalAlgorithmLst = als,
            initialAlgorithmLst = ials,
            constraintLst = constraintLst,
            clsattrs = clsattrs,
            externalDecl = externalDecl
            ), _, _, g)
      equation
        g = List.fold2(el, mkElementNode, inParentRef, inKind, g);
        g = mkEqNode(FNode.eqNodeName, eqs, inParentRef, inKind, g);
        g = mkEqNode(FNode.ieqNodeName, ieqs, inParentRef, inKind, g);
        g = mkAlNode(FNode.alNodeName, als, inParentRef, inKind, g);
        g = mkAlNode(FNode.ialNodeName, ials, inParentRef, inKind, g);
        g = mkOptNode(FNode.optNodeName, constraintLst, clsattrs, inParentRef, inKind, g);
        g = mkExternalNode(FNode.edNodeName, externalDecl, inParentRef, inKind, g);
      then
        g;

    case (SCode.CLASS_EXTENDS(composition = cdef, modifications = m), _, _, g)
      equation
        g = mkClassChildren(cdef, inParentRef, inKind, g);
        g = mkModNode(FNode.modNodeName, m, inParentRef, inKind, g);
        g = mkRefNode(FNode.refNodeName, {}, inParentRef, g);
      then
        g;

    case (SCode.DERIVED(typeSpec = ts, modifications = m), _, _, g)
      equation
        _ = AbsynUtil.typeSpecPath(ts);
        nr = inParentRef;
        g = mkModNode(FNode.modNodeName, m, nr, inKind, g);
        ad = AbsynUtil.typeSpecDimensions(ts);
        g = mkDimsNode(FNode.tydimsNodeName, SOME(ad), nr, inKind, g);
        g = mkRefNode(FNode.refNodeName, {}, nr, g);
      then
        g;

    case (SCode.OVERLOAD(_), _, _, g)
      equation
      then
        g;

    case (SCode.PDER(_, _), _, _, g)
      equation
      then
        g;

    else inGraph;

  end matchcontinue;
end mkClassChildren;

public function mkElementNode
"Extends the graph with an element."
  input SCode.Element inElement;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inElement, inParentRef, inKind, inGraph)
    local
      Graph g;
      SCode.Ident name;
      Absyn.Path p;
      Node n;
      Absyn.TypeSpec ts;
      Ref nr;
      SCode.Mod m;

    // component
    case (SCode.COMPONENT(), _, _, g)
      equation
        g = mkCompNode(inElement, inParentRef, inKind, g);
      then
        g;

    // class
    case (SCode.CLASS(), _, _, g)
      equation
        g = mkClassNode(inElement, DAE.NOPRE(), DAE.NOMOD(), inParentRef, inKind, g);
      then
        g;

    case (SCode.EXTENDS(baseClassPath = p, modifications = m), _, _, g)
      equation
        // the extends is saved as a child with the extends name
        name = FNode.mkExtendsName(p);
        (g, n) = FGraph.node(g, name, {inParentRef}, FCore.EX(inElement, DAE.NOMOD()));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, name, nr);
        g = mkModNode(FNode.modNodeName, m, nr, inKind, g);
        g = mkRefNode(FNode.refNodeName, {}, nr, g);
      then
        g;

    case (SCode.IMPORT(), _, _, g)
      equation
        g = mkImportNode(inElement, inParentRef, inKind, g);
      then
        g;

    case (SCode.DEFINEUNIT(), _, _, g)
      equation
        g = mkUnitsNode(inElement, inParentRef, inKind, g);
      then
        g;

  end match;
end mkElementNode;

public function mkUnitsNode
"@author: adrpo
 create FNode.duNodeName if it doesn't
 exist and add the given element to it"
  input SCode.Element inElement;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inElement, inParentRef, inKind, inGraph)
    local
      Graph g;
      Node n;
      Ref r;
      list<SCode.Element> du;

    // if is there add the unit to it
    case (_, _, _, g)
      equation
        r = FNode.child(inParentRef, FNode.duNodeName);
        FNode.addDefinedUnitToRef(r, inElement);
      then
        g;

    // if not there create it
    case (_, _, _, g)
      equation
        (g, n) = FGraph.node(g, FNode.duNodeName, {inParentRef}, FCore.DU({inElement}));
        r = FNode.toRef(n);
        FNode.addChildRef(inParentRef, FNode.duNodeName, r);
      then
        g;
  end matchcontinue;
end mkUnitsNode;

public function mkImportNode
"@author: adrpo
 create FNode.imNodeName if it doesn't
 exist and add the given element to it"
  input SCode.Element inElement;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inElement, inParentRef, inKind, inGraph)
    local
      Graph g;
      Node n;
      Ref r;
      list<SCode.Element> du;

    // if is there add the import to it
    case (_, _, _, g)
      equation
        r = FNode.child(inParentRef, FNode.imNodeName);
        FNode.addImportToRef(r, inElement);
      then
        g;

    // if not there create it
    case (_, _, _, g)
      equation
        (g, n) = FGraph.node(g, FNode.imNodeName, {inParentRef}, FCore.IM(FCore.emptyImportTable));
        r = FNode.toRef(n);
        FNode.addChildRef(inParentRef, FNode.imNodeName, r);
        FNode.addImportToRef(r, inElement);
      then
        g;

  end matchcontinue;
end mkImportNode;

public function mkDimsNode
  input Name inName "name to use for the array dims node: $dims (FNode.dimsNodeName) or $tydims (FNode.tydimsNodeName)";
  input Option<Absyn.ArrayDim> inArrayDims;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inName, inArrayDims, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      SCode.Mod m;
      Absyn.ArrayDim a;
      Graph g;

    case (_, NONE(), _, _, g) then g;
    case (_, SOME({}), _, _, g) then g;

    // some array dims
    case (_, SOME(a as _::_), _, _, g)
      equation
        (g, n) = FGraph.node(g, inName, {inParentRef}, FCore.DIMS(inName, a));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, inName, nr);
        g = mkDimsNode_helper(0, a, nr, inKind, g);
      then
        g;

  end match;
end mkDimsNode;

public function mkDimsNode_helper
  input Integer inStartWith;
  input Absyn.ArrayDim inArrayDims;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inStartWith, inArrayDims, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      Name name;
      Absyn.ArrayDim rest;
      Absyn.Subscript s;
      Integer i;
      Absyn.Exp e;
      Graph g;

    // we're done
    case (_, {}, _, _, g) then g;

    // nosub, saved as Absyn.END
    case (i, Absyn.NOSUB()::rest, _, _, g)
      equation
        name = intString(i);
        g = mkExpressionNode(name, Absyn.END(), inParentRef, inKind, g);
        g = mkDimsNode_helper(i + 1, rest, inParentRef, inKind, g);
      then
        g;

    // subscript, saved as exp
    case (i, Absyn.SUBSCRIPT(e)::rest, _, _, g)
      equation
        name = intString(i);
        g = mkExpressionNode(name, e, inParentRef, inKind, g);
        g = mkDimsNode_helper(i + 1, rest, inParentRef, inKind, g);
      then
        g;

  end match;
end mkDimsNode_helper;

public function mkCompNode
"Extends the graph with a component"
  input SCode.Element inComp;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
protected
  String name;
  Graph g;
  Node n;
  Ref nr;
  SCode.Mod m;
  Option<Absyn.Exp> cnd;
  Absyn.ArrayDim ad;
  Absyn.TypeSpec ts;
  Absyn.ArrayDim tad;
  Data nd;
  DAE.Var i;
algorithm
  SCode.COMPONENT(name = name, attributes = SCode.ATTR(arrayDims = ad), typeSpec = ts, modifications = m, condition = cnd) := inComp;
  (nd, i) := FNode.element2Data(inComp, inKind);
  (g, n) := FGraph.node(inGraph, name, {inParentRef}, nd);
  nr := FNode.toRef(n);
  FNode.addChildRef(inParentRef, name, nr);
  // add instance node
  g := mkInstNode(i, nr, g);
  // add ref node
  g := mkRefNode(FNode.refNodeName, {}, nr, g);
  outGraph := g;
end mkCompNode;

public function mkInstNode
"Extends the graph with an inst node"
  input DAE.Var inVar;
  input Ref inParentRef;
  input Graph inGraph;
  output Graph outGraph;
protected
  Ref nr;
  Node n;
  Graph g;
algorithm
  (g, n) := FGraph.node(inGraph, FNode.itNodeName, {inParentRef}, FCore.IT(inVar));
  nr := FNode.toRef(n);
  FNode.addChildRef(inParentRef, FNode.itNodeName, nr);
  outGraph := g;
end mkInstNode;

public function mkConditionNode
  input Option<Absyn.Exp> inCondition;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inCondition, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      Absyn.Exp e;
      Graph g;

    // no binding
    case (NONE(), _, _, g) then g;

    // some condition
    case (SOME(e), _, _, g)
      equation
        g = mkExpressionNode(FNode.cndNodeName, e, inParentRef, inKind, g);
      then
        g;

  end match;
end mkConditionNode;

public function mkExpressionNode
  input Name inName;
  input Absyn.Exp inExp;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inName, inExp, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      Absyn.Exp e;
      list<Absyn.ComponentRef> crefs;
      Graph g;

    case (_, e, _, _, g)
      equation
        (g, n) = FGraph.node(g, inName, {inParentRef}, FCore.EXP(inName, e));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, inName, nr);
        g = analyseExp(e, nr, inKind, g);
      then
        g;

  end match;
end mkExpressionNode;

public function mkCrefsNodes
  input list<Absyn.ComponentRef> inCrefs;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inCrefs, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      Name name;
      list<Absyn.ComponentRef> rest;
      Absyn.Subscript s;
      Integer i;
      Absyn.Exp e;
      Graph g;
      Absyn.ComponentRef cr;

    // we're done
    case ({}, _, _, g) then g;

    // cref::rest
    case (cr::rest, _, _, g)
      equation
        g = mkCrefNode(cr, inParentRef, inKind, g);
        g = mkCrefsNodes(rest, inParentRef, inKind, g);
      then
        g;

  end match;
end mkCrefsNodes;

public function mkCrefNode
  input Absyn.ComponentRef inCref;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inCref, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      Absyn.Exp e;
      Graph g;
      Name name;

    case (_, _, _, g)
      equation
        name = Dump.printComponentRefStr(inCref);
        (g, n) = FGraph.node(g, name, {inParentRef}, FCore.CR(inCref));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, name, nr);
        g = mkDimsNode(FNode.subsNodeName, List.mkOption(AbsynUtil.getSubsFromCref(inCref, true, true)), nr, inKind, g);
      then
        g;

  end match;
end mkCrefNode;

public function mkTypeNode
  input list<DAE.Type> inTypes "the types to add";
  input Ref inParentRef;
  input Name inName "name to search for";
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inTypes, inParentRef, inName, inGraph)
    local
      list<DAE.Type> tys;
      Ref nr, pr;
      Option<Name> name;
      FNode.Parents parents;
      Children children;
      Node n;
      Graph g;

    // type node present, update
    case (_, _, _, _)
      equation
        // search in the parent node for a child with name FNode.tyNodeName
        pr = FNode.child(inParentRef, FNode.tyNodeName);
        // search for the given name in FNode.tyNodeName
        nr = FNode.child(pr, inName);
        FNode.addTypesToRef(nr, inTypes);
      then
        inGraph;

    // type node not present, add
    case (_, _, _, g)
      equation
        // search in the parent node for a child with name FNode.tyNodeName
        failure(_ = FNode.child(inParentRef, FNode.tyNodeName));
        // add it
        (g, n) = FGraph.node(g, FNode.tyNodeName, {inParentRef}, FCore.ND(NONE()));
        pr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, FNode.tyNodeName, pr);
        (g, n) = FGraph.node(g, inName, {pr}, FCore.FT(inTypes));
        nr = FNode.toRef(n);
        FNode.addChildRef(pr, inName, nr);
      then
        g;

    // type node present, but inName not present in it
    case (_, _, _, g)
      equation
        // search in the parent node for a child with name FNode.tyNodeName
        pr = FNode.child(inParentRef, FNode.tyNodeName);
        failure(_ = FNode.child(pr, inName));
        // add it
        (g, n) = FGraph.node(g, inName, {pr}, FCore.FT(inTypes));
        nr = FNode.toRef(n);
        FNode.addChildRef(pr, inName, nr);
      then
        g;

    else
      equation
        pr = FGraph.top(inGraph);
        print("FGraphBuildEnv.mkTypeNode: Error making type node: " + inName +
              " in parent: " + FNode.name(FNode.fromRef(pr)) + "\n");
      then
        inGraph;

  end matchcontinue;
end mkTypeNode;

public function mkEqNode
"equation node"
  input Name inName;
  input list<SCode.Equation> inEqs;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inName, inEqs, inParentRef, inKind, inGraph)
    local
      Graph g;
      Node n;
      Ref nr;

    case (_, {}, _, _, g) then g;

    case (_, _, _, _, g)
      equation
        (g, n) = FGraph.node(g, inName, {inParentRef}, FCore.EQ(inName, inEqs));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, inName, nr);
        g = List.fold2(inEqs, analyseEquation, nr, inKind, g);
      then
        g;

  end match;
end mkEqNode;

public function mkAlNode
"algorithm node"
  input Name inName;
  input list<SCode.AlgorithmSection> inAlgs;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inName, inAlgs, inParentRef, inKind, inGraph)
    local
      Graph g;
      Node n;
      Ref nr;

    case (_, {}, _, _, g) then g;

    case (_, _, _, _, g)
      equation
        (g, n) = FGraph.node(g, inName, {inParentRef}, FCore.AL(inName, inAlgs));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, inName, nr);
        g = List.fold2(inAlgs, analyseAlgorithm, nr, inKind, g);
      then
        g;

  end match;
end mkAlNode;

public function mkOptNode
"optimization node"
  input Name inName;
  input list<SCode.ConstraintSection> inConstraintLst;
  input list<Absyn.NamedArg> inClsAttrs;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inName, inConstraintLst, inClsAttrs, inParentRef, inKind, inGraph)
    local
      Graph g;
      Node n;
      Ref nr;

    case (_, {}, {}, _, _, g) then g;

    case (_, _, _, _, _, g)
      equation
        (g, n) = FGraph.node(g, inName, {inParentRef}, FCore.OT(inConstraintLst, inClsAttrs));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, inName, nr);
      then
        g;

  end match;
end mkOptNode;

public function mkExternalNode
"optimization node"
  input Name inName;
  input Option<SCode.ExternalDecl> inExternalDeclOpt;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inName, inExternalDeclOpt, inParentRef, inKind, inGraph)
    local
      Graph g;
      Node n;
      Ref nr;
      SCode.ExternalDecl ed;
      Option<Absyn.ComponentRef> ocr;
      Option<Absyn.Exp> oae;
      list<Absyn.Exp> exps;

    case (_, NONE(), _, _, g) then g;

    case (_, SOME(ed as SCode.EXTERNALDECL(output_ = ocr, args = exps)), _, _, g)
      equation
        (g, n) = FGraph.node(g, inName, {inParentRef}, FCore.ED(ed));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, inName, nr);
        oae = Util.applyOption(ocr, AbsynUtil.crefExp);
        g = mkCrefsFromExps(List.consOption(oae, exps), nr, inKind, g);
      then
        g;

  end match;
end mkExternalNode;

public function mkCrefsFromExps
  input list<Absyn.Exp> inExps;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inExps, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      Absyn.Exp e;
      list<Absyn.Exp> rest;
      list<Absyn.ComponentRef> crefs;
      Graph g;

    case ({}, _, _, g) then g;

    case (e::rest, _, _, g)
      equation
        crefs = AbsynUtil.getCrefFromExp(e, true, true);
        g = mkCrefsNodes(crefs, inParentRef, inKind, g);
        g = mkCrefsFromExps(rest, inParentRef, inKind, g);
      then
        g;

  end match;
end mkCrefsFromExps;

protected function analyseExp
"Recursively analyses an expression."
  input Absyn.Exp inExp;
  input Ref inRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  (_, outGraph) := AbsynUtil.traverseExpBidir(inExp,
    function analyseExpTraverserEnter(ref = inRef, kind = inKind), analyseExpTraverserExit, inGraph);
end analyseExp;

protected function analyseOptExp
  "Recursively analyses an optional expression."
  input Option<Absyn.Exp> inExp;
  input Ref inRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inExp, inRef, inKind, inGraph)
    local
      Absyn.Exp exp;
      Graph g;

    case (NONE(), _, _, g) then g;

    case (SOME(exp), _, _, g)
      equation
        g = analyseExp(exp, inRef, inKind, g);
      then
        g;

  end match;
end analyseOptExp;

protected function analyseExpTraverserEnter
  "Traversal enter function for use in analyseExp."
  input output Absyn.Exp inExp;
  input Ref ref;
  input Kind kind;
  input output Graph graph;
algorithm
  graph := match inExp
    local
      Absyn.ComponentRef cref;
      Absyn.ForIterators iters;

    case Absyn.CREF(componentRef = cref)
      then analyseCref(cref, ref, kind, graph);

    case Absyn.CALL(functionArgs = Absyn.FOR_ITER_FARG(iterators = iters))
      then addIterators(iters, ref, kind, graph);

    case Absyn.CALL(function_ = cref)
      then analyseCref(cref, ref, kind, graph);

    case Absyn.PARTEVALFUNCTION(function_ = cref)
      then analyseCref(cref, ref, kind, graph);

    case Absyn.MATCHEXP()
      then addMatchScope(inExp, ref, kind, graph);

    else graph;
  end match;
end analyseExpTraverserEnter;

protected function analyseCref
  "Analyses a component reference."
  input Absyn.ComponentRef inCref;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inCref, inParentRef, inKind, inGraph)
    local
      Absyn.Path path;
      Ref ref;
      Graph g;

    case (Absyn.WILD(), _, _, g) then g;

    case (_, _, _, g)
      equation
        g = mkCrefNode(inCref, inParentRef, inKind, g);
      then
        g;

  end matchcontinue;
end analyseCref;

protected function analyseExpTraverserExit
  "Traversal exit function for use in analyseExp."
  input output Absyn.Exp exp;
  input output Graph graph;
algorithm
  // nothing to do here!
end analyseExpTraverserExit;

protected function analyseEquation
"Analyses an equation."
  input SCode.Equation inEquation;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
protected
  SCode.EEquation equ;
algorithm
  SCode.EQUATION(equ) := inEquation;
  (_, outGraph) := SCodeUtil.mapFoldEEquations(equ,
    function analyseEEquationTraverser(ref = inParentRef, kind = inKind), inGraph);
end analyseEquation;

protected function analyseEEquationTraverser
  "Traversal function for use in analyseEquation."
  input output SCode.EEquation eq;
  input Ref ref;
  input Kind kind;
  input output Graph graph;
algorithm
  (eq, graph) := match eq
    local
      SCode.Ident iter_name;
      Absyn.ComponentRef cref1;

    case SCode.EQ_FOR(index = iter_name)
      algorithm
        graph := addIterators({Absyn.ITERATOR(iter_name, NONE(), NONE())}, ref, kind, graph);
      then
        SCodeUtil.mapFoldEEquationExps(eq, function traverseExp(ref = ref, kind = kind), graph);

    case SCode.EQ_REINIT(cref = Absyn.CREF(componentRef = cref1))
      algorithm
        graph := analyseCref(cref1, ref, kind, graph);
      then
        SCodeUtil.mapFoldEEquationExps(eq, function traverseExp(ref = ref, kind = kind), graph);

    else
      algorithm
        _ := SCodeUtil.getEEquationInfo(eq);
      then
        SCodeUtil.mapFoldEEquationExps(eq, function traverseExp(ref = ref, kind = kind), graph);

  end match;
end analyseEEquationTraverser;

protected function traverseExp
  "Traversal function used by analyseEEquationTraverser and
  analyseStatementTraverser."
  input output Absyn.Exp exp;
  input output Graph graph;
  input Ref ref;
  input Kind kind;
algorithm
  (exp, graph) := AbsynUtil.traverseExpBidir(exp,
    function analyseExpTraverserEnter(ref = ref, kind = kind), analyseExpTraverserExit, graph);
end traverseExp;

protected function analyseAlgorithm
"Analyses an algorithm."
  input SCode.AlgorithmSection inAlgorithm;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
protected
  list<SCode.Statement> stmts;
algorithm
  SCode.ALGORITHM(stmts) := inAlgorithm;
  outGraph := List.fold2(stmts, analyseStatement, inParentRef, inKind, inGraph);
end analyseAlgorithm;

protected function analyseStatement
  "Analyses a statement in an algorithm."
  input SCode.Statement inStatement;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  (_, outGraph) := SCodeUtil.mapFoldStatements(inStatement,
    function analyseStatementTraverser(ref = inParentRef, kind = inKind), inGraph);
end analyseStatement;

protected function analyseStatementTraverser
  "Traversal function used by analyseStatement."
  input output SCode.Statement stmt;
  input Ref ref;
  input Kind kind;
  input output Graph graph;
algorithm
  (stmt, graph) := match stmt
    local
      String iter_name;

    case SCode.ALG_FOR()
      algorithm
        graph := addIterators({Absyn.ITERATOR(stmt.index, NONE(), NONE())}, ref, kind, graph);
        (_, graph) := SCodeUtil.mapFoldStatementExps(stmt,
          function traverseExp(ref = ref, kind = kind), graph);
      then
        (stmt, graph);

     case SCode.ALG_PARFOR()
      algorithm
        graph := addIterators({Absyn.ITERATOR(stmt.index, NONE(), NONE())}, ref, kind, graph);
        (_, graph) := SCodeUtil.mapFoldStatementExps(stmt,
          function traverseExp(ref = ref, kind = kind), graph);
      then
        (stmt, graph);

    else
      algorithm
        _ := SCodeUtil.getStatementInfo(stmt);
        (_, graph) := SCodeUtil.mapFoldStatementExps(stmt,
          function traverseExp(ref = ref, kind = kind), graph);
      then
        (stmt, graph);

  end match;
end analyseStatementTraverser;

public function addIterators
"adds iterators nodes"
  input Absyn.ForIterators inIterators;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inIterators, inParentRef, inKind, inGraph)
    local
      Graph g;
      Node n;
      Ref nr;
      Absyn.ForIterators i;

    // FNode.forNodeName already present!
    case (_, _, _, g)
      equation
        nr = FNode.child(inParentRef, FNode.forNodeName);
        FNode.addIteratorsToRef(nr, inIterators);
        g = addIterators_helper(inIterators, nr, inKind, g);
      then
        g;

    // FNode.forNodeName not present, add it
    case (_, _, _, g)
      equation
        (g, n) = FGraph.node(g, FNode.forNodeName, {inParentRef}, FCore.FS(inIterators));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, FNode.forNodeName, nr);
        g = addIterators_helper(inIterators, nr, inKind, g);
      then
        g;

  end matchcontinue;
end addIterators;

public function addIterators_helper
  input Absyn.ForIterators inIterators;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inIterators, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      Name name;
      list<Absyn.ForIterator> rest;
      Absyn.ForIterator i;
      Absyn.Exp e;
      Graph g;
      Absyn.ComponentRef cr;

    // we're done
    case ({}, _, _, g) then g;

    // iterator::rest
    case ((i as Absyn.ITERATOR(name=name))::rest, _, _, g)
      equation
        (g, n) = FGraph.node(g, name, {inParentRef}, FCore.FI(i));
        nr = FNode.toRef(n);
        FNode.addChildRef(inParentRef, name, nr);
        g = addIterators_helper(rest, inParentRef, inKind, g);
      then
        g;

  end match;
end addIterators_helper;

public function addMatchScope
"Extends the node with a match-expression, i.e. opens a new scope and
 adds the local declarations in the match to it."
  input Absyn.Exp inMatchExp;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
protected
  Node n;
  Ref nr;
  list<Absyn.ElementItem> local_decls;
  Graph g;
algorithm
  (g, n) := FGraph.node(inGraph, FNode.matchNodeName, {inParentRef}, FCore.MS(inMatchExp));
  nr := FNode.toRef(n);
  FNode.addChildRef(inParentRef, FNode.matchNodeName, nr);
  Absyn.MATCHEXP(localDecls = local_decls) := inMatchExp;
  outGraph := addMatchScope_helper(local_decls, nr, inKind, g);
end addMatchScope;

public function addMatchScope_helper
  input list<Absyn.ElementItem> inElements;
  input Ref inParentRef;
  input Kind inKind;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inElements, inParentRef, inKind, inGraph)
    local
      Node n;
      Ref nr;
      Name name;
      Absyn.Element element;
      list<Absyn.ElementItem> rest;
      Absyn.ForIterator i;
      Absyn.Exp e;
      Graph g;
      Absyn.ComponentRef cr;
      list<SCode.Element> el;

    // we're done
    case ({}, _, _, g) then g;

    // el::rest
    case (Absyn.ELEMENTITEM(element = element)::rest, _, _, g)
      equation
        // Translate the element item to a SCode element.
        el = AbsynToSCode.translateElement(element, SCode.PROTECTED());
        g = List.fold2(el, mkElementNode, inParentRef, inKind, g);
        g = addMatchScope_helper(rest, inParentRef, inKind, g);
      then
        g;

    // el::rest
    case (_::rest, _, _, g)
      equation
        g = addMatchScope_helper(rest, inParentRef, inKind, g);
      then
        g;

  end match;
end addMatchScope_helper;

public function mkRefNode
  input Name inName;
  input Scope inTargetScope;
  input Ref inParentRef;
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inName, inTargetScope, inParentRef, inGraph)
    local
      Node n;
      Ref rn, rc;
      Graph g;

    case (_, _, _, g)
      equation
        (g, n) = FGraph.node(g, inName, {inParentRef}, FCore.REF(inTargetScope));
        // make a ref
        rn = FNode.toRef(n);
        // add the ref node
        FNode.addChildRef(inParentRef, inName, rn);
      then
        g;

  end match;
end mkRefNode;

annotation(__OpenModelica_Interface="frontend");
end FGraphBuildEnv;

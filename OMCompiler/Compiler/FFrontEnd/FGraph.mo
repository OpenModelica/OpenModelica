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

encapsulated package FGraph
" file:        FGraph.mo
  package:     FGraph
  description: Graph of program


"

// public imports
public
import Absyn;
import AbsynUtil;
import SCode;
import DAE;
import ClassInf;
import FCore;
import FNode;
import InnerOuter;

protected
import List;
import Util;
import System;
import Debug;
import FGraphStream;
import FGraphBuildEnv;
import Global;
import Config;
import PrefixUtil;
import Flags;
import SCodeDump;
import MetaModelica.Dangerous;
import Mod;
import Error;
import ComponentReference;
import Types;
import SCodeUtil;

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
type RefTree = FCore.RefTree;
type Children = FCore.Children;
type Parents = FCore.Parents;
type Scope = FCore.Scope;
type Top = FCore.Top;
type Graph = FCore.Graph;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Status = FCore.Status;

constant FCore.Graph emptyGraph = FCore.EG("empty");

public function top
"get the top node ref from the graph"
  input Graph inGraph;
  output Ref outRef;
algorithm
  outRef := match inGraph
    case FCore.G() then inGraph.top.node;
  end match;
end top;

public function extra
"get the extra from the graph"
  input Graph inGraph;
  output Extra outExtra;
algorithm
  outExtra := match inGraph
    case FCore.G() then inGraph.top.extra;
  end match;
end extra;

public function currentScope
"get the top current scope from the graph"
  input Graph inGraph;
  output Scope outScope;
algorithm
  outScope := match(inGraph)
    case FCore.G(scope = outScope) then outScope;
    case FCore.EG(_) then {};
  end match;
end currentScope;

public function lastScopeRef
"get the last ref from the current scope the graph"
  input Graph inGraph;
  output Ref outRef;
algorithm
  outRef := listHead(currentScope(inGraph));
end lastScopeRef;

public function setLastScopeRef
  input Ref inRef;
  input Graph inGraph;
  output Graph outGraph = inGraph;
algorithm
  outGraph := match outGraph
    case FCore.G()
      algorithm
        outGraph.scope := inRef :: listRest(outGraph.scope);
      then
        outGraph;

    else outGraph;
  end match;
end setLastScopeRef;

public function stripLastScopeRef
"remove the last ref from the current scope the graph"
  input Graph inGraph;
  output Graph outGraph;
  output Ref outRef;
protected
  Top t;
  Scope s;
algorithm
  FCore.G(t, outRef::s) := inGraph;
  // strip the last scope ref
  outGraph := FCore.G(t, s);
end stripLastScopeRef;

public function topScope
"remove all the scopes, leave just the top one from the graph scopes"
  input Graph inGraph;
  output Graph outGraph;
protected
  Ref t, r;
  Scope s;
  Name gn;
  Visited v;
  Extra e;
  Next next;
algorithm
  // leave only the top scope
  outGraph := match inGraph
    case FCore.G() then arrayGet(inGraph.top.graph, 1);
  end match;
end topScope;

public function empty
"make an empty graph"
  output Graph outGraph;
algorithm
  outGraph := emptyGraph;
end empty;

public function new
"make a new graph"
  input Name inGraphName;
  input Absyn.Path inPath;
  output Graph outGraph;
protected
  Node n;
  Scope s;
  Visited v;
  Ref nr;
  Next next;
  Id id;
  array<Graph> ag;
  Top top;
algorithm
  id := System.tmpTickIndex(Global.fgraph_nextId);
  n := FNode.new(FNode.topNodeName, id, {}, FCore.TOP());
  nr := FNode.toRef(n);
  s := {nr};
  ag := Dangerous.arrayCreateNoInit(1, emptyGraph);
  top := FCore.GTOP(ag,inGraphName,nr,FCore.EXTRA(inPath));
  outGraph := FCore.G(top,s);
  // Creates a cycle, but faster to get the initial environment
  arrayUpdate(ag, 1, FCore.G(top, {nr}));
  FGraphStream.node(n);
end new;

public function node
"make a new node in the graph"
  input Graph inGraph;
  input Name inName;
  input Parents inParents;
  input Data inData;
  output Graph outGraph;
  output Node outNode;
algorithm
  (outGraph, outNode) := match(inGraph, inName, inParents, inData)
    local
      Integer i;
      Boolean b;
      Id id;
      Graph g;
      Node n;

    case (g, _, _, _)
      equation
        i = System.tmpTickIndex(Global.fgraph_nextId);
        n = FNode.new(inName, i, inParents, inData);
        FGraphStream.node(n);
        // uncomment this if unique node id's are not unique!
        /*
        b = (id == i);
        Debug.bcall1(true, print, "Next: " + intString(id) + " <-> " + intString(i) + " node: " + FNode.toStr(n) + "\n");
        // true = b;
        */
     then
       (g, n);

  end match;
end node;

public function clone
"@author: adrpo
 clone a graph. everything is copied except visited information and refs (which will be new)"
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inGraph)
    local
      Graph g;
      Top t;
      Ref nt;
      Name gn;
      Scope s;
      Visited v;
      Extra e;
      Next n "next node id for this graph";
      array<Graph> ag;

    case FCore.G(t, s)
      equation
        // make a new top
        nt = FNode.toRef(FNode.fromRef(t.node));
        // make new graph
        // g = FCore.G(t, s);
        // deep copy the top, clone the entire subtree, update references
        (g, nt) = FNode.copyRef(nt, inGraph);
        // update scope references
        s = List.map1r(s, FNode.lookupRefFromRef, nt);
        ag = arrayCreate(1, emptyGraph);
        t = FCore.GTOP(ag, t.name, nt, t.extra);
        g = FCore.G(t, s);
        arrayUpdate(ag, 1, g);
      then g;

  end match;
end clone;

public function updateComp
"This function updates a component already added to the graph, but
 that prior to the update did not have any binding. I.e this function is
 called in the second stage of instantiation with declare before use."
  input Graph inGraph;
  input DAE.Var inVar;
  input FCore.Status instStatus;
  input Graph inTargetGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue (inGraph,inVar,instStatus,inTargetGraph)
    local
      Ref pr, r;
      Name n;
      Id id;
      Parents p;
      Children c;
      SCode.Element e;
      DAE.Var i, v;
      DAE.Mod m;
      Status s;
      Kind k;
      Scope sc;
      Graph g;

    // update in the current frame
    case (g, v as DAE.TYPES_VAR(name = n), _, _)
      equation
        pr = lastScopeRef(g);
        r = FNode.child(pr, n);
        FCore.N(n, id, p, c, FCore.CO(e, m, k, _)) = FNode.fromRef(r);
        r = FNode.updateRef(r, FCore.N(n, id, p, c, FCore.CO(e, m, k, instStatus)));
        // update the target scope
        r = updateSourceTargetScope(r, currentScope(inTargetGraph));
        r = updateInstance(r, v);
      then
        g;

    // if not found update in the parent frame
    case (g, v, _, _)
      equation
        pr = lastScopeRef(g);
        true = FNode.isImplicitRefName(pr);
        (g, _) = stripLastScopeRef(g);
        g = updateComp(g, v, instStatus, inTargetGraph);
      then
        g;

    // do NOT fail!
    else inGraph;

  end matchcontinue;
end updateComp;

public function updateSourceTargetScope
"update the class scope in the source"
  input Ref inRef;
  input Scope inTargetScope;
  output Ref outRef;
algorithm
  outRef := matchcontinue (inRef,inTargetScope)
    local
      Ref pr, r;
      Graph g;
      Scope sc;

    // update the target scope of the node, hopefully existing
    case (r, _)
      equation
        r = FNode.refRef(r);
        r = FNode.updateRef(r, FNode.setData(FNode.fromRef(r), FCore.REF(inTargetScope)));
      then
        inRef;

    // create one and update it
    case (r, _)
      equation
        Error.addCompilerWarning("FNode.updateSourceTargetScope: node does not yet have a reference child: " + FNode.toPathStr(FNode.fromRef(r)) +
              " target scope: " + FNode.scopeStr(inTargetScope) + "\n");
      then
        inRef;

  end matchcontinue;
end updateSourceTargetScope;

public function updateInstance
"update the class scope in the source"
  input Ref inRef;
  input DAE.Var inVar;
  output Ref outRef;
algorithm
  outRef := matchcontinue (inRef,inVar)
    local
      Ref pr, r;
      Graph g;
      Scope sc;

    // update the instance node
    case (r, _)
      equation
        r = FNode.refInstance(r);
        r = FNode.updateRef(r, FNode.setData(FNode.fromRef(r), FCore.IT(inVar)));
      then
        inRef;

   else
    equation
      Error.addCompilerError("FGraph.updateInstance failed for node: " + FNode.toPathStr(FNode.fromRef(inRef)) + " variable:" + Types.printVarStr(inVar));
    then
      fail();

  end matchcontinue;
end updateInstance;

protected function updateVarAndMod
"update the component data"
  input Graph inGraph;
  input DAE.Var inVar;
  input DAE.Mod inMod;
  input FCore.Status instStatus;
  input Graph inTargetGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue (inGraph,inVar,inMod,instStatus,inTargetGraph)
    local
      Ref pr, r;
      Name n;
      Id id;
      Parents p;
      Children c;
      SCode.Element e;
      DAE.Var i, v;
      DAE.Mod m;
      Status s;
      Kind k;
      Scope sc;
      Graph g;

    // update in the current frame
    case (g, v as DAE.TYPES_VAR(name = n), _, _, _)
      equation
        pr = lastScopeRef(g);
        r = FNode.child(pr, n);
        FCore.N(n, id, p, c, FCore.CO(e, _, k, _)) = FNode.fromRef(r);
        r = FNode.updateRef(r, FCore.N(n, id, p, c, FCore.CO(e, inMod, k, instStatus)));
        r = updateSourceTargetScope(r, currentScope(inTargetGraph));
        r = updateInstance(r, v);
      then
        g;

    // if not found update in the parent frame
    case (g, v, _, _, _)
      equation
        pr = lastScopeRef(g);
        true = FNode.isImplicitRefName(pr);
        (g, _) = stripLastScopeRef(g);
        g = updateVarAndMod(g, v, inMod, instStatus, inTargetGraph);
      then
        g;

    // do NOT fail!
    else inGraph;

  end matchcontinue;
end updateVarAndMod;

public function updateClass
"This function updates a class element in the graph"
  input Graph inGraph;
  input SCode.Element inElement;
  input DAE.Prefix inPrefix;
  input DAE.Mod inMod;
  input FCore.Status instStatus;
  input Graph inTargetGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue (inGraph,inElement,inPrefix,inMod,instStatus,inTargetGraph)
    local
      Ref pr, r;
      Name n;
      Id id;
      Parents p;
      Children c;
      SCode.Element e;
      Kind k;
      Scope sc;
      Graph g;
      Status s;
      DAE.Mod m;
      DAE.Prefix pre;

    // update in the current frame
    case (g, e as SCode.CLASS(name = n), _, _, _, _)
      equation
        pr = lastScopeRef(g);
        r = FNode.child(pr, n);
        FCore.N(n, id, p, c, FCore.CL(_, _, _, k, _)) = FNode.fromRef(r);
        r = FNode.updateRef(r, FCore.N(n, id, p, c, FCore.CL(e, inPrefix, inMod, k, instStatus)));
        // r = updateSourceTargetScope(r, currentScope(inTargetGraph));
      then
        g;

    // if not found update in the parent frame
    case (g, e, _, _, _, _)
      equation
        pr = lastScopeRef(g);
        true = FNode.isImplicitRefName(pr);
        (g, _) = stripLastScopeRef(g);
        g = updateClass(g, e, inPrefix, inMod, instStatus, inTargetGraph);
      then
        g;
  end matchcontinue;
end updateClass;

public function updateClassElement
"This function updates a class element in the given parent ref"
  input Ref inRef;
  input SCode.Element inElement;
  input DAE.Prefix inPrefix;
  input DAE.Mod inMod;
  input FCore.Status instStatus;
  input Graph inTargetGraph;
  output Ref outRef;
algorithm
  outRef := match (inRef,inElement,inPrefix,inMod,instStatus,inTargetGraph)
    local
      Ref pr, r;
      Name n;
      Id id;
      Parents p;
      Children c;
      SCode.Element e;
      Kind k;
      Scope sc;
      Graph g;
      Status s;
      DAE.Mod m;
      DAE.Prefix pre;

    case (r, e as SCode.CLASS(name = n), _, _, _, _)
      equation
        FCore.N(_, id, p, c, FCore.CL(_, _, _, k, _)) = FNode.fromRef(r);
        r = FNode.updateRef(r, FCore.N(n, id, p, c, FCore.CL(e, inPrefix, inMod, k, instStatus)));
      then
        r;

  end match;
end updateClassElement;

public function addForIterator
"Adds a for loop iterator to the graph."
  input Graph inGraph;
  input String name;
  input DAE.Type ty;
  input DAE.Binding binding;
  input SCode.Variability variability;
  input Option<DAE.Const> constOfForIteratorRange;
  output Graph outGraph;
algorithm
  outGraph := match(inGraph, name, ty, binding, variability, constOfForIteratorRange)
    local
      Graph g;
      Ref r;
      SCode.Element c;
      DAE.Var v;

    case (g, _, _, _,_,_)
      equation
        c = SCode.COMPONENT(
              name,
              SCode.defaultPrefixes,
              SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR(), Absyn.NONFIELD()),
              Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
              SCode.noComment, NONE(), AbsynUtil.dummyInfo);
        v = DAE.TYPES_VAR(
              name,
              DAE.ATTR(DAE.NON_CONNECTOR(), SCode.NON_PARALLEL(), variability, Absyn.BIDIR(), Absyn.NOT_INNER_OUTER(), SCode.PUBLIC()),
              ty,
              binding,
              false,
              constOfForIteratorRange);
        r = lastScopeRef(g);
        g = FGraphBuildEnv.mkCompNode(c, r, FCore.BUILTIN(), g);
        // update the var too!
        g = updateVarAndMod(g, v, DAE.NOMOD(), FCore.VAR_UNTYPED(), empty());
      then
        g;

  end match;
end addForIterator;

public function printGraphPathStr "Retrive the graph current scope path as a string"
  input Graph inGraph;
  output String outString;
algorithm
  outString := matchcontinue (inGraph)
    local
      String str;
      Scope s;

    case (FCore.G(scope = s as _::_::_))
      equation
        // remove top
        _::s = listReverse(s);
        str = stringDelimitList(List.map(s, FNode.refName), ".");
      then
        str;

    else "<global scope>";

  end matchcontinue;
end printGraphPathStr;

public function openNewScope
"Opening a new scope in the graph means adding a new node in the current scope."
  input Graph inGraph;
  input SCode.Encapsulated encapsulatedPrefix;
  input Option<Name> inName;
  input Option<FCore.ScopeType> inScopeType;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue(inGraph, encapsulatedPrefix, inName, inScopeType)
    local
      Graph g;
      Name n;
      Node no;
      Ref r, p;

    // else open a new scope!
    case (g, _, SOME(n), _)
      equation
        p = lastScopeRef(g);
        (g, no) = node(g, n, {p}, FCore.ND(inScopeType));
        r = FNode.toRef(no);
        // FNode.addChildRef(p, n, r);
        g = pushScopeRef(g, r);
      then
        g;

    else
      equation
        Error.addCompilerError("FGraph.openNewScope: failed to open new scope in scope: " + getGraphNameStr(inGraph) + " name: " + Util.stringOption(inName) + "\n");
      then
        fail();

  end matchcontinue;
end openNewScope;

public function openScope
"Opening a new scope in the graph means adding a new node in the current scope."
  input Graph inGraph;
  input SCode.Encapsulated encapsulatedPrefix;
  input Name inName;
  input Option<FCore.ScopeType> inScopeType;
  output Graph outGraph;
protected
  Ref p;
algorithm
  p := lastScopeRef(inGraph);
  outGraph := matchcontinue(inGraph, encapsulatedPrefix, inName, inScopeType)
    local
      Graph g, gComp;
      Name n;
      Node no;
      Ref r;
      Scope sc;

    // see if we have it as a class instance
    case (g, _, n, _)
      equation
        r = FNode.child(p, n);
        FCore.CL(status = FCore.CLS_INSTANCE(_)) = FNode.refData(r);
        FNode.addChildRef(p, n, r);
        g = pushScopeRef(g, r);
      then
        g;

    // see if we have a child with the same name!
    case (g, _, n, _)
      equation
        r = FNode.child(p, n);
        r = FNode.copyRefNoUpdate(r);
        // FNode.addChildRef(p, n, r);
        g = pushScopeRef(g, r);
      then
        g;

    // else open a new scope!
    case (g, _, n, _)
      equation
        (g, no) = node(g, n, {p}, FCore.ND(inScopeType));
        r = FNode.toRef(no);
        // FNode.addChildRef(p, n, r);
        g = pushScopeRef(g, r);
      then
        g;

    else
      equation
        Error.addCompilerError("FGraph.openScope: failed to open new scope in scope: " + getGraphNameStr(inGraph) + " name: " + inName + "\n");
      then
        fail();

  end matchcontinue;
end openScope;

public function inForLoopScope "returns true if environment has a frame that is a for loop"
  input Graph inGraph;
  output Boolean res;
algorithm
  res := matchcontinue(inGraph)
    local
      String name;

    case(_)
      equation
        name = FNode.refName(listHead(currentScope(inGraph)));
        true = stringEq(name, FCore.forScopeName);
      then true;

    else false;

  end matchcontinue;
end inForLoopScope;

public function inForOrParforIterLoopScope "returns true if environment has a frame that is a for iterator 'loop'"
  input Graph inGraph;
  output Boolean res;
algorithm
  res := matchcontinue(inGraph)
    local String name;

    case (_)
      equation
        name = FNode.refName(listHead(currentScope(inGraph)));
        true = stringEq(name, FCore.forIterScopeName) or stringEq(name, FCore.parForIterScopeName);
      then true;

    else false;
  end matchcontinue;
end inForOrParforIterLoopScope;

public function getScopePath
"get the current scope as a path from the graph"
  input Graph inGraph;
  output Option<Absyn.Path> outPath;
algorithm
  outPath := matchcontinue(inGraph)
    local
      Absyn.Path p;
      Ref r;

    case (_)
      equation
        {r} = currentScope(inGraph);
        true = FNode.isRefTop(r);
      then
        NONE();

    case (_)
      equation
        p = getGraphName(inGraph);
      then
        SOME(p);

  end matchcontinue;
end getScopePath;

public function getGraphNameStr
"Returns the FQ name of the environment."
  input Graph inGraph;
  output String outString;
algorithm
  outString := matchcontinue(inGraph)
    case (_)
      then
        AbsynUtil.pathString(getGraphName(inGraph));
    else ".";
  end matchcontinue;
end getGraphNameStr;

public function getGraphName
"Returns the FQ name of the environment."
  input Graph inGraph;
  output Absyn.Path outPath;
protected
  Absyn.Path p;
  Scope s;
  Ref r;
algorithm
  r::s := currentScope(inGraph);
  p := AbsynUtil.makeIdentPathFromString(FNode.refName(r));
  for r in s loop
    p := Absyn.QUALIFIED(FNode.refName(r), p);
  end for;
  Absyn.QUALIFIED(_, outPath) := p;
end getGraphName;

public function getGraphNameNoImplicitScopes
"Returns the FQ name of the environment."
  input Graph inGraph;
  output Absyn.Path outPath;
protected
  Absyn.Path p;
  Scope s;
algorithm
  _::s := listReverse(currentScope(inGraph));
  outPath := AbsynUtil.stringListPath(list(str for str guard stringGet(str,1)<>36 /* "$" */ in list(FNode.refName(n) for n in s)));
end getGraphNameNoImplicitScopes;

public function pushScopeRef
"@author:adrpo
 push the given ref as first element in the graph scope list"
  input output Graph graph;
  input Ref inRef;
algorithm
  _ := match graph
    case FCore.G()
    algorithm
      graph.scope := inRef::graph.scope;
    then ();
  end match;
end pushScopeRef;

public function pushScope
"@author:adrpo
 put the given scope in the graph scope at the begining (listAppend(inScope, currentScope(graph)))"
  input output Graph graph;
  input Scope inScope;
algorithm
  _ := match graph
    case FCore.G()
    algorithm
      graph.scope := listAppend(inScope, graph.scope);
    then ();
  end match;
end pushScope;

public function setScope
"@author:adrpo
 replaces the graph scope with the given scope"
  input output Graph graph;
  input Scope inScope;
algorithm
  _ := match graph
    case FCore.G()
    algorithm
      graph.scope := inScope;
    then ();
  end match;
end setScope;

public function restrictionToScopeType
  input SCode.Restriction inRestriction;
  output Option<FCore.ScopeType> outType;
algorithm
  outType := match(inRestriction)
    case SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION()) then SOME(FCore.PARALLEL_SCOPE());
    case SCode.R_FUNCTION(SCode.FR_KERNEL_FUNCTION()) then SOME(FCore.PARALLEL_SCOPE());
    case SCode.R_FUNCTION(_) then SOME(FCore.FUNCTION_SCOPE());
    else SOME(FCore.CLASS_SCOPE());
  end match;
end restrictionToScopeType;

public function scopeTypeToRestriction
  "Converts a ScopeType to a Restriction. Restriction is much more expressive
   than ScopeType, so the returned Restriction is more of a rough indication of
   what the original Restriction was."
  input FCore.ScopeType inScopeType;
  output SCode.Restriction outRestriction;
algorithm
  outRestriction := match inScopeType
    case FCore.PARALLEL_SCOPE() then SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION());
    case FCore.FUNCTION_SCOPE() then SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(false));
    else SCode.R_CLASS();
  end match;
end scopeTypeToRestriction;

public function isTopScope "Returns true if we are in the top-most scope"
  input Graph graph;
  output Boolean isTop;
algorithm
  isTop := matchcontinue graph

    case _
      equation
        true = FNode.isRefTop(lastScopeRef(graph));
      then
        true;

    else false;

  end matchcontinue;
end isTopScope;

public function crefStripGraphScopePrefix
  "Removes the entire environment prefix from the given component reference, or
  returns the unchanged reference. This is done because models might import
  local packages, for example:

    package P
      import myP = InsideP;

      package InsideP
        function f end f;
      end InsideP;

      constant c = InsideP.f();
    end P;

    package P2
      extends P;
    end P2;

  When P2 is instantiated all elements from P will be brought into P2's scope
  due to the extends. The binding of c will still point to P.InsideP.f though, so
  the lookup will try to instantiate P which might fail if P is a partial
  package or for other reasons. This is really a bug in Lookup (it shouldn't
  need to instantiate the whole package just to find a function), but to work
  around this problem for now this function will remove the environment prefix
  when InsideP.f is looked up in P, so that it resolves to InsideP.f and not
  P.InsideP.f. This allows P2 to find it in the local scope instead, since the
  InsideP package has been inherited from P."
  input Absyn.ComponentRef inCref;
  input Graph inEnv;
  input Boolean stripPartial;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnv, stripPartial)
    local
      Absyn.Path env_path;
      Absyn.ComponentRef cref1, cref2;

    case (_, _, _)
      equation
        false = Flags.isSet(Flags.STRIP_PREFIX);
      then
        inCref;

    case (_, _, _)
      equation
        SOME(env_path) = getScopePath(inEnv);
        cref1 = AbsynUtil.unqualifyCref(inCref);
        env_path = AbsynUtil.makeNotFullyQualified(env_path);
        // try to strip as much as possible
        cref2 = crefStripGraphScopePrefix2(cref1, env_path, stripPartial);
        // check if we really did anything, fail if we did nothing!
        false = AbsynUtil.crefEqual(cref1, cref2);
      then
        cref2;

    else inCref;
  end matchcontinue;
end crefStripGraphScopePrefix;

protected function crefStripGraphScopePrefix2
  input Absyn.ComponentRef inCref;
  input Absyn.Path inEnvPath;
  input Boolean stripPartial;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnvPath, stripPartial)
    local
      Absyn.Ident id1, id2;
      Absyn.ComponentRef cref;
      Absyn.Path env_path;

    case (Absyn.CREF_QUAL(name = id1, subscripts = {}, componentRef = cref),
          Absyn.QUALIFIED(name = id2, path = env_path), _)
      equation
        true = stringEqual(id1, id2);
      then
        crefStripGraphScopePrefix2(cref, env_path, stripPartial);

    case (Absyn.CREF_QUAL(name = id1, subscripts = {}, componentRef = cref),
          Absyn.IDENT(name = id2), _)
      equation
        true = stringEqual(id1, id2);
      then
        cref;

    // adrpo: leave it as stripped as you can if you can't match it above and we have true for stripPartial
    case (Absyn.CREF_QUAL(name = id1, subscripts = {}),
          env_path, true)
      equation
        false = stringEqual(id1, AbsynUtil.pathFirstIdent(env_path));
      then
        inCref;
  end matchcontinue;
end crefStripGraphScopePrefix2;

public function pathStripGraphScopePrefix
"same as pathStripGraphScopePrefix"
  input Absyn.Path inPath;
  input Graph inEnv;
  input Boolean stripPartial;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEnv, stripPartial)
    local
      Absyn.Path env_path;
      Absyn.Path path1, path2;

    case (_, _, _)
      equation
        false = Flags.isSet(Flags.STRIP_PREFIX);
      then inPath;

    case (_, _, _)
      equation
        SOME(env_path) = getScopePath(inEnv);
        path1 = AbsynUtil.makeNotFullyQualified(inPath);
        env_path = AbsynUtil.makeNotFullyQualified(env_path);
        // try to strip as much as possible
        path2 = pathStripGraphScopePrefix2(path1, env_path, stripPartial);
        // check if we really did anything, fail if we did nothing!
        false = AbsynUtil.pathEqual(path1, path2);
      then
        path2;

    else inPath;
  end matchcontinue;
end pathStripGraphScopePrefix;

protected function pathStripGraphScopePrefix2
  input Absyn.Path inPath;
  input Absyn.Path inEnvPath;
  input Boolean stripPartial;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPath, inEnvPath, stripPartial)
    local
      Absyn.Ident id1, id2;
      Absyn.Path path;
      Absyn.Path env_path;

    case (Absyn.QUALIFIED(name = id1, path = path),
          Absyn.QUALIFIED(name = id2, path = env_path), _) guard stringEqual(id1, id2)
      then
        pathStripGraphScopePrefix2(path, env_path, stripPartial);

    case (Absyn.QUALIFIED(name = id1, path = path),
          Absyn.IDENT(name = id2), _) guard stringEqual(id1, id2)
      then
        path;

    // adrpo: leave it as stripped as you can if you can't match it above and stripPartial is true
    case (Absyn.QUALIFIED(name = id1), env_path, true) guard not stringEqual(id1, AbsynUtil.pathFirstIdent(env_path))
      then
        inPath;
  end match;
end pathStripGraphScopePrefix2;

public function mkComponentNode "This function adds a component to the graph."
  input Graph inGraph;
  input DAE.Var inVar;
  input SCode.Element inVarEl;
  input DAE.Mod inMod;
  input Status instStatus;
  input Graph inCompGraph;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue (inGraph,inVar,inVarEl,inMod,instStatus,inCompGraph)
    local
      Option<Name> id;
      Option<FCore.ScopeType> st;
      list<SCode.Element> du;
      DAE.Var v;
      Name n;
      SCode.Element c;
      Graph g, cg;
      DAE.Mod m;
      Ref r;
      FCore.Status i;

    // Graph of component
    case (_, DAE.TYPES_VAR(name = n),c,_,_,_)
      equation
        // maks sure the element name and the DAE.TYPES_VAR name is the same!
        false = stringEq(n, SCodeUtil.elementName(c));
        Error.addCompilerError("FGraph.mkComponentNode: The component name: " + SCodeUtil.elementName(c) + " is not the same as its DAE.TYPES_VAR: " + n + "\n");
      then
        fail();

    // Graph of component
    case (g, v as DAE.TYPES_VAR(name = n),c,m,i,cg)
      equation
        // make sure the element name and the DAE.TYPES_VAR name is the same!
        true = stringEq(n, SCodeUtil.elementName(c));
        r = lastScopeRef(g);
        g = FGraphBuildEnv.mkCompNode(c, r, FCore.USERDEFINED(), g);
        // update the var too!
        g = updateVarAndMod(g, v, m, i, cg);
      then
        g;

  end matchcontinue;
end mkComponentNode;

public function mkClassNode
"This function adds a class definition to the environment.
 Enumeration are expanded from a list into a class with components"
  input Graph inGraph;
  input SCode.Element inClass;
  input DAE.Prefix inPrefix;
  input DAE.Mod inMod;
  input Boolean checkDuplicate = false;
  output Graph outGraph;
algorithm
  outGraph := matchcontinue (inGraph, inClass, inPrefix, inMod)
    local
      Name n;
      Graph g;
      Ref r;

    // already there as class instance, do nothing!
    case (g, SCode.CLASS(name = n), _, _)
      equation
        r = lastScopeRef(g);
        r = FNode.child(r, n);
        FCore.CL(status = FCore.CLS_INSTANCE(_)) = FNode.refData(r);
      then
        g;

    case (g, SCode.CLASS(), _, _)
      equation
        r = lastScopeRef(g);
        g = FGraphBuildEnv.mkClassNode(inClass, inPrefix, inMod, r,
          FCore.USERDEFINED(), g, checkDuplicate);
      then
        g;

  end matchcontinue;
end mkClassNode;

public function mkTypeNode
"This function adds a class definition to the environment.
 Enumeration are expanded from a list into a class with components"
  input Graph inGraph;
  input Name inName;
  input DAE.Type inType;
  output Graph outGraph;
algorithm
  outGraph := match (inGraph, inName, inType)
    local
      Name n;
      Graph g;
      Ref r;

    case (g, _, _)
      equation
        r = lastScopeRef(g);
        g = FGraphBuildEnv.mkTypeNode({inType}, r, inName, g);
      then
        g;

  end match;
end mkTypeNode;

public function mkImportNode
"This function adds a class definition to the environment.
 Enumeration are expanded from a list into a class with components"
  input Graph inGraph;
  input SCode.Element inImport;
  output Graph outGraph;
algorithm
  outGraph := match (inGraph, inImport)
    local
      Name n;
      Graph g;
      Ref r;

    case (g, _)
      equation
        r = lastScopeRef(g);
        g = FGraphBuildEnv.mkElementNode(inImport, r, FCore.USERDEFINED(), g);
      then
        g;

  end match;
end mkImportNode;

public function mkDefunitNode
"This function adds a class definition to the environment.
 Enumeration are expanded from a list into a class with components"
  input Graph inGraph;
  input SCode.Element inDu;
  output Graph outGraph;
algorithm
  outGraph := match (inGraph, inDu)
    local
      Name n;
      Graph g;
      Ref r;

    case (g, _)
      equation
        r = lastScopeRef(g);
        g = FGraphBuildEnv.mkElementNode(inDu, r, FCore.USERDEFINED(), g);
      then
        g;

  end match;
end mkDefunitNode;

public function classInfToScopeType
  input ClassInf.State inState;
  output Option<FCore.ScopeType> outType;
algorithm
  outType := match(inState)
    case ClassInf.FUNCTION() then SOME(FCore.FUNCTION_SCOPE());
    else SOME(FCore.CLASS_SCOPE());
  end match;
end classInfToScopeType;

public function isEmpty
"returns true if empty graph"
  input Graph inGraph;
  output Boolean b;
algorithm
  b := match(inGraph)
    case (FCore.EG(_)) then true;
    else false;
  end match;
end isEmpty;

public function isNotEmpty
"returns true if not empty graph"
  input Graph inGraph;
  output Boolean b;
algorithm
  b := not isEmpty(inGraph);
end isNotEmpty;

public function isEmptyScope
  input Graph graph;
  output Boolean isEmpty;
algorithm
  try
    isEmpty := RefTree.isEmpty(FNode.children(FNode.fromRef(lastScopeRef(graph))));
  else
    isEmpty := true;
  end try;
end isEmptyScope;

public function printGraphStr
"prints the graph"
  input Graph inGraph;
  output String s;
algorithm
  s := "NOT IMPLEMENTED YET";
end printGraphStr;

public function inFunctionScope
  input Graph inGraph;
  output Boolean inFunction;
algorithm
  inFunction := match(inGraph)
    local
      Scope s;
      Ref r;

    case FCore.G(scope = s) guard checkScopeType(s, SOME(FCore.FUNCTION_SCOPE())) or
                                  checkScopeType(s, SOME(FCore.PARALLEL_SCOPE()))
      then
        true;

    else false;

  end match;
end inFunctionScope;

public function getScopeName " Returns the name of a scope, if no name exist, the function fails."
  input Graph inGraph;
  output Name name;
algorithm
  name := match (inGraph)
    local Ref r;
    case (_)
      equation
        r = lastScopeRef(inGraph);
        // not top
        false = FNode.isRefTop(r);
        name = FNode.refName(r);
      then
        name;
  end match;
end getScopeName;

public function checkScopeType
  input Scope inScope;
  input Option<FCore.ScopeType> inScopeType;
  output Boolean yes;
algorithm
  yes := matchcontinue(inScope, inScopeType)
    local
      Ref r;
      Scope rest;
      SCode.Restriction restr;
      Option<FCore.ScopeType> st;

    case ({}, _) then false;

    // classes
    case (r::_, _)
      equation
        true = FNode.isRefClass(r);
        restr = SCodeUtil.getClassRestriction(FNode.getElement(FNode.fromRef(r)));
        true = valueEq(restrictionToScopeType(restr), inScopeType);
      then
        true;

    // FCore.ND(scopeType)
    case (r::_, _)
      equation
        FCore.N(data = FCore.ND(st)) = FNode.fromRef(r);
        true = valueEq(st, inScopeType);
      then
        true;

    case (_::rest, _)
      then
        checkScopeType(rest, inScopeType);

  end matchcontinue;
end checkScopeType;

public function lastScopeRestriction
  input Graph inGraph;
  output SCode.Restriction outRestriction;
protected
  Scope s;
algorithm
  FCore.G(scope = s) := inGraph;
  outRestriction := getScopeRestriction(s);
end lastScopeRestriction;

public function getScopeRestriction
  input Scope inScope;
  output SCode.Restriction outRestriction;
algorithm
  outRestriction := matchcontinue inScope
    local
      Ref r;
      FCore.ScopeType st;

    case r :: _ guard(FNode.isRefClass(r))
      then SCodeUtil.getClassRestriction(FNode.getElement(FNode.fromRef(r)));

    case r :: _
      algorithm
        FCore.N(data = FCore.ND(SOME(st))) := FNode.fromRef(r);
      then
        scopeTypeToRestriction(st);

    else getScopeRestriction(listRest(inScope));

  end matchcontinue;
end getScopeRestriction;

public function getGraphPathNoImplicitScope
"This function returns all partially instantiated parents as an Absyn.Path
 option I.e. it collects all identifiers of each frame until it reaches
 the topmost unnamed frame. If the environment is only the topmost frame,
 NONE() is returned."
  input Graph inGraph;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm
  outAbsynPathOption := getGraphPathNoImplicitScope_dispatch(currentScope(inGraph));
end getGraphPathNoImplicitScope;

protected function getGraphPathNoImplicitScope_dispatch
"This function returns all partially instantiated parents as an Absyn.Path
 option I.e. it collects all identifiers of each frame until it reaches
 the topmost unnamed frame. If the environment is only the topmost frame,
 NONE() is returned."
  input Scope inScope;
  output Option<Absyn.Path> outAbsynPathOption;
protected
  Option<Absyn.Path> opath;
algorithm
  outAbsynPathOption := matchcontinue (inScope)
    local
      Name id;
      Absyn.Path path,path_1;
      Scope rest;
      Ref ref;

    case (ref :: rest)
      guard
        not FNode.isRefTop(ref)
      algorithm
        id := FNode.refName(ref);
        if isImplicitScope(id) then
          opath := getGraphPathNoImplicitScope_dispatch(rest);
        else
          opath := getGraphPathNoImplicitScope_dispatch(rest);
          if isSome(opath) then
            SOME(path) := opath;
            path_1 := AbsynUtil.joinPaths(path, Absyn.IDENT(id));
            opath := SOME(path_1);
          else
            opath := SOME(Absyn.IDENT(id));
          end if;
        end if;
      then
        opath;

    else NONE();

  end matchcontinue;
end getGraphPathNoImplicitScope_dispatch;

public function isImplicitScope
  input Name inName;
  output Boolean isImplicit;
algorithm
  isImplicit := FCore.isImplicitScope(inName);
end isImplicitScope;

public function joinScopePath "Used to join an Graph scope with an Absyn.Path (probably an IDENT)"
  input Graph inGraph;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
protected
  Option<Absyn.Path> opath;
  Absyn.Path envPath;
algorithm
  opath := getScopePath(inGraph);
  if isSome(opath) then
    SOME(envPath) := opath;
    outPath := AbsynUtil.joinPaths(envPath,inPath);
  else
    outPath := inPath;
  end if;
end joinScopePath;

public function splitGraphScope
"splits out the for loop scope from the graph scope"
  input Graph inGraph;
  output Graph outRealGraph;
  output Scope outForScope;
algorithm
  (outRealGraph, outForScope) := splitGraphScope_dispatch(inGraph, {});
end splitGraphScope;

public function splitGraphScope_dispatch
"splits out the for loop scope from the graph scope"
  input Graph inGraph;
  input Scope inAcc;
  output Graph outRealGraph;
  output Scope outForScope;
algorithm
  (outRealGraph, outForScope) := match(inGraph, inAcc)
    local
      Graph g;
      Ref r;
      Scope s;

    case (FCore.EG(_), _) then (inGraph, listReverse(inAcc));

    case (FCore.G(scope = r::_), _)
      equation
        if FNode.isImplicitRefName(r) then
          (g, _) = stripLastScopeRef(inGraph);
          (g, s) = splitGraphScope_dispatch(g, r::inAcc);
        else
          g = inGraph;
          s = listReverse(inAcc);
        end if;
      then
        (g, s);

  end match;
end splitGraphScope_dispatch;

public function getVariablesFromGraphScope
"@author: adrpo
  returns the a list with all the variables names in the given graph from the last graph scope"
  input Graph inGraph;
  output list<Name> variables;
algorithm
  variables := match (inGraph)
    local
      list<Name> lst;
      Ref r;

    // empty case
    case FCore.EG(_) then {};

    // some graph, no scope
    case FCore.G(scope = {}) then {};

    // some graph
    case FCore.G(scope = r::_)
      equation
        lst = List.map(FNode.filter(r, FNode.isRefComponent), FNode.refName);
      then
        lst;

  end match;
end getVariablesFromGraphScope;

public function removeComponentsFromScope
"@author:adrpo
 remove the children of the last ref"
  input Graph inGraph;
  output Graph outGraph;
protected
  Ref r;
  Node n;
algorithm
  r := lastScopeRef(inGraph);
  r := FNode.copyRefNoUpdate(r);
  n := FNode.fromRef(r);
  n := FNode.setChildren(n, RefTree.new());
  r := FNode.updateRef(r, n);
  (outGraph, _) := stripLastScopeRef(inGraph);
  outGraph := pushScopeRef(outGraph, r);
end removeComponentsFromScope;

public function cloneLastScopeRef
  input Graph inGraph;
  output Graph outGraph;
protected
  Ref r;
algorithm
  (outGraph, r) := stripLastScopeRef(inGraph);
  r := FNode.copyRefNoUpdate(r);
  outGraph := pushScopeRef(outGraph, r);
end cloneLastScopeRef;

public function updateScope
  input Graph inGraph;
  output Graph outGraph;
algorithm
  outGraph := match(inGraph)
    case (_) then inGraph;
  end match;
end updateScope;

public function mkVersionNode
"@author: adrpo
 THE MOST IMPORTANT FUNCTION IN THE COMPILER :)
 This function works like this:
 From source scope:
   A.B.C.D
 we lookup a target scope
   X.Y.Z.W
 to be used for a component, derived class, or extends
 We get back X.Y.Z + CLASS(W) via lookup.
 We build X.Y.Z.W_newVersion and return it.
 The newVersion name is generated by mkVersionName based on
 the source scope, the element name, prefix and modifiers.
 The newVersion scope is only created if there are non emtpy
 modifiers given to this functions"
  input Graph inSourceEnv;
  input Name inSourceName;
  input DAE.Prefix inPrefix;
  input DAE.Mod inMod;
  input Graph inTargetClassEnv;
  input SCode.Element inTargetClass;
  input InnerOuter.InstHierarchy inIH;
  output Graph outVersionedTargetClassEnv;
  output SCode.Element outVersionedTargetClass;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outVersionedTargetClassEnv, outVersionedTargetClass, outIH) := matchcontinue(inSourceEnv, inSourceName, inPrefix, inMod, inTargetClassEnv, inTargetClass, inIH)
    local
      Graph gclass;
      Ref classRef, sourceRef, targetClassParentRef, versionRef;
      Node n;
      Ref r;
      DAE.Prefix crefPrefix;
      Scope sourceScope;
      SCode.Element c;
      Name targetClassName, newTargetClassName;
      InnerOuter.InstHierarchy ih;

    /*
    case (_, _, _, _, _, _, _)
      equation
        c = inTargetClass;
        gclass = inTargetClassEnv;
        targetClassName = SCodeUtil.elementName(c);

        (newTargetClassName, crefPrefix) = mkVersionName(inSourceEnv, inSourceName, inPrefix, inMod, inTargetClassEnv, targetClassName);

        // get the last scope from target
        targetClassParentRef = lastScopeRef(inTargetClassEnv);
        classRef = FNode.child(targetClassParentRef, newTargetClassName);
        c = FNode.getElementFromRef(classRef);
      then
        (inTargetClassEnv, c, inIH);*/

    case (_, _, _, _, _, _, _)
      equation
        c = inTargetClass;
        gclass = inTargetClassEnv;
        targetClassName = SCodeUtil.elementName(c);

        (newTargetClassName, crefPrefix) = mkVersionName(inSourceEnv, inSourceName, inPrefix, inMod, inTargetClassEnv, targetClassName);

        // get the last item in the source env
        sourceRef = FNode.child(lastScopeRef(inSourceEnv), inSourceName);
        _ = sourceRef :: currentScope(inSourceEnv);

        // get the last scope from target
        targetClassParentRef = lastScopeRef(inTargetClassEnv);
        // get the class from class env
        classRef = FNode.child(targetClassParentRef, targetClassName);
        // clone the class
        classRef = FNode.copyRefNoUpdate(classRef);

        // check if the name of the class already exists!
        // failure(_ = FNode.child(targetClassParentRef, newTargetClassName));

        // change class name (so unqualified references to the same class reach the original element
        FCore.CL(e = c) = FNode.refData(classRef);
        c = SCodeUtil.setClassName(newTargetClassName, c);
        classRef = updateClassElement(classRef, c, crefPrefix, inMod, FCore.CLS_INSTANCE(targetClassName) /* FCore.CLS_UNTYPED() */, empty());
        // parent the classRef
        FNode.addChildRef(targetClassParentRef, newTargetClassName, classRef);
        // update the source target scope
        sourceRef = updateSourceTargetScope(sourceRef, classRef :: currentScope(gclass));

        // we never need to add the instance as inner!
        ih = inIH; // ih = InnerOuter.addClassIfInner(c, crefPrefix, gclass, inIH);

        /*
        print("Instance1: CL(" + getGraphNameStr(inSourceEnv) + ").CO(" +
              inSourceName + ").CL(" + getGraphNameStr(inTargetClassEnv) + "." +
              targetClassName + SCodeDump.printModStr(Mod.unelabMod(inMod), SCodeDump.defaultOptions) + ")\n\t" +
              newTargetClassName + "\n");*/
      then
        (gclass, c, ih);

    else
      equation
        c = inTargetClass;
        targetClassName = SCodeUtil.elementName(c);
        (newTargetClassName,_) = mkVersionName(inSourceEnv, inSourceName, inPrefix, inMod, inTargetClassEnv, targetClassName);

        Error.addCompilerWarning(
          "FGraph.mkVersionNode: failed to create version node:\n" +
          "Instance: CL(" + getGraphNameStr(inSourceEnv) + ").CO(" +
          inSourceName + ").CL(" + getGraphNameStr(inTargetClassEnv) + "." +
          targetClassName + SCodeDump.printModStr(Mod.unelabMod(inMod), SCodeDump.defaultOptions) + ")\n\t" +
          newTargetClassName + "\n");
      then
        (inTargetClassEnv, inTargetClass, inIH);

  end matchcontinue;
end mkVersionNode;

public function createVersionScope
  input Graph inSourceEnv;
  input Name inSourceName;
  input DAE.Prefix inPrefix;
  input DAE.Mod inMod;
  input Graph inTargetClassEnv;
  input SCode.Element inTargetClass;
  input InnerOuter.InstHierarchy inIH;
  output Graph outVersionedTargetClassEnv;
  output SCode.Element outVersionedTargetClass;
  output InnerOuter.InstHierarchy outIH;
algorithm
  (outVersionedTargetClassEnv, outVersionedTargetClass, outIH) := matchcontinue(inSourceEnv, inSourceName, inPrefix, inMod, inTargetClassEnv, inTargetClass, inIH)
    local
      Graph gclass;
      SCode.Element c;

    /*
    case (_, _, _, _, _, _, _)
      equation
        print(AbsynUtil.pathString(PrefixUtil.prefixToPath(inPrefix)) + " S:" + getGraphNameStr(inSourceEnv) + "/" + inSourceName + " ||| " + "T:" + getGraphNameStr(inTargetClassEnv) + "/" + SCodeUtil.elementName(inTargetClass) + "\n");
      then
        fail();*/

    // case (_, _, _, _, _, _, _) then (inTargetClassEnv, inTargetClass, inIH);

    // don't do this if there is no modifications on the class
    // TODO! FIXME! wonder if we can skip this if it has only a binding, not an actual type modifier
    case (_, _, _, DAE.NOMOD(), _, _, _) then (inTargetClassEnv, inTargetClass, inIH);
    case (_, _, _, DAE.MOD(subModLst={}), _, _, _) then (inTargetClassEnv, inTargetClass, inIH);

    // don't do this for MetaModelica, target class is builtin or builtin type, functions
    case (_, _, _, _, _, _, _)
      equation
        true = Config.acceptMetaModelicaGrammar() or
               isTargetClassBuiltin(inTargetClassEnv, inTargetClass) or
               inFunctionScope(inSourceEnv) or
               SCodeUtil.isOperatorRecord(inTargetClass);
      then
        (inTargetClassEnv, inTargetClass, inIH);

    // or OpenModelica scripting stuff
    case (_, _, _, _, _, _, _)
      equation
        true = stringEq(AbsynUtil.pathFirstIdent(getGraphName(inTargetClassEnv)), "OpenModelica");
      then
        (inTargetClassEnv, inTargetClass, inIH);

    // need to create a new version of the class
    case (_, _, _, _, _, _, _)
      equation
        (gclass, c, outIH) = mkVersionNode(inSourceEnv, inSourceName, inPrefix, inMod, inTargetClassEnv, inTargetClass, inIH);
      then
        (gclass, c, outIH);

  end matchcontinue;
end createVersionScope;

public function isTargetClassBuiltin
  input Graph inGraph;
  input SCode.Element inClass;
  output Boolean yes;
algorithm
  yes := matchcontinue(inGraph, inClass)
    local Ref r;
    case (_, _)
      equation
        r = FNode.child(lastScopeRef(inGraph), SCodeUtil.elementName(inClass));
        yes = FNode.isRefBasicType(r) or FNode.isRefBuiltin(r);
      then
        yes;

    else false;
  end matchcontinue;
end isTargetClassBuiltin;

public function mkVersionName
  input Graph inSourceEnv;
  input Name inSourceName;
  input DAE.Prefix inPrefix;
  input DAE.Mod inMod;
  input Graph inTargetClassEnv;
  input Name inTargetClassName;
  output Name outName;
  output DAE.Prefix outCrefPrefix;
algorithm
  (outName, outCrefPrefix) := match(inSourceEnv, inSourceName, inPrefix, inMod, inTargetClassEnv, inTargetClassName)
    local
      Graph gcomp, gclass;
      Ref classRef;
      Ref compRef;
      Node n;
      Ref r;
      DAE.Prefix crefPrefix;
      Name name;

    case (_, _, _, _, _, _)
      equation
        crefPrefix = PrefixUtil.prefixAdd(inSourceName,{},{},inPrefix,SCode.CONST(),ClassInf.UNKNOWN(Absyn.IDENT("")), AbsynUtil.dummyInfo); // variability doesn't matter

        // name = inTargetClassName + "$" + ComponentReference.printComponentRefStr(PrefixUtil.prefixToCref(crefPrefix));
        name = inTargetClassName + "$" + AbsynUtil.pathString(AbsynUtil.stringListPath(listReverse(AbsynUtil.pathToStringList(PrefixUtil.prefixToPath(crefPrefix)))), "$", usefq=false)
               ; // + "$" + AbsynUtil.pathString2NoLeadingDot(getGraphName(inSourceEnv), "$");
        // name = "'$" + inTargetClassName + "@" + AbsynUtil.pathString(AbsynUtil.stringListPath(listReverse(AbsynUtil.pathToStringList(PrefixUtil.prefixToPath(crefPrefix))))) + "'";
        // name = "'$" + getGraphNameStr(inSourceEnv) + "." + AbsynUtil.pathString(AbsynUtil.stringListPath(listReverse(AbsynUtil.pathToStringList(PrefixUtil.prefixToPath(crefPrefix))))) + "'";
        // name = "$'" + getGraphNameStr(inSourceEnv) + "." +
        //        AbsynUtil.pathString(AbsynUtil.stringListPath(listReverse(AbsynUtil.pathToStringList(PrefixUtil.prefixToPath(crefPrefix))))) +
        //        SCodeDump.printModStr(Mod.unelabMod(inMod), SCodeDump.defaultOptions);
      then
        (name, crefPrefix);

  end match;
end mkVersionName;

public function getClassPrefix
  input FCore.Graph inEnv;
  input Name inClassName;
  output DAE.Prefix outPrefix;
algorithm
  outPrefix := matchcontinue(inEnv, inClassName)
    local
      DAE.Prefix p;
      Ref r;

    case (_, _)
      equation
        r = FNode.child(lastScopeRef(inEnv), inClassName);
        FCore.CL(pre = p) = FNode.refData(r);
      then
        p;

    else DAE.NOPRE();

  end matchcontinue;
end getClassPrefix;

public function isInstance
  input FCore.Graph inEnv;
  input FCore.Name inName;
  output Boolean yes;
algorithm
  yes := matchcontinue(inEnv, inName)

    case (_, _)
      equation
         FCore.CL(status = FCore.CLS_INSTANCE(_)) = FNode.refData(FNode.child(lastScopeRef(inEnv), inName));
       then
         true;

    else false;

  end matchcontinue;
end isInstance;

public function getInstanceOriginalName
  input FCore.Graph inEnv;
  input FCore.Name inName;
  output FCore.Name outName;
algorithm
  outName := matchcontinue(inEnv, inName)

    case (_, _)
      equation
         FCore.CL(status = FCore.CLS_INSTANCE(outName)) = FNode.refData(FNode.child(lastScopeRef(inEnv), inName));
       then
         outName;

    else inName;

  end matchcontinue;
end getInstanceOriginalName;

public function graphPrefixOf
"note that A.B.C is not prefix of A.B.C,
 only A.B is a prefix of A.B.C"
  input Graph inPrefixEnv;
  input Graph inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := graphPrefixOf2(listReverse(currentScope(inPrefixEnv)), listReverse(currentScope(inEnv)));
end graphPrefixOf;

public function graphPrefixOf2
"Checks if one environment is a prefix of another.
 note that A.B.C is not prefix of A.B.C,
 only A.B is a prefix of A.B.C"
  input Scope inPrefixEnv;
  input Scope inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := match(inPrefixEnv, inEnv)
    local
      String n1, n2;
      Scope rest1, rest2;
      Ref r1, r2;

    case ({}, _::_) then true;

    case (r1 :: rest1, r2 :: rest2) guard stringEq(FNode.refName(r1), FNode.refName(r2))
      then
        graphPrefixOf2(rest1, rest2);

    else false;

  end match;
end graphPrefixOf2;

public function setStatus
  input Graph inEnv;
  input Name inName;
  input FCore.Data inStatus;
  output Graph outEnv;
algorithm
  outEnv := matchcontinue(inEnv, inName, inStatus)
    local
      Graph g;
      Node n;
      Ref ref, refParent;

    case (g, _, _)
      equation
        refParent = lastScopeRef(g);
        if FNode.refHasChild(refParent, inName) then
          ref = FNode.child(refParent, inName);
          if FNode.refHasChild(ref, FNode.statusNodeName) then
            // child exists and has a status node
            ref = FNode.child(ref, FNode.statusNodeName);
            n = FNode.setData(FNode.fromRef(ref), inStatus);
            ref = FNode.updateRef(ref, n);
          else
            // child exists but has no status node
            (g, n) = node(g, FNode.statusNodeName, {ref}, inStatus);
            FNode.addChildRef(ref, FNode.statusNodeName, FNode.toRef(n));
          end if;
        //else child does not exist, do nothing, is an import or extends
        end if;
      then
        g;

    // did we fail for some weird reson?
    case (g, _, _)
      equation
        print("FGraph.setStatus failed on: " + getGraphNameStr(g) + " element: " + inName + "\n");
      then
        g;

  end matchcontinue;
end setStatus;

public function getStatus
  input Graph inEnv;
  input Name inName;
  output FCore.Data outStatus;
algorithm
  outStatus := match(inEnv, inName)
    local
      Graph g;
      Node n;
      Ref ref, refParent;
      FCore.Data s;

    // child exists and has a status node
    case (g, _)
      equation
        refParent = lastScopeRef(g);
        true = FNode.refHasChild(refParent, inName);
        ref = FNode.child(refParent, inName);
        true = FNode.refHasChild(ref, FNode.statusNodeName);
        ref = FNode.child(ref, FNode.statusNodeName);
        s = FNode.refData(ref);
      then
        s;

    // we can fail here with no problem, there is no status node!
    case (_, _)
      equation
        // print("FGraph.getStatus failed on: " + getGraphNameStr(g) + " element: " + inName + "\n");
      then
        fail();

  end match;
end getStatus;

public function selectScope
"return the environment pointed by the path if it exists, else fails"
  input Graph inEnv;
  input Absyn.Path inPath;
  output Graph outEnv;
algorithm
  outEnv := match(inEnv, inPath)
    local
      Graph env;
      list<String> pl, el;
      Integer lp, le, diff;
      Scope cs;
      Absyn.Path p;

    case (_, _)
      equation
        p = AbsynUtil.stripLast(inPath);
        true = AbsynUtil.pathPrefixOf(p, getGraphName(inEnv));
        pl = AbsynUtil.pathToStringList(p);
        lp = listLength(pl);
        cs = currentScope(inEnv);
        le = listLength(cs) - 1;
        diff = le - lp;
        cs = List.stripN(cs, diff);
        env = setScope(inEnv, cs);
        // print("F: " + AbsynUtil.pathString(inPath) + "\n"); print("E: " + getGraphNameStr(inEnv) + "\n"); print("R: " + getGraphNameStr(env) + "\n");
      then
        env;

  end match;
end selectScope;

public function makeScopePartial
  input Graph inEnv;
  output Graph outEnv = inEnv;
protected
  Node node;
  Data data;
  SCode.Element el;
algorithm
  try
    node := FNode.fromRef(lastScopeRef(inEnv));
    node := match node
      case FCore.N(data = data as FCore.CL(e = el))
        algorithm
          el := SCodeUtil.makeClassPartial(el);
          data.e := el;
          node.data := data;
        then
          node;

      else node;
    end match;
    outEnv := setLastScopeRef(FNode.toRef(node), outEnv);
  else
  end try;
end makeScopePartial;

public function isPartialScope
  input Graph inEnv;
  output Boolean outIsPartial;
protected
  SCode.Element el;
algorithm
  try
    FCore.N(data = FCore.CL(e = el)) := FNode.fromRef(lastScopeRef(inEnv));
    outIsPartial := SCodeUtil.isPartial(el);
  else
    outIsPartial := false;
  end try;
end isPartialScope;

annotation(__OpenModelica_Interface="frontend");
end FGraph;

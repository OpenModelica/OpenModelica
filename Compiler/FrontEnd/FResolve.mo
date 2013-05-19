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

encapsulated package FResolve
" file:        FResolve.mo
  package:     FResolve
  description: SCode dependency analysis that resolved all elements before instantiation

  RCS: $Id: FResolve.mo 14085 2012-11-27 12:12:40Z adrpo $

  SCode dependency analysis that resolves all elements before instantiation
"

public import Absyn;
public import SCode;
public import Util;
public import FNode;
public import DAE;
public import FGraphEnv;
public import FGraph;

public type Ident = FNode.Ident;
public type NodeId = FNode.NodeId;
public type Name = FNode.Name;
public type Type = DAE.Type;
public type Types = list<DAE.Type>;
public type Node = FNode.Node;
public type NodeData = FNode.NodeData;
public type Ref = FNode.Ref;
public type NameRef = FNode.NameRef;
public type Refs = FNode.Refs;
public type Env = FGraphEnv.Env;
public type Graph = FGraph.Graph;

protected import FRef;

public function resolve
  input Env inEnv;
  input NodeId inRef;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inRef, inRefs)
    local
      NodeId r;
      list<NodeId> rfs;
      Node n;
      Env e;
      
    case (_, _, _)
      equation
        n = FGraphEnv.getNode(inEnv, inRef);
        (e, r, rfs) = resolveNode(inEnv, n, inRefs);
      then
        (e, r, rfs);
    
    else
      equation
        n = FGraphEnv.getNode(inEnv, inRef);
        print("Could not resolve reference: " +& FRef.stringFromNodeData(FNode.getNodeData(n)) +& " in env: " +& FGraphEnv.name(inEnv) +& "\n");  
      then
        fail();
  end matchcontinue;
end resolve;

public function resolvePath
  input Env inEnv;
  input Absyn.Path inPath;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
protected
  Node rnode;
  NodeData nd;
  Graph g; 
  Name n;
  Absyn.TypeSpec ts;
  Env e;
algorithm
  g := FGraphEnv.getGraph(inEnv);
  ts := Absyn.pathToTypeSpec(inPath);
  nd := FNode.mkTRData(ts);
  n := FNode.refName(nd);
  // add it as a child of noNode
  (g, rnode) := FGraph.mkChildNode(g, n, FNode.noNodeId, nd);
  e := FGraphEnv.setGraph(inEnv, g);
  (outEnv, outRef, outRefs) := resolve(e, FNode.getNodeId(rnode), {});
end resolvePath;

public function resolveNode
  input Env inEnv;
  input Node inNode;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inNode, inRefs)
    local
      NodeId r;
      list<NodeId> rfs;
      Node n;
      Env e;
      Ref ref;
      NodeId id, pid;
      Name name;
      FNode.AvlTree children;
      Absyn.TypeSpec ts;
      Absyn.ComponentRef cr;
    
    // resolve type reference  
    case (_, FNode.N(id, pid, name, children, FNode.TR(ts, ref)), _)
      equation
        (e, ref, rfs) = resolveRef(inEnv, ref, inRefs);
        n = FNode.N(id, pid, name, children, FNode.TR(ts, ref));
        // update node
        e = FGraphEnv.setGraph(e, FGraph.setNode(FGraphEnv.getGraph(e), id, n));
      then
        (e, id, rfs);
    
    // resolve component reference    
    case (_, FNode.N(id, pid, name, children, FNode.CR(cr, ref)), _)
      equation
        (e, ref, rfs) = resolveRef(inEnv, ref, inRefs);
        n = FNode.N(id, pid, name, children, FNode.CR(cr, ref));
        // update node
        e = FGraphEnv.setGraph(e, FGraph.setNode(FGraphEnv.getGraph(e), id, n));
      then
        (e, id, rfs);    
    else
      equation
        print("Could not resolve reference: " +& FRef.stringFromNodeData(FNode.getNodeData(inNode)) +& " in env: " +& FGraphEnv.name(inEnv) +& "\n");  
      then
        fail();
  end matchcontinue;
end resolveNode;

public function resolveRef
  input Env inEnv;
  input Ref inRef;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output Ref outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inRef, inRefs)
    local
      Ref r, rest;
      Refs rfs, subs;
      NameRef n;
      Env e;
      list<NodeId> nrefs;
      
    // one name ref
    case (_, {n}, _)
      equation
        (e, n, nrefs) = resolveName(inEnv, n, inRefs);
      then
        (e, {n}, nrefs);
    
    // multiple
    case (_, n::rest, _)
      equation
        (e, n, nrefs) = resolveName(inEnv, n, inRefs);
        (e, r, nrefs) = resolveRef(e, rest, nrefs);
      then
        (e, n::r, nrefs);
    
  end matchcontinue;
end resolveRef;

public function resolveName
  input Env inEnv;
  input NameRef inRef;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NameRef outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inRef, inRefs)
    local
      NodeId i;
      Refs rfs, subs;
      Name n;
      Env e;
      list<NodeId> nrefs;
      NameRef r;
      
    // unresolved ref
    case (_, FNode.U(n, subs), _)
      equation
        (e, i, nrefs) = resolveIdent(inEnv, n, inRefs);
        // where do we resolve the subs?
        (e, subs, nrefs) = resolveSubs(e, subs, nrefs);
        r = FNode.R(n, subs, i);
      then
        (e, r, nrefs);
    
    // already resolved ref, open scope and return
    case (_, FNode.R(n, subs, i), _)
      equation
        e = FGraphEnv.openScope(i, inEnv); 
      then
        (e, inRef, inRefs);
    
  end matchcontinue;
end resolveName;

public function resolveSubs
  input Env inEnv;
  input Refs inSubs;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output Refs outSubs;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outSubs, outRefs) := matchcontinue(inEnv, inSubs, inRefs)
    local
      Refs subs;
      
    // resolve subs
    case (_, subs, _) then (inEnv, inSubs, inRefs);
  
  end matchcontinue;  
end resolveSubs;

public function resolveIdent
  input Env inEnv;
  input Ident inRef;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inRef, inRefs)
    local
      list<NodeId> refs;
      NodeId i, s;
      Node n;
      Graph g;
      Ident id;
      Env e;
      
    // found in current node
    case (e, id, _)
      equation
        s = FGraphEnv.getScopeHead(e);
        g = FGraphEnv.getGraph(e);
        n = FGraph.getChildSilent(g, s, id);
        // add unresolved references from extends, types, modifiers, etc.
        (e, refs) = analyseNode(e, FNode.getNodeId(n), inRefs);
        i = FNode.getNodeId(n);
      then
        (e, i, refs);
        
    // not found here, try to resolve in extends
    case (e, id, _)
      equation
        s = FGraphEnv.getScopeHead(e);
        g = FGraphEnv.getGraph(e);
        n = FGraph.getNode(g, s);
        (e, i, refs) = resolveInBaseClasses(e, n, id, inRefs);
      then
        (e, i, refs);
        
    // not found in base classes, resolve in imports
    case (e, id, _)
      equation
        s = FGraphEnv.getScopeHead(e);
        g = FGraphEnv.getGraph(e);
        n = FGraph.getNode(g, s);
        (e, i, refs) = resolveInImports(e, n, id, inRefs);
      then
        (e, i, refs);

    // not found in imports, resolve in parents
    case (e, id, _)
      equation
        s = FGraphEnv.getScopeHead(e);
        g = FGraphEnv.getGraph(e);
        n = FGraph.getNode(g, s);
        (e, i, refs) = resolveInParent(e, n, id, inRefs);
      then
        (e, i, refs);

  end matchcontinue;
end resolveIdent;

public function resolveInBaseClasses
"(e, n, id, inRefs)"
  input Env inEnv;
  input Node inNode;
  input Name inIdent;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inNode, inIdent, inRefs)
    local
      list<NodeId> refs;
      NodeId i, s;
      Node n;
      Graph g;
      Ident id;
      Env e;
      list<NodeId> exts;
      
    // get the extends and search in them
    case (e, n, id, _)
      equation
        // get the base classes
        exts = FNode.getExtendsIds(n);
        (e, i, refs) = resolveInExtends(e, exts, id, inRefs);
      then
        (e, i, inRefs);
  
  end matchcontinue;
end resolveInBaseClasses;

public function resolveInExtends
  input Env inEnv;
  input list<NodeId> inExts;
  input Name inIdent;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inExts, inIdent, inRefs)
    local
      list<NodeId> refs;
      NodeId i, s;
      Node n;
      Graph g;
      Ident id;
      Env e;
      list<NodeId> rest;
      
    // search in first extends
    case (e, i::rest, id, _)
      equation
        refs = inRefs;
        i = FNode.topNodeId;
      then
        (e, i, refs);

    // search in rest
    case (e, _::rest, id, _)
      equation
        i = FNode.topNodeId;
        refs = inRefs;
      then
        (e, i, refs);
    
    else fail(); 
  end matchcontinue;
end resolveInExtends;

public function resolveInImports
"(e, n, id, inRefs)"
  input Env inEnv;
  input Node inNode;
  input Name inIdent;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inNode, inIdent, inRefs)
    local
      list<NodeId> refs;
      NodeId i, s;
      Node n;
      Graph g;
      Ident id;
      Env e;
      list<NodeId> exts;
      
    // get the imports and search in them
    case (e, n, id, _)
      equation
        // get the base classes
        exts = FNode.getImportIds(n);
        (e, i, refs) = resolveInImport(e, exts, id, inRefs);
      then
        (e, i, inRefs);
  
  end matchcontinue;
end resolveInImports;

public function resolveInImport
  input Env inEnv;
  input list<NodeId> inExts;
  input Name inIdent;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inExts, inIdent, inRefs)
    local
      list<NodeId> refs;
      NodeId i, s;
      Node n;
      Graph g;
      Ident id;
      Env e;
      list<NodeId> rest;
      
    // search in first extends
    case (e, i::rest, id, _)
      equation
        refs = inRefs;
        i = FNode.topNodeId;
      then
        (e, i, refs);

    // search in rest
    case (e, _::rest, id, _)
      equation
        i = FNode.topNodeId;
        refs = inRefs;
      then
        (e, i, refs);
    
    else fail(); 
  end matchcontinue;
end resolveInImport;

public function resolveInParent
"(e, n, id, inRefs)"
  input Env inEnv;
  input Node inNode;
  input Name inIdent;
  input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
  output Env outEnv;
  output NodeId outRef;
  output list<NodeId> outRefs;
algorithm
  (outEnv, outRef, outRefs) := matchcontinue(inEnv, inNode, inIdent, inRefs)
    local
      list<NodeId> refs;
      NodeId i, s;
      Node n;
      Graph g;
      Ident id;
      Env e;
      list<NodeId> exts;
      
    // get the imports and search in them
    case (e, n, id, _)
      equation
        i = FNode.topNodeId;
      then
        (e, i, inRefs);
  
  end matchcontinue;
end resolveInParent;

public function analyseNode
"@author: adrpo
 look at the node and adds unresolved references for the it"
 input Env inEnv;
 input NodeId inNodeId;
 input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
 output Env outEnv;
 output list<NodeId> outRefs;
algorithm
  (outEnv, outRefs) := matchcontinue(inEnv, inNodeId, inRefs)
    local
      list<NodeId> refs;
      NodeId i;
      Node n;
      Graph g;
      Env e;

    case (e, i, _)
      equation
        n = FGraphEnv.getNode(e, i);
        true = FNode.isElement(n);
        (e, refs) = analyseElement(e, n, inRefs); 
      then 
        (e, refs);

  end matchcontinue;
end analyseNode;

public function analyseElement
"@author: adrpo"
 input Env inEnv;
 input Node inNode;
 input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
 output Env outEnv;
 output list<NodeId> outRefs;
algorithm
  (outEnv, outRefs) := matchcontinue(inEnv, inNode, inRefs)
    local
      list<NodeId> refs;
      NodeId i;
      Node n;
      Graph g;
      SCode.Element el;
      Env e;

    case (e, FNode.N(id = i, data = FNode.CL(e = el)), _)
      equation
        (e, refs) = analyseClass(e, i, el, inRefs);
      then 
        (e, refs);

    case (e, FNode.N(id = i, data = FNode.CO(e = el)), _)
      equation
        (e, refs) = analyseComponent(e, i, el, inRefs); 
      then 
        (e, refs);

    case (e, FNode.N(id = i, data = FNode.EX(e = el)), _)
      equation
        (e, refs) = analyseExtends(e, i, el, inRefs); 
      then 
        (e, refs);

    case (e, FNode.N(id = i, data = FNode.IM(e = el)), _)
      equation
        (e, refs) = analyseImport(e, i, el, inRefs); 
      then 
        (e, refs);

  end matchcontinue;
end analyseElement;

public function analyseClass
"@author: adrpo"
 input Env inEnv;
 input NodeId inNodeId;
 input SCode.Element inElement;
 input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
 output Env outEnv;
 output list<NodeId> outRefs;
algorithm
  (outEnv, outRefs) := matchcontinue(inEnv, inNodeId, inElement, inRefs)
    local
      list<NodeId> refs;
      NodeId i;
      Node n;
      Graph g;
      SCode.Element el;

    case (_, _, _, _)
      equation
      then
        (inEnv, inRefs);

  end matchcontinue;
end analyseClass;

public function analyseComponent
"@author: adrpo"
 input Env inEnv;
 input NodeId inNodeId;
 input SCode.Element inElement;
 input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
 output Env outEnv;
 output list<NodeId> outRefs;
algorithm
  (outEnv, outRefs) := matchcontinue(inEnv, inNodeId, inElement, inRefs)
    local
      list<NodeId> refs;
      NodeId i;
      Node n;
      Graph g;
      SCode.Element el;

    case (_, _, _, _)
      equation
      then
        (inEnv, inRefs);

  end matchcontinue;
end analyseComponent;

public function analyseExtends
"@author: adrpo"
 input Env inEnv;
 input NodeId inNodeId;
 input SCode.Element inElement;
 input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
 output Env outEnv;
 output list<NodeId> outRefs;
algorithm
  (outEnv, outRefs) := matchcontinue(inEnv, inNodeId, inElement, inRefs)
    local
      list<NodeId> refs;
      NodeId i;
      Node n;
      Graph g;
      SCode.Element el;

    case (_, _, _, _)
      equation
      then
        (inEnv, inRefs);

  end matchcontinue;
end analyseExtends;

public function analyseImport
"@author: adrpo"
 input Env inEnv;
 input NodeId inNodeId;
 input SCode.Element inElement;
 input list<NodeId> inRefs "unresolved references until now, or empty as an accumulator";
 output Env outEnv;
 output list<NodeId> outRefs;
algorithm
  (outEnv, outRefs) := matchcontinue(inEnv, inNodeId, inElement, inRefs)
    local
      list<NodeId> refs;
      NodeId i;
      Node n;
      Graph g;
      SCode.Element el;

    case (_, _, _, _)
      equation
      then
        (inEnv, inRefs);

  end matchcontinue;
end analyseImport;

end FResolve;

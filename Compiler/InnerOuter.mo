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

package InnerOuter
"
  file:	       InnerOuter.mo
  package:     InnerOuter
  description: Instance hierarchy and functionality to deal with Inner/Outer definitions

  RCS: $Id: InnerOuter.mo 4847 2010-01-21 22:45:09Z adrpo $"
  
import Absyn;
import DAE;
import Env;
import Prefix;
import SCode;
import UnitAbsyn;
import Connect;
import ConnectionGraph;

protected import System;
protected import Exp;
protected import Util;
protected import Debug;
protected import DAEUtil;
protected import VarTransform;
protected import OptManager;
protected import Dump;
protected import Error;
protected import Lookup;
protected import Inst;
protected import ConnectUtil;
protected import RTOpts;
protected import Mod;
protected import PrefixUtil;

public
type Cache     = Env.Cache;
type Env       = Env.Env;
type Frame     = Env.Frame;
type AvlTree   = Env.AvlTree;
type Item      = Env.Item;
type Ident     = Env.Ident;
type CSetsType = Env.CSetsType;
type Prefix    = Prefix.Prefix;
type Mod       = DAE.Mod;

uniontype InstResult
  record INST_RESULT
    Cache outCache;
    Env outEnv;
    UnitAbsyn.InstStore outStore;
    DAE.DAElist outDae;
    Connect.Sets outSets;
    DAE.Type outType;
    ConnectionGraph.ConnectionGraph outGraph;    
  end INST_RESULT;  
end InstResult;

uniontype InstInner
  record INST_INNER
    SCode.Ident name;
    Absyn.InnerOuter io;
    // add these if needed!
    // SCode.Mod scodeMod;
    // DAE.Mod mod;
    Option<InstResult> instResult;
    list<DAE.ComponentRef> outers "which outers are referencing this inner"; 
  end INST_INNER;
end InstInner;

public
type Key = DAE.ComponentRef "the prefix + '.' + the component name";
type Value = InstInner "the inputs of the instantiation function and the results";

uniontype TopInstance "a top instance is an instance of a model thar resides at top level" 
  record TOP_INSTANCE
    Option<Absyn.Path> path "top model path";
    InstHierarchyHashTable ht "hash table with fully qualified components";
  end TOP_INSTANCE;
end TopInstance;

type InstHierarchy = list<TopInstance>;

constant InstHierarchy emptyInstHierarchy = {}
"an empty instance hierarchy";

public function handleInnerOuterEquations 
"Author: BZ, 2008-12
 Depending on the inner outer declaration we do 
 different things for dae declared for a variable.
 If it is an outer variable, we remove all equations 
 (will be declared again in the inner part).
 If it is InnerOuter declared, we rename all the crefs 
 in this equation to unique vars, while we want to keep 
 them with this prefix for the inner part of the innerouter."
  input Absyn.InnerOuter io;
  input DAE.DAElist dae;
  input InstHierarchy inIH;
  input ConnectionGraph.ConnectionGraph inGraphNew;
  input ConnectionGraph.ConnectionGraph inGraph;
  output DAE.DAElist odae;
  output InstHierarchy outIH;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (odae,outIH,outGraph) := matchcontinue(io,dae,inIH,inGraphNew,inGraph)
    local 
      DAE.DAElist dae1,dae2;
      ConnectionGraph.ConnectionGraph graphNew,graph;
      InstHierarchy ih;
    // is an outer, remove equations
    // outer components do NOT change the connection graph!
    case(Absyn.OUTER(),dae,ih,graphNew,graph) 
      equation
        (odae,_) = DAEUtil.splitDAEIntoVarsAndEquations(dae);
      then
        (odae,ih,graph);
    // is both an inner and an outer, 
    // rename inner vars in the equations to unique names
    // innerouter component change the connection graph
    case(Absyn.INNEROUTER(),dae,ih,graphNew,graph)
      equation
        (dae1,dae2) = DAEUtil.splitDAEIntoVarsAndEquations(dae);
        // rename variables in the equations and algs.
        dae2 = DAEUtil.nameUniqueOuterVars(dae2);
        // rename variables in the 
        dae = DAEUtil.joinDaes(dae1,dae2);
        // adrpo: TODO! FIXME: here we should do a difference of graphNew-graph
        //                     and rename the new equations added with unique vars.
      then
        (dae,ih,graph);
    // is an inner do nothing
    case(Absyn.INNER(),dae,ih,graphNew,graph) then (dae,ih,graphNew);
    // is not an inner nor an outer
    case(Absyn.UNSPECIFIED (),dae,ih,graphNew,graph) then (dae,ih,graphNew);
    // something went totally wrong!
    case(_,dae,ih,graphNew,graph)
      equation
        print("- InnerOuter.handleInnerOuterEquations failed!\n");
      then fail();
  end matchcontinue;
end handleInnerOuterEquations;

public function changeOuterReferences "
Changes the outer references in a dae to the corresponding
inner reference, given that an inner reference exist in the DAE.
Update connection sets incase of Absyn.INNEROUTER()"
  input DAE.DAElist inDae;
  input Connect.Sets csets;
  input InstHierarchy inIH;  
  input ConnectionGraph.ConnectionGraph inGraph;
  output DAE.DAElist outDae;
  output Connect.Sets ocsets;
  output InstHierarchy outIH;  
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm 
  (ocsets,outDae,outIH,outGraph) := matchcontinue(inDae,csets,inIH,inGraph)
    local
      list<DAE.Element> innerVars,outerVars,allDAEelts;
      VarTransform.VariableReplacements repl;
      list<DAE.ComponentRef> sources,targets;
      Boolean updateGraph ;
      list<DAE.ComponentRef> definiteRoots "Roots defined with Connection.root" ;
      list<tuple<DAE.ComponentRef, Real>> potentialRoots "Roots defined with Connection.potentialRoot" ;
      ConnectionGraph.Edges branches "Edges defined with Connection.branch" ;
      ConnectionGraph.DaeEdges connections "Edges defined with connect statement" ;
      ConnectionGraph.ConnectionGraph graph;
      InstHierarchy ih;      
  
    // adrpo: return the same if we have no inner/outer components! 
    case(inDae,csets,ih,graph)
      equation
        // print("changeOuterReferences: " +& ConnectUtil.printSetsStr(csets));
        false = System.getHasInnerOuterDefinitions();
      then (inDae,csets,ih,graph);

    // adrpo: specific faster case when there are *no inner* elements!
    case(inDae as DAE.DAE(allDAEelts,_),csets,ih,graph)
      equation
        // when we have no inner elements we can return the same!
        (DAE.DAE({},_),DAE.DAE(_,_)) = DAEUtil.findAllMatchingElements(inDae,DAEUtil.isInnerVar,DAEUtil.isOuterVar);
      then (inDae,csets,ih,graph);
        
    // adrpo: specific faster case when there are *no outer* elements!
    case(inDae as DAE.DAE(allDAEelts,_),csets,ih,graph)
      equation
        // when we have no outer elements we can return the same!
        (DAE.DAE(_,_),DAE.DAE({},_)) = DAEUtil.findAllMatchingElements(inDae,DAEUtil.isInnerVar,DAEUtil.isOuterVar);
      then (inDae,csets,ih,graph);

    // general case
    case(inDae as DAE.DAE(allDAEelts,_),csets,ih,
         graph as ConnectionGraph.GRAPH(updateGraph, 
                                        definiteRoots, 
                                        potentialRoots, 
                                        branches, 
                                        connections))
      equation
        (DAE.DAE(innerVars,_),DAE.DAE(outerVars,_)) = DAEUtil.findAllMatchingElements(inDae,DAEUtil.isInnerVar,DAEUtil.isOuterVar);  
        repl = buildInnerOuterRepl(innerVars,outerVars,VarTransform.emptyReplacements());
        // print("Number of elts/inner vars/outer vars: " +& 
        //       intString(listLength(allDAEelts)) +& 
        //       "/" +& intString(listLength(innerVars)) +&
        //       "/" +& intString(listLength(outerVars)) +& "\n");
        sources = VarTransform.replacementSources(repl);
        targets = VarTransform.replacementTargets(repl);
        inDae = DAEUtil.removeVariables(inDae,sources);
        inDae = DAEUtil.removeInnerAttrs(inDae,targets); 
        outDae = VarTransform.applyReplacementsDAE(inDae,repl,NONE);
        // adrpo: send in the sources/targets so we avoid building them again!
        ocsets = changeOuterReferences2(repl,csets,sources,targets);
      then
        (outDae,ocsets,ih,graph);
    // failtrace
    case(inDae,csets,ih,graph)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- Inst.changeOuterReferences failed!");
      then 
        fail();
  end matchcontinue;
end changeOuterReferences;

protected function changeOuterReferences2 "
Author: BZ, 2008-09 
Helper function for changeOuterReferences 
Verfify that we have replacement rules, then apply them for the outerconnect.
With the difference that we add the scope of the inner declaration to the connection set variables."
  input VarTransform.VariableReplacements repl;
  input Connect.Sets csets;
  input list<DAE.ComponentRef> sources;
  input list<DAE.ComponentRef> targets; 
  output Connect.Sets ocsets;
algorithm 
  ocsets := matchcontinue(repl,csets,sources,targets)
    local
      list<Connect.Set> sets;
      list<DAE.ComponentRef> ccons,dcs;    
      list<Connect.OuterConnect> ocs,ocs2;
    // no outer connects!
    case(repl,Connect.SETS(outerConnects = {}),_,_) then csets;
    // no targets!
    case(repl,csets,sources,{})
      equation
        // adrpo: not needed as the targets are send from up ABOVE :)
        // targets = VarTransform.replacementTargets(repl);
        // true = intEq(listLength(targets),0);
      then 
        csets;
    // we have something
    case(repl,Connect.SETS(sets,ccons,dcs,ocs),sources,targets)
      equation
        // adrpo: send in the sources/targets so we avoid building them again!
        ocs2 = changeOuterReferences3(ocs,repl,sources,targets);
      then
        Connect.SETS(sets,ccons,dcs,ocs2);
  end matchcontinue;
end changeOuterReferences2;

protected function changeOuterReferences3 "
Author: BZ, 2008-09 
Helper function for changeOuterReferences 
Extract the innouter declared connections. "
  input list<Connect.OuterConnect> ocs;
  input VarTransform.VariableReplacements repl;
  input list<DAE.ComponentRef> sources;
  input list<DAE.ComponentRef> targets;
  output list<Connect.OuterConnect> oocs;
algorithm 
  oocs := matchcontinue(ocs,repl,sources,targets)
    local
      list<Connect.OuterConnect> recRes;
      DAE.ComponentRef cr1,cr2,ncr1,ncr2,cr3,ver1,ver2;
      Absyn.InnerOuter io1,io2;
      Connect.Face f1,f2;
      Prefix.Prefix scope;
      list<DAE.ComponentRef> src,dst;
      String s1,s2; 
      DAE.ElementSource source "the origin of the element"; 
    // handle nothingness
    case({},_,_,_) then {};
    // the left hand side is an outer!
    case(Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::ocs,repl,sources,targets)
      equation
        (_,true) = innerOuterBooleans(io1);
        cr3 = PrefixUtil.prefixCref(scope,cr1);
        // adrpo: not needed as the sources/targets are send from up ABOVE :)
        src = sources; // VarTransform.replacementSources(repl);
        dst = targets; // VarTransform.replacementTargets(repl);
        ncr1 = changeOuterReferences4(cr3,src,dst);
        ver1 = Exp.crefFirstIdent(ncr1);
        ver2 = Exp.crefFirstIdent(cr1);
        false = Exp.crefEqual(ver1,ver2);
        recRes = changeOuterReferences3(ocs,repl,src,dst);
      then
        Connect.OUTERCONNECT(scope,ncr1,Absyn.INNER(),f1,cr2,io2,f2,source)::recRes;
    // the right hand side is an outer!
    case(Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::ocs,repl,sources,targets)
      equation
        (_,true) = innerOuterBooleans(io2);
        cr3 = PrefixUtil.prefixCref(scope,cr2);
        // adrpo: not needed as the sources/targets are send from up ABOVE :)
        src = sources; // VarTransform.replacementSources(repl);
        dst = targets; // VarTransform.replacementTargets(repl); 
        ncr2 = changeOuterReferences4(cr3,src,dst);
        ver1 = Exp.crefFirstIdent(ncr2);
        ver2 = Exp.crefFirstIdent(cr2);
        false = Exp.crefEqual(ver1,ver2);
        recRes = changeOuterReferences3(ocs,repl,src,dst);
      then
        Connect.OUTERCONNECT(scope,cr1,io1,f1,ncr2,Absyn.INNER(),f2,source)::recRes;
    // none of left or right hand side are outer
    case(Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::ocs,repl,sources,targets) 
      equation
        s1 = Exp.printComponentRefStr(cr1);
        s2 = Exp.printComponentRefStr(cr2);
        recRes = changeOuterReferences3(ocs,repl,sources,targets); 
      then 
        Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::recRes;
  end matchcontinue; 
end changeOuterReferences3;

protected function changeOuterReferences4 "
Author: BZ, 2008-12
Helper function for changeOuterReferences.
Finds the common part of the variable and it's source of replacement.
Then uses the first common part of the replacement destination.
ex:
 m1.m2.m3, m1.m2.m3.m4, m2.m3.m4
 ==> m2.$unique'ified$m3"
input DAE.ComponentRef inCr;
input list<DAE.ComponentRef> src,dst;
output DAE.ComponentRef outCr;
algorithm outCr := matchcontinue(inCr,src,dst)
  local DAE.ComponentRef s,d,cr1,cr2;
  case(inCr,s::src,d::dst)
    equation
      true = Exp.crefPrefixOf(inCr,s);
      cr1 = extractCommonPart(inCr,d);
      false = Exp.crefIsIdent(cr1); // an ident can not be the inner part of an innerouter.
      outCr = DAEUtil.nameInnerouterUniqueCref(cr1);     
      then
        outCr;
  case(inCr,s::src,d::dst)
    equation
      false = Exp.crefPrefixOf(inCr,s);
      outCr = changeOuterReferences4(inCr,src,dst);
      then
        outCr;
  end matchcontinue;
end changeOuterReferences4;

protected function buildInnerOuterRepl 
"Builds replacement rules for changing outer references 
 to the inner variable"
	input list<DAE.Element> innerVars;
	input list<DAE.Element> outerVars;
	input VarTransform.VariableReplacements inRepl;
	output VarTransform.VariableReplacements outRepl;
algorithm
  repl := matchcontinue(innerVars,outerVars,inRepl)
    local VarTransform.VariableReplacements repl; DAE.Element v;
    case({},_,repl) then repl;    
    case(v::innerVars,outerVars,repl) 
      equation
      repl = buildInnerOuterReplVar(v,outerVars,repl);
      repl = buildInnerOuterRepl(innerVars,outerVars,repl);
    then repl;
  end matchcontinue;
end buildInnerOuterRepl;

protected function buildInnerOuterReplVar 
"Help function to buildInnerOuterRepl"
	input DAE.Element innerVar;
	input list<DAE.Element> outerVars;
	input VarTransform.VariableReplacements inRepl;
	output VarTransform.VariableReplacements outRepl;
algorithm
	outRepl := matchcontinue(innerVar,outerVars,inRepl)
	  local 
        list<DAE.ComponentRef> outerCrs,ourOuterCrs;
	    DAE.ComponentRef cr; VarTransform.VariableReplacements repl;
	  case(DAE.VAR(componentRef = cr, innerOuter = Absyn.INNEROUTER()),outerVars,repl) 
	    equation
        outerCrs = Util.listMap(outerVars,DAEUtil.varCref);
	      ourOuterCrs = Util.listSelect1(outerCrs,cr,isInnerOuterMatch);
	      cr = DAEUtil.nameInnerouterUniqueCref(cr);
        repl = Util.listFold_2r(ourOuterCrs,VarTransform.addReplacement,repl,DAE.CREF(cr,DAE.ET_OTHER()));
	    then repl;
	  case(DAE.VAR(componentRef = cr),outerVars,repl) 
	    equation
	      outerCrs = Util.listMap(outerVars,DAEUtil.varCref);
	      ourOuterCrs = Util.listSelect1(outerCrs,cr,isInnerOuterMatch);
	      repl = Util.listFold_2r(ourOuterCrs,VarTransform.addReplacement,repl,DAE.CREF(cr,DAE.ET_OTHER()));
	    then repl;
	end matchcontinue;
end buildInnerOuterReplVar;

protected function isInnerOuterMatch 
"Returns true if an inner element matches an outer, i.e.
the outer reference should be translated to the inner reference"
  input DAE.ComponentRef outerCr " e.g. a.b.x";
  input DAE.ComponentRef innerCr " e.g. x";
  output Boolean res;
algorithm
  res := matchcontinue(outerCr,innerCr)
    local
      DAE.ComponentRef innerCr1,outerCr1;
      DAE.Ident id1, id2;
    // try a simple comparison first.
    // adrpo: this case is just to speed up the checking! 
    case(outerCr,innerCr)
      equation
        // try to compare last ident first!
        id1 = Exp.crefLastIdent(outerCr);
        id2 = Exp.crefLastIdent(innerCr);
        false = stringEqual(id1, id2);
      then false;
    // try the hard and expensive case.
    case(outerCr,innerCr)
      equation
        // Strip the common part of inner outer cr. 
        // For instance, innerCr = e.f.T1, outerCr = e.f.g.h.a.b.c.d.T1 results in
        // innerCr1 = T1, outerCr = g.h.a.b.c.d.T1
        (outerCr1,innerCr1) = stripCommonCrefPart(outerCr,innerCr);
        res = Exp.crefContainedIn(outerCr1,innerCr1);
      then res;
  end matchcontinue;
end isInnerOuterMatch;

protected function stripCommonCrefPart 
"Help function to isInnerOuterMatch"
  input DAE.ComponentRef outerCr;
  input DAE.ComponentRef innerCr;
  output DAE.ComponentRef outOuterCr;
  output DAE.ComponentRef outInnerCr;
algorithm
  (outOuterCr,outInnerCr) := matchcontinue(outerCr,innerCr)
  local
    DAE.Ident id1,id2;
    list<DAE.Subscript> subs1,subs2;
  	DAE.ComponentRef cr1,cr2,cr11,cr22;
    case(DAE.CREF_QUAL(id1,_,subs1,cr1),DAE.CREF_QUAL(id2,_,subs2,cr2)) 
      equation
        equality(id1=id2);
        (cr11,cr22) = stripCommonCrefPart(cr1,cr2);
      then (cr11,cr22);
    case(cr1,cr2) then (cr1,cr2);
  end matchcontinue;
end stripCommonCrefPart;

protected function extractCommonPart "
Author: BZ, 2008-12
Compares two crefs ex:
model1.model2.connector vs model2.connector.variable
would become: model2.connector"
input DAE.ComponentRef prefixedCref;
input DAE.ComponentRef innerCref;
output DAE.ComponentRef cr3;
algorithm cr3 := matchcontinue(prefixedCref,innerCref)
local
  DAE.ExpType ty,ty2;
  DAE.ComponentRef c1,c2,c3;  
  case(prefixedCref,innerCref)
    equation
     c1 = Exp.crefIdent(prefixedCref);
     c2 = Exp.crefIdent(innerCref);
     true = Exp.crefEqual(c1,c2);
     c3 = Exp.crefSetLastType(innerCref,Exp.crefLastType(prefixedCref));     
     then
       c3;
  case(prefixedCref,innerCref)
    equation
      c2 = Exp.crefStripLastIdent(innerCref);      
      cr3 = extractCommonPart(prefixedCref,c2);
    then
      cr3;
  end matchcontinue;
end extractCommonPart;

public function renameUniqueVarsInTopScope 
"Author: BZ, 2008-09 
 Helper function for instClass. 
 If top scope, traverse DAE and change any uniqnamed vars back to original.
 This is a work around for innerouter declarations."
  input Boolean isTopScope;
  input DAE.DAElist dae;
  output DAE.DAElist odae;
algorithm 
  odae := matchcontinue(isTopScope,dae)
    // adrpo: don't do anything if there are no inner/outer declarations in the model!
    case (_, dae)
      equation
        false = System.getHasInnerOuterDefinitions();
      then 
        dae;
    // we are in top level scope (isTopScope=true) and we need to rename
    case (true,dae)
      equation
        odae = DAEUtil.renameUniqueOuterVars(dae);
      then
        odae;
    // we are NOT in top level scope (isTopScope=false) and we need to rename
    case (false,dae) then dae;
end matchcontinue;
end renameUniqueVarsInTopScope; 

public function retrieveOuterConnections 
"Moves outerConnections to connection sets
 author PA:
 This function moves the connections put in outerConnects to the connection
 set, if a corresponding innner component can be found in the environment. 
 If not, they are kept in the outerConnects for use higher up in the instance 
 hierarchy."
  input Env.Cache cache;
  input Env env;
  input InstHierarchy inIH;
  input Prefix pre;
  input Connect.Sets csets;
  input Boolean topCall;
  output Connect.Sets outCsets;
  output list<Connect.OuterConnect> innerOuterConnects;
algorithm
  outCsets := matchcontinue(cache,env,ih,pre,csets,topCall)
    local 
      list<Connect.Set> setLst;
      list<DAE.ComponentRef> crs;
      list<DAE.ComponentRef> delcomps;
      list<Connect.OuterConnect> outerConnects;
      InstHierarchy ih;
      
    case(cache,env,ih,pre,Connect.SETS(setLst,crs,delcomps,outerConnects),topCall) 
      equation
        (outerConnects,setLst,crs,innerOuterConnects) = 
        retrieveOuterConnections2(cache,env,ih,pre,outerConnects,setLst,crs,topCall);
      then 
        (Connect.SETS(setLst,crs,delcomps,outerConnects),innerOuterConnects);        
  end matchcontinue;
end retrieveOuterConnections;

protected function retrieveOuterConnections2 
"help function to retrieveOuterConnections"
  input Env.Cache cache;
  input Env env;
  input InstHierarchy inIH;
  input Prefix pre;
  input list<Connect.OuterConnect> outerConnects;
  input list<Connect.Set> setLst;
  input list<DAE.ComponentRef> crs;
  input Boolean topCall;
  output list<Connect.OuterConnect> outOuterConnects;
  output list<Connect.Set> outSetLst;
  output list<DAE.ComponentRef> outCrs;
  output list<Connect.OuterConnect> innerOuterConnects;
algorithm
  (outOuterConnects,outSetLst,outCrs,innerOuterConnects) := 
  matchcontinue(cache,env,inIH,pre,outerConnects,setLst,crs,topCall)
    local 
      DAE.ComponentRef cr1,cr2,cr1first,cr2first;
      Absyn.InnerOuter io1,io2;
      Connect.OuterConnect oc;
      Boolean keepInOuter,inner1,inner2,outer1,outer2,added,cr1Outer,cr2Outer;    
      Connect.Face f1,f2;    
      Prefix.Prefix scope;
      InstHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      
    case(cache,env,ih,pre,{},setLst,crs,_) then ({},setLst,crs,{});
      
    case(cache,env,ih,pre,Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::outerConnects,setLst,crs,topCall) 
      equation
        cr1first = Exp.crefFirstIdent(cr1);
        cr2first = Exp.crefFirstIdent(cr2);
        (inner1,outer1) = lookupVarInnerOuterAttr(cache,env,ih,cr1first,cr2first);
        true = inner1;
        /*      
        f1 = ConnectUtil.componentFace(env,cr1);
        f2 = ConnectUtil.componentFace(env,cr2);
        */
        f1 = ConnectUtil.componentFaceType(cr1);
        f2 = ConnectUtil.componentFaceType(cr2); 
        (setLst,crs,added) = ConnectUtil.addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,crs);
        /* If no connection set available (added = false), create new one */
        setLst = addOuterConnectIfEmpty(cache,env,ih,pre,setLst,added,cr1,io1,f1,cr2,io2,f2);      
     
        (outerConnects,setLst,crs,innerOuterConnects) = 
        retrieveOuterConnections2(cache,env,ih,pre,outerConnects,setLst,crs,topCall);
        outerConnects = Util.if_(outer1,Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::outerConnects,outerConnects);      
      then 
        (outerConnects,setLst,crs,innerOuterConnects);
      
      /* This case is for innerouter declarations, since we do not have them in enviroment we need to treat them
      in a special way */
    case(cache,env,ih,pre,(oc as Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source))::outerConnects,setLst,crs,true)
      local Boolean b1,b2,b3,b4; 
      equation
        (b1,b3) = innerOuterBooleans(io1);
        (b2,b4) = innerOuterBooleans(io2);
        true = boolOr(b1,b2); // for inner outer we set Absyn.INNER() 
        false = boolOr(b3,b4); 
        f1 = ConnectUtil.componentFaceType(cr1);
        f2 = ConnectUtil.componentFaceType(cr2);
        cr1 = DAEUtil.unNameInnerouterUniqueCref(cr1,DAE.UNIQUEIO);
        cr2 = DAEUtil.unNameInnerouterUniqueCref(cr2,DAE.UNIQUEIO);
        io1 = convertInnerOuterInnerToOuter(io1); // we need to change from inner to outer to be able to join sets in: addOuterConnectToSets 
        io2 = convertInnerOuterInnerToOuter(io2);
        (setLst,crs,added) = ConnectUtil.addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,crs);
        /* If no connection set available (added = false), create new one */
        setLst = addOuterConnectIfEmptyNoEnv(cache,env,ih,pre,setLst,added,cr1,io1,f1,cr2,io2,f2);
        (outerConnects,setLst,crs,innerOuterConnects) = 
        retrieveOuterConnections2(cache,env,ih,pre,outerConnects,setLst,crs,true);
      then 
        (outerConnects,setLst,crs,innerOuterConnects);
         
    case(cache,env,ih,pre,Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::outerConnects,setLst,crs,topCall) 
      equation
        (outerConnects,setLst,crs,innerOuterConnects) = 
        retrieveOuterConnections2(cache,env,ih,pre,outerConnects,setLst,crs,topCall);
      then 
        (Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::outerConnects,setLst,crs,innerOuterConnects);  
  end matchcontinue;
end retrieveOuterConnections2;

protected function convertInnerOuterInnerToOuter 
"Author: BZ, 2008-12 
 Change from Absyn.INNER => Absyn.OUTER, 
 this to be able to use normal functions 
 for the innerouter declared variables/connections."
  input Absyn.InnerOuter io;
  output Absyn.InnerOuter oio;
algorithm 
  oio := matchcontinue(io) 
    case(Absyn.INNER()) then Absyn.OUTER();
    case(io) then io;
  end matchcontinue;
end convertInnerOuterInnerToOuter; 

protected function addOuterConnectIfEmpty 
"help function to retrieveOuterConnections2
 author PA.
 Adds a new connectionset if inner component 
 found but no connection set refering to the 
 inner component. In that is case the outer 
 connection (from inside sub-components) forms 
 a connection set of their own."
  input Env.Cache cache;  
  input Env env;
  input InstHierarchy inIH;
  input Prefix pre;
  input list<Connect.Set> setLst;
  input Boolean added "if true, this function does nothing";
  input DAE.ComponentRef cr1;
  input Absyn.InnerOuter io1;
  input Connect.Face f1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io2;
  input Connect.Face f2;
  output list<Connect.Set> outSetLst;
algorithm
  outSetLst := matchcontinue(cache,env,ih,pre,setLst,added,cr1,io1,f1,cr2,io2,f2)
     local SCode.Variability vt1,vt2;
       DAE.Type t1,t2;
       Boolean flowPrefix;
       DAE.DAElist dae;
       list<Connect.Set> setLst2;
       Connect.Sets csets;
       InstHierarchy ih;
       
    case(cache,env,ih,pre,setLst,true,_,_,_,_,_,_) 
      then setLst;
    
    case(cache,env,ih,pre,setLst,false,cr1,io1,f1,cr2,io2,f2) 
      equation
        (cache,DAE.ATTR(flowPrefix,_,_,vt1,_,_),t1,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        (cache,DAE.ATTR(_,_,_,vt2,_,_),t2,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        io1 = removeOuter(io1);
        io2 = removeOuter(io2);            
        (cache,env,ih,csets as Connect.SETS(setLst=setLst2),dae,_) = 
        Inst.connectComponents(cache,env,ih,Connect.emptySet,pre,cr1,f1,t1,vt1,cr2,f2,t2,vt2,flowPrefix,io1,io2,ConnectionGraph.EMPTY);     
        /* TODO: take care of dae, can contain asserts from connections */
        setLst = listAppend(setLst,setLst2);
    then 
      setLst;
      
     /* This can fail, for innerouter, the inner part is not declared in env so instead the call to addOuterConnectIfEmptyNoEnv will succed.
    case(cache,env,pre,setLst,_,cr1,_,_,cr2,_,_) 
      equation 
        print("#FAILURE# in: addOuterConnectIfEmpty:__ " +& Exp.printComponentRefStr(cr1) +& " " +& Exp.printComponentRefStr(cr2) +& "\n"); 
      then fail();*/
      
  end matchcontinue;
end addOuterConnectIfEmpty;  

protected function addOuterConnectIfEmptyNoEnv 
"help function to retrieveOuterConnections2
 author BZ.
 Adds a new connectionset if inner component found but 
 no connection set refering to the inner component. 
 In that case the outer connection (from inside 
 sub-components) forms a connection set of their own.
 2008-12: This is an extension of addOuterConnectIfEmpty, 
          with the difference that we only need to find 
          one variable in the enviroment."
  input Env.Cache cache;  
  input Env env;
  input InstHierarchy inIH;
  input Prefix pre;
  input list<Connect.Set> setLst;
  input Boolean added "if true, this function does nothing";
  input DAE.ComponentRef cr1;
  input Absyn.InnerOuter io1;
  input Connect.Face f1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io2;
  input Connect.Face f2;
  output list<Connect.Set> outSetLst;
algorithm
  outSetLst := matchcontinue(cache,env,inIH,pre,setLst,added,cr1,io1,f1,cr2,io2,f2)
     local 
       SCode.Variability vt1,vt2;
       DAE.Type t1,t2;
       Boolean flow_;
       DAE.DAElist dae;
       list<Connect.Set> setLst2;
       Connect.Sets csets;
       InstHierarchy ih;
       
    case(cache,env,ih,pre,setLst,true,_,_,_,_,_,_) then setLst;
    
    case(cache,env,ih,pre,setLst,false,cr1,io1,f1,cr2,io2,f2) 
      equation
        (cache,DAE.ATTR(flowPrefix=flow_,parameter_=vt1),t1,_,_,_) = 
        Lookup.lookupVar(cache,env,cr1);
        pre = Prefix.NOPRE();
        t2 = t1;
        vt2 = vt1;
        io1 = removeOuter(io1);
        io2 = removeOuter(io2);            
        (cache,env,ih,csets as Connect.SETS(setLst=setLst2),dae,_) = 
        Inst.connectComponents(cache,env,ih,Connect.emptySet,pre,cr1,f1,t1,vt1,cr2,f2,t2,vt2,flow_,io1,io2,ConnectionGraph.EMPTY);
        /* TODO: take care of dae, can contain asserts from connections */
        setLst = listAppend(setLst,setLst2);
    then 
      setLst;
      
    case(cache,env,ih,pre,setLst,false,cr1,io1,f1,cr2,io2,f2) 
      equation
        pre = Prefix.NOPRE();
        (cache,DAE.ATTR(flowPrefix=flow_,parameter_=vt2),t2,_,_,_) = 
        Lookup.lookupVar(cache,env,cr2);
        t1 = t2;
        vt1 = vt2;
        io1 = removeOuter(io1);
        io2 = removeOuter(io2);            
        (cache,env,ih,csets as Connect.SETS(setLst=setLst2),dae,_) = 
        Inst.connectComponents(cache,env,ih,Connect.emptySet,pre,cr1,f1,t1,vt1,cr2,f2,t2,vt2,flow_,io1,io2,ConnectionGraph.EMPTY);
        /* TODO: take care of dae, can contain asserts from connections */
        setLst = listAppend(setLst,setLst2);
    then setLst;
    case(cache,env,ih,pre,setLst,_,_,_,_,_,_,_) 
      equation print("failure in: addOuterConnectIfEmptyNOENV\n"); 
        then fail();
  end matchcontinue;
end addOuterConnectIfEmptyNoEnv; 

protected function removeOuter 
"Removes outer attribute, keeping inner"
  input Absyn.InnerOuter io;
  output Absyn.InnerOuter outIo;
algorithm
  outIo := matchcontinue(io)
    case(Absyn.OUTER()) then Absyn.UNSPECIFIED();
    case(Absyn.INNER()) then Absyn.INNER();
    case(Absyn.INNEROUTER()) then Absyn.INNER();
    case(Absyn.UNSPECIFIED()) then Absyn.UNSPECIFIED();     
  end matchcontinue;
end removeOuter;
  
protected function lookupVarInnerOuterAttr 
"searches for two variables in env and retrieves 
 its inner and outer attributes in form of booleans"
  input Env.Cache cache;
  input Env env;
  input InstHierarchy inIH;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean isInner;
  output Boolean isOuter;
algorithm
  (isInner,isOuter) := matchcontinue(cache,env,inIH,cr1,cr2)
    local 
      Absyn.InnerOuter io,io1,io2;
      Boolean isInner1,isInner2,isOuter1,isOuter2;
      InstHierarchy ih;          
    /* Search for both */
    case(cache,env,ih,cr1,cr2)
      equation
        (_,DAE.ATTR(innerOuter=io1),_,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        (_,DAE.ATTR(innerOuter=io2),_,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        (isInner1,isOuter1) = innerOuterBooleans(io1);
        (isInner2,isOuter2) = innerOuterBooleans(io2);
        isInner = isInner1 or isInner2;
        isOuter = isOuter1 or isOuter2;
      then 
        (isInner,isOuter);
    /* try to find var cr1 (lookup can fail for one of them) */
    case(cache,env,ih,cr1,cr2) 
      equation
        (_,DAE.ATTR(innerOuter=io),_,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        (isInner,isOuter) = innerOuterBooleans(io);
      then 
        (isInner,isOuter);
     /* ..else try cr2 (lookup can fail for one of them) */
    case(cache,env,ih,cr1,cr2) 
      equation
        (_,DAE.ATTR(innerOuter=io),_,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        (isInner,isOuter) = innerOuterBooleans(io);
      then (isInner,isOuter);
  end matchcontinue;
end lookupVarInnerOuterAttr;

public function checkMissingInnerDecl 
"Checks that outer declarations has a 
 corresponding inner declaration.
 This can only be done at the top scope"
  input DAE.DAElist inDae;
  input Boolean callScope "only done if true";
protected
  list<DAE.Element> innerVars,outerVars,allVars;
  VarTransform.VariableReplacements repl;
  list<DAE.ComponentRef> srcs,targets;
  DAE.FunctionTree funcs1,funcs2;
algorithm
  _ := matchcontinue(inDae,callScope)
    // adrpo, do nothing if we have no inner/outer components
    case(inDae,_)
      equation
        false = System.getHasInnerOuterDefinitions();
      then ();
    // if call scope is TOP level (true) do the checking
    case(inDae,true) 
      equation
        //print("DAE has :" +& intString(listLength(inDae)) +& " elements\n");
        (DAE.DAE(innerVars,funcs1),DAE.DAE(outerVars,funcs2)) = DAEUtil.findAllMatchingElements(inDae,DAEUtil.isInnerVar,DAEUtil.isOuterVar);
        checkMissingInnerDecl1(DAE.DAE(innerVars,funcs1),DAE.DAE(outerVars,funcs2));
      then ();
    // if call scope is NOT TOP level (false) do nothing
    case(inDae,false) 
      then ();
   end matchcontinue;
end checkMissingInnerDecl;

protected function checkMissingInnerDecl1 
"checks that the 'inner' prefix is used 
 when an corresponding 'outer' variable 
 found"
  input DAE.DAElist innerVarsDae;
  input DAE.DAElist outerVarsDae;
algorithm
  Util.listMap01(DAEUtil.daeElements(outerVarsDae),DAEUtil.daeElements(innerVarsDae),checkMissingInnerDecl2);
end checkMissingInnerDecl1;

protected function checkMissingInnerDecl2 
"help function to checkMissingInnerDecl"
  input DAE.Element outerVar;
  input list<DAE.Element> innerVars;
algorithm
  _ := matchcontinue(outerVar,innerVars)
    local 
      String str,str2; DAE.ComponentRef cr; DAE.Element v;
      list<DAE.ComponentRef> crs;
      Absyn.InnerOuter io;
      
    case(DAE.VAR(componentRef=cr),innerVars) 
      equation
        crs = Util.listMap(innerVars, DAEUtil.varCref);
        {_} = Util.listSelect1(crs, cr, isInnerOuterMatch);
      then ();
    case(DAE.VAR(componentRef=cr, innerOuter = io),innerVars)  
      equation
        // ?? adrpo: NOT USED! TODO! FIXME! str2 = Dump.unparseInnerouterStr(io);
        crs = Util.listMap(innerVars,DAEUtil.varCref);
        {} = Util.listSelect1(crs, cr,isInnerOuterMatch);
        // ?? adrpo: NOT USED! TODO! FIXME! str = Exp.printComponentRefStr(cr);
        failExceptForCheck();
      then (); 
    case(DAE.VAR(componentRef=cr, innerOuter = io),innerVars) 
      local Absyn.InnerOuter io;
      equation
        str2 = Dump.unparseInnerouterStr(io);
        crs = Util.listMap(innerVars,DAEUtil.varCref);
        {} = Util.listSelect1(crs, cr,isInnerOuterMatch);
        str = Exp.printComponentRefStr(cr);
        Error.addMessage(Error.MISSING_INNER_PREFIX,{str,str2});
      then fail(); 
  end matchcontinue;
end checkMissingInnerDecl2;

public function failExceptForCheck 
"function that fails if checkModel option is not set, otherwise it succeeds.
 It should be used for the cases when normal instantiation should fail but 
 a instantiation for performing checkModel call should not fail"
algorithm
  _ := matchcontinue()
    case() equation true = OptManager.getOption("checkModel"); then ();
    case() equation /* false = OptManager.getOption("checkModel"); */ then fail();
  end matchcontinue;
end failExceptForCheck;

public function innerOuterBooleans 
"Returns inner outer information as two booleans"
  input Absyn.InnerOuter io;
  output Boolean inner1;
  output Boolean outer1;
algorithm
  (inner1,outer1) := matchcontinue(io)
    case(Absyn.INNER()) then (true,false);
    case(Absyn.OUTER()) then (false,true);
    case(Absyn.INNEROUTER()) then (true,true);
    case(Absyn.UNSPECIFIED()) then (false,false);
  end matchcontinue;
end innerOuterBooleans;  

public function referOuter "
Author: BZ, 2008-12 
determin the innerouter attributes for 2 connections.
Special cases:
  if (innerouter , unspecified) -> do NOT prefix firstelement refers to outer elem
  if (innerouter , outer) -> DO prefix
  else
  	use normal function( innerOuterBooleans)
"
input Absyn.InnerOuter io1;
input Absyn.InnerOuter io2;
output Boolean prefix1;
output Boolean prefix2;
algorithm (prefix1,prefix2) := matchcontinue(io1,io2)
  case(Absyn.INNEROUTER(),Absyn.UNSPECIFIED()) then (true,false);
  case(Absyn.INNEROUTER(),Absyn.OUTER()) then (false,true);
  case(io1,io2)
    local Boolean b1,b2;
      equation
        (_,b1) = innerOuterBooleans(io1);
        (_,b2) = innerOuterBooleans(io2);
        then (b1,b2);
  end matchcontinue;
end referOuter;

public function outerConnection "Returns true if either Absyn.InnerOuter is OUTER."
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  output Boolean isOuter;
algorithm
  isOuter := matchcontinue(io1,io2)
    case(Absyn.OUTER(),_) then true;
    case(_,Absyn.OUTER()) then true;
    case(Absyn.INNEROUTER(),_) then true;
    case(_,Absyn.INNEROUTER()) then true;
    case(_,_) then false;        
  end matchcontinue;
end outerConnection;

public function assertDifferentFaces 
"function assertDifferentFaces 
  This function fails if two connectors have same 
  faces, e.g both inside or both outside connectors"
  input Env.Env env;
  input InstHierarchy inIH;
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
algorithm 
  _ := matchcontinue (env,inIH,inComponentRef1,inComponentRef2)
    local DAE.ComponentRef c1,c2;
    case (env,inIH,c1,c2)
      equation 
        Connect.INSIDE()  = ConnectUtil.componentFace(env,inIH,c1);
        Connect.OUTSIDE() = ConnectUtil.componentFace(env,inIH,c1);
      then
        ();
    case (env,inIH,c1,c2)
      equation 
        Connect.OUTSIDE() = ConnectUtil.componentFace(env,inIH,c1);
        Connect.INSIDE()  = ConnectUtil.componentFace(env,inIH,c1);
      then
        ();
  end matchcontinue;
end assertDifferentFaces;

protected function lookupInnerInIH
"@author: adrpo
 Given an instance hierarchy and a component name find the 
 modification of the inner component with the same name"
 input TopInstance inTIH;
 input Prefix.Prefix inPrefix;
 input SCode.Ident inComponentIdent;
 output InstInner outInstInner;
algorithm
  (outInstInner) := matchcontinue(inTIH, inPrefix, inComponentIdent)
    local
      SCode.Ident name;
      Cache outCache;
      DAE.Var outVar;
      Prefix.Prefix prefix;
      Absyn.InnerOuter io;
      Boolean isInner;
      InstHierarchyHashTable ht;
      DAE.ComponentRef cref;
      InstInner instInner;

    // no prefix, this is an error!
    // disabled as this is used in Interactive.getComponents
    // and makes mosfiles/interactive_api_attributes.mos to fail!
    case (TOP_INSTANCE(_, ht), Prefix.NOPRE(),  name) 
      equation
        // print ("Error: outer component: " +& name +& " defined at the top level!");
        // print("InnerOuter.lookupInnerInIH : Looking up: " +& PrefixUtil.printPrefixStr(Prefix.NOPRE()) +& "." +& name +& " REACHED TOP LEVEL! \n");
        // TODO! add warning! 
      then emptyInstInner(name);

    // we have a prefix, remove the last cref from the prefix and search!    
    case (TOP_INSTANCE(_, ht), inPrefix,  name) 
      equation
        // back one step in the instance hierarchy
        prefix = PrefixUtil.prefixStripLast(inPrefix);
        // put the name as the last prefix
        cref = PrefixUtil.prefixCref(prefix, DAE.CREF_IDENT(name, DAE.ET_OTHER(), {}));
        // print("InnerOuter.lookupInnerInIH : Searching for: " +& Exp.printComponentRefStr(cref) +& "\n");
        // search in instance hierarchy
        (instInner as INST_INNER(_, io, _, _)) = get(cref, ht);
        // isInner = Absyn.isInner(io);
        // instInner = Util.if_(isInner, instInner, emptyInstInner(name));
        // print("InnerOuter.lookupInnerInIH : Looking up: " +&  Exp.printComponentRefStr(cref) +& " FOUND! \n");
      then 
        instInner;
        
    // we have a prefix, search recursively as there was a failure before!    
    case (TOP_INSTANCE(_, ht), inPrefix,  name) 
      equation
        // back one step in the instance hierarchy
        prefix = PrefixUtil.prefixStripLast(inPrefix);
        // put the name as the last prefix
        cref = PrefixUtil.prefixCref(prefix, DAE.CREF_IDENT(name, DAE.ET_OTHER(), {})); 
        // search in instance hierarchy
        // we had a failure
        failure(instInner = get(cref, ht));
        // print("InnerOuter.lookupInnerInIH : Couldn't find: " +& Exp.printComponentRefStr(cref) +& " going deeper\n");
        // call recursively to back one more step!
        instInner = lookupInnerInIH(inTIH, prefix, name);
     then
       instInner;
        
    // if we fail return nothing
    case (inTIH as TOP_INSTANCE(_, ht), prefix, name)
      equation
        print("InnerOuter.lookupInnerInIH : Looking up: " +& PrefixUtil.printPrefixStr(prefix) +& "." +& name +& " NOT FOUND! \n");
        // dumpInstHierarchyHashTable(ht);
      then emptyInstInner(name);
  end matchcontinue;
end lookupInnerInIH;

public function modificationOnOuter "
Author BZ, 2008-11 
According to specification modifiers on outer elements is not allowed."
  input Env.Cache cache;
  input Env env;
  input InstHierarchy ih;
  input Prefix.Prefix prefix;
  input String componentName;
  input DAE.ComponentRef cr;
  input Mod inMod;
  input Absyn.InnerOuter io;
  input Boolean impl;
  output Boolean modd;
algorithm 
  omodexp := matchcontinue(cache,env,ih,prefix,componentName,cr,inMod,io,impl)
  local
    String s1,s2,s;
    SCode.Mod scmod1,scmod2;
    Mod mod1,mod2;
  // if we don't have the same modification on inner report error!
  case(_,_,_,_,_,cr,DAE.MOD(finalPrefix = _),Absyn.OUTER(),impl)
    equation
      s1 = Exp.printComponentRefStr(cr);
      s2 = Mod.prettyPrintMod(inMod, 0);
      s = s1 +&  " " +& s2;
      Error.addMessage(Error.OUTER_MODIFICATION, {s});
    then
      true;
  case(_,_,_,_,_,_,_,_,impl) then false;
  end matchcontinue;
end modificationOnOuter;

public function switchInnerToOuterAndPrefix 
"function switchInnerToOuterAndPrefix 
  switches the inner to outer attributes of a component in the dae."
  input list<DAE.Element> inDae;
  input Absyn.InnerOuter io;
  input Prefix.Prefix pre;
  output list<DAE.Element> outDae;   
 algorithm
  outDae := matchcontinue (inDae,io,pre)
    local
      list<DAE.Element> lst,r_1,r,lst_1;
      DAE.Element v;
      DAE.VarDirection dir_1;
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.Type t;
      Option<DAE.Exp> e;
      list<DAE.Subscript> id;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.VarDirection dir;
      String s1,s2;
      DAE.Element x;
      Absyn.InnerOuter io;
      DAE.VarProtection prot;
      String idName;
      DAE.ElementSource source "the origin of the element";

      /* Component that is unspecified does not change inner/outer on subcomponents */ 
    case (lst,Absyn.UNSPECIFIED(),_) then lst;
      
    case ({},_,_) then {}; 
      
      /* unspecified variables are changed to inner/outer if component has such prefix. */ 
    case ((DAE.VAR(componentRef = cr,
                   kind = vk,
                   direction = dir,
                   protection=prot,
                   ty = t,
                   binding = e,
                   dims = id,
                   flowPrefix = flowPrefix,
                   streamPrefix = streamPrefix,
                   source = source,
                   variableAttributesOption = dae_var_attr,
                   absynCommentOption = comment,
                   innerOuter=Absyn.INNER()) :: r),io,pre) 
      equation 
        cr = PrefixUtil.prefixCref(pre, cr);
        r_1 = switchInnerToOuterAndPrefix(r, io, pre);
      then
        (DAE.VAR(cr,vk,dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r_1);

	  /* If var already have inner/outer, keep it. */
    case ( (v as DAE.VAR(componentRef = _)) :: r,io,pre) 
      equation 
        r_1 = switchInnerToOuterAndPrefix(r, io, pre);
      then
        v :: r_1;

			/* Traverse components */
    case ((DAE.COMP(ident = idName,dAElist = lst,source = source) :: r),io,pre)
      equation 
        lst_1 = switchInnerToOuterAndPrefix(lst, io, pre);
        r_1 = switchInnerToOuterAndPrefix(r, io, pre);
      then
        (DAE.COMP(idName,lst_1,source) :: r_1);

    case ((x :: r),io, pre)
      equation 
        r_1 = switchInnerToOuterAndPrefix(r, io, pre);
      then
        (x :: r_1);
  end matchcontinue;
end switchInnerToOuterAndPrefix;

public function prefixOuterDaeVars
"function prefixOuterDaeVars
  prefixes all the outer variables in the DAE with the given prefix."  
  input list<DAE.Element> inDae;
  input Prefix.Prefix crefPrefix;  
  output list<DAE.Element> outDae;   
 algorithm
  outDae := matchcontinue (inDae,crefPrefix)
    local
      list<DAE.Element> lst,r_1,r,lst_1;
      DAE.Element v;
      DAE.VarDirection dir_1;
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.Type t;
      Option<DAE.Exp> e;
      list<DAE.Subscript> id;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.VarDirection dir;
      String s1,s2;
      DAE.Element x;
      Absyn.InnerOuter io;
      DAE.VarProtection prot;
      String idName;
      DAE.ElementSource source "the origin of the element";

    case ({},_) then {}; 
      
    // prefix variables. 
    case ((DAE.VAR(componentRef = cr,
                   kind = vk,
                   direction = dir,
                   protection=prot,
                   ty = t,
                   binding = e,
                   dims = id,
                   flowPrefix = flowPrefix,
                   streamPrefix = streamPrefix,
                   source = source,
                   variableAttributesOption = dae_var_attr,
                   absynCommentOption = comment,
                   innerOuter=io) :: r),crefPrefix) 
      equation 
        cr = PrefixUtil.prefixCref(crefPrefix, cr);
        r_1 = prefixOuterDaeVars(r, crefPrefix);
      then
        (DAE.VAR(cr,vk,dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r_1);

		// Traverse components 
    case ((DAE.COMP(ident = idName,dAElist = lst,source = source) :: r),crefPrefix)
      equation 
        lst_1 = prefixOuterDaeVars(lst, crefPrefix);
        r_1 = prefixOuterDaeVars(r, crefPrefix);
      then
        (DAE.COMP(idName,lst_1,source) :: r_1);

    case ((x :: r),crefPrefix)
      equation 
        r_1 = prefixOuterDaeVars(r, crefPrefix);
      then
        (x :: r_1);
  end matchcontinue;
end prefixOuterDaeVars;

public function switchInnerToOuterInEnv "
function switchInnerToOuterInEnv 
  switches the inner to outer attributes of a component in the Env."
  input Env inEnv;
  input DAE.ComponentRef inCr;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv,inCr)
    local
      Env envIn, envOut, envRest;
      DAE.ComponentRef cr;
      Frame f;
    // handle nothingness
    case ({}, _) then {};      
    // only need to handle top frame!
    case (envIn as (f::envRest), cr)
      equation
        f = switchInnerToOuterInFrame(f, cr);
      then 
        f::envRest;
  end matchcontinue;
end switchInnerToOuterInEnv;

protected function switchInnerToOuterInFrame "
function switchInnerToOuterInFrame 
  switches the inner to outer attributes of a component in the Frame."
  input Frame inFrame;
  input DAE.ComponentRef inCr;
  output Frame outFrame;
algorithm
  outFrame := matchcontinue(inFrame,inCr)
    local
      DAE.ComponentRef cr;
      Frame f;
      Option<Ident> optName "Optional class name" ;
      AvlTree clsAndVars "List of uniquely named classes and variables" ;
      AvlTree types "List of types, which DOES NOT need to be uniquely named, eg. size may have several types" ;
      list<Item> imports "list of unnamed items (imports)" ;
      Env.BCEnv inherited "list of frames for inherited elements" ;
      CSetsType connectionSet "current connection set crefs" ;
      Boolean isEncapsulated "encapsulated bool=true means that FRAME is created due to encapsulated class" ;
      list<SCode.Element> defineUnits "list of units defined in the frame" ;
    
    case (f as Env.FRAME(optName, clsAndVars, types, imports, inherited, connectionSet, isEncapsulated, defineUnits), cr)
      equation
        SOME(clsAndVars) = switchInnerToOuterInAvlTree(SOME(clsAndVars), cr);
      then 
        Env.FRAME(optName, clsAndVars, types, imports, inherited, connectionSet, isEncapsulated, defineUnits);

    case (f as Env.FRAME(optName, clsAndVars, types, imports, inherited, connectionSet, isEncapsulated, defineUnits), cr)
      equation
        // when above fails leave unchanged
      then 
        Env.FRAME(optName, clsAndVars, types, imports, inherited, connectionSet, isEncapsulated, defineUnits);
        
  end matchcontinue;
end switchInnerToOuterInFrame;

protected function switchInnerToOuterInAvlTree "
function switchInnerToOuterInAvlTree 
  switches the inner to outer attributes of a component in the AvlTree."
  input Option<AvlTree> inTreeOpt;
  input DAE.ComponentRef inCr;
  output Option<AvlTree> outTreeOpt;
algorithm
  outTreeOpt := matchcontinue(inTreeOpt,inCr)
    local
      DAE.ComponentRef cr;
      Env.AvlKey rkey;
      String s1,s2,s3,res;
      Env.AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;      
    
    case (NONE(),_) then NONE();    
    
    case (SOME(Env.AVLTREENODE(value = SOME(Env.AVLTREEVALUE(rkey,rval)),height = h,left = l,right = r)), cr)
      equation 
        rval = switchInnerToOuterInAvlTreeValue(rval, cr);
        l = switchInnerToOuterInAvlTree(l, cr); 
        r = switchInnerToOuterInAvlTree(r, cr);        
      then
        SOME(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(rkey,rval)),h,l,r));
        
    case (SOME(Env.AVLTREENODE(value = NONE(),height = h,left = l,right = r)),cr)
      equation 
        l = switchInnerToOuterInAvlTree(l, cr); 
        r = switchInnerToOuterInAvlTree(r, cr);        
      then
        SOME(Env.AVLTREENODE(NONE(),h,l,r));
  end matchcontinue;
end switchInnerToOuterInAvlTree;

protected function switchInnerToOuterInAvlTreeValue "
function switchInnerToOuterInAvlTreeValue 
  switches the inner to outer attributes of a component in the AvlTree."
  input Item inItem;
  input DAE.ComponentRef inCr;
  output Item outItem;
algorithm
  outItem := matchcontinue(inItem,inCr)
    local
      DAE.ComponentRef cr;
      Env.AvlKey rkey;
      String s1,s2,s3,res;
      Env.AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;
      DAE.Var instantiated;
      DAE.Ident name "name";
      DAE.Attributes attributes "attributes";
      Boolean protected_ "protected";
      DAE.Type type_ "type";
      DAE.Binding binding "binding ; equation modification";
      DAE.Var instantiated "instantiated component";
      Option<tuple<SCode.Element, DAE.Mod>> declaration "declaration if not fully instantiated.";
      Env.InstStatus instStatus "if it untyped, typed or fully instantiated (dae)";
      Env env "The environment of the instantiated component. Contains e.g. all sub components";

      Boolean flowPrefix "flow" ;
      Boolean streamPrefix "stream" ;
      SCode.Accessibility accessibility "accessibility" ;
      SCode.Variability parameter_ "parameter" ;
      Absyn.Direction direction "direction" ;
      Absyn.InnerOuter innerOuter "inner, outer,  inner outer or unspecified";
    
    case (Env.VAR(DAE.TYPES_VAR(name, attributes, protected_, type_, binding), declaration, instStatus, env), cr)
      equation
        DAE.ATTR(flowPrefix, streamPrefix, accessibility, parameter_, direction, Absyn.INNER()) = attributes;
        attributes = DAE.ATTR(flowPrefix, streamPrefix, accessibility, parameter_, direction, Absyn.OUTER());
        // env = switchInnerToOuterInEnv(env, inCr);
      then Env.VAR(DAE.TYPES_VAR(name, attributes, protected_, type_, binding), declaration, instStatus, env);

    // leave unchanged
    case (inItem, _) then inItem;        
  end matchcontinue;
end switchInnerToOuterInAvlTreeValue;


///////////////////////////////////////////////////
/// instance hieararchy for inner/outer
/// add furher functions before this
///////////////////////////////////////////////////


public function emptyInstInner
  input String name;
  output InstInner outInstInner;
algorithm
  outInstInner := INST_INNER(name, Absyn.UNSPECIFIED(), NONE(), {});
end emptyInstInner;

public function lookupInnerVar 
"@author: adrpo
 This function lookups the result of instatiation of the inner 
 component given an instance hierarchy a prefix and a component name."
  input Cache inCache;
  input Env inEnv;
  input InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input SCode.Ident inIdent;
  input Absyn.InnerOuter io;
  output InstInner outInstInner;
algorithm 
  (outInstInner) := matchcontinue (inCache,inEnv,inIH,inPrefix,inIdent,io)
    local
      Cache cache;
      String n;
      Absyn.InnerOuter io;
      Env env;
      Prefix.Prefix pre;
      InstHierarchy ih;
      TopInstance tih;
      InstInner instInner; 
      
    // adrpo: if component is an outer or an inner/outer we need to 
    //        lookup the modification of the inner component and use it
    //        when we instantiate the outer component
    case (cache,env,tih::_,pre,n,io) 
      equation 
        // is component an outer or an inner/outer?
        true = Absyn.isOuter(io);  // is outer
        false = Absyn.isInner(io); // and is not inner
        // search the instance hierarchy for the inner component
        instInner = lookupInnerInIH(tih, pre, n);
      then 
        instInner;
      
    // failure in case we look for anything else but outer!
    case (cache,env,_,pre,n,io)
      equation
        Debug.fprintln("failtrace", "InnerOuter.lookupInnerVar failed on component: " +& PrefixUtil.printPrefixStr(pre) +& "." +& n); 
      then 
        fail();
    end matchcontinue;
end lookupInnerVar;

public function updateInstHierarchy
"@author: adrpo
 This function updates the instance hierarchy by adding 
 the INNER components to it with the given prefix"
  input InstHierarchy inIH;
  input Prefix.Prefix inPrefix;
  input Absyn.InnerOuter inInnerOuter;
  input InstInner inInstInner; 
  output InstHierarchy outIH;
algorithm
  outIH := matchcontinue(inIH,inPrefix,inInnerOuter,inInstInner)
    local
      TopInstance tih;
      InstHierarchy restIH, ih;
      DAE.ComponentRef cref;
      SCode.Ident name;
      Absyn.InnerOuter io;
      DAE.Mod mod;
      InstHierarchyHashTable ht;
      Option<Absyn.Path> pathOpt;
      SCode.Element c;
      DAE.DAElist dae;
      Env innerComponentEnv;

    // only add inner elements
    case(ih,inPrefix,inInnerOuter,inInstInner as INST_INNER(name=name))
      equation
        false = Absyn.isInner(inInnerOuter);
        // prefix the name!
        cref = PrefixUtil.prefixCref(inPrefix, DAE.CREF_IDENT(name, DAE.ET_OTHER(), {}));
        // print ("InnerOuter.updateInstHierarchy jumping over non-inner: " +& Exp.printComponentRefStr(cref) +& "\n");
      then
        ih;

    // no hashtable, create one!
    case({},inPrefix,inInnerOuter,inInstInner as INST_INNER(name=name))
      equation
        // print ("InnerOuter.updateInstHierarchy creating an empty hash table! \n");        
        ht = emptyInstHierarchyHashTable();
        tih = TOP_INSTANCE(NONE(), ht);
        ih = updateInstHierarchy({tih}, inPrefix, inInnerOuter, inInstInner);
      then 
        ih;

    // add to the hierarchy
    case((tih as TOP_INSTANCE(pathOpt, ht))::restIH,inPrefix,inInnerOuter,
         inInstInner as INST_INNER(name, io, _, _))
      equation
        // prefix the name!
        cref = PrefixUtil.prefixCref(inPrefix, DAE.CREF_IDENT(name, DAE.ET_OTHER(), {}));
        // add to hashtable!
        // print ("InnerOuter.updateInstHierarchy adding: " +& Exp.printComponentRefStr(cref) +& " to IH\n");
        ht = add((cref,inInstInner), ht);
      then 
        TOP_INSTANCE(pathOpt, ht)::restIH;
    // failure
    case(ih,inPrefix,inInnerOuter,inInstInner as INST_INNER(name, io, _, _))
      equation
        // prefix the name!
        cref = PrefixUtil.prefixCref(inPrefix, DAE.CREF_IDENT("UNKNOWN", DAE.ET_OTHER(), {}));        
        print ("InnerOuter.updateInstHierarchy failure for: " +& Exp.printComponentRefStr(cref) +& "\n");
      then 
        fail();        
  end matchcontinue;  
end updateInstHierarchy;

/////////////////////////////////////////////////////////////////
// hash table implementation for InnerOuter instance hierarchy //
/////////////////////////////////////////////////////////////////

public function hashFunc 
"author: PA
  Calculates a hash value for DAE.ComponentRef"
  input Key k;
  output Integer res;
algorithm 
  res := System.hash(Exp.crefStr(k));
end hashFunc;

public function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
     res := stringEqual(Exp.crefStr(key1),Exp.crefStr(key2));
end keyEqual;

public function dumpInstHierarchyHashTable ""
  input InstHierarchyHashTable t;
algorithm
  print("InstHierarchyHashTable:\n");
  print(Util.stringDelimitList(Util.listMap(hashTableList(t),dumpTuple),"\n"));
  print("\n");
end dumpInstHierarchyHashTable;

public function dumpTuple
  input tuple<Key,Value> tpl;
  output String str;
algorithm
  str := matchcontinue(tpl)
    local 
      Key k; Value v; 
    case((k,v)) 
      equation
        str = "{" +& 
         Exp.crefStr(k) +& 
         " opaque InstInner for now, implement printing. " +& "}\n";
      then str;
  end matchcontinue;
end dumpTuple;

/* end of InstHierarchyHashTable instance specific code */

/* Generic hashtable code below!! */
public  
uniontype InstHierarchyHashTable
  record HASHTABLE
    list<tuple<Key,Integer>>[:] hashTable " hashtable to translate Key to array indx" ;
    ValueArray valueArr "Array of values" ;
    Integer bucketSize "bucket size" ;
    Integer numberOfEntries "number of entries in hashtable" ;   
  end HASHTABLE;
end InstHierarchyHashTable; 

uniontype ValueArray 
"array of values are expandable, to amortize the 
 cost of adding elements in a more efficient manner"
  record VALUE_ARRAY
    Integer numberOfElements "number of elements in hashtable" ;
    Integer arrSize "size of crefArray" ;
    Option<tuple<Key,Value>>[:] valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

public function cloneInstHierarchyHashTable 
"Author BZ 2008-06
 Make a stand-alone-copy of hashtable."
input InstHierarchyHashTable inHash;
output InstHierarchyHashTable outHash;
algorithm outHash := matchcontinue(inHash)
  local 
    list<tuple<Key,Integer>>[:] arg1,arg1_2;
    Integer arg3,arg4,arg3_2,arg4_2,arg21,arg21_2,arg22,arg22_2;
    Option<tuple<Key,Value>>[:] arg23,arg23_2;
  case(HASHTABLE(arg1,VALUE_ARRAY(arg21,arg22,arg23),arg3,arg4))
    equation
      arg1_2 = arrayCopy(arg1);
      arg21_2 = arg21;
      arg22_2 = arg22;
      arg23_2 = arrayCopy(arg23);
      arg3_2 = arg3;
      arg4_2 = arg4;
      then
        HASHTABLE(arg1_2,VALUE_ARRAY(arg21_2,arg22_2,arg23_2),arg3_2,arg4_2);
end matchcontinue;
end cloneInstHierarchyHashTable;

public function emptyInstHierarchyHashTable 
"author: PA
  Returns an empty InstHierarchyHashTable.
  Using the bucketsize 100 and array size 10."
  output InstHierarchyHashTable hashTable;
  list<tuple<Key,Integer>>[:] arr;
  list<Option<tuple<Key,Value>>> lst;
  Option<tuple<Key,Value>>[:] emptyarr;
algorithm 
  arr := fill({}, 1000);
  emptyarr := fill(NONE(), 100);
  hashTable := HASHTABLE(arr,VALUE_ARRAY(0,100,emptyarr),1000,0);
end emptyInstHierarchyHashTable;

public function isEmpty "Returns true if hashtable is empty"
  input InstHierarchyHashTable hashTable;
  output Boolean res;
algorithm
  res := matchcontinue(hashTable)
    case(HASHTABLE(_,_,_,0)) then true;
    case(_) then false;  
  end matchcontinue;
end isEmpty;

public function add 
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input InstHierarchyHashTable hashTable;
  output InstHierarchyHashTable outHahsTable;
algorithm 
  outVariables:=
  matchcontinue (entry,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);        
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
      
      /* adding when already present => Updating value */
    case ((newv as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,_)
      equation 
        print("-InstHierarchyHashTable.add failed\n");
      then
        fail();
  end matchcontinue;
end add;

public function addNoUpdCheck 
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input InstHierarchyHashTable hashTable;
  output InstHierarchyHashTable outHahsTable;
algorithm 
  outVariables := matchcontinue (entry,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
    // Adding when not existing previously
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);        
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
    case (_,_)
      equation 
        print("-InstHierarchyHashTable.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;

public function delete 
"author: PA
  delete the Value associatied with Key from the InstHierarchyHashTable.
  Note: This function does not delete from the index table, only from the ValueArray.
  This means that a lot of deletions will not make the InstHierarchyHashTable more compact, it 
  will still contain a lot of incices information."
  input Key key;
  input InstHierarchyHashTable hashTable;
  output InstHierarchyHashTable outHahsTable;
algorithm 
  outVariables := matchcontinue (key,hashTable)
    local     
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      list<tuple<Key,Integer>>[:] hashvec_1,hashvec;
      String name_str;      
      tuple<Key,Value> v,newv;
      Key key;
      Value value;     
    // adding when already present => Updating value
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        (_,indx) = get1(key, hashTable);
        indx_1 = indx - 1;
        varr_1 = valueArrayClearnth(varr, indx);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,hashTable)
      equation 
        print("-InstHierarchyHashTable.delete failed\n");
        print("content:"); dumpInstHierarchyHashTable(hashTable);
      then
        fail();
  end matchcontinue;
end delete;

public function get 
"author: PA 
  Returns a Value given a Key and a InstHierarchyHashTable."
  input Key key;
  input InstHierarchyHashTable hashTable;
  output Value value;
algorithm 
  (value,_):= get1(key,hashTable);
end get;

public function get1 "help function to get"
  input Key key;
  input InstHierarchyHashTable hashTable;
  output Value value;
  output Integer indx;
algorithm 
  (value,indx):= matchcontinue (key,hashTable)
    local
      Integer hval,hashindx,indx,indx_1,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;      
      list<tuple<Key,Integer>>[:] hashvec;     
      ValueArray varr;
      Key key2;
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation 
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        v = valueArrayNth(varr, indx);
      then
        (v,indx);
  end matchcontinue;
end get1;

public function get2 
"author: PA 
  Helper function to get"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  output Integer index;
algorithm 
  index := matchcontinue (key,keyIndices)
    local
      Key key2;
      Value res;
      list<tuple<Key,Integer>> xs;
    case (key,((key2,index) :: _))
      equation 
        true = keyEqual(key, key2);
      then
        index;
    case (key,(_ :: xs))      
      equation 
        index = get2(key, xs);
      then
        index;
  end matchcontinue;
end get2;

public function hashTableValueList "return the Value entries as a list of Values"
  input InstHierarchyHashTable hashTable;
  output list<Value> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple22);
end hashTableValueList;

public function hashTableKeyList "return the Key entries as a list of Keys"
  input InstHierarchyHashTable hashTable;
  output list<Key> valLst;
algorithm
   valLst := Util.listMap(hashTableList(hashTable),Util.tuple21);
end hashTableKeyList;

public function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
  input InstHierarchyHashTable hashTable;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue(hashTable)
  local ValueArray varr;
    case(HASHTABLE(valueArr = varr)) equation
      tplLst = valueArrayList(varr);
    then tplLst; 
  end matchcontinue;
end hashTableList;

public function valueArrayList 
"author: PA
  Transforms a ValueArray to a tuple<Key,Value> list"
  input ValueArray valueArray;
  output list<tuple<Key,Value>> tplLst;
algorithm 
  tplLst := matchcontinue (valueArray)
    local
      Option<tuple<Key,Value>>[:] arr;
      tuple<Key,Value> elt;
      Integer lastpos,n,size;
      list<tuple<Key,Value>> lst;
    case (VALUE_ARRAY(numberOfElements = 0,valueArray = arr)) then {}; 
    case (VALUE_ARRAY(numberOfElements = 1,valueArray = arr))
      equation 
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr))
      equation 
        lastpos = n - 1;
        lst = valueArrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end valueArrayList;

public function valueArrayList2 "Helper function to valueArrayList"
  input Option<tuple<Key,Value>>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<tuple<Key,Value>> outVarLst;
algorithm 
  outVarLst := matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      tuple<Key,Value> v;
      Option<tuple<Key,Value>>[:] arr;
      Integer pos,lastpos,pos_1;
      list<tuple<Key,Value>> res;
    case (arr,pos,lastpos)
      equation 
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        NONE = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (res);
  end matchcontinue;
end valueArrayList2;

public function valueArrayLength 
"author: PA
  Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer size;
algorithm 
  size := matchcontinue (valueArray)
    case (VALUE_ARRAY(numberOfElements = size)) then size; 
  end matchcontinue;
end valueArrayLength;

public function valueArrayAdd 
"function: valueArrayAdd
  author: PA 
  Adds an entry last to the ValueArray, increasing 
  array size if no space left by factor 1.4"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      Option<tuple<Key,Value>>[:] arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation 
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,size,arr_1);
        
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation 
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize*.0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE);
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation 
        print("-InstHierarchyHashTable.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth 
"function: valueArraySetnth
  author: PA 
  Set the n:th variable in the ValueArray to value."
  input ValueArray valueArray;
  input Integer pos;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,pos,entry)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;      
    case (VALUE_ARRAY(n,size,arr),pos,entry)
      equation 
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_,_)
      equation 
        print("-InstHierarchyHashTable.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

public function valueArrayClearnth 
"author: PA
  Clears the n:th variable in the ValueArray (set to NONE)."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm 
  outValueArray := matchcontinue (valueArray,pos)
    local
      Option<tuple<Key,Value>>[:] arr_1,arr;
      Integer n,size,pos;      
    case (VALUE_ARRAY(n,size,arr),pos)
      equation 
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, NONE);
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_)
      equation 
        print("-InstHierarchyHashTable.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

public function valueArrayNth 
"function: valueArrayNth
  author: PA 
  Retrieve the n:th Vale from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Value value;
algorithm 
  value := matchcontinue (valueArray,pos)
    local
      Value v;
      Integer n,pos,len;
      Option<tuple<Key,Value>>[:] arr;
      String ps,lens,ns;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation 
        (pos < n) = true;
        SOME((_,v)) = arr[pos + 1];
      then
        v;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation 
        (pos < n) = true;
        NONE = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;

end InnerOuter;
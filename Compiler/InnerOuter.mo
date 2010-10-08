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
protected import InstSection;
protected import ConnectUtil;
protected import RTOpts;
protected import Mod;
protected import PrefixUtil;
protected import ErrorExt;

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
    Prefix innerPrefix "the prefix of the inner. we need it to prefix the outer variables with it!";    
    SCode.Ident name;
    Absyn.InnerOuter io;
    String fullName "full inner component name";
    Absyn.Path typePath "the type of the inner";
    String scope "the scope of the inner";
    // add these if needed!
    // SCode.Mod scodeMod;
    // DAE.Mod mod;
    Option<InstResult> instResult;
    list<DAE.ComponentRef> outers "which outers are referencing this inner";
  end INST_INNER;
end InstInner;

uniontype OuterPrefix
  record OUTER
    DAE.ComponentRef outerComponentRef "the prefix of this outer + component name";
    DAE.ComponentRef innerComponentRef "the coresponding prefix for this outer + component name";
  end OUTER;
end OuterPrefix;

type OuterPrefixes = list<OuterPrefix>;
  
constant OuterPrefixes emptyOuterPrefixes = {} "empty outer prefixes";

public
type Key = DAE.ComponentRef "the prefix + '.' + the component name";
type Value = InstInner "the inputs of the instantiation function and the results";

uniontype TopInstance "a top instance is an instance of a model thar resides at top level"
  record TOP_INSTANCE
    Option<Absyn.Path> path "top model path";
    InstHierarchyHashTable ht "hash table with fully qualified components";
    OuterPrefixes outerPrefixes "the outer prefixes help us prefix the outer components with the correct prefix of inner component directly";
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
    case (Absyn.OUTER(),dae,ih,graphNew,graph)
      equation
        (odae,_) = DAEUtil.splitDAEIntoVarsAndEquations(dae);
      then
        (odae,ih,graph);
    // is both an inner and an outer,
    // rename inner vars in the equations to unique names
    // innerouter component change the connection graph
    case (Absyn.INNEROUTER(),dae,ih,graphNew,graph)
      equation
        (dae1,dae2) = DAEUtil.splitDAEIntoVarsAndEquations(dae);
        // rename variables in the equations and algs.
        // inner vars from dae1 are kept with the same name.
        dae2 = DAEUtil.nameUniqueOuterVars(dae2);
        
        dae = DAEUtil.joinDaes(dae1,dae2);
        // adrpo: TODO! FIXME: here we should do a difference of graphNew-graph
        //                     and rename the new equations added with unique vars.
      then
        (dae,ih,graph);
    // is an inner do nothing
    case (Absyn.INNER(),dae,ih,graphNew,graph) then (dae,ih,graphNew);
    // is not an inner nor an outer
    case (Absyn.UNSPECIFIED (),dae,ih,graphNew,graph) then (dae,ih,graphNew);
    // something went totally wrong!
    case (_,dae,ih,graphNew,graph)
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
  input Boolean isTopLevel;
  output DAE.DAElist outDae;
  output Connect.Sets ocsets;
  output InstHierarchy outIH;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (ocsets,outDae,outIH,outGraph) := matchcontinue(inDae,csets,inIH,inGraph,isTopLevel)
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

    // adrpo: is not top level so return the same
    case(inDae,csets,ih,graph,false) 
      then (inDae,csets,ih,graph);

    // adrpo: return the same if we have no inner/outer components!
    case(inDae,csets,ih,graph,true)
      equation
        // print("changeOuterReferences: " +& ConnectUtil.printSetsStr(csets));
        false = System.getHasInnerOuterDefinitions();
      then (inDae,csets,ih,graph);

    // adrpo: specific faster case when there are *no inner* elements!
    case(inDae as DAE.DAE(allDAEelts),csets,ih,graph,true)
      equation
        // when we have no inner elements we can return the same!
        (DAE.DAE({}),_) = DAEUtil.findAllMatchingElements(inDae,DAEUtil.isInnerVar,DAEUtil.isOuterVar);
      then (inDae,csets,ih,graph);

    // adrpo: specific faster case when there are *no outer* elements!
    case(inDae as DAE.DAE(allDAEelts),csets,ih,graph,true)
      equation
        // when we have no outer elements we can return the same!
        (_,DAE.DAE({})) = DAEUtil.findAllMatchingElements(inDae,DAEUtil.isInnerVar,DAEUtil.isOuterVar);
      then (inDae,csets,ih,graph);

    // general case
    case(inDae as DAE.DAE(allDAEelts),csets,ih,
         graph as ConnectionGraph.GRAPH(updateGraph,
                                        definiteRoots,
                                        potentialRoots,
                                        branches,
                                        connections),true)
      equation
        (DAE.DAE(innerVars),DAE.DAE(outerVars)) = DAEUtil.findAllMatchingElements(inDae,DAEUtil.isInnerVar,DAEUtil.isOuterVar);
        repl = buildInnerOuterRepl(innerVars,outerVars,VarTransform.emptyReplacements());
        // Debug.fprintln("innerouter", "Number of elts/inner vars/outer vars: " +&
        //        intString(listLength(allDAEelts)) +&
        //        "/" +& intString(listLength(innerVars)) +&
        //        "/" +& intString(listLength(outerVars)));
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
    case(inDae,csets,ih,graph,true)
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
      Connect.OuterConnect oc;
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
        (_,cr3) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,scope,cr1);
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
        (_,cr3) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,scope,cr2);
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
    case((oc as Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source))::ocs,repl,sources,targets)
      equation
        //s1 = Exp.printComponentRefStr(cr1);
        //s2 = Exp.printComponentRefStr(cr2);
        recRes = changeOuterReferences3(ocs,repl,sources,targets);
      then
        oc::recRes;
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

public function changeInnerOuterInOuterConnect 
"@author: adrpo
  changes inner to outer and outer to inner where needed"
  input list<Connect.OuterConnect> ocs;
  output list<Connect.OuterConnect> oocs;
algorithm
  oocs := matchcontinue(ocs)
    local
      list<Connect.OuterConnect> recRes;
      Connect.OuterConnect oc;
      DAE.ComponentRef cr1,cr2,ncr1,ncr2,cr3,ver1,ver2;
      Absyn.InnerOuter io1,io2;
      Connect.Face f1,f2;
      Prefix.Prefix scope;
      list<DAE.ComponentRef> src,dst;
      String s1,s2;
      DAE.ElementSource source "the origin of the element";
    // handle nothingness
    case({}) then {};
    // the left hand side is an outer!
    case(Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::ocs)
      equation
        (_,true) = innerOuterBooleans(io1);
        // (_,cr3) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,scope,cr1);
        // ncr1 = cr3;
        ncr1 = PrefixUtil.prefixToCref(scope);
        // Debug.fprintln("ios", "changeInnerOuterInOuterConnect: changing left: " +&
        //   Exp.printComponentRefStr(cr1) +& " to inner");
        ver1 = Exp.crefFirstIdent(ncr1);
        ver2 = Exp.crefIdent(cr1);
        false = Exp.crefEqual(ver1,ver2);
        recRes = changeInnerOuterInOuterConnect(ocs);
      then
        Connect.OUTERCONNECT(scope,cr1,Absyn.INNER(),f1,cr2,io2,f2,source)::recRes;
    // the right hand side is an outer!
    case(Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::ocs)
      equation
        (_,true) = innerOuterBooleans(io2);
        // (_,cr3) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,scope,cr2);
        // ncr2 = cr3;        
        ncr2 = PrefixUtil.prefixToCref(scope);
        // Debug.fprintln("ios", "changeInnerOuterInOuterConnect: changing right: " +&
        //   Exp.printComponentRefStr(cr2) +& " to inner");
        ver1 = Exp.crefFirstIdent(ncr2);
        ver2 = Exp.crefIdent(cr2);
        false = Exp.crefEqual(ver1,ver2);
        recRes = changeInnerOuterInOuterConnect(ocs);
      then
        Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,Absyn.INNER(),f2,source)::recRes;
    // none of left or right hand side are outer
    case((oc as Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source))::ocs)
      equation
        recRes = changeInnerOuterInOuterConnect(ocs);
      then
        oc::recRes;
  end matchcontinue;
end changeInnerOuterInOuterConnect;

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
        true = stringEqual(id1, id2);
        (cr11,cr22) = stripCommonCrefPart(cr1,cr2);
      then 
        (cr11,cr22);
    
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
algorithm 
  cr3 := matchcontinue(prefixedCref,innerCref)
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
      Connect.Sets newCsets;

    case(cache,env,ih,pre,Connect.SETS(setLst,crs,delcomps,outerConnects),topCall)
      equation
        (outerConnects,setLst,crs,innerOuterConnects) = retrieveOuterConnections2(cache,env,ih,pre,outerConnects,setLst,crs,topCall);
      then
        (Connect.SETS(setLst,crs,delcomps,outerConnects),innerOuterConnects);
    
  end matchcontinue;
end retrieveOuterConnections;

protected function removeInnerPrefixFromCref
"@author: adrpo
 This function will strip the given prefix from the component references."
 input Prefix.Prefix inPrefix;
 input Exp.ComponentRef inCref;
 output Exp.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inPrefix, inCref)
    local
      Exp.ComponentRef crefPrefix, crOuter;
    
    // no prefix to strip, return the cref!
    case (Prefix.NOPRE(), inCref) then inCref;
    
    // we have a prefix, remove it from the cref
    case (inPrefix, inCref)
      equation
        // transform prefix into cref
        crefPrefix = PrefixUtil.prefixToCref(inPrefix);
        // remove the prefix from the component reference
        crOuter = Exp.crefStripPrefix(inCref, crefPrefix);
      then
        crOuter;
    
    // something went wrong, print a failtrace and then 
    case (inPrefix, inCref)
      equation
        //true = RTOpts.debugFlag("failtrace");
        //Debug.traceln("- InnerOuter.removeInnerPrefixFromCref failed on prefix: " +& PrefixUtil.printPrefixStr(inPrefix) +&
        // " cref: " +& Exp.printComponentRefStr(inCref));
      then 
        inCref;
  end matchcontinue;
end removeInnerPrefixFromCref;

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
      DAE.ComponentRef cr1,cr2,cr1Outer,cr2Outer,crefPrefix;
      Absyn.InnerOuter io1,io2;
      Connect.OuterConnect oc;
      Boolean keepInOuter,inner1,inner2,outer1,outer2,added,b1Outer,b2Outer;
      Connect.Face f1,f2;
      Prefix.Prefix scope;
      InstHierarchy ih;
      DAE.ElementSource source "the origin of the element";
      Absyn.Info info;

    // handle empty
    case(cache,env,ih,pre,{},setLst,crs,_) then ({},setLst,crs,{});
      
    // an inner only outer connect  
    case(cache,env,ih,pre,Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source as DAE.SOURCE(info = info))::outerConnects,setLst,crs,topCall)
      equation
        cr1Outer = cr1;
        cr2Outer = cr2;
        
        // Debug.fprintln("innerouter", "Prefix: " +& PrefixUtil.printPrefixStr(pre) +& "/" +& 
        //  Exp.printComponentRefStr(cr1) +& " = " +& Exp.printComponentRefStr(cr2) +& " => " +&
        //  Exp.printComponentRefStr(cr1Outer) +& " = " +& Exp.printComponentRefStr(cr2Outer));
        
        (inner1,outer1) = lookupVarInnerOuterAttr(cache,env,ih,cr1Outer,cr2Outer);
        
        // Debug.fprintln("innerouter", "cr1 inner: "+& Util.if_(inner1, " true ", " false ") +& 
        //                              "cr1 outer: "+& Util.if_(outer1, " true ", " false "));
        
        true = inner1;
        false = outer1;
        
        // don't use these as they take longer, instead use the type from the cref directly!
        // f1 = ConnectUtil.componentFace(env,cr1);
        // f2 = ConnectUtil.componentFace(env,cr2);
        
        f1 = ConnectUtil.componentFaceType(cr1);
        f2 = ConnectUtil.componentFaceType(cr2);
        
        // remove the prefixes so we can find it in the DAE
        cr1 = removeInnerPrefixFromCref(pre, cr1);
        cr2 = removeInnerPrefixFromCref(pre, cr2);
        
        (setLst,crs,added) = ConnectUtil.addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,crs);
        
        // if no connection set available (added = false), create new one
        setLst = addOuterConnectIfEmpty(cache,env,ih,pre,setLst,added,cr1,io1,f1,cr2,io2,f2,info);
        
        (outerConnects,setLst,crs,innerOuterConnects) =
          retrieveOuterConnections2(cache,env,ih,pre,outerConnects,setLst,crs,topCall);
        
        // if is also outer, then keep it also in the outer connects 
        outerConnects = Util.if_(outer1,Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::outerConnects,outerConnects);
      then
        (outerConnects,setLst,crs,innerOuterConnects);
    
    // this case is for innerouter declarations, since we do not have them in environment we need to treat them in a special way 
    case(cache,env,ih,pre,(oc as Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source as DAE.SOURCE(info = info)))::outerConnects,setLst,crs,true)
      local Boolean b1,b2,b3,b4;
      equation
        (b1,b3) = innerOuterBooleans(io1);
        (b2,b4) = innerOuterBooleans(io2);
        true = boolOr(b1,b2); // for inner outer we set Absyn.INNER()
        false = boolOr(b3,b4);
        f1 = ConnectUtil.componentFaceType(cr1);
        f2 = ConnectUtil.componentFaceType(cr2);
        // cr1 = DAEUtil.unNameInnerouterUniqueCref(cr1,DAE.UNIQUEIO);
        // cr2 = DAEUtil.unNameInnerouterUniqueCref(cr2,DAE.UNIQUEIO);
        io1 = convertInnerOuterInnerToOuter(io1); // we need to change from inner to outer to be able to join sets in: addOuterConnectToSets
        io2 = convertInnerOuterInnerToOuter(io2);
        (setLst,crs,added) = ConnectUtil.addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,crs);
        /* If no connection set available (added = false), create new one */
        setLst = addOuterConnectIfEmptyNoEnv(cache,env,ih,pre,setLst,added,cr1,io1,f1,cr2,io2,f2,info);
        (outerConnects,setLst,crs,innerOuterConnects) =
        retrieveOuterConnections2(cache,env,ih,pre,outerConnects,setLst,crs,true);
      then
        (outerConnects,setLst,crs,innerOuterConnects);
    
    // just keep the outer connects the same if we don't find them in the same scope   
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
  input Absyn.Info info;
  output list<Connect.Set> outSetLst;
algorithm
  outSetLst := matchcontinue(cache,env,ih,pre,setLst,added,cr1,io1,f1,cr2,io2,f2,info)
     local SCode.Variability vt1,vt2;
       DAE.Type t1,t2;
       Boolean flowPrefix,streamPrefix;
       DAE.DAElist dae;
       list<Connect.Set> setLst2;
       Connect.Sets csets;
       InstHierarchy ih;

    // if it was added, return the same
    case(cache,env,ih,pre,setLst,true,_,_,_,_,_,_,_)
      then setLst;
    
    // if it was not added, add it (search for both components)
    case(cache,env,ih,pre,setLst,false,cr1,io1,f1,cr2,io2,f2,info)
      equation
        (cache,DAE.ATTR(flowPrefix,streamPrefix,_,vt1,_,_),t1,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        (cache,DAE.ATTR(         _,_,_,vt2,_,_),t2,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        io1 = removeOuter(io1);
        io2 = removeOuter(io2);
        (cache,env,ih,csets as Connect.SETS(setLst=setLst2),dae,_) =
        InstSection.connectComponents(cache,env,ih,Connect.SETS(setLst,{},{},{}),pre,cr1,f1,t1,vt1,cr2,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,ConnectionGraph.EMPTY,info);
        /* TODO: take care of dae, can contain asserts from connections */
        setLst = setLst2; // listAppend(setLst,setLst2);
      then
        setLst;

    // This can fail, for innerouter, the inner part is not declared in env so instead the call to addOuterConnectIfEmptyNoEnv will succed.
    case(cache,env,ih,pre,setLst,_,cr1,_,_,cr2,_,_,_)
      equation
        //print("Failed lookup: " +& Exp.printComponentRefStr(cr1) +& "\n");
        //print("Failed lookup: " +& Exp.printComponentRefStr(cr2) +& "\n");
        // print("#FAILURE# in: addOuterConnectIfEmpty:__ " +& Exp.printComponentRefStr(cr1) +& " " +& Exp.printComponentRefStr(cr2) +& "\n");
      then fail();

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
  input Absyn.Info info;
  output list<Connect.Set> outSetLst;
algorithm
  outSetLst := matchcontinue(cache,env,inIH,pre,setLst,added,cr1,io1,f1,cr2,io2,f2,info)
     local
       SCode.Variability vt1,vt2;
       DAE.Type t1,t2;
       Boolean flowPrefix,streamPrefix;
       DAE.DAElist dae;
       list<Connect.Set> setLst2;
       Connect.Sets csets;
       InstHierarchy ih;

    // if it was added, return the same
    case(cache,env,ih,pre,setLst,true,_,_,_,_,_,_,_) then setLst;
    
    // if it was not added, add it (first component found: cr1)
    case(cache,env,ih,pre,setLst,false,cr1,io1,f1,cr2,io2,f2,info)
      equation
        (cache,DAE.ATTR(flowPrefix=flowPrefix,streamPrefix=streamPrefix,parameter_=vt1),t1,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        pre = Prefix.NOPRE();
        t2 = t1;
        vt2 = vt1;
        io1 = removeOuter(io1);
        io2 = removeOuter(io2);
        (cache,env,ih,csets as Connect.SETS(setLst=setLst2),dae,_) =
        InstSection.connectComponents(cache,env,ih,Connect.SETS(setLst,{},{},{}),pre,cr1,f1,t1,vt1,cr2,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,ConnectionGraph.EMPTY,info);
        /* TODO: take care of dae, can contain asserts from connections */
        setLst = setLst2; // listAppend(setLst,setLst2);
    then
      setLst;

    // if it was not added, add it (first component found: cr2)
    case(cache,env,ih,pre,setLst,false,cr1,io1,f1,cr2,io2,f2,info)
      equation
        pre = Prefix.NOPRE();
        (cache,DAE.ATTR(flowPrefix=flowPrefix,streamPrefix=streamPrefix,parameter_=vt2),t2,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        t1 = t2;
        vt1 = vt2;
        io1 = removeOuter(io1);
        io2 = removeOuter(io2);
        (cache,env,ih,csets as Connect.SETS(setLst=setLst2),dae,_) =
        InstSection.connectComponents(cache,env,ih,Connect.SETS(setLst,{},{},{}),pre,cr1,f1,t1,vt1,cr2,f2,t2,vt2,flowPrefix,streamPrefix,io1,io2,ConnectionGraph.EMPTY,info);
        /* TODO: take care of dae, can contain asserts from connections */
        setLst = setLst2; // listAppend(setLst,setLst2);
      then setLst;
    
    // fail
    case(cache,env,ih,pre,setLst,_,_,_,_,_,_,_,_)
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
 its inner and outer attributes in form of booleans.
 adrpo: Make sure that there are no error messages displayed!"
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
    // Search for both 
    case(cache,env,ih,cr1,cr2)
      equation
        ErrorExt.setCheckpoint("lookupVarInnerOuterAttr");
        (_,DAE.ATTR(innerOuter=io1),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        (_,DAE.ATTR(innerOuter=io2),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        (isInner1,isOuter1) = innerOuterBooleans(io1);
        (isInner2,isOuter2) = innerOuterBooleans(io2);
        isInner = isInner1 or isInner2;
        isOuter = isOuter1 or isOuter2;
        ErrorExt.rollBack("lookupVarInnerOuterAttr");
      then
        (isInner,isOuter);
    // try to find var cr1 (lookup can fail for one of them)
    case(cache,env,ih,cr1,cr2)
      equation        
        (_,DAE.ATTR(innerOuter=io),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        (isInner,isOuter) = innerOuterBooleans(io);
        ErrorExt.rollBack("lookupVarInnerOuterAttr");
      then
        (isInner,isOuter);
     // ..else try cr2 (lookup can fail for one of them)
    case(cache,env,ih,cr1,cr2)
      equation
        (_,DAE.ATTR(innerOuter=io),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        (isInner,isOuter) = innerOuterBooleans(io);
        ErrorExt.rollBack("lookupVarInnerOuterAttr");
      then (isInner,isOuter);
     // failure
    case(cache,env,ih,cr1,cr2)
      equation        
        ErrorExt.rollBack("lookupVarInnerOuterAttr");
      then fail();
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
        (DAE.DAE(innerVars),DAE.DAE(outerVars)) = DAEUtil.findAllMatchingElements(inDae,DAEUtil.isInnerVar,DAEUtil.isOuterVar);
        checkMissingInnerDecl1(DAE.DAE(innerVars),DAE.DAE(outerVars));
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
        crs = Util.listMap(innerVars,DAEUtil.varCref);
        {} = Util.listSelect1(crs, cr, isInnerOuterMatch);
        str2 = Dump.unparseInnerouterStr(io);        
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
      Prefix.Prefix prefix, innerPrefix;
      Absyn.InnerOuter io;
      Boolean isInner;
      InstHierarchyHashTable ht;
      DAE.ComponentRef cref;
      InstInner instInner;
      OuterPrefixes outerPrefixes;
    
    // no prefix, this is an error!
    // disabled as this is used in Interactive.getComponents
    // and makes mosfiles/interactive_api_attributes.mos to fail!
    case (TOP_INSTANCE(_, ht, outerPrefixes), Prefix.PREFIX(compPre = Prefix.NOCOMPPRE()),  name)
      then lookupInnerInIH(inTIH, Prefix.NOPRE(), inComponentIdent);
    
    // no prefix, this is an error!
    // disabled as this is used in Interactive.getComponents
    // and makes mosfiles/interactive_api_attributes.mos to fail!
    case (TOP_INSTANCE(_, ht, outerPrefixes), Prefix.NOPRE(),  name)
      equation
        // Debug.fprintln("innerouter", "Error: outer component: " +& name +& " defined at the top level!");
        // Debug.fprintln("innerouter", "InnerOuter.lookupInnerInIH : looking for: " +& PrefixUtil.printPrefixStr(Prefix.NOPRE()) +& "/" +& name +& " REACHED TOP LEVEL!");
        // TODO! add warning!
      then emptyInstInner(Prefix.NOPRE(), name);
    
    // we have a prefix, remove the last cref from the prefix and search!
    case (TOP_INSTANCE(_, ht, outerPrefixes), inPrefix,  name)
      equation
        // back one step in the instance hierarchy
        
        // Debug.fprintln("innerouter", "InnerOuter.lookupInnerInIH : looking for: " +& PrefixUtil.printPrefixStr(inPrefix) +& "/" +& name);

        prefix = PrefixUtil.prefixStripLast(inPrefix);

        // Debug.fprintln("innerouter", "InnerOuter.lookupInnerInIH : stripping and looking for: " +& PrefixUtil.printPrefixStr(prefix) +& "/" +& name);

        // put the name as the last prefix
        (_,cref) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,prefix, DAE.CREF_IDENT(name, DAE.ET_OTHER(), {}));

        // search in instance hierarchy
        instInner = get(cref, ht);

        // isInner = Absyn.isInner(io);
        // instInner = Util.if_(isInner, instInner, emptyInstInner(inPrefix, name));
        // Debug.fprintln("innerouter", "InnerOuter.lookupInnerInIH : Looking up: " +&  
        //  Exp.printComponentRefStr(cref) +& " FOUND with innerPrefix: " +&
        //  PrefixUtil.printPrefixStr(innerPrefix));
      then
        instInner;

    // we have a prefix, search recursively as there was a failure before!
    case (TOP_INSTANCE(_, ht, outerPrefixes), inPrefix,  name)
      equation
        // back one step in the instance hierarchy
        // Debug.fprintln("innerouter", "InnerOuter.lookupInnerInIH : looking for: " +& PrefixUtil.printPrefixStr(inPrefix) +& "/" +& name);
        
        prefix = PrefixUtil.prefixStripLast(inPrefix);
        
        // Debug.fprintln("innerouter", "InnerOuter.lookupInnerInIH : stripping and looking for: " +& PrefixUtil.printPrefixStr(prefix) +& "/" +& name);
        
        // put the name as the last prefix
        (_,cref) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,prefix, DAE.CREF_IDENT(name, DAE.ET_OTHER(), {}));
        
        // search in instance hierarchy we had a failure
        failure(instInner = get(cref, ht));
        
        // Debug.fprintln("innerouter", "InnerOuter.lookupInnerInIH : Couldn't find: " +& Exp.printComponentRefStr(cref) +& " going deeper");
        
        // call recursively to back one more step!
        instInner = lookupInnerInIH(inTIH, prefix, name);
      then
        instInner;
    
    // if we fail return nothing
    case (inTIH as TOP_INSTANCE(_, ht, outerPrefixes), prefix, name)
      equation
        // Debug.fprintln("innerouter", "InnerOuter.lookupInnerInIH : looking for: " +& PrefixUtil.printPrefixStr(prefix) +& "/" +& name +& " NOT FOUND!");
        // dumpInstHierarchyHashTable(ht);
      then 
        emptyInstInner(prefix, name);
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
        (_,cr) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,pre, cr);
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
    case ((DAE.COMP(ident = idName,dAElist = lst,source = source,comment = comment) :: r),io,pre)
      equation
        lst_1 = switchInnerToOuterAndPrefix(lst, io, pre);
        r_1 = switchInnerToOuterAndPrefix(r, io, pre);
      then
        (DAE.COMP(idName,lst_1,source,comment) :: r_1);

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
        (_,cr) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,crefPrefix, cr);
        r_1 = prefixOuterDaeVars(r, crefPrefix);
      then
        (DAE.VAR(cr,vk,dir,prot,t,e,id,flowPrefix,streamPrefix,source,dae_var_attr,comment,io) :: r_1);

		// Traverse components
    case ((DAE.COMP(ident = idName,dAElist = lst,source = source,comment = comment) :: r),crefPrefix)
      equation
        lst_1 = prefixOuterDaeVars(lst, crefPrefix);
        r_1 = prefixOuterDaeVars(r, crefPrefix);
      then
        (DAE.COMP(idName,lst_1,source,comment) :: r_1);

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
      Option<Env.ScopeType> st;
      AvlTree clsAndVars "List of uniquely named classes and variables" ;
      AvlTree types "List of types, which DOES NOT need to be uniquely named, eg. size may have several types" ;
      list<Item> imports "list of unnamed items (imports)" ;
      CSetsType connectionSet "current connection set crefs" ;
      Boolean isEncapsulated "encapsulated bool=true means that FRAME is created due to encapsulated class" ;
      list<SCode.Element> defineUnits "list of units defined in the frame" ;

    case (f as Env.FRAME(optName, st, clsAndVars, types, imports, connectionSet, isEncapsulated, defineUnits), cr)
      equation
        SOME(clsAndVars) = switchInnerToOuterInAvlTree(SOME(clsAndVars), cr);
      then
        Env.FRAME(optName, st, clsAndVars, types, imports, connectionSet, isEncapsulated, defineUnits);

    case (f as Env.FRAME(optName, st, clsAndVars, types, imports, connectionSet, isEncapsulated, defineUnits), cr)
      equation
        // when above fails leave unchanged
      then
        Env.FRAME(optName, st, clsAndVars, types, imports, connectionSet, isEncapsulated, defineUnits);

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
      Option<DAE.Const> cnstForRange;
    
    // inner
    case (Env.VAR(DAE.TYPES_VAR(name, attributes, protected_, type_, binding, cnstForRange), declaration, instStatus, env), cr)
      equation
        DAE.ATTR(flowPrefix, streamPrefix, accessibility, parameter_, direction, Absyn.INNER()) = attributes;
        attributes = DAE.ATTR(flowPrefix, streamPrefix, accessibility, parameter_, direction, Absyn.OUTER());
        // env = switchInnerToOuterInEnv(env, inCr);
      then Env.VAR(DAE.TYPES_VAR(name, attributes, protected_, type_, binding, cnstForRange), declaration, instStatus, env);
    
    // inner outer
    case (Env.VAR(DAE.TYPES_VAR(name, attributes, protected_, type_, binding, cnstForRange), declaration, instStatus, env), cr)
      equation
        DAE.ATTR(flowPrefix, streamPrefix, accessibility, parameter_, direction, Absyn.INNEROUTER()) = attributes;
        attributes = DAE.ATTR(flowPrefix, streamPrefix, accessibility, parameter_, direction, Absyn.OUTER());
        // env = switchInnerToOuterInEnv(env, inCr);
      then Env.VAR(DAE.TYPES_VAR(name, attributes, protected_, type_, binding, cnstForRange), declaration, instStatus, env);

    // leave unchanged
    case (inItem, _) then inItem;
  end matchcontinue;
end switchInnerToOuterInAvlTreeValue;


///////////////////////////////////////////////////
/// instance hieararchy for inner/outer
/// add furher functions before this
///////////////////////////////////////////////////


public function emptyInstInner
  input Prefix innerPrefix;
  input String name;
  output InstInner outInstInner;
algorithm
  outInstInner := INST_INNER(innerPrefix, name, Absyn.UNSPECIFIED(), "", Absyn.IDENT(""), "", NONE(), {});
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
        //true = Absyn.isOuter(io);  // is outer
        //false = Absyn.isInner(io); // and is not inner
        // search the instance hierarchy for the inner component
        instInner = lookupInnerInIH(tih, pre, n);
      then
        instInner;

    // failure in case we look for anything else but outer!
    case (cache,env,_,pre,n,io)
      equation
        Debug.fprintln("failtrace", "InnerOuter.lookupInnerVar failed on component: " +& PrefixUtil.printPrefixStr(pre) +& "/" +& n);
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
      OuterPrefixes outerPrefixes;
    
    /* only add inner elements
    case(ih,inPrefix,inInnerOuter,inInstInner as INST_INNER(name=name))
      equation
        false = Absyn.isInner(inInnerOuter);
        // prefix the name!
        (_,cref) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,inPrefix, DAE.CREF_IDENT(name, DAE.ET_OTHER(), {}));
        // print ("InnerOuter.updateInstHierarchy jumping over non-inner: " +& Exp.printComponentRefStr(cref) +& "\n");
      then
        ih;*/
    
    // no hashtable, create one!
    case({},inPrefix,inInnerOuter,inInstInner as INST_INNER(name=name))
      equation
        // print ("InnerOuter.updateInstHierarchy creating an empty hash table! \n");
        ht = emptyInstHierarchyHashTable();
        tih = TOP_INSTANCE(NONE(), ht, emptyOuterPrefixes);
        ih = updateInstHierarchy({tih}, inPrefix, inInnerOuter, inInstInner);
      then
        ih;
    
    // add to the hierarchy
    case((tih as TOP_INSTANCE(pathOpt, ht, outerPrefixes))::restIH,inPrefix,inInnerOuter,
         inInstInner as INST_INNER(name=name, io=io))
      equation
        // prefix the name!
        (_,cref) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,inPrefix, DAE.CREF_IDENT(name, DAE.ET_OTHER(), {}));
        // add to hashtable!
        // Debug.fprintln("innerouter", "InnerOuter.updateInstHierarchy adding: " +& 
        //   PrefixUtil.printPrefixStr(inPrefix) +& "/" +& name +& " to IH");
        ht = add((cref,inInstInner), ht);
      then
        TOP_INSTANCE(pathOpt, ht, outerPrefixes)::restIH;
    
    // failure
    case(ih,inPrefix,inInnerOuter,inInstInner as INST_INNER(name=name, io=io))
      equation
        // prefix the name!
        //(_,cref) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,inPrefix, DAE.CREF_IDENT("UNKNOWN", DAE.ET_OTHER(), {}));
        // Debug.fprintln("innerouter", "InnerOuter.updateInstHierarchy failure for: " +& 
        //   PrefixUtil.printPrefixStr(inPrefix) +& "/" +& name);
      then
        fail();
  end matchcontinue;
end updateInstHierarchy;

public function addOuterPrefixToIH
"@author: adrpo
 This function remembers the outer prefix with the correct prefix of the inner"
  input InstHierarchy inIH;
  input DAE.ComponentRef inOuterComponentRef;
  input DAE.ComponentRef inInnerComponentRef;
  output InstHierarchy outIH;
algorithm
  outIH := matchcontinue(inIH, inOuterComponentRef, inInnerComponentRef)
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
      OuterPrefixes outerPrefixes;

    // no hashtable, create one!
    case({}, inOuterComponentRef, inInnerComponentRef)
      equation
        // create an empty table and add the crefs to it.
        ht = emptyInstHierarchyHashTable();
        tih = TOP_INSTANCE(NONE(), ht, {OUTER(inOuterComponentRef, inInnerComponentRef)});
        ih = {tih};
      then
        ih;

    // add to the top instance
    case((tih as TOP_INSTANCE(pathOpt, ht, outerPrefixes))::restIH, inOuterComponentRef, inInnerComponentRef)
      equation
        // Debug.fprintln("innerouter", "InnerOuter.addOuterPrefix adding: outer cref: " +& 
        //   Exp.printComponentRefStr(inOuterComponentRef) +& " refers to inner cref: " +& 
        //   Exp.printComponentRefStr(inInnerComponentRef) +& " to IH");
        outerPrefixes = Util.listUnionElt(OUTER(inOuterComponentRef,inInnerComponentRef), outerPrefixes); 
      then
        TOP_INSTANCE(pathOpt, ht, outerPrefixes)::restIH;

    // failure
    case(ih,inOuterComponentRef, inInnerComponentRef)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.traceln("InnerOuter.addOuterPrefix failed to add: outer cref: " +& 
          Exp.printComponentRefStr(inOuterComponentRef) +& " refers to inner cref: " +& 
          Exp.printComponentRefStr(inInnerComponentRef) +& " to IH");        
      then
        fail();
  end matchcontinue;
end addOuterPrefixToIH;

public function prefixOuterCrefWithTheInnerPrefix
"@author: adrpo
  This function searches for outer crefs and prefixes them with the inner prefix"
  input InstHierarchy inIH;
  input DAE.ComponentRef inOuterComponentRef;
  input Prefix inPrefix;
  output DAE.ComponentRef outInnerComponentRef;
algorithm
  outInnerComponentRef := matchcontinue(inIH, inOuterComponentRef, inPrefix)
    local
      DAE.ComponentRef outerCrefPrefix, fullCref, innerCref, innerCrefPrefix;
      OuterPrefixes outerPrefixes;
      
    // we have no outer references, fail so prefixing can happen in the calling function 
    case ({}, inOuterComponentRef, inPrefix) 
      then 
        fail();
    
    // we have some outer references, search for our prefix + cref in them 
    case ({TOP_INSTANCE(_, _, outerPrefixes)}, inOuterComponentRef, inPrefix)
      equation
        (_,fullCref) = PrefixUtil.prefixCref(Env.emptyCache(),{},emptyInstHierarchy,inPrefix, inOuterComponentRef);

        // this will fail if we don't find it so prefixing can happen in the calling function
        (outerCrefPrefix, innerCrefPrefix) = searchForInnerPrefix(fullCref, outerPrefixes);

        innerCref = changeOuterReferenceToInnerReference(fullCref, outerCrefPrefix, innerCrefPrefix);

        // Debug.fprintln("innerouter", "- InnerOuter.prefixOuterCrefWithTheInnerPrefix replaced cref " +& 
        //  Exp.printComponentRefStr(fullCref) +& " with cref: " +& 
        //  Exp.printComponentRefStr(innerCref));        
      then 
        innerCref;
    
    // failure 
    case (_, inOuterComponentRef, inPrefix)
      equation
        // true = RTOpts.debugFlag("failtrace");
        // Debug.traceln("- InnerOuter.prefixOuterCrefWithTheInnerPrefix failed to find prefix of inner for outer: prefix/cref " +& 
        //   PrefixUtil.printPrefixStr(inPrefix) +& "/" +& Exp.printComponentRefStr(inOuterComponentRef));
      then
        fail();        
  end matchcontinue;
end prefixOuterCrefWithTheInnerPrefix;

protected function changeOuterReferenceToInnerReference
"@author: adrpo
  This function replaces the outer prefix with the inner prefix in the full cref"
  input DAE.ComponentRef inFullCref;
  input DAE.ComponentRef inOuterCrefPrefix;
  input DAE.ComponentRef inInnerCrefPrefix;
  output DAE.ComponentRef outInnerCref;
algorithm
  outInnerCref := matchcontinue(inFullCref, inOuterCrefPrefix, inInnerCrefPrefix)
    local
      DAE.ComponentRef ifull, ocp, icp, ic;
    
    // handle the case where full cref is larger than outer prefix 
    case (ifull, ocp, icp)
      equation
        // strip the outer prefix
        ic = Exp.crefStripPrefix(ifull, ocp);
        // add the inner prefix
        ic = Exp.joinCrefs(icp, ic);
      then
        ic;
    
    // handle the case where full cref is equal to outer prefix 
    case (ifull, ocp, icp)
      equation
        // test cref equality
        true = Exp.crefEqualNoStringCompare(ifull, ocp);
        // the inner cref is the inner prefix!
        ic = icp;  
      then
        ic;
  end matchcontinue;
end changeOuterReferenceToInnerReference;

protected function searchForInnerPrefix
"@author: adrpo
  search in the outer prefixes and retrieve the outer/inner crefs"
  input DAE.ComponentRef fullCref;  
  input OuterPrefixes outerPrefixes;
  output DAE.ComponentRef outerCrefPrefix;
  output DAE.ComponentRef innerCrefPrefix;
algorithm
  (outerCrefPrefix, innerCrefPrefix) := matchcontinue(fullCref, outerPrefixes)
    local
      DAE.ComponentRef crOuter, crInner;
      OuterPrefixes rest;

    // we haven't found it, fail!
    case (_, {}) 
      then 
        fail();
    
    // handle the head that matches 
    case (fullCref, OUTER(crOuter, crInner)::rest)
      equation
         true = Exp.crefPrefixOf(crOuter, fullCref);
      then 
        (crOuter, crInner);

    // handle the rest 
    case (fullCref, _::rest)
      equation
         (crOuter, crInner) = searchForInnerPrefix(fullCref, rest);
      then 
        (crOuter, crInner);
  end matchcontinue; 
end searchForInnerPrefix;

public function printInnerDefStr
  input InstInner inInstInner;
  output String outStr;
algorithm
  outStr := matchcontinue(inInstInner)
    local 
      Prefix innerPrefix;
      SCode.Ident name;
      Absyn.InnerOuter io;
      Option<InstResult> instResult;
      String fullName "full inner component name";
      Absyn.Path typePath "the type of the inner";
      String scope "the scope of the inner";      
      list<DAE.ComponentRef> outers "which outers are referencing this inner";
      DAE.ComponentRef cref;
      String str, strOuters;

    case(INST_INNER(innerPrefix, name, io, fullName, typePath, scope, instResult, outers))
      equation
        strOuters = Util.if_(listLength(outers) == 0, 
                      "", 
                      " Referenced by 'outer' components: {" +&
                      Util.stringDelimitList(Util.listMap(outers, Exp.printComponentRefStr), ", ") +& "}");
        str = Absyn.pathString(typePath) +& " " +& fullName +& "; defined in scope: " +& scope +& "." +& strOuters;   
      then 
        str;
  end matchcontinue;
end printInnerDefStr;

public function getExistingInnerDeclarations
"@author: adrpo
 This function retrieves all the existing inner declarations as a string"
  input InstHierarchy inIH;
  input Env.Env inEnv;
  output String innerDeclarations;
algorithm
  innerDeclarations := matchcontinue(inIH, inEnv)
    local
      TopInstance tih;
      InstHierarchy restIH, ih;
      InstHierarchyHashTable ht;
      Option<Absyn.Path> pathOpt;
      OuterPrefixes outerPrefixes;
      list<InstInner> inners;
      String str;
      
    // we have no inner components yet
    case ({}, inEnv) 
      then 
        "There are no 'inner' components defined in the model in the any of the parent scopes of 'outer' component's scope: " +& Env.printEnvPathStr(inEnv) +& "." ;
    
    // get the list of components
    case((tih as TOP_INSTANCE(pathOpt, ht, outerPrefixes))::restIH, inEnv)
      equation
        inners = getInnersFromInstHierarchyHashTable(ht);
        str = Util.stringDelimitList(Util.listMap(inners, printInnerDefStr), "\n    ");
      then
        str;
  end matchcontinue;
end getExistingInnerDeclarations;

public function getInnersFromInstHierarchyHashTable 
"@author: adrpo
  Returns all the inners defined in the hashtable."
  input InstHierarchyHashTable t;
  output list<InstInner> inners;
algorithm
  inners := Util.listMap(hashTableList(t),getValue);
end getInnersFromInstHierarchyHashTable;

public function getValue
  input tuple<Key,Value> tpl;
  output InstInner v;
algorithm
  v := matchcontinue(tpl)
    local
      Key k; Value v;
    case((k,v)) then v;
  end matchcontinue;
end getValue;

/////////////////////////////////////////////////////////////////
// hash table implementation for InnerOuter instance hierarchy //
/////////////////////////////////////////////////////////////////

public function hashFunc
"author: PA
  Calculates a hash value for DAE.ComponentRef"
  input Key k;
  output Integer res;
algorithm
  res := System.hash(Exp.printComponentRefStr(k));
end hashFunc;

public function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
     res := Exp.crefEqualNoStringCompare(key1,key2);
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
        // print("Added NEW to IH: key:" +& Exp.printComponentRefStr(key) +& " value: " +& printInnerDefStr(value) +& "\n"); 
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);

      /* adding when already present => Updating value */
    case ((newv as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
        // print("Updated NEW to IH: key:" +& Exp.printComponentRefStr(key) +& " value: " +& printInnerDefStr(value) +& "\n");        
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,_)
      equation
        print("- InnerOuter.add failed\n");
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
        print("- InnerOuter.addNoUpdCheck failed\n");
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
  (value, indx) := matchcontinue (key,hashTable)
    local
      Integer hval,hashindx,indx,indx_1,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;
      list<tuple<Key,Integer>>[:] hashvec;
      ValueArray varr;
      Key k;
    
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        (k, v) = valueArrayNth(varr, indx);
        true = keyEqual(k, key);
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
        rexpandsize = rsize *. 0.4;
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
  output Key key;
  output Value value;
algorithm
  (key, value) := matchcontinue (valueArray,pos)
    local
      Key k;
      Value v;
      Integer n,pos,len;
      Option<tuple<Key,Value>>[:] arr;
      String ps,lens,ns;
    
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation
        (pos < n) = true;
        SOME((k,v)) = arr[pos + 1];
      then
        (k, v);
    
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation
        (pos < n) = true;
        NONE = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;

end InnerOuter;

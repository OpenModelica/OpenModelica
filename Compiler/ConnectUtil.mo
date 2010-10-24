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

package ConnectUtil
" file:	 ConnectUtil.mo
  package:      ConnectUtil
  description: Connection set management

  RCS: $Id: ConnectUtil.mo 4762 2010-01-11 03:41:52Z adrpo $

  Connections generate connection sets (datatype SET is described in Connect)
  which are constructed during instantiation.  When a connection
  set is generated, it is used to create a number of equations.
  The kind of equations created depends on the type of the set.

  ConnectUtil.mo is called from Inst.mo and is responsible for
  creation of all connect-equations later passed to the DAE module
  in DAEUtil.mo."

public import Absyn;
public import ComponentReference;
public import Connect;
public import DAE;
public import Env;
public import InnerOuter;
public import Prefix;
public import ClassInf;
public import ConnectionGraph;

protected import Exp;
protected import DAEUtil;
protected import Static;
protected import Lookup;
protected import Print;
protected import Util;
protected import Types;
protected import Debug;
protected import Error;
protected import Dump;
protected import PrefixUtil;
protected import RTOpts;
protected import System;

public
type Env     = Env.Env;
type AvlTree = Env.AvlTree;
type Cache   = Env.Cache;

public function addDeletedComponent
  "Adds a conditional component with condition = false to the connection sets,
  so that we can avoid adding connections to those components."
  input DAE.ComponentRef component;
  input Connect.Sets inSets;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(component, inSets)
    local
      list<Connect.Set> setLst;
      list<DAE.ComponentRef> crs, deletedComps;
      list<Connect.OuterConnect> outerConn;
    case (_, Connect.SETS(setLst, crs, deletedComps, outerConn))
      then Connect.SETS(setLst, crs, component :: deletedComps, outerConn);
  end matchcontinue;
end addDeletedComponent;

protected function isDeletedComponent
  "Checks if a component is a conditional component with condition = false."
  input DAE.ComponentRef component;
  input list<DAE.ComponentRef> deletedComponents;
  output Boolean isDeleted;
algorithm
  isDeleted := matchcontinue(component, deletedComponents)
    local
      DAE.ComponentRef c;
      list<DAE.ComponentRef> rest;
      Boolean is_deleted;
    case (_, {}) then false;
    case (_, c :: _)
      equation
        true = Exp.crefPrefixOf(c, component);
      then
        true;
    case (_, _ :: rest)
      equation
        is_deleted = isDeletedComponent(component, rest);
      then
        is_deleted;
  end matchcontinue;
end isDeletedComponent;

public function connectionContainsDeletedComponents
  "Checks if a connection contains any conditional components with condition =
  false."
  input DAE.ComponentRef component1;
  input DAE.ComponentRef component2;
  input Connect.Sets sets;
  output Boolean containsDeletedComponent;
algorithm
  containsDeletedComponent := matchcontinue(component1, component2, sets)
    local
      list<DAE.ComponentRef> dc;
    // No components have been deleted.
    case (_, _, Connect.SETS(deletedComponents = {})) then false;
    // The first component is deleted.
    case (_, _, Connect.SETS(deletedComponents = dc))
      equation
        true = isDeletedComponent(component1, dc);
      then
        true;
    // The second component is deleted;
    case (_, _, Connect.SETS(deletedComponents = dc))
      equation
        true = isDeletedComponent(component2, dc);
      then
        true;
    // Neither of the components are deleted.
    case (_, _, _) then false;
  end matchcontinue;
end connectionContainsDeletedComponents;
    
public function addOuterConnection " Adds a connection with a reference to an outer connector
These are added to a special list, such that they can be moved up in the instance hierarchy to a place
where both instances are defined."
  input Prefix.Prefix scope;
  input Connect.Sets sets;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Connect.Face f1;
  input Connect.Face f2;
  input DAE.ElementSource source;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(scope,sets,cr1,cr2,io1,io2,f1,f2,source)
    local
      list<Connect.Set> ss;
      list<DAE.ComponentRef> crs,dc;
      list<Connect.OuterConnect> oc;
    // First check if already added
    case(scope,sets as Connect.SETS(ss,crs,dc,oc),cr1,cr2,io1,io2,f1,f2,_)
      equation
        _::_ = Util.listSelect2(oc,cr1,cr2,outerConnectionMatches);
      then sets;
    // add the outerconnect
    case(scope,Connect.SETS(ss,crs,dc,oc),cr1,cr2,io1,io2,f1,f2,source)
      then Connect.SETS(ss,crs,dc,Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)::oc);
  end matchcontinue;
end addOuterConnection;

protected function outerConnectionMatches "Returns true if Connect.OuterConnect matches the two component refernces passed as argument"
  input Connect.OuterConnect oc;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean matches;
algorithm
  matches := matchcontinue(oc,cr1,cr2)
    local DAE.ComponentRef cr11,cr22;
    case(Connect.OUTERCONNECT(cr1=cr11,cr2=cr22),cr1,cr2) 
      equation
        matches =
        Exp.crefEqual(cr11,cr1) and Exp.crefEqual(cr22,cr2) or
        Exp.crefEqual(cr11,cr2) and Exp.crefEqual(cr22,cr1);
      then matches;
  end matchcontinue;
end outerConnectionMatches;

public function addOuterConnectToSets "adds an outerconnection to all sets where a corresponding inner definition is present
For instance,
if a connection set contains {world.v, topPin.v}
and we have an outer connection connect(world,a2.aPin),
the connection should be added to the set, resulting in
{world.v,topPin.v,a2.aPin.v}"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Connect.Face f1;
  input Connect.Face f2;
  input list<Connect.Set> setLst;
  input list<DAE.ComponentRef> inCrs;
  output list<Connect.Set> outSetLst;
  output list<DAE.ComponentRef> outCrs;
  output Boolean added "true if addition was made";
algorithm
  (outSetLst,outCrs,added) := matchcontinue(cr1,cr2,io1,io2,f1,f2,setLst,inCrs)
  local
    list<tuple<DAE.ComponentRef,DAE.ElementSource>> crs;
    list<tuple<DAE.ComponentRef,Connect.Face,DAE.ElementSource>> fcrs;
    list<tuple<DAE.ComponentRef,Option<DAE.ComponentRef>,Connect.Face,DAE.ElementSource>> scrs;
    Connect.Set set; Boolean added2;

    case(cr1,cr2,io1,io2,f1,f2,{},inCrs) then ({},inCrs,false);

    case(cr1,cr2,io1,io2,f1,f2,Connect.EQU(crs)::setLst,inCrs) equation
      (crs,inCrs,added) = addOuterConnectToSets2(cr1,cr2,io1,io2,crs,inCrs);
      (setLst,inCrs,added2) = addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,inCrs);
    then (Connect.EQU(crs)::setLst,inCrs,added or added2);

    case(cr1,cr2,io1,io2,f1,f2,Connect.FLOW(fcrs as _ :: _ :: _)::setLst,inCrs) equation
      (fcrs,inCrs,setLst,added) = addOuterConnectToSets3(cr1,cr2,f1,f2,io1,io2,fcrs,inCrs,setLst);
      (setLst,inCrs,added2) = addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,inCrs);
    then (Connect.FLOW(fcrs)::setLst,inCrs,added or added2);

    case(cr1,cr2,io1,io2,f1,f2,Connect.STREAM(scrs)::setLst,inCrs) equation
      (scrs,inCrs,added) = addOuterConnectToSets4(cr1,cr2,f1,f2,io1,io2,scrs,inCrs);
      (setLst,inCrs,added2) = addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,inCrs);
    then (Connect.STREAM(scrs)::setLst,inCrs,added or added2);

    case(cr1,cr2,io1,io2,f1,f2,set::setLst,inCrs) equation
      (setLst,inCrs,added) = addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,inCrs);
    then (set::setLst,inCrs,added);
  end matchcontinue;
end addOuterConnectToSets;

protected function addOuterConnectToSets2 "help function to addOuterconnectToSets"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input list<Connect.EquSetElement> crs;
  input list<DAE.ComponentRef> inCrs "from connection crefs (outer scopes)";
  output list<Connect.EquSetElement> outCrs;
  output list<DAE.ComponentRef> outCrs2 "from connection crefs (outer scopes)";
  output Boolean added;
protected
  Boolean isOuter1,isOuter2;
algorithm
  (_,isOuter1) := InnerOuter.innerOuterBooleans(io1);
  (_,isOuter2) := InnerOuter.innerOuterBooleans(io2);
  (outCrs,outCrs2,added) := addOuterConnectToSets22(cr1,cr2,isOuter1,isOuter2,crs,inCrs);
end addOuterConnectToSets2;

protected function addOuterConnectToSets22 "help function to addOuterconnectToSets2"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean isOuter1;
  input Boolean isOuter2;
  input list<Connect.EquSetElement> crs;
  input list<DAE.ComponentRef> inCrs "from connection crefs (outer scopes)";
  output list<Connect.EquSetElement> outCrs;
  output list<DAE.ComponentRef> outCrs2 "from connection crefs (outer scopes)";
  output Boolean added;
algorithm
  (outCrs,outCrs2,added) := matchcontinue(cr1,cr2,isOuter1,isOuter2,crs,inCrs)
    local
      DAE.ComponentRef outerCr,outerCr,connectorCr,newCr;
      DAE.ElementSource src;

    case(cr1,cr2,true,true,crs,inCrs)
      equation
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"Connections where both connectors are outer references","No suggestion"});
      then (crs,inCrs,false);

    case(cr1,cr2,true,false,crs,inCrs)
      equation
        (outerCr,src)::_ = Util.listSelect1(crs,cr1,crefTuplePrefixOf);
        connectorCr = Exp.crefStripPrefix(outerCr,cr1);
        newCr = Exp.joinCrefs(cr2,connectorCr);
      then ((newCr,src)::crs,inCrs,true);

    case(cr1,cr2,false,true,crs,inCrs)
      equation
        (outerCr,src)::_ = Util.listSelect1(crs,cr2,crefTuplePrefixOf);
        connectorCr = Exp.crefStripPrefix(outerCr,cr2);
        newCr = Exp.joinCrefs(cr1,connectorCr);
      then ((newCr,src)::crs,inCrs,true);

    case(cr1,cr2,_,_,crs,inCrs) then (crs,inCrs,false);
  end matchcontinue;
end addOuterConnectToSets22;

protected function addOuterConnectToSets3 "help function to addOuterconnectToSets"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Connect.Face f1;
  input Connect.Face f2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input list<Connect.FlowSetElement> crs;
  input list<DAE.ComponentRef> inCrs;
  input list<Connect.Set> inSets;
  output list<Connect.FlowSetElement> outCrs;
  output list<DAE.ComponentRef> outCrs2;
  output list<Connect.Set> outSets;
  output Boolean added;
protected
  Boolean isOuter1,isOuter2;
algorithm
  (_,isOuter1) := InnerOuter.innerOuterBooleans(io1);
  (_,isOuter2) := InnerOuter.innerOuterBooleans(io2);
  (outCrs,outCrs2,outSets,added) := addOuterConnectToSets33(cr1,cr2,isOuter1,isOuter2,f1,f2,crs,inCrs,inSets);
end addOuterConnectToSets3;

protected function addOuterConnectToSets33 "help function to addOuterconnectToSets3"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean isOuter1;
  input Boolean isOuter2;
  input Connect.Face f1;
  input Connect.Face f2;
  input list<Connect.FlowSetElement> crs;
  input list<DAE.ComponentRef> inCrs;
  input list<Connect.Set> inSets;
  output list<Connect.FlowSetElement> outCrs;
  output list<DAE.ComponentRef> outCrs2;
  output list<Connect.Set> outSets;
  output Boolean added;
algorithm
  (outCrs,outCrs2,outSets,added) := matchcontinue(cr1,cr2,isOuter1,isOuter2,f1,f2,crs,inCrs,inSets)
    local
      DAE.ComponentRef outerCr,outerCr,connectorCr,newCr;
      DAE.ElementSource src;
      list<Connect.Set> sets;

    case(cr1,cr2,true,true,f1,f2,crs,inCrs,_)
      equation
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"Connections where both connectors are outer references","No suggestion"});
      then (crs,inCrs,inSets,false);

    case(cr1,cr2,true,false,f1,f2,crs,inCrs,_)
      equation
        (outerCr,_,src)::_ = Util.listSelect1(crs,cr1,flowTuplePrefixOf);
        connectorCr = Exp.crefStripPrefix(outerCr,cr1);
        newCr = Exp.joinCrefs(cr2,connectorCr);
        sets = removeUnconnectedFlowVariable(newCr, f2, inSets);
      then ((newCr,f2,src)::crs,inCrs,sets,true);

    case(cr1,cr2,false,true,f1,f2,crs,inCrs,_)
      equation
        (outerCr,_,src)::_ = Util.listSelect1(crs,cr2,flowTuplePrefixOf);
        connectorCr = Exp.crefStripPrefix(outerCr,cr2);
        newCr = Exp.joinCrefs(cr1,connectorCr);
        sets = removeUnconnectedFlowVariable(newCr, f1, inSets);
      then ((newCr,f1,src)::crs,inCrs,sets,true);

    case(cr1,cr2,_,_,_,_,crs,inCrs,_) then (crs,inCrs,inSets,false);
  end matchcontinue;
end addOuterConnectToSets33;

protected function addOuterConnectToSets4 "help function to addOuterconnectToSets"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Connect.Face f1;
  input Connect.Face f2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input list<Connect.StreamSetElement> crs;
  input list<DAE.ComponentRef> inCrs;
  output list<Connect.StreamSetElement> outCrs;
  output list<DAE.ComponentRef> outCrs2;
  output Boolean added;
protected
  Boolean isOuter1,isOuter2;
algorithm
  (_,isOuter1) := InnerOuter.innerOuterBooleans(io1);
  (_,isOuter2) := InnerOuter.innerOuterBooleans(io2);
  (outCrs,outCrs2,added) := addOuterConnectToSets44(cr1,cr2,isOuter1,isOuter2,f1,f2,crs,inCrs);
end addOuterConnectToSets4;

protected function addOuterConnectToSets44 "help function to addOuterconnectToSets4"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean isOuter1;
  input Boolean isOuter2;
  input Connect.Face f1;
  input Connect.Face f2;
  input list<Connect.StreamSetElement> crs;
  input list<DAE.ComponentRef> inCrs;
  output list<Connect.StreamSetElement> outCrs;
  output list<DAE.ComponentRef> outCrs2;
  output Boolean added;
algorithm
  (outCrs,outCrs2,added) := matchcontinue(cr1,cr2,isOuter1,isOuter2,f1,f2,crs,inCrs)
    local
      DAE.ComponentRef outerCr,outerCr,connectorCr,newCr;
      DAE.ElementSource src;
      Option<DAE.ComponentRef> outerCrFlowOpt;

    case(cr1,cr2,true,true,f1,f2,crs,inCrs)
      equation
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"Connections where both connectors are outer references","No suggestion"});
      then (crs,inCrs,false);

    case(cr1,cr2,true,false,f1,f2,crs,inCrs)
      equation
        (outerCr,outerCrFlowOpt,_,src)::_ = Util.listSelect1(crs,cr1,streamTuplePrefixOf);
        connectorCr = Exp.crefStripPrefix(outerCr,cr1);
        newCr = Exp.joinCrefs(cr2,connectorCr);        
      then ((newCr,NONE(),f2,src)::crs,inCrs,true);

    case(cr1,cr2,false,true,f1,f2,crs,inCrs)
      equation
        (outerCr,outerCrFlowOpt,_,src)::_ = Util.listSelect1(crs,cr2,streamTuplePrefixOf);
        connectorCr = Exp.crefStripPrefix(outerCr,cr2);
        newCr = Exp.joinCrefs(cr1,connectorCr);
      then ((newCr,NONE(),f1,src)::crs,inCrs,true);

    case(cr1,cr2,_,_,_,_,crs,inCrs) then (crs,inCrs,false);
  end matchcontinue;
end addOuterConnectToSets44;

public function addEqu "function: addEqu
  Adds an equal equation, see explaining text above.
  - Adding
  The two functions addEq and addFlow addes a variable to a
  connection set.  The first function is used to add a non-flow
  variable, and the second is used to add a flow variable.  When
  two component are to be added to a collection of connection sets,
  the connections sets containg the components have to be located.
  If no such set exists, a new set containing only the new component
  is created.

  If the connection sets containing the two components are not the
  same, they are merged."
  input Connect.Sets ss;
  input DAE.ComponentRef r1;
  input DAE.ComponentRef r2;
  input DAE.ElementSource source "the origin of the element";
  output Connect.Sets ss_1;
  Connect.Set s1,s2;
  Connect.Sets ss_1;
algorithm
  s1 := findEquSet(ss, r1, source);
  s2 := findEquSet(ss, r2, source);
  
  ss_1 := merge(ss, s1, s2);
end addEqu;

public function addFlow "function: addFlow
  Adds an flow equation, see addEqu above."
  input Connect.Sets ss;
  input DAE.ComponentRef r1;
  input Connect.Face d1;
  input DAE.ComponentRef r2;
  input Connect.Face d2;
  input DAE.ElementSource source "the element origin";
  output Connect.Sets ss_1;
  Connect.Set s1,s2;
  Connect.Sets ss_1;
algorithm
  s1 := findFlowSet(ss, r1, d1, source);
  s2 := findFlowSet(ss, r2, d2, source);
  ss_1 := merge(ss, s1, s2);
end addFlow;

public function addArrayFlow "function: addArrayFlow
 For connecting two arrays, a flow equation for each index should be generated, see addFlow."
  input Connect.Sets ss;
  input DAE.ComponentRef r1;
  input Connect.Face d1;
  input DAE.ComponentRef r2;
  input Connect.Face d2;
  input Integer dsize;
  input DAE.ElementSource source "the element origin";
  output Connect.Sets outSets;
  Connect.Set s1,s2;
  Connect.Sets ss_1;
algorithm
  outSets := matchcontinue (ss,r1,d1,r2,d2,dsize,source)
    local
      Connect.Sets s,ss_1,ss_2,ss;
      DAE.ComponentRef r1_1,r2_1,r1,r2;
      Integer i_1,i;
      Connect.Set s1,s2;

    case (s,_,_,_,_,0,source) then s;
    case (ss,r1,d1,r2,d2,i,source)
      equation
        r1_1 = Exp.subscriptCref(r1, {DAE.INDEX(DAE.ICONST(i))});
        r2_1 = Exp.subscriptCref(r2, {DAE.INDEX(DAE.ICONST(i))});
        i_1 = i - 1;
        s1 = findFlowSet(ss, r1_1, d1, source);
        s2 = findFlowSet(ss, r2_1, d2, source);
        ss_1 = merge(ss, s1, s2);
        ss_2 = addArrayFlow(ss_1, r1, d1, r2, d2, i_1, source);
      then
        ss_2;
  end matchcontinue;
end addArrayFlow;

public function addFlowVariable
  "Adds a single flow variable to the connection sets."
  input Connect.Sets inCS;
  input DAE.ComponentRef inCref;
  input Connect.Face inFace;
  input DAE.ElementSource inSource;
  output Connect.Sets outCS;
algorithm
  outCS := matchcontinue(inCS, inCref, inFace, inSource)
    // If the variable has already been added, do nothing.
    case (Connect.SETS(setLst = sl as _ :: _), _, _, _)
      local
        list<Connect.Set> sl;
      equation
        failure(_ = Util.listMap2(sl, checkSet, inCref, inFace));
      then
        inCS;

    // Otherwise, create a new flow set and add it to the sets.
    case (Connect.SETS(setLst = sl, connection = c, deletedComponents = d,
        outerConnects = o), _, _, _)
      local
        list<Connect.Set> sl;
        list<DAE.ComponentRef> c, d;
        list<Connect.OuterConnect> o;
        Connect.Set flow_set;
      equation
        flow_set = newFlowSet(inCref, inFace, inSource);
      then
        Connect.SETS(flow_set :: sl, c, d, o);
  end matchcontinue;
end addFlowVariable;

public function checkSet
  "Checks that a given component is not a member of the given set. If the
  component is in the set it fails."
  input Connect.Set inSet;
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
  output Connect.Set outSet;
algorithm
  outSet := matchcontinue(inSet, inComponentRef, inFace)
    case (Connect.FLOW(tplExpComponentRefFaceLst = cs), _, _)
      local list<Connect.FlowSetElement> cs;
      equation
        failure(findInSetFlow(cs, inComponentRef, inFace));
      then
        inSet;
    case (Connect.EQU(expComponentRefLst = _), _, _) then inSet;
    case (Connect.STREAM(tplExpComponentRefFaceLst = _), _, _) then inSet;
  end matchcontinue;
end checkSet;

public function addStream "function: addStream
  Adds an flow equation, see addEqu above."
  input Connect.Sets ss;
  input DAE.ComponentRef r1;
  input Connect.Face d1;
  input DAE.ComponentRef r2;
  input Connect.Face d2;
  input DAE.ElementSource source "the element origin";
  output Connect.Sets ss_1;
  Connect.Set s1,s2;
  Connect.Sets ss_1;
algorithm
  s1 := findStreamSet(ss, r1, d1, source);
  s2 := findStreamSet(ss, r2, d2, source);
  ss_1 := merge(ss, s1, s2);
end addStream;

public function addArrayStream "function: addArrayStream
 For connecting two arrays, a flow equation for each index should be generated, see addStream."
  input Connect.Sets ss;
  input DAE.ComponentRef r1;
  input Connect.Face d1;
  input DAE.ComponentRef r2;
  input Connect.Face d2;
  input Integer dsize;
  input DAE.ElementSource source "the element origin";
  output Connect.Sets outSets;
  Connect.Set s1,s2;
  Connect.Sets ss_1;
algorithm
  outSets := matchcontinue (ss,r1,d1,r2,d2,dsize,source)
    local
      Connect.Sets s,ss_1,ss_2,ss;
      DAE.ComponentRef r1_1,r2_1,r1,r2;
      Integer i_1,i;
      Connect.Set s1,s2;

    case (s,_,_,_,_,0,source) then s;
    case (ss,r1,d1,r2,d2,i,source)
      equation
        r1_1 = Exp.subscriptCref(r1, {DAE.INDEX(DAE.ICONST(i))});
        r2_1 = Exp.subscriptCref(r2, {DAE.INDEX(DAE.ICONST(i))});
        i_1 = i - 1;
        s1 = findStreamSet(ss, r1_1, d1, source);
        s2 = findStreamSet(ss, r2_1, d2, source);
        ss_1 = merge(ss, s1, s2);
        ss_2 = addArrayStream(ss_1, r1, d1, r2, d2, i_1, source);
      then
        ss_2;
  end matchcontinue;
end addArrayStream;

public function addMultiArrayEqu "function: addMultiArrayEqu
 Author: BZ 2008-07
  For connecting two arrays, an equal equation for each index should
  be generated. generic dimensionality"
  input Connect.Sets inSets1;
  input DAE.ComponentRef inComponentRef2;
  input DAE.ComponentRef inComponentRef3;
  input list<DAE.Dimension> dimensions;
  input DAE.ElementSource source "the origins of the element";
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue (inSets1,inComponentRef2,inComponentRef3,dimensions,source)
    local
      list<list<DAE.Exp>> expSubs;
      list<list<DAE.Subscript>> subSubs;
      Integer dimension;
    case (inSets1,_,_,{},source) then inSets1;
    case (inSets1,inComponentRef2,inComponentRef3,dimensions,source)
      equation
        expSubs = generateSubscriptList(dimensions);
        subSubs = Util.listListMap(expSubs,Exp.makeIndexSubscript);
        outSets = addMultiArrayEqu2(inSets1,inComponentRef2,inComponentRef3,subSubs,source);
      then
       outSets;
  end matchcontinue;
end addMultiArrayEqu;

protected function addMultiArrayEqu2 "
Author: BZ, 2008-07
Generates Subscripts, from the input list<list, for the componentreferences given."
  input Connect.Sets inSets1;
  input DAE.ComponentRef inComponentRef2;
  input DAE.ComponentRef inComponentRef3;
  input list<list<DAE.Subscript>> dimensions;
  input DAE.ElementSource source "the origins of the element";
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(inSets1,inComponentRef2,inComponentRef3,dimensions,source)
    local
      Connect.Sets s,ss_1,ss_2,ss;
      DAE.ComponentRef r1_1,r2_1,r1,r2;
      Connect.Set s1,s2;
      list<list<DAE.Subscript>> restDims;
      list<DAE.Subscript> dims;
      Integer dimension;
    case (s,_,_,{},_) then s;
    case (ss,r1,r2,dims::restDims,source)
      equation
        r1_1 = Exp.replaceCrefSliceSub(r1,dims);
        r2_1 = Exp.replaceCrefSliceSub(r2,dims);
        s1 = findEquSet(ss, r1_1, source);
        s2 = findEquSet(ss, r2_1, source);
        ss_1 = merge(ss, s1, s2);
        ss_2 = addMultiArrayEqu2(ss_1, r1, r2, restDims, source);
      then
        ss_2;
  end matchcontinue;
end addMultiArrayEqu2;

protected function generateSubscriptList "
Author BZ 2008-07
Generates all subscripts for the dimension/(s)"
  input list<DAE.Dimension> dims;
  output list<list<DAE.Exp>> subs;
algorithm subs := matchcontinue(dims)
  local
    DAE.Dimension dim;
    list<DAE.Dimension> rest;
    list<list<DAE.Exp>> nextLevel,result,currLevel;
  case(dim::{})
    equation
      currLevel = generateSubscriptList2(dim);
      currLevel = listReverse(currLevel);
    then currLevel;
  case(dim::rest)
    equation
      currLevel = generateSubscriptList2(dim);
      currLevel = listReverse(currLevel);
      nextLevel = generateSubscriptList(rest);
      result = mergeCurrentWithRestIndexies(nextLevel,currLevel);
    then result;
end matchcontinue;
end generateSubscriptList;

protected function generateSubscriptList2
  input DAE.Dimension inDim;
  output list<list<DAE.Exp>> outIndices;
algorithm
  outIndices := matchcontinue(inDim)
    local
      list<DAE.Exp> exp_indices;
      list<list<DAE.Exp>> res;
    case DAE.DIM_INTEGER(integer = i)
      local 
        Integer i;
        list<Integer> indices;
      equation
        indices = Util.listIntRange(i);
        res = Util.listMap(Util.listMap(indices, Exp.makeIntegerExp), Util.listCreate);
      then
        res;
    case DAE.DIM_ENUM(enumTypeName = name, literals = l)
      local
        Absyn.Path name;
        list<String> l;
        list<DAE.Exp> el;
      equation
        (DAE.ARRAY(array = el), _) = Static.makeEnumerationArray(name, l);
        res = Util.listMap(el, Util.listCreate);
      then
        res;
  end matchcontinue;
end generateSubscriptList2;

protected function mergeCurrentWithRestIndexies "
Helper function for generateSubscriptList, merges recursive dimensions with current."
  input list<list<DAE.Exp>> curr;
  input list<list<DAE.Exp>> Indexies;
  output list<list<DAE.Exp>> oIndexies;
algorithm oIndexies := matchcontinue(curr,Indexies)
  local
    list<DAE.Exp> il;
    list<list<DAE.Exp>> ill,merged;
  case(_,{}) then {};
  case(curr,(il as (_ :: (_ :: _)))::ill)
    equation
      ill = mergeCurrentWithRestIndexies(curr,ill);
      merged = Util.listMap1(curr,Util.listAppendr,il);
      merged = listAppend(merged,ill);
      then
        merged;
  case(curr,(il as {_})::ill)
    equation
      ill = mergeCurrentWithRestIndexies(curr,ill);
      merged = Util.listMap1(curr,Util.listAppendr,il);
      merged = listAppend(merged,ill);
    then
      merged;
  end matchcontinue;
end mergeCurrentWithRestIndexies;

protected function crefTupleNotPrefixOf
  "Determines if connection cref is prefix to the component "
  input Connect.EquSetElement tupleCrSource;
  input DAE.ComponentRef compName;
  output Boolean selected;
algorithm
  selected := matchcontinue(tupleCrSource,compName)
    local DAE.ComponentRef cr;
    case((cr,_),compName) then Exp.crefNotPrefixOf(compName,cr);
  end matchcontinue;
end crefTupleNotPrefixOf;

protected function crefTuplePrefixOf
  "Determines if connection cref is NOT prefix to the component "
  input Connect.EquSetElement tupleCrSource;
  input DAE.ComponentRef compName;
  output Boolean selected;
algorithm
  selected := matchcontinue(tupleCrSource,compName)
    local DAE.ComponentRef cr;
    case((cr,_),compName) then Exp.crefPrefixOf(compName,cr);
  end matchcontinue;
end crefTuplePrefixOf;

protected function flowTupleNotPrefixOf 
  "Determines if connection cref is NOT prefix to the component "
  input Connect.FlowSetElement tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
    local DAE.ComponentRef cr;
    case((cr,_,_),compName) then Exp.crefNotPrefixOf(compName,cr);
  end matchcontinue;
end flowTupleNotPrefixOf;

protected function flowTuplePrefixOf 
  "Determines if connection cref is prefix to the component "
  input Connect.FlowSetElement tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
    local DAE.ComponentRef cr;
    case((cr,_,_),compName) then Exp.crefPrefixOf(compName,cr);
  end matchcontinue;
end flowTuplePrefixOf;

protected function streamTupleNotPrefixOf 
  "Determines if connection cref is NOT prefix to the component "
  input Connect.StreamSetElement tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
    local DAE.ComponentRef cr;
    case((cr,_,_,_),compName) then Exp.crefNotPrefixOf(compName,cr);
  end matchcontinue;
end streamTupleNotPrefixOf;

protected function streamTuplePrefixOf 
  "Determines if connection cref is prefix to the component "
  input Connect.StreamSetElement tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
    local DAE.ComponentRef cr;
    case((cr,_,_,_),compName) then Exp.crefPrefixOf(compName,cr);
  end matchcontinue;
end streamTuplePrefixOf;

public function equations
  "From a number of connection sets, this function generates a list of
  equations."
  input Connect.Sets inSets;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue (inSets)
    local
      DAE.DAElist dae1,dae2,dae;
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> cs;
      list<DAE.ComponentRef> crs, dc;
      list<Connect.Set> ss;
      Connect.Sets sets;
      list<Connect.OuterConnect> outerConn;

    case (Connect.SETS(setLst = {})) then DAEUtil.emptyDae;

    // generate potential equations
    case (Connect.SETS((Connect.EQU(expComponentRefLst = cs) :: ss),crs,dc,outerConn))
      equation
        dae1 = equEquations(cs);
        dae2 = equations(Connect.SETS(ss,crs,dc,outerConn));
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae;
    
    // generate flow equations
    case (Connect.SETS((Connect.FLOW(tplExpComponentRefFaceLst = cs) :: ss),crs,dc,outerConn))
      local list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> cs;
      equation
        dae1 = flowEquations(cs);
        dae2 = equations(Connect.SETS(ss,crs,dc,outerConn));
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae;
    
    // generate stream equations
    case (Connect.SETS((Connect.STREAM(tplExpComponentRefFaceLst = cs) :: ss),crs,dc,outerConn))
      local list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> cs;
      equation        
        dae1 = streamEquations(cs);
        dae2 = equations(Connect.SETS(ss,crs,dc,outerConn));
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae;    
    
    // failure
    case (sets)
      equation
        Debug.fprint("failtrace","- ConnectUtil.equations failed\n");
      then
        fail();
  end matchcontinue;
end equations;

protected function equEquations "function: equEquations
  A non-flow connection set contains a number of components.
  Generating the equation from this set means equating all the
  components.  For n components, this will give n-1 equations.
  For example, if the set contains the components X, Y.A and
  Z.B, the equations generated will be X = Y.A and X = Z.B."
  input list<Connect.EquSetElement> inExpComponentRefLst;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue (inExpComponentRefLst)
    local
      list<DAE.Element> eq;
      DAE.ComponentRef x,y;
      list<Connect.EquSetElement> cs;
      DAE.ElementSource src,src1,src2;
      DAE.FunctionTree funcs;
      Absyn.Info info;
      list<Absyn.Within> partOfLst;
      list<Option<DAE.ComponentRef>> instanceOptLst;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> connectEquationOptLst;
      list<Absyn.Path> typeLst;      

    case {_} then DAEUtil.emptyDae;
    case ((x,src1) :: ((y,src2) :: cs))
      equation
        DAE.DAE(eq) = equEquations(((x,src1) :: cs));
        DAE.SOURCE(info, partOfLst, instanceOptLst, connectEquationOptLst, typeLst) = DAEUtil.mergeSources(src1,src2);
        // do not propagate connects from different sources! use the crefs directly!
        src = DAE.SOURCE(info, partOfLst, instanceOptLst, {SOME((x,y))}, typeLst);
      then
        (DAE.DAE(DAE.EQUEQUATION(x,y,src) :: eq));
    case(_) equation print(" FAILURE IN CONNECT \n"); then fail();
  end matchcontinue;
end equEquations;

protected function flowEquations "function: flowEquations
  Generating equations from a flow connection set is a little
  trickier that from a non-flow set.  Only one equation is
  generated, but it has to consider whether the comoponents were
  inside or outside connectors.
  This function uses flowSum to create the sum of all components
  (some of which will be negated), and the returns the equation
  where this sum is equal to 0.0."
  input list<Connect.FlowSetElement> cs;
  output DAE.DAElist outDae;
  DAE.Exp sum;
  DAE.ElementSource source;
  list<DAE.ElementSource> lde;
  DAE.ElementSource ed;
  DAE.FunctionTree funcs;
algorithm
  sum := flowSum(cs);
  (ed::lde) := Util.listMap(cs, Util.tuple33);
  source := Util.listFold(lde, DAEUtil.mergeSources, ed);
  outDae := DAE.DAE({DAE.EQUATION(sum, DAE.RCONST(0.0), source)});
end flowEquations;

protected function flowSum "function: flowSum
  This function creates an exression expressing the sum of all
  components in the given list.  Before adding the component to the
  sum, it is passed to signFlow which will negate all outside
  connectors."
  input list<Connect.FlowSetElement> inTplExpComponentRefFaceLst;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inTplExpComponentRefFaceLst)
    local
      DAE.Exp exp,exp1,exp2;
      DAE.ComponentRef c;
      Connect.Face f;
      list<Connect.FlowSetElement> cs;
    case {(c,f,_)}
      equation
        exp = signFlow(c, f);
         //print("Generating flow expression: " +& Exp.printExpStr(exp) +& "\n");
      then
        exp;
    case (((c,f,_) :: cs))
      equation
        exp1 = signFlow(c, f);
        exp2 = flowSum(cs);
      then
        DAE.BINARY(exp1,DAE.ADD(DAE.ET_REAL()),exp2);
  end matchcontinue;
end flowSum;

protected function signFlow "function: signFlow
  This function takes a name of a component and a Connect.Face, returns an
  expression. If the face is Connect.INSIDE the expression simply contains
  the component reference, but if it is Connect.OUTSIDE, the expression is
  negated."
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inComponentRef,inFace)
    local DAE.ComponentRef c;
    case (c,Connect.INSIDE()) then DAE.CREF(c,DAE.ET_OTHER());
    case (c,Connect.OUTSIDE()) then DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.CREF(c,DAE.ET_OTHER()));
  end matchcontinue;
end signFlow;

protected function streamEquations "function: streamEquations
  Generating equations from a stream connection set is a little
  trickier that from a non-stream set."
  input list<Connect.StreamSetElement> cs;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue(cs)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource src1, src2, src;
      DAE.FunctionTree funcs;
      DAE.DAElist dae;
      String str;
      list<String> strs;
      Connect.Face f1, f2;

    // handle only two stream connects in the set for now!
        
    // both inside, do nothing!
    case ({(cr1, _, Connect.INSIDE(), _), (cr2, _, Connect.INSIDE(), _)})
      then DAEUtil.emptyDae;

    // one inside, one outside
    case ({(cr1, _, f1, src1), (cr2, _, f2, src2)}) 
      equation
        // faces are not equal! one inside, one outside
        false = faceEqual(f1, f2); 
        src = DAEUtil.mergeSources(src1, src2);
        // add the stream equation cr1 = cr2 for one inside, one outside
        dae = DAE.DAE({
                DAE.EQUATION(DAE.CREF(cr1,DAE.ET_OTHER()), 
                             DAE.CREF(cr2,DAE.ET_OTHER()), 
                             src)});
      then dae;

    // anything else, ERROR!
    case (cs) 
      equation
        strs = Util.listMap(cs, printStreamRefStr);
        str = Util.stringDelimitList(strs, ", ");
        str = System.stringAppendList({"stream set: {",str,"}"});        
        print("Only one-to-one connections of streams are supported: unsupported connection set:" +& str);
      then DAEUtil.emptyDae;
  end matchcontinue;   
end streamEquations;

protected function faceEqual "function: sameFace
Test for face equality."
  input Connect.Face inFace1;
  input Connect.Face inFace2;
  output Boolean sameFaces;
algorithm
  sameFaces := matchcontinue (inFace1,inFace2)
    local DAE.ComponentRef c;
    case (Connect.INSIDE(),Connect.INSIDE()) then true;
    case (Connect.OUTSIDE(),Connect.OUTSIDE()) then true;
    case (_,_) then false;
  end matchcontinue;
end faceEqual;

//- Lookup
//  These functions are used to find and create connection sets.

protected function findEquSet "function: findEquSet
  This function finds a non-flow connection set that contains the
  component named by the second argument. If no such set is found,
  a new set is created."
  input Connect.Sets inSets;
  input DAE.ComponentRef inComponentRef;
  input DAE.ElementSource source "the element source";
  output Connect.Set outSet;
algorithm
  outSet := matchcontinue (inSets,inComponentRef,source)
    local
      Connect.Set s;
      DAE.ComponentRef c;
      list<Connect.Set> ss;
      list<DAE.ComponentRef> crs,dc;
      list<Connect.OuterConnect> outerConn;

    case (Connect.SETS(setLst = {}),c,source)
      equation
        s = newEquSet(c, source);
      then
        s;
    case (Connect.SETS(setLst = ((s as Connect.EQU(expComponentRefLst = cs)) :: _)),c,source)
      local list<tuple<DAE.ComponentRef, DAE.ElementSource>> cs;
      equation
        findInSetEqu(cs, c);
      then
        s;
    case (Connect.SETS((_ :: ss),crs,dc,outerConn),c,source)
      equation
        s = findEquSet(Connect.SETS(ss,crs,dc,outerConn), c, source);
      then
        s;
  end matchcontinue;
end findEquSet;

protected function findFlowSet "function: findFlowSet
  This function finds a flow connection set that contains the
  component named by the second argument.  If no such set is found,
  a new set is created."
  input Connect.Sets inSets;
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
  input DAE.ElementSource source "the element source";
  output Connect.Set outSet;
algorithm
  outSet := matchcontinue (inSets,inComponentRef,inFace,source)
    local
      Connect.Set s;
      DAE.ComponentRef c;
      Connect.Face d;
      list<Connect.Set> ss;
      list<DAE.ComponentRef> crs,dc;
      list<Connect.OuterConnect> outerConn;

    case (Connect.SETS(setLst = {}),c,d,source)
      equation
        s = newFlowSet(c, d, source);
      then
        s;
    case (Connect.SETS(setLst = ((s as Connect.FLOW(tplExpComponentRefFaceLst = cs)) :: _)),c,d,source)
      local list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> cs; 
      equation
        findInSetFlow(cs, c, d);
      then
        s;
    case (Connect.SETS((_ :: ss),crs,dc,outerConn),c,d,source)
      equation
        s = findFlowSet(Connect.SETS(ss,crs,dc,outerConn), c, d, source);
      then
        s;
  end matchcontinue;
end findFlowSet;

protected function findInSetEqu "function: findInSetEqu
  This is a version of findInSet which is specialized on non-flow connection sets"
  input list<Connect.EquSetElement> inExpComponentRefLst;
  input DAE.ComponentRef inComponentRef;
algorithm
  _ := matchcontinue (inExpComponentRefLst,inComponentRef)
    local 
      DAE.ComponentRef c1,c2;
      list<Connect.EquSetElement> cs;
    case ((c1,_) :: _,c2) equation Static.eqCref(c1, c2); then ();
    case (_ :: cs,c2) equation findInSetEqu(cs, c2); then ();
  end matchcontinue;
end findInSetEqu;

protected function flowSetElementEqual
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
  input Connect.FlowSetElement inElem;
  output Boolean isEqual;
algorithm
  isEqual := matchcontinue(inComponentRef, inFace, inElem)
    local
      DAE.ComponentRef cr;
      Connect.Face face;
    case (_, _, (cr, face, _))
      equation
        Static.eqCref(cr, inComponentRef);
        true = faceEqual(face, inFace);
      then
        true;
    case (_, _, _) then false;
  end matchcontinue;
end flowSetElementEqual;

protected function findInSetFlow "function: findInSetFlow
  This is a version of findInSet which is specialized on flow connection sets"
  input list<Connect.FlowSetElement> inTplExpComponentRefFaceLst;
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
algorithm
  _ := matchcontinue (inTplExpComponentRefFaceLst, inComponentRef, inFace)
    local 
      Connect.FlowSetElement fe;
      list<Connect.FlowSetElement> cs;
    case (fe :: _, _, _) 
      equation 
        true = flowSetElementEqual(inComponentRef, inFace, fe);
      then ();
    case (_ :: cs, _, _) 
      equation 
        findInSetFlow(cs, inComponentRef, inFace); 
      then ();
  end matchcontinue;
end findInSetFlow;

protected function newEquSet "function: newEquSet
  This function creates a new non-flow connection
  set containing only the given component."
  input DAE.ComponentRef inComponentRef;
  input DAE.ElementSource source "the origin of the element";
  output Connect.Set outSet;
algorithm
  outSet := matchcontinue (inComponentRef, source)
    local DAE.ComponentRef c;
    case (c,source) then Connect.EQU({(c,source)});
  end matchcontinue;
end newEquSet;

protected function newFlowSet "function: newFlowSet
  This function creates a new-flow connection set containing only
  the given component."
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
  input DAE.ElementSource source "the origin of the element";
  output Connect.Set outSet;
algorithm
  outSet := matchcontinue (inComponentRef,inFace,source)
    local DAE.ComponentRef c; Connect.Face d;
    case (c,d,source) then Connect.FLOW({(c,d,source)});
  end matchcontinue;
end newFlowSet;

protected function findStreamSet "function: findStreamSet
  This function finds a flow connection set that contains the
  component named by the second argument.  If no such set is found,
  a new set is created."
  input Connect.Sets inSets;
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
  input DAE.ElementSource source "the element source";
  output Connect.Set outSet;
algorithm
  outSet := matchcontinue (inSets,inComponentRef,inFace,source)
    local
      Connect.Set s;
      DAE.ComponentRef c;
      Connect.Face d;
      list<Connect.Set> ss;
      list<DAE.ComponentRef> crs,dc;
      list<Connect.OuterConnect> outerConn;

    case (Connect.SETS(setLst = {}),c,d,source)
      equation
        s = newStreamSet(c, d, source);
      then
        s;
    case (Connect.SETS(setLst = ((s as Connect.STREAM(tplExpComponentRefFaceLst = cs)) :: _)),c,d,source)
      local list<Connect.StreamSetElement> cs;
      equation
        findInSetStream(cs, c);
      then
        s;
    case (Connect.SETS((_ :: ss),crs,dc,outerConn),c,d,source)
      equation
        s = findStreamSet(Connect.SETS(ss,crs,dc,outerConn), c, d, source);
      then
        s;
  end matchcontinue;
end findStreamSet;

protected function newStreamSet "function: newStreamSet
  This function creates a new-stream connection set containing only
  the given component."
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
  input DAE.ElementSource source "the origin of the element";
  output Connect.Set outSet;
algorithm
  outSet := matchcontinue (inComponentRef,inFace,source)
    local DAE.ComponentRef c; Connect.Face d;
    case (c,d,source) then Connect.STREAM({(c,NONE(),d,source)});
  end matchcontinue;
end newStreamSet;

protected function findInSetStream "function: findInSetStream
  This is a version of findInSet which is specialized on stream connection sets"
  input list<Connect.StreamSetElement> inTplExpComponentRefFaceLst;
  input DAE.ComponentRef inComponentRef;
algorithm
  _ := matchcontinue (inTplExpComponentRefFaceLst,inComponentRef)
    local DAE.ComponentRef c1,c2; list<Connect.StreamSetElement> cs;
    case ((c1,_,_,_) :: _,c2) equation Static.eqCref(c1, c2); then ();
    case (_ :: cs,c2) equation findInSetStream(cs, c2); then ();
  end matchcontinue;
end findInSetStream;

protected function setsEqual
  input Connect.Set inSet1;
  input Connect.Set inSet2;
  output Boolean equalSets;
algorithm
  equalSets := matchcontinue(inSet1,inSet2)
    local
      DAE.ComponentRef cr1,cr2;
      list<Connect.EquSetElement> equRest1,equRest2;
      list<Connect.FlowSetElement> flowRest1,flowRest2;
      list<Connect.StreamSetElement> streamRest1,streamRest2;
      Connect.Face face1,face2;

    // pointer equality testing first.
    case (inSet1, inSet2)
      equation
        true = System.refEqual(inSet1, inSet2);         
      then true;

    // deal with empty case
    case (Connect.EQU({}), Connect.EQU({})) then true;
    case (Connect.FLOW({}), Connect.FLOW({})) then true;
    case (Connect.STREAM({}), Connect.STREAM({})) then true;      
    // deal with non empty Connect.EQU
    case (Connect.EQU((cr1,_)::equRest1), Connect.EQU((cr2,_)::equRest2))
      equation
        true = Exp.crefEqualNoStringCompare(cr1, cr2); // equality(cr1 = cr2);
        true = setsEqual(Connect.EQU(equRest1),Connect.EQU(equRest2));
      then
        true;
    // deal with non empty Connect.FLOW
    case (Connect.FLOW((cr1,face1,_)::flowRest1), Connect.FLOW((cr2,face2,_)::flowRest2))
      equation
        true = faceEqual(face1, face2);
        true = Exp.crefEqualNoStringCompare(cr1, cr2); // equality(cr1 = cr2);
        true = setsEqual(Connect.FLOW(flowRest1),Connect.FLOW(flowRest2));
      then
        true;
    // deal with non empty Connect.STREAM
    case (Connect.STREAM((cr1,_,face1,_)::streamRest1), Connect.STREAM((cr2,_,face2,_)::streamRest2))
      equation
        true = faceEqual(face1, face2);
        true = Exp.crefEqualNoStringCompare(cr1, cr2); // equality(cr1 = cr2);
        true = setsEqual(Connect.STREAM(streamRest1),Connect.STREAM(streamRest2));
      then
        true;        
    case (_, _) then false;
  end matchcontinue;
end setsEqual;

//- Merging

protected function merge "function: merge
  The result of merging two connection sets
  is the intersection of the two sets."
  input Connect.Sets inSets;
  input Connect.Set inSet1;
  input Connect.Set inSet2;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue (inSets,inSet1,inSet2)
    local
      list<Connect.Set> ss,ss_1;
      list<DAE.ComponentRef> crs,dc;
      // potential
      list<Connect.EquSetElement> pcs,pcs1,pcs2;
      // flow
      list<Connect.FlowSetElement> fcs,fcs1,fcs2;
      // stream
      list<Connect.StreamSetElement> scs,scs1,scs2;
      Connect.Set s1,s2;
      list<Connect.OuterConnect> outerConn;
    
    // sets are equal, do nothing
    case (inSets,s1,s2)
      equation
        true = setsEqual(s1,s2);
      then
        inSets;

    // potential
    case (Connect.SETS(ss,crs,dc,outerConn),
          (s1 as Connect.EQU(expComponentRefLst = pcs1)),
          (s2 as Connect.EQU(expComponentRefLst = pcs2)))
      equation
        pcs = Util.listMergeSorted(pcs1, pcs2, equSetElementLess);
        Connect.SETS(ss_1,_,_,_) = removeSet2(Connect.SETS(ss,crs,dc,outerConn), s1, s2);
      then
        Connect.SETS((Connect.EQU(pcs) :: ss_1),crs,dc,outerConn);
    
    // flow
    case (Connect.SETS(ss,crs,dc,outerConn),
          (s1 as Connect.FLOW(tplExpComponentRefFaceLst = fcs1)),
          (s2 as Connect.FLOW(tplExpComponentRefFaceLst = fcs2)))
      equation
        fcs = listAppend(fcs1, fcs2);
        Connect.SETS(ss_1,_,_,_) = removeSet2(Connect.SETS(ss,crs,dc,outerConn), s1, s2);
      then
        Connect.SETS((Connect.FLOW(fcs) :: ss_1),crs,dc,outerConn);
    
    // stream
    case (Connect.SETS(ss,crs,dc,outerConn),
          (s1 as Connect.STREAM(tplExpComponentRefFaceLst = scs1)),
          (s2 as Connect.STREAM(tplExpComponentRefFaceLst = scs2)))      
      equation
        scs = listAppend(scs1, scs2);
        Connect.SETS(ss_1,_,_,_) = removeSet2(Connect.SETS(ss,crs,dc,outerConn), s1, s2);
      then
        Connect.SETS((Connect.STREAM(scs) :: ss_1),crs,dc,outerConn);
  end matchcontinue;
end merge;

protected function equSetElementLess
  "Compares two potiential set elements, and returns true if the first element
  is less than the second element. This is used in merge to keep potential sets
  sorted when merging them."
  input Connect.EquSetElement inElem1;
  input Connect.EquSetElement inElem2;
  output Boolean res;
algorithm
  res := matchcontinue(inElem1, inElem2)
    local
      DAE.ComponentRef cr1, cr2;
    case ((cr1, _), (cr2, _)) then ComponentReference.crefSortFunc(cr2, cr1);
  end matchcontinue;
end equSetElementLess;

protected function removeSet2 "function: removeSet2
  This function removes the two sets given in the second and third
  argument from the collection of sets given in the first argument."
  input Connect.Sets inSets1;
  input Connect.Set inSet2;
  input Connect.Set inSet3;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue (inSets1,inSet2,inSet3)
    local
      list<DAE.ComponentRef> crs,dc;
      Connect.Sets ss_1;
      Connect.Set s,s1,s2;
      list<Connect.Set> ss;
      list<Connect.OuterConnect> outerConn;

    case (Connect.SETS({},crs,dc,outerConn),_,_) 
      then Connect.SETS({},crs,dc,outerConn);

    case (Connect.SETS((s :: ss),crs,dc,outerConn),s1,s2)
      equation
        true = setsEqual(s, s1);
        ss_1 = removeSet(Connect.SETS(ss,crs,dc,outerConn), s2);
      then
        ss_1;

    case (Connect.SETS((s :: ss),crs,dc,outerConn),s1,s2)
      equation
        true = setsEqual(s, s2);
        ss_1 = removeSet(Connect.SETS(ss,crs,dc,outerConn), s1);
      then
        ss_1;

    case (Connect.SETS((s :: ss),crs,dc,outerConn),s1,s2)
      local list<Connect.Set> ss_1;
      equation
        Connect.SETS(ss_1,_,_,_) = removeSet2(Connect.SETS(ss,crs,dc,outerConn), s1, s2);
      then
        Connect.SETS((s :: ss_1),crs,dc,outerConn);
  end matchcontinue;
end removeSet2;

protected function removeSet "function: removeSet
  This function removes one set from a list of sets."
  input Connect.Sets inSets;
  input Connect.Set inSet;
  output Connect.Sets outSets;
algorithm
  outSets:=
  matchcontinue (inSets,inSet)
    local
      list<DAE.ComponentRef> crs,dc;
      Connect.Set s,s1;
      list<Connect.Set> ss,ss_1;
      list<Connect.OuterConnect> outerConn;

    case (Connect.SETS({},crs,dc,outerConn),_) then Connect.SETS({},crs,dc,outerConn);

    case (Connect.SETS((s :: ss),crs,dc,outerConn),s1)
      equation
        true = setsEqual(s, s1);
      then
        Connect.SETS(ss,crs,dc,outerConn);

    case (Connect.SETS((s :: ss),crs,dc,outerConn),s1)
      equation
        Connect.SETS(ss_1,_,_,_) = removeSet(Connect.SETS(ss,crs,dc,outerConn), s1);
      then
        Connect.SETS((s :: ss_1),crs,dc,outerConn);
  end matchcontinue;
end removeSet;

public function connectUnconnectedFlowFromEq
  "This function tries to find an unconnected flow component, and removes it
  from the connection sets if found. It is used to implicitly connect flow
  variables when a flow variable is assigned locally in an equation."
  input DAE.ComponentRef inComponentRef;
  input Connect.Sets inSets;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(inComponentRef, inSets)
    local
      DAE.ComponentRef cr;
      list<Connect.Set> set_lst;
      list<DAE.ComponentRef> c, d;
      list<Connect.OuterConnect> oc;
    case (_, Connect.SETS(setLst = set_lst, connection = c, 
        deletedComponents = d, outerConnects = oc))
      equation
        set_lst = removeUnconnectedFlowVariable(inComponentRef, Connect.INSIDE, set_lst);
      then
        Connect.SETS(set_lst, c, d, oc);
    case (_, _) then inSets;
  end matchcontinue;
end connectUnconnectedFlowFromEq;

protected function removeUnconnectedFlowVariable
  "This function searches for a flow variable that is unconnected, i.e. that is
  alone in a connection set, and removed the set from the connection sets."
  input DAE.ComponentRef inComponentRef;
  input Connect.Face inFace;
  input list<Connect.Set> inSets;
  output list<Connect.Set> outSets;
algorithm
  outSets := matchcontinue(inComponentRef, inFace, inSets)
    local
      Connect.FlowSetElement fe;
      list<Connect.Set> sets;
      Connect.Set s;
    case (_, _, {}) then {};
    case (_, _, Connect.FLOW(tplExpComponentRefFaceLst = {fe}) :: sets)
      equation
        true = flowSetElementEqual(inComponentRef, inFace, fe);
      then
        sets;
    case (_, _, s :: sets)
      equation
        sets = removeUnconnectedFlowVariable(inComponentRef, inFace, sets);
      then
        s :: sets;
  end matchcontinue;
end removeUnconnectedFlowVariable;

/*
  - Printing

  These are a few functions used for printing a description of the
  connection sets.  The implementation is excluded from the report
  for brevity.
*/

public function printSets "function: printSets
  Prints a description of a number of connection sets to the
  standard output."
  input Connect.Sets inSets;
algorithm
  _ := matchcontinue (inSets)
    local
      Connect.Set x;
      list<Connect.Set> xs;
      list<DAE.ComponentRef> crs,dc;
      list<Connect.OuterConnect> outerConn;
    case Connect.SETS(setLst = {}) then ();
    case Connect.SETS((x :: xs),crs,dc,outerConn)
      equation
        printSet(x);
        printSets(Connect.SETS(xs,crs,dc,outerConn));
      then
        ();
  end matchcontinue;
end printSets;

protected function printSet ""
  input Connect.Set inSet;
algorithm
  Print.printBuf(printSetStr(inSet));
end printSet;

protected function printFlowRef
  input Connect.FlowSetElement inTplExpComponentRefFace;
algorithm
  Print.printBuf(printFlowRefStr(inTplExpComponentRefFace));
end printFlowRef;

protected function printStreamRef
  input Connect.StreamSetElement inTplExpComponentRefFace;
algorithm
  Print.printBuf(printStreamRefStr(inTplExpComponentRefFace));
end printStreamRef;

public function printSetsStr "function: printSetsStr
  Prints a description of a number of connection sets to a string"
  input Connect.Sets inSets;
  output String outString;
algorithm
  outString := matchcontinue (inSets)
    local
      list<String> s1;
      String s1_1,s2,res,s3,s4;
      list<Connect.Set> sets;
      list<DAE.ComponentRef> crs;
      list<DAE.ComponentRef> dc;
      list<Connect.OuterConnect> outerConn;
    case Connect.SETS(setLst = {},connection = {},deletedComponents = {},outerConnects = {})
      equation
        res = "Connect.SETS( EMPTY )\n";
      then
        res;
    case Connect.SETS(setLst = sets,connection = crs,deletedComponents=dc,outerConnects=outerConn)
      equation
        s1 = Util.listMap(sets, printSetStr);
        s1_1 = Util.stringDelimitList(s1, ", ");
        s2 = printSetCrsStr(crs);
        s3 = Util.stringDelimitList(Util.listMap(dc,Exp.printComponentRefStr), ",");
        s4 = printOuterConnectsStr(outerConn);
        res = System.stringAppendList({"Connect.SETS(\n\t",
          s1_1,", \n\t",
          s2,", \n\tdeleted comps: ",s3,", \n\touter connections:",s4,")\n"});
      then
        res;
  end matchcontinue;
end printSetsStr;

protected function printOuterConnectsStr "prints the outer connections to a string, see also printSetsStr"
  input list<Connect.OuterConnect> outerConn;
  output String str;
algorithm
  str := matchcontinue(outerConn)
    local
      String s0, s1,s2,s3; DAE.ComponentRef cr1,cr2;
      Absyn.InnerOuter io1,io2;
      Prefix.Prefix prefix;

    case({}) then "";

    case(Connect.OUTERCONNECT(prefix,cr1,io1,_,cr2,io2,_,_)::outerConn) equation
      s0 = PrefixUtil.printPrefixStr(prefix);
      s1 = printOuterConnectsStr(outerConn);
      s2 = Exp.printComponentRefStr(cr1);
      s3 = Exp.printComponentRefStr(cr2);
      str = "(" +& s0 +& ", " +& s2 +& "("+& Dump.unparseInnerouterStr(io1) +&"), " +& s3 +&"("+& Dump.unparseInnerouterStr(io2) +& ") ) ," +& s1;
    then str;
  end matchcontinue;
end printOuterConnectsStr;

protected function printSetStr " a function to print the connection set "
  input Connect.Set inSet;
  output String outString;
algorithm
  outString := matchcontinue (inSet)
    local
      list<String> strs;
      String s1,res;
      list<Connect.EquSetElement> cs;
    case Connect.EQU(expComponentRefLst = cs)
      equation
        strs = Util.listMap(Util.listMap(cs, Util.tuple21), Exp.printComponentRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = System.stringAppendList({"\n\tnon-flow set: {",s1,"}"});
      then
        res;
    case Connect.FLOW(tplExpComponentRefFaceLst = cs)
      local list<Connect.FlowSetElement> cs;
      equation
        strs = Util.listMap(cs, printFlowRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = System.stringAppendList({"\n\tflow set: {",s1,"}"});
      then
        res;
    case Connect.STREAM(tplExpComponentRefFaceLst = cs)
      local list<Connect.StreamSetElement> cs;
      equation
        strs = Util.listMap(cs, printStreamRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = System.stringAppendList({"\n\tstream set: {",s1,"}"});
      then
        res;        
  end matchcontinue;
end printSetStr;

public function printFlowRefStr
  input Connect.FlowSetElement inTplExpComponentRefFace;
  output String outString;
algorithm
  outString := matchcontinue (inTplExpComponentRefFace)
    local
      String s,res;
      DAE.ComponentRef c;
    case ((c,Connect.INSIDE(),_))
      equation
        s = Exp.printComponentRefStr(c);
        res = stringAppend(s, " INSIDE");
      then
        res;
    case ((c,Connect.OUTSIDE(),_))
      equation
        s = Exp.printComponentRefStr(c);
        res = stringAppend(s, " OUTSIDE");
      then
        res;
  end matchcontinue;
end printFlowRefStr;

public function printStreamRefStr
  input Connect.StreamSetElement inTplExpComponentRefFace;
  output String outString;
algorithm
  outString := matchcontinue (inTplExpComponentRefFace)
    local
      String s,res;
      DAE.ComponentRef c;
      Option<DAE.ComponentRef> optFlowCref;
      
    case ((c,optFlowCref,Connect.INSIDE(),_))
      equation
        s = Exp.printComponentRefStr(c);
        res = stringAppend(s, " INSIDE");
      then
        res;
    case ((c,optFlowCref,Connect.OUTSIDE(),_))
      equation
        s = Exp.printComponentRefStr(c);
        res = stringAppend(s, " OUTSIDE");
      then
        res;
  end matchcontinue;
end printStreamRefStr;

protected function printSetCrsStr
  input list<DAE.ComponentRef> crs;
  output String res;
  list<String> c_strs;
  String s;
algorithm
  c_strs := Util.listMap(crs, Exp.printComponentRefStr);
  s := Util.stringDelimitList(c_strs, ", ");
  res := System.stringAppendList({"connect crs: {",s,"}"});
end printSetCrsStr;

public function componentFace
"function: componentFace
  This function determines whether a component
  reference refers to an inner or outer connector:
  Rules:
    qualified cref and connector     => OUTSIDE
    non-qualifed cref                => OUTSIDE
    qualified cref and non-connector => INSIDE

  Modelica Specification 4.0 
  Section: 9.1.2 Inside and Outside Connectors
  In an element instance M, each connector element of M is called an outside connector with respect to M. 
  All other connector elements that are hierarchically inside M, but not in one of the outside connectors 
  of M, is called an inside connector with respect to M. This is done **BEFORE** resolving outer elements 
  to corresponding inner ones."
  input Env env;
  input InnerOuter.InstHierarchy inIH;
  input DAE.ComponentRef inComponentRef;
  output Connect.Face outFace;
algorithm
  outFace := matchcontinue (env,inIH,inComponentRef)
    local
      DAE.ComponentRef cr;
      DAE.Ident id;
      InnerOuter.InstHierarchy ih;

    // is a non-qualified cref => OUTSIDE
    case (env,ih,DAE.CREF_IDENT(ident = _)) 
      then Connect.OUTSIDE();

    // is a qualified cref and is a connector => OUTSIDE 
    case (env,ih,DAE.CREF_QUAL(ident = id,componentRef = cr)) 
      equation
       (_,_,(DAE.T_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_)),_),_,_,_,_,_,_) 
         = Lookup.lookupVar(Env.emptyCache(),env,ComponentReference.makeCrefIdent(id,DAE.ET_OTHER(),{}));
      then Connect.OUTSIDE();

    // is a qualified cref and is NOT a connector => INSIDE
    case (env,ih,DAE.CREF_QUAL(componentRef =_)) 
      then Connect.INSIDE();
  end matchcontinue;
end componentFace;

public function componentFaceType
"function: componentFaceType
  Author: BZ, 2008-12
  Same functionalty as componentFace, with the difference that 
  this function checks ident-type rather then env->lookup ==> type.
  Rules:
    qualified cref and connector     => OUTSIDE
    non-qualifed cref                => OUTSIDE
    qualified cref and non-connector => INSIDE
  
  Modelica Specification 4.0 
  Section: 9.1.2 Inside and Outside Connectors
  In an element instance M, each connector element of M is called an outside connector with respect to M. 
  All other connector elements that are hierarchically inside M, but not in one of the outside connectors 
  of M, is called an inside connector with respect to M. This is done **BEFORE** resolving outer elements 
  to corresponding inner ones."
  input DAE.ComponentRef inComponentRef;
  output Connect.Face outFace;
algorithm
  outFace := matchcontinue (inComponentRef)
    // is a non-qualified cref => OUTSIDE
    case (DAE.CREF_IDENT(ident = _)) then Connect.OUTSIDE();
    // is a qualified cref and is a connector => OUTSIDE
    case (DAE.CREF_QUAL(identType = DAE.ET_COMPLEX(complexClassType=ClassInf.CONNECTOR(_,_)))) then Connect.OUTSIDE();
    // is a qualified cref and is NOT a connector => INSIDE
    case (DAE.CREF_QUAL(componentRef =_)) then Connect.INSIDE();
  end matchcontinue;
end componentFaceType;

public function updateConnectionSetTypes "function: updateConnectionSetTypes
When instantiating connection_sets we have no type information on them.
So this is what till function will do, update type information on csets."
  input Connect.Sets csets;
  input DAE.ComponentRef typedRef;
  output Connect.Sets updatedEnv;
algorithm 
  updatedEnv := matchcontinue(csets,typedRef)
    local
      Connect.Sets cs1;
      list<Connect.Set> arg1;
      list<DAE.ComponentRef> arg2,arg2_2;
      list<DAE.ComponentRef> arg3;
      list<Connect.OuterConnect> arg4,arg4_2;
    
    case((cs1 as Connect.SETS(arg1,arg2,arg3,arg4)),typedRef)
      equation
        //TODO: update types for rest of set(arg1,arg3,arg4)
        arg2_2 = updateConnectionSetTypesCrefs(arg2,typedRef);
      then
        Connect.SETS(arg1,arg2_2,arg3,arg4);
    
    case(_,_)
      equation
        Debug.fprint("failtrace", "- updateConnectionSetTypes failed");
      then
        fail();
  end matchcontinue;
end updateConnectionSetTypes;

protected function updateConnectionSetTypesCrefs "function: updateConnectionSetTypes2
helper function for updateConnectionSetTypes"
  input list<DAE.ComponentRef> list1;
  input DAE.ComponentRef list2;
  output list<DAE.ComponentRef> list3;
algorithm 
  list3 := matchcontinue(list1,list2)
    local
      list<DAE.ComponentRef> cr1s,cr2s;
      DAE.ComponentRef cr1,cr2;
    // empty case
    case({},_) then {};
    // found something, replace the cref in the list 
    case(cr1::cr1s, cr2)
      equation
        true = Exp.crefEqual(cr1,cr2);
        cr2s = updateConnectionSetTypesCrefs(cr1s,cr2);
      then
        cr2::cr2s;
    // move along to some better part of the day
    case(cr1::cr1s,cr2)
      equation
        cr2s = updateConnectionSetTypesCrefs(cr1s,cr2);
      then
        cr1::cr2s;
  end matchcontinue;
end updateConnectionSetTypesCrefs;

end ConnectUtil;


/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

package Connect
" file:	 Connect.mo
  package:      Connect
  description: Connection set management
 
  RCS: $Id$
 
  Connections generate connection sets (datatype SET is described below)
  which are constructed during instantiation.  When a connection 
  set is generated, it is used to create a number of equations. 
  The kind of equations created depends on the type of the set. 
  
  Connect.mo is called from Inst.mo and is responsible for 
  creation of all connect-equations later passed to the DAE module 
  in DAE.mo."


public import Static;
public import DAE;
public import Env;
public import Prefix;
public import Absyn;

public 
uniontype Face"This type indicates whether a connector is an inside or an outside connector. 
 Note: this is not the same as inner and outer references. 
       A connector is inside if it connects from the outside into a 
       component and it is outside if it connects out from the component. 
       This is important when generating equations for flow variables,
       where outside connectors are multiplied with -1 (since flow is always into a component)."
  record INSIDE "This is an inside connection" end INSIDE;
  record OUTSIDE "This is an outside connection" end OUTSIDE;
end Face;

public 
uniontype Set "A connection set is represented using the Set type."
  record EQU "a list of component references"
    list<DAE.ComponentRef> expComponentRefLst;
  end EQU;

  record FLOW "a list of component reference and a face"
    list<tuple<DAE.ComponentRef, Face>> tplExpComponentRefFaceLst;
  end FLOW;

end Set;

public 
uniontype Sets "The connection \'Sets\' contains 
   - the connection set 
	 - a list of component references occuring in connect statemens
	 - a list of deleted components
	 - connect statements to propagate upwards in instance hierachy (inner/outer connectors)
	 
	The list of componentReferences are used only when evaluating the cardinality operator. 
	It is passed -into- classes to be instantiated, while the Set list is returned -from-
  instantiated classes. 
  The list of deleted components is required to be able to remove connections to them."
  record SETS
    list<Set> setLst "the connection set";
    list<DAE.ComponentRef> connection "connection_set connect_refs - list of 
					      crefs in connect statements. This is used to be able to evaluate cardinality. 
					      It is registered in env by Inst.addConnnectionSetToEnv.";
		list<DAE.ComponentRef> deletedComponents "list of components with conditional declaration = false";			      
		list<OuterConnect> outerConnects "connect statements to propagate upwards"; 
  end SETS;
end Sets;

uniontype OuterConnect
  record OUTERCONNECT
    Prefix.Prefix scope "the scope that this connect was created";
    DAE.ComponentRef cr1 "the lhs component reference";
    Absyn.InnerOuter io1 "inner/outer attribute for cr1 component";
    Face f1 "the face of the lhs component";
    DAE.ComponentRef cr2 "the rhs component reference";
    Absyn.InnerOuter io2 "inner/outer attribute for cr2 component";
    Face f2 "the face of the rhs component";
  end OUTERCONNECT;
end OuterConnect;    

public constant Sets emptySet=SETS({},{},{},{});

protected import Exp;

public function addDeletedComponent "Adds a deleted component, i.e. conditional component 
with condition = false, to Sets, if condition b is false"
  input Boolean b;
  input DAE.ComponentRef component;
  input Sets sets;
  output Sets outSets;
algorithm
  outSets := matchcontinue(b,component,sets)
  local 
    list<Set> setLst;
    list<DAE.ComponentRef> crs,deletedComps;
    list<OuterConnect> outerConn;
    case(true,component,sets) then sets;
    case(false,component,SETS(setLst,crs,deletedComps,outerConn)) 
    then SETS(setLst,crs,component::deletedComps,outerConn);
  end matchcontinue;
end addDeletedComponent;

public function addOuterConnection " Adds a connection with a reference to an outer connector

These are added to a special list, such that they can be moved up in the instance hierarchy to a place
where both instances are defined.
"
  input Prefix.Prefix scope;
  input Sets sets;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Face f1;
  input Face f2;
  
  output Sets outSets;
algorithm
  outSets := matchcontinue(scope,sets,cr1,cr2,io1,io2,f1,f2)
  local list<Set> ss;
    list<DAE.ComponentRef> crs,dc;
    list<OuterConnect> oc;
    /* First check if already added */
    case(scope,sets as SETS(ss,crs,dc,oc),cr1,cr2,io1,io2,f1,f2) equation
      _::_ = Util.listSelect2(oc,cr1,cr2,outerConnectionMatches);
    then sets;
      
    case(scope,SETS(ss,crs,dc,oc),cr1,cr2,io1,io2,f1,f2) then SETS(ss,crs,dc,OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2)::oc);        
  end matchcontinue;
end addOuterConnection;

protected function outerConnectionMatches "Returns true if OuterConnect matches the two component refernces passed as argument"
  input OuterConnect oc;
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  output Boolean matches;
algorithm
  matches := matchcontinue(oc,cr1,cr2)
    local DAE.ComponentRef cr11,cr22;
    case(OUTERCONNECT(cr1=cr11,cr2=cr22),cr1,cr2) equation
      matches = Exp.crefEqual(cr11,cr1) and Exp.crefEqual(cr22,cr2) or
           Exp.crefEqual(cr11,cr2) and Exp.crefEqual(cr22,cr1);
    then matches;
  end matchcontinue;
end outerConnectionMatches;
 
public function addOuterConnectToSets "adds an outerconnection to all sets where a corresponding inner definition is present

For instance, 
if a connection set contains {world.v, topPin.v}
and we have an outer connection connect(world,a2.aPin),
the connection should be added to the set, resulting in
{world.v,topPin.v,a2.aPin.v}

"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input Face f1;
  input Face f2;
  input list<Set> setLst;
  input list<DAE.ComponentRef> inCrs;
  output list<Set> outSetLst;
  output list<DAE.ComponentRef> outCrs;
  output Boolean added "true if addition was made";
algorithm
  (outSetLst,outCrs,added) := matchcontinue(cr1,cr2,io1,io2,f1,f2,setLst,inCrs)
  local list<DAE.ComponentRef> crs; Set set;
    list<tuple<DAE.ComponentRef,Face>> fcrs;
    Boolean added2;
    
    case(cr1,cr2,io1,io2,f1,f2,{},inCrs) then ({},inCrs,false);
      
    case(cr1,cr2,io1,io2,f1,f2,EQU(crs)::setLst,inCrs) equation
      (crs,inCrs,added) = addOuterConnectToSets2(cr1,cr2,io1,io2,crs,inCrs);
      (setLst,inCrs,added2) = addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,inCrs);
    then (EQU(crs)::setLst,inCrs,added or added2);
    
    case(cr1,cr2,io1,io2,f1,f2,FLOW(fcrs)::setLst,inCrs) equation
      (fcrs,inCrs,added) = addOuterConnectToSets3(cr1,cr2,f1,f2,io1,io2,fcrs,inCrs);
      (setLst,inCrs,added2) = addOuterConnectToSets(cr1,cr2,io1,io2,f1,f2,setLst,inCrs);
    then (FLOW(fcrs)::setLst,inCrs,added or added2);
    
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
  input list<DAE.ComponentRef> crs;
  input list<DAE.ComponentRef> inCrs "from connection crefs (outer scopes)";
  output list<DAE.ComponentRef> outCrs;
  output list<DAE.ComponentRef> outCrs2 "from connection crefs (outer scopes)";
  output Boolean added;
protected 
  Boolean isOuter1,isOuter2;
algorithm
  (_,isOuter1) := Inst.innerOuterBooleans(io1);
  (_,isOuter2) := Inst.innerOuterBooleans(io2);
  (outCrs,outCrs2,added) := addOuterConnectToSets22(cr1,cr2,isOuter1,isOuter2,crs,inCrs);
end addOuterConnectToSets2;

protected function addOuterConnectToSets22 "help function to addOuterconnectToSets2"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean isOuter1;
  input Boolean isOuter2;
  input list<DAE.ComponentRef> crs;
  input list<DAE.ComponentRef> inCrs "from connection crefs (outer scopes)";
  output list<DAE.ComponentRef> outCrs;
  output list<DAE.ComponentRef> outCrs2 "from connection crefs (outer scopes)";
  output Boolean added;
algorithm
  (outCrs,outCrs2,added) := matchcontinue(cr1,cr2,isOuter1,isOuter2,crs,inCrs)
  local DAE.ComponentRef outerCr,outerCr,connectorCr,newCr;
    case(cr1,cr2,true,true,crs,inCrs) equation
      Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"Connections where both connectors are outer references","No suggestion"});
    then (crs,inCrs,false);
    case(cr1,cr2,true,false,crs,inCrs) equation
       outerCr::_ = Util.listSelect1R(crs,cr1,Exp.crefPrefixOf);
       connectorCr = Exp.crefStripPrefix(outerCr,cr1);
       newCr = Exp.joinCrefs(cr2,connectorCr);
    then  (newCr::crs,inCrs,true);
    case(cr1,cr2,false,true,crs,inCrs) equation
       outerCr::_ = Util.listSelect1R(crs,cr2,Exp.crefPrefixOf);
       connectorCr = Exp.crefStripPrefix(outerCr,cr2);
       newCr = Exp.joinCrefs(cr1,connectorCr);
    then (newCr::crs,inCrs,true);
    case(cr1,cr2,_,_,crs,inCrs) then (crs,inCrs,false);
  end matchcontinue;
end addOuterConnectToSets22; 
 
protected function addOuterConnectToSets3 "help function to addOuterconnectToSets"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Face f1;
  input Face f2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;  
  input list<tuple<DAE.ComponentRef,Face>> crs;
  input list<DAE.ComponentRef> inCrs;
  output list<tuple<DAE.ComponentRef,Face>> outCrs;
  output list<DAE.ComponentRef> outCrs2;
  output Boolean added;
protected
  Boolean isOuter1,isOuter2;
algorithm
  (_,isOuter1) := Inst.innerOuterBooleans(io1);
  (_,isOuter2) := Inst.innerOuterBooleans(io2);
  (outCrs,outCrs2,added) := addOuterConnectToSets33(cr1,cr2,isOuter1,isOuter2,f1,f2,crs,inCrs);
end addOuterConnectToSets3;

protected function addOuterConnectToSets33 "help function to addOuterconnectToSets3"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean isOuter1;
  input Boolean isOuter2;
  input Face f1;
  input Face f2;
  input list<tuple<DAE.ComponentRef,Face>> crs;
  input list<DAE.ComponentRef> inCrs;
  output list<tuple<DAE.ComponentRef,Face>> outCrs;
  output list<DAE.ComponentRef> outCrs2;
  output Boolean added;
algorithm
  (outCrs,outCrs2,added) := matchcontinue(cr1,cr2,isOuter1,isOuter2,f1,f2,crs,inCrs)
  local DAE.ComponentRef outerCr,outerCr,connectorCr,newCr;
    case(cr1,cr2,true,true,f1,f2,crs,inCrs) equation
      Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"Connections where both connectors are outer references","No suggestion"});
    then (crs,inCrs,false);
    case(cr1,cr2,true,false,f1,f2,crs,inCrs) equation      
       outerCr::_ = Util.listSelect1R(Util.listMap(crs,Util.tuple21),cr1,Exp.crefPrefixOf);
       connectorCr = Exp.crefStripPrefix(outerCr,cr1);
       newCr = Exp.joinCrefs(cr2,connectorCr);  
    then  ((newCr,f2)::crs,inCrs,true);
    case(cr1,cr2,false,true,f1,f2,crs,inCrs) equation
       outerCr::_ = Util.listSelect1R(Util.listMap(crs,Util.tuple21),cr2,Exp.crefPrefixOf);
       connectorCr = Exp.crefStripPrefix(outerCr,cr2);
       newCr = Exp.joinCrefs(cr1,connectorCr);
    then ((newCr,f1)::crs,inCrs,true);
    case(cr1,cr2,_,_,_,_,crs,inCrs) then (crs,inCrs,false);
  end matchcontinue;
end addOuterConnectToSets33; 
 
public function addEqu "function: addEqu
 
  Adds an equal equation, see explaining text above.
 
  - Adding
 
  The two functions `add_eq\' and `add_flow\' addes a variable to a
  connection set.  The first function is used to add a non-flow
  variable, and the second is used to add a flow variable.  When
  two component are to be added to a collection of connection sets,
  the connections sets containg the components have to be located.
  If no such set exists, a new set containing only the new component
  is created.
 
  If the connection sets containing the two components are not the
  same, they are merged.
"
  input Sets ss;
  input DAE.ComponentRef r1;
  input DAE.ComponentRef r2;
  output Sets ss_1;
  Set s1,s2;
  Sets ss_1;
algorithm 
  s1 := findEquSet(ss, r1);
  s2 := findEquSet(ss, r2);
  ss_1 := merge(ss, s1, s2);
end addEqu;

public function addFlow "function: addFlow
  
  Adds an flow equation, see add_equ above.
"
  input Sets ss;
  input DAE.ComponentRef r1;
  input Face d1;
  input DAE.ComponentRef r2;
  input Face d2;
  output Sets ss_1;
  Set s1,s2;
  Sets ss_1;
algorithm 
  s1 := findFlowSet(ss, r1, d1);
  s2 := findFlowSet(ss, r2, d2);
  ss_1 := merge(ss, s1, s2);
end addFlow;

public function addArrayFlow "function: addArrayFlow
 For connecting two arrays, a flow equation for each index should be generated, see addFlow.
"
  input Sets ss;
  input DAE.ComponentRef r1;
  input Face d1;
  input DAE.ComponentRef r2;
  input Face d2;
  input Integer dsize;
  output Sets ss_1;
  Set s1,s2;
  Sets ss_1;
algorithm 
    outSets:=
  matchcontinue (ss,r1,d1,r2,d2,dsize)
    local
      Sets s,ss_1,ss_2,ss;
      DAE.ComponentRef r1_1,r2_1,r1,r2;
      Integer i_1,i;
      Set s1,s2;
    case (s,_,_,_,_,0) then s; 
    case (ss,r1,d1,r2,d2,i)
      equation 
        r1_1 = Exp.subscriptCref(r1, {DAE.INDEX(DAE.ICONST(i))});
        r2_1 = Exp.subscriptCref(r2, {DAE.INDEX(DAE.ICONST(i))});
        i_1 = i - 1;
        s1 = findFlowSet(ss, r1_1,d1);
        s2 = findFlowSet(ss, r2_1,d2);
        ss_1 = merge(ss, s1, s2);
        ss_2 = addArrayFlow(ss_1, r1,d1, r2,d2, i_1);        
      then
        ss_2;
  end matchcontinue;
end addArrayFlow;

public function addMultiArrayEqu "function: addMultiArrayEqu 
 Author: BZ 2008-07
  For connecting two arrays, an equal equation for each index should 
  be generated. generic dimensionality
"
  input Sets inSets1;
  input DAE.ComponentRef inComponentRef2;
  input DAE.ComponentRef inComponentRef3;
  input list<Integer> dimensions;
  output Sets outSets;
algorithm 
  outSets:=
  matchcontinue (inSets1,inComponentRef2,inComponentRef3,dimensions)
    local
      Integer i_1,i;
      list<Integer> rest;
      list<list<Integer>> intSubs;
      list<list<DAE.Subscript>> subSubs;
      Integer dimension;
    case (inSets1,_,_,{}) then inSets1; 
    case (inSets1,inComponentRef2,inComponentRef3,dimensions)
      equation  
        intSubs = generateSubscriptList(dimensions);
        intSubs = listReverse(intSubs);
        subSubs = Util.listMap(intSubs,Exp.intSubscripts);
        outSets = addMultiArrayEqu2(inSets1,inComponentRef2,inComponentRef3,subSubs);
      then
       outSets;
  end matchcontinue;
end addMultiArrayEqu;

protected function addMultiArrayEqu2 "
Author: BZ, 2008-07
Generates Subscripts, from the input list<list, for the componentreferences given.
"
  input Sets inSets1;
  input DAE.ComponentRef inComponentRef2;
  input DAE.ComponentRef inComponentRef3;
  input list<list<DAE.Subscript>> dimensions;
  output Sets outSets;
  algorithm outSets := matchcontinue(inSets1,inComponentRef2,inComponentRef3,dimensions)
    local
      Sets s,ss_1,ss_2,ss;
      DAE.ComponentRef r1_1,r2_1,r1,r2;
      Set s1,s2;
      list<list<DAE.Subscript>> restDims;
      list<DAE.Subscript> dims;
      Integer dimension;
    case (s,_,_,{}) then s; 
    case (ss,r1,r2,dims::restDims)
      equation
        r1_1 = Exp.replaceCrefSliceSub(r1,dims);
        r2_1 = Exp.replaceCrefSliceSub(r2,dims);
        s1 = findEquSet(ss, r1_1);
        s2 = findEquSet(ss, r2_1);
        ss_1 = merge(ss, s1, s2);
        ss_2 = addMultiArrayEqu2(ss_1, r1, r2, restDims);
      then
        ss_2;
end matchcontinue;
end addMultiArrayEqu2;

protected function generateSubscriptList "
Author BZ 2008-07
Generates all subscripts for the dimension/(s)
"
  input list<Integer> dims;
  output list<list<Integer>> subs;
algorithm subs := matchcontinue(dims)
  local
    Integer dim;
    list<Integer> rest;
    list<list<Integer>> nextLevel,result,currLevel;
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

protected function generateSubscriptList2 "
helper function for generateSubscriptList
"
  input Integer i;
  output list<list<Integer>>  oil;
algorithm oil := matchcontinue(i)
  local
  case(0) then {};
  case(i)
    equation
      oil = generateSubscriptList2(i-1);      
      then
        {i}::oil;
end matchcontinue;
end generateSubscriptList2;

protected function mergeCurrentWithRestIndexies "
Helper function for generateSubscriptList, merges recursive dimensions with current.
"
input list<list<Integer>> curr;
input list<list<Integer>> Indexies;
output list<list<Integer>> oIndexies;
algorithm oIndexies := matchcontinue(curr,Indexies)
  local
    list<Integer> il;
    list<list<Integer>> ill,merged;
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

public function equations "
  Equation generation
  From a number of connection sets, this function generates a list of equations."
  input Sets sets;
  input Prefix.Prefix pre "prefix required for checking deleted components";
  output list<DAE.Element> eqns;
algorithm
  eqns := matchcontinue(sets,pre)
    local 
      list<Set> s;
      list<DAE.ComponentRef> crs,deletedComps;
      DAE.ComponentRef cr,deletedComp;
      list<OuterConnect> outerConn;
    // no deleted components  
    case(sets as SETS(s,crs,{},outerConn),pre)
      equation
         //print(printSetsStr(sets));
      then equations2(sets);
    // handle deleted components  
    case(SETS(s,crs,deletedComp::deletedComps,outerConn),pre) 
      equation
        cr = deletedComp;
        s = removeComponentInSets(cr,s);
      then 
        equations(SETS(s,crs,deletedComps,outerConn),pre);
    // failure
    case(_,_) equation
      Debug.fprint("failtrace","Connect.equations failed\n");
    then fail();
  end matchcontinue;
end equations;

protected function removeComponentInSets "Removes all connections to component from the set"
  input DAE.ComponentRef compName;
  input list<Set> s;
  output list<Set> outS;
algorithm
  outS := matchcontinue(compName,s)
    local 
      list<DAE.ComponentRef> crs;
      list<tuple<DAE.ComponentRef, Face>> fcrs;
    // handle the empty case
    case(compName,{}) then {};
    // we have an equation
    case(compName, EQU(crs)::s) 
      equation
        //print("Deleting: " +& Exp.printComponentRefStr(compName) +& "\n");
        crs = Util.listSelect1R(crs,compName,Exp.crefNotPrefixOf);
        //print("Result EQU after remove: " +& Util.stringDelimitList(Util.listMap(crs, Exp.printComponentRefStr), ", ") +& "\n");        
        s = removeComponentInSets(compName,s);
      then EQU(crs)::s;
    // we have a flow component
    case(compName, FLOW(fcrs)::s) 
      equation  
        //print("Deleting: " +& Exp.printComponentRefStr(compName) +& "\n");        
        fcrs = Util.listSelect1(fcrs,compName,flowTupleNotPrefixOf);
        //print("Result FLOW after remove: " +& Util.stringDelimitList(Util.listMap(Util.listMap(fcrs, Util.tuple21), Exp.printComponentRefStr), ", ") +& "\n");
        s = removeComponentInSets(compName,s);
      then FLOW(fcrs)::s;
    // failure
    case(compName,_) equation
      // print("Failed to remove component:" +& Exp.printComponentRefStr(compName) +& "\n");
      Debug.fprintln("failtrace","- Connect.removeComponentInSets failed");
    then fail();
  end matchcontinue;
end removeComponentInSets;

protected function flowTupleNotPrefixOf "Help function to removeComponentInSets.
Determines if connection cref is to the component "
  input tuple<DAE.ComponentRef, Face> tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
  local DAE.ComponentRef cr1;
    case((cr1,_),compName)
      then Exp.crefNotPrefixOf(compName,cr1);
  end matchcontinue;
end flowTupleNotPrefixOf;

protected function equations2 "
Helper function to equations. Once deleted components has been 
removed from connection sets, this function generates the equations."
  input Sets inSets;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst := matchcontinue (inSets)
    local
      list<DAE.Element> dae1,dae2,dae;
      list<DAE.ComponentRef> cs,crs,dc;
      list<Set> ss;
      Sets sets;
      list<OuterConnect> outerConn;
    case (SETS(setLst = {})) then {}; 
    
    /* Empty equ set, can come from deleting components */
    case (SETS((EQU(expComponentRefLst = {}) :: ss),crs,dc,outerConn))
      equation 
        dae = equations2(SETS(ss,crs,dc,outerConn));
      then
        dae;

    /* Empty flow set, can come from deleting components */
    case (SETS((FLOW(tplExpComponentRefFaceLst = {}) :: ss),crs,dc,outerConn))
      equation 
        dae = equations2(SETS(ss,crs,dc,outerConn));
      then
        dae;
    
    case (SETS((EQU(expComponentRefLst = cs) :: ss),crs,dc,outerConn))
      equation 
        dae1 = equEquations(cs);
        dae2 = equations2(SETS(ss,crs,dc,outerConn));
        dae = listAppend(dae1, dae2);
      then
        dae;
    case (SETS((FLOW(tplExpComponentRefFaceLst = cs) :: ss),crs,dc,outerConn))
      local list<tuple<DAE.ComponentRef, Face>> cs;
      equation 
        dae1 = flowEquations(cs);
        dae2 = equations2(SETS(ss,crs,dc,outerConn));
        dae = listAppend(dae1, dae2);
      then
        dae;
    case (sets)
      equation 
        Debug.fprint("failtrace","- Connect.equations2 failed\n");
      then
        fail();        
  end matchcontinue;
end equations2;

protected function equEquations "function: equEquations
  
  A non-flow connection set contains a number of components.
  Generating the equation from this set means equating all the
  components.  For n components, this will give n-1 equations.
 
  For example, if the set contains the components `x\', `y.a\' and
  `z.b\', the equations generated will me `x = y.a\' and `y.a = z.b\'.
"
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inExpComponentRefLst)
    local
      list<DAE.Element> eq;
      DAE.ComponentRef x,y;
      list<DAE.ComponentRef> cs;
    case {_} then {}; 
    case (x :: (y :: cs))
      equation 
        eq = equEquations((y :: cs));
      then
        (DAE.EQUEQUATION(x,y) :: eq);
    case(_) equation print(" FAILURE IN CONNECT \n"); then fail();
  end matchcontinue;
end equEquations;

protected function flowEquations "function: flowEquations
  Generating equations from a flow connection set is a little
  trickier that from a non-flow set.  Only one equation is
  generated, but it has to consider whether the comoponents were
  inner or outer connectors.
  This function uses `flow_sum\' to create the sum of all components
  (some of which will be negated), and the returns the equation
  where this sum is equal to 0.0."
  input list<tuple<DAE.ComponentRef, Face>> cs;
  output list<DAE.Element> outDAEElementLst;
  DAE.Exp sum;
algorithm 
  sum := flowSum(cs);
  outDAEElementLst := {DAE.EQUATION(sum,DAE.RCONST(0.0))};
end flowEquations;

protected function flowSum "function: flowSum
  This function creates an exression expressing the sum of all
  components in the given list.  Before adding the component to the
  sum, it is passed to `sign_flow\' which will negate all outer
  connectors."
  input list<tuple<DAE.ComponentRef, Face>> inTplExpComponentRefFaceLst;
  output DAE.Exp outExp;
algorithm 
  outExp := matchcontinue (inTplExpComponentRefFaceLst)
    local
      DAE.Exp exp,exp1,exp2;
      DAE.ComponentRef c;
      Face f;
      list<tuple<DAE.ComponentRef, Face>> cs;
    case {(c,f)}
      equation
        exp = signFlow(c, f);
        // print("Generating flow expresion: " +& Exp.printExpStr(exp) +& "\n");
      then
        exp;
    case (((c,f) :: cs))
      equation 
        exp1 = signFlow(c, f);
        exp2 = flowSum(cs);
      then
        DAE.BINARY(exp1,DAE.ADD(DAE.ET_REAL()),exp2);
  end matchcontinue;
end flowSum;

protected function signFlow "function: signFlow
 
  This function takes a name of a component and a `Face\', returns an
  expression.  If the face is INSIDE the expression simply contains
  the component reference, but if it is OUTSIDE, the expression is
  negated."
  input DAE.ComponentRef inComponentRef;
  input Face inFace;
  output DAE.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentRef,inFace)
    local DAE.ComponentRef c;
    case (c,INSIDE()) then DAE.CREF(c,DAE.ET_OTHER()); 
    case (c,OUTSIDE()) then DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.CREF(c,DAE.ET_OTHER())); 
  end matchcontinue;
end signFlow;

protected function findEquSet "
  - Lookup
  
  These functions are used to find and create connection sets.

  function: findEquSet
 
  This function finds a non-flow connection set that contains the
  component named by the second argument.  If no such set is found,
  a new set is created.
"
  input Sets inSets;
  input DAE.ComponentRef inComponentRef;
  output Set outSet;
algorithm 
  outSet:=
  matchcontinue (inSets,inComponentRef)
    local
      Set s;
      DAE.ComponentRef c;
      list<Set> ss;
      list<DAE.ComponentRef> crs,dc;
      list<OuterConnect> outerConn;
    case (SETS(setLst = {}),c)
      equation 
        s = newEquSet(c);
      then
        s;
    case (SETS(setLst = (s :: _)),c)
      equation 
        findInSet(s, c);
      then
        s;
    case (SETS((_ :: ss),crs,dc,outerConn),c)
      equation 
        s = findEquSet(SETS(ss,crs,dc,outerConn), c);
      then
        s;
  end matchcontinue;
end findEquSet;

protected function findFlowSet "function: findFlowSet
 
  This function finds a flow connection set that contains the
  component named by the second argument.  If no such set is found,
  a new set is created.
"
  input Sets inSets;
  input DAE.ComponentRef inComponentRef;
  input Face inFace;
  output Set outSet;
algorithm 
  outSet:=
  matchcontinue (inSets,inComponentRef,inFace)
    local
      Set s;
      DAE.ComponentRef c;
      Face d;
      list<Set> ss;
      list<DAE.ComponentRef> crs,dc;
      list<OuterConnect> outerConn;
    case (SETS(setLst = {}),c,d)
      equation 
        s = newFlowSet(c, d);
      then
        s;
    case (SETS(setLst = (s :: _)),c,d)
      equation 
        findInSet(s, c);
      then
        s;
    case (SETS((_ :: ss),crs,dc,outerConn),c,d)
      equation 
        s = findFlowSet(SETS(ss,crs,dc,outerConn), c, d);
      then
        s;
  end matchcontinue;
end findFlowSet;

protected function findInSet "function: findInSet
  
  This function checks if a componet already appears in a given
  connection set.
"
  input Set inSet;
  input DAE.ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inSet,inComponentRef)
    local
      list<DAE.ComponentRef> cs;
      DAE.ComponentRef c;
    case (EQU(expComponentRefLst = cs),c)
      equation 
        findInSetEqu(cs, c);
      then
        ();
    case (FLOW(tplExpComponentRefFaceLst = cs),c)
      local list<tuple<DAE.ComponentRef, Face>> cs;
      equation 
        findInSetFlow(cs, c);
      then
        ();
  end matchcontinue;
end findInSet;

protected function findInSetEqu "function: findInSetEqu
  
  This is a version of `find_in_set\' which is specialized on
  non-flow connection sets
"
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input DAE.ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inExpComponentRefLst,inComponentRef)
    local
      DAE.ComponentRef c1,c2;
      list<DAE.ComponentRef> cs;
    case ((c1 :: _),c2)
      equation 
        Static.eqCref(c1, c2);
      then
        ();
    case ((_ :: cs),c2)
      equation 
        findInSetEqu(cs, c2);
      then
        ();
  end matchcontinue;
end findInSetEqu;

protected function findInSetFlow "function: findInSetFlow
  
  This is a version of `find_in_set\' which is specialized on
  flow connection sets
"
  input list<tuple<DAE.ComponentRef, Face>> inTplExpComponentRefFaceLst;
  input DAE.ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inTplExpComponentRefFaceLst,inComponentRef)
    local
      DAE.ComponentRef c1,c2;
      list<tuple<DAE.ComponentRef, Face>> cs;
    case (((c1,_) :: _),c2)
      equation 
        Static.eqCref(c1, c2);
      then
        ();
    case ((_ :: cs),c2)
      equation 
        findInSetFlow(cs, c2);
      then
        ();
  end matchcontinue;
end findInSetFlow;

protected function newEquSet "function: newEquSet
 
  This function creates a new non-flow connection set containing
  only the given component.
"
  input DAE.ComponentRef inComponentRef;
  output Set outSet;
algorithm 
  outSet:=
  matchcontinue (inComponentRef)
    local DAE.ComponentRef c;
    case c then EQU({c}); 
  end matchcontinue;
end newEquSet;

protected function newFlowSet "function: newFlowSet
 
  This function creates a new-flow connection set containing only
  the given component.
"
  input DAE.ComponentRef inComponentRef;
  input Face inFace;
  output Set outSet;
algorithm 
  outSet:=
  matchcontinue (inComponentRef,inFace)
    local
      DAE.ComponentRef c;
      Face d;
    case (c,d) then FLOW({(c,d)}); 
  end matchcontinue;
end newFlowSet;

protected function merge "
  - Merging
  
  The result of merging two connection sets is the intersection of
  the two sets.
"
  input Sets inSets1;
  input Set inSet2;
  input Set inSet3;
  output Sets outSets;
algorithm 
  outSets:=
  matchcontinue (inSets1,inSet2,inSet3)
    local
      list<Set> ss,ss_1;
      list<DAE.ComponentRef> crs,cs,cs1,cs2,dc;
      Set s1,s2;
      list<OuterConnect> outerConn;
    case (SETS(ss,crs,dc,outerConn),s1,s2)
      equation 
        equality(s1 = s2);
      then
        SETS(ss,crs,dc,outerConn);
    case (SETS(ss,crs,dc,outerConn),(s1 as EQU(expComponentRefLst = cs1)),(s2 as EQU(expComponentRefLst = cs2)))
      equation 
        cs = listAppend(cs1, cs2);
        SETS(ss_1,_,_,_) = removeSet2(SETS(ss,crs,dc,outerConn), s1, s2);
      then
        SETS((EQU(cs) :: ss_1),crs,dc,outerConn);
    case (SETS(ss,crs,dc,outerConn),(s1 as FLOW(tplExpComponentRefFaceLst = cs1)),(s2 as FLOW(tplExpComponentRefFaceLst = cs2)))
      local list<tuple<DAE.ComponentRef, Face>> cs,cs1,cs2;
      equation 
        cs = listAppend(cs1, cs2);
        SETS(ss_1,_,_,_) = removeSet2(SETS(ss,crs,dc,outerConn), s1, s2);
      then
        SETS((FLOW(cs) :: ss_1),crs,dc,outerConn);
  end matchcontinue;
end merge;

protected function removeSet2 "function: removeSet2
  
  This function removes the two sets given in the second and third
  argument from the collection of sets given in the first argument.
"
  input Sets inSets1;
  input Set inSet2;
  input Set inSet3;
  output Sets outSets;
algorithm 
  outSets:=
  matchcontinue (inSets1,inSet2,inSet3)
    local
      list<DAE.ComponentRef> crs,dc;
      Sets ss_1;
      Set s,s1,s2;
      list<Set> ss;
      list<OuterConnect> outerConn;      
    case (SETS({},crs,dc,outerConn),_,_) then SETS({},crs,dc,outerConn); 
    case (SETS((s :: ss),crs,dc,outerConn),s1,s2)
      equation 
        equality(s = s1);
        ss_1 = removeSet(SETS(ss,crs,dc,outerConn), s2);
      then
        ss_1;
    case (SETS((s :: ss),crs,dc,outerConn),s1,s2)
      equation 
        equality(s = s2);
        ss_1 = removeSet(SETS(ss,crs,dc,outerConn), s1);
      then
        ss_1;
    case (SETS((s :: ss),crs,dc,outerConn),s1,s2)
      local list<Set> ss_1;
      equation 
        SETS(ss_1,_,_,_) = removeSet2(SETS(ss,crs,dc,outerConn), s1, s2);
      then
        SETS((s :: ss_1),crs,dc,outerConn);
  end matchcontinue;
end removeSet2;

protected function removeSet "function: removeSet
 
  This function removes one set from a list of sets.
"
  input Sets inSets;
  input Set inSet;
  output Sets outSets;
algorithm 
  outSets:=
  matchcontinue (inSets,inSet)
    local
      list<DAE.ComponentRef> crs,dc;
      Set s,s1;
      list<Set> ss,ss_1;
      list<OuterConnect> outerConn;      
    case (SETS({},crs,dc,outerConn),_) then SETS({},crs,dc,outerConn); 
    case (SETS((s :: ss),crs,dc,outerConn),s1)
      equation 
        equality(s = s1);
      then
        SETS(ss,crs,dc,outerConn);
    case (SETS((s :: ss),crs,dc,outerConn),s1)
      equation 
        SETS(ss_1,_,_,_) = removeSet(SETS(ss,crs,dc,outerConn), s1);
      then
        SETS((s :: ss_1),crs,dc,outerConn);
  end matchcontinue;
end removeSet;

public function unconnectedFlowEquations "Unconnected flow variables.
  function: unconnectedFlowEquations 
 
  This function will generate set-to-zero equations for INSIDE flow variables.
  It can not generate for OUTSIDE flow variables, since we do not yet know if 
  these are connected or not. This is only known in the preceding recursive 
  call. However, the top call must generate for both INSIDE and OUTSIDE
  connectors, hence the preceding to last argument, true for top call"
 	input Env.Cache inCache;
  input Sets inSets;
  input list<DAE.Element> inDAEElementLst;
  input Env.Env inEnv;
  input Prefix.Prefix prefix;
  input Boolean inBoolean;
  input list<OuterConnect> ocl;   
  output Env.Cache outCache;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outCache,outDAEElementLst) := matchcontinue (inCache,inSets,inDAEElementLst,inEnv,prefix,inBoolean,ocl)
    local
      list<DAE.ComponentRef> v1,v2,v3,vSpecial,vars,vars2,vars3,unconnectedvars,deletedComponents;
      list<DAE.Element> dae_1,dae;
      Sets csets;
      list<Env.Frame> env;
      Env.Cache cache;
      DAE.ComponentRef prefixCref;
        list<Set> set;
    case (cache,(csets as SETS(setLst = set, deletedComponents = deletedComponents)),dae,env,prefix,true,ocl)
      local list<DAE.ComponentRef> flowCrefs;
      equation 
        v1 = Env.localOutsideConnectorFlowvars(env) "if outermost call look at both inner and outer unconnected connectors" ;
        v2 = Env.localInsideConnectorFlowvars(env);
        /* TODO: finish this part, This is currently not used due to bad specifications.
	 			as of 2008-12 we do not know wheter an inner connector connected as inside should generate a = 0.0 equation or not.
				flowCrefs = extractFlowCrefs(set);
				(v3,vSpecial) = extractOuterNonEnvDeclaredVars(ocl,true,flowCrefs);
				vars = listAppend(v1, listAppend(v2,v3));
				*/
				
				//print("\n Outside connectors, v1: " +& Util.stringDelimitList(Util.listMap(v1,Exp.printComponentRefStr),", ") +& "\n");
				//print(" Inside connectors, v2: " +& Util.stringDelimitList(Util.listMap(v2,Exp.printComponentRefStr),", ") +& "\n");
				 
        vars = listAppend(v1, v2);
        vars2 = getInsideFlowVariables(csets);
        vars3 = getOuterConnectFlowVariables(csets,vars,prefix);
        vars2 = listAppend(vars3,vars2);
        
        //print(" vars2 : " +& Util.stringDelimitList(Util.listMap(vars2,Exp.printComponentRefStr),", ") +& "\n");
        
        //print(" acquired: " +& Util.stringDelimitList(Util.listMap(vars2,Exp.printComponentRefStr),", ") +& "\n");
        // last array subscripts are not present in vars, therefor removed from vars2 too.
        vars2 = Util.listMap(vars2,Exp.crefStripLastSubs); 
        unconnectedvars = removeVariables(vars, vars2);
        unconnectedvars = removeUnconnectedDeletedComponents(unconnectedvars,csets,prefix);
      
        // no prefix for top level
        /* SE COMMENT ABOVE  
				unconnectedvars = Util.listUnion(vSpecial,unconnectedvars);*/
        (cache,dae_1) = generateZeroflowEquations(cache,unconnectedvars,env,Prefix.NOPRE(),deletedComponents);
      then
        (cache,dae_1);

      case (cache,(csets as SETS(deletedComponents = deletedComponents)),dae,env,prefix,false,ocl)
      equation 
        vars = Env.localInsideConnectorFlowvars(env);
        vars2 = getInsideFlowVariables(csets);
        prefixCref = Prefix.prefixToCref(prefix);
        vars2 = Util.listMap1(vars2,Exp.crefStripPrefix,prefixCref);
        vars3 = getOuterConnectFlowVariables(csets,vars,prefix);       
        vars2 = listAppend(vars3,vars2);
        // last array subscripts are not present in vars, therefor removed from vars2 too.
        vars2 = Util.listMap(vars2,Exp.crefStripLastSubs);
        unconnectedvars = removeVariables(vars, vars2);
        unconnectedvars = removeUnconnectedDeletedComponents(unconnectedvars,csets,prefix);
          
				// Add prefix that was "removed" above
        (cache,dae_1) = generateZeroflowEquations(cache,unconnectedvars,env,prefix,deletedComponents);
      then
        (cache,dae_1);
    case (cache,csets,dae,env,_,_,_) 
    then (cache,{}); 
  end matchcontinue;
end unconnectedFlowEquations;

/* The following following "dead code" belongs to function unconnectedFlowEquations
		See the TODO, text. 


protected function extractOuterNonEnvDeclaredVars ""
  input list<OuterConnect> outerConnects;
  input Boolean includeInside;
  input list<DAE.ComponentRef> definedFlowVars;
  output list<DAE.ComponentRef> outCrefs;
  output list<DAE.ComponentRef> outCrefs2;
algorithm (outCrefs,outCrefs2) := matchcontinue(outerConnects,includeInside,definedFlowVars)
  local
    DAE.ComponentRef cr1,cr2;
    Absyn.InnerOuter io1,io2;
    Face f1,f2;
    list<DAE.ComponentRef> crefs1,crefs2;
    list<list<DAE.ComponentRef>> tmpCrefContainer;
  case({},_,_) then ({},{});
  case(OUTERCONNECT(_,cr1,io1,f1,cr2,io2,f2)::outerConnects,includeInside,definedFlowVars)
    equation
      crefs1 = extractOuterNonEnvDeclaredVars22(cr1,io1,f1);
      crefs2 = extractOuterNonEnvDeclaredVars22(cr1,io1,f1);
      crefs1 = listAppend(crefs1,crefs2);
      tmpCrefContainer = Util.listMap1(crefs1,extractOuterNonEnvDeclaredVarsFilterFlow,definedFlowVars);
      crefs1 = Util.listFold(tmpCrefContainer,Util.listUnion,{});
      outCrefs  = cr1::{cr2};
      tmpCrefContainer = Util.listMap1(outCrefs,extractOuterNonEnvDeclaredVarsFilterFlow,definedFlowVars);
      outCrefs = Util.listFold(tmpCrefContainer,Util.listUnion,{});
    then
      (outCrefs,crefs1);
end matchcontinue;
end extractOuterNonEnvDeclaredVars;

protected function extractOuterNonEnvDeclaredVars22 ""
input DAE.ComponentRef cr;
input Absyn.InnerOuter io;
input Face dir;
output list<DAE.ComponentRef> res;
algorithm res := matchcontinue(cr,io,dir)
  case(cr,Absyn.INNER(),INSIDE) then {cr};
  case(_,_,_) then {};
  end matchcontinue;
end extractOuterNonEnvDeclaredVars22;

protected function extractOuterNonEnvDeclaredVars2 ""
input DAE.ComponentRef cr;
input Absyn.InnerOuter io;
input Face dir;
output list<DAE.ComponentRef> res;
algorithm res := matchcontinue(cr,io,dir)
  case(cr,Absyn.INNER(),INSIDE) then {cr};
  case(cr,_,OUTSIDE) then {cr};
  case(_,_,_) then {};
  end matchcontinue;
end extractOuterNonEnvDeclaredVars2;

protected function extractOuterNonEnvDeclaredVarsFilterFlow ""
input DAE.ComponentRef cr;
input list<DAE.ComponentRef> flows;
output list<DAE.ComponentRef> outCrefs;
algorithm outCrefs := matchcontinue(cr,flows)
  local
    DAE.ComponentRef flow1;
    list<DAE.ComponentRef> recRes;
  case(cr,{}) then {};
  case(cr, flow1::flows)
    equation
      true = Exp.crefPrefixOf(cr,flow1);
      recRes = extractOuterNonEnvDeclaredVarsFilterFlow(cr,flows);
      recRes = Util.listUnionElt(flow1,recRes);
      then 
        recRes;
  case(cr, flow1::flows)
    equation
      false = Exp.crefPrefixOf(cr,flow1);
      recRes = extractOuterNonEnvDeclaredVarsFilterFlow(cr,flows);
    then 
      recRes;
   end matchcontinue;
end extractOuterNonEnvDeclaredVarsFilterFlow;

public function isOutside ""
  input Face f;
  output Boolean b;
algorithm b:= matchcontinue(f)
  case(OUTER) then true;
  case(_) then false;
end matchcontinue;
end isOutside;

protected function extractFlowCrefs "
Author: BZ, 2008-12
Get all flow vars as DAE.ComponentRef from a list of sets.
"
  input list<Set> inSets;
  output list<DAE.ComponentRef> ocrefs;
algorithm ocrefs := matchcontinue(inSets)
  case({}) then {};
  case(EQU(_)::inSets) then extractFlowCrefs(inSets);
  case(FLOW(lv)::inSets)
    local
      list<tuple<DAE.ComponentRef, Face>> lv;
      list<DAE.ComponentRef> recRes,res;
    equation
      res = Util.listMap(lv,Util.tuple21);
      recRes = extractFlowCrefs(inSets);
      res = listAppend(res,recRes);
    then
      res;
  case(_) equation print(" failure in extractFlowCrefs\n"); then fail();
end matchcontinue;
end extractFlowCrefs;
*/

protected function removeUnconnectedDeletedComponents "Removes deleted components,
 i.e. with conditional declaration = false, from
the list of unconnected variables"
  input list<DAE.ComponentRef> vars;
  input Sets sets;
  input Prefix.Prefix prefix;
  output list<DAE.ComponentRef> outVars;
algorithm
  outVars := matchcontinue(vars,sets,prefix)
    local
      DAE.ComponentRef deletedComp;
      list<Set> s;
      list<DAE.ComponentRef> crs,deletedComps;
      list<OuterConnect> outerConn;

    case(vars,SETS(s,crs,{},_),prefix) then vars;

    case(vars,SETS(s,crs,deletedComp::deletedComps,outerConn),prefix)
      equation
        vars = Util.listSelect2(vars, deletedComp, prefix, crefNotPrefixOf);
        // print("Deleting: " +& Exp.printComponentRefStr(deletedComp) +& "\n");
        // print("Result unconnected vars after remove -> prefix: " +& Prefix.printPrefixStr(prefix) +& "/" +& Util.stringDelimitList(Util.listMap(vars, Exp.printComponentRefStr), ", ") +& "\n");
        vars = removeUnconnectedDeletedComponents(vars,SETS(s,crs,deletedComps,outerConn),prefix);
      then vars;
  end matchcontinue;
end removeUnconnectedDeletedComponents;

protected function crefNotPrefixOf
  input DAE.ComponentRef crSubPrefix;
  input DAE.ComponentRef cr;
  input Prefix.Prefix prefix;
  output Boolean selected;
algorithm
   selected := matchcontinue (crSubPrefix, cr, prefix)
     local DAE.ComponentRef prefixCref; Boolean select;
     // deal with NO prefix!
     case (crSubPrefix, cr, Prefix.NOPRE())
       equation
         select = not Exp.crefPrefixOf(cr, crSubPrefix);
       then
         select;
     case (crSubPrefix, cr, prefix)
       equation
         // adrpo: we need to ADD the prefix otherwise it won't find components!
         //        Example of the problem: Deleting: rev.constantTorque
         //                                Result unconnected vars after remove: constantTorque.support.tau <- add it here
         prefixCref = Prefix.prefixToCref(prefix);
         crSubPrefix = Exp.joinCrefs(prefixCref, crSubPrefix);
         select = not Exp.crefPrefixOf(cr, crSubPrefix);
       then
         select;         
   end matchcontinue; 
end crefNotPrefixOf;

protected function removeVariables "function: removeVariables
  Removes all the variables in the second list from the first list."
  input list<DAE.ComponentRef> inExpComponentRefLst1;
  input list<DAE.ComponentRef> inExpComponentRefLst2;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst1,inExpComponentRefLst2)
    local
      list<DAE.ComponentRef> vars,vars_1,res,removelist;
      DAE.ComponentRef r1;
    case (vars,{}) then vars;  /* vars remove */ 
    case (vars,(r1 :: removelist))
      equation 
        vars_1 = removeVariable(r1, vars);
        res = removeVariables(vars_1, removelist);
      then
        res;
  end matchcontinue;
end removeVariables;

protected function removeVariable "function: removeVariable
 
  Removes a variable from a list of variables.
"
  input DAE.ComponentRef inComponentRef;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inComponentRef,inExpComponentRefLst)
    local
      DAE.ComponentRef cr,cr2;
      list<DAE.ComponentRef> xs,res;
    case (cr,{}) then {}; 
    case (cr,(cr2 :: xs))
      equation 
        true = Exp.crefEqual(cr, cr2);
      then
        xs;
    case (cr,(cr2 :: xs))
      equation 
        res = removeVariable(cr, xs);
      then
        (cr2 :: res);
  end matchcontinue;
end removeVariable;

protected function generateZeroflowEquations "function: generateZeroflowEquations
 
  Unconnected flow variables should be set to zero. This function 
  generates equations setting each variable in the list to zero.
"
	input Env.Cache inCache;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input Env.Env inEnv;
  input Prefix.Prefix prefix;
  input list<DAE.ComponentRef> deletedComponents;
  output Env.Cache outCache;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outCache,outDAEElementLst) :=
  matchcontinue (inCache,inExpComponentRefLst,inEnv,prefix,deletedComponents)
    local
      list<DAE.Element> res,res1;
      DAE.ComponentRef cr;
      Env.Env env;
      DAE.Type tp;
      DAE.ExpType arrType;
      list<DAE.ComponentRef> xs;
      list<int> dimSizes;
      list<Option<Integer>> dimSizesOpt;
      list<DAE.Exp> dimExps;
      Env.Cache cache;
      DAE.ComponentRef cr2;
    case (cache,{},_,_,_) then (cache,{}); 
    case (cache,(cr :: xs),env,prefix,deletedComponents)
      equation
        (cache,_,tp,_,_,_) = Lookup.lookupVar(cache,env,cr);
        true = Types.isArray(tp); // For variables that are arrays, generate cr = fill(0,dims);
        dimSizes = Types.getDimensionSizes(tp);
        (_,dimSizesOpt) = Types.flattenArrayTypeOpt(tp); 
        dimExps = Util.listMap(dimSizes,Exp.makeIntegerExp);
        (cache,res) = generateZeroflowEquations(cache,xs,env,prefix,deletedComponents);
        cr2 = Prefix.prefixCref(prefix,cr);
        arrType = DAE.ET_ARRAY(DAE.ET_REAL(),dimSizesOpt);
        dimExps = {DAE.ICONST(0),DAE.ICONST(0),DAE.ICONST(0)};
        res1 = generateZeroflowArrayEquations(cr2, dimSizes, DAE.RCONST(0.0));
        res = listAppend(res1,res);
      then
        (cache,res);
    case (cache,(cr :: xs),env,prefix,deletedComponents) // For scalars.
      equation
        (cache,_,tp,_,_,_) = Lookup.lookupVar(cache,env,cr);
        false = Types.isArray(tp); // scalar
        (cache,res) = generateZeroflowEquations(cache,xs,env,prefix,deletedComponents);
        cr2 = Prefix.prefixCref(prefix,cr);
        //print(" Generated flow equation for: " +& Exp.printComponentRefStr(cr2) +& "\n");
      then
        (cache,DAE.EQUATION(DAE.CREF(cr2,DAE.ET_REAL()),DAE.RCONST(0.0)) :: res);
  end matchcontinue;
end generateZeroflowEquations;

protected function generateZeroflowArrayEquations
"function generateZeroflowArrayEquations
 @author adrpo
 Given:
 - a component reference (ex. a.b)
 - a list of dimensions  (ex. {3, 4})
 - an expression         (ex. expr)
 this function will generate a list of equations of the form:
 { a.b[1,1] = expr, a.b[1,2] = expr, a.b[1,3] = expr, a.b[1.4] = expr,
   a.b[2,1] = expr, a.b[2,2] = expr, a.b[2,3] = expr, a.b[2.4] = expr,
   a.b[3,1] = expr, a.b[3,2] = expr, a.b[3,3] = expr, a.b[3.4] = expr }"
  input DAE.ComponentRef cr;
  input list<Integer> dimensions;
  input DAE.Exp initExp;
  output list<DAE.Element> equations;
algorithm
  equations := matchcontinue(cr, dimensions, initExp)
    local
      list<DAE.Element> out;
      list<list<Integer>> indexIntegerLists;
      list<list<DAE.Subscript>> indexSubscriptLists;
    case(cr, dimensions, initExp)
      equation
        // take the list of dimensions: ex. {2, 5, 3}
        // and generate a list of ranges: ex. {{1, 2}, {1, 2, 3, 4, 5}, {1, 2, 3}}
        indexIntegerLists = Util.listMap(dimensions, Util.listIntRange);
        // from a list like: {{1, 2}, {1, 2, 3, 4, 5}
        // generate a list like: { { {DAE.INDEX(DAE.ICONST(1)}, {DAE.INDEX(DAE.ICONST(2)} }, ... }
        indexSubscriptLists = Util.listListMap(indexIntegerLists, integer2Subscript);
        // now generate a product of all lists in { {lst1}, {lst2}, {lst3} }
        // which will generate indexes like [1, 1, 1], [1, 1, 2], [1, 2, 3] ... [2, 5, 3]
        indexSubscriptLists = generateAllIndexes(indexSubscriptLists, {});
        out = Util.listMap1(indexSubscriptLists, genZeroEquation, (cr, initExp));
      then
        out;
  end matchcontinue;
end generateZeroflowArrayEquations;

protected function genZeroEquation
"@author adrpo
 given an integer transform it into an list<DAE.Subscript>"
  input   list<DAE.Subscript> indexSubscriptList;
  input   tuple<DAE.ComponentRef, DAE.Exp> crAndInitExp;
  output  DAE.Element eq;
algorithm
  eq := matchcontinue (indexSubscriptList, crAndInitExp)
    local
      DAE.ComponentRef cr;
      DAE.Exp initExp;
    case (indexSubscriptList, (cr, initExp))
      equation
        cr = Exp.subscriptCref(cr, indexSubscriptList);        
      then
        DAE.EQUATION(DAE.CREF(cr,DAE.ET_REAL()), initExp);
  end matchcontinue;
end genZeroEquation;

function generateAllIndexes
  input  list<list<DAE.Subscript>> inIndexLists;
  input  list<list<DAE.Subscript>> accumulator;
  output list<list<DAE.Subscript>> outIndexLists;
algorithm
  outIndexLists := matchcontinue (inIndexLists, accumulator)
    local
      list<DAE.Subscript> hd;
      list<list<DAE.Subscript>> tail, res1, res2;
    case ({}, accumulator) then accumulator;
    case (hd::tail, accumulator)
      equation
        //print ("generateAllIndexes hd:"); printMe(hd);
        res1 = Util.listProduct({hd}, accumulator);
        res2 = generateAllIndexes(tail, res1);
        //print ("generateAllIndexes res2:"); Util.listMap0(res2, printMe);
      then
        res2;
  end matchcontinue;
end generateAllIndexes;

protected function integer2Subscript
"@author adrpo
 given an integer transform it into an DAE.Subscript"
  input  Integer       index;
  output DAE.Subscript subscript;
algorithm
 subscript := DAE.INDEX(DAE.ICONST(index));
end integer2Subscript;

protected function getAllFlowVariables "function: getAllFlowVariables
  
  Return a list of all flow variables from the connection sets.
"
  input Sets inSets;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inSets)
    local
      list<DAE.ComponentRef> res1,res2,res,crs,dc;
      list<tuple<DAE.ComponentRef, Face>> varlst;
      list<Set> xs;
      list<OuterConnect> outerConn;
    case SETS(setLst = {}) then {}; 
    case (SETS((FLOW(tplExpComponentRefFaceLst = varlst) :: xs),crs,dc,outerConn))
      equation 
        res1 = Util.listMap(varlst, Util.tuple21);
        res2 = getAllFlowVariables(SETS(xs,crs,dc,outerConn));
        res = listAppend(res1, res2);
      then
        res;
    case (SETS((EQU(expComponentRefLst = res1) :: xs),crs,dc,outerConn))
      equation 
        res = getAllFlowVariables(SETS(xs,crs,dc,outerConn));
      then
        res;
  end matchcontinue;
end getAllFlowVariables;

protected function getOuterConnectFlowVariables "Retrieves all flow variables from outer connections
given a list of all local flow variables
For instance, for a connect(A,B) in outerConnects and  a list of flow variables A.i, B.i, other.i,... 
where A and B are Electrical Pin, the function returns
{A.i, B.i}
Note: A and B a prefixed eariler, so the prefix is remove, if the reference is not outer.
"
  input Sets csets;
  input list<DAE.ComponentRef> allFlowVars;
  input Prefix.Prefix prefix;
  output list<DAE.ComponentRef> flowVars;
algorithm
    flowVars := matchcontinue(csets,allFlowVars,prefix)
    local list<OuterConnect> outerConnects;
      case(SETS(outerConnects=outerConnects),allFlowVars,prefix) equation
        flowVars = Util.listListUnionOnTrue(Util.listMap2(outerConnects,getOuterConnectFlowVariables2,allFlowVars,prefix),Exp.crefEqual);
      then flowVars;
    end matchcontinue;
end getOuterConnectFlowVariables;

protected function getOuterConnectFlowVariables2 "Help function to getOuterConnectFlowVariables"
  input OuterConnect outerConnect;
  input list<DAE.ComponentRef> allFlowVars;
  input Prefix.Prefix prefix;
  output list<DAE.ComponentRef> flowVars;
algorithm
  flowVars := matchcontinue(outerConnect,allFlowVars,prefix)
  local DAE.ComponentRef cr1,cr2;
    Absyn.InnerOuter io1,io2;
    case(OUTERCONNECT(_,cr1,io1,_,cr2,io2,_),allFlowVars,prefix) equation
      cr1 = removePrefixOnNonOuter(cr1,io1,prefix);
      cr2 = removePrefixOnNonOuter(cr2,io2,prefix);
      flowVars = listAppend(
        Util.listSelect1R(allFlowVars,cr1,Exp.crefPrefixOf)
        ,
        Util.listSelect1R(allFlowVars,cr2,Exp.crefPrefixOf)
        );
     then flowVars;        
  end matchcontinue;   
end getOuterConnectFlowVariables2;
  
protected  function removePrefixOnNonOuter "help function to  getOuterConnectFlowVariables2"
  input DAE.ComponentRef cr;
  input Absyn.InnerOuter io;
  input Prefix.Prefix prefix;
  output DAE.ComponentRef outCr;
algorithm
  outCr := matchcontinue(cr,io,prefix)
  local DAE.ComponentRef prefixCref;
    case(cr,Absyn.OUTER(),prefix) then cr;
    case(cr,Absyn.INNEROUTER(),prefix) then cr;
    case(cr,_,prefix) equation
      prefixCref = Prefix.prefixToCref(prefix);
      cr =Exp.crefStripPrefix(cr,prefixCref);
    then cr;
  end matchcontinue;
end removePrefixOnNonOuter;

protected function getInsideFlowVariables "function: getInsideFlowVariables
 
  Get all flow variables that are inner variables from the Sets.
"
  input Sets inSets;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inSets)
    local
      list<DAE.ComponentRef> res1,res2,res,crs,dc;
      list<tuple<DAE.ComponentRef, Face>> vars;
      list<Set> xs;
      list<OuterConnect> outerConn;
            
    case (SETS(setLst = {})) then {}; 
    case (SETS((FLOW(tplExpComponentRefFaceLst = vars) :: xs),crs,dc,outerConn))
      equation 
        res1 = getInsideFlowVariables2(vars);
        res2 = getInsideFlowVariables(SETS(xs,crs,dc,outerConn));
        res = listAppend(res1, res2);
      then
        res;
    case (SETS((EQU(expComponentRefLst = _) :: xs),crs,dc,outerConn))
      equation 
        res = getInsideFlowVariables(SETS(xs,crs,dc,outerConn));
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_inner_flow_variables failed\\n\") */  then fail(); 
  end matchcontinue;
end getInsideFlowVariables;

protected function getInsideFlowVariables2 "function: getInsideFlowVariables2
 
  Help function to get_inner_flow_variables.
"
  input list<tuple<DAE.ComponentRef, Face>> inTplExpComponentRefFaceLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inTplExpComponentRefFaceLst)
    local
      list<DAE.ComponentRef> res;
      DAE.ComponentRef cr;
      list<tuple<DAE.ComponentRef, Face>> xs;
    case ({}) then {}; 
    case (((cr,INSIDE()) :: xs))
      equation 
        res = getInsideFlowVariables2(xs);
      then
        (cr :: res);
    case ((_ :: xs))
      equation 
        res = getInsideFlowVariables2(xs);
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_inner_flow_variables_2 failed\\n\") */  then fail(); 
  end matchcontinue;
end getInsideFlowVariables2;

protected function getOutsideFlowVariables "function: getOutsideFlowVariables
 
  Get all flow variables that are outer variables from the Sets.
"
  input Sets inSets;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inSets)
    local
      list<DAE.ComponentRef> res1,res2,res,crs,dc;
      list<tuple<DAE.ComponentRef, Face>> vars;
      list<Set> xs;
      list<OuterConnect> outerConn;
    case (SETS(setLst = {})) then {}; 
    case (SETS((FLOW(tplExpComponentRefFaceLst = vars) :: xs),crs,dc,outerConn))
      equation 
        res1 = getOutsideFlowVariables2(vars);
        res2 = getOutsideFlowVariables(SETS(xs,crs,dc,outerConn));
        res = listAppend(res1, res2);
      then
        res;
    case (SETS((EQU(expComponentRefLst = _) :: xs),crs,dc,outerConn))
      equation 
        res = getOutsideFlowVariables(SETS(xs,crs,dc,outerConn));
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_outer_flow_variables failed\\n\") */  then fail(); 
  end matchcontinue;
end getOutsideFlowVariables;

protected function getOutsideFlowVariables2 "function: getOutsideFlowVariables2
 
  Help function to get_outer_flow_variables.
"
  input list<tuple<DAE.ComponentRef, Face>> inTplExpComponentRefFaceLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inTplExpComponentRefFaceLst)
    local
      list<DAE.ComponentRef> res;
      DAE.ComponentRef cr;
      list<tuple<DAE.ComponentRef, Face>> xs;
    case ({}) then {}; 
    case (((cr,OUTSIDE()) :: xs))
      equation 
        res = getOutsideFlowVariables2(xs);
      then
        (cr :: res);
    case (( _ :: xs))
      equation 
        res = getOutsideFlowVariables2(xs);
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_outer_flow_variables_2 failed\\n\") */  then fail(); 
  end matchcontinue;
end getOutsideFlowVariables2;

protected import Print;
protected import Util;
protected import Types;
protected import Lookup;
protected import Debug;
protected import Error;
protected import Inst;
protected import Dump;

/*
  - Printing
 
  These are a few functions used for printing a description of the
  connection sets.  The implementation is excluded from the report
  for brevity.
*/

public function printSets "function: printSets
 
  Prints a description of a number of connection sets to the
  standard output.
"
  input Sets inSets;
algorithm 
  _:=
  matchcontinue (inSets)
    local
      Set x;
      list<Set> xs;
      list<DAE.ComponentRef> crs,dc;
      list<OuterConnect> outerConn;
    case SETS(setLst = {}) then (); 
    case SETS((x :: xs),crs,dc,outerConn)
      equation 
        printSet(x);
        printSets(SETS(xs,crs,dc,outerConn));
      then
        ();
  end matchcontinue;
end printSets;

protected function printSet ""
  input Set inSet;
algorithm 
  Print.printBuf(printSetStr(inSet));
end printSet;

protected function printFlowRef
  input tuple<DAE.ComponentRef, Face> inTplExpComponentRefFace;
algorithm 
  Print.printBuf(printFlowRefStr(inTplExpComponentRefFace));
end printFlowRef;

public function printSetsStr "function: printSetsStr
  Prints a description of a number of connection sets to a string"
  input Sets inSets;
  output String outString;
algorithm 
  outString := matchcontinue (inSets)
    local
      list<String> s1;
      String s1_1,s2,res,s3,s4;
      list<Set> sets;
      list<DAE.ComponentRef> crs;
      list<DAE.ComponentRef> dc;
      list<OuterConnect> outerConn;
    case SETS(setLst = {},connection = {},deletedComponents = {},outerConnects = {})
      equation
        res = "SETS( EMPTY )\n";
      then
        res;      
    case SETS(setLst = sets,connection = crs,deletedComponents=dc,outerConnects=outerConn)
      equation 
        s1 = Util.listMap(sets, printSetStr);
        s1_1 = Util.stringDelimitList(s1, ", ");
        s2 = printSetCrsStr(crs);
        s3 = Util.stringDelimitList(Util.listMap(dc,Exp.printComponentRefStr),",");
        s4 = printOuterConnectsStr(outerConn);
        res = Util.stringAppendList({"SETS( ",s1_1,", ",s2,", deleted comps: ",s3,", outer connections:",s4,")\n"});
      then
        res;
  end matchcontinue;
end printSetsStr;

protected function printOuterConnectsStr "prints the outer connections to a string, see also printSetsStr"
  input list<OuterConnect> outerConn;
  output String str;
algorithm
  str := matchcontinue(outerConn)
  local String s1,s2,s3; DAE.ComponentRef cr1,cr2;
    Absyn.InnerOuter io1,io2;
    case({}) then "";
      
    case(OUTERCONNECT(_,cr1,io1,_,cr2,io2,_)::outerConn) equation
      s1 = printOuterConnectsStr(outerConn);
      s2 = Exp.printComponentRefStr(cr1);
      s3 = Exp.printComponentRefStr(cr2);
      str = "(" +& s2 +& "("+& Dump.unparseInnerouterStr(io1) +&"), " +& s3 +&"("+& Dump.unparseInnerouterStr(io2) +& ") ) ," +& s1;
    then str;
  end matchcontinue;
end printOuterConnectsStr;

protected function printSetStr
  input Set inSet;
  output String outString;
algorithm 
  outString := matchcontinue (inSet)
    local
      list<String> strs;
      String s1,res;
      list<DAE.ComponentRef> cs;
    case EQU(expComponentRefLst = cs)
      equation 
        strs = Util.listMap(cs, Exp.printComponentRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = Util.stringAppendList({" non-flow set: {",s1,"}"});
      then
        res;
    case FLOW(tplExpComponentRefFaceLst = cs)
      local list<tuple<DAE.ComponentRef, Face>> cs;
      equation 
        strs = Util.listMap(cs, printFlowRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = Util.stringAppendList({" flow set: {",s1,"}"});
      then
        res;
  end matchcontinue;
end printSetStr;

public function printFlowRefStr
  input tuple<DAE.ComponentRef, Face> inTplExpComponentRefFace;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inTplExpComponentRefFace)
    local
      String s,res;
      DAE.ComponentRef c;
    case ((c,INSIDE()))
      equation 
        s = Exp.printComponentRefStr(c);
        res = stringAppend(s, " INSIDE");
      then
        res;
    case ((c,OUTSIDE()))
      equation 
        s = Exp.printComponentRefStr(c);
        res = stringAppend(s, " OUTSIDE");
      then
        res;
  end matchcontinue;
end printFlowRefStr;

protected function printSetCrsStr
  input list<DAE.ComponentRef> crs;
  output String res;
  list<String> c_strs;
  String s;
algorithm 
  c_strs := Util.listMap(crs, Exp.printComponentRefStr);
  s := Util.stringDelimitList(c_strs, ", ");
  res := Util.stringAppendList({" connect crs: { ",s,"}"});
end printSetCrsStr;
end Connect;


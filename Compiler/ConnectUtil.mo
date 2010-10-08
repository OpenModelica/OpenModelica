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

public
type Env     = Env.Env;
type AvlTree = Env.AvlTree;
type Cache   = Env.Cache;

public function addDeletedComponent "Adds a deleted component, i.e. conditional component
with condition = false, to Connect.Sets, if condition b is false"
  input Boolean b;
  input DAE.ComponentRef component;
  input Connect.Sets sets;
  output Connect.Sets outSets;
algorithm
  outSets := matchcontinue(b,component,sets)
  local
    list<Connect.Set> setLst;
    list<DAE.ComponentRef> crs,deletedComps;
    list<Connect.OuterConnect> outerConn;
    case(true,component,sets) then sets;
    case(false,component,Connect.SETS(setLst,crs,deletedComps,outerConn))
    then Connect.SETS(setLst,crs,component::deletedComps,outerConn);
  end matchcontinue;
end addDeletedComponent;

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

    case(cr1,cr2,io1,io2,f1,f2,Connect.FLOW(fcrs)::setLst,inCrs) equation
      (fcrs,inCrs,added) = addOuterConnectToSets3(cr1,cr2,f1,f2,io1,io2,fcrs,inCrs);
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
  input list<tuple<DAE.ComponentRef,DAE.ElementSource>> crs;
  input list<DAE.ComponentRef> inCrs "from connection crefs (outer scopes)";
  output list<tuple<DAE.ComponentRef,DAE.ElementSource>> outCrs;
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
  input list<tuple<DAE.ComponentRef,DAE.ElementSource>> crs;
  input list<DAE.ComponentRef> inCrs "from connection crefs (outer scopes)";
  output list<tuple<DAE.ComponentRef,DAE.ElementSource>> outCrs;
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
  input list<tuple<DAE.ComponentRef,Connect.Face,DAE.ElementSource>> crs;
  input list<DAE.ComponentRef> inCrs;
  output list<tuple<DAE.ComponentRef,Connect.Face,DAE.ElementSource>> outCrs;
  output list<DAE.ComponentRef> outCrs2;
  output Boolean added;
protected
  Boolean isOuter1,isOuter2;
algorithm
  (_,isOuter1) := InnerOuter.innerOuterBooleans(io1);
  (_,isOuter2) := InnerOuter.innerOuterBooleans(io2);
  (outCrs,outCrs2,added) := addOuterConnectToSets33(cr1,cr2,isOuter1,isOuter2,f1,f2,crs,inCrs);
end addOuterConnectToSets3;

protected function addOuterConnectToSets33 "help function to addOuterconnectToSets3"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Boolean isOuter1;
  input Boolean isOuter2;
  input Connect.Face f1;
  input Connect.Face f2;
  input list<tuple<DAE.ComponentRef,Connect.Face,DAE.ElementSource>> crs;
  input list<DAE.ComponentRef> inCrs;
  output list<tuple<DAE.ComponentRef,Connect.Face,DAE.ElementSource>> outCrs;
  output list<DAE.ComponentRef> outCrs2;
  output Boolean added;
algorithm
  (outCrs,outCrs2,added) := matchcontinue(cr1,cr2,isOuter1,isOuter2,f1,f2,crs,inCrs)
    local
      DAE.ComponentRef outerCr,outerCr,connectorCr,newCr;
      DAE.ElementSource src;

    case(cr1,cr2,true,true,f1,f2,crs,inCrs)
      equation
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"Connections where both connectors are outer references","No suggestion"});
      then (crs,inCrs,false);

    case(cr1,cr2,true,false,f1,f2,crs,inCrs)
      equation
        (outerCr,_,src)::_ = Util.listSelect1(crs,cr1,flowTuplePrefixOf);
        connectorCr = Exp.crefStripPrefix(outerCr,cr1);
        newCr = Exp.joinCrefs(cr2,connectorCr);
      then ((newCr,f2,src)::crs,inCrs,true);

    case(cr1,cr2,false,true,f1,f2,crs,inCrs)
      equation
        (outerCr,_,src)::_ = Util.listSelect1(crs,cr2,flowTuplePrefixOf);
        connectorCr = Exp.crefStripPrefix(outerCr,cr2);
        newCr = Exp.joinCrefs(cr1,connectorCr);
      then ((newCr,f1,src)::crs,inCrs,true);

    case(cr1,cr2,_,_,_,_,crs,inCrs) then (crs,inCrs,false);
  end matchcontinue;
end addOuterConnectToSets33;

protected function addOuterConnectToSets4 "help function to addOuterconnectToSets"
  input DAE.ComponentRef cr1;
  input DAE.ComponentRef cr2;
  input Connect.Face f1;
  input Connect.Face f2;
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  input list<tuple<DAE.ComponentRef,Option<DAE.ComponentRef>,Connect.Face,DAE.ElementSource>> crs;
  input list<DAE.ComponentRef> inCrs;
  output list<tuple<DAE.ComponentRef,Option<DAE.ComponentRef>,Connect.Face,DAE.ElementSource>> outCrs;
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
  input list<tuple<DAE.ComponentRef,Option<DAE.ComponentRef>,Connect.Face,DAE.ElementSource>> crs;
  input list<DAE.ComponentRef> inCrs;
  output list<tuple<DAE.ComponentRef,Option<DAE.ComponentRef>,Connect.Face,DAE.ElementSource>> outCrs;
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
  output Connect.Sets ss_1;
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
  output Connect.Sets ss_1;
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

public function equations "
  Equation generation
  From a number of connection sets, this function generates a list of equations."
  input Connect.Sets sets;
  input Prefix.Prefix pre "prefix required for checking deleted components";
  input Boolean isTopScope "this is true if we are in a top scope class!";
  input ConnectionGraph.ConnectionGraph inConnectionGraph;
  output DAE.DAElist outDAE;
  output ConnectionGraph.ConnectionGraph outConnectionGraph;  
algorithm
  (outDAE, outConnectionGraph) := matchcontinue(sets,pre,isTopScope,inConnectionGraph)
    local
      list<Connect.Set> s;
      list<DAE.ComponentRef> crs,deletedComps;
      DAE.ComponentRef cr,deletedComp;
      list<Connect.OuterConnect> outerConn;
      ConnectionGraph.ConnectionGraph graph;
      DAE.DAElist dae;
      list<DAE.Element> daeElements, daeEqualityConstraint;
      DAE.FunctionTree functions;
      
    // no deleted components
    case(sets as Connect.SETS(s,crs,{},outerConn),pre,isTopScope,graph)
      equation
        // print(printSetsStr(sets)); 
        dae = equations2(sets);
      then 
        (dae, graph);

    // handle deleted components
    case(Connect.SETS(s,crs,deletedComp::deletedComps,outerConn),pre,isTopScope,graph)
      equation
        cr = deletedComp;
        s = removeComponentInSets(cr,s);
        
        // remove all branches/connections/roots in the connection graph leading to the deleted components
        graph = ConnectionGraph.removeDeletedComponentsFromCG(graph, cr);
        // recursive call with all the rest of deleted components. 
        (dae, graph) = equations(Connect.SETS(s,crs,deletedComps,outerConn),pre,isTopScope,graph);
      then
        (dae, graph);

    // failure
    case(_,_,_,_) equation
      Debug.fprint("failtrace", "Connect.equations failed\n");
    then fail();
  end matchcontinue;
end equations;

protected function removeComponentInSets "Removes all connections to component from the set"
  input DAE.ComponentRef compName;
  input list<Connect.Set> s;
  output list<Connect.Set> outS;
algorithm
  outS := matchcontinue(compName,s)
    local
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> crs;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> fcrs;
      list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> scrs;
    // handle the empty case
    case(compName,{}) then {};
    // we have an equation
    case(compName, Connect.EQU(crs)::s)
      equation
        //print("Deleting: " +& Exp.printComponentRefStr(compName) +& "\n");
        crs = Util.listSelect1(crs,compName,crefTupleNotPrefixOf);
        //print("Result Connect.EQU after remove: " +& Util.stringDelimitList(Util.listMap(Util.listMap(crs,Util.tuple21), Exp.printComponentRefStr), ", ") +& "\n");
        s = removeComponentInSets(compName,s);
      then Connect.EQU(crs)::s;
    // we have a flow component
    case(compName, Connect.FLOW(fcrs)::s)
      equation
        //print("Deleting: " +& Exp.printComponentRefStr(compName) +& "\n");
        fcrs = Util.listSelect1(fcrs,compName,flowTupleNotPrefixOf);
        //print("Result Connect.FLOW after remove: " +& Util.stringDelimitList(Util.listMap(Util.listMap(fcrs, Util.tuple31), Exp.printComponentRefStr), ", ") +& "\n");
        s = removeComponentInSets(compName,s);
      then Connect.FLOW(fcrs)::s;
    // we have a stream component
    case(compName, Connect.STREAM(scrs)::s)
      equation
        //print("Deleting: " +& Exp.printComponentRefStr(compName) +& "\n");
        scrs = Util.listSelect1(scrs,compName,streamTupleNotPrefixOf);
        //print("Result Connect.FLOW after remove: " +& Util.stringDelimitList(Util.listMap(Util.listMap(fcrs, Util.tuple31), Exp.printComponentRefStr), ", ") +& "\n");
        s = removeComponentInSets(compName,s);
      then Connect.STREAM(scrs)::s;
    // failure
    case(compName,_) equation
      // print("Failed to remove component:" +& Exp.printComponentRefStr(compName) +& "\n");
      Debug.fprintln("failtrace","- Connect.removeComponentInSets failed");
    then fail();
  end matchcontinue;
end removeComponentInSets;

function crefTupleNotPrefixOf
  input tuple<DAE.ComponentRef, DAE.ElementSource> tupleCrSource;
  input DAE.ComponentRef compName;
  output Boolean selected;
algorithm
  selected := matchcontinue(tupleCrSource,compName)
    local DAE.ComponentRef cr;
    case((cr,_),compName) then Exp.crefNotPrefixOf(compName,cr);
  end matchcontinue;
end crefTupleNotPrefixOf;

function crefTuplePrefixOf
  input tuple<DAE.ComponentRef, DAE.ElementSource> tupleCrSource;
  input DAE.ComponentRef compName;
  output Boolean selected;
algorithm
  selected := matchcontinue(tupleCrSource,compName)
    local DAE.ComponentRef cr;
    case((cr,_),compName) then Exp.crefPrefixOf(compName,cr);
  end matchcontinue;
end crefTuplePrefixOf;

protected function flowTupleNotPrefixOf "Help function to removeComponentInSets.
Determines if connection cref is NOT to the component "
  input tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource> tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
    local DAE.ComponentRef cr;
    case((cr,_,_),compName) then Exp.crefNotPrefixOf(compName,cr);
  end matchcontinue;
end flowTupleNotPrefixOf;

protected function flowTuplePrefixOf "Help function to removeComponentInSets.
Determines if connection cref is to the component "
  input tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource> tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
    local DAE.ComponentRef cr;
    case((cr,_,_),compName) then Exp.crefPrefixOf(compName,cr);
  end matchcontinue;
end flowTuplePrefixOf;

protected function streamTupleNotPrefixOf "Help function to removeComponentInSets.
Determines if connection cref is NOT to the component "
  input tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource> tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
    local DAE.ComponentRef cr;
    case((cr,_,_,_),compName) then Exp.crefNotPrefixOf(compName,cr);
  end matchcontinue;
end streamTupleNotPrefixOf;

protected function streamTuplePrefixOf "Help function to removeComponentInSets.
Determines if connection cref is to the component "
  input tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource> tpl;
  input DAE.ComponentRef compName;
  output Boolean b;
algorithm
  b:= matchcontinue(tpl,compName)
    local DAE.ComponentRef cr;
    case((cr,_,_,_),compName) then Exp.crefPrefixOf(compName,cr);
  end matchcontinue;
end streamTuplePrefixOf;

protected function equations2 "
Helper function to equations. Once deleted components has been
removed from connection sets, this function generates the equations."
  input Connect.Sets inSets;
  output DAE.DAElist  outDae;
algorithm
  outDAEElementLst := matchcontinue (inSets)
    local
      DAE.DAElist dae1,dae2,dae;
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> cs;
      list<DAE.ComponentRef> crs, dc;
      list<Connect.Set> ss;
      Connect.Sets sets;
      list<Connect.OuterConnect> outerConn;

    case (Connect.SETS(setLst = {})) then DAEUtil.emptyDae;

    /* Empty equ set, can come from deleting components */
    case (Connect.SETS((Connect.EQU(expComponentRefLst = {}) :: ss),crs,dc,outerConn))
      equation
        dae = equations2(Connect.SETS(ss,crs,dc,outerConn));
      then
        dae;

    /* Empty flow set, can come from deleting components */
    case (Connect.SETS((Connect.FLOW(tplExpComponentRefFaceLst = {}) :: ss),crs,dc,outerConn))
      equation
        dae = equations2(Connect.SETS(ss,crs,dc,outerConn));
      then
        dae;

    /* Empty stream set, can come from deleting components */
    case (Connect.SETS((Connect.STREAM(tplExpComponentRefFaceLst = {}) :: ss),crs,dc,outerConn))
      equation
        dae = equations2(Connect.SETS(ss,crs,dc,outerConn));
      then
        dae;
    
    // generate potential equations
    case (Connect.SETS((Connect.EQU(expComponentRefLst = cs) :: ss),crs,dc,outerConn))
      equation
        dae1 = equEquations(cs);
        dae2 = equations2(Connect.SETS(ss,crs,dc,outerConn));
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae;
    
    // generate flow equations
    case (Connect.SETS((Connect.FLOW(tplExpComponentRefFaceLst = cs) :: ss),crs,dc,outerConn))
      local list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> cs;
      equation
        dae1 = flowEquations(cs);
        dae2 = equations2(Connect.SETS(ss,crs,dc,outerConn));
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae;
    
    // generate stream equations
    case (Connect.SETS((Connect.STREAM(tplExpComponentRefFaceLst = cs) :: ss),crs,dc,outerConn))
      local list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> cs;
      equation        
        dae1 = streamEquations(cs);
        dae2 = equations2(Connect.SETS(ss,crs,dc,outerConn));
        dae = DAEUtil.joinDaes(dae1, dae2);
      then
        dae;    
    
    // failure
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
  For example, if the set contains the components X, Y.A and
  Z.B, the equations generated will me X = Y.A and Y.A = Z.B."
  input list<tuple<DAE.ComponentRef,DAE.ElementSource>> inExpComponentRefLst;
  output DAE.DAElist outDae;
algorithm
  outDae := matchcontinue (inExpComponentRefLst)
    local
      list<DAE.Element> eq;
      DAE.ComponentRef x,y;
      list<tuple<DAE.ComponentRef,DAE.ElementSource>> cs;
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
        DAE.DAE(eq) = equEquations(((y,src2) :: cs));
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
  input list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> cs;
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
  input list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> inTplExpComponentRefFaceLst;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inTplExpComponentRefFaceLst)
    local
      DAE.Exp exp,exp1,exp2;
      DAE.ComponentRef c;
      Connect.Face f;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> cs;
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
  input list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> cs;
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
        str = Util.stringAppendList({"stream set: {",str,"}"});        
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
    case (Connect.SETS(setLst = (s :: _)),c,source)
      equation
        findInSet(s, c);
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
    case (Connect.SETS(setLst = (s :: _)),c,d,source)
      equation
        findInSet(s, c);
      then
        s;
    case (Connect.SETS((_ :: ss),crs,dc,outerConn),c,d,source)
      equation
        s = findFlowSet(Connect.SETS(ss,crs,dc,outerConn), c, d, source);
      then
        s;
  end matchcontinue;
end findFlowSet;

protected function findInSet "function: findInSet
  This function checks if a componet already
  appears in a given connection set."
  input Connect.Set inSet;
  input DAE.ComponentRef inComponentRef;
algorithm
  _ := matchcontinue (inSet,inComponentRef)
    local
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> cs;
      DAE.ComponentRef c;
    case (Connect.EQU(expComponentRefLst = cs),c)
      equation
        findInSetEqu(cs, c);
      then
        ();
    case (Connect.FLOW(tplExpComponentRefFaceLst = cs),c)
      local list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> cs;
      equation
        findInSetFlow(cs, c);
      then
        ();
    case (Connect.STREAM(tplExpComponentRefFaceLst = cs),c)
      local list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> cs;
      equation
        findInSetStream(cs, c);
      then
        ();
  end matchcontinue;
end findInSet;

protected function findInSetEqu "function: findInSetEqu
  This is a version of findInSet which is specialized on non-flow connection sets"
  input list<tuple<DAE.ComponentRef, DAE.ElementSource>> inExpComponentRefLst;
  input DAE.ComponentRef inComponentRef;
algorithm
  _ := matchcontinue (inExpComponentRefLst,inComponentRef)
    local DAE.ComponentRef c1,c2;
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> cs;

    case ((c1,_) :: _,c2) equation Static.eqCref(c1, c2); then ();
    case (_ :: cs,c2) equation findInSetEqu(cs, c2); then ();
  end matchcontinue;
end findInSetEqu;

protected function findInSetFlow "function: findInSetFlow
  This is a version of findInSet which is specialized on flow connection sets"
  input list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> inTplExpComponentRefFaceLst;
  input DAE.ComponentRef inComponentRef;
algorithm
  _ := matchcontinue (inTplExpComponentRefFaceLst,inComponentRef)
    local DAE.ComponentRef c1,c2; list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> cs;
    case ((c1,_,_) :: _,c2) equation Static.eqCref(c1, c2); then ();
    case (_ :: cs,c2) equation findInSetFlow(cs, c2); then ();
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
    case (Connect.SETS(setLst = (s :: _)),c,d,source)
      equation
        findInSet(s, c);
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
  input list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> inTplExpComponentRefFaceLst;
  input DAE.ComponentRef inComponentRef;
algorithm
  _ := matchcontinue (inTplExpComponentRefFaceLst,inComponentRef)
    local DAE.ComponentRef c1,c2; list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> cs;
    case ((c1,_,_,_) :: _,c2) equation Static.eqCref(c1, c2); then ();
    case (_ :: cs,c2) equation findInSetStream(cs, c2); then ();
  end matchcontinue;
end findInSetStream;

function setsEqual
  input Connect.Set inSet1;
  input Connect.Set inSet2;
  output Boolean equalSets;
algorithm
  equalSets := matchcontinue(inSet1,inSet2)
    local
      DAE.ComponentRef cr1,cr2;
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> equRest1,equRest2;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> flowRest1,flowRest2;
      list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> streamRest1,streamRest2;
      Connect.Face face1,face2;

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
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> pcs,pcs1,pcs2;
      // flow
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> fcs,fcs1,fcs2;
      // stream
      list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> scs,scs1,scs2;
      Connect.Set s1,s2;
      list<Connect.OuterConnect> outerConn;
    
    // sets are equal, do nothing
    case (inSets/*Connect.SETS(ss,crs,dc,outerConn)*/,s1,s2)
      equation
        true = setsEqual(s1,s2);
      then
        inSets; // Connect.SETS(ss,crs,dc,outerConn);

    // potential
    case (Connect.SETS(ss,crs,dc,outerConn),
          (s1 as Connect.EQU(expComponentRefLst = pcs1)),
          (s2 as Connect.EQU(expComponentRefLst = pcs2)))
      equation
        pcs = listAppend(pcs1, pcs2);
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

public function unconnectedFlowEquations "Unconnected flow variables.
  function: unconnectedFlowEquations

  This function will generate set-to-zero equations for Connect.INSIDE flow variables.
  It can not generate for Connect.OUTSIDE flow variables, since we do not yet know if
  these are connected or not. This is only known in the preceding recursive
  call. However, the top call must generate for both Connect.INSIDE and Connect.OUTSIDE
  connectors, hence the preceding to last argument, true for top call"
 	input Cache inCache;
  input Connect.Sets inSets;
  input DAE.DAElist inDae;
  input Env inEnv;
  input Prefix.Prefix prefix;
  input Boolean isTopScope;
  input list<Connect.OuterConnect> ocl;
  output Cache outCache;
  output DAE.DAElist outDae;
algorithm
  (outCache, outDae) := matchcontinue (inCache,inSets,inDae,inEnv,prefix,isTopScope,ocl)
    local
      list<DAE.ComponentRef> v1,v2,v3,vSpecial,vars,vars2,vars3,unconnectedvars,deletedComponents;
      DAE.DAElist dae_1,dae;
      Connect.Sets csets;
      list<Env.Frame> env;
      Cache cache;
      DAE.ComponentRef prefixCref;
      list<Connect.Set> set;
      list<DAE.ComponentRef> flowCrefs;
    
    // is top scope as the input var isTopScope is true
    case (cache,(csets as Connect.SETS(setLst = set, deletedComponents = deletedComponents)),dae,env,prefix,true,ocl)
      equation
        v1 = localOutsideConnectorFlowvars(env) "if outermost call look at both inner and outer unconnected connectors" ;
        v2 = localInsideConnectorFlowvars(env);
        /* TODO: finish this part, This is currently not used due to bad specifications.
	 			as of 2008-12 we do not know wheter an inner connector connected as inside should generate a = 0.0 equation or not.
				flowCrefs = extractFlowCrefs(set);
				(v3,vSpecial) = extractOuterNonEnvDeclaredVars(ocl,true,flowCrefs);
				vars = listAppend(v1, listAppend(v2,v3));
				*/
        
				//print("\n Outside connectors, v1: " +& Util.stringDelimitList(Util.listMap(v1,Exp.printComponentRefStr),", ") +& "\n");
				//print(" Inside connectors, v2: " +& Util.stringDelimitList(Util.listMap(v2,Exp.printComponentRefStr),", ") +& "\n");
        
        vars  = listAppend(v1, v2);
        vars2 = getInsideFlowVariables(csets);
        vars3 = getOuterConnectFlowVariables(csets,vars,prefix);
        vars2 = listAppend(vars3,vars2);
        
        //print(" vars2 : " +& Util.stringDelimitList(Util.listMap(vars2,Exp.printComponentRefStr),", ") +& "\n");
        //print(" acquired: " +& Util.stringDelimitList(Util.listMap(vars2,Exp.printComponentRefStr),", ") +& "\n");
        // last array subscripts are not present in vars, therefore removed from vars2 too.
        
        vars2 = Util.listMap(vars2,Exp.crefStripLastSubs);
        
        // print(" removing : " +& Util.stringDelimitList(Util.listMap(vars2,Exp.printComponentRefStr),", ") +& "\n");
        // print(" from : " +& Util.stringDelimitList(Util.listMap(vars,Exp.printComponentRefStr),", ") +& "\n");

        unconnectedvars = removeVariables(vars, vars2);
        unconnectedvars = removeUnconnectedDeletedComponents(unconnectedvars,csets,prefix);
        
        // no prefix for top level
        /* SE COMMENT ABOVE
				unconnectedvars = Util.listUnion(vSpecial,unconnectedvars);*/
        (cache,dae_1) = generateZeroflowEquations(cache,unconnectedvars,env,Prefix.NOPRE(),deletedComponents);
      then
        (cache,dae_1);
    
    // is NOT top scope as the input var isTopScope is false
    case (cache,(csets as Connect.SETS(deletedComponents = deletedComponents)),dae,env,prefix,false,ocl)
      equation
        vars = localInsideConnectorFlowvars(env);
        vars2 = getInsideFlowVariables(csets);
        prefixCref = PrefixUtil.prefixToCref(prefix);
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

    // we could not find any unconnected flow equations, return emtpty DAE  
    case (cache,csets,dae,env,_,_,_) then (cache,DAEUtil.emptyDae);
  end matchcontinue;
end unconnectedFlowEquations;

/* The following following "dead code" belongs to function unconnectedFlowEquations
		See the TODO, text.


protected function extractOuterNonEnvDeclaredVars ""
  input list<Connect.OuterConnect> outerConnects;
  input Boolean includeInside;
  input list<DAE.ComponentRef> definedFlowVars;
  output list<DAE.ComponentRef> outCrefs;
  output list<DAE.ComponentRef> outCrefs2;
algorithm (outCrefs,outCrefs2) := matchcontinue(outerConnects,includeInside,definedFlowVars)
  local
    DAE.ComponentRef cr1,cr2;
    Absyn.InnerOuter io1,io2;
    Connect.Face f1,f2;
    list<DAE.ComponentRef> crefs1,crefs2;
    list<list<DAE.ComponentRef>> tmpCrefContainer;
  case({},_,_) then ({},{});
  case(Connect.OUTERCONNECT(_,cr1,io1,f1,cr2,io2,f2)::outerConnects,includeInside,definedFlowVars)
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
input Connect.Face dir;
output list<DAE.ComponentRef> res;
algorithm res := matchcontinue(cr,io,dir)
  case(cr,Absyn.INNER(),Connect.INSIDE) then {cr};
  case(_,_,_) then {};
  end matchcontinue;
end extractOuterNonEnvDeclaredVars22;

protected function extractOuterNonEnvDeclaredVars2 ""
input DAE.ComponentRef cr;
input Absyn.InnerOuter io;
input Connect.Face dir;
output list<DAE.ComponentRef> res;
algorithm res := matchcontinue(cr,io,dir)
  case(cr,Absyn.INNER(),Connect.INSIDE) then {cr};
  case(cr,_,Connect.OUTSIDE) then {cr};
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
  input Connect.Face f;
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
  input list<Connect.Set> inSets;
  output list<DAE.ComponentRef> ocrefs;
algorithm ocrefs := matchcontinue(inSets)
  case({}) then {};
  case(Connect.EQU(_)::inSets) then extractFlowCrefs(inSets);
  case(Connect.FLOW(lv)::inSets)
    local
      list<tuple<DAE.ComponentRef, Connect.Face>> lv;
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
  input Connect.Sets sets;
  input Prefix.Prefix prefix;
  output list<DAE.ComponentRef> outVars;
algorithm
  outVars := matchcontinue(vars,sets,prefix)
    local
      DAE.ComponentRef deletedComp;
      list<Connect.Set> s;
      list<DAE.ComponentRef> crs,deletedComps;
      list<Connect.OuterConnect> outerConn;

    case(vars,Connect.SETS(s,crs,{},_),prefix) then vars;

    case(vars,Connect.SETS(s,crs,deletedComp::deletedComps,outerConn),prefix)
      equation
        vars = Util.listSelect2(vars, deletedComp, prefix, crefNotPrefixOf);
        // print("Deleting: " +& Exp.printComponentRefStr(deletedComp) +& "\n");
        // print("Result unconnected vars after remove -> prefix: " +& PrefixUtil.printPrefixStr(prefix) +& "/" +& Util.stringDelimitList(Util.listMap(vars, Exp.printComponentRefStr), ", ") +& "\n");
        vars = removeUnconnectedDeletedComponents(vars,Connect.SETS(s,crs,deletedComps,outerConn),prefix);
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
         prefixCref = PrefixUtil.prefixToCref(prefix);
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
  outExpComponentRefLst := matchcontinue (inExpComponentRefLst1,inExpComponentRefLst2)
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
  Removes a variable from a list of variables."
  input DAE.ComponentRef inComponentRef;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inComponentRef,inExpComponentRefLst)
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
  generates equations setting each variable in the list to zero."
	input Cache inCache;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input Env inEnv;
  input Prefix.Prefix prefix;
  input list<DAE.ComponentRef> deletedComponents;
  output Cache outCache;
  output DAE.DAElist outDae;
algorithm
  (outCache,outDae) := matchcontinue (inCache,inExpComponentRefLst,inEnv,prefix,deletedComponents)
    local
      DAE.DAElist res,res1;
      DAE.ComponentRef cr;
      Env env;
      DAE.Type tp;
      DAE.ExpType arrType;
      list<DAE.ComponentRef> xs;
      list<int> dimSizesInt;
      list<DAE.Dimension> dimSizes;
      Cache cache;
      DAE.ComponentRef cr2;
      DAE.FunctionTree funcs;
      list<DAE.Element> elts;
    case (cache,{},_,_,_) then (cache,DAEUtil.emptyDae);
    case (cache,(cr :: xs),env,prefix,deletedComponents)
      equation
        (cache,_,tp,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr);
        true = Types.isArray(tp); // For variables that are arrays, generate cr = fill(0,dims);
        dimSizesInt = Types.getDimensionSizes(tp);
        (_,dimSizes) = Types.flattenArrayTypeOpt(tp);
        (cache,res) = generateZeroflowEquations(cache,xs,env,prefix,deletedComponents);
        (cache,cr2) = PrefixUtil.prefixCref(cache,env,InnerOuter.emptyInstHierarchy,prefix,cr);
        dimSizes = {DAE.DIM_INTEGER(0), DAE.DIM_INTEGER(0), DAE.DIM_INTEGER(0)};
        arrType = DAE.ET_ARRAY(DAE.ET_REAL(),dimSizes);
        res1 = generateZeroflowArrayEquations(cr2, dimSizesInt, DAE.RCONST(0.0));
        res = DAEUtil.joinDaes(res1,res);
      then
        (cache,res);
    case (cache,(cr :: xs),env,prefix,deletedComponents) // For scalars.
      equation
        (cache,_,tp,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr);
        false = Types.isArray(tp); // scalar
        (cache,DAE.DAE(elts)) = generateZeroflowEquations(cache,xs,env,prefix,deletedComponents);
        (cache,cr2) = PrefixUtil.prefixCref(cache,env,InnerOuter.emptyInstHierarchy,prefix,cr);
        //print(" Generated flow equation for: " +& Exp.printComponentRefStr(cr2) +& "\n");
      then
        (cache,DAE.DAE(DAE.EQUATION(DAE.CREF(cr2,DAE.ET_REAL()),DAE.RCONST(0.0), DAE.emptyElementSource) :: elts));
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
  output DAE.DAElist dae;
algorithm
  dae:= matchcontinue(cr, dimensions, initExp)
    local
      list<DAE.Element> out;
      list<list<Integer>> indexIntegerLists;
      list<list<DAE.Subscript>> indexSubscriptLists;
      DAE.FunctionTree funcs;
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
        DAE.DAE(out);
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
        DAE.EQUATION(DAE.CREF(cr,DAE.ET_REAL()), initExp, DAE.emptyElementSource);
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
  Return a list of all flow variables from the connection sets."
  input Connect.Sets inSets;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inSets)
    local
      list<DAE.ComponentRef> res1,res2,res,crs,dc;
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> resTplLst;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> varlst;
      list<Connect.Set> xs;
      list<Connect.OuterConnect> outerConn;

    case Connect.SETS(setLst = {}) then {};
    case (Connect.SETS((Connect.FLOW(tplExpComponentRefFaceLst = varlst) :: xs),crs,dc,outerConn))
      equation
        res1 = Util.listMap(varlst, Util.tuple31);
        res2 = getAllFlowVariables(Connect.SETS(xs,crs,dc,outerConn));
        res = listAppend(res1, res2);
      then
        res;
    case (Connect.SETS((Connect.EQU(expComponentRefLst = resTplLst) :: xs),crs,dc,outerConn))
      equation
        res = getAllFlowVariables(Connect.SETS(xs,crs,dc,outerConn));
      then
        res;
  end matchcontinue;
end getAllFlowVariables;

protected function getOuterConnectFlowVariables "Retrieves all flow variables from outer connections
given a list of all local flow variables
For instance, for a connect(A,B) in outerConnects and  a list of flow variables A.i, B.i, other.i,...
where A and B are Electrical Pin, the function returns {A.i, B.i}
Note: A and B a prefixed earlier, so the prefix is removed if the reference is not outer."
  input Connect.Sets csets;
  input list<DAE.ComponentRef> allFlowVars;
  input Prefix.Prefix prefix;
  output list<DAE.ComponentRef> flowVars;
algorithm
    flowVars := matchcontinue(csets,allFlowVars,prefix)
      local 
        list<Connect.OuterConnect> outerConnects;

      case(Connect.SETS(outerConnects=outerConnects),allFlowVars,prefix) 
        equation
          flowVars = Util.listListUnionOnTrue(Util.listMap2(outerConnects,getOuterConnectFlowVariables2,allFlowVars,prefix),Exp.crefEqual);
        then flowVars;
    end matchcontinue;
end getOuterConnectFlowVariables;

protected function getOuterConnectFlowVariables2 "Help function to getOuterConnectFlowVariables"
  input Connect.OuterConnect outerConnect;
  input list<DAE.ComponentRef> allFlowVars;
  input Prefix.Prefix prefix;
  output list<DAE.ComponentRef> flowVars;
algorithm
  flowVars := matchcontinue(outerConnect,allFlowVars,prefix)
    local
      DAE.ComponentRef cr1,cr2;
      Absyn.InnerOuter io1,io2;

    case(Connect.OUTERCONNECT(_,cr1,io1,_,cr2,io2,_,_),allFlowVars,prefix) 
      equation
        cr1 = removePrefixOnNonOuter(cr1,io1,prefix);
        cr2 = removePrefixOnNonOuter(cr2,io2,prefix);
        flowVars = listAppend(Util.listSelect1R(allFlowVars,cr1,Exp.crefPrefixOf), Util.listSelect1R(allFlowVars,cr2,Exp.crefPrefixOf));
      then 
        flowVars;
  end matchcontinue;
end getOuterConnectFlowVariables2;

protected  function removePrefixOnNonOuter "help function to  getOuterConnectFlowVariables2"
  input DAE.ComponentRef cr;
  input Absyn.InnerOuter io;
  input Prefix.Prefix prefix;
  output DAE.ComponentRef outCr;
algorithm
  outCr := matchcontinue(cr,io,prefix)
    local 
      DAE.ComponentRef prefixCref;

    case(cr,Absyn.OUTER(),prefix) then cr;
    case(cr,Absyn.INNEROUTER(),prefix) then cr;
    case(cr,_,prefix) equation
      prefixCref = PrefixUtil.prefixToCref(prefix);
      cr = Exp.crefStripPrefix(cr,prefixCref);
    then cr;
  end matchcontinue;
end removePrefixOnNonOuter;

protected function getInsideFlowVariables "function: getInsideFlowVariables
  Get all flow variables that are inner variables from the Connect.Sets."
  input Connect.Sets inSets;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inSets)
    local
      list<DAE.ComponentRef> res1,res2,res,crs,dc;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> vars;
      list<Connect.Set> xs;
      list<Connect.OuterConnect> outerConn;

    case (Connect.SETS(setLst = {})) then {};
    case (Connect.SETS((Connect.FLOW(tplExpComponentRefFaceLst = vars) :: xs),crs,dc,outerConn))
      equation
        res1 = getInsideFlowVariables2(vars);
        res2 = getInsideFlowVariables(Connect.SETS(xs,crs,dc,outerConn));
        res = listAppend(res1, res2);
      then
        res;
    case (Connect.SETS((Connect.EQU(expComponentRefLst = _) :: xs),crs,dc,outerConn))
      equation
        res = getInsideFlowVariables(Connect.SETS(xs,crs,dc,outerConn));
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_inner_flow_variables failed\\n\") */  then fail();
  end matchcontinue;
end getInsideFlowVariables;

protected function getInsideFlowVariables2 "function: getInsideFlowVariables2
  Help function to getInnerFlowVariables."
  input list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> inTplExpComponentRefFaceLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inTplExpComponentRefFaceLst)
    local
      list<DAE.ComponentRef> res;
      DAE.ComponentRef cr;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> xs;
      String str;
    
    // handle emptyness 
    case ({}) then {};
    
    // is an inside, add to our list
    case ((cr,Connect.INSIDE(),_) :: xs)
      equation
        res = getInsideFlowVariables2(xs);
      then
        (cr :: res);
    
    // anything else, just handle the rest
    case (_ :: xs)
      equation
        res = getInsideFlowVariables2(xs);
      then
        res;

    case (xs)
      equation 
        true = RTOpts.debugFlag("failtrace");
        str = Util.stringDelimitList(Util.listMap(xs, printFlowRefStr), ", ");
        str = Util.stringAppendList({"flow set: {", str, "}"});
        Debug.traceln("- ConnectUtil.getInnerFlowVariables2 failed on list: " +& str);
      then 
        fail();
  end matchcontinue;
end getInsideFlowVariables2;

protected function getOutsideFlowVariables "function: getOutsideFlowVariables
  Get all flow variables that are outer variables from the Connect.Sets."
  input Connect.Sets inSets;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inSets)
    local
      list<DAE.ComponentRef> res1,res2,res,crs,dc;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> vars;
      list<Connect.Set> xs;
      list<Connect.OuterConnect> outerConn;
    case (Connect.SETS(setLst = {})) then {};
    case (Connect.SETS((Connect.FLOW(tplExpComponentRefFaceLst = vars) :: xs),crs,dc,outerConn))
      equation
        res1 = getOutsideFlowVariables2(vars);
        res2 = getOutsideFlowVariables(Connect.SETS(xs,crs,dc,outerConn));
        res = listAppend(res1, res2);
      then
        res;
    case (Connect.SETS((Connect.EQU(expComponentRefLst = _) :: xs),crs,dc,outerConn))
      equation
        res = getOutsideFlowVariables(Connect.SETS(xs,crs,dc,outerConn));
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_outer_flow_variables failed\\n\") */  then fail();
  end matchcontinue;
end getOutsideFlowVariables;

protected function getOutsideFlowVariables2 "function: getOutsideFlowVariables2
  Help function to getOuterFlowVariables."
  input list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> inTplExpComponentRefFaceLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inTplExpComponentRefFaceLst)
    local
      list<DAE.ComponentRef> res;
      DAE.ComponentRef cr;
      list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> xs;
    case ({}) then {};
    case ((cr,Connect.OUTSIDE(),_) :: xs)
      equation
        res = getOutsideFlowVariables2(xs);
      then
        (cr :: res);
    case (_ :: xs)
      equation
        res = getOutsideFlowVariables2(xs);
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_outer_flow_variables_2 failed\\n\") */  then fail();
  end matchcontinue;
end getOutsideFlowVariables2;

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
  input tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource> inTplExpComponentRefFace;
algorithm
  Print.printBuf(printFlowRefStr(inTplExpComponentRefFace));
end printFlowRef;

protected function printStreamRef
  input tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource> inTplExpComponentRefFace;
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
        res = Util.stringAppendList({"Connect.SETS(\n\t",
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
      list<tuple<DAE.ComponentRef, DAE.ElementSource>> cs;
    case Connect.EQU(expComponentRefLst = cs)
      equation
        strs = Util.listMap(Util.listMap(cs, Util.tuple21), Exp.printComponentRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = Util.stringAppendList({"\n\tnon-flow set: {",s1,"}"});
      then
        res;
    case Connect.FLOW(tplExpComponentRefFaceLst = cs)
      local list<tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource>> cs;
      equation
        strs = Util.listMap(cs, printFlowRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = Util.stringAppendList({"\n\tflow set: {",s1,"}"});
      then
        res;
    case Connect.STREAM(tplExpComponentRefFaceLst = cs)
      local list<tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource>> cs;
      equation
        strs = Util.listMap(cs, printStreamRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = Util.stringAppendList({"\n\tstream set: {",s1,"}"});
      then
        res;        
  end matchcontinue;
end printSetStr;

public function printFlowRefStr
  input tuple<DAE.ComponentRef, Connect.Face, DAE.ElementSource> inTplExpComponentRefFace;
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
  input tuple<DAE.ComponentRef, Option<DAE.ComponentRef>, Connect.Face, DAE.ElementSource> inTplExpComponentRefFace;
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
  res := Util.stringAppendList({"connect crs: {",s,"}"});
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
         = Lookup.lookupVar(Env.emptyCache(),env,DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}));
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
  lsit3 := matchcontinue(list1,list2)
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

public function localOutsideConnectorFlowvars "function: localOutsideConnectorFlowvars
  Return the outside connector variables that are flow in the local scope."
  input Env inEnv;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inEnv)
    local
      list<DAE.ComponentRef> res;
      Option<DAE.Ident> sid;
      AvlTree ht;
    case ((Env.FRAME(optName = sid,clsAndVars = ht) :: _))
      equation
        res = localOutsideConnectorFlowvars2(SOME(ht));
      then
        res;
  end matchcontinue;
end localOutsideConnectorFlowvars;

protected function localOutsideConnectorFlowvars2 "function: localOutsideConnectorFlowvars2
  Helper function to localOutsideConnectorFlowvars"
  input Option<AvlTree> inBinTreeOption;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inBinTreeOption)
    local
      list<DAE.ComponentRef> lst1,lst2,lst3,res;
      DAE.Ident id;
      list<DAE.Var> vars;
      Option<AvlTree> l,r;
      Absyn.InnerOuter io;

    // no tree
    case (NONE) then {};

    // a CONNECTOR variable with inner outer, prefix all inside 
    // variables from its type with its id and return the list
    case (SOME(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(_,Env.VAR(DAE.TYPES_VAR(id,DAE.ATTR(innerOuter=io),_,
          (DAE.T_COMPLEX(ClassInf.CONNECTOR(_,_),vars,_,_),_),_,_),_,_,_))),_,l,r)))
      equation
        lst1 = localOutsideConnectorFlowvars2(l);
        lst2 = localOutsideConnectorFlowvars2(r);
        // make sure is not an outer?
        (_,false) = InnerOuter.innerOuterBooleans(io);
        lst3 = Types.flowVariables(vars, DAE.CREF_IDENT(id,DAE.ET_OTHER(),{}));
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    // follow left and right in the tree
    case (SOME(Env.AVLTREENODE(SOME(_),_,l,r)))
      equation
        lst1 = localOutsideConnectorFlowvars2(l);
        lst2 = localOutsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;
    case(_) then {};
  end matchcontinue;
end localOutsideConnectorFlowvars2;

public function localInsideConnectorFlowvars "function: localInsideConnectorFlowvars
  Returns the inside connector variables that are flow from the local scope."
  input Env inEnv;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inEnv)
    local
      list<DAE.ComponentRef> res;
      Option<DAE.Ident> sid;
      AvlTree ht;
    case ((Env.FRAME(optName = sid,clsAndVars = ht) :: _))
      equation
        res = localInsideConnectorFlowvars2(SOME(ht));
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars;

protected function localInsideConnectorFlowvars2 "function: localInsideConnectorFlowvars2
  Helper function to localInsideConnectorFlowvars"
  input Option<AvlTree> inBinTreeOption;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inBinTreeOption)
    local
      list<DAE.ComponentRef> lst1,lst2,res,lst3;
      DAE.Ident id;
      Option<AvlTree> l,r;
      list<DAE.Var> vars;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      Absyn.InnerOuter io;
      DAE.Dimension ad;
      DAE.Type at,tmpty,flatArrayType;
      DAE.Attributes tatr;
      Boolean b3;
      DAE.Binding bind;
      list<Integer> adims;
      list<DAE.Var> tvars;
      list<list<Integer>> indexIntegerLists;
      list<list<DAE.Subscript>> indexSubscriptLists;
      //list<DAE.ComponentRef> arrayComplex;
    
    // empty
    case (NONE) then {};

    // Case where we have an array, assumed indexed which contains complex types.
    case (SOME(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(_,
            Env.VAR(DAE.TYPES_VAR(id,(tatr as DAE.ATTR(innerOuter=io)),b3,
                    (tmpty as (DAE.T_ARRAY(ad,at),_)),bind,_),_,_,_))),_,l,r)))
      equation
        // make sure is not an outer
        (_,false) = InnerOuter.innerOuterBooleans(io);
        ((flatArrayType as (DAE.T_COMPLEX(_,tvars,_,_),_)),adims) = Types.flattenArrayType(tmpty);
        false = Types.isComplexConnector(flatArrayType);

        indexSubscriptLists = createSubs(listReverse(adims));

        lst1 = localInsideConnectorFlowvars3_2(tvars, id, indexSubscriptLists);
        lst2 = localInsideConnectorFlowvars2(l);
        lst3 = localInsideConnectorFlowvars2(r);
        res = Util.listFlatten({lst1,lst2,lst3});
        //print(" returning: " +& Util.stringDelimitList(Util.listMap(res,Exp.printComponentRefStr), ", ") +& "\n");
      then
        res;

    // If CONNECTOR then outside and not inside, skip..
    case (SOME(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(_,Env.VAR(DAE.TYPES_VAR(name=id,
          type_ = (DAE.T_COMPLEX(ClassInf.CONNECTOR(_,_),_,_,_),_)),_,_,_))),_,l,r)))  
      equation 
        lst1 = localInsideConnectorFlowvars2(l);
        lst2 = localInsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;

    // If OUTER, skip..
    case (SOME(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(_,Env.VAR(
          DAE.TYPES_VAR(name=id,attributes = DAE.ATTR(innerOuter=io),
          type_ = (DAE.T_COMPLEX(_,vars,_,_),_)),_,_,_))),_,l,r)))  
      equation
        (_,true) = InnerOuter.innerOuterBooleans(io);
        lst1 = localInsideConnectorFlowvars2(l);
        lst2 = localInsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;

    // ... else retrieve connectors as subcomponents
    case (SOME(Env.AVLTREENODE(SOME(Env.AVLTREEVALUE(_,Env.VAR(DAE.TYPES_VAR(id,_,_,
          (DAE.T_COMPLEX(_,vars,_,_),_),_,_),_,_,_))),_,l,r)))  
      equation 
        lst1 = localInsideConnectorFlowvars3(vars, id);
        lst2 = localInsideConnectorFlowvars2(l);
        lst3 = localInsideConnectorFlowvars2(r);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;

    case (SOME(Env.AVLTREENODE(_,_,l,r)))
      equation 
        lst1 = localInsideConnectorFlowvars2(l);
        lst2 = localInsideConnectorFlowvars2(r);
        res = listAppend(lst1, lst2);
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars2;

protected function localInsideConnectorFlowvars3 "function: localInsideConnectorFlowvars3
  Helper function to localInsideConnectorFlowvars2"
  input list<DAE.Var> inTypesVarLst;
  input DAE.Ident inIdent;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inTypesVarLst,inIdent)
    local
      list<DAE.ComponentRef> lst1,lst2,res;
      DAE.Ident id,oid,name;
      list<DAE.Var> vars,xs;
      Absyn.InnerOuter io;
      Boolean isExpandable;
      Absyn.Path path;
      DAE.Dimension ad;
      list<Integer> adims;
      list<DAE.Var> tvars;
      DAE.Type tmpty,flatArrayType;
      list<list<DAE.Subscript>> indexSubscriptLists;
      DAE.ComponentRef connectorRef;
      Boolean isExpandable;

    // empty case
    case ({},_) then {}; 

    // not outer connector
    case ((DAE.TYPES_VAR(name = id,attributes=DAE.ATTR(innerOuter=io),
           type_ = (DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(path= path, isExpandable = isExpandable),
                    complexVarLst = vars),_)) :: xs),oid)
      equation
        lst1 = localInsideConnectorFlowvars3(xs, oid);
        (_,false) = InnerOuter.innerOuterBooleans(io);
        // We set type unknown for inside connectors for the check of "unconnected connectors".
        lst2 = Types.flowVariables(vars, DAE.CREF_QUAL(oid,DAE.ET_COMPLEX(path,{},ClassInf.UNKNOWN(Absyn.IDENT("unk"))),{},
                                                           DAE.CREF_IDENT(id,DAE.ET_COMPLEX(path,{},
                                                           ClassInf.CONNECTOR(path,isExpandable)),{})));
        res = listAppend(lst1, lst2);
      then
        res;

    case ((DAE.TYPES_VAR(name = id,attributes=DAE.ATTR(innerOuter=io),type_ = (tmpty as (DAE.T_ARRAY(ad,_),_))) :: xs),oid)        
      equation 
        ((flatArrayType as (DAE.T_COMPLEX(ClassInf.CONNECTOR(path=path,isExpandable=isExpandable),tvars,_,_),_)),adims) = Types.flattenArrayType(tmpty);
        (_,false) = InnerOuter.innerOuterBooleans(io);
        true = Types.isComplexConnector(flatArrayType);
        indexSubscriptLists = createSubs(adims);
        lst1 = localInsideConnectorFlowvars3_2(tvars, id, indexSubscriptLists);
        connectorRef = DAE.CREF_QUAL(oid,DAE.ET_COMPLEX(path,{},ClassInf.UNKNOWN(Absyn.IDENT("unk"))),{},
                                     DAE.CREF_IDENT(id,DAE.ET_COMPLEX(path,{},ClassInf.CONNECTOR(path,isExpandable)),{}));
        lst1 = localInsideConnectorFlowvars3_3(tvars,connectorRef,indexSubscriptLists);
        //print(" Array refs: " +& Util.stringDelimitList(Util.listMap(lst1,Exp.printComponentRefStr),", ") +& "\n");
      then lst1;

    case ((_ :: xs),oid)
      equation
        res = localInsideConnectorFlowvars3(xs, oid);
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars3;

protected function localInsideConnectorFlowvars3_3 "
Author BZ, 2009-10
Helper function for localInsideConnectorFlowvars3, handles the case with inside array connectors"
  input list<DAE.Var> connectorSubs;
  input DAE.ComponentRef baseRef;
  input list<list<DAE.Subscript>> ssubs;
  output list<DAE.ComponentRef> outRefs;
algorithm outRefs := matchcontinue(connectorSubs,baseRef,ssubs)
  local
    list<DAE.Subscript> s;
    list<DAE.ComponentRef> lst1,lst2;
  case({},_,_) then {};
  case(_,_,{}) then {};
  case(connectorSubs,baseRef,s::ssubs)
    equation
      lst1 = localInsideConnectorFlowvars3_3(connectorSubs,baseRef,ssubs);
      baseRef = Exp.subscriptCref(baseRef,s);
      lst2 = Types.flowVariables(connectorSubs, baseRef);
      outRefs = listAppend(lst1,lst2);
      then
        outRefs;
  end matchcontinue;
end localInsideConnectorFlowvars3_3;

protected function localInsideConnectorFlowvars3_2 "
Author: BZ, 2009-05
Extract vars from complex types.
Helper function for array complex vars."
  input list<DAE.Var> inTypesVarLst;
  input DAE.Ident inIdent;
  input list<list<DAE.Subscript>> ssubs;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst := matchcontinue (inTypesVarLst,inIdent,ssubs)
    local
      list<DAE.ComponentRef> lst1,lst2,lst3,res;
      DAE.Ident id,oid,name;
      list<DAE.Var> vars,xs;
      Absyn.InnerOuter io;
      list<DAE.Subscript> s;
      DAE.Var tv;
      Boolean isExpandable;
      Absyn.Path path;
    case ({},_,_) then {};
    case (_,_,{}) then {};
    case (((tv as DAE.TYPES_VAR(name = id,attributes=DAE.ATTR(innerOuter=io),type_ =
           (DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(path = path, isExpandable = isExpandable),
                            complexVarLst = vars),_))) :: xs),oid,s::ssubs)
      equation
        lst3 = localInsideConnectorFlowvars3_2({tv},oid,ssubs);
        lst1 = localInsideConnectorFlowvars3_2(xs, oid,s::ssubs);
        (_,false) = InnerOuter.innerOuterBooleans(io);
        //lst2 = Types.flowVariables(vars, DAE.CREF_QUAL(oid,DAE.ET_COMPLEX(name,{},ClassInf.CONNECTOR(name)),s,DAE.CREF_IDENT(id,DAE.ET_COMPLEX(name,{},ClassInf.CONNECTOR(name)),{})));
        // We set type unknown for inside connectors for the check of "unconnected connectors".
        lst2 = Types.flowVariables(vars, DAE.CREF_QUAL(oid,DAE.ET_COMPLEX(path,{},
                                                           ClassInf.UNKNOWN(Absyn.IDENT("unk"))),s,
                                         DAE.CREF_IDENT(id,DAE.ET_COMPLEX(path,{},
                                                           ClassInf.CONNECTOR(path,isExpandable)),{})));
        res = Util.listFlatten({lst1, lst2,lst3});
      then
        res;
    case ((_ :: xs),oid,ssubs)
      equation
        //print(" **** FAILURE localInsideConnectorFlowvars3\n **** ");
        res = localInsideConnectorFlowvars3_2(xs, oid,ssubs);
      then
        res;
  end matchcontinue;
end localInsideConnectorFlowvars3_2;

protected function createSubs "
Author: BZ, 2009-05
Create subscripts from given integerlist of dimensions, ex
{2,3} => {1,1},{1,2},{1,3},{2,1},{2,2},{2,3}."
  input list<Integer> inInts;
  output list<list<DAE.Subscript>> osubs;
algorithm osubs := matchcontinue(inInts)
  local
    list<Integer> ints;
    Integer i;
    list<DAE.Subscript> localSubs;
  case({}) then {};
  case(i::inInts)
    equation
      osubs = createSubs(inInts);
      ints = Util.listIntRange(i);
      localSubs = Util.listMap(ints,integer2Subscript);
      osubs = createSubs2(localSubs,osubs);
       //_ = Util.listMap(osubs,dummyDump);
    then
      osubs;
end matchcontinue;
end createSubs;

protected function createSubs2
  input list<DAE.Subscript> s;
  input list<list<DAE.Subscript>> subs;
  output list<list<DAE.Subscript>> osubs;
algorithm osubs := matchcontinue(s,subs)
  local
    list<DAE.Subscript> lsubs;
    list<list<DAE.Subscript>> lssubs;
    DAE.Subscript sub;
    case({},_) then {};
    case(sub::s,{}) // base case
    equation
      osubs = createSubs2(s,{});
      then
        {sub}::osubs;
  case(sub::s,subs)
    equation
      lssubs = createSubs3(sub,subs);
      osubs = createSubs2(s,subs);
      osubs = listAppend(lssubs,osubs);
      then
         osubs;
  end matchcontinue;
end createSubs2;

protected function createSubs3
  input DAE.Subscript s;
  input list<list<DAE.Subscript>> subs;
  output list<list<DAE.Subscript>> osubs;
algorithm osubs := matchcontinue(s,subs)
  local
    list<DAE.Subscript> lsubs;
    case(_,{}) then {};
  case(s,lsubs::subs)
    equation
      osubs = createSubs3(s,subs);
      lsubs = listAppend({s},lsubs);
      then
         lsubs::osubs;
  end matchcontinue;
end createSubs3;

end ConnectUtil;


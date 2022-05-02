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
encapsulated package InnerOuter
" file:        InnerOuter.mo
  package:     InnerOuter
  description: Instance hierarchy and functionality to deal with Inner/Outer definitions"


import Absyn;
import DAE.Connect;
import ConnectionGraph;
import DAE;
import FCore;
import FNode;
import SCode;
import UnitAbsyn;
import HashSet;

protected import Array;
protected import ComponentReference;
protected import ConnectUtil;
protected import DAEUtil;
protected import Debug;
protected import ElementSource;
protected import Error;
protected import ErrorExt;
protected import Flags;
protected import InstSection;
protected import List;
protected import Lookup;
protected import Mod;
protected import PrefixUtil;
protected import Util;
protected import BaseHashSet;
protected import FGraph;

public
type Cache     = FCore.Cache;

uniontype InstResult
  record INST_RESULT
    Cache outCache;
    FCore.Graph outEnv;
    UnitAbsyn.InstStore outStore;
    DAE.DAElist outDae;
    Connect.Sets outSets;
    DAE.Type outType;
    ConnectionGraph.ConnectionGraph outGraph;
  end INST_RESULT;
end InstResult;

uniontype InstInner
  record INST_INNER
    DAE.Prefix innerPrefix "the prefix of the inner. we need it to prefix the outer variables with it!";
    SCode.Ident name;
    Absyn.InnerOuter io;
    String fullName "full inner component name";
    Absyn.Path typePath "the type of the inner";
    String scope "the scope of the inner";
    Option<InstResult> instResult;
    list<DAE.ComponentRef> outers "which outers are referencing this inner";
    Option<SCode.Element> innerElement "class or component";
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
    HashSet.HashSet sm "Set of synchronous SM states (fully qualified components)";
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
  input DAE.DAElist inDae;
  input InstHierarchy inIH;
  input ConnectionGraph.ConnectionGraph inGraphNew;
  input ConnectionGraph.ConnectionGraph inGraph;
  output DAE.DAElist odae;
  output InstHierarchy outIH;
  output ConnectionGraph.ConnectionGraph outGraph;
algorithm
  (odae,outIH,outGraph) := matchcontinue(io,inDae,inIH,inGraphNew,inGraph)
    local
      DAE.DAElist dae1,dae2,dae;
      ConnectionGraph.ConnectionGraph graphNew,graph;
      InstHierarchy ih;
    // is an outer, remove equations
    // outer components do NOT change the connection graph!
    case (Absyn.OUTER(),dae,ih,_,graph)
      equation
        (odae,_) = DAEUtil.splitDAEIntoVarsAndEquations(dae);
      then
        (odae,ih,graph);
    // is both an inner and an outer,
    // rename inner vars in the equations to unique names
    // innerouter component change the connection graph
    case (Absyn.INNER_OUTER(),dae,ih,_,graph)
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
    case (Absyn.INNER(),dae,ih,graphNew,_) then (dae,ih,graphNew);
    // is not an inner nor an outer
    case (Absyn.NOT_INNER_OUTER (),dae,ih,graphNew,_) then (dae,ih,graphNew);
    // something went totally wrong!
    else
      equation
        print("- InnerOuter.handleInnerOuterEquations failed!\n");
      then fail();
  end matchcontinue;
end handleInnerOuterEquations;

public function changeInnerOuterInOuterConnect
  "changes inner to outer and outer to inner where needed"
  input output Connect.Sets sets;
algorithm
  sets.outerConnects := List.map(sets.outerConnects, changeInnerOuterInOuterConnect2);
end changeInnerOuterInOuterConnect;

protected function changeInnerOuterInOuterConnect2
"@author: adrpo
  changes inner to outer and outer to inner where needed"
  input Connect.OuterConnect inOC;
  output Connect.OuterConnect outOC;
algorithm
  outOC := matchcontinue(inOC)
    local
      DAE.ComponentRef cr1,cr2,ncr1,ncr2;
      Absyn.InnerOuter io1,io2;
      Connect.Face f1,f2;
      DAE.Prefix scope;
      DAE.ElementSource source "the origin of the element";

    // the left hand side is an outer!
    case Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)
      equation
        (_,true) = innerOuterBooleans(io1);
        ncr1 = PrefixUtil.prefixToCref(scope);
        // fprintln(Flags.IOS, "changeInnerOuterInOuterConnect: changing left: " +
        //   ComponentReference.printComponentRefStr(cr1) + " to inner");
        false = ComponentReference.crefFirstCrefLastCrefEqual(ncr1,cr1);
      then
        Connect.OUTERCONNECT(scope,cr1,Absyn.INNER(),f1,cr2,io2,f2,source);

    // the right hand side is an outer!
    case Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,io2,f2,source)
      equation
        (_,true) = innerOuterBooleans(io2);
        ncr2 = PrefixUtil.prefixToCref(scope);
        // fprintln(Flags.IOS, "changeInnerOuterInOuterConnect: changing right: " +
        //   ComponentReference.printComponentRefStr(cr2) + " to inner");
        false = ComponentReference.crefFirstCrefLastCrefEqual(ncr2,cr2);
      then
        Connect.OUTERCONNECT(scope,cr1,io1,f1,cr2,Absyn.INNER(),f2,source);

    // none of left or right hand side are outer
    else inOC;
  end matchcontinue;
end changeInnerOuterInOuterConnect2;

public function retrieveOuterConnections
"Moves outerConnections to connection sets
 author PA:
 This function moves the connections put in outerConnects to the connection
 set, if a corresponding innner component can be found in the environment.
 If not, they are kept in the outerConnects for use higher up in the instance
 hierarchy."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstHierarchy inIH;
  input DAE.Prefix inPrefix;
  input Connect.Sets inSets;
  input Boolean inTopCall;
  input ConnectionGraph.ConnectionGraph inCGraph;
  output Connect.Sets outSets;
  output list<Connect.OuterConnect> outInnerOuterConnects;
  output ConnectionGraph.ConnectionGraph outCGraph;
protected
  list<Connect.OuterConnect> oc;
algorithm
  Connect.SETS(outerConnects = oc) := inSets;
  (oc, outSets, outInnerOuterConnects, outCGraph) :=
    retrieveOuterConnections2(inCache, inEnv, inIH, inPrefix, oc, inSets, inTopCall, inCGraph);
  outSets.outerConnects := oc;
end retrieveOuterConnections;

protected function removeInnerPrefixFromCref
"@author: adrpo
 This function will strip the given prefix from the component references."
 input DAE.Prefix inPrefix;
 input DAE.ComponentRef inCref;
 output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inPrefix, inCref)
    local
      DAE.ComponentRef crefPrefix, crOuter;

    // no prefix to strip, return the cref!
    case (DAE.NOPRE(),_) then inCref;

    // we have a prefix, remove it from the cref
    case (_, _)
      equation
        // transform prefix into cref
        crefPrefix = PrefixUtil.prefixToCref(inPrefix);
        // remove the prefix from the component reference
        crOuter = ComponentReference.crefStripPrefix(inCref, crefPrefix);
      then
        crOuter;

    // something went wrong, print a failtrace and then
    else
      equation
        //true = Flags.isSet(Flags.FAILTRACE);
        //Debug.traceln("- InnerOuter.removeInnerPrefixFromCref failed on prefix: " + PrefixUtil.printPrefixStr(inPrefix) +
        // " cref: " + ComponentReference.printComponentRefStr(inCref));
      then
        inCref;
  end matchcontinue;
end removeInnerPrefixFromCref;

protected function retrieveOuterConnections2
"help function to retrieveOuterConnections"
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstHierarchy inIH;
  input DAE.Prefix inPrefix;
  input list<Connect.OuterConnect> inOuterConnects;
  input Connect.Sets inSets;
  input Boolean inTopCall;
  input ConnectionGraph.ConnectionGraph inCGraph;
  output list<Connect.OuterConnect> outOuterConnects;
  output Connect.Sets outSets;
  output list<Connect.OuterConnect> outInnerOuterConnects;
  output ConnectionGraph.ConnectionGraph outCGraph;
algorithm
  (outOuterConnects, outSets, outInnerOuterConnects, outCGraph) :=
  matchcontinue(inCache, inEnv, inIH, inPrefix, inOuterConnects, inSets, inTopCall, inCGraph)
    local
      DAE.ComponentRef cr1, cr2;
      Absyn.InnerOuter io1, io2;
      Connect.Face f1, f2;
      Connect.OuterConnect oc;
      list<Connect.OuterConnect> rest_oc, ioc;
      Boolean inner1, inner2, outer1, outer2, added;
      DAE.Prefix scope;
      DAE.ElementSource source "the origin of the element";
      SourceInfo info;
      Connect.Sets sets;
      ConnectionGraph.ConnectionGraph graph;

    // handle empty
    case (_, _, _, _, {}, _, _, _) then (inOuterConnects, inSets, {}, inCGraph);

    // an inner only outer connect
    case(_, _, _, _, Connect.OUTERCONNECT(scope, cr1, io1, f1, cr2, io2, f2,
        source as DAE.SOURCE(info = info)) :: rest_oc, sets, _, graph)
      equation
        (inner1, outer1) = lookupVarInnerOuterAttr(inCache, inEnv, inIH, cr1, cr2);

        true = inner1;
        false = outer1;

        // remove the prefixes so we can find it in the DAE
        cr1 = removeInnerPrefixFromCref(inPrefix, cr1);
        cr2 = removeInnerPrefixFromCref(inPrefix, cr2);

        (sets, added) = ConnectUtil.addOuterConnectToSets(cr1, cr2, io1, io2, f1, f2, sets, info);

        // if no connection set available (added = false), create new one
        (sets, graph) = addOuterConnectIfEmpty(inCache, inEnv, inIH, inPrefix, sets,
          added, cr1, io1, f1, cr2, io2, f2, info, graph);

        (rest_oc, sets, ioc, graph) =
          retrieveOuterConnections2(inCache, inEnv, inIH, inPrefix, rest_oc, sets, inTopCall, graph);

        // if is also outer, then keep it also in the outer connects
        rest_oc = if outer1 then Connect.OUTERCONNECT(scope, cr1, io1, f1, cr2, io2, f2, source) :: rest_oc else rest_oc;
      then
        (rest_oc, sets, ioc, graph);

    // this case is for innerouter declarations, since we do not have them in environment we need to treat them in a special way
    case(_, _, _, _, Connect.OUTERCONNECT(_, cr1, io1, f1, cr2, io2, f2,
        DAE.SOURCE(info = info)) :: rest_oc, sets, true, graph)
      equation
        (inner1, outer1) = innerOuterBooleans(io1);
        (inner2, outer2) = innerOuterBooleans(io2);
        true = boolOr(inner1, inner2); // for inner outer we set Absyn.INNER()
        false = boolOr(outer1, outer2);

        io1 = convertInnerOuterInnerToOuter(io1); // we need to change from inner to outer to be able to join sets in: addOuterConnectToSets
        io2 = convertInnerOuterInnerToOuter(io2);

        (sets, added) = ConnectUtil.addOuterConnectToSets(cr1, cr2, io1, io2, f1, f2, sets, info);
        // If no connection set available (added = false), create new one
        (sets, graph) = addOuterConnectIfEmpty(inCache, inEnv, inIH, inPrefix, sets,
          added, cr1, io1, f1, cr2, io2, f2, info, graph);
        (rest_oc, sets, ioc, graph) =
          retrieveOuterConnections2(inCache, inEnv, inIH, inPrefix, rest_oc, sets, true, graph);
      then
        (rest_oc, sets, ioc, graph);

    // just keep the outer connects the same if we don't find them in the same scope
    case(_, _, _, _, oc :: rest_oc, sets, _, graph)
      equation
        (rest_oc, sets, ioc, graph) =
          retrieveOuterConnections2(inCache, inEnv, inIH, inPrefix, rest_oc, sets, inTopCall, graph);
      then
        (oc :: rest_oc, sets, ioc, graph);
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
  oio := match(io)
    case(Absyn.INNER()) then Absyn.OUTER();
    else io;
  end match;
end convertInnerOuterInnerToOuter;

protected function addOuterConnectIfEmpty
"help function to retrieveOuterConnections2
 author PA.
 Adds a new connectionset if inner component
 found but no connection set refering to the
 inner component. In that is case the outer
 connection (from inside sub-components) forms
 a connection set of their own."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input InstHierarchy inIH;
  input DAE.Prefix pre;
  input Connect.Sets inSets;
  input Boolean added "if true, this function does nothing";
  input DAE.ComponentRef cr1;
  input Absyn.InnerOuter iio1;
  input Connect.Face f1;
  input DAE.ComponentRef cr2;
  input Absyn.InnerOuter iio2;
  input Connect.Face f2;
  input SourceInfo info;
  input ConnectionGraph.ConnectionGraph inCGraph;
  output Connect.Sets outSets;
  output ConnectionGraph.ConnectionGraph outCGraph;
algorithm
  (outSets, outCGraph) := match(inCache,inEnv,inIH,pre,inSets,added,cr1,iio1,f1,cr2,iio2,f2,info,inCGraph)
     local
       SCode.Variability vt1,vt2;
       DAE.Type t1,t2;
       DAE.ConnectorType ct;
       DAE.DAElist dae;
       InstHierarchy ih;
       Connect.SetTrie sets;
       Integer sc;
       list<Connect.SetConnection> cl;
       list<Connect.OuterConnect> oc;
       FCore.Cache cache;
       FCore.Graph env;
       Absyn.InnerOuter io1,io2;
       ConnectionGraph.ConnectionGraph graph;

    // if it was added, return the same
    case(_,_,_,_,_,true,_,_,_,_,_,_,_,_)
      then (inSets, inCGraph);

    // if it was not added, add it (search for both components)
    case(cache,env,ih,_, Connect.SETS(sets, sc, cl, oc),false,_,io1,_,_,io2,_,_, graph)
      equation
        (cache,DAE.ATTR(connectorType = ct, variability = vt1),t1,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        (cache,DAE.ATTR(variability = vt2),t2,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        io1 = removeOuter(io1);
        io2 = removeOuter(io2);
        (cache,env,ih, Connect.SETS(sets = sets, setCount = sc, connections = cl),_, graph) =
          InstSection.connectComponents(
            cache,env,ih,
            Connect.SETS(sets, sc, cl, {}),
            pre,cr1,f1,t1,vt1,cr2,f2,t2,vt2,ct,io1,io2,
            graph,info);
        // TODO: take care of dae, can contain asserts from connections
      then
        (Connect.SETS(sets, sc, cl, oc), graph);

    // This can fail, for innerouter, the inner part is not declared in env so instead the call to addOuterConnectIfEmptyNoEnv will succed.
    else
      equation
        //print("Failed lookup: " + ComponentReference.printComponentRefStr(cr1) + "\n");
        //print("Failed lookup: " + ComponentReference.printComponentRefStr(cr2) + "\n");
        // print("#FAILURE# in: addOuterConnectIfEmpty:__ " + ComponentReference.printComponentRefStr(cr1) + " " + ComponentReference.printComponentRefStr(cr2) + "\n");
      then fail();

  end match;
end addOuterConnectIfEmpty;

protected function removeOuter
"Removes outer attribute, keeping inner"
  input Absyn.InnerOuter io;
  output Absyn.InnerOuter outIo;
algorithm
  outIo := match(io)
    case(Absyn.OUTER())           then Absyn.NOT_INNER_OUTER();
    case(Absyn.INNER())           then Absyn.INNER();
    case(Absyn.INNER_OUTER())     then Absyn.INNER();
    case(Absyn.NOT_INNER_OUTER()) then Absyn.NOT_INNER_OUTER();
  end match;
end removeOuter;

protected function lookupVarInnerOuterAttr
"searches for two variables in env and retrieves
 its inner and outer attributes in form of booleans.
 adrpo: Make sure that there are no error messages displayed!"
  input FCore.Cache cache;
  input FCore.Graph env;
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
    case(_,_,_,_,_)
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
    case(_,_,_,_,_)
      equation
        (_,DAE.ATTR(innerOuter=io),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr1);
        (isInner,isOuter) = innerOuterBooleans(io);
        ErrorExt.rollBack("lookupVarInnerOuterAttr");
      then
        (isInner,isOuter);
     // ..else try cr2 (lookup can fail for one of them)
    case(_,_,_,_,_)
      equation
        (_,DAE.ATTR(innerOuter=io),_,_,_,_,_,_,_) = Lookup.lookupVar(cache,env,cr2);
        (isInner,isOuter) = innerOuterBooleans(io);
        ErrorExt.rollBack("lookupVarInnerOuterAttr");
      then (isInner,isOuter);
     // failure
    else
      equation
        ErrorExt.rollBack("lookupVarInnerOuterAttr");
      then fail();
  end matchcontinue;
end lookupVarInnerOuterAttr;

protected function innerOuterBooleans
"Returns inner outer information as two booleans"
  input Absyn.InnerOuter io;
  output Boolean inner1;
  output Boolean outer1;
algorithm
  (inner1,outer1) := match(io)
    case(Absyn.INNER()) then (true,false);
    case(Absyn.OUTER()) then (false,true);
    case(Absyn.INNER_OUTER()) then (true,true);
    case(Absyn.NOT_INNER_OUTER()) then (false,false);
  end match;
end innerOuterBooleans;

public function outerConnection "Returns true if either Absyn.InnerOuter is OUTER."
  input Absyn.InnerOuter io1;
  input Absyn.InnerOuter io2;
  output Boolean isOuter;
algorithm
  isOuter := match(io1,io2)
    case(Absyn.OUTER(),_) then true;
    case(_,Absyn.OUTER()) then true;
    case(Absyn.INNER_OUTER(),_) then true;
    case(_,Absyn.INNER_OUTER()) then true;
    else false;
  end match;
end outerConnection;

protected function lookupInnerInIH
"@author: adrpo
 Given an instance hierarchy and a component name find the
 modification of the inner component with the same name"
 input TopInstance inTIH;
 input DAE.Prefix inPrefix;
 input SCode.Ident inComponentIdent;
 output InstInner outInstInner;
algorithm
  (outInstInner) := matchcontinue(inTIH, inPrefix, inComponentIdent)
    local
      SCode.Ident name;
      DAE.Prefix prefix;
      InstHierarchyHashTable ht;
      DAE.ComponentRef cref;
      InstInner instInner;
      OuterPrefixes outerPrefixes;

    // no prefix, this is an error!
    // disabled as this is used in Interactive.getComponents
    // and makes mosfiles/interactive_api_attributes.mos to fail!
    case (TOP_INSTANCE(), DAE.PREFIX(compPre = DAE.NOCOMPPRE()),  _)
      then lookupInnerInIH(inTIH, DAE.NOPRE(), inComponentIdent);

    // no prefix, this is an error!
    // disabled as this is used in Interactive.getComponents
    // and makes mosfiles/interactive_api_attributes.mos to fail!
    case (TOP_INSTANCE(), DAE.NOPRE(),  name)
      equation
        // fprintln(Flags.INNER_OUTER, "Error: outer component: " + name + " defined at the top level!");
        // fprintln(Flags.INNER_OUTER, "InnerOuter.lookupInnerInIH : looking for: " + PrefixUtil.printPrefixStr(DAE.NOPRE()) + "/" + name + " REACHED TOP LEVEL!");
        // TODO! add warning!
      then emptyInstInner(DAE.NOPRE(), name);

    // we have a prefix, remove the last cref from the prefix and search!
    case (TOP_INSTANCE(_, ht, _, _), _,  name)
      equation
        // back one step in the instance hierarchy

        // fprintln(Flags.INNER_OUTER, "InnerOuter.lookupInnerInIH : looking for: " + PrefixUtil.printPrefixStr(inPrefix) + "/" + name);

        prefix = PrefixUtil.prefixStripLast(inPrefix);

        // fprintln(Flags.INNER_OUTER, "InnerOuter.lookupInnerInIH : stripping and looking for: " + PrefixUtil.printPrefixStr(prefix) + "/" + name);

        // put the name as the last prefix
        (_,cref) = PrefixUtil.prefixCref(FCore.emptyCache(), FGraph.empty(), emptyInstHierarchy, prefix, ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {}));

        // search in instance hierarchy
        instInner = get(cref, ht);

        // isInner = AbsynUtil.isInner(io);
        // instInner = if_(isInner, instInner, emptyInstInner(inPrefix, name));
        // fprintln(Flags.INNER_OUTER, "InnerOuter.lookupInnerInIH : Looking up: " +
        //  ComponentReference.printComponentRefStr(cref) + " FOUND with innerPrefix: " +
        //  PrefixUtil.printPrefixStr(innerPrefix));
      then
        instInner;

    // we have a prefix, search recursively as there was a failure before!
    case (TOP_INSTANCE(_, ht, _, _), _,  name)
      equation
        // back one step in the instance hierarchy
        // fprintln(Flags.INNER_OUTER, "InnerOuter.lookupInnerInIH : looking for: " + PrefixUtil.printPrefixStr(inPrefix) + "/" + name);

        prefix = PrefixUtil.prefixStripLast(inPrefix);

        // fprintln(Flags.INNER_OUTER, "InnerOuter.lookupInnerInIH : stripping and looking for: " + PrefixUtil.printPrefixStr(prefix) + "/" + name);

        // put the name as the last prefix
        (_,cref) = PrefixUtil.prefixCref(FCore.emptyCache(), FGraph.empty(), emptyInstHierarchy, prefix, ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {}));

        // search in instance hierarchy we had a failure
        failure(_ = get(cref, ht));

        // fprintln(Flags.INNER_OUTER, "InnerOuter.lookupInnerInIH : Couldn't find: " + ComponentReference.printComponentRefStr(cref) + " going deeper");

        // call recursively to back one more step!
        instInner = lookupInnerInIH(inTIH, prefix, name);
      then
        instInner;

    // if we fail return nothing
    case (TOP_INSTANCE(), prefix, name)
      equation
        // fprintln(Flags.INNER_OUTER, "InnerOuter.lookupInnerInIH : looking for: " + PrefixUtil.printPrefixStr(prefix) + "/" + name + " NOT FOUND!");
        // dumpInstHierarchyHashTable(ht);
      then
        emptyInstInner(prefix, name);
  end matchcontinue;
end lookupInnerInIH;

public function modificationOnOuter "
Author BZ, 2008-11
According to specification modifiers on outer elements is not allowed."
  input FCore.Cache cache;
  input FCore.Graph env;
  input InstHierarchy ih;
  input DAE.Prefix prefix;
  input String componentName;
  input DAE.ComponentRef cr;
  input DAE.Mod inMod;
  input Absyn.InnerOuter io;
  input Boolean impl;
  input SourceInfo inInfo;
  output Boolean modd;
algorithm
  modd := matchcontinue(cache,env,ih,prefix,componentName,cr,inMod,io,impl,inInfo)
    local
      String s1,s2,s;
    // if we don't have the same modification on inner report error!
    case(_,_,_,_,_,_,DAE.MOD(),Absyn.OUTER(),_,_)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = Mod.prettyPrintMod(inMod, 0);
        s = s1 +  " " + s2;
        Error.addSourceMessage(Error.OUTER_MODIFICATION, {s}, inInfo);
      then
        true;

    else false;

  end matchcontinue;
end modificationOnOuter;

public function switchInnerToOuterInGraph
  "function switchInnerToOuterInGraph switches the inner to outer attributes of
   a component in the Env."
  input FCore.Graph inEnv;
  input DAE.ComponentRef inCr;
  output FCore.Graph outEnv;
algorithm
  outEnv := match(inEnv,inCr)
    local
      FCore.Graph envIn,  envRest;
      DAE.ComponentRef cr;
      FCore.Ref r;
      FCore.Node n;
    // handle nothingness
    case (FCore.EG(_), _) then inEnv;
    case (FCore.G(scope = {}), _) then inEnv;
    // only need to handle top frame!
    case (_, cr)
      equation
        r = FGraph.lastScopeRef(inEnv);
        n = FNode.fromRef(r);
        n = switchInnerToOuterInNode(n, cr);
        r = FNode.updateRef(r, n);
      then
        inEnv;
  end match;
end switchInnerToOuterInGraph;

protected function switchInnerToOuterInNode "
function switchInnerToOuterInFrame
  switches the inner to outer attributes of a component in the Frame."
  input FCore.Node inNode;
  input DAE.ComponentRef inCr;
  output FCore.Node outNode = inNode;
algorithm
  _ := match outNode
    case FCore.N()
      algorithm
        outNode.children := FNode.RefTree.map(outNode.children,
          function switchInnerToOuterInChild(cr = inCr));
      then
        ();

    else ();
  end match;
end switchInnerToOuterInNode;

protected function switchInnerToOuterInChild
  input FCore.Name name;
  input DAE.ComponentRef cr;
  input FCore.Ref inRef;
  output FCore.Ref ref;
protected
  FCore.Node n;
algorithm
  n := FNode.fromRef(inRef);
  n := switchInnerToOuterInChildrenValue(n, cr);
  ref := FNode.updateRef(inRef, n);
end switchInnerToOuterInChild;

protected function switchInnerToOuterInChildrenValue "
function switchInnerToOuterInChildrenValue
  switches the inner to outer attributes of a component in the RefTree."
  input FCore.Node inNode;
  input DAE.ComponentRef inCr;
  output FCore.Node outNode;
algorithm
  outNode := matchcontinue(inNode,inCr)
    local
      DAE.ComponentRef cr;
      FCore.Ref r;
      FCore.Node node;

      DAE.Ident name;
      DAE.Attributes attributes;
      SCode.Visibility visibility;
      DAE.Type ty;
      DAE.Binding binding;
      Boolean bndsrc;

      DAE.ConnectorType ct;
      SCode.Parallelism parallelism "parallelism";
      SCode.Variability variability "variability" ;
      Absyn.Direction direction "direction" ;
      Option<DAE.Const> cnstForRange;

    // inner
    case (node, _)
      equation
        // get the instance child
        r = FNode.childFromNode(node, FNode.itNodeName);
        FCore.IT(DAE.TYPES_VAR(name, attributes, ty, binding, bndsrc, cnstForRange)) = FNode.refData(r);
        DAE.ATTR(ct, parallelism, variability, direction, Absyn.INNER(), visibility) = attributes;
        attributes = DAE.ATTR(ct, parallelism, variability, direction, Absyn.OUTER(), visibility);
        // update the ref
        r = FNode.updateRef(r, FNode.setData(FNode.fromRef(r),FCore.IT(DAE.TYPES_VAR(name, attributes, ty, binding, bndsrc, cnstForRange))));
        // env = switchInnerToOuterInGraph(env, inCr);
      then
        node;

    // inner outer
    case (node, _)
      equation
        // get the instance child
        r = FNode.childFromNode(node, FNode.itNodeName);
        FCore.IT(DAE.TYPES_VAR(name, attributes, ty, binding, bndsrc, cnstForRange)) = FNode.refData(r);
        DAE.ATTR(ct, parallelism, variability, direction, Absyn.INNER_OUTER(), visibility) = attributes;
        attributes = DAE.ATTR(ct, parallelism, variability, direction, Absyn.OUTER(), visibility);
        // update the ref
        r = FNode.updateRef(r, FNode.setData(FNode.fromRef(r),FCore.IT(DAE.TYPES_VAR(name, attributes, ty, binding, bndsrc, cnstForRange))));
        // env = switchInnerToOuterInGraph(env, inCr);
      then
        node;

    // leave unchanged
    case (_, _) then inNode;

  end matchcontinue;
end switchInnerToOuterInChildrenValue;


///////////////////////////////////////////////////
/// instance hieararchy for inner/outer
/// add furher functions before this
///////////////////////////////////////////////////


protected function emptyInstInner
  input DAE.Prefix innerPrefix;
  input String name;
  output InstInner outInstInner;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outInstInner := INST_INNER(innerPrefix, name, Absyn.NOT_INNER_OUTER(), "", Absyn.IDENT(""), "", NONE(), {}, NONE());
end emptyInstInner;

public function lookupInnerVar
"@author: adrpo
 This function lookups the result of instatiation of the inner
 component given an instance hierarchy a prefix and a component name."
  input Cache inCache;
  input FCore.Graph inEnv;
  input InstHierarchy inIH;
  input DAE.Prefix inPrefix;
  input SCode.Ident inIdent;
  input Absyn.InnerOuter io;
  output InstInner outInstInner;
algorithm
  (outInstInner) := matchcontinue (inCache,inEnv,inIH,inPrefix,inIdent,io)
    local
      Cache cache;
      String n;
      FCore.Graph env;
      DAE.Prefix pre;
      TopInstance tih;
      InstInner instInner;

    // adrpo: if component is an outer or an inner/outer we need to
    //        lookup the modification of the inner component and use it
    //        when we instantiate the outer component
    case (_,_,tih::_,pre,n,_)
      equation
        // is component an outer or an inner/outer?
        //true = AbsynUtil.isOuter(io);  // is outer
        //false = AbsynUtil.isInner(io); // and is not inner
        // search the instance hierarchy for the inner component
        instInner = lookupInnerInIH(tih, pre, n);
      then
        instInner;

    // failure in case we look for anything else but outer!
    case (_,_,_,pre,n,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("InnerOuter.lookupInnerVar failed on component: " + PrefixUtil.printPrefixStr(pre) + "/" + n);
      then
        fail();
  end matchcontinue;
end lookupInnerVar;

public function updateInstHierarchy
"@author: adrpo
 This function updates the instance hierarchy by adding
 the INNER components to it with the given prefix"
  input InstHierarchy inIH;
  input DAE.Prefix inPrefix;
  input Absyn.InnerOuter inInnerOuter;
  input InstInner inInstInner;
  output InstHierarchy outIH;
algorithm
  outIH := match(inIH,inPrefix,inInnerOuter,inInstInner)
    local
      TopInstance tih;
      InstHierarchy restIH, ih;
      DAE.ComponentRef cref;
      SCode.Ident name;
      Absyn.InnerOuter io;
      InstHierarchyHashTable ht;
      Option<Absyn.Path> pathOpt;
      OuterPrefixes outerPrefixes;
      DAE.ComponentRef cref_;
      HashSet.HashSet sm;

    /* only add inner elements
    case(ih,inPrefix,inInnerOuter,inInstInner as INST_INNER(name=name))
      equation
        false = AbsynUtil.isInner(inInnerOuter);
        // prefix the name!
        (_,cref) = PrefixUtil.prefixCref(FCore.emptyCache(),{},emptyInstHierarchy,inPrefix, ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {}));
        // print ("InnerOuter.updateInstHierarchy jumping over non-inner: " + ComponentReference.printComponentRefStr(cref) + "\n");
      then
        ih;*/

    // no hashtable, create one!
    case({},_,_,INST_INNER())
      equation
        // print ("InnerOuter.updateInstHierarchy creating an empty hash table! \n");
        ht = emptyInstHierarchyHashTable();
        sm = HashSet.emptyHashSet();
        tih = TOP_INSTANCE(NONE(), ht, emptyOuterPrefixes, sm);
        ih = updateInstHierarchy({tih}, inPrefix, inInnerOuter, inInstInner);
      then
        ih;

    // add to the hierarchy
    case((TOP_INSTANCE(pathOpt, ht, outerPrefixes, sm))::restIH,_,_,
         INST_INNER(name=name))
      equation
        // prefix the name!
        cref_ = ComponentReference.makeCrefIdent(name, DAE.T_UNKNOWN_DEFAULT, {});
        (_,cref) = PrefixUtil.prefixCref(FCore.emptyCache(), FGraph.empty(), emptyInstHierarchy, inPrefix, cref_);
        // add to hashtable!
        // fprintln(Flags.FAILTRACE, "InnerOuter.updateInstHierarchy adding: " + PrefixUtil.printPrefixStr(inPrefix) + "/" + name + " to IH");
        ht = add((cref,inInstInner), ht);
      then
        TOP_INSTANCE(pathOpt, ht, outerPrefixes, sm)::restIH;

    // failure
    case(_,_,_,INST_INNER())
      equation
        // prefix the name!
        //(_,cref) = PrefixUtil.prefixCref(FCore.emptyCache(),{},emptyInstHierarchy,inPrefix, ComponentReference.makeCrefIdent("UNKNOWN", DAE.T_UNKNOWN_DEFAULT, {}));
        // fprintln(Flags.INNER_OUTER, "InnerOuter.updateInstHierarchy failure for: " +
        //   PrefixUtil.printPrefixStr(inPrefix) + "/" + name);
      then
        fail();
  end match;
end updateInstHierarchy;

public function updateSMHierarchy
"@author: BTH
Add State Machine state to collection of State Machine states in instance hierarchy."
  input DAE.ComponentRef smState;
  input InstHierarchy inIH;
  output InstHierarchy outIH;
algorithm
  outIH := match (smState, inIH)
    local
      TopInstance tih;
      InstHierarchy restIH, ih;
      DAE.ComponentRef cref;
      SCode.Ident name;
      InstHierarchyHashTable ht;
      Option<Absyn.Path> pathOpt;
      OuterPrefixes outerPrefixes;
      HashSet.HashSet sm;
      HashSet.HashSet sm2;

    // no hashtable, create one!
    case(_,{})
      equation
        ht = emptyInstHierarchyHashTable();
        sm = HashSet.emptyHashSet();
        //sm = Debug.bcallret2(true, BaseHashSet.add, smState, sm, sm);
        sm2 = BaseHashSet.add(smState, sm);
        // FIXME what to put for emptyOuterPrefixes
        tih = TOP_INSTANCE(NONE(), ht, emptyOuterPrefixes, sm2);

        ih = {tih};
      then
        ih;

    // add to the hierarchy
    case (cref,TOP_INSTANCE(pathOpt, ht, outerPrefixes, sm)::restIH)
      equation
        // add to hashtable!
        sm = BaseHashSet.add(cref, sm); // add((cref,inInstInner), ht);
      then
        TOP_INSTANCE(pathOpt, ht, outerPrefixes, sm)::restIH;

    // failure
    case (DAE.CREF_IDENT(ident=name),_)
      equation
        true = Flags.isSet(Flags.INSTANCE);
        Debug.traceln("InnerOuter.updateSMHierarchy failure for: " + name);
      then
        fail();
  end match;
end updateSMHierarchy;


public function addClassIfInner
  input SCode.Element inClass;
  input DAE.Prefix inPrefix;
  input FCore.Graph inScope;
  input InstHierarchy inIH;
  output InstHierarchy outIH;
algorithm
  outIH := matchcontinue(inClass, inPrefix, inScope, inIH)
    local
      String name, scopeName;
      Absyn.InnerOuter io;

    // add inner or innerouter
    case (SCode.CLASS(name = name, prefixes = SCode.PREFIXES(innerOuter = io)), _, _, _)
      equation
        true = AbsynUtil.isInner(io);
        scopeName = FGraph.getGraphNameStr(inScope);
        // add to instance hierarchy
        outIH = updateInstHierarchy(inIH, inPrefix, io,
          INST_INNER(
            inPrefix, // prefix
            name, // class name
            io,
            name,
            Absyn.IDENT(name),
            scopeName,
            NONE(),
            {},
            SOME(inClass)));
      then
        outIH;

    // do nothing if not inner
    else inIH;

  end matchcontinue;
end addClassIfInner;

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
      InstHierarchyHashTable ht;
      Option<Absyn.Path> pathOpt;
      OuterPrefixes outerPrefixes;
      HashSet.HashSet sm;

    // no hashtable, create one!
    case({}, _, _)
      equation
        // create an empty table and add the crefs to it.
        ht = emptyInstHierarchyHashTable();
        sm = HashSet.emptyHashSet();
        tih = TOP_INSTANCE(NONE(), ht, {OUTER(ComponentReference.crefStripSubs(inOuterComponentRef), inInnerComponentRef)}, sm);
        ih = {tih};
      then
        ih;

    // add to the top instance
    case((TOP_INSTANCE(pathOpt, ht, outerPrefixes, sm))::restIH, _, _)
      equation
        // fprintln(Flags.INNER_OUTER, "InnerOuter.addOuterPrefix adding: outer cref: " +
        //   ComponentReference.printComponentRefStr(inOuterComponentRef) + " refers to inner cref: " +
        //   ComponentReference.printComponentRefStr(inInnerComponentRef) + " to IH");
        outerPrefixes = List.unionElt(OUTER(ComponentReference.crefStripSubs(inOuterComponentRef), inInnerComponentRef), outerPrefixes);
      then
        TOP_INSTANCE(pathOpt, ht, outerPrefixes, sm)::restIH;

    // failure
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("InnerOuter.addOuterPrefix failed to add: outer cref: " +
          ComponentReference.printComponentRefStr(inOuterComponentRef) + " refers to inner cref: " +
          ComponentReference.printComponentRefStr(inInnerComponentRef) + " to IH");
      then
        fail();
  end matchcontinue;
end addOuterPrefixToIH;

public function prefixOuterCrefWithTheInnerPrefix
"@author: adrpo
  This function searches for outer crefs and prefixes them with the inner prefix"
  input InstHierarchy inIH;
  input DAE.ComponentRef inOuterComponentRef;
  input DAE.Prefix inPrefix;
  output DAE.ComponentRef outInnerComponentRef;
algorithm
  outInnerComponentRef := match(inIH, inOuterComponentRef, inPrefix)
    local
      DAE.ComponentRef outerCrefPrefix, fullCref, innerCref, innerCrefPrefix;
      OuterPrefixes outerPrefixes;

    // we have no outer references, fail so prefixing can happen in the calling function
    case ({}, _, _)
      then
        fail();

    // we have some outer references, search for our prefix + cref in them
    case ({TOP_INSTANCE(_, _, outerPrefixes as _::_, _)}, _, _)
      equation
        (_,fullCref) = PrefixUtil.prefixCref(FCore.emptyCache(), FGraph.empty(), emptyInstHierarchy, inPrefix, inOuterComponentRef);

        // this will fail if we don't find it so prefixing can happen in the calling function
        (outerCrefPrefix, innerCrefPrefix) = searchForInnerPrefix(fullCref, inOuterComponentRef, outerPrefixes);

        innerCref = changeOuterReferenceToInnerReference(fullCref, outerCrefPrefix, innerCrefPrefix);

        // fprintln(Flags.FAILTRACE, "- InnerOuter.prefixOuterCrefWithTheInnerPrefix replaced cref " + ComponentReference.printComponentRefStr(fullCref) + " with cref: " + ComponentReference.printComponentRefStr(innerCref));
      then
        innerCref;

    // failure
    else
      equation
        // true = Flags.isSet(Flags.FAILTRACE);
        // Debug.traceln("- InnerOuter.prefixOuterCrefWithTheInnerPrefix failed to find prefix of inner for outer: prefix/cref " + PrefixUtil.printPrefixStr(inPrefix) + "/" + ComponentReference.printComponentRefStr(inOuterComponentRef));
      then
        fail();
  end match;
end prefixOuterCrefWithTheInnerPrefix;

protected function changeOuterReferenceToInnerReference
"@author: adrpo
  This function replaces the outer prefix with the inner prefix in the full cref"
  input DAE.ComponentRef inFullCref;
  input DAE.ComponentRef inOuterCrefPrefix;
  input DAE.ComponentRef inInnerCrefPrefix;
  output DAE.ComponentRef outInnerCref;
algorithm
  outInnerCref := match(inFullCref, inOuterCrefPrefix, inInnerCrefPrefix)
    local
      DAE.ComponentRef ifull, ocp, icp, ic;
      list<DAE.ComponentRef> eifull, eocp, eicp, epre, erest, esuffix;

    // The full cref might contain subscripts that we wish to keep, so we use
    // the inner and outer prefix to extract the relevant parts of the full cref.
    //
    // E.g. if we have a full cref a.b.c.d.e.f.g, an outer prefix a.b.c.d.e and
    // an inner prefix a.d.e, then we want a, d.e and f.g, resulting in a.d.e.f.g.
    case (ifull, ocp, icp)
      equation
        // print("F:" + ComponentReference.printComponentRefStr(ifull) + "\n" + "I:" + ComponentReference.printComponentRefStr(icp) + "\n" + "O:" + ComponentReference.printComponentRefStr(ocp) + "\n");
        // Explode the crefs to lists so that they are easier to work with.
        eifull = ComponentReference.explode(ifull);
        eicp = ComponentReference.explode(icp);

        // Split the full cref so that we get the part that is equal to the
        // outer prefix and the rest of the suffix.
        (eocp, esuffix) = List.split(eifull, ComponentReference.identifierCount(ocp));

        // Extract the common prefix of the outer and inner prefix.
        (epre, erest) = List.splitEqualPrefix(eocp, eicp, ComponentReference.crefFirstIdentEqual);

        // remove the common prefix from the inner!
        (_, eicp) = List.splitEqualPrefix(eicp, epre, ComponentReference.crefFirstIdentEqual);

        // Extract the common suffix of the outer and inner prefix.
        (erest, _) = List.splitEqualPrefix(listReverse(erest), listReverse(eicp), ComponentReference.crefFirstIdentEqual);

        // Combine the parts into a new cref.
        erest = List.append_reverse(erest, esuffix);
        eifull = listAppend(epre, erest);
        ic = ComponentReference.implode(eifull);
        // print("C:" + ComponentReference.printComponentRefStr(ic) + "\n");
      then
        ic;

  end match;
end changeOuterReferenceToInnerReference;

protected function searchForInnerPrefix
"@author: adrpo
  search in the outer prefixes and retrieve the outer/inner crefs"
  input DAE.ComponentRef fullCref;
  input DAE.ComponentRef inOuterCref;
  input OuterPrefixes outerPrefixes;
  output DAE.ComponentRef outerCrefPrefix;
  output DAE.ComponentRef innerCrefPrefix;
protected
  DAE.ComponentRef cr, id;
  Boolean b1 = false, b2 = false;
algorithm
  // print("L:" + intString(listLength(outerPrefixes)) + "\n");
  for op in outerPrefixes loop
    OUTER(outerComponentRef = outerCrefPrefix) := op;
    b1 := ComponentReference.crefPrefixOfIgnoreSubscripts(outerCrefPrefix, fullCref);
    if not b1
    then
      cr := ComponentReference.crefStripLastIdent(outerCrefPrefix);
      b2 := ComponentReference.crefLastIdent(outerCrefPrefix) == ComponentReference.crefFirstIdent(inOuterCref)
            and ComponentReference.crefPrefixOfIgnoreSubscripts(cr, fullCref);
    end if;

    if b1 or b2
    then
      OUTER(innerComponentRef = innerCrefPrefix) := op;
      return;
    end if;
  end for;

  fail();
end searchForInnerPrefix;

protected function printInnerDefStr
  input InstInner inInstInner;
  output String outStr;
algorithm
  outStr := match(inInstInner)
    local
      DAE.Prefix innerPrefix;
      SCode.Ident name;
      Absyn.InnerOuter io;
      Option<InstResult> instResult;
      String fullName "full inner component name";
      Absyn.Path typePath "the type of the inner";
      String scope "the scope of the inner";
      list<DAE.ComponentRef> outers "which outers are referencing this inner";
      String str, strOuters;

    case(INST_INNER(_, _, _, fullName, typePath, scope, _, outers, _))
      equation
        outers = List.uniqueOnTrue(outers, ComponentReference.crefEqualNoStringCompare);
        strOuters = if listEmpty(outers)
                      then ""
                      else (" Referenced by 'outer' components: {" +
                        stringDelimitList(List.map(outers, ComponentReference.printComponentRefStr), ", ") + "}");
        str = AbsynUtil.pathString(typePath) + " " + fullName + "; defined in scope: " + scope + "." + strOuters;
      then
        str;
  end match;
end printInnerDefStr;

public function getExistingInnerDeclarations
"@author: adrpo
 This function retrieves all the existing inner declarations as a string"
  input InstHierarchy inIH;
  input FCore.Graph inEnv;
  output String innerDeclarations;
algorithm
  innerDeclarations := match(inIH, inEnv)
    local
      TopInstance tih;
      InstHierarchy restIH;
      InstHierarchyHashTable ht;
      Option<Absyn.Path> pathOpt;
      OuterPrefixes outerPrefixes;
      list<InstInner> inners;
      String str;

    // we have no inner components yet
    case ({}, _)
      then
        "There are no 'inner' components defined in the model in any of the parent scopes of 'outer' component's scope: " + FGraph.printGraphPathStr(inEnv) + "." ;

    // get the list of components
    case((TOP_INSTANCE(_, ht, _, _))::_, _)
      equation
        inners = getInnersFromInstHierarchyHashTable(ht);
        str = stringDelimitList(List.map(inners, printInnerDefStr), "\n    ");
      then
        str;
  end match;
end getExistingInnerDeclarations;

protected function getInnersFromInstHierarchyHashTable
"@author: adrpo
  Returns all the inners defined in the hashtable."
  input InstHierarchyHashTable t;
  output list<InstInner> inners;
algorithm
  inners := List.map(hashTableList(t),getValue);
end getInnersFromInstHierarchyHashTable;

protected function getValue
  input tuple<Key,Value> tpl;
  output InstInner v;
algorithm
  v := match(tpl)
    case((_,v)) then v;
  end match;
end getValue;

/////////////////////////////////////////////////////////////////
// hash table implementation for InnerOuter instance hierarchy //
/////////////////////////////////////////////////////////////////

protected function hashFunc
"author: PA
  Calculates a hash value for DAE.ComponentRef"
  input Key k;
  output Integer res;
algorithm
  res := stringHashDjb2(ComponentReference.printComponentRefStr(k));
end hashFunc;

protected function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
     res := ComponentReference.crefEqualNoStringCompare(key1,key2);
end keyEqual;

protected function dumpInstHierarchyHashTable ""
  input InstHierarchyHashTable t;
algorithm
  print("InstHierarchyHashTable:\n");
  print(stringDelimitList(List.map(hashTableList(t),dumpTuple),"\n"));
  print("\n");
end dumpInstHierarchyHashTable;

protected function dumpTuple
  input tuple<Key,Value> tpl;
  output String str;
algorithm
  str := match(tpl)
    local
      Key k; Value v;
    case((k,_))
      equation
        str = "{" +
         ComponentReference.crefStr(k) +
         " opaque InstInner for now, implement printing. " + "}\n";
      then str;
  end match;
end dumpTuple;

/* end of InstHierarchyHashTable instance specific code */

/* Generic hashtable code below!! */
public
uniontype InstHierarchyHashTable
  record HASHTABLE
    array<list<tuple<Key,Integer>>> hashTable " hashtable to translate Key to array indx" ;
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
    array<Option<tuple<Key,Value>>> valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

protected function emptyInstHierarchyHashTable
"author: PA
  Returns an empty InstHierarchyHashTable.
  Using the bucketsize 100 and array size 10."
  output InstHierarchyHashTable hashTable;
protected
  array<list<tuple<Key,Integer>>> arr;
  list<Option<tuple<Key,Value>>> lst;
  array<Option<tuple<Key,Value>>> emptyarr;
algorithm
  arr := arrayCreate(1000, {});
  emptyarr := arrayCreate(100, NONE());
  hashTable := HASHTABLE(arr,VALUE_ARRAY(0,emptyarr),1000,0);
end emptyInstHierarchyHashTable;

protected function add
"author: PA
  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value."
  input tuple<Key,Value> entry;
  input InstHierarchyHashTable hashTable;
  output InstHierarchyHashTable outHashTable;
algorithm
  outHashTable :=
  matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,_)),(HASHTABLE(hashvec,varr,bsize,_)))
      equation
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
        // print("Added NEW to IH: key:" + ComponentReference.printComponentRefStr(key) + " value: " + printInnerDefStr(value) + "\n");
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);

      /* adding when already present => Updating value */
    case ((newv as (key,_)),(HASHTABLE(hashvec,varr,bsize,n)))
      equation
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        varr_1 = valueArraySetnth(varr, indx, newv);
        // print("Updated NEW to IH: key:" + ComponentReference.printComponentRefStr(key) + " value: " + printInnerDefStr(value) + "\n");
      then HASHTABLE(hashvec,varr_1,bsize,n);
    else
      equation
        print("- InnerOuter.add failed\n");
      then
        fail();
  end matchcontinue;
end add;

public function get
"author: PA
  Returns a Value given a Key and a InstHierarchyHashTable."
  input Key key;
  input InstHierarchyHashTable hashTable;
  output Value value;
algorithm
  (value,_):= get1(key,hashTable);
end get;

protected function get1 "help function to get"
  input Key key;
  input InstHierarchyHashTable hashTable;
  output Value value;
  output Integer indx;
algorithm
  (value, indx) := match (key,hashTable)
    local
      Integer hval,hashindx,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;
      array<list<tuple<Key,Integer>>> hashvec;
      ValueArray varr;
      Key k;

    case (_,(HASHTABLE(hashvec,varr,bsize,_)))
      equation
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        (k, v) = valueArrayNth(varr, indx);
        true = keyEqual(k, key);
      then
        (v,indx);
  end match;
end get1;

protected function get2
"author: PA
  Helper function to get"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  output Integer index;
algorithm
  index := matchcontinue (key,keyIndices)
    local
      Key key2;
      list<tuple<Key,Integer>> xs;
    case (_,((key2,index) :: _))
      equation
        true = keyEqual(key, key2);
      then
        index;
    case (_,(_ :: xs))
      equation
        index = get2(key, xs);
      then
        index;
  end matchcontinue;
end get2;

protected function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
  input InstHierarchyHashTable hashTable;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := match(hashTable)
  local ValueArray varr;
    case(HASHTABLE(valueArr = varr)) equation
      tplLst = valueArrayList(varr);
    then tplLst;
  end match;
end hashTableList;

protected function valueArrayList
"author: PA
  Transforms a ValueArray to a tuple<Key,Value> list"
  input ValueArray valueArray;
  output list<tuple<Key,Value>> tplLst;
algorithm
  tplLst := matchcontinue (valueArray)
    local
      array<Option<tuple<Key,Value>>> arr;
      tuple<Key,Value> elt;
      Integer lastpos,n,size;
      list<tuple<Key,Value>> lst;
    case (VALUE_ARRAY(numberOfElements = 0)) then {};
    case (VALUE_ARRAY(numberOfElements = 1,valueArray = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr))
      equation
        lastpos = n - 1;
        lst = valueArrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end valueArrayList;

protected function valueArrayList2 "Helper function to valueArrayList"
  input array<Option<tuple<Key,Value>>> inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<tuple<Key,Value>> outVarLst;
algorithm
  outVarLst := matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      tuple<Key,Value> v;
      array<Option<tuple<Key,Value>>> arr;
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
        NONE() = arr[pos + 1];
        res = valueArrayList2(arr, pos_1, lastpos);
      then
        (res);
  end matchcontinue;
end valueArrayList2;

protected function valueArrayLength
"author: PA
  Returns the number of elements in the ValueArray"
  input ValueArray valueArray;
  output Integer size;
algorithm
  size := match (valueArray)
    case (VALUE_ARRAY(numberOfElements = size)) then size;
  end match;
end valueArrayLength;

protected function valueArrayAdd
"author: PA
  Adds an entry last to the ValueArray, increasing
  array size if no space left by factor 1.4"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<tuple<Key,Value>>> arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),_)
      equation
        (n < arrayLength(arr)) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,arr_1);

    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),_)
      equation
        size = arrayLength(arr);
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize * 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        arr_1 = Array.expand(expandsize_1, arr,NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,arr_2);
    else
      equation
        print("-InstHierarchyHashTable.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

protected function valueArraySetnth
"author: PA
  Set the n:th variable in the ValueArray to value."
  input ValueArray valueArray;
  input Integer pos;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,pos,entry)
    local
      array<Option<tuple<Key,Value>>> arr;
      Integer n,size;
    case (VALUE_ARRAY(_,arr),_,_)
      equation
        (pos < arrayLength(arr)) = true;
        arrayUpdate(arr, pos + 1, SOME(entry));
      then
        valueArray;
    else
      equation
        print("-InstHierarchyHashTable.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;

protected function valueArrayClearnth
"author: PA
  Clears the n:th variable in the ValueArray (set to NONE())."
  input ValueArray valueArray;
  input Integer pos;
  output ValueArray outValueArray;
algorithm
  outValueArray := matchcontinue (valueArray,pos)
    local
      array<Option<tuple<Key,Value>>> arr;
      Integer n,size;
    case (VALUE_ARRAY(_,arr),_)
      equation
        (pos < arrayLength(arr)) = true;
        arrayUpdate(arr, pos + 1,NONE());
      then
        valueArray;
    else
      equation
        print("-InstHierarchyHashTable.valueArrayClearnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayClearnth;

protected function valueArrayNth
"author: PA
  Retrieve the n:th Vale from ValueArray, index from 0..n-1."
  input ValueArray valueArray;
  input Integer pos;
  output Key key;
  output Value value;
algorithm
  (key, value) := match (valueArray,pos)
    local
      Key k;
      Value v;
      Integer n;
      array<Option<tuple<Key,Value>>> arr;

    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),_)
      equation
        (pos < n) = true;
        SOME((k,v)) = arr[pos + 1];
      then
        (k, v);

  end match;
end valueArrayNth;

annotation(__OpenModelica_Interface="frontend");
end InnerOuter;

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

public import Exp;
public import Static;
public import DAE;
public import Env;
public import Prefix;

public 
uniontype Face "This type indicates whether a connector is an inner or an outer
    connector."
  record INNER end INNER;

  record OUTER end OUTER;

end Face;

public 
uniontype Set "A connection set is represented using the `Set\' type."
  record EQU
    list<Exp.ComponentRef> expComponentRefLst;
  end EQU;

  record FLOW
    list<tuple<Exp.ComponentRef, Face>> tplExpComponentRefFaceLst;
  end FLOW;

end Set;

public 
uniontype Sets "The connection \'Sets\' contains the connection set and a list of 
  component references occuring in connect statemens. The latter is 
  used only when evaluating the cardinality operator. It is passed -into-
  classes to be instantiated, while the \'Set list\' is returned -from-
  instantiated classes. 
"
  record SETS
    list<Set> setLst;
    list<Exp.ComponentRef> connection "connection_set connect_refs - list of 
					      crefs in connect statements." ;
  end SETS;

end Sets;

public constant Sets emptySet=SETS({},{});

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
  input Exp.ComponentRef r1;
  input Exp.ComponentRef r2;
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
  input Exp.ComponentRef r1;
  input Face d1;
  input Exp.ComponentRef r2;
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
  input Exp.ComponentRef r1;
  input Face d1;
  input Exp.ComponentRef r2;
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
      Exp.ComponentRef r1_1,r2_1,r1,r2;
      Integer i_1,i;
      Set s1,s2;
    case (s,_,_,_,_,0) then s; 
    case (ss,r1,d1,r2,d2,i)
      equation 
        r1_1 = Exp.subscriptCref(r1, {Exp.INDEX(Exp.ICONST(i))});
        r2_1 = Exp.subscriptCref(r2, {Exp.INDEX(Exp.ICONST(i))});
        i_1 = i - 1;
        s1 = findFlowSet(ss, r1_1,d1);
        s2 = findFlowSet(ss, r2_1,d2);
        ss_1 = merge(ss, s1, s2);
        ss_2 = addArrayFlow(ss_1, r1,d1, r2,d2, i_1);
      then
        ss_2;
  end matchcontinue;
end addArrayFlow;

public function addArrayEqu "function: addArrayEqu
 
  For connecting two arrays, an equal equation for each index should 
  be generated.
"
  input Sets inSets1;
  input Exp.ComponentRef inComponentRef2;
  input Exp.ComponentRef inComponentRef3;
  input Integer inInteger4;
  output Sets outSets;
algorithm 
  outSets:=
  matchcontinue (inSets1,inComponentRef2,inComponentRef3,inInteger4)
    local
      Sets s,ss_1,ss_2,ss;
      Exp.ComponentRef r1_1,r2_1,r1,r2;
      Integer i_1,i;
      Set s1,s2;
    case (s,_,_,0) then s; 
    case (ss,r1,r2,i)
      equation 
        r1_1 = Exp.subscriptCref(r1, {Exp.INDEX(Exp.ICONST(i))});
        r2_1 = Exp.subscriptCref(r2, {Exp.INDEX(Exp.ICONST(i))});
        i_1 = i - 1;
        s1 = findEquSet(ss, r1_1);
        s2 = findEquSet(ss, r2_1);
        ss_1 = merge(ss, s1, s2);
        ss_2 = addArrayEqu(ss_1, r1, r2, i_1);
      then
        ss_2;
  end matchcontinue;
end addArrayEqu;

public function equations "
  - Equation generation

  function: equations
 
  From a number of connection sets, this function generates a list
  of equations.
"
  input Sets inSets;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inSets)
    local
      list<DAE.Element> dae1,dae2,dae;
      list<Exp.ComponentRef> cs,crs;
      list<Set> ss;
    case (SETS(setLst = {})) then {}; 
    case (SETS(setLst = (EQU(expComponentRefLst = cs) :: ss),connection = crs))
      equation 
        dae1 = equEquations(cs);
        dae2 = equations(SETS(ss,crs));
        dae = listAppend(dae1, dae2);
      then
        dae;
    case (SETS(setLst = (FLOW(tplExpComponentRefFaceLst = cs) :: ss),connection = crs))
      local list<tuple<Exp.ComponentRef, Face>> cs;
      equation 
        dae1 = flowEquations(cs);
        dae2 = equations(SETS(ss,crs));
        dae = listAppend(dae1, dae2);
      then
        dae;
  end matchcontinue;
end equations;

protected function equEquations "function: equEquations
  
  A non-flow connection set contains a number of components.
  Generating the equation from this set means equating all the
  components.  For n components, this will give n-1 equations.
 
  For example, if the set contains the components `x\', `y.a\' and
  `z.b\', the equations generated will me `x = y.a\' and `y.a = z.b\'.
"
  input list<Exp.ComponentRef> inExpComponentRefLst;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  outDAEElementLst:=
  matchcontinue (inExpComponentRefLst)
    local
      list<DAE.Element> eq;
      Exp.ComponentRef x,y;
      list<Exp.ComponentRef> cs;
    case {_} then {}; 
    case (x :: (y :: cs))
      equation 
        eq = equEquations((y :: cs));
      then
        (DAE.EQUATION(Exp.CREF(x,Exp.OTHER()),Exp.CREF(y,Exp.OTHER())) :: eq);
  end matchcontinue;
end equEquations;

protected function flowEquations "function: flowEquations
  
  Generating equations from a flow connection set is a little
  trickier that from a non-flow set.  Only one equation is
  generated, but it has to consider whether the comoponents were
  inner or outer connectors.
 
  This function uses `flow_sum\' to create the sum of all components
  (some of which will be negated), and the returns the equation
  where this sum is equal to 0.0.
"
  input list<tuple<Exp.ComponentRef, Face>> cs;
  output list<DAE.Element> outDAEElementLst;
  Exp.Exp sum;
algorithm 
  sum := flowSum(cs);
  outDAEElementLst := {DAE.EQUATION(sum,Exp.RCONST(0.0))};
end flowEquations;

protected function flowSum "function: flowSum
  
  This function creates an exression expressing the sum of all
  components in the given list.  Before adding the component to the
  sum, it is passed to `sign_flow\' which will negate all outer
  connectors.
"
  input list<tuple<Exp.ComponentRef, Face>> inTplExpComponentRefFaceLst;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inTplExpComponentRefFaceLst)
    local
      Exp.Exp exp,exp1,exp2;
      Exp.ComponentRef c;
      Face f;
      list<tuple<Exp.ComponentRef, Face>> cs;
    case {(c,f)}
      equation 
        exp = signFlow(c, f);
      then
        exp;
    case (((c,f) :: cs))
      equation 
        exp1 = signFlow(c, f);
        exp2 = flowSum(cs);
      then
        Exp.BINARY(exp1,Exp.ADD(Exp.REAL()),exp2);
  end matchcontinue;
end flowSum;

protected function signFlow "function: signFlow
 
  This function takes a name of a component and a `Face\', returns an
  expression.  If the face is `INNER\' the expression simply contains
  the component reference, but if it is `OUTER\', the expression is
  negated.
"
  input Exp.ComponentRef inComponentRef;
  input Face inFace;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentRef,inFace)
    local Exp.ComponentRef c;
    case (c,INNER()) then Exp.CREF(c,Exp.OTHER()); 
    case (c,OUTER()) then Exp.UNARY(Exp.UMINUS(Exp.REAL()),Exp.CREF(c,Exp.OTHER())); 
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
  input Exp.ComponentRef inComponentRef;
  output Set outSet;
algorithm 
  outSet:=
  matchcontinue (inSets,inComponentRef)
    local
      Set s;
      Exp.ComponentRef c;
      list<Set> ss;
      list<Exp.ComponentRef> crs;
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
    case (SETS(setLst = (_ :: ss),connection = crs),c)
      equation 
        s = findEquSet(SETS(ss,crs), c);
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
  input Exp.ComponentRef inComponentRef;
  input Face inFace;
  output Set outSet;
algorithm 
  outSet:=
  matchcontinue (inSets,inComponentRef,inFace)
    local
      Set s;
      Exp.ComponentRef c;
      Face d;
      list<Set> ss;
      list<Exp.ComponentRef> crs;
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
    case (SETS(setLst = (_ :: ss),connection = crs),c,d)
      equation 
        s = findFlowSet(SETS(ss,crs), c, d);
      then
        s;
  end matchcontinue;
end findFlowSet;

protected function findInSet "function: findInSet
  
  This function checks if a componet already appears in a given
  connection set.
"
  input Set inSet;
  input Exp.ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inSet,inComponentRef)
    local
      list<Exp.ComponentRef> cs;
      Exp.ComponentRef c;
    case (EQU(expComponentRefLst = cs),c)
      equation 
        findInSetEqu(cs, c);
      then
        ();
    case (FLOW(tplExpComponentRefFaceLst = cs),c)
      local list<tuple<Exp.ComponentRef, Face>> cs;
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
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input Exp.ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inExpComponentRefLst,inComponentRef)
    local
      Exp.ComponentRef c1,c2;
      list<Exp.ComponentRef> cs;
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
  input list<tuple<Exp.ComponentRef, Face>> inTplExpComponentRefFaceLst;
  input Exp.ComponentRef inComponentRef;
algorithm 
  _:=
  matchcontinue (inTplExpComponentRefFaceLst,inComponentRef)
    local
      Exp.ComponentRef c1,c2;
      list<tuple<Exp.ComponentRef, Face>> cs;
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
  input Exp.ComponentRef inComponentRef;
  output Set outSet;
algorithm 
  outSet:=
  matchcontinue (inComponentRef)
    local Exp.ComponentRef c;
    case c then EQU({c}); 
  end matchcontinue;
end newEquSet;

protected function newFlowSet "function: newFlowSet
 
  This function creates a new-flow connection set containing only
  the given component.
"
  input Exp.ComponentRef inComponentRef;
  input Face inFace;
  output Set outSet;
algorithm 
  outSet:=
  matchcontinue (inComponentRef,inFace)
    local
      Exp.ComponentRef c;
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
      list<Exp.ComponentRef> crs,cs,cs1,cs2;
      Set s1,s2;
    case (SETS(setLst = ss,connection = crs),s1,s2)
      equation 
        equality(s1 = s2);
      then
        SETS(ss,crs);
    case (SETS(setLst = ss,connection = crs),(s1 as EQU(expComponentRefLst = cs1)),(s2 as EQU(expComponentRefLst = cs2)))
      equation 
        cs = listAppend(cs1, cs2);
        SETS(ss_1,_) = removeSet2(SETS(ss,crs), s1, s2);
      then
        SETS((EQU(cs) :: ss_1),crs);
    case (SETS(setLst = ss,connection = crs),(s1 as FLOW(tplExpComponentRefFaceLst = cs1)),(s2 as FLOW(tplExpComponentRefFaceLst = cs2)))
      local list<tuple<Exp.ComponentRef, Face>> cs,cs1,cs2;
      equation 
        cs = listAppend(cs1, cs2);
        SETS(ss_1,_) = removeSet2(SETS(ss,crs), s1, s2);
      then
        SETS((FLOW(cs) :: ss_1),crs);
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
      list<Exp.ComponentRef> crs;
      Sets ss_1;
      Set s,s1,s2;
      list<Set> ss;
    case (SETS(setLst = {},connection = crs),_,_) then SETS({},crs); 
    case (SETS(setLst = (s :: ss),connection = crs),s1,s2)
      equation 
        equality(s = s1);
        ss_1 = removeSet(SETS(ss,crs), s2);
      then
        ss_1;
    case (SETS(setLst = (s :: ss),connection = crs),s1,s2)
      equation 
        equality(s = s2);
        ss_1 = removeSet(SETS(ss,crs), s1);
      then
        ss_1;
    case (SETS(setLst = (s :: ss),connection = crs),s1,s2)
      local list<Set> ss_1;
      equation 
        SETS(ss_1,_) = removeSet2(SETS(ss,crs), s1, s2);
      then
        SETS((s :: ss_1),crs);
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
      list<Exp.ComponentRef> crs;
      Set s,s1;
      list<Set> ss,ss_1;
    case (SETS(setLst = {},connection = crs),_) then SETS({},crs); 
    case (SETS(setLst = (s :: ss),connection = crs),s1)
      equation 
        equality(s = s1);
      then
        SETS(ss,crs);
    case (SETS(setLst = (s :: ss),connection = crs),s1)
      equation 
        SETS(ss_1,_) = removeSet(SETS(ss,crs), s1);
      then
        SETS((s :: ss_1),crs);
  end matchcontinue;
end removeSet;

public function unconnectedFlowEquations "Unconnected flow variables.
  function: unconnectedFlowEquations 
 
  This function will generate set-to-zero equations for INNER flow variables.
  It can not generate for outer flow varaibles, since we do not yet know if 
  these are connected or not. This is only known in the preceding recursive 
  call. However, the top call must generate for both inner and outer 
  connectors, hence the last argument, true for top call"
 	input Env.Cache inCache;
  input Sets inSets;
  input list<DAE.Element> inDAEElementLst;
  input Env.Env inEnv;
  input Prefix.Prefix prefix;
  input Boolean inBoolean;
  output Env.Cache outCache;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outCache,outDAEElementLst) :=
  matchcontinue (inCache,inSets,inDAEElementLst,inEnv,prefix,inBoolean)
    local
      list<Exp.ComponentRef> v1,v2,vars,vars2,unconnectedvars;
      list<DAE.Element> dae_1,dae;
      Sets csets;
      list<Env.Frame> env;
      Env.Cache cache;
      Exp.ComponentRef prefixCref;
    case (cache,csets,dae,env,prefix,true)
      equation 
        v1 = Env.localOutsideConnectorFlowvars(env) "if outermost call look at both inner and outer unconnected connectors" ;
        v2 = Env.localInsideConnectorFlowvars(env);
        vars = listAppend(v1, v2);
        vars2 = getOuterFlowVariables(csets);
        // last array subscripts are not present in vars, therefor removed from vars2 too.
        vars2 = Util.listMap(vars2,Exp.crefStripLastSubs); 
/*        print("scope =");print(Env.printEnvPathStr(env));print("\n");
        print("v1:");print(Util.stringDelimitList(Util.listMap(v1,Exp.printComponentRefStr),","));print("\n");
        print("v2:");print(Util.stringDelimitList(Util.listMap(v2,Exp.printComponentRefStr),","));print("\n");
        print("vars :");print(Util.stringDelimitList(Util.listMap(vars,Exp.printComponentRefStr),","));print("\n");
        print("vars2 :");print(Util.stringDelimitList(Util.listMap(vars2,Exp.printComponentRefStr),","));print("\n");
  */
        unconnectedvars = removeVariables(vars, vars2);
       
        // no prefix for top level
        (cache,dae_1) = generateZeroflowEquations(cache,unconnectedvars,env,Prefix.NOPRE());
      then
        (cache,dae_1);

      case (cache,csets,dae,env,prefix,false)
      equation 
        vars = Env.localInsideConnectorFlowvars(env);
        vars2 = getInnerFlowVariables(csets);
/*				print("inner call scope:");print(Env.printEnvPathStr(env));print(" ");
				print("prefix :");print(Prefix.printPrefixStr(prefix));print("\n");
        print("vars:");print(Util.stringDelimitList(Util.listMap(vars,Exp.printComponentRefStr),","));print("\n");
        print("vars2:");print(Util.stringDelimitList(Util.listMap(vars2,Exp.printComponentRefStr),","));print("\n");
*/
        prefixCref = Prefix.prefixToCref(prefix);
        vars2 = Util.listMap1(vars2,Exp.crefStripPrefix,prefixCref);
        
        // last array subscripts are not present in vars, therefor removed from vars2 too.
        vars2 = Util.listMap(vars2,Exp.crefStripLastSubs);
        unconnectedvars = removeVariables(vars, vars2);

				// Add prefix that was "removed" above
        (cache,dae_1) = generateZeroflowEquations(cache,unconnectedvars,env,prefix);
        
      then
        (cache,dae_1);
        
    case (cache,csets,dae,env,_,_) 
    then (cache,{}); 
  end matchcontinue;
end unconnectedFlowEquations;

protected function removeVariables "function: removeVariables
 
  Removes all the variables in the second list from the first list.
"
  input list<Exp.ComponentRef> inExpComponentRefLst1;
  input list<Exp.ComponentRef> inExpComponentRefLst2;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst1,inExpComponentRefLst2)
    local
      list<Exp.ComponentRef> vars,vars_1,res,removelist;
      Exp.ComponentRef r1;
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
  input Exp.ComponentRef inComponentRef;
  input list<Exp.ComponentRef> inExpComponentRefLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inComponentRef,inExpComponentRefLst)
    local
      Exp.ComponentRef cr,cr2;
      list<Exp.ComponentRef> xs,res;
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
  input Exp.ComponentRef cr;
  input list<Integer> dimensions;
  input Exp.Exp initExp;
  output list<DAE.Element> equations;
algorithm
  equations := matchcontinue(cr, dimensions, initExp)
    local
      list<DAE.Element> out;
      list<list<Integer>> indexIntegerLists;
      list<list<Exp.Subscript>> indexSubscriptLists;      
    case(cr, dimensions, initExp)
      equation
        // take the list of dimensions: ex. {2, 5, 3}
        // and generate a list of ranges: ex. {{1, 2}, {1, 2, 3, 4, 5}, {1, 2, 3}}
        indexIntegerLists = Util.listMap(dimensions, Util.listIntRange);
        // from a list like: {{1, 2}, {1, 2, 3, 4, 5}
        // generate a list like: { { {Exp.INDEX(Exp.ICONST(1)}, {Exp.INDEX(Exp.ICONST(2)} }, ... }
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
 given an integer transform it into an list<Exp.Subscript>"
  input   list<Exp.Subscript> indexSubscriptList;
  input   tuple<Exp.ComponentRef, Exp.Exp> crAndInitExp;
  output  DAE.Element eq; 
algorithm  
  eq := matchcontinue (indexSubscriptList, crAndInitExp)
    local
      Exp.ComponentRef cr;
      Exp.Exp initExp;
    case (indexSubscriptList, (cr, initExp))
      equation
        // printMe(indexSubscriptList);
        cr = Exp.subscriptCref(cr, indexSubscriptList);        
      then 
        DAE.EQUATION(Exp.CREF(cr,Exp.REAL()), initExp);
  end matchcontinue;
end genZeroEquation;

function printMe
  input list<Exp.Subscript> hd;
algorithm
  print(Exp.printListStr(hd, Exp.printSubscriptStr, ",")); 
  print ("\n");
end printMe;

function generateAllIndexes
  input  list<list<Exp.Subscript>> inIndexLists;
  input  list<list<Exp.Subscript>> accumulator;
  output list<list<Exp.Subscript>> outIndexLists;
algorithm
  outIndexLists := matchcontinue (inIndexLists, accumulator)
    local 
      list<Exp.Subscript> hd;
      list<list<Exp.Subscript>> tail, res1, res2;      
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
 given an integer transform it into an Exp.Subscript"
  input  Integer       index;
  output Exp.Subscript subscript;
algorithm  
 subscript := Exp.INDEX(Exp.ICONST(index));
end integer2Subscript;

protected function generateZeroflowEquations 
"function: generateZeroflowEquations 
  Unconnected flow variables should be set to zero. This function 
  generates equations setting each variable in the list to zero."
	input Env.Cache inCache;
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input Env.Env inEnv;
  input Prefix.Prefix prefix;
  output Env.Cache outCache;
  output list<DAE.Element> outDAEElementLst;
algorithm 
  (outCache,outDAEElementLst) :=
  matchcontinue (inCache,inExpComponentRefLst,inEnv,prefix)
    local
      list<DAE.Element> res, res1, res2;
      Exp.ComponentRef cr;
      Env.Env env;
      Types.Type tp;
      list<Exp.ComponentRef> xs;
      list<Integer> dimSizes;
      list<Option<Integer>> dimSizesOpt;
      list<Exp.Exp> dimExps;
      Env.Cache cache;
      Exp.ComponentRef cr2;
    case (cache,{},_,_) then (cache,{}); 
    case (cache,(cr :: xs),env,prefix)
      equation
        (cache,_,tp,_) = Lookup.lookupVar(cache,env,cr);
        true = Types.isArray(tp); // For variables that are arrays, generate cr = fill(0,dims);
        dimSizes = Types.getDimensionSizes(tp);
        (_,dimSizesOpt) = Types.flattenArrayTypeOpt(tp); 
        dimExps = Util.listMap(dimSizes,Exp.makeIntegerExp);
        (cache,res2) = generateZeroflowEquations(cache,xs,env,prefix);
        cr2 = Prefix.prefixCref(prefix,cr);
        res1 = generateZeroflowArrayEquations(cr, dimSizes, Exp.RCONST(0.0));
        res = listAppend(res1, res2);        
      then
        (cache, res);         
 
    case (cache,(cr :: xs),env,prefix) // For scalars.
      equation
        (cache,_,tp,_) = Lookup.lookupVar(cache,env,cr);
        false = Types.isArray(tp); // scalar
        (cache,res) = generateZeroflowEquations(cache,xs,env,prefix);
        cr2 = Prefix.prefixCref(prefix,cr);
      then
        (cache,DAE.EQUATION(Exp.CREF(cr2,Exp.REAL()),Exp.RCONST(0.0)) :: res);
  end matchcontinue;
end generateZeroflowEquations;

protected function getAllFlowVariables "function: getAllFlowVariables
  
  Return a list of all flow variables from the connection sets.
"
  input Sets inSets;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inSets)
    local
      list<Exp.ComponentRef> res1,res2,res,crs;
      list<tuple<Exp.ComponentRef, Face>> varlst;
      list<Set> xs;
    case SETS(setLst = {}) then {}; 
    case (SETS(setLst = (FLOW(tplExpComponentRefFaceLst = varlst) :: xs),connection = crs))
      equation 
        res1 = Util.listMap(varlst, Util.tuple21);
        res2 = getAllFlowVariables(SETS(xs,crs));
        res = listAppend(res1, res2);
      then
        res;
    case (SETS(setLst = (EQU(expComponentRefLst = res1) :: xs),connection = crs))
      equation 
        res = getAllFlowVariables(SETS(xs,crs));
      then
        res;
  end matchcontinue;
end getAllFlowVariables;

protected function getInnerFlowVariables "function: getInnerFlowVariables
 
  Get all flow variables that are inner variables from the Sets.
"
  input Sets inSets;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inSets)
    local
      list<Exp.ComponentRef> res1,res2,res,crs;
      list<tuple<Exp.ComponentRef, Face>> vars;
      list<Set> xs;
    case (SETS(setLst = {})) then {}; 
    case (SETS(setLst = (FLOW(tplExpComponentRefFaceLst = vars) :: xs),connection = crs))
      equation 
        res1 = getInnerFlowVariables2(vars);
        res2 = getInnerFlowVariables(SETS(xs,crs));
        res = listAppend(res1, res2);
      then
        res;
    case (SETS(setLst = (EQU(expComponentRefLst = _) :: xs),connection = crs))
      equation 
        res = getInnerFlowVariables(SETS(xs,crs));
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_inner_flow_variables failed\\n\") */  then fail(); 
  end matchcontinue;
end getInnerFlowVariables;

protected function getInnerFlowVariables2 "function: getInnerFlowVariables2
 
  Help function to get_inner_flow_variables.
"
  input list<tuple<Exp.ComponentRef, Face>> inTplExpComponentRefFaceLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inTplExpComponentRefFaceLst)
    local
      list<Exp.ComponentRef> res;
      Exp.ComponentRef cr;
      list<tuple<Exp.ComponentRef, Face>> xs;
    case ({}) then {}; 
    case (((cr,INNER()) :: xs))
      equation 
        res = getInnerFlowVariables2(xs);
      then
        (cr :: res);
    case ((_ :: xs))
      equation 
        res = getInnerFlowVariables2(xs);
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_inner_flow_variables_2 failed\\n\") */  then fail(); 
  end matchcontinue;
end getInnerFlowVariables2;

protected function getOuterFlowVariables "function: getOuterFlowVariables
 
  Get all flow variables that are inner variables from the Sets.
"
  input Sets inSets;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inSets)
    local
      list<Exp.ComponentRef> res1,res2,res,crs;
      list<tuple<Exp.ComponentRef, Face>> vars;
      list<Set> xs;
    case (SETS(setLst = {})) then {}; 
    case (SETS(setLst = (FLOW(tplExpComponentRefFaceLst = vars) :: xs),connection = crs))
      equation 
        res1 = getOuterFlowVariables2(vars);
        res2 = getOuterFlowVariables(SETS(xs,crs));
        res = listAppend(res1, res2);
      then
        res;
    case (SETS(setLst = (EQU(expComponentRefLst = _) :: xs),connection = crs))
      equation 
        res = getOuterFlowVariables(SETS(xs,crs));
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_outer_flow_variables failed\\n\") */  then fail(); 
  end matchcontinue;
end getOuterFlowVariables;

protected function getOuterFlowVariables2 "function: getOuterFlowVariables2
 
  Help function to get_outer_flow_variables.
"
  input list<tuple<Exp.ComponentRef, Face>> inTplExpComponentRefFaceLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inTplExpComponentRefFaceLst)
    local
      list<Exp.ComponentRef> res;
      Exp.ComponentRef cr;
      list<tuple<Exp.ComponentRef, Face>> xs;
    case ({}) then {}; 
    case (((cr,INNER()) :: xs))
      equation 
        res = getOuterFlowVariables2(xs);
      then
        (cr :: res);
    case (( _ :: xs))
      equation 
        res = getOuterFlowVariables2(xs);
      then
        res;
    case (_) /* Debug.fprint(\"failtrace\",\"-get_outer_flow_variables_2 failed\\n\") */  then fail(); 
  end matchcontinue;
end getOuterFlowVariables2;

protected import Print;
protected import Util;
protected import Types;
protected import Lookup;

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
      list<Exp.ComponentRef> crs;
    case SETS(setLst = {}) then (); 
    case SETS(setLst = (x :: xs),connection = crs)
      equation 
        printSet(x);
        printSets(SETS(xs,crs));
      then
        ();
  end matchcontinue;
end printSets;

protected function printSet
  input Set inSet;
algorithm 
  _:=
  matchcontinue (inSet)
    local list<Exp.ComponentRef> cs;
    case EQU(expComponentRefLst = cs)
      equation 
        Print.printBuf(" non-flow set: { ");
        Exp.printList(cs, Exp.printComponentRef, ", ");
        Print.printBuf(" }\n");
      then
        ();
    case FLOW(tplExpComponentRefFaceLst = cs)
      local list<tuple<Exp.ComponentRef, Face>> cs;
      equation 
        Print.printBuf(" flow set: { ");
        Exp.printList(cs, printFlowRef, ", ");
        Print.printBuf(" }\n");
      then
        ();
  end matchcontinue;
end printSet;

protected function printFlowRef
  input tuple<Exp.ComponentRef, Face> inTplExpComponentRefFace;
algorithm 
  _:=
  matchcontinue (inTplExpComponentRefFace)
    local Exp.ComponentRef c;
    case ((c,INNER()))
      equation 
        Exp.printComponentRef(c);
        Print.printBuf(" INNER");
      then
        ();
    case ((c,OUTER()))
      equation 
        Exp.printComponentRef(c);
        Print.printBuf(" OUTER");
      then
        ();
  end matchcontinue;
end printFlowRef;

public function printSetsStr "function: printSetsStr
 
  Prints a description of a number of connection sets to a string
"
  input Sets inSets;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inSets)
    local
      list<String> s1;
      String s1_1,s2,res;
      list<Set> sets;
      list<Exp.ComponentRef> crs;
    case SETS(setLst = sets,connection = crs)
      equation 
        s1 = Util.listMap(sets, printSetStr);
        s1_1 = Util.stringDelimitList(s1, ", ");
        s2 = printSetCrsStr(crs);
        res = Util.stringAppendList({"SETS(\n  ",s1_1,",\n  ",s2,"\n)\n"});
      then
        res;
  end matchcontinue;
end printSetsStr;

protected function printSetStr
  input Set inSet;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inSet)
    local
      list<String> strs;
      String s1,res;
      list<Exp.ComponentRef> cs;
    case EQU(expComponentRefLst = cs)
      equation 
        strs = Util.listMap(cs, Exp.printComponentRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = Util.stringAppendList({" non-flow set: { ",s1,"}"});
      then
        res;
    case FLOW(tplExpComponentRefFaceLst = cs)
      local list<tuple<Exp.ComponentRef, Face>> cs;
      equation 
        strs = Util.listMap(cs, printFlowRefStr);
        s1 = Util.stringDelimitList(strs, ", ");
        res = Util.stringAppendList({" flow set: { ",s1,"}"});
      then
        res;
  end matchcontinue;
end printSetStr;

protected function printFlowRefStr
  input tuple<Exp.ComponentRef, Face> inTplExpComponentRefFace;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inTplExpComponentRefFace)
    local
      String s,res;
      Exp.ComponentRef c;
    case ((c,INNER()))
      equation 
        s = Exp.printComponentRefStr(c);
        res = stringAppend(s, " INNER");
      then
        res;
    case ((c,OUTER()))
      equation 
        s = Exp.printComponentRefStr(c);
        res = stringAppend(s, " OUTER");
      then
        res;
  end matchcontinue;
end printFlowRefStr;

protected function printSetCrsStr
  input list<Exp.ComponentRef> crs;
  output String res;
  list<String> c_strs;
  String s;
algorithm 
  c_strs := Util.listMap(crs, Exp.printComponentRefStr);
  s := Util.stringDelimitList(c_strs, ", ");
  res := Util.stringAppendList({" connect crs: { ",s,"}"});
end printSetCrsStr;
end Connect;


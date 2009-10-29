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

package DFA
"
  file:	       DFA.mo
  package:     DFA
  description: DFA intermediate form

  RCS: $Id$

  DFA (Deterministic Finite Automaton) provides the datatypes and functions for working with states.
  It is used in the pattern matching algorithm from Paternm.mo"

public import Absyn;
public import Env;
public import Types;
public import SCode;
public import Debug;
public import MetaUtil;
public import Error;

type Stamp = Integer;
type ArcName = Absyn.Ident;
type SimpleStateArray = SimpleState[:];

protected import Lookup;
protected import Util;

public uniontype Dfa
  record DFArec
    list<Absyn.ElementItem> localVarList;
    list<Absyn.ElementItem> pathVarList; // Not in use
    Option<RightHandSide> elseCase;
    State startState;
    Integer numOfStates;
    Integer numOfCases; // The number of match cases in the
                        // original match expression
  end DFArec;
end Dfa;

public uniontype State
  record SWITCHSTATE
    list<Arc> outgoingArcs;
  end SWITCHSTATE;

  record STATE
    Stamp stamp;
    Integer refCount; // Not in use
    list<Arc> outgoingArcs;
    Option<RightHandSide> rhSide;
  end STATE;

  record DUMMIESTATE
  end DUMMIESTATE;

  record GOTOSTATE
    Stamp stamp;
    Stamp toState;
  end GOTOSTATE;
end State;

public uniontype Arc
  record ARC
    State state;
    ArcName arcName;
    Option<RenamedPat> pat;
    list<Integer> matchCaseNumbers; // The numbers of the righthand sides
                                    // that this arc leads to.
  end ARC;
end Arc;

// This data structure is used in the optimization phase in Patternm.
// A list/array of SimpleStates is used as a "light" version of
// the DFA.
public uniontype SimpleState
  record SIMPLESTATE
    Stamp stamp;
    list<tuple<ArcName,Stamp>> outgoingArcs; // Name of arc and the number of the state that the arc leads to
    Integer caseNum; // This one is zero if it's not a final state
    Option<Absyn.Ident> varName; // The state variable
  end SIMPLESTATE;

  record SIMPLEDUMMIE
  end SIMPLEDUMMIE;
end SimpleState;


public function addNewArc "function: addNewArc
	author: KS
	A function that adds a new arc to a states arc-list
"
  input State firstState;
  input ArcName arcName;
  input State newState;
  input Option<RenamedPat> pat;
  input list<Integer> caseNumbers;
  output State outState;
algorithm
  outState :=
  matchcontinue (firstState,arcName,newState,pat,caseNumbers)
    local
      State localFirstState;
      ArcName localArcName;
      State localNewState;
      Stamp localStamp;
      Integer localRefCount;
      list<Arc> localOutArcs;
      Option<RightHandSide> localRhSide;
      Arc newArc;
      Option<RenamedPat> localPat;
      list<Integer> localCaseNumbers;
    case (SWITCHSTATE(localOutArcs),localArcName,localNewState,localPat,localCaseNumbers)
      equation
        newArc = ARC(localNewState,localArcName,localPat,localCaseNumbers);
        localOutArcs = listAppend(localOutArcs,(newArc :: {}));
        localFirstState = SWITCHSTATE(localOutArcs);
      then localFirstState;
    case (STATE(localStamp,localRefCount,localOutArcs,localRhSide),
        localArcName,localNewState,localPat,localCaseNumbers)
      equation
        newArc = ARC(localNewState,localArcName,localPat,localCaseNumbers);
        localOutArcs = listAppend(localOutArcs,(newArc :: {}));
        localFirstState = STATE(localStamp,localRefCount,localOutArcs,localRhSide);
      then localFirstState;
    case (_, _, _, _, _)
      equation
        Debug.fprintln("matchcase", "- DFA.addNewArc failed");
      then fail();
  end matchcontinue;
end addNewArc;

/*
public function fromDFAtoIfNodes "function: fromDFAtoIfNodes
	author: KS
	Main function for converting a DFA into a valueblock expression containing
	if-statements.
"
  input Dfa dfa;
  input list<Absyn.Exp> inputVarList; // matchcontinue (var1,var2,...)
  input list<Absyn.Exp> resVarList;  // (var1,var2,...) := matchcontinue (...) ...
  input Env.Cache cache;
  input Env.Env env;
  input RightHandList rightSideList;
  input Boolean lightVs;
  output Env.Cache outCache;
  output Absyn.Exp outExp;
algorithm
  (outCache,outExp) :=
  matchcontinue (dfa,inputVarList,resVarList,cache,env,rightSideList,lightVs)
    local
      list<Absyn.ElementItem> localVarList,varList;
      Option<RightHandSide> elseCase;
      State startState;
      Absyn.Exp exp,resExpr,arrayOfTrue;
      list<Absyn.AlgorithmItem> algs;
      Integer numCases;
      Absyn.Exp statesList;
      Env.Cache localCache;
      Env.Env localEnv;
      Boolean localLightVs;
      list<Absyn.Exp> expList,localResVarList,localInputVarList,listOfTrue;
      RightHandList localRightSideList;

      // Light Version (only one matchcontinue case), do not generate state labels etc.
    case (DFArec(localVarList,_,elseCase,startState,_,numCases),localInputVarList,
        localResVarList,localCache,localEnv,RIGHTHANDSIDE(localList,body,result,_) :: _,true)
      local
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
        list<Absyn.ElementItem> newVars,varList,localList;
        list<Absyn.AlgorithmItem> algs2,algs3,body;
        Absyn.Exp result,vBlock;
        list<Absyn.Exp> exp2;
      equation
        (dfaEnv,localCache) = addVarsToDfaEnv(localInputVarList,{},localCache,localEnv);

        //----------
        exp2 = createListFromExpression(result);

        // Create the assignments that assign the return variables
        algs3 = createLastAssignments(localResVarList,exp2,{});
        body = listAppend(body,algs3);

        vBlock = Absyn.VALUEBLOCK(localList,Absyn.VALUEBLOCKALGORITHMS(body),Absyn.BOOL(true));
        algs3 = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("DUMMIE__",{})),vBlock),NONE())};
        //----------

        (localCache,algs,newVars) = fromStatetoAbsynCode(startState,NONE(),localCache,localEnv,dfaEnv,{},true);

        varList = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Boolean"),NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("DUMMIE__",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        varList = listAppend(varList,newVars);

        algs2 = {Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),NONE())};
        algs2 = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.CREF(Absyn.CREF_IDENT("DUMMIE__",{})),
             algs2,{},algs3),NONE())};
        algs = listAppend(algs,algs2);

        exp = Absyn.VALUEBLOCK(varList,Absyn.VALUEBLOCKALGORITHMS(algs),Absyn.BOOL(true));
       then (localCache,exp);

    case (DFArec(localVarList,_,elseCase,startState,_,numCases),localInputVarList,
        localResVarList,localCache,localEnv,localRightSideList,_)
      equation

        // Used for catch handling. Keep track of the last righthand side visited.
        varList = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("LASTRIGHTHANDSIDE__",{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        localVarList = listAppend(localVarList,varList);

        //The variable BOOLVAR__ should be initialized with true
        listOfTrue = createListOfTrue(numCases,{});
        arrayOfTrue = Absyn.ARRAY(listOfTrue);

        // This variable is used for catch handling. An array
        varList = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Integer"),NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("BOOLVAR__",{Absyn.SUBSCRIPT(Absyn.INTEGER(numCases))},SOME(Absyn.CLASSMOD({},SOME(arrayOfTrue)))),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        localVarList = listAppend(localVarList,varList);

        // This variable is a dummie variable, used when we want to use a valueblock but not
        // return anything interesting. DUMMIE__ := VALUEBLOCK( ... )
        varList = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Boolean"),NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("DUMMIE__",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        localVarList = listAppend(localVarList,varList);

        // This boolean variable is used with the catch handling
        varList = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TPATH(Absyn.IDENT("Boolean"),NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT("NOTDONE__",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        localVarList = listAppend(localVarList,varList);

        (localCache,algs,varList) = generateAlgorithmBlock(localResVarList,localInputVarList,startState,
          elseCase,localCache,localEnv,localRightSideList);

        // This varList contains new variables introduced in connection with constructor-call
        // patterns
        localVarList = listAppend(localVarList,varList);

        //resExpr = Util.listFirst(localResVarList);

        //Create the main valueblock
        exp = Absyn.VALUEBLOCK(localVarList,Absyn.VALUEBLOCKALGORITHMS(algs),Absyn.BOOL(true));
      then (localCache,exp);
  end matchcontinue;
end fromDFAtoIfNodes;
*/

/*
protected function generateAlgorithmBlock "function: generateAlgorithmBlock
	author: KS
 Generate the algorithm statements in the value block from the DFA
"
  input list<Absyn.Exp> resVarList; // Component references to the return list variables
  input list<Absyn.Exp> inputVarList; // matchcontinue (var1,var2,...)
  input State startState;
  input Option<RightHandSide> elseCase;
  input Env.Cache cache;
  input Env.Env env;
  input RightHandList rightHandList;
  output Env.Cache outCache;
  output list<Absyn.AlgorithmItem> outAlgorithms;
  output list<Absyn.ElementItem> outNewVars;
algorithm
  (outCache,outAlgorithms,outNewVars) :=
  matchcontinue (resVarList,inputVarList,startState,elseCase,cache,env,rightHandList)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      list<Absyn.Exp> localResVarList,localInputVarList;
      list<Absyn.ElementItem> newVars;
      RightHandList localRightHandList;
    case (localResVarList,localInputVarList,localStartState,NONE(),localCache,
        localEnv,localRightHandList) // NO ELSE-CASE
      local
        State localStartState;
        list<Absyn.AlgorithmItem> algs,algs2;
        Absyn.AlgorithmItem algItem1,algItem2;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
      equation
        // The DFA Environment is used to store the type of some path variables. It is used
        // when we want to get the type of a list variable. Since the input variables
        // are the outermost path variables, we add them to this environment.
        (dfaEnv,localCache) = addVarsToDfaEnv(localInputVarList,{},localCache,localEnv);

        // while() {
        // try {
        // if (...)
        // ...
        // break();
        // ---- A NON-MATCH SHOULD BE HANDLED HERE ----
        // finalstate1:
        // ...
        // break();
        // ...
        // finalstateN:
        // ...
        // break();
        // } catch (int i) {
        // BOOLVAR__[LASTRIGHTHANDSIDE__] = 0;
        //}
        // }
        // if (NOTDONE__) throw 1;
        //
        (localCache,algs,newVars) = fromStatetoAbsynCode(localStartState,NONE(),localCache,localEnv,dfaEnv,{},false);
        //------
        algs = listAppend(algs,{Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),NONE())});
        algs2 = generateFinalStates(localRightHandList,{},localResVarList);
        algs = listAppend(algs,algs2);
        //------

        algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_TRY(algs),NONE());
        algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_CATCH({Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(
          Absyn.CREF_IDENT("BOOLVAR__",{Absyn.SUBSCRIPT(Absyn.CREF(Absyn.CREF_IDENT("LASTRIGHTHANDSIDE__",{})))})),
          Absyn.INTEGER(0)),NONE())}),NONE());
        algs = listAppend({algItem1},{algItem2});
        algs = {Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(Absyn.BOOL(true)
          ,algs),NONE())};
        //algItem1 = Absyn.ALGORITHMITEM(Absyn.ALG_THROW(),NONE());
        //algItem2 = Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.CREF(Absyn.CREF_IDENT("NOTDONE__",{})),{algItem1},{},{}),NONE());
        //algs = listAppend(algs,{algItem2});

      then (localCache,algs,newVars);
   // ELSE-CASE
    case (localResVarList,localInputVarList,localStartState,SOME(RIGHTHANDSIDE(localVars,algList2,res,_)),
        localCache,localEnv,localRightHandList) // AN ELSE-CASE EXIST
      local
        list<Absyn.ElementItem> localVars;
        list<Absyn.AlgorithmItem> algList,algList2,algList3,bodyIf,algIf;
        Absyn.Exp res,resExpr;
        State localStartState;
        list<Absyn.Exp> expList;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
      equation
        // The DFA Environment is used to store the type of some path variables. It is used
        // when we want to get the type of a list variable. Since the input variables
        // are the outermost path variables, we add them to this environment.
        (dfaEnv,localCache) = addVarsToDfaEnv(localInputVarList,{},localCache,localEnv);

        (localCache,algList,newVars) = fromStatetoAbsynCode(localStartState,NONE(),localCache,localEnv,dfaEnv,{},false);

        // Create result assignments
        expList = createListFromExpression(res);
        algList3 = createLastAssignments(localResVarList,expList,{});

        algList2 = listAppend(algList2,algList3);

        bodyIf = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("DUMMIE__",{})),
          Absyn.VALUEBLOCK(localVars,Absyn.VALUEBLOCKALGORITHMS(algList2),Absyn.BOOL(true))),NONE())};

        algIf = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.CREF(
          Absyn.CREF_IDENT("NOTDONE__",{})),bodyIf,{},{}),NONE())};

        algList = listAppend(algList,algIf);
        algList = listAppend(algList,{Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),NONE())});
        //------
        algList2 = generateFinalStates(localRightHandList,{},localResVarList);
        algList = listAppend(algList,algList2);
        //------

        // while(NOTDONE__) {
        // try {
        // if (...)
        // ...
        // if (NOTDONE__) {valueblock (<ELSE-CASE>)}
        // break();
        // ---- A NON-MATCH SHOULD BE HANDLED HERE ----
        // finalstate1:
        // ...
        // break();
        // ...
        // finalstateN:
        // ...
        // break();
        // } catch (int i) {
        // BOOLVAR__[LASTRIGHTHANDSIDE__] = 0;
        //}
        // }
        algList2 = {Absyn.ALGORITHMITEM(Absyn.ALG_TRY(algList),NONE())};
        algList3 = {Absyn.ALGORITHMITEM(Absyn.ALG_CATCH({Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(
          Absyn.CREF_IDENT("BOOLVAR__",{Absyn.SUBSCRIPT(Absyn.CREF(Absyn.CREF_IDENT("LASTRIGHTHANDSIDE__",{})))})),
          Absyn.INTEGER(0)),NONE())}),NONE())};
        algList = listAppend(algList2,algList3);
        algList = {Absyn.ALGORITHMITEM(Absyn.ALG_WHILE(Absyn.CREF(Absyn.CREF_IDENT("NOTDONE__",{}))
          ,algList),NONE())};

      then (localCache,algList,newVars);
  end matchcontinue;
end generateAlgorithmBlock;
*/

/*
protected function generateFinalStates "function: generateFinalStates
Generates the final states.
        finalstate1:
         ...
         return();
         ...
         finalstateN:
         ...
         return();
"
  input RightHandList inList;
  input list<Absyn.AlgorithmItem> accList;
  input list<Absyn.Exp> resVarList;
  output list<Absyn.AlgorithmItem> outList;
algorithm
  outList :=
  matchcontinue (inList,accList,resVarList)
    local
      RightHandList rest;
      list<Absyn.AlgorithmItem> localAccList;
      list<Absyn.Exp> localResVarList;
    case ({},localAccList,_) then localAccList;
      // No local variables
    case (RIGHTHANDSIDE({},body,result,caseNum) :: rest,localAccList,localResVarList)
      local
        Integer caseNum;
        Absyn.Exp result,resVars;
        list<Absyn.AlgorithmItem> outList,body,lastAssign,doneAssign,stateAssign;
        String stateName;
        RightHandList rest;
        list<Absyn.Exp> exp2;
      equation
        // finalStateN:
        // LASTRIGHTHANDSIDE__ = caseNum;
        // <CODE>
        // resVar1 = ...;
        // ...
        // resVarX = ...;
        // NOTDONE__ = false;
        // break();

        exp2 = createListFromExpression(result);

        // Create the assignments that assigns the return variables
        lastAssign = createLastAssignments(localResVarList,exp2,{});

        stateAssign = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("LASTRIGHTHANDSIDE__",{})),
          Absyn.INTEGER(caseNum)),NONE())};
        outList = listAppend(stateAssign,body);
        outList = listAppend(outList,lastAssign);

        // Set NOTDONE__ to false
        doneAssign = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("NOTDONE__",{})),
          Absyn.BOOL(false)),NONE())};
        outList = listAppend(outList,doneAssign);

        stateName = stringAppend("finalstate",intString(caseNum));
        stateAssign = {Absyn.ALGORITHMITEM(Absyn.ALG_LABEL(stateName),NONE())};
        outList = listAppend(stateAssign,outList);
        stateAssign = {Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),NONE())};
        outList = listAppend(outList,stateAssign);

        localAccList = listAppend(localAccList,outList);
        localAccList = generateFinalStates(rest,localAccList,localResVarList);
      then localAccList;

        // Local variables
    case (RIGHTHANDSIDE(localList,body,result,caseNum) :: rest,localAccList,localResVarList)
      local
        list<Absyn.EquationItem> equations;
        list<Absyn.ElementItem> localList;
        Absyn.Exp result,vBlock,resVars;
        list<Absyn.AlgorithmItem> outList,body,lastAssign,doneAssign,stateAssign;
        String stateName;
        Integer caseNum;
        RightHandList rest;
        list<Absyn.Exp> exp2;
      equation
        // finalstateN:
        // {
        // <VAR-DECL>
        // LASTRIGHTHANDSIDE = caseNum;
        // <CODE>
        // resVar1 = ...;
        // ...
        // resVarX = ...;
        // NOTDONE__ = false;
        // }
        // break();
        exp2 = createListFromExpression(result);

        // Create the assignments that assign the return variables
        lastAssign = createLastAssignments(localResVarList,exp2,{});

        stateAssign = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("LASTRIGHTHANDSIDE__",{})),
          Absyn.INTEGER(caseNum)),NONE())};
        outList = listAppend(stateAssign,body);

        outList = listAppend(outList,lastAssign);

        // Set NOTDONE__ to false
        doneAssign = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("NOTDONE__",{})),
          Absyn.BOOL(false)),NONE())};
        outList = listAppend(outList,doneAssign);
        vBlock = Absyn.VALUEBLOCK(localList,Absyn.VALUEBLOCKALGORITHMS(outList),Absyn.BOOL(true));
        outList = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("DUMMIE__",{})),vBlock),NONE())};

        stateName = stringAppend("finalstate",intString(caseNum));
        stateAssign = {Absyn.ALGORITHMITEM(Absyn.ALG_LABEL(stateName),NONE())};
        outList = listAppend(stateAssign,outList);

        stateAssign = {Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),NONE())};
        outList = listAppend(outList,stateAssign);

        localAccList = listAppend(localAccList,outList);
        localAccList = generateFinalStates(rest,localAccList,localResVarList);
      then localAccList;
  end matchcontinue;
end generateFinalStates;
*/

/*
protected function fromStatetoAbsynCode "function: fromStatetoAbsynCode
 	author: KS
 	Takes a DFA state and recursively generates if-else nodes by investigating
	 the outgoing arcs.
"
  input State state;
  input Option<RenamedPat> inPat;
  input Env.Cache cache;
  input Env.Env env;
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
  input list<Absyn.ElementItem> accNewVars;
  input Boolean lightVs;
  output Env.Cache outCache;
  output list<Absyn.AlgorithmItem> ifNodes;
  output list<Absyn.ElementItem> outNewVars; // New variables from Constructor-call patterns
algorithm
  (outCache,ifNodes,outNewVars) :=
  matchcontinue (state,inPat,cache,env,dfaEnv,accNewVars,lightVs)
    local
      Stamp stamp;
      Absyn.Ident stateVar,localInStateVar;
      RenamedPat localInPat,pat;
      Env.Cache localCache;
      Env.Env localEnv;
      list<tuple<Absyn.Ident,Absyn.TypeSpec>> localDfaEnv;
      list<Absyn.Exp> exp2;
      Integer localRetExpLen;
      String stateName;
      list<Absyn.ElementItem> localAccNewVars;
      Boolean localLightVs;
      // JUST TO BE SURE
    case (DUMMIESTATE(),_,localCache,_,_,localAccNewVars,_) equation then (localCache,{},localAccNewVars);

      // GOTO STATE
    case (GOTOSTATE(_,n),_,localCache,_,_,localAccNewVars,_)
      local
        list<Absyn.AlgorithmItem> outElems;
        Integer n;
        String s;
      equation
        s = stringAppend("state",intString(n));
        outElems = {Absyn.ALGORITHMITEM(Absyn.ALG_GOTO(s),NONE())};
      then (localCache,outElems,localAccNewVars);

      //FINAL STATE
    case(STATE(stamp,_,_,SOME(RIGHTHANDLIGHT(n))),_,localCache,_,_,localAccNewVars,false)
      local
        list<Absyn.AlgorithmItem> outList;
        String s;
        Integer n;
      equation
        s = stringAppend("finalstate",intString(n));
        outList = {Absyn.ALGORITHMITEM(Absyn.ALG_GOTO(s),NONE())};
      then (localCache,outList,localAccNewVars);

        // Light Version
    case(STATE(stamp,_,_,SOME(RIGHTHANDLIGHT(n))),_,localCache,_,_,localAccNewVars,true)
      local
        list<Absyn.AlgorithmItem> outList;
        Integer n;
      equation
        outList = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT("DUMMIE__",{})),Absyn.BOOL(false)),NONE())};
      then (localCache,outList,localAccNewVars);

        // THIS IS A TEST STATE, INCOMING ARC WAS AN ELSE-ARC OR THIS IS THE FIRST STATE
    case (STATE(stamp,_,arcs as (ARC(_,_,SOME(pat),_) :: _),NONE()),NONE(),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      local
        list<Arc> arcs;
        list<Absyn.AlgorithmItem> algList,stateAssign;
      equation

        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(arcs,extractPathVar(pat),true,Absyn.INTEGER(0),{},{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);

        stateAssign = generateLabelNode(stamp,localLightVs);

        algList = listAppend(stateAssign,algList);
      then (localCache,algList,localAccNewVars);

        // THIS IS A TEST STATE (INCOMING ARC WAS A CONSTRUCTOR, CONS OR CONSTRUCTOR-CALL)
    case (STATE(stamp,_,arcs as (ARC(_,_,SOME(pat),_) :: _),NONE()),SOME(localInPat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      local
        list<Arc> arcs;
        list<Absyn.AlgorithmItem> algList,bindings2,pathAssignList,stateAssign;
        list<Absyn.ElementItem> declList;
        Absyn.Exp valueBlock;
      equation
        true = constructorOrNot(localInPat);

        // The following function, generatePathVarDeclarations, will
        // generate new variables and bindings. For instance if we
        // have a record RECNAME{ TYPE1 field1, TYPE2 field2 } :
        //
        // if (getType(x) = RECNAME)
        // stateN:
        // x__1 = x.field1;
        // x__2 = x.field2;
        //
        // The new variables are added to the declaration section of the whole
        // pattern match statement.
        (localCache,localDfaEnv,declList,pathAssignList) = generatePathVarDeclarations(localInPat,localCache,localEnv,localDfaEnv);
        localAccNewVars = listAppend(localAccNewVars,declList);

        (localCache,algList,localAccNewVars) =
        generateIfElseifAndElse(arcs,extractPathVar(pat),true,Absyn.INTEGER(0),{},{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);

        algList = listAppend(pathAssignList,algList);

        stateAssign = generateLabelNode(stamp,localLightVs);
        algList = listAppend(stateAssign,algList);

      then (localCache,algList,localAccNewVars);

        //TEST STATE,THE ARC TO THIS STATE WAS NOT A CONSTRUCTOR
    case(STATE(stamp,_,arcs as (ARC(_,_,SOME(pat),_) :: _),NONE()),SOME(localInPat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      local
        list<Arc> arcs;
        list<Absyn.AlgorithmItem> algList,stateAssign;
      equation
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(arcs,extractPathVar(pat),true,Absyn.INTEGER(0),{},{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);

        stateAssign = generateLabelNode(stamp,localLightVs);
        algList = listAppend(stateAssign,algList);

      then (localCache,algList,localAccNewVars);
  end matchcontinue;
end fromStatetoAbsynCode;
*/

protected function generateLabelNode "function: generateLabelNode
For a light version no states are generated. A light version
is generated when we only have one case clause in a matchcontinue
expression.
"
  input Integer stamp;
  input Boolean lightVs;
  output list<Absyn.AlgorithmItem> outList;
algorithm
  outList :=
  matchcontinue(stamp,lightVs)

    case (_,true) then {};
    case (localStamp,false)
      local
        list<Absyn.AlgorithmItem> lst;
        String stateName; Integer localStamp;
      equation
        stateName = stringAppend("state",intString(localStamp));
        lst = {Absyn.ALGORITHMITEM(Absyn.ALG_LABEL(stateName),NONE())};
      then lst;
  end matchcontinue;
end generateLabelNode;


protected function createLastAssignments "function: createLastAssignments
	author: KS
	Creates the assignments that will assign the result variables
	the final values.
	(v1,v2...vN) := matchcontinue (x,y,...)
                case (...) then (1,2,...,N);
	Here v1,v2,...,vN should be assigned the values 1,2,...N.
"
  input list<Absyn.Exp> lhsList;
  input list<Absyn.Exp> rhsList;
  input list<Absyn.AlgorithmItem> accList;
  output list<Absyn.AlgorithmItem> outList;
algorithm
  outList :=
  matchcontinue (lhsList,rhsList,accList)
    local
      list<Absyn.AlgorithmItem> localAccList;
      Absyn.Exp firstLhs,firstRhs;
      list<Absyn.Exp> restLhs,restRhs;
      Absyn.AlgorithmItem elem;
      String str;
    case ({},{},localAccList) then localAccList;

    /* The case: then fail(); */
    case(_,Absyn.CALL(Absyn.CREF_IDENT("fail",_),_) :: {},_)
      local
      equation
        localAccList = {Absyn.ALGORITHMITEM(Absyn.ALG_BREAK(),NONE)};
      then localAccList;
    /*------------------------*/

    /* The case: then (); */
    case (_,Absyn.TUPLE({}) :: _,_) then {};

    /* The case: then ();
     * A tuple of 0 elements isn't a tuple according to the parser?
     * Handle wild := matchcontinue ... then (); // sjoelund */
    case ({Absyn.CREF(Absyn.WILD)},{},_) then {};

    case (firstLhs :: restLhs,firstRhs :: restRhs,localAccList)
      equation
        elem = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(firstLhs,firstRhs),NONE);
        localAccList = listAppend(localAccList,{elem});
        localAccList = createLastAssignments(restLhs,restRhs,localAccList);
      then localAccList;
    
    case (_,_,_)
      equation
        Debug.fprintln("matchcase", "- DFA.createLastAssignments failed");
      then fail();
  end matchcontinue;
end createLastAssignments;

protected function generatePathVarDeclarations "function: generatePathVarDeclerations
	author: KS
	Used when we have a record constructor call in a pattern and we need to
	create path variables of the subpatterns of the record constructor.
"
  input RenamedPat pat;
  input Env.Cache cache;
  input Env.Env env;
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
  output Env.Cache outCache;
  output list<tuple<Absyn.Ident,Absyn.TypeSpec>> outDfaEnv;
  output list<Absyn.ElementItem> outDecl;
  output list<Absyn.AlgorithmItem> outAssigns;
algorithm
  (outCache,outDfaEnv,outDecl,outAssigns) :=
  matchcontinue (pat,cache,env,dfaEnv)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      list<tuple<Absyn.Ident,Absyn.TypeSpec>> localDfaEnv;
    case (RP_CONS(pathVar,first,second),localCache,localEnv,localDfaEnv)
      local
        Absyn.Ident pathVar;
        RenamedPat first,second;
        list<Absyn.ElementItem> elem1,elem2;
        Absyn.Ident firstPathVar,secondPathVar;
        Absyn.TypeSpec t;
        list<Absyn.AlgorithmItem> assignList;
        Absyn.AlgorithmItem assign1,assign2;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem1,dfaEnvElem2;
      equation
        //Example:
        // if (x == CONS)    -- (This comparison will not occure)
        // TYPE1 pathVar__1;
        // list<TYPE1> pathVar__2;
        // pathVar__1 = listCar(x,1);
        // pathVar__2 = listCdr(x,2);

        // The variable should be found in the DFA environment
        Absyn.TCOMPLEX(Absyn.IDENT("list"),{t},NONE()) = lookupTypeOfVar(localDfaEnv,pathVar);

        firstPathVar = extractPathVar(first);
        elem1 = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            t,
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(firstPathVar,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        secondPathVar = extractPathVar(second);
        elem2 = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TCOMPLEX(Absyn.IDENT("list"),{t},NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(secondPathVar,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        // Add the new variables to the DFA environment
        // For example, if we have a pattern:
        // RP_CONS(x,RP_INTEGER(x__1,1),RP_CONS(x__2,RP_INTEGER(x__2__1,2),RP_EMPTYLIST(x__2__2)))
        // Then we must know the type of x__2 when arriving to the second
        // RP_CONS pattern
        dfaEnvElem1 = {(firstPathVar,t)};
        dfaEnvElem2 = {(secondPathVar,Absyn.TCOMPLEX(Absyn.IDENT("list"),{t},NONE()))};
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem1);
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem2);
        elem1 = listAppend(elem1,elem2);

        assign1 = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(firstPathVar,{})),
          Absyn.CALL(Absyn.CREF_IDENT("listGet",{}),Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(pathVar,{})),Absyn.INTEGER(1)},{}))),NONE());
        assign2 = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(Absyn.CREF(Absyn.CREF_IDENT(secondPathVar,{})),
          Absyn.CALL(Absyn.CREF_IDENT("listRest",{}),Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(pathVar,{}))},{}))),NONE());

        assignList = listAppend({assign1},{assign2});
      then (localCache,localDfaEnv,elem1,assignList);
    case (RP_CALL(pathVar,cRef,argList),localCache,localEnv,localDfaEnv)
      local
        Absyn.Ident pathVar,recName;
        list<Absyn.Ident> pathVarList,fieldNameList;
        list<RenamedPat> argList;
        SCode.Class sClass;
        list<Absyn.TypeSpec> fieldTypes;
        Absyn.Path pathName;
        list<Absyn.ElementItem> elemList;
        list<Absyn.AlgorithmItem> assignList;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem;
        Absyn.ComponentRef cRef;
      equation
        pathName = Absyn.crefToPath(cRef);
        recName = Absyn.pathString(pathName);

        // For instance if we have
        // a record RECNAME{ TYPE1 field1, TYPE2 field2 } :
        //
        // if (getType(pathVar) = RECNAME)
        // TYPE1 pathVar__1;
        // TYPE2 pathVar__2;
        // x__1 = pathVar.field1;
        // x__2 = pathVar.field2;

        pathVarList = Util.listMap(argList,extractPathVar);
        // Get recordnames
        (localCache,sClass,localEnv) = Lookup.lookupClass(localCache,localEnv,pathName,true);
        (fieldNameList,fieldTypes) = extractFieldNamesAndTypes(sClass);

        dfaEnvElem = mergeLists(pathVarList,fieldTypes,{});
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem);

        assignList = createPathVarAssignments(pathVar,pathVarList,fieldNameList,{},0);
        elemList = createPathVarDeclarations(pathVarList,fieldTypes,{});
      then (localCache,localDfaEnv,elemList,assignList);
    case (RP_TUPLE(pathVar,argList),localCache,localEnv,localDfaEnv)
      local
        Absyn.Ident pathVar;
        list<RenamedPat> argList;
        list<Absyn.TypeSpec> fieldTypes;
        list<Absyn.AlgorithmItem> assignList;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem;
        list<Absyn.Ident> pathVarList;
        list<Absyn.ElementItem> elemList;
      equation
        //Example:
        // if (x == TUPLE)    -- (This comparison will not occure)
        // TYPE1 pathVar__1;
        // TYPE2 pathVar__2;
        // ...
        // pathVar__1 = metaMGetField(x,1);
        // pathVar__2 = metaMGetField(x,2);
        // ...

        // The variable should be found in the DFA environment
        Absyn.TCOMPLEX(Absyn.IDENT("tuple"),fieldTypes,NONE()) = lookupTypeOfVar(localDfaEnv,pathVar);

        pathVarList = Util.listMap(argList,extractPathVar);
        dfaEnvElem = mergeLists(pathVarList,fieldTypes,{});
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem);

        assignList = createPathVarAssignments(pathVar,pathVarList,{},{},1);
        elemList = createPathVarDeclarations(pathVarList,fieldTypes,{});
      then (localCache,localDfaEnv,elemList,assignList);

    case (RP_SOME(pathVar,arg),localCache,localEnv,localDfaEnv)
      local
        Absyn.Ident pathVar,pathVar2;
        RenamedPat arg;
        list<Absyn.TypeSpec> fieldTypes;
        list<Absyn.AlgorithmItem> assignList;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem;
        list<Absyn.Ident> pathVarList;
        list<Absyn.ElementItem> elemList;
      equation
        //Example:
        // if (x == SOME)    -- (This comparison will not occure)
        // TYPE1 pathVar__1;
        // pathVar__1 = metaMGetField(x,1);

        // The variable should be found in the DFA environment
        Absyn.TCOMPLEX(Absyn.IDENT("Option"),fieldTypes,NONE()) = lookupTypeOfVar(localDfaEnv,pathVar);
        pathVar2=extractPathVar(arg);
        pathVarList = {pathVar2};
        dfaEnvElem = mergeLists(pathVarList,fieldTypes,{});
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem);

        assignList = createPathVarAssignments(pathVar,pathVarList,{},{},1);
        elemList = createPathVarDeclarations(pathVarList,fieldTypes,{});
      then (localCache,localDfaEnv,elemList,assignList);
      
    case (_,localCache,localEnv,localDfaEnv)
      then (localCache,localDfaEnv,{},{});
  end matchcontinue;
end generatePathVarDeclarations;

public function extractFieldNamesAndTypes 
"function: extractFieldNamesAndTypes
	author: KS"
  input SCode.Class sClass;
  output list<Absyn.Ident> fieldNameList;
  output list<Absyn.TypeSpec> fieldTypes;
algorithm
  (fieldNameList,fieldTypes) := matchcontinue (sClass)
    local
      list<Absyn.Ident> fNameList;
      list<Absyn.TypeSpec> fTypes;
      list<SCode.Element> elemList;
    case (SCode.CLASS(_,_,_,_,SCode.PARTS(elemList,_,_,_,_,_,_)))
      equation
        fNameList = Util.listMap(elemList,extractFieldName);
        fTypes = Util.listMap(elemList,extractFieldType);
      then (fNameList,fTypes);
    /* adrpo: handle also the case model extends X end X; */
    case (SCode.CLASS(_,_,_,_,SCode.CLASS_EXTENDS(_,_,elemList,_,_,_,_,_)))
      equation
        fNameList = Util.listMap(elemList,extractFieldName);
        fTypes = Util.listMap(elemList,extractFieldType);
      then (fNameList,fTypes);
  end matchcontinue;
end extractFieldNamesAndTypes;

public function extractFieldName 
"function: extractFieldName
	author: KS"
  input SCode.Element elem;
  output Absyn.Ident id;
algorithm
  id := matchcontinue (elem)
    local Absyn.Ident localId;
    case (SCode.COMPONENT(localId,_,_,_,_,_,_,_,_,_,_,_,_)) then localId;
  end matchcontinue;
end extractFieldName;

public function extractFieldType 
"function: extractFieldType
	author: KS"
  input SCode.Element elem;
  output Absyn.TypeSpec typeSpec;
algorithm
  typeSpec := matchcontinue (elem)
    local Absyn.TypeSpec t;    
    case (SCode.COMPONENT(typeSpec = t)) then t;
  end matchcontinue;
end extractFieldType;

protected function createPathVarDeclarations 
"function: createPathVarAssignments
	author: KS
	Used when we have a record constructor call in a pattern and we need to
	create path variables of the subpatterns of the record constructor."
  input list<Absyn.Ident> pathVars;
  input list<Absyn.TypeSpec> recTypes;
  input list<Absyn.ElementItem> accElemList;
  output list<Absyn.ElementItem> elemList;
algorithm
  elemList := matchcontinue (pathVars,recTypes,accElemList)
    local
      list<Absyn.ElementItem> localAccElemList,elem;
      Absyn.Ident localRecName,firstPathVar;
      list<Absyn.Ident> restPathVars;
      Absyn.TypeSpec firstType;
      list<Absyn.TypeSpec> restTypes;
    case ({},{},localAccElemList) then localAccElemList;
    case (firstPathVar :: restPathVars, firstType :: restTypes,localAccElemList)
      equation
        elem = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            firstType,
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(firstPathVar,{},NONE())
            ,NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};
        localAccElemList = listAppend(localAccElemList,elem);
        localAccElemList = createPathVarDeclarations(restPathVars,restTypes,localAccElemList);
    then localAccElemList;
  end matchcontinue;
end createPathVarDeclarations;

/*
protected function generateIfElseifAndElse 
"function: generateIfElseifAndElse
	author: KS
	Generate if-statements."
  input list<Arc> arcs;
  input Absyn.Ident stateVar;
  input Boolean ifOrNotBool;
  input Absyn.Exp trueStatement;
  input list<Absyn.AlgorithmItem> trueBranch;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseIfBranch;
  input Env.Cache cache;
  input Env.Env env;
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
  input list<Absyn.ElementItem> accNewVars;
  input Boolean lightVs;
  output Env.Cache outCache;
  output list<Absyn.AlgorithmItem> outList;
  output list<Absyn.ElementItem> outNewVars;
algorithm
  (outCache,outList,outNewVars) :=
  matchcontinue (arcs,stateVar,ifOrNotBool,trueStatement,trueBranch,elseIfBranch,cache,env,dfaEnv,accNewVars,lightVs)
    local
      State localState;
      list<Arc> rest;
      Absyn.Ident localStateVar;
      RenamedPat pat;
      Absyn.Exp localTrueStatement,branchCheck;
      list<Absyn.AlgorithmItem> localTrueBranch,localElseBranch,algList;
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> localElseIfBranch;
      list<tuple<Absyn.Exp,list<Absyn.AlgorithmItem>>> eeElseIfBranch;
      Env.Cache localCache;
      Env.Env localEnv;
      list<tuple<Absyn.Ident,Absyn.TypeSpec>> localDfaEnv;
      tuple<Absyn.Exp,list<Absyn.AlgorithmItem>> tup;
      Integer localRetExpLen;
      list<Integer> caseNumbers;
      list<Absyn.ElementItem> localAccNewVars;
      Boolean localLightVs;
      Absyn.Exp exp,constVal,firstExp;
      list<Absyn.AlgorithmItem> eIfBranch;
      Absyn.Ident recordName;
      list<Absyn.Exp> tempList;
      Absyn.ComponentRef cRef;              
    case({},_,_,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,_,_,localAccNewVars,_)
      equation
        algList = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(localTrueStatement,localTrueBranch,localElseIfBranch,{}),NONE())};
      then (localCache,algList,localAccNewVars);
        
    // DummieState
    case(ARC(DUMMIESTATE(),_,_,_) :: _,_,_,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,_,_,localAccNewVars,_)
      equation
        //print("DUMMIE STATE\n");
        algList = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(localTrueStatement,localTrueBranch,localElseIfBranch,{}),NONE())};
      then (localCache,algList,localAccNewVars);

    // Else case
    case(ARC(localState,_,NONE(),caseNumbers) :: _,localStateVar,_,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      
      equation
        // For the catch handling
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        (localCache,localElseBranch,localAccNewVars) = fromStatetoAbsynCode(localState,NONE(),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        eeElseIfBranch = {(branchCheck,localElseBranch)};
        localElseIfBranch = listAppend(localElseIfBranch,eeElseIfBranch);
        algList = {Absyn.ALGORITHMITEM(Absyn.ALG_IF(localTrueStatement,localTrueBranch,localElseIfBranch,{}),NONE())};
      then (localCache,algList,localAccNewVars);

    //If, Wildcard case
    case(ARC(localState,_,SOME(pat as RP_WILDCARD(_)),caseNumbers) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,localTrueBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,branchCheck,localTrueBranch,{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //If, Cons case
    case(ARC(localState,_,SOME(pat as RP_CONS(_,_,_)),caseNumbers) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,localTrueBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        exp = Absyn.LBINARY(branchCheck,Absyn.AND(),Absyn.LUNARY(Absyn.NOT(),Absyn.CALL(Absyn.CREF_IDENT("listEmpty",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{}))));
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,exp,localTrueBranch,{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //If, tuple case
    case(ARC(localState,_,SOME(pat as RP_TUPLE(_,_)),caseNumbers) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,localTrueBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,branchCheck,localTrueBranch,{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //If, SOME case
    case(ARC(localState,_,SOME(pat as RP_SOME(_,_)),caseNumbers) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,localTrueBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        exp = Absyn.LBINARY(branchCheck,Absyn.AND(),Absyn.LUNARY(Absyn.NOT(),Absyn.CALL(Absyn.CREF_IDENT("optionNone",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{}))));
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,exp,localTrueBranch,{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //If, CONSTANT
    case(ARC(localState,_,SOME(pat),caseNumbers) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,localTrueBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        constVal = getConstantValue(pat);
        firstExp = createConstCompareExp(constVal,localStateVar);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        exp = Absyn.LBINARY(firstExp,Absyn.AND(),branchCheck);
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,exp,localTrueBranch,{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //If, CALL case
    case(ARC(localState,_,SOME(pat as RP_CALL(_,cRef,_)),caseNumbers) :: rest,localStateVar,true,_,_,_,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        recordName = Absyn.pathString(Absyn.crefToPath(cRef));
        (localCache,localTrueBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        tempList = {Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))};
        exp = Absyn.LBINARY(Absyn.CALL(Absyn.CREF_IDENT("stringCmp",{}),Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_QUAL(localStateVar,{},Absyn.CREF_IDENT("fieldTag__",{})))
          ,Absyn.STRING(recordName)},{})),Absyn.AND(),branchCheck);
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,exp,localTrueBranch,{},localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);
        
    //Elseif, wildcard
    case(ARC(localState,_,SOME(pat as RP_WILDCARD(_)),caseNumbers) :: rest,localStateVar,false,localTrueStatement,
        localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,eIfBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        tup = (branchCheck,eIfBranch);
        localElseIfBranch = listAppend(localElseIfBranch,{tup});
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //Elseif, cons
    case(ARC(localState,_,SOME(pat as RP_CONS(_,_,_)),caseNumbers) :: rest,localStateVar,false,localTrueStatement,
        localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,eIfBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        exp = Absyn.LBINARY(branchCheck,Absyn.AND(),Absyn.LUNARY(Absyn.NOT(),Absyn.CALL(Absyn.CREF_IDENT("listEmpty",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{}))));
        tup = (exp,eIfBranch);
        localElseIfBranch = listAppend(localElseIfBranch,{tup});
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //Elseif, tuple
    case(ARC(localState,_,SOME(pat as RP_TUPLE(_,_)),caseNumbers) :: rest,localStateVar,false,localTrueStatement,
        localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,eIfBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        tup = (branchCheck,eIfBranch);
        localElseIfBranch = listAppend(localElseIfBranch,{tup});
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //Elseif, some
    case(ARC(localState,_,SOME(pat as RP_SOME(_,_)),caseNumbers) :: rest,localStateVar,false,localTrueStatement,
        localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        (localCache,eIfBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        exp = Absyn.LBINARY(branchCheck,Absyn.AND(),Absyn.LUNARY(Absyn.NOT(),Absyn.CALL(Absyn.CREF_IDENT("optionNone",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{}))));
        tup = (exp,eIfBranch);
        localElseIfBranch = listAppend(localElseIfBranch,{tup});
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //Elseif, call
    case(ARC(localState,_,SOME(pat as RP_CALL(_,cRef,_)),caseNumbers) :: rest,localStateVar,false,localTrueStatement,
        localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        recordName = Absyn.pathString(Absyn.crefToPath(cRef));
        (localCache,eIfBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        tempList = {Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))};
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        exp = Absyn.LBINARY(Absyn.CALL(Absyn.CREF_IDENT("stringCmp",{}),Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_QUAL(localStateVar,{},Absyn.CREF_IDENT("fieldTag__",{}))),
          Absyn.STRING(recordName)},{})),Absyn.AND(),branchCheck);
        tup = (exp,eIfBranch);
        localElseIfBranch = listAppend(localElseIfBranch,{tup});
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);

    //Elseif, constant
    case(ARC(localState,_,SOME(pat),caseNumbers) :: rest,localStateVar,false,localTrueStatement,
        localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs)
      equation
        constVal = getConstantValue(pat);
        (localCache,eIfBranch,localAccNewVars) = fromStatetoAbsynCode(localState,SOME(pat),localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
        firstExp = createConstCompareExp(constVal,localStateVar);
        branchCheck = generateBranchCheck(caseNumbers,Absyn.BOOL(true),localLightVs);
        exp = Absyn.LBINARY(firstExp,Absyn.AND(),branchCheck);
        tup = (exp,eIfBranch);
        localElseIfBranch = listAppend(localElseIfBranch,{tup});
        (localCache,algList,localAccNewVars) = generateIfElseifAndElse(rest,localStateVar,false,localTrueStatement,localTrueBranch,localElseIfBranch,localCache,localEnv,localDfaEnv,localAccNewVars,localLightVs);
      then (localCache,algList,localAccNewVars);
  end matchcontinue;
end generateIfElseifAndElse;
*/

protected function generateBranchCheck "function: generateBranchCheck"
  input list<Integer> inList;
  input Absyn.Exp inExp;
  input Boolean lightVs;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (inList,inExp,lightVs)
    local
      Absyn.Exp localInExp;

    case (_,_,true) then Absyn.BOOL(true);

    case ({},localInExp,false) then localInExp;

    // First time
    case (firstNum :: restNum,Absyn.BOOL(true),false)
      local
        Integer firstNum;
        list<Integer> restNum;
      equation
        localInExp = Absyn.RELATION(Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{Absyn.SUBSCRIPT(Absyn.INTEGER(firstNum))})),
          Absyn.EQUAL(),Absyn.INTEGER(1));
        localInExp = generateBranchCheck(restNum,localInExp,false);
      then localInExp;
    //----------------

    case (firstNum :: restNum,localInExp,false)
      local
        Integer firstNum;
        list<Integer> restNum;
      equation
        localInExp = Absyn.LBINARY(localInExp,Absyn.OR(),
          Absyn.RELATION(Absyn.CREF(Absyn.CREF_IDENT("BOOLVAR__",{Absyn.SUBSCRIPT(Absyn.INTEGER(firstNum))})),
          Absyn.EQUAL(),Absyn.INTEGER(1)));
        localInExp = generateBranchCheck(restNum,localInExp,false);
      then localInExp;
  end matchcontinue;
end generateBranchCheck;

protected function createConstCompareExp "function: createConstCompareExp
Used by generateIfElseifAndElse
when we want two write an expression for comparing constants
"
  input Absyn.Exp constVal;
  input Absyn.Ident stateVar;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (constVal,stateVar)
    local
      Integer i;
      Real r;
      String s;
      Boolean b;
      Absyn.Exp exp;
      Absyn.Ident localStateVar;
    case (Absyn.INTEGER(i),localStateVar)
      equation
      exp = Absyn.RELATION(Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})),
        Absyn.EQUAL(),Absyn.INTEGER(i));
      then exp;
    case (Absyn.REAL(r),localStateVar)
      equation
        exp = Absyn.RELATION(Absyn.CALL(Absyn.CREF_IDENT("String",{}),
          Absyn.FUNCTIONARGS({Absyn.REAL(r),Absyn.INTEGER(5)},{})),
            Absyn.EQUAL(),Absyn.CALL(Absyn.CREF_IDENT("String",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})),Absyn.INTEGER(5)},{})));
      then exp;
    case (Absyn.STRING(s),localStateVar)
      equation
        exp = Absyn.RELATION(Absyn.STRING(s),Absyn.EQUAL(),Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})));
      then exp;
    case (Absyn.BOOL(b),localStateVar)
      equation
        exp = Absyn.RELATION(Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{})),
          Absyn.EQUAL(),Absyn.BOOL(b));
      then exp;
    case (Absyn.LIST({}),localStateVar)
      equation
        exp = Absyn.CALL(Absyn.CREF_IDENT("listEmpty",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{}));
      then exp;
    case (Absyn.CREF(Absyn.CREF_IDENT("NONE",{})),localStateVar)
      equation
        exp = Absyn.CALL(Absyn.CREF_IDENT("optionNone",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localStateVar,{}))},{}));
      then exp;
 end matchcontinue;
end createConstCompareExp;

protected function createListFromExpression "function: createListFromExpression"
  input Absyn.Exp exp;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (exp)
    local
      list<Absyn.Exp> l;
      Absyn.Exp e;
    case(Absyn.TUPLE(l)) then l;
    case (e)
      equation
        l = {e};
      then l;
  end matchcontinue;
end createListFromExpression;

public function boolString "function:: boolString"
  input Boolean bool;
  output String str;
algorithm
  str :=
  matchcontinue (bool)
    case (true) equation then "true";
    case (false) equation then "false";
  end matchcontinue;
end boolString;

protected function getConstantValue "function: getConstantValue"
  input RenamedPat pat;
  output Absyn.Exp val;
algorithm
  val :=
  matchcontinue (pat)
    case (RP_INTEGER(_,val))
      local
        Integer val;
      equation
      then Absyn.INTEGER(val);
    case (RP_STRING(_,val))
      local
        String val;
      equation
      then Absyn.STRING(val);
    case (RP_BOOL(_,val))
      local
        Boolean val;
      equation
      then Absyn.BOOL(val);
    case (RP_REAL(_,val))
      local
        Real val;
      equation
      then Absyn.REAL(val);
    case (RP_EMPTYLIST(_))
      then Absyn.LIST({});
    case (RP_NONE(_)) then Absyn.CREF(Absyn.CREF_IDENT("NONE",{}));
  end matchcontinue;
end getConstantValue;

public function extractPathVar "function: extractPathVar"
  input RenamedPat pat;
  output Absyn.Ident pathVar;
algorithm
  pathVar :=
  matchcontinue (pat)
    local
      Absyn.Ident localPathVar;
    case (RP_INTEGER(localPathVar,_)) equation then localPathVar;
    case (RP_REAL(localPathVar,_)) equation then localPathVar;
    case (RP_BOOL(localPathVar,_)) equation then localPathVar;
    case (RP_STRING(localPathVar,_)) equation then localPathVar;
    case (RP_CONS(localPathVar,_,_)) equation then localPathVar;
    case (RP_CALL(localPathVar,_,_)) equation then localPathVar;
    case (RP_TUPLE(localPathVar,_)) equation then localPathVar;
    case (RP_WILDCARD(localPathVar)) equation then localPathVar;
    case (RP_EMPTYLIST(localPathVar)) equation then localPathVar;
    case (RP_NONE(localPathVar)) equation then localPathVar;
    case (RP_SOME(localPathVar,_)) equation then localPathVar;
    case _ equation Debug.fprintln("matchcase", "- DFA.extractPathVar failed"); then fail();
  end matchcontinue;
end extractPathVar;

protected function constructorOrNot "function: constructorOrNot"
  input RenamedPat pat;
  output Boolean val;
algorithm
  val :=
  matchcontinue (pat)
    case (RP_CONS(_,_,_)) then true;
    case (RP_TUPLE(_,_)) then true;
    case (RP_CALL(_,_,_)) then true;
    case (RP_SOME(_,_)) then true;
    case (_) then false;
  end matchcontinue;
end constructorOrNot;


protected function lookupTypeOfVar "function: lookupTypeOfVar"
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
  input Absyn.Ident id;
  output Absyn.TypeSpec outTypeSpec;
algorithm
  outTypeSpec :=
  matchcontinue (dfaEnv,id)
    case ({},_) then fail();
    case ((localId2,t2) :: restTups,localId)
      local
        Absyn.TypeSpec t2;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> restTups;
        Absyn.Ident localId,localId2;
      equation
        true = (localId ==& localId2);
      then t2;
    case (_ :: restTups,localId)
      local
        Absyn.TypeSpec t;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> restTups;
        Absyn.Ident localId;
      equation
        t = lookupTypeOfVar(restTups,localId);
      then t;
  end matchcontinue;
end lookupTypeOfVar;

protected function mergeLists "function: mergeLists"
  input list<Absyn.Ident> idList;
  input list<Absyn.TypeSpec> tList;
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> accList;
  output list<tuple<Absyn.Ident,Absyn.TypeSpec>> outList;
algorithm
  outTypeSpec :=
  matchcontinue (idList,tList,accList)
    local
      list<tuple<Absyn.Ident,Absyn.TypeSpec>> localAccList;
    case ({},_,localAccList) then localAccList;
    case (_,{},localAccList) then localAccList;
    case (id :: restIds,tSpec :: restSpecs,localAccList)
      local
        Absyn.Ident id;
        list<Absyn.Ident> restIds;
        list<Absyn.TypeSpec> restSpecs;
        Absyn.TypeSpec tSpec;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> tup;
      equation
        tup = {(id,tSpec)};
        localAccList = listAppend(localAccList,tup);
        localAccList = mergeLists(restIds,restSpecs,localAccList);
      then localAccList;
  end matchcontinue;
end mergeLists;

protected function addVarsToDfaEnv "function: addVarsToDfaEnv"
  input list<Absyn.Exp> expList;
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
  input Env.Cache cache;
  input Env.Env env;
  output list<tuple<Absyn.Ident,Absyn.TypeSpec>> outDfaEnv;
  output Env.Cache outCache;
algorithm
  (outDfaEnv,outCache) :=
  matchcontinue (expList,dfaEnv,cache,env)
    local
      list<tuple<Absyn.Ident,Absyn.TypeSpec>> localDfaEnv;
      Env.Cache localCache;
      Env.Env localEnv;
      list<Absyn.Exp> restExps;
    case ({},localDfaEnv,localCache,_) then (localDfaEnv,localCache);
    case (Absyn.CREF(Absyn.WILD) :: restExps,localDfaEnv,localCache,localEnv)
      equation
        (localDfaEnv,localCache) = addVarsToDfaEnv(restExps,localDfaEnv,localCache,localEnv);
      then (localDfaEnv,localCache);
    case (Absyn.CREF(Absyn.CREF_IDENT(firstId,{})) :: restExps,localDfaEnv,localCache,localEnv)
      local
        Absyn.Ident firstId;
        Types.Type t;
        Absyn.TypeSpec t2;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem;
      equation
        (localCache,Types.VAR(_,_,_,t,_),_,_) = Lookup.lookupIdent(localCache,localEnv,firstId);
        t2 = MetaUtil.typeConvert(t);
        dfaEnvElem = {(firstId,t2)};
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem);
        (localDfaEnv,localCache) = addVarsToDfaEnv(restExps,localDfaEnv,localCache,localEnv);
      then (localDfaEnv,localCache);
    case (_,_,_,_)
      equation
        Debug.fprintln("matchcase", "- DFA.addVarsToDfaEnv failed");
      then fail();
  end matchcontinue;
end addVarsToDfaEnv;

protected function createListOfTrue "function: createListOfTrue"
  input Integer nStates;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (nStates,accList)
    local
      list<Absyn.Exp> localAccList;
    case (0,localAccList) then localAccList;
    case (n,localAccList)
      local
        Integer n;
        list<Absyn.Exp> e;
      equation
        e = {Absyn.INTEGER(1)};
        localAccList = listAppend(localAccList,e);
        localAccList = createListOfTrue(n-1,localAccList);
      then localAccList;
  end matchcontinue;
end createListOfTrue;

public function addNewSimpleState "function: addNewSimpleState"
  input list<SimpleState> stateList;
  input Integer stateNum;
  input SimpleState state;
  output list<SimpleState> outList;
algorithm
  outList :=
  matchcontinue (stateList,stateNum,state)
    case (localStateList,localStateNum,localState)
      local
        SimpleStateArray localStateArray;
        Integer localStateNum;
        SimpleState localState;
        list<SimpleState> localStateList;
      equation
        false = (localStateNum > listLength(localStateList));
        localStateArray = listArray(localStateList);
        localStateArray = arrayUpdate(localStateArray,localStateNum,localState);
        localStateList = arrayList(localStateArray);
      then localStateList;
    case (localStateList,localStateNum,localState)
      local
        Integer n;
        Integer localStateNum;
        SimpleState localState;
        list<SimpleState> localStateList;
      equation
        n = listLength(localStateList);
        localStateList = increaseListSize(localStateList,localStateNum - n);
        localStateList = addNewSimpleState(localStateList,localStateNum,localState);
      then localStateList;
  end matchcontinue;
end addNewSimpleState;

protected function increaseListSize "function: increaseListSize"
  input list<SimpleState> inList;
  input Integer size;
  output list<SimpleState> outList;
algorithm
  outList :=
  matchcontinue (inList,size)
    local
      list<SimpleState> localInList;
    case (localInList,0) then localInList;
    case (localInList,n)
      local
        Integer n;
      equation
        localInList = listAppend(localInList,{SIMPLEDUMMIE()});
        localInList = increaseListSize(localInList,n-1);
      then localInList;
  end matchcontinue;
end increaseListSize;

public function simplifyState "function: simplifyState
Transform a normal state into a simple, 'light' state.
"
  input State normalState;
  output SimpleState simpleState;
algorithm
  simpleState :=
  matchcontinue (normalState)
    case (STATE(n,_,arcs as (ARC(_,_,SOME(p),_) :: _),NONE()))
      local
        Integer n;
        list<Arc> arcs;
        Absyn.Ident varName;
        RenamedPat p;
        list<tuple<ArcName,Stamp>> simpleArcs;
        SimpleState sState;
      equation
        varName = extractPathVar(p);
        simpleArcs = simplifyArcs(arcs,{});
        sState = SIMPLESTATE(n,simpleArcs,0,SOME(varName));
      then sState;
    case (_)
    then fail();
  end matchcontinue;
end simplifyState;

public function simplifyArcs "function: simplifyArcs"
  input list<Arc> inArcs;
  input  list<tuple<ArcName,Stamp>> accArcs;
  output  list<tuple<ArcName,Stamp>> outArcs;
algorithm
  outArcs :=
  matchcontinue (inArcs,accArcs)
    local
      list<tuple<ArcName,Stamp>> localAccArcs;
    case ({},localAccArcs) then localAccArcs;
    case (ARC(DUMMIESTATE(),_,_,_) :: _,localAccArcs) then localAccArcs;
    case (ARC(GOTOSTATE(_,n),aName,_,_) :: restArcs,localAccArcs)
      local
        Integer n;
        ArcName aName;
        list<Arc> restArcs;
      equation
        localAccArcs = listAppend(localAccArcs,{(aName,n)});
        localAccArcs = simplifyArcs(restArcs,localAccArcs);
      then localAccArcs;
    case (ARC(STATE(n,_,_,_),aName,_,_) :: restArcs,localAccArcs)
      local
        Integer n;
        ArcName aName;
        list<Arc> restArcs;
      equation
        localAccArcs = listAppend(localAccArcs,{(aName,n)});
        localAccArcs = simplifyArcs(restArcs,localAccArcs);
      then localAccArcs;
  end matchcontinue;
end simplifyArcs;

// Data structure for a pattern of the form path=pattern
public
uniontype RenamedPat "The `RenamedPat\' datatype"
  record RP_INTEGER
    Absyn.Ident var;
    Integer value "value" ;
  end RP_INTEGER;

  record RP_REAL
    Absyn.Ident var;
    Real value "value" ;
  end RP_REAL;

  record RP_CREF
    Absyn.Ident var;
    Absyn.Ident compRef;
    //  Absyn.ComponentRef componentReg "componentReg" ;
  end RP_CREF;

  record RP_STRING
    Absyn.Ident var;
    String value "value" ;
  end RP_STRING;

  record RP_BOOL
    Absyn.Ident var;
    Boolean value "value Binary operations, e.g. ab" ;
  end RP_BOOL;

  record RP_CALL
    Absyn.Ident var;
    Absyn.ComponentRef function_ "function" ;
    RenamedPatList functionArgs "functionArgs Array construction using \'{\',\'}\' or \'array\'" ;
  end RP_CALL;

  record RP_TUPLE
    Absyn.Ident var;
    list<RenamedPat> expressions "expressions array access operator for last element, e.g. a{end}:=1;" ;
  end RP_TUPLE;

  // MetaModelica expression follows!
  record RP_CONS
    Absyn.Ident var;
    RenamedPat head " head of the list ";
    RenamedPat rest " rest of the list ";
  end RP_CONS;

  record RP_WILDCARD
    Absyn.Ident lhsVar;
  end RP_WILDCARD;

  record RP_EMPTYLIST
    Absyn.Ident var;
  end RP_EMPTYLIST;

  record RP_NONE
    Absyn.Ident var;
  end RP_NONE;

  record RP_SOME
    Absyn.Ident var;
    RenamedPat pat;
  end RP_SOME;

end RenamedPat;

type RenamedPatList = list<RenamedPat>;

// Datastructure for the righthand sides in a matchcontinue expression
public
uniontype RightHandSide

  record RIGHTHANDSIDE
    list<Absyn.ElementItem> localDecls;
    list<Absyn.EquationItem> equations;
    Absyn.Exp result;
    Integer numberOfCase;
  end RIGHTHANDSIDE;

  // We use this one in the pattern matching so that we do not have
  // to carry around a lot of code all the time
  record RIGHTHANDLIGHT
    Integer numberOfCase;
  end RIGHTHANDLIGHT;
end RightHandSide;

type RenamedPatVec = RenamedPat[:];
type RenamedPatList = list<RenamedPat>;
type RenamedPatMatrix = RenamedPatList[:];
type RenamedPatMatrix2 = list<RenamedPatList>;
type IndexVector = list<Integer>;
type RightHandVector = RightHandSide[:];
type RightHandList = list<RightHandSide>;

// Functions for the handling of matrices
public function patternsFromCol "function: patternsFromCol
	author: KS
	Selects patterns from a column according to the indices in the index vector
"
  input RenamedPatMatrix patMat;
  input IndexVector indices;
  input Integer colNum;
  output RenamedPatList outList;
algorithm
  outList := patternsFromColHelper(patMat[colNum],indices,{});
end patternsFromCol;


public function patternsFromColHelper "function: patternsFromColHelper
	author: KS
	Recursive helper function to patternsFromCol
"
  input RenamedPatList patList;
  input IndexVector indices;
  input RenamedPatList accPatList;
  output RenamedPatList outPatVec;
algorithm
  outPatVec :=
  matchcontinue (patList,indices,accPatList)
    local
      RenamedPatList localAccPatList;
      Integer first;
      IndexVector rest;
      RenamedPatList localPatList;
    case (_,{},localAccPatList)
      equation then localAccPatList;
    case (localPatList,first :: rest,localAccPatList)
      local
        RenamedPat[:] temp;
        RenamedPat temp2;
      equation
        temp = listArray(localPatList);
        temp2 = temp[first];
      then patternsFromColHelper(localPatList,rest,listAppend(localAccPatList,temp2 :: {}));
  end matchcontinue;
end patternsFromColHelper;


public function patternsFromOtherCol "function: patternsFromOtherCol
	author: KS
	Selects patterns from all columns except one according to
	the indices in the index vector
"
  input RenamedPatMatrix patMat;
  input IndexVector indices;
  input Integer colNum;
  output RenamedPatMatrix outPatMat;
algorithm
  outPatMat := patternsFromOtherColHelper(1,colNum,indices,patMat,{});
end patternsFromOtherCol;


public function patternsFromOtherColHelper "function: patternsFromOtherColHelper
	author: KS
	Recursive helper function to patternsFromOtherCol
"
  input Integer pivot;
  input Integer colNum;
  input IndexVector indices;
  input RenamedPatMatrix patMat;
  input list<RenamedPatList> accPatMat;
  output RenamedPatMatrix patList;
algorithm
  patList :=
  matchcontinue (pivot,colNum,indices,patMat,accPatMat)
    local
      Integer localPivot;
      Integer localColNum;
      IndexVector localIndices;
      RenamedPatMatrix localPatMat;
      list<RenamedPatList> localAccPatMat;
    case (localPivot,_,_,localPatMat,localAccPatMat)
      equation
        true = (localPivot > arrayLength(localPatMat));
      then listArray(localAccPatMat);
    case (localPivot,localColNum,localIndices,localPatMat,localAccPatMat)
      equation
        true = (localPivot == localColNum);
      then patternsFromOtherColHelper(localPivot+1,localColNum,localIndices,localPatMat,localAccPatMat);
    case (localPivot,localColNum,localIndices,localPatMat,localAccPatMat)
      local
        RenamedPatList patternsFromThisCol;
      equation
        patternsFromThisCol = patternsFromColHelper(localPatMat[localPivot],localIndices,{});
      then patternsFromOtherColHelper(localPivot+1,localColNum,localIndices,localPatMat,
        listAppend(localAccPatMat,cons(patternsFromThisCol,{})));
  end matchcontinue;
end patternsFromOtherColHelper;


public function appendMatrices "function: appendMatrices
	author: KS
	Appends two matrices with the same number of rows
"
  input RenamedPatMatrix2 patMat1;
  input RenamedPatMatrix2 patMat2;
  output RenamedPatMatrix2 outPatMat;
algorithm
  outPatMat := listAppend(patMat1,patMat2);
end appendMatrices;

public function firstRow "function: firstRow
	author: KS
	Selects the first row of a RenamedPat matrix and returns it as a list.
"
  input RenamedPatMatrix2 patMat;
  input RenamedPatList accList;
  output RenamedPatList outList;
algorithm
  outList :=
  matchcontinue (patMat,accList)
    local
      RenamedPatList localAccList;
    case ({},localAccList) equation then localAccList;
    case ((first :: _) :: rest,localAccList)
      local
        RenamedPat first;
        list<RenamedPatList> rest;
        RenamedPatList patList;
      equation
        patList = firstRow(rest,listAppend(localAccList,Util.listCreate(first)));
      then patList;
  end matchcontinue;
end firstRow;


public function removeFirstRow "function: removeFirstRow
	author: KS
	Removes the first row from a matrix and returns the matrix with
	the first row removed
"
  input RenamedPatMatrix2 patMat;
  input RenamedPatMatrix2 accPatMat;
  output RenamedPatMatrix2 outPatMat;
algorithm
  outPatMat :=
  matchcontinue (patMat,accPatMat)
    local
      list<RenamedPatList> localAccPatMat;
    case (localPatMat,{})
      local
        RenamedPatMatrix2 localPatMat;
        list<RenamedPat> listTemp;
      equation
        listTemp = Util.listFirst(localPatMat);
        true = (listLength(listTemp) == 1);
      then {};
    case ({},localAccPatMat)
      equation
      then localAccPatMat;
    case ((_ :: restFirst) :: rest,localAccPatMat)
      local
        list<RenamedPatList> rest;
        RenamedPatList restFirst;
        RenamedPatMatrix2 temp;
      equation
        localAccPatMat = listAppend(localAccPatMat,restFirst :: {});
        temp = removeFirstRow(rest,localAccPatMat);
      then temp;
  end matchcontinue;
end removeFirstRow;

/*
public function printMatrix "function: printMatrix
	author: KS
"
  input RenamedPatMatrix2 patMat;
algorithm
  _ :=
  matchcontinue (patMat)
    case ({}) equation then ();
    case (first :: rest)
      local
        RenamedPatList first;
        RenamedPatMatrix2 rest;
      equation
        printList(first);
        printMatrix(rest);
      then ();
  end matchcontinue;
end printMatrix;
*/

public function matrixFix "function: matrixFix
	author: KS
"
  input RenamedPatMatrix2 inMat;
  output RenamedPatMatrix2 outAccMat;
algorithm
  outAccMat :=
  matchcontinue(inMat)
    case ({}) equation then {};
    case ({} :: {}) equation then {};
    case (first :: rest)
      local
        RenamedPatList first;
        RenamedPatMatrix2 rest,temp;
      equation
        temp = matrixFix(rest);
        temp = first :: temp;
      then temp;
  end matchcontinue;
end matrixFix;

/*
public function printList "function: printList
	author: KS
"
  input RenamedPatList inList;
algorithm
  _ :=
  matchcontinue (inList)
    case ({}) equation then ();
    case (first :: rest)
      local
        RenamedPat first;
        RenamedPatList rest;
      equation
        printPattern(first);
        print("\n");
        printList(rest);
      then ();
  end matchcontinue;
end printList;*/

public function printPatternStr
  input RenamedPat inPat;
  output String out;
algorithm
  out :=
  matchcontinue (inPat)
    local
      String var, str;
    case(RP_INTEGER(var,value))
      local
        Integer value;
      equation
        str = intString(value);
        str = Util.stringAppendList({"Pathvar:", var, " :",str,"\n"});
      then str;
    case(RP_BOOL(var,_))
      equation
        str = Util.stringAppendList({"Pathvar:", var, " BOOL","\n"});
      then str;
    case(RP_STRING(var,value))
      local
        String value;
      equation
        str = Util.stringAppendList({"Pathvar:", var, ":",value,"\n"});
      then str;
    case(RP_CONS(var,head,rest))
      local
        RenamedPat head; String headStr;
        RenamedPat rest; String restStr;
      equation
        headStr = printPatternStr(head);
        restStr = printPatternStr(rest);
        str = Util.stringAppendList({"Pathvar:", var, " CONS: ",headStr,",",restStr,"\n"});
      then str;
    case(RP_WILDCARD(var))
      equation
        str = Util.stringAppendList({"Pathvar:", var, " WILDCARD","\n"});
      then str;
    case(RP_EMPTYLIST(var))
      equation
        str = Util.stringAppendList({"Pathvar:", var, " EMPTY LIST","\n"});
      then str;
    case (_)
      then "Printing of pattern not implemented";
  end matchcontinue;
end printPatternStr;

public function getRightHandSideNumbers "function: getRightHandSideNumbers"
  input RightHandList inList;
  input list<Integer> accList;
  output list<Integer> outList;
algorithm
  outList :=
  matchcontinue (inList,accList)
    local
      list<Integer> localAccList;
    case ({},localAccList) then localAccList;
    case (RIGHTHANDLIGHT(n) :: rest,localAccList)
      local
        Integer n;
        RightHandList rest;
      equation
        localAccList = listAppend(localAccList,{n});
        localAccList = getRightHandSideNumbers(rest,localAccList);
      then localAccList;
  end matchcontinue;
end getRightHandSideNumbers;


public function printDFASimple
  input SimpleStateArray inArr;
  input Integer pivot;
  output Integer y;
algorithm
  y :=
  matchcontinue (inArr,pivot)
    case (_,0) then 0;
    case (localInArr,localPivot)
      local
        SimpleStateArray localInArr;
        SimpleState st;
        Integer localPivot,i;
      equation
        st = localInArr[localPivot];
        i = printStateSimple(st);
        i = printDFASimple(localInArr,localPivot-1);
      then 0;
  end matchcontinue;
end printDFASimple;

public function printStateSimple
  input SimpleState inS;
  output Integer y;
algorithm
  y :=
  matchcontinue (inS)
    case (SIMPLEDUMMIE()) then 0;
    case (SIMPLESTATE(st,oArcs,cN,NONE()))
      local
        Integer st,cN,i;
        list<tuple<ArcName,Stamp>> oArcs;
      equation
        print("State, ");
        print(intString(st));
        print(", cN:");
        print(intString(cN));
        print(", ");
        i = printSimpleArcs(oArcs);
        print("end state");
        print(intString(st));
        print("\n");
      then 0;
    case (SIMPLESTATE(st,oArcs,cN,SOME(id)))
      local
        Integer st,cN,i;
        list<tuple<ArcName,Stamp>> oArcs;
        Absyn.Ident id;
      equation
        print("State, ");
        print(intString(st));
        print(", cN:");
        print(intString(cN));
        print(", varName:");
        print(id);
        print(", ");
        i = printSimpleArcs(oArcs);
        print("end state");
        print(intString(st));
        print("\n");
      then 0;
  end matchcontinue;
end printStateSimple;

public function printSimpleArcs
  input list<tuple<ArcName,Stamp>> inList;
  output Integer y;
algorithm
  y :=
  matchcontinue(inList)
    case ({}) then 0;
    case ((id,st) :: rList)
      local
        Stamp st;
        Absyn.Ident id;
        list<tuple<ArcName,Stamp>> rList;
        Integer i;
      equation
        print(", Arc to ");
        print(intString(st));
        print(", arcName ");
        print(id);
        i = printSimpleArcs(rList);
      then 0;
  end matchcontinue;
end printSimpleArcs;

public function matchContinueToSwitch
  input RenamedPatMatrix2 patMat;
  input list<list<Absyn.ElementItem>> caseLocalDecls;
  input list<Absyn.Exp> inputVarList; // matchcontinue (var1,var2,...)
  input list<Absyn.ElementItem> declList;
  input list<Absyn.Exp> resVarList;
  input RightHandList rhlist;
  input Env.Cache cache;
  input Env.Env localEnv;
  output Env.Cache outCache;
  output Absyn.Exp expr;
protected
  list<Absyn.Exp> cases;
  list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
  list<String> invalidDecls;
  Absyn.Algorithm alg;
  Absyn.AlgorithmItem algItem;
algorithm
  (dfaEnv, invalidDecls, cache) := getMatchContinueInvalidDeclsAndInitialEnv(inputVarList, resVarList, cache, localEnv);
  checkShadowing(declList,invalidDecls);
  (outCache, cases) := matchContinueToSwitch2(patMat, caseLocalDecls, inputVarList, resVarList, rhlist, cache, localEnv, invalidDecls, dfaEnv);
  alg := Absyn.ALG_MATCHCASES(cases);
  algItem := Absyn.ALGORITHMITEM(alg, NONE);
  expr := Absyn.VALUEBLOCK(declList,Absyn.VALUEBLOCKALGORITHMS({algItem}),Absyn.BOOL(true));
end matchContinueToSwitch;

protected function matchContinueToSwitch2
  input RenamedPatMatrix2 patMat;
  input list<list<Absyn.ElementItem>> caseLocalDecls;
  input list<Absyn.Exp> inputVarList;
  input list<Absyn.Exp> resVarList;
  input RightHandList rhlist;
  input Env.Cache cache;
  input Env.Env localEnv;
  input list<String> invalidDecls;
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> initialDfaEnv;
  output Env.Cache outCache;
  output list<Absyn.Exp> expr;
algorithm
  (outCache, expr) := matchcontinue (patMat, caseLocalDecls, inputVarList, resVarList, rhlist, cache, localEnv, invalidDecls, initialDfaEnv)
    local
      RenamedPatList firstCase;
      RenamedPatMatrix2 restCase;
      RightHandList restRh;
      Absyn.Exp expr, result;
      Env.Cache localCache;
      Absyn.AlgorithmItem alg;
      list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
      list<Absyn.ElementItem> localList, els, els2, firstDecls;
      list<list<Absyn.ElementItem>> elsRes, restDecls;
      list<Absyn.Exp> exp2;
      list<Absyn.EquationItem> body;
      list<Absyn.AlgorithmItem> algs, algs3;
      tuple<Integer,list<Absyn.AlgorithmItem>> res;
      list<list<Absyn.AlgorithmItem>> caseAlgs;
      list<String> dfaEnvIdents;
    case ({}, {}, _, _, {}, localCache, _, _, _) then (localCache, {});
    case (firstCase :: restCase, firstDecls :: restDecls,inputVarList, resVarList, RIGHTHANDSIDE(localList,body,result,_) :: restRh, localCache, localEnv, invalidDecls, initialDfaEnv)
      equation
        dfaEnv = initialDfaEnv;
        checkShadowing(firstDecls,invalidDecls);
        
        exp2 = createListFromExpression(result);

        // Create the assignments that assign the return variables
        algs3 = createLastAssignments(resVarList,exp2,{});
        (localCache, dfaEnv, els, algs) = generatePathVarDeclarationsList(firstCase, inputVarList, localCache, localEnv, dfaEnv);
        els = listAppend(els, firstDecls);
        expr = Absyn.VALUEBLOCK(els,Absyn.VALUEBLOCKMATCHCASE(algs,body,algs3),Absyn.BOOL(true));
        (cache, exp2) = matchContinueToSwitch2(restCase, restDecls, inputVarList, resVarList, restRh, localCache, localEnv, invalidDecls, initialDfaEnv);
      then (cache, expr :: exp2);
    case (_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln("matchcase", "- DFA.matchContinueToSwitch2 failed");
      then fail();
  end matchcontinue;
end matchContinueToSwitch2;

protected function getMatchContinueInvalidDeclsAndInitialEnv
  input list<Absyn.Exp> inputVarList;
  input list<Absyn.Exp> resVarList;
  input Env.Cache inCache;
  input Env.Env localEnv;
  output list<tuple<String,Absyn.TypeSpec>> dfaEnv;      
  output list<String> invalidDecls;
  output Env.Cache cache;
protected
  list<tuple<String,Absyn.TypeSpec>> dfaEnvRes;
  list<String> envIdents, envIdents1, envIdents2;
algorithm
  (dfaEnvRes,cache) := addVarsToDfaEnv(resVarList,{},inCache,localEnv);
  envIdents1 := Util.listMap(dfaEnvRes, Util.tuple21);
  (dfaEnv,cache) := addVarsToDfaEnv(inputVarList,{},cache,localEnv);
  envIdents2 := Util.listMap(dfaEnv, Util.tuple21);
  invalidDecls := listAppend(envIdents1, envIdents2);
end getMatchContinueInvalidDeclsAndInitialEnv;

protected function checkShadowing
  input list<Absyn.ElementItem> elItems;
  input list<String> invalidDecls;
algorithm
  _ := matchcontinue (elItems, invalidDecls)
    local
      list<String> elIdents;
      list<Boolean> boolList;
      Absyn.Info info;
      Absyn.ElementSpec spec;
    case ({}, _) then ();
    case (Absyn.ELEMENTITEM(Absyn.ELEMENT(info = info, specification = spec)) :: elItems, invalidDecls)
      equation
        elIdents = getElementSpecComponentNames(spec);
        checkShadowing2(info, elIdents, invalidDecls);
        checkShadowing(elItems, invalidDecls);
      then ();
  end matchcontinue;
end checkShadowing;

protected function checkShadowing2
  input Absyn.Info info;
  input list<String> elIdents;
  input list<String> invalidDecls;
algorithm
  _ := matchcontinue (info, elIdents, invalidDecls)
    local
      String elIdent;
    case (_, {}, _) then ();
    case (info, elIdent::elIdents, invalidDecls)
      equation
        checkShadowing3(info,elIdent,invalidDecls);
        checkShadowing2(info,elIdents,invalidDecls);
      then ();
  end matchcontinue;
end checkShadowing2;

protected function checkShadowing3
  input Absyn.Info info;
  input String elIdent;
  input list<String> invalidDecls;
algorithm
  _ := matchcontinue (info, elIdent, invalidDecls)
    case (_, elIdent, invalidDecls)
      equation
        false = listMember(elIdent, invalidDecls);
      then ();
    case (info, elIdent, _)
      equation
        Error.addSourceMessage(Error.MATCH_SHADOWING, {elIdent}, info);
      then fail();
  end matchcontinue;
end checkShadowing3;

protected function getElementSpecComponentNames
  input Absyn.ElementSpec spec;
  output list<String> out;
algorithm
  out := matchcontinue (spec)
    local
      list<String> strs;
      list<Absyn.ComponentItem> comps;
    case Absyn.COMPONENTS(components = comps)
      equation
        strs = Util.listMap(comps, getComponentName);
      then strs;
    case _
      equation
        Debug.fprintln("matchcase", "- DFA.getElementName failed");
      then fail();
  end matchcontinue;
end getElementSpecComponentNames;

protected function getComponentName
  input Absyn.ComponentItem comp;
  output String out;
algorithm
  out := matchcontinue (comp)
    local
      String name;
    case Absyn.COMPONENTITEM(Absyn.COMPONENT(name = name),_,_) then name;
  end matchcontinue;
end getComponentName;

function generatePathVarDeclarationsList
  input list<RenamedPat> pats;
  input list<Absyn.Exp> inputVarList;
  input Env.Cache cache;
  input Env.Env env;
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
  output Env.Cache outCache;
  output list<tuple<Absyn.Ident,Absyn.TypeSpec>> outDfaEnv;
  output list<Absyn.ElementItem> outEls;
  output list<Absyn.AlgorithmItem> outAlgs;
algorithm
  (outCache,outDfaEnv,outEls,outAlgs) := matchcontinue(pats, inputVarList, cache, env, dfaEnv)
    local
      list<Absyn.ElementItem> outEls, outEls1, outEls2, matchDecls;
      list<Absyn.AlgorithmItem> outAlgs, outAlgs1, outAlgs2, matchAlgs;
      list<RenamedPat> rest;
      RenamedPat pat;
      list<Absyn.Exp> varList;
      Absyn.Exp var;
    case ({},{},cache,env,dfaEnv) then (cache,dfaEnv,{},{});
    case (pat :: rest, var :: varList, cache, env, dfaEnv)
      equation
        (cache,dfaEnv,matchDecls,matchAlgs) = generatePathVarDeclarationsNew(pat, cache, env, dfaEnv);
        (cache,dfaEnv,outEls,outAlgs) = generatePathVarDeclarationsList(rest,varList,cache,env,dfaEnv);
        outAlgs = listAppend(matchAlgs, outAlgs);
        outEls = listAppend(matchDecls, outEls);
      then (cache,dfaEnv,outEls,outAlgs);
    case (pat :: rest, var :: varList, cache, env, dfaEnv)
      equation
        outAlgs1 = getPatternComp(pat, var, true);
        (cache,dfaEnv,outEls,outAlgs2) = generatePathVarDeclarationsList(rest,varList,cache,env,dfaEnv);
        outAlgs = listAppend(outAlgs1, outAlgs2);
      then (cache,dfaEnv,outEls,outAlgs);
    case (pat :: _,_,_,_,_)
      local String str;
      equation
        str = printPatternStr(pat);
        Debug.fprintln("matchcase", "- generatePathVarDeclarationsList failed: " +& str);
      then fail();
  end matchcontinue;
end generatePathVarDeclarationsList;

protected function getPatternExp "function: getPatternExp"
  input RenamedPat pat;
  output Absyn.Exp val;
algorithm
  val := matchcontinue (pat)
    case (RP_INTEGER(_,val))
      local
        Integer val;
      equation
      then Absyn.INTEGER(val);
    case (RP_STRING(_,val))
      local
        String val;
      equation
      then Absyn.STRING(val);
    case (RP_BOOL(_,val))
      local
        Boolean val;
      equation
      then Absyn.BOOL(val);
    case (RP_REAL(_,val))
      local
        Real val;
      equation
      then Absyn.REAL(val);
    case (RP_EMPTYLIST(_))
      then Absyn.LIST({});
    case (RP_NONE(_)) then Absyn.CREF(Absyn.CREF_IDENT("NONE",{}));
  end matchcontinue;
end getPatternExp;

protected function getPatternComp "function: getPatternComp"
  input RenamedPat pat;
  input Absyn.Exp var;
  input Boolean nequal;
  output list<Absyn.AlgorithmItem> out;
algorithm
  out := matchcontinue (pat, var, nequal)
    local
      Absyn.Exp exp;
      Absyn.AlgorithmItem alg;
      Absyn.Operator op;
    case (RP_EMPTYLIST(_), var, nequal) // Optimizes comparison with emptylist by not creating an empty list to compare with
      equation
        alg = Absyn.ALGORITHMITEM(Absyn.ALG_BREAK, NONE);
        exp = Absyn.CALL(Absyn.CREF_IDENT("listEmpty",{}), Absyn.FUNCTIONARGS({var}, {}));
        exp = Util.if_(nequal, Absyn.LUNARY(Absyn.NOT(), exp), exp);
        alg = Absyn.ALGORITHMITEM(Absyn.ALG_IF(exp, {alg}, {}, {}),NONE);
      then {alg};
    case (RP_NONE(_), var, nequal) // Optimizes comparison with NONE by not creating an empty option to compare with
      equation
        alg = Absyn.ALGORITHMITEM(Absyn.ALG_BREAK, NONE);
        exp = Absyn.CALL(Absyn.CREF_IDENT("optionNone",{}), Absyn.FUNCTIONARGS({var}, {}));
        exp = Util.if_(nequal, Absyn.LUNARY(Absyn.NOT(), exp), exp);
        alg = Absyn.ALGORITHMITEM(Absyn.ALG_IF(exp, {alg}, {}, {}),NONE);
      then {alg};
    case (pat, var, nequal)
      equation
        op = Util.if_(nequal, Absyn.NEQUAL, Absyn.EQUAL);
        exp = getPatternExp(pat);
        alg = Absyn.ALGORITHMITEM(Absyn.ALG_BREAK, NONE);
        alg = Absyn.ALGORITHMITEM(Absyn.ALG_IF(Absyn.RELATION(var,op,exp), {alg}, {}, {}),NONE);
      then {alg};
    case (_, _, _) then {};
  end matchcontinue;
end getPatternComp;

protected function uniontypeComp        
  input Absyn.Ident pathVar;
  input SCode.Restriction restriction;
  input Integer numFields;
  input Absyn.Ident classPathStr;
  output list<Absyn.AlgorithmItem> out;
algorithm
  out := matchcontinue (pathVar,restriction,numFields,classPathStr)
    local
      Integer i;
      Absyn.AlgorithmItem alg;
      Absyn.Exp exp;
      Absyn.FunctionArgs fargs;
    case (_,SCode.R_RECORD(),_,_) then {};
    case (pathVar,SCode.R_METARECORD(_,i),numFields,classPathStr)
      equation
        alg = Absyn.ALGORITHMITEM(Absyn.ALG_BREAK, NONE);
        fargs = Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(pathVar,{})),Absyn.INTEGER(i),Absyn.INTEGER(numFields),Absyn.STRING(classPathStr)}, {});
        exp = Absyn.CALL(Absyn.CREF_IDENT("mmc_uniontype_metarecord_typedef_equal",{}), fargs);
        exp = Absyn.LUNARY(Absyn.NOT(), exp);
        alg = Absyn.ALGORITHMITEM(Absyn.ALG_IF(exp, {alg}, {}, {}),NONE);
      then {alg};
  end matchcontinue;
end uniontypeComp;

protected function generatePathVarDeclarationsNew "function: generatePathVarDeclerations
	author: KS
	Used when we have a record constructor call in a pattern and we need to
	create path variables of the subpatterns of the record constructor.
"
  input RenamedPat pat;
  input Env.Cache cache;
  input Env.Env env;
  input list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnv;
  output Env.Cache outCache;
  output list<tuple<Absyn.Ident,Absyn.TypeSpec>> outDfaEnv;
  output list<Absyn.ElementItem> outDecl;
  output list<Absyn.AlgorithmItem> outAssigns;
algorithm
  (outCache,outDfaEnv,outDecl,outAssigns) :=
  matchcontinue (pat,cache,env,dfaEnv)
    local
      Env.Cache localCache;
      Env.Env localEnv;
      list<tuple<Absyn.Ident,Absyn.TypeSpec>> localDfaEnv;
      Absyn.Exp firstCref, secondCref, cref, cref2;
      list<Absyn.AlgorithmItem> algs, algs1, algs2, algs3;
      list<Absyn.ElementItem> elem,elem1,elem2;
      list<Absyn.Exp> crefs;
    case (RP_CONS(pathVar,first,second),localCache,localEnv,localDfaEnv)
      local
        Absyn.Ident pathVar;
        RenamedPat first,second;
        Absyn.Ident firstPathVar,secondPathVar;
        Absyn.TypeSpec t;
        Absyn.AlgorithmItem assign1,assign2;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem1,dfaEnvElem2;
      equation
        //Example:
        // if (x == CONS)    -- (This comparison will not occure)
        // TYPE1 pathVar__1;
        // list<TYPE1> pathVar__2;
        // pathVar__1 = listCar(x,1);
        // pathVar__2 = listCdr(x,2);

        // The variable should be found in the DFA environment
        Absyn.TCOMPLEX(Absyn.IDENT("list"),{t},NONE()) = lookupTypeOfVar(localDfaEnv,pathVar);

        firstPathVar = extractPathVar(first);
        secondPathVar = extractPathVar(second);
        
        firstCref = identToCrefExp(firstPathVar);
        secondCref = identToCrefExp(secondPathVar);
        
        elem1 = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            t,
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(firstPathVar,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        elem2 = {Absyn.ELEMENTITEM(Absyn.ELEMENT(
          false,NONE(),Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
            Absyn.TCOMPLEX(Absyn.IDENT("list"),{t},NONE()),
            {Absyn.COMPONENTITEM(Absyn.COMPONENT(secondPathVar,{},NONE()),NONE(),NONE())}),
            Absyn.INFO("f",false,0,0,0,0,Absyn.TIMESTAMP(0.0,0.0)),NONE()))};

        // Add the new variables to the DFA environment
        // For example, if we have a pattern:
        // RP_CONS(x,RP_INTEGER(x__1,1),RP_CONS(x__2,RP_INTEGER(x__2__1,2),RP_EMPTYLIST(x__2__2)))
        // Then we must know the type of x__2 when arriving to the second
        // RP_CONS pattern
        dfaEnvElem1 = {(firstPathVar,t)};
        dfaEnvElem2 = {(secondPathVar,Absyn.TCOMPLEX(Absyn.IDENT("list"),{t},NONE()))};
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem1);
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem2);
        elem = listAppend(elem1,elem2);

        cref = identToCrefExp(pathVar);
        assign1 = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(firstCref,
          Absyn.CALL(Absyn.CREF_IDENT("listGet",{}),Absyn.FUNCTIONARGS({cref,Absyn.INTEGER(1)},{}))),NONE());
        assign2 = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(secondCref,
          Absyn.CALL(Absyn.CREF_IDENT("listRest",{}),Absyn.FUNCTIONARGS({cref},{}))),NONE());

        (localCache, localDfaEnv, elem1, algs1) = generatePathVarDeclarationsList({first}, {firstCref}, localCache, localEnv, localDfaEnv);
        (localCache, localDfaEnv, elem2, algs2) = generatePathVarDeclarationsList({second}, {secondCref}, localCache, localEnv, localDfaEnv);
        // algs3 = getPatternComp(RP_EMPTYLIST("dummy"), cref, false);
        
        elem = listAppend(elem, elem1);
        elem = listAppend(elem, elem2);
        algs = listAppend(assign1::algs1,assign2::algs2);
        // algs = listAppend(algs3, algs);
      then (localCache,localDfaEnv,elem,algs);
    case (RP_CALL(pathVar,cRef,argList),localCache,localEnv,localDfaEnv)
      local
        Absyn.Ident pathVar,recName,className,classPathStr;
        list<Absyn.Ident> pathVarList,fieldNameList;
        list<RenamedPat> argList;
        SCode.Class sClass;
        list<Absyn.TypeSpec> fieldTypeSpecs;
        list<Types.Type> fieldTypes;
        Absyn.Path pathName, classPath;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem;
        Absyn.ComponentRef cRef;
        SCode.Restriction restriction;
        Integer numFields;
        Types.Type ty;
        String tyStr;
      equation
        pathName = Absyn.crefToPath(cRef);
        recName = Absyn.pathString(pathName);

        // For instance if we have
        // a record RECNAME{ TYPE1 field1, TYPE2 field2 } :
        //
        // if (getType(pathVar) = RECNAME)
        // TYPE1 pathVar__1;
        // TYPE2 pathVar__2;
        // x__1 = pathVar.field1;
        // x__2 = pathVar.field2;

        pathVarList = Util.listMap(argList,extractPathVar);
        // Get recordnames
        (localCache,sClass as SCode.CLASS(name = className, restriction = restriction),localEnv) = Lookup.lookupClass(localCache,localEnv,pathName,true);
        (localCache,ty,localEnv) = Lookup.lookupType(localCache,localEnv,pathName,true);
        //tyStr = Types.unparseType(ty);
        //Debug.fprintln("matchcase", "- Looked up record cons. func: " +& tyStr);
        classPath = Env.joinEnvPath(localEnv,Absyn.IDENT(className));
        classPathStr = Absyn.pathString(classPath);
        (fieldNameList,fieldTypes) = MetaUtil.constructorCallTypeToNamesAndTypes(ty); // extractFieldNamesAndTypes(sClass);
        fieldTypeSpecs = Util.listMap(fieldTypes, MetaUtil.typeConvert);

        dfaEnvElem = mergeLists(pathVarList,fieldTypeSpecs,{});
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem);

        algs1 = createPathVarAssignmentsCall(pathVar,pathVarList,fieldNameList,{},restriction,cRef);
        elem1 = createPathVarDeclarations(pathVarList,fieldTypeSpecs,{});

        crefs = Util.listMap(pathVarList, identToCrefExp);
        (localCache, localDfaEnv, elem2, algs2) = generatePathVarDeclarationsList(argList, crefs, localCache, localEnv, localDfaEnv);
        elem = listAppend(elem1, elem2);
        algs = listAppend(algs1,algs2);
        
        numFields = listLength(argList);
        algs2 = uniontypeComp(pathVar, restriction, numFields, classPathStr);
        algs = listAppend(algs2,algs);
      then (localCache,localDfaEnv,elem,algs);
    case (RP_TUPLE(pathVar,argList),localCache,localEnv,localDfaEnv)
      local
        Absyn.Ident pathVar;
        list<RenamedPat> argList;
        list<Absyn.TypeSpec> fieldTypes;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem;
        list<Absyn.Ident> pathVarList;
      equation
        //Example:
        // if (x == TUPLE)    -- (This comparison will not occur)
        // TYPE1 pathVar__1;
        // TYPE2 pathVar__2;
        // ...
        // pathVar__1 = metaMGetField(x,1);
        // pathVar__2 = metaMGetField(x,2);
        // ...

        // The variable should be found in the DFA environment
        Absyn.TCOMPLEX(Absyn.IDENT("tuple"),fieldTypes,NONE()) = lookupTypeOfVar(localDfaEnv,pathVar);

        pathVarList = Util.listMap(argList,extractPathVar);
        dfaEnvElem = mergeLists(pathVarList,fieldTypes,{});
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem);

        algs1 = createPathVarAssignments(pathVar,pathVarList,{},{},1);
        elem1 = createPathVarDeclarations(pathVarList,fieldTypes,{});
        
        crefs = Util.listMap(pathVarList, identToCrefExp);
        (localCache, localDfaEnv, elem2, algs2) = generatePathVarDeclarationsList(argList, crefs, localCache, localEnv, localDfaEnv);        
        elem = listAppend(elem1, elem2);
        algs = listAppend(algs1,algs2);
      then (localCache,localDfaEnv,elem,algs);

    case (RP_SOME(pathVar,arg),localCache,localEnv,localDfaEnv)
      local
        Absyn.Ident pathVar,pathVar2;
        RenamedPat arg;
        list<Absyn.TypeSpec> fieldTypes;
        list<tuple<Absyn.Ident,Absyn.TypeSpec>> dfaEnvElem;
        list<Absyn.Ident> pathVarList;
      equation
        //Example:
        // if (x != NONE)    -- Or we get segfaults
        // TYPE1 pathVar__1;
        // pathVar__1 = metaMGetField(x,1);

        // The variable should be found in the DFA environment
        Absyn.TCOMPLEX(Absyn.IDENT("Option"),fieldTypes,NONE()) = lookupTypeOfVar(localDfaEnv,pathVar);
        pathVar2=extractPathVar(arg);
        cref = identToCrefExp(pathVar);
        cref2 = identToCrefExp(pathVar2);
        
        pathVarList = {pathVar2};
        dfaEnvElem = mergeLists(pathVarList,fieldTypes,{});
        localDfaEnv = listAppend(localDfaEnv,dfaEnvElem);

        algs1 = createPathVarAssignments(pathVar,pathVarList,{},{},1);
        elem1 = createPathVarDeclarations(pathVarList,fieldTypes,{});
        
        (localCache, localDfaEnv, elem2, algs2) = generatePathVarDeclarationsList({arg}, {cref2}, localCache, localEnv, localDfaEnv);
        algs3 = getPatternComp(RP_NONE("dummy"), cref, false); // Check if it is, in fact, SOME
        
        algs = listAppend(algs1, algs2);
        algs = listAppend(algs3, algs);
        elem = listAppend(elem1, elem2);
      then (localCache,localDfaEnv,elem,algs);
  end matchcontinue;
end generatePathVarDeclarationsNew;

protected function identToCrefExp
  input String id;
  output Absyn.Exp out;
algorithm
  out := Absyn.CREF(Absyn.CREF_IDENT(id,{}));
end identToCrefExp;

protected function createPathVarAssignments 
"function: createPathVarAssignments
	author: KS
	Used when we have a record constructor call in a pattern and need to
	bind the path variables of the subpatterns of the record constructor
	to values."
  input Absyn.Ident recVarName;
  input list<Absyn.Ident> pathVarList;
  input list<Absyn.Ident> fieldNameList;
  input list<Absyn.AlgorithmItem> accList;
  input Integer fieldNum;
  output list<Absyn.AlgorithmItem> outList;
algorithm
  outList := matchcontinue (recVarName,pathVarList,fieldNameList,accList,fieldNum)
    local
      list<Absyn.AlgorithmItem> localAccList;
      Absyn.Ident localRecVarName,firstPathVar,firstFieldName;
      list<Absyn.Ident> restVar,restFieldNames;
      list<Absyn.AlgorithmItem> elem;
      list<Absyn.Ident> restVar;
      Integer n;
    case (_,{},{},localAccList,_) then localAccList;
    // This case is for tuples when we simply call metaMGetField(x,num)
    case (localRecVarName,firstPathVar :: restVar,_,localAccList,n)
      equation
        elem = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(
          Absyn.CREF(Absyn.CREF_IDENT(firstPathVar,{})),
          Absyn.CALL(Absyn.CREF_IDENT("mmc_get_field",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localRecVarName,{})),Absyn.INTEGER(n)},{}))),NONE())};
        localAccList = listAppend(localAccList,elem);
        localAccList = createPathVarAssignments(localRecVarName,restVar,{},localAccList,n+1);
      then localAccList;
  end matchcontinue;
end createPathVarAssignments;

protected function createPathVarAssignmentsCall
"function: createPathVarAssignments
	author: KS
	Used when we have a record constructor call in a pattern and need to
	bind the path variables of the subpatterns of the record constructor
	to values."
  input Absyn.Ident recVarName;
  input list<Absyn.Ident> pathVarList;
  input list<Absyn.Ident> fieldNameList;
  input list<Absyn.AlgorithmItem> accList;
  input SCode.Restriction restriction;
  input Absyn.ComponentRef cref;
  output list<Absyn.AlgorithmItem> outList;
algorithm
  outList := matchcontinue (recVarName,pathVarList,fieldNameList,accList,restriction,cref)
    local
      list<Absyn.AlgorithmItem> localAccList;
      Absyn.Ident localRecVarName,firstPathVar,firstFieldName;
      list<Absyn.Ident> restVar,restFieldNames;
      list<Absyn.AlgorithmItem> elem;
      list<Absyn.Ident> restVar;
      Integer n;
    case (_,{},{},localAccList,_,_) then localAccList;
    // We should use fieldNames to create assignments.
    case (localRecVarName,firstPathVar::restVar,firstFieldName::restFieldNames,localAccList,SCode.R_RECORD(),cref)
      equation
        elem = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(
          Absyn.CREF(Absyn.CREF_IDENT(firstPathVar,{})),
          Absyn.CREF(Absyn.CREF_QUAL(localRecVarName,{},
          Absyn.CREF_IDENT(firstFieldName,{})))),NONE())};
        localAccList = listAppend(localAccList,elem);
        localAccList = createPathVarAssignmentsCall(localRecVarName,restVar,restFieldNames,localAccList,restriction,cref);
      then localAccList;
    case (localRecVarName,firstPathVar::restVar,firstFieldName::restFieldNames,localAccList,SCode.R_METARECORD(utPath,utIndex),cref)
      local
        Absyn.Path utPath;
        Absyn.Exp utCref;
        Integer utIndex;
      equation
        elem = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(
          Absyn.CREF(Absyn.CREF_IDENT(firstPathVar,{})),
          Absyn.CALL(Absyn.CREF_IDENT("mmc_get_field",{}),
          Absyn.FUNCTIONARGS({Absyn.CREF(Absyn.CREF_IDENT(localRecVarName,{})),Absyn.CREF(cref),Absyn.STRING(firstFieldName)},{}))),NONE())};
        localAccList = listAppend(localAccList,elem);
        localAccList = createPathVarAssignmentsCall(localRecVarName,restVar,restFieldNames,localAccList,restriction,cref);
      then localAccList;
    case (_,_,_,_,_,_)
      equation
        Debug.fprintln("matchcase", "- createPathVarAssignmentsCall failed");
      then fail();
  end matchcontinue;
end createPathVarAssignmentsCall;

end DFA;

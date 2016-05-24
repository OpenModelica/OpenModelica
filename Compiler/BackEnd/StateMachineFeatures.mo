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

encapsulated package StateMachineFeatures
" file:        StateMachineFeatures.mo
  package:     StateMachineFeatures
  description: Provides support for Modelica State Machines.
"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEUtil;
protected import List;
protected import Util;
protected import HashSet;
protected import BaseHashSet;
protected import HashTableSM;
protected import Array;
protected import PrefixUtil;
protected import ExpressionDump;
protected import ValuesUtil;
protected import DAEDump;
protected import HashTableExpToIndexExp;
protected import MathematicaDump;


public
uniontype Mode "
Collecting information about a mode/state"
  record MODE
    String name;
    Boolean isInitial;
    HashSet.HashSet edges "relations to other modes due to in- and out-going transitions";
    BackendDAE.EquationArray eqs "equations defined in the mode instance"; // Better use list<BackendDAE.Equation> eqs;?
    BackendDAE.EquationArray outgoing "outgoing transitions";
    list<BackendDAE.Var> outShared "outer output variables of state";
    list<BackendDAE.Var> outLocal "output variables and (non-input) local variables of state";
    //list<BackendDAE.Var> outStateInnerOuters "inner outer output variables of state";
    list<DAE.ComponentRef> crefPrevious "crefs for which a rhs 'previous(cref)' exists in state";
  end MODE;
end Mode;

// Table having crefs as keys and corresponding MODE as value
type ModeTable = HashTableSM.HashTable;

public
uniontype IncidenceTable
  record INCIDENCE_TABLE
    HashTable.HashTable cref2index "Map cref to corresponding index in incidence matrix";
    Boolean incidence[:,:] "Incidence matrix showing which modes are connected by transitions";
  end INCIDENCE_TABLE;
end IncidenceTable;

public
uniontype FlatAutomaton
  record FLAT_AUTOMATON
    DAE.ComponentRef initialState;
    //HashSet.HashSet states;
    array<DAE.ComponentRef> states;
    SMSemantics sms;
  end FLAT_AUTOMATON;
end FlatAutomaton;


public
uniontype Composition "Hierarchical composition of mode automaton"
  record R
    DAE.ComponentRef initialState;
    array<tuple<DAE.ComponentRef,list<Composition>>> refining;
  end R;
end Composition;
/* The MLS example as Composition
{R("state1", {
  ("state1", {
    R("state1.stateA", {
      ("state1.stateA", {}),
      ("state1.stateB", {}),
      ("state1.stateC", {}),
      ("state1.stateD", {})
    }),
    R("state1.stateX", {
      ("state1.stateX", {}),
      ("state1.stateY", {})
    })
  }),
  ("state2", {})
})}
*/


public
uniontype Transition "
Properties of a transition"
  record TRANSITION
    Integer from;
    Integer to;
    Boolean immediate = true;
    Boolean reset = true;
    Boolean synchronize = false;
    Integer priority = 1;
  end TRANSITION;
end Transition;

public
uniontype SMSemantics
  record SMS
    list<DAE.ComponentRef> q "States";
    list<Transition> t "List/Array of transition data sorted in priority";
    list<DAE.Exp> c "Transition conditions sorted in priority";
    list<BackendDAE.Var> vars "SMS veriables";
    list<BackendDAE.Var> knowns "SMS constants/parameters";
    list<BackendDAE.Equation> eqs "SMS equations";
  end SMS;
end SMSemantics;

public
uniontype AutomataEqs "
Synthesized equations for (hierarchic/parallel) Automata/State Machines"
  record AUTOMATA_EQS
    list<BackendDAE.Var> vars "synthesized veriables";
    list<BackendDAE.Var> knowns "synthesized constants/parameters";
    list<BackendDAE.Equation> eqs "synthesized equations";
  end AUTOMATA_EQS;
end AutomataEqs;

public
uniontype TransitionType
  record T_TRANSITION "transtion(..) statement"
  end T_TRANSITION;
  record T_INITIAL_STATE "initialState(..) statement"
  end T_INITIAL_STATE;
end TransitionType;

constant String SMS_PRE = "smOf" "prefix for crefs of fresh State Machine Semantics variables/knowns";
constant Boolean DEBUG_SMDUMP = false "enable verbose stdout debug information during elaboration";

public function stateMachineElab
  "Deactived old module, since now implemented in frontend. See function 'stateMachineElabDEACTIVATED' for old code.

   Might want to reactivate (and adapt) the module at a later time, particularly when state machine support is to be
   extended to support features that cannot be handled in a good way in the front-end.
  "
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := inDAE;
end stateMachineElab;

public function stateMachineElabDEACTIVATED
  "Elaborate state machines and transform them in data-flow equations."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  ModeTable modes;
  Integer nModes;
  list<String> names;
  IncidenceTable iTable;
  IncidenceTable transClosure;
  list<DAE.ComponentRef> initialStates;
  list<FlatAutomaton> flatAutomata;
  list<Composition> comps;
  list<String> ss;
  AutomataEqs automataEqs;
  BackendDAE.EqSystem syst, systNew;
  BackendDAE.Shared shared, sharedNew;
algorithm

  if DEBUG_SMDUMP then
    print("***** SMF-stateMachineElab BackendDAE INPUT: ***** \n");
    BackendDump.printBackendDAE(inDAE);
  end if;

  (syst, shared) := match inDAE
    local
      BackendDAE.EqSystem syst1;
      BackendDAE.Shared shared1;
    case (BackendDAE.DAE({syst1}, shared1)) then (syst1, shared1);
    else equation
      BackendDAE.DAE({syst1}, shared1) = BackendDAEOptimize.collapseIndependentBlocks(inDAE);
    then (syst1, shared1);
  end match;

  if DEBUG_SMDUMP then
    print("***** SMF-stateMachineElab Vars: ***** \n");
    print(dumpVarsStr(syst));
  end if;

  // Identify modes in the system
  modes := identifyModes(syst);
  names := List.map(BaseHashTable.hashTableKeyList(modes), ComponentReference.crefLastIdent);
  if (not listEmpty(names)) then
    if DEBUG_SMDUMP then
      print("***** SMF-stateMachineElab States: ***** \n" + stringDelimitList(names, ",")  + "\n");
      print("***** SMF-stateMachineElab ModeTable: ***** \n");
      BaseHashTable.dumpHashTable(modes);
    end if;
    nModes := BaseHashTable.hashTableCurrentSize(modes);

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: Incidence matrix: ***** \n"); end if;
    iTable := createIncidenceTable(modes, nModes);
    if DEBUG_SMDUMP then printIncidenceTable(iTable, nModes); end if;

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: Transitive closure: ***** \n"); end if;
    transClosure := transitiveClosure(iTable, nModes);
    if DEBUG_SMDUMP then printIncidenceTable(transClosure, nModes); end if;

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: Initial States: ***** \n"); end if;
    initialStates := extractInitialStates(modes);
    if DEBUG_SMDUMP then print( stringDelimitList(List.map(initialStates, ComponentReference.printComponentRefStr), ", ") + "\n"); end if;

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: Flat Automata: ***** \n"); end if;
    flatAutomata := extractFlatAutomata(initialStates, transClosure, nModes);
    if DEBUG_SMDUMP then print(stringDelimitList(List.map(flatAutomata,dumpFlatAutomatonStr), "\n") + "\n"); end if;

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: Composition: ***** \n"); end if;
    comps := getComposition(flatAutomata);
    ss := List.map(comps, dumpCompositionStr);
    if DEBUG_SMDUMP then print(stringDelimitList(ss, ",\n") + "\n"); end if;

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: annotate modes with additional information ***** \n"); end if;
    (modes, systNew, sharedNew) := annotateModes(modes, syst, shared);
    if DEBUG_SMDUMP then BaseHashTable.dumpHashTable(modes); end if;

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: Replace all outer variables by their coressponding inner variables ***** \n"); end if;
    // FIXME: The current approach has deficiencies since the variable replacement needs to be done on the global equation level and not only on the mode level
    // BackendVariable.varStartValue
    (modes, systNew) := List.fold(BaseHashTable.hashTableList(modes), elaborateMode, (modes, systNew));
    if DEBUG_SMDUMP then BaseHashTable.dumpHashTable(modes); end if;

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: annotate Flat Automata with semantic equations  ***** \n"); end if;
    flatAutomata := List.map1(flatAutomata, annotateFlatAutomaton, modes);

    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: Synthesize automata equations  ***** \n"); end if;
    (automataEqs, systNew) := synthesizeAutomataEqs(modes, comps, flatAutomata, true, AUTOMATA_EQS({},{},{}), systNew);

    //print("***** SMF-stateMachineElab: Update backend DAE (Don't use yet)  ***** \n");
    //(systNew, sharedNew) := updateBackendDAE_DontUseYet(systNew, sharedNew, automataEqs);
    if DEBUG_SMDUMP then print("***** SMF-stateMachineElab: Wrap equations in when clauses hack  ***** \n"); end if;
    (systNew, sharedNew) := wrapHack(systNew, sharedNew, automataEqs, 1.0);

    outDAE := BackendDAE.DAE({systNew}, sharedNew);
  else
    outDAE := inDAE;
  end if;

  if DEBUG_SMDUMP then
    print("***** SMF-stateMachineElab BackendDAE OUTPUT: ***** \n");
    BackendDump.printBackendDAE(outDAE);
    //BackendDump.dumpBackendDAEToModelica(outDAE, "AFTERSMELAB");
    //BackendDump.printShared(shared);
    //debugPrintKnownVars(shared);
    //BackendDump.dumpEqSystems({syst}, "Ordered");
    //BackendDump.printShared(shared);
  end if;

end stateMachineElabDEACTIVATED;

protected function synthesizeAutomataEqs "
Author: BTH
Synthesize Automata/state machines relevant data-flow equations.
"
  input ModeTable modes;
  input list<Composition> comps;
  input list<FlatAutomaton> flatAs;
  input Boolean isTopLevel "true if comps are the toplevel Automata";
  input AutomataEqs synEqsAcc;
  input BackendDAE.EqSystem systIn;
  output AutomataEqs synEqsOut;
  output BackendDAE.EqSystem systOut;
algorithm
  systOut := systIn;
  synEqsOut := synEqsAcc;
  for comp in comps loop
    (synEqsOut, systOut) := synthesizeAutomatonEqs(modes, comp, flatAs, isTopLevel, synEqsOut, systOut);
  end for;
end synthesizeAutomataEqs;

protected function synthesizeAutomatonEqs "
Author: BTH
Synthesize Automaton/state machine relevant data-flow equations.
"
  input ModeTable modes;
  input Composition comp;
  input list<FlatAutomaton> flatAs;
  input Boolean isTopLevel "true if comp is a toplevel Automata";
  input AutomataEqs synEqsAcc;
  input BackendDAE.EqSystem systIn;
  output AutomataEqs synEqsOut;
  output BackendDAE.EqSystem systOut;
protected
  DAE.ComponentRef initRef, resetRef, stateRef, activeResetStateRef, activeStateRef, activeResetRef, activeRef;
  BackendDAE.Var initVar, activePlotIndicatorVar;
  DAE.ComponentRef preRef, refiningRef, refiningResetRef, refiningActiveRef;
  Composition refiningComp;
  list<Composition> stateRefiningComps, refiningComps;
  FlatAutomaton flatA;
  DAE.Exp rhs, andExp, eqExp, activeResetStateRefExp, activeStateRefExp, activeResetRefExp;
  BackendDAE.EquationAttributes bindingKind;
  BackendDAE.Equation activePlotIndicatorEqn;
  DAE.Type tArrayBool;
  Integer n,i,nStates;
  AutomataEqs synEqs;
  // FLAT_AUTOMATON
  DAE.ComponentRef initialState;
  array<DAE.ComponentRef> states;
  SMSemantics sms;
  // AUTOMATA_EQS
  list<BackendDAE.Var> vars, varsAdd "synthesized veriables";
  list<BackendDAE.Var> knowns, knownsAdd "synthesized constants/parameters";
  list<BackendDAE.Equation> eqs, eqsAdd "synthesized equations";
  // COMPOSITION
  DAE.ComponentRef initialState, refiningRefined;
  array<tuple<DAE.ComponentRef,list<Composition>>> refining;
  list<tuple<DAE.ComponentRef,list<Composition>>> refiningFiltered;
algorithm
  AUTOMATA_EQS(vars, knowns, eqs) := synEqsAcc;
  bindingKind := BackendDAE.EQUATION_ATTRIBUTES(false, BackendDAE.BINDING_EQUATION());

  R(initialState, refining) := comp;
  flatA := List.find1(flatAs, findInitialState, initialState);
  FLAT_AUTOMATON(initialState, states, sms) := flatA;
  preRef := ComponentReference.crefPrefixString(SMS_PRE, initialState);
  nStates := arrayLength(states);
  tArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource);

  SMS(vars=varsAdd, knowns=knownsAdd, eqs=eqsAdd) := sms;
  // Add var, knowns, eqs of flat automaton to equation system
  vars := listAppend(vars, varsAdd);
  knowns := listAppend(knowns, knownsAdd);
  eqs := listAppend(eqs, eqsAdd);

  // toplevel Automata need to "self-reset" at their first clock tick. After that reset is always false
  // FIXME: Except if we have self transitions or other reset transitions back on the initial state??
  if isTopLevel then
    // Boolean preRef.init(start=true) = false
    initRef := qCref("init", DAE.T_BOOL_DEFAULT, {}, preRef);
    initVar := createVarWithDefaults(initRef, BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);
    initVar := BackendVariable.setVarStartValue(initVar, DAE.BCONST(true));
    initVar := BackendVariable.setVarFixed(initVar, true);
    vars := initVar :: vars;
    eqs := BackendDAE.EQUATION(DAE.CREF(initRef, DAE.T_BOOL_DEFAULT), DAE.BCONST(false), DAE.emptyElementSource, bindingKind) :: eqs;
    // preRef.reset = previous(preRef.init)
    resetRef := qCref("reset", DAE.T_BOOL_DEFAULT, {}, preRef);
    rhs := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(initRef, DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
    eqs := BackendDAE.EQUATION(DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT), rhs, DAE.emptyElementSource, bindingKind) :: eqs;

    // input Boolean active "true if the state machine is active";
    // set to "true", since toplevel state machines is always active
    activeRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, preRef);
    eqs := BackendDAE.EQUATION(DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT), DAE.BCONST(true), DAE.emptyElementSource, bindingKind) :: eqs;
  end if;


  n := arrayLength(refining);
  refiningComps := {};
  for i in 1:n loop
    (stateRef,stateRefiningComps) := arrayGet(refining,i);
    // propagate reset handling and activation handling to state machine refinements
    if not listEmpty(stateRefiningComps) then
      for refiningComp in stateRefiningComps loop
        // Add equation for reset handling
        //  SMS_PRE.refiningComp.reset = SMS_PRE.initialState.activeResetStates[i] or (SMS_PRE.initialState.activeReset and SMS_PRE.initialState.activeState==i)
        activeResetStateRef := qCref("activeResetStates", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef);
        activeResetStateRefExp := DAE.CREF(activeResetStateRef, DAE.T_BOOL_DEFAULT);
        activeStateRef :=  qCref("activeState", DAE.T_INTEGER_DEFAULT, {}, preRef);
        activeStateRefExp :=  DAE.CREF(activeStateRef, DAE.T_INTEGER_DEFAULT);
        activeResetRef := qCref("activeReset", DAE.T_BOOL_DEFAULT, {}, preRef);
        activeResetRefExp :=  DAE.CREF(activeResetRef, DAE.T_BOOL_DEFAULT);
        // SMS_PRE.initialState.activeState==i
        eqExp := DAE.RELATION(activeStateRefExp, DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(i),-1, NONE());
        // SMS_PRE.initialState.activeReset and SMS_PRE.initialState.activeState==i
        andExp := DAE.LBINARY(activeResetRefExp, DAE.AND(DAE.T_BOOL_DEFAULT), eqExp);
        rhs := DAE.LBINARY(activeResetStateRefExp, DAE.OR(DAE.T_BOOL_DEFAULT), andExp);
        R(initialState=refiningRefined) := refiningComp;
        refiningRef := ComponentReference.crefPrefixString(SMS_PRE, refiningRefined);
        refiningResetRef := qCref("reset", DAE.T_BOOL_DEFAULT, {}, refiningRef);
        eqs := BackendDAE.EQUATION(DAE.CREF(refiningResetRef, DAE.T_BOOL_DEFAULT), rhs, DAE.emptyElementSource, bindingKind) :: eqs;
        // Add equation for activation handling
        // SMS_PRE.refiningComp.active = (SMS_PRE.initialState.activeReset.activeState == i)
        refiningActiveRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, refiningRef);
        eqs := BackendDAE.EQUATION(DAE.CREF(refiningActiveRef, DAE.T_BOOL_DEFAULT), eqExp, DAE.emptyElementSource, bindingKind) :: eqs;
      end for;
    end if;
    refiningComps := listAppend(refiningComps, stateRefiningComps);

    // Add indication for plotting whether a state is active or not
    (activePlotIndicatorVar, activePlotIndicatorEqn) :=  synthesizeAutomatonEqsCreateActiveIndication(stateRef, preRef, i);
    vars := activePlotIndicatorVar :: vars;
    eqs :=  activePlotIndicatorEqn :: eqs;

  end for;

  // Transform equations within a mode to conditional data-flow equations
  (synEqs, systOut) := synthesizeAutomatonEqsModeToDataflow(modes, flatA, AUTOMATA_EQS(vars,knowns,eqs), systIn);

  // recursion into refined substates
  synEqsOut := synthesizeAutomataEqs(modes, refiningComps, flatAs, false, synEqs, systOut);

end synthesizeAutomatonEqs;


protected function synthesizeAutomatonEqsModeToDataflow "
Author: BTH
Helper function to synthesizeAutomatonEqs.
Transform equations within a mode to conditional data-flow equations
"
  input ModeTable modes;
  input FlatAutomaton flatA;
  input AutomataEqs synEqsIn;
  input BackendDAE.EqSystem systIn;
  output AutomataEqs synEqsOut;
  output BackendDAE.EqSystem systOut = systIn;
protected
  Integer n,i;
  DAE.ComponentRef cref, preRef, activeRef, activeStateRef;
  DAE.Exp activeRefExp, activeStateRefExp, relExp, andExp, rhs, previousExp;
  BackendDAE.Var var;
  list<tuple<Integer,BackendDAE.Var>> outStateInnerOuters;
  BackendDAE.Type varType;
  DAE.CallAttributes callAttributes;
  list<BackendDAE.Equation> outLocalEqns;
  HashSet.HashSet crefLocalsSet, crefSharedSet;
  HashTableExpToIndexExp.HashTable sharedCrefToStateExps;
  HashTableExpToIndexExp.Value sharedStateExps;
  BackendDAE.EquationAttributes attrDynamic, bindingKind;
  // CREF
  DAE.ComponentRef componentRef;
  DAE.Type ty;
  // EQUATION
  DAE.Exp exp;
  DAE.Exp scalar;
  DAE.ElementSource source "origin of equation";
  BackendDAE.EquationAttributes attr;
  // AUTOMATA_EQS
  list<BackendDAE.Var> vars2 "synthesized veriables";
  list<BackendDAE.Var> knowns2 "synthesized constants/parameters";
  list<BackendDAE.Equation> eqs2 "synthesized equations";
  // FLAT_AUTOMATON
  DAE.ComponentRef initialState;
  array<DAE.ComponentRef> states;
  SMSemantics sms;
  // MODE
  String name;
  Boolean isInitial;
  HashSet.HashSet edges "relations to other modes due to in- and out-going transitions";
  BackendDAE.EquationArray eqs "equations defined in the mode instance";
  BackendDAE.EquationArray outgoing "outgoing transitions";
  list<BackendDAE.Var> outShared "outer output variables of state";
  list<BackendDAE.Var> outLocal "output variables and (non-input) local variables of state";
  list<DAE.ComponentRef> crefPrevious "crefs for which a rhs 'previous(cref)' exists in state";
algorithm
  FLAT_AUTOMATON(initialState, states, sms) := flatA;
  AUTOMATA_EQS(vars2,knowns2,eqs2) := synEqsIn;

  outStateInnerOuters := {};
  outLocalEqns := {};
  sharedCrefToStateExps := HashTableExpToIndexExp.emptyHashTable();
  attrDynamic := BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC;

  preRef := ComponentReference.crefPrefixString(SMS_PRE, initialState);
  activeRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, preRef);
  activeRefExp := DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT);
  activeStateRef :=  qCref("activeState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  activeStateRefExp :=  DAE.CREF(activeStateRef, DAE.T_INTEGER_DEFAULT);
  n := arrayLength(states);
  for i in 1:n loop
    cref := arrayGet(states, i);
    MODE(name, isInitial, edges, eqs, outgoing, outShared, outLocal, crefPrevious) := BaseHashTable.get(cref, modes);
    crefLocalsSet := List.applyAndFold(outLocal, BaseHashSet.add, BackendVariable.varCref, HashSet.emptyHashSet());
    crefSharedSet := List.applyAndFold(outShared, BaseHashSet.add, BackendVariable.varCref, HashSet.emptyHashSet());
    // collect all inner outer outputs together with the index of the state they occur in
    outStateInnerOuters := listAppend(outStateInnerOuters, List.map(List.filterOnTrue(outLocal,filterInnerOuters), function Util.makeTuple(inValue1=i)));

    // SMS_PRE.initialState.activeState == i
    relExp := DAE.RELATION(activeStateRefExp, DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(i),-1, NONE());
    // SMS_PRE.initialState.activeState==i and SMS_PRE.initialState.active
    andExp := DAE.LBINARY(relExp, DAE.AND(DAE.T_BOOL_DEFAULT), activeRefExp);
    for eqn in BackendEquation.equationList(eqs) loop
      BackendDAE.EQUATION(exp,scalar,source,attr) := eqn;
      DAE.CREF(componentRef=componentRef,ty=ty) := exp;

      // If lhs x is a local variable add equation "x := if stateActive then exp else previous(x)"
      if BaseHashSet.has(componentRef, crefLocalsSet) then
        callAttributes := DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
        previousExp := DAE.CALL(Absyn.IDENT("previous"), {exp}, callAttributes);
        rhs := DAE.IFEXP(andExp, scalar, previousExp);
        outLocalEqns :=  BackendDAE.EQUATION(exp, rhs, source, attr) :: outLocalEqns;

        // Find variable corresponding to componentRef
        var := List.find1(outLocal,cmpVarCref,componentRef);

        // If lhs "x" is a state variable, i.e., "x" appears somewhere in the global equation system as "previous(x)",
        // than substitute all "previous(x)" by a fresh variable "x_previous" which is defined by an equation "x_previous = if resetOfState than initialValueOfX else previous(x)"
        // FIXME this substitution logic isn't sufficient since it is possible that a another mode (whose equations are not yet in synthesized to systOut) contains equations with "previous(x)" that would be missed by the current algorithm
        (vars2, outLocalEqns, systOut) := handleResets(exp, var, n, i, andExp, preRef, vars2, outLocalEqns, systOut);

      // If lhs x is an outer variable accumulate rhs in hash entry for x for later merging of variable definitions
      elseif BaseHashSet.has(componentRef, crefSharedSet) then
        if BaseHashTable.hasKey(exp,sharedCrefToStateExps) then
          sharedStateExps := (i,scalar) :: BaseHashTable.get(exp,sharedCrefToStateExps);
          BaseHashTable.update((exp,sharedStateExps),sharedCrefToStateExps);
        else
          sharedCrefToStateExps := BaseHashTable.addNoUpdCheck((exp,{(i,scalar)}),sharedCrefToStateExps);
        end if;
      end if;
    end for;
  end for;

  // Add equations for connecting inner outer output crefs to outer outputs that are one level deeper in the instance hierarchy
  sharedCrefToStateExps := List.fold(outStateInnerOuters, addInnerOuterConnection, sharedCrefToStateExps);

  // merge variable definitions
  for entry in BaseHashTable.hashTableList(sharedCrefToStateExps) loop
    (exp,sharedStateExps) := entry;
    // assume the shared variable is "x" and the if-condition "expIf(i) = SMS_PRE.initialState.activeState==i and SMS_PRE.initialState.active",
    // the aim is to merge the shared variable definitions into an equation with the structure
    // x = if expIf(1) then rhsOfState_1 else (if expIf(2) then rhsOfState_2 else (... else (if expIf(n) then rhsOfState_n else previous(x))))
    rhs := mergeVariableDefinitions(sharedStateExps,exp,activeStateRefExp,activeRefExp,systOut);
    outLocalEqns :=  BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, attr) :: outLocalEqns;
  end for;

  synEqsOut := AUTOMATA_EQS(vars2,knowns2,listAppend(eqs2,listReverse(outLocalEqns)));
end synthesizeAutomatonEqsModeToDataflow;

protected function addInnerOuterConnection "
Author: BTH
Helper function to synthesizeAutomatonEqsModeToDataflow.
Constructs (hopefully) a relation betwenn an inner outer cref and its corresponding inner cref.
Probably rather fragile approach...
"
  input tuple<Integer,BackendDAE.Var> inStateVar;
  input HashTableExpToIndexExp.HashTable inTable;
  output HashTableExpToIndexExp.HashTable outTable = inTable;
protected
  DAE.Exp key, exp;
  Integer i;
  BackendDAE.Var var;
  DAE.ComponentRef varName, strippedName, crefLast, crefInner;
  DAE.Type varType;
  HashTableExpToIndexExp.Value sharedStateExps;
algorithm
  (i,var) := inStateVar;
  BackendDAE.VAR(varName=varName,varType=varType) := var;

  // with some luck this cref construction gives the corresponding inner...
  crefLast := ComponentReference.crefLastCref(varName);
  if (ComponentReference.crefDepth(varName) > 2) then
    strippedName := ComponentReference.crefStripLastIdent(ComponentReference.crefStripLastIdent(varName));
    crefInner := ComponentReference.joinCrefs(strippedName,crefLast);
  else
    crefInner := crefLast;
  end if;

  key := DAE.CREF(crefInner,varType);
  exp := DAE.CREF(varName,varType);

  if BaseHashTable.hasKey(key,outTable) then
    sharedStateExps := (i,exp) :: BaseHashTable.get(key,outTable);
    BaseHashTable.update((key,sharedStateExps),outTable);
  else
    outTable := BaseHashTable.addNoUpdCheck((key,{(i,exp)}),outTable);
  end if;
end addInnerOuterConnection;

protected function filterInnerOuters "
Helper function to synthesizeAutomatonEqsModeToDataflow"
  input BackendDAE.Var inElement;
  output Boolean outB;
algorithm
  outB := match inElement
    case BackendDAE.VAR(innerOuter=DAE.INNER_OUTER()) then true;
    else false;
  end match;
end filterInnerOuters;

protected function handleResets "
Author: BTH
Handle state machine resets for discrete 'state' variables.
Ugly helper function to synthesizeAutomatonEqsModeToDataflow"
  input DAE.Exp varCRefToCheck;
  input BackendDAE.Var varToCheck "variable that corresponds to varCRefToCheck";
  input Integer n "number of modes in flat automaton";
  input Integer i "number of mode that we are currently in";
  input DAE.Exp stateActivationExp;
  input DAE.ComponentRef preRef;
  input list<BackendDAE.Var> inLocalVars;
  input list<BackendDAE.Equation> inLocalEqns;
  input BackendDAE.EqSystem systIn;
  output list<BackendDAE.Var> outLocalVars = inLocalVars "possibly one fresh substitution variable is added to this list";
  output list<BackendDAE.Equation> outLocalEqns = inLocalEqns "possibly fresh equations are added to this list";
  output BackendDAE.EqSystem systOut = systIn "possibly instances of 'previous(x)' are substituted by 'x_previous'";
protected
  DAE.ComponentRef substituteRef, activeResetRef, activeResetStatesRef;
  DAE.Exp orExp, andExp, activeResetRefExp, ifExp, startValueExp, previousExp, substituteExp;
  Boolean gotHits;
  BackendDAE.Var var, substituteVar;
  DAE.Type tArrayBool;
  BackendDAE.EquationAttributes attrDynamic;
  DAE.CallAttributes callAttributes;
  // CREF
  DAE.ComponentRef componentRef;
  DAE.Type ty;
algorithm
  DAE.CREF(componentRef=componentRef, ty=ty) := varCRefToCheck;
  tArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_INTEGER(n)}, DAE.emptyTypeSource);
  callAttributes := DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
  attrDynamic := BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC;

  activeResetRef := qCref("activeReset", DAE.T_BOOL_DEFAULT, {}, preRef);
  activeResetRefExp := DAE.CREF(activeResetRef, DAE.T_BOOL_DEFAULT);
  substituteRef := ComponentReference.appendStringLastIdent("_previous", componentRef);
  gotHits := false;
  substituteExp := DAE.CREF(substituteRef, ty);
  previousExp := DAE.CALL(Absyn.IDENT("previous"), {varCRefToCheck}, callAttributes);

  (outLocalEqns,(_,(_,_,gotHits))) := BackendEquation.traverseExpsOfEquationList(outLocalEqns, Expression.traverseSubexpressionsHelper, (traversingPreviousExpByVariableSubsHelper, (previousExp, substituteExp, false)));
  (_,(_,_,gotHits)) := BackendDAEUtil.traverseBackendDAEExpsEqSystemWithUpdate(systOut, Expression.traverseSubexpressionsHelper, (traversingPreviousExpByVariableSubsHelper, (previousExp, substituteExp, gotHits)));
  if gotHits then
    // Add substitute variable "x_previous"
    substituteVar := createVarWithDefaults(substituteRef, BackendDAE.VARIABLE(), ty);
    outLocalVars := substituteVar :: outLocalVars;

    // Find start value for the variable that is to be substituted, i.e., "x.start" of "previous(x)"
    startValueExp := BackendVariable.varStartValue(varToCheck);

    // Add defining equation for substitute variable "x_previous = if (activeState==i and active and (activeReset or activeResetStates[i])) than startValueOfX else previous(x)"
    activeResetStatesRef := qCref("activeResetStates", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef);
    // activeReset or activeResetStates[i]
    orExp := DAE.LBINARY(activeResetRefExp, DAE.OR(DAE.T_BOOL_DEFAULT), DAE.CREF(activeResetStatesRef, DAE.T_BOOL_DEFAULT));
    // activeState==i and active and (activeReset or activeResetStates[i])
    andExp := DAE.LBINARY(stateActivationExp, DAE.AND(DAE.T_BOOL_DEFAULT), orExp);
    // if (activeState==i and active and (activeReset or activeResetStates[i])) than startValueOfX else previous(x)
    ifExp := DAE.IFEXP(andExp, startValueExp, previousExp);
    outLocalEqns :=  BackendDAE.EQUATION(DAE.CREF(substituteRef, ty), ifExp, DAE.emptyElementSource, attrDynamic) :: outLocalEqns;
  end if;
end handleResets;


protected function cmpVarCref
  input BackendDAE.Var inElement;
  input DAE.ComponentRef arg;
  output Boolean outSelect;
protected
  DAE.ComponentRef varName;
algorithm
  BackendDAE.VAR(varName=varName) := inElement;
  outSelect := ComponentReference.crefEqual(varName,arg);
end cmpVarCref;

protected function traversingPreviousExpByVariableSubsHelper "
Author: BTH
Helper function to synthesizeAutomatonEqsModeToDataflow for traversing the BackendDAE.EqSystem
Searches for previous(x), replaces occurances by 'x_previous' and indicates whether substitution were performed"
  input DAE.Exp inExp;
  input tuple<DAE.Exp,DAE.Exp,Boolean> inPatternSubstituteHit;
  output DAE.Exp outExp;
  output tuple<DAE.Exp,DAE.Exp,Boolean> outPatternSubstituteHit;
protected
  DAE.Exp patternExp, substituteExp;
  Boolean gotHit;
algorithm
  (patternExp,substituteExp,gotHit) := inPatternSubstituteHit;
  (outExp,outPatternSubstituteHit) := match inExp
    local
      DAE.Exp e;
    case e guard Expression.expEqual(e,patternExp) then (substituteExp,(patternExp,substituteExp,true));
    else (inExp,inPatternSubstituteHit);
  end match;
end traversingPreviousExpByVariableSubsHelper;

protected function replaceInnerOuterByInner "
Author: BTH
Helper function to mergeVariableDefinitions
Fragile hack. Check if sharedCrefExp is 'inner outer', if so replace all previous(sharedCrefExp) by previous(inner cref that corresponds to sharedCrefExp)"
  input list<tuple<Integer,DAE.Exp>> inStateExpLst;
  input DAE.Exp SharedCrefExp;
  input BackendDAE.EqSystem systIn;
  output list<tuple<Integer,DAE.Exp>> outStateExpLst = inStateExpLst;
protected
  BackendDAE.Variables orderedVars "ordered Variables, only states and alg. vars";
  BackendDAE.Var sharedVar;
  DAE.ComponentRef sharedCref,crefLast,strippedName,crefInner;
  DAE.Type ty;
  DAE.VarInnerOuter innerOuter;
  Boolean isInnerOuter;
algorithm
  DAE.CREF(componentRef=sharedCref,ty=ty) := SharedCrefExp;
  BackendDAE.EQSYSTEM(orderedVars=orderedVars) := systIn;
  ({sharedVar},_) := BackendVariable.getVar(sharedCref, orderedVars);
  isInnerOuter := match sharedVar
    case BackendDAE.VAR(innerOuter=DAE.INNER_OUTER()) then true;
    else false;
  end match;

  // if sharedCref is "inner outer" try the replacements
  if isInnerOuter then
    // with some luck this cref construction gives the corresponding inner...
    crefLast := ComponentReference.crefLastCref(sharedCref);
    if (ComponentReference.crefDepth(sharedCref) > 2) then
      strippedName := ComponentReference.crefStripLastIdent(ComponentReference.crefStripLastIdent(sharedCref));
      crefInner := ComponentReference.joinCrefs(strippedName,crefLast);
    else
      crefInner := crefLast;
    end if;

    outStateExpLst := List.map2(outStateExpLst,mapReplaceInnerOuterByInner,SharedCrefExp,DAE.CREF(crefInner,ty));

  end if;
end replaceInnerOuterByInner;

protected function mapReplaceInnerOuterByInner "
Helper function to replaceInnerOuterByInner."
  input tuple<Integer,DAE.Exp> inElement;
  input DAE.Exp inFindExp;
  input DAE.Exp inReplaceExp;
  output tuple<Integer,DAE.Exp> outElement;
protected
  Integer i;
  DAE.Exp exp;
algorithm
  (i,exp) := inElement;
  exp := Expression.traverseExpBottomUp(exp,traversingInnerOuterByOuterSubs,(inFindExp,inReplaceExp));
  outElement := (i,exp);
end mapReplaceInnerOuterByInner;

protected function traversingInnerOuterByOuterSubs "
Author: BTH
Helper function to mapReplaceInnerOuterByInner
Searches for an expression and replaces it be the other"
  input DAE.Exp inExp;
  input tuple<DAE.Exp,DAE.Exp> inPatternSubstitute;
  output DAE.Exp outExp;
  output tuple<DAE.Exp,DAE.Exp> outPatternSubstitute;
protected
  DAE.Exp patternExp, substituteExp;
algorithm
  (patternExp,substituteExp) := inPatternSubstitute;
  (outExp,outPatternSubstitute) := match inExp
    local
      DAE.Exp e;
    case e guard Expression.expEqual(e,patternExp) then (substituteExp,(patternExp,substituteExp));
    else (inExp,inPatternSubstitute);
  end match;
end traversingInnerOuterByOuterSubs;


protected function mergeVariableDefinitions "
Author: BTH
Merge variable definitions for outer (shared) variables into an if-expression"
  input list<tuple<Integer,DAE.Exp>> inStateExpLst;
  input DAE.Exp SharedCrefExp;
  input DAE.Exp activeStateRefExp "SMS_PRE.initialState.activeState";
  input DAE.Exp activeRefExp "SMS_PRE.initialState.active";
  input BackendDAE.EqSystem systIn;
  output DAE.Exp res;
protected
  list<tuple<Integer,DAE.Exp>> stateExpLst;
algorithm
  // Fragile hack. Check if sharedCref is "inner outer", if so replace all previous(sharedCref) by previous(inner cref that corresponds to sharedCref)
  stateExpLst := replaceInnerOuterByInner(inStateExpLst, SharedCrefExp, systIn);

  res := match (stateExpLst,SharedCrefExp)
    local
      Integer i;
      DAE.Exp ifExp,relExp;
      list<tuple<Integer,DAE.Exp>> rest;
      DAE.CallAttributes callAttributes;
      // IFEXP
      DAE.Exp expCond;
      DAE.Exp expThen;
      DAE.Exp expElse;
      // CREF
      DAE.ComponentRef cref;
      DAE.Type ty;
    case ((i, expThen)::{}, DAE.CREF(componentRef=cref,ty=ty))
      equation
        callAttributes = DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
        // SMS_PRE.initialState.activeState == i
        relExp = DAE.RELATION(activeStateRefExp, DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(i),-1, NONE());
        // SMS_PRE.initialState.activeState==i and SMS_PRE.initialState.active
        expCond = DAE.LBINARY(relExp, DAE.AND(DAE.T_BOOL_DEFAULT), activeRefExp);
        expElse = DAE.CALL(Absyn.IDENT("previous"), {SharedCrefExp}, callAttributes);
        ifExp = DAE.IFEXP(expCond, expThen, expElse);
      then ifExp;
    case ((i, expThen)::rest,_)
      equation
        // SMS_PRE.initialState.activeState == i
        relExp = DAE.RELATION(activeStateRefExp, DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(i),-1, NONE());
        // SMS_PRE.initialState.activeState==i and SMS_PRE.initialState.active
        expCond = DAE.LBINARY(relExp, DAE.AND(DAE.T_BOOL_DEFAULT), activeRefExp);
        expElse = mergeVariableDefinitions(rest,SharedCrefExp,activeStateRefExp,activeRefExp,systIn);
      then DAE.IFEXP(expCond, expThen, expElse);
  end match;
end mergeVariableDefinitions;


protected function synthesizeAutomatonEqsCreateActiveIndication "
Author: BTH
Helper function to synthesizeAutomatonEqs.
Create indication for plotting whether a state is active or not"
  input DAE.ComponentRef stateRef "cref of state to which activation indication shall be added";
  input DAE.ComponentRef preRef "cref of prefix where variables of governing semantic equations for stateRef are located";
  input Integer i "index of state within flat automaton state array";
  output BackendDAE.Var activePlotIndicatorVar;
  output BackendDAE.Equation eqn;
protected
  DAE.ComponentRef activeRef, activePlotIndicatorRef, activeStateRef;
  DAE.Exp  andExp, eqExp;
  BackendDAE.EquationAttributes bindingKind;
algorithm
  // Create Variable stateRef.active
  // FIXME Use name that cannot possible conflict with user variable (or is .active reserved for state machines?)
  activePlotIndicatorRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, stateRef);
  activePlotIndicatorVar := createVarWithDefaults(activePlotIndicatorRef, BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);

  // stateRef.active := SMS_PRE.initialState.active and (SMS_PRE.initialState.activeState==i)
  activeRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, preRef);
  activeStateRef :=  qCref("activeState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  // SMS_PRE.initialState.activeState==i
  eqExp := DAE.RELATION(DAE.CREF(activeStateRef, DAE.T_INTEGER_DEFAULT), DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(i),-1, NONE());
  // SMS_PRE.initialState.active and (SMS_PRE.initialState.activeState==i)
  andExp := DAE.LBINARY(DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT), DAE.AND(DAE.T_BOOL_DEFAULT), eqExp);
  bindingKind := BackendDAE.EQ_ATTR_DEFAULT_BINDING;
  eqn := BackendDAE.EQUATION(DAE.CREF(activePlotIndicatorRef, DAE.T_BOOL_DEFAULT), andExp, DAE.emptyElementSource, bindingKind);
end synthesizeAutomatonEqsCreateActiveIndication;

protected function filterRs "
Only elements with refined states pass."
  input tuple<DAE.ComponentRef,list<Composition>> inElement;
algorithm
  (_,R()::_) := inElement;
end filterRs;


protected function wrapHack "
Author: BTH
Wrap equations in when-clauses as long as Synchronous Features are not supported"
  input BackendDAE.EqSystem systIn;
  input BackendDAE.Shared sharedIn;
  input AutomataEqs automataEqs;
  input Real samplingTime;
  output BackendDAE.EqSystem systOut;
  output BackendDAE.Shared sharedOut;
protected
  list<BackendDAE.Equation> wrappedEqs;
  BackendDAE.TimeEvent timeEvent;

  // AUTOMATA_EQS
  list<BackendDAE.Var> vars;
  list<BackendDAE.Var> knowns;
  list<BackendDAE.Equation> eqs;
  // Fields of EQUATION_ARRAY
  Integer orderedSize, removedSize;
  Integer orderedNumberOfElement, removedNumberOfElement;
  Integer orderedArrSize, removedArrSize;
  array<Option<BackendDAE.Equation>> orderedEquOptArr, removedEquOptArr;
algorithm
  AUTOMATA_EQS(vars, knowns, eqs) := automataEqs;

  // Hack: Wrap everything in when equations
  // FIXME: Guess there is a reference mechanism and maybe I shouldn't hardcode "1" as index? (needs also adaption in wrapInWhenhack)
  timeEvent := BackendDAE.SAMPLE_TIME_EVENT(1, DAE.RCONST(samplingTime), DAE.RCONST(samplingTime));
  wrappedEqs := List.map1(eqs, wrapInWhenHack, samplingTime);

  systOut := List.fold(vars, BackendVariable.addVarDAE, systIn);
  systOut := BackendEquation.equationsAddDAE(wrappedEqs, systOut);
  sharedOut := List.fold(knowns, BackendVariable.addNewKnVarDAE, sharedIn);
  if (not listEmpty(wrappedEqs)) then
    sharedOut := wrapAddTimeEventHack({timeEvent}, sharedOut);
  end if;
end wrapHack;


protected function updateBackendDAE_DontUseYet "
Author: BTH
Update backend DAE. Don't use as long as synchronous elements support is missing in the backend"
  input BackendDAE.EqSystem systIn;
  input BackendDAE.Shared sharedIn;
  input AutomataEqs automataEqs;
  output BackendDAE.EqSystem systOut;
  output BackendDAE.Shared sharedOut;
protected
  // AUTOMATA_EQS
  list<BackendDAE.Var> vars;
  list<BackendDAE.Var> knowns;
  list<BackendDAE.Equation> eqs;
  // Fields of EQUATION_ARRAY
  Integer orderedSize, removedSize;
  Integer orderedNumberOfElement, removedNumberOfElement;
  Integer orderedArrSize, removedArrSize;
  array<Option<BackendDAE.Equation>> orderedEquOptArr, removedEquOptArr;
algorithm
  AUTOMATA_EQS(vars, knowns, eqs) := automataEqs;
  systOut := List.fold(vars, BackendVariable.addVarDAE, systIn);
  systOut := BackendEquation.equationsAddDAE(eqs, systOut);
  sharedOut := List.fold(knowns, BackendVariable.addNewKnVarDAE, sharedIn);
end updateBackendDAE_DontUseYet;

protected function findInitialState "
Author: BTH
Succeeds if initialState in flatAIn equals the crefCmp, otherwise fails.
Helper function to find flat automaton within a list of flat automata"
  input FlatAutomaton flatAIn;
  input DAE.ComponentRef crefCmp;
  output Boolean outFound;
algorithm
  outFound := match flatAIn
    case FLAT_AUTOMATON() then ComponentReference.crefEqual(flatAIn.initialState, crefCmp);
    else false;
  end match;
end findInitialState;


protected function annotateFlatAutomaton "
Author: BTH
annotate Flat Automata with semantic equations"
  input FlatAutomaton flatAIn;
  input ModeTable modesIn;
  output FlatAutomaton flatAOut;
algorithm
  flatAOut := addSMSemantics(flatAIn, modesIn);
end annotateFlatAutomaton;

protected function addSMSemantics "
Author: BTH
Add semantic equations governing a flat automaton"
  input FlatAutomaton flatAIn;
  input ModeTable modesIn;
  output FlatAutomaton flatAOut;
protected
  list<String> s1,s2;
  Integer i, nStates, nTransitions;
  Transition t1;
  DAE.Exp exp, rhs, expCond, expThen, expElse, exp1, exp2, expIf;
  list<DAE.Exp> expLst;
  Option<DAE.Exp> bindExp;
  BackendDAE.EquationAttributes bindingKind;
  DAE.Type tArrayInteger, tArrayBool;

  DAE.ComponentRef preRef, cref, nStatesRef, activeRef, resetRef, selectedStateRef, selectedResetRef, firedRef, activeStateRef, activeResetRef, nextStateRef, nextResetRef, stateMachineInFinalStateRef;
  BackendDAE.Var var, nStatesVar, activeVar, resetVar, selectedStateVar, selectedResetVar, firedVar, activeStateVar, activeResetVar, nextStateVar, nextResetVar, stateMachineInFinalStateVar;

  BackendDAE.Var defaultIntVar, defaultBoolVar;
  // Modeling Transitions "t":
  array<DAE.ComponentRef> tFromRefs, tToRefs, tImmediateRefs, tResetRefs, tSynchronizeRefs, tPriorityRefs, activeResetStatesRefs, nextResetStatesRefs, finalStatesRefs;
  array<BackendDAE.Var> tFromVars, tToVars, tImmediateVars, tResetVars, tSynchronizeVars, tPriorityVars, activeResetStatesVars, nextResetStatesVars, finalStatesVars;
  // // Modeling Conditions "c":
  array<DAE.ComponentRef> cRefs, cImmediateRefs;
  array<BackendDAE.Var> cVars, cImmediateVars;

  BackendDAE.Equation selectedStateEqn, selectedResetEqn, firedEqn, activeStateEqn, activeResetEqn, nextStateEqn, nextResetEqn;

  // FLAT_AUTOMATON
  DAE.ComponentRef initialState;
  array<DAE.ComponentRef> states;
  SMSemantics sms;
  // SMS
  list<DAE.ComponentRef> q "States";
  list<Transition> t;
  list<DAE.Exp> cExps;
  list<BackendDAE.Var> vars;
  list<BackendDAE.Var> knowns;
  list<BackendDAE.Equation> eqs;
  // TRANSITION
  Integer from;
  Integer to;
  Boolean immediate;
  Boolean reset;
  Boolean synchronize;
  Integer priority;
algorithm

  FLAT_AUTOMATON(initialState, states, sms) := flatAIn;
  q := arrayList(states);

  // make sure that created vars won't clutter up the variable space
  preRef := ComponentReference.crefPrefixString(SMS_PRE, initialState);

  (t, cExps) := createTandC(q, modesIn);
  //s1 := List.map(t, dumpTransitionStr);
  //print("==TRANSITIONS:===\n"+ stringDelimitList(s1, "\n"));
  //print("\n==CONDITIONS:===\n");
  //List.map_0(c,ExpressionDump.dumpExp);

  defaultIntVar := createVarWithDefaults(ComponentReference.makeDummyCref(), BackendDAE.DISCRETE(), DAE.T_INTEGER_DEFAULT);
  defaultBoolVar := createVarWithDefaults(ComponentReference.makeDummyCref(), BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);
  knowns := {};
  vars := {};
  // ***** Create new variable declarations needed for semantic equations *****
  nStates := listLength(q);
  nStatesRef := qCref("nState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  nStatesVar := createVarWithDefaults(nStatesRef, BackendDAE.PARAM(), DAE.T_INTEGER_DEFAULT);
  //nStatesVar := BackendVariable.setBindValue(nStatesVar, SOME(Values.INTEGER(nStates)));
  nStatesVar := BackendVariable.setBindExp(nStatesVar, SOME(DAE.ICONST(nStates)));
  knowns := nStatesVar :: knowns;


  // parameter Transition t[:] "Array of transition data sorted in priority";
  nTransitions := listLength(t);
  tArrayInteger := DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(nTransitions)}, DAE.emptyTypeSource);
  tArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_INTEGER(nTransitions)}, DAE.emptyTypeSource);
  tFromRefs := arrayCreate(nTransitions, ComponentReference.makeDummyCref());
  tToRefs := arrayCreate(nTransitions, ComponentReference.makeDummyCref());
  tImmediateRefs := arrayCreate(nTransitions, ComponentReference.makeDummyCref());
  tResetRefs := arrayCreate(nTransitions, ComponentReference.makeDummyCref());
  tSynchronizeRefs := arrayCreate(nTransitions, ComponentReference.makeDummyCref());
  tPriorityRefs := arrayCreate(nTransitions, ComponentReference.makeDummyCref());
  tFromVars := arrayCreate(nTransitions, defaultIntVar);
  tToVars := arrayCreate(nTransitions, defaultIntVar);
  tImmediateVars := arrayCreate(nTransitions, defaultBoolVar);
  tResetVars := arrayCreate(nTransitions, defaultBoolVar);
  tSynchronizeVars := arrayCreate(nTransitions, defaultBoolVar);
  tPriorityVars := arrayCreate(nTransitions, defaultIntVar);
  i := 0;
  for t1 in t loop
    i := i+1;
    TRANSITION(from,to,immediate,reset,synchronize,priority) := t1;
    tFromRefs := arrayUpdate(tFromRefs, i, qCref("tFrom", tArrayInteger, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tFromVars := arrayUpdate(tFromVars, i, createVarWithDefaults(arrayGet(tFromRefs,i), BackendDAE.PARAM(), DAE.T_INTEGER_DEFAULT));
    tFromVars := arrayUpdate(tFromVars, i, BackendVariable.setBindExp(arrayGet(tFromVars,i), SOME(DAE.ICONST(from))));
    knowns := arrayGet(tFromVars,i) :: knowns;

    tToRefs := arrayUpdate(tToRefs, i, qCref("tTo", tArrayInteger, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tToVars := arrayUpdate(tToVars, i, createVarWithDefaults(arrayGet(tToRefs,i), BackendDAE.PARAM(), DAE.T_INTEGER_DEFAULT));
    tToVars := arrayUpdate(tToVars, i, BackendVariable.setBindExp(arrayGet(tToVars,i), SOME(DAE.ICONST(to))));
    knowns := arrayGet(tToVars,i) :: knowns;

    tImmediateRefs := arrayUpdate(tImmediateRefs, i, qCref("tImmediate", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tImmediateVars := arrayUpdate(tImmediateVars, i, createVarWithDefaults(arrayGet(tImmediateRefs,i), BackendDAE.PARAM(), DAE.T_BOOL_DEFAULT));
    tImmediateVars := arrayUpdate(tImmediateVars, i, BackendVariable.setBindExp(arrayGet(tImmediateVars,i), SOME(DAE.BCONST(immediate))));
    knowns := arrayGet(tImmediateVars,i) :: knowns;

    tResetRefs := arrayUpdate(tResetRefs, i, qCref("tReset", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tResetVars := arrayUpdate(tResetVars, i, createVarWithDefaults(arrayGet(tResetRefs,i), BackendDAE.PARAM(), DAE.T_BOOL_DEFAULT));
    tResetVars := arrayUpdate(tResetVars, i, BackendVariable.setBindExp(arrayGet(tResetVars,i), SOME(DAE.BCONST(reset))));
    knowns := arrayGet(tResetVars,i) :: knowns;

    tSynchronizeRefs := arrayUpdate(tSynchronizeRefs, i, qCref("tSynchronize", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tSynchronizeVars := arrayUpdate(tSynchronizeVars, i, createVarWithDefaults(arrayGet(tSynchronizeRefs,i), BackendDAE.PARAM(), DAE.T_BOOL_DEFAULT));
    tSynchronizeVars := arrayUpdate(tSynchronizeVars, i, BackendVariable.setBindExp(arrayGet(tSynchronizeVars,i), SOME(DAE.BCONST(synchronize))));
    knowns := arrayGet(tSynchronizeVars,i) :: knowns;

    tPriorityRefs := arrayUpdate(tPriorityRefs, i, qCref("tPriority", tArrayInteger, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tPriorityVars := arrayUpdate(tPriorityVars, i, createVarWithDefaults(arrayGet(tPriorityRefs,i), BackendDAE.PARAM(), DAE.T_INTEGER_DEFAULT));
    tPriorityVars := arrayUpdate(tPriorityVars, i, BackendVariable.setBindExp(arrayGet(tPriorityVars,i), SOME(DAE.ICONST(priority))));
    knowns := arrayGet(tPriorityVars,i) :: knowns;
  end for;
  //input Boolean c[size(t,1)] "Transition conditions sorted in priority";
  //input Boolean cImmediate[size(t,1)];
  /* IMPLEMENTATION NOTE in respect to MLS: cImmediate is introduced in order to delay transitions by simply doing c[i] = previous(cImmediate[i]) for delayed transitons.
     Now, all c[i] can be treated as immediate transitions. Hence, different to MLS 17.3.4 there are no distinguished equations for 'immediate' or 'delayed' transitions needed.
     This avoids seemingly algebraic dependency loops for delayed transitions that are introduced if MLS 17.3.4 equations are implemented directly
     (this is because in MLS 17.3.4 delayed transitions c[i] appear in a non-delayed form in the equation for 'immediate';
     actually, MLS 17.3.4 doesn't introduce 'real' algebraic loops for delayed transitions since if-conditions "exclude" the paths that would lead to algebraic loops during execution;
     however, it requires sophisticated analysis for a tool to statically deduce that fact)
  */
  cRefs := arrayCreate(nTransitions, ComponentReference.makeDummyCref());
  cImmediateRefs := arrayCreate(nTransitions, ComponentReference.makeDummyCref());
  cVars := arrayCreate(nTransitions, defaultBoolVar);
  cImmediateVars := arrayCreate(nTransitions, defaultBoolVar);
  i := 0;
  for exp in cExps loop
    i := i+1;
    cRefs := arrayUpdate(cRefs, i, qCref("c", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    cImmediateRefs := arrayUpdate(cImmediateRefs, i, qCref("cImmediate", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    cVars := arrayUpdate(cVars, i, createVarWithDefaults(arrayGet(cRefs,i), BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT));
    cImmediateVars := arrayUpdate(cImmediateVars, i, createVarWithDefaults(arrayGet(cImmediateRefs,i), BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT));
    // TODO Binding probably needs to be turned into a proper equation. Done below
    // cVars := arrayUpdate(cVars, i, BackendVariable.setBindExp(arrayGet(cVars,i), SOME(exp)));
    vars := arrayGet(cVars, i) :: vars;
    vars := arrayGet(cImmediateVars, i) :: vars;
  end for;
  //input Boolean active "true if the state machine is active";
  activeRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, preRef);
  activeVar := createVarWithDefaults(activeRef, BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);
  vars := activeVar :: vars;
  //input Boolean reset "true when the state machine should be reset";
  resetRef := qCref("reset", DAE.T_BOOL_DEFAULT, {}, preRef);
  resetVar := createVarWithDefaults(resetRef, BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);
  vars := resetVar :: vars;
  //Integer selectedState
  selectedStateRef := qCref("selectedState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  selectedStateVar := createVarWithDefaults(selectedStateRef, BackendDAE.DISCRETE(), DAE.T_INTEGER_DEFAULT);
  vars := selectedStateVar :: vars;
  //Boolean selectedReset
  selectedResetRef := qCref("selectedReset", DAE.T_BOOL_DEFAULT, {}, preRef);
  selectedResetVar := createVarWithDefaults(selectedResetRef, BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);
  vars := selectedResetVar :: vars;
  // Integer fired
  firedRef := qCref("fired", DAE.T_INTEGER_DEFAULT, {}, preRef);
  firedVar := createVarWithDefaults(firedRef, BackendDAE.DISCRETE(), DAE.T_INTEGER_DEFAULT);
  vars := firedVar :: vars;
  // output Integer activeState
  activeStateRef := qCref("activeState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  activeStateVar := createVarWithDefaults(activeStateRef, BackendDAE.DISCRETE(), DAE.T_INTEGER_DEFAULT);
  vars := activeStateVar :: vars;
  // output Boolean activeReset
  activeResetRef := qCref("activeReset", DAE.T_BOOL_DEFAULT, {}, preRef);
  activeResetVar := createVarWithDefaults(activeResetRef, BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);
  vars := activeResetVar :: vars;
  // Integer nextState
  nextStateRef := qCref("nextState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  nextStateVar := createVarWithDefaults(nextStateRef, BackendDAE.DISCRETE(), DAE.T_INTEGER_DEFAULT);
  vars := nextStateVar :: vars;
  // Boolean nextReset
  nextResetRef := qCref("nextReset", DAE.T_BOOL_DEFAULT, {}, preRef);
  nextResetVar := createVarWithDefaults(nextResetRef, BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);
  vars := nextResetVar :: vars;
  //output Boolean activeResetStates[nStates]
  activeResetStatesRefs := arrayCreate(nStates, ComponentReference.makeDummyCref());
  activeResetStatesVars := arrayCreate(nStates, defaultBoolVar);
  for i in 1:nStates loop
    activeResetStatesRefs := arrayUpdate(activeResetStatesRefs, i, qCref("activeResetStates", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    activeResetStatesVars := arrayUpdate(activeResetStatesVars, i, createVarWithDefaults(arrayGet(activeResetStatesRefs,i), BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT));
    vars := arrayGet(activeResetStatesVars, i) :: vars;
  end for;
  // Boolean nextResetStates[nStates]
  nextResetStatesRefs := arrayCreate(nStates, ComponentReference.makeDummyCref());
  nextResetStatesVars := arrayCreate(nStates, defaultBoolVar);
  for i in 1:nStates loop
    nextResetStatesRefs := arrayUpdate(nextResetStatesRefs, i, qCref("nextResetStates", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    nextResetStatesVars := arrayUpdate(nextResetStatesVars, i, createVarWithDefaults(arrayGet(nextResetStatesRefs,i), BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT));
    vars := arrayGet(nextResetStatesVars, i) :: vars;
  end for;
  // Boolean finalStates[nStates]
  finalStatesRefs := arrayCreate(nStates, ComponentReference.makeDummyCref());
  finalStatesVars := arrayCreate(nStates, defaultBoolVar);
  for i in 1:nStates loop
    finalStatesRefs := arrayUpdate(finalStatesRefs, i, qCref("finalStates", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    finalStatesVars := arrayUpdate(finalStatesVars, i, createVarWithDefaults(arrayGet(finalStatesRefs,i), BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT));
    vars := arrayGet(finalStatesVars, i) :: vars;
  end for;
  // Boolean stateMachineInFinalState
  stateMachineInFinalStateRef := qCref("stateMachineInFinalState", DAE.T_BOOL_DEFAULT, {}, preRef);
  stateMachineInFinalStateVar := createVarWithDefaults(stateMachineInFinalStateRef, BackendDAE.DISCRETE(), DAE.T_BOOL_DEFAULT);
  vars := stateMachineInFinalStateVar :: vars;

  // ***** Create new governing equations *****
  eqs := {};
  bindingKind := BackendDAE.EQ_ATTR_DEFAULT_BINDING;

  //input Boolean c[size(t,1)] "Transition conditions sorted in priority";
  // Delayed transitions are realized by "c[i] = previous(cImmediate[i])"
  i := 0;
  for cExp in cExps loop
    i := i+1;
    exp := DAE.CREF(arrayGet(cImmediateRefs,i), DAE.T_BOOL_DEFAULT);
    eqs := BackendDAE.EQUATION(exp, cExp, DAE.emptyElementSource, bindingKind) :: eqs;
    exp1 := DAE.CREF(arrayGet(cRefs,i), DAE.T_BOOL_DEFAULT);
    BackendDAE.VAR(bindExp=bindExp) := arrayGet(tImmediateVars,i);
    // Check whether it is an immediate or an delayed transition
    rhs := if Util.applyOptionOrDefault(bindExp, function Expression.expEqual(inExp1=DAE.BCONST(true)), false) then
      // immediate transition
      exp else
      // delayed transition
      DAE.CALL(Absyn.IDENT("previous"), {exp}, DAE.callAttrBuiltinImpureBool);
    eqs := BackendDAE.EQUATION(exp1, rhs, DAE.emptyElementSource, bindingKind) :: eqs;
  end for;

  // Integer selectedState = if reset then 1 else previous(nextState);
  exp := DAE.CREF(selectedStateRef, DAE.T_INTEGER_DEFAULT);
  expCond := DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.ICONST(1);
  expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(nextStateRef, DAE.T_INTEGER_DEFAULT)}, DAE.callAttrBuiltinImpureInteger);
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  selectedStateEqn := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind);
  eqs := selectedStateEqn :: eqs;

  // Boolean selectedReset = if reset then true else previous(nextReset);
  exp := DAE.CREF(selectedResetRef, DAE.T_BOOL_DEFAULT);
  expCond := DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.BCONST(true);
  expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(nextResetRef, DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  selectedResetEqn := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind);
  eqs := selectedResetEqn :: eqs;

  /*  Following semantic activation equations are specified in MLS 17.3.4:
        Integer delayed= max(if (if not t[i].immediate and t[i].from == nextState then c[i] else false) then i else 0 for i in 1:size(t,1));
        Integer immediate = max(if (if t[i].immediate and t[i].from == selectedState then c[i] else false) then i else 0 for i in 1:size(t,1));
        Integer fired = max(previous(delayed), immediate);
      This implementation doesn't implement them directly.
      Recall that delayed transitions have been previously modeled as c[i] = previous(cImmediate[i]), so that the firing conditions is simplified to:
        Integer fired = max(if (if t[i].from == selectedState then c[i] else false) then i else 0 for i in 1: size(t ,1)); */
  exp := DAE.CREF(firedRef, DAE.T_INTEGER_DEFAULT);
  expLst := {};
  for i in 1:nTransitions loop
    // t[i].from == selectedState:
    expCond := DAE.RELATION(DAE.CREF(arrayGet(tFromRefs,i), DAE.T_INTEGER_DEFAULT), DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.CREF(selectedStateRef, DAE.T_INTEGER_DEFAULT),-1, NONE());
    expThen := DAE.CREF(arrayGet(cRefs,i), DAE.T_BOOL_DEFAULT);
    expElse := DAE.BCONST(false);
    // if (t[i].from == selectedState) then (c[i]) else (false)
    expIf := DAE.IFEXP(expCond, expThen, expElse);
    // if (if t[i].from == selectedState then c[i] else false) then i else 0
    expLst := DAE.IFEXP(expIf, DAE.ICONST(i), DAE.ICONST(0)) :: expLst;
  end for;
  rhs := DAE.CALL(Absyn.IDENT("max"), expLst, DAE.callAttrBuiltinInteger);
  firedEqn := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind);
  eqs := firedEqn :: eqs;

  // output Integer activeState = if reset then 1 elseif fired > 0 then t[fired].to else selectedState;
  exp := DAE.CREF(activeStateRef, DAE.T_INTEGER_DEFAULT);
  expCond := DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.ICONST(1);
  // fired > 0:
  exp1 := DAE.RELATION(DAE.CREF(firedRef, DAE.T_INTEGER_DEFAULT), DAE.GREATER(DAE.T_INTEGER_DEFAULT), DAE.ICONST(0), -1, NONE());
  // t[fired].to:
  exp2 := DAE.CREF(qCref("tTo", tArrayInteger, {DAE.INDEX(DAE.CREF(firedRef,DAE.T_INTEGER_DEFAULT))}, preRef), DAE.T_INTEGER_DEFAULT);
  // elsif fired > 0 then t[fired].to else selectedState:
  expElse := DAE.IFEXP(exp1, exp2, DAE.CREF(selectedStateRef, DAE.T_INTEGER_DEFAULT));
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  activeStateEqn := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind);
  eqs := activeStateEqn :: eqs;

  // output Boolean activeReset = if reset then true elseif fired > 0 then t[fired].reset else selectedReset;
  exp := DAE.CREF(activeResetRef, DAE.T_BOOL_DEFAULT);
  expCond := DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.BCONST(true);
  // fired > 0:
  exp1 := DAE.RELATION(DAE.CREF(firedRef, DAE.T_INTEGER_DEFAULT), DAE.GREATER(DAE.T_INTEGER_DEFAULT), DAE.ICONST(0), -1, NONE());
  // t[fired].reset:
  exp2 := DAE.CREF(qCref("tReset", tArrayBool, {DAE.INDEX(DAE.CREF(firedRef,DAE.T_INTEGER_DEFAULT))}, preRef), DAE.T_INTEGER_DEFAULT);
  // elseif fired > 0 then t[fired].reset else selectedReset:
  expElse := DAE.IFEXP(exp1, exp2, DAE.CREF(selectedResetRef, DAE.T_BOOL_DEFAULT));
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  activeResetEqn := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind);
  eqs := activeResetEqn :: eqs;

  // Integer nextState = if active then activeState else previous(nextState);
  exp := DAE.CREF(nextStateRef, DAE.T_INTEGER_DEFAULT);
  expCond := DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.CREF(activeStateRef, DAE.T_INTEGER_DEFAULT);
  expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(nextStateRef, DAE.T_INTEGER_DEFAULT)}, DAE.callAttrBuiltinImpureInteger);
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  nextStateEqn := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind);
  eqs := nextStateEqn :: eqs;

  // Boolean nextReset = if active then false else previous(nextReset);
  exp := DAE.CREF(nextResetRef, DAE.T_BOOL_DEFAULT);
  expCond := DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.BCONST(false);
  expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(nextResetRef, DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  nextResetEqn := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind);
  eqs := nextResetEqn :: eqs;

  // output Boolean activeResetStates[nStates] = {if reset then true else previous(nextResetStates[i]) for i in 1:nStates};
  for i in 1:nStates loop
    exp := DAE.CREF(arrayGet(activeResetStatesRefs,i), DAE.T_BOOL_DEFAULT);
    expCond := DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT);
    expThen := DAE.BCONST(true);
    expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(arrayGet(nextResetStatesRefs,i), DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
    rhs := DAE.IFEXP(expCond, expThen, expElse);
    eqs := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind) :: eqs;
  end for;

  // Boolean nextResetStates[nStates] = if active then {if selectedState == i then false else activeResetStates[i] for i in 1:nStates} else previous(nextResetStates);
  for i in 1:nStates loop
    exp := DAE.CREF(arrayGet(nextResetStatesRefs,i), DAE.T_BOOL_DEFAULT);
    expCond := DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT);
    // selectedState == i:
    exp1 := DAE.RELATION(DAE.CREF(selectedStateRef, DAE.T_INTEGER_DEFAULT), DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(i),-1, NONE());
    /*===== specification semantics (probably wrong!): ===== */
    // if (selectedState == i) then false else activeResetStates[i]
    expThen := DAE.IFEXP(exp1, DAE.BCONST(false), DAE.CREF(arrayGet(activeResetStatesRefs,i), DAE.T_BOOL_DEFAULT));
    /*===== ??FIXED?? semantics: ===== */
    // if (selectedState == i) then false else activeReset
    //expThen := DAE.IFEXP(exp1, DAE.BCONST(false), DAE.CREF(activeResetRef, DAE.T_BOOL_DEFAULT));

    // previous(nextResetStates[i])
    expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(arrayGet(nextResetStatesRefs,i), DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
    // if active then (if selectedState == i then false else activeResetStates[i]) else previous(nextResetStates[i])
    rhs := DAE.IFEXP(expCond, expThen, expElse);
    // Ignore:
    //rhs := DAE.LUNARY(DAE.NOT(DAE.T_BOOL_DEFAULT), DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(arrayGet(nextResetStatesRefs,i), DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool));
    eqs := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind) :: eqs;
  end for;

  // Boolean finalStates[nStates] = {max(if t[j].from == i then 1 else 0 for j in 1:size(t,1)) == 0 for i in 1:nStates};
  for i in 1:nStates loop
    exp := DAE.CREF(arrayGet(finalStatesRefs,i), DAE.T_BOOL_DEFAULT);
    expLst := {};
    for j in 1:nTransitions loop
      // t[j].from == i:
      expCond := DAE.RELATION(DAE.CREF(arrayGet(tFromRefs,j), DAE.T_INTEGER_DEFAULT), DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(i),-1, NONE());
      // if t[j].from == i then 1 else 0:
      expLst := DAE.IFEXP(expCond, DAE.ICONST(1), DAE.ICONST(0)) :: expLst;
    end for;
    // max(if t[j].from == i then 1 else 0 for j in 1:size(t,1))
    exp1 := DAE.CALL(Absyn.IDENT("max"), expLst, DAE.callAttrBuiltinInteger);
    // max(if t[j].from == i then 1 else 0 for j in 1:size(t,1)) == 0
    rhs := DAE.RELATION(exp1, DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(0),-1, NONE());
    eqs := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind) :: eqs;
  end for;

  // Boolean stateMachineInFinalState = finalStates[activeState];
  exp := DAE.CREF(stateMachineInFinalStateRef, DAE.T_BOOL_DEFAULT);
  rhs := DAE.CREF(qCref("finalStates", tArrayBool, {DAE.INDEX(DAE.CREF(activeStateRef,DAE.T_INTEGER_DEFAULT))}, preRef), DAE.T_BOOL_DEFAULT);
  eqs := BackendDAE.EQUATION(exp, rhs, DAE.emptyElementSource, bindingKind) :: eqs;

  flatAOut := FLAT_AUTOMATON(initialState, states, SMS(q, t, cExps, vars, knowns, eqs));
end addSMSemantics;

protected function qCref "
Author: BTH
Helper function to addSMSemantics"
  input DAE.Ident ident;
  input DAE.Type identType "type of the identifier, without considering the subscripts";
  input list<DAE.Subscript> subscriptLst;
  input DAE.ComponentRef componentRef;
  output DAE.ComponentRef outQual;
algorithm
  outQual := ComponentReference.joinCrefs(componentRef,DAE.CREF_IDENT(ident,identType,subscriptLst));
end qCref;


public function dumpTransitionStr "
Author: BTH
Dump transition to string."
  input Transition transition;
  output String transitionStr;
protected
  Integer from;
  Integer to;
  Boolean immediate;
  Boolean reset;
  Boolean synchronize;
  Integer priority;
algorithm
  TRANSITION(from, to, immediate, reset, synchronize, priority) := transition;
  transitionStr := "TRANSITION(from="+intString(from)+", to="+intString(to)+
    ", immediate="+boolString(immediate)+", reset+"+boolString(reset)+
    ", synchronize="+boolString(synchronize)+", priority="+intString(priority)+")";
end dumpTransitionStr;

protected function createTandC "
Author: BTH"
  input list<DAE.ComponentRef> q;
  input ModeTable modes;
  output list<Transition> t;
  output list<DAE.Exp> c;
protected
  DAE.ComponentRef cref, cFrom, cTo;
  Boolean bImmediate, bReset, bSynchronize;
  Integer iPriority, iFrom, iTo;
  BackendDAE.EquationArray outgoing "outgoing transitions";
  list<BackendDAE.Equation> eqsLst;
  BackendDAE.Equation eqs;
  Mode mode;
  DAE.Exp from, to, condition, immediate, reset, synchronize, priority;
  list<tuple<Transition, DAE.Exp>> tc, tcSorted;
algorithm
  tc := {};
  for cref in q loop
    mode := BaseHashTable.get(cref, modes);
    MODE(outgoing=outgoing) := mode;
    eqsLst := BackendEquation.equationList(outgoing);

    for eqs in eqsLst loop
      BackendDAE.ALGORITHM(alg = DAE.ALGORITHM_STMTS(
        statementLst = {
          DAE.STMT_NORETCALL(
            exp = DAE.CALL(
              path = Absyn.IDENT(name = "transition"),
              expLst = {from, to, condition, immediate, reset, synchronize, priority}
            )
          )
        }
      )) := eqs;
      DAE.CREF(componentRef=cFrom) := from;
      DAE.CREF(componentRef=cTo) := to;
      DAE.BCONST(bool=bImmediate) := immediate;
      DAE.BCONST(bool=bReset) := reset;
      DAE.BCONST(bool=bSynchronize) := synchronize;
      DAE.ICONST(integer=iPriority) := priority;
      iFrom := List.position(cFrom, q);
      iTo := List.position(cTo, q);
      tc := (TRANSITION(iFrom, iTo, bImmediate, bReset, bSynchronize, iPriority), condition) :: tc;
    end for;
  end for;
  tcSorted := List.sort(tc, priorityLt);
  (t, c) := List.unzip(tcSorted);
end createTandC;

protected function priorityLt "
Author: BTH
Helper function to sort transitions and corresponding transition condition according to the priority of the transition."
  input tuple<Transition, DAE.Exp> in1;
  input tuple<Transition, DAE.Exp> in2;
  output Boolean inRes;
protected
  Integer priority1, priority2;
algorithm
  (TRANSITION(priority=priority1),_) := in1;
  (TRANSITION(priority=priority2),_) := in2;
  inRes := intLt(priority1, priority2);
end priorityLt;


protected function createVarWithDefaults "
Author: BTH
Create a BackendDAE.Var with some defaults"
  input DAE.ComponentRef cref;
  input BackendDAE.VarKind varKind;
  input BackendDAE.Type varType;
  output BackendDAE.Var var;
algorithm
  var := BackendDAE.VAR(cref, varKind, DAE.BIDIR(), DAE.NON_PARALLEL(), varType, NONE(), NONE(), {},
    DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(),false);
end createVarWithDefaults;

public function emptySMS "
Author: BTH
Create empty SMS record."
  output SMSemantics sms;
algorithm
  sms := SMS({},{},{},{},{},{});
end emptySMS;

protected function annotateModes "
Author: BTH
Collect mode relevant information, e.g., equations declared in that mode."
  input ModeTable modesIn;
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output ModeTable modesOut;
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.EquationArray orderedEqsNew, removedEqsNew;
  array<Option<BackendDAE.Var>> varOptArr;
  // Fields EQSYSTEM:
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  // Fields SHARED:
  BackendDAE.EquationArray removedEqs;
  // Fields of EQUATION_ARRAY
  Integer orderedSize, removedSize;
  Integer orderedNumberOfElement, removedNumberOfElement;
  Integer orderedArrSize, removedArrSize;
  array<Option<BackendDAE.Equation>> orderedEquOptArr, removedEquOptArr;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, removedEqs=removedEqs) := inSyst;

  BackendDAE.EQUATION_ARRAY(orderedSize, orderedNumberOfElement, orderedArrSize, orderedEquOptArr) := orderedEqs;
  BackendDAE.EQUATION_ARRAY(removedSize, removedNumberOfElement, removedArrSize, removedEquOptArr) := removedEqs;
  (orderedEquOptArr, modesOut) := Array.mapNoCopy_1(orderedEquOptArr, annotateMode, modesIn);
  (removedEquOptArr, modesOut) := Array.mapNoCopy_1(removedEquOptArr, annotateMode, modesOut);

  // New equation arrays (equations assigned to modes are replaced by NONE())
  orderedSize := Array.fold(orderedEquOptArr, incIfSome, 0); // FIXME: Correct to assume that any non-NONE equation has to be counted?
  orderedNumberOfElement := orderedSize; // FIXME: Correct to assume that orderedNumberOfElement = orderedSize?
  orderedEqsNew := BackendDAE.EQUATION_ARRAY(orderedSize, orderedNumberOfElement, orderedArrSize, orderedEquOptArr);
  removedEqsNew := BackendDAE.EQUATION_ARRAY(removedSize, removedNumberOfElement, removedArrSize, removedEquOptArr);

  BackendDAE.VARIABLES(varArr=BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr)) := orderedVars;
  // add outer output variables to modes that declared them
  (_, modesOut) := Array.mapNoCopy_1(varOptArr, annotateModeOutShared, modesOut);
  // add output variables and (non-input) local variables to modes that declared them
  (_, modesOut) := Array.mapNoCopy_1(varOptArr, annotateModeOutLocal, modesOut);

  outSyst := inSyst;
  outShared := inShared;

end annotateModes;

protected function incIfSome
  input Option<BackendDAE.Equation> optEq;
  input Integer seed;
  output Integer yield;
algorithm
  yield := seed + (if isSome(optEq) then 1 else 0);
end incIfSome;

protected function annotateModeOutLocal "
Author: BTH
Collect output variables and (non-input) local variables."
  input tuple<Option<BackendDAE.Var>, ModeTable> inVarModeTable;
  output tuple<Option<BackendDAE.Var>, ModeTable> outVarModeTable;
protected
  BackendDAE.Var var;
  ModeTable mt;
  Mode mode;
  DAE.ComponentRef cref;
  DAE.ElementSource source "origin of variable";
  Prefix.ComponentPrefix instance;
algorithm
  try
    (SOME(var), mt) := inVarModeTable;

    // Check that we are neither having an "outer output" nor an "input"
    _ := match var
      case BackendDAE.VAR(varDirection=DAE.OUTPUT(), innerOuter = DAE.OUTER()) then fail();
      case BackendDAE.VAR(varDirection=DAE.INPUT()) then fail();
      else ();
    end match;

    BackendDAE.VAR(source=source) := var;
    DAE.SOURCE(instance=instance) := source;
    cref := PrefixUtil.prefixToCref(Prefix.PREFIX(instance,Prefix.CLASSPRE(SCode.PARAM())));
    mode := BaseHashTable.get(cref, mt);
    mode := match mode
      case MODE()
        equation
          mode.outLocal = var :: mode.outLocal;
      then mode;
    end match;
    BaseHashTable.update((cref, mode), mt);
    outVarModeTable := (SOME(var), mt);
  else
    outVarModeTable := inVarModeTable;
  end try;
end annotateModeOutLocal;



protected function annotateModeOutShared "
Author: BTH
Collect outer output variables in the mode/state to that they correspond."
  input tuple<Option<BackendDAE.Var>, ModeTable> inVarModeTable;
  output tuple<Option<BackendDAE.Var>, ModeTable> outVarModeTable;
protected
  BackendDAE.Var var;
  ModeTable mt;
  Mode mode;
  DAE.ComponentRef cref;
  // BackendDAE.Var
  DAE.ComponentRef varName "variable name";
  BackendDAE.VarKind varKind "Kind of variable";
  DAE.VarDirection varDirection "input, output or bidirectional";
  DAE.VarParallelism varParallelism "parallelism of the variable. parglobal, parlocal or non-parallel";
  BackendDAE.Type varType "built-in type or enumeration";
  Option<DAE.Exp> bindExp "Binding expression e.g. for parameters";
  Option<Values.Value> bindValue "binding value for parameters";
  DAE.InstDims arryDim "array dimensions of non-expanded var";
  DAE.ElementSource source "origin of variable";
  Option<DAE.VariableAttributes> values "values on built-in attributes";
  Option<BackendDAE.TearingSelect> tearingSelectOption "value for TearingSelect";
  Option<SCode.Comment> comment "this contains the comment and annotation from Absyn";
  DAE.ConnectorType connectorType "flow, stream, unspecified or not connector.";
  DAE.VarInnerOuter io;
  Prefix.ComponentPrefix instance;
algorithm
  try
    (SOME(var), mt) := inVarModeTable;
    BackendDAE.VAR(varName, varKind, DAE.OUTPUT(), varParallelism, varType, bindExp,
      bindValue, arryDim, source, values, tearingSelectOption, comment, connectorType, DAE.OUTER()) := var;

    DAE.SOURCE(instance=instance as Prefix.PRE()) := source;
    cref := PrefixUtil.prefixToCref(Prefix.PREFIX(instance,Prefix.CLASSPRE(SCode.PARAM())));
    mode := BaseHashTable.get(cref, mt);
    mode := match mode
      case MODE()
        equation
          mode.outShared = var :: mode.outShared;
      then mode;
    end match;
    BaseHashTable.update((cref, mode), mt);
    outVarModeTable := (SOME(var), mt);
  else
    outVarModeTable := inVarModeTable;
  end try;
end annotateModeOutShared;

protected function annotateMode "
Author: BTH
Helper function to annotateModes
- Move equation to corresponding mode
  - Collect variables 'x' that appear as 'previous(x)' in field 'crefPrevious'
- Remove initialState(..) statement
- Move transition statements to the mode there it is the outgoing transition (field outgoing)
"
  input tuple<Option<BackendDAE.Equation>, ModeTable> inEqModeTable;
  output tuple<Option<BackendDAE.Equation>, ModeTable> outEqModeTable;
protected
  Option<BackendDAE.Equation> eqOpt;
  ModeTable modeTable;
  Option<DAE.ElementSource> sourceOpt "origin of equation";
  Prefix.ComponentPrefix instance;
  Option<DAE.ComponentRef> instanceOpt "the instance(s) this element is part of";
  Option<tuple<DAE.ComponentRef,TransitionType>> transitionOpt "transition statement";
  Option<Mode> optMode;
algorithm
  (eqOpt, modeTable) := inEqModeTable;

  // Match any possible Equation type and extract the source field.
  sourceOpt := match (eqOpt)
    local
      DAE.ElementSource source1;
    case SOME((BackendDAE.EQUATION(source=source1))) then SOME(source1);
    case SOME((BackendDAE.ARRAY_EQUATION(source=source1))) then SOME(source1);
    case SOME((BackendDAE.SOLVED_EQUATION(source=source1))) then SOME(source1);
    case SOME((BackendDAE.RESIDUAL_EQUATION(source=source1))) then SOME(source1);
    case SOME((BackendDAE.ALGORITHM(source=source1))) then SOME(source1);
    case SOME((BackendDAE.WHEN_EQUATION(source=source1))) then SOME(source1);
    case SOME((BackendDAE.COMPLEX_EQUATION(source=source1))) then SOME(source1);
    case SOME((BackendDAE.IF_EQUATION(source=source1))) then SOME(source1);
    else NONE();
  end match;

  // Check whether equation is a transition(cref, ..) or initialState(cref) statement and extract first argument.
  transitionOpt := match (eqOpt)
    local
      String name;
      list<DAE.Exp> expLst;
      tuple<DAE.ComponentRef,TransitionType> transition;
      DAE.ComponentRef cref;
    case (SOME(
        BackendDAE.ALGORITHM(alg = DAE.ALGORITHM_STMTS(
          statementLst = {
            DAE.STMT_NORETCALL(
              exp = DAE.CALL(
                path = Absyn.IDENT(name = name),
                expLst = DAE.CREF(componentRef=cref)::_
              )
            )
          }
        ))
      )) guard (name == "transition" or name == "initialState")
      equation
        transition = if (name == "transition") then (cref, T_TRANSITION()) else (cref, T_INITIAL_STATE());
      then
        SOME(transition);
    else NONE();
  end match;


  // If we had a transition statement, extract the instance of its first argument,
  // if not, check if source refers to a "parent" instance
  instanceOpt := match (sourceOpt, transitionOpt)
    local
      Option<DAE.ComponentRef> crefOpt;
      DAE.ComponentRef cref;
    case (_, SOME((cref,_))) then SOME(cref);
    case (SOME(DAE.SOURCE(instance=instance)), NONE()) then SOME(PrefixUtil.prefixToCref(Prefix.PREFIX(instance,Prefix.CLASSPRE(SCode.PARAM()))));
    else NONE();
  end match;

  // Is there a mode/state that corresponds to the instance?
  optMode := match (instanceOpt)
    local
      DAE.ComponentRef cref;
    case SOME(cref) guard BaseHashTable.hasKey(cref, modeTable)
      then SOME(BaseHashTable.get(cref, modeTable));
    else NONE();
  end match;

  // Remove equations that correspond to a mode/state from the DAE equation array (replace by NONE())
  // and move them to the corresponding modes
  outEqModeTable := match (optMode, instanceOpt, transitionOpt, eqOpt)
    local
      DAE.ComponentRef cref;
      BackendDAE.Equation eq;
      ModeTable modeTableNew;
      String name;
      Boolean isInitial;
      HashSet.HashSet edges;
      BackendDAE.EquationArray eqs, outgoing;
      list<BackendDAE.Var> os, ol;
      list<DAE.ComponentRef> ps;
      //Option<tuple<DAE.ComponentRef,TransitionType>> transOpt;

    // Move equation to "parent" mode/state instance and
    // search for "x" that occur as "previous(x)" in rhs of equation
    case (SOME(MODE(name,isInitial,edges,eqs,outgoing,os,ol,ps)), SOME(cref), NONE(), SOME(eq))
      equation
        eqs = BackendEquation.addEquation(eq, eqs);
        ps = listAppend(ps, equationsPreviousCrefs({eq}));
        BaseHashTable.update((cref, MODE(name,isInitial,edges,eqs,outgoing,os,ol,ps)), modeTable);
      then (NONE(), modeTable);

    // Move transtion(..) statement to mode/state where it is the outgoing transition
    case (SOME(MODE(name,isInitial,edges,eqs,outgoing,os,ol,ps)), SOME(cref), SOME((_,T_TRANSITION())), SOME(eq))
      equation
        outgoing = BackendEquation.addEquation(eq, outgoing);
        BaseHashTable.update((cref, MODE(name,isInitial,edges,eqs,outgoing,os,ol,ps)), modeTable);
      then (NONE(), modeTable);

    // Remove initialState(..) statement
    case (SOME(MODE()), _, SOME((_,T_INITIAL_STATE())), SOME(_))
      then (NONE(), modeTable);

    // return structures without any modifications
    else (eqOpt, modeTable);
  end match;

end annotateMode;

public function equationsPreviousCrefs "
Author: BTH
From a list of equations return all component references x that occur as previous(x)."
  input list<BackendDAE.Equation> inEquationLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  (_, (_,outExpComponentRefLst)) := BackendEquation.traverseExpsOfEquationList(inEquationLst, Expression.traverseSubexpressionsHelper, (traversingPreviousCRefFinder, {}));
end equationsPreviousCrefs;

public function traversingPreviousCRefFinder "
Author: BTH
Exp traverser that matches on previous(x) and returns a list of a union of all componentRefs x."
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inCrefs;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> crefs;
algorithm
  (outExp,crefs) := match (inExp,inCrefs)
    local
      DAE.ComponentRef cr;
    case (DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(componentRef=cr)}, _), crefs)
      equation
        crefs = List.unionEltOnTrue(cr,crefs,ComponentReference.crefEqual);
      then (inExp,crefs);
    else (inExp,inCrefs);
  end match;
end traversingPreviousCRefFinder;

protected function elaborateMode "
Author: BTH
Replace all outer variables by their corresponding inner variables and remove the outer variables declarations"
  input tuple<DAE.ComponentRef,Mode> inCrefMode;
  input tuple<ModeTable,BackendDAE.EqSystem> inModesSyst;
  output tuple<ModeTable,BackendDAE.EqSystem>  outModesSyst;
protected
  ModeTable modes;
  BackendDAE.EqSystem syst;
  list<DAE.ComponentRef> outLastCrefs, outStrippedCrefs, innerCrefs;
  list<DAE.Exp> rhsExps;
  Option<BackendDAE.Equation> optEqn;
  DAE.ComponentRef outCref, keyCref;
  Option<DAE.ComponentRef> innerOptCref;
  Boolean success, isInnerOuter;
  Mode mode;
  list<BackendDAE.Var> outSharedNew, varLst;
  BackendDAE.Var innerVar;
  // MODE
  String name;
  Boolean isInitial;
  HashSet.HashSet edges "relations to other modes due to in- and out-going transitions";
  BackendDAE.EquationArray eqs "equations defined in the mode instance";
  BackendDAE.EquationArray outgoing "outgoing transitions";
  list<BackendDAE.Var> outShared "outer output variables of state";
  list<BackendDAE.Var> outLocal "output variables and (non-input) local variables of state";
  list<DAE.ComponentRef> crefPrevious "crefs for which a rhs 'previous(cref)' exists in state";
  // EQUATION_ARRAY
  Integer size "size of the Equations in scalar form";
  Integer numberOfElement "no. elements";
  Integer arrSize "array size";
  array<Option<BackendDAE.Equation>> equOptArr;
  DAE.VarInnerOuter io1, io2;
  // EQSYSTEM
  BackendDAE.Variables orderedVars;
algorithm
  (modes,syst) := inModesSyst;
  (keyCref,mode) := inCrefMode;
  MODE(name, isInitial, edges, eqs, outgoing, outShared, outLocal, crefPrevious) := mode;
  BackendDAE.EQUATION_ARRAY(size, numberOfElement, arrSize, equOptArr) := eqs;
  BackendDAE.EQSYSTEM(orderedVars=orderedVars) := syst;
  outSharedNew := {};

  for outVar in outShared loop
    success := false;
    outCref := BackendVariable.varCref(outVar);
    for i in 1:arrayLength(equOptArr) loop
      optEqn := arrayGet(equOptArr,i);

      // Try if this equation relates the "outer" variable to the corresponding "inner" variable
      innerOptCref := getOptInner(optEqn,outCref);

      if isSome(innerOptCref) then
        // Remove the equation relating inner and outer
        arrayUpdate(equOptArr, i, NONE());
        size := size - 1;
        //numberOfElement := numberOfElement - 1;
        eqs := BackendDAE.EQUATION_ARRAY(size, numberOfElement, arrSize, equOptArr);
        // replace all outer crefs by their corresponding inner cref
        (eqs,_) := BackendEquation.traverseEquationArray_WithUpdate(eqs, subsOuterByInnerEq, (outCref,Util.getOption(innerOptCref)));
        // update outSharedNew and use that later to construct MODE
        ({innerVar}, _) := BackendVariable.getVar(Util.getOption(innerOptCref), orderedVars);
        outSharedNew := innerVar :: outSharedNew;
        // replace possible outer crefs in "crefPrevious" by their corresponding inner
        crefPrevious := List.replaceOnTrue( Util.getOption(innerOptCref), crefPrevious,
                                            function ComponentReference.crefEqual(inComponentRef1=outCref) );
        // Remove variable from BackendDAE variables (the corresponding element in the variable array is set to NONE())
        orderedVars := BackendVariable.removeCref(outCref,orderedVars);
        success := true;
        break;
      end if;
    end for;

    assert(success, "Expect to find inner variable corresponding to outer variable " + ComponentReference.crefStr(outCref));
  end for;

  // Rebuild "orderedVars" in order to eliminate intermediate "NONE()" entries in variable array.
  // "BackendVariable.removeCref" only sets the corresponding entry to NONE() which is not sufficient
  // FIXME: This seems to be a rather poor way to do it. Maybe there is a better way to "really" remove a variable.
  varLst := BackendVariable.varList(orderedVars);
  orderedVars := BackendVariable.listVar(varLst);

  mode := MODE(name,isInitial,edges,eqs,outgoing,listReverse(outSharedNew),outLocal,crefPrevious);
  BaseHashTable.update((keyCref, mode), modes);
  syst.orderedVars := orderedVars;
  outModesSyst := (modes,syst);
end elaborateMode;

protected function subsOuterByInnerEq "
Author: BTH
Substitute outer variables in equation by corresponding 'inner'.
Helper function to elaborateMode"
  input BackendDAE.Equation inEq;
  input tuple<DAE.ComponentRef,DAE.ComponentRef> inOuterInner "<outer variable, inner variable>";
  output BackendDAE.Equation outEq;
  output tuple<DAE.ComponentRef,DAE.ComponentRef> outOuterInner;
algorithm
  (outEq,outOuterInner) := BackendEquation.traverseExpsOfEquation(inEq,subsOuterByInnerExp,inOuterInner);
end subsOuterByInnerEq;

protected function subsOuterByInnerExp "
Author: BTH
Substitute outer variables in expression by corresponding 'inner'.
Helper function to subsOuterByInnerEq"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef,DAE.ComponentRef> inOuterInner "<outer variable, inner variable>";
  output DAE.Exp outExp;
  output tuple<DAE.ComponentRef,DAE.ComponentRef> outOuterInner;
algorithm
  (outExp, outOuterInner) := Expression.traverseExpBottomUp(inExp, subsOuterByInner, inOuterInner);
end subsOuterByInnerExp;

protected function subsOuterByInner "
Author: BTH
Helper function to subsOuterByInnerExp"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef,DAE.ComponentRef> inOuterInner "<outer variable, inner variable>";
  output DAE.Exp outExp;
  output tuple<DAE.ComponentRef,DAE.ComponentRef> outOuterInner;
algorithm
  (outExp,outOuterInner) := match (inExp,inOuterInner)
    local
      DAE.ComponentRef outerCref, innerCref;
      DAE.ComponentRef componentRef;
      DAE.Type ty;
    case (DAE.CREF(componentRef,ty),(outerCref,innerCref)) guard ComponentReference.crefEqual(componentRef,outerCref)
      then (DAE.CREF(innerCref,ty),inOuterInner);
    else (inExp,inOuterInner);
  end match;
end subsOuterByInner;


protected function getOptInner "
Author: BTH
Check if equation relates the 'outer' with the corresponding 'inner'
and optionally return the 'inner'
Helper function for elaborateMode"
  input Option<BackendDAE.Equation> inEq;
  input DAE.ComponentRef crefOuter;
  output Option<DAE.ComponentRef> outOptInner;
protected
  Option<DAE.Exp> rhsExp;
  Boolean equal;
algorithm
  rhsExp := Util.applyOption(inEq,BackendEquation.getEquationRHS);
  //print("In getOptInner: rhsExp: "+ (if isSome(rhsExp) then ExpressionDump.printExpStr(Util.getOption(rhsExp)) else "NONE()") + "\n");
  outOptInner := match rhsExp
    local
      DAE.ComponentRef crefInner;
    case SOME(DAE.CREF(componentRef=crefInner)) guard  ComponentReference.crefLastIdentEqual(crefOuter, crefInner)
      then SOME(crefInner);
    else NONE();
  end match;
end getOptInner;


protected function getComposition "
Author: BTH
Infer the hierachical structure from the input list of flat automata."
  input list<FlatAutomaton> flatAutomata;
  output list<Composition> comps;
protected
  FlatAutomaton fa;
  list<Composition> cs;
  array<DAE.ComponentRef> states;
  DAE.ComponentRef state, cref;
  Composition comp;
  tuple<DAE.ComponentRef, list<Composition>> entry;
  array<tuple<DAE.ComponentRef,list<Composition>>> refining;
  Integer i,n;
  list<Boolean> refineds;
  Boolean refined;
algorithm
  cs := {};
  for fa in flatAutomata loop
   FLAT_AUTOMATON(initialState=cref, states=states) := fa;
   n := arrayLength(states);
   refining := arrayCreate(n, (ComponentReference.makeDummyCref(),{}));
   for i in 1:n loop
    //print("In getComposition: cs: "+anyString(cs)+"\n");
    (cs, entry) := collectSubmodes(cs, arrayGet(states, i));
    refining := arrayUpdate(refining, i, entry);
   end for;
   comp := R(cref, refining);

   // Need to traverse and update cs
   refined := false;
   (cs, refineds) := List.map1_2(cs, refineSupermode, comp);
   refined := List.exist(refineds, function boolEq(b2=true));
   // If no refinement of existing mode was possible, add the mode as (tentatative) root mode
   cs := if (refined) then cs else comp::cs;
  end for;
  comps := cs;
end getComposition;

protected function refineSupermode "
Author: BTH
Recursively check whether cSub is a refinement of cSuper or of one of the sub-modes of cSuper.
If so, add cSub as a refinement to the known refinements of cSuper and return the refined cSuper
(cSuper -> cOut). The second output 'wasRefined' indicates if a refinement was found."
  input Composition cSuper;
  input Composition cSub;
  output Composition cOut;
  output Boolean wasRefined;
protected
  array<tuple<DAE.ComponentRef,list<Composition>>> refiningSuper;
  tuple<DAE.ComponentRef,list<Composition>> entry;
  list<Composition> refining, refiningNew;
  Composition c1, c2;
  DAE.ComponentRef crefIS, crefState, crefSub, crefStripped;
  Boolean isSub, wasRefinedDeeperInHierarchy;
  Integer i,n;
algorithm
  R(crefIS, refiningSuper) := cSuper;
  R(initialState=crefSub) := cSub;
  n := arrayLength(refiningSuper);
  wasRefined := false;
  // Check if a state can be refined at this hierarchy level, if so, return refined composition
  for i in 1:n loop
    (crefState,refining) := arrayGet(refiningSuper, i);
    crefStripped := if ComponentReference.crefDepth(crefSub) > 1 then ComponentReference.crefStripLastIdent(crefSub) else DAE.WILD();
    isSub := ComponentReference.crefEqual(crefState, crefStripped);
    //print("refineSupermode: crefState: "+ComponentReference.printComponentRefStr(crefState)+", crefSub: "+ComponentReference.printComponentRefStr(crefSub)+", isSub: "+boolString(isSub)+"\n");
    if isSub then
      refining := cSub :: refining;
      refiningSuper := arrayUpdate(refiningSuper, i, (crefState,refining));
      cOut := R(crefIS, refiningSuper);
      wasRefined := true;
      return;
    end if;
  end for;
  // No refinement possible at this level. Try to traverse deeper into hierarchy
  for i in 1:n loop
    (crefState,refining) := arrayGet(refiningSuper, i);
    refiningNew := {};
    for c1 in refining loop
      (c2, wasRefinedDeeperInHierarchy) := refineSupermode(c1, cSub);
      refiningNew := c2 :: refiningNew;
      wasRefined := wasRefined or wasRefinedDeeperInHierarchy;
    end for;
    // If refinement was possible, update hierarchy level and return refined composition
    if wasRefined then
      refiningNew := MetaModelica.Dangerous.listReverseInPlace(refiningNew);
      refiningSuper := arrayUpdate(refiningSuper, i, (crefState,refiningNew));
      cOut := R(crefIS, refiningSuper);
      return;
    end if;
  end for;
  // Got until here: No refinement was possible, return unchanged composition
  assert(wasRefined == false, "Can't get here if wasRefined is true");
  cOut := cSuper;
end refineSupermode;

protected function collectSubmodes "
Author: BTH
Find sub-modes of state 'cRefIn' in list 'csIn'. If a sub-mode 'csub' is found,
a tuple ('crefIn',{'csub'}) is returned, and a list 'csOut'=='csIn' - 'csub' is returned.
Otherwise, ('crefIn', {}) is returned, and 'csOut' == 'csIn' is returned.
In case of parallel states ('crefIn',{'csub1','csub2'}) is returned.
"
  input list<Composition> csIn;
  input DAE.ComponentRef crefIn;
  output list<Composition> csOut;
  output tuple<DAE.ComponentRef, list<Composition>> refinedOut;
protected
  DAE.ComponentRef cref, crefStripped;
  Composition c;
  list<Composition> refiningAcc;
  Boolean isSub;
algorithm
  csOut := {};
  refiningAcc := {};
  for c in csIn loop
    R(initialState=cref) := c;
    //print("collectSubmodes cref:"+ComponentReference.printComponentRefStr(cref)+"\n");
    crefStripped := ComponentReference.crefStripLastIdent(cref);
    isSub := ComponentReference.crefEqual(crefStripped, crefIn);
    //print("collectSubmodes crefStripped: "+ComponentReference.printComponentRefStr(crefStripped)+", crefIn: "+ComponentReference.printComponentRefStr(crefIn)+", isSub: "+boolString(isSub)+"\n");
    if isSub then
      refiningAcc := c :: refiningAcc;
    else
      csOut := c::csOut;
    end if;
  end for;
  refinedOut := (crefIn, refiningAcc);
end collectSubmodes;

protected function dumpCompositionStr "
Author: BTH
"
  input Composition composition;
  output String str;
algorithm
  str := match (composition)
    local
      DAE.ComponentRef cref;
      array<tuple<DAE.ComponentRef, list<Composition>>> cs;
      String s;
      list<String> ss;
    case R(initialState=cref, refining=cs) guard arrayLength(cs) == 0
      then "R["+ComponentReference.printComponentRefStr(cref) + ", {}]";
    case R(initialState=cref, refining=cs)
      equation
        s = "R["+ComponentReference.printComponentRefStr(cref) + ", {";
        ss = arrayList(Array.map(cs, dumpCompositionEntryStr));
      then s + stringDelimitList(ss, ", ") + "}]";
    end match;
end dumpCompositionStr;

protected function dumpCompositionEntryStr
  input tuple<DAE.ComponentRef,list<Composition>> entry;
  output String str;
protected
  DAE.ComponentRef cref;
  list<Composition> comps;
  list<String> s;
algorithm
  (cref, comps) := entry;
  str := match comps
    case {} then "("+ComponentReference.printComponentRefStr(cref)+", {})";
    else
      equation
        s = List.map(comps, dumpCompositionStr);
      then "("+ComponentReference.printComponentRefStr(cref)+", {"+stringDelimitList(s, ", ") + "})";
  end match;
end dumpCompositionEntryStr;


public function dumpFlatAutomatonStr "
Author: BTH
Dump flat automata to string"
  input FlatAutomaton flatA;
  output String flatStr;
protected
  list<DAE.ComponentRef> crefs;
  String initialStateStr, statesStr, smsStr;
  list<String> statesStrs;
  // FLAT_AUTOMATON fields
  DAE.ComponentRef initialState;
  array<DAE.ComponentRef> states;
  SMSemantics sms;
algorithm
  FLAT_AUTOMATON(initialState=initialState, states=states, sms=sms) := flatA;
  initialStateStr := ComponentReference.printComponentRefStr(initialState);
  crefs := arrayList(states);
  statesStrs := List.map(crefs, ComponentReference.printComponentRefStr);
  statesStr := stringDelimitList(statesStrs, ", ");
  smsStr := dumpSMSemanticsStr(sms);

  flatStr := initialStateStr+"( states("+statesStr+"), "+smsStr+" )";
end dumpFlatAutomatonStr;

public function dumpSMSemanticsStr "
Author: BTH
Dump SMSemantics to string"
  input SMSemantics sms;
  output String smsStr;
protected
  String qStr, tStr, varsStr, knownsStr, eqsStr;
  list<String> qStrs, tStrs, varsStrs, knownsStrs, eqsStrs;
  // SMS fields
  list<DAE.ComponentRef> q;
  list<Transition> t;
  list<DAE.Exp> c;
  list<BackendDAE.Var> vars;
  list<BackendDAE.Var> knowns;
  list<BackendDAE.Equation> eqs;
algorithm
  SMS(q=q, t=t, c=c,
    vars=vars, knowns=knowns, eqs=eqs) := sms;
  qStrs := List.map(q, ComponentReference.printComponentRefStr);
  qStr := stringDelimitList(qStrs, ", ");
  // TODO dump for transitons
  tStrs := {}; // List.map(transitions, BackendDump.equationString);
  tStr := ""; // stringDelimitList(transitionsStrs, "\n");
  // TODO dump for c
  varsStrs := List.map(vars, dumpVarStr);
  varsStr := stringDelimitList(varsStrs, "; ");
  knownsStrs := List.map(knowns, dumpVarStr);
  knownsStr := stringDelimitList(knownsStrs, "; ");
  eqsStrs :=  List.map(eqs, BackendDump.equationString);
  eqsStr := stringDelimitList(eqsStrs, "\n");

  smsStr := "SMS( q("+qStr+"), transitions("+tStr+"), "
    +"vars("+varsStr+"), knowns("+knownsStr+"), eqs("+eqsStr+") );";
end dumpSMSemanticsStr;

protected function extractFlatAutomata "
Author: BTH
For each initial state extract the (flat) automaton that is defined by the
transitive closure associated with that initial state."
  input list<DAE.ComponentRef> initialStates;
  input IncidenceTable iTable;
  input Integer nModes "Number of modes";
  output list<FlatAutomaton> flatAutomata;
protected
  HashTable.HashTable cref2index;
  Boolean incidence[nModes,nModes];
  list<tuple<DAE.ComponentRef, Integer>> entries;
  array<DAE.ComponentRef> i2cref;
  DAE.ComponentRef cref;
  list<DAE.ComponentRef> members;
  array<DAE.ComponentRef> membersArr;
  HashSet.HashSet memberSet;
  Integer n,i,j;
algorithm
  INCIDENCE_TABLE(cref2index, incidence) := iTable;
  n := BaseHashTable.hashTableCurrentSize(cref2index);
  // sanity check:
  assert(n == nModes, "Value of nModes needs to be equal to number of modes within mode table argument.");

  entries := BaseHashTable.hashTableList(cref2index);
  entries := List.sort(entries, crefIndexCmp);
  //i2cref := arrayCreate(n, ComponentReference.makeDummyCref());
  i2cref := listArray(List.map(entries, Util.tuple21));

  flatAutomata := {};
  for cref in initialStates loop
    i := BaseHashTable.get(cref, cref2index);
    members := {};
    for j in 1:n loop
      if incidence[i,j] then
        members := i2cref[j]::members;
      end if;
    end for;

    // Enusre uniquenes of entries
    memberSet := HashSet.emptyHashSetSized(listLength(members));
    memberSet := List.fold(members, BaseHashSet.add, memberSet);

    // Ensure that initialState comes first in array
    memberSet := BaseHashSet.delete(cref, memberSet);
    membersArr := listArray(cref :: BaseHashSet.hashSetList(memberSet));

    flatAutomata := FLAT_AUTOMATON(cref, membersArr, emptySMS())::flatAutomata;
  end for;

end extractFlatAutomata;


protected function extractInitialStates "
Author: BTH
Return crefs of states declared as 'initialState' in modes. "
  input ModeTable modes;
  output list<DAE.ComponentRef> initialStates;
protected
  list<tuple<DAE.ComponentRef, Mode>> entries;
  tuple<DAE.ComponentRef, Mode> e;
  DAE.ComponentRef cref;
  Mode mode;
  Boolean isInitial;
algorithm
  entries := BaseHashTable.hashTableList(modes);
  initialStates := {};
  for e in entries loop
    (cref, mode) := e;
    MODE(isInitial=isInitial) := mode;
    if isInitial then
      initialStates := cref::initialStates;
    end if;
  end for;
end extractInitialStates;


protected function transitiveClosure "
Author: BTH
Compute the transitive closure over the transition relation between states/modes.
This allows to cluster modes/states that are part of the same (flat) automaton.
The function uses the Warshall's algorithm for that task, c.f.
http://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm
or the more succinct (and potentially more readable) description
http://de.wikipedia.org/wiki/Warshall-Algorithmus
"
  input IncidenceTable iTable;
  input Integer nModes "Number of modes";
  output IncidenceTable  transClosure;
protected
  HashTable.HashTable cref2index;
  Boolean incidence[nModes,nModes];
  Integer n,k,i,j;
  Boolean c;
algorithm
  INCIDENCE_TABLE(cref2index, incidence) := iTable;
  n := BaseHashTable.hashTableCurrentSize(cref2index);
  // sanity check:
  assert(n == nModes, "Value of nModes needs to be equal to number of modes within mode table argument.");

  // Warshall's algorithm for computing the transitive closure
  for k in 1:n loop
    for i in 1:n loop
      if incidence[i,k] then
        for j in 1:n loop
          if incidence[k,j] then
            incidence[i,j] := true;
          end if;
        end for;
      end if;
    end for;
  end for;

  transClosure := INCIDENCE_TABLE(cref2index, incidence);
end transitiveClosure;



protected function printIncidenceTable "
Author: BTH
Print incidence table."
  input IncidenceTable iTable;
  input Integer nModes "Number of modes";
protected
  HashTable.HashTable cref2index;
  Boolean incidence[nModes,nModes];
  list<tuple<DAE.ComponentRef, Integer>> entries;
  tuple<DAE.ComponentRef, Integer> entry;
  DAE.ComponentRef cref;
  Integer n,i,j,padn;
  array<Boolean> row;
  String str,pads;
  Boolean b;
algorithm
  INCIDENCE_TABLE(cref2index, incidence) := iTable;
  entries := BaseHashTable.hashTableList(cref2index);

  // sanity check:
  n := listLength(entries);
  assert(n == nModes, "Value of nModes needs to be equal to number of modes within mode table argument.");

  entries := List.sort(entries, crefIndexCmp);
  for entry in entries loop
    (cref, i) := entry;
    print( ComponentReference.printComponentRefStr(cref) + ": " + intString(i) + "\n" );
  end for;

  pads := " ";
  padn := 8;
  // Print table header
  str := Util.stringPadRight("i", padn, pads);
  for i in 1:n loop
    str := str + Util.stringPadLeft(intString(i)+",", padn, pads);
  end for;
  print(str + "\n");
  // print incidence matrix rows
  for i in 1:n loop
    str := Util.stringPadRight(intString(i), padn, pads);
    for j in 1:n loop
      b := incidence[i,j];
      str := str + Util.stringPadLeft(boolString(b)+",", padn, pads);
    end for;
    print(str + "\n");
  end for;
end printIncidenceTable;

protected function crefIndexCmp "
Author: BTH
Compare the indices assigned to two crefs (helper function for sorting)"
  input tuple<DAE.ComponentRef, Integer> inElement1;
  input tuple<DAE.ComponentRef, Integer> inElement2;
  output Boolean inRes;
protected
  Integer i1, i2;
algorithm
  (_, i1) := inElement1;
  (_, i2) := inElement2;
  inRes := i1 > i2;
end crefIndexCmp;



protected function createIncidenceTable "
Author: BTH
Create incidence table showing which modes are connected by transitions."
  input ModeTable modes;
  input Integer nModes "Number of modes";
  output IncidenceTable iTable;
protected
  HashTable.HashTable cref2index "Map cref to corresponding index in incidence matrix";
  Boolean incidence[nModes,nModes] "Incidence matrix showing which modes are connected by transitions";
  array<Boolean> iRow;
  Integer n,m,i,j,k;
  DAE.ComponentRef cref;
  HashSet.HashSet edges;
  array<DAE.ComponentRef> crefs1,crefs2;
algorithm
  crefs1 := listArray(BaseHashTable.hashTableKeyList(modes));
  n := arrayLength(crefs1);
  cref2index := HashTable.emptyHashTableSized(n);
  assert(n == nModes, "Value of nModes needs to be equal to number of modes within mode table argument.");
  incidence := fill(false,n,n);

  for i in 1:n loop
    cref2index := BaseHashTable.addNoUpdCheck((crefs1[i], i), cref2index);
  end for;

  for i in 1:n loop
    MODE(edges=edges) := BaseHashTable.get(crefs1[i], modes);
    crefs2 := listArray(BaseHashSet.hashSetList(edges));
    m := arrayLength(crefs2);
    for j in 1:m loop
      cref := crefs2[j];
      k := BaseHashTable.get(cref, cref2index);
      incidence[i,k] := true;
    end for;
  end for;

  iTable := INCIDENCE_TABLE(cref2index, incidence);
end createIncidenceTable;



protected function identifyModes "
Author: BTH
Traverse the equations, search for 'transition' and 'initialState' operators,
extract the state arguments from them and collect them in the table.
"
  input BackendDAE.EqSystem inSyst;
  output ModeTable modes;
protected
  BackendDAE.EquationArray removedEqs;
algorithm
  modes := BackendEquation.traverseEquationArray(inSyst.removedEqs, extractStates, HashTableSM.emptyHashTable());
end identifyModes;


protected function extractStates "
Author: BTH
Helper function to identifyModes"
  input BackendDAE.Equation inEq;
  input ModeTable inA;
  output BackendDAE.Equation outEq;
  output ModeTable outA;
algorithm
  (outEq, outA) := match (inEq, inA)
    local
      String name;
      list<DAE.Exp> expLst;
      ModeTable modes;
    case (
        BackendDAE.ALGORITHM(alg = DAE.ALGORITHM_STMTS(
          statementLst = {
            DAE.STMT_NORETCALL(
              exp = DAE.CALL(
                path = Absyn.IDENT(name = name),
                expLst = expLst
              )
            )
          }
        )),
      _)
      equation
        //print("SMF-extractStates: "+ BackendDump.dumpEqnsStr({inEq}) +"\n");
        modes = extractState(name, expLst, inA);
      then
        (inEq, modes);
    else
      equation
        //print("SMF-extractStates: NO MATCH\n");
      then
        (inEq, inA);
  end match;
end extractStates;


protected function extractState "
Author: BTH
Helper function to extractStates"
  input String name;
  input list<DAE.Exp> expLst;
  input ModeTable inA;
  output ModeTable outA;
algorithm
  outA := match (name, expLst)
    local
      DAE.ComponentRef cstate1, cstate2;
      Integer tmp;
      Mode mode1, mode2;
      ModeTable modes;
      String name1,name2;
      Boolean isInitial1,isInitial2;
      HashSet.HashSet edges1,edges2;
      BackendDAE.EquationArray eqs1,eqs2,outgoing1,outgoing2;
      list<BackendDAE.Var> os1,os2,ol1,ol2;
      list<DAE.ComponentRef> ps1,ps2;
      //array<Option<BackendDAE.Equation>> equOptArr;
    case ("initialState", {DAE.CREF(componentRef=cstate1)})
      equation
        //print("SMF-printEq2: "+anyString(cstate1)+"\n");
        mode1 = if BaseHashTable.hasKey(cstate1, inA)
          then BaseHashTable.get(cstate1, inA)
            else MODE(ComponentReference.crefLastIdent(cstate1), true, HashSet.emptyHashSet(),
                      BackendEquation.emptyEqns(), BackendEquation.emptyEqns(), {}, {}, {});
        MODE(name1,isInitial1,edges1,eqs1,outgoing1,os1,ol1,ps1) = mode1;
        mode1 = MODE(name1,true,edges1,eqs1,outgoing1,os1,ol1,ps1);
        modes = BaseHashTable.add((cstate1, mode1), inA);
      then modes;
    case ("transition", DAE.CREF(componentRef=cstate1)::DAE.CREF(componentRef=cstate2)::_)
      equation
        //print("SMF-printEq2: "+anyString(cstate1)+"\n");
        _ = ComponentReference.crefDepth(cstate1);
        mode1 = if BaseHashTable.hasKey(cstate1, inA)
          then BaseHashTable.get(cstate1, inA)
            else MODE(ComponentReference.crefLastIdent(cstate1), false, HashSet.emptyHashSet(),
                      BackendEquation.emptyEqns(), BackendEquation.emptyEqns(),{},{},{});
        MODE(name1, isInitial1, edges1, eqs1,outgoing1,os1,ol1,ps1) = mode1;
        isInitial1 = isInitial1 or false;
        edges1 = BaseHashSet.add(cstate2, edges1);
        mode1 = MODE(name1, isInitial1, edges1, eqs1, outgoing1,os1,ol1,ps1);
        modes = BaseHashTable.add((cstate1, mode1), inA);

        // FIXME: I should just update the mode1 and not create a mode2???
        mode2 = if BaseHashTable.hasKey(cstate2, modes)
          then BaseHashTable.get(cstate2, modes)
            else MODE(ComponentReference.crefLastIdent(cstate1), false, HashSet.emptyHashSet(),
                      BackendEquation.emptyEqns(), BackendEquation.emptyEqns(), {}, {}, {});
        MODE(name2, isInitial2, edges2, eqs2, outgoing2, os2, ol2, ps2) = mode2;
        isInitial2 = isInitial2 or false;
        edges2 = BaseHashSet.add(cstate1, edges2);
        mode2 = MODE(name2, isInitial2, edges2, eqs2, outgoing2, os2, ol2, ps2);
        modes = BaseHashTable.add((cstate2, mode2), modes);
      then modes;
  end match;
end extractState;


protected function wrapAddTimeEventHack "
Author: BTH
Just a workaround as long as no support of synchronous features."
  input list<BackendDAE.TimeEvent> timeEventsIn;
  input BackendDAE.Shared inShared;
  output BackendDAE.Shared outShared = inShared;
protected
  BackendDAE.EventInfo eventInfo;
algorithm
  eventInfo := outShared.eventInfo;
  eventInfo.timeEvents := listAppend(outShared.eventInfo.timeEvents, timeEventsIn);
  outShared.eventInfo := eventInfo;
end wrapAddTimeEventHack;

protected function wrapInWhenHack "
Author: BTH
Just a workaround as long as no support of synchronous features."
  input BackendDAE.Equation inEq;
  input Real samplingTime;
  output BackendDAE.Equation outEq;
protected
  DAE.Exp expCond;
  Integer size;
  BackendDAE.WhenEquation whenEquation;
  DAE.ComponentRef left;

  // EQUATION
  DAE.Exp exp;
  DAE.Exp scalar;
  DAE.ElementSource source "origin of equation";
  BackendDAE.EquationAttributes attr;
  // EQUATION_ATTRIBUTES
  Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
  BackendDAE.EquationKind kind;

algorithm
  try
    BackendDAE.EQUATION(exp,scalar,source,attr) := inEq;
    DAE.CREF(componentRef=left) := exp;
    BackendDAE.EQUATION_ATTRIBUTES(differentiated, kind) := attr;
    // walk through scalar, replace previous(x) by pre(x)
    scalar := Expression.traverseExpBottomUp(scalar, subsPreForPrevious, NONE());
    // sample(0, samplingTime)
    expCond := DAE.ARRAY(DAE.T_ARRAY_BOOL_NODIM, true, {DAE.CALL(Absyn.IDENT("sample"), {DAE.ICONST(1), DAE.RCONST(0), DAE.RCONST(samplingTime)}, DAE.callAttrBuiltinImpureBool),DAE.CALL(Absyn.IDENT("initial"), {}, DAE.callAttrBuiltinImpureBool)});
    whenEquation := BackendDAE.WHEN_STMTS(expCond, {BackendDAE.ASSIGN(left, scalar, source)}, NONE());
    // wbraun: size states how many scalar variable this equation is for
    size := Expression.sizeOf(Expression.typeof(exp));
    //size := 1; // Fixme what is "size" for? does it reference the "sample index" of a corresponding (time)event BackendDAE.Shared.eventInfo.timeEvents
    outEq := BackendDAE.WHEN_EQUATION(size, whenEquation, source,
      BackendDAE.EQUATION_ATTRIBUTES(differentiated, BackendDAE.DYNAMIC_EQUATION()));
  else
    print("wrapInWhenHack: I FAILED MISERABLY FOR: " + anyString(inEq) + "\n");
    fail();
    //outEq := inEq;
  end try;
end wrapInWhenHack;

protected function subsPreForPrevious "
Author: BTH
Helper function to wrapInWhenHack"
  input DAE.Exp inExp;
  input Option<Boolean> inA;
  output DAE.Exp outExp;
  output Option<Boolean> outA;
algorithm
  outExp := match inExp
    local
      Absyn.Path path;
      list<DAE.Exp> expLst;
      DAE.CallAttributes attr;
    case DAE.CALL(Absyn.IDENT("previous"), expLst, attr)
      then DAE.CALL(Absyn.IDENT("pre"), expLst, attr);
    else
      inExp;
  end match;
  outA := NONE();
end subsPreForPrevious;

protected function debugPrintKnownVars
  input BackendDAE.Shared shared;
protected
  BackendDAE.Variables globalKnownVars;
  BackendDAE.VariableArray varArr "Array of variables";
  array<Option<BackendDAE.Var>> varOptArr;
  list<Option<BackendDAE.Var>> varOptLst;
  list<Option<String>> varStrLst;
  list<String> strLst;
  String varStrs;
algorithm
  BackendDAE.SHARED(globalKnownVars=globalKnownVars) := shared;
  BackendDAE.VARIABLES(varArr=varArr) := globalKnownVars;
  BackendDAE.VARIABLE_ARRAY(varOptArr=varOptArr) := varArr;
  varOptLst := arrayList(varOptArr);
  varOptLst := List.filterOnTrue(varOptLst, isSome);
  varStrLst := List.map(varOptLst, dumpSomeVarStr);
  strLst := List.map(varStrLst, function Util.getOptionOrDefault(inDefault="NONE"));
  varStrs := stringDelimitList(strLst, ";\n");
  print("Shared globalKnownVars:\n"+varStrs+"\n");
end debugPrintKnownVars;


protected function dumpVarsStr
  input BackendDAE.EqSystem inEqSystem;
  output String outStr;
protected
  BackendDAE.Variables orderedVars "ordered Variables, only states and alg. vars";
  // Variables
  array<list<BackendDAE.CrefIndex>> crefIdxLstArr "HashTB, cref->indx";
  BackendDAE.VariableArray varArr "Array of variables";
  Integer bucketSize "bucket size";
  Integer numberOfVars "no. of vars";
  // VariableArray
  Integer numberOfElements "no. elements";
  Integer arrSize "array size";
  array<Option<BackendDAE.Var>> varOptArr;
  list<Option<String>> sVarOptLst;
  list<String> sVarLst;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars) := inEqSystem;
  BackendDAE.VARIABLES(crefIdxLstArr, varArr, bucketSize, numberOfVars) := orderedVars;
  BackendDAE.VARIABLE_ARRAY(numberOfElements, arrSize, varOptArr) := varArr;
  sVarOptLst := arrayList(Array.map(varOptArr, dumpSomeVarStr));
  sVarLst := List.map(List.filterOnTrue(sVarOptLst, isSome), Util.getOption);
  outStr := stringDelimitList(sVarLst, "\n");
end dumpVarsStr;

protected function dumpSomeVarStr
  input Option<BackendDAE.Var> inVar;
  output Option<String> outStr;
algorithm
  outStr := match inVar
    local
      BackendDAE.Var var;
    case SOME(var) then SOME(dumpVarStr(var));
    else NONE();
  end match;
end dumpSomeVarStr;

public function dumpVarStr
  input BackendDAE.Var inVar;
  output String outStr;
protected
  Option<String> s1,s2,s3;
  String sVarName,sVarKind,sVarDirection,sVarType,sBindExp,sBindValue,sInstanceOpt,sIo;
  Option<DAE.ComponentRef> crefOpt;
  // BackendDAE.Var
  DAE.ComponentRef varName "variable name";
  BackendDAE.VarKind varKind "Kind of variable";
  DAE.VarDirection varDirection "input, output or bidirectional";
  DAE.VarParallelism varParallelism "parallelism of the variable. parglobal, parlocal or non-parallel";
  BackendDAE.Type varType "built-in type or enumeration";
  Option<DAE.Exp> bindExp "Binding expression e.g. for parameters";
  Option<Values.Value> bindValue "binding value for parameters";
  DAE.InstDims arryDim "array dimensions of non-expanded var";
  DAE.ElementSource source "origin of variable";
  Option<DAE.VariableAttributes> values "values on built-in attributes";
  Option<BackendDAE.TearingSelect> tearingSelectOption "value for TearingSelect";
  Option<SCode.Comment> comment "this contains the comment and annotation from Absyn";
  DAE.ConnectorType connectorType "flow, stream, unspecified or not connector.";
  DAE.VarInnerOuter io;
algorithm
  BackendDAE.VAR(varName, varKind, varDirection, varParallelism, varType,
   bindExp, bindValue, arryDim, source, values, tearingSelectOption, comment, connectorType, io) := inVar;
   sVarName := ComponentReference.crefStr(varName);
   sVarKind := BackendDump.kindString(varKind);
   sVarDirection := DAEDump.dumpDirectionStr(varDirection);
   sVarType := DAEDump.daeTypeStr(varType);
   s1 := Util.applyOption(bindExp, function ExpressionDump.dumpExpStr(inInteger=0));
   sBindExp := Util.getOptionOrDefault(s1, "");
   s2 := Util.applyOption(bindValue, ValuesUtil.valString);
   sBindValue := Util.getOptionOrDefault(s2, "");
   sInstanceOpt := PrefixUtil.printComponentPrefixStr(source.instance);
   sIo := match io
     case DAE.INNER() then "inner";
     case DAE.OUTER() then "outer";
     case DAE.INNER_OUTER() then "inner outer";
     case DAE.NOT_INNER_OUTER() then "";
   end match;

  outStr := sVarName + ": " + sIo + " " + sVarDirection + " " + sVarType + "=" +
            sBindExp + ":" + sBindValue + "; in " + sInstanceOpt;
end dumpVarStr;

protected function debugDumpMathematicaStr
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output String str;
protected
  BackendDAE.Variables orderedVars, globalKnownVars;
  BackendDAE.EquationArray orderedEqs, initialEqs;
  list<BackendDAE.Equation> orderedEqsLst;
  list<BackendDAE.Equation> initialEqsLst;
algorithm

  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs) := syst;
  orderedEqsLst := BackendEquation.equationList(orderedEqs);

  BackendDAE.SHARED(globalKnownVars=globalKnownVars, initialEqs=initialEqs) := shared;
  initialEqsLst := BackendEquation.equationList(initialEqs);

  str := MathematicaDump.dumpMmaDAEStr((globalKnownVars, orderedVars,initialEqsLst,orderedEqsLst));
end debugDumpMathematicaStr;


annotation(__OpenModelica_Interface="backend");
end StateMachineFeatures;

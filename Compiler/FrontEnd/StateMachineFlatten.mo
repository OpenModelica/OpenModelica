/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2015, Open Source Modelica Consortium (OSMC),
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

 encapsulated package StateMachineFlatten
 " file:        StateMachineFlatten.mo
  package:     StateMachineFlatten
  description: Flattening of state machines

  This module contains functions to transform an instantiated state machine to flat data-flow equations.
  The approach a rather direct implementation of the state machine to data-flow equations transformation
  described in the specification. A more efficient implemention could avoid that transformation to
  data-flow and instead keep the state machine structure in the back-end in order to generate optimized
  code (in terms of memory requirements and minimized conditional statements).
  "
public import Absyn;
public import DAE;
public import FCore;

protected import List;
protected import InstStateMachineUtil;
protected import ComponentReference;
protected import ExpressionDump;
protected import DAEUtil;
protected import Util;
protected import DAEDump;
protected import Error;
protected import HashTableCrToExpOption;
protected import Flags;


protected
uniontype Transition "
Properties of a transition"
  record TRANSITION
    Integer from;
    Integer to;
    DAE.Exp condition;
    Boolean immediate = true;
    Boolean reset = true;
    Boolean synchronize = false;
    Integer priority = 1;
  end TRANSITION;
end Transition;


public
uniontype FlatSmSemantics "
Structure that combines states of flat state machine in
canonical order with governing semantic equations."
  record FLAT_SM_SEMANTICS
    DAE.Ident ident;
    array<DAE.Element> smComps "First element is the initial state";
    // Flat State machine semantics (SMS)
    list<Transition> t "List/Array of transition data sorted in priority";
    list<DAE.Exp> c "Transition conditions sorted in priority";
    list<DAE.Element> vars "SMS veriables";
    list<DAE.Element> knowns "SMS constants/parameters";
    list<DAE.Element> eqs "SMS equations";
    // Activation and Reset propagation through hierarchy
    list<DAE.Element> pvars "Propagation related variables";
    list<DAE.Element> peqs "Propagation equations";
    Option<DAE.ComponentRef> enclosingState "Cref to enclosing state if any"; // FIXME needed?
  end FLAT_SM_SEMANTICS;
end FlatSmSemantics;

constant String SMS_PRE = "smOf" "prefix for crefs of fresh State Machine Semantics variables/knowns";

public function stateMachineToDataFlow "
Author: BTH
  Transform state machines to data-flow equations
"
  input FCore.Cache cache; // FIXME need to update this somewhere?
  input FCore.Graph env; // FIXME need to update this somewhere?
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
protected
  list<DAE.Element> elementLst, elementLst1, flatSmLst, otherLst, elementLst2, elementLst3;
  list<Transition> t;
  DAE.Element compElem;
  Integer nOfSubstitutions;

  // COMP
  DAE.Ident ident;
  list<DAE.Element> dAElist "a component with subelements, normally only used at top level.";
  DAE.ElementSource source "the origin of the component/equation/algorithm";
  Option<SCode.Comment> comment;
algorithm
  DAE.DAE(elementLst=elementLst) := inDAElist;
  assert(listLength(elementLst) == 1, "Internal compiler error: Handling of elementLst != 1 not supported\n");
  DAE.COMP(ident, dAElist, source, comment) := listHead(elementLst);

  (flatSmLst, otherLst) := List.extractOnTrue(dAElist, isFlatSm);
  elementLst2 := List.fold2(flatSmLst, flatSmToDataFlow, NONE(), NONE(), {});

  // FIXME HACK1 Wrap equations in when clauses hack (as long as clocked features are not fully supported in C runtime)
  if (not listEmpty(flatSmLst) and not stringEqual(Config.simCodeTarget(), "Cpp")) then
    elementLst2 := wrapHack(cache, elementLst2);
  end if;

  elementLst3 := listAppend(otherLst, elementLst2);
  outDAElist := DAE.DAE({DAE.COMP(ident, elementLst3, source, comment)});
  // print("StateMachineFlatten.stateMachineToDataFlow: outDAElist before global subs:\n" + DAEDump.dumpStr(outDAElist,FCore.getFunctionTree(cache)));

  // traverse dae expressions for making substitutions activeState(x) -> x.active
  (outDAElist, _, (_,nOfSubstitutions)) := DAEUtil.traverseDAE(outDAElist, FCore.getFunctionTree(cache), Expression.traverseSubexpressionsHelper, (traversingSubsActiveState, 0));

  if (not listEmpty(flatSmLst) and not stringEqual(Config.simCodeTarget(), "Cpp")) then
    // FIXME HACK2 traverse dae expressions for making substitutions previous(x) -> pre(x) (as long as clocked features are not fully supported in C runtime)
    (outDAElist, _, (_,nOfSubstitutions)) := DAEUtil.traverseDAE(outDAElist, FCore.getFunctionTree(cache), Expression.traverseSubexpressionsHelper, (traversingSubsPreForPrevious, 0));
    // FIXME HACK3 traverse dae expressions for making substitutions sample(x, _) -> x (as long as clocked features are not fully supported in C runtime)
    (outDAElist, _, (_,nOfSubstitutions)) := DAEUtil.traverseDAE(outDAElist, FCore.getFunctionTree(cache), Expression.traverseSubexpressionsHelper, (traversingSubsXForSampleX, 0));
  end if;
  // print("StateMachineFlatten.stateMachineToDataFlow: outDAElist:\n" + DAEDump.dumpStr(outDAElist,FCore.getFunctionTree(cache)));
end stateMachineToDataFlow;

protected function traversingSubsActiveState "
Author: BTH
Helper function to traverse subexpressions
Substitutes 'activeState(x)' by 'x.active' "
  input DAE.Exp inExp;
  input Integer inHitCount;
  output DAE.Exp outExp;
  output Integer outHitCount;
algorithm
  (outExp,outHitCount) := match inExp
    local
      DAE.ComponentRef componentRef;
    case DAE.CALL(path=Absyn.IDENT("activeState"), expLst={DAE.CREF(componentRef=componentRef)})
      then (DAE.CREF(ComponentReference.crefPrependIdent(componentRef, "active", {}, DAE.T_BOOL_DEFAULT), DAE.T_BOOL_DEFAULT), inHitCount + 1);
    else (inExp,inHitCount);
  end match;
end traversingSubsActiveState;

protected function flatSmToDataFlow "
  Author: BTH
  Transform a flat state machine to data-flow equations
"
  input DAE.Element inFlatSm "flat state machine that is to be transformed to data-flow equations";
  input Option<DAE.ComponentRef> inEnclosingStateCrefOption "Cref of state that encloses the flat state machiene (NONE() if at top hierarchy)";
  input Option<FlatSmSemantics> inEnclosingFlatSmSemanticsOption "The flat state machine semantics structure governing the enclosing state (NONE() if at top hierarchy)";
  input list<DAE.Element> accElems;
  output list<DAE.Element> outElems = accElems;
protected
  DAE.Ident ident;
  list<DAE.Element> dAElist, smCompsLst, otherLst1, transitionLst, otherLst2,
    otherLst3, eqnLst, otherLst4, smCompsLst2;
  DAE.Element initialStateOp, initialStateComp;
  DAE.ComponentRef crefInitialState;

  FlatSmSemantics flatSmSemanticsBasics, flatSmSemanticsWithPropagation, flatSmSemantics;
  list<Transition> transitions;
  list<DAE.Element> vars "SMS veriables";
  list<DAE.Element> knowns "SMS constants/parameters";
  list<DAE.Element> eqs "SMS equations";
  list<DAE.Element> pvars "Propagation related variables";
  list<DAE.Element> peqs "Propagation equations";
  // Option<DAE.ComponentRef> enclosingState "Cref to enclosing state if any"; // FIXME needed?
algorithm
  DAE.FLAT_SM(ident=ident, dAElist=dAElist) := inFlatSm;

  // break Elements into different groups
  (smCompsLst, otherLst1) := List.extractOnTrue(dAElist, isSMComp);
  (transitionLst, otherLst2) := List.extractOnTrue(otherLst1, isTransition);
  ({initialStateOp}, otherLst3) := List.extractOnTrue(otherLst2, isInitialState);
  (eqnLst, otherLst4) := List.extractOnTrue(otherLst3, isEquation);
  assert(listLength(otherLst4) == 0, "Internal compiler error. Unexpected elements in flat state machine.");

  DAE.NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("initialState"), expLst={DAE.CREF(componentRef=crefInitialState)})) := initialStateOp;
  ({initialStateComp}, smCompsLst2) := List.extract1OnTrue(smCompsLst, sMCompEqualsRef, crefInitialState);

  // Create basic semantic equations (MLS 17.3.4 Semantics Summary)
  flatSmSemanticsBasics := basicFlatSmSemantics(ident, initialStateComp::smCompsLst2, transitionLst);

  // Add activation and reset propagation related equations
  flatSmSemanticsWithPropagation := addPropagationEquations(flatSmSemanticsBasics, inEnclosingStateCrefOption, inEnclosingFlatSmSemanticsOption);

  // Elaborate on ticksInState() and timeInState() operators (MLS 17.1 Transitions)
  flatSmSemantics := elabXInStateOps(flatSmSemanticsWithPropagation, inEnclosingStateCrefOption);

  // Extract semantic equations for flat state machine and add the elements to the DAE list
  FLAT_SM_SEMANTICS(vars=vars, knowns=knowns, eqs=eqs, pvars=pvars, peqs=peqs) := flatSmSemantics;
  outElems := List.flatten({outElems, eqnLst, vars, knowns, eqs, pvars, peqs});

  // Extract DAE.Elements from state components (and recurse into potential FLAT_SMs in the state component)
  outElems := List.fold1(smCompsLst, smCompToDataFlow, flatSmSemantics, outElems);
end flatSmToDataFlow;

protected function elabXInStateOps "
Author: BTH
  Transform ticksInState() and timeInState() operators to data-flow equations
"
  input FlatSmSemantics inFlatSmSemantics;
  input Option<DAE.ComponentRef> inEnclosingStateCrefOption "Cref of state that encloses the flat state machiene (NONE() if at top hierarchy)";
  output FlatSmSemantics outFlatSmSemantics;
protected
  Integer i;
  Boolean found;
  DAE.Exp c2, c3, c4, conditionNew, substTickExp, substTimeExp;
  DAE.ComponentRef stateRef;
  Transition t2;
  list<Transition> tElab = {} "Elaborated transitions";
  list<DAE.Exp> cElab = {} "Elaborated conditions";
  list<DAE.Element> smeqsElab = {} "Elaborated smeqs";
  // FLAT_SM_SEMANTICS
  DAE.Ident ident;
  array<DAE.Element> smComps "First element is the initial state";
  list<Transition> t "List/Array of transition data sorted in priority";
  list<DAE.Exp> c "Transition conditions sorted in priority";
  list<DAE.Element> smvars "SMS veriables";
  list<DAE.Element> smknowns "SMS constants/parameters";
  list<DAE.Element> smeqs "SMS equations";
  list<DAE.Element> pvars = {} "Propagation related variables";
  list<DAE.Element> peqs = {} "Propagation equations";
  Option<DAE.ComponentRef> enclosingStateOption "Cref to enclosing state if any"; // FIXME needed?
  // TRANSITION
  Integer from;
  Integer to;
  DAE.Exp condition;
  Boolean immediate;
  Boolean reset;
  Boolean synchronize;
  Integer priority;
algorithm
  FLAT_SM_SEMANTICS(ident, smComps, t, c, smvars, smknowns, smeqs, pvars, peqs, enclosingStateOption) := inFlatSmSemantics;

  // We have some redundancy here (t[:].condition == c[:]) and thus need to update both
  i := 0;
  for tc in List.threadTuple(t,c) loop
    i := i + 1;
    (t2, c2) := tc;
    TRANSITION(from, to, condition, immediate, reset, synchronize, priority) := t2;

    // Need to access decorations attached to 'from' state
    DAE.SM_COMP(componentRef=stateRef) := arrayGet(smComps, from);

    // == Search whether condition contains a subexpression 'ticksInState()', if so, substitute them by 'smComps[from].$ticksInState' ==
    substTickExp := DAE.CREF(qCref("$ticksInState", DAE.T_INTEGER_DEFAULT, {}, stateRef), DAE.T_INTEGER_DEFAULT);
    (c3, (_, _, found)) := Expression.traverseExpTopDown(c2, traversingSubsXInState, ("ticksInState", substTickExp, false));
    if found and isSome(inEnclosingStateCrefOption) then
      // MLS 3.3 17.1: "can only be used in transition conditions of state machines not present in states of hierarchical state machines" violated
      Error.addCompilerError("Found 'ticksInState()' within a state of an hierarchical state machine.");
      fail();
    end if;
    // if a transition was updated we also need to update the semantic equation containing that transition's logic
    smeqsElab := if found  then List.map5(smeqs, smeqsSubsXInState, arrayGet(smComps, 1), i, listLength(t), substTickExp, "ticksInState") else  smeqs;
    smeqs := smeqsElab; // use updated smeqs

    // == Search whether condition contains a subexpression 'timeInState()', if so, substitute them by 'smComps[from].$timeInState' ==
    substTimeExp := DAE.CREF(qCref("$timeInState", DAE.T_REAL_DEFAULT, {}, stateRef), DAE.T_REAL_DEFAULT);
    (c4, (_, _, found)) := Expression.traverseExpTopDown(c2, traversingSubsXInState, ("timeInState", substTimeExp, false));
    if found and isSome(inEnclosingStateCrefOption) then
      // MLS 3.3 17.1: "can only be used in transition conditions of state machines not present in states of hierarchical state machines" violated
      Error.addCompilerError("Found 'timeInState()' within a state of an hierarchical state machine.");
      fail();
    end if;
    // if a transition was updated we also need to update the semantic equation containing that transition's logic
    smeqsElab := if found  then List.map5(smeqs, smeqsSubsXInState, arrayGet(smComps, 1), i, listLength(t), substTimeExp, "timeInState") else  smeqs;
    smeqs := smeqsElab; // use updated smeqs

    tElab := TRANSITION(from, to, c4, immediate, reset, synchronize, priority) :: tElab;
    cElab := c4 :: cElab;
  end for;

  outFlatSmSemantics := FLAT_SM_SEMANTICS(ident, smComps, listReverse(tElab), listReverse(cElab), smvars, smknowns, smeqsElab, pvars, peqs, enclosingStateOption);
end elabXInStateOps;

protected function smeqsSubsXInState "
Author: BTH
Helper function to elabXInStateOps.
Replace 'xInState()' in RHS of semantic equations by 'substExp', but only within the transition
condition specified by the remaining function arguments.
"
  input DAE.Element inSmeqs "SMS equation";
  input DAE.Element initialStateComp "Initial state component of governing flat state machine";
  input Integer i "Index of transition";
  input Integer nTransitions;
  input DAE.Exp substExp;
  input String xInState "Name of function that is to be replaced, e.g., 'timeInState', or 'tickInState'";
  output DAE.Element outSmeqs "SMS equation";
protected
  DAE.ComponentRef preRef, cref, lhsRef, crefInitialState;
  DAE.Type tArrayBool;
  DAE.ElementSource elemSource;
  DAE.Exp lhsExp, rhsExp, rhsExp2;
  DAE.Type ty;
algorithm
  // Cref to initial state of governing flat state machine
  DAE.SM_COMP(componentRef=crefInitialState) := initialStateComp;
  preRef := ComponentReference.crefPrefixString(SMS_PRE, crefInitialState);
  tArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_INTEGER(nTransitions)}, DAE.emptyTypeSource);
  cref := qCref("cImmediate", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef);
  DAE.EQUATION(lhsExp, rhsExp, elemSource) := inSmeqs;
  DAE.CREF(lhsRef, ty) := lhsExp;
  // print("StateMachineFlatten.smeqsSubsXInState: cref: " + ComponentReference.printComponentRefStr(cref) + "\n");
  // print("StateMachineFlatten.smeqsSubsXInState: lhsRef: " + ComponentReference.printComponentRefStr(lhsRef) + "\n");
  if ComponentReference.crefEqual(cref, lhsRef) then
    // print("StateMachineFlatten.smeqsSubsXInState: rhsExp: " + ExpressionDump.printExpStr(rhsExp) + "\n");
    (rhsExp2, _) :=  Expression.traverseExpTopDown(rhsExp, traversingSubsXInState, (xInState, substExp, false));
    // print("StateMachineFlatten.smeqsSubsXInState: rhsExp2: " + ExpressionDump.printExpStr(rhsExp2) + "\n");
  else
    rhsExp2 := rhsExp;
  end if;
  outSmeqs := DAE.EQUATION(lhsExp, rhsExp2, elemSource);
end smeqsSubsXInState;

protected function traversingSubsXInState "
Author: BTH
Helper function to elabXInStateOps and smeqsSubsXInState.
Replace 'XInState()' operators (first element of inXSubstHit) by expression given in second element of inXSubstHit tuple.
"
  input DAE.Exp inExp;
  input tuple<String, DAE.Exp, Boolean> inXSubstHit;
  output DAE.Exp outExp;
  output Boolean cont = true;
  output tuple<String, DAE.Exp, Boolean> outXSubstHit;
algorithm
  (outExp, outXSubstHit) := match (inExp, inXSubstHit)
    local
      DAE.Exp subsExp;
      Boolean hit;
      String xInState, name;
    case (DAE.CALL(path=Absyn.IDENT(name)), (xInState, subsExp, hit)) guard name == xInState
      then (subsExp, (xInState, subsExp, true));
    else then (inExp, inXSubstHit);
  end match;
end traversingSubsXInState;

protected function smCompToDataFlow "
Author: BTH
  Transform state machine component to data-flow equations
"
  input DAE.Element inSMComp;
  input FlatSmSemantics inEnclosingFlatSmSemantics "The flat state machine semantics structure governing the state component";
  input list<DAE.Element> accElems;
  output list<DAE.Element> outElems = accElems;
protected
  list<DAE.Element> varLst, otherLst1, equationLst1, equationLst2, otherLst2, flatSmLst, otherLst3;
  DAE.ComponentRef componentRef;
  list<DAE.ComponentRef> varCrefs;
  list<Option<DAE.VariableAttributes>> variableAttributesOptions;
  list<Option<DAE.Exp>> startValuesOpt;
  list<tuple<DAE.ComponentRef, Option<DAE.Exp>>> varCrefStartVal;
  list<DAE.Element> dAElist "a component with subelements";
  HashTableCrToExpOption.HashTable crToExpOpt "Table that maps the cref of a variable to its start value";
algorithm
  DAE.SM_COMP(componentRef=componentRef, dAElist=dAElist) := inSMComp;

  (varLst, otherLst1) := List.extractOnTrue(dAElist, isVar);
  varCrefs := List.map(varLst, DAEUtil.varCref);
  variableAttributesOptions := List.map(varLst, DAEUtil.getVariableAttributes);
  startValuesOpt := List.map(variableAttributesOptions, getStartAttrOption);
  varCrefStartVal := List.threadTuple(varCrefs, startValuesOpt);
  crToExpOpt := HashTableCrToExpOption.emptyHashTableSized(listLength(varCrefStartVal) + 1);
  // create table that maps the cref of a variable to its start value
  crToExpOpt := List.fold(varCrefStartVal, BaseHashTable.add, crToExpOpt);
  //print("StateMachineFlatten.smCompToDataFlow: crToExpOpt:\n"); BaseHashTable.dumpHashTable(crToExpOpt);

  (equationLst1, otherLst2) := List.extractOnTrue(otherLst1, isEquation);


  // 1. Make equations conditional so that they are only active if enclosing state is active
  // 2. Add reset equations for discrete-time states declared in the component
  equationLst2 := List.fold3(equationLst1, addStateActivationAndReset, inSMComp, inEnclosingFlatSmSemantics, crToExpOpt, {});

  (flatSmLst, otherLst3) := List.extractOnTrue(otherLst2, isFlatSm);

  // append non FLAT_SM elements to accumulator
  outElems := List.flatten({outElems, varLst, equationLst2, otherLst3});

  // recurse into FLAT_SM elements (if any)
  outElems := List.fold2(flatSmLst, flatSmToDataFlow, SOME(componentRef), SOME(inEnclosingFlatSmSemantics), outElems);
end smCompToDataFlow;

protected function addStateActivationAndReset
  input DAE.Element inEqn;
  input DAE.Element inEnclosingSMComp "The state component enclosing the equation";
  input FlatSmSemantics inEnclosingFlatSmSemantics "The flat state machine semantics structure governing the state component";
  input HashTableCrToExpOption.HashTable crToExpOpt "Table mapping variable declaration in the enclosing state to start values";
  input list<DAE.Element> accEqns;
  output list<DAE.Element> outEqns;
protected
  DAE.ComponentRef crefLHS, enclosingStateRef, substituteRef, activeResetRef, activeResetStatesRef;
  Boolean found, is;
  DAE.Type tyLHS;
  DAE.Element eqn, eqn1, eqn2, var2;
  // EQUATION
  DAE.Exp exp;
  DAE.Exp scalar, scalarNew;
  DAE.ElementSource source;
algorithm
  DAE.EQUATION(exp, scalar, source) := inEqn;
  try
    DAE.CREF(componentRef=crefLHS, ty=tyLHS) := exp;
  else
    Error.addCompilerError("Currently, only equations in state machines with a LHS component reference are supported");
    fail();
  end try;
  DAE.SM_COMP(componentRef=enclosingStateRef) := inEnclosingSMComp;

  // Search whether the RHS of an equation 'x=exp' contains a subexpression 'previous(x)', if so, substitute them by 'x_previous'
  (scalarNew, (_, found)) := Expression.traverseExpTopDown(scalar, traversingSubsPreviousCref, (crefLHS, false));
  eqn := DAE.EQUATION(exp, scalarNew, source);

  if found then
    // Transform equation 'a.x = e' to 'a.x = if a.active then e else a.x_previous'
    eqn1 := wrapInStateActivationConditional(eqn, enclosingStateRef, true);

    // Create fresh variable 'a.x_previous'
    var2 := createVarWithDefaults(ComponentReference.appendStringLastIdent("_previous", crefLHS), DAE.DISCRETE(), tyLHS, {});
    // Create fresh reset equation: 'a.x_previous = if a.active and (smOf.a.activeReset or smOf.fsm_of_a.activeResetStates[i] then x_start else previous(a.x)'
    eqn2 := createResetEquation(crefLHS, tyLHS, enclosingStateRef, inEnclosingFlatSmSemantics, crToExpOpt);

    outEqns := eqn1 :: var2 :: eqn2 :: accEqns;
  else
    outEqns := wrapInStateActivationConditional(eqn, enclosingStateRef, false)::accEqns;
  end if;
end addStateActivationAndReset;

protected function createResetEquation "
Author: BTH
Given LHS 'a.x' and its start value 'x_start', as well as its enclosing state component 'a' with index 'i' in its governing FLAT_SM 'fsm_of_a' return eqn
'a.x_previous = if a.active and (smOf.a.activeReset or smOf.fsm_of_a.activeResetStates[i] then x_start else previous(a.x)'
"
  input DAE.ComponentRef inLHSCref "LHS cref";
  input DAE.Type inLHSty "LHS type";
  input DAE.ComponentRef inStateCref "Component reference of state enclosing the equation";
  input FlatSmSemantics inEnclosingFlatSmSemantics "The flat state machine semantics structure governing the state component";
  input HashTableCrToExpOption.HashTable crToExpOpt "Table mapping variable declaration in the enclosing state to start values";
  output DAE.Element outEqn;
protected
  DAE.Exp activeExp, lhsExp, activeResetExp, activeResetStatesExp, orExp, andExp, previousExp, startValueExp, ifExp;
  Option<DAE.Exp> startValueOpt;
  DAE.ComponentRef initStateRef, preRef;
  Integer i, nStates;
  array<DAE.Element> enclosingFlatSMComps;
  DAE.Type tArrayBool;
  DAE.CallAttributes callAttributes;
algorithm
  FLAT_SM_SEMANTICS(smComps=enclosingFlatSMComps) := inEnclosingFlatSmSemantics;
  DAE.SM_COMP(componentRef=initStateRef) := arrayGet(enclosingFlatSMComps, 1); // initial state

  // prefix for state machine semantics equations of the governing flat state machine
  preRef := ComponentReference.crefPrefixString(SMS_PRE, initStateRef);

  // position of enclosing state in the array of states of its governing flat state machine
  i := List.position1OnTrue(arrayList(enclosingFlatSMComps), sMCompEqualsRef, inStateCref);

  // smOf.a.activeReset
  activeResetExp := DAE.CREF(qCref("activeReset", DAE.T_BOOL_DEFAULT, {}, preRef), DAE.T_BOOL_DEFAULT);

  nStates := arrayLength(enclosingFlatSMComps);
  tArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource);
  // smOf.fsm_of_a.activeResetStates[i]
  activeResetStatesExp := DAE.CREF(qCref("activeResetStates", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef), DAE.T_BOOL_DEFAULT);

  // smOf.fsm_of_a.activeReset or smOf.fsm_of_a.activeResetStates[i]
  orExp := DAE.LBINARY(activeResetExp, DAE.OR(DAE.T_BOOL_DEFAULT), activeResetStatesExp);

  // a.active (reference the active indicator for this state)
  activeExp := DAE.CREF(qCref("active", DAE.T_BOOL_DEFAULT, {}, inStateCref), DAE.T_BOOL_DEFAULT);

  // a.active and (smOf.fsm_of_a.activeReset or smOf.fsm_of_a.activeResetStates[i])
  andExp := DAE.LBINARY(activeExp, DAE.AND(DAE.T_BOOL_DEFAULT), orExp);

  callAttributes := DAE.CALL_ATTR(inLHSty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
  // previous(a.x)
  previousExp := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(inLHSCref, inLHSty)}, callAttributes);

  startValueOpt := BaseHashTable.get(inLHSCref, crToExpOpt);
  if isSome(startValueOpt) then
    startValueExp := Util.getOption(startValueOpt);
  else
    // No start value given for the variable, default to "0"
    startValueExp := match inLHSty
      case DAE.T_INTEGER()
        algorithm
          Error.addCompilerWarning("Variable "+ComponentReference.crefStr(inLHSCref)+" lacks start value. Defaulting to start=0.\n");
        then DAE.ICONST(0);
      case DAE.T_REAL()
        algorithm
          Error.addCompilerWarning("Variable "+ComponentReference.crefStr(inLHSCref)+" lacks start value. Defaulting to start=0.\n");
       then DAE.RCONST(0);
      case DAE.T_BOOL()
        algorithm
          Error.addCompilerWarning("Variable "+ComponentReference.crefStr(inLHSCref)+" lacks start value. Defaulting to start=false.\n");
        then DAE.BCONST(false);
      case DAE.T_STRING()
        algorithm
          Error.addCompilerWarning("Variable "+ComponentReference.crefStr(inLHSCref)+" lacks start value. Defaulting to start=\"\".\n");
        then DAE.SCONST("");
      else
        algorithm
          Error.addCompilerError("Variable "+ComponentReference.crefStr(inLHSCref)+" lacks start value.\n");
        then fail();
    end match;
  end if;

  // if a.active and (smOf.fsm_of_a.activeReset or smOf.fsm_of_a.activeResetStates[i]) than x_start else previous(a.x)
  ifExp := DAE.IFEXP(andExp, startValueExp, previousExp);

  // a.x_previous
  lhsExp := DAE.CREF(ComponentReference.appendStringLastIdent("_previous", inLHSCref), inLHSty);

  // a.x_previous = if a.active and (smOf.a.activeReset or smOf.fsm_of_a.activeResetStates[i] then x_start else previous(a.x)
  outEqn := DAE.EQUATION(lhsExp, ifExp, DAE.emptyElementSource);

end createResetEquation;

protected function wrapInStateActivationConditional "
Author: BTH
Transform an equation 'a.x = e' to 'a.x = if a.active then e else previous(a.x)' (isResetEquation=false)
Transform an equation 'a.x = e' to 'a.x = if a.active then e else x_previous' (isResetEquation=true)
"
  input DAE.Element inEqn;
  input DAE.ComponentRef inStateCref "Component reference of state enclosing the equation";
  input Boolean isResetEquation "Reset equations";
  output DAE.Element outEqn;
protected
  DAE.Exp exp, scalar, scalar1, activeRef, expElse;
  DAE.Type ty;
  DAE.CallAttributes callAttributes;
  DAE.ElementSource source;
  DAE.ComponentRef cref;
algorithm
  DAE.EQUATION(exp, scalar, source) := inEqn;
  try
    DAE.CREF(cref, ty) := exp;
  else
    Error.addCompilerError("The LHS of equations in state machines needs to be a component reference");
    fail();
  end try;
  // reference the active indicator for this state
  activeRef := DAE.CREF(qCref("active", DAE.T_BOOL_DEFAULT, {}, inStateCref), DAE.T_BOOL_DEFAULT);
  callAttributes := DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
  if isResetEquation then // x_previous
    expElse := DAE.CREF(ComponentReference.appendStringLastIdent("_previous", cref), ty);
  else                    // previous(x)
    expElse := DAE.CALL(Absyn.IDENT("previous"), {exp}, callAttributes);
  end if;
  scalar1 := DAE.IFEXP(activeRef, scalar, expElse);
  // state.x = if state.active then .. else expElse
  outEqn := DAE.EQUATION(exp, scalar1, source);
end wrapInStateActivationConditional;


protected function traversingSubsPreviousCref "
Author: BTH
Given a cref 'x', find if the expression has subexpressions 'previous(x)' and replace them by 'x_previous'
and return an indication if any substitutions took place.
"
  input DAE.Exp inExp;
  input tuple<DAE.ComponentRef, Boolean> inCrefHit;
  output DAE.Exp outExp;
  output Boolean cont = true;
  output tuple<DAE.ComponentRef, Boolean> outCrefHit;
algorithm
  (outExp, outCrefHit) := match (inExp, inCrefHit)
    local
      DAE.ComponentRef cr, cref, substituteRef;
      Boolean hit;
      DAE.CallAttributes attr;
      DAE.Type ty;
    case (DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(cr, ty)}, attr),
      (cref, hit)) guard ComponentReference.crefEqual(cr, cref)
      algorithm
        substituteRef := ComponentReference.appendStringLastIdent("_previous", cref);
      then (DAE.CREF(substituteRef, ty), (cref, true));
    else then (inExp, inCrefHit);
  end match;

end traversingSubsPreviousCref;

protected function getStartAttrOption "
Helper function to smCompToDataFlow
"
  input Option<DAE.VariableAttributes> inVarAttrOpt;
  output Option<DAE.Exp> outExpOpt;
protected
  DAE.Exp start;
algorithm
  if isSome(inVarAttrOpt) then
    start := DAEUtil.getStartAttr(inVarAttrOpt);
    outExpOpt := SOME(start);
  else
    outExpOpt := NONE();
  end if;
end getStartAttrOption;


protected function addPropagationEquations "
Author: BTH
Add activation and reset propagation related equation and variables to flat state machine
"
  input FlatSmSemantics inFlatSmSemantics;
  input Option<DAE.ComponentRef> inEnclosingStateCrefOption "Cref of state that encloses the flat state machiene (NONE() if at top hierarchy)";
  input Option<FlatSmSemantics> inEnclosingFlatSmSemanticsOption "The flat state machine semantics structure governing the enclosing state (NONE() if at top hierarchy)";
  output FlatSmSemantics outFlatSmSemantics;
protected
  DAE.ComponentRef preRef, initStateRef, initRef, resetRef, activeRef, stateRef, activePlotIndicatorRef;
  DAE.Element initVar, activePlotIndicatorVar, ticksInStateVar, timeEnteredStateVar, timeInStateVar;
  DAE.Element activePlotIndicatorEqn, ticksInStateEqn, timeEnteredStateEqn, timeInStateEqn;
  DAE.Exp rhs, andExp, eqExp, activeResetStateRefExp, activeStateRefExp, activeResetRefExp;
  DAE.Type tArrayBool, tArrayInteger;

  // FLAT_SM_SEMANTICS
  DAE.Ident ident;
  array<DAE.Element> smComps "First element is the initial state";
  list<Transition> t "List/Array of transition data sorted in priority";
  list<DAE.Exp> c "Transition conditions sorted in priority";
  list<DAE.Element> smvars "SMS veriables";
  list<DAE.Element> smknowns "SMS constants/parameters";
  list<DAE.Element> smeqs "SMS equations";
  Option<DAE.ComponentRef> enclosingStateOption "Cref to enclosing state if any"; // FIXME needed?
  list<DAE.Element> pvars = {} "Propagation related variables";
  list<DAE.Element> peqs = {} "Propagation equations";

  // Enclosing FLAT_SM_SEMANTICS
  DAE.ComponentRef enclosingStateCref, enclosingPreRef, enclosingActiveResetStateRef, enclosingActiveResetRef, enclosingActiveStateRef;
  FlatSmSemantics enclosingFlatSMSemantics;
  array<DAE.Element> enclosingFlatSMComps "First element is the initial state";
  DAE.ComponentRef enclosingFlatSMInitStateRef;
  Integer posOfEnclosingSMComp, nStates;


algorithm
  FLAT_SM_SEMANTICS(ident=ident, smComps=smComps, t=t, c=c, vars=smvars, knowns=smknowns, eqs=smeqs) := inFlatSmSemantics;

  DAE.SM_COMP(componentRef=initStateRef) := arrayGet(smComps, 1); // initial state
  // cref prefix for semantics equations governing flat state machine
  preRef := ComponentReference.crefPrefixString(SMS_PRE, initStateRef);

  // MLS 17.3.4 Semantics Summary: "active" and "reset" are *inputs* to the state machine semantics. They are defined below
  activeRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, preRef);
  resetRef := qCref("reset", DAE.T_BOOL_DEFAULT, {}, preRef);
  if isNone(inEnclosingFlatSmSemanticsOption) then
    // toplevel flat state machines need to "self-reset" at their first clock tick. After that reset is always false
    // Boolean preRef.init(start=true) = false
    initRef := qCref("init", DAE.T_BOOL_DEFAULT, {}, preRef);
    initVar := createVarWithDefaults(initRef, DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, {});
    initVar := setVarFixedStartValue(initVar, DAE.BCONST(true));
    pvars := initVar :: pvars;
    peqs := DAE.EQUATION(DAE.CREF(initRef, DAE.T_BOOL_DEFAULT), DAE.BCONST(false), DAE.emptyElementSource) :: peqs;

    // preRef.reset = previous(preRef.init)
    rhs := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(initRef, DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
    peqs := DAE.EQUATION(DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT), rhs, DAE.emptyElementSource) :: peqs;

    // input Boolean active "true if the state machine is active";
    // set to "true", since toplevel state machines is always active
    peqs := DAE.EQUATION(DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT), DAE.BCONST(true), DAE.emptyElementSource) :: peqs;
  else
    // We have an enclosing state: propagate reset handling and activation handling to refined state machine
    enclosingStateCref := Util.getOption(inEnclosingStateCrefOption);
    enclosingFlatSMSemantics := Util.getOption(inEnclosingFlatSmSemanticsOption);
    FLAT_SM_SEMANTICS(smComps=enclosingFlatSMComps) := enclosingFlatSMSemantics;
    // initial state of enclosing flat state machine
    DAE.SM_COMP(componentRef=enclosingFlatSMInitStateRef) := arrayGet(enclosingFlatSMComps, 1);
    // cref prefix for semantics equations governing enclosing SM
    enclosingPreRef := ComponentReference.crefPrefixString(SMS_PRE, enclosingFlatSMInitStateRef);

    // Position of enclosing state in enclosing flat state machine
    posOfEnclosingSMComp := List.position1OnTrue(arrayList(enclosingFlatSMComps), sMCompEqualsRef, enclosingStateCref);

    // == Create equation for SMS_PRE.initStateRef.reset ==
    nStates := arrayLength(enclosingFlatSMComps);
    tArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource);
    tArrayInteger := DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource);
    enclosingActiveResetStateRef := qCref("activeResetStates", tArrayBool, {DAE.INDEX(DAE.ICONST(posOfEnclosingSMComp))}, enclosingPreRef);
    enclosingActiveResetRef := qCref("activeReset", DAE.T_BOOL_DEFAULT, {}, enclosingPreRef);
    enclosingActiveStateRef := qCref("activeState", DAE.T_INTEGER_DEFAULT, {}, enclosingPreRef);
    // SMS_PRE.enclosingFlatSMInitStateRef.activeState == posOfEnclosingSMComp
    eqExp := DAE.RELATION(DAE.CREF(enclosingActiveStateRef, DAE.T_INTEGER_DEFAULT), DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(posOfEnclosingSMComp),-1, NONE());
    // SMS_PRE.enclosingFlatSMInitStateRef.activeReset and SMS_PRE.enclosingFlatSMInitStateRef.activeState == posOfEnclosingSMComp
    andExp := DAE.LBINARY(DAE.CREF(enclosingActiveResetRef, DAE.T_BOOL_DEFAULT), DAE.AND(DAE.T_BOOL_DEFAULT), eqExp);
    rhs := DAE.LBINARY(DAE.CREF(enclosingActiveResetStateRef, DAE.T_BOOL_DEFAULT), DAE.OR(DAE.T_BOOL_DEFAULT), andExp);
    // SMS_PRE.initStateRef.reset = SMS_PRE.enclosingFlatSMInitStateRef.activeResetStates[posOfEnclosingSMComp]
    //   or (SMS_PRE.enclosingFlatSMInitStateRef.activeReset and SMS_PRE.enclosingFlatSMInitStateRef.activeState == posOfEnclosingSMComp)
    peqs := DAE.EQUATION(DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT), rhs, DAE.emptyElementSource) :: peqs;

    // == Create equation for SMS_PRE.initStateRef.active ==
    rhs := DAE.RELATION(DAE.CREF(enclosingActiveStateRef, DAE.T_INTEGER_DEFAULT), DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(posOfEnclosingSMComp),-1, NONE());
    // SMS_PRE.initStateRef.active = SMS_PRE.enclosingFlatSMInitStateRef.activeState == posOfEnclosingSMComp
    peqs := DAE.EQUATION(DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT), rhs, DAE.emptyElementSource) :: peqs;
  end if;

  // Decorate state with additional information
  for i in 1:arrayLength(smComps) loop
    // Add indication for plotting whether a state is active or not (stateRef.active)
    DAE.SM_COMP(componentRef=stateRef) := arrayGet(smComps, i);
    (activePlotIndicatorVar, activePlotIndicatorEqn) :=  createActiveIndicator(stateRef, preRef, i);
    pvars := activePlotIndicatorVar :: pvars;
    peqs :=  activePlotIndicatorEqn :: peqs;

    // Add ticksInState counter (stateRef.$ticksInState = if stateRef.active then previous(stateRef.$ticksInState) + 1 else 0)
    DAE.VAR(componentRef=activePlotIndicatorRef) := activePlotIndicatorVar;
    (ticksInStateVar, ticksInStateEqn) := createTicksInStateIndicator(stateRef, activePlotIndicatorRef);
    pvars := ticksInStateVar :: pvars;
    peqs :=  ticksInStateEqn :: peqs;

    // == Add timeInState Indicator (stateRef.$timeInState(start=0)) ==
    // Auxiliary variable holding time when state was entred (stateRef.$timeEnteredState(start=0)
    // stateRef.$timeEnteredState = if previous(stateRef.active) == false and stateRef.active == true then sample(time) else previous(stateRef.$timeEnteredState)
    (timeEnteredStateVar, timeEnteredStateEqn) := createTimeEnteredStateIndicator(stateRef, activePlotIndicatorRef);
    // stateRef.$timeInState = if stateRef.active then sample(time) - stateRef.$timeEnteredState else 0
    (timeInStateVar, timeInStateEqn) := createTimeInStateIndicator(stateRef, activePlotIndicatorRef, timeEnteredStateVar);
    pvars := timeEnteredStateVar :: timeInStateVar :: pvars;
    peqs :=  timeEnteredStateEqn :: timeInStateEqn :: peqs;
  end for;

  outFlatSmSemantics := FLAT_SM_SEMANTICS(ident, smComps, t, c, smvars, smknowns, smeqs, pvars, peqs, inEnclosingStateCrefOption);

end addPropagationEquations;

protected function createTimeInStateIndicator "
Author: BTH
Helper function to addPropagationEquations.
Create variable that indicates the time duration since a transition was made to the currently active state"
  input DAE.ComponentRef stateRef "cref of state to which timeInState variable shall be added";
  input DAE.ComponentRef stateActiveRef "cref of active indicator corresponding to stateRef";
  input DAE.Element timeEnteredStateVar "Auxiliary variable generated in createTimeEnteredStateIndicator(..)";
  output DAE.Element timeInStateVar;
  output DAE.Element timeInStateEqn;
protected
  DAE.ComponentRef timeInStateRef, timeEnteredStateRef;
  DAE.Type ty;
  DAE.Exp timeInStateExp, timeEnteredStateExp, stateActiveExp, expCond, expSampleTime, expThen, expElse;
algorithm
  // Create Variable stateRef.$timeEnteredState
  timeInStateRef := qCref("$timeInState", DAE.T_REAL_DEFAULT, {}, stateRef);
  timeInStateVar := createVarWithDefaults(timeInStateRef, DAE.DISCRETE(), DAE.T_REAL_DEFAULT, {});
  timeInStateVar := setVarFixedStartValue(timeInStateVar, DAE.RCONST(0));
  timeInStateExp := DAE.CREF(timeInStateRef, DAE.T_REAL_DEFAULT);

  DAE.VAR(componentRef=timeEnteredStateRef, ty=ty) := timeEnteredStateVar;
  timeEnteredStateExp := DAE.CREF(timeEnteredStateRef, ty);

  stateActiveExp := Expression.crefExp(stateActiveRef);

  // == $timeInState = if active then sample(time) - $timeEnteredState else 0; ==
  // active
  expCond := Expression.crefExp(stateActiveRef);
  // sample(time)
  expSampleTime := DAE.CALL(Absyn.IDENT("sample"),
    { DAE.CREF(DAE.CREF_IDENT("time", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT),
      DAE.CLKCONST(DAE.INFERRED_CLOCK())},
    DAE.callAttrBuiltinImpureReal);
  // sample(time) - $timeEnteredState
  expThen := DAE.BINARY(expSampleTime, DAE.SUB(DAE.T_REAL_DEFAULT), timeEnteredStateExp);
  // 0
  expElse := DAE.RCONST(0);
  // $timeInState = if active then sample(time) - $timeEnteredState else 0;
  timeInStateEqn := DAE.EQUATION(timeInStateExp, DAE.IFEXP(expCond, expThen, expElse), DAE.emptyElementSource);
end createTimeInStateIndicator;

protected function createTimeEnteredStateIndicator "
Author: BTH
Helper function to addPropagationEquations.
Create auxiliary variable that remembers the time in which a state is entered"
  input DAE.ComponentRef stateRef "cref of state to which timeEnteredState variable shall be added";
  input DAE.ComponentRef stateActiveRef "cref of active indicator corresponding to stateRef";
  output DAE.Element timeEnteredStateVar;
  output DAE.Element timeEnteredStateEqn;
protected
  DAE.ComponentRef timeEnteredStateRef;
  DAE.Exp timeEnteredStateExp, stateActiveExp, expCond, expThen, expElse;
algorithm
  // Create Variable stateRef.$timeEnteredState
  timeEnteredStateRef := qCref("$timeEnteredState", DAE.T_REAL_DEFAULT, {}, stateRef);
  timeEnteredStateVar := createVarWithDefaults(timeEnteredStateRef, DAE.DISCRETE(), DAE.T_REAL_DEFAULT, {});
  timeEnteredStateVar := setVarFixedStartValue(timeEnteredStateVar, DAE.RCONST(0));
  timeEnteredStateExp := DAE.CREF(timeEnteredStateRef, DAE.T_REAL_DEFAULT);

  stateActiveExp := Expression.crefExp(stateActiveRef);

  // == $timeEnteredState = if previous(active) == false and active == true then sample(time) else previous($timeEnteredState); ==
  // previous(active) == false and active == true
  expCond := DAE.LBINARY(
    DAE.RELATION( DAE.CALL(Absyn.IDENT("previous"), {stateActiveExp}, DAE.callAttrBuiltinImpureBool), DAE.EQUAL(DAE.T_BOOL_DEFAULT), DAE.BCONST(false), -1, NONE()), // previous(active) == false
    DAE.AND(DAE.T_BOOL_DEFAULT), // and
    DAE.RELATION( stateActiveExp, DAE.EQUAL(DAE.T_BOOL_DEFAULT), DAE.BCONST(true), -1, NONE()) // active == true
    );
  // sample(time)
  expThen := DAE.CALL(Absyn.IDENT("sample"),
    { DAE.CREF(DAE.CREF_IDENT("time", DAE.T_REAL_DEFAULT, {}), DAE.T_REAL_DEFAULT),
      DAE.CLKCONST(DAE.INFERRED_CLOCK())},
    DAE.callAttrBuiltinImpureReal);
  // previous($timeEnteredState)
  expElse := DAE.CALL(Absyn.IDENT("previous"), {timeEnteredStateExp}, DAE.callAttrBuiltinImpureReal);
  // $timeEnteredState = if previous(active) == false and active == true then sample(time) else previous($timeEnteredState);
  timeEnteredStateEqn := DAE.EQUATION(timeEnteredStateExp, DAE.IFEXP(expCond, expThen, expElse), DAE.emptyElementSource);
end createTimeEnteredStateIndicator;

protected function createTicksInStateIndicator "
Author: BTH
Helper function to addPropagationEquations.
Create variable that counts ticks within a state"
  input DAE.ComponentRef stateRef "cref of state to which ticksInState counter shall be added";
  input DAE.ComponentRef stateActiveRef "cref of active indicator corresponding to stateRef";
  output DAE.Element ticksInStateVar;
  output DAE.Element ticksInStateEqn;
protected
  DAE.ComponentRef ticksInStateRef;
  DAE.Exp ticksInStateExp, expCond, expThen, expElse;
algorithm
  // Create Variable stateRef.$ticksInState
  ticksInStateRef := qCref("$ticksInState", DAE.T_INTEGER_DEFAULT, {}, stateRef);
  ticksInStateVar := createVarWithDefaults(ticksInStateRef, DAE.DISCRETE(), DAE.T_INTEGER_DEFAULT, {});
  ticksInStateVar := setVarFixedStartValue(ticksInStateVar, DAE.ICONST(0));

  // $ticksInState = if active then previous($ticksInState) + 1 else 0;
  ticksInStateExp := DAE.CREF(ticksInStateRef, DAE.T_INTEGER_DEFAULT);
  expCond := Expression.crefExp(stateActiveRef);
  // previous($ticksInState) + 1
  expThen := DAE.BINARY(DAE.CALL(Absyn.IDENT("previous"), {ticksInStateExp}, DAE.callAttrBuiltinImpureInteger), DAE.ADD(DAE.T_INTEGER_DEFAULT), DAE.ICONST(1));
  expElse := DAE.ICONST(0);
  ticksInStateEqn := DAE.EQUATION(ticksInStateExp, DAE.IFEXP(expCond, expThen, expElse), DAE.emptyElementSource);
end createTicksInStateIndicator;

protected function createActiveIndicator "
Author: BTH
Helper function to addPropagationEquations.
Create indication (e.g., for plotting) whether a state is active or not"
  input DAE.ComponentRef stateRef "cref of state to which activation indication shall be added";
  input DAE.ComponentRef preRef "cref of prefix where variables of governing semantic equations for stateRef are located";
  input Integer i "index of state within flat state machine state array";
  output DAE.Element activePlotIndicatorVar;
  output DAE.Element eqn;
protected
  DAE.ComponentRef activeRef, activePlotIndicatorRef, activeStateRef;
  DAE.Exp  andExp, eqExp;
algorithm
  // Create Variable stateRef.active
  // FIXME Use name that cannot possible conflict with user variable (or is .active reserved for state machines?)
  activePlotIndicatorRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, stateRef);
  activePlotIndicatorVar := createVarWithStartValue(activePlotIndicatorRef, DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, DAE.BCONST(false), {});

  // stateRef.active := SMS_PRE.initialState.active and (SMS_PRE.initialState.activeState==i)
  activeRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, preRef);
  activeStateRef :=  qCref("activeState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  // SMS_PRE.initialState.activeState==i
  eqExp := DAE.RELATION(DAE.CREF(activeStateRef, DAE.T_INTEGER_DEFAULT), DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(i),-1, NONE());
  // SMS_PRE.initialState.active and (SMS_PRE.initialState.activeState==i)
  andExp := DAE.LBINARY(DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT), DAE.AND(DAE.T_BOOL_DEFAULT), eqExp);
  eqn := DAE.EQUATION(DAE.CREF(activePlotIndicatorRef, DAE.T_BOOL_DEFAULT), andExp, DAE.emptyElementSource);
end createActiveIndicator;


protected function setVarFixedStartValue "
Author: BTH
Set a fixed start value to a variable
"
  input DAE.Element inVar;
  input DAE.Exp inExp;
  output DAE.Element outVar;
protected
  Option<DAE.VariableAttributes> vao;
algorithm
  DAE.VAR(variableAttributesOption=vao) := inVar;
  vao := DAEUtil.setStartAttrOption(vao, SOME(inExp));
  vao := DAEUtil.setFixedAttr(vao, SOME(DAE.BCONST(true)));
  outVar := DAEUtil.setVariableAttributes(inVar, vao);
end setVarFixedStartValue;

protected function basicFlatSmSemantics "
Author: BTH
Helper function to flatSmToDataFlow.
Create variables/parameters and equations for defining the state machine semantic (SMS) equations.
"
  input DAE.Ident ident;
  input list<DAE.Element> q "state components";
  input list<DAE.Element> inTransitions;
  output FlatSmSemantics flatSmSemantics;
protected
  DAE.ComponentRef crefInitialState, preRef;

  // Modeling variables and parameters/constants
  DAE.Element defaultIntVar, defaultBoolVar;
  list<DAE.Element> vars "SMS veriables", knowns "SMS constants/parameters";
  Integer i;

  DAE.ComponentRef preRef, cref, nStatesRef, activeRef, resetRef, selectedStateRef, selectedResetRef, firedRef, activeStateRef, activeResetRef, nextStateRef, nextResetRef, stateMachineInFinalStateRef;
  DAE.Element var, nStatesVar, activeVar, resetVar, selectedStateVar, selectedResetVar, firedVar, activeStateVar, activeResetVar, nextStateVar, nextResetVar, stateMachineInFinalStateVar;

  // Modeling arrays with size nStates
  Integer nStates;
  DAE.InstDims nStatesDims;
  DAE.Type nStatesArrayBool;
  array<DAE.ComponentRef> activeResetStatesRefs, nextResetStatesRefs, finalStatesRefs;
  array<DAE.Element> activeResetStatesVars, nextResetStatesVars, finalStatesVars;

  // Modeling Transitions "t":
  list<Transition> t;
  Integer nTransitions;
  DAE.InstDims tDims;
  DAE.Type tArrayInteger, tArrayBool;
  array<DAE.ComponentRef> tFromRefs, tToRefs, tImmediateRefs, tResetRefs, tSynchronizeRefs, tPriorityRefs;
  array<DAE.Element> tFromVars, tToVars, tImmediateVars, tResetVars, tSynchronizeVars, tPriorityVars;
  // TRANSITION
  Integer from;
  Integer to;
  DAE.Exp condition;
  Boolean immediate;
  Boolean reset;
  Boolean synchronize;
  Integer priority;

  // Modeling Conditions "c":
  list<DAE.Exp> cExps;
  array<DAE.ComponentRef> cRefs, cImmediateRefs;
  array<DAE.Element> cVars, cImmediateVars;

  // Modeling Equations
  list<DAE.Element> eqs "SMS equations";
  DAE.Element selectedStateEqn, selectedResetEqn, firedEqn, activeStateEqn, activeResetEqn, nextStateEqn, nextResetEqn;
  DAE.Exp exp, rhs, expCond, expThen, expElse, exp1, exp2, expIf;
  list<DAE.Exp> expLst;
  Option<DAE.Exp> bindExp;


algorithm
  // make sure that created vars won't clutter up the variable space
  DAE.SM_COMP(componentRef=crefInitialState) := listHead(q);
  preRef := ComponentReference.crefPrefixString(SMS_PRE, crefInitialState);

  (t, cExps) := createTandC(q, inTransitions);
  // print("StateMachineFlatten.basicFlatSmSemantics: transitions:\n\t" + stringDelimitList(List.map(t, dumpTransitionStr), "\n\t") + "\n");
  // print("StateMachineFlatten.basicFlatSmSemantics: conditions\n\t" + stringDelimitList(List.map(cExps, ExpressionDump.printExpStr), "\n\t") + "\n");

  defaultIntVar := createVarWithDefaults(ComponentReference.makeDummyCref(), DAE.DISCRETE(), DAE.T_INTEGER_DEFAULT, {});
  defaultBoolVar := createVarWithDefaults(ComponentReference.makeDummyCref(), DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, {});
  knowns := {};
  vars := {};

  // ***** Create new variable declarations needed for semantic equations *****
  nStates := listLength(q);
  nStatesRef := qCref("nState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  nStatesVar := createVarWithDefaults(nStatesRef, DAE.PARAM(), DAE.T_INTEGER_DEFAULT, {});
  nStatesVar := DAEUtil.setElementVarBinding(nStatesVar, SOME(DAE.ICONST(nStates)));
  knowns := nStatesVar :: knowns;

  // parameter Transition t[:] "Array of transition data sorted in priority";
  nTransitions := listLength(t);
  tDims := {DAE.DIM_INTEGER(nTransitions)};
  tArrayInteger := DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,tDims, DAE.emptyTypeSource);
  tArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,tDims, DAE.emptyTypeSource);
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
    TRANSITION(from,to,_,immediate,reset,synchronize,priority) := t1;
    tFromRefs := arrayUpdate(tFromRefs, i, qCref("tFrom", tArrayInteger, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tFromVars := arrayUpdate(tFromVars, i, createVarWithDefaults(arrayGet(tFromRefs,i), DAE.PARAM(), DAE.T_INTEGER_DEFAULT, tDims));
    tFromVars := arrayUpdate(tFromVars, i, DAEUtil.setElementVarBinding(arrayGet(tFromVars,i), SOME(DAE.ICONST(from))));
    knowns := arrayGet(tFromVars,i) :: knowns;

    tToRefs := arrayUpdate(tToRefs, i, qCref("tTo", tArrayInteger, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tToVars := arrayUpdate(tToVars, i, createVarWithDefaults(arrayGet(tToRefs,i), DAE.PARAM(), DAE.T_INTEGER_DEFAULT, tDims));
    tToVars := arrayUpdate(tToVars, i, DAEUtil.setElementVarBinding(arrayGet(tToVars,i), SOME(DAE.ICONST(to))));
    knowns := arrayGet(tToVars,i) :: knowns;

    tImmediateRefs := arrayUpdate(tImmediateRefs, i, qCref("tImmediate", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tImmediateVars := arrayUpdate(tImmediateVars, i, createVarWithDefaults(arrayGet(tImmediateRefs,i), DAE.PARAM(), DAE.T_BOOL_DEFAULT, tDims));
    tImmediateVars := arrayUpdate(tImmediateVars, i, DAEUtil.setElementVarBinding(arrayGet(tImmediateVars,i), SOME(DAE.BCONST(immediate))));
    knowns := arrayGet(tImmediateVars,i) :: knowns;

    tResetRefs := arrayUpdate(tResetRefs, i, qCref("tReset", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tResetVars := arrayUpdate(tResetVars, i, createVarWithDefaults(arrayGet(tResetRefs,i), DAE.PARAM(), DAE.T_BOOL_DEFAULT, tDims));
    tResetVars := arrayUpdate(tResetVars, i, DAEUtil.setElementVarBinding(arrayGet(tResetVars,i), SOME(DAE.BCONST(reset))));
    knowns := arrayGet(tResetVars,i) :: knowns;

    tSynchronizeRefs := arrayUpdate(tSynchronizeRefs, i, qCref("tSynchronize", tArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tSynchronizeVars := arrayUpdate(tSynchronizeVars, i, createVarWithDefaults(arrayGet(tSynchronizeRefs,i), DAE.PARAM(), DAE.T_BOOL_DEFAULT, tDims));
    tSynchronizeVars := arrayUpdate(tSynchronizeVars, i, DAEUtil.setElementVarBinding(arrayGet(tSynchronizeVars,i), SOME(DAE.BCONST(synchronize))));
    knowns := arrayGet(tSynchronizeVars,i) :: knowns;

    tPriorityRefs := arrayUpdate(tPriorityRefs, i, qCref("tPriority", tArrayInteger, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    tPriorityVars := arrayUpdate(tPriorityVars, i, createVarWithDefaults(arrayGet(tPriorityRefs,i), DAE.PARAM(), DAE.T_INTEGER_DEFAULT, tDims));
    tPriorityVars := arrayUpdate(tPriorityVars, i, DAEUtil.setElementVarBinding(arrayGet(tPriorityVars,i), SOME(DAE.ICONST(priority))));
    knowns := arrayGet(tPriorityVars,i) :: knowns;
  end for;

  // input Boolean c[size(t,1)] "Transition conditions sorted in priority";
  // input Boolean cImmediate[size(t,1)];
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
    cVars := arrayUpdate(cVars, i, createVarWithDefaults(arrayGet(cRefs,i), DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, tDims));
    cImmediateVars := arrayUpdate(cImmediateVars, i, createVarWithStartValue(arrayGet(cImmediateRefs,i), DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, DAE.BCONST(false), tDims));
    // TODO Binding probably needs to be turned into a proper equation. Done below
    // cVars := arrayUpdate(cVars, i, BackendVariable.setBindExp(arrayGet(cVars,i), SOME(exp)));
    vars := arrayGet(cVars, i) :: vars;
    vars := arrayGet(cImmediateVars, i) :: vars;
  end for;
  //input Boolean active "true if the state machine is active";
  activeRef := qCref("active", DAE.T_BOOL_DEFAULT, {}, preRef);
  activeVar := createVarWithDefaults(activeRef, DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, {});
  vars := activeVar :: vars;
  //input Boolean reset "true when the state machine should be reset";
  resetRef := qCref("reset", DAE.T_BOOL_DEFAULT, {}, preRef);
  resetVar := createVarWithDefaults(resetRef, DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, {});
  vars := resetVar :: vars;
  //Integer selectedState
  selectedStateRef := qCref("selectedState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  selectedStateVar := createVarWithDefaults(selectedStateRef, DAE.DISCRETE(), DAE.T_INTEGER_DEFAULT, {});
  vars := selectedStateVar :: vars;
  //Boolean selectedReset
  selectedResetRef := qCref("selectedReset", DAE.T_BOOL_DEFAULT, {}, preRef);
  selectedResetVar := createVarWithDefaults(selectedResetRef, DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, {});
  vars := selectedResetVar :: vars;
  // Integer fired
  firedRef := qCref("fired", DAE.T_INTEGER_DEFAULT, {}, preRef);
  firedVar := createVarWithDefaults(firedRef, DAE.DISCRETE(), DAE.T_INTEGER_DEFAULT, {});
  vars := firedVar :: vars;
  // output Integer activeState
  activeStateRef := qCref("activeState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  activeStateVar := createVarWithDefaults(activeStateRef, DAE.DISCRETE(), DAE.T_INTEGER_DEFAULT, {});
  vars := activeStateVar :: vars;
  // output Boolean activeReset
  activeResetRef := qCref("activeReset", DAE.T_BOOL_DEFAULT, {}, preRef);
  activeResetVar := createVarWithDefaults(activeResetRef, DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, {});
  vars := activeResetVar :: vars;
  // Integer nextState
  nextStateRef := qCref("nextState", DAE.T_INTEGER_DEFAULT, {}, preRef);
  nextStateVar := createVarWithStartValue(nextStateRef, DAE.DISCRETE(), DAE.T_INTEGER_DEFAULT, DAE.ICONST(0), {}); // is state -> start value, but value not specified in spec
  vars := nextStateVar :: vars;
  // Boolean nextReset
  nextResetRef := qCref("nextReset", DAE.T_BOOL_DEFAULT, {}, preRef);
  nextResetVar := createVarWithStartValue(nextResetRef, DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, DAE.BCONST(false), {}); // is state -> start value, but not value specified in spec
  vars := nextResetVar :: vars;
  // ***** arrays with size nStates *****
  nStatesDims := {DAE.DIM_INTEGER(nStates)};
  nStatesArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,nStatesDims, DAE.emptyTypeSource);
  //output Boolean activeResetStates[nStates]
  activeResetStatesRefs := arrayCreate(nStates, ComponentReference.makeDummyCref());
  activeResetStatesVars := arrayCreate(nStates, defaultBoolVar);
  for i in 1:nStates loop
    activeResetStatesRefs := arrayUpdate(activeResetStatesRefs, i, qCref("activeResetStates", nStatesArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    activeResetStatesVars := arrayUpdate(activeResetStatesVars, i, createVarWithDefaults(arrayGet(activeResetStatesRefs,i), DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, nStatesDims));
    vars := arrayGet(activeResetStatesVars, i) :: vars;
  end for;
  // Boolean nextResetStates[nStates]
  nextResetStatesRefs := arrayCreate(nStates, ComponentReference.makeDummyCref());
  nextResetStatesVars := arrayCreate(nStates, defaultBoolVar);
  for i in 1:nStates loop
    nextResetStatesRefs := arrayUpdate(nextResetStatesRefs, i, qCref("nextResetStates", nStatesArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    nextResetStatesVars := arrayUpdate(nextResetStatesVars, i, createVarWithStartValue(arrayGet(nextResetStatesRefs,i), DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, DAE.BCONST(false), nStatesDims));
    vars := arrayGet(nextResetStatesVars, i) :: vars;
  end for;
  // Boolean finalStates[nStates]
  finalStatesRefs := arrayCreate(nStates, ComponentReference.makeDummyCref());
  finalStatesVars := arrayCreate(nStates, defaultBoolVar);
  for i in 1:nStates loop
    finalStatesRefs := arrayUpdate(finalStatesRefs, i, qCref("finalStates", nStatesArrayBool, {DAE.INDEX(DAE.ICONST(i))}, preRef));
    finalStatesVars := arrayUpdate(finalStatesVars, i, createVarWithDefaults(arrayGet(finalStatesRefs,i), DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, nStatesDims));
    vars := arrayGet(finalStatesVars, i) :: vars;
  end for;
  // Boolean stateMachineInFinalState
  stateMachineInFinalStateRef := qCref("stateMachineInFinalState", DAE.T_BOOL_DEFAULT, {}, preRef);
  stateMachineInFinalStateVar := createVarWithDefaults(stateMachineInFinalStateRef, DAE.DISCRETE(), DAE.T_BOOL_DEFAULT, {});
  vars := stateMachineInFinalStateVar :: vars;

  // ***** Create new governing equations *****
  eqs := {};

  //input Boolean c[size(t,1)] "Transition conditions sorted in priority";
  // Delayed transitions are realized by "c[i] = previous(cImmediate[i])"
  i := 0;
  for cExp in cExps loop
    i := i+1;
    exp := DAE.CREF(arrayGet(cImmediateRefs,i), DAE.T_BOOL_DEFAULT);
    eqs := DAE.EQUATION(exp, cExp, DAE.emptyElementSource) :: eqs;
    exp1 := DAE.CREF(arrayGet(cRefs,i), DAE.T_BOOL_DEFAULT);
    DAE.VAR(binding=bindExp) := arrayGet(tImmediateVars,i);
    // Check whether it is an immediate or an delayed transition
    rhs := if Util.applyOptionOrDefault(bindExp, function Expression.expEqual(inExp1=DAE.BCONST(true)), false) then
      // immediate transition
      exp else
      // delayed transition
      DAE.CALL(Absyn.IDENT("previous"), {exp}, DAE.callAttrBuiltinImpureBool);
    eqs := DAE.EQUATION(exp1, rhs, DAE.emptyElementSource) :: eqs;
  end for;

  // Integer selectedState = if reset then 1 else previous(nextState);
  exp := DAE.CREF(selectedStateRef, DAE.T_INTEGER_DEFAULT);
  expCond := DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.ICONST(1);
  expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(nextStateRef, DAE.T_INTEGER_DEFAULT)}, DAE.callAttrBuiltinImpureInteger);
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  selectedStateEqn := DAE.EQUATION(exp, rhs, DAE.emptyElementSource);
  eqs := selectedStateEqn :: eqs;

  // Boolean selectedReset = if reset then true else previous(nextReset);
  exp := DAE.CREF(selectedResetRef, DAE.T_BOOL_DEFAULT);
  expCond := DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.BCONST(true);
  expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(nextResetRef, DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  selectedResetEqn := DAE.EQUATION(exp, rhs, DAE.emptyElementSource);
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
  rhs := if listLength(expLst) > 1 then DAE.CALL(Absyn.IDENT("max"), {Expression.makeScalarArray(expLst, DAE.T_INTEGER_DEFAULT)}, DAE.callAttrBuiltinInteger)
    else listHead(expLst); // runtime can't handle 'max({x})'. Hence, replace 'max({x})' by 'x'.
  firedEqn := DAE.EQUATION(exp, rhs, DAE.emptyElementSource);
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
  activeStateEqn := DAE.EQUATION(exp, rhs, DAE.emptyElementSource);
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
  activeResetEqn := DAE.EQUATION(exp, rhs, DAE.emptyElementSource);
  eqs := activeResetEqn :: eqs;

  // Integer nextState = if active then activeState else previous(nextState);
  exp := DAE.CREF(nextStateRef, DAE.T_INTEGER_DEFAULT);
  expCond := DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.CREF(activeStateRef, DAE.T_INTEGER_DEFAULT);
  expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(nextStateRef, DAE.T_INTEGER_DEFAULT)}, DAE.callAttrBuiltinImpureInteger);
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  nextStateEqn := DAE.EQUATION(exp, rhs, DAE.emptyElementSource);
  eqs := nextStateEqn :: eqs;

  // Boolean nextReset = if active then false else previous(nextReset);
  exp := DAE.CREF(nextResetRef, DAE.T_BOOL_DEFAULT);
  expCond := DAE.CREF(activeRef, DAE.T_BOOL_DEFAULT);
  expThen := DAE.BCONST(false);
  expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(nextResetRef, DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
  rhs := DAE.IFEXP(expCond, expThen, expElse);
  nextResetEqn := DAE.EQUATION(exp, rhs, DAE.emptyElementSource);
  eqs := nextResetEqn :: eqs;

  // output Boolean activeResetStates[nStates] = {if reset then true else previous(nextResetStates[i]) for i in 1:nStates};
  for i in 1:nStates loop
    exp := DAE.CREF(arrayGet(activeResetStatesRefs,i), DAE.T_BOOL_DEFAULT);
    expCond := DAE.CREF(resetRef, DAE.T_BOOL_DEFAULT);
    expThen := DAE.BCONST(true);
    expElse := DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(arrayGet(nextResetStatesRefs,i), DAE.T_BOOL_DEFAULT)}, DAE.callAttrBuiltinImpureBool);
    rhs := DAE.IFEXP(expCond, expThen, expElse);
    eqs := DAE.EQUATION(exp, rhs, DAE.emptyElementSource) :: eqs;
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
    eqs := DAE.EQUATION(exp, rhs, DAE.emptyElementSource) :: eqs;
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
    exp1 := if listLength(expLst) > 1 then DAE.CALL(Absyn.IDENT("max"), {Expression.makeScalarArray(expLst, DAE.T_INTEGER_DEFAULT)}, DAE.callAttrBuiltinInteger)
      else listHead(expLst); // runtime can't handle 'max({x})'. Hence, replace 'max({x})' by 'x'.
    // max(if t[j].from == i then 1 else 0 for j in 1:size(t,1)) == 0
    rhs := DAE.RELATION(exp1, DAE.EQUAL(DAE.T_INTEGER_DEFAULT), DAE.ICONST(0),-1, NONE());
    eqs := DAE.EQUATION(exp, rhs, DAE.emptyElementSource) :: eqs;
  end for;

  // Boolean stateMachineInFinalState = finalStates[activeState];
  exp := DAE.CREF(stateMachineInFinalStateRef, DAE.T_BOOL_DEFAULT);
  rhs := DAE.CREF(qCref("finalStates", tArrayBool, {DAE.INDEX(DAE.CREF(activeStateRef,DAE.T_INTEGER_DEFAULT))}, preRef), DAE.T_BOOL_DEFAULT);
  eqs := DAE.EQUATION(exp, rhs, DAE.emptyElementSource) :: eqs;

  // Now return the semantics equations of the flat state machine and associated variables and parameters
  flatSmSemantics := FLAT_SM_SEMANTICS(ident, listArray(q), t, cExps, vars, knowns, eqs, {}, {}, NONE());
end basicFlatSmSemantics;

protected function qCref "
Author: BTH
Helper function to basicFlatSmSemantics"
  input DAE.Ident ident;
  input DAE.Type identType "type of the identifier, without considering the subscripts";
  input list<DAE.Subscript> subscriptLst;
  input DAE.ComponentRef componentRef;
  output DAE.ComponentRef outQual;
algorithm
  outQual := ComponentReference.joinCrefs(componentRef,DAE.CREF_IDENT(ident,identType,subscriptLst));
end qCref;

protected function createVarWithDefaults "
Author: BTH
Create a DAE.VAR with some defaults"
  input DAE.ComponentRef componentRef;
  input DAE.VarKind kind;
  input DAE.Type ty;
  input DAE.InstDims dims;
  output DAE.Element var;
algorithm
  var := DAE.VAR(componentRef, kind, DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.PUBLIC(), ty, NONE(), dims,
    DAE.NON_CONNECTOR(), DAE.emptyElementSource, NONE() /* VariableAttributes */, NONE(), Absyn.NOT_INNER_OUTER());
end createVarWithDefaults;

protected function createVarWithStartValue "
Author: BTH
Create a DAE.VAR with fixed start value and some defaults"
  input DAE.ComponentRef componentRef;
  input DAE.VarKind kind;
  input DAE.Type ty;
  input DAE.Exp startExp;
  input DAE.InstDims dims;
  output DAE.Element outVar;
protected
  DAE.Element var;
algorithm
  var := DAE.VAR(componentRef, kind, DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.PUBLIC(), ty, NONE(), dims,
    DAE.NON_CONNECTOR(), DAE.emptyElementSource, NONE() /* VariableAttributes */, NONE(), Absyn.NOT_INNER_OUTER());
  outVar := setVarFixedStartValue(var, startExp);
end createVarWithStartValue;

protected function createTandC "
Author: BTH
Helper function to basicFlatSmSemantics"
  input list<DAE.Element> inSMComps;
  input list<DAE.Element> inTransitions;
  output list<Transition> t;
  output list<DAE.Exp> c;
protected
  list<Transition> transitions;
algorithm
  transitions := List.map1(inTransitions, createTransition, inSMComps);
  //print("\nStateMachineFlatten.createTandC: UNSORTED:\n"+ stringDelimitList(List.map(transitions,dumpTransitionStr), "\n"));

  // sort transtion according to priority
  t := List.sort(transitions, priorityLt);
  //print("\nStateMachineFlatten.createTandC: SORTED:\n"+ stringDelimitList(List.map(t,dumpTransitionStr), "\n"));

  // TODO Check that if several transitions could fire from the same state, all transitions have different priorities

  // extract condtions from ordered transitions
  c := List.map(t, extractCondtionFromTransition);
end createTandC;

protected function extractCondtionFromTransition
  input Transition trans;
  output DAE.Exp condition;
algorithm
  TRANSITION(condition=condition) := trans;
end extractCondtionFromTransition;

protected function priorityLt "
Compare priority of transitions
"
    input Transition inTrans1;
    input Transition inTrans2;
    output Boolean res;
protected
  Integer priority1, priority2;
algorithm
  TRANSITION(priority=priority1) := inTrans1;
  TRANSITION(priority=priority2) := inTrans2;
  res := intLt(priority1, priority2);
end priorityLt;

protected function createTransition "
Author: BTH
Helper function to flatSmToDataFlow
"
  input DAE.Element transitionElem;
  input list<DAE.Element> states;
  output Transition trans;
protected
  DAE.ComponentRef crefFrom, crefTo;
  // Transition
  Integer from;
  Integer to;
  DAE.Exp condition;
  Boolean immediate = true;
  Boolean reset = true;
  Boolean synchronize = false;
  Integer priority = 1;
algorithm

DAE.NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("transition"),
      expLst=DAE.CREF(componentRef=crefFrom)::DAE.CREF(componentRef=crefTo)::condition::
      DAE.BCONST(immediate) :: DAE.BCONST(reset) :: DAE.BCONST(synchronize)
      :: DAE.ICONST(priority)::{})) := transitionElem;

from :=  List.position1OnTrue(states, sMCompEqualsRef, crefFrom);
to :=  List.position1OnTrue(states, sMCompEqualsRef, crefTo);

trans := TRANSITION(from, to, condition, immediate, reset, synchronize, priority);
end createTransition;

protected function isFlatSm "
Author: BTH
Check if element is a FLAT_SM.
"
  input DAE.Element inElement;
  output Boolean outResult;
algorithm
  outResult := match (inElement)
    case DAE.FLAT_SM() then true;
    else false;
  end match;
end isFlatSm;

protected function isSMComp "
Author: BTH
Check if element is a SM_COMP.
"
  input DAE.Element inElement;
  output Boolean outResult;
algorithm
  outResult := match (inElement)
    case DAE.SM_COMP() then true;
    else false;
  end match;
end isSMComp;


protected function isTransition "
Author: BTH
Return true if element is a transition, otherwise false"
  input  DAE.Element inElement;
  output Boolean result;
algorithm
  result := match (inElement)
    local
      DAE.Exp exp;
    case DAE.NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("transition"))) then true;
    else then false;
  end match;
end isTransition;

protected function isInitialState "
Author: BTH
Return true if element is an initialState, otherwise false"
  input  DAE.Element inElement;
  output Boolean result;
algorithm
  result := match (inElement)
    local
      DAE.Exp exp;
    case DAE.NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("initialState"))) then true;
    else then false;
  end match;
end isInitialState;

protected function isEquation "
Author: BTH
Return true if element is an EQUATION, otherwise false"
  input  DAE.Element inElement;
  output Boolean result;
algorithm
  result := match (inElement)
    local
      DAE.Exp exp;
    case DAE.EQUATION() then true;
    else then false;
  end match;
end isEquation;

protected function isVar "
Author: BTH
Return true if element is an VAR, otherwise false"
  input  DAE.Element inElement;
  output Boolean result;
algorithm
  result := match (inElement)
    local
      DAE.Exp exp;
    case DAE.VAR() then true;
    else then false;
  end match;
end isVar;

protected function sMCompEqualsRef "
Author: BTH
Return true if the componentRef of the second argument equals the componentRef of the SMComp (first argument)
"
  input DAE.Element inElement;
  input DAE.ComponentRef inCref;
  output Boolean result;
algorithm
  result := match (inElement)
    local
      DAE.ComponentRef cref;
    case DAE.SM_COMP(cref) guard ComponentReference.crefEqual(cref, inCref) then true;
    else false;
  end match;
end sMCompEqualsRef;

public function dumpTransitionStr "
Author: BTH
Dump transition to string."
  input Transition transition;
  output String transitionStr;
protected
  Integer from;
  Integer to;
  DAE.Exp condition;
  Boolean immediate;
  Boolean reset;
  Boolean synchronize;
  Integer priority;
algorithm
  TRANSITION(from, to, condition, immediate, reset, synchronize, priority) := transition;
  transitionStr := "TRANSITION(from="+intString(from)+", to="+intString(to)+
    ", condition="+ExpressionDump.printExpStr(condition)+
    ", immediate="+boolString(immediate)+", reset="+boolString(reset)+
    ", synchronize="+boolString(synchronize)+", priority="+intString(priority)+")";
end dumpTransitionStr;

protected function wrapHack "
Author: BTH
Wrap equations in when-clauses as long as Synchronous Features are not supported"
  input FCore.Cache cache;
  input list<DAE.Element> inElementLst;
  output list<DAE.Element> outElementLst;
protected
  Integer nOfSubstitutions;
  list<DAE.Element> eqnLst, otherLst;
  DAE.Element whenEq;
  DAE.Exp cond1, cond2, condition;
  DAE.Type tArrayBool;
algorithm

  (eqnLst, otherLst) := List.extractOnTrue(inElementLst, isEquation);

  // == {initial(), sample(DEFAULT_CLOCK_PERIOD, DEFAULT_CLOCK_PERIOD)} ==
  cond1 := DAE.CALL(Absyn.IDENT("initial"),
    {}, DAE.callAttrBuiltinImpureBool);
  cond2 := DAE.CALL(Absyn.IDENT("sample"),
    {DAE.RCONST(Flags.getConfigReal(Flags.DEFAULT_CLOCK_PERIOD)),
     DAE.RCONST(Flags.getConfigReal(Flags.DEFAULT_CLOCK_PERIOD))}, DAE.callAttrBuiltinImpureBool);
  tArrayBool := DAE.T_ARRAY(DAE.T_BOOL_DEFAULT,{DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
  condition := DAE.ARRAY(tArrayBool, true, {cond1, cond2});

  // when {initial(), sample(DEFAULT_CLOCK_PERIOD, DEFAULT_CLOCK_PERIOD)} then .. end when;
  whenEq := DAE.WHEN_EQUATION(condition,
    eqnLst, NONE(), DAE.emptyElementSource);

  outElementLst := listAppend(otherLst, {whenEq});
end wrapHack;


protected function traversingSubsPreForPrevious "
Author: BTH
Helper function to traverse subexpressions
Substitutes 'previous(x)' by 'pre(x)' "
  input DAE.Exp inExp;
  input Integer inHitCount;
  output DAE.Exp outExp;
  output Integer outHitCount;
algorithm
  (outExp,outHitCount) := match inExp
    local
      DAE.ComponentRef componentRef;
      list<DAE.Exp> expLst;
      DAE.CallAttributes attr;
    case DAE.CALL(Absyn.IDENT("previous"), expLst, attr)
      then (DAE.CALL(Absyn.IDENT("pre"), expLst, attr), inHitCount + 1);
    else (inExp,inHitCount);
  end match;
end traversingSubsPreForPrevious;

protected function traversingSubsXForSampleX "
Author: BTH
Helper function to traverse subexpressions
Substitutes 'sample(x, _)' by 'x' "
  input DAE.Exp inExp;
  input Integer inHitCount;
  output DAE.Exp outExp;
  output Integer outHitCount;
algorithm
  (outExp,outHitCount) := match inExp
    local
      DAE.ComponentRef componentRef;
      DAE.Exp expX;
      DAE.CallAttributes attr;
    case DAE.CALL(Absyn.IDENT("sample"),
    { expX,
      DAE.CLKCONST(DAE.INFERRED_CLOCK())},
    attr)
      then (expX, inHitCount + 1);
    else (inExp,inHitCount);
  end match;
end traversingSubsXForSampleX;

 annotation(__OpenModelica_Interface="frontend");
 end StateMachineFlatten;

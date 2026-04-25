/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFStateMachineFlatten
"Transform state machines in the NF FlatModel to flat data-flow equations.
 This is the NF equivalent of StateMachineFlatten.mo, operating on NFFlatModel
 instead of DAE. Implements the transformation described in MLS §17."

import FlatModel = NFFlatModel;
import Equation = NFEquation;
import Expression = NFExpression;
import Type = NFType;
import ComponentRef = NFComponentRef;
import Variable = NFVariable;
import Binding = NFBinding;
import Attributes = NFAttributes;
import Dimension = NFDimension;
import Subscript = NFSubscript;
import Operator = NFOperator;

protected
import AbsynUtil;
import Call = NFCall;
import DAE;
import ElementSource;
import Error;
import ExecStat.execStat;
import Flags;
import List;
import NFBackendExtension;
import NFBuiltinFuncs;
import NFInstNode.InstNode;
import NFPrefixes.{Variability, Purity, Visibility};
import SCode;
import UnorderedMap;
import Util;

// ============================================================
// Internal data types
// ============================================================

protected
uniontype Transition
  record TRANSITION
    Integer from;
    Integer to;
    Expression condition;
    Boolean immediate = true;
    Boolean reset = true;
    Boolean synchronize = false;
    Integer priority = 1;
  end TRANSITION;
end Transition;

protected
uniontype FlatSmSemantics
  record FLAT_SM_SEMANTICS
    ComponentRef initStateRef "Cref of the initial state (used as prefix for smOf vars)";
    array<ComponentRef> smComps "State crefs; index 1 = initial state";
    list<Transition> t "Transitions sorted by priority";
    list<Expression> c "Conditions sorted by priority";
    list<Variable> vars "SMS discrete variables";
    list<Variable> knowns "SMS parameters/constants";
    list<Equation> eqs "SMS equations";
    list<Variable> pvars "Propagation variables";
    list<Equation> peqs "Propagation equations";
    Option<ComponentRef> enclosingState "Enclosing state if hierarchical SM";
  end FLAT_SM_SEMANTICS;
end FlatSmSemantics;

constant String SMS_PRE = "smOf";

// ============================================================
// Public entry point
// ============================================================

public
function flatten
  "Main entry point. Transforms state machine NORETCALL equations to flat data-flow equations."
  input output FlatModel flatModel;
protected
  list<ComponentRef> initStates;
  list<list<ComponentRef>> smGroups;
  list<Equation> smEqs, otherEqs, resultEqs;
  list<Variable> smVars, resultVars;
  Integer nSubstitutions;
algorithm
  // Quick exit if no state machines present
  // initialState() lives in initialEquations; transition() in equations
  if not List.any(flatModel.equations, isTransitionOrInitialState) and
     not List.any(flatModel.initialEquations, isTransitionOrInitialState) then
    return;
  end if;

  // Partition: initialState() from initialEquations, transition() from equations
  (initStates, smGroups) := groupStateMachines(flatModel.equations, flatModel.initialEquations);

  if listEmpty(initStates) then
    return;
  end if;

  // Remove SM equations from both equation sections
  otherEqs := List.filterOnFalse(flatModel.equations, isTransitionOrInitialState);

  smVars := {};
  smEqs := {};
  for i in 1:listLength(initStates) loop
    (smEqs, smVars) := flatSmToDataFlow(
      listGet(initStates, i),
      listGet(smGroups, i),
      flatModel.equations,
      flatModel.variables,
      NONE(), NONE(),
      smEqs, smVars);
  end for;

  // Substitute activeState(x) → x.active globally; SM eqs come after
  resultEqs := listAppend(smEqs, list(subsActiveStateInEq(eq) for eq in otherEqs));
  resultVars := listAppend(smVars, flatModel.variables);

  flatModel.equations := resultEqs;
  // Remove initialState() from initialEquations; transition() already removed above
  flatModel.initialEquations := List.filterOnFalse(flatModel.initialEquations, isTransitionOrInitialState);
  flatModel.variables := resultVars;

  execStat(getInstanceName());
end flatten;

// ============================================================
// SM group detection
// ============================================================

protected
function groupStateMachines
  "Extract flat state machine groups from the equation lists.
   transition() calls come from equations; initialState() from initialEquations.
   Returns parallel lists: one initial-state cref per SM group,
   and one list of all state crefs per SM group."
  input list<Equation> equations;
  input list<Equation> initialEquations;
  output list<ComponentRef> initStates = {};
  output list<list<ComponentRef>> smGroups = {};
protected
  list<ComponentRef> allFroms = {}, allTos = {}, allInits = {};
  ComponentRef cr1, cr2;
  list<list<ComponentRef>> groups = {};
  list<ComponentRef> group;
algorithm
  // Collect transition() and initialState() from both equation sections
  for eq in listAppend(equations, initialEquations) loop
    () := match eq
      local
        Call eqCall;
        String fname;
      case Equation.NORETCALL(exp = Expression.CALL(call = eqCall))
        algorithm
          fname := Call.functionNameLast(eqCall);
          if stringEq(fname, "transition") then
            {Expression.CREF(cref = cr1), Expression.CREF(cref = cr2)} :=
              List.firstN(Call.arguments(eqCall), 2);
            allFroms := cr1 :: allFroms;
            allTos := cr2 :: allTos;
          elseif stringEq(fname, "initialState") then
            {Expression.CREF(cref = cr1)} := List.firstN(Call.arguments(eqCall), 1);
            allInits := cr1 :: allInits;
          end if;
        then ();
      else ();
    end match;
  end for;

  // Group states by connectivity (each initialState defines one flat SM)
  // Simple approach: each initialState is the root of one flat SM,
  // containing all states reachable via transitions
  for initCref in allInits loop
    group := collectReachableStates(initCref, allFroms, allTos);
    initStates := initCref :: initStates;
    smGroups := group :: smGroups;
  end for;

  initStates := listReverse(initStates);
  smGroups := listReverse(smGroups);
end groupStateMachines;

protected
function collectReachableStates
  "Collect all states reachable from initCref via transitions (BFS)."
  input ComponentRef initCref;
  input list<ComponentRef> froms;
  input list<ComponentRef> tos;
  output list<ComponentRef> states;
protected
  list<ComponentRef> queue = {initCref};
  list<ComponentRef> visited = {};
  ComponentRef cur;
algorithm
  states := {};
  while not listEmpty(queue) loop
    cur :: queue := queue;
    if not List.isMemberOnTrue(cur, visited, ComponentRef.isEqual) then
      visited := cur :: visited;
      states := cur :: states;
      // Find neighbors
      for i in 1:listLength(froms) loop
        if ComponentRef.isEqual(listGet(froms, i), cur) then
          queue := listGet(tos, i) :: queue;
        end if;
        if ComponentRef.isEqual(listGet(tos, i), cur) then
          queue := listGet(froms, i) :: queue;
        end if;
      end for;
    end if;
  end while;
  // Put initial state first.
  // List.sort uses "greater-than" semantics: compare(a,b)=true means b comes before a.
  states := List.sort(states, function statePriorityGt(initCref = initCref));
end collectReachableStates;

protected
function statePriorityGt
  "Sort comparator (greater-than semantics for List.sort) so initCref comes first."
  input ComponentRef cr1;
  input ComponentRef cr2;
  input ComponentRef initCref;
  output Boolean gt;
algorithm
  // compare(a, b) = true  →  b should come before a
  if ComponentRef.isEqual(cr2, initCref) then
    gt := true;   // cr2 is the init state → cr2 should come first → cr1 > cr2
  elseif ComponentRef.isEqual(cr1, initCref) then
    gt := false;  // cr1 is the init state → cr1 should come first → cr1 < cr2 (NOT greater)
  else
    gt := ComponentRef.toString(cr1) > ComponentRef.toString(cr2);
  end if;
end statePriorityGt;

// ============================================================
// Flat SM to data-flow transformation
// ============================================================

protected
function flatSmToDataFlow
  "Transform one flat state machine into data-flow equations and variables."
  input ComponentRef initStateCref;
  input list<ComponentRef> stateCrefs "All state crefs, init state first";
  input list<Equation> allEquations;
  input list<Variable> allVariables;
  input Option<ComponentRef> enclosingStateCrefOpt;
  input Option<FlatSmSemantics> enclosingSmSemOpt;
  input output list<Equation> accEqs;
  input output list<Variable> accVars;
protected
  list<Equation> transitionEqs, initialStateEqs, stateEqs;
  FlatSmSemantics sem, semWithProp, semFinal;
algorithm
  // Extract transition and initialState equations for this SM group
  transitionEqs := List.filterOnTrue(allEquations,
    function isTransitionForGroup(stateCrefs = stateCrefs));
  initialStateEqs := List.filterOnTrue(allEquations,
    function isInitialStateForGroup(initStateCref = initStateCref));

  // Build basic semantics
  sem := basicFlatSmSemantics(initStateCref, stateCrefs, transitionEqs);

  // Add propagation equations
  semWithProp := addPropagationEquations(sem, enclosingStateCrefOpt, enclosingSmSemOpt);

  // Elaborate ticksInState/timeInState operators
  semFinal := elabXInStateOps(semWithProp, enclosingStateCrefOpt);

  // Accumulate SMS variables and equations
  accVars := List.flatten({accVars, semFinal.vars, semFinal.knowns, semFinal.pvars});
  accEqs := List.flatten({accEqs, semFinal.eqs, semFinal.peqs});

  // Transform state component equations
  for stateCref in stateCrefs loop
    (accEqs, accVars) := smCompToDataFlow(stateCref, semFinal, allEquations, allVariables, accEqs, accVars);
  end for;
end flatSmToDataFlow;

// ============================================================
// State machine component to data-flow
// ============================================================

protected
function smCompToDataFlow
  "Transform equations belonging to a state component into conditional data-flow equations."
  input ComponentRef stateCref;
  input FlatSmSemantics sem;
  input list<Equation> allEquations;
  input list<Variable> allVariables;
  input output list<Equation> accEqs;
  input output list<Variable> accVars;
protected
  list<Equation> stateEqs;
  list<Variable> stateVars;
  list<ComponentRef> stateVarCrefs;
  UnorderedMap<ComponentRef, Expression> crToStart;
  list<Equation> transformedEqs;
  list<Variable> extraVars;
algorithm
  // Equations whose LHS cref has stateCref as prefix
  stateEqs := List.filterOnTrue(allEquations,
    function isEquationOfState(stateCref = stateCref));

  // Variables belonging to this state
  stateVars := List.filterOnTrue(allVariables,
    function isVariableOfState(stateCref = stateCref));

  // Build map: stateVar cref → start value
  crToStart := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
  for v in stateVars loop
    UnorderedMap.addUnique(v.name, getStartValue(v), crToStart);
  end for;

  // Transform each equation
  transformedEqs := {};
  extraVars := {};
  for eq in stateEqs loop
    (transformedEqs, extraVars) := addStateActivationAndReset(eq, stateCref, sem, crToStart, transformedEqs, extraVars);
  end for;

  accEqs := listAppend(listReverse(transformedEqs), accEqs);
  accVars := listAppend(listReverse(extraVars), accVars);
end smCompToDataFlow;

// ============================================================
// addStateActivationAndReset
// ============================================================

protected
function addStateActivationAndReset
  "Make equations conditional on state activation; add reset equations for state variables."
  input Equation inEq;
  input ComponentRef stateCref;
  input FlatSmSemantics sem;
  input UnorderedMap<ComponentRef, Expression> crToStart;
  input output list<Equation> accEqs;
  input output list<Variable> accVars;
algorithm
  () := match inEq
    case Equation.EQUALITY()
      algorithm
        (accEqs, accVars) := addStateActivationAndReset1(inEq, stateCref, sem, crToStart, accEqs, accVars);
      then ();

    case Equation.WHEN()
      algorithm
        // Recursively transform equations in WHEN branches
        accEqs := transformWhenBranches(inEq, stateCref, sem, crToStart) :: accEqs;
      then ();

    else
      algorithm
        accEqs := inEq :: accEqs;
      then ();
  end match;
end addStateActivationAndReset;

protected
function transformWhenBranches
  input Equation whenEq;
  input ComponentRef stateCref;
  input FlatSmSemantics sem;
  input UnorderedMap<ComponentRef, Expression> crToStart;
  output Equation outEq;
protected
  list<Equation.Branch> branches, newBranches;
  list<Equation> transformedBody;
  list<Variable> dummyVars;
  InstNode whenScope;
  DAE.ElementSource whenSource;
  Expression branchCond;
  Variability branchCondVar;
  list<Equation> branchBody;
algorithm
  Equation.WHEN(branches = branches, scope = whenScope, source = whenSource) := whenEq;
  newBranches := {};
  for branch in branches loop
    branch := match branch
      case Equation.Branch.BRANCH(condition = branchCond, conditionVar = branchCondVar, body = branchBody)
        algorithm
          transformedBody := {};
          dummyVars := {};
          for eq in branchBody loop
            (transformedBody, dummyVars) := addStateActivationAndReset(eq, stateCref, sem, crToStart, transformedBody, dummyVars);
          end for;
        then Equation.Branch.BRANCH(branchCond, branchCondVar, listReverse(transformedBody));
      else branch;
    end match;
    newBranches := branch :: newBranches;
  end for;
  outEq := Equation.WHEN(listReverse(newBranches), whenScope, whenSource);
end transformWhenBranches;

protected
function addStateActivationAndReset1
  "Transform a simple equation: make conditional on state.active; add reset for state variables."
  input Equation inEq;
  input ComponentRef stateCref;
  input FlatSmSemantics sem;
  input UnorderedMap<ComponentRef, Expression> crToStart;
  input output list<Equation> accEqs;
  input output list<Variable> accVars;
protected
  Expression lhs, rhs;
  ComponentRef lhsCref;
  Type lhsTy;
  InstNode eqScope;
  DAE.ElementSource eqSource;
  list<ComponentRef> stateVarCrefs;
  Boolean hasStateVarOnLHS, hasPreviousOfStateVar;
  Expression newRhs;
  Equation eq1, eq2;
  Variable var2;
algorithm
  Equation.EQUALITY(lhs = lhs, rhs = rhs, ty = lhsTy, scope = eqScope, source = eqSource) := inEq;
  stateVarCrefs := UnorderedMap.keyList(crToStart);

  try
    Expression.CREF(ty = lhsTy, cref = lhsCref) := lhs;

    // Substitute previous(x) → x_previous for state variables in RHS
    (newRhs, _) := Expression.mapFold(rhs,
      function subsPreviousCrefs(stateVarCrefs = stateVarCrefs), false);
    eq1 := Equation.EQUALITY(lhs, newRhs, lhsTy, eqScope, eqSource);

    // If LHS is a state variable (one that has previous(x) applied to it)
    hasStateVarOnLHS := false;
    for svc in stateVarCrefs loop
      hasStateVarOnLHS := ComponentRef.isEqual(svc, lhsCref);
      if hasStateVarOnLHS then
        break;
      end if;
    end for;
    if hasStateVarOnLHS then
      // Transform: x = e → x = if active then e else x_previous
      eq1 := wrapInStateActivationConditional(eq1, stateCref, true);
      // Add reset equation: x_previous = if active and (reset or activeResetStates[i]) then x_start else previous(x)
      eq2 := createResetEquation(lhsCref, lhsTy, stateCref, sem, crToStart);
      // Add fresh variable x_previous
      var2 := makeVar(
        ComponentRef.prefixCref(InstNode.NAME_NODE(ComponentRef.firstName(lhsCref) + "_previous"),
          lhsTy, {}, ComponentRef.rest(lhsCref)),
        lhsTy, Variability.DISCRETE);
      accEqs := eq1 :: eq2 :: accEqs;
      accVars := var2 :: accVars;
    else
      // Not a state variable: just wrap with activation condition
      accEqs := wrapInStateActivationConditional(eq1, stateCref, false) :: accEqs;
    end if;
  else
    // Fallback: pass equation through unchanged
    accEqs := inEq :: accEqs;
  end try;
end addStateActivationAndReset1;

// ============================================================
// basicFlatSmSemantics
// ============================================================

protected
function basicFlatSmSemantics
  "Create variables and equations implementing MLS §17.3.4 state machine semantics."
  input ComponentRef initStateCref;
  input list<ComponentRef> stateCrefs "All states; index 1 = initial state";
  input list<Equation> transitionEqs;
  output FlatSmSemantics sem;
protected
  ComponentRef preRef;
  Integer nStates, nTransitions, i;
  list<Transition> t;
  list<Expression> cExps;
  list<Variable> vars = {}, knowns = {};
  list<Equation> eqs = {};

  // Scalar references for semantic variables
  ComponentRef nStatesRef, activeRef, resetRef, selectedStateRef, selectedResetRef,
    firedRef, activeStateRef, activeResetRef, nextStateRef, nextResetRef,
    stateMachineInFinalStateRef;

  // Array references (sized by nStates)
  Type tArrayBool, tArrayInt;
  list<ComponentRef> activeResetStatesRefs = {}, nextResetStatesRefs = {}, finalStatesRefs = {};
  list<ComponentRef> cRefs = {}, cImmediateRefs = {};

  // Array references (sized by nTransitions)
  Type tTArrayBool, tTArrayInt;
  list<ComponentRef> tFromRefs = {}, tToRefs = {}, tImmediateRefs = {}, tResetRefs = {},
    tSynchronizeRefs = {}, tPriorityRefs = {};

  Expression exp, rhs, expCond, expThen, expElse, exp1, exp2, expIf;
  list<Expression> expLst;
  Option<Expression> bindExp;
  Boolean immediateVal;

  // Dimension objects
  Dimension tDim, nStatesDim;
algorithm
  preRef := makeSMSPrefix(initStateCref);
  (t, cExps) := createTandC(stateCrefs, transitionEqs);

  nStates := listLength(stateCrefs);
  nTransitions := listLength(t);
  tDim := Dimension.INTEGER(nTransitions, Variability.STRUCTURAL_PARAMETER);
  nStatesDim := Dimension.INTEGER(nStates, Variability.STRUCTURAL_PARAMETER);

  tTArrayBool := Type.ARRAY(Type.BOOLEAN(), {tDim});
  tTArrayInt  := Type.ARRAY(Type.INTEGER(), {tDim});
  tArrayBool  := Type.ARRAY(Type.BOOLEAN(), {nStatesDim});
  tArrayInt   := Type.ARRAY(Type.INTEGER(), {nStatesDim});

  // ***** Parameter: nState *****
  nStatesRef := qCref("nState", Type.INTEGER(), {}, preRef);
  knowns := makeVarWithBinding(nStatesRef, Type.INTEGER(), Variability.STRUCTURAL_PARAMETER,
    Expression.INTEGER(nStates)) :: knowns;

  // ***** Transition parameters (tFrom, tTo, tImmediate, tReset, tSynchronize, tPriority) *****
  i := 0;
  for tr in t loop
    i := i + 1;
    tFromRefs := qCref("tFrom", tTArrayInt, {Subscript.INDEX(Expression.INTEGER(i))}, preRef) :: tFromRefs;
    knowns := makeVarWithBinding(listHead(tFromRefs), Type.INTEGER(), Variability.STRUCTURAL_PARAMETER,
      Expression.INTEGER(tr.from)) :: knowns;

    tToRefs := qCref("tTo", tTArrayInt, {Subscript.INDEX(Expression.INTEGER(i))}, preRef) :: tToRefs;
    knowns := makeVarWithBinding(listHead(tToRefs), Type.INTEGER(), Variability.STRUCTURAL_PARAMETER,
      Expression.INTEGER(tr.to)) :: knowns;

    tImmediateRefs := qCref("tImmediate", tTArrayBool, {Subscript.INDEX(Expression.INTEGER(i))}, preRef) :: tImmediateRefs;
    knowns := makeVarWithBinding(listHead(tImmediateRefs), Type.BOOLEAN(), Variability.STRUCTURAL_PARAMETER,
      Expression.BOOLEAN(tr.immediate)) :: knowns;

    tResetRefs := qCref("tReset", tTArrayBool, {Subscript.INDEX(Expression.INTEGER(i))}, preRef) :: tResetRefs;
    knowns := makeVarWithBinding(listHead(tResetRefs), Type.BOOLEAN(), Variability.STRUCTURAL_PARAMETER,
      Expression.BOOLEAN(tr.reset)) :: knowns;

    tSynchronizeRefs := qCref("tSynchronize", tTArrayBool, {Subscript.INDEX(Expression.INTEGER(i))}, preRef) :: tSynchronizeRefs;
    knowns := makeVarWithBinding(listHead(tSynchronizeRefs), Type.BOOLEAN(), Variability.STRUCTURAL_PARAMETER,
      Expression.BOOLEAN(tr.synchronize)) :: knowns;

    tPriorityRefs := qCref("tPriority", tTArrayInt, {Subscript.INDEX(Expression.INTEGER(i))}, preRef) :: tPriorityRefs;
    knowns := makeVarWithBinding(listHead(tPriorityRefs), Type.INTEGER(), Variability.STRUCTURAL_PARAMETER,
      Expression.INTEGER(tr.priority)) :: knowns;
  end for;
  tFromRefs := listReverse(tFromRefs);
  tToRefs := listReverse(tToRefs);
  tImmediateRefs := listReverse(tImmediateRefs);
  tResetRefs := listReverse(tResetRefs);
  tSynchronizeRefs := listReverse(tSynchronizeRefs);
  tPriorityRefs := listReverse(tPriorityRefs);

  // ***** Condition variables c and cImmediate *****
  i := 0;
  for cExp in cExps loop
    i := i + 1;
    cImmediateRefs := qCref("cImmediate", tTArrayBool, {Subscript.INDEX(Expression.INTEGER(i))}, preRef) :: cImmediateRefs;
    cRefs := qCref("c", tTArrayBool, {Subscript.INDEX(Expression.INTEGER(i))}, preRef) :: cRefs;
    vars := makeVarWithStart(listHead(cImmediateRefs), Type.BOOLEAN(), Variability.DISCRETE, Expression.BOOLEAN(false)) :: vars;
    vars := makeVar(listHead(cRefs), Type.BOOLEAN(), Variability.DISCRETE) :: vars;
  end for;
  cImmediateRefs := listReverse(cImmediateRefs);
  cRefs := listReverse(cRefs);

  // ***** Scalar SMS variables *****
  activeRef := qCref("active", Type.BOOLEAN(), {}, preRef);
  vars := makeVar(activeRef, Type.BOOLEAN(), Variability.DISCRETE) :: vars;
  resetRef := qCref("reset", Type.BOOLEAN(), {}, preRef);
  vars := makeVar(resetRef, Type.BOOLEAN(), Variability.DISCRETE) :: vars;
  selectedStateRef := qCref("selectedState", Type.INTEGER(), {}, preRef);
  vars := makeVar(selectedStateRef, Type.INTEGER(), Variability.DISCRETE) :: vars;
  selectedResetRef := qCref("selectedReset", Type.BOOLEAN(), {}, preRef);
  vars := makeVar(selectedResetRef, Type.BOOLEAN(), Variability.DISCRETE) :: vars;
  firedRef := qCref("fired", Type.INTEGER(), {}, preRef);
  vars := makeVar(firedRef, Type.INTEGER(), Variability.DISCRETE) :: vars;
  activeStateRef := qCref("activeState", Type.INTEGER(), {}, preRef);
  vars := makeVar(activeStateRef, Type.INTEGER(), Variability.DISCRETE) :: vars;
  activeResetRef := qCref("activeReset", Type.BOOLEAN(), {}, preRef);
  vars := makeVar(activeResetRef, Type.BOOLEAN(), Variability.DISCRETE) :: vars;
  nextStateRef := qCref("nextState", Type.INTEGER(), {}, preRef);
  vars := makeVarWithStart(nextStateRef, Type.INTEGER(), Variability.DISCRETE, Expression.INTEGER(0)) :: vars;
  nextResetRef := qCref("nextReset", Type.BOOLEAN(), {}, preRef);
  vars := makeVarWithStart(nextResetRef, Type.BOOLEAN(), Variability.DISCRETE, Expression.BOOLEAN(false)) :: vars;

  // ***** Array variables sized by nStates *****
  for j in 1:nStates loop
    activeResetStatesRefs := qCref("activeResetStates", tArrayBool, {Subscript.INDEX(Expression.INTEGER(j))}, preRef) :: activeResetStatesRefs;
    vars := makeVar(listHead(activeResetStatesRefs), Type.BOOLEAN(), Variability.DISCRETE) :: vars;
    nextResetStatesRefs := qCref("nextResetStates", tArrayBool, {Subscript.INDEX(Expression.INTEGER(j))}, preRef) :: nextResetStatesRefs;
    vars := makeVarWithStart(listHead(nextResetStatesRefs), Type.BOOLEAN(), Variability.DISCRETE, Expression.BOOLEAN(false)) :: vars;
    finalStatesRefs := qCref("finalStates", tArrayBool, {Subscript.INDEX(Expression.INTEGER(j))}, preRef) :: finalStatesRefs;
    vars := makeVar(listHead(finalStatesRefs), Type.BOOLEAN(), Variability.DISCRETE) :: vars;
  end for;
  activeResetStatesRefs := listReverse(activeResetStatesRefs);
  nextResetStatesRefs := listReverse(nextResetStatesRefs);
  finalStatesRefs := listReverse(finalStatesRefs);
  stateMachineInFinalStateRef := qCref("stateMachineInFinalState", Type.BOOLEAN(), {}, preRef);
  vars := makeVar(stateMachineInFinalStateRef, Type.BOOLEAN(), Variability.DISCRETE) :: vars;

  // ***** Governing equations *****

  // cImmediate[i] = cExp[i];  c[i] = if immediate then cImmediate[i] else previous(cImmediate[i])
  i := 0;
  for cExp in cExps loop
    i := i + 1;
    eqs := makeEq(makeCrefExp(listGet(cImmediateRefs, i), Type.BOOLEAN()), cExp, Type.BOOLEAN()) :: eqs;
    TRANSITION(immediate = immediateVal) := listGet(t, i);
    rhs := if immediateVal then
      makeCrefExp(listGet(cImmediateRefs, i), Type.BOOLEAN())
    else
      // Delayed: c[i] = if initial() then false else pre(cImmediate[i])
      // initial() guard prevents event-iteration cycling during initialization
      makeIfExp(makeInitialCall(), Expression.BOOLEAN(false),
        makePreviousCall(makeCrefExp(listGet(cImmediateRefs, i), Type.BOOLEAN()), Type.BOOLEAN()),
        Type.BOOLEAN());
    eqs := makeEq(makeCrefExp(listGet(cRefs, i), Type.BOOLEAN()), rhs, Type.BOOLEAN()) :: eqs;
  end for;

  // selectedState = if reset then 1 else previous(nextState)
  eqs := makeEq(
    makeCrefExp(selectedStateRef, Type.INTEGER()),
    makeIfExp(
      makeCrefExp(resetRef, Type.BOOLEAN()),
      Expression.INTEGER(1),
      makePreviousCall(makeCrefExp(nextStateRef, Type.INTEGER()), Type.INTEGER()),
      Type.INTEGER()),
    Type.INTEGER()) :: eqs;

  // selectedReset = if reset then true else previous(nextReset)
  eqs := makeEq(
    makeCrefExp(selectedResetRef, Type.BOOLEAN()),
    makeIfExp(
      makeCrefExp(resetRef, Type.BOOLEAN()),
      Expression.BOOLEAN(true),
      makePreviousCall(makeCrefExp(nextResetRef, Type.BOOLEAN()), Type.BOOLEAN()),
      Type.BOOLEAN()),
    Type.BOOLEAN()) :: eqs;

  // fired = max(if (t[i].from == selectedState) then c[i] else false) then i else 0 for i)
  expLst := {};
  for j in 1:nTransitions loop
    expCond := makeRelationEq(
      makeCrefExp(listGet(tFromRefs, j), Type.INTEGER()),
      makeCrefExp(selectedStateRef, Type.INTEGER()),
      Type.INTEGER());
    expIf := makeIfExp(expCond, makeCrefExp(listGet(cRefs, j), Type.BOOLEAN()), Expression.BOOLEAN(false), Type.BOOLEAN());
    expLst := makeIfExp(expIf, Expression.INTEGER(j), Expression.INTEGER(0), Type.INTEGER()) :: expLst;
  end for;
  expLst := listReverse(expLst);
  rhs := if listLength(expLst) > 1 then
    makeMaxIntArrCall(expLst)
  elseif listLength(expLst) == 1 then listHead(expLst)
  else Expression.INTEGER(0);  // no transitions: fired = 0 always
  eqs := makeEq(makeCrefExp(firedRef, Type.INTEGER()), rhs, Type.INTEGER()) :: eqs;

  // activeState = if reset then 1 elseif fired > 0 then t[fired].to else selectedState
  exp1 := makeRelationGt(makeCrefExp(firedRef, Type.INTEGER()), Expression.INTEGER(0), Type.INTEGER());
  exp2 := makeCrefExp(qCref("tTo", tTArrayInt, {Subscript.INDEX(makeCrefExp(firedRef, Type.INTEGER()))}, preRef), Type.INTEGER());
  expElse := makeIfExp(exp1, exp2, makeCrefExp(selectedStateRef, Type.INTEGER()), Type.INTEGER());
  eqs := makeEq(
    makeCrefExp(activeStateRef, Type.INTEGER()),
    makeIfExp(makeCrefExp(resetRef, Type.BOOLEAN()), Expression.INTEGER(1), expElse, Type.INTEGER()),
    Type.INTEGER()) :: eqs;

  // activeReset = if reset then true elseif fired > 0 then t[fired].reset else selectedReset
  exp1 := makeRelationGt(makeCrefExp(firedRef, Type.INTEGER()), Expression.INTEGER(0), Type.INTEGER());
  exp2 := makeCrefExp(qCref("tReset", tTArrayBool, {Subscript.INDEX(makeCrefExp(firedRef, Type.INTEGER()))}, preRef), Type.BOOLEAN());
  expElse := makeIfExp(exp1, exp2, makeCrefExp(selectedResetRef, Type.BOOLEAN()), Type.BOOLEAN());
  eqs := makeEq(
    makeCrefExp(activeResetRef, Type.BOOLEAN()),
    makeIfExp(makeCrefExp(resetRef, Type.BOOLEAN()), Expression.BOOLEAN(true), expElse, Type.BOOLEAN()),
    Type.BOOLEAN()) :: eqs;

  // nextState = if active then activeState else previous(nextState)
  eqs := makeEq(
    makeCrefExp(nextStateRef, Type.INTEGER()),
    makeIfExp(
      makeCrefExp(activeRef, Type.BOOLEAN()),
      makeCrefExp(activeStateRef, Type.INTEGER()),
      makePreviousCall(makeCrefExp(nextStateRef, Type.INTEGER()), Type.INTEGER()),
      Type.INTEGER()),
    Type.INTEGER()) :: eqs;

  // nextReset = if active then false else previous(nextReset)
  eqs := makeEq(
    makeCrefExp(nextResetRef, Type.BOOLEAN()),
    makeIfExp(
      makeCrefExp(activeRef, Type.BOOLEAN()),
      Expression.BOOLEAN(false),
      makePreviousCall(makeCrefExp(nextResetRef, Type.BOOLEAN()), Type.BOOLEAN()),
      Type.BOOLEAN()),
    Type.BOOLEAN()) :: eqs;

  // activeResetStates[i] = if reset then true else previous(nextResetStates[i])
  for j in 1:nStates loop
    eqs := makeEq(
      makeCrefExp(listGet(activeResetStatesRefs, j), Type.BOOLEAN()),
      makeIfExp(
        makeCrefExp(resetRef, Type.BOOLEAN()),
        Expression.BOOLEAN(true),
        makePreviousCall(makeCrefExp(listGet(nextResetStatesRefs, j), Type.BOOLEAN()), Type.BOOLEAN()),
        Type.BOOLEAN()),
      Type.BOOLEAN()) :: eqs;
  end for;

  // nextResetStates[i] = if active then (if activeState == i then false else activeResetStates[i]) else previous(nextResetStates[i])
  for j in 1:nStates loop
    exp1 := makeRelationEq(makeCrefExp(activeStateRef, Type.INTEGER()), Expression.INTEGER(j), Type.INTEGER());
    expThen := makeIfExp(exp1, Expression.BOOLEAN(false), makeCrefExp(listGet(activeResetStatesRefs, j), Type.BOOLEAN()), Type.BOOLEAN());
    expElse := makePreviousCall(makeCrefExp(listGet(nextResetStatesRefs, j), Type.BOOLEAN()), Type.BOOLEAN());
    eqs := makeEq(
      makeCrefExp(listGet(nextResetStatesRefs, j), Type.BOOLEAN()),
      makeIfExp(makeCrefExp(activeRef, Type.BOOLEAN()), expThen, expElse, Type.BOOLEAN()),
      Type.BOOLEAN()) :: eqs;
  end for;

  // finalStates[i] = max(if t[j].from == i then 1 else 0 for j) == 0
  for j in 1:nStates loop
    expLst := {};
    for k in 1:nTransitions loop
      expCond := makeRelationEq(makeCrefExp(listGet(tFromRefs, k), Type.INTEGER()), Expression.INTEGER(j), Type.INTEGER());
      expLst := makeIfExp(expCond, Expression.INTEGER(1), Expression.INTEGER(0), Type.INTEGER()) :: expLst;
    end for;
    expLst := listReverse(expLst);
    // With no outgoing transitions, finalStates[i] = true (state is a final state)
    rhs := if listLength(expLst) > 1 then
      makeRelationEq(makeMaxIntArrCall(expLst), Expression.INTEGER(0), Type.INTEGER())
    elseif listLength(expLst) == 1 then
      makeRelationEq(listHead(expLst), Expression.INTEGER(0), Type.INTEGER())
    else
      Expression.BOOLEAN(true);
    eqs := makeEq(makeCrefExp(listGet(finalStatesRefs, j), Type.BOOLEAN()), rhs, Type.BOOLEAN()) :: eqs;
  end for;

  // stateMachineInFinalState = finalStates[activeState]
  eqs := makeEq(
    makeCrefExp(stateMachineInFinalStateRef, Type.BOOLEAN()),
    makeCrefExp(qCref("finalStates", tArrayBool, {Subscript.INDEX(makeCrefExp(activeStateRef, Type.INTEGER()))}, preRef), Type.BOOLEAN()),
    Type.BOOLEAN()) :: eqs;

  sem := FLAT_SM_SEMANTICS(
    initStateCref,
    listArray(stateCrefs),
    t, cExps,
    vars, knowns, eqs, {}, {}, NONE());
end basicFlatSmSemantics;

// ============================================================
// addPropagationEquations
// ============================================================

protected
function addPropagationEquations
  "Add activation/reset propagation variables and equations."
  input FlatSmSemantics inSem;
  input Option<ComponentRef> enclosingStateCrefOpt;
  input Option<FlatSmSemantics> enclosingSmSemOpt;
  output FlatSmSemantics outSem = inSem;
protected
  ComponentRef preRef, initStateRef, activeRef, resetRef, initRef;
  list<Variable> pvars = {};
  list<Equation> peqs = {};
  Integer nStates, posOfEnclosing;
  Type tArrayBool;

  // Enclosing SM fields
  ComponentRef enclosingStateCref, enclosingPreRef, enclosingActiveResetStateRef,
    enclosingActiveResetRef, enclosingActiveStateRef, enclosingInitStateRef;
  FlatSmSemantics enclosingSem;
  array<ComponentRef> enclosingComps;

  // Per-state indicator variables
  ComponentRef stateRef, activePlotRef, ticksRef, timeEnteredRef, timeInRef;
  Variable activePlotVar, ticksVar, timeEnteredVar, timeInVar;
  Equation activePlotEq, ticksEq, timeEnteredEq, timeInEq;
algorithm
  initStateRef := inSem.initStateRef;
  preRef := makeSMSPrefix(initStateRef);
  activeRef := qCref("active", Type.BOOLEAN(), {}, preRef);
  resetRef := qCref("reset", Type.BOOLEAN(), {}, preRef);
  nStates := arrayLength(inSem.smComps);
  tArrayBool := Type.ARRAY(Type.BOOLEAN(), {Dimension.INTEGER(nStates, Variability.STRUCTURAL_PARAMETER)});

  if isNone(enclosingSmSemOpt) then
    // Toplevel SM: self-reset at first clock tick
    initRef := qCref("init", Type.BOOLEAN(), {}, preRef);
    pvars := makeVarWithStart(initRef, Type.BOOLEAN(), Variability.DISCRETE, Expression.BOOLEAN(true)) :: pvars;
    peqs := makeEq(makeCrefExp(initRef, Type.BOOLEAN()), Expression.BOOLEAN(false), Type.BOOLEAN()) :: peqs;
    // reset = initial() or pre(init)  -- initial() guard prevents event-iteration cycling
    peqs := makeEq(
      makeCrefExp(resetRef, Type.BOOLEAN()),
      Expression.LBINARY(makeInitialCall(), Operator.makeOr(Type.BOOLEAN()), makePreviousCall(makeCrefExp(initRef, Type.BOOLEAN()), Type.BOOLEAN())),
      Type.BOOLEAN()) :: peqs;
    // active = true (toplevel SM always active)
    peqs := makeEq(makeCrefExp(activeRef, Type.BOOLEAN()), Expression.BOOLEAN(true), Type.BOOLEAN()) :: peqs;
  else
    // Nested SM: propagate from enclosing SM
    SOME(enclosingStateCref) := enclosingStateCrefOpt;
    SOME(enclosingSem) := enclosingSmSemOpt;
    enclosingComps := enclosingSem.smComps;
    enclosingInitStateRef := arrayGet(enclosingComps, 1);
    enclosingPreRef := makeSMSPrefix(enclosingInitStateRef);

    posOfEnclosing := 1;
    for sc in arrayList(enclosingComps) loop
      if ComponentRef.isEqual(sc, enclosingStateCref) then break; end if;
      posOfEnclosing := posOfEnclosing + 1;
    end for;

    enclosingActiveStateRef := qCref("activeState", Type.INTEGER(), {}, enclosingPreRef);
    enclosingActiveResetRef := qCref("activeReset", Type.BOOLEAN(), {}, enclosingPreRef);
    enclosingActiveResetStateRef := qCref("activeResetStates", tArrayBool,
      {Subscript.INDEX(Expression.INTEGER(posOfEnclosing))}, enclosingPreRef);

    // reset = activeResetStates[pos] or (activeReset and activeState == pos)
    peqs := makeEq(
      makeCrefExp(resetRef, Type.BOOLEAN()),
      Expression.LBINARY(
        makeCrefExp(enclosingActiveResetStateRef, Type.BOOLEAN()),
        Operator.makeOr(Type.BOOLEAN()),
        Expression.LBINARY(
          makeCrefExp(enclosingActiveResetRef, Type.BOOLEAN()),
          Operator.makeAnd(Type.BOOLEAN()),
          makeRelationEq(makeCrefExp(enclosingActiveStateRef, Type.INTEGER()),
            Expression.INTEGER(posOfEnclosing), Type.INTEGER()))),
      Type.BOOLEAN()) :: peqs;

    // active = (activeState == pos)
    peqs := makeEq(
      makeCrefExp(activeRef, Type.BOOLEAN()),
      makeRelationEq(makeCrefExp(enclosingActiveStateRef, Type.INTEGER()),
        Expression.INTEGER(posOfEnclosing), Type.INTEGER()),
      Type.BOOLEAN()) :: peqs;
  end if;

  // Per-state: active indicator, ticksInState, timeEnteredState, timeInState
  for j in 1:nStates loop
    stateRef := arrayGet(inSem.smComps, j);
    (activePlotVar, activePlotEq) := createActiveIndicator(stateRef, preRef, j);
    pvars := activePlotVar :: pvars;
    peqs := activePlotEq :: peqs;

    activePlotRef := activePlotVar.name;
    (ticksVar, ticksEq) := createTicksInStateIndicator(stateRef, activePlotRef);
    pvars := ticksVar :: pvars;
    peqs := ticksEq :: peqs;

    (timeEnteredVar, timeEnteredEq) := createTimeEnteredStateIndicator(stateRef, activePlotRef);
    (timeInVar, timeInEq) := createTimeInStateIndicator(stateRef, activePlotRef, timeEnteredVar);
    pvars := timeEnteredVar :: timeInVar :: pvars;
    peqs := timeEnteredEq :: timeInEq :: peqs;
  end for;

  outSem.pvars := pvars;
  outSem.peqs := peqs;
  outSem.enclosingState := enclosingStateCrefOpt;
end addPropagationEquations;

// ============================================================
// elabXInStateOps
// ============================================================

protected
function elabXInStateOps
  "Elaborate ticksInState() and timeInState() in transition conditions."
  input output FlatSmSemantics sem;
  input Option<ComponentRef> enclosingStateCrefOpt;
protected
  list<Transition> tElab = {};
  list<Expression> cElab = {};
  list<Equation> eqsElab;
  Integer i;
  ComponentRef stateRef;
  Expression substTickExp, substTimeExp, c3, c4;
  Boolean found;
  Transition curT;
  Integer curFrom, curTo, curPriority;
  Boolean curImmediate, curReset, curSynchronize;
algorithm
  i := 0;
  for tc in List.zip(sem.t, sem.c) loop
    i := i + 1;
    (_, c3) := tc;
    curT := listGet(sem.t, i);
    TRANSITION(from = curFrom, to = curTo, immediate = curImmediate,
      reset = curReset, synchronize = curSynchronize, priority = curPriority) := curT;
    stateRef := arrayGet(sem.smComps, curFrom);

    substTickExp := makeCrefExp(qCref("$ticksInState", Type.INTEGER(), {}, stateRef), Type.INTEGER());
    (c4, found) := subsXInState(c3, "ticksInState", substTickExp);
    if found and isSome(enclosingStateCrefOpt) then
      Error.addCompilerError("Found 'ticksInState()' within a state of a hierarchical state machine.");
      fail();
    end if;
    if found then
      sem.eqs := list(smeqsSubsXInState(eq, arrayGet(sem.smComps, 1), i, listLength(sem.t), substTickExp, "ticksInState") for eq in sem.eqs);
    end if;

    substTimeExp := makeCrefExp(qCref("$timeInState", Type.REAL(), {}, stateRef), Type.REAL());
    (c4, found) := subsXInState(c4, "timeInState", substTimeExp);
    if found and isSome(enclosingStateCrefOpt) then
      Error.addCompilerError("Found 'timeInState()' within a state of a hierarchical state machine.");
      fail();
    end if;
    if found then
      sem.eqs := list(smeqsSubsXInState(eq, arrayGet(sem.smComps, 1), i, listLength(sem.t), substTimeExp, "timeInState") for eq in sem.eqs);
    end if;

    tElab := TRANSITION(curFrom, curTo, c4, curImmediate, curReset, curSynchronize, curPriority) :: tElab;
    cElab := c4 :: cElab;
  end for;
  sem.t := listReverse(tElab);
  sem.c := listReverse(cElab);
end elabXInStateOps;

protected
function subsXInState
  "Find and replace xInState() in expression."
  input Expression inExp;
  input String funcName;
  input Expression substExp;
  output Expression outExp;
  output Boolean found = false;
algorithm
  (outExp, found) := Expression.mapFold(inExp,
    function subsXInStateHelper(funcName = funcName, substExp = substExp), false);
end subsXInState;

protected
function subsXInStateHelper
  input output Expression exp;
  input String funcName;
  input Expression substExp;
  input output Boolean found;
protected
  Call expCall;
algorithm
  try
    Expression.CALL(call = expCall) := exp;
    if not stringEq(Call.functionNameLast(expCall), funcName) then fail(); end if;
    if not listEmpty(Call.arguments(expCall)) then fail(); end if;
    exp := substExp;
    found := true;
  else
  end try;
end subsXInStateHelper;

protected
function smeqsSubsXInState
  "Replace xInState() in a specific transition's semantic equation."
  input Equation eq;
  input ComponentRef initStateComp;
  input Integer i;
  input Integer nTransitions;
  input Expression substExp;
  input String xInState;
  output Equation outEq = eq;
protected
  ComponentRef preRef, lhsRef, cRef;
  Type tArrayBool;
  Expression lhs, rhs, newRhs;
  Boolean found;
algorithm
  outEq := match eq
    case Equation.EQUALITY()
      algorithm
        preRef := makeSMSPrefix(initStateComp);
        tArrayBool := Type.ARRAY(Type.BOOLEAN(), {Dimension.INTEGER(nTransitions, Variability.STRUCTURAL_PARAMETER)});
        cRef := qCref("cImmediate", tArrayBool, {Subscript.INDEX(Expression.INTEGER(i))}, preRef);
        Expression.CREF(cref = lhsRef) := eq.lhs;
        if ComponentRef.isEqual(cRef, lhsRef) then
          (newRhs, _) := subsXInState(eq.rhs, xInState, substExp);
          outEq := Equation.EQUALITY(eq.lhs, newRhs, eq.ty, eq.scope, eq.source);
        end if;
      then outEq;
    else eq;
  end match;
end smeqsSubsXInState;

// ============================================================
// State indicator helpers
// ============================================================

protected
function createActiveIndicator
  "Create stateRef.active variable and equation: active = smOf.init.active and (activeState == i)"
  input ComponentRef stateRef;
  input ComponentRef preRef;
  input Integer i;
  output Variable activePlotVar;
  output Equation eqn;
protected
  ComponentRef activePlotRef, activeRef, activeStateRef;
  Expression andExp, eqExp;
algorithm
  activePlotRef := qCref("active", Type.BOOLEAN(), {}, stateRef);
  activePlotVar := makeVarWithStart(activePlotRef, Type.BOOLEAN(), Variability.DISCRETE, Expression.BOOLEAN(false));
  activeRef := qCref("active", Type.BOOLEAN(), {}, preRef);
  activeStateRef := qCref("activeState", Type.INTEGER(), {}, preRef);
  eqExp := makeRelationEq(makeCrefExp(activeStateRef, Type.INTEGER()), Expression.INTEGER(i), Type.INTEGER());
  andExp := Expression.LBINARY(makeCrefExp(activeRef, Type.BOOLEAN()), Operator.makeAnd(Type.BOOLEAN()), eqExp);
  eqn := makeEq(makeCrefExp(activePlotRef, Type.BOOLEAN()), andExp, Type.BOOLEAN());
end createActiveIndicator;

protected
function createTicksInStateIndicator
  "Create stateRef.$ticksInState = if active then previous($ticksInState)+1 else 0"
  input ComponentRef stateRef;
  input ComponentRef stateActiveRef;
  output Variable ticksVar;
  output Equation ticksEq;
protected
  ComponentRef ticksRef;
  Expression ticksExp, expCond, expThen, expElse;
algorithm
  ticksRef := qCref("$ticksInState", Type.INTEGER(), {}, stateRef);
  ticksVar := makeVarWithStart(ticksRef, Type.INTEGER(), Variability.DISCRETE, Expression.INTEGER(0));
  ticksExp := makeCrefExp(ticksRef, Type.INTEGER());
  // $ticksInState = if initial() or not active then 0 else pre($ticksInState) + 1
  // initial() guard prevents event-iteration cycling during initialization
  expCond := Expression.LBINARY(makeInitialCall(), Operator.makeOr(Type.BOOLEAN()),
    Expression.LUNARY(Operator.makeNot(Type.BOOLEAN()), makeCrefExp(stateActiveRef, Type.BOOLEAN())));
  expThen := Expression.INTEGER(0);
  expElse := Expression.BINARY(
    makePreviousCall(ticksExp, Type.INTEGER()),
    Operator.makeAdd(Type.INTEGER()),
    Expression.INTEGER(1));
  ticksEq := makeEq(ticksExp, makeIfExp(expCond, expThen, expElse, Type.INTEGER()), Type.INTEGER());
end createTicksInStateIndicator;

protected
function createTimeEnteredStateIndicator
  "Create $timeEnteredState = if (not previous(active) and active) then sample(time) else previous($timeEnteredState)"
  input ComponentRef stateRef;
  input ComponentRef stateActiveRef;
  output Variable timeEnteredVar;
  output Equation timeEnteredEq;
protected
  ComponentRef timeEnteredRef;
  Expression timeEnteredExp, expCond, expThen, expElse, activeExp;
algorithm
  timeEnteredRef := qCref("$timeEnteredState", Type.REAL(), {}, stateRef);
  timeEnteredVar := makeVarWithStart(timeEnteredRef, Type.REAL(), Variability.CONTINUOUS, Expression.REAL(0.0));
  timeEnteredExp := makeCrefExp(timeEnteredRef, Type.REAL());
  activeExp := makeCrefExp(stateActiveRef, Type.BOOLEAN());
  // previous(active) == false and active == true
  expCond := Expression.LBINARY(
    makeRelationEq(makePreviousCall(activeExp, Type.BOOLEAN()), Expression.BOOLEAN(false), Type.BOOLEAN()),
    Operator.makeAnd(Type.BOOLEAN()),
    makeRelationEq(activeExp, Expression.BOOLEAN(true), Type.BOOLEAN()));
  // sample(time, Clock()) - using inferred clock
  expThen := makeSampleTimeCall();
  expElse := makePreviousCall(timeEnteredExp, Type.REAL());
  timeEnteredEq := makeEq(timeEnteredExp, makeIfExp(expCond, expThen, expElse, Type.REAL()), Type.REAL());
end createTimeEnteredStateIndicator;

protected
function createTimeInStateIndicator
  "Create $timeInState = if active then sample(time) - $timeEnteredState else 0"
  input ComponentRef stateRef;
  input ComponentRef stateActiveRef;
  input Variable timeEnteredVar;
  output Variable timeInVar;
  output Equation timeInEq;
protected
  ComponentRef timeInRef;
  Expression timeInExp, expCond, expThen, expElse, timeEnteredExp;
algorithm
  timeInRef := qCref("$timeInState", Type.REAL(), {}, stateRef);
  timeInVar := makeVarWithStart(timeInRef, Type.REAL(), Variability.CONTINUOUS, Expression.REAL(0.0));
  timeInExp := makeCrefExp(timeInRef, Type.REAL());
  timeEnteredExp := makeCrefExp(timeEnteredVar.name, Type.REAL());
  expCond := makeCrefExp(stateActiveRef, Type.BOOLEAN());
  expThen := Expression.BINARY(makeSampleTimeCall(), Operator.makeSub(Type.REAL()), timeEnteredExp);
  expElse := Expression.REAL(0.0);
  timeInEq := makeEq(timeInExp, makeIfExp(expCond, expThen, expElse, Type.REAL()), Type.REAL());
end createTimeInStateIndicator;

// ============================================================
// Reset and activation wrapping
// ============================================================

protected
function wrapInStateActivationConditional
  "Transform a.x = e → a.x = if a.active then e else (x_previous or previous(a.x))"
  input Equation inEq;
  input ComponentRef stateCref;
  input Boolean isResetEquation;
  output Equation outEq;
protected
  Expression lhs, rhs, activeRef, expElse;
  ComponentRef lhsCref;
  Type ty;
  InstNode eqScope;
  DAE.ElementSource eqSource;
algorithm
  Equation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, scope = eqScope, source = eqSource) := inEq;
  Expression.CREF(ty = ty, cref = lhsCref) := lhs;
  activeRef := makeCrefExp(qCref("active", Type.BOOLEAN(), {}, stateCref), Type.BOOLEAN());
  if isResetEquation then
    expElse := makeCrefExp(
      ComponentRef.prefixCref(
        InstNode.NAME_NODE(ComponentRef.firstName(lhsCref) + "_previous"),
        ty, {}, ComponentRef.rest(lhsCref)),
      ty);
  else
    expElse := makePreviousCall(lhs, ty);
  end if;
  outEq := Equation.EQUALITY(lhs, makeIfExp(activeRef, rhs, expElse, ty), ty, eqScope, eqSource);
end wrapInStateActivationConditional;

protected
function createResetEquation
  "Create: x_previous = if active and (activeReset or activeResetStates[i]) then x_start else previous(x)"
  input ComponentRef lhsCref;
  input Type lhsTy;
  input ComponentRef stateCref;
  input FlatSmSemantics sem;
  input UnorderedMap<ComponentRef, Expression> crToStart;
  output Equation outEq;
protected
  ComponentRef preRef, initStateRef;
  Expression activeExp, activeResetExp, activeResetStatesExp, orExp, andExp, prevExp, startExp, ifExp, lhsPrevExp;
  Integer i, nStates;
  Type tArrayBool;
algorithm
  initStateRef := arrayGet(sem.smComps, 1);
  preRef := makeSMSPrefix(initStateRef);
  i := 1;
  for sc in arrayList(sem.smComps) loop
    if ComponentRef.isEqual(sc, stateCref) then break; end if;
    i := i + 1;
  end for;
  nStates := arrayLength(sem.smComps);
  tArrayBool := Type.ARRAY(Type.BOOLEAN(), {Dimension.INTEGER(nStates, Variability.STRUCTURAL_PARAMETER)});

  activeResetExp := makeCrefExp(qCref("activeReset", Type.BOOLEAN(), {}, preRef), Type.BOOLEAN());
  activeResetStatesExp := makeCrefExp(qCref("activeResetStates", tArrayBool,
    {Subscript.INDEX(Expression.INTEGER(i))}, preRef), Type.BOOLEAN());
  orExp := Expression.LBINARY(activeResetExp, Operator.makeOr(Type.BOOLEAN()), activeResetStatesExp);
  activeExp := makeCrefExp(qCref("active", Type.BOOLEAN(), {}, stateCref), Type.BOOLEAN());
  andExp := Expression.LBINARY(activeExp, Operator.makeAnd(Type.BOOLEAN()), orExp);
  prevExp := makePreviousCall(makeCrefExp(lhsCref, lhsTy), lhsTy);

  startExp := UnorderedMap.getOrDefault(lhsCref, crToStart, Expression.INTEGER(0));

  ifExp := makeIfExp(andExp, startExp, prevExp, lhsTy);
  lhsPrevExp := makeCrefExp(
    ComponentRef.prefixCref(
      InstNode.NAME_NODE(ComponentRef.firstName(lhsCref) + "_previous"),
      lhsTy, {}, ComponentRef.rest(lhsCref)),
    lhsTy);
  outEq := makeEq(lhsPrevExp, ifExp, lhsTy);
end createResetEquation;

// ============================================================
// Expression substitution helpers
// ============================================================

protected
function subsActiveStateInEq
  "Replace activeState(x) → x.active in all expressions of an equation."
  input output Equation eq;
algorithm
  eq := Equation.mapExp(eq, subsActiveStateInExp);
end subsActiveStateInEq;

protected
function subsActiveStateInExp
  "Replace activeState(x) → x.active in an expression."
  input output Expression exp;
algorithm
  exp := Expression.map(exp, subsActiveStateHelper);
end subsActiveStateInExp;

protected
function subsActiveStateHelper
  input output Expression exp;
protected
  Call expCall;
  ComponentRef argCref;
  Expression newExp;
algorithm
  try
    Expression.CALL(call = expCall) := exp;
    if not stringEq(Call.functionNameLast(expCall), "activeState") then fail(); end if;
    {Expression.CREF(cref = argCref)} := Call.arguments(expCall);
    newExp := makeCrefExp(qCref("active", Type.BOOLEAN(), {}, argCref), Type.BOOLEAN());
    exp := newExp;
  else
  end try;
end subsActiveStateHelper;

protected
function subsPreviousCrefs
  "Replace previous(x) → x_previous for x in stateVarCrefs."
  input output Expression exp;
  input list<ComponentRef> stateVarCrefs;
  input output Boolean found;
protected
  list<Expression> args;
  Expression arg1;
  Type argTy;
  ComponentRef argCref;
  Call expCall;
  Expression newExp;
algorithm
  try
    Expression.CALL(call = expCall) := exp;
    if not stringEq(Call.functionNameLast(expCall), "previous") then fail(); end if;
    args := Call.arguments(expCall);
    if listLength(args) <> 1 then fail(); end if;
    arg1 := listHead(args);
    Expression.CREF(ty = argTy, cref = argCref) := arg1;
    for svc in stateVarCrefs loop
      if ComponentRef.isEqual(svc, argCref) then
        newExp := makeCrefExp(
          ComponentRef.prefixCref(
            InstNode.NAME_NODE(ComponentRef.firstName(argCref) + "_previous"),
            argTy, {},
            ComponentRef.rest(argCref)),
          argTy);
        exp := newExp;
        found := true;
        break;
      end if;
    end for;
  else
  end try;
end subsPreviousCrefs;

// ============================================================
// createTandC
// ============================================================

protected
function createTandC
  "Build the sorted transition list (t) and condition list (c) from transition NORETCALL equations."
  input list<ComponentRef> stateCrefs;
  input list<Equation> transitionEqs;
  output list<Transition> t;
  output list<Expression> c;
protected
  list<Transition> transitions;
algorithm
  transitions := List.filterMap(transitionEqs,
    function extractTransition(stateCrefs = stateCrefs));
  t := List.sort(transitions, priorityGt);
  c := list(tr.condition for tr in t);
end createTandC;

protected
function extractTransition
  "Extract a Transition record from a transition() NORETCALL equation. Fails if not a transition."
  input Equation eq;
  input list<ComponentRef> stateCrefs;
  output Transition trans;
protected
  ComponentRef crFrom, crTo;
  Expression cond;
  Boolean imm = true, rst = true, syn = false;
  Integer prio = 1;
  Integer from, to;
  list<Expression> args;
  Call eqCall;
algorithm
  Equation.NORETCALL(exp = Expression.CALL(call = eqCall)) := eq;
  if not stringEq(Call.functionNameLast(eqCall), "transition") then fail(); end if;
  args := Call.arguments(eqCall);
  Expression.CREF(cref = crFrom) := listGet(args, 1);
  Expression.CREF(cref = crTo) := listGet(args, 2);
  cond := listGet(args, 3);
  if listLength(args) >= 4 then Expression.BOOLEAN(value = imm) := listGet(args, 4); end if;
  if listLength(args) >= 5 then Expression.BOOLEAN(value = rst) := listGet(args, 5); end if;
  if listLength(args) >= 6 then Expression.BOOLEAN(value = syn) := listGet(args, 6); end if;
  if listLength(args) >= 7 then Expression.INTEGER(value = prio) := listGet(args, 7); end if;
  from := 1;
  for sc in stateCrefs loop
    if ComponentRef.isEqual(sc, crFrom) then break; end if;
    from := from + 1;
  end for;
  to := 1;
  for sc in stateCrefs loop
    if ComponentRef.isEqual(sc, crTo) then break; end if;
    to := to + 1;
  end for;
  trans := TRANSITION(from, to, cond, imm, rst, syn, prio);
end extractTransition;

protected
function priorityGt
  "Greater-than comparator for List.sort: compare(a,b)=true means b comes before a.
   Lower priority numbers (= higher MLS priority) sort first."
  input Transition t1;
  input Transition t2;
  output Boolean gt;
algorithm
  gt := t1.priority > t2.priority;
end priorityGt;

// ============================================================
// Predicate helpers
// ============================================================

protected
function isTransitionOrInitialState
  "True if the equation is a transition() or initialState() NORETCALL."
  input Equation eq;
  output Boolean res = false;
algorithm
  () := match eq
    local
      Call eqCall;
    case Equation.NORETCALL(exp = Expression.CALL(call = eqCall))
      algorithm
        res := match Call.functionNameLast(eqCall)
          case "transition" then true;
          case "initialState" then true;
          else false;
        end match;
      then ();
    else ();
  end match;
end isTransitionOrInitialState;

protected
function isTransitionForGroup
  "True if the equation is a transition() involving states in stateCrefs."
  input Equation eq;
  input list<ComponentRef> stateCrefs;
  output Boolean res = false;
protected
  ComponentRef cr;
algorithm
  () := match eq
    local
      Call eqCall;
    case Equation.NORETCALL(exp = Expression.CALL(call = eqCall))
      guard stringEq(Call.functionNameLast(eqCall), "transition")
      algorithm
        Expression.CREF(cref = cr) := listHead(Call.arguments(eqCall));
        for sc in stateCrefs loop
          if ComponentRef.isEqual(cr, sc) then res := true; break; end if;
        end for;
      then ();
    else ();
  end match;
end isTransitionForGroup;

protected
function isInitialStateForGroup
  "True if the equation is the initialState() for the given init state."
  input Equation eq;
  input ComponentRef initStateCref;
  output Boolean res = false;
protected
  ComponentRef cr;
algorithm
  () := match eq
    local
      Call eqCall;
    case Equation.NORETCALL(exp = Expression.CALL(call = eqCall))
      guard stringEq(Call.functionNameLast(eqCall), "initialState")
      algorithm
        Expression.CREF(cref = cr) := listHead(Call.arguments(eqCall));
        res := ComponentRef.isEqual(cr, initStateCref);
      then ();
    else ();
  end match;
end isInitialStateForGroup;

protected
function isEquationOfState
  "True if the LHS cref of the equation has stateCref as its outer prefix."
  input Equation eq;
  input ComponentRef stateCref;
  output Boolean res = false;
protected
  ComponentRef lhsCref;
algorithm
  () := match eq
    case Equation.EQUALITY(lhs = Expression.CREF(cref = lhsCref))
      algorithm
        res := crefHasPrefix(stateCref, lhsCref);
      then ();
    else ();
  end match;
end isEquationOfState;

protected
function isVariableOfState
  "True if the variable name has stateCref as its outer prefix."
  input Variable var;
  input ComponentRef stateCref;
  output Boolean res;
algorithm
  res := crefHasPrefix(stateCref, var.name);
end isVariableOfState;

// ============================================================
// ComponentRef utilities
// ============================================================

protected
function qCref
  "Build a qualified ComponentRef: prefix.name[subs]"
  input String name;
  input Type ty;
  input list<Subscript> subs;
  input ComponentRef prefixCr;
  output ComponentRef cref;
algorithm
  cref := ComponentRef.fromNode(InstNode.NAME_NODE(name), ty, subs);
  cref := ComponentRef.prepend(prefixCr, cref);
end qCref;

protected
function makeSMSPrefix
  "Build the 'smOf.initStateName' prefix for SMS variables."
  input ComponentRef initStateCref;
  output ComponentRef preRef;
algorithm
  preRef := ComponentRef.fromNode(InstNode.NAME_NODE(SMS_PRE), Type.UNKNOWN(), {});
  preRef := ComponentRef.append(initStateCref, preRef);
end makeSMSPrefix;

// ============================================================
// Variable creation helpers
// ============================================================

protected
function makeVar
  "Create a synthetic discrete Variable."
  input ComponentRef name;
  input Type ty;
  input Variability var;
  output Variable v;
protected
  Attributes attr;
algorithm
  attr := NFAttributes.DEFAULT_ATTR;
  attr.variability := var;
  v := Variable.VARIABLE(name, ty, NFBinding.EMPTY_BINDING, Visibility.PUBLIC,
    attr, {}, {}, SCode.COMMENT(NONE(), NONE()), AbsynUtil.dummyInfo,
    NFBackendExtension.DUMMY_BACKEND_INFO);
end makeVar;

protected
function makeVarWithStart
  "Create a synthetic discrete Variable with a fixed start value."
  input ComponentRef name;
  input Type ty;
  input Variability var;
  input Expression startExp;
  output Variable v;
algorithm
  v := makeVar(name, ty, var);
  v.typeAttributes := {
    ("start", Binding.FLAT_BINDING(startExp, Variability.CONSTANT, NFBinding.Source.GENERATED)),
    ("fixed", Binding.FLAT_BINDING(Expression.BOOLEAN(true), Variability.CONSTANT, NFBinding.Source.GENERATED))
  };
end makeVarWithStart;

protected
function makeVarWithBinding
  "Create a synthetic parameter Variable with a binding expression."
  input ComponentRef name;
  input Type ty;
  input Variability var;
  input Expression bindExp;
  output Variable v;
algorithm
  v := makeVar(name, ty, var);
  v.binding := Binding.FLAT_BINDING(bindExp, var, NFBinding.Source.GENERATED);
end makeVarWithBinding;

// ============================================================
// Equation creation helpers
// ============================================================

protected
function makeEq
  "Create a simple equality equation."
  input Expression lhs;
  input Expression rhs;
  input Type ty;
  output Equation eq;
algorithm
  eq := Equation.EQUALITY(lhs, rhs, ty, InstNode.EMPTY_NODE(), DAE.emptyElementSource);
end makeEq;

// ============================================================
// Expression creation helpers
// ============================================================

protected
function makeCrefExp
  "Create Expression.CREF from a ComponentRef."
  input ComponentRef cref;
  input Type ty;
  output Expression exp;
algorithm
  exp := Expression.CREF(ty, cref);
end makeCrefExp;

protected
function makeIfExp
  "Create an IF expression."
  input Expression cond;
  input Expression thenExp;
  input Expression elseExp;
  input Type ty;
  output Expression exp;
algorithm
  exp := Expression.IF(ty, cond, thenExp, elseExp);
end makeIfExp;

protected
function makePreviousCall
  "Create pre(exp) for DT state machine semantics."
  input Expression exp;
  input Type ty;
  output Expression result;
algorithm
  result := Expression.CALL(Call.makeTypedCall(
    NFBuiltinFuncs.PREVIOUS, {exp}, Variability.DISCRETE, Purity.IMPURE, ty));
end makePreviousCall;

function makeInitialCall
  "Create initial() expression — true during initialization phase."
  output Expression result;
algorithm
  result := Expression.CALL(Call.makeTypedCall(
    NFBuiltinFuncs.INITIAL, {}, Variability.DISCRETE, Purity.IMPURE, Type.BOOLEAN()));
end makeInitialCall;

protected
function makeMaxIntArrCall
  "Create max({e1, e2, ...}) for an integer array."
  input list<Expression> exps;
  output Expression result;
protected
  Type arrTy;
algorithm
  arrTy := Type.ARRAY(Type.INTEGER(), {Dimension.INTEGER(listLength(exps), Variability.STRUCTURAL_PARAMETER)});
  result := Expression.CALL(Call.makeTypedCall(
    NFBuiltinFuncs.MAX_INT_ARR,
    {Expression.ARRAY(arrTy, listArray(exps), true)},
    Variability.DISCRETE, Purity.PURE, Type.INTEGER()));
end makeMaxIntArrCall;

protected
function makeSampleTimeCall
  "Create sample(time, Clock()) for time-related SM equations."
  output Expression result;
algorithm
  // Approximation: just use 'time' directly (sample semantics handled by backend)
  result := Expression.CREF(Type.REAL(),
    ComponentRef.prefixCref(InstNode.NAME_NODE("time"), Type.REAL(), {}, ComponentRef.EMPTY()));
end makeSampleTimeCall;

protected
function makeRelationEq
  "Create exp1 == exp2."
  input Expression exp1;
  input Expression exp2;
  input Type ty;
  output Expression result;
algorithm
  result := Expression.RELATION(exp1, Operator.makeEqual(ty), exp2, 0);
end makeRelationEq;

protected
function makeRelationGt
  "Create exp1 > exp2."
  input Expression exp1;
  input Expression exp2;
  input Type ty;
  output Expression result;
algorithm
  result := Expression.RELATION(exp1, Operator.makeGreater(ty), exp2, 0);
end makeRelationGt;

// ============================================================
// Start value helpers
// ============================================================

protected
function getStartValue
  "Extract start Expression from a Variable; fall back to a type default."
  input Variable var;
  output Expression startExp;
protected
  String attrName;
  Binding attrBinding;
  Option<Expression> startOpt;
  Type ty;
algorithm
  for attr in var.typeAttributes loop
    (attrName, attrBinding) := attr;
    if attrName == "start" then
      startOpt := Binding.typedExp(attrBinding);
      if isSome(startOpt) then
        SOME(startExp) := startOpt;
        return;
      end if;
    end if;
  end for;
  // Fall back to type default
  ty := var.ty;
  startExp := match ty
    case Type.INTEGER() then Expression.INTEGER(0);
    case Type.REAL()    then Expression.REAL(0.0);
    case Type.BOOLEAN() then Expression.BOOLEAN(false);
    case Type.STRING()  then Expression.STRING("");
    else Expression.INTEGER(0);
  end match;
end getStartValue;

// ============================================================
// ComponentRef prefix check
// ============================================================

protected
function crefHasPrefix
  "True if the outer scope of cref equals prefix (NF crefs are innermost-first,
   so prefix appears at the tail of the cref chain)."
  input ComponentRef prefix;
  input ComponentRef cref;
  output Boolean res = false;
algorithm
  if ComponentRef.isEqual(prefix, cref) then
    res := true;
  elseif ComponentRef.isEmpty(cref) then
    res := false;
  else
    res := crefHasPrefix(prefix, ComponentRef.rest(cref));
  end if;
end crefHasPrefix;

annotation(__OpenModelica_Interface="frontend");
end NFStateMachineFlatten;

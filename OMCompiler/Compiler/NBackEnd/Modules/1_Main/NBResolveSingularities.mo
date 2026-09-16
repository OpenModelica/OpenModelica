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

encapsulated package NBResolveSingularities
"file:        NBResolveSingularities.mo
 package:     NBResolveSingularities
 description: This file contains the functions to resolve structurally singular systems.
"
public
  import Module = NBModule;

protected
  // NF imports
  import NFBackendExtension.{BackendInfo, VariableAttributes, StateSelect};
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import Subscript = NFSubscript;
  import Type = NFType;

  // NB imports
  import Adjacency = NBAdjacency;
  import NBFunctionAlias.Call_Aux;
  import Differentiate = NBDifferentiate;
  import NBEquation.{Equation, EqData, EquationAttributes, EquationKind, EquationPointer, EquationPointers, SlicingStatus, Iterator};
  import Initialization = NBInitialization;
  import Matching = NBMatching;
  import Variable = NFVariable;
  import BVariable = NBVariable;
  import NBVariable.{VarData, VariablePointer, VariablePointers};

  // util imports
  import BackendUtil = NBBackendUtil;
  import Slice = NBSlice;
  import StringUtil;
  import UnorderedSet;

public
  function indexReduction
    "algorithm
        1. IR
        - get unkowns and eqs from markings and arrays
        - collect state candidates from constraint eqs
        - differentiate all eqs and collect new derivatives

        2. DUMMY DERIVATIVE
        - sort vars with priority (StateSelect)
        - (ToDo: remove always vars)
        - create adjacency matrix from original vars/eqs
        - match the system with inverse matching to respect ordering
        - do not kick out never variables (provided by ordering)
        - (ToDo: fail if a never variable could not be chosen)
        - see if any equations are unmatched
          - none unmatched -> static state selection
          - any unmatched -> dynamic state selection with remaining eqs and vars

        3. STATIC AND DYNAMIC
        - make all matched variables DUMMY_STATES and all corresponding derivatives DUMMY_DERIVATIVES
        - move DUMMY_STATES to algebraic vars

        4. STATIC
        - no additional tasks

        (ToDo: 5. DYNAMIC)
        - make ALL variables (besides StateSelect = always) DUMMY_STATES and corresponding derivatives DUMMY_DERIVATIVES
        - create state set from remaining eqs and vars
        - create a state and derivative variable for each remaining eq ($SET.x, $SET.dx)
        - create state selection matrix $SET.A (parameter)
        - create equations $SET.x[i] = sum($SET.A[i,j]*DUMMY_STATE[j] | forall j)
        - create equations $SET.dx[i] = sum($SET.A[i,j]*DUMMY_DERIVATIVE[j] | forall j)

        6. AFTER IR
        - add differentiated equations
        - add adjacency matrix entries
        - add new variables in correct arrays
      "
  extends Module.resolveSingularitiesInterface;
  protected
    Adjacency.Mapping mapping;
    array<Boolean> excluded_eqns;
    array<list<Integer>> msss;
    list<Integer> marked_eqns;
    PointerCyclic<Equation> constraint, diffed_eqn;
    list<Slice<VariablePointer>> states, dummy_states;
    list<PointerCyclic<Variable>> sliced_states, sliced_dummy_states, state_derivatives, dummy_derivatives = {}, dummy_slice_vars;
    list<PointerCyclic<Variable>> current_candidates, rest_candidates;
    list<Slice<EquationPointer>> constraint_eqns, matched_eqns, unmatched_eqns;
    list<PointerCyclic<Equation>> new_eqns = {};
    Differentiate.DifferentiationArguments diffArguments;
    Pointer<Differentiate.DifferentiationArguments> diffArguments_ptr;
    VariablePointers candidate_ptrs;
    EquationPointers constraint_ptrs;
    Adjacency.Matrix set_adj, full_local;
    Matching set_matching;
    UnorderedMap<ComponentRef, Integer> vo, vn, eo, en;
    list<tuple<String, BVariable.checkVar>> stages;
    BVariable.checkVar stageFunc;
    String stageStr;

    // slice handling
    type SliceSet = UnorderedSet<Integer>;
    UnorderedMap<ComponentRef, SliceSet> slice_map = UnorderedMap.new<SliceSet>(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedSet<ComponentRef> dummy_slice_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual) "dummy variables to fill unslicable equations";

    // sliced dummy/state candidate handling: state candidates matched by Matching.getMatches
    // can be a partial (non-full) slice of an array variable, e.g. only theta[1] out of theta[1:2]
    // needs to become a dummy state. Since a variable's VariableKind (STATE / DUMMY_STATE / ...)
    // is a whole-variable property, not a per-index one, such a slice is materialized as its own
    // small alias variable (sized to exactly the selected indices) plus a linking equation, the
    // same technique NBFunctionAlias.introduceSlicedStateAlias uses for the mirror-image problem
    // (a variable only partially a *state* because der() only touches some of its indices).
    // NOTE: intentionally *not* a fresh Pointer.create(1) -- indexReduction is called
    // once per detected singular subsystem, so a local counter would restart at 1 each
    // time and could collide with (or literally reuse the exact name of) an alias
    // variable created by an earlier call, e.g. two unrelated aliases both "$DUM_1".
    // VarData.getUniqueIndex(varData) is the same model-wide, ever-increasing counter
    // already used for equation naming in this function (see removeSlicedDerivatives
    // below); reusing it for the alias variable name too guarantees no collision.
    UnorderedMap<ComponentRef, Expression> alias_subst = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
    list<PointerCyclic<Equation>> alias_eqns;

    Boolean debug = false;
  algorithm
    // get the mapping and fail if there is none
    mapping := match mapping_opt
      case SOME(mapping) then mapping;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no mapping was provided."});
      then fail();
    end match;

    // mark the forbidden equations (discrete and already differentiated in previous index reduction steps)
    excluded_eqns := listArray(list(Equation.isDiscrete(eqn) or Equation.hasDerivative(eqn) for eqn in EquationPointers.toList(equations)));

    // get the minimally structurally singular subset
    msss := match adj
      case Adjacency.FINAL() then getMSSS(adj.m, adj.mT, matching, excluded_eqns, mapping);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected final matrix as adj input but got :\n"
          + Adjacency.Matrix.toString(adj)});
      then fail();
    end match;

    if not arrayLength(msss) == 0 then
      changed := true;
      // msss to flat unique list (via UnorderedSet)
      marked_eqns := UnorderedSet.unique_list(List.flatten(arrayList(msss)), Util.id, intEq);
      // --------------------------------------------------------
      //      1. BASIC INDEX REDUCTION
      // --------------------------------------------------------

      // get all unmatched eqns and state candidates
      // state candidates and constraint equations are lists of slices
      // adjacency matrix and arrays are only full based
      // slice them before matching
      (constraint_ptrs, candidate_ptrs, constraint_eqns) := getConstraintsAndCandidates(equations, marked_eqns, mapping);

      for eq in constraint_eqns loop
        UnorderedMap.add(Equation.getEqnName(Slice.getT(eq)), UnorderedSet.fromList(eq.indices, Util.id, intEq), slice_map);
      end for;

      if VariablePointers.scalarSize(candidate_ptrs) < sum(Slice.size(eq, function Equation.size(resize = true)) for eq in constraint_eqns) then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because there was not enough state candidates to balance out the constraint equations.\n"
          + EquationPointers.toString(constraint_ptrs, "Constraint") + "\n" + VariablePointers.toString(candidate_ptrs, "State Candidate")});
       fail();
      end if;

      // ToDo: differ between user dumping and developer dumping
      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(StringUtil.headline_1("Index Reduction") + "\n"
            + VariablePointers.toString(candidate_ptrs, "State Candidate")
            + EquationPointers.toString(constraint_ptrs, "Constraint"));
      end if;

      // --------------------------------------------------------
      //  2. DUMMY DERIVATIVE
      // --------------------------------------------------------
      // create full adjacency matrix and prepare data
      full_local      := Adjacency.Matrix.createFull(candidate_ptrs, constraint_ptrs, kind);
      set_adj         := Adjacency.Matrix.EMPTY(NBAdjacency.MatrixStrictness.LINEAR);
      rest_candidates := VariablePointers.toList(candidate_ptrs);
      eo              := constraint_ptrs.map;
      en              := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
      vo              := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
      vn              := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
      set_matching    := NBMatching.EMPTY_MATCHING;

      // order of importance for variables to not be states:
      stages := {
        ("1. StateSelect.NEVER",    function BVariable.isStateSelect(stateSelect = StateSelect.NEVER)),
        ("2. StateSelect.AVOID",    function BVariable.isStateSelect(stateSelect = StateSelect.AVOID)),
        ("3. Artificial Variables", BVariable.isArtificial),
        ("4. StateSelect.DEFAULT",  function BVariable.isStateSelect(stateSelect = StateSelect.DEFAULT)),
        ("5. StateSelect.PREFER",   function BVariable.isStateSelect(stateSelect = StateSelect.PREFER))
      };

      for stage in stages loop
        (stageStr, stageFunc) := stage;
        // split the candidates to get all currently relevant ones
        (current_candidates, rest_candidates) := List.splitOnTrue(rest_candidates, stageFunc);

        if listEmpty(current_candidates) then
          // nothing to do, no candidates for this stage or matching is already perfect
          if debug then
            print(StringUtil.headline_2("Nothing done for (" + stageStr + ") Index Reduction") + "\n");
          end if;
        else
          // prepare the current maps
          vo := UnorderedMap.merge(vo, UnorderedMap.copy(vn), sourceInfo());
          vn := UnorderedMap.subMap(candidate_ptrs.map, list(BVariable.getVarName(var) for var in current_candidates));
          // expand the adjacency matrix
          (set_adj, full_local)   := Adjacency.Matrix.expand(set_adj, full_local, vo, vn, eo, en, candidate_ptrs, constraint_ptrs, kind);
          // continue matching
          set_matching            := Matching.regular(set_matching, set_adj, false, true, false);

          if debug then
            print(Adjacency.Matrix.toString(set_adj, "(" + stageStr + ") Index Reduction"));
            print(Matching.toString(set_matching, "(" + stageStr + ") Index Reduction"));
          end if;

          if Matching.isEmpty(set_matching) and Matching.isPerfect(set_matching) then
            if debug then
              print(StringUtil.headline_2("Finished with perfect matching in stage " + stageStr + ".") + "\n");
            end if;
            break;
          end if;
        end if;
      end for;

      // parse the result of the matching
      (dummy_states, states, matched_eqns, unmatched_eqns) := Matching.getMatches(set_matching, Adjacency.Matrix.getMappingOpt(set_adj), candidate_ptrs, constraint_ptrs);
      unmatched_eqns := resolveSlicedUnmatched(unmatched_eqns, slice_map);

      // resolve sliced (partial-index) state/dummy candidates *before* differentiation:
      // this has to happen first so the constraint equations reference the (whole) alias
      // instead of a slice of the original by the time they are differentiated below --
      // differentiation is what promotes a plain algebraic alias to a proper STATE (see
      // NBDifferentiate.mo's ALGEBRAIC => STATE_DER case), so the alias arrives at the
      // state bucketing further down already whole.
      //
      // the state side and the dummy side are NOT symmetric here: a sliced *state*
      // candidate gets its own small alias variable + linking equation (same technique as
      // NBFunctionAlias.introduceSlicedStateAlias). A sliced *dummy* candidate does not --
      // a component reference indexed inside a for-loop can represent either slice
      // depending on the iterator value, so it cannot always be statically replaced by an
      // alias. Instead, once the sibling state slice(s) of the same variable have been
      // aliased out, the remainder of the original variable purely *is* the dummy, so the
      // whole original variable can (and must) be marked DUMMY_STATE directly below --
      // this is also what correctly excludes it from all future candidacy (see
      // getStateCandidate's isDummyState check), which a second alias never would (the
      // original variable would remain a plain, unexcluded candidate forever).
      // resolveSlicedDummyStates checks that the combined state+dummy indices fully
      // account for the variable before upgrading it to whole; see its docstring.
      dummy_states := resolveSlicedDummyStates(dummy_states, states);
      (states, alias_eqns) := resolveSlicedCandidates(states, alias_subst, VarData.getUniqueIndex(varData), VarData.getUniqueIndex(varData));
      if not UnorderedMap.isEmpty(alias_subst) then
        for constraint in EquationPointers.toList(constraint_ptrs) loop
          substituteSlicedDummyEqn(constraint, alias_subst);
        end for;
      end if;
      new_eqns := listAppend(alias_eqns, new_eqns);
      // the alias linking equations must also be *differentiated*, same as the other
      // constraint equations below -- otherwise only the value-level link ($DUM_n =
      // theta[i]) exists, and the *derivative* of the aliased slice (part of the whole
      // original variable's now-DUMMY_DER derivative, e.g. $DER.theta) is left without a
      // defining equation -- exactly the "(and their derivatives too?)" gap flagged when
      // this design was discussed. NBSorting.tarjan fails on the resulting var/eqn
      // imbalance otherwise. Folding them into constraint_ptrs reuses the loop below
      // instead of a second, separate differentiation pass; slice_map needs a matching
      // (empty, i.e. "not itself sliced") entry so removeSlicedDerivatives is a no-op
      // for them.
      for eqn in alias_eqns loop
        UnorderedMap.add(Equation.getEqnName(eqn), UnorderedSet.new(Util.id, intEq), slice_map);
      end for;
      constraint_ptrs := EquationPointers.addList(alias_eqns, constraint_ptrs);

      // Build differentiation argument structure
      diffArguments           := Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.TIME, funcMap);
      diffArguments.diff_map  := SOME(VarData.getStateOrder(varData));
      diffArguments_ptr       := Pointer.create(diffArguments);

      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(StringUtil.headline_3("[dummyselect] 1. Differentiate the constraint equations"));
      end if;

      // differentiate all eqns
      for constraint in EquationPointers.toList(constraint_ptrs) loop
        diffed_eqn := Differentiate.differentiateEquationPointer(constraint, diffArguments_ptr);
        diffed_eqn := removeSlicedDerivatives(diffed_eqn, UnorderedMap.getSafe(Equation.getEqnName(constraint), slice_map, sourceInfo()), dummy_slice_set, VarData.getUniqueIndex(varData));
        new_eqns := diffed_eqn :: new_eqns;
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print("[dummyselect] constraint eqn:\t\t" + Equation.toString(PointerCyclic.access(constraint)) + "\n");
          print("[dummyselect] differentiated eqn:\t" + Equation.toString(PointerCyclic.access(diffed_eqn)) + "\n\n");
        end if;
      end for;
      diffArguments := Pointer.access(diffArguments_ptr);

      // --------------------------------------------------------
      //  3. STATIC AND DYNAMIC STATE SELECTION
      // --------------------------------------------------------
      // for both static and dynamic state selection all matched states are regarded dummys
      // note: any originally-sliced candidate was already upgraded to its whole variable
      // above (resolveSlicedDummyStates), so every entry here should have empty .indices
      // by construction -- the else branch is a defensive fallback, not an expected path.
      for dummy in dummy_states loop
        if listEmpty(dummy.indices) then
          dummy_derivatives := BVariable.makeDummyState(Slice.getT(dummy)) :: dummy_derivatives;
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because slicing during index reduction is not yet supported.\n"
            + Slice.toString(dummy, BVariable.pointerToString, 10)});
          fail();
        end if;
      end for;

      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(StringUtil.headline_4("[dummyselect] (" + intString(listLength(states)) + ") Selected States"));
        print(Slice.lstToString(states, BVariable.pointerToString) + "\n\n");
      end if;
      if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) then
        print(StringUtil.headline_4("[stateselection] (" + intString(listLength(diffArguments.new_vars)) + ") State Derivatives Created by Differentiation"));
        print(List.toString(diffArguments.new_vars, BVariable.pointerToString, List.Style.NEWLINE_TAB) + "\n\n");
        print(StringUtil.headline_4("[stateselection] (" + intString(listLength(dummy_states)) + ") Selected Dummy States"));
        print(Slice.lstToString(dummy_states, BVariable.pointerToString) + "\n\n");
      end if;

      if listEmpty(unmatched_eqns) then
        // --------------------------------------------------------
        //  4. STATIC STATE SELECTION
        // --------------------------------------------------------
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print(StringUtil.headline_2("\t STATIC STATE SELECTION\n\t(no unmatched equations)") + "\n");
        end if;
      else
        // --------------------------------------------------------
        //  5. DYNAMIC STATE SELECTION
        // --------------------------------------------------------
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print(toStringDynamicSelect(dummy_states, unmatched_eqns));
        end if;
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because dynamic state selection is not yet supported."});
        fail();
      end if;

      // --------------------------------------------------------
      //     6. UPDATE VARIABLE AND EQUATION ARRAYS
      // --------------------------------------------------------
      // filter all variables that were created during differentiation for state derivatives
      // ToDo: these have to be slices as well! check if new created variables are whole dim of arrays
      (state_derivatives, _) := List.extractOnTrue(diffArguments.new_vars, BVariable.isStateDerivative);

      // cleanup varData and expand eqData
      // some algebraics -> states (to states)
      sliced_states := list(Slice.getT(slice) for slice in states);
      varData := VarData.addTypedList(varData, sliced_states, NBVariable.VarData.VarType.STATE);
      // new derivatives (to derivatives)
      varData := VarData.addTypedList(varData, state_derivatives, NBVariable.VarData.VarType.STATE_DER);
      // some states -> dummy states (to algebraics)
      sliced_dummy_states := list(Slice.getT(slice) for slice in dummy_states);
      varData := VarData.addTypedList(varData, sliced_dummy_states, NBVariable.VarData.VarType.ALGEBRAIC);
      // some derivatives -> dummy derivatives (to algebraics)
      varData := VarData.addTypedList(varData, dummy_derivatives, NBVariable.VarData.VarType.ALGEBRAIC);
      // new equations
      eqData := EqData.addTypedList(eqData, new_eqns, EqData.EqType.CONTINUOUS);

      // add all new differentiated variables
      variables := VariablePointers.addList(diffArguments.new_vars, variables);
      // add all dummy states
      variables := VariablePointers.addList(sliced_dummy_states, variables);
      // remove all states
      variables := VariablePointers.removeList(sliced_states, variables);
      // add new equations (after cleanup because equation names are added there)
      equations := EquationPointers.addList(new_eqns, equations);

      // add all slice dummies that were added to fill equations which cannot be split
      dummy_slice_vars := list(BVariable.getVarPointer(cref, sourceInfo()) for cref in UnorderedSet.toList(dummy_slice_set));
      varData := VarData.addTypedList(varData, dummy_slice_vars, NBVariable.VarData.VarType.ALGEBRAIC);
      variables := VariablePointers.addList(dummy_slice_vars, variables);
    else
      changed := false;
    end if;
  end indexReduction;

  function balanceInitialization
    extends Module.resolveSingularitiesInterface;
  protected
    list<Slice<VariablePointer>> unmatched_vars;
    list<Slice<EquationPointer>> unmatched_eqns;
    list<PointerCyclic<Variable>> start_vars, failed_vars = {};
    list<PointerCyclic<Equation>> sliced_eqns, start_eqns;
    PointerCyclic<Variable> var_ptr;
    PointerCyclic<list<PointerCyclic<Variable>>> ptr_start_vars = PointerCyclic.create({});
    PointerCyclic<list<PointerCyclic<Equation>>> ptr_start_eqns = PointerCyclic.create({});
    Pointer<Integer> idx;
    String error_msg;
    UnorderedMap<ComponentRef, Integer> vo, vn, eo, en;
  algorithm
    (_, unmatched_vars, _, unmatched_eqns) := Matching.getMatches(matching, mapping_opt, variables, equations);
    if Flags.isSet(Flags.INITIALIZATION) then
      print(toStringUnmatched(unmatched_vars, unmatched_eqns));
    end if;
    if not (listEmpty(unmatched_vars) and listEmpty(unmatched_eqns)) then
      changed := true;
      // --------------------------------------------------------
      //            1. Resolve Overdetermination
      // --------------------------------------------------------
      // ToDo: unmatched eq -> dependencies -> matched eqns -> ... until no further dependencies
      // dependency found twice on one branch --> loop --> fail
      // recursively replace cref with solved equations
      // simplify equation and check for 0 = 0
      if not listEmpty(unmatched_eqns) then
        Error.addMessage(Error.COMPILER_WARNING, {getInstanceName()
          + " reports an overdetermined initialization!\nChecking for consistency is not yet supported, following equations had to be removed:\n"
          + Slice.lstToString(unmatched_eqns, function Equation.pointerToString(str = ""))});
        // update this for potential arrays!
        // copy old map to update adjacency matrix correctly
        eo          := UnorderedMap.copy(equations.map);
        // get all unmatched equations and remove them from the system and overall equations
        sliced_eqns := list(Slice.getT(eqn) for eqn in unmatched_eqns);
        equations   := EquationPointers.removeList(sliced_eqns, equations);
        // also update adjacency matrices
        (adj, full) := Adjacency.Matrix.compress(adj, full, equations, variables, eo);
      end if;

      // --------------------------------------------------------
      //            2. Resolve Underdetermination
      // --------------------------------------------------------
      idx := EqData.getUniqueIndex(eqData);
      for var in unmatched_vars loop
        var_ptr := Slice.getT(var);
        if BVariable.isFixable(var_ptr) then
          // var = $START.var ($PRE.d = $START.d for previous vars)
          // DO NOT SET VARIABLE TO FIXED! we might have to fix it again for Lambda=0 system
          Initialization.createStartEquationSlice(var, ptr_start_vars, ptr_start_eqns, idx, true);
        else
          failed_vars := var_ptr :: failed_vars;
        end if;
      end for;

      if listEmpty(failed_vars) then
        start_vars  := PointerCyclic.access(ptr_start_vars);
        start_eqns  := PointerCyclic.access(ptr_start_eqns);

        // copy old equation map to update adjacency matrices correctly
        vo          := variables.map;
        eo          := UnorderedMap.copy(equations.map);

        // add new vars and equations to overall data
        varData := VarData.addTypedList(varData, start_vars, VarData.VarType.START);
        eqData := EqData.addTypedList(eqData, start_eqns, EqData.EqType.INITIAL);

        // add new equations to system pointer arrays
        equations := EquationPointers.addList(start_eqns, equations);

        // update adjacency matrices
        vn := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual);
        en := UnorderedMap.subMap(equations.map, list(Equation.getEqnName(eqn) for eqn in start_eqns));
        (adj, full) := Adjacency.Matrix.expand(adj, full, vo, vn, eo, en, variables, equations, kind);

        if Flags.isSet(Flags.INITIALIZATION) then
          print(List.toStringCustom(start_eqns, function Equation.pointerToString(str = ""),
            StringUtil.headline_4("Created Start Equations for balancing the Initialization (" + intString(listLength(start_eqns)) + "):"), "\t", "\n\t", "", false) + "\n\n");
        end if;
      else
        error_msg := getInstanceName()
          + " failed because following non-fixable variables could not be solved:\n"
          + List.toString(failed_vars, BVariable.pointerToString, List.Style.NEWLINE_TAB) + "\n";
        if Flags.isSet(Flags.INITIALIZATION) then
          error_msg := error_msg + "\nFollowing equations were created by fixing variables:\n"
            + List.toString(PointerCyclic.access(ptr_start_eqns), function Equation.pointerToString(str = "\t"), List.Style.NEWLINE_TAB) + "\n";
        else
          error_msg := error_msg + "\nUse -d=initialization for more debug output.";
        end if;
        if Flags.isSet(Flags.BLT_DUMP) then
          error_msg := error_msg + "\n" + VariablePointers.toString(variables, "All") + EquationPointers.toString(equations, "All")
            + Adjacency.Mapping.toString(Util.getOptionOrDefault(mapping_opt, Adjacency.Mapping.empty()))
            + Adjacency.Matrix.toString(adj) + "\n" + Matching.toString(matching);
        else
          error_msg := error_msg + "\nUse -d=bltdump for more verbose debug output.";
        end if;
        Error.addMessage(Error.INTERNAL_ERROR,{error_msg});
        fail();
      end if;
    else
      changed := false;
    end if;
  end balanceInitialization;

protected
  function getMSSS
    "finds the minimal structurally singular subsets"
    input Adjacency.IntMatrix m               "eqn -> vars";
    input Adjacency.IntMatrix mT              "var -> eqns";
    input Matching matching;
    input array<Boolean> excluded_eqns;
    input Adjacency.Mapping mapping;
    output array<list<Integer>> msss;
  protected
    list<Integer> eqn_candidates = {};
    array<Integer> color_clustering;
    array<Integer> eqn_coloring = arrayCreate(Adjacency.IntMatrix.rows(m), -1);
    array<Integer> var_coloring = arrayCreate(Adjacency.IntMatrix.rows(mT), -1);
    Integer color = 0;
  algorithm
    // find all unmatched equation indices
    for eqn in 1:arrayLength(matching.eqn_to_var) loop
      if matching.eqn_to_var[eqn] == -1 then
        eqn_candidates := eqn :: eqn_candidates;
      end if;
    end for;
    color_clustering := listArray(list(i for i in 1:listLength(eqn_candidates)));

    // use a new color for each uncolored equation
    for eqn in eqn_candidates loop
      if eqn_coloring[eqn] == -1 then
        color := color + 1;
        fillColorEqn(eqn, color, eqn_coloring, var_coloring, color_clustering, m, mT, matching, mapping);
      end if;
    end for;

    resolveClustering(color_clustering);

    // fill the msss array, sorting each equation to their respective color
    msss := arrayCreate(color, {});
    for eqn in 1:arrayLength(eqn_coloring) loop
      if eqn_coloring[eqn] <> -1 and not excluded_eqns[mapping.eqn_StA[eqn]] then
        color := color_clustering[eqn_coloring[eqn]];
        msss[color] := eqn :: msss[color];
      end if;
    end for;

    // remove all empty colors (purely discrete)
    msss := listArray(list(ms for ms guard(not listEmpty(ms)) in arrayList(msss)));
  end getMSSS;

  function fillColorEqn
    "finds all connected equation nodes and colors them equally
    starts at an equation"
    input Integer eqn;
    input Integer color;
    input array<Integer> eqn_coloring;
    input array<Integer> var_coloring;
    input array<Integer> color_clustering;
    input Adjacency.IntMatrix m               "eqn -> vars";
    input Adjacency.IntMatrix mT              "var -> eqns";
    input Matching matching;
    input Adjacency.Mapping mapping;
  protected
    array<Integer> data = Adjacency.IntMatrix.entries(m);
    Integer first = m.start[eqn];
  algorithm
    arrayUpdate(eqn_coloring, eqn, color);
    for k in first:first + m.len[eqn] - 1 loop
      fillColorVar(data[k], color, eqn_coloring, var_coloring, color_clustering, m, mT, matching, mapping);
    end for;
  end fillColorEqn;

  function fillColorVar
    "finds all connected equation nodes and colors them equally
    starts at a variable"
    input Integer var;
    input Integer color;
    input array<Integer> eqn_coloring;
    input array<Integer> var_coloring;
    input array<Integer> color_clustering;
    input Adjacency.IntMatrix m               "eqn -> vars";
    input Adjacency.IntMatrix mT              "var -> eqns";
    input Matching matching;
    input Adjacency.Mapping mapping;
  protected
    Integer eqn = matching.var_to_eqn[var];
  algorithm
    if var_coloring[var] == -1 then
      arrayUpdate(var_coloring, var, color);
      if eqn <> -1 then
        if eqn_coloring[eqn] == -1 then
          fillColorEqn(eqn, color, eqn_coloring, var_coloring, color_clustering, m, mT, matching, mapping);
        end if;
      end if;
    else
      colorClustering(var_coloring[var], color, color_clustering);
    end if;
  end fillColorVar;

  function colorClustering
    input Integer old_color;
    input Integer new_color;
    input array<Integer> color_clustering;
  algorithm
    if color_clustering[old_color] <> old_color then
      colorClustering(color_clustering[old_color], new_color, color_clustering);
    end if;
    arrayUpdate(color_clustering, old_color, new_color);
  end colorClustering;

  function resolveClustering
    input array<Integer> color_clustering;
  protected
    Integer color;
  algorithm
    for i in 1:arrayLength(color_clustering) loop
      color := i;
      while color_clustering[color] <> color loop
        color := color_clustering[color];
      end while;
      arrayUpdate(color_clustering, i, color);
    end for;
  end resolveClustering;

  function getConstraintsAndCandidates
    input EquationPointers equations;
    input list<Integer> marked_eqns;
    input Adjacency.Mapping mapping;
    output EquationPointers constr = EquationPointers.empty();
    output VariablePointers states = VariablePointers.empty();
    output list<Slice<EquationPointer>> sliced_constr = {};
  protected
    UnorderedSet<Integer> eqn_indices = UnorderedSet.new(Util.id, intEq);
    array<list<Integer>> eqn_slices = arrayCreate(EquationPointers.size(equations), {});
    UnorderedSet<ComponentRef> state_candidates = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    PointerCyclic<Equation> eqn_ptr;
    PointerCyclic<Variable> var_ptr;
  algorithm
    // collect all relevant constraint equations
    for eqn in marked_eqns loop
      UnorderedSet.add(mapping.eqn_StA[eqn], eqn_indices);
      eqn_slices[mapping.eqn_StA[eqn]] := eqn :: eqn_slices[mapping.eqn_StA[eqn]];
    end for;

    // get the constraint equation, add it to the array and add all slices of it to the slice list
    // furthermore, get all contained constrained equations
    for eqn in UnorderedSet.toList(eqn_indices) loop
      eqn_ptr := EquationPointers.getEqnAt(equations, eqn);
      constr  := EquationPointers.add(eqn_ptr, constr);
      sliced_constr := Slice.SLICE(eqn_ptr, eqn_slices[eqn]) :: sliced_constr;
      for candidate in Equation.collectCrefs(PointerCyclic.access(eqn_ptr), getStateCandidate) loop
        UnorderedSet.add(candidate, state_candidates);
      end for;
    end for;

    // add all state candidates to the array
    for candidate in UnorderedSet.toList(state_candidates) loop
      var_ptr := BVariable.getVarPointer(candidate, sourceInfo());
      states  := VariablePointers.add(var_ptr, states);
    end for;
  end getConstraintsAndCandidates;

  function getStateCandidate
    input output ComponentRef cref          "the cref to check";
    input UnorderedSet<ComponentRef> acc    "accumulator for relevant crefs";
  protected
    PointerCyclic<Variable> var;
    function getStateCandidateVar
      input PointerCyclic<Variable> var;
      input UnorderedSet<ComponentRef> acc    "accumulator for relevant crefs";
    algorithm
      if (BVariable.isContinuous(var, false) and not (BVariable.isTime(var) or BVariable.isDummyVariable(var) or BVariable.isDummyState(var) or (BVariable.isForcedState(var) and not BVariable.isStateSelect(var, StateSelect.PREFER)) )) then
        UnorderedSet.add(BVariable.getVarName(var), acc);
      end if;
    end getStateCandidateVar;
  algorithm
    var := BVariable.getVarPointer(cref, sourceInfo());
    if BVariable.isRecord(var) then
      for child in BVariable.getRecordChildren(var) loop
        getStateCandidateVar(child, acc);
      end for;
    else
      getStateCandidateVar(var, acc);
    end if;
  end getStateCandidate;

  function candidatePriority
    "returns the priority of a variable for state selection.
    higher priority -> better chance of getting picked as a state."
    input PointerCyclic<Variable> candidate;
    output Integer prio;
  algorithm
    prio := match PointerCyclic.access(candidate)
      local
        VariableAttributes attributes;
      case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(attributes = attributes))
      then match VariableAttributes.getStateSelect(attributes)
        case NFBackendExtension.StateSelect.NEVER   then -200;
        case NFBackendExtension.StateSelect.AVOID   then -100;
        case NFBackendExtension.StateSelect.DEFAULT then 0;
        case NFBackendExtension.StateSelect.PREFER  then 100;
        case NFBackendExtension.StateSelect.ALWAYS  then 200;
                                                    else 0;
      end match;
      else algorithm
      then fail();
    end match;
  end candidatePriority;

  function sortCandidates
    "sorts the state candidates"
    input output list<PointerCyclic<Variable>> candidates;
  protected
    list<tuple<Integer,PointerCyclic<Variable>>> priorities = {};
  algorithm
    for candidate in candidates loop
      priorities := (candidatePriority(candidate), candidate) :: priorities;
    end for;
    priorities := List.sort(priorities, BackendUtil.indexTplGt);
    candidates := List.unzipSecond(priorities);
  end sortCandidates;

  function resolveSlicedDummyStates
    "handles sliced (partial-index) entries of the *dummy* candidate list (as returned by
    Matching.getMatches), which -- unlike sliced state candidates, see
    resolveSlicedCandidates -- must NOT be given their own alias: a component reference
    indexed inside a for-loop can represent elements of either slice depending on the
    iterator value, so it cannot always be statically replaced. Instead, for each sliced
    dummy candidate this checks whether the combined indices matched as either state or
    dummy for that same variable, in this call, cover its *entire* declared extent. If
    so, nothing of the variable is left unaccounted for -- the state-side slice(s) will
    be aliased out separately (resolveSlicedCandidates), leaving the dummy side to purely
    *be* the remainder of the original variable -- so the candidate is upgraded to the
    whole variable (empty .indices), letting it be marked DUMMY_STATE directly by the
    existing, unmodified whole-variable BVariable.makeDummyState further down. This also
    correctly excludes it from all future candidacy (see getStateCandidate's isDummyState
    check), which a second alias never would (the original variable would remain a plain,
    unexcluded candidate forever, see the infinite-loop this replaced).
    Fails loudly instead of silently mismarking a variable if coverage is incomplete --
    e.g. because some of the variable's indices genuinely belong to a different, not
    (yet) detected singular subsystem -- since marking the whole variable dummy in that
    case would wrongly exclude those indices from ever becoming candidates, now or in a
    later, recursive index reduction pass (see NBMatching.singular)."
    input output list<Slice<VariablePointer>> dummy_states;
    input list<Slice<VariablePointer>> states;
  protected
    type SliceSet = UnorderedSet<Integer>;
    UnorderedMap<ComponentRef, SliceSet> covered = UnorderedMap.new<SliceSet>(ComponentRef.hash, ComponentRef.isEqual);
    ComponentRef cref;
    SliceSet cover_set;
    Integer full_size;
    list<Slice<VariablePointer>> resolved = {};
  algorithm
    // gather, per variable, every index matched as either state or dummy in this call
    for cand in listAppend(states, dummy_states) loop
      if not listEmpty(cand.indices) then
        cref := BVariable.getVarName(Slice.getT(cand));
        if UnorderedMap.contains(cref, covered) then
          cover_set := UnorderedMap.getSafe(cref, covered, sourceInfo());
          for idx in cand.indices loop
            UnorderedSet.add(idx, cover_set);
          end for;
        else
          UnorderedMap.add(cref, UnorderedSet.fromList(cand.indices, Util.id, intEq), covered);
        end if;
      end if;
    end for;

    for dummy in dummy_states loop
      if listEmpty(dummy.indices) then
        resolved := dummy :: resolved;
      else
        cref      := BVariable.getVarName(Slice.getT(dummy));
        cover_set := UnorderedMap.getSafe(cref, covered, sourceInfo());
        full_size := BVariable.size(Slice.getT(dummy));
        if UnorderedSet.size(cover_set) == full_size then
          resolved := Slice.SLICE(Slice.getT(dummy), {}) :: resolved;
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the partially matched array variable "
            + ComponentRef.toString(cref) + " could not be fully accounted for during index reduction ("
            + intString(UnorderedSet.size(cover_set)) + " of " + intString(full_size)
            + " elements matched as state or dummy state) -- the remainder belongs to a different, currently unresolved part of the system.\n"
            + Slice.toString(dummy, BVariable.pointerToString, 10)});
          fail();
        end if;
      end if;
    end for;
    dummy_states := listReverse(resolved);
  end resolveSlicedDummyStates;

  function resolveSlicedCandidates
    "resolves any sliced (partial-index) entries of a *state* candidate list (as
    returned by Matching.getMatches) into a whole alias variable, sized to exactly the
    selected indices, plus a linking equation collected in the output list. A variable's
    VariableKind (STATE / DUMMY_STATE / ...) is a whole-variable property, not a
    per-index one, so a candidate that is only a partial slice of a larger array
    variable cannot be handled directly -- same problem, same fix, as
    NBFunctionAlias.introduceSlicedStateAlias (there: a variable only partially a
    *state* because der() only touches some of its indices).
    Whole (unsliced, empty .indices) entries pass through unchanged. This must run
    *before* the constraint equations are differentiated (see indexReduction): the
    substitution rules recorded in subst have to be applied to those equations first,
    so differentiation encounters the (whole) alias instead of a slice of the original
    and promotes it to a proper state on its own, the same way it would any other
    algebraic candidate.
    NOT used for sliced *dummy* candidates -- see resolveSlicedDummyStates for why."
    input output list<Slice<VariablePointer>> candidates;
    input UnorderedMap<ComponentRef, Expression> subst;
    input Pointer<Integer> aux_index;
    input Pointer<Integer> eq_index;
    output list<PointerCyclic<Equation>> alias_eqns = {};
  protected
    list<Slice<VariablePointer>> resolved = {};
    PointerCyclic<Variable> alias_var;
    PointerCyclic<Equation> alias_eqn;
  algorithm
    for cand in candidates loop
      if listEmpty(cand.indices) then
        resolved := cand :: resolved;
      else
        (alias_var, alias_eqn) := resolveSlicedDummy(cand, subst, aux_index, eq_index);
        alias_eqns := alias_eqn :: alias_eqns;
        resolved := Slice.SLICE(alias_var, {}) :: resolved;
      end if;
    end for;
    candidates := listReverse(resolved);
  end resolveSlicedCandidates;

  function resolveSlicedDummy
    "materializes a single sliced state/dummy candidate as its own whole alias variable
    (see resolveSlicedCandidates): creates $DUM_n (scalar if only one index is
    selected, Real[n] otherwise), records cref(original[selected index]) ->
    cref(alias[i]) substitution rules in subst for each selected index, and returns
    the linking equation $DUM_n = {original[indices...]}."
    input Slice<VariablePointer> dummy;
    input UnorderedMap<ComponentRef, Expression> subst;
    input Pointer<Integer> aux_index;
    input Pointer<Integer> eq_index;
    output PointerCyclic<Variable> alias_var;
    output PointerCyclic<Equation> alias_eqn;
  protected
    Variable var = PointerCyclic.access(Slice.getT(dummy));
    ComponentRef orig_cref = BVariable.getVarName(Slice.getT(dummy));
    Type elem_ty = Type.arrayElementType(Variable.typeOf(var));
    list<Integer> sizes = list(Dimension.size(d) for d in Type.arrayDims(Variable.typeOf(var)));
    Integer n = listLength(dummy.indices);
    Type alias_ty;
    ComponentRef alias_cref, elem_cref, alias_elem_cref;
    list<Expression> elems = {};
    list<Integer> loc;
    list<Subscript> subs;
    Integer i = 1;
    Expression rhs;
  algorithm
    alias_ty := if n == 1 then elem_ty else Type.ARRAY(elem_ty, {Dimension.fromInteger(n)});
    (alias_var, alias_cref) := BVariable.makeAuxVar(NBVariable.DUMMY_ALIAS_STR, Pointer.access(aux_index), alias_ty, false);
    Pointer.update(aux_index, Pointer.access(aux_index) + 1);

    for idx in dummy.indices loop
      // idx is a zero-based flat index into the (possibly multi-dimensional) original
      // array; convert it back to a per-dimension, one-based subscript.
      loc  := Slice.indexToLocation(idx, sizes);
      subs := list(Subscript.INDEX(Expression.INTEGER(l + 1)) for l in loc);
      elem_cref := ComponentRef.setSubscripts(subs, orig_cref);
      elems := Expression.fromCref(elem_cref) :: elems;

      alias_elem_cref := if n == 1 then alias_cref else ComponentRef.setSubscripts({Subscript.INDEX(Expression.INTEGER(i))}, alias_cref);
      UnorderedMap.add(elem_cref, Expression.fromCref(alias_elem_cref), subst);
      i := i + 1;
    end for;
    elems := listReverse(elems);

    rhs := if n == 1 then listHead(elems) else Expression.makeArray(alias_ty, listArray(elems));
    alias_eqn := Equation.makeAssignment(Expression.fromCref(alias_cref), rhs, eq_index, "DUM", Iterator.EMPTY(), EquationAttributes.default(EquationKind.CONTINUOUS, false));
  end resolveSlicedDummy;

  function substituteSlicedDummyEqn
    "applies the sliced-dummy alias substitution rules (see resolveSlicedCandidates) to
    one constraint equation, in place, before it is differentiated."
    input PointerCyclic<Equation> eqn_ptr;
    input UnorderedMap<ComponentRef, Expression> subst;
  protected
    Equation eqn = PointerCyclic.access(eqn_ptr);
  algorithm
    eqn := Equation.map(eqn, function substituteSlicedDummyExp(subst = subst));
    PointerCyclic.update(eqn_ptr, eqn);
  end substituteSlicedDummyEqn;

  function substituteSlicedDummyExp
    input output Expression exp;
    input UnorderedMap<ComponentRef, Expression> subst;
  algorithm
    exp := match exp
      case Expression.CREF() guard(UnorderedMap.contains(exp.cref, subst))
      then UnorderedMap.getSafe(exp.cref, subst, sourceInfo());
      else exp;
    end match;
  end substituteSlicedDummyExp;

  function resolveSlicedUnmatched
    "removes all the unmatched slices that are irrelevant"
    input list<Slice<EquationPointer>> old_unmatched;
    output list<Slice<EquationPointer>> filtered_unmatched = {};
    input UnorderedMap<ComponentRef, UnorderedSet<Integer>> slice_map;
    function resolveSlicedUnmatchedSingle
      input Slice<EquationPointer> eq;
      input output list<Slice<EquationPointer>> acc;
      input UnorderedMap<ComponentRef, UnorderedSet<Integer>> slice_map;
    protected
      UnorderedSet<Integer> relevant_indices;
    algorithm
      relevant_indices := UnorderedMap.getSafe(Equation.getEqnName(Slice.getT(eq)), slice_map, sourceInfo());
      // empty set indicates everything is relevant (just like slices without indices indicate everything)
      if UnorderedSet.isEmpty(relevant_indices) then
        // case 1.
        acc := eq :: acc;
      else
        // case 2.
        eq.indices := list(ind for ind guard(UnorderedSet.contains(ind, relevant_indices)) in eq.indices);
        // if the list is empty, none are relevant. full relevance does not have to be considered here, would have been case 1.
        if not listEmpty(eq.indices) then acc := eq :: acc; end if;
      end if;
    end resolveSlicedUnmatchedSingle;
  algorithm
    for eq in old_unmatched loop
      filtered_unmatched := resolveSlicedUnmatchedSingle(eq, filtered_unmatched, slice_map);
    end for;
  end resolveSlicedUnmatched;

  function removeSlicedDerivatives
    input output PointerCyclic<Equation> derivative;
    input UnorderedSet<Integer> slice_set;
    input UnorderedSet<ComponentRef> dummy_slice_set;
    input Pointer<Integer> aux_index;
  protected
    Equation eqn;
  algorithm
    // only do something if the set is not empty implying full occurence
    if not UnorderedSet.isEmpty(slice_set) then
      eqn := removeSlicedDerivateEqn(PointerCyclic.access(derivative), Iterator.EMPTY(), dummy_slice_set, aux_index);
      PointerCyclic.update(derivative, eqn);
    end if;
  end removeSlicedDerivatives;

  function removeSlicedDerivateEqn
    input output Equation eqn;
    input Iterator iter;
    input UnorderedSet<ComponentRef> dummy_slice_set;
    input Pointer<Integer> aux_index;
  protected
    function replaceTupleLiterals
      input output Expression exp;
      input Iterator iter;
      input UnorderedSet<ComponentRef> dummy_slice_set;
      input Pointer<Integer> aux_index;
    protected
      ComponentRef aux;
    algorithm
      if Expression.isLiteral(exp) then
        aux := Call_Aux.createName(Expression.typeOf(exp), iter, aux_index, NBVariable.DERIVATIVE_STR, false);
        exp := Expression.CREF(ComponentRef.getSubscriptedType(aux), aux);
        UnorderedSet.add(aux, dummy_slice_set);
      end if;
    end replaceTupleLiterals;
  algorithm
      eqn := match eqn
        local
          Expression lhs;

        // apply to each body equation
        case Equation.FOR_EQUATION() algorithm
          eqn.body := list(removeSlicedDerivateEqn(b, eqn.iter, dummy_slice_set, aux_index) for b in eqn.body);
        then eqn;

        // replace everything that evaluated to a literal expression with wildcard outputs
        case Equation.RECORD_EQUATION(lhs = lhs as Expression.TUPLE()) algorithm
          lhs.elements := list(replaceTupleLiterals(e, iter, dummy_slice_set, aux_index) for e in lhs.elements);
          eqn.lhs := lhs;
        then eqn;

        // ToDo: more cases and fail if not doable

        else eqn;
      end match;
  end removeSlicedDerivateEqn;

  function toStringCandidatesConstraints
    input list<Slice<VariablePointer>> state_candidates;
    input list<Slice<EquationPointer>> constraint_eqns;
    output String str;
  algorithm
    str := StringUtil.headline_1("Index Reduction") + "\n"
            + StringUtil.headline_4("(" + intString(listLength(state_candidates)) + ") Sorted State Candidates")
            + Slice.lstToString(state_candidates, BVariable.pointerToString) + "\n"
            + StringUtil.headline_4("(" + intString(listLength(constraint_eqns)) + ") Constraint Equations")
            + Slice.lstToString(constraint_eqns, function Equation.pointerToString(str = "")) + "\n";
  end toStringCandidatesConstraints;

  function toStringDynamicSelect
    input list<Slice<VariablePointer>>  dummy_states;
    input list<Slice<EquationPointer>> unmatched_eqns;
    output String str;
  algorithm
    str := StringUtil.headline_2("\t  DYNAMIC STATE SELECTION\n\t(some unmatched equations)")
            + StringUtil.headline_4("(" + intString(listLength(dummy_states)) + ") Remaining State Candidates")
            + Slice.lstToString(dummy_states, BVariable.pointerToString) + "\n"
            + StringUtil.headline_4("(" + intString(listLength(unmatched_eqns)) + ") Remaining Equations")
            + Slice.lstToString(unmatched_eqns, function Equation.pointerToString(str = "")) + "\n";
  end toStringDynamicSelect;

  function toStringUnmatched
    input list<Slice<VariablePointer>> unmatched_vars;
    input list<Slice<EquationPointer>> unmatched_eqns;
    output String str;
  protected
    String s1, s2, s3, s4;
  algorithm
    if listEmpty(unmatched_vars) then
      s1 := StringUtil.headline_4("Not underdetermined.");
      s3 := "";
    else
      s1 := "Stage " + intString(listLength(unmatched_vars)) + " underdetermined.\n";
      s3 := "\n" + StringUtil.headline_4("(" + intString(listLength(unmatched_vars)) + ") Unmatched variables:")
            + Slice.lstToString(unmatched_vars, BVariable.pointerToString) + "\n";
    end if;
    if listEmpty(unmatched_eqns) then
      s2 := StringUtil.headline_4("Not overdetermined.");
      s4 := "";
    else
      s2 := "Stage " + intString(listLength(unmatched_eqns)) + " overdetermined.\n";
      s4 := "\n" + StringUtil.headline_4("(" + intString(listLength(unmatched_eqns)) + ") Unmatched equations:")
          + Slice.lstToString(unmatched_eqns, function Equation.pointerToString(str = "")) + "\n";
    end if;
    str := s1 + s2 + s3 + s4 + "\n";
  end toStringUnmatched;

  annotation(__OpenModelica_Interface="nbackend");
end NBResolveSingularities;

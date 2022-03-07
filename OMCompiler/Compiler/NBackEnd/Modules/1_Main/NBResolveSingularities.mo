/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBResolveSingularities
"file:        NBResolveSingularities.mo
 package:     NBResolveSingularities
 description: This file contains the functions to resolve structurally singular systems.
"
public
  import Module = NBModule;

protected
  // NF imports
  import BackendExtension = NFBackendExtension;
  import ComponentRef = NFComponentRef;
  import NFFlatten.FunctionTree;

  // NB imports
  import Adjacency = NBAdjacency;
  import Differentiate = NBDifferentiate;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EqData, EquationPointer, EquationPointers, SlicingStatus};
  import Initialization = NBInitialization;
  import Matching = NBMatching;
  import Variable = NFVariable;
  import BVariable = NBVariable;
  import NBVariable.{VarData, VariablePointer, VariablePointers};

  // util imports
  import BackendUtil = NBBackendUtil;
  import Slice = NBSlice;
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
    input list<list<Integer>> marked_eqns_lst;
  protected
    list<Integer> marked_eqns;
    SlicingStatus status;
    Pointer<Equation> constraint, sliced_eqn, diffed_eqn;
    list<Slice<VariablePointer>> state_candidates = {}, states, dummy_states;
    list<Pointer<Variable>> sliced_candidates, sliced_states, sliced_dummy_states, state_derivatives, dummy_derivatives = {};
    list<Slice<EquationPointer>> constraint_eqns = {}, matched_eqns, unmatched_eqns;
    list<Pointer<Equation>> sliced_constraints, new_eqns = {};
    Differentiate.DifferentiationArguments diffArguments;
    Pointer<Differentiate.DifferentiationArguments> diffArguments_ptr;
    VariablePointers candidate_ptrs;
    EquationPointers constraint_ptrs;
    Adjacency.Matrix set_adj;
    Matching set_matching;

    Boolean debug = false;
  algorithm
    if not listEmpty(marked_eqns_lst) then
      changed := true;
      marked_eqns := List.unique(List.flatten(marked_eqns_lst));
      // --------------------------------------------------------
      //      1. BASIC INDEX REDUCTION
      // --------------------------------------------------------

      // get all unmatched eqns and state candidates
      (constraint_eqns, state_candidates) := getConstraintsAndCandidates(equations, marked_eqns, mapping_opt);

      // ToDo: differ between user dumping and developer dumping
      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(toStringCandidatesConstraints(state_candidates, constraint_eqns));
      end if;

      // Build differentiation argument structure
      diffArguments := Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.TIME, funcTree);
      diffArguments_ptr := Pointer.create(diffArguments);

      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(StringUtil.headline_3("[dummyselect] 1. Differentiate the constraint equations"));
      end if;

      // differentiate all eqns
      for eqn in constraint_eqns loop
        constraint := Slice.getT(eqn);
        (sliced_eqn, status) := Equation.slice(constraint, eqn.indices, NONE(), funcTree);
        if status == SlicingStatus.UNCHANGED then
          diffed_eqn := Differentiate.differentiateEquationPointer(constraint, diffArguments_ptr);
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because slicing during index reduction is not yet supported.\n"
            + "  constraint eqn:\t\t" + Equation.toString(Pointer.access(constraint)) + "\n"
            + "  needed sliced eqn:\t\t" + Equation.toString(Pointer.access(sliced_eqn)) + "\n"});
          fail();
        end if;
        new_eqns := diffed_eqn :: new_eqns;
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print("[dummyselect] constraint eqn:\t\t" + Equation.toString(Pointer.access(constraint)) + "\n");
          print("[dummyselect] differentiated eqn:\t" + Equation.toString(Pointer.access(diffed_eqn)) + "\n\n");
        end if;
      end for;
      diffArguments := Pointer.access(diffArguments_ptr);

      // --------------------------------------------------------
      //  2. DUMMY DERIVATIVE
      // --------------------------------------------------------
      sliced_candidates := list(Slice.getT(state) for state in state_candidates);
      candidate_ptrs  := VariablePointers.fromList(sliced_candidates);
      sliced_constraints := list(Slice.getT(constraint) for constraint in constraint_eqns);
      constraint_ptrs := EquationPointers.fromList(sliced_constraints);

      // create adjacency matrix and match with transposed matrix to respect variable priority
      set_adj := Adjacency.Matrix.create(candidate_ptrs, constraint_ptrs, matrixType, NBAdjacency.MatrixStrictness.STATE_SELECT);
      set_matching := Matching.regular(Matching.EMPTY_MATCHING(), set_adj, true, true);

      if debug then
        print(Adjacency.Matrix.toString(set_adj, "Index Reduction"));
        print(Matching.toString(set_matching, "Index Reduction "));
      end if;

      // parse the result of the matching
      (dummy_states, states, matched_eqns, unmatched_eqns) := Matching.getMatches(set_matching, Adjacency.Matrix.getMappingOpt(set_adj), candidate_ptrs, constraint_ptrs);

      if Flags.isSet(Flags.DUMMY_SELECT) then
        print(StringUtil.headline_4("(" + intString(listLength(states)) + ") Selected States"));
        print(Slice.lstToString(states, BVariable.pointerToString) + "\n");
      end if;

      // --------------------------------------------------------
      //  3. STATIC AND DYNAMIC STATE SELECTION
      // --------------------------------------------------------
      // for both static and dynamic state selection all matched states are regarded dummys
      for dummy in dummy_states loop
        if listLength(dummy.indices) == 0 then
          dummy_derivatives := BVariable.makeDummyState(Slice.getT(dummy)) :: dummy_derivatives;
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because slicing during index reduction is not yet supported.\n"
            + "  needed sliced dummy:\t\t" + Slice.toString(dummy, BVariable.pointerToString) + "\n"});
          fail();
        end if;
      end for;

      if listEmpty(unmatched_eqns) then
        // --------------------------------------------------------
        //  4. STATIC STATE SELECTION
        // --------------------------------------------------------
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print(StringUtil.headline_2("\t STATIC STATE SELECTION\n\t(no unmatched equations)"));
        end if;
      else
        // --------------------------------------------------------
        //  5. DYNAMIC STATE SELECTION
        // --------------------------------------------------------
        if Flags.isSet(Flags.DUMMY_SELECT) then
          print(toStringDynamicSelect(dummy_states, unmatched_eqns));
        end if;
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because dynamic index reduction is not yet supported."});
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
      eqData := EqData.addTypedList(eqData, new_eqns, NBEquation.EqData.EqType.CONTINUOUS);

      // add all new differentiated variables
      variables := VariablePointers.addList(diffArguments.new_vars, variables);
      // add all dummy states
      variables := VariablePointers.addList(sliced_dummy_states, variables);
      // add new equations (after cleanup because equation names are added there)
      equations := EquationPointers.addList(new_eqns, equations);
    else
      changed := false;
    end if;
  end indexReduction;

  function balanceInitialization
    extends Module.resolveSingularitiesInterface;
    input Matching matching;
  protected
    list<Slice<VariablePointer>> unmatched_vars;
    list<Slice<EquationPointer>> unmatched_eqns;
    list<Pointer<Variable>> start_vars, failed_vars = {};
    list<Pointer<Equation>> sliced_eqns, start_eqns;
    Pointer<Variable> var_ptr;
    Pointer<list<Pointer<Variable>>> ptr_start_vars = Pointer.create({});
    Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqns = Pointer.create({});
    Pointer<Integer> idx;
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
        sliced_eqns := list(Slice.getT(eqn) for eqn in unmatched_eqns);
        eqData := EqData.removeList(sliced_eqns, eqData);
        equations := EquationPointers.removeList(sliced_eqns, equations);
      end if;

      // --------------------------------------------------------
      //            2. Resolve Underdetermination
      // --------------------------------------------------------
      idx := EqData.getUniqueIndex(eqData);
      for var in unmatched_vars loop
        var_ptr := Slice.getT(var);
        if BVariable.isFixable(var_ptr) then
          var_ptr := BVariable.setFixed(var_ptr);
          Initialization.createStartEquationSlice(var, ptr_start_vars, ptr_start_eqns, idx);
        else
          failed_vars := var_ptr :: failed_vars;
        end if;
      end for;

      if listEmpty(failed_vars) then
        start_vars := Pointer.access(ptr_start_vars);
        start_eqns := Pointer.access(ptr_start_eqns);

        // add new vars and equations to overall data
        varData := VarData.addTypedList(varData, start_vars, NBVariable.VarData.VarType.START);
        eqData := EqData.addTypedList(eqData, start_eqns, NBEquation.EqData.EqType.INITIAL);

        // add new equations to system pointer arrays
        equations := EquationPointers.addList(start_eqns, equations);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
          + " failed because following non-fixable variables could not be solved:\n"
          + List.toString(failed_vars, BVariable.pointerToString, "", "\t", ", ", "\n", true)});
        fail();
      end if;
    else
      changed := false;
    end if;
  end balanceInitialization;

protected
  function getConstraintsAndCandidates
    input EquationPointers equations;
    input list<Integer> marked_eqns;
    input Option<Adjacency.Mapping> mapping_opt;
    output list<Slice<EquationPointer>> constraint_eqns;
    output list<Slice<VariablePointer>> state_candidates;
  protected
    UnorderedSet<ComponentRef> candidates;
    list<Pointer<Equation>> eqns_scalar = {};
    list<Pointer<Variable>> vars_scalar = {};
  algorithm
    (constraint_eqns, state_candidates) := match mapping_opt
      local
        Adjacency.Mapping mapping;
        Pointer<Equation> constraint;

      // SCALAR
      case NONE() algorithm
        candidates := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual, Util.nextPrime(listLength(marked_eqns)));
        for idx in marked_eqns loop
          constraint := ExpandableArray.get(idx, equations.eqArr);
          eqns_scalar := constraint :: eqns_scalar;
          for candidate in BEquation.Equation.collectCrefs(Pointer.access(constraint), getStateCandidate) loop
            UnorderedSet.add(candidate, candidates);
          end for;
        end for;
        for cref in UnorderedSet.toList(candidates) loop
          vars_scalar := BVariable.getVarPointer(cref) :: vars_scalar;
        end for;
        vars_scalar := sortCandidates(vars_scalar);
      then (list(Slice.SLICE(eqn, {}) for eqn in eqns_scalar), list(Slice.SLICE(var, {}) for var in vars_scalar));

      // PSEUDO ARRAY
      case SOME(mapping) algorithm
      then ({}, {});

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end getConstraintsAndCandidates;

  function getStateCandidate
    input output ComponentRef cref          "the cref to check";
    input Pointer<list<ComponentRef>> acc   "accumulator for relevant crefs";
  protected
    Pointer<Variable> var;
  algorithm
    var := BVariable.getVarPointer(cref);
    if (BVariable.isContinuous(var) and not BVariable.isTime(var)) then
      Pointer.update(acc, cref :: Pointer.access(acc));
    end if;
  end getStateCandidate;

  function candidatePriority
    "returns the priority of a variable for state selection.
    higher priority -> better chance of getting picked as a state."
    input Pointer<Variable> candidate;
    output Integer prio;
  algorithm
    prio := match Pointer.access(candidate)
      local
        BackendExtension.VariableAttributes attributes;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = attributes))
      then match BackendExtension.VariableAttributes.getStateSelect(attributes)
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
    input output list<Pointer<Variable>> candidates;
  protected
    list<tuple<Integer,Pointer<Variable>>> priorities = {};
  algorithm
    for candidate in candidates loop
      priorities := (candidatePriority(candidate), candidate) :: priorities;
    end for;
    priorities := List.sort(priorities, BackendUtil.indexTplGt);
    (_, candidates) := List.unzip(priorities);
  end sortCandidates;

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
    s1 := if listEmpty(unmatched_vars) then "Not underdetermined.\n" else "Stage " + intString(listLength(unmatched_vars)) + " underdetermined.\n";
    s2 := if listEmpty(unmatched_eqns) then "Not overdetermined.\n" else "Stage " + intString(listLength(unmatched_eqns)) + " overdetermined.\n";
    s3 := StringUtil.headline_4("(" + intString(listLength(unmatched_vars)) + ") Unmatched variables:")
          + Slice.lstToString(unmatched_vars, BVariable.pointerToString) + "\n";
    s4 := "\n" + StringUtil.headline_4("(" + intString(listLength(unmatched_eqns)) + ") Unmatched equations:")
          + Slice.lstToString(unmatched_eqns, function Equation.pointerToString(str = "")) + "\n";
    str := s1 + s2 + s3 + s4;
  end toStringUnmatched;

  annotation(__OpenModelica_Interface="backend");
end NBResolveSingularities;


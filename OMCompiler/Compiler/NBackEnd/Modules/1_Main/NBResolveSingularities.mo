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
  import NFBackendExtension.{BackendInfo, VariableAttributes};
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
    list<Integer> marked_eqns;
    Adjacency.Matrix state_adj;
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
    Adjacency.Matrix set_adj, full_local;
    Matching set_matching;
    array<list<Integer>> msss;
    Boolean debug = false;
  algorithm
    // get the minimally structurally singular subset
    msss := match adj
      case Adjacency.FINAL() then getMSSS(adj.m, adj.mT, matching);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected final matrix as adj input but got :\n"
          + Adjacency.Matrix.toString(adj)});
      then fail();
    end match;

    if not arrayLength(msss) == 0 then
      changed := true;
      // msss to flat unique list (via UnorderedSet)
      marked_eqns := UnorderedSet.unique_list(List.flatten(arrayList(msss)), Util.id, intEq);
      print(List.toString(marked_eqns, intString) + "\n");
      // --------------------------------------------------------
      //      1. BASIC INDEX REDUCTION
      // --------------------------------------------------------

      // get all unmatched eqns and state candidates
      // state candidates and constraint equations are lists of slices
      // adjacency matrix and arrays are only full based
      // slice them before matching
      (_, _, state_adj, constraint_eqns) := getConstraintsAndCandidates(equations, marked_eqns, mapping_opt);
      state_candidates := {};

      if List.compareLength(state_candidates, constraint_eqns) < 0 then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
          + " failed because there were not enough state candidates to balance out the constraint equations.\n"
          + StringUtil.headline_4("(" + intString(listLength(state_candidates)) + "|"
          + intString(sum(Slice.size(v, function BVariable.size(resize = true)) for v in state_candidates)) + ") State Candidates")
          + List.toString(state_candidates, function Slice.toString(func=BVariable.pointerToString, maxLength=10), "", "\t", "\n\t", "\n", true) + "\n"
          + StringUtil.headline_4("(" + intString(listLength(constraint_eqns)) + "|"
          + intString(sum(Slice.size(e, function Equation.size(resize = true)) for e in constraint_eqns)) + ") Constraint Equations")
          + List.toString(constraint_eqns, function Slice.toString(func=function Equation.pointerToString(str=""), maxLength=10), "", "\t", "\n\t", "\n", true) + "\n"});
        fail();
      end if;

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
      // create full matrix
      full_local := Adjacency.Matrix.createFull(candidate_ptrs, constraint_ptrs);
      // create solvable adjacency matrix for matching
      set_adj := Adjacency.Matrix.fromFull(full_local, candidate_ptrs.map, constraint_ptrs.map, constraint_ptrs, NBAdjacency.MatrixStrictness.LINEAR);
      set_matching := Matching.regular(NBMatching.EMPTY_MATCHING, set_adj, true, true);

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
        if listEmpty(dummy.indices) then
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
      eqData := EqData.addTypedList(eqData, new_eqns, EqData.EqType.CONTINUOUS);

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

  function noIndexReduction
    "fails if the system has unmatched variables"
    extends Module.resolveSingularitiesInterface;
  protected
    list<Slice<VariablePointer>> unmatched_vars, matched_vars;
    list<Slice<EquationPointer>> unmatched_eqns, matched_eqns;
    String err_str;
    Adjacency.Mapping mapping;
    Option<array<tuple<Integer, Integer>>> var_opt, eqn_opt;
    array<list<Integer>> msss;
    VariablePointers states;
    EquationPointers constraints;
    Integer msss_idx = 1;
  algorithm
    (matched_vars, unmatched_vars, matched_eqns, unmatched_eqns) := Matching.getMatches(matching, mapping_opt, variables, equations);
    if not listEmpty(unmatched_vars) then
      err_str := getInstanceName()
        + " failed.\n" + StringUtil.headline_4("(" + intString(listLength(unmatched_vars)) + "|"
        + intString(sum(Slice.size(v, function BVariable.size(resize = true)) for v in unmatched_vars)) + ") Unmatched Variables")
        + List.toString(unmatched_vars, function Slice.toString(func=BVariable.pointerToString, maxLength=10), "", "\t", "\n\t", "\n", true) + "\n"
        + StringUtil.headline_4("(" + intString(listLength(unmatched_eqns)) + "|"
        + intString(sum(Slice.size(e, function Equation.size(resize = true)) for e in unmatched_eqns)) + ") Unmatched Equations")
        + List.toString(unmatched_eqns, function Slice.toString(func=function Equation.pointerToString(str=""), maxLength=10), "", "\t", "\n\t", "\n", true) + "\n";
      if Flags.isSet(Flags.BLT_DUMP) then
        // get the minimally structurally singular subset
        msss := match adj
          case Adjacency.FINAL() then getMSSS(adj.m, adj.mT, matching);
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected final matrix as adj input but got :\n"
              + Adjacency.Matrix.toString(adj)});
          then fail();
        end match;

        for marked_eqns in msss loop
          (constraints, states, _, _) := getConstraintsAndCandidates(equations, marked_eqns, mapping_opt);
          err_str := err_str + StringUtil.headline_2("MSSS " + intString(msss_idx) + "") + "\n"
            + EquationPointers.toString(constraints, "Constraint")
            + VariablePointers.toString(states, "State");
          msss_idx := msss_idx + 1;
        end for;
      end if;
      Error.addMessage(Error.INTERNAL_ERROR,{err_str});
      fail();
    end if;
    changed := false;
  end noIndexReduction;

  function balanceInitialization
    extends Module.resolveSingularitiesInterface;
  protected
    list<Slice<VariablePointer>> unmatched_vars;
    list<Slice<EquationPointer>> unmatched_eqns;
    list<Pointer<Variable>> start_vars, failed_vars = {};
    list<Pointer<Equation>> sliced_eqns, start_eqns;
    Pointer<Variable> var_ptr;
    Pointer<list<Pointer<Variable>>> ptr_start_vars = Pointer.create({});
    Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqns = Pointer.create({});
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
          Initialization.createStartEquationSlice(var, ptr_start_vars, ptr_start_eqns, idx);
        else
          failed_vars := var_ptr :: failed_vars;
        end if;
      end for;

      if listEmpty(failed_vars) then
        start_vars  := Pointer.access(ptr_start_vars);
        start_eqns  := Pointer.access(ptr_start_eqns);

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
        (adj, full) := Adjacency.Matrix.expand(adj, full, vo, vn, eo, en, variables, equations);

        if Flags.isSet(Flags.INITIALIZATION) then
          print(List.toString(start_eqns, function Equation.pointerToString(str = ""),
            StringUtil.headline_4("Created Start Equations for balancing the Initialization (" + intString(listLength(start_eqns)) + "):"), "\t", "\n\t", "", false) + "\n\n");
        end if;
      else
        error_msg := getInstanceName()
          + " failed because following non-fixable variables could not be solved:\n"
          + List.toString(failed_vars, BVariable.pointerToString, "", "\t", ", ", "\n", true);
        if Flags.isSet(Flags.INITIALIZATION) then
          error_msg := error_msg + "\nFollowing equations were created by fixing variables:\n"
            + List.toString(Pointer.access(ptr_start_eqns), function Equation.pointerToString(str = "\t"), "", "", "\n", "\n", true);
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
    "finds the minimally structurally singular subsets"
    input array<list<Integer>> m              "eqn -> list<var>";
    input array<list<Integer>> mT             "var -> list<eqn>";
    input Matching matching;
    output array<list<Integer>> msss;
  protected
    list<Integer> eqn_candidates = {};
    array<Integer> eqn_coloring = arrayCreate(arrayLength(matching.eqn_to_var), -1);
    array<Integer> var_coloring = arrayCreate(arrayLength(matching.var_to_eqn), -1);
    Integer color = 0;
  algorithm
    // find all unmatched variable and equation indices
    for eqn in 1:arrayLength(matching.eqn_to_var) loop
      if matching.eqn_to_var[eqn] == -1 then
        eqn_candidates := eqn :: eqn_candidates;
      end if;
    end for;

    // use a new color for each uncolored equation
    for eqn in eqn_candidates loop
      if eqn_coloring[eqn] == -1 then
        color := color + 1;
        fillColorEqn(eqn, color, eqn_coloring, var_coloring, m, mT);
      end if;
    end for;

    // fill the msss array, sorting each equation to their respective color
    msss := arrayCreate(color, {});
    for eqn in 1:arrayLength(eqn_coloring) loop
      if eqn_coloring[eqn] <> -1 then
        msss[eqn_coloring[eqn]] := eqn :: msss[eqn_coloring[eqn]];
      end if;
    end for;
  end getMSSS;

  function fillColorEqn
    "finds all connected equation nodes and colors them equally
    starts at an equation"
    input Integer eqn;
    input Integer color;
    input array<Integer> eqn_coloring;
    input array<Integer> var_coloring;
    input array<list<Integer>> m              "eqn -> list<var>";
    input array<list<Integer>> mT             "var -> list<eqn>";
  algorithm
    arrayUpdate(eqn_coloring, eqn, color);
    for var in m[eqn] loop
      if var_coloring[var] == -1 then
        fillColorVar(var, color, eqn_coloring, var_coloring, m, mT);
      end if;
    end for;
  end fillColorEqn;

  function fillColorVar
    "finds all connected equation nodes and colors them equally
    starts at a variable"
    input Integer var;
    input Integer color;
    input array<Integer> eqn_coloring;
    input array<Integer> var_coloring;
    input array<list<Integer>> m              "eqn -> list<var>";
    input array<list<Integer>> mT             "var -> list<eqn>";
  algorithm
    arrayUpdate(var_coloring, var, color);
    for eqn in mT[var] loop
      if eqn_coloring[eqn] == -1 then
        fillColorEqn(eqn, color, eqn_coloring, var_coloring, m, mT);
      end if;
    end for;
  end fillColorVar;

  function getConstraintsAndCandidates
    input EquationPointers equations;
    input list<Integer> marked_eqns;
    input Option<Adjacency.Mapping> mapping_opt;
    output EquationPointers constr = EquationPointers.empty();
    output VariablePointers states = VariablePointers.empty();
    output Adjacency.Matrix state_adj;
    output list<Slice<EquationPointer>> sliced_constr = {};
  protected
    Adjacency.Mapping mapping;
    UnorderedSet<Integer> eqn_indices = UnorderedSet.new(Util.id, intEq);
    array<list<Integer>> eqn_slices = arrayCreate(EquationPointers.size(equations), {});
    UnorderedSet<ComponentRef> state_candidates = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    Pointer<Equation> eqn_ptr;
    Adjacency.Matrix full;
  algorithm
    // get the mapping and fail if there is none
    mapping := match mapping_opt
      case SOME(mapping) then mapping;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no mapping was provided."});
      then fail();
    end match;

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
      for candidate in BEquation.Equation.collectCrefs(Pointer.access(eqn_ptr), getStateCandidate) loop
        UnorderedSet.add(candidate, state_candidates);
      end for;
    end for;

    // add all state candidates to the array
    for candidate in UnorderedSet.toList(state_candidates) loop
      states := VariablePointers.add(BVariable.getVarPointer(candidate), states);
    end for;

    // create adjacency matrix
    full      := Adjacency.Matrix.createFull(states, constr);
    state_adj := Adjacency.Matrix.fromFull(full, states.map, constr.map, constr, NBAdjacency.MatrixStrictness.LINEAR);

    print(VariablePointers.toString(states) + "\n");
    print(EquationPointers.toString(constr) + "\n");

    print(Adjacency.Matrix.toString(full, "full") + "\n");
    print(Adjacency.Matrix.toString(state_adj, "final") + "\n");

    // plan:
    // BEFORE -> figure out state order stuff (in detect states? replace all know der() calls with respective states instead of $DER)
    // just like with the constraint equations, get the states candidates
    // create state candidates array use it for createFull
    // create final from full
    // slice final using the constr slicings (state slicing not needed)

/*
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
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;*/
  end getConstraintsAndCandidates;

  function getStateCandidate
    input output ComponentRef cref          "the cref to check";
    input UnorderedSet<ComponentRef> acc    "accumulator for relevant crefs";
  protected
    Pointer<Variable> var;
    function getStateCandidateVar
      input Pointer<Variable> var;
      input UnorderedSet<ComponentRef> acc    "accumulator for relevant crefs";
    algorithm
      if (BVariable.isContinuous(var, false) and not (BVariable.isTime(var) or BVariable.isDummyVariable(var))) then
        UnorderedSet.add(BVariable.getVarName(var), acc);
      end if;
    end getStateCandidateVar;
  algorithm
    var := BVariable.getVarPointer(cref);
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
    input Pointer<Variable> candidate;
    output Integer prio;
  algorithm
    prio := match Pointer.access(candidate)
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

  annotation(__OpenModelica_Interface="backend");
end NBResolveSingularities;

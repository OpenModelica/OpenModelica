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
encapsulated package NBIndexReduction
"file:        NBIndexReduction.mo
 package:     NBIndexReduction
 description: This file contains the functions to resolve structurally singular systems.
"

  public
    import BackendExtension = NFBackendExtension;
    import ComponentRef = NFComponentRef;
    import NFFlatten.FunctionTree;

    import Adjacency = NBAdjacency;
    import Differentiate = NBDifferentiate;
    import BEquation = NBEquation;
    import NBEquation.EqData;
    import NBEquation.Equation;
    import NBEquation.EquationPointers;
    import NBCausalize.Matching;
    import NBCausalize.Sorting;
    import BVariable = NBVariable;
    import NBVariable.VarData;
    import NBVariable.Variable;
    import NBVariable.VariablePointers;

    import BackendUtil = NBBackendUtil;

  function main
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
    input output VariablePointers variables;
    input output EquationPointers equations;
    input output VarData varData;
    input output EqData eqData;
    input output FunctionTree funcTree;
    input list<Integer> marked_eqns;
  protected
    Pointer<Equation> constraint, diffed_eqn;
    list<ComponentRef> candidates = {};
    list<Pointer<Variable>> state_candidates = {}, states, state_derivatives, dummy_states, dummy_derivatives = {};
    list<Pointer<Equation>> constraint_eqns = {}, matched_eqns, unmatched_eqns, new_eqns = {};
    Differentiate.DifferentiationArguments diffArguments;
    Pointer<Differentiate.DifferentiationArguments> diffArguments_ptr;
    VariablePointers candidate_ptrs;
    EquationPointers constraint_ptrs;
    Adjacency.Matrix set_adj;
    Matching set_matching;

    Boolean debug = false;
  algorithm
    // --------------------------------------------------------
    //      1. BASIC INDEX REDUCTION
    // --------------------------------------------------------

    // get all unmatched eqns and state candidates
    for idx in marked_eqns loop
      constraint := ExpandableArray.get(idx, equations.eqArr);
      constraint_eqns := constraint :: constraint_eqns;
      candidates := listAppend(BEquation.Equation.collectCrefs(Pointer.access(constraint), getStateCandidate), candidates);
    end for;
    for cref in candidates loop
      state_candidates := BVariable.getVarPointer(cref) :: state_candidates;
    end for;
    state_candidates := sortCandidates(List.unique(state_candidates));

    // ToDo: differ between user dumping and developer dumping
    if Flags.isSet(Flags.DUMMY_SELECT) then
      print(StringUtil.headline_1("Index Reduction") + "\n");
      print(StringUtil.headline_4("(" + intString(listLength(state_candidates)) + ") Sorted State Candidates"));
      print("{" + stringDelimitList(list(ComponentRef.toString(BVariable.getVarName(var)) for var in state_candidates), ", ") + "}\n\n");
      print(StringUtil.headline_4("(" + intString(listLength(constraint_eqns)) + ") Constraint Equations"));
      print(stringDelimitList(list(Equation.toString(Pointer.access(eqn)) for eqn in constraint_eqns), "\n") + "\n\n");
    end if;

    // Build differentiation argument structure
    diffArguments := Differentiate.DIFFERENTIATION_ARGUMENTS(
      diffCref        = ComponentRef.EMPTY(),
      new_vars        = {},
      jacobianHT      = NONE(),
      diffType        = NBDifferentiate.DifferentiationType.TIME,
      funcTree        = funcTree,
      diffedFunctions = AvlSetPath.new()
    );
    diffArguments_ptr := Pointer.create(diffArguments);

    if Flags.isSet(Flags.DUMMY_SELECT) then
      print(StringUtil.headline_3("[dummyselect] 1. Differentiate the constraint equations"));
    end if;

    // differentiate all eqns
    for eqn in constraint_eqns loop
      diffed_eqn := Differentiate.differentiateEquationPointer(eqn, diffArguments_ptr);
      new_eqns := diffed_eqn :: new_eqns;
      if Flags.isSet(Flags.DUMMY_SELECT) then
        print("[dummyselect] constraint eqn:\t\t" + Equation.toString(Pointer.access(eqn)) + "\n");
        print("[dummyselect] differentiated eqn:\t" + Equation.toString(Pointer.access(diffed_eqn)) + "\n\n");
      end if;
    end for;
    diffArguments := Pointer.access(diffArguments_ptr);

    // --------------------------------------------------------
    //  2. DUMMY DERIVATIVE
    // --------------------------------------------------------
    candidate_ptrs := VariablePointers.fromList(state_candidates);
    constraint_ptrs := EquationPointers.fromList(constraint_eqns);

    // create adjacency matrix and match with transposed matrix to respect variable priority
    set_adj := Adjacency.Matrix.create(candidate_ptrs, constraint_ptrs, NBAdjacency.MatrixType.SCALAR, NBAdjacency.MatrixStrictness.STATE_SELECT);
    set_matching := Matching.regular(set_adj, true, true);

    if debug then
      print(Adjacency.Matrix.toString(set_adj, "Index Reduction"));
      print(Matching.toString(set_matching, "Index Reduction "));
    end if;

    // parse the result of the matching
    (dummy_states, states, matched_eqns, unmatched_eqns) := Matching.getUnmatched(set_matching, candidate_ptrs, constraint_ptrs);

    if Flags.isSet(Flags.DUMMY_SELECT) then
      print(StringUtil.headline_4("(" + intString(listLength(states)) + ") Selected States"));
      print("{" + stringDelimitList(list(ComponentRef.toString(BVariable.getVarName(var)) for var in states), ", ") + "}\n\n");
    end if;

    // --------------------------------------------------------
    //  3. STATIC AND DYNAMIC STATE SELECTION
    // --------------------------------------------------------
    // for both static and dynamic state selection all matched states are regarded dummys
    for dummy in dummy_states loop
      dummy_derivatives := BVariable.makeDummyState(dummy) :: dummy_derivatives;
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
        print(StringUtil.headline_2("\t  DYNAMIC STATE SELECTION\n\t(some unmatched equations)"));
        print(StringUtil.headline_4("(" + intString(listLength(unmatched_eqns)) + ") Remaining Equations"));
        print(stringDelimitList(list(Equation.toString(Pointer.access(eqn)) for eqn in unmatched_eqns), "\n") + "\n\n");
        print(StringUtil.headline_4("(" + intString(listLength(dummy_states)) + ") Remaining State Candidates"));
        print("{" + stringDelimitList(list(ComponentRef.toString(BVariable.getVarName(var)) for var in dummy_states), ", ") + "}\n\n");
      end if;
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because dynamic index reduction is not yet supported."});
      fail();
    end if;

    // --------------------------------------------------------
    //     6. UPDATE VARIABLE AND EQUATION ARRAYS
    // --------------------------------------------------------
    // filter all variables that were created during differentiation for state derivatives
    (state_derivatives, _) := List.extractOnTrue(diffArguments.new_vars, BVariable.isStateDerivative);

    // cleanup varData and expand eqData
    // some algebraics -> states (to states)
    varData := VarData.addTypedList(varData, states, NBVariable.VarData.VarType.STATE);
    // new derivatives (to derivatives)
    varData := VarData.addTypedList(varData, state_derivatives, NBVariable.VarData.VarType.STATE_DER);
    // some states -> dummy states (to algebraics)
    varData := VarData.addTypedList(varData, dummy_states, NBVariable.VarData.VarType.ALGEBRAIC);
    // some derivatives -> dummy derivatives (to algebraics)
    varData := VarData.addTypedList(varData, dummy_derivatives, NBVariable.VarData.VarType.ALGEBRAIC);
    // new equations
    eqData := EqData.addTypedList(eqData, new_eqns, NBEquation.EqData.EqType.CONTINUOUS);

    // add all new differentiated variables
    variables := VariablePointers.addList(diffArguments.new_vars, variables);
    // add all dummy states
    variables := VariablePointers.addList(dummy_states, variables);
    // add new equations (after cleanup because equation names are added there)
    equations := EquationPointers.addList(new_eqns, equations);
  end main;

protected
  function getStateCandidate
    input output ComponentRef cref          "the cref to check";
    input Pointer<list<ComponentRef>> acc   "accumulator for relevant crefs";
  protected
    Pointer<Variable> var;
  algorithm
    var := BVariable.getVarPointer(cref);
    if (BVariable.isState(var) or BVariable.isStateDerivative(var) or BVariable.isAlgebraic(var)) then
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

  annotation(__OpenModelica_Interface="backend");
end NBIndexReduction;


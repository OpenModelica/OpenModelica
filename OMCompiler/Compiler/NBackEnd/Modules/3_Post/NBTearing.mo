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
encapsulated uniontype NBTearing
"file:        NBTearing.mo
 package:     NBTearing
 description: This file contains the data-types used for tearing. It is a
              uniontype and therefore also contains some structures for tearing.
"

public
  import BackendDAE = NBackendDAE;
  import Module = NBModule;
  import Slice = NBSlice;
  import NBVariable.{VarSlice, VariablePointer, VariablePointers, VarData};
  import NBEquation.{Equation, EqnSlice, EquationPointer, EquationPointers, EqData};
  import StrongComponent = NBStrongComponent;

protected
  // selfimport
  import Tearing = NBTearing;

  // NF imports
  import NFFlatten.FunctionTree;
  import Variable = NFVariable;
  import ComponentRef = NFComponentRef;

  // Backend imports
  import Adjacency = NBAdjacency;
  import NBAdjacency.Solvability;
  import Causalize = NBCausalize;
  import BEquation = NBEquation;
  import Initialization = NBInitialization;
  import BJacobian = NBJacobian;
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import Inline = NBInline;
  import Jacobian = NBackendDAE.BackendDAE;
  import Matching = NBMatching;
  import Solve = NBSolve;
  import Sorting = NBSorting;
  import Partition = NBPartition;

  //Util imports
  import BackendUtil = NBBackendUtil;
  import StringUtil;

public

  record TEARING_SET
    list<Slice<VariablePointer>> iteration_vars   "the variables used for iteration";
    list<Slice<EquationPointer>> residual_eqns    "implicitely solved residual equations";
    array<StrongComponent> innerEquations         "array of matched equations and variables";
    Option<Jacobian> jac                          "optional jacobian";
  end TEARING_SET;

  function hash
    "compute hash value by only using iteration variables with their first index should be unique enough"
    input Tearing set;
    output Integer h = 5381;
  algorithm
    for var in set.iteration_vars loop
      h := stringHashDjb2Continue(BVariable.pointerToString(Slice.getT(var)), h);
      for i in List.firstOrEmpty(var.indices) loop
        h := stringHashDjb2Continue(intString(i), h);
      end for;
    end for;
  end hash;

  function isEqual
    "checking the jacobian should not be necessary"
    input Tearing set1;
    input Tearing set2;
    output Boolean b;
  algorithm
     b := List.isEqualOnTrue(set1.residual_eqns, set2.residual_eqns, function Slice.isEqual(func = Equation.isEqualPtr));
     b := if b then Array.isEqualOnTrue(set1.innerEquations, set2.innerEquations, StrongComponent.isEqual) else b;
     b := if b then List.isEqualOnTrue(set1.iteration_vars, set2.iteration_vars, function Slice.isEqual(func = BVariable.equalName)) else b;
  end isEqual;

  function size
    input Tearing set;
    input Boolean resize;
    output Integer s;
  algorithm
    s := sum(Slice.size(eq, function Equation.size(resize = resize)) for eq in set.residual_eqns);
    s := s + sum(StrongComponent.size(eq, resize) for eq in set.innerEquations);
  end size;

  function toString
    input Tearing set;
    input output String str;
  algorithm
    str := StringUtil.headline_4(str);
    str := str + "### Iteration Variables:\n" + Slice.lstToString(set.iteration_vars, BVariable.pointerToString);
    str := str + "\n### Residual Equations:\n" + Slice.lstToString(set.residual_eqns, function Equation.pointerToString(str = ""));
    str := str + "\n### Inner Equations:\n" + Array.toString(set.innerEquations, function StrongComponent.toString(index = -1), "", "\t", "\n\t", "");
    if Util.isSome(set.jac) then
      str := str + "\n" + BJacobian.toString(Util.getOption(set.jac), "NLS");
    end if;
  end toString;

  function main
    "Wrapper function for any tearing function. This will be
    called during simulation and gets the corresponding subfunction from
    Config."
    extends Module.wrapper;
    input Partition.Kind kind;
  protected
    constant list<Module.tearingInterface> funcs = getModule();
    FunctionTree funcTree;
  algorithm
    if Flags.isSet(Flags.TEARING_DUMP) then
      print(StringUtil.headline_1("[" + Partition.Partition.kindToString(kind) + "] Tearing") + "\n");
    end if;
    bdae := match (kind, bdae)
      local
        list<Partition.Partition> partitions;
        Pointer<Integer> eq_index;

      case (NBPartition.Kind.ODE, BackendDAE.MAIN(ode = partitions, funcTree = funcTree, eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (partitions, funcTree) := tearingTraverser(partitions, funcs, funcTree, eq_index, kind);
          bdae.ode := partitions;
          bdae.funcTree := funcTree;
      then bdae;

      case (NBPartition.Kind.INI, BackendDAE.MAIN(init = partitions, funcTree = funcTree, eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (partitions, funcTree) := tearingTraverser(partitions, funcs, funcTree, eq_index, kind);
          bdae.init := partitions;
          if Util.isSome(bdae.init_0) then
            (partitions, funcTree) := tearingTraverser(Util.getOption(bdae.init_0), funcs, funcTree, eq_index, kind);
            bdae.init_0 := SOME(partitions);
          end if;
          bdae.funcTree := funcTree;
      then bdae;

      case (NBPartition.Kind.DAE, BackendDAE.MAIN(dae = SOME(partitions), funcTree = funcTree, eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (partitions, funcTree) := tearingTraverser(partitions, funcs, funcTree, eq_index, kind);
          bdae.dae := SOME(partitions);
          bdae.funcTree := funcTree;
          // recursively call this function to also apply to the ODE section (used for events)
          // ToDo: only create event partitions, disregard rest
      then main(bdae, NBPartition.Kind.ODE);

    // ToDo: all the other cases: e.g. Jacobian, Hessian
    end match;
  end main;

  function implicit
    input output StrongComponent comp     "the suspected algebraic loop.";
    input output FunctionTree funcTree    "Function call bodies";
    input output Integer index            "current unique loop index";
    input Partition.Kind kind = NBPartition.Kind.ODE   "partition type";
  protected
    // dummy adjacency matrix, don't need it for implicit
    Adjacency.Matrix dummy = Adjacency.EMPTY(NBAdjacency.MatrixStrictness.FULL);
    StrongComponent new_comp;
    Pointer<Boolean> homotopy = Pointer.create(false);
  algorithm
    (comp, dummy, funcTree, index) := match comp
      // create implicit equations
      case StrongComponent.SINGLE_COMPONENT() algorithm
        Equation.map(Pointer.access(comp.eqn), function Initialization.containsHomotopyCall(b = homotopy));
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = singleImplicit(comp.var, comp.eqn),
          casual  = NONE(),
          linear  = false,
          mixed   = false,
          homotopy = Pointer.access(homotopy),
          status  = NBSolve.Status.IMPLICIT);
      then finalize(new_comp, dummy, funcTree, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), kind);

      case StrongComponent.MULTI_COMPONENT() algorithm
        Equation.map(Pointer.access(Slice.getT(comp.eqn)), function Initialization.containsHomotopyCall(b = homotopy));
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = singleImplicit(Slice.getT(listHead(comp.vars)), Slice.getT(comp.eqn)), // this is wrong! need to take all vars
          casual  = NONE(),
          linear  = false,
          mixed   = false,
          homotopy = Pointer.access(homotopy),
          status  = NBSolve.Status.IMPLICIT);
      then finalize(new_comp, dummy, funcTree, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), kind);

      case StrongComponent.RESIZABLE_COMPONENT() algorithm
        Equation.map(Pointer.access(Slice.getT(comp.eqn)), function Initialization.containsHomotopyCall(b = homotopy));
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = singleImplicit(Slice.getT(comp.var), Slice.getT(comp.eqn)),
          casual  = NONE(),
          linear  = false,
          mixed   = false,
          homotopy = Pointer.access(homotopy),
          status  = NBSolve.Status.IMPLICIT);
      then finalize(new_comp, dummy, funcTree, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), kind);

      // do nothing otherwise
      else (comp, dummy, funcTree, index);
    end match;
  end implicit;

  function singleImplicit
    input VariablePointer var;
    input EquationPointer eqn;
    output NBTearing tearingSet = Tearing.TEARING_SET(
      iteration_vars  = {Slice.SLICE(var, {})},
      residual_eqns   = {Slice.SLICE(eqn, {})},
      innerEquations  = listArray({}),
      jac             = NONE());
  end singleImplicit;

  function getModule
    "Returns the module function that was chosen by the user."
    output list<Module.tearingInterface> funcs;
  protected
    String flag = Flags.getConfigString(Flags.TEARING_METHOD);
    function isNotGuruVar extends BVariable.checkVar;
      input Boolean init;
    algorithm
      b := BVariable.hasTearingSelect(var_ptr, NFBackendExtension.TearingSelect.PREFER, intLt);
    end isNotGuruVar;
  algorithm
    funcs := match flag
      case "minimalTearing" then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, finalize};
      case "cellier"        then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, finalize}; // TODO set `minimal = false` when it's actually doing something
      case "omcTearing"     then {function initialize(varFunc = BVariable.isDiscontinuous, eqnFunc = Equation.isDiscontinuous), minimal, finalize}; // TODO set `minimal = false` when it's actually doing something
      case "guruTearing"    then {function initialize(varFunc = isNotGuruVar, eqnFunc = noFilterEqn), guru, finalize};
      /* ... New tearing modules have to be added here */
      else fail();
    end match;
  end getModule;

  function getVariables
    input Tearing tearing;
    output list<Pointer<Variable>> variables;
  algorithm
     variables := listAppend(var for var in list(Slice.getT(var) for var in tearing.iteration_vars) :: list(StrongComponent.getVariables(comp) for comp in tearing.innerEquations));
  end getVariables;

  function getResidualVars
    input Tearing tearing;
    output list<Pointer<Variable>> residuals;
  algorithm
    residuals := list(Equation.getResidualVar(Slice.getT(eqn)) for eqn in tearing.residual_eqns);
  end getResidualVars;

  function getResidualEqns
    input Tearing tearing;
    output list<Pointer<Equation>> residuals = list(Slice.getT(eqn) for eqn in tearing.residual_eqns);
  end getResidualEqns;

  function setResidualEqns
    input output Tearing tearing;
    input list<Slice<EquationPointer>> residuals;
  algorithm
    tearing.residual_eqns := residuals;
  end setResidualEqns;

protected
  // Traverser function
  function tearingTraverser
    input list<Partition.Partition> partitions;
    input list<Module.tearingInterface> funcs;
    output list<Partition.Partition> new_partitions = {};
    input output FunctionTree funcTree;
    input Pointer<Integer> eq_index;
    input Partition.Kind kind;
  protected
    array<StrongComponent> strongComponents;
    StrongComponent tmp;
    Integer idx = 0;
    Adjacency.Matrix full "full adjacency matrix containing solvability info";
  algorithm
    for part in partitions loop
      if isSome(part.strongComponents) and isSome(part.adjacencyMatrix) then
        SOME(strongComponents) := part.strongComponents;
        SOME(full) := part.adjacencyMatrix;
        for i in 1:arrayLength(strongComponents) loop
          // each module has a list of functions that need to be applied
          tmp := strongComponents[i];
          for func in funcs loop
            (tmp, full, funcTree, idx) := func(tmp, full, funcTree, idx, part.unknowns, part.equations, eq_index, kind);
          end for;
          // only update if it changed
          if not referenceEq(tmp, strongComponents[i]) then
            arrayUpdate(strongComponents, i, tmp);
          end if;
        end for;
        part.strongComponents := SOME(strongComponents);
        part.adjacencyMatrix := SOME(full);
      end if;
      new_partitions := part :: new_partitions;
    end for;
    new_partitions := listReverse(new_partitions);
  end tearingTraverser;

  function noFilterVar extends BVariable.checkVar;
    input Boolean init;
  algorithm
    b := true;
  end noFilterVar;

  function noFilterEqn extends BEquation.checkEqn;
  algorithm
    b := true;
  end noFilterEqn;

  function initialize
    extends Module.tearingInterface;
    input checkVarInit varFunc = noFilterVar;
    input BEquation.checkEqn eqnFunc = noFilterEqn;
    partial function checkVarInit extends BVariable.checkVar;
      input Boolean init;
    end checkVarInit;
  protected
    Tearing strict;
    list<ComponentRef> vars_lst, eqns_lst;
    UnorderedSet<ComponentRef> vars_set         "all loop vars, used to determine solvability";
    UnorderedMap<ComponentRef, Integer> v, e    "all loop vars and equations map";
    constant Boolean init = kind == NBPartition.Kind.INI;
  algorithm
    (comp, full, index) := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        index := index + 1;
        comp.idx := index;

        // filter variables and equations appropriately
        vars_lst := list(BVariable.getVarName(Slice.getT(var)) for var guard varFunc(Slice.getT(var), init) in strict.iteration_vars);
        eqns_lst := list(Equation.getEqnName(Slice.getT(eqn)) for eqn guard eqnFunc(Slice.getT(eqn)) in strict.residual_eqns);

        // the set of all loop variables used to determine solvability
        vars_set := UnorderedSet.fromList(vars_lst, ComponentRef.hash, ComponentRef.isEqual);

        // the sets of variables and equations
        v := UnorderedMap.subMap(variables.map, vars_lst);
        e := UnorderedMap.subMap(equations.map, eqns_lst);

        // refine the adjacency matrix by updating solvability information
        (full, funcTree)  := Adjacency.Matrix.refine(full, funcTree, v, e, variables, equations, vars_set, kind == NBPartition.Kind.INI);
        comp.linear       := checkLinearity(full, v, e);
      then (comp, full, index);
      else (comp, full, index);
    end match;
  end initialize;

  function finalize extends Module.tearingInterface;
  protected
    Tearing strict;
    list<list<Slice<EquationPointer>>> acc;
    UnorderedSet<VariablePointer> dummy_set = UnorderedSet.new(BVariable.hash, BVariable.equalName);
  algorithm
    comp := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // inline potential records
        acc := list(Inline.inlineRecordSliceEquation(eqn, variables, dummy_set, eq_index, true) for eqn in strict.residual_eqns);

        // create residual equations
        strict.residual_eqns  := list(Slice.apply(eqn, function Equation.createResidual(residualCref_opt = NONE(), new = true, allowFail = false)) for eqn in List.flatten(acc));
        comp.strict := strict;

        if Flags.isSet(Flags.TEARING_DUMP) then
          print(StringUtil.headline_2("[" + Partition.Partition.kindToString(kind) + "] Tearing Result " + intString(comp.idx)) + "\n" + StrongComponent.toString(comp) + "\n");
        end if;
      then comp;
      else comp;
    end match;
  end finalize;

  function minimal extends Module.tearingInterface;
    // only extracts discrete variables to be solved as inner equations
  protected
    Tearing strict;
    list<Pointer<Variable>> vars_lst, cont_vars, disc_vars;
    list<Pointer<Equation>> eqns_lst, cont_eqns, disc_eqns;
    Integer num_vars, num_eqns;
    list<Slice<VariablePointer>> matched_vars, iteration_vars = {};
    list<Slice<EquationPointer>> residual_lst;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> inner_comps;
    UnorderedMap<ComponentRef, Integer> v, e;
    UnorderedSet<ComponentRef> matched_set = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    comp := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // split equations and variables for discretes and continuous
        vars_lst := list(Slice.getT(var) for var in strict.iteration_vars);
        eqns_lst := list(Slice.getT(eqn) for eqn in strict.residual_eqns);
        (cont_vars, disc_vars) := filterDiscreteVariables(vars_lst, kind == NBPartition.Kind.INI);
        (cont_eqns, disc_eqns) := List.splitOnTrue(eqns_lst, Equation.isContinousRecordAware);
        num_vars := sum(BVariable.size(var) for var in disc_vars);
        num_eqns := sum(Equation.size(eqn) for eqn in disc_eqns);

        // do nothing if there are no discrete equations
        if not listEmpty(disc_eqns) then
          comp.mixed := true;

          // the sets of discrete variables and discrete equations
          v := UnorderedMap.subMap(variables.map, list(BVariable.getVarName(var) for var in disc_vars));
          e := UnorderedMap.subMap(equations.map, list(Equation.getEqnName(eqn) for eqn in disc_eqns));

          // match the discretes to create inner components
          adj         := Adjacency.Matrix.fromFull(full, v, e, equations, NBAdjacency.MatrixStrictness.MATCHING);
          matching    := Matching.regular(NBMatching.EMPTY_MATCHING, adj, true, true);

          // get matched vars and remove them from the iteration variable list
          (matched_vars, _, _, _) := Matching.getMatches(matching, Adjacency.Matrix.getMappingOpt(adj), variables, equations);
          // build the matched variables set
          for var in matched_vars loop
            UnorderedSet.add(BVariable.getVarName(Slice.getT(var)), matched_set);
          end for;
          // only take variables that are not in the set
          for var in strict.iteration_vars loop
            if not UnorderedSet.contains(BVariable.getVarName(Slice.getT(var)), matched_set) then
              iteration_vars := var :: iteration_vars;
            end if;
          end for;

          // upgrade adjacency matrix and sort the system creating inner equation components
          adj         := Adjacency.Matrix.upgrade(adj, full, v, e, equations, NBAdjacency.MatrixStrictness.SORTING);
          inner_comps := Sorting.tarjan(adj, matching, variables, equations); // probably need other variables and equations here?
          strict.innerEquations := listArray(inner_comps);

          // create residuals equations and iteration variables
          strict.residual_eqns  := list(Slice.SLICE(eqn, {}) for eqn in cont_eqns);
          strict.iteration_vars := iteration_vars;
          comp.strict := strict;
        end if;
      then comp;
      else comp;
    end match;
  end minimal;

  function guru extends Module.tearingInterface;
  protected
    list<StrongComponent> inner_comps = {};
    list<EqnSlice> residuals = {};
    Tearing strict;
    Integer nEqn;
    list<VarSlice> inner_vars, guru_vars, failed_vars;
    UnorderedSet<VariablePointer> solvable_vars;
    UnorderedMap<ComponentRef, VarSlice> unsolved_inner_vars;
    UnorderedMap<ComponentRef, EqnSlice> unsolved_equations;
    array<UnorderedSet<ComponentRef>> filtered_rows;
    Option<ComponentRef> solve_opt;
    ComponentRef solve_cref;
    VarSlice solve_var;
    EqnSlice solve_eqn;
    Boolean success, var_assigned;
    ComponentRef stripped;
    constant Boolean init = kind == NBPartition.Kind.INI;
  algorithm
    comp := match (comp, full)
      case (StrongComponent.ALGEBRAIC_LOOP(strict = strict), Adjacency.FULL()) algorithm
        nEqn := arrayLength(full.equation_names);

        // split variables to inner variables and guru iteration vars
        (inner_vars, guru_vars) := List.splitOnTrue(strict.iteration_vars,
          function Slice.check(func = function BVariable.hasTearingSelect(compareTS = NFBackendExtension.TearingSelect.PREFER, func = intLt)));

        if listEmpty(guru_vars) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. No guru variables provided for strong component:\n"
            + StrongComponent.toString(comp)});
          fail();
        else
          failed_vars := list(var for var guard(Slice.check(var, function NBVariable.isDiscontinuous(init = init))) in guru_vars);
          if not listEmpty(failed_vars) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Following variables cannot be chosen as iteration variables because they are discontinuous:\n"
              + List.toString(failed_vars, function Slice.toString(func = BVariable.pointerToString, maxLength = 10), "", "\t" , "\n\t", "")});
            fail();
          end if;

          // collect the (yet) unsolved inner vars as a map of their name to their variable slice
          // at the end of the algorithm this set has to be empty
          unsolved_inner_vars := UnorderedMap.new<VarSlice>(ComponentRef.hash, ComponentRef.isEqual);
          for var in inner_vars loop
            UnorderedMap.add(BVariable.getVarName(Slice.getT(var)), var, unsolved_inner_vars);
          end for;

          // collect the (yet) unsolved equations. all remaining at the end will be residual
          unsolved_equations := UnorderedMap.new<EqnSlice>(ComponentRef.hash, ComponentRef.isEqual);
          for eqn in strict.residual_eqns loop
            UnorderedMap.add(Equation.getEqnName(Slice.getT(eqn)), eqn, unsolved_equations);
          end for;

          // main routine finding the inner variable and equation pairs
          while(not UnorderedMap.isEmpty(unsolved_inner_vars)) loop
            for i in 1:nEqn loop
              var_assigned := false;
              if UnorderedMap.contains(full.equation_names[i], unsolved_equations) then
                solve_opt := NONE();
                success := false;
                for cref in UnorderedSet.toList(full.occurences[i]) loop
                  stripped := ComponentRef.stripSubscriptsAll(cref);
                  if UnorderedMap.contains(stripped, unsolved_inner_vars) then
                    if isNone(solve_opt) then
                      success := true;
                      solve_opt := SOME(cref);
                    else
                      success := false;
                      break;
                    end if;
                  end if;
                end for;

                // ToDo: multi-components (algorithms)
                _:= match (solve_opt, success)
                  // case I: possibly solvable as inner. check if the full cref can be solved
                  case (SOME(solve_cref), true) algorithm
                    // ToDo: for now assume it can be fully solved, needs to be checked!
                    // ToDo: check solvability? --> if not linear then fail or check strictness
                    stripped    := ComponentRef.stripSubscriptsAll(solve_cref);
                    solve_var   := UnorderedMap.getSafe(stripped, unsolved_inner_vars, sourceInfo());
                    solve_eqn   := UnorderedMap.getSafe(full.equation_names[i], unsolved_equations, sourceInfo());
                    inner_comps := StrongComponent.createSliceOrSingle(solve_cref, solve_var, solve_eqn) :: inner_comps;

                    // remove the variable and equation from candidates
                    UnorderedMap.remove(stripped, unsolved_inner_vars);
                    UnorderedMap.remove(full.equation_names[i], unsolved_equations);
                    var_assigned := true;
                  then ();

                  // case II: more than one inner found, just skip and do nothing until this might be solvable later
                  case (SOME(solve_cref), false) then ();

                  // case III: none found, has to be residual
                  case (NONE(), false) algorithm
                    residuals := UnorderedMap.getSafe(full.equation_names[i], unsolved_equations, sourceInfo()) :: residuals;
                    UnorderedMap.remove(full.equation_names[i], unsolved_equations);
                  then ();

                  // FAIL: algorithm should not be able to produce this impossible combination
                  else algorithm
                    Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Impossible result for equation representative: "
                      + ComponentRef.toString(full.equation_names[i]) + "."});
                  then ();
                end match;
              end if;
              if var_assigned then break; end if;
            end for;

            // if not variable could be assigned in a full circle of checking all equations the problem is impossible to solve
            if not var_assigned then
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Following variables could not be solved as inner variables:\n"
                + List.toString(UnorderedMap.valueList(unsolved_inner_vars), function Slice.toString(func = BVariable.pointerToString, maxLength = 10), "", "\t" , "\n\t", "")});
              fail();
            end if;
          end while;

          comp.mixed := List.any(inner_vars, function Slice.check(func = function BVariable.isDiscontinuous(init = init)));

          // save residuals equations and iteration variables to the strong component
          strict.innerEquations := listArray(listReverse(inner_comps));
          strict.residual_eqns  := listAppend(UnorderedMap.valueList(unsolved_equations), residuals);
          strict.iteration_vars := guru_vars;
          comp.strict := strict;
        end if;

      then comp;
      else comp;
    end match;
  end guru;

  function checkLinearity
    input Adjacency.Matrix full;
    input UnorderedMap<ComponentRef, Integer> v "variables in the algebraic loop";
    input UnorderedMap<ComponentRef, Integer> e "equations in the algebraic loop";
    output Boolean linear;
  protected
    function varIsLinear
      input ComponentRef var;
      input UnorderedMap<ComponentRef, Integer> v;
      input UnorderedMap<ComponentRef, Solvability> sol;
      output Boolean b = not (UnorderedMap.contains(var, v) and Solvability.isNonlinearOrImplicit(UnorderedMap.getSafe(var, sol, sourceInfo())));
    end varIsLinear;

    function eqnIsLinear
      input Integer i "equation index";
      input array<UnorderedSet<ComponentRef>> occ;
      input array<UnorderedMap<ComponentRef, Solvability>> sol;
      input UnorderedMap<ComponentRef, Integer> v;
      output Boolean b = UnorderedSet.all(occ[i], function varIsLinear(v = v, sol = sol[i]));
    end eqnIsLinear;
  algorithm
    linear := match full
      case Adjacency.Matrix.FULL() then UnorderedMap.all(e, function eqnIsLinear(occ = full.occurences, sol = full.solvabilities, v = v));
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected type full, got type " + Adjacency.Matrix.strictnessString(Adjacency.Matrix.getStrictness(full)) + "."});
      then fail();
    end match;
  end checkLinearity;

  function filterDiscreteVariables
    "splits off all discrete variables. also splits off variables that belong to a record with a discrete variable in this algebraic loop"
    input list<Pointer<Variable>> vars_lst;
    input Boolean init;
    output list<Pointer<Variable>> cont_vars;
    output list<Pointer<Variable>> disc_vars;
  protected
    UnorderedSet<ComponentRef> discrete_records = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    list<Pointer<Variable>> rec_disc_vars;

    function addDiscreteRecord
      "checks if it has a record parent that needs to be added"
      input Pointer<Variable> var;
      input UnorderedSet<ComponentRef> discrete_records;
    algorithm
      _ := match BVariable.getParent(var)
        local
          Pointer<Variable> parent;
        case SOME(parent) algorithm
          UnorderedSet.add(BVariable.getVarName(parent), discrete_records);
          addDiscreteRecord(parent, discrete_records);
        then ();
        else ();
      end match;
    end addDiscreteRecord;

    function checkDiscreteRecord
      "checks if continuous variable is part of records of which discretes are in this loop"
      input Pointer<Variable> var;
      input UnorderedSet<ComponentRef> discrete_records;
      input Boolean is_parent;
      output Boolean b;
    algorithm
      b := match BVariable.getParent(var)
        local
          Pointer<Variable> parent;
        case SOME(parent) then checkDiscreteRecord(parent, discrete_records, true);
        else is_parent and UnorderedSet.contains(BVariable.getVarName(var), discrete_records);
      end match;
    end checkDiscreteRecord;
  algorithm
    // basic filter all discrete variables
    (cont_vars, disc_vars) := List.splitOnTrue(vars_lst, function BVariable.isContinuous(init = init));
    // add all records that contain discrete variables
    for var in disc_vars loop addDiscreteRecord(var, discrete_records); end for;
    // split off all variables that are part of records of which discretes are in this loop
    (rec_disc_vars, cont_vars) := List.splitOnTrue(cont_vars, function checkDiscreteRecord(discrete_records = discrete_records, is_parent = false));

    // add the continous record variables that might be solved alongside discretes to the list
    disc_vars := listReverse(listAppend(rec_disc_vars, disc_vars));
  end filterDiscreteVariables;

  annotation(__OpenModelica_Interface="backend");
end NBTearing;

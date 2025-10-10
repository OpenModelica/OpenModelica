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
  import NBVariable.{VariablePointer, VariablePointers};
  import NBEquation.{Equation, EquationPointer, EquationPointers};
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
  algorithm
    funcs := match flag
      case "cellier"        then {function initialize(minimal = false), minimal, finalize};
      case "noTearing"      then {function initialize(minimal = true), minimal, finalize};
      case "omcTearing"     then {function initialize(minimal = false), minimal, finalize};
      case "minimalTearing" then {function initialize(minimal = true), minimal, finalize};
      /* ... New tearing modules have to be added here */
      else fail();
    end match;
  end getModule;

  function getResidualVars
    input Tearing tearing;
    output list<Pointer<Variable>> residuals;
  algorithm
    residuals := list(Equation.getResidualVar(Slice.getT(eqn)) for eqn in tearing.residual_eqns);
  end getResidualVars;

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

  function initialize
    extends Module.tearingInterface;
    input Boolean minimal "if true, refines only discrete variables and equations";
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

        if minimal then
          // get discrete loop variables and equations
          vars_lst := list(BVariable.getVarName(Slice.getT(var)) for var guard not BVariable.isContinuous(Slice.getT(var), init) in strict.iteration_vars);
          eqns_lst := list(Equation.getEqnName(Slice.getT(eqn)) for eqn guard not Equation.isContinuous(Slice.getT(eqn)) in strict.residual_eqns);
        else
          // get all loop variables and equations
          vars_lst := list(BVariable.getVarName(Slice.getT(var)) for var in strict.iteration_vars);
          eqns_lst := list(Equation.getEqnName(Slice.getT(eqn)) for eqn in strict.residual_eqns);
        end if;

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
    list<StrongComponent> residual_comps;
    Option<Jacobian> jacobian;
    Tearing strict;
  protected
    list<list<Slice<EquationPointer>>> acc;
    UnorderedSet<VariablePointer> dummy_set = UnorderedSet.new(BVariable.hash, BVariable.equalName);
  algorithm
    comp := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // inline potential records
        acc := list(Inline.inlineRecordSliceEquation(eqn, variables, dummy_set, eq_index, true) for eqn in strict.residual_eqns);

        // create residual equations
        strict.residual_eqns := list(Slice.apply(eqn, function Equation.createResidual(new = true)) for eqn in List.flatten(acc));

        // create residual equations
        residual_comps := list(StrongComponent.fromSolvedEquationSlice(eqn) for eqn in strict.residual_eqns);
        // update jacobian to take slices (just to have correct inner variables and such)
        (jacobian, funcTree) := BJacobian.nonlinear(
          variables = VariablePointers.fromList(list(Slice.getT(var) for var in strict.iteration_vars)),
          equations = EquationPointers.fromList(list(Slice.getT(eqn) for eqn in strict.residual_eqns)),
          comps     = Array.appendList(strict.innerEquations, residual_comps),
          funcTree  = funcTree,
          name      = Partition.Partition.kindToString(kind) + (if comp.linear then "_LS_JAC_" else "_NLS_JAC_") + intString(index),
          init      = kind == NBPartition.Kind.INI);
        strict.jac := jacobian;
        comp.strict := strict;
        if Flags.isSet(Flags.TEARING_DUMP) then
          print(StrongComponent.toString(comp) + "\n");
        end if;
      then comp;
      else comp;
    end match;
  end finalize;

  function none extends Module.tearingInterface;
    // does nothing
  end none;

  function minimal extends Module.tearingInterface;
    // only extracts discrete variables to be solved as inner equations
  protected
    Tearing strict;
    list<Pointer<Variable>> vars_lst, cont_vars, disc_vars;
    list<Pointer<Equation>> eqns_lst, cont_eqns, disc_eqns;
    Integer num_vars, num_eqns;
    list<Slice<EquationPointer>> residual_lst;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> inner_comps;
    UnorderedMap<ComponentRef, Integer> v, e  "discrete variables and equations we have to refine";
  algorithm
    comp := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // split equations and variables for discretes and continuous
        vars_lst := list(Slice.getT(var) for var in strict.iteration_vars);
        eqns_lst := list(Slice.getT(eqn) for eqn in strict.residual_eqns);
        (cont_vars, disc_vars) := List.splitOnTrue(vars_lst, function BVariable.isContinuous(init = kind == NBPartition.Kind.INI));
        (cont_eqns, disc_eqns) := List.splitOnTrue(eqns_lst, Equation.isContinuous);
        num_vars := sum(BVariable.size(var) for var in disc_vars);
        num_eqns := sum(Equation.size(eqn) for eqn in disc_eqns);

        if num_vars <> num_eqns then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed because number of discrete variables " + intString(num_vars) + " differs from number of discrete equations: " + intString(num_eqns)
            + ".\n" + StringUtil.headline_4("(" + intString(listLength(disc_vars)) + "|"
            + intString(num_vars) + ") Discrete Variables")
            + List.toString(disc_vars, BVariable.pointerToString, "", "\t", "\n\t", "\n", true) + "\n"
            + StringUtil.headline_4("(" + intString(listLength(disc_eqns)) + "|"
            + intString(num_eqns) + ") Discrete Equations")
            + List.toString(disc_eqns, function Equation.pointerToString(str=""), "", "\t", "\n\t", "\n", true) + "\n"});
          fail();
        end if;

        if not listEmpty(disc_vars) then
          comp.mixed := true;

          // the sets of discrete variables and discrete equations
          v := UnorderedMap.subMap(variables.map, list(BVariable.getVarName(var) for var in disc_vars));
          e := UnorderedMap.subMap(equations.map, list(Equation.getEqnName(eqn) for eqn in disc_eqns));

          // match the discretes to create inner components
          adj         := Adjacency.Matrix.fromFull(full, v, e, equations, NBAdjacency.MatrixStrictness.MATCHING);
          matching    := Matching.regular(NBMatching.EMPTY_MATCHING, adj, true, true);
          adj         := Adjacency.Matrix.upgrade(adj, full, v, e, equations, NBAdjacency.MatrixStrictness.SORTING);
          inner_comps := Sorting.tarjan(adj, matching, variables, equations); //probably need other variables and equations here?
          strict.innerEquations := listArray(inner_comps);

          // create residuals equations and iteration variables
          strict.residual_eqns  := list(Slice.SLICE(eqn, {}) for eqn in cont_eqns);
          strict.iteration_vars := list(Slice.SLICE(var, {}) for var in cont_vars);
          comp.strict := strict;
        end if;
      then comp;
      else comp;
    end match;
  end minimal;

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

  annotation(__OpenModelica_Interface="backend");
end NBTearing;

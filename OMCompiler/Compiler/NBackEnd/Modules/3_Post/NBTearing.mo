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

  // Backend imports
  import Adjacency = NBAdjacency;
  import BEquation = NBEquation;
  import BJacobian = NBJacobian;
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import Inline = NBInline;
  import Jacobian = NBackendDAE.BackendDAE;
  import Matching = NBMatching;
  import Sorting = NBSorting;
  import System = NBSystem;

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
    input Tearing tearing;
    output Integer i = -1;
  algorithm
    // ToDo!
  end hash;

  function isEqual
    input Tearing tearing1;
    input Tearing tearing2;
    output Boolean b = false;
  algorithm
    // ToDo!
  end isEqual;

  function toString
    input Tearing set;
    input output String str;
  algorithm
    str := StringUtil.headline_4(str);
    str := str + "### Iteration Variables:\n" + Slice.lstToString(set.iteration_vars, BVariable.pointerToString);
    str := str + "\n### Residual Equations:\n" + Slice.lstToString(set.residual_eqns, function Equation.pointerToString(str = ""));
    str := str + "\n### Inner Equations:\n" + List.toString(arrayList(set.innerEquations), function StrongComponent.toString(index = -1), "", "\t", "\n\t", "");
    if Util.isSome(set.jac) then
      str := str + "\n" + BJacobian.toString(Util.getOption(set.jac), "NLS");
    end if;
  end toString;

  function main
    "Wrapper function for any tearing function. This will be
    called during simulation and gets the corresponding subfunction from
    Config."
    extends Module.wrapper;
    input System.SystemType systemType;
  protected
    constant Module.tearingInterface func = getModule();
    FunctionTree funcTree;
  algorithm
    if Flags.isSet(Flags.TEARING_DUMP) then
      print(StringUtil.headline_1("[" + System.System.systemTypeString(systemType) + "] Tearing") + "\n");
    end if;
    bdae := match (systemType, bdae)
      local
        list<System.System> systems;
        VariablePointers variables;
        Pointer<Integer> eq_index;

      case (NBSystem.SystemType.ODE, BackendDAE.MAIN(ode = systems, funcTree = funcTree, varData = BVariable.VAR_DATA_SIM(variables = variables), eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree, variables, eq_index, systemType);
          bdae.ode := systems;
          bdae.funcTree := funcTree;
      then bdae;

      case (NBSystem.SystemType.INI, BackendDAE.MAIN(init = systems, funcTree = funcTree, varData = BVariable.VAR_DATA_SIM(variables = variables), eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree, variables, eq_index, systemType);
          bdae.init := systems;
          if Util.isSome(bdae.init_0) then
            (systems, funcTree) := tearingTraverser(Util.getOption(bdae.init_0), func, funcTree, variables, eq_index, systemType);
            bdae.init_0 := SOME(systems);
          end if;
          bdae.funcTree := funcTree;
      then bdae;

      case (NBSystem.SystemType.DAE, BackendDAE.MAIN(dae = SOME(systems), funcTree = funcTree, varData = BVariable.VAR_DATA_SIM(variables = variables), eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree, variables, eq_index, systemType);
          bdae.dae := SOME(systems);
          bdae.funcTree := funcTree;
      then bdae;

    // ToDo: all the other cases: e.g. Jacobian, Hessian
    end match;
  end main;

  function implicit
    input output StrongComponent comp     "the suspected algebraic loop.";
    input output FunctionTree funcTree    "Function call bodies";
    input output Integer index            "current unique loop index";
    input System.SystemType systemType = NBSystem.SystemType.ODE   "system type";
  algorithm
    (comp, funcTree, index) := match comp
      // create implicit equations
      case StrongComponent.SINGLE_COMPONENT()
      then tearingNone(StrongComponent.ALGEBRAIC_LOOP(
            idx     = index,
            strict  = singleImplicit(comp.var, comp.eqn),
            casual  = NONE(),
            linear  = false,
            mixed   = false,
            status  = NBSolve.Status.IMPLICIT), funcTree, index, VariablePointers.empty(), Pointer.create(0), systemType);

      case StrongComponent.MULTI_COMPONENT()
      then tearingNone(StrongComponent.ALGEBRAIC_LOOP(
            idx     = index,
            strict  = singleImplicit(List.first(comp.vars), comp.eqn), // this is wrong! need to take all vars
            casual  = NONE(),
            linear  = false,
            mixed   = false,
            status  = NBSolve.Status.IMPLICIT), funcTree, index, VariablePointers.empty(), Pointer.create(0), systemType);

      // do nothing otherwise
      else (comp, funcTree, index);
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
    output Module.tearingInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.JACOBIAN)
  algorithm
    (func) := match flag
      case "default"  then (tearingNone);
      case "none"     then (tearingNone);
      case "minimal"  then (tearingNone);
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
    input list<System.System> systems;
    input Module.tearingInterface func;
    output list<System.System> new_systems = {};
    input output FunctionTree funcTree;
    input VariablePointers variables;
    input Pointer<Integer> eq_index;
    input System.SystemType systemType;
  protected
    array<StrongComponent> strongComponents;
    StrongComponent tmp;
    Integer idx = 0;
  algorithm
    for syst in systems loop
      if isSome(syst.strongComponents) then
        SOME(strongComponents) := syst.strongComponents;
        for i in 1:arrayLength(strongComponents) loop
          (tmp, funcTree, idx) := func(strongComponents[i], funcTree, idx, variables, eq_index, systemType);
          // only update if it changed
          if not referenceEq(tmp, strongComponents[i]) then
            arrayUpdate(strongComponents, i, tmp);
          end if;
        end for;
        syst.strongComponents := SOME(strongComponents);
      end if;
      new_systems := syst :: new_systems;
    end for;
    new_systems := listReverse(new_systems);
  end tearingTraverser;

  function tearingNone extends Module.tearingInterface;
    // does nothing but set index and call the jacobian
  protected
    list<StrongComponent> residual_comps;
    Option<Jacobian> jacobian;
    Tearing strict;
  protected
    list<Slice<EquationPointer>> tmp;
    list<list<Slice<EquationPointer>>> acc = {};
  algorithm
    (comp, index) := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        index := index + 1;
        comp.idx := index;

        for eqn in listReverse(strict.residual_eqns) loop
          tmp := Inline.inlineRecordSliceEquation(eqn, variables, eq_index, true);
          if listEmpty(tmp) then
            acc := {eqn} :: acc;
          else
            acc := tmp :: acc;
          end if;
        end for;

        // create residual equations
        strict.residual_eqns := list(Slice.apply(eqn, function Equation.createResidual(new = true)) for eqn in List.flatten(acc));
        comp.strict := strict;
        residual_comps := list(StrongComponent.fromSolvedEquationSlice(eqn) for eqn in strict.residual_eqns);

        // update jacobian to take slices (just to have correct inner variables and such)
        (jacobian, funcTree) := BJacobian.nonlinear(
          variables = VariablePointers.fromList(list(Slice.getT(var) for var in comp.strict.iteration_vars)),
          equations = EquationPointers.fromList(list(Slice.getT(eqn) for eqn in comp.strict.residual_eqns)),
          comps     = listArray(residual_comps),
          funcTree  = funcTree,
          name      = System.System.systemTypeString(systemType) + "_NLS_JAC_" + intString(index));

        strict.jac := jacobian;
        comp.strict := strict;
        if Flags.isSet(Flags.TEARING_DUMP) then
          print(StrongComponent.toString(comp) + "\n");
        end if;
      then (comp, index);
      else (comp, index);
    end match;
  end tearingNone;

  function tearingMinimal extends Module.tearingInterface;
    // only extracts discrete variables to be solved as inner equations and calls jacobian module
  protected
    list<StrongComponent> residual_comps;
    Option<Jacobian> jacobian;
    Tearing strict;
    list<Pointer<Variable>> vars_lst, cont_vars, disc_vars;
    list<Pointer<Equation>> eqns_lst, cont_eqns, disc_eqns;
    list<Slice<VariablePointer>> iter_lst;
    list<Slice<EquationPointer>> residual_lst;
    VariablePointers discreteVars;
    EquationPointers eqns;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> inner_comps, residual_comps;
  algorithm
    (comp, index) := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        index := index + 1;
        comp.idx := index;

        // ToDo: if other tearing modules have been used before
        //   we should not only look in residuals and iteration arrays.
        //   have minimal tearing explicitely as starting method?

        // Equation attributes update! -> discrete initial etc are not mutually exclusive
        //

        // split variables and equations in discrete and continuous
        vars_lst := list(Slice.getT(var) for var in strict.iteration_vars);
        eqns_lst := list(Slice.getT(eqn) for eqn in strict.residual_eqns);
        (cont_vars, disc_vars)  := List.splitOnTrue(vars_lst, BVariable.isContinuous);
        (cont_eqns, disc_eqns)  := List.splitOnTrue(eqns_lst, Equation.isContinuous);
        iter_lst                := list(Slice.SLICE(var, {}) for var in cont_vars);

        if listEmpty(disc_vars) and listEmpty(disc_eqns) then
          // if there are no discrete variables > don't do anything
          residual_lst    := strict.residual_eqns;
          inner_comps     := {};
        else
          // fail and report if length is not equal!
          if listLength(disc_vars) <> listLength(disc_eqns) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
              + " failed because there is an unequal amount of discrete variables and equations:\n"
              + List.toString(disc_vars, BVariable.pointerToString, "discrete variables", "\t", "\n\t", "\n\n")
              + List.toString(disc_eqns, function Equation.pointerToString(str = ""), "discrete equations", "\t", "\n\t", "\n\n")});
              fail();
          end if;
          // solve the equations for linear occurences of the discrete variables
          // it should be:
          // solve discrete vars <-> discrete eqs
          discreteVars    := VariablePointers.fromList(disc_vars);
          eqns            := EquationPointers.fromList(disc_eqns);

          (adj, SOME(funcTree)) := Adjacency.Matrix.create(discreteVars, eqns, NBAdjacency.MatrixType.PSEUDO, NBAdjacency.MatrixStrictness.LINEAR, SOME(funcTree));
          matching := Matching.regular(NBMatching.EMPTY_MATCHING, adj, true, false);
          (_, _, _, residual_lst) := Matching.getMatches(matching, NONE(), discreteVars, eqns);
          inner_comps := Sorting.tarjan(adj, matching, discreteVars, eqns);
        end if;

        // create residual equations
        strict.residual_eqns := list(Slice.apply(eqn, function Equation.createResidual(new = true)) for eqn in strict.residual_eqns);
        residual_comps := list(StrongComponent.fromSolvedEquationSlice(eqn) for eqn in strict.residual_eqns);

        // update jacobian to take slices (just to have correct inner variables and such)
        (jacobian, funcTree) := BJacobian.nonlinear(
          variables = VariablePointers.fromList(list(Slice.getT(var) for var in comp.strict.iteration_vars)),
          equations = EquationPointers.fromList(list(Slice.getT(eqn) for eqn in comp.strict.residual_eqns)),
          comps     = listArray(residual_comps),
          funcTree  = funcTree,
          name      = System.System.systemTypeString(systemType) + "_NLS_JAC_" + intString(index));

        strict.iteration_vars := iter_lst;
        strict.residual_eqns  := residual_lst;
        strict.innerEquations := listArray(inner_comps);
        strict.jac            := jacobian;
        comp.strict           := strict;
        if Flags.isSet(Flags.TEARING_DUMP) then
          print(StrongComponent.toString(comp) + "\n");
        end if;
      then (comp, index);
      else (comp, index);
    end match;
  end tearingMinimal;

/*
  function tearingMinimal extends Module.tearingInterface;
  protected
    list<StrongComponent> residual_comps;
    Option<Jacobian> jacobian;
    StrongComponent new_comp;
    list<Slice<EquationPointer>> residuals = {};
    list<Pointer<Variable>> cont_lst, disc_lst;
  algorithm
    (comp, index) := match comp
      case StrongComponent.ALGEBRAIC_LOOP() algorithm
        index := index + 1;
        comp.idx := index;

        //(cont_lst, disc_lst)  := List.splitOnTrue(comp.strict.residual_vars, BVariable.isContinuous);

        // create residual equations
        for eqn in listReverse(comp.strict.iteration_vars) loop
          residuals := Slice.apply(eqn, function Equation.createResidual(new = true)) :: residuals;
        end for;
        comp.strict := setResidualEqns(comp.strict, residuals);
        residual_comps := list(StrongComponent.fromSolvedEquationSlice(eqn) for eqn in comp.strict.residual_eqns);

        // update jacobian to take slices (just to have correct inner variables and such)
        (jacobian, funcTree) := BJacobian.nonlinear(
          variables = VariablePointers.fromList(list(Slice.getT(var) for var in comp.strict.iteration_vars)),
          equations = EquationPointers.fromList(list(Slice.getT(eqn) for eqn in comp.strict.residual_eqns)),
          comps     = listArray(residual_comps),
          funcTree  = funcTree,
          name      = System.System.systemTypeString(systemType) + "_NLS_JAC_" + intString(index));

          new_comp := StrongComponent.addLoopJacobian(comp, jacobian);
          if Flags.isSet(Flags.TEARING_DUMP) then
            print(StrongComponent.toString(comp) + "\n");
          end if;
      then (new_comp, index);
      else (comp, index);
    end match;
  end tearingMinimal;

  function tearingMinimalWork
    input String name;
    input list<Pointer<Variable>> variables;
    input list<Pointer<Equation>> equations;
    input Boolean mixed;
    output StrongComponent comp;
    input output FunctionTree funcTree;
    input output Integer index;
  protected
    list<Pointer<Variable>> cont_lst, disc_lst;
    list<Slice<VariablePointer>> iteration_lst;
    list<Slice<EquationPointer>> residual_lst;
    VariablePointers discreteVars;
    EquationPointers eqns;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> inner_comps, residual_comps;
    Tearing tearingSet;
    Option<Jacobian> jacobian;

  algorithm
    index := index + 1;

    (cont_lst, disc_lst)  := List.splitOnTrue(variables, BVariable.isContinuous);
    iteration_lst         := list(Slice.SLICE(var, {}) for var in cont_lst);
    if listEmpty(disc_lst) then
      residual_lst    := list(Slice.SLICE(eqn, {}) for eqn in equations);
      inner_comps     := {};
    else
      discreteVars    := VariablePointers.fromList(disc_lst);
      eqns            := EquationPointers.fromList(equations);

      (adj, SOME(funcTree)) := Adjacency.Matrix.create(discreteVars, eqns, NBAdjacency.MatrixType.PSEUDO, NBAdjacency.MatrixStrictness.LINEAR, SOME(funcTree));
      matching := Matching.regular(NBMatching.EMPTY_MATCHING, adj, true, false);
      (_, _, _, residual_lst) := Matching.getMatches(matching, NONE(), discreteVars, eqns);
      inner_comps := Sorting.tarjan(adj, matching, discreteVars, eqns);
    end if;

    // create residual equations
    residual_lst := list(Slice.apply(eqn, function Equation.createResidual(new = true)) for eqn in residual_lst);
    residual_comps := list(StrongComponent.fromSolvedEquationSlice(eqn) for eqn in residual_lst);

    tearingSet := TEARING_SET(iteration_lst, residual_lst, listArray(inner_comps), NONE());
    comp := StrongComponent.ALGEBRAIC_LOOP(index, tearingSet, NONE(), false, mixed, NBSolve.Status.IMPLICIT);

    // inner equations are part of the jacobian
    (jacobian, funcTree) := BJacobian.nonlinear(
      variables = VariablePointers.fromList(cont_lst),
      equations = EquationPointers.fromList(list(Slice.getT(res) for res in residual_lst)),
      comps     = listArray(listAppend(inner_comps, residual_comps)),
      funcTree  = funcTree,
      name      = name + intString(index)
    );

    comp := StrongComponent.addLoopJacobian(comp, jacobian);
    if Flags.isSet(Flags.TEARING_DUMP) and not listEmpty(disc_lst) then
      print(StrongComponent.toString(comp) + "\n");
    end if;
  end tearingMinimalWork;
*/
  annotation(__OpenModelica_Interface="backend");
end NBTearing;

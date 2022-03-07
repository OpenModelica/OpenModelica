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
  import NBEquation.{Equation, EquationPointer, EquationPointers, InnerEquation};
  import Jacobian = NBackendDAE.BackendDAE;
  import Matching = NBMatching;
  import Sorting = NBSorting;
  import StrongComponent = NBStrongComponent;
  import System = NBSystem;
  import NBVariable.VariablePointers;

  //Util imports
  import BackendUtil = NBBackendUtil;
  import StringUtil;

public
  record TEARING_SET
    list<Pointer<Variable>> iteration_vars        "the variables used for iteration";
    list<Slice<EquationPointer>> residual_eqns    "implicitely solved residual equations";
    array<InnerEquation> innerEquations           "array of matched equations and variables";
    Option<Jacobian> jac                          "optional jacobian";
  end TEARING_SET;

  function hash
    input Tearing tearing;
    input Integer mod;
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
    str := str + "### Iteration Variables:\n";
    for var in set.iteration_vars loop
      str := str + Variable.toString(Pointer.access(var), "\t") + "\n";
    end for;
    str := str + "\n### Residual Equations:\n" + Slice.lstToString(set.residual_eqns, function Equation.pointerToString(str = ""));
    str := str + "\n### Inner Equations:\n";
    for eqn in set.innerEquations loop
      str := str  + InnerEquation.toString(eqn, "\t") + "\n";
    end for;
    if Util.isSome(set.jac) then
      str := str + "\n" + BJacobian.toString(Util.getOption(set.jac), "NLS", true);
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

      case (NBSystem.SystemType.ODE, BackendDAE.MAIN(ode = systems, funcTree = funcTree))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree, systemType);
          bdae.ode := systems;
      then bdae;

      case (NBSystem.SystemType.INI, BackendDAE.MAIN(init = systems, funcTree = funcTree))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree, systemType);
          bdae.init := systems;
      then bdae;

      case (NBSystem.SystemType.DAE, BackendDAE.MAIN(dae = SOME(systems), funcTree = funcTree))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, func, funcTree, systemType);
          bdae.dae := SOME(systems);
      then bdae;

    // ToDo: all the other cases: e.g. Jacobian, Hessian
    end match;
  end main;

  function implicit extends Module.tearingInterface;
  algorithm
    (comp, funcTree, index) := match comp
      // create implicit equations
      case StrongComponent.SINGLE_EQUATION()
      then tearingNoneWork(
          name      = System.System.systemTypeString(systemType) + "_IMP_JAC_",
          variables = {comp.var},
          equations = {comp.eqn},
          mixed     = false,
          funcTree  = funcTree,
          index     = index
        );

      case StrongComponent.SINGLE_ARRAY()
      then tearingNoneWork(
          name      = System.System.systemTypeString(systemType) + "_IMP_JAC_",
          variables = {comp.var},
          equations = {comp.eqn},
          mixed     = false,
          funcTree  = funcTree,
          index     = index
        );

      case StrongComponent.SINGLE_RECORD_EQUATION()
      then tearingNoneWork(
          name      = System.System.systemTypeString(systemType) + "_IMP_JAC_",
          variables = comp.vars,
          equations = {comp.eqn},
          mixed     = false,
          funcTree  = funcTree,
          index     = index
        );

      // do nothing otherwise
      else (comp, funcTree, index);
    end match;
  end implicit;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.tearingInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.JACOBIAN)
  algorithm
    (func) := match flag
      case "default"  then (tearingMinimal);
      case "none"     then (tearingNone);
      case "minimal"  then (tearingMinimal);
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

protected
  // Traverser function
  function tearingTraverser
    input list<System.System> systems;
    input Module.tearingInterface func;
    output list<System.System> new_systems = {};
    input output FunctionTree funcTree;
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
          (tmp, funcTree, idx) := func(strongComponents[i], funcTree, idx, systemType);
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

  // Module body functions
  function tearingNone extends Module.tearingInterface;
  algorithm
    (comp, funcTree, index) := match comp
      // apply tearing if it is an algebraic loop
      case StrongComponent.ALGEBRAIC_LOOP()
      then tearingNoneWork(
          name      = System.System.systemTypeString(systemType) + "_NLS_JAC_",
          variables = comp.vars,
          equations = comp.eqns,
          mixed     = comp.mixed,
          funcTree  = funcTree,
          index     = index
        );

      // do nothing otherwise
      else (comp, funcTree, index);
    end match;
  end tearingNone;

  function tearingNoneWork
    input String name;
    input list<Pointer<Variable>> variables;
    input list<Pointer<Equation>> equations;
    input Boolean mixed;
    output StrongComponent comp;
    input output FunctionTree funcTree;
    input output Integer index;
  protected
    InnerEquation dummy;
    Tearing tearingSet;
    Option<Jacobian> jacobian;
    list<StrongComponent> residual_comps;
  algorithm
    index := index + 1;
    for eqn in equations loop
      Equation.createResidual(eqn);
    end for;
    dummy := BEquation.INNER_EQUATION(Pointer.create(Equation.DUMMY_EQUATION()), Pointer.create(NBVariable.DUMMY_VARIABLE));
    tearingSet := TEARING_SET(variables, list(Slice.SLICE(eqn, {}) for eqn in equations), arrayCreate(0, dummy), NONE());
    comp := StrongComponent.TORN_LOOP(index, tearingSet, NONE(), false, mixed, NBSolve.Status.IMPLICIT);
    residual_comps := list(StrongComponent.fromSolvedEquation(eqn) for eqn in equations);

    (jacobian, funcTree) := BJacobian.nonlinear(
      variables = VariablePointers.fromList(variables),
      equations = EquationPointers.fromList(equations),
      comps     = listArray(residual_comps),
      funcTree  = funcTree,
      name      = name + intString(index)
    );

    comp := StrongComponent.addLoopJacobian(comp, jacobian);
  end tearingNoneWork;

  function tearingMinimal extends Module.tearingInterface;
  algorithm
    (comp, funcTree, index) := match comp
      // apply tearing if it is an algebraic loop
      case StrongComponent.ALGEBRAIC_LOOP()
      then tearingMinimalWork(
          name      = System.System.systemTypeString(systemType) + "_NLS_JAC_",
          variables = comp.vars,
          equations = comp.eqns,
          mixed     = comp.mixed,
          funcTree  = funcTree,
          index     = index
        );

      // do nothing otherwise
      else (comp, funcTree, index);
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
    list<Slice<EquationPointer>> residual_lst;
    VariablePointers discreteVars;
    EquationPointers eqns;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> inner_comps, residual_comps;
    list<InnerEquation> innerEquations;
    Tearing tearingSet;
    Option<Jacobian> jacobian;

  algorithm
    index := index + 1;

    (cont_lst, disc_lst) := List.splitOnTrue(variables, BVariable.isContinuous);
    if listEmpty(disc_lst) then
      cont_lst        := variables;
      residual_lst    := list(Slice.SLICE(eqn, {}) for eqn in equations);
      inner_comps     := {};
      innerEquations  := {};
    else
      discreteVars    := VariablePointers.fromList(disc_lst);
      eqns            := EquationPointers.fromList(equations);

      // make ARRAY possible
      (adj, SOME(funcTree)) := Adjacency.Matrix.create(discreteVars, eqns, NBAdjacency.MatrixType.PSEUDO, NBAdjacency.MatrixStrictness.LINEAR, SOME(funcTree));
      matching := Matching.regular(Matching.EMPTY_MATCHING(), adj, true, false);
      (_, _, _, residual_lst) := Matching.getMatches(matching, NONE(), discreteVars, eqns);
      inner_comps := Sorting.tarjan(adj, matching, discreteVars, eqns);
      innerEquations := list(BEquation.InnerEquation.fromStrongComponent(c) for c in inner_comps);
    end if;

    for res in residual_lst loop
      Slice.applyMutable(res, Equation.createResidual);
    end for;
    residual_comps := list(StrongComponent.fromSolvedEquation(Slice.getT(res)) for res in residual_lst);

    tearingSet := TEARING_SET(cont_lst, residual_lst, listArray(innerEquations), NONE());
    comp := StrongComponent.TORN_LOOP(index, tearingSet, NONE(), false, mixed, NBSolve.Status.IMPLICIT);

    // inner equations are part of the jacobian
    (jacobian, funcTree) := BJacobian.nonlinear(
      variables = VariablePointers.fromList(variables),
      equations = EquationPointers.fromList(equations),
      comps     = listArray(listAppend(inner_comps, residual_comps)),
      funcTree  = funcTree,
      name      = name + intString(index)
    );

    comp := StrongComponent.addLoopJacobian(comp, jacobian);
    if Flags.isSet(Flags.TEARING_DUMP) and not listEmpty(disc_lst) then
      print(StrongComponent.toString(comp) + "\n");
    end if;
  end tearingMinimalWork;

  annotation(__OpenModelica_Interface="backend");
end NBTearing;

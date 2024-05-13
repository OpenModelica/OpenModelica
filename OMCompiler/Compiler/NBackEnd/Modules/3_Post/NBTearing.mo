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
  import BEquation = NBEquation;
  import BJacobian = NBJacobian;
  import BVariable = NBVariable;
  import Causalize = NBCausalize;
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
    constant list<Module.tearingInterface> funcs = getModule();
    FunctionTree funcTree;
  algorithm
    if Flags.isSet(Flags.TEARING_DUMP) then
      print(StringUtil.headline_1("[" + System.System.systemTypeString(systemType) + "] Tearing") + "\n");
    end if;
    bdae := match (systemType, bdae)
      local
        list<System.System> systems;
        Pointer<Integer> eq_index;

      case (NBSystem.SystemType.ODE, BackendDAE.MAIN(ode = systems, funcTree = funcTree, eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, funcs, funcTree, eq_index, systemType);
          bdae.ode := systems;
          bdae.funcTree := funcTree;
      then bdae;

      case (NBSystem.SystemType.INI, BackendDAE.MAIN(init = systems, funcTree = funcTree, eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, funcs, funcTree, eq_index, systemType);
          bdae.init := systems;
          if Util.isSome(bdae.init_0) then
            (systems, funcTree) := tearingTraverser(Util.getOption(bdae.init_0), funcs, funcTree, eq_index, systemType);
            bdae.init_0 := SOME(systems);
          end if;
          bdae.funcTree := funcTree;
      then bdae;

      case (NBSystem.SystemType.DAE, BackendDAE.MAIN(dae = SOME(systems), funcTree = funcTree, eqData = BEquation.EQ_DATA_SIM(uniqueIndex = eq_index)))
        algorithm
          (systems, funcTree) := tearingTraverser(systems, funcs, funcTree, eq_index, systemType);
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
  protected
    // dummy adjacency matrix, dont need it for implicit
    Adjacency.Matrix dummy = Adjacency.EMPTY(NBAdjacency.MatrixStrictness.FULL);
    StrongComponent new_comp;
  algorithm
    (comp, dummy, funcTree, index) := match comp
      // create implicit equations
      case StrongComponent.SINGLE_COMPONENT() algorithm
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = singleImplicit(comp.var, comp.eqn),
          casual  = NONE(),
          linear  = false,
          mixed   = false,
          status  = NBSolve.Status.IMPLICIT);
      then finalize(new_comp, dummy, funcTree, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), systemType);

      case StrongComponent.MULTI_COMPONENT() algorithm
        new_comp := StrongComponent.ALGEBRAIC_LOOP(
          idx     = index,
          strict  = singleImplicit(List.first(comp.vars), comp.eqn), // this is wrong! need to take all vars
          casual  = NONE(),
          linear  = false,
          mixed   = false,
          status  = NBSolve.Status.IMPLICIT);
      then finalize(new_comp, dummy, funcTree, index, VariablePointers.empty(), EquationPointers.empty(), Pointer.create(0), systemType);

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
      case "cellier"        then {initialize, minimal, finalize};
      case "noTearing"      then {initialize, minimal, finalize};
      case "omcTearing"     then {initialize, minimal, finalize};
      case "minimalTearing" then {initialize, minimal, finalize};
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
    input list<Module.tearingInterface> funcs;
    output list<System.System> new_systems = {};
    input output FunctionTree funcTree;
    input Pointer<Integer> eq_index;
    input System.SystemType systemType;
  protected
    array<StrongComponent> strongComponents;
    StrongComponent tmp;
    Integer idx = 0;
    Adjacency.Matrix full "full adjacency matrix containing solvability info";
  algorithm
    for syst in systems loop
      if isSome(syst.strongComponents) and isSome(syst.adjacencyMatrix) then
        SOME(strongComponents) := syst.strongComponents;
        SOME(full) := syst.adjacencyMatrix;
        for i in 1:arrayLength(strongComponents) loop
          // each module has a list of functions that need to be applied
          tmp := strongComponents[i];
          for func in funcs loop
            (tmp, full, funcTree, idx) := func(tmp, full, funcTree, idx, syst.unknowns, syst.equations, eq_index, systemType);
          end for;
          // only update if it changed
          if not referenceEq(tmp, strongComponents[i]) then
            arrayUpdate(strongComponents, i, tmp);
          end if;
        end for;
        syst.strongComponents := SOME(strongComponents);
        syst.adjacencyMatrix := SOME(full);
      end if;
      new_systems := syst :: new_systems;
    end for;
    new_systems := listReverse(new_systems);
  end tearingTraverser;

  function initialize extends Module.tearingInterface;
  protected
    Tearing strict;
    list<Pointer<Variable>> vars_lst;
    list<Pointer<Equation>> eqns_lst;
    UnorderedSet<ComponentRef> vars_set         "all loop vars, used to determine solvability";
    UnorderedMap<ComponentRef, Integer> v, e    "all loop vars and equations map";
  algorithm
    (comp, full, index) := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        index := index + 1;
        comp.idx := index;

        // get all loop variables and equations
        vars_lst := list(Slice.getT(var) for var in strict.iteration_vars);
        eqns_lst := list(Slice.getT(eqn) for eqn in strict.residual_eqns);

        // the set of all loop variables used to determine solvability
        vars_set  := UnorderedSet.fromList(list(BVariable.getVarName(var) for var in vars_lst), ComponentRef.hash, ComponentRef.isEqual);

        // the sets of discrete variables and discrete equations
        v         := UnorderedMap.subMap(variables.map, list(BVariable.getVarName(var) for var in vars_lst));
        e         := UnorderedMap.subMap(equations.map, list(Equation.getEqnName(eqn) for eqn in eqns_lst));

        // refining the adjacency matrix by updating solvability information using differentiation
        (full, funcTree)  := Adjacency.Matrix.refine(full, funcTree, v, e, variables, equations, vars_set);
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
    list<Slice<EquationPointer>> tmp;
    list<list<Slice<EquationPointer>>> acc = {};
    String tag;
  algorithm
    comp := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // inline potential records
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

        tag := if comp.linear then "_LS_JAC_" else "_NLS_JAC_";
        // create residual equations
        residual_comps := list(StrongComponent.fromSolvedEquationSlice(eqn) for eqn in strict.residual_eqns);
        // update jacobian to take slices (just to have correct inner variables and such)
        (jacobian, funcTree) := BJacobian.nonlinear(
          variables = VariablePointers.fromList(list(Slice.getT(var) for var in strict.iteration_vars)),
          equations = EquationPointers.fromList(list(Slice.getT(eqn) for eqn in strict.residual_eqns)),
          comps     = arrayAppend(strict.innerEquations,listArray(residual_comps)),
          funcTree  = funcTree,
          name      = System.System.systemTypeString(systemType) + tag + intString(index));
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
    list<Slice<EquationPointer>> residual_lst;
    Adjacency.Matrix adj;
    Matching matching;
    list<StrongComponent> inner_comps;
    UnorderedMap<ComponentRef, Integer> v, e            "discrete variables and equations we have to refine";
  algorithm
    comp := match comp
      case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
        // split equations and variables for discretes and continuous
        vars_lst := list(Slice.getT(var) for var in strict.iteration_vars);
        eqns_lst := list(Slice.getT(eqn) for eqn in strict.residual_eqns);
        (cont_vars, disc_vars)  := List.splitOnTrue(vars_lst, BVariable.isContinuous);
        (cont_eqns, disc_eqns)  := List.splitOnTrue(eqns_lst, Equation.isContinuous);

        if listLength(disc_vars) <> listLength(disc_eqns) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed because there is an unequal amount of discrete variables and equations:\n"
            + List.toString(disc_vars, BVariable.pointerToString, "discrete variables", "\t", "\n\t", "\n\n")
            + List.toString(disc_eqns, function Equation.pointerToString(str = ""), "discrete equations", "\t", "\n\t", "\n\n")});
            fail();
        end if;

        if not listEmpty(disc_vars) then
          comp.mixed := true;

          // the sets of discrete variables and discrete equations
          v         := UnorderedMap.subMap(variables.map, list(BVariable.getVarName(var) for var in disc_vars));
          e         := UnorderedMap.subMap(equations.map, list(Equation.getEqnName(eqn) for eqn in disc_eqns));

          // match the discretes to create inner components
          adj         := Adjacency.Matrix.fromFull(full, v, e, equations, NBAdjacency.MatrixStrictness.MATCHING);
          matching    := Matching.regular(NBMatching.EMPTY_MATCHING, adj, true, true);
          adj         := Adjacency.Matrix.upgrade(adj, full, v, e, equations, NBAdjacency.MatrixStrictness.SORTING);
          inner_comps := Sorting.tarjan(adj, matching, variables, equations); //probably need other variables and equations here?
          strict.innerEquations := listArray(inner_comps);

          // create residuals equations and iteration variables
          (_, _, _, residual_lst) := Matching.getMatches(matching, Adjacency.Matrix.getMappingOpt(full), variables, equations);
          strict.residual_eqns    := residual_lst;
          strict.iteration_vars   := list(Slice.SLICE(var, {}) for var in cont_vars);
          comp.strict := strict;
        end if;
      then comp;
      else comp;
    end match;
  end minimal;

  function checkLinearity
    input Adjacency.Matrix full;
    input UnorderedMap<ComponentRef, Integer> v;
    input UnorderedMap<ComponentRef, Integer> e;
    output Boolean linear = true;
  protected
    list<ComponentRef> var_lst = UnorderedMap.keyList(v);
  algorithm
    linear := match full
      case Adjacency.Matrix.FULL() algorithm
        for eqn_idx in UnorderedMap.valueList(e) loop
          for var in var_lst loop
            if UnorderedSet.contains(var, full.occurences[eqn_idx]) and Solvability.nonlinearOrImplicit(UnorderedMap.getSafe(var, full.solvabilities[eqn_idx], sourceInfo())) then
              linear := false; break;
            end if;
          end for;
        end for;
      then true;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected type full, got type " + Adjacency.Matrix.strictnessString(Adjacency.Matrix.getStrictness(full)) + "."});
      then fail();
    end match;
  end checkLinearity;

  annotation(__OpenModelica_Interface="backend");
end NBTearing;

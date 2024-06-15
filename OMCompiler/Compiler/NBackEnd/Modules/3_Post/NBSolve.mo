/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2021, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBSolve
" file:         NBSolve.mo
  package:      NBSolve
  description:  This file contains all functions for the solving process.
"

import Module = NBModule;

public
  // OF imports
  import AvlSetPath;

  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFlatten.FunctionTree;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Variable = NFVariable;

  // backend imports
  import BackendDAE = NBackendDAE;
  import BackendUtil = NBBackendUtil;
  import Causalize = NBCausalize;
  import Differentiate = NBDifferentiate;
  import NBEquation.{Equation, EquationPointer, EquationPointers, EqData, IfEquationBody, WhenEquationBody, WhenStatement, SlicingStatus};
  import NBVariable.{VariablePointer, VariablePointers, VarData};
  import BVariable = NBVariable;
  import Replacements = NBReplacements;
  import Slice = NBSlice;
  import StrongComponent = NBStrongComponent;
  import NBSystem.{System, SystemType};
  import Tearing = NBTearing;

  type Status = enumeration(UNPROCESSED, EXPLICIT, IMPLICIT, UNSOLVABLE);

  function statusString
    input Status status;
    output String str;
  algorithm
    str := match status
      case Status.UNPROCESSED then "Solve.UNPROCESSED";
      case Status.EXPLICIT    then "Solve.EXPLICIT";
      case Status.IMPLICIT    then "Solve.IMPLICIT";
      case Status.UNSOLVABLE  then "Solve.UNSOLVABLE";
    end match;
  end statusString;

  function main
    "solves each strong component and creates ALIAS strong components for each one already solved the exact same way."
    extends Module.wrapper;
  protected
    Pointer<FunctionTree> funcTree_ptr;
    Pointer<Integer> implicit_index_ptr = Pointer.create(1);
    type StrongComponentLst = list<StrongComponent>;
    UnorderedMap<StrongComponent, list<StrongComponent>> duplicate_map = UnorderedMap.new<StrongComponentLst>(StrongComponent.hash, StrongComponent.isEqual);
  protected
    StrongComponent unsolved;
    list<StrongComponent> solved;
  algorithm
    bdae := match bdae

      case BackendDAE.MAIN() algorithm
        funcTree_ptr    := Pointer.create(bdae.funcTree);
        // The order here is important. Whatever comes first is declared the "original", same components afterwards will be alias
        // Has to be the same order as in SimCode!
        bdae.init       := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.init);
        if Util.isSome(bdae.init_0) then
          bdae.init_0   := SOME(list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in Util.getOption(bdae.init_0)));
        end if;
        bdae.ode        := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.ode);
        bdae.algebraic  := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.algebraic);
        bdae.ode_event  := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.ode_event);
        bdae.alg_event  := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.alg_event);
        bdae.funcTree   := Pointer.access(funcTree_ptr);

        /*
        // for now slicing just converts to generic, so deactivate
        // also: referenceEq doesnt work on alias components
        if Flags.isSet(Flags.DUMP_SLICE) then
          for tpl in UnorderedMap.toList(duplicate_map) loop
            (unsolved, solved) := tpl;
            if not referenceEq(List.first(solved), unsolved) then
              print("[dumpSlice] The block:\n" + StrongComponent.toString(unsolved) + "\n"
                + "[dumpSlice] got sliced to:\n" + List.toString(solved, function StrongComponent.toString(index = -1), "", "", "\n", "") + "\n\n");
            end if;
          end for;
        end if;*/

      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
      then fail();
    end match;
  end main;

  function solveSystem
    input output System system;
    input Pointer<FunctionTree> funcTree_ptr;
    input Pointer<Integer> implicit_index_ptr;
    input UnorderedMap<StrongComponent, list<StrongComponent>> duplicate_map;
  protected
    type EquationPointerList = list<Pointer<Equation>>;
    UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map = UnorderedMap.new<EquationPointerList>(ComponentRef.hash, ComponentRef.isEqual);
    list<StrongComponent> solved_comps = {};
    FunctionTree funcTree = Pointer.access(funcTree_ptr);
    Integer implicit_index = Pointer.access(implicit_index_ptr);
    array<StrongComponent> new_comps;
    Pointer<Integer> sliced_idx, comp_idx = Pointer.create(1);
    ComponentRef name;
    list<Pointer<Equation>> sliced_eqns;
  algorithm
    if Util.isSome(system.strongComponents) then
      for comp in Util.getOption(system.strongComponents) loop
        solved_comps := match UnorderedMap.get(comp, duplicate_map)
          local list<StrongComponent> alias_comps;
          case SOME(alias_comps) then listAppend(alias_comps, solved_comps); // strong component already solved -> get alias comps
          else algorithm
            // solve strong component -> create alias comps
            (alias_comps, funcTree, implicit_index) := solveStrongComponent(comp, funcTree, system.systemType, implicit_index, slicing_map);
            UnorderedMap.add(comp, list(StrongComponent.createAlias(system.systemType, system.partitionIndex, comp_idx, c) for c in alias_comps), duplicate_map);
          then listAppend(alias_comps, solved_comps);
        end match;
      end for;
      system.strongComponents := SOME(listArray(listReverse(solved_comps)));
      // update sliced eqn names
      for tpl in UnorderedMap.toList(slicing_map) loop
        (name, sliced_eqns) := tpl;
        if not listEmpty(sliced_eqns) then
          sliced_idx := Pointer.create(1);
          for eqn_ptr in sliced_eqns loop
            Equation.subIdxName(eqn_ptr, sliced_idx);
          end for;
        end if;
      end for;
      Pointer.update(funcTree_ptr, funcTree);
      Pointer.update(implicit_index_ptr, implicit_index);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " cannot solve system without strong components: " + System.toString(system) + "\n\n"});
      fail();
    end if;
  end solveSystem;

  function solveStrongComponent
    input StrongComponent comp;
    output list<StrongComponent> solved_comps = {};
    input output FunctionTree funcTree;
    input SystemType systemType;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
  protected
    Status solve_status;
    StrongComponent implicit_comp;
  algorithm
    try
      (solved_comps, solve_status) := match comp
        local
          Equation eqn;
          Slice<VariablePointer> var_slice;
          Slice<EquationPointer> eqn_slice;
          Pointer<Equation> eqn_ptr;
          ComponentRef var_cref, eqn_cref;
          SlicingStatus slicing_status;
          list<Integer> sizes, eqn_indices;
          UnorderedMap<ComponentRef, Expression> replacements;
          Integer index;
          list<Equation> entwined_eqns = {};
          list<Pointer<Equation>> rest, sliced_eqns = {};
          StrongComponent generic_comp;
          list<StrongComponent> entwined_slices = {};
          Tearing strict;
          list<StrongComponent> tmp, inner_comps = {};

        case StrongComponent.SINGLE_COMPONENT() algorithm
          (eqn, funcTree, solve_status, implicit_index) := solveSingleStrongComponent(Pointer.access(comp.eqn), Pointer.access(comp.var), funcTree, systemType, implicit_index, slicing_map);
        then ({StrongComponent.SINGLE_COMPONENT(comp.var, Pointer.create(eqn), solve_status)}, solve_status);

        case StrongComponent.MULTI_COMPONENT() algorithm
          (eqn_slice, funcTree, solve_status, implicit_index) := solveMultiStrongComponent(comp.eqn, comp.vars, funcTree, systemType, implicit_index, slicing_map);
        then ({StrongComponent.MULTI_COMPONENT(comp.vars, eqn_slice, solve_status)}, solve_status);

        case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
          for inner_comp in listReverse(arrayList(strict.innerEquations)) loop
            (tmp, funcTree, implicit_index) := solveStrongComponent(inner_comp, funcTree, systemType, implicit_index, slicing_map);
            inner_comps := listAppend(tmp, inner_comps);
          end for;
          strict.innerEquations := listArray(inner_comps);
          comp.strict := strict;
          comp.status := Status.IMPLICIT;
        then ({comp}, Status.IMPLICIT);

        case StrongComponent.SLICED_COMPONENT(eqn = eqn_slice) guard(Equation.isForEquation(Slice.getT(eqn_slice))) algorithm
          (generic_comp, funcTree, solve_status, implicit_index) := solveGenericEquation(comp, funcTree, systemType, implicit_index, slicing_map);
        then ({generic_comp}, solve_status);

        /* currently not used */
        case StrongComponent.SLICED_COMPONENT(eqn = eqn_slice) guard(Equation.isForEquation(Slice.getT(eqn_slice))) algorithm
          eqn_ptr := Slice.getT(eqn_slice);
          (eqn_ptr, slicing_status, solve_status, funcTree) := Equation.slice(eqn_ptr, eqn_slice.indices, SOME(comp.var_cref), funcTree);
          if slicing_status == NBEquation.SlicingStatus.FAILURE then
            // if slicing failed -> scalarize;
            (eqn, funcTree, solve_status, implicit_index, _) := solveEquation(Pointer.access(Slice.getT(eqn_slice)), comp.var_cref, funcTree, systemType, implicit_index, slicing_map);
            Pointer.update(eqn_ptr, eqn);
            sizes := Equation.sizes(eqn_ptr);
            replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
            for index in listReverse(eqn_slice.indices) loop
              (eqn, funcTree) := Equation.singleSlice(eqn_ptr, index, sizes, ComponentRef.EMPTY(), replacements, funcTree);
              sliced_eqns := Pointer.create(eqn) :: sliced_eqns;
            end for;
            sliced_eqns := listReverse(sliced_eqns);
            solved_comps := list(StrongComponent.fromSolvedEquationSlice(Slice.SLICE(eqn, {})) for eqn in sliced_eqns);
          else
            Pointer.update(eqn_ptr, Equation.splitIterators(Pointer.access(eqn_ptr)));
            sliced_eqns := {eqn_ptr};
            solved_comps := {StrongComponent.SLICED_COMPONENT(comp.var_cref, comp.var, Slice.SLICE(eqn_ptr, {}), solve_status)};
          end if;

          // safe the slicing replacement in the map
          eqn_cref := Equation.getEqnName(eqn_ptr);
          sliced_eqns := listAppend(UnorderedMap.getOrDefault(eqn_cref, slicing_map, {}), sliced_eqns);
          UnorderedMap.add(eqn_cref, sliced_eqns, slicing_map);

        then (solved_comps, solve_status);

        case StrongComponent.SLICED_COMPONENT(var = var_slice, eqn = eqn_slice) guard(Equation.isArrayEquation(Slice.getT(eqn_slice))) algorithm
          // array equation solved for the a sliced variable.
          // get all slices of the variable ocurring in the equation and select the slice that fits the indices
          eqn := Pointer.access(Slice.getT(eqn_slice));
          (var_cref, solve_status) := getVarSlice(BVariable.getVarName(Slice.getT(var_slice)), eqn);

          if solve_status < Status.UNSOLVABLE then
            (eqn, funcTree, solve_status, implicit_index, _) := solveEquation(eqn, var_cref, funcTree, systemType, implicit_index, slicing_map);
            comp.eqn := Slice.SLICE(Pointer.create(eqn), {});
            comp.status := solve_status;
          end if;
        then ({comp}, solve_status);

        case StrongComponent.SLICED_COMPONENT() algorithm
          // just a regular equation solved for a sliced variable
          // use cref instead of var because it has subscripts!
          (eqn, funcTree, solve_status, implicit_index) := solveSingleStrongComponent(Pointer.access(Slice.getT(comp.eqn)), Variable.fromCref(comp.var_cref), funcTree, systemType, implicit_index, slicing_map);
          comp.eqn := Slice.SLICE(Pointer.create(eqn), {});
          comp.status := solve_status;
        then ({comp}, solve_status);

        /* for now handle all entwined equations generically and don't try to solve */
        case StrongComponent.ENTWINED_COMPONENT() algorithm
          for slice in comp.entwined_slices loop
            (generic_comp, funcTree, solve_status, implicit_index) := solveGenericEquation(slice, funcTree, systemType, implicit_index, slicing_map);
            // make loop on any solve_status != explicit
            entwined_slices := generic_comp :: entwined_slices;
          end for;
          comp.entwined_slices := listReverse(entwined_slices);
        then ({comp}, NBSolve.Status.EXPLICIT);

        /* currently not used */
        case StrongComponent.ENTWINED_COMPONENT() algorithm
          // slice each entwined equation individually
          for slice in comp.entwined_slices loop
            StrongComponent.SLICED_COMPONENT(var_cref = var_cref, eqn = eqn_slice) := slice;
            (eqn_ptr, slicing_status, solve_status, funcTree) := Equation.slice(Slice.getT(eqn_slice), eqn_slice.indices, SOME(var_cref), funcTree);
            if slicing_status == NBEquation.SlicingStatus.FAILURE then break; end if;
            Equation.renameIterators(eqn_ptr, "$i");
            eqn := Pointer.access(eqn_ptr);
            entwined_eqns := Equation.splitIterators(eqn) :: entwined_eqns;
          end for;

          if slicing_status == NBEquation.SlicingStatus.FAILURE then
            // if slicing failed -> scalarize;
            // first solve all equation bodies accordingly
            for slice in comp.entwined_slices loop
              StrongComponent.SLICED_COMPONENT(var_cref = var_cref, eqn = eqn_slice) := slice;
              (eqn, funcTree, solve_status, implicit_index, _) := solveEquation(Pointer.access(Slice.getT(eqn_slice)), var_cref, funcTree, systemType, implicit_index, slicing_map);
              Pointer.update(eqn_ptr, eqn);
            end for;
            replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
            for tpl in comp.entwined_tpl_lst loop
              (eqn_ptr, index) := tpl;
              // do this more efficiently! (sizes beforehand?)
              sizes := Equation.sizes(eqn_ptr);
              (eqn, funcTree) := Equation.singleSlice(eqn_ptr, index, sizes, ComponentRef.EMPTY(), replacements, funcTree);
              sliced_eqns := Pointer.create(eqn) :: sliced_eqns;
            end for;
            sliced_eqns := listReverse(sliced_eqns);
            solved_comps := list(StrongComponent.fromSolvedEquationSlice(Slice.SLICE(eqn, {})) for eqn in sliced_eqns);
          else
            // entwine the equations as far as possible
            entwined_eqns := Equation.entwine(listReverse(entwined_eqns));
            sliced_eqns := list(Pointer.create(eqn) for eqn in entwined_eqns);
            solved_comps := list(StrongComponent.fromSolvedEquationSlice(Slice.SLICE(eqn, {})) for eqn in sliced_eqns);
          end if;

          // safe the slicing replacement in the map
          // -> just use the first name as replacement for all of them and all other with empty lists
          eqn_ptr :: rest := sliced_eqns;
          eqn_cref := Equation.getEqnName(eqn_ptr);
          sliced_eqns := listAppend(UnorderedMap.getOrDefault(eqn_cref, slicing_map, {}), sliced_eqns);
          UnorderedMap.add(eqn_cref, sliced_eqns, slicing_map);

          // empty for all others (do not overwrite if it exists)
          if not listEmpty(rest) then
            for eqn_ptr in rest loop
              eqn_cref := Equation.getEqnName(eqn_ptr);
              UnorderedMap.tryAdd(eqn_cref, {}, slicing_map);
            end for;
          end if;
        then (solved_comps, solve_status);

        else ({comp}, Status.UNSOLVABLE);
      end match;
    else
      // this fails in the next case because of the unsolvable status
      (solved_comps, solve_status) := ({comp}, Status.UNSOLVABLE);
    end try;

    // solve implicit equation (algebraic loop is always implicit)
    if solve_status == Status.IMPLICIT and listLength(solved_comps) == 1 then
      (implicit_comp, funcTree, implicit_index)  := Tearing.implicit(
        comp        = List.first(solved_comps),
        funcTree    = funcTree,
        index       = implicit_index,
        systemType  = systemType
      );
      solved_comps := {implicit_comp};
    elseif solve_status > Status.EXPLICIT then
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed with status = " + statusString(solve_status)
        + " while trying to solve following strong component:\n" + StrongComponent.toString(comp) + "\n"});
      fail();
    end if;
  end solveStrongComponent;

  function solveGenericEquation
    input output StrongComponent comp;
    input output FunctionTree funcTree;
    input SystemType systemType;
    output Status solve_status;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
  algorithm
    (comp, solve_status) := match comp
      local
        Slice<EquationPointer> eqn_slice;
        Equation eqn;
      case StrongComponent.SLICED_COMPONENT(eqn = eqn_slice) guard(Equation.isForEquation(Slice.getT(eqn_slice))) algorithm
        (eqn, funcTree, solve_status, implicit_index, _) := solveEquation(Pointer.access(Slice.getT(eqn_slice)), comp.var_cref, funcTree, systemType, implicit_index, slicing_map);
        // if solve_status not explicit -> algebraic loop with residual and Status.IMPLICIT
        eqn_slice := Slice.SLICE(Pointer.create(eqn), eqn_slice.indices);
      then (StrongComponent.GENERIC_COMPONENT(comp.var_cref, eqn_slice), Status.EXPLICIT);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + StrongComponent.toString(comp) + "\n"});
      then fail();
    end match;
  end solveGenericEquation;

  function solveSingleStrongComponent
    input output Equation eqn;
    input Variable var;
    input output FunctionTree funcTree;
    input SystemType systemType;
    output Status status;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
  algorithm
    if ComponentRef.isEmpty(var.name) then
      // empty variable name implies equation without return value
      (eqn, status) := (eqn, Status.EXPLICIT);
    else
      (eqn, funcTree, status, implicit_index, _) := solveEquation(eqn, var.name, funcTree, systemType, implicit_index, slicing_map);
    end if;
  end solveSingleStrongComponent;

  function solveMultiStrongComponent
    input output Slice<EquationPointer> eqn_slice;
    input list<Slice<VariablePointer>> var_slices;
    input output FunctionTree funcTree;
    input SystemType systemType;
    output Status status;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
  protected
    Equation eqn = Pointer.access(Slice.getT(eqn_slice));
  algorithm
    (eqn_slice, funcTree, status) := match eqn
      local
        list<Pointer<Variable>> vars = list(Slice.getT(v) for v in var_slices);
        Equation solved_eqn;
        IfEquationBody if_body;
        Expression lhs, rhs;
        ComponentRef var_cref;
        UnorderedSet<ComponentRef> record_crefs;

      case Equation.IF_EQUATION() algorithm
        (if_body, funcTree, status, implicit_index) := solveIfBody(eqn.body, VariablePointers.fromList(vars), funcTree, systemType, implicit_index, slicing_map);
        eqn.body := if_body;
      then (Slice.SLICE(Pointer.create(eqn), eqn_slice.indices), funcTree, status);

      // ToDo: inverse algorithms
      case Equation.ALGORITHM()
      then (Slice.SLICE(Pointer.clone(Slice.getT(eqn_slice)), eqn_slice.indices), funcTree, Status.EXPLICIT);

      // for now assume they are solved
      case Equation.WHEN_EQUATION()
      then (Slice.SLICE(Pointer.clone(Slice.getT(eqn_slice)), eqn_slice.indices), funcTree, Status.EXPLICIT);

      // solve tuple equations
      case Equation.RECORD_EQUATION() algorithm
        (solved_eqn, status) := match (eqn.lhs, eqn.rhs)
          local
            Expression exp;
          case (exp as Expression.TUPLE(), _) guard(tupleSolvable(exp.elements, vars)) then (eqn, Status.EXPLICIT);
          case (_, exp as Expression.TUPLE()) guard(tupleSolvable(exp.elements, vars)) algorithm
            eqn.rhs := eqn.lhs;
            eqn.lhs := exp;
          then (eqn, Status.EXPLICIT);
          else algorithm
            // check if all belong to the same record
            record_crefs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
            for var_slice in var_slices loop
              (var_cref, status) := getVarSlice(BVariable.getVarName(Slice.getT(var_slice)), eqn);
              UnorderedSet.add(var_cref, record_crefs);
              if status == Status.UNSOLVABLE then break; end if;
            end for;

            solved_eqn := match (UnorderedSet.toList(record_crefs), status)
              case ({var_cref}, Status.UNPROCESSED) algorithm
                (solved_eqn, funcTree, status, _) := solveBody(eqn, var_cref, funcTree);
              then solved_eqn;
              else eqn;
            end match;

          then (solved_eqn, status);
        end match;
      then (Slice.SLICE(Pointer.create(solved_eqn), eqn_slice.indices), funcTree, status);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for equation:\n" + Slice.toString(eqn_slice, function Equation.pointerToString(str = ""))});
      then fail();
    end match;
  end solveMultiStrongComponent;

  function solveEquation
    input output Equation eqn;
    input ComponentRef cref;
    input output FunctionTree funcTree;
    input SystemType systemType;
    output Status status;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    output Boolean invertRelation     "If the equation represents a relation, this tells if the sign should be inverted";
  algorithm
    (eqn, funcTree, status, invertRelation) := match eqn
      local
        Equation body;
        Slice<EquationPointer> body_slice;
        Pointer<Variable> indexed_var;

      // For equations are expected to only have one body equation at this point
      case Equation.FOR_EQUATION(body = {body as Equation.IF_EQUATION()}) algorithm
        // create indexed variable to trick matching algorithm to solve for it
        indexed_var := BVariable.makeVarPtrCyclic(BVariable.getVar(cref), cref);
        (body_slice, funcTree, status, implicit_index) := solveMultiStrongComponent(Slice.SLICE(Pointer.create(body), {}), {Slice.SLICE(indexed_var, {})}, funcTree, systemType, implicit_index, slicing_map);
        eqn.body := {Pointer.access(Slice.getT(body_slice))};
      then (eqn, funcTree, status, false);

      case Equation.FOR_EQUATION(body = {body}) algorithm
        (body, funcTree, status, invertRelation) := solveBody(body, cref, funcTree);
        eqn.body := {body};
      then (eqn, funcTree, status, invertRelation);

      case Equation.FOR_EQUATION() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed to solve a for-equation with multiple body eqns for a single cref. Please iterate over body elements individually.\n"
            + "cref: " + ComponentRef.toString(cref) + " in equation:\n" + Equation.toString(eqn)});
      then fail();

      else solveBody(eqn, cref, funcTree);
    end match;
  end solveEquation;

  function solveBody
    input output Equation eqn;
    input ComponentRef cref;
    input output FunctionTree funcTree;
    output Status status;
    output Boolean invertRelation     "If the equation represents a relation, this tells if the sign should be inverted";
  protected
    Type ty;
    ComponentRef fixed_cref;
    Expression residual, derivative;
    Differentiate.DifferentiationArguments diffArgs;
    Operator divOp, uminOp;
  algorithm
    // fix crefs where the array is of size one
    fixed_cref := ComponentRef.stripSubscriptsAll(cref);
    ty := ComponentRef.getSubscriptedType(fixed_cref, true);
    if Type.isArray(ty) and Type.sizeOf(ty) == 1 then
      fixed_cref := getVarSlice(fixed_cref, eqn);
    else
      fixed_cref := cref;
    end if;
    (eqn, status, invertRelation) := solveSimple(eqn, fixed_cref);
    // if the equation does not have a simple structure try to solve with other strategies
    if status == Status.UNPROCESSED then
      residual := Equation.getResidualExp(eqn);
      diffArgs := Differentiate.DIFFERENTIATION_ARGUMENTS(
        diffCref        = fixed_cref,
        new_vars        = {},
        jacobianHT      = NONE(),
        diffType        = NBDifferentiate.DifferentiationType.SIMPLE,
        funcTree        = funcTree,
        scalarized      = false
      );
      (derivative, diffArgs) := Differentiate.differentiateExpressionDump(residual, diffArgs, getInstanceName());
      derivative := SimplifyExp.simplifyDump(derivative, true, getInstanceName());

      if Expression.isZero(derivative) then
        invertRelation := false;
        status := Status.UNSOLVABLE;
      elseif not Expression.containsCref(derivative, fixed_cref) then
        // If eqn is linear in cref:
        (eqn, funcTree) := solveLinear(eqn, residual, derivative, diffArgs, fixed_cref, funcTree);
        // If the derivative is negative, invert possible inequality sign
        invertRelation := Expression.isNegative(derivative);
        status := Status.EXPLICIT;
      else
        // If eqn is non-linear in cref
        if Flags.isSet(Flags.FAILTRACE) then
          Error.addCompilerWarning(getInstanceName() + " cref: " + ComponentRef.toString(fixed_cref)
            + " has to be solved implicitely in equation:\n" + Equation.toString(eqn));
        end if;
        invertRelation := false;
        status := Status.IMPLICIT;
      end if;
    end if;
    eqn := Equation.simplify(eqn, getInstanceName());
  end solveBody;

  function solveIfBody
    input output IfEquationBody body;
    input VariablePointers vars;
    input output FunctionTree funcTree;
    output Status status;
    input SystemType systemType;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
  protected
    IfEquationBody else_if;
    list<StrongComponent> comps, solved_comps;
    list<Pointer<Equation>> new_then_eqns = {};
  algorithm
    // causalize this branch equations for the unknowns
    (_, comps) := Causalize.simple(vars, EquationPointers.fromList(body.then_eqns));
    // solve each strong component explicitely and save equations to branch
    for comp in comps loop
      (solved_comps, funcTree, implicit_index) := solveStrongComponent(comp, funcTree, systemType, implicit_index, slicing_map);
      for solved_comp in solved_comps loop
        new_then_eqns := StrongComponent.toSolvedEquation(solved_comp) :: new_then_eqns;
      end for;
    end for;
    body.then_eqns := listReverse(new_then_eqns);
    // if there is an else branch -> go deeper
    if Util.isSome(body.else_if) then
      (else_if, funcTree, status, implicit_index) := solveIfBody(Util.getOption(body.else_if), vars, funcTree, systemType, implicit_index, slicing_map);
      body.else_if := SOME(else_if);
    else
      // StrongComponent.toSolvedEquation fails for everything that is not explicitely solvable so at this point one can assume it is
      status := Status.EXPLICIT;
    end if;
  end solveIfBody;

  function solveSimple
    input output Equation eqn;
    input ComponentRef cref;
    output Status status;
    output Boolean invertRelation;
  algorithm
    (eqn, status, invertRelation) := match eqn

      // check lhs and rhs for simple structure
      case Equation.SCALAR_EQUATION() then solveSimpleLhsRhs(eqn.lhs, eqn.rhs, cref, eqn);
      case Equation.ARRAY_EQUATION()  then solveSimpleLhsRhs(eqn.lhs, eqn.rhs, cref, eqn);
      case Equation.RECORD_EQUATION() then solveSimpleLhsRhs(eqn.lhs, eqn.rhs, cref, eqn);

      // ToDo: need to check if implicit
      case Equation.WHEN_EQUATION() then solveSimpleWhen(eqn.body, cref, eqn);

      // ToDo: more cases
      // ToDo: tuples, record elements, array constructors

      else (eqn, Status.UNPROCESSED, false);
    end match;
  end solveSimple;

protected
  function solveSimpleLhsRhs
    input Expression lhs;
    input Expression rhs;
    input ComponentRef cref;
    input output Equation eqn;
    output Status status;
    output Boolean invertRelation;
  algorithm
    (eqn, status, invertRelation) := match (lhs, rhs)
      local
        ComponentRef checkCref;
        Expression exp;
        list<Expression> elements;

      // always checks if exp is independent of cref!

      // 1. already solved
      // cref = exp
      case (Expression.CREF(cref = checkCref), exp)
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (eqn, Status.EXPLICIT, false);

      // 2. only swap lsh and rhs
      // exp = cref
      case (exp, Expression.CREF(cref = checkCref))
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      // 3.1 negate (MINUS) lhs and rhs
      // -cref = exp
      case (Expression.UNARY(exp = Expression.CREF(cref = checkCref)), exp)
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.updateLHSandRHS(eqn, Expression.negate(lhs), Expression.negate(rhs)), Status.EXPLICIT, false);

      // 3.2 negate (NOT) lhs and rhs
      // not cref = exp
      case (Expression.LUNARY(exp = Expression.CREF(cref = checkCref)), exp)
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.updateLHSandRHS(eqn, Expression.logicNegate(lhs), Expression.logicNegate(rhs)), Status.EXPLICIT, false);

      // 4.1 negate (MINUS) and swap lhs and rhs
      // exp = -cref
      case (exp, Expression.UNARY(exp = Expression.CREF(cref = checkCref)))
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.updateLHSandRHS(eqn, Expression.negate(rhs), Expression.negate(lhs)), Status.EXPLICIT, false);

      // 4.2 negate (NOT) and swap lhs and rhs
      // exp = not cref
      case (exp, Expression.LUNARY(exp = Expression.CREF(cref = checkCref)))
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.updateLHSandRHS(eqn, Expression.logicNegate(rhs), Expression.logicNegate(lhs)), Status.EXPLICIT, false);

      // simple solve tuples
      case (exp as Expression.TUPLE(), _) guard(tupleSolvable(exp.elements, {BVariable.getVarPointer(cref)})) then (eqn, Status.EXPLICIT, false);
      case (_, exp as Expression.TUPLE()) guard(tupleSolvable(exp.elements, {BVariable.getVarPointer(cref)})) then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, false);

      else (eqn, Status.UNPROCESSED, false);
    end match;
  end solveSimpleLhsRhs;

  function solveSimpleWhen
    input WhenEquationBody body;
    input ComponentRef cref;
    input Equation eqn;
    output Equation eqnOut = eqn "don't change the equation";
    output Status status;
    output Boolean invertRelation = false;
  algorithm
    for stmt in body.when_stmts loop
      status := match stmt
        local
          ComponentRef checkCref;
        case WhenStatement.ASSIGN(lhs = Expression.CREF(cref = checkCref))
          guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(stmt.rhs, cref))
        then Status.EXPLICIT;
        else Status.UNSOLVABLE;
      end match;

      if status == Status.EXPLICIT then
        break;
      end if;
    end for;
  end solveSimpleWhen;

  function solveLinear
    "author: kabdelhak, phannebohm
    solves a linear equation with one newton step
    0 = f(x)  ---> x = -f(0)/f`(0)"
    input output Equation eqn;
    input Expression residual;
    input Expression derivative;
    input Differentiate.DifferentiationArguments diffArgs;
    input ComponentRef cref;
    input output FunctionTree funcTree;
  protected
    Expression crefExp, numerator;
    Operator mulOp, uminOp;
    Type ty;
  algorithm
    funcTree := diffArgs.funcTree;
    crefExp := Expression.fromCref(cref);
    ty := ComponentRef.getSubscriptedType(cref, true);
    numerator := Replacements.single(residual, crefExp, Expression.makeZero(ty));
    mulOp := Operator.OPERATOR(ty, NFOperator.Op.MUL);
    uminOp := Operator.OPERATOR(ty, NFOperator.Op.UMINUS);
    // Set eqn: cref = - f/f'
    eqn := Equation.setLHS(eqn, crefExp);
    eqn := Equation.setRHS(eqn, Expression.UNARY(uminOp, Expression.MULTARY({numerator},{derivative}, mulOp)));
  end solveLinear;

  function tupleSolvable
    "checks if the tuple expression exactly represents the variables we need to solve for"
    input list<Expression> tuple_exps;
    input list<Pointer<Variable>> vars;
    output Boolean b = false;
  protected
    list<Expression> filtered_exps = list(e for e guard(not Expression.isWildCref(e)) in tuple_exps);
    UnorderedMap<ComponentRef, Boolean> map;
  algorithm
    if listLength(filtered_exps) == listLength(vars) then
      map := UnorderedMap.new<Boolean>(ComponentRef.hash, ComponentRef.isEqual);
      // add all variables to solve for
      for var in vars loop
        UnorderedMap.add(BVariable.getVarName(var), false, map);
      end for;
      // set the map entry for all variables that occur to true
      for exp in filtered_exps loop
        _ := match exp
          case Expression.CREF() guard(UnorderedMap.contains(exp.cref, map)) algorithm
            UnorderedMap.add(exp.cref, true, map);
          then ();
          else algorithm return; then ();
        end match;
      end for;
      // check if all variables occured
      b := List.all(UnorderedMap.valueList(map), Util.id);
    end if;
  end tupleSolvable;

  function getVarSlice
    input output ComponentRef var_cref;
    input Equation eqn;
    output Status solve_status;
  protected
    list<ComponentRef> slices_lst;
    Option<Pointer<Variable>> record_parent;
  algorithm
    slices_lst := Equation.collectCrefs(eqn, function Slice.getSliceCandidates(name = var_cref));

    if listLength(slices_lst) == 1 then
      var_cref := List.first(slices_lst);
      solve_status := Status.UNPROCESSED;
    else
      // check if the record parents occur (todo: vice versa?)
      record_parent := BVariable.getParent(BVariable.getVarPointer(var_cref));
      if Util.isSome(record_parent) then
        (var_cref, solve_status) := getVarSlice(BVariable.getVarName(Util.getOption(record_parent)), eqn);
      else
        // todo: choose best slice of list if more than one.
        // only fail for listLength == 0
        solve_status := Status.UNSOLVABLE;
      end if;
    end if;
  end getVarSlice;

  annotation(__OpenModelica_Interface="backend");
end NBSolve;

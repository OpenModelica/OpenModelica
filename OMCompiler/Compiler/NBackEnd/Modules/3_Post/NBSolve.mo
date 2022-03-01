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
  import Differentiate = NBDifferentiate;
  import NBEquation.{Equation, EquationPointer, EquationPointers, EqData, SlicingStatus};
  import NBVariable.VarData;
  import Replacements = NBReplacements;
  import Slice = NBSlice;
  import StrongComponent = NBStrongComponent;
  import NBSystem.{System, SystemType};
  import Tearing = NBTearing;

  type Status = enumeration(UNPROCESSED, EXPLICIT, IMPLICIT, UNSOLVABLE);
  type StrongComponentLst = list<StrongComponent>;
  type EquationPointerList = list<Pointer<Equation>>;

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
    UnorderedMap<StrongComponent, StrongComponentLst> duplicate_map = UnorderedMap.new<StrongComponentLst>(StrongComponent.hash, StrongComponent.isEqual);
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
        bdae.ode        := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.ode);
        bdae.algebraic  := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.algebraic);
        bdae.ode_event  := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.ode_event);
        bdae.alg_event  := list(solveSystem(sys, funcTree_ptr, implicit_index_ptr, duplicate_map) for sys in bdae.alg_event);
        bdae.funcTree   := Pointer.access(funcTree_ptr);


        if Flags.isSet(Flags.DUMP_SLICE) then
          for tpl in UnorderedMap.toList(duplicate_map) loop
            (unsolved, solved) := tpl;
            print("[dumpSlice] The block:\n" + StrongComponent.toString(unsolved) + "\n"
              + "[dumpSlice] got sliced to:\n" + List.toString(solved, function StrongComponent.toString(index = -1, showAlias = true), "", "", "\n", "") + "\n\n");
          end for;
        end if;

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
    input UnorderedMap<StrongComponent, StrongComponentLst> duplicate_map;
  protected
    UnorderedMap<ComponentRef, EquationPointerList> slicing_map = UnorderedMap.new<EquationPointerList>(ComponentRef.hash, ComponentRef.isEqual);
    list<StrongComponent> tmp, solved_comps = {};
    FunctionTree funcTree = Pointer.access(funcTree_ptr);
    Integer implicit_index = Pointer.access(implicit_index_ptr);
    array<StrongComponent> new_comps;
    Pointer<Integer> sliced_idx, comp_idx = Pointer.create(1);
    ComponentRef name;
    list<Pointer<Equation>> sliced_eqns;
  algorithm
    if Util.isSome(system.strongComponents) then
      for comp in Util.getOption(system.strongComponents) loop
        if UnorderedMap.contains(comp, duplicate_map) then
          // strong component already solved -> get alias comps
          solved_comps := listAppend(UnorderedMap.getSafe(comp, duplicate_map), solved_comps);
        else
          // solve strong component -> create alias comps
          (tmp, funcTree, implicit_index) := solveStrongComponent(comp, funcTree, system.systemType, implicit_index, slicing_map);
          UnorderedMap.add(comp, list(StrongComponent.createAlias(system.systemType, system.partitionIndex, comp_idx, tmp_c) for tmp_c in tmp), duplicate_map);
          solved_comps := listAppend(tmp, solved_comps);
        end if;
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
    input UnorderedMap<ComponentRef, EquationPointerList> slicing_map;
  protected
    Status solve_status;
    StrongComponent implicit_comp;
  algorithm
    (solved_comps, solve_status) := match comp
        local
          Equation eqn;
          Slice<EquationPointer> eqn_slice;
          Pointer<Equation> eqn_ptr;
          ComponentRef var_cref, eqn_cref;
          SlicingStatus slicing_status;
          list<Integer> sizes, eqn_indices;
          UnorderedMap<ComponentRef, Expression> replacements;
          Integer index;
          list<Equation> entwined_eqns = {};
          list<Pointer<Equation>> rest, sliced_eqns = {};

        case StrongComponent.SINGLE_EQUATION() algorithm
          (eqn, funcTree, solve_status) := solveTrivialStrongComponent(Pointer.access(comp.eqn), Pointer.access(comp.var), funcTree);
        then ({StrongComponent.SINGLE_EQUATION(comp.var, Pointer.create(eqn), solve_status)}, solve_status);

        case StrongComponent.SINGLE_ARRAY() algorithm
          (eqn, funcTree, solve_status) := solveTrivialStrongComponent(Pointer.access(comp.eqn), Pointer.access(comp.var), funcTree);
        then ({StrongComponent.SINGLE_ARRAY(comp.var, Pointer.create(eqn), solve_status)}, solve_status);

        // ToDo: solve inner branch systems for WHEN and IF
        case StrongComponent.SINGLE_WHEN_EQUATION() algorithm
          (eqn, funcTree, solve_status) := solveTrivialStrongComponent(Pointer.access(comp.eqn), Pointer.access(List.first(comp.vars)), funcTree);
        then ({StrongComponent.SINGLE_WHEN_EQUATION(comp.vars, Pointer.create(eqn), solve_status)}, solve_status);

        // ToDo
        //case StrongComponent.SINGLE_IF_EQUATION() algorithm
        //  (eqn, funcTree, solve_status) := solveTrivialStrongComponent(Pointer.access(comp.eqn), Pointer.access(List.first(comp.vars)), funcTree);
        //then ({StrongComponent.SINGLE_IF_EQUATION(comp.vars, Pointer.create(eqn), solve_status)}, solve_status);

        case StrongComponent.TORN_LOOP() algorithm
          // do we need to do smth here? e.g. solve inner equations? call tearing from here?
          comp.status := Status.IMPLICIT;
       then ({comp}, Status.IMPLICIT);

        case StrongComponent.SLICED_EQUATION(eqn = eqn_slice) guard(Equation.isForEquation(Slice.getT(eqn_slice))) algorithm
          eqn_ptr := Slice.getT(eqn_slice);
          (eqn_ptr, slicing_status, solve_status, funcTree) := Equation.slice(eqn_ptr, eqn_slice.indices, SOME(comp.var_cref), funcTree);
          if slicing_status == NBEquation.SlicingStatus.FAILURE then
            // if slicing failed -> scalarize;
            (eqn, funcTree, solve_status, _) := solveEquation(Pointer.access(Slice.getT(eqn_slice)), comp.var_cref, funcTree);
            Pointer.update(eqn_ptr, eqn);
            sizes := Equation.sizes(eqn_ptr);
            replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
            for index in listReverse(eqn_slice.indices) loop
              (eqn, funcTree) := Equation.singleSlice(eqn_ptr, index, sizes, ComponentRef.EMPTY(), replacements, funcTree);
              sliced_eqns := Pointer.create(eqn) :: sliced_eqns;
            end for;
            sliced_eqns := listReverse(sliced_eqns);
            solved_comps := list(StrongComponent.fromSolvedEquation(eqn) for eqn in sliced_eqns);
          else
            Pointer.update(eqn_ptr, Equation.splitIterators(Pointer.access(eqn_ptr)));
            sliced_eqns := {eqn_ptr};
            solved_comps := {StrongComponent.SLICED_EQUATION(comp.var_cref, comp.var, Slice.SLICE(eqn_ptr, {}), solve_status)};
          end if;

          // safe the slicing replacement in the map
          eqn_cref := Equation.getEqnName(eqn_ptr);
          if UnorderedMap.contains(eqn_cref, slicing_map) then
            sliced_eqns := listAppend(UnorderedMap.getSafe(eqn_cref, slicing_map), sliced_eqns);
          end if;
          UnorderedMap.add(eqn_cref, sliced_eqns, slicing_map);

        then (solved_comps, solve_status);

        case StrongComponent.SLICED_EQUATION() algorithm
          // just a regular equation solved for a sliced variable
          // use cref instead of var because it has subscripts!
          (eqn, funcTree, solve_status) := solveTrivialStrongComponent(Pointer.access(Slice.getT(comp.eqn)), Variable.fromCref(comp.var_cref), funcTree);
          comp.eqn := Slice.SLICE(Pointer.create(eqn), {});
          comp.status := solve_status;
        then ({comp}, solve_status);

        case StrongComponent.ENTWINED_EQUATION() algorithm
          // slice each entwined equation individually
          for slice in comp.entwined_slices loop
            StrongComponent.SLICED_EQUATION(var_cref = var_cref, eqn = eqn_slice) := slice;
            (eqn_ptr, slicing_status, solve_status, funcTree) := Equation.slice(Slice.getT(eqn_slice), eqn_slice.indices, SOME(var_cref), funcTree);
            if slicing_status == NBEquation.SlicingStatus.FAILURE then break; end if;
            eqn := Equation.renameIterators(Pointer.access(eqn_ptr), "$k");
            entwined_eqns := Equation.splitIterators(eqn) :: entwined_eqns;
          end for;

          if slicing_status == NBEquation.SlicingStatus.FAILURE then
            // if slicing failed -> scalarize;
            // first solve all equation bodies accordingly
            for slice in comp.entwined_slices loop
              StrongComponent.SLICED_EQUATION(var_cref = var_cref, eqn = eqn_slice) := slice;
              (eqn, funcTree, solve_status, _) := solveEquation(Pointer.access(Slice.getT(eqn_slice)), var_cref, funcTree);
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
            solved_comps := list(StrongComponent.fromSolvedEquation(eqn) for eqn in sliced_eqns);
          else
            // entwine the equations as far as possible
            entwined_eqns := Equation.entwine(listReverse(entwined_eqns));
            sliced_eqns := list(Pointer.create(eqn) for eqn in entwined_eqns);
            solved_comps := list(StrongComponent.fromSolvedEquation(eqn) for eqn in sliced_eqns);
          end if;

          // safe the slicing replacement in the map
          // -> just use the first name as replacement for all of them and all other with empty lists
          eqn_ptr :: rest := sliced_eqns;
          eqn_cref := Equation.getEqnName(eqn_ptr);
          if UnorderedMap.contains(eqn_cref, slicing_map) then
            sliced_eqns := listAppend(UnorderedMap.getSafe(eqn_cref, slicing_map), sliced_eqns);
          end if;
          UnorderedMap.add(eqn_cref, sliced_eqns, slicing_map);

          // empty for all others (do not overwrite if it exists)
          if not listEmpty(rest) then
            for eqn_ptr in rest loop
              eqn_cref := Equation.getEqnName(eqn_ptr);
              if not UnorderedMap.contains(eqn_cref, slicing_map) then
                UnorderedMap.add(eqn_cref, {}, slicing_map);
              end if;
            end for;
          end if;
        then (solved_comps, solve_status);

        else ({comp}, Status.UNSOLVABLE);
    end match;

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

  function solveTrivialStrongComponent
    input output Equation eqn;
    input Variable var;
    input output FunctionTree funcTree;
    output Status status;
  algorithm
    if ComponentRef.isEmpty(var.name) then
      // empty variable name implies equation without return value
      (eqn, status) := (eqn, NBSolve.Status.EXPLICIT);
    else
      (eqn, funcTree, status, _) := solveEquation(eqn, var.name, funcTree);
    end if;
  end solveTrivialStrongComponent;

  function solveEquation
    input output Equation eqn;
    input ComponentRef cref;
    input output FunctionTree funcTree;
    output Status status;
    output Boolean invertRelation     "If the equation represents a relation, this tells if the sign should be inverted";
  algorithm
    (eqn, funcTree, status, invertRelation) := match eqn
      local
        Equation body;

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
    Expression residual, derivative;
    Differentiate.DifferentiationArguments diffArgs;
    Operator divOp, uminOp;
    Type ty;
  algorithm
    (eqn, status, invertRelation) := solveSimple(eqn, cref);
    // if the equation does not have a simple structure try to solve with other strategies
    if status == Status.UNPROCESSED then
      residual := Equation.getResidualExp(eqn);
      diffArgs := Differentiate.DIFFERENTIATION_ARGUMENTS(
        diffCref        = cref,
        new_vars        = {},
        jacobianHT      = NONE(),
        diffType        = NBDifferentiate.DifferentiationType.SIMPLE,
        funcTree        = funcTree,
        diffedFunctions = AvlSetPath.new(),
        scalarized      = false
      );
      (derivative, diffArgs) := Differentiate.differentiateExpressionDump(residual, diffArgs, getInstanceName());
      derivative := SimplifyExp.simplify(derivative);

      if Expression.isZero(derivative) then
        invertRelation := false;
        status := Status.UNSOLVABLE;
      elseif not Expression.containsCref(derivative, cref) then
        // If eqn is linear in cref:
        (eqn, funcTree) := solveLinear(eqn, residual, derivative, diffArgs, cref, funcTree);
        // If the derivative is negative, invert possible inequality sign
        invertRelation := Expression.isNegative(derivative);
        status := Status.EXPLICIT;
      else
        // If eqn is non-linear in cref
        if Flags.isSet(Flags.FAILTRACE) then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to solve Cref: "
            + ComponentRef.toString(cref) + " in equation:\n" + Equation.toString(eqn)});
        end if;
        invertRelation := false;
        status := Status.IMPLICIT;
      end if;
    end if;
    eqn := Equation.simplify(eqn, getInstanceName());
  end solveBody;

protected
  function solveSimple
    input output Equation eqn;
    input ComponentRef cref;
    output Status status;
    output Boolean invertRelation;
  algorithm
    (eqn, status, invertRelation) := match eqn
      local
        ComponentRef lhs, rhs;

      case Equation.SCALAR_EQUATION(lhs = Expression.CREF(cref = lhs))
        guard(ComponentRef.isEqual(cref, lhs) and not Expression.containsCref(eqn.rhs, cref))
      then (eqn, Status.EXPLICIT, false);

      case Equation.SCALAR_EQUATION(rhs = Expression.CREF(cref = rhs))
        guard(ComponentRef.isEqual(cref, rhs) and not Expression.containsCref(eqn.lhs, cref))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      case Equation.ARRAY_EQUATION(lhs = Expression.CREF(cref = lhs))
        guard(ComponentRef.isEqual(cref, lhs) and not Expression.containsCref(eqn.rhs, cref))
      then (eqn, Status.EXPLICIT, false);

      case Equation.ARRAY_EQUATION(rhs = Expression.CREF(cref = rhs))
        guard(ComponentRef.isEqual(cref, rhs) and not Expression.containsCref(eqn.lhs, cref))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      // we do not check for x = x because that is nonsensical
      case Equation.SIMPLE_EQUATION()
        guard(ComponentRef.isEqual(cref, eqn.lhs))
      then (eqn, Status.EXPLICIT, false);

      case Equation.SIMPLE_EQUATION()
        guard(ComponentRef.isEqual(cref, eqn.rhs))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      case Equation.RECORD_EQUATION(lhs = Expression.CREF(cref = lhs))
        guard(ComponentRef.isEqual(cref, lhs) and not Expression.containsCref(eqn.rhs, cref))
      then (eqn, Status.EXPLICIT, false);

      case Equation.RECORD_EQUATION(rhs = Expression.CREF(cref = rhs))
        guard(ComponentRef.isEqual(cref, rhs) and not Expression.containsCref(eqn.lhs, cref))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, true);

      case Equation.WHEN_EQUATION() then (eqn, Status.EXPLICIT, false); // ToDo: need to check if implicit

      // ToDo: more cases

      else (eqn, Status.UNPROCESSED, false);
    end match;
  end solveSimple;

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

  annotation(__OpenModelica_Interface="backend");
end NBSolve;

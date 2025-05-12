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
  import Algorithm = NFAlgorithm;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import NFFlatten.FunctionTree;
  import NFFunction.Function;
  import Operator = NFOperator;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Variable = NFVariable;

  // backend imports
  import BackendDAE = NBackendDAE;
  import BackendUtil = NBBackendUtil;
  import Causalize = NBCausalize;
  import Differentiate = NBDifferentiate;
  import NBEquation.{Equation, EquationPointer, EquationPointers, EqData, EquationAttributes, Iterator, IfEquationBody, WhenEquationBody, WhenStatement, SlicingStatus};
  import NBVariable.{VariablePointer, VariablePointers, VarData};
  import BVariable = NBVariable;
  import Inline = NBInline;
  import Replacements = NBReplacements;
  import Slice = NBSlice;
  import StrongComponent = NBStrongComponent;
  import BPartition = NBPartition;
  import NBPartition.Partition;
  import Tearing = NBTearing;

  type Status = enumeration(UNPROCESSED, EXPLICIT, IMPLICIT, UNSOLVABLE);
  // TRUE -> relation must be inverted, FALSE -> relation must not be inverted, UNKNOWN -> TODO: make relation depend on derivative of the expr
  type RelationInversion = enumeration(TRUE, FALSE, UNKNOWN);

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
        bdae.init       := list(solvePartition(par, funcTree_ptr, implicit_index_ptr, duplicate_map, bdae.varData, bdae.eqData) for par in bdae.init);
        if Util.isSome(bdae.init_0) then
          bdae.init_0   := SOME(list(solvePartition(par, funcTree_ptr, implicit_index_ptr, duplicate_map, bdae.varData, bdae.eqData) for par in Util.getOption(bdae.init_0)));
        end if;
        bdae.ode        := list(solvePartition(par, funcTree_ptr, implicit_index_ptr, duplicate_map, bdae.varData, bdae.eqData) for par in bdae.ode);
        bdae.algebraic  := list(solvePartition(par, funcTree_ptr, implicit_index_ptr, duplicate_map, bdae.varData, bdae.eqData) for par in bdae.algebraic);
        bdae.ode_event  := list(solvePartition(par, funcTree_ptr, implicit_index_ptr, duplicate_map, bdae.varData, bdae.eqData) for par in bdae.ode_event);
        bdae.alg_event  := list(solvePartition(par, funcTree_ptr, implicit_index_ptr, duplicate_map, bdae.varData, bdae.eqData) for par in bdae.alg_event);
        bdae.clocked    := list(solvePartition(par, funcTree_ptr, implicit_index_ptr, duplicate_map, bdae.varData, bdae.eqData) for par in bdae.clocked);
        bdae.funcTree   := Pointer.access(funcTree_ptr);
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

  function solvePartition
    input output Partition partition;
    input Pointer<FunctionTree> funcTree_ptr;
    input Pointer<Integer> implicit_index_ptr;
    input UnorderedMap<StrongComponent, list<StrongComponent>> duplicate_map;
    input VarData varData;
    input EqData eqData;
  protected
    BPartition.Kind kind = Partition.getKind(partition);
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
    if Util.isSome(partition.strongComponents) then
      for comp in Util.getOption(partition.strongComponents) loop
        solved_comps := match UnorderedMap.get(comp, duplicate_map)
          local list<StrongComponent> alias_comps;
          case SOME(alias_comps) then listAppend(alias_comps, solved_comps); // strong component already solved -> get alias comps
          else algorithm
            // solve strong component -> create alias comps
            (alias_comps, funcTree, implicit_index) := solveStrongComponent(comp, funcTree, kind, implicit_index, slicing_map, varData, eqData);
            UnorderedMap.add(comp, list(StrongComponent.createAlias(kind, partition.index, comp_idx, c) for c in alias_comps), duplicate_map);
          then listAppend(alias_comps, solved_comps);
        end match;
      end for;
      partition.strongComponents := SOME(listArray(listReverse(solved_comps)));
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
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " cannot solve partition without strong components: " + Partition.toString(partition) + "\n\n"});
      fail();
    end if;
  end solvePartition;

  function solveStrongComponent
    input StrongComponent comp;
    output list<StrongComponent> solved_comps = {};
    input output FunctionTree funcTree;
    input BPartition.Kind kind;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    input VarData varData;
    input EqData eqData;
  protected
    Status solve_status;
    StrongComponent implicit_comp;
  algorithm
    try
      (solved_comps, solve_status) := match comp
        local
          Pointer<Equation> eqn_ptr;
          Equation eqn;
          Slice<VariablePointer> var_slice;
          Slice<EquationPointer> eqn_slice;
          ComponentRef var_cref, eqn_cref;
          StrongComponent generic_comp, solved_comp;
          list<StrongComponent> entwined_slices = {};
          Tearing strict;
          list<StrongComponent> tmp, inner_comps = {};

          Algorithm alg;
          list<ComponentRef> solved_crefs, inputs, outputs;
          UnorderedSet<ComponentRef> output_crefs, input_crefs, solved_inputs;
          list<tuple<ComponentRef, ComponentRef>> tmp_crefs;
          list<Pointer<Variable>> tmp_vars;
          list<Pointer<Equation>> tmp_eqns;
          Pointer<Integer> idx;
          UnorderedMap<ComponentRef, ComponentRef> cref_repl;
          UnorderedMap<ComponentRef, Expression> exp_repl;
          list<Slice<VariablePointer>> iter_vars;
          list<Slice<EquationPointer>> residuals;

        case StrongComponent.SINGLE_COMPONENT() algorithm
          (eqn, funcTree, solve_status, implicit_index) := solveSingleStrongComponent(Pointer.access(comp.eqn), Pointer.access(comp.var), funcTree, kind, implicit_index, slicing_map, varData, eqData);
        then ({StrongComponent.SINGLE_COMPONENT(comp.var, Pointer.create(eqn), solve_status)}, solve_status);

        case StrongComponent.MULTI_COMPONENT() algorithm
          eqn_ptr := Slice.getT(comp.eqn);
          eqn := Pointer.access(eqn_ptr);
          (solved_comp, solve_status) := match eqn
            case Equation.ALGORITHM(alg = alg) algorithm
              // X = set of solved variables
              solved_crefs := list(BVariable.getVarName(Slice.getT(var)) for var in comp.vars);

              // Y = set of inputs
              inputs := List.flatten(list(BVariable.getRecordChildrenCref(i) for i in alg.inputs));
              input_crefs := UnorderedSet.fromList(inputs, ComponentRef.hash, ComponentRef.isEqual);
              // Y^ <- Y U X set of inputs that are solved (iteration vars, no need to create temporary variables)
              solved_inputs := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
              for solved_cref in solved_crefs loop
                if UnorderedSet.contains(solved_cref, input_crefs) then
                  UnorderedSet.add(solved_cref, solved_inputs);
                end if;
              end for;

              // Z = set of outputs
              outputs := List.flatten(list(BVariable.getRecordChildrenCref(o) for o in alg.outputs));
              output_crefs := UnorderedSet.fromList(outputs, ComponentRef.hash, ComponentRef.isEqual);
              // Z^ <- Z \ X set of outputs that are not solved
              for solved_cref in solved_crefs loop
                UnorderedSet.remove(solved_cref, output_crefs);
              end for;

              if UnorderedSet.isEmpty(output_crefs) then
                // EXPLICIT: no unsolved outputs
                (eqn_slice, funcTree, solve_status, implicit_index) := solveMultiStrongComponent(comp.eqn, comp.vars, funcTree, kind, implicit_index, slicing_map, Iterator.EMPTY(), varData, eqData);
                solved_comp := StrongComponent.MULTI_COMPONENT(comp.vars, eqn_slice, solve_status);
              else
                // IMPLICIT: some outputs are not solved in the body
                solve_status := Status.IMPLICIT;
                idx := Pointer.create(0);
                // create temporary variables for all outputs that are not solved for
                tmp_crefs := list((cref, BVariable.makeTmpVar(cref)) for cref in UnorderedSet.toList(output_crefs));
                tmp_vars := list(BVariable.getVarPointer(Util.tuple22(tpl)) for tpl in tmp_crefs);

                // create equations equalizing the temporary variables and the real ones
                // res = z - z^ for z^ in Z^
                tmp_eqns := list(Equation.makeAssignment(
                  lhs   = Expression.fromCref(Util.tuple21(tpl)),
                  rhs   = Expression.fromCref(Util.tuple22(tpl)),
                  idx   = idx,
                  str   = "TMP",
                  iter  = Iterator.EMPTY(),
                  attr  = EquationAttributes.default(NBEquation.EquationKind.CONTINUOUS, false)) for tpl in tmp_crefs);
                // make residual equations
                tmp_eqns := list(Equation.createResidual(e) for e in tmp_eqns);
                // create z -> z^ replacements for the algorithm body and for the algorithm outputs
                cref_repl := UnorderedMap.new<ComponentRef>(ComponentRef.hash, ComponentRef.isEqual);
                exp_repl  := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
                for tpl in tmp_crefs loop
                  UnorderedMap.add(Util.tuple21(tpl), Util.tuple22(tpl), cref_repl);
                  UnorderedMap.add(Util.tuple21(tpl), Expression.fromCref(Util.tuple22(tpl)), exp_repl);
                end for;
                // replace z -> z^ in the algorithm outputs and set the solved variables to those outputs
                alg.outputs := list(UnorderedMap.getOrDefault(c, cref_repl, c) for c in eqn.alg.outputs);
                comp.vars   := list(Slice.SLICE(BVariable.getVarPointer(c), {}) for c in alg.outputs);
                comp.status := Status.EXPLICIT;
                eqn.alg     := alg;
                // replace z -> z^  in the algorithm body
                Pointer.update(eqn_ptr, Equation.map(eqn, function Replacements.applySimpleExp(replacements = exp_repl)));
                // create the algebraic loop, already torn
                strict := Tearing.TEARING_SET(list(Slice.SLICE(BVariable.getVarPointer(c), {}) for c in UnorderedSet.toList(solved_inputs)), list(Slice.SLICE(e, {}) for e in tmp_eqns), listArray({comp}), NONE());
                // ToDo: set all the booleans correctly
                solved_comp := StrongComponent.ALGEBRAIC_LOOP(implicit_index, strict, NONE(), false, false, false, solve_status);
                print(StrongComponent.toString(solved_comp));

                // add new equations and new variables
                EqData.addTypedList(eqData, tmp_eqns, NBEquation.EqData.EqType.CONTINUOUS);
                VarData.addTypedList(varData, tmp_vars, NBVariable.VarData.VarType.ALGEBRAIC);
                // ToDo: create sub routine for this (?)
              end if;
            then (solved_comp, Status.EXPLICIT);

            else algorithm
              (eqn_slice, funcTree, solve_status, implicit_index) := solveMultiStrongComponent(comp.eqn, comp.vars, funcTree, kind, implicit_index, slicing_map, Iterator.EMPTY(), varData, eqData);
            then (StrongComponent.MULTI_COMPONENT(comp.vars, eqn_slice, solve_status), solve_status);
          end match;
        then ({solved_comp}, solve_status);

        case StrongComponent.ALGEBRAIC_LOOP(strict = strict) algorithm
          for inner_comp in listReverse(arrayList(strict.innerEquations)) loop
            (tmp, funcTree, implicit_index) := solveStrongComponent(inner_comp, funcTree, kind, implicit_index, slicing_map, varData, eqData);
            inner_comps := listAppend(tmp, inner_comps);
          end for;
          strict.innerEquations := listArray(inner_comps);
          comp.strict := strict;
          comp.status := Status.IMPLICIT;
        then ({comp}, Status.IMPLICIT);

        case StrongComponent.SLICED_COMPONENT(eqn = eqn_slice) guard(Equation.isForEquation(Slice.getT(eqn_slice))) algorithm
          (generic_comp, funcTree, solve_status, implicit_index) := solveGenericEquation(comp, funcTree, kind, implicit_index, slicing_map, varData, eqData);
        then ({generic_comp}, solve_status);

        case StrongComponent.SLICED_COMPONENT(var = var_slice, eqn = eqn_slice) guard(Equation.isArrayEquation(Slice.getT(eqn_slice))) algorithm
          // array equation solved for the a sliced variable.
          // get all slices of the variable ocurring in the equation and select the slice that fits the indices
          (eqn_slice, funcTree, implicit_index, solve_status) := solveForVarSlice(eqn_slice, var_slice, funcTree, kind, implicit_index, slicing_map, varData, eqData);
          comp.eqn := eqn_slice;
          comp.status := solve_status;
        then ({comp}, solve_status);

        case StrongComponent.SLICED_COMPONENT() algorithm
          // just a regular equation solved for a sliced variable
          // use cref instead of var because it has subscripts!
          (eqn, funcTree, solve_status, implicit_index) := solveSingleStrongComponent(Pointer.access(Slice.getT(comp.eqn)), Variable.fromCref(comp.var_cref), funcTree, kind, implicit_index, slicing_map, varData, eqData);
          if solve_status < Status.UNSOLVABLE then
            comp.eqn := Slice.SLICE(Pointer.create(eqn), {});
          else
            (eqn_slice, funcTree, implicit_index, solve_status) := solveForVarSlice(comp.eqn, comp.var, funcTree, kind, implicit_index, slicing_map, varData, eqData);
            comp.eqn := eqn_slice;
          end if;
          comp.status := solve_status;
        then ({comp}, solve_status);

        case StrongComponent.RESIZABLE_COMPONENT() algorithm
          // a resizable component with trivial solution
          // ToDo 1: resolve the eval order
          // ToDo 2: resolve potential equation slicing
          (eqn, funcTree, solve_status, implicit_index, _) := solveEquation(Pointer.access(Slice.getT(comp.eqn)), comp.var_cref, funcTree, kind, implicit_index, slicing_map, varData, eqData);
          eqn := Equation.applyForOrder(eqn, comp.order);
          comp.eqn := Slice.SLICE(Pointer.create(eqn), comp.eqn.indices);
          comp.status := solve_status;
        then ({comp}, solve_status);

        /* for now handle all entwined equations generically and don't try to solve */
        case StrongComponent.ENTWINED_COMPONENT() algorithm
          for slice in comp.entwined_slices loop
            (generic_comp, funcTree, solve_status, implicit_index) := solveGenericEquation(slice, funcTree, kind, implicit_index, slicing_map, varData, eqData);
            // make loop on any solve_status != explicit
            entwined_slices := generic_comp :: entwined_slices;
          end for;
          comp.entwined_slices := listReverse(entwined_slices);
        then ({comp}, NBSolve.Status.EXPLICIT);

        else ({comp}, Status.UNSOLVABLE);
      end match;
    else
      // this fails in the next case because of the unsolvable status
      (solved_comps, solve_status) := ({comp}, Status.UNSOLVABLE);
    end try;

    // solve implicit equation (algebraic loop is always implicit)
    if solve_status == Status.IMPLICIT and List.hasOneElement(solved_comps) then
      (implicit_comp, funcTree, implicit_index)  := Tearing.implicit(
        comp        = listHead(solved_comps),
        funcTree    = funcTree,
        index       = implicit_index,
        kind  = kind
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
    input BPartition.Kind kind;
    output Status solve_status;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    input VarData varData;
    input EqData eqData;
  algorithm
    (comp, solve_status) := match comp
      local
        Slice<VariablePointer> var_slice;
        Slice<EquationPointer> eqn_slice;

      case StrongComponent.SLICED_COMPONENT(var = var_slice, eqn = eqn_slice) guard(Equation.isForEquation(Slice.getT(eqn_slice))) algorithm
        (comp, solve_status, funcTree, implicit_index) := solveGenericEquationSlice(var_slice, eqn_slice, comp.var_cref, funcTree, kind, implicit_index, slicing_map, varData, eqData);
      then (comp, solve_status);

      // ToDo: make these actually resizable inside entwined equations (?)
      case StrongComponent.RESIZABLE_COMPONENT(var = var_slice, eqn = eqn_slice) guard(Equation.isForEquation(Slice.getT(eqn_slice))) algorithm
        eqn_slice := Slice.apply(eqn_slice, function Pointer.apply(func = function Equation.applyForOrder(order = comp.order)));
        (comp, solve_status, funcTree, implicit_index) := solveGenericEquationSlice(var_slice, eqn_slice, comp.var_cref,  funcTree, kind, implicit_index, slicing_map, varData, eqData);
      then (comp, solve_status);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + StrongComponent.toString(comp) + "\n"});
      then fail();
    end match;
  end solveGenericEquation;

  function solveGenericEquationSlice
    input Slice<VariablePointer> var_slice;
    input Slice<EquationPointer> eqn_slice;
    input ComponentRef cref;
    output StrongComponent comp;
    output Status solve_status;
    input output FunctionTree funcTree;
    input BPartition.Kind kind;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    input VarData varData;
    input EqData eqData;
  protected
    Pointer<Equation> eqn_ptr = Slice.getT(eqn_slice);
    Equation eqn;
    Slice<EquationPointer> solved_slice;
    UnorderedMap<ComponentRef, Expression> replacements;
  algorithm
    if listLength(eqn_slice.indices) == 1 then
      replacements    := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
      (eqn, funcTree) := Equation.singleSlice(eqn_ptr, listHead(eqn_slice.indices), Equation.sizes(eqn_ptr), cref, replacements, funcTree);
    else
      (eqn, funcTree, solve_status, implicit_index, _) := solveEquation(Pointer.access(eqn_ptr), cref, funcTree, kind, implicit_index, slicing_map, varData, eqData);
    end if;
    if solve_status < Status.UNSOLVABLE then
      solved_slice := Slice.SLICE(Pointer.create(eqn), eqn_slice.indices);
    else
      (solved_slice, funcTree, implicit_index, solve_status) := solveForVarSlice(eqn_slice, var_slice, funcTree, kind, implicit_index, slicing_map, varData, eqData);
    end if;
    // ToDo: if solve_status not explicit -> algebraic loop with residual and Status.IMPLICIT
    comp := StrongComponent.GENERIC_COMPONENT(cref, solved_slice);
  end solveGenericEquationSlice;

  function solveSingleStrongComponent
    input output Equation eqn;
    input Variable var;
    input output FunctionTree funcTree;
    input BPartition.Kind kind;
    output Status status;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    input VarData varData;
    input EqData eqData;
  protected
    ComponentRef var_cref;
  algorithm
    if ComponentRef.isEmpty(var.name) then
      // empty variable name implies equation without return value
      (eqn, status) := (eqn, Status.EXPLICIT);
    else
      (var_cref, status) := getVarSlice(var.name, eqn);
      var_cref := if status < Status.UNSOLVABLE then var_cref else var.name;
      (eqn, funcTree, status, implicit_index, _) := solveEquation(eqn, var_cref, funcTree, kind, implicit_index, slicing_map, varData, eqData);
    end if;
  end solveSingleStrongComponent;

  function solveMultiStrongComponent
    input output Slice<EquationPointer> eqn_slice;
    input list<Slice<VariablePointer>> var_slices;
    input output FunctionTree funcTree;
    input BPartition.Kind kind;
    output Status status;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    input Iterator iter;
    input VarData varData;
    input EqData eqData;
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
        (if_body, funcTree, status, implicit_index) := solveIfBody(eqn.body, VariablePointers.fromList(vars), funcTree, kind, implicit_index, slicing_map, iter, varData, eqData);
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

      // dummy equation implies removed equation (occurs only in simulation systems)
      case Equation.DUMMY_EQUATION() then (eqn_slice, funcTree, Status.EXPLICIT);

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for equation:\n" + Slice.toString(eqn_slice, function Equation.pointerToString(str = ""))});
      then fail();
    end match;
  end solveMultiStrongComponent;

  function solveEquation
    input output Equation eqn;
    input ComponentRef cref;
    input output FunctionTree funcTree;
    input BPartition.Kind kind;
    output Status status;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    output RelationInversion invertRelation     "If the equation represents a relation, this tells if the sign should be inverted";
    input VarData varData;
    input EqData eqData;
  algorithm
    (eqn, funcTree, status, invertRelation) := match eqn
      local
        Equation body;
        Slice<EquationPointer> body_slice;
        Pointer<Variable> indexed_var;
        Iterator dummy;

      // For equations are expected to only have one body equation at this point
      case Equation.FOR_EQUATION(body = {body as Equation.IF_EQUATION()}) algorithm
        // create indexed variable to trick matching algorithm to solve for it
        indexed_var := BVariable.makeVarPtrCyclic(BVariable.getVar(cref), cref);
        dummy := Iterator.dummy(eqn.iter);
        (body_slice, funcTree, status, implicit_index) := solveMultiStrongComponent(Slice.SLICE(Pointer.create(body), {}), {Slice.SLICE(indexed_var, {})}, funcTree, kind, implicit_index, slicing_map, dummy, varData, eqData);
        eqn.body := {Pointer.access(Slice.getT(body_slice))};
      then (eqn, funcTree, status, RelationInversion.FALSE);

      case Equation.FOR_EQUATION(body = {body}) algorithm
        (body, funcTree, status, invertRelation) := solveBody(body, cref, funcTree);
        eqn.body := {body};
      then (eqn, funcTree, status, invertRelation);

      case Equation.FOR_EQUATION() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName()
            + " failed to solve a for-equation with multiple body eqns for a single cref. Please iterate over body elements individually.\n"
            + "cref: " + ComponentRef.toString(cref) + " in equation:\n" + Equation.toString(eqn)});
      then fail();

      // dummy equation implies removed equation (occurs only in simulation systems)
      case Equation.DUMMY_EQUATION() then (eqn, funcTree, Status.EXPLICIT, RelationInversion.FALSE);

      else solveBody(eqn, cref, funcTree);
    end match;
  end solveEquation;

  function solveBody
    input output Equation eqn;
    input ComponentRef cref;
    input output FunctionTree funcTree;
    output Status status;
    output RelationInversion invertRelation "If the equation represents a relation, this tells if the sign should be inverted";
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

    if Flags.isSet(Flags.DUMP_SOLVE) then
      solvePrintInput(eqn, fixed_cref);
    end if;

    (eqn, status, invertRelation) := solveSimple(eqn, fixed_cref);
    // if the equation does not have a simple structure try to solve with other strategies
    if status == Status.UNPROCESSED then
      residual := Equation.getResidualExp(eqn);
      diffArgs := Differentiate.DifferentiationArguments.simpleCref(fixed_cref, funcTree);
      (derivative, diffArgs) := Differentiate.differentiateExpressionDump(residual, diffArgs, getInstanceName());
      derivative := SimplifyExp.simplifyDump(derivative, true, getInstanceName());

      if Expression.isZero(derivative) then
        invertRelation := RelationInversion.FALSE;
        status := Status.UNSOLVABLE;
      elseif not Expression.containsCref(derivative, fixed_cref) then
        // If eqn is linear in cref:
        (eqn, funcTree) := solveLinear(eqn, residual, derivative, diffArgs, fixed_cref, funcTree);
        // If the derivative is negative, invert possible inequality sign
        invertRelation := if Expression.isPositive(derivative) then RelationInversion.FALSE else if Expression.isNegative(derivative) then RelationInversion.TRUE else RelationInversion.UNKNOWN;
        status := Status.EXPLICIT;
      else
        // call general solving routine, can solve an equation, if a cref is contained once in the equation
        (eqn, status) := solveUnique(eqn, residual, fixed_cref);

        if status == Status.EXPLICIT then
          invertRelation := RelationInversion.UNKNOWN; // TODO: make me depend on the derivative
        else
          invertRelation := RelationInversion.FALSE;
        end if;

        if Flags.isSet(Flags.FAILTRACE) and status <> Status.EXPLICIT then
          Error.addCompilerWarning(getInstanceName() + " cref: " + ComponentRef.toString(fixed_cref)
            + " has to be solved implicitely in equation:\n" + Equation.toString(eqn));
        end if;
      end if;
    end if;
    eqn := Equation.simplify(eqn, getInstanceName());
    if Flags.isSet(Flags.DUMP_SOLVE) then
      solvePrintOutput(eqn, status);
    end if;
  end solveBody;

  function solveIfBody
    input output IfEquationBody body;
    input VariablePointers vars;
    input output FunctionTree funcTree;
    output Status status;
    input BPartition.Kind kind;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    input Iterator iter;
    input VarData varData;
    input EqData eqData;
  protected
    IfEquationBody else_if;
    list<StrongComponent> comps, solved_comps;
    list<Pointer<Equation>> new_then_eqns = {};
  algorithm
    // causalize this branch equations for the unknowns
    (_, comps) := Causalize.simple(vars, EquationPointers.fromList(body.then_eqns), iter = iter);
    // solve each strong component explicitly and save equations to branch
    for comp in comps loop
      (solved_comps, funcTree, implicit_index) := solveStrongComponent(comp, funcTree, kind, implicit_index, slicing_map, varData, eqData);
      for solved_comp in solved_comps loop
        new_then_eqns := StrongComponent.toSolvedEquation(solved_comp) :: new_then_eqns;
      end for;
    end for;
    body.then_eqns := listReverse(new_then_eqns);
    // if there is an else branch -> go deeper
    if Util.isSome(body.else_if) then
      (else_if, funcTree, status, implicit_index) := solveIfBody(Util.getOption(body.else_if), vars, funcTree, kind, implicit_index, slicing_map, iter, varData, eqData);
      body.else_if := SOME(else_if);
    else
      // StrongComponent.toSolvedEquation fails for everything that is not explicitly solvable so at this point one can assume it is
      status := Status.EXPLICIT;
    end if;
  end solveIfBody;

  function solveSimple
    input output Equation eqn;
    input ComponentRef cref;
    output Status status;
    output RelationInversion invertRelation;
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

      else (eqn, Status.UNPROCESSED, RelationInversion.FALSE);
    end match;
  end solveSimple;

protected
  function solveSimpleLhsRhs
    input Expression lhs;
    input Expression rhs;
    input ComponentRef cref;
    input output Equation eqn;
    output Status status;
    output RelationInversion invertRelation;
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
      then (eqn, Status.EXPLICIT, RelationInversion.FALSE);

      // 2. only swap lsh and rhs
      // exp = cref
      case (exp, Expression.CREF(cref = checkCref))
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, RelationInversion.TRUE);

      // 3.1 negate (MINUS) lhs and rhs
      // -cref = exp
      case (Expression.UNARY(exp = Expression.CREF(cref = checkCref)), exp)
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.updateLHSandRHS(eqn, Expression.negate(lhs), Expression.negate(rhs)), Status.EXPLICIT, RelationInversion.TRUE);

      // 3.2 negate (NOT) lhs and rhs
      // not cref = exp
      case (Expression.LUNARY(exp = Expression.CREF(cref = checkCref)), exp)
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.updateLHSandRHS(eqn, Expression.logicNegate(lhs), Expression.logicNegate(rhs)), Status.EXPLICIT, RelationInversion.FALSE);

      // 4.1 negate (MINUS) and swap lhs and rhs
      // exp = -cref
      case (exp, Expression.UNARY(exp = Expression.CREF(cref = checkCref)))
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.updateLHSandRHS(eqn, Expression.negate(rhs), Expression.negate(lhs)), Status.EXPLICIT, RelationInversion.FALSE);

      // 4.2 negate (NOT) and swap lhs and rhs
      // exp = not cref
      case (exp, Expression.LUNARY(exp = Expression.CREF(cref = checkCref)))
        guard(ComponentRef.isEqual(cref, checkCref) and not Expression.containsCref(exp, cref))
      then (Equation.updateLHSandRHS(eqn, Expression.logicNegate(rhs), Expression.logicNegate(lhs)), Status.EXPLICIT, RelationInversion.FALSE);

      // simple solve tuples
      case (exp as Expression.TUPLE(), _) guard(tupleSolvable(exp.elements, {BVariable.getVarPointer(cref)})) then (eqn, Status.EXPLICIT, RelationInversion.FALSE);
      case (_, exp as Expression.TUPLE()) guard(tupleSolvable(exp.elements, {BVariable.getVarPointer(cref)})) then (Equation.swapLHSandRHS(eqn), Status.EXPLICIT, RelationInversion.FALSE);

      else (eqn, Status.UNPROCESSED, RelationInversion.FALSE);
    end match;
  end solveSimpleLhsRhs;

  function solveSimpleWhen
    input WhenEquationBody body;
    input ComponentRef cref;
    input Equation eqn;
    output Equation eqnOut = eqn "don't change the equation";
    output Status status;
    output RelationInversion invertRelation = RelationInversion.FALSE;
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

  function solveUnique
    "author: linuslangenkamp
    solves a generic equation in terms of a cref that is contained only once
    returns Status.IMPLICIT if the equation can't be solved or the cref is contained multiple times"
    input output Equation eqn;
    input Expression residual;
    input ComponentRef cref;
    output Status status;
  protected
    Expression crefExp = Expression.fromCref(cref), exp, solvedRHS;
    Boolean crefFound;
    list<Expression> inverseInstructions = {};
    Type ty = ComponentRef.getSubscriptedType(cref, true);
  algorithm
    // find a list of inverse operations or detect that a cref is contained more than once
    (crefFound, inverseInstructions, status) := solveUniqueFindInstructions(residual, cref, false, inverseInstructions);

    if Flags.isSet(Flags.DUMP_SOLVE) then
      solveUniquePrintInstructions(inverseInstructions, status);
    end if;

    // apply the inverse operations or return if implicit
    eqn := match status
      case Status.IMPLICIT
        then eqn;
      else algorithm
        status := Status.EXPLICIT;
        solvedRHS := Expression.makeZero(ty);
        for instruction in inverseInstructions loop
          solvedRHS := applyInstruction(solvedRHS, instruction);
        end for;
        eqn := Equation.setLHS(eqn, crefExp);
        eqn := Equation.setRHS(eqn, solvedRHS);
        then eqn;
    end match;
  end solveUnique;

  function solveUniqueFindInstructions
    "performs the recursion steps"
    input Expression exp;
    input ComponentRef cref;
    input output Boolean crefFound;
    input output list<Expression> inverseInstructions;
    output Status status = Status.EXPLICIT; // just set this per default, since the algorithm detects implicit equations
  protected
    Expression substExp = NBVariable.toExpression(Pointer.create(NBVariable.SUBST_VARIABLE));
    Type ty = ComponentRef.getSubscriptedType(cref, true);
    Boolean crefFoundInRecursion;
    String name;
    Call call;
  algorithm
    // TODO: update crefFounds, hard to read!
    // TODO: potential types
    // TODO: add missing cases
    if crefFound then
      // cref was already found elsewhere
      if Expression.containsCref(exp, cref) then
        // cref appears more than once, abort
        status := Status.IMPLICIT;
      else
        // set crefFound = false, since the cref is not found in this branch
        crefFound := false;
      end if;
      return;
    end if;

    () := match exp
      case Expression.REAL() then ();
      case Expression.INTEGER() then ();
      case Expression.CREF() algorithm
        if ComponentRef.isEqual(cref, exp.cref) then
          crefFound := true;
        end if;
        then ();
      case Expression.CAST() algorithm
        (crefFound, inverseInstructions, status) := solveUniqueFindInstructionsCast(substExp, exp, cref, crefFound, inverseInstructions);
        then ();
      case Expression.MULTARY() algorithm
        (crefFound, inverseInstructions, status) := solveUniqueFindInstructionsMultary(substExp, exp, cref, crefFound, inverseInstructions);
        then ();
      case Expression.BINARY() algorithm
        () := match exp.operator
          case Operator.OPERATOR(op = NFOperator.Op.POW) algorithm
            (crefFound, inverseInstructions, status) := solveUniqueFindInstructionsBinaryPow(ty, substExp, exp, cref, crefFound, inverseInstructions);
            then ();
          case Operator.OPERATOR(op = NFOperator.Op.ADD) algorithm
            (crefFound, inverseInstructions, status) := solveUniqueFindInstructionsBinaryComOp(substExp, exp, cref, crefFound, inverseInstructions);
            then ();
          case Operator.OPERATOR(op = NFOperator.Op.MUL) algorithm
            (crefFound, inverseInstructions, status) := solveUniqueFindInstructionsBinaryComOp(substExp, exp, cref, crefFound, inverseInstructions);
            then ();
        else algorithm // fallback -> set implicit
          if Flags.isSet(Flags.DUMP_SOLVE) then
            solveUniquePrintImplicitFallback(exp);
          end if;
          status := Status.IMPLICIT;
          then ();
        end match;
        then ();
      case Expression.UNARY() algorithm
        () := match exp.operator
          case Operator.OPERATOR(op = NFOperator.Op.UMINUS) algorithm
            (crefFound, inverseInstructions, status) := solveUniqueFindInstructionsUnaryUminus(ty, substExp, exp, cref, crefFound, inverseInstructions);
            then ();
          else algorithm // fallback -> set implicit
            if Flags.isSet(Flags.DUMP_SOLVE) then
              solveUniquePrintImplicitFallback(exp);
            end if;
            status := Status.IMPLICIT;
            then ();
        end match;
        then ();
      case (Expression.CALL(call = call as Call.TYPED_CALL())) guard(List.hasOneElement(Call.arguments(exp.call))) algorithm
        (crefFound, inverseInstructions, status) := solveUniqueFindInstructionsCallOneArg(ty, substExp, exp, cref, crefFound, inverseInstructions);
        then ();
      case (Expression.CALL(call = call as Call.TYPED_CALL())) guard(listLength(Call.arguments(exp.call)) == 2) algorithm
        (crefFound, inverseInstructions, status) := solveUniqueFindInstructionsCallTwoArgs(ty, substExp, exp, cref, crefFound, inverseInstructions);
        then ();
      else algorithm // fallback -> set implicit
        if Flags.isSet(Flags.DUMP_SOLVE) then
          solveUniquePrintImplicitFallback(exp);
        end if;
        status := Status.IMPLICIT;
        then ();
    end match;
  end solveUniqueFindInstructions;

  function solveUniqueFindInstructionsMultary
    "find instructions for a multary"
    input Expression substExp;
    input Expression exp;
    input ComponentRef cref;
    input output Boolean crefFound;
    input output list<Expression> inverseInstructions;
    output Status status;
  protected
    list<Expression> argList = {}, invargList = {};
    Boolean crefFoundInRecursion;
  algorithm
    () := match exp
      case Expression.MULTARY() algorithm
        for arg in exp.arguments loop
          (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(arg, cref, crefFound, inverseInstructions);
          if status == Status.IMPLICIT then
            return;
          end if;
          if not crefFoundInRecursion then
            argList := arg :: argList;
          else
            crefFound := true;
          end if;
        end for;
        if crefFound then
          if List.any(exp.inv_arguments, function Expression.containsCref(cref=cref)) then
            status := Status.IMPLICIT;
            return;
          else
            // inverse multary for cref in args
            inverseInstructions := Expression.MULTARY(substExp :: exp.inv_arguments, argList, exp.operator) :: inverseInstructions;
          end if;
        else
          for invarg in exp.inv_arguments loop
            (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(invarg, cref, crefFound, inverseInstructions);
            if status == Status.IMPLICIT then
              return;
            end if;
            if not crefFoundInRecursion then
              invargList := invarg :: invargList;
            else
              crefFound := true;
            end if;
          end for;
          if crefFound then
            // inverse multary for cref in invargs
            inverseInstructions := Expression.MULTARY(argList, substExp :: invargList, exp.operator) :: inverseInstructions;
          end if;
        end if;
      then ();
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " can only be called for Expression.MULTARY."});
        then fail();
    end match;
  end solveUniqueFindInstructionsMultary;

  function solveUniqueFindInstructionsBinaryPow
    "find instructions for a binary with power operator"
    input Type ty;
    input Expression substExp;
    input Expression exp;
    input ComponentRef cref;
    input output Boolean crefFound;
    input output list<Expression> inverseInstructions;
    output Status status;
  protected
    Boolean crefFoundInRecursion;
    Expression local_exp1, local_exp2;
  algorithm
    () := match exp
      case Expression.BINARY() algorithm
        (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(exp.exp1, cref, crefFound, inverseInstructions);
        if status == Status.IMPLICIT then
          return;
        end if;
        if crefFoundInRecursion then
          // case for f(cref) ^ exp2 -> $SUBST_CREF^(1 / exp2)
          crefFound := true;
          if Expression.containsCref(exp.exp2, cref) then
            status := Status.IMPLICIT;
          else
            inverseInstructions := Expression.BINARY(substExp, exp.operator, Expression.MULTARY({}, {exp.exp2}, Operator.OPERATOR(ty, NFOperator.Op.MUL))) :: inverseInstructions;
          end if;
        else
          (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(exp.exp2, cref, crefFound, inverseInstructions);
          if status == Status.IMPLICIT then
            return;
          end if;
          if crefFoundInRecursion then
            // case for exp1 ^ f(cref) -> log($SUBST_CREF)/log(exp1)
            crefFound := true;
            local_exp1 := Expression.CALL(Call.makeTypedCall(
            fn          = NFBuiltinFuncs.LOG_REAL,
            args        = {substExp},
            variability = Expression.variability(substExp),
            purity      = NFPrefixes.Purity.PURE
            ));
            local_exp2 := Expression.CALL(Call.makeTypedCall(
            fn          = NFBuiltinFuncs.LOG_REAL,
            args        = {exp.exp1},
            variability = Expression.variability(exp.exp1),
            purity      = NFPrefixes.Purity.PURE
            ));
            // split the instructions, s.t. only top level search for substExp/dummyCref has to be performed in applyInstruction
            inverseInstructions := local_exp1 :: Expression.MULTARY({substExp}, {local_exp2}, Operator.OPERATOR(ty, NFOperator.Op.MUL)) :: inverseInstructions;
          end if;
        end if;
        then ();
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " can only be called for Expression.BINARY with operator POW."});
        then fail();
    end match;
  end solveUniqueFindInstructionsBinaryPow;

  function solveUniqueFindInstructionsBinaryComOp
    "find instructions for a binary with commutative operator
    simply calls multary with the corresponding op"
    input Expression substExp;
    input Expression exp;
    input ComponentRef cref;
    input output Boolean crefFound;
    input output list<Expression> inverseInstructions;
    output Status status;
  protected
    Boolean crefFoundInRecursion;
  algorithm
    () := match exp
      case Expression.BINARY() algorithm
        (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructionsMultary(substExp,
                               Expression.MULTARY({exp.exp1, exp.exp2}, {}, exp.operator), cref, crefFound, inverseInstructions);
        if status == Status.IMPLICIT then
          return;
        end if;
        if crefFoundInRecursion then
          crefFound := true;
        end if;
        then ();
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " can only be called for Expression.BINARY with commutative operator."});
        then fail();
    end match;
  end solveUniqueFindInstructionsBinaryComOp;

  function solveUniqueFindInstructionsCast
    "find instructions for a cast"
    input Expression substExp;
    input Expression exp;
    input ComponentRef cref;
    input output Boolean crefFound;
    input output list<Expression> inverseInstructions;
    output Status status;
  protected
    Boolean crefFoundInRecursion;
  algorithm
    () := match exp
      case Expression.CAST() algorithm
        (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(exp.exp, cref, crefFound, inverseInstructions);
        if status == Status.IMPLICIT then
          return;
        end if;
        if crefFoundInRecursion then
          crefFound := true;
        end if;
        then ();
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " can only be called for Expression.CAST."});
        then fail();
    end match;
  end solveUniqueFindInstructionsCast;

  function solveUniqueFindInstructionsUnaryUminus
    "find instructions for an unary with uminus operator"
    input Type ty;
    input Expression substExp;
    input Expression exp;
    input ComponentRef cref;
    input output Boolean crefFound;
    input output list<Expression> inverseInstructions;
    output Status status;
  protected
    Boolean crefFoundInRecursion;
  algorithm
    () := match exp
      case Expression.UNARY() algorithm
        (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(exp.exp, cref, crefFound, inverseInstructions);
            if status == Status.IMPLICIT then
              return;
            end if;
            if crefFoundInRecursion then
              // case for -(f(cref)) -> -($SUBST_CREF)
              crefFound := true;
              inverseInstructions := Expression.UNARY(Operator.OPERATOR(ty, NFOperator.Op.UMINUS), substExp) :: inverseInstructions;
            end if;
            then ();
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " can only be called for Expression.BINARY with commutative operator."});
        then fail();
    end match;
  end solveUniqueFindInstructionsUnaryUminus;

  function solveUniqueFindInstructionsCallOneArg
    "find instructions for a call with one argument"
    input Type ty;
    input Expression substExp;
    input Expression exp;
    input ComponentRef cref;
    input output Boolean crefFound;
    input output list<Expression> inverseInstructions;
    output Status status;
  protected
    Boolean crefFoundInRecursion;
    Expression argExp;
    Call call;
    String name;
  algorithm
    () := match exp
      case (Expression.CALL(call = call as Call.TYPED_CALL())) guard List.hasOneElement(Call.arguments(exp.call)) algorithm
        name :=  AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
        argExp := match Call.arguments(call)
          case {argExp} then argExp;
        end match;
        (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(argExp, cref, crefFound, inverseInstructions);
        if status == Status.IMPLICIT then
          return;
        end if;
        if crefFoundInRecursion then
          // case for call(f(cref)) -> call^{-1}($SUBST_CREF)
          crefFound := true;
          inverseInstructions := match name
            case "sqrt" then // sqrt(f(cref)) -> $SUBST_CREF^2
              Expression.BINARY(substExp, Operator.OPERATOR(ty, NFOperator.Op.POW), Expression.REAL(2)) :: inverseInstructions;
            case "cos" then // cos(f(cref)) -> acos($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.ACOS_REAL, substExp, inverseInstructions);
            case "sin" then // sin(f(cref)) -> asin($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.ASIN_REAL, substExp, inverseInstructions);
            case "tan" then // tan(f(cref)) -> atan($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.ATAN_REAL, substExp, inverseInstructions);
            case "acos" then // acos(f(cref)) -> cos($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.COS_REAL, substExp, inverseInstructions);
            case "asin" then // asin(f(cref)) -> sin($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.SIN_REAL, substExp, inverseInstructions);
            case "atan" then // atan(f(cref)) -> tan($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.TAN_REAL, substExp, inverseInstructions);
            case "cosh" then // cosh(f(cref)) -> acosh($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.ACOSH_REAL, substExp, inverseInstructions);
            case "sinh" then // sinh(f(cref)) -> asinh($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.ASINH_REAL, substExp, inverseInstructions);
            case "tanh" then // tanh(f(cref)) -> atanh($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.ATANH_REAL, substExp, inverseInstructions);
            case "acosh" then // acosh(f(cref)) -> cosh($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.COSH_REAL, substExp, inverseInstructions);
            case "asinh" then // asinh(f(cref)) -> sinh($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.SINH_REAL, substExp, inverseInstructions);
            case "atanh" then // atanh(f(cref)) -> tanh($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.TANH_REAL, substExp, inverseInstructions);
            case "exp" then // exp(f(cref)) -> log($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.LOG_REAL, substExp, inverseInstructions);
            case "log" then // log(f(cref)) -> exp($SUBST_CREF)
              solveUniqueCreateSubstCall(NFBuiltinFuncs.EXP_REAL, substExp, inverseInstructions);
            case "log10" then // log_10(f(cref)) -> 10^($SUBST_CREF)
              Expression.BINARY(Expression.REAL(10), Operator.OPERATOR(ty, NFOperator.Op.POW), substExp) :: inverseInstructions;
            else algorithm // fallback -> set implicit
              if Flags.isSet(Flags.DUMP_SOLVE) then
                solveUniquePrintImplicitFallback(exp);
              end if;
              status := Status.IMPLICIT;
              then inverseInstructions;
          end match;
        end if;
        then ();
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " can only be called for Expression.CALL with one argument."});
        then fail();
    end match;
  end solveUniqueFindInstructionsCallOneArg;

  function solveUniqueFindInstructionsCallTwoArgs
    "find instructions for a call with two arguments"
    input Type ty;
    input Expression substExp;
    input Expression exp;
    input ComponentRef cref;
    input output Boolean crefFound;
    input output list<Expression> inverseInstructions;
    output Status status;
  protected
    Boolean crefFoundInRecursion;
    Expression argExp1, argExp2, e1, e2;
    Call call;
    String name;
  algorithm
    () := match exp
      case (Expression.CALL(call = call as Call.TYPED_CALL())) guard(listLength(Call.arguments(exp.call)) == 2) algorithm
        name :=  AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
        {argExp1, argExp2} := match Call.arguments(call)
          case {argExp1, argExp2} then {argExp1, argExp2};
        end match;
        (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(argExp1, cref, crefFound, inverseInstructions);
        if status == Status.IMPLICIT then
          return;
        end if;
        if crefFoundInRecursion then
          crefFound := true;
          if Expression.containsCref(argExp2, cref) then
            status := Status.IMPLICIT;
          else
            // calc inverse w.r.t first argument and append to instructions
            inverseInstructions := match name
              case "atan2" algorithm // atan2(x,y) -> x=y*tan($SUBST_CREF)
                inverseInstructions := Expression.MULTARY({substExp, argExp2}, {}, Operator.OPERATOR(ty, NFOperator.Op.MUL)) :: inverseInstructions;
                then solveUniqueCreateSubstCall(NFBuiltinFuncs.TAN_REAL, substExp, inverseInstructions);
              else algorithm // fallback -> set implicit
                if Flags.isSet(Flags.DUMP_SOLVE) then
                  solveUniquePrintImplicitFallback(exp);
                end if;
                status := Status.IMPLICIT;
                then inverseInstructions;
            end match;
          end if;
        else
          (crefFoundInRecursion, inverseInstructions, status) := solveUniqueFindInstructions(argExp2, cref, crefFound, inverseInstructions);
          if status == Status.IMPLICIT then
            return;
          end if;
          if crefFoundInRecursion then
            crefFound := true;
            // calc inverse w.r.t second argument and append to instructions
            inverseInstructions := match name
              case "atan2" algorithm // atan2(x,y) -> y=x/tan($SUBST_CREF)
                inverseInstructions := Expression.MULTARY({argExp1}, {substExp}, Operator.OPERATOR(ty, NFOperator.Op.MUL)) :: inverseInstructions;
                then solveUniqueCreateSubstCall(NFBuiltinFuncs.TAN_REAL, substExp, inverseInstructions);
              else algorithm // fallback -> set implicit
                if Flags.isSet(Flags.DUMP_SOLVE) then
                  solveUniquePrintImplicitFallback(exp);
                end if;
                status := Status.IMPLICIT;
                then inverseInstructions;
            end match;
          end if;
        end if;
        then ();
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " can only be called for Expression.CALL with two arguments."});
        then fail();
    end match;
  end solveUniqueFindInstructionsCallTwoArgs;

  function solveUniqueCreateSubstCall
    "helper to create call with substitute cref and to the instructions"
    input Function fn;
    input Expression exp;
    input output list<Expression> inverseInstructions;
  algorithm
    inverseInstructions := Expression.CALL(Call.makeTypedCall(
                                           fn          = fn,
                                           args        = {exp},
                                           variability = Expression.variability(exp),
                                           purity      = NFPrefixes.Purity.PURE
                                           )) :: inverseInstructions;
  end solveUniqueCreateSubstCall;

  function solvePrintInput
    input Equation eqn;
    input ComponentRef crefExp;
  algorithm
    print("\n##########################################\nSTART - Solve\n\n");
    print("Solve Input:\n");
    print("### Variable:\n\t" + ComponentRef.toString(crefExp) + "\n### Equation:\n\t" + Equation.toString(eqn) + "\n\n");
  end solvePrintInput;

  function solvePrintOutput
    input Equation eqn;
    input Status status;
  algorithm
    print("Solve Output:\n");
    print("### Status:\n\t" + statusString(status) + "\n");
    print("### Equation:\n\t" + Equation.toString(eqn) + "\n");
    print("\nEND - Solve\n##########################################\n\n");
  end solvePrintOutput;

  function solveUniquePrintInstructions
    input list<Expression> inverseInstructions;
    input Status status;
  algorithm
    print("SolveUnique Instructions (substitute from top to bottom):\n");
    print("\t0 (is initial)\n");
    for instruction in inverseInstructions loop
      print("\t" + Expression.toString(instruction) + "\n");
    end for;
    print("### Status:\n\t" + statusString(status) + "\n");
    print("\n");
  end solveUniquePrintInstructions;

  function solveUniquePrintImplicitFallback
    input Expression exp;
  algorithm
    print("Setting Status.Implicit (fallback) due to:\n");
    print("### Expression:\n\t" + Expression.toString(exp) + "\n");
    print("\n");
  end solveUniquePrintImplicitFallback;

  function applyInstruction
    "substitute insertExp for $SUBST_CREF in instruction"
    input output Expression insertExp;
    input Expression instruction;
  algorithm
    insertExp := match instruction
      local
        list<Expression> argList = {}, invargList = {};
        Expression exp;
      case Expression.MULTARY() algorithm
        for arg in instruction.arguments loop
          if not Expression.isSubstitute(arg) then
            argList := arg :: argList;
          else
            argList := insertExp :: argList;
          end if;
        end for;
        for invarg in instruction.inv_arguments loop
          if not Expression.isSubstitute(invarg) then
            invargList := invarg :: invargList;
          else
            invargList := insertExp :: invargList;
          end if;
        end for;
        then Expression.MULTARY(argList, invargList, instruction.operator);
      case Expression.BINARY() algorithm
        if Expression.isSubstitute(instruction.exp1) then
          instruction.exp1 := insertExp;
        end if;
        if Expression.isSubstitute(instruction.exp2) then
          instruction.exp2 := insertExp;
        end if;
        then instruction;
      case Expression.UNARY() algorithm
        if Expression.isSubstitute(instruction.exp) then
          instruction.exp := insertExp;
        end if;
        then instruction;
      case exp as Expression.CALL() algorithm
        () := match instruction.call
          local Call local_call;
          case local_call as Call.TYPED_CALL() algorithm
            for arg in local_call.arguments loop
              if not Expression.isSubstitute(arg) then
                argList := arg :: argList;
              else
                argList := insertExp :: argList;
              end if;
            end for;
            local_call.arguments := listReverse(argList);
            exp.call := local_call;
            then ();
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " can only handle TYPED_CALL."});
            then fail();
        end match;
        then exp;
    end match;
  end applyInstruction;

  function tupleSolvable
    "checks if the tuple expression exactly represents the variables we need to solve for"
    input list<Expression> tuple_exps;
    input list<Pointer<Variable>> vars;
    output Boolean b = false;
  protected
    list<Expression> filtered_exps = list(e for e guard(not Expression.isWildCref(e)) in tuple_exps);
    UnorderedMap<ComponentRef, Boolean> map;
  algorithm
    if List.compareLength(filtered_exps, vars) == 0 then
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

    if List.hasOneElement(slices_lst) then
      var_cref := listHead(slices_lst);
      solve_status := Status.UNPROCESSED;
    else
      // check if the record parents occur (todo: vice versa?)
      record_parent := BVariable.getParent(BVariable.getVarPointer(var_cref));
      if Util.isSome(record_parent) then
        (var_cref, solve_status) := getVarSlice(BVariable.getVarName(Util.getOption(record_parent)), eqn);
      else
        // todo: choose best slice of list if more than one.
        // only fail for listEmpty
        solve_status := Status.UNSOLVABLE;
      end if;
    end if;
  end getVarSlice;

  function solveForVarSlice
    input output Slice<EquationPointer> eqn_slice;
    input Slice<VariablePointer> var_slice;
    input output FunctionTree funcTree;
    input BPartition.Kind kind;
    input output Integer implicit_index;
    input UnorderedMap<ComponentRef, list<Pointer<Equation>>> slicing_map;
    input VarData varData;
    input EqData eqData;
    output Status solve_status;
  protected
    Equation eqn;
    ComponentRef var_cref;
  algorithm
    eqn := Pointer.access(Slice.getT(eqn_slice));
    (var_cref, solve_status) := getVarSlice(BVariable.getVarName(Slice.getT(var_slice)), eqn);

    if solve_status < Status.UNSOLVABLE then
      (eqn, funcTree, solve_status, implicit_index, _) := solveEquation(eqn, var_cref, funcTree, kind, implicit_index, slicing_map, varData, eqData);
      eqn_slice := Slice.SLICE(Pointer.create(eqn), {});
    end if;
  end solveForVarSlice;

  annotation(__OpenModelica_Interface="backend");
end NBSolve;

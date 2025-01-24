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
encapsulated uniontype NBResizable<T>
" file:         NBResizable.mo
  package:      NBResizable
  description:  This file contains util functions for resizable parameters.
"

protected
  // frontend imports
  import NFBackendExtension.{BackendInfo, VariableAttributes};
  import Binding = NFBinding;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import NFFlatten.FunctionTreeImpl;
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Operator = NFOperator;
  import Variable = NFVariable;

  // backend imports
  import NBEquation.{Equation, Iterator, EquationPointers, EquationAttributes, EquationKind};
  import NBVariable.{VarData, VariablePointers};
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import NBDifferentiate.DifferentiationArguments;
  import Replacements = NBReplacements;
  import Solve = NBSolve;
public
  constant Boolean debug = false; // SET TO TRUE FOR DEBUGGING
  type EvalOrder = enumeration(INDEPENDENT, FORWARD, BACKWARD, FAILED);

  function resize
    "this resizes the resizable parameters to the optimal value to get the smallest possible system"
    input output EquationPointers equations;
    input output VarData varData;
  protected
    UnorderedSet<ComponentRef> parameters, min_parameters;
    UnorderedMap<ComponentRef, Expression> optimal_values;
    // c2p: constraint to parameters map
    // p2c: parameter to constraints map
    // i: inequality constraints
    // e: equality constraints
    UnorderedMap<Expression, ParameterList> c2pi, c2pe;
    UnorderedMap<ComponentRef, ConstraintList> p2ci, p2ce;
    partial function applyFunc
      input output Type ty;
    end applyFunc;
    applyFunc func;
  algorithm
    varData := match varData
      // only do something if there are resizable variables
      case VarData.VAR_DATA_SIM() guard(VariablePointers.size(varData.resizables) > 0) algorithm
        // prepare sets and maps
        parameters        := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        min_parameters    := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        optimal_values    := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
        c2pi              := UnorderedMap.new<ParameterList>(Expression.hash, Expression.isEqual);
        c2pe              := UnorderedMap.new<ParameterList>(Expression.hash, Expression.isEqual);

        // find the optimal values for iterators
        EquationPointers.map(equations, function findOptimalResizableValues(parameters = parameters, min_parameters = min_parameters, optimal_values = optimal_values, c2pi = c2pi, c2pe = c2pe));

        // initialize the optimal values for parameters with their min or max attribute (or 0 if none available)
        UnorderedSet.apply(parameters, function setInitialValues(min_parameters = min_parameters, optimal_values = optimal_values));

        if debug then
          print(optimalValuesToString(optimal_values, StringUtil.headline_2("[debug] Initial Resizable Parameter Values:") + "\n"));
          print(List.toString(UnorderedMap.keyList(c2pi), Expression.toString, StringUtil.headline_2("[debug] Final Inequality Constraints:"), "  0 >= ", "\n  0 >= ", "\n") + "\n");
          print(List.toString(UnorderedMap.keyList(c2pe), Expression.toString, StringUtil.headline_2("[debug] Final Equality Constraints:"), "  0 = ", "\n  0 = ", "\n") + "\n");
        end if;

        // compute the optimal values by checking constraints
        p2ci := invertConstraintParameterMap(c2pi, parameters);
        p2ce := invertConstraintParameterMap(c2pe, parameters);
        computeOptimalValues(optimal_values, c2pi, p2ci, c2pe, p2ce);

        // traverse the model and update all values depending on these resizable parameters
        func := function Type.applyToDims(func = function updateDimension(optimal_values = optimal_values));
        // update variables
        varData.variables := VariablePointers.map(varData.variables, function Variable.applyToType(func = func));
        varData.variables := VariablePointers.mapPtr(varData.variables, function BVariable.updateResizableParameter(optimal_values = optimal_values));
        varData.variables := VariablePointers.mapPtr(varData.variables, function BVariable.mapExp(funcExp = function Expression.applyToType(func = func), mapFunc = Expression.map));
        // update equations
        EquationPointers.mapPtr(equations, function Equation.applyToType(func = func));
        equations := EquationPointers.mapExp(equations, function Expression.applyToType(func = func));
        EquationPointers.mapRes(equations, function BVariable.applyToType(func = func));

        if Flags.isSet(Flags.DUMP_RESIZABLE) or debug then
          print(optimalValuesToString(optimal_values));
        end if;
      then varData;

      else algorithm
        if Flags.isSet(Flags.DUMP_RESIZABLE) or debug then
          print(StringUtil.headline_2("[dumpResizable] No resizable parameters were detected in the model."));
        end if;
      then varData;
    end match;
  end resize;

  function detect
    "this function detects if an equation is resizable"
    input Equation eqn;
    input ComponentRef cref_to_solve;
    output UnorderedMap<ComponentRef, EvalOrder> order;
  protected
    Pointer<Variable> var_ptr = BVariable.getVarPointer(cref_to_solve);
    UnorderedSet<ComponentRef> var_occurences = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    UnorderedSet<ComponentRef> ite_occurences;
    list<ComponentRef> occ_lst, iterators;
    list<list<Subscript>> subs;
    list<Subscript> subs_to_solve, local_subs;
    Subscript sub_to_solve;
    ComponentRef iter;
    DifferentiationArguments args;
    Option<Integer> opt_factor;
    Integer factor;
    Expression shift;
    Integer shift_value, v2;
    EvalOrder eval;
  algorithm
    order := match eqn
      case Equation.FOR_EQUATION() algorithm
        for body in eqn.body loop
          Equation.map(body, function collectVars(func = function BVariable.equalName(var_ptr2 = var_ptr), collector = var_occurences));
          occ_lst := UnorderedSet.toList(var_occurences);
          (iterators, _)  := Iterator.getFrames(Equation.getForIterator(eqn));
          order := UnorderedMap.fromLists(iterators, list(EvalOrder.INDEPENDENT for i in iterators), ComponentRef.hash, ComponentRef.isEqual);
          if listLength(occ_lst) <> 1 then
            subs  := list(ComponentRef.subscriptsAllWithWholeFlat(cref) for cref in occ_lst);
            subs  := List.transposeList(subs);
            subs_to_solve := ComponentRef.subscriptsAllWithWholeFlat(cref_to_solve);
            for dim in List.zip(subs, subs_to_solve) loop
              (local_subs, sub_to_solve) := dim;
              ite_occurences := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
              for sub in local_subs loop
                Subscript.mapExp(sub, function collectVars(func = BVariable.isIterator, collector = ite_occurences));
              end for;
              iterators := UnorderedSet.toList(ite_occurences);
              _ := match iterators
                case {iter} algorithm
                  eval := UnorderedMap.getSafe(iter, order, sourceInfo());
                  if eval < EvalOrder.FAILED then
                    args := DifferentiationArguments.simpleCref(iter);
                    opt_factor := NONE();
                    for sub in local_subs loop
                      factor := getFactor(Subscript.toExp(sub), args, opt_factor);
                      opt_factor := SOME(factor);
                    end for;

                    _ := match opt_factor
                      case SOME(factor) guard(factor <> 0) algorithm
                        try
                          Expression.INTEGER(shift_value) := getShift(Subscript.toExp(sub_to_solve), iter);
                          for sub in local_subs loop
                            Expression.INTEGER(v2) := getShift(Subscript.toExp(sub), iter);
                            eval := match eval
                              case EvalOrder.INDEPENDENT  guard(shift_value == v2)  then EvalOrder.INDEPENDENT;
                              case EvalOrder.INDEPENDENT  guard(shift_value > v2)   then EvalOrder.FORWARD;
                              case EvalOrder.INDEPENDENT  guard(shift_value < v2)   then EvalOrder.BACKWARD;
                              case EvalOrder.FORWARD      guard(shift_value >= v2)  then EvalOrder.FORWARD;
                              case EvalOrder.BACKWARD     guard(shift_value <= v2)  then EvalOrder.BACKWARD;
                              else EvalOrder.FAILED;
                            end match;
                          end for;
                          if eval == EvalOrder.FAILED then break; end if;
                        else
                          eval := EvalOrder.FAILED;
                        end try;
                        UnorderedMap.add(iter, eval, order);
                      then ();
                      else ();
                    end match;
                  end if;
                then ();

                else algorithm
                  for it in iterators loop
                    UnorderedMap.add(it, EvalOrder.FAILED, order);
                  end for;
                  break;
                then ();
              end match;
            end for;
          end if;
        end for;
      then order;
      else algorithm
        order := UnorderedMap.fromLists({ComponentRef.EMPTY()}, {EvalOrder.FAILED}, ComponentRef.hash, ComponentRef.isEqual);
      then order;
    end match;
  end detect;

  function orderFailed
    input EvalOrder eo;
    output Boolean b = eo == EvalOrder.FAILED;
  end orderFailed;

protected
  type ParameterList = list<ComponentRef>;
  type ConstraintList = list<Expression>;
  type Occurences = UnorderedSet<Expression>;
  constant tuple<ComponentRef, Expression> END_TPL = (ComponentRef.EMPTY(), Expression.END());

  function findOptimalResizableValues
    input output Equation eqn;
    input UnorderedSet<ComponentRef> parameters;
    input UnorderedSet<ComponentRef> min_parameters;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
    input UnorderedMap<Expression, ParameterList> c2pi;
    input UnorderedMap<Expression, ParameterList> c2pe;
  protected
    UnorderedMap<ComponentRef, Expression> resizables, replacements;
    UnorderedMap<ComponentRef, Occurences> occs;
    UnorderedSet<ComponentRef> constrained_vars = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    Dimension lhs_dim, rhs_dim;
    Expression const;
    UnorderedSet<ComponentRef> local_parameters;
  algorithm
    if debug then
      print("[debug] checking equation:\n" + Equation.toString(eqn) + "\n");
    end if;

    _ := match eqn
      // Main Routine: collect iterators and resizable parameter constraints and target equations
      case Equation.FOR_EQUATION() algorithm
        resizables    := getResizableIterators(eqn.iter);
        replacements  := getVarReplacements(eqn.iter);

        // add all resizable iterators with empty occurence sets to intialize
        occs := UnorderedMap.new<Occurences>(ComponentRef.hash, ComponentRef.isEqual);
        for res in UnorderedMap.keyList(resizables) loop
          UnorderedMap.add(res, UnorderedSet.new(Expression.hash, Expression.isEqual), occs);
        end for;

        // fill the occurence sets traversing the body of the equation
        for body in eqn.body loop
          Equation.map(body, function collectOccurences(occs = occs));
          Equation.map(body, function collectVars(func = BVariable.isArray, collector = constrained_vars));
        end for;
        findOptimalValue(eqn, occs, resizables, parameters, min_parameters, optimal_values, c2pi);
        UnorderedSet.fold(constrained_vars, function addVariableConstraint(eqn = eqn, replacements = SOME(replacements)), c2pi);
      then ();

      case Equation.ARRAY_EQUATION() algorithm
        for tpl in List.zip(Type.arrayDims(Expression.typeOf(eqn.lhs)), Type.arrayDims(Expression.typeOf(eqn.rhs))) loop
          (lhs_dim, rhs_dim) := tpl;
          if Dimension.isResizable(lhs_dim) or Dimension.isResizable(rhs_dim) then
            const := Expression.MULTARY({Dimension.sizeExp(lhs_dim)}, {Dimension.sizeExp(rhs_dim)}, Operator.makeAdd(Type.INTEGER()));
            try
              addConstraint(const, NONE(), c2pe, Expression.isZero, "array dimension", "=");
            else
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed.\nViolation of implicit constraint `" + Dimension.toString(lhs_dim) + " = " + Dimension.toString(rhs_dim)
                + "` for LHS and RHS type dimensions in equation:\n" + Equation.toString(eqn)});
              fail();
            end try;
          end if;
        end for;
      then ();

      else algorithm
        // create dummy replacements (no iterators to replace)
        Equation.map(eqn, function collectVars(func = BVariable.isResizable, collector = constrained_vars));
        // subs: [n] dim [m] --> m >= n --> implication on split?
        // subs: [10] dim [m] --> m >= 10 also implication on split values
        UnorderedSet.fold(constrained_vars, function addVariableConstraint(eqn = eqn, replacements = NONE()), c2pi);
      then ();
    end match;
    if debug then
      print("\n");
    end if;
  end findOptimalResizableValues;

  function getResizableIterators
    input Iterator iter;
    output UnorderedMap<ComponentRef, Expression> resizables = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
  protected
    list<ComponentRef> names;
    list<Expression> ranges;
  algorithm
    (names, ranges) := Iterator.getFrames(iter);
    for tpl in List.zip(names, ranges) loop
      if iteratorIsResizable(Util.tuple22(tpl)) then
        UnorderedMap.add(Util.tuple21(tpl), Util.tuple22(tpl), resizables);
      end if;
    end for;
  end getResizableIterators;

  function getVarReplacements
    input Iterator iter;
    output UnorderedMap<ComponentRef, Expression> replacements = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
  protected
    list<ComponentRef> names;
    list<Expression> ranges;
    ComponentRef name;
    Expression range, max_call;
  algorithm
    (names, ranges) := Iterator.getFrames(iter);
    for tpl in List.zip(names, ranges) loop
      (name, range) := tpl;
      _ := match range
        case Expression.RANGE() algorithm
          if Util.isSome(range.step) and Expression.isNegative(Util.getOption(range.step)) then
            UnorderedMap.add(name, range.start, replacements);
          elseif Util.isNone(range.step) or Expression.isPositive(Util.getOption(range.step)) then
            UnorderedMap.add(name, range.stop, replacements);
          else
            max_call := Expression.CALL(Call.makeTypedCall(
              fn          = NFBuiltinFuncs.MAX_INT,
              args        = {range.start, range.stop},
              variability = Expression.variability(range.start),
              purity      = NFPrefixes.Purity.PURE
            ));
            UnorderedMap.add(name, max_call, replacements);
          end if;
        then ();
        else ();
      end match;
    end for;
  end getVarReplacements;

  function iteratorIsResizable
    input Expression range;
    output Boolean b = Expression.fold(range, expContainsResizable, false);
  end iteratorIsResizable;

  function expContainsResizable
    "needs to be mapped with Expression.fold()"
    input Expression exp;
    input output Boolean b;
  algorithm
    if not b then
      b := match exp
        case Expression.CREF() then BVariable.checkCref(exp.cref, BVariable.isResizableParameter);
        else false;
      end match;
    end if;
  end expContainsResizable;

  function collectResizables
    "needs to be mapped with Expression.map()"
    input output Expression exp;
    input UnorderedSet<ComponentRef> collector;
  algorithm
    _ := match exp
      case Expression.CREF() guard(BVariable.checkCref(exp.cref, BVariable.isResizableParameter)) algorithm
        UnorderedSet.add(exp.cref, collector);
      then ();
      else ();
    end match;
  end collectResizables;

  function collectOccurences
    input output Expression exp;
    input UnorderedMap<ComponentRef, Occurences> occs;
  algorithm
    _ := match exp
      case Expression.CREF() algorithm
        _ := ComponentRef.mapSubscripts(exp.cref, function collectOccurencesSubscript(occs = occs));
      then ();
      else ();
    end match;
  end collectOccurences;

  function collectOccurencesSubscript
    input output Subscript sub;
    input UnorderedMap<ComponentRef, Occurences> occs;
  protected
    UnorderedSet<ComponentRef> acc = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    Expression subExp;
  algorithm
    Subscript.mapExp(sub, function collectOccurencesSubscriptExp(occs = occs, acc = acc));
    if not UnorderedSet.isEmpty(acc) then
      subExp := Subscript.toExp(sub);
      UnorderedSet.apply(acc, function addOccurence(subExp = subExp, occs = occs));
    end if;
  end collectOccurencesSubscript;

  function collectOccurencesSubscriptExp
    input output Expression exp;
    input UnorderedMap<ComponentRef, Occurences> occs;
    input UnorderedSet<ComponentRef> acc;
  algorithm
    _ := match exp
      case Expression.CREF() guard(UnorderedMap.contains(exp.cref, occs)) algorithm
        UnorderedSet.add(exp.cref, acc);
      then ();
      else ();
    end match;
  end collectOccurencesSubscriptExp;

  function addOccurence
    input output ComponentRef iter;
    input Expression subExp;
    input UnorderedMap<ComponentRef, Occurences> occs;
  protected
    UnorderedSet<Expression> local_occ = UnorderedMap.getSafe(iter, occs, sourceInfo());
  algorithm
    UnorderedSet.add(subExp, local_occ);
  end addOccurence;

  function collectVars
    input output Expression exp;
    input BVariable.checkVar func;
    input UnorderedSet<ComponentRef> collector;
  algorithm
    _ := match exp
      case Expression.CREF() guard(func(BVariable.getVarPointer(exp.cref))) algorithm
        UnorderedSet.add(exp.cref, collector);
      then ();
      else();
    end match;
  end collectVars;

  function findOptimalValue
    input Equation eqn;
    input UnorderedMap<ComponentRef, Occurences> occs;
    input UnorderedMap<ComponentRef, Expression> resizables;
    input UnorderedSet<ComponentRef> parameters;
    input UnorderedSet<ComponentRef> min_parameters;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
    input UnorderedMap<Expression, ParameterList> c2pi;
  protected
    Option<Integer> opt_factor = NONE();
    Integer min_distance = 0;
    Integer max_distance = 0;
    Integer distance;
    ComponentRef cref;
    UnorderedSet<Expression> occ;
    DifferentiationArguments args;
    list<tuple<ComponentRef, Integer>> optimal_distances = {};
    list<ComponentRef> failed_crefs = {};
    list<ComponentRef> failed_iters = {};
    Expression range, step, target, distance_const;
    UnorderedSet<ComponentRef> local_parameters;
  algorithm
    for tpl in UnorderedMap.toList(occs) loop
      (cref, occ) := tpl;
      for exp in UnorderedSet.toList(occ) loop
        args := DifferentiationArguments.simpleCref(cref);
        (opt_factor, min_distance, max_distance) := getDistance(cref, exp, args, opt_factor, min_distance, max_distance);
      end for;
      if Util.isSome(opt_factor) and Util.getOption(opt_factor) <> 0 then
        optimal_distances := (cref, max_distance - min_distance) :: optimal_distances;
      else
        failed_crefs := cref :: failed_crefs;
      end if;
    end for;

    for tpl in optimal_distances loop
      (cref, distance) := tpl;
      range := UnorderedMap.getSafe(cref, resizables, sourceInfo());
      Expression.map(range, function collectResizables(collector = parameters));
      _ := match range
        case Expression.RANGE() algorithm
          step := Util.getOptionOrDefault(range.step, Expression.INTEGER(1));
          // collect local parameters and merge with global parameters
          local_parameters := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
          _ := Expression.map(range, function collectResizables(collector = local_parameters));
          UnorderedSet.merge(parameters, local_parameters);
          // optimization target function (minimum)
          // min! f(x) = stop - start
          target := Expression.MULTARY({range.stop}, {range.start}, Operator.makeAdd(Type.INTEGER()));
          target := SimplifyExp.simplify(target);

          // differentiate the target by all contained parameters to determine initial values
          UnorderedSet.apply(local_parameters, function getInitialValues(target = target, args = args, min_parameters = min_parameters, optimal_values = optimal_values));

          // the optimal distance constraint
          // distance - (stop - start)/start <= 0
          distance_const := Expression.MULTARY({Expression.INTEGER(distance)}, {Expression.MULTARY({target}, {step}, Operator.makeMul(Type.INTEGER()))}, Operator.makeAdd(Type.INTEGER()));
          distance_const := SimplifyExp.simplify(distance_const);
          distance_const := SimplifyExp.combineBinaries(distance_const);
          distance_const := SimplifyExp.simplify(distance_const);
          UnorderedMap.add(distance_const, UnorderedSet.toList(local_parameters), c2pi);
          if debug then
            print("[debug] adding equation constraint: 0 >= " + Expression.toString(distance_const) + "\n");
          end if;
        then ();
        else ();
      end match;
    end for;
  end findOptimalValue;

  function getFactor
    input Expression exp;
    input DifferentiationArguments args;
    input Option<Integer> opt_factor;
    output Integer factor;
  protected
    Expression diff;
  algorithm
    diff := Differentiate.differentiateExpression(exp, args);
    diff := SimplifyExp.simplify(diff);
    factor := Expression.integerValueOrDefault(diff, 0);

    if Util.isSome(opt_factor) and factor <> Util.getOption(opt_factor) then
      factor := 0;
    end if;
  end getFactor;

  function getShift
    input Expression exp;
    input ComponentRef cref;
    output Expression shift;
  algorithm
    shift := Replacements.single(exp, Expression.CREF(Type.INTEGER(), cref), Expression.INTEGER(0));
    shift := SimplifyExp.simplify(shift);
  end getShift;

  function getDistance
    input ComponentRef cref;
    input Expression exp;
    input DifferentiationArguments args;
    input output Option<Integer> opt_factor;
    input output Integer min_distance;
    input output Integer max_distance;
  protected
    Expression shift;
    Integer factor, distance;
  algorithm
    if Util.isNone(opt_factor) or Util.getOption(opt_factor) <> 0 then
      factor := getFactor(exp, args, opt_factor);

      if factor <> 0 then
        // if the factor checks out, get shift and update min and max
        shift := getShift(exp, cref);
        try
          // the shift has to be a single integer value
          Expression.INTEGER(distance) := shift;
          if Util.isNone(opt_factor) then
            min_distance := distance;
            max_distance := distance;
            opt_factor := SOME(factor);
          else
            min_distance := intMin(distance, min_distance);
            max_distance := intMax(distance, max_distance);
          end if;
        else
          // failed
          min_distance := 0;
          max_distance := 0;
          opt_factor := SOME(0);
        end try;
      else
        // failed
        min_distance := 0;
        max_distance := 0;
        opt_factor := SOME(0);
      end if;
    end if;
  end getDistance;

  function addVariableConstraint
    input ComponentRef cref;
    input Equation eqn "for debugging only";
    input Option<UnorderedMap<ComponentRef, Expression>> replacements;
    input output UnorderedMap<Expression, ParameterList> c2pi;
  protected
    Variable var = Pointer.access(BVariable.getVarPointer(cref));
    list<Dimension> dims = Type.arrayDims(var.ty);
    list<Subscript> subs = ComponentRef.subscriptsAllWithWholeFlat(cref); // needs list reverse?
    Dimension dim;
    Subscript sub;
    Expression sub_exp, const;
    Operator op = Operator.makeAdd(Type.INTEGER());
  algorithm
    for tpl in List.zip(dims, subs) loop
      (dim, sub) := tpl;
      sub_exp := Subscript.toExp(sub);
      const   := Expression.MULTARY({sub_exp}, {Dimension.sizeExp(dim)}, op);
      try
        addConstraint(const, replacements, c2pi, Expression.isNonPositive, "variable", ">=");
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed.\nViolation of implicit constraint `" + Dimension.toString(dim) + " >= " + Subscript.toString(sub)
          + "` for component reference `" + ComponentRef.toString(cref) + "` of variable `" + Variable.toString(Pointer.access(BVariable.getVarPointer(cref))) + "`\nin equation:\n" + Equation.toString(eqn)});
        fail();
      end try;
    end for;
  end addVariableConstraint;

  function addConstraint
    input Expression old_const;
    input Option<UnorderedMap<ComponentRef, Expression>> replacements;
    input UnorderedMap<Expression, ParameterList> c2p;
    input checkFunc func "checks validity of redundant constraints";
    input String const_kind "only for debugging: words to describe the kind of constraint";
    input String eq_kind "only for debugging: in/equality symbols (=, >=, <=, >, <)";
    partial function checkFunc
      input Expression exp;
      output Boolean b;
    end checkFunc;
  protected
    Expression const, diff;
    UnorderedSet<ComponentRef> parameters;
    list<ComponentRef> params;
    Boolean redundant;
    DifferentiationArguments args;
    UnorderedMap<ComponentRef, Expression> zero_replacements;
  algorithm
    if Util.isSome(replacements) then
      const := Expression.map(old_const, function Replacements.applySimpleExp(replacements = Util.getOption(replacements)));
    else
      const := old_const;
    end if;
    parameters := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    Expression.map(const, function collectResizables(collector = parameters));
    params := UnorderedSet.toList(parameters);

    redundant := true;
    for p in params loop
      args := DifferentiationArguments.simpleCref(p);
      diff := Differentiate.differentiateExpression(const, args);
      diff := SimplifyExp.simplify(diff);
      if not Expression.isZero(diff) then
        redundant := false; break;
      end if;
    end for;

    if not redundant then
      UnorderedMap.add(const, params, c2p);
    else
      zero_replacements := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);
      for p in params loop
        UnorderedMap.add(p, Expression.INTEGER(0), zero_replacements);
      end for;
      const := Expression.map(const, function Replacements.applySimpleExp(replacements = zero_replacements));
      const := SimplifyExp.simplify(const);
      if not func(const) then fail(); end if;
    end if;

    if debug then
      if redundant then
        print("[debug] not adding redundant " + const_kind + " constraint: 0 " + const_kind + " " + Expression.toString(old_const) + " simplified to: 0 " + const_kind + " " + Expression.toString(const) + "\n");
      else
        print("[debug] adding " + const_kind + " constraint: 0 " + const_kind + " " + Expression.toString(old_const) + " simplified to: 0 " + const_kind + " " + Expression.toString(const) + "\n");
      end if;
    end if;
  end addConstraint;

  function getInitialValues
    input output ComponentRef cref;
    input Expression target;
    input DifferentiationArguments args;
    input UnorderedSet<ComponentRef> min_parameters;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
  protected
    Expression diff, binding;
    Boolean failed = false;
    Variable var;
  algorithm
    args.diffCref := cref;
    diff := Differentiate.differentiateExpression(target, args);
    diff := SimplifyExp.simplify(diff);

    if Expression.isPositive(diff) then
      // use min value as initial guess
      UnorderedSet.add(cref, min_parameters);
    elseif Expression.isNegative(diff) then
      // use max value as initial guess
    else
      // cannot be determined -> use actual binding value
      var := Pointer.access(BVariable.getVarPointer(cref));
      binding := Binding.getExp(var.binding);
      UnorderedMap.add(cref, binding, optimal_values);
    end if;
  end getInitialValues;

  function setInitialValues
    input output ComponentRef cref;
    input UnorderedSet<ComponentRef> min_parameters;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
  protected
    Variable var;
    VariableAttributes attributes;
    Expression value;
  algorithm
    if not UnorderedMap.contains(cref, optimal_values) then
      var := Pointer.access(BVariable.getVarPointer(cref));
      value := match var
        case Variable.VARIABLE(backendinfo = BackendInfo.BACKEND_INFO(attributes = attributes as VariableAttributes.VAR_ATTR_INT())) algorithm
          if UnorderedSet.contains(cref, min_parameters) then
            if Util.isSome(attributes.min) then
              SOME(value) := attributes.min;
            else
              value := Expression.INTEGER(0);
            end if;
          elseif Util.isSome(attributes.max) then
            SOME(value) := attributes.max;
          else
            value := Expression.INTEGER(0);
          end if;
        then value;
        else Expression.INTEGER(0);
      end match;
      UnorderedMap.add(cref, value, optimal_values);
    end if;
  end setInitialValues;

  function invertConstraintParameterMap
    input UnorderedMap<Expression, ParameterList> c2p;
    input UnorderedSet<ComponentRef> parameters;
    output UnorderedMap<ComponentRef, ConstraintList> p2c = UnorderedMap.new<ConstraintList>(ComponentRef.hash, ComponentRef.isEqual);
  protected
    Expression const;
    list<ComponentRef> params;
  algorithm
    // initializing map
    for param in UnorderedSet.toList(parameters) loop
      UnorderedMap.add(param, {}, p2c);
    end for;

    // inverting map
    for tpl in UnorderedMap.toList(c2p) loop
      (const, params) := tpl;
      for param in params loop
        UnorderedMap.add(param, const :: UnorderedMap.getSafe(param, p2c, sourceInfo()), p2c);
      end for;
    end for;
  end invertConstraintParameterMap;

  function computeOptimalValues
    input UnorderedMap<ComponentRef, Expression> optimal_values;
    input UnorderedMap<Expression, ParameterList> c2pi;
    input UnorderedMap<ComponentRef, ConstraintList> p2ci;
    input UnorderedMap<Expression, ParameterList> c2pe;
    input UnorderedMap<ComponentRef, ConstraintList> p2ce;
  protected
    UnorderedSet<ComponentRef> failed_parameters = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    fixConstraints(optimal_values, c2pi, p2ci, failed_parameters, function intLe(i2 = 0));
    fixConstraints(optimal_values, c2pe, p2ce, failed_parameters, function intEq(i2 = 0));
  end computeOptimalValues;

  function fixConstraints
    input UnorderedMap<ComponentRef, Expression> optimal_values;
    input UnorderedMap<Expression, ParameterList> c2p;
    input UnorderedMap<ComponentRef, ConstraintList> p2c;
    input UnorderedSet<ComponentRef> failed_parameters;
    input checkVal func "function to check if constraint is complied with";
    partial function checkVal
      input Integer i;
      output Boolean b;
    end checkVal;
  protected
    UnorderedSet<Expression> parsed_constraints = UnorderedSet.new(Expression.hash, Expression.isEqual);
    Expression constraint, replaced, old_optimal_value;
    list<ComponentRef> crefs;
    Equation eqn, solved_eqn;
    Solve.Status status;
    Integer value;
    Boolean failed;
  algorithm
    // traversing constraints
    for tpl in UnorderedMap.toList(c2p) loop
      (constraint, crefs) := tpl;
      _ := match checkConstraint(constraint, optimal_values)
        // this constraint is not violated
        case SOME(value) guard(func(value)) then ();

        // this constraint is violated
        case SOME(value)algorithm
          // create artificial equation
          eqn := Equation.makeAssignmentEqn(constraint, Expression.INTEGER(0), Iterator.EMPTY(), EquationAttributes.default(EquationKind.DISCRETE, false));
          for cref in crefs loop
            failed := false;
            // solve the artificial equation for cref
            (solved_eqn, _, status, _) := Solve.solveBody(eqn, cref, FunctionTreeImpl.EMPTY());
            if status == NBSolve.Status.EXPLICIT then
              // try to used solved value as new parameter value to fulfill constraint
              _ := match checkConstraint(Equation.getRHS(solved_eqn), optimal_values)
                case SOME(value) algorithm
                  // saving previous optimal value and checking new one
                  old_optimal_value := UnorderedMap.getSafe(cref, optimal_values, sourceInfo());
                  UnorderedMap.add(cref, Expression.INTEGER(value), optimal_values);

                  // check all constraints of this parameter
                  for cons in UnorderedMap.getSafe(cref, p2c, sourceInfo()) loop
                    if UnorderedSet.contains(constraint, parsed_constraints) and not func(Util.getOptionOrDefault(checkConstraint(cons, optimal_values), 1)) then
                      failed := true;
                      break;
                    end if;
                  end for;

                  // if this parameter would violate any old constraint, use old value and check next parameter
                  if failed then
                    UnorderedMap.add(cref, old_optimal_value, optimal_values);
                  end if;
                then ();
                else ();
              end match;
            else
              // if the equation could not be solved, fail
              failed := true;
            end if;

            // this constraint has been resolved if one parameter could be adjusted to fulfill it
            // without breaking other constraints
            if not failed then
              UnorderedSet.add(constraint, parsed_constraints); break;
            end if;
          end for;
        then ();

        // this constraint cannot be determined
        else algorithm
          for cref in crefs loop
            UnorderedSet.add(cref, failed_parameters);
          end for;
        then ();
      end match;

      // this constraint cannot be fixed
      if failed then
        for cref in crefs loop
          UnorderedSet.add(cref, failed_parameters);
        end for;
      end if;
    end for;
  end fixConstraints;

  function checkConstraint
    input Expression constraint;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
    output Option<Integer> value;
  protected
    Expression replaced;
  algorithm
    replaced := Expression.map(constraint, function Replacements.applySimpleExp(replacements = optimal_values));
    replaced := SimplifyExp.simplify(replaced);
    value := match replaced
      case Expression.INTEGER() then SOME(replaced.value);
      else NONE();
    end match;
  end checkConstraint;

  function updateDimension
    input output Dimension dim;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
  algorithm
    dim := match dim
      case Dimension.RESIZABLE() algorithm
        dim.opt_size := checkConstraint(dim.exp, optimal_values);
      then dim;

      else dim;
    end match;
  end updateDimension;

// *****************************
// DEBUGGING TOSTRING FUNCTIONS
// *****************************

  function optimalValuesToString
    "called using -d=dumpResizable"
    input UnorderedMap<ComponentRef, Expression> optimal_values;
    input output String str = StringUtil.headline_2("[dumpResizable] Evaluated Optimal Resizable Parameter Values:") + "\n";
  protected
    ComponentRef param;
    Expression value;
    Variable var;
    list<String> names = {}, old_vals = {}, new_vals = {};
    String name, old, new;
    Integer names_len;
  algorithm
    for tpl in UnorderedMap.toList(optimal_values) loop
      (param, value)  := tpl;
      var             := Pointer.access(BVariable.getVarPointer(param));
      names           := ComponentRef.toString(param) :: names;
      new_vals        := Expression.toString(value) :: new_vals;
      old_vals        := Binding.toString(var.binding) :: old_vals;
    end for;

    names_len := max(stringLength(n) for n in names);

    while not listEmpty(names) loop
      name  :: names := names;
      new   :: new_vals := new_vals;
      old   :: old_vals := old_vals;
      str := str + "  " + name + " " + StringUtil.repeat(".", names_len + 5 - stringLength(name)) + " OPTIMAL: " + new + " (ORIGINAL: " + old + ")\n";
    end while;
    str := str + "\n";
  end optimalValuesToString;

  function occurencesToString
    "helper function for debugging"
    input UnorderedMap<ComponentRef, Occurences> occs;
    output String str = "";
  algorithm
    for tpl in UnorderedMap.toList(occs) loop
      str := ComponentRef.toString(Util.tuple21(tpl)) + ": {" + UnorderedSet.toString(Util.tuple22(tpl), Expression.toString, ", ") + "}\n";
    end for;
  end occurencesToString;

  function distancesToString
    "helper function for debugging"
    input tuple<ComponentRef, Integer> tpl;
    output String str = ComponentRef.toString(Util.tuple21(tpl)) + ":" + intString(Util.tuple22(tpl));
  end distancesToString;

  function parametersToString
    "helper function for debugging"
    input list<ComponentRef> parameters;
    output String str = List.toString(parameters, ComponentRef.toString);
  end parametersToString;

  function constraintsToString
    "helper function for debugging"
    input list<Expression> constraints;
    output String str = List.toString(constraints, Expression.toString);
  end constraintsToString;

  annotation(__OpenModelica_Interface="backend");
end NBResizable;

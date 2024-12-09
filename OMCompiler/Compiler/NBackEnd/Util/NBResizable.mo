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
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import NBDifferentiate.DifferentiationArguments;
  import Replacements = NBReplacements;
  import Solve = NBSolve;
public
  function main
    input output EquationPointers equations;
  protected
    UnorderedSet<ComponentRef> parameters, min_parameters;
    UnorderedMap<ComponentRef, Expression> optimal_values;
    UnorderedMap<Expression, ParameterList> c2p = UnorderedMap.new<ParameterList>(Expression.hash, Expression.isEqual);
    UnorderedMap<ComponentRef, ConstraintList> p2c;
  algorithm
    // prepare sets and maps
    parameters        := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    min_parameters    := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    optimal_values    := UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual);

    // find the optimal values for iterators
    EquationPointers.map(equations, function findOptimalResizableValue(parameters = parameters, min_parameters = min_parameters, optimal_values = optimal_values, c2p = c2p));

    // initialize the optimal values for paremeters with their min or max attribute (or 0 if none available)
    UnorderedSet.apply(parameters, function setInitialValues(min_parameters = min_parameters, optimal_values = optimal_values));

    // compute the optimal values by checking constraints
    p2c := invertConstraintParameterMap(c2p, parameters);
    computeOptimalValues(optimal_values, c2p, p2c);

    equations := EquationPointers.mapExp(equations,
      function Expression.applyToType(func =
      function Type.applyToDims(func =
      function updateDimension(optimal_values = optimal_values))));

    if Flags.isSet(Flags.DUMP_RESIZABLE) then
      print(optimalValuesToString(optimal_values));
    end if;
  end main;

protected
  type ParameterList = list<ComponentRef>;
  type ConstraintList = list<Expression>;
  type Occurences = UnorderedSet<Expression>;
  constant tuple<ComponentRef, Expression> END_TPL = (ComponentRef.EMPTY(), Expression.END());

  function findOptimalResizableValue
    input output Equation eqn;
    input UnorderedSet<ComponentRef> parameters;
    input UnorderedSet<ComponentRef> min_parameters;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
    input UnorderedMap<Expression, ParameterList> c2p;
  protected
    UnorderedMap<ComponentRef, Expression> resizables;
    UnorderedMap<ComponentRef, Occurences> occs = UnorderedMap.new<Occurences>(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    _ := match eqn
      // only do something on for-equations
      case Equation.FOR_EQUATION() algorithm
        resizables := getResizableIterators(eqn.iter);
        // add all resizable iterators with empty occurence sets to intialize
        for res in UnorderedMap.keyList(resizables) loop
          UnorderedMap.add(res, UnorderedSet.new(Expression.hash, Expression.isEqual), occs);
        end for;
        // fill the occurence sets traversing the body of the equation
        for body in eqn.body loop
          Equation.map(body, function collectOccurences(occs = occs));
        end for;
        findOptimalValue(eqn, occs, resizables, parameters, min_parameters, optimal_values, c2p);
      then ();
      else ();
    end match;
  end findOptimalResizableValue;

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

  function findOptimalValue
    input Equation eqn;
    input UnorderedMap<ComponentRef, Occurences> occs;
    input UnorderedMap<ComponentRef, Expression> resizables;
    input UnorderedSet<ComponentRef> parameters;
    input UnorderedSet<ComponentRef> min_parameters;
    input UnorderedMap<ComponentRef, Expression> optimal_values;
    input UnorderedMap<Expression, ParameterList> c2p;
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
          // distance - step * (stop - step) <= 0
          distance_const := Expression.MULTARY({Expression.INTEGER(distance)}, {Expression.MULTARY({step, target}, {}, Operator.makeMul(Type.INTEGER()))}, Operator.makeAdd(Type.INTEGER()));
          distance_const := SimplifyExp.simplify(distance_const);
          distance_const := SimplifyExp.combineBinaries(distance_const);
          distance_const := SimplifyExp.simplify(distance_const);
          UnorderedMap.add(distance_const, UnorderedSet.toList(local_parameters), c2p);
        then ();
        else ();
      end match;
    end for;
  end findOptimalValue;

  function getDistance
    input ComponentRef cref;
    input Expression exp;
    input DifferentiationArguments args;
    input output Option<Integer> opt_factor;
    input output Integer min_distance;
    input output Integer max_distance;
  protected
    Expression diff, shift;
    Integer factor, distance;
  algorithm
    if Util.isNone(opt_factor) or Util.getOption(opt_factor) <> 0 then
      // get the factor
      diff := Differentiate.differentiateExpression(exp, args);
      diff := SimplifyExp.simplify(diff);
      factor := Expression.integerValueOrDefault(diff, 0);

      if Util.isSome(opt_factor) and factor <> Util.getOption(opt_factor) then
        factor := 0;
      end if;

      if factor <> 0 then
        // if the factor checks out, get shift and update min and max
        shift := Replacements.single(exp, Expression.CREF(Type.INTEGER(), cref), Expression.INTEGER(0));
        shift := SimplifyExp.simplify(shift);
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
    input UnorderedMap<Expression, ParameterList> c2p;
    input UnorderedMap<ComponentRef, ConstraintList> p2c;
  protected
    UnorderedSet<ComponentRef> failed_parameters;
    Expression constraint, replaced, old_optimal_value;
    list<ComponentRef> crefs;
    Equation eqn, solved_eqn;
    Solve.Status status;
    Integer value;
    Boolean failed;
  algorithm
    failed_parameters := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);

    // traversing constraints
    for tpl in UnorderedMap.toList(c2p) loop
      (constraint, crefs) := tpl;
      _ := match checkConstraint(constraint, optimal_values)
        // this constraint is not violated
        case SOME(value) guard(value <= 0) then ();

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
                    if not Util.getOptionOrDefault(checkConstraint(cons, optimal_values), 1) <= 0 then
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
            if not failed then break; end if;
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
  end computeOptimalValues;

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
    output String str = StringUtil.headline_2("[dumpResizable] Evaluated Optimal Resizable Parameter Values:") + "\n";
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

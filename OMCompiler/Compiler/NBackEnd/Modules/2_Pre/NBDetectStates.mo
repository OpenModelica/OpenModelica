/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NBDetectStates
" file:         NBDetectStates.mo
  package:      NBDetectStates
  description:  This file contains all functions for the detection of continuous
                and discrete state variables.
"

public
  import Module = NBModule;

protected
  // Old Frontend Imports
  import Absyn;

  // New Frontend Imports
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import Function = NFFunction;
  import InstNode = NFInstNode.InstNode;
  import SimplifyExp = NFSimplifyExp;
  import Algorithm = NFAlgorithm;
  import Statement = NFStatement;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Operator = NFOperator;
  import Variable = NFVariable;
  import NFBackendExtension.{StateSelect, VariableKind};

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import NBEquation.{Equation, EquationPointers, EqData, EquationAttributes, EquationKind, Iterator, WhenEquationBody, IfEquationBody};
  import FunctionAlias = NBFunctionAlias;
  import BPartition = NBPartition;
  import NBVariable.{StateOrder, VariablePointers, VarData};

  // Util
  import StringUtil;
  import UnorderedSet;

  type ElementOrder = tuple<Option<StateOrder>, UnorderedSet<Integer>, Integer> "order (NONE() if ambiguous), covered flat indices, size";

// =========================================================================
//                      MAIN ROUTINE, PLEASE DO NOT CHANGE
// =========================================================================
public
  function main
    "Wrapper function for any detect states function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
  protected
    Module.detectStatesInterface mainFunc;
    Module.detectContinuousStatesInterface contFunc;
    Module.detectDiscreteStatesInterface discFunc;
  algorithm
    (mainFunc, contFunc, discFunc) := getModule();

    bdae := match bdae
      local
        VarData varData                       "Data containing variable pointers";
        EqData eqData                         "Data containing equation pointers";
      case BackendDAE.MAIN(varData = varData, eqData = eqData)
        algorithm
          (varData, eqData) := mainFunc(varData, eqData, contFunc, discFunc);
          bdae.varData := varData;
          bdae.eqData := eqData;
      then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.detectStatesInterface mainFunc;
    output Module.detectContinuousStatesInterface contFunc;
    output Module.detectDiscreteStatesInterface discFunc;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.DETECT_STATES)
  algorithm
    (mainFunc, contFunc, discFunc) := match flag
      case "default" then (detectStatesDefault, detectContinuousStatesDefault, detectDiscreteStatesDefault);
      /* ... New detect states modules have to be added here */
      else fail();
    end match;
  end getModule;

/* =========================================================================
                              SUB ROUTINES
========================================================================= */
protected
  function detectStatesDefault extends Module.detectStatesInterface;
  protected
    VariablePointers variables      "All variables";
    EquationPointers equations      "System equations";
    EquationPointers disc_eqns      "Discrete equations";
    EquationPointers init_eqns      "Initial equations";
    EquationPointers removed_eqns   "Removed equations";
    VariablePointers unknowns       "Unknowns";
    VariablePointers knowns         "Knowns";
    VariablePointers initials       "Initial unknowns";
    VariablePointers states         "States";
    VariablePointers derivatives    "State derivatives (der(x) -> $DER.x)";
    VariablePointers algebraics     "Algebraic variables";
    VariablePointers discretes      "Discrete variables";
    VariablePointers discrete_states"Discrete state variables";
    VariablePointers clocked_states "Clocked state variables";
    VariablePointers previous       "Previous discrete variables (pre(d) -> $PRE.d)";
    list<Pointer<Equation>> aux_eqns;
    EqData newEqData;
    UnorderedMap<ComponentRef, ElementOrder> element_order;
  algorithm
    // introduce sliced state alias before resolving the der() calls
    (varData, eqData) := FunctionAlias.introduceSlicedStateAlias(varData, eqData, NBPartition.Kind.ODE);

    (varData, eqData) := match (varData, eqData)
      case (BVariable.VAR_DATA_SIM(), BEquation.EQ_DATA_SIM()) algorithm

        // collect continuous states from all equations
        (variables, unknowns, knowns, initials, states, derivatives, algebraics, aux_eqns)
          := continuousFunc(varData.variables, varData.unknowns, varData.knowns, varData.initials, varData.states, varData.derivatives, varData.algebraics, eqData.equations);

        // collect discrete states from discrete equations
        (variables, disc_eqns, knowns, initials, discretes, discrete_states, clocked_states, previous)
          := discreteFunc(varData.variables, eqData.discretes, varData.knowns, varData.initials, varData.discretes, varData.discrete_states, varData.clocked_states, varData.previous, "discrete equations");

        // collect clocked states from clocked equations
        (variables, disc_eqns, knowns, initials, discretes, discrete_states, clocked_states, previous)
          := discreteFunc(variables, eqData.clocked, knowns, initials, discretes, discrete_states, clocked_states, previous, "clocked equations");

        // collect clocked states from continuous equations
        (variables, disc_eqns, knowns, initials, discretes, discrete_states, clocked_states, previous)
          := discreteFunc(variables, eqData.continuous, knowns, initials, discretes, discrete_states, clocked_states, previous, "continuous equations");

        // collect discrete states from initial equations
        (variables, init_eqns, knowns, initials, discretes, discrete_states, clocked_states, previous)
          := discreteFunc(variables, eqData.initials, knowns, initials, discretes, discrete_states, clocked_states, previous, "initial equations");

        // collect pre, edge and change from the removed equations, e.g. when equations that only have reinit
        (variables, removed_eqns, knowns, initials, discretes, discrete_states, clocked_states, previous)
          := discreteFunc(variables, eqData.removed, knowns, initials, discretes, discrete_states, clocked_states, previous, "removed equations");

        // update variable arrays
        varData.variables         := variables;
        varData.unknowns          := unknowns;
        varData.knowns            := knowns;
        varData.initials          := initials;
        varData.derivatives       := derivatives;
        varData.algebraics        := algebraics;
        varData.discretes         := discretes;
        varData.discrete_states   := discrete_states;
        varData.clocked_states    := clocked_states;
        varData.previous          := previous;
        varData.states            := states;

        // update equation arrays
        newEqData := EqData.addTypedList(eqData, aux_eqns, EqData.EqType.CONTINUOUS, false);

        // detect state order
        element_order := UnorderedMap.new<ElementOrder>(ComponentRef.hash, ComponentRef.isEqual);
        EquationPointers.map(eqData.continuous, function stateOrder(state_order = varData.state_order, element_order = element_order, iterators = UnorderedMap.new<Expression>(ComponentRef.hash, ComponentRef.isEqual)));
        addElementOrders(varData.state_order, element_order);
        if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) and not UnorderedMap.isEmpty(varData.state_order) then
          print(StringUtil.headline_4("[stateselection] State Order:"));
          print("\t" + UnorderedMap.toString(varData.state_order, ComponentRef.toString, StateOrder.toString, "\n\t", " --d/dt--> ") + "\n\n");
        end if;
      then (varData, newEqData);
      else (varData, eqData);
    end match;
  end detectStatesDefault;

  function detectContinuousStatesDefault extends Module.detectContinuousStatesInterface;
  protected
    Pointer<list<Pointer<Variable>>> acc_states = Pointer.create({});
    Pointer<list<Pointer<Variable>>> acc_derivatives = Pointer.create({});
    Pointer<list<Pointer<Equation>>> acc_aux_equations = Pointer.create({});
    Pointer<Integer> uniqueIndex = Pointer.create(0);
    Differentiate.DifferentiationArguments diffArgs = Differentiate.DifferentiationArguments.default();
  algorithm
    // collect all 'natural' states der(x)
    EquationPointers.mapExp(equations, function collectStatesAndDerivatives(acc_states = acc_states, acc_derivatives = acc_derivatives, scalarized = variables.scalarized));
    // resolve all general der(exp) expressions
    EquationPointers.mapExp(equations, function resolveGeneralDer(acc_states = acc_states, acc_derivatives = acc_derivatives, acc_aux_equations = acc_aux_equations, uniqueIndex = uniqueIndex, diffArgs = diffArgs));
    // move stuff to their correct arrays
    (variables, unknowns, knowns, initials, states, derivatives, algebraics) := updateStatesAndDerivatives(variables, unknowns, knowns, initials, states, derivatives, algebraics, Pointer.access(acc_states), Pointer.access(acc_derivatives));

    // promote StateSelect.prefer variables if their derivative already exists
    (variables, unknowns, knowns, initials, states, derivatives, algebraics) := promotePreferStates(variables, unknowns, knowns, initials, states, derivatives, algebraics);

    aux_eqns := Pointer.access(acc_aux_equations);
    if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) and not listEmpty(aux_eqns) then
      print(StringUtil.headline_4("[stateselection] (" + intString(listLength(aux_eqns)) + ") Created auxiliary equations:"));
      print(List.toString(aux_eqns, function Equation.pointerToString(str=""), List.Style.NEWLINE_TAB) + "\n\n");
    end if;
  end detectContinuousStatesDefault;

  function detectDiscreteStatesDefault extends Module.detectDiscreteStatesInterface;
  protected
    Pointer<list<Pointer<Variable>>> acc_discrete_states = Pointer.create({});
    Pointer<list<Pointer<Variable>>> acc_clocked_states = Pointer.create({});
    Pointer<list<Pointer<Variable>>> acc_previous = Pointer.create({});
  algorithm
    // collect all states on the lhs of a when
    EquationPointers.map(equations, function collectDiscreteStatesFromWhen(acc_discrete_states = acc_discrete_states, acc_previous = acc_previous, scalarized = variables.scalarized));
    // collect all pre(d)
    EquationPointers.mapExp(equations, function collectPreAndPrevious(acc_previous = acc_previous, acc_clocked_states = acc_clocked_states, scalarized = variables.scalarized));
    // move stuff to their correct arrays
    (variables, knowns, initials, discretes, discrete_states, clocked_states, previous) := updateDiscreteStatesAndPrevious(variables, knowns, initials, discretes, discrete_states, clocked_states, previous, Pointer.access(acc_discrete_states), Pointer.access(acc_clocked_states), Pointer.access(acc_previous), context);
  end detectDiscreteStatesDefault;

  function collectStatesAndDerivatives
    "Collects all states and creates a derivative variable for each."
    input output Expression exp;
    input Pointer<list<Pointer<Variable>>> acc_states;
    input Pointer<list<Pointer<Variable>>> acc_derivatives;
    input Boolean scalarized;
  algorithm
    exp := match exp
      local
        Expression res;
        ComponentRef state_cref, der_cref;
        Pointer<Variable> state_var, der_var;

      // parse all der(x) calls where x is not a state derivative. those need to be handled by resolveGeneralDer()
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "der")),
        arguments = {Expression.CREF(cref = state_cref)})) guard(not BVariable.checkCref(state_cref, BVariable.isStateDerivative, sourceInfo()))
        algorithm
          state_var := BVariable.getVarPointer(state_cref, sourceInfo());

          if not BVariable.isContinuous(state_var, false) then
            // if the variable is not continuous, its derivative is zero
            res := Expression.makeZero(ComponentRef.getSubscriptedType(state_cref));
          else
            if BVariable.hasDerVar(state_var) then
              // this derivative was already created -> the variable should already have a pointer to its derivative
              der_cref := BVariable.getPartnerCref(state_cref, BVariable.getVarDer, scalarized);
            else
              // create new derivative variable
              (der_cref, der_var) := BVariable.makeDerVar(state_cref, scalarized);
              state_var := BVariable.getVarPointer(state_cref, sourceInfo());
              BVariable.setStateDerivativeVar(state_var, der_var);
              Pointer.update(acc_states, state_var :: Pointer.access(acc_states));
              Pointer.update(acc_derivatives, der_var :: Pointer.access(acc_derivatives));
            end if;
            res := Expression.fromCref(der_cref);
          end if;
      then res;

      else exp;
    end match;
  end collectStatesAndDerivatives;

  function resolveGeneralDer
    "Collects all states and creates a derivative variable for each."
    input output Expression exp;
    input Pointer<list<Pointer<Variable>>> acc_states;
    input Pointer<list<Pointer<Variable>>> acc_derivatives;
    input Pointer<list<Pointer<Equation>>> acc_aux_equations;
    input Pointer<Integer> uniqueIndex;
    input Differentiate.DifferentiationArguments diffArgs;
  algorithm
    exp := match exp
      local
        ComponentRef state_cref, der_cref;
        Pointer<Variable> state_var, der_var;
        Expression arg, returnExp;
        Pointer<Equation> aux_equation;
        Differentiate.DifferentiationArguments oDiffArgs;

      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "der")), arguments = {arg}))
        algorithm
          if Expression.fold(arg, checkAlgebraic, 0) > 1 then
            // more than one algebraic variable > create auxiliary state
            (state_var, state_cref, der_var, der_cref) := BVariable.makeAuxStateVar(Pointer.access(uniqueIndex), SOME(arg));
            aux_equation := Equation.makeAssignment(Expression.fromCref(state_cref), arg, uniqueIndex, NBVariable.AUXILIARY_STR, Iterator.EMPTY(), EquationAttributes.default(EquationKind.CONTINUOUS, false));
            returnExp := Expression.fromCref(der_cref);

            Pointer.update(acc_states, state_var :: Pointer.access(acc_states));
            Pointer.update(acc_derivatives, der_var :: Pointer.access(acc_derivatives));
            Pointer.update(acc_aux_equations, aux_equation :: Pointer.access(acc_aux_equations));
          else
            // one or less algebraic variables > differentiate the expression
            (returnExp, oDiffArgs) := Differentiate.differentiateExpression(arg, diffArgs);
            returnExp := SimplifyExp.simplifyDump(returnExp, true, getInstanceName());
            if List.hasOneElement(oDiffArgs.new_vars) then
              der_var := listHead(oDiffArgs.new_vars);
              Pointer.update(acc_derivatives, der_var :: Pointer.access(acc_derivatives));
              Pointer.update(acc_states, Util.getOption(BVariable.getVarState(der_var)) :: Pointer.access(acc_states));
            elseif List.hasSeveralElements(oDiffArgs.new_vars) then
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the number of algebraic variables were miscounted! " +
                "Expected: 0 or 1, got: " + intString(listLength(oDiffArgs.new_vars))});
              fail();
            end if;
          end if;
      then returnExp;

      else exp;
    end match;
  end resolveGeneralDer;

  function checkAlgebraic
    "Needs to be mapped with Expression.fold()
    counts the number of algebraic variables in an expression.
    Count state derivatives double to ensure that they get an auxiliary."
    input Expression exp;
    input output Integer i;
  algorithm
    i := match exp
      case Expression.CREF() guard(BVariable.isStateDerivative(BVariable.getVarPointer(exp.cref, sourceInfo()))) then i + 2;
      case Expression.CREF() guard(BVariable.isAlgebraic(BVariable.getVarPointer(exp.cref, sourceInfo()))) then i + 1;
      else i;
    end match;
  end checkAlgebraic;

  function updateStatesAndDerivatives
    "Updates the variable pointer arrays with the new information about states and derivatives."
    input output VariablePointers variables      "All variables";
    input output VariablePointers unknowns       "Unknowns";
    input output VariablePointers knowns         "Knowns";
    input output VariablePointers initials       "Initial unknowns";
    input output VariablePointers states         "States";
    input output VariablePointers derivatives    "State derivatives (der(x) -> $DER.x)";
    input output VariablePointers algebraics     "Algebraic variables";
    input list<Pointer<Variable>> acc_states;
    input list<Pointer<Variable>> acc_derivatives;
  algorithm
    // Add the new derivatives to variables, unknowns and derivative pointer arrays
    variables := VariablePointers.addList(acc_derivatives, variables);
    unknowns := VariablePointers.addList(acc_derivatives, unknowns);
    initials := VariablePointers.addList(acc_derivatives, initials);
    derivatives := VariablePointers.addList(acc_derivatives, derivatives);

    // add states to variables and state pointer array
    variables := VariablePointers.addList(acc_states, variables);
    states := VariablePointers.addList(acc_states, states);

    // remove states from unknowns and algebraics
    unknowns := VariablePointers.removeList(acc_states, unknowns);
    algebraics := VariablePointers.removeList(acc_states, algebraics);

    if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) then
      print(StringUtil.headline_4("[stateselection] (" + intString(listLength(acc_states)) + ") Natural states before index reduction:"));
      if listEmpty(acc_states) then
        print("\t<no states>\n\n");
      else
        print(List.toString(acc_states, BVariable.pointerToString, List.Style.NEWLINE_TAB) + "\n\n");
      end if;
    end if;
  end updateStatesAndDerivatives;

  function collectPreAndPrevious
    "Collects all pre and previous variables. Only to be used on discrete equations!"
    input output Expression exp;
    input Pointer<list<Pointer<Variable>>> acc_previous;
    input Pointer<list<Pointer<Variable>>> acc_clocked_states;
    input Boolean scalarized;
  algorithm
    exp := match exp
      local
        Function.Function fn;
        Boolean b;
        list<Expression> args;
        Expression new_exp, old_exp;

      // the call has an input that is only a boolean. for pre() return the boolean, for edge() and change() always false
      case Expression.CALL(call = Call.TYPED_CALL(fn = fn, arguments = {Expression.BOOLEAN(b)}))
      algorithm
        new_exp := match fn
          case Function.FUNCTION(path = Absyn.IDENT(name = "previous")) then Expression.BOOLEAN(b);
          case Function.FUNCTION(path = Absyn.IDENT(name = "pre"))      then Expression.BOOLEAN(b);
          case Function.FUNCTION(path = Absyn.IDENT(name = "edge"))     then Expression.BOOLEAN(false);
          case Function.FUNCTION(path = Absyn.IDENT(name = "change"))   then Expression.BOOLEAN(false);
          else exp;
        end match;
      then new_exp;

      // the expression is previous(d) -> $PRE.d or previous(not d) -> not $PRE.d
      // also store the clocked state
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "previous")), arguments = args))
      algorithm
        (new_exp, old_exp) := preFromArgs(args, acc_previous, scalarized, "previous");
        () := match old_exp
          case Expression.CREF() algorithm
            Pointer.update(acc_clocked_states, BVariable.getVarPointer(old_exp.cref, sourceInfo()) :: Pointer.access(acc_clocked_states));
          then ();

          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because previous() can only contain component references, but contained: "
              + Expression.toString(old_exp)});
          then fail();
        end match;
      then new_exp;

      // the expression is pre(d) -> $PRE.d or pre(not d) -> not $PRE.d
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "pre")), arguments = args))
      algorithm
        (new_exp, _) := preFromArgs(args, acc_previous, scalarized, "pre");
      then new_exp;

      // the expression is edge(d) -> d and not $PRE.d or edge(not d) not d and $PRE.d
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "edge")), arguments = args))
      algorithm
        (new_exp, old_exp) := preFromArgs(args, acc_previous, scalarized, "edge");
      then Expression.LBINARY(old_exp, Operator.makeAnd(Expression.typeOf(old_exp)), Expression.logicNegate(new_exp));

      // the expression is change(d) -> d <> $PRE.d or change(not d) not d <> not $PRE.d
      // (not necessary to have the "not" but works and is most consistent with other cases)
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "change")), arguments = args))
      algorithm
        (new_exp, old_exp) := preFromArgs(args, acc_previous, scalarized, "change");
      then Expression.RELATION(old_exp, Operator.makeNotEqual(Expression.typeOf(old_exp)), new_exp, -1);

      else exp;
    end match;
  end collectPreAndPrevious;

  function preFromArgs
    "takes a list of arguments (expected to be only one cref) and creates the pre variable from it.
    used for pre(), edge(), change()"
    input list<Expression> args;
    input Pointer<list<Pointer<Variable>>> acc_previous;
    input Boolean scalarized;
    input String context;
    output Expression new_exp;
    output Expression old_exp;
  protected
    ComponentRef state_cref, pre_cref;
    Pointer<Variable> state_var;
    Boolean negated;
  algorithm
    (state_var, old_exp, negated) := match args
      case {old_exp as Expression.CREF(cref = state_cref)}                           then (BVariable.getVarPointer(state_cref, sourceInfo()), old_exp, false);
      case {old_exp as Expression.LUNARY(exp = Expression.CREF(cref = state_cref))}  then (BVariable.getVarPointer(state_cref, sourceInfo()), old_exp, true);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unexpected expression " + context + "("
          + List.toString(args, Expression.toString, List.Style.FLAT) + ")."});
      then fail();
    end match;
    pre_cref := getPreVar(state_cref, state_var, acc_previous, scalarized);

    new_exp := Expression.fromCref(pre_cref);
    if negated then
      new_exp := Expression.logicNegate(new_exp);
    end if;
  end preFromArgs;

  function updateDiscreteStatesAndPrevious
    "Updates the variable pointer arrays with the new information about states and derivatives."
    input output VariablePointers variables       "All variables";
    input output VariablePointers knowns          "Knowns";
    input output VariablePointers initials        "initial unknowns";
    input output VariablePointers discretes       "Discrete variables";
    input output VariablePointers discrete_states "Discrete state variables";
    input output VariablePointers clocked_states  "Clocked state variables";
    input output VariablePointers previous        "Previous (left limit) variables";
    input list<Pointer<Variable>> acc_discrete_states;
    input list<Pointer<Variable>> acc_clocked_states;
    input list<Pointer<Variable>> acc_previous;
    input String context                          "only for debugging";
  algorithm
    // Add the new derivatives to variables, unknowns and derivative pointer arrays
    variables       := VariablePointers.addList(acc_previous, variables);
    knowns          := VariablePointers.addList(acc_previous, knowns);
    initials        := VariablePointers.addList(acc_previous, initials);
    previous        := VariablePointers.addList(acc_previous, previous);
    discrete_states := VariablePointers.addList(acc_discrete_states, discrete_states);
    clocked_states  := VariablePointers.addList(acc_clocked_states, clocked_states);
    // remove discrete states from discretes and remove clocked states from both discretes and discrete states
    discretes       := VariablePointers.removeList(acc_discrete_states, discretes);
    discretes       := VariablePointers.removeList(acc_clocked_states, discretes);
    discrete_states := VariablePointers.removeList(acc_clocked_states, discrete_states);

    if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) then
      if not listEmpty(acc_discrete_states) then
        print(StringUtil.headline_4("[stateselection] Natural discrete states from " + context + ":"));
        print(List.toString(acc_discrete_states, BVariable.pointerToString, List.Style.NEWLINE_TAB) + "\n\n");
      end if;
      if not listEmpty(acc_clocked_states) then
        print(StringUtil.headline_4("[stateselection] Natural clocked states from " + context + ":"));
        print(List.toString(acc_clocked_states, BVariable.pointerToString, List.Style.NEWLINE_TAB) + "\n\n");
      end if;
    end if;

    if Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO) then
      if not listEmpty(acc_previous) then
        print(StringUtil.headline_4("[discreteinfo] pre() and previous() variables from " + context + ":"));
        print(List.toString(acc_previous, BVariable.pointerToString, List.Style.NEWLINE_TAB) + "\n\n");
      end if;
    end if;

  end updateDiscreteStatesAndPrevious;

  function collectDiscreteStatesFromWhen
    "All variables on the LHS in a when equation are considered discrete."
    input output Equation eqn "outputs equation just to fit the map() interface. does not change.";
    input Pointer<list<Pointer<Variable>>> acc_discrete_states;
    input Pointer<list<Pointer<Variable>>> acc_previous;
    input Boolean scalarized;
  algorithm
    () := match eqn
      case Equation.WHEN_EQUATION() algorithm
        collectDiscreteStatesFromWhenBody(eqn.body, acc_discrete_states, acc_previous, scalarized);
      then ();
      case Equation.FOR_EQUATION() algorithm
        for b_eqn in eqn.body loop
          collectDiscreteStatesFromWhen(b_eqn, acc_discrete_states, acc_previous, scalarized);
        end for;
      then ();
      case Equation.IF_EQUATION() algorithm
        collectDiscreteStatesFromWhenInIf(eqn.body, acc_discrete_states, acc_previous, scalarized);
      then ();
      case Equation.ALGORITHM() algorithm
        collectDiscreteStatesFromWhenStatements(eqn.alg.statements, acc_discrete_states, acc_previous, scalarized);
      then ();
      else ();
    end match;
  end collectDiscreteStatesFromWhen;

  function collectDiscreteStatesFromWhenStatements
    "All variables assigned in a when-statement of an algorithm are considered discrete."
    input list<Statement> statements;
    input Pointer<list<Pointer<Variable>>> acc_discrete_states;
    input Pointer<list<Pointer<Variable>>> acc_previous;
    input Boolean scalarized;
  protected
    UnorderedSet<ComponentRef> assigned = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    Pointer<Variable> state_var;
  algorithm
    collectWhenStatementOutputs(statements, assigned);
    for cref in UnorderedSet.toList(assigned) loop
      // the function getPreVar() does all necessary collecting of information
      // but we don't need the actual pre cref it returns
      state_var := BVariable.getVarPointer(cref, sourceInfo());
      BVariable.makeDiscreteStateVar(state_var);
      getPreVar(cref, state_var, acc_previous, scalarized);
      Pointer.update(acc_discrete_states, state_var :: Pointer.access(acc_discrete_states));
    end for;
  end collectDiscreteStatesFromWhenStatements;

  function collectWhenStatementOutputs
    "Collects the outputs of all when-statements, also of the ones inside of for-statements
    (the frontend creates these for algorithms of array components)."
    input list<Statement> statements;
    input UnorderedSet<ComponentRef> assigned;
  protected
    list<ComponentRef> outputs;
  algorithm
    for stmt in statements loop
      () := match stmt
        case Statement.WHEN() algorithm
          for branch in stmt.branches loop
            (_, outputs) := Algorithm.getInputsOutputs(Util.tuple22(branch));
            // variables only this algorithm uses keep their value without being discrete states
            for cref in outputs loop
              if not BVariable.isAlgorithmLocalCref(cref) then
                UnorderedSet.add(cref, assigned);
              end if;
            end for;
          end for;
        then ();
        case Statement.FOR() algorithm
          collectWhenStatementOutputs(stmt.body, assigned);
        then ();
        else ();
      end match;
    end for;
  end collectWhenStatementOutputs;

  function collectDiscreteStatesFromWhenBody
    "All variables on the LHS in a when equation are considered discrete."
    input WhenEquationBody body;
    input Pointer<list<Pointer<Variable>>> acc_discrete_states;
    input Pointer<list<Pointer<Variable>>> acc_previous;
    input Boolean scalarized;
  protected
    Pointer<Variable> state_var;
  algorithm
    for state_cref in WhenEquationBody.getAllAssigned(body) loop
      // the function getPreVar() does all necessary collecting of information
      // but we don't need the actual pre cref it returns
      state_var := BVariable.getVarPointer(state_cref, sourceInfo());
      BVariable.makeDiscreteStateVar(state_var);
      getPreVar(state_cref, state_var, acc_previous, scalarized);
      Pointer.update(acc_discrete_states, state_var :: Pointer.access(acc_discrete_states));
    end for;
  end collectDiscreteStatesFromWhenBody;

  function collectDiscreteStatesFromWhenInIf
    input IfEquationBody body;
    input Pointer<list<Pointer<Variable>>> acc_discrete_states;
    input Pointer<list<Pointer<Variable>>> acc_previous;
    input Boolean scalarized;
  algorithm
    for eqn in body.then_eqns loop
      collectDiscreteStatesFromWhen(Pointer.access(eqn), acc_discrete_states, acc_previous, scalarized);
    end for;
    if isSome(body.else_if) then
      collectDiscreteStatesFromWhenInIf(Util.getOption(body.else_if),  acc_discrete_states, acc_previous, scalarized);
    end if;
  end collectDiscreteStatesFromWhenInIf;

  function getPreVar
    input ComponentRef var_cref;
    input Pointer<Variable> var_ptr;
    input Pointer<list<Pointer<Variable>>> acc_previous;
    input Boolean scalarized;
    output ComponentRef pre_cref;
  protected
    Option<Pointer<Variable>> pre = BVariable.getVarPre(var_ptr);
    Pointer<Variable> pre_var;
  algorithm
    if isSome(pre) then
      SOME(pre_var) := pre;
      pre_cref := BVariable.getVarName(pre_var);
      pre_cref := ComponentRef.copySubscripts(var_cref, pre_cref);
    else
      if not scalarized then
        // prevent the created pre variable from having the subscripts, but add it to the pre_cref
        (pre_cref, pre_var) := BVariable.makePreVar(ComponentRef.stripSubscriptsAll(var_cref));
        pre_cref := ComponentRef.copySubscripts(var_cref, pre_cref);
      else
        (pre_cref, pre_var) := BVariable.makePreVar(var_cref);
      end if;
      Pointer.update(acc_previous, pre_var :: Pointer.access(acc_previous));
    end if;
  end getPreVar;

  public function findDiscreteStatesFromWhenBody
    "All variables on the LHS in a when equation are considered discrete, add these to acc lists"
    input WhenEquationBody body;
    input Pointer<list<Pointer<Variable>>> acc_discrete_states;
    input Pointer<list<Pointer<Variable>>> acc_previous;
  protected
    Pointer<Variable> state_var, pre_var;
  algorithm
    for state_cref in WhenEquationBody.getAllAssigned(body) loop
      state_var := BVariable.getVarPointer(state_cref, sourceInfo());
      () := match BVariable.getVarPre(state_var)
        case SOME(pre_var) algorithm
          Pointer.update(acc_previous, pre_var :: Pointer.access(acc_previous));
        then ();
        else ();
      end match;
      Pointer.update(acc_discrete_states, state_var :: Pointer.access(acc_discrete_states));
    end for;
  end findDiscreteStatesFromWhenBody;

  function stateOrder
    "Collects state orders x = k*der(y) + c that hold for every element of y."
    input output Equation eqn;
    input UnorderedMap<ComponentRef, StateOrder> state_order;
    input UnorderedMap<ComponentRef, ElementOrder> element_order;
    input UnorderedMap<ComponentRef, Expression> iterators "ranges of the surrounding for-loops";
  protected
    list<ComponentRef> names;
    list<Expression> ranges;
    list<Option<Iterator>> maps;
    UnorderedMap<ComponentRef, Expression> body_iterators;
  algorithm
    () := match eqn
      case Equation.SCALAR_EQUATION() algorithm
        updateStateOrder(stateRelation(eqn.lhs, eqn.rhs), iterators, state_order, element_order);
      then ();

      case Equation.ARRAY_EQUATION() algorithm
        updateStateOrder(stateRelation(eqn.lhs, eqn.rhs), iterators, state_order, element_order);
      then ();

      case Equation.FOR_EQUATION() algorithm
        (names, ranges, maps) := Iterator.getFrames(eqn.iter);
        if List.all(maps, isNone) then
          body_iterators := UnorderedMap.copy(iterators);
          for frame in List.zip(names, ranges) loop
            UnorderedMap.add(Util.tuple21(frame), Util.tuple22(frame), body_iterators);
          end for;
          for b in eqn.body loop
            stateOrder(b, state_order, element_order, body_iterators);
          end for;
        end if;
      then ();

      else ();
    end match;
  end stateOrder;

  function addElementOrders
    "Adds the state orders that are given element by element and cover the whole state."
    input UnorderedMap<ComponentRef, StateOrder> state_order;
    input UnorderedMap<ComponentRef, ElementOrder> element_order;
  protected
    ComponentRef state;
    StateOrder order;
    UnorderedSet<Integer> covered;
    Integer total;
  algorithm
    for entry in UnorderedMap.toList(element_order) loop
      () := match entry
        case (state, (SOME(order), covered, total)) algorithm
          if UnorderedSet.size(covered) == total then
            addStateOrder(state, order, state_order);
          end if;
        then ();
        else ();
      end match;
    end for;
  end addElementOrders;

  function promotePreferStates
    "Promotes StateSelect.prefer variables to states if the model has ANY der() calls.
    Only relevant for variables that have StateSelect.prefer but do NOT occur inside der()
    calls — those that do occur are already promoted by natural state collection and removed
    from algebraics before this function runs."
    input output VariablePointers variables;
    input output VariablePointers unknowns;
    input output VariablePointers knowns;
    input output VariablePointers initials;
    input output VariablePointers states;
    input output VariablePointers derivatives;
    input output VariablePointers algebraics;
  protected
    list<Pointer<Variable>> acc_prefer_states = {};
    list<Pointer<Variable>> acc_prefer_ders = {};
    ComponentRef der_cref;
    Pointer<Variable> der_var;
  algorithm
    // only promote if the model is dynamic (has at least one der() call)
    if VariablePointers.size(states) > 0 then
      for alg_ptr in VariablePointers.toList(algebraics) loop
        if BVariable.isStateSelect(alg_ptr, StateSelect.PREFER) then
          // this variable has StateSelect.prefer but is not inside any der() call;
          // create its derivative and promote it to a state
          (der_cref, der_var) := BVariable.makeDerVar(BVariable.getVarName(alg_ptr), variables.scalarized);
          BVariable.setVarKind(alg_ptr, VariableKind.STATE(1, SOME(PointerWeak.downgrade(der_var)), false));
          acc_prefer_states := alg_ptr :: acc_prefer_states;
          acc_prefer_ders := der_var :: acc_prefer_ders;
        end if;
      end for;

      if not listEmpty(acc_prefer_states) then
        // update state variable arrays
        states     := VariablePointers.addList(acc_prefer_states, states);
        unknowns   := VariablePointers.removeList(acc_prefer_states, unknowns);
        algebraics := VariablePointers.removeList(acc_prefer_states, algebraics);

        // update derivative variable arrays (newly created — not yet in any array)
        variables    := VariablePointers.addList(acc_prefer_ders, variables);
        unknowns     := VariablePointers.addList(acc_prefer_ders, unknowns);
        initials     := VariablePointers.addList(acc_prefer_ders, initials);
        derivatives  := VariablePointers.addList(acc_prefer_ders, derivatives);

        if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) then
          print(StringUtil.headline_4("[stateselection] (" + intString(listLength(acc_prefer_states)) + ") Forced states by StateSelect.PREFER:"));
          print(List.toString(acc_prefer_states, BVariable.pointerToString, List.Style.NEWLINE_TAB) + "\n\n");
        end if;
      end if;
    end if;
  end promotePreferStates;

  function stateRelation
    "Returns ($DER.y, x, (k, c)) if lhs = rhs is x = k*der(y) + c with constant or
    parameter coefficients. The crefs keep their subscripts. (k, c) is NONE() for x = der(y)."
    input Expression lhs;
    input Expression rhs;
    output Option<tuple<ComponentRef, ComponentRef, Option<tuple<Expression, Expression>>>> relation = NONE();
  protected
    list<ComponentRef> crefs;
    ComponentRef der_cref, alias;
    Expression residual, a, b, d;
    Type ty;
    Operator mul;
    Boolean found;
  algorithm
    crefs := Expression.fold(rhs, collectUnknown, Expression.fold(lhs, collectUnknown, {}));
    (der_cref, alias, found) := match crefs
      case {der_cref, alias} guard(isDerivativeCref(der_cref) and not isDerivativeCref(alias) and BVariable.isVarCref(alias)) then (der_cref, alias, true);
      case {alias, der_cref} guard(isDerivativeCref(der_cref) and not isDerivativeCref(alias) and BVariable.isVarCref(alias)) then (der_cref, alias, true);
      else (ComponentRef.EMPTY(), ComponentRef.EMPTY(), false);
    end match;
    if not found then
      return;
    end if;

    if Expression.isCref(lhs) and Expression.isCref(rhs) then
      relation := SOME((der_cref, alias, NONE()));
      return;
    end if;

    // a*der(y) + b*x + d = 0
    ty := Expression.typeOf(lhs);
    residual := Expression.MULTARY({lhs}, {rhs}, Operator.makeAdd(ty));
    try
      a := SimplifyExp.simplify(Differentiate.differentiateExpression(residual, Differentiate.DifferentiationArguments.simpleCref(der_cref)));
      b := SimplifyExp.simplify(Differentiate.differentiateExpression(residual, Differentiate.DifferentiationArguments.simpleCref(alias)));
    else
      return;
    end try;
    d := SimplifyExp.simplify(Expression.map(residual, function replaceByZero(crefs = crefs)));
    if Type.isArray(Expression.typeOf(d)) and Expression.isZero(d) then
      d := Expression.makeZero(Type.arrayElementType(ty));
    end if;
    if not (isCoefficient(a) and isCoefficient(b) and isCoefficient(d)) or Expression.isZero(a) or Expression.isZero(b) then
      return;
    end if;

    // k = -a/b, c = -d/b
    ty := Expression.typeOf(a);
    mul := Operator.makeMul(ty);
    a := SimplifyExp.simplify(Expression.negate(Expression.MULTARY({a}, {b}, mul)));
    d := SimplifyExp.simplify(Expression.negate(Expression.MULTARY({d}, {b}, mul)));
    relation := SOME((der_cref, alias, if Expression.isOne(a) and Expression.isZero(d) then NONE() else SOME((a, d))));
  end stateRelation;

  function collectUnknown
    "Collects the crefs that are not parameters, constants or iterators."
    input Expression exp;
    input output list<ComponentRef> crefs;
  algorithm
    crefs := match exp
      case Expression.CREF() guard(not ComponentRef.isIterator(exp.cref) and not (BVariable.isVarCref(exp.cref) and BVariable.checkCref(exp.cref, BVariable.isParamOrConst, sourceInfo())))
      then List.unionEltOnTrue(exp.cref, crefs, ComponentRef.isEqual);
      else crefs;
    end match;
  end collectUnknown;

  function replaceByZero
    input output Expression exp;
    input list<ComponentRef> crefs;
  algorithm
    exp := match exp
      case Expression.CREF() guard(List.isMemberOnTrue(exp.cref, crefs, ComponentRef.isEqual)) then Expression.makeZero(exp.ty);
      else exp;
    end match;
  end replaceByZero;

  function isCoefficient
    "true for scalar, pure expressions of constants, parameters and literals."
    input Expression exp;
    output Boolean b = not Type.isArray(Expression.typeOf(exp)) and Expression.fold(exp, isCoefficientNode, true);
  end isCoefficient;

  function isCoefficientNode
    input Expression exp;
    input output Boolean b;
  algorithm
    b := b and (match exp
      case Expression.CREF() then BVariable.isVarCref(exp.cref) and BVariable.checkCref(exp.cref, BVariable.isParamOrConst, sourceInfo());
      case Expression.CALL() then Expression.isPure(exp);
      else true;
    end match);
  end isCoefficientNode;

  function isDerivativeCref
    input ComponentRef cref;
    output Boolean b = BVariable.isVarCref(cref) and BVariable.checkCref(cref, BVariable.isStateDerivative, sourceInfo());
  end isDerivativeCref;

  function updateStateOrder
    "Adds x = k*der(y) + c if the subscripts of x and der(y) are equal and cover all elements.
    Relations that cover only some elements are collected in element_order."
    input Option<tuple<ComponentRef, ComponentRef, Option<tuple<Expression, Expression>>>> relation;
    input UnorderedMap<ComponentRef, Expression> iterators;
    input UnorderedMap<ComponentRef, StateOrder> state_order;
    input UnorderedMap<ComponentRef, ElementOrder> element_order;
  protected
    Pointer<Variable> alias_var, der_var;
    ComponentRef alias, der_cref, state_cref;
    Option<tuple<Expression, Expression>> coefficients;
    StateOrder order;
    list<Subscript> subs;
    list<Dimension> dims;
    list<list<Integer>> values;
  algorithm
    if isNone(relation) then
      return;
    end if;
    SOME((der_cref, alias, coefficients)) := relation;

    alias_var := BVariable.getVarPointer(alias, sourceInfo());
    der_var := BVariable.getVarPointer(der_cref, sourceInfo());
    if not BVariable.isContinuous(alias_var, false) or BVariable.isTime(alias_var) then
      return;
    end if;

    subs := ComponentRef.subscriptsAllWithWholeFlat(der_cref);
    dims := Type.arrayDims(Variable.typeOf(Pointer.access(der_var)));
    if not (List.isEqualOnTrue(subs, ComponentRef.subscriptsAllWithWholeFlat(alias), Subscript.isEqual)
      and List.isEqualOnTrue(dims, Type.arrayDims(Variable.typeOf(Pointer.access(alias_var))), Dimension.isEqualKnown)
      and listLength(subs) == listLength(dims) and distinctIterators(subs, iterators)) then
      return;
    end if;

    state_cref := BVariable.getVarName(Util.getOption(BVariable.getVarState(der_var)));
    order := StateOrder.STATE_ORDER(ComponentRef.stripSubscriptsAll(alias), coefficients);
    if ComponentRef.isEqual(state_cref, order.partner) then
      return;
    end if;
    // iterators as slices of their ranges
    subs := list(match sub
        local
          ComponentRef iter;
        case Subscript.INDEX(index = Expression.CREF(cref = iter)) guard(UnorderedMap.contains(iter, iterators))
        then Subscript.SLICE(UnorderedMap.getOrFail(iter, iterators));
        else sub;
      end match for sub in subs);

    if List.all(List.zip(subs, dims), coversDim) then
      addStateOrder(state_cref, order, state_order);
    elseif List.all(subs, Subscript.isLiteral) and List.all(dims, isLiteralDim) then
      values := list(Subscript.toIndexList(sub, Dimension.size(dim)) threaded for sub in subs, dim in dims);
      () := match UnorderedMap.get(state_cref, element_order)
        local
          StateOrder old_order;
        case NONE() algorithm
          UnorderedMap.add(state_cref, (SOME(order), UnorderedSet.new(Util.id, intEq), product(Dimension.size(d) for d in dims)), element_order);
        then ();
        case SOME((SOME(old_order), _, _)) guard(StateOrder.isEqual(order, old_order)) then ();
        else algorithm
          UnorderedMap.add(state_cref, (NONE(), UnorderedSet.new(Util.id, intEq), 0), element_order);
        then ();
      end match;
      addElements(values, dims, Util.tuple32(UnorderedMap.getOrFail(state_cref, element_order)));
    end if;
  end updateStateOrder;

  function addStateOrder
    "Adds the order if the state has none yet. x = der(y) replaces x = k*der(y) + c."
    input ComponentRef state;
    input StateOrder order;
    input UnorderedMap<ComponentRef, StateOrder> state_order;
  algorithm
    () := match (UnorderedMap.get(state, state_order), order)
      case (NONE(), _) algorithm
        UnorderedMap.add(state, order, state_order);
      then ();
      case (SOME(StateOrder.STATE_ORDER(coefficients = SOME(_))), StateOrder.STATE_ORDER(coefficients = NONE())) algorithm
        UnorderedMap.add(state, order, state_order);
      then ();
      else ();
    end match;
  end addStateOrder;

  function coversDim
    input tuple<Subscript, Dimension> sub_dim;
    output Boolean b;
  protected
    Expression slice;
    Dimension dim;
  algorithm
    b := match sub_dim
      case (Subscript.WHOLE(), _) then true;
      case (Subscript.SLICE(slice = slice), dim) then Expression.isFullRange(slice, dim);
      else false;
    end match;
  end coversDim;

  function isLiteralDim
    input Dimension dim;
    output Boolean b = Dimension.isKnown(dim) and not Dimension.isResizable(dim) and Type.isInteger(Dimension.subscriptType(dim));
  end isLiteralDim;

  function distinctIterators
    "false if an iterator is used for more than one dimension, e.g. x[i, i]."
    input list<Subscript> subs;
    input UnorderedMap<ComponentRef, Expression> iterators;
    output Boolean b = true;
  protected
    UnorderedSet<ComponentRef> used = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    for sub in subs loop
      () := match sub
        local
          ComponentRef iter;
        case Subscript.INDEX(index = Expression.CREF(cref = iter)) guard(UnorderedMap.contains(iter, iterators)) algorithm
          if UnorderedSet.contains(iter, used) then
            b := false;
            return;
          end if;
          UnorderedSet.add(iter, used);
        then ();
        else ();
      end match;
    end for;
  end distinctIterators;

  function addElements
    "Adds the flat indices of all combinations of the subscript values."
    input list<list<Integer>> values;
    input list<Dimension> dims;
    input UnorderedSet<Integer> covered;
    input Integer offset = 0;
  protected
    Integer size;
  algorithm
    if listEmpty(values) then
      UnorderedSet.add(offset, covered);
    else
      size := Dimension.size(listHead(dims));
      for v in listHead(values) loop
        if v >= 1 and v <= size then
          addElements(listRest(values), listRest(dims), covered, offset * size + v - 1);
        end if;
      end for;
    end if;
  end addElements;

  annotation(__OpenModelica_Interface="nbackend");
end NBDetectStates;



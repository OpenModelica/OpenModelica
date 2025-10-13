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
  import Expression = NFExpression;
  import Function = NFFunction;
  import InstNode = NFInstNode.InstNode;
  import SimplifyExp = NFSimplifyExp;
  import Type = NFType;
  import Operator = NFOperator;
  import Variable = NFVariable;
  import NFBackendExtension.VariableKind;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Differentiate = NBDifferentiate;
  import NBEquation.{Equation, EquationPointers, EqData, EquationAttributes, EquationKind, Iterator, WhenEquationBody, WhenStatement, IfEquationBody};
  import NBVariable.{VariablePointers, VarData};

  // Util
  import StringUtil;

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
  algorithm
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
        EquationPointers.map(EqData.getEquations(newEqData), function stateOrder(state_order = varData.state_order));
        if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) and not UnorderedMap.isEmpty(varData.state_order) then
          print(StringUtil.headline_4("[stateselection] State Order:"));
          print("\t" + UnorderedMap.toString(varData.state_order, ComponentRef.toString, ComponentRef.toString, "\n\t", " --d/dt--> ") + "\n\n");
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

    aux_eqns := Pointer.access(acc_aux_equations);
    if Flags.isSet(Flags.DUMP_STATESELECTION_INFO) and not listEmpty(aux_eqns) then
      print(StringUtil.headline_4("[stateselection] (" + intString(listLength(aux_eqns)) + ") Created auxiliary equations:"));
      print(List.toString(aux_eqns, function Equation.pointerToString(str=""), "", "\t", "\n\t", "\n") + "\n");
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

      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "der")),
        arguments = {Expression.CREF(cref = state_cref)}))
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
        Integer idx;

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
    counts the number of algebraic variables in an expression."
    input Expression exp;
    input output Integer i;
  algorithm
    i := match exp
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
        print(List.toString(acc_states, BVariable.pointerToString, "", "\t", "\n\t", "\n") + "\n");
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
        _ := match old_exp
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
    Pointer<Variable> state_var, pre_var;
    Boolean negated;
  algorithm
    (state_var, old_exp, negated) := match args
      case {old_exp as Expression.CREF(cref = state_cref)}                           then (BVariable.getVarPointer(state_cref, sourceInfo()), old_exp, false);
      case {old_exp as Expression.LUNARY(exp = Expression.CREF(cref = state_cref))}  then (BVariable.getVarPointer(state_cref, sourceInfo()), old_exp, true);
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unexpected expression " + context + "("
          + List.toString(args, Expression.toString, "", "", ", ", "") + ")."});
      then fail();
    end match;
    pre_cref := getPreVar(state_cref, state_var, acc_previous, scalarized);
    if not scalarized then
      pre_cref := ComponentRef.copySubscripts(state_cref, pre_cref);
    end if;
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
        print(List.toString(acc_discrete_states, BVariable.pointerToString, "", "\t", "\n\t", "\n") + "\n");
      end if;
      if not listEmpty(acc_clocked_states) then
        print(StringUtil.headline_4("[stateselection] Natural clocked states from " + context + ":"));
        print(List.toString(acc_clocked_states, BVariable.pointerToString, "", "\t", "\n\t", "\n") + "\n");
      end if;
    end if;

    if Flags.isSet(Flags.DUMP_DISCRETEVARS_INFO) then
      if not listEmpty(acc_previous) then
        print(StringUtil.headline_4("[discreteinfo] pre() and previous() variables from " + context + ":"));
        print(List.toString(acc_previous, BVariable.pointerToString, "", "\t", "\n\t", "\n") + "\n");
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
      else ();
    end match;
  end collectDiscreteStatesFromWhen;

  function collectDiscreteStatesFromWhenBody
    "All variables on the LHS in a when equation are considered discrete."
    input WhenEquationBody body;
    input Pointer<list<Pointer<Variable>>> acc_discrete_states;
    input Pointer<list<Pointer<Variable>>> acc_previous;
    input Boolean scalarized;
  algorithm
    for body_stmt in body.when_stmts loop
      () := match body_stmt
        local
          ComponentRef state_cref, pre_cref;
          Pointer<Variable> state_var;

        case WhenStatement.ASSIGN(lhs = Expression.CREF(cref = state_cref)) algorithm
          // the function getPreVar() does all necessary collecting of information
          // but we don't need the actual pre cref it returns
          state_var := BVariable.getVarPointer(state_cref, sourceInfo());
          BVariable.makeDiscreteStateVar(state_var);
          getPreVar(state_cref, state_var, acc_previous, scalarized);
          Pointer.update(acc_discrete_states, state_var :: Pointer.access(acc_discrete_states));
        then ();

        else ();
      end match;
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
    if Util.isSome(body.else_if) then
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
    if Util.isSome(pre) then
      SOME(pre_var) := pre;
      pre_cref := BVariable.getVarName(pre_var);
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
  algorithm
    for body_stmt in body.when_stmts loop
      () := match body_stmt
        local
          ComponentRef state_cref, pre_cref;
          Pointer<Variable> state_var, pre_var;

        case WhenStatement.ASSIGN(lhs = Expression.CREF(cref = state_cref)) algorithm
          state_var := BVariable.getVarPointer(state_cref, sourceInfo());
          _ := match BVariable.getVarPre(state_var)
            case SOME(pre_var) algorithm
              Pointer.update(acc_previous, pre_var :: Pointer.access(acc_previous));
            then ();
            else ();
          end match;
          Pointer.update(acc_discrete_states, state_var :: Pointer.access(acc_discrete_states));
        then ();
        else ();
      end match;
    end for;
  end findDiscreteStatesFromWhenBody;

  function stateOrder
    input output Equation eqn;
    input UnorderedMap<ComponentRef, ComponentRef> state_order;
  protected
    Expression lhs, rhs;
  algorithm
    _ := match eqn
      case Equation.SCALAR_EQUATION(lhs = lhs as Expression.CREF(), rhs = rhs as Expression.CREF()) algorithm
        updateStateOrder(lhs.cref, rhs.cref, state_order);
      then ();

      // ToDo: sliced array/for-loops
      case Equation.ARRAY_EQUATION(lhs = lhs as Expression.CREF(), rhs = rhs as Expression.CREF()) algorithm
        updateStateOrder(lhs.cref, rhs.cref, state_order);
      then ();

      case Equation.FOR_EQUATION() algorithm
        for b in eqn.body loop
          stateOrder(b, state_order);
        end for;
      then ();

      else ();
    end match;
  end stateOrder;

  function updateStateOrder
    input ComponentRef lhs;
    input ComponentRef rhs;
    input UnorderedMap<ComponentRef, ComponentRef> state_order;
  protected
    Pointer<Variable> state;
    VariableKind lhs_k, rhs_k;
  algorithm
    _ := match (BVariable.getVarKind(BVariable.getVarPointer(lhs, sourceInfo())), BVariable.getVarKind(BVariable.getVarPointer(rhs, sourceInfo())))
      // a = der(b)
      case (_, VariableKind.STATE_DER(state = state)) algorithm
        UnorderedMap.add(BVariable.getVarName(state), ComponentRef.stripSubscriptsAll(lhs), state_order);
      then ();
      // der(b) = a
      case (VariableKind.STATE_DER(state = state), _) algorithm
        UnorderedMap.add(BVariable.getVarName(state), ComponentRef.stripSubscriptsAll(rhs), state_order);
      then ();
      else ();
    end match;
  end updateStateOrder;

  annotation(__OpenModelica_Interface="backend");
end NBDetectStates;



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
encapsulated package NBInitialization
"file:        NBInitialization.mo
 package:     NBInitialization
 description: This file contains the main data types for the initialization
              process.
"

protected
  // NF imports
  import BackendExtension = NFBackendExtension;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import Flatten = NFFlatten;
  import NFFunction.Function;
  import NFFlatten.{FunctionTree, FunctionTreeImpl};
  import NFInstNode.InstNode;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers, EqData, EquationAttributes, EquationKind, WhenEquationBody};
  import BVariable = NBVariable;
  import NBVariable.{VariablePointer, VariablePointers, VarData};
  import Causalize = NBCausalize;
  import Jacobian = NBJacobian;
  import Module = NBModule;
  import Partitioning = NBPartitioning;
  import NBSystem;
  import NBSystem.System;
  import Tearing = NBTearing;

  // Util imports
  import ClockIndexes;
  import DoubleEnded;
  import Slice = NBSlice;

public
  function main extends Module.wrapper;
  protected
    VariablePointers variables, initialVars;
    EquationPointers equations, initialEqs;
    list<tuple<Module.wrapper, String>> modules;
    list<tuple<String, Real>> clocks;
  algorithm
    try
      bdae := match bdae
        local
          VarData varData;
          EqData eqData;
        case BackendDAE.MAIN( varData = varData as VarData.VAR_DATA_SIM(variables = variables, initials = initialVars),
                              eqData = eqData as EqData.EQ_DATA_SIM(equations = equations, initials = initialEqs))
          algorithm
            // create the equations from fixed variables.
            (variables, equations, initialEqs) := createStartEquations(varData.states, variables, equations, initialEqs, eqData.uniqueIndex, "State");
            (variables, equations, initialEqs) := createStartEquations(varData.discretes, variables, equations, initialEqs, eqData.uniqueIndex, "Discrete State");
            (equations, initialEqs, initialVars) := createParameterEquations(varData.parameters, equations, initialEqs, initialVars, eqData.uniqueIndex);

            varData.variables := variables;
            varData.initials := initialVars;
            eqData.equations := equations;
            // clone all simulation equations and add them to the initial equations
            eqData.initials := EquationPointers.addList(EquationPointers.toList(initialEqs), EquationPointers.clone(equations, false));

            bdae.varData := varData;
            bdae.eqData := eqData;
        then bdae;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed to create initial system!"});
        then fail();
      end match;

      // Modules
      modules := {
        (function Partitioning.main(systemType = NBSystem.SystemType.INI),  "Partitioning"),
        (cleanup,                                                           "Cleanup"),
        (function Causalize.main(systemType = NBSystem.SystemType.INI),     "Causalize"),
        (function Tearing.main(systemType = NBSystem.SystemType.INI),       "Tearing")
      };
      (bdae, clocks) := BackendDAE.applyModules(bdae, modules, ClockIndexes.RT_CLOCK_NEW_BACKEND_INITIALIZATION);

      if Flags.isSet(Flags.DUMP_BACKEND_CLOCKS) then
        if not listEmpty(clocks) then
          print(StringUtil.headline_4("Initialization Backend Clocks:"));
          print(stringDelimitList(list(Module.moduleClockString(clck) for clck in clocks), "\n") + "\n");
        end if;
      end if;
    else
      Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed to apply modules!"});
      fail();
    end try;
  end main;

  function createStartEquations
    "Creates start equations from fixed start values."
    input VariablePointers states;
    input output VariablePointers variables;
    input output EquationPointers equations;
    input output EquationPointers initialEqs;
    input Pointer<Integer> idx;
    input String str "only for debugging dump";
  protected
    Pointer<list<Pointer<Variable>>> ptr_start_vars = Pointer.create({});
    Pointer<list<Pointer<Equation>>> ptr_start_eqs = Pointer.create({});
    list<Pointer<Variable>> start_vars;
    list<Pointer<Equation>> start_eqs;
  algorithm
    _ := VariablePointers.mapPtr(states, function createStartEquation(ptr_start_vars = ptr_start_vars, ptr_start_eqs = ptr_start_eqs, idx = idx));
    start_vars := Pointer.access(ptr_start_vars);
    start_eqs := Pointer.access(ptr_start_eqs);

    variables := BVariable.VariablePointers.addList(start_vars, variables);
    equations := EquationPointers.addList(start_eqs, equations);
    initialEqs := EquationPointers.addList(start_eqs, initialEqs);

    if Flags.isSet(Flags.INITIALIZATION) and not listEmpty(start_eqs) then
      print(List.toString(start_eqs, function Equation.pointerToString(str = ""), StringUtil.headline_4("Created " + str + " Start Equations:"), "\t", "\n\t", "", false) + "\n\n");
    end if;
  end createStartEquations;

  function createStartEquation
    "creates a start equation for a fixed state or discrete state."
    input Pointer<Variable> state;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
  algorithm
    () := match Pointer.access(state)
      local
        ComponentRef name, start_name;
        Pointer<Variable> var_ptr, start_var;
        Pointer<Equation> start_eq;
        EquationKind kind;

      // if it is an array create for equation
      case Variable.VARIABLE() guard BVariable.isFixed(state) and BVariable.isArray(state) algorithm
        createStartEquationSlice(Slice.SLICE(state, {}), ptr_start_vars, ptr_start_eqs, idx);
      then ();

      // create scalar equation
      case Variable.VARIABLE() guard BVariable.isFixed(state) algorithm
        name := BVariable.getVarName(state);
        (var_ptr, name, start_var, start_name) := createStartVar(state, name, {});
        kind := if BVariable.isContinuous(state) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
        start_eq := Equation.makeAssignment(name, Expression.fromCref(start_name), idx, NBEquation.START_STR, {}, EquationAttributes.default(kind, true));
        Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
        Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
      then ();

      else ();
    end match;
  end createStartEquation;

  function createStartVar
    "creates start variable and cref.
    for discrete states the variable itself is changed to its
    pre variable because they have to be initialized instead!.
    normal:             var = $START.var
    disc state and pre: $PRE.dst = $START.dst"
    input output Pointer<Variable> var_ptr;
    input output ComponentRef name;
    input list<Subscript> subscripts;
    output Pointer<Variable> start_var;
    output ComponentRef start_name;
  protected
    Pointer<Variable> disc_state_var;
    ComponentRef merged_name;
  algorithm
    if BVariable.isDiscreteState(var_ptr) then
      // for discrete states change the lhs cref to the $PRE cref
      merged_name := ComponentRef.mergeSubscripts(subscripts, name, true, true);
      name := BVariable.getPreCref(name);
      name := ComponentRef.mergeSubscripts(subscripts, name, true, true);
      var_ptr := BVariable.getVarPointer(name);
    elseif BVariable.isPrevious(var_ptr) then
      // for previous change the rhs to the start value of the discrete state
      merged_name := BVariable.getDiscreteStateCref(name);
      merged_name := ComponentRef.mergeSubscripts(subscripts, merged_name, true, true);
    else
      // just apply subscripts and make start var
      name := ComponentRef.mergeSubscripts(subscripts, name, true, true);
      merged_name := name;
    end if;
    (start_name, start_var) := BVariable.makeStartVar(merged_name);
  end createStartVar;

  function createParameterEquations
    "creates parameter equations of the form param = $START.param for all fixed params."
    input VariablePointers parameters;
    input output EquationPointers equations;
    input output EquationPointers initialEqs;
    input output VariablePointers initialVars;
    input Pointer<Integer> idx;
  protected
    list<Pointer<Equation>> parameter_eqs = {};
    list<Pointer<Variable>> initial_param_vars = {};
  algorithm
    for var in VariablePointers.toList(parameters) loop
      // only consider non constant parameter bindings
      if (BVariable.getBindingVariability(var) > NFPrefixes.Variability.STRUCTURAL_PARAMETER) then
        // add variable to initial unknowns
        initial_param_vars := var :: initial_param_vars;
        // generate equation only if variable is fixed
        if BVariable.isFixed(var) then
          parameter_eqs := Equation.generateBindingEquation(var, idx, true) :: parameter_eqs;
        end if;
      end if;
    end for;
    equations := EquationPointers.addList(parameter_eqs, equations);
    initialEqs := EquationPointers.addList(parameter_eqs, initialEqs);
    initialVars := VariablePointers.addList(initial_param_vars, initialVars);
    if (Flags.isSet(Flags.INITIALIZATION) and not listEmpty(parameter_eqs)) or Flags.isSet(Flags.DUMP_BINDINGS) then
      print(List.toString(parameter_eqs, function Equation.pointerToString(str = ""), StringUtil.headline_4("Created Parameter Binding Equations:"), "\t", "\n\t", "", false) + "\n\n");
    end if;
  end createParameterEquations;

  function createStartEquationSlice
    "creates a start equation for a sliced variable.
    usually results in a for equation, but might be scalarized if that is not possible."
    input Slice<VariablePointer> state;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
  protected
    Pointer<Variable> var_ptr, start_var;
    ComponentRef name, start_name;
    list<Dimension> dims;
    list<InstNode> iterators;
    list<ComponentRef> iter_crefs;
    list<Expression> ranges;
    list<Subscript> subscripts;
    list<tuple<ComponentRef, Expression>> frames;
    Pointer<Equation> start_eq;
    EquationKind kind;
  algorithm
    var_ptr := Slice.getT(state);
    name    := BVariable.getVarName(var_ptr);
    dims    := Type.arrayDims(ComponentRef.nodeType(name));
    (iterators, ranges, subscripts) := Flatten.makeIterators(name, dims);
    iter_crefs := list(ComponentRef.makeIterator(iter, Type.INTEGER()) for iter in iterators);
    iter_crefs := list(BackendDAE.lowerIteratorCref(iter) for iter in iter_crefs);
    subscripts := list(Subscript.mapExp(sub, BackendDAE.lowerIteratorExp) for sub in subscripts);
    frames  := List.zip(iter_crefs, ranges);
    (var_ptr, name, start_var, start_name) := createStartVar(var_ptr, name, subscripts);
    kind := if BVariable.isContinuous(var_ptr) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
    start_eq := Equation.makeAssignment(name, Expression.fromCref(start_name), idx, NBEquation.START_STR, frames, EquationAttributes.default(kind, true));
    if not listEmpty(state.indices) then
      // empty list indicates full array, slice otherwise
      (start_eq, _, _) := Equation.slice(start_eq, state.indices, NONE(), FunctionTreeImpl.EMPTY());
    end if;
    Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
    Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
  end createStartEquationSlice;

  function createPreEquation
    "creates d = $PRE.d equations"
    input Pointer<Variable> disc_state;
    input Pointer<list<Pointer<Equation>>> ptr_pre_eqs;
    input Pointer<Integer> idx;
  algorithm
    () := match Pointer.access(disc_state)
      local
        Pointer<Variable> previous;
        Pointer<Equation> pre_eq;
        EquationKind kind;

      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.VariableKind.DISCRETE_STATE(previous = previous)))
        algorithm
          kind := if BVariable.isContinuous(disc_state) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
          pre_eq := Equation.makeAssignment(BVariable.getVarName(disc_state), Expression.fromCref(BVariable.getVarName(previous)), idx, NBEquation.PRE_STR, {}, EquationAttributes.default(kind, true));
          Pointer.update(ptr_pre_eqs, pre_eq :: Pointer.access(ptr_pre_eqs));
      then ();
      else ();
    end match;
  end createPreEquation;

  function createPreEquationSlice
    "creates a pre equation for a sliced variable.
    usually results in a for equation, but might be scalarized if that is not possible."
    input Slice<VariablePointer> disc_state;
    input Pointer<list<Pointer<Equation>>> ptr_pre_eqs;
    input Pointer<Integer> idx;
  protected
    Pointer<Variable> var_ptr;
    ComponentRef name, pre_name;
    list<Dimension> dims;
    list<InstNode> iterators;
    list<Expression> ranges;
    list<Subscript> subscripts;
    list<tuple<ComponentRef, Expression>> frames;
    Pointer<Equation> pre_eq;
    EquationKind kind;
  algorithm
    var_ptr := Slice.getT(disc_state);
    name    := BVariable.getVarName(var_ptr);
    dims    := Type.arrayDims(ComponentRef.nodeType(name));
    (iterators, ranges, subscripts) := Flatten.makeIterators(name, dims);
    frames  := List.zip(list(ComponentRef.makeIterator(iter, Type.INTEGER()) for iter in iterators), ranges);

    pre_name := BVariable.getPreCref(name);
    pre_name := ComponentRef.mergeSubscripts(subscripts, pre_name, true, true);
    name := ComponentRef.mergeSubscripts(subscripts, name, true, true);

    kind := if BVariable.isContinuous(var_ptr) then EquationKind.CONTINUOUS else EquationKind.DISCRETE;
    pre_eq := Equation.makeAssignment(name, Expression.fromCref(pre_name), idx, NBEquation.PRE_STR, frames, EquationAttributes.default(kind, true));

    if not listEmpty(disc_state.indices) then
      // empty list indicates full array, slice otherwise
      (pre_eq, _, _) := Equation.slice(pre_eq, disc_state.indices, NONE(), FunctionTreeImpl.EMPTY());
    end if;
    Pointer.update(ptr_pre_eqs, pre_eq :: Pointer.access(ptr_pre_eqs));
  end createPreEquationSlice;

  function cleanup
    "removes calls from the initial problem and marks init_0"
    extends Module.wrapper;
  protected
    Pointer<Boolean> hasHom = Pointer.create(false);
  algorithm
    bdae := match bdae
      case BackendDAE.MAIN() algorithm

        // initial() -> false
        bdae.ode        := list(System.mapEqn(sys, function cleanupInitialCall(init = false)) for sys in bdae.ode);
        bdae.algebraic  := list(System.mapEqn(sys, function cleanupInitialCall(init = false)) for sys in bdae.algebraic);
        bdae.ode_event  := list(System.mapEqn(sys, function cleanupInitialCall(init = false)) for sys in bdae.ode_event);
        bdae.alg_event  := list(System.mapEqn(sys, function cleanupInitialCall(init = false)) for sys in bdae.alg_event);
        if Util.isSome(bdae.dae) then
          bdae.dae := SOME(list(System.mapEqn(sys, function cleanupInitialCall(init = false)) for sys in Util.getOption(bdae.dae)));
        end if;
        // initial() -> true
        bdae.init := list(System.mapEqn(sys, function cleanupInitialCall(init = true)) for sys in bdae.init);

        // homotopy(actual, simplified) -> actual
        bdae.ode        := list(System.mapExp(sys, function cleanupHomotopy(init = false, hasHom = hasHom)) for sys in bdae.ode);
        bdae.algebraic  := list(System.mapExp(sys, function cleanupHomotopy(init = false, hasHom = hasHom)) for sys in bdae.algebraic);
        bdae.ode_event  := list(System.mapExp(sys, function cleanupHomotopy(init = false, hasHom = hasHom)) for sys in bdae.ode_event);
        bdae.alg_event  := list(System.mapExp(sys, function cleanupHomotopy(init = false, hasHom = hasHom)) for sys in bdae.alg_event);
        if Util.isSome(bdae.dae) then
          bdae.dae := SOME(list(System.mapExp(sys, function cleanupHomotopy(init = false, hasHom = hasHom)) for sys in Util.getOption(bdae.dae)));
        end if;

        // create init_0 if homotopy call exists.
        if Pointer.access(hasHom) then
          bdae.init_0 := SOME(list(System.clone(sys, false) for sys in bdae.init));
          bdae.init_0 := SOME(list(System.mapExp(sys, function cleanupHomotopy(init = true, hasHom = hasHom)) for sys in Util.getOption(bdae.init_0)));
        end if;

      then bdae;

      else bdae;
    end match;
  end cleanup;

  function cleanupInitialCall
    input output Equation eq;
    input Boolean init;
  algorithm
    eq := match eq
      local
        WhenEquationBody body;
        Pointer<Boolean> simplify;
      case Equation.WHEN_EQUATION(body = body) algorithm
        simplify := Pointer.create(false);
        body.condition := Expression.map(body.condition, function cleanupInitialCallExp(init = init, simplify = simplify));
        // TODO simplify when equation if `Pointer.access(simplify)` is true
        eq.body := body;
      then Equation.simplify(eq);
      else eq;
    end match;
  end cleanupInitialCall;

  function cleanupInitialCallExp
    input output Expression exp;
    input Boolean init;
    input Pointer<Boolean> simplify "output, determines if when-equation should be simplified";
  algorithm
    exp := match exp
      local
        Expression e;
        String name;
        Call call;
      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
        e := match name
          case "initial" algorithm
            Pointer.update(simplify, true);
          then Expression.BOOLEAN(init);
          else exp;
        end match;
      then e;
      else exp;
    end match;
  end cleanupInitialCallExp;

  function cleanupHomotopy
    input output Expression exp;
    input Boolean init "if init then replace with simplified, else replace with actual";
    input Pointer<Boolean> hasHom   "output, determines if system contains homotopy()";
  algorithm
    exp := match exp
      local
        Expression e;
        String name;
        Call call;
      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        name := AbsynUtil.pathString(Function.nameConsiderBuiltin(call.fn));
        e := match name
          case "homotopy" algorithm
            Pointer.update(hasHom, true);
          then listGet(Call.arguments(exp.call), if init then 2 else 1);
          else exp;
        end match;
      then e;
      else exp;
    end match;
  end cleanupHomotopy;

  annotation(__OpenModelica_Interface="backend");
end NBInitialization;

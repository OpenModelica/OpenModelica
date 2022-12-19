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
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import Flatten = NFFlatten;
  import NFFlatten.{FunctionTree, FunctionTreeImpl};
  import NFInstNode.InstNode;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import NBEquation.{Equation,EquationPointers};
  import BVariable = NBVariable;
  import NBVariable.{VariablePointer, VariablePointers};
  import Causalize = NBCausalize;
  import Jacobian = NBJacobian;
  import Module = NBModule;
  import Partitioning = NBPartitioning;
  import System = NBSystem;
  import Tearing = NBTearing;

  // Util imports
  import ClockIndexes;
  import DoubleEnded;
  import Slice = NBSlice;

public
  function main extends Module.wrapper;
  protected
    BVariable.VariablePointers variables, initialVars;
    BEquation.EquationPointers equations, initialEqs;
    list<tuple<Module.wrapper, String>> modules;
    list<tuple<String, Real>> clocks;
  algorithm
    try
      bdae := match bdae
        local
          BVariable.VarData varData;
          BEquation.EqData eqData;
        case BackendDAE.MAIN( varData = varData as BVariable.VAR_DATA_SIM(variables = variables, initials = initialVars),
                              eqData = eqData as BEquation.EQ_DATA_SIM(equations = equations, initials = initialEqs))
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to create initial system!"});
        then fail();
      end match;

      // Modules
      modules := {
        (function Partitioning.main(systemType = NBSystem.SystemType.INI),  "Partitioning"),
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
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to apply modules!"});
    end try;
  end main;

  function createStartEquations
    "Creates start equations from fixed start values."
    input BVariable.VariablePointers states;
    input output BVariable.VariablePointers variables;
    input output BEquation.EquationPointers equations;
    input output BEquation.EquationPointers initialEqs;
    input Pointer<Integer> idx;
    input String str "only for debugging dump";
  protected
    Pointer<list<Pointer<Variable>>> ptr_start_vars = Pointer.create({});
    Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqs = Pointer.create({});
    list<Pointer<Variable>> start_vars;
    list<Pointer<BEquation.Equation>> start_eqs;
  algorithm
    _ := BVariable.VariablePointers.mapPtr(states, function createStartEquation(ptr_start_vars = ptr_start_vars, ptr_start_eqs = ptr_start_eqs, idx = idx));
    start_vars := Pointer.access(ptr_start_vars);
    start_eqs := Pointer.access(ptr_start_eqs);

    variables := BVariable.VariablePointers.addList(start_vars, variables);
    equations := BEquation.EquationPointers.addList(start_eqs, equations);
    initialEqs := BEquation.EquationPointers.addList(start_eqs, initialEqs);

    if Flags.isSet(Flags.INITIALIZATION) and not listEmpty(start_eqs) then
      print(List.toString(start_eqs, function Equation.pointerToString(str = ""), StringUtil.headline_4("Created " + str + " Start Equations:"), "\t", "\n\t", "", false) + "\n\n");
    end if;
  end createStartEquations;

  function createStartEquation
    "creates a start equation for a fixed state or discrete state."
    input Pointer<Variable> state;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
  algorithm
    _ := match Pointer.access(state)
      local
        ComponentRef name, start_name;
        Pointer<Variable> var_ptr, start_var;
        Pointer<BEquation.Equation> start_eq;

      // if it is an array create for equation
      case Variable.VARIABLE() guard BVariable.isFixed(state) and BVariable.isArray(state) algorithm
        createStartEquationSlice(Slice.SLICE(state, {}), ptr_start_vars, ptr_start_eqs, idx);
      then ();

      // create scalar equation
      case Variable.VARIABLE() guard BVariable.isFixed(state) algorithm
        name := BVariable.getVarName(state);
        (var_ptr, name, start_var, start_name) := createStartVar(state, name, {});
        start_eq := BEquation.Equation.makeAssignment(name, Expression.fromCref(start_name), idx, NBEquation.START_STR, {}, NBEquation.EQ_ATTR_DEFAULT_INITIAL);
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
    input BVariable.VariablePointers parameters;
    input output BEquation.EquationPointers equations;
    input output BEquation.EquationPointers initialEqs;
    input output BVariable.VariablePointers initialVars;
    input Pointer<Integer> idx;
  protected
    list<Pointer<BEquation.Equation>> parameter_eqs = {};
    list<Pointer<Variable>> initial_param_vars = {};
  algorithm
    for var in BVariable.VariablePointers.toList(parameters) loop
      // only consider non constant parameter bindings
      if (BVariable.getBindingVariability(var) > NFPrefixes.Variability.STRUCTURAL_PARAMETER) then
        // add variable to initial unknowns
        initial_param_vars := var :: initial_param_vars;
        // generate equation only if variable is fixed
        if BVariable.isFixed(var) then
          parameter_eqs := BEquation.Equation.generateBindingEquation(var, idx, true) :: parameter_eqs;
        end if;
      end if;
    end for;
    equations := BEquation.EquationPointers.addList(parameter_eqs, equations);
    initialEqs := BEquation.EquationPointers.addList(parameter_eqs, initialEqs);
    initialVars := BVariable.VariablePointers.addList(initial_param_vars, initialVars);
    if Flags.isSet(Flags.INITIALIZATION) and not listEmpty(parameter_eqs) then
      print(List.toString(parameter_eqs, function Equation.pointerToString(str = ""), StringUtil.headline_4("Created Parameter Binding Equations:"), "\t", "\n\t", "", false) + "\n\n");
    end if;
  end createParameterEquations;

  function createStartEquationSlice
    "creates a start equation for a sliced variable.
    usually results in a for equation, but might be scalarized if that is not possible."
    input Slice<VariablePointer> state;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqs;
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
    start_eq := Equation.makeAssignment(name, Expression.fromCref(start_name), idx, NBEquation.START_STR, frames, NBEquation.EQ_ATTR_DEFAULT_INITIAL);
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
    input Pointer<list<Pointer<BEquation.Equation>>> ptr_pre_eqs;
    input Pointer<Integer> idx;
  algorithm
    _ := match Pointer.access(disc_state)
      local
        Pointer<Variable> previous;
        Pointer<BEquation.Equation> pre_eq;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.VariableKind.DISCRETE_STATE(previous = previous)))
        algorithm
          pre_eq := BEquation.Equation.makeAssignment(BVariable.getVarName(disc_state), Expression.fromCref(BVariable.getVarName(previous)), idx, NBEquation.PRE_STR, {}, NBEquation.EQ_ATTR_DEFAULT_INITIAL);
          Pointer.update(ptr_pre_eqs, pre_eq :: Pointer.access(ptr_pre_eqs));
      then ();
      else ();
    end match;
  end createPreEquation;

  function createPreEquationSlice
    "creates a pre equation for a sliced variable.
    usually results in a for equation, but might be scalarized if that is not possible."
    input Slice<VariablePointer> disc_state;
    input Pointer<list<Pointer<BEquation.Equation>>> ptr_pre_eqs;
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
  algorithm
    var_ptr := Slice.getT(disc_state);
    name    := BVariable.getVarName(var_ptr);
    dims    := Type.arrayDims(ComponentRef.nodeType(name));
    (iterators, ranges, subscripts) := Flatten.makeIterators(name, dims);
    frames  := List.zip(list(ComponentRef.makeIterator(iter, Type.INTEGER()) for iter in iterators), ranges);

    pre_name := BVariable.getPreCref(name);
    pre_name := ComponentRef.mergeSubscripts(subscripts, pre_name, true, true);
    name := ComponentRef.mergeSubscripts(subscripts, name, true, true);

    pre_eq := Equation.makeAssignment(name, Expression.fromCref(pre_name), idx, NBEquation.PRE_STR, frames, NBEquation.EQ_ATTR_DEFAULT_INITIAL);

    if not listEmpty(disc_state.indices) then
      // empty list indicates full array, slice otherwise
      (pre_eq, _, _) := Equation.slice(pre_eq, disc_state.indices, NONE(), FunctionTreeImpl.EMPTY());
    end if;
    Pointer.update(ptr_pre_eqs, pre_eq :: Pointer.access(ptr_pre_eqs));
  end createPreEquationSlice;

  annotation(__OpenModelica_Interface="backend");
end NBInitialization;

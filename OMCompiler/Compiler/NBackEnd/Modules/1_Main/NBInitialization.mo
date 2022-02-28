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
            (variables, equations, initialEqs) := createStartEquations(varData.states, variables, equations, initialEqs, eqData.uniqueIndex);
            (variables, equations, initialEqs) := createStartEquations(varData.discretes, variables, equations, initialEqs, eqData.uniqueIndex);
            (equations, initialEqs) := createPreEquations(varData.previous, equations, initialEqs, eqData.uniqueIndex);
            (equations, initialEqs, initialVars) := createParameterEquations(varData.parameters, equations, initialEqs, initialVars, eqData.uniqueIndex);

            varData.variables := variables;
            varData.initials := initialVars;
            eqData.equations := equations;
            eqData.initials := EquationPointers.addList(EquationPointers.toList(initialEqs), EquationPointers.clone(equations, false));

            bdae.varData := varData;
            bdae.eqData := eqData;
        then bdae;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
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
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
    end try;
  end main;

  function createStartEquations
    "Creates start equations from fixed start values.
     kabdelhak: currently does not check for consistency!"
    // ToDo: create Module wrapper for this.
    input BVariable.VariablePointers states;
    input output BVariable.VariablePointers variables;
    input output BEquation.EquationPointers equations;
    input output BEquation.EquationPointers initialEqs;
    input Pointer<Integer> idx;
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
      print(List.toString(start_eqs, function Equation.pointerToString(str = ""), StringUtil.headline_4("Created Start Equations:"), "\t", "\n\t", "", false) + "\n\n");
    end if;
  end createStartEquations;

  function createStartEquation
    input Pointer<Variable> state;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
  algorithm
    _ := match Pointer.access(state)
      local
        ComponentRef name, start_name;
        Pointer<Variable> start_var;
        Pointer<BEquation.Equation> start_eq;
        Option<Expression> start;

      // if it is an array create for equation
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_REAL(fixed = SOME(Expression.BOOLEAN(value = true)))))
        guard(BVariable.isArray(state)) algorithm
          createStartEquationSlice(Slice.SLICE(state, {}), ptr_start_vars, ptr_start_eqs, idx);
      then ();

      // create scalar equation
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(attributes = BackendExtension.VAR_ATTR_REAL(fixed = SOME(Expression.BOOLEAN(value = true)), start = start)))
        algorithm
          name := BVariable.getVarName(state);
          (start_name, start_var) := BVariable.makeStartVar(name);
          start_eq := BEquation.Equation.makeStartEq(name, start_name, idx);
          Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
          Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
      then ();
      else ();
    end match;
  end createStartEquation;

  function createStartEquationSlice
    input Slice<VariablePointer> state;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqs;
    input Pointer<Integer> idx;
  protected
    Pointer<Variable> var_ptr, start_var;
    ComponentRef name, start_name;
    list<Dimension> dims;
    list<InstNode> iterators;
    list<Expression> ranges;
    list<Subscript> subscripts;
    list<tuple<ComponentRef, Expression>> frames;
    Pointer<Equation> start_eq;
  algorithm
    var_ptr := Slice.getT(state);
    name := BVariable.getVarName(var_ptr);
    dims := Type.arrayDims(ComponentRef.nodeType(name));
    (iterators, ranges, subscripts) := Flatten.makeIterators(name, dims);
    frames := List.zip(list(ComponentRef.makeIterator(iter, Type.INTEGER()) for iter in iterators), ranges);
    name := ComponentRef.mergeSubscripts(subscripts, name);
    (start_name, start_var) := BVariable.makeStartVar(name);
    start_eq := BEquation.Equation.makeStartEq(name, start_name, idx, frames);
    if listEmpty(state.indices) then
      // empty list indicates full array, slice otherwise
      (start_eq, _, _) := Equation.slice(start_eq, state.indices, NONE(), FunctionTreeImpl.EMPTY());
    end if;
    Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
    Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
  end createStartEquationSlice;

  function createPreEquations
    "Creates start equations from fixed start values.
     kabdelhak: currently does not check for consistency!"
    // ToDo: create Module wrapper for this.
    input BVariable.VariablePointers previous;
    input output BEquation.EquationPointers equations;
    input output BEquation.EquationPointers initialEqs;
    input Pointer<Integer> idx;
  protected
    Pointer<list<Pointer<BEquation.Equation>>> ptr_pre_eqs = Pointer.create({});
    list<Pointer<BEquation.Equation>> pre_eqs;
  algorithm
    _ := BVariable.VariablePointers.mapPtr(previous, function createPreEquation(ptr_pre_eqs = ptr_pre_eqs, idx = idx));
    pre_eqs := Pointer.access(ptr_pre_eqs);
    equations := BEquation.EquationPointers.addList(pre_eqs, equations);
    initialEqs := BEquation.EquationPointers.addList(pre_eqs, initialEqs);
    if Flags.isSet(Flags.INITIALIZATION) and not listEmpty(pre_eqs) then
      print(List.toString(pre_eqs, function Equation.pointerToString(str = ""), StringUtil.headline_4("Created Unfixed Discrete Equations:"), "\t", "\n\t", "", false) + "\n\n");
    end if;
  end createPreEquations;

  function createPreEquation
    input Pointer<Variable> preVar;
    input Pointer<list<Pointer<BEquation.Equation>>> ptr_pre_eqs;
    input Pointer<Integer> idx;
  algorithm
    _ := match Pointer.access(preVar)
      local
        Pointer<Variable> disc_var;
        Pointer<BEquation.Equation> pre_eq;
      case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.VariableKind.PREVIOUS(disc = disc_var)))
        algorithm
          pre_eq := BEquation.Equation.makePreEq(BVariable.getVarName(preVar), BVariable.getVarName(disc_var), idx);
          Pointer.update(ptr_pre_eqs, pre_eq :: Pointer.access(ptr_pre_eqs));
      then ();
      else ();
    end match;
  end createPreEquation;

  function createParameterEquations
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
      if (BVariable.getBindingVariability(var) <> NFPrefixes.Variability.CONSTANT) then
        // add variable to initial unknowns
        initial_param_vars := var :: initial_param_vars;
        // generate equation only if variable is fixed
        if BVariable.isFixed(var) then
          parameter_eqs := BEquation.Equation.generateBindingEquation(var, idx) :: parameter_eqs;
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

  function sortInitEqns
    "sorts initial equations to be at the start of the array"
    input output EquationPointers equations;
  protected
    DoubleEnded.MutableList<Pointer<Equation>> eqns = DoubleEnded.empty(Pointer.create(Equation.DUMMY_EQUATION()));
  algorithm
    for eqn in EquationPointers.toList(equations) loop
      if Equation.isInitial(eqn) then
        DoubleEnded.push_front(eqns, eqn);
      else
        DoubleEnded.push_back(eqns, eqn);
      end if;
    end for;
    equations := EquationPointers.fromList(DoubleEnded.toListAndClear(eqns));
  end sortInitEqns;

  function sortInitVars
    "sorts initial variables such that states are at the end of the array"
    input output VariablePointers variables;
  protected
    DoubleEnded.MutableList<Pointer<Variable>> vars = DoubleEnded.empty(Pointer.create(NBVariable.DUMMY_VARIABLE));
  algorithm
    for var in VariablePointers.toList(variables) loop
      if BVariable.isState(var) then
        DoubleEnded.push_back(vars, var);
      else
        DoubleEnded.push_front(vars, var);
      end if;
    end for;
    variables := VariablePointers.fromList(DoubleEnded.toListAndClear(vars));
  end sortInitVars;

  annotation(__OpenModelica_Interface="backend");
end NBInitialization;

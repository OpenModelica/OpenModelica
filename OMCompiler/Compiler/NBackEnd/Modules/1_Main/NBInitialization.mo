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
  import Expression = NFExpression;
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Causalize = NBCausalize;
  import Jacobian = NBJacobian;
  import Module = NBModule;
  import Partitioning = NBPartitioning;
  import System = NBSystem;
  import Tearing = NBTearing;

public
  function main extends Module.wrapper;
  protected
    BVariable.VariablePointers variables, initialVars;
    BEquation.EquationPointers equations, initialEqs;
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
            eqData.initials := initialEqs;

            bdae.varData := varData;
            bdae.eqData := eqData;
        then bdae;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;

      // Modules
      bdae := Partitioning.main(bdae, NBSystem.SystemType.INI);
      bdae := Causalize.main(bdae, NBSystem.SystemType.INI);
      bdae := Tearing.main(bdae, NBSystem.SystemType.INI);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
    end try;
  end main;

protected
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
  end createParameterEquations;

  annotation(__OpenModelica_Interface="backend");
end NBInitialization;

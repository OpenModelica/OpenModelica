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
encapsulated uniontype NBInitialization
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
  import Module = NBModule;
  import NBSystem;
  import Partitioning = NBPartitioning;

public
  function main extends Module.wrapper;
  protected
    BVariable.VariablePointers variables;
    BVariable.VariablePointers states;
    BEquation.EquationPointers equations;
    BEquation.EquationPointers initialEqs;
  algorithm
    bdae := match bdae
      local
        BackendDAE.BackendDAE qual;
        BVariable.VarData varData;
        BEquation.EqData eqData;
      case qual as BackendDAE.BDAE( varData = varData as BVariable.VAR_DATA_SIM(variables = variables, states = states),
                                    eqData = eqData as BEquation.EQ_DATA_SIM(equations = equations, initials = initialEqs))
        algorithm
          (variables, equations, initialEqs) := createStartEquations(states, variables, equations, initialEqs);

          varData.variables := variables;
          eqData.equations := equations;
          eqData.initials := initialEqs;

          qual.varData := varData;
          qual.eqData := eqData;
      then qual;
    end match;

    bdae := Partitioning.main(bdae, NBSystem.SystemType.INIT);
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
  protected
    Pointer<list<Pointer<Variable>>> ptr_start_vars = Pointer.create({});
    Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqs = Pointer.create({});
    list<Pointer<Variable>> start_vars;
    list<Pointer<BEquation.Equation>> start_eqs;
  algorithm
    _ := BVariable.VariablePointers.map(states, function createStartEquation(ptr_start_vars = ptr_start_vars, ptr_start_eqs = ptr_start_eqs));
    start_vars := Pointer.access(ptr_start_vars);
    start_eqs := Pointer.access(ptr_start_eqs);

  //  print("BEFORE: " + BVariable.VariablePointers.toString(initialVars) + "\n");
    variables := BVariable.VariablePointers.addList(start_vars, variables);

    //    print("AFTER: " + BVariable.VariablePointers.toString(initialVars) + "\n");
    print("BEFORE: " + BEquation.EquationPointers.toString(initialEqs) + "\n");

    equations := BEquation.EquationPointers.addList(start_eqs, equations);
    initialEqs := BEquation.EquationPointers.addList(start_eqs, initialEqs);
    print("AFTER: " + BEquation.EquationPointers.toString(initialEqs) + "\n");
end createStartEquations;

  function createStartEquation
    input output Variable state;
    input Pointer<list<Pointer<Variable>>> ptr_start_vars;
    input Pointer<list<Pointer<BEquation.Equation>>> ptr_start_eqs;
  algorithm
    _ := match state
      local
        ComponentRef name, start_name;
        Pointer<Variable> start_var;
        Pointer<BEquation.Equation> start_eq;
        Option<Expression> start;
      case Variable.VARIABLE(name = name, backendinfo = BackendExtension.BACKEND_INFO(attributes = SOME(BackendExtension.VAR_ATTR_REAL(fixed = SOME(Expression.BOOLEAN(value = true)), start = start))))
        algorithm
          (start_name, start_var) := BVariable.makeStartVar(name);
          start_eq := Pointer.create(BEquation.Equation.makeStartEq(name, start_name));
          Pointer.update(ptr_start_vars, start_var :: Pointer.access(ptr_start_vars));
          Pointer.update(ptr_start_eqs, start_eq :: Pointer.access(ptr_start_eqs));
      then ();
      else ();
    end match;
  end createStartEquation;

  annotation(__OpenModelica_Interface="backend");
end NBInitialization;

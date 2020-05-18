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
  description:  This file contains all functions for the detection of continous
                and discrete state variables.
"

public
  import Module = NBModule;

protected
  // Old Frontend Imports
  import Absyn;

  // New Frontend Imports
  import BackendExtension = NFBackendExtension;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Function = NFFunction;
  import InstNode = NFInstNode.InstNode;
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;

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
        BVariable.VarData varData                       "Data containing variable pointers";
        BEquation.EqData eqData                         "Data containing equation pointers";
      case BackendDAE.BDAE(varData = varData, eqData = eqData)
        algorithm
          mainFunc(varData, eqData, contFunc, discFunc);
        then bdae;
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
   BVariable.VariablePointers variables      "All variables";
   BEquation.EquationPointers equations      "System equations";
   BEquation.EquationPointers disc_eqns      "Discrete equations";
   BVariable.VariablePointers unknowns       "Unknowns";
   BVariable.VariablePointers knowns         "Knowns";
   BVariable.VariablePointers initials       "Initial unknowns";
   BVariable.VariablePointers states         "States";
   BVariable.VariablePointers derivatives    "State derivatives (der(x) -> $DER.x)";
   BVariable.VariablePointers algebraics     "Algebraic variables";
   BVariable.VariablePointers discretes      "Discrete variables";
   BVariable.VariablePointers previous       "Previous discrete variables (pre(d) -> $PRE.d)";
   BVariable.VariablePointers auxiliaries, aliasVars, parameters, constants     "(only to reconstruct VAR_DATA_SIM)";

  algorithm
    BVariable.VAR_DATA_SIM(variables = variables, unknowns = unknowns, knowns = knowns, initials = initials, auxiliaries = auxiliaries, aliasVars = aliasVars, states = states, derivatives = derivatives, algebraics = algebraics, discretes = discretes, previous = previous, parameters = parameters, constants = constants) := varData;
    BEquation.EQ_DATA_SIM(equations = equations, discretes = disc_eqns) := eqData;
    (variables, equations, unknowns, knowns, initials, states, derivatives, algebraics) := continuousFunc(variables, equations, unknowns, knowns, initials, states, derivatives, algebraics);
    (variables, disc_eqns, knowns, initials, discretes, previous) := discreteFunc(variables, disc_eqns, knowns, initials, discretes, previous);
    varData := BVariable.VAR_DATA_SIM(variables, unknowns, knowns, initials, states, auxiliaries, aliasVars, derivatives, algebraics, discretes, previous, parameters, constants);
    eqData := BEquation.EqData.setEquations(eqData, equations);
  end detectStatesDefault;

  function detectContinuousStatesDefault extends Module.detectContinuousStatesInterface;
  protected
    Pointer<list<Pointer<Variable>>> acc_states = Pointer.create({});
    Pointer<list<Pointer<Variable>>> acc_derivatives = Pointer.create({});
  algorithm
    BEquation.EquationPointers.mapExp(equations, function collectStatesAndDerivatives(acc_states = acc_states, acc_derivatives = acc_derivatives));
    (variables, unknowns, knowns, states, derivatives, algebraics) := updateStatesAndDerivatives(variables, unknowns, knowns, initials, states, derivatives, algebraics, Pointer.access(acc_states), Pointer.access(acc_derivatives));
  end detectContinuousStatesDefault;

  function detectDiscreteStatesDefault extends Module.detectDiscreteStatesInterface;
  protected
    Pointer<list<Pointer<Variable>>> acc_discrete_states = Pointer.create({});
    Pointer<list<Pointer<Variable>>> acc_previous = Pointer.create({});
  algorithm
    BEquation.EquationPointers.mapExp(equations, function collectDiscreteStatesAndPrevious(acc_discrete_states = acc_discrete_states, acc_previous = acc_previous));
    (variables, knowns, discretes, previous) := updateDiscreteStatesAndPrevious(variables, knowns, initials, discretes, previous, Pointer.access(acc_discrete_states), Pointer.access(acc_previous));
  end detectDiscreteStatesDefault;

  function collectStatesAndDerivatives
    "Collects all states and creates a derivative variable for each."
    input output Expression exp;
    input Pointer<list<Pointer<Variable>>> acc_states;
    input Pointer<list<Pointer<Variable>>> acc_derivatives;
  algorithm
    exp := match exp
      local
        ComponentRef state_cref, der_cref;
        Pointer<Variable> state_var, der_var;
      // ToDo need Call.TYPED_REDUCTION?
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "der")),
        arguments = {Expression.CREF(cref = state_cref)}))
        algorithm
          state_var := BVariable.getVarPointer(state_cref);
          if BVariable.isState(state_var) then
            // this derivative was already created -> the variable should already have a pointer to its derivative
            der_cref := BVariable.getDerCref(state_cref);
          else
            (der_cref, der_var) := BVariable.makeDerVar(state_cref);
            state_var := BVariable.makeStateVar(state_var, der_var);
            Pointer.update(acc_states, state_var :: Pointer.access(acc_states));
            Pointer.update(acc_derivatives, der_var :: Pointer.access(acc_derivatives));
          end if;
      then Expression.fromCref(der_cref);
      // ToDo! General expressions inside call! -> ticket #5934
      else exp;
    end match;
  end collectStatesAndDerivatives;

  function updateStatesAndDerivatives
    "Updates the variable pointer arrays with the new information about states and derivatives."
    input output BVariable.VariablePointers variables      "All variables";
    input output BVariable.VariablePointers unknowns       "Unknowns";
    input output BVariable.VariablePointers knowns         "Knowns";
    input output BVariable.VariablePointers initials       "Initial unknowns";
    input output BVariable.VariablePointers states         "States";
    input output BVariable.VariablePointers derivatives    "State derivatives (der(x) -> $DER.x)";
    input output BVariable.VariablePointers algebraics     "Algebraic variables";
    input list<Pointer<Variable>> acc_states;
    input list<Pointer<Variable>> acc_derivatives;
  algorithm
    // Add the new derivatives to variables, unknowns and derivative pointer arrays
    variables := BVariable.VariablePointers.addList(acc_derivatives, variables);
    unknowns := BVariable.VariablePointers.addList(acc_derivatives, unknowns);
    initials := BVariable.VariablePointers.addList(acc_derivatives, initials);
    derivatives := BVariable.VariablePointers.addList(acc_derivatives, derivatives);

    // add states to knowns and state pointer array
    states := BVariable.VariablePointers.addList(acc_states, states);

    // remove states from unknowns and algebraics
    unknowns := BVariable.VariablePointers.removeList(acc_states, unknowns);
    algebraics := BVariable.VariablePointers.removeList(acc_states, algebraics);
  end updateStatesAndDerivatives;

  function collectDiscreteStatesAndPrevious
    "Collects all discrete states and creates a previous variable for each. Only to be used on discrete equations!"
    input output Expression exp;
    input Pointer<list<Pointer<Variable>>> acc_discrete_states;
    input Pointer<list<Pointer<Variable>>> acc_previous;
  algorithm
    exp := match exp
      local
        ComponentRef state_cref, pre_cref;
        Pointer<Variable> state_var, pre_var;
      // ToDo need Call.TYPED_REDUCTION?
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "pre")),
        arguments = {Expression.CREF(cref = state_cref)}))
        algorithm
          state_var := BVariable.getVarPointer(state_cref);
          if BVariable.isDiscreteState(state_var) then
            // this previous was already created -> the variable should already have a pointer to its previous variable
            pre_cref := BVariable.getPreCref(state_cref);
          else
            (pre_cref, pre_var) := BVariable.makePreVar(state_cref);
            state_var := BVariable.makeDiscreteStateVar(state_var, pre_var);
            Pointer.update(acc_discrete_states, state_var :: Pointer.access(acc_discrete_states));
            Pointer.update(acc_previous, pre_var :: Pointer.access(acc_previous));
          end if;
      then Expression.fromCref(pre_cref);
      // ToDo! General expressions inside pre call!
      // ToDo! edge and change replacement!
      else exp;
    end match;
  end collectDiscreteStatesAndPrevious;


  function updateDiscreteStatesAndPrevious
    "Updates the variable pointer arrays with the new information about states and derivatives."
    input output BVariable.VariablePointers variables       "All variables";
    input output BVariable.VariablePointers knowns          "Knowns";
    input output BVariable.VariablePointers initials        "initial unknowns";
    input output BVariable.VariablePointers discretes       "Discrete variables";
    input output BVariable.VariablePointers previous        "Previous (left limit) variables";
    input list<Pointer<Variable>> acc_discrete_states;
    input list<Pointer<Variable>> acc_previous;
  algorithm
    // Add the new derivatives to variables, unknowns and derivative pointer arrays
    variables := BVariable.VariablePointers.addList(acc_previous, variables);
    knowns := BVariable.VariablePointers.addList(acc_previous, knowns);
    initials := BVariable.VariablePointers.addList(acc_previous, initials);
    previous := BVariable.VariablePointers.addList(acc_previous, previous);
  end updateDiscreteStatesAndPrevious;
  annotation(__OpenModelica_Interface="backend");
end NBDetectStates;

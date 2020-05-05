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
  import Call = NFCall.Call;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Function = NFFunction;
  import InstNode = NFInstNode.InstNode;
  import Variable = NFVariable;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;

  // Util imports
  import Error;
  import NHashTable;

/* =========================================================================
                      MAIN ROUTINE, PLEASE DO NOT CHANGE
========================================================================= */
public
  function main
    "Wrapper function for any detect states function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.moduleWrapper;
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
   BVariable.VariablePointers unknowns       "Unknowns";
   BVariable.VariablePointers knowns         "Knowns";
   BVariable.VariablePointers states         "States";
   BVariable.VariablePointers derivatives    "State derivatives (der(x) -> $DER.x)";
   BVariable.VariablePointers algebraics     "Algebraic variables";
   BVariable.VariablePointers discretes      "Discrete variables";
   BVariable.VariablePointers previous       "Previous discrete variables (pre(d) -> $PRE.d)";
   BVariable.VariablePointers auxiliaries, aliasVars, parameters, constants     "(only to reconstruct VAR_DATA_SIM)";

  algorithm
    BVariable.VAR_DATA_SIM(variables = variables, unknowns = unknowns, knowns = knowns, auxiliaries = auxiliaries, aliasVars = aliasVars, states = states, derivatives = derivatives, algebraics = algebraics, discretes = discretes, previous = previous, parameters = parameters, constants = constants) := varData;
    BEquation.EQ_DATA_SIM(equations = equations) := eqData;
    (variables, equations, unknowns, knowns, states, derivatives, algebraics) := continuousFunc(variables, equations, unknowns, knowns, states, derivatives, algebraics);
    (variables, equations, discretes, previous) := discreteFunc(variables, equations, discretes, previous);
    varData := BVariable.VAR_DATA_SIM(variables, unknowns, knowns, states, auxiliaries, aliasVars, derivatives, algebraics, discretes, previous, parameters, constants);
    eqData := BEquation.EqData.setEquations(eqData, equations);
  end detectStatesDefault;

  function detectContinuousStatesDefault extends Module.detectContinuousStatesInterface;
  protected
    Pointer<list<Pointer<Variable>>> acc_states = Pointer.create({});
    Pointer<list<Pointer<Variable>>> acc_derivatives = Pointer.create({});
    Pointer<NHashTable.HashTable> hashTable = Pointer.create(NHashTable.emptyHashTable());
  algorithm
    BEquation.EquationPointers.mapExp(equations, function collectStateCrefs(acc_states = acc_states, acc_derivatives = acc_derivatives, hashTable = hashTable));
    (variables, unknowns, knowns, states, derivatives, algebraics) := updateStatesAndDerivatives(variables, unknowns, knowns, states, derivatives, algebraics, Pointer.access(acc_states), Pointer.access(acc_derivatives));
  end detectContinuousStatesDefault;

  function detectDiscreteStatesDefault extends Module.detectDiscreteStatesInterface;
  end detectDiscreteStatesDefault;

  function collectStateCrefs
    input output Expression exp;
    input Pointer<list<Pointer<Variable>>> acc_states;
    input Pointer<list<Pointer<Variable>>> acc_derivatives;
    input Pointer<NHashTable.HashTable> hashTable;
  algorithm
    exp := match exp
      local
        ComponentRef state_cref, der_cref;
        NHashTable.HashTable ht;
        Pointer<Variable> state_var, der_var;
      // ToDo need Call.TYPED_REDUCTION?
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "der")),
        arguments = {Expression.CREF(cref = state_cref)}))
        algorithm

          ht := Pointer.access(hashTable);
          if not BaseHashTable.hasKey(state_cref, ht) then
            state_var := BVariable.getVarPointer(state_cref);
            (der_cref, der_var) := makeDerVar(state_cref);
            state_var := makeStateVar(state_var, der_var);
            Pointer.update(acc_states, state_var :: Pointer.access(acc_states));
            Pointer.update(acc_derivatives, der_var :: Pointer.access(acc_derivatives));
            Pointer.update(hashTable, BaseHashTable.add((state_cref, 0), ht));
          else
            // this derivative was already created -> the variable should already have a pointer to its derivative
            der_cref := getDerVar(state_cref);
          end if;
      then Expression.fromCref(der_cref);
      // ToDo! General expressions inside call! -> ticket #5934

      else exp;
    end match;
  end collectStateCrefs;

  function makeStateVar
    input output Pointer<Variable> varPointer;
    input Pointer<Variable> derivative;
  protected
    Variable var;
  algorithm
    var := Pointer.access(varPointer);
    var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.STATE(1, SOME(derivative), true));
    Pointer.update(varPointer, var);
  end makeStateVar;

  function makeDerVar
    input output ComponentRef cref;
    output Pointer<Variable> var_ptr;
  algorithm
    _ := match ComponentRef.node(cref)
      local
        InstNode qual;
        Pointer<Variable> state;
        Variable var;
      case qual as InstNode.VAR_NODE()
        algorithm
          state := BVariable.getVarPointer(cref);
          qual.name := NBVariable.DERIVATIVE_STR;
          cref := ComponentRef.append(cref, ComponentRef.fromNode(qual, ComponentRef.nodeType(cref)));
          var := BVariable.fromCref(cref);
          var.backendinfo := BackendExtension.BackendInfo.setVarKind(var.backendinfo, BackendExtension.STATE_DER(state));
          var_ptr := Pointer.create(var);
          cref := BackendDAE.lowerComponentReferenceInstNode(cref, var_ptr);
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBDetectStates.makeDerCref failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
  end makeDerVar;

  function getDerVar
    input output ComponentRef cref;
  algorithm
    cref := match cref
      local
        Pointer<Variable> state, derivative;
        Variable derVar;
      case ComponentRef.CREF(node = InstNode.VAR_NODE(varPointer = state)) then match Pointer.access(state)
        case Variable.VARIABLE(backendinfo = BackendExtension.BACKEND_INFO(varKind = BackendExtension.STATE(derivative = SOME(derivative))))
          algorithm
            derVar := Pointer.access(derivative);
        then derVar.name;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{"NBDetectStates.getDerVar failed for " + ComponentRef.toString(cref) + " because of wrong variable kind."});
        then fail();
      end match;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBDetectStates.getDerVar failed for " + ComponentRef.toString(cref) + " because of wrong InstNode type."});
      then fail();
    end match;
  end getDerVar;

  function updateStatesAndDerivatives
    input output BVariable.VariablePointers variables      "All variables";
    input output BVariable.VariablePointers unknowns       "Unknowns";
    input output BVariable.VariablePointers knowns         "Knowns";
    input output BVariable.VariablePointers states         "States";
    input output BVariable.VariablePointers derivatives    "State derivatives (der(x) -> $DER.x)";
    input output BVariable.VariablePointers algebraics     "Algebraic variables";
    input list<Pointer<Variable>> acc_states;
    input list<Pointer<Variable>> acc_derivatives;
  algorithm
    // Add the new derivatives to variables, unknowns and derivative pointer arrays
    variables := List.fold(acc_derivatives, function BVariable.VariablePointers.addVar(), variables);
    unknowns := List.fold(acc_derivatives, function BVariable.VariablePointers.addVar(), unknowns);
    derivatives := List.fold(acc_derivatives, function BVariable.VariablePointers.addVar(), derivatives);

    // add states to knowns and state pointer array
    knowns := List.fold(acc_states, function BVariable.VariablePointers.addVar(), knowns);
    states := List.fold(acc_states, function BVariable.VariablePointers.addVar(), states);

    // remove states from unknowns and algebraics
    unknowns := List.fold(acc_states, function BVariable.VariablePointers.removeVar(), unknowns);
    algebraics := List.fold(acc_states, function BVariable.VariablePointers.removeVar(), algebraics);
  end updateStatesAndDerivatives;

  annotation(__OpenModelica_Interface="backend");
end NBDetectStates;

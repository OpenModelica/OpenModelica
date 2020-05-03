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
  import Call = NFCall.Call;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Function = NFFunction;
  import InstNode = NFInstNode.InstNode;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;

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
        BVariable.VariablePointers states         "States";
        BVariable.VariablePointers derivatives    "State derivatives (der(x) -> $DER.x)";
        BVariable.VariablePointers algebraics     "Algebraic variables";
        BVariable.VariablePointers discretes      "Discrete variables";
        BVariable.VariablePointers previous       "Previous discrete variables (pre(d) -> $PRE.d)";
        BEquation.Equations equations             "System equations";
      case BackendDAE.BDAE(varData = BVariable.VAR_DATA_SIM(states = states, derivatives = derivatives,
                algebraics = algebraics, discretes = discretes, previous = previous),
                eqData = BEquation.EQ_DATA_SIM(equations = equations))
        algorithm
          equations := mainFunc(states, derivatives, algebraics, discretes, previous, equations, contFunc, discFunc);
          bdae.eqData := BEquation.EqData.setEquations(bdae.eqData, equations);
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
  algorithm
    equations := continuousFunc(states, derivatives, algebraics, equations);
    equations := discreteFunc(discretes, previous, equations);
  end detectStatesDefault;

  function detectContinuousStatesDefault extends Module.detectContinuousStatesInterface;
  algorithm
    equations := BEquation.Equations.mapExp(equations, function replaceDerOperatorExp(states = states, derivatives = derivatives, algebraics = algebraics));
  end detectContinuousStatesDefault;

  function detectDiscreteStatesDefault extends Module.detectDiscreteStatesInterface;
  end detectDiscreteStatesDefault;

  function replaceDerOperatorExp
    input output Expression exp;
    input BVariable.VariablePointers states;
    input BVariable.VariablePointers derivatives;
    input BVariable.VariablePointers algebraics;
  algorithm
    exp := match exp
      local
        ComponentRef cref;
      // ToDo need TYPED_REDUCTION?
      // ToDo check if already found HT? smart check with existing arrays?
      case Expression.CALL(call = Call.TYPED_CALL(fn = Function.FUNCTION(path = Absyn.IDENT(name = "der")),
        arguments = {Expression.CREF(cref = cref)}))
        algorithm
          print("Expression derivative found: " + Expression.toString(exp) + "\n");
        //  cref := makeDerCref(cref);
      then exp;
      else exp;
    end match;
  end replaceDerOperatorExp;

  function makeDerCref
    input output ComponentRef cref;
  protected
    InstNode node;
  algorithm
    node := match ComponentRef.node(cref)
      local
        InstNode qual;
      case qual as InstNode.VAR_NODE()
        algorithm
          qual.name := NBVariable.DERIVATIVE_STR + "_" + qual.name;
      then qual;
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"NBDetectStates.makeDerCref failed for " + ComponentRef.toString(cref)});
      then fail();
    end match;
    cref := ComponentRef.fromNode(node, ComponentRef.nodeType(cref));

    print("Expression derivative created: " + ComponentRef.toString(cref) + "\n");
  end makeDerCref;

  annotation(__OpenModelica_Interface="backend");
end NBDetectStates;

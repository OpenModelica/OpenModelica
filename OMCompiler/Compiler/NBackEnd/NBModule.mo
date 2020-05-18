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
encapsulated package NBModule
" file:         NBModule.mo
  package:      NBModule
  description:  This file contains all functions and structures regarding
                generic backend modules and interfaces.
"
public
  import BackendDAE = NBackendDAE;

protected
  // NF imports
  import NFFlatten.FunctionTree;

  // Backend imports
  import BEquation = NBEquation;
  import Jacobian = NBackendDAE;
  import BVariable = NBVariable;
  import System = NBSystem;

public
  partial function wrapper
    input output BackendDAE bdae;
  end wrapper;

// =========================================================================
//                         MANDATORY PRE-OPT MODULES
// =========================================================================

//                               DETECT STATES
// *************************************************************************
  partial function detectStatesInterface
    "DetectStates
     This function is only allowed to read and change equations, change algebraic
     variables to states and create state derivatives. It also detects der() and
     pre() calls and replaces them with $DER and $PRE.
     Sub-Modules:
      - DetectContinuousStates
      - DetectDiscreteStates"
    input output BVariable.VarData varData                "Data containing variable pointers";
    input output BEquation.EqData eqData                  "Data containing equation pointers";
    input detectContinuousStatesInterface continuousFunc  "Subroutine for continous states";
    input detectDiscreteStatesInterface discreteFunc      "Subroutine for discrete states";
  end detectStatesInterface;

  partial function detectContinuousStatesInterface
    "DetectContinuousStates
     This function is only allowed to read and change equations, change algebraic
     variables to states and create state derivatives."
    input output BVariable.VariablePointers variables     "All variables";
    input output BEquation.EquationPointers equations     "System equations";
    input output BVariable.VariablePointers unknowns      "Unknowns";
    input output BVariable.VariablePointers knowns        "Knowns";
    input output BVariable.VariablePointers initials      "Initial unknowns";
    input output BVariable.VariablePointers states        "States";
    input output BVariable.VariablePointers derivatives   "State derivatives (der(x) -> $DER.x)";
    input output BVariable.VariablePointers algebraics    "Algebraic variables";
  end detectContinuousStatesInterface;

  partial function detectDiscreteStatesInterface
    "DetectDiscreteStates
     This function is only allowed to read and change equations, change algebraic
     variables to discrete and create previous discrete variables."
    input output BVariable.VariablePointers variables     "All variables";
    input output BEquation.EquationPointers equations     "ONLY Discrete equations!";
    input output BVariable.VariablePointers knowns        "Knowns";
    input output BVariable.VariablePointers initials      "Initial unknowns";
    input output BVariable.VariablePointers discretes     "Discrete variables";
    input output BVariable.VariablePointers previous      "Previous discrete variables (pre(d) -> $PRE.d)";
  end detectDiscreteStatesInterface;

//                               PARTITIONING
// *************************************************************************
  partial function partitioningInterface
    "Partitioning
     This function is only allowed to create systems of specialized SystemType
     by creating an adjacency matrix using provided variables and equations."
    input System.SystemType systemType;
    input BVariable.VariablePointers variables;
    input BEquation.EquationPointers equations;
    output list<System.System> systems;
  end partitioningInterface;

//                               JACOBIAN
// *************************************************************************
  partial function jacobianInterface
    "The jacobian is only allowed to read the variables and equations of current
    system and additionally the global known variables. It needs a unique name
    and is allowed to manipulate the function tree.
    [!] This function can not only be used as an optimization module but also for
    nonlinear systems, state sets, linearization and dynamic optimization."
    input String name                           "Name of jacobian";
    input BVariable.VariablePointers unknowns   "Variable array of unknowns";
    input BEquation.EquationPointers equations  "Equations array";
    input BVariable.VariablePointers knowns     "Variable array of knowns";
    output Option<Jacobian> jacobian            "Resulting jacobian";
    input output FunctionTree funcTree          "Function call bodies";
  end jacobianInterface;

  annotation(__OpenModelica_Interface="backend");
end NBModule;

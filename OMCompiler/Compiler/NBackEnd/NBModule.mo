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

protected
  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;

public
  partial function moduleWrapper
    input output BackendDAE bdae;
  end moduleWrapper;

/* =========================================================================
                        MANDATORY PRE-OPT MODULES
========================================================================= */
  partial function detectStatesInterface
    "DetectStates
     This function is only allowed to read and change equations, change algebraic
     variables to states and create state derivatives. It also detects der() and
     pre() calls and replaces them with $DER and $PRE. No return value for
     variables since all arrays are arrays of pointers.
     Sub-Modules:
      - DetectContinuousStates
      - DetectDiscreteStates"
    input BVariable.VariablePointers states               "States";
    input BVariable.VariablePointers derivatives          "State derivatives (der(x) -> $DER.x)";
    input BVariable.VariablePointers algebraics           "Algebraic variables";
    input BVariable.VariablePointers discretes            "Discrete variables";
    input BVariable.VariablePointers previous             "Previous discrete variables (pre(d) -> $PRE.d)";
    input output BEquation.Equations equations            "System equations";
    input detectContinuousStatesInterface continuousFunc  "Subroutine for continous states";
    input detectDiscreteStatesInterface discreteFunc      "Subroutine for discrete states";
  end detectStatesInterface;

  partial function detectContinuousStatesInterface
    "DetectContinuousStates
     This function is only allowed to read and change equations, change algebraic
     variables to states and create state derivatives. No return values for
     variables since all arrays are arrays of pointers."
    input BVariable.VariablePointers states         "States";
    input BVariable.VariablePointers derivatives    "State derivatives (der(x) -> $DER.x)";
    input BVariable.VariablePointers algebraics     "Algebraic variables";
    input output BEquation.Equations equations      "System equations";
  end detectContinuousStatesInterface;

  partial function detectDiscreteStatesInterface
    "DetectDiscreteStates
     This function is only allowed to read and change equations, change algebraic
     variables to discrete and create previous discrete variables. No return value
     for variables since all arrays are arrays of pointers."
    input BVariable.VariablePointers discretes      "Discrete variables";
    input BVariable.VariablePointers previous       "Previous discrete variables (pre(d) -> $PRE.d)";
    input output BEquation.Equations equations      "System equations";
  end detectDiscreteStatesInterface;

  annotation(__OpenModelica_Interface="backend");
end NBModule;

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package SimCodeVar
" file:        SimCodeVar.mo
  package:     SimCodeVar
  description: Package to store simcode variables. Moved out of SimCodeUtil to break circular dependency with HpcOmSimCode.

"

// public imports
public import BackendDAE;
public import DAE;

uniontype SimVars "Container for metadata about variables in a Modelica model."
  record SIMVARS
    list<SimVar> stateVars;
    list<SimVar> derivativeVars;
    list<SimVar> algVars;
    list<SimVar> discreteAlgVars;
    list<SimVar> intAlgVars;
    list<SimVar> boolAlgVars;
    list<SimVar> inputVars;
    list<SimVar> outputVars;
    list<SimVar> aliasVars;
    list<SimVar> intAliasVars;
    list<SimVar> boolAliasVars;
    list<SimVar> paramVars;
    list<SimVar> intParamVars;
    list<SimVar> boolParamVars;
    list<SimVar> stringAlgVars;
    list<SimVar> stringParamVars;
    list<SimVar> stringAliasVars;
    list<SimVar> extObjVars;
    list<SimVar> constVars;
    list<SimVar> intConstVars;
    list<SimVar> boolConstVars;
    list<SimVar> stringConstVars;
    list<SimVar> jacobianVars;
    list<SimVar> seedVars;
    list<SimVar> realOptimizeConstraintsVars;
    list<SimVar> realOptimizeFinalConstraintsVars;
    list<SimVar> sensitivityVars; // variable used to calculate sensitivities for parameters nSensitivitityParameters + nRealParam*nStates
  end SIMVARS;
end SimVars;

public constant SimVars emptySimVars = SIMVARS({}, {}, {}, {}, {}, {}, {}, {},
  {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {});

public uniontype SimVar "Information about a variable in a Modelica model."
  record SIMVAR
    DAE.ComponentRef name;
    BackendDAE.VarKind varKind;
    String comment;
    String unit;
    String displayUnit;
    Integer index;
    Option<DAE.Exp> minValue;
    Option<DAE.Exp> maxValue;
    Option<DAE.Exp> initialValue;
    Option<DAE.Exp> nominalValue;
    Boolean isFixed;
    DAE.Type type_;
    Boolean isDiscrete;
    // arrayCref is the name of the array if this variable is the first in that
    // array
    Option<DAE.ComponentRef> arrayCref;
    AliasVariable aliasvar;
    DAE.ElementSource source;
    Causality causality;
    Option<Integer> variable_index;
    list<String> numArrayElement;
    Boolean isValueChangeable;
    Boolean isProtected;
    Boolean hideResult;
    Option<array<Integer>> inputIndex;
  end SIMVAR;
end SimVar;

uniontype AliasVariable
  record NOALIAS end NOALIAS;
  record ALIAS
    DAE.ComponentRef varName;
  end ALIAS;
  record NEGATEDALIAS
    DAE.ComponentRef varName;
  end NEGATEDALIAS;
end AliasVariable;

uniontype Causality
  record NONECAUS end NONECAUS;
  record INTERNAL end INTERNAL;
  record OUTPUT end OUTPUT;
  record INPUT end INPUT;
end Causality;

annotation(__OpenModelica_Interface="backend");
end SimCodeVar;

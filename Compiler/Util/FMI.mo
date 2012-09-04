/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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
 
 encapsulated package FMI
" file:         FMI.mo
  package:     FMI
  description: This file contains FMI's import specific function, which are implemented in C."

uniontype FmiImport
  record FMIIMPORT
    Integer fmiContext;
    Integer fmiInstance;
    String fmiModelIdentifier;
    String fmiDescription;
    Real fmiExperimentStartTime;
    Real fmiExperimentStopTime;
    Real fmiExperimentTolerance;
    Integer fmiModelVariablesInstance;
    list<Integer> fmiModelVariablesList;
  end FMIIMPORT;
end FmiImport;

public function initializeFMIImport
  input String inFileName;
  input String inWorkingDirectory;
  input Integer inFMILogLevel;
  output Boolean result;
  output Integer outFMIContext;
  output Integer outFMIInstance;
  output String outModelIdentifier;
  output String outDescription;
  output Real outExperimentStartTime;
  output Real outExperimentStopTime;
  output Real outExperimentTolerance;
  output Integer outModelVariablesInstance;
  output list<Integer> outModelVariablesList;
  external "C" result=FMIImpl__initializeFMIImport(inFileName, inWorkingDirectory, inFMILogLevel, outFMIContext, outFMIInstance, outModelIdentifier, outDescription,
  outExperimentStartTime, outExperimentStopTime, outExperimentTolerance,
  outModelVariablesInstance, outModelVariablesList) annotation(Library = {"omcruntime","fmilib"});
end initializeFMIImport;

public function releaseFMIImport
  input Integer inFMIModelVariablesInstance;
  input Integer inFMIInstance;
  input Integer inFMIContext;
  external "C" FMIImpl__releaseFMIImport(inFMIModelVariablesInstance, inFMIInstance, inFMIContext) annotation(Library = {"omcruntime","fmilib"});
end releaseFMIImport;

public function getFMIModelVariableVariability
  input Integer inFMIModelVariable;
  output String outFMIModelVariableVariability;
  external "C" outFMIModelVariableVariability=FMIImpl__getFMIModelVariableVariability(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIModelVariableVariability;

public function getFMIModelVariableCausality
  input Integer inFMIModelVariable;
  output String outFMIModelVariableCausality;
  external "C" outFMIModelVariableCausality=FMIImpl__getFMIModelVariableCausality(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIModelVariableCausality;

public function getFMIModelVariableBaseType
  input Integer inFMIModelVariable;
  output String outFMIModelVariableBaseType;
  external "C" outFMIModelVariableBaseType=FMIImpl__getFMIModelVariableBaseType(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIModelVariableBaseType;

public function getFMIModelVariableName
  input Integer inFMIModelVariable;
  output String outFMIModelVariableName;
  external "C" outFMIModelVariableName=FMIImpl__getFMIModelVariableName(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIModelVariableName;

public function getFMIModelVariableDescription
  input Integer inFMIModelVariable;
  output String outFMIModelVariableDescription;
  external "C" outFMIModelVariableDescription=FMIImpl__getFMIModelVariableDescription(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIModelVariableDescription;

public function getFMINumberOfContinuousStates
  input Integer inFMIInstance;
  output Integer outFMINumberOfContinuousStates;
  external "C" outFMINumberOfContinuousStates=FMIImpl__getFMINumberOfContinuousStates(inFMIInstance) annotation(Library = {"omcruntime","fmilib"});
end getFMINumberOfContinuousStates;

public function getFMINumberOfEventIndicators
  input Integer inFMIInstance;
  output Integer outFMINumberOfEventIndicators;
  external "C" outFMINumberOfEventIndicators=FMIImpl__getFMINumberOfEventIndicators(inFMIInstance) annotation(Library = {"omcruntime","fmilib"});
end getFMINumberOfEventIndicators;

public function getFMIModelVariableHasStart
  input Integer inFMIModelVariable;
  output Boolean outFMIModelVariableHasStart;
  external "C" outFMIModelVariableHasStart=FMIImpl__getFMIModelVariableHasStart(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIModelVariableHasStart;

public function getFMIModelVariableIsFixed
  input Integer inFMIModelVariable;
  output Boolean outFMIModelVariableHasFixed;
  external "C" outFMIModelVariableHasFixed=FMIImpl__getFMIModelVariableIsFixed(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIModelVariableIsFixed;

public function getFMIRealVariableStartValue
  input Integer inFMIModelVariable;
  output Real outFMIRealVariableStartValue;
  external "C" outFMIRealVariableStartValue=FMIImpl__getFMIRealVariableStartValue(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIRealVariableStartValue;

public function getFMIIntegerVariableStartValue
  input Integer inFMIModelVariable;
  output Integer outFMIIntegerVariableStartValue;
  external "C" outFMIIntegerVariableStartValue=FMIImpl__getFMIIntegerVariableStartValue(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIIntegerVariableStartValue;

public function getFMIBooleanVariableStartValue
  input Integer inFMIModelVariable;
  output Boolean outFMIBooleanVariableStartValue;
  external "C" outFMIBooleanVariableStartValue=FMIImpl__getFMIBooleanVariableStartValue(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIBooleanVariableStartValue;

public function getFMIStringVariableStartValue
  input Integer inFMIModelVariable;
  output String outFMIStringVariableStartValue;
  external "C" outFMIStringVariableStartValue=FMIImpl__getFMIStringVariableStartValue(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIStringVariableStartValue;

public function getFMIEnumerationVariableStartValue
  input Integer inFMIModelVariable;
  output Integer outFMIEnumerationVariableStartValue;
  external "C" outFMIEnumerationVariableStartValue=FMIImpl__getFMIEnumerationVariableStartValue(inFMIModelVariable) annotation(Library = {"omcruntime","fmilib"});
end getFMIEnumerationVariableStartValue;

end FMI;

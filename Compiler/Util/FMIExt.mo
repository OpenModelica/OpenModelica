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

encapsulated package FMIExt
" file:         FMI.mo
  package:     FMI
  description: This file contains FMI's import specific function, which are implemented in C."

public import FMI;

public function initializeFMIImport
  input String inFileName;
  input String inWorkingDirectory;
  input Integer inFMILogLevel;
  input Boolean inInputConnectors;
  input Boolean inOutputConnectors;
  input Boolean inIsModelDescriptionImport = false;
  output Boolean result;
  output Option<Integer> outFMIContext "Stores a pointer. If it is declared as Integer, it is truncated to 32-bit.";
  output Option<Integer> outFMIInstance "Stores a pointer. If it is declared as Integer, it is truncated to 32-bit.";
  output FMI.Info outFMIInfo;
  output list<FMI.TypeDefinitions> outTypeDefinitionsList;
  output FMI.ExperimentAnnotation outExperimentAnnotation;
  output Option<Integer> outModelVariablesInstance "Stores a pointer. If it is declared as Integer, it is truncated to 32-bit.";
  output list<FMI.ModelVariables> outModelVariablesList;
  external "C" result=FMIImpl__initializeFMIImport(inFileName, inWorkingDirectory, inFMILogLevel, inInputConnectors, inOutputConnectors, inIsModelDescriptionImport,
  outFMIContext, outFMIInstance, outFMIInfo, outTypeDefinitionsList, outExperimentAnnotation, outModelVariablesInstance, outModelVariablesList)
    annotation(Library = {"omcruntime","fmilib"});
end initializeFMIImport;

public function releaseFMIImport
  input Option<Integer> inFMIModelVariablesInstance "Stores a pointer. If it is declared as Integer, it is truncated to 32-bit.";
  input Option<Integer> inFMIInstance "Stores a pointer. If it is declared as Integer, it is truncated to 32-bit.";
  input Option<Integer> inFMIContext "Stores a pointer. If it is declared as Integer, it is truncated to 32-bit.";
  input String inFMIVersion;
  external "C" FMIImpl__releaseFMIImport(inFMIModelVariablesInstance, inFMIInstance, inFMIContext, inFMIVersion) annotation(Library = {"omcruntime","fmilib"});
end releaseFMIImport;

annotation(__OpenModelica_Interface="util");
end FMIExt;

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
  description: This file contains FMI specific function, which are implemented in C."

/*public function importFMU
  input String inFileName;
  input String inWorkingDirectory;
  output String outGeneratedFileName;
  external "C" outGeneratedFileName=FMIImpl__importFMU(inFileName, inWorkingDirectory) annotation(Library = {"omcruntime","fmilib"});
end importFMU;*/

public function initializeFMIContext
  input String inFileName;
  input String inWorkingDirectory;
  output Integer outFMIContext;
  external "C" outFMIContext=FMIImpl__initializeFMIContext(inFileName, inWorkingDirectory) annotation(Library = {"omcruntime","fmilib"});
end initializeFMIContext;

public function releaseFMIContext
  input Integer inFMIContext;
  external "C" FMIImpl__releaseFMIContext(inFMIContext) annotation(Library = {"omcruntime","fmilib"});
end releaseFMIContext;

public function initializeFMI
  input Integer inFMIContext;
  input String inWorkingDirectory;
  output Integer outFMI;
  external "C" outFMI=FMIImpl__initializeFMI(inFMIContext, inWorkingDirectory) annotation(Library = {"omcruntime","fmilib"});
end initializeFMI;

public function releaseFMI
  input Integer inFMI;
  external "C" FMIImpl__releaseFMI(inFMI) annotation(Library = {"omcruntime","fmilib"});
end releaseFMI;

public function getFMIModelIdentifier
  input Integer inFMI;
  output String outFMIModelIdentifier;
  external "C" outFMIModelIdentifier=FMIImpl__getFMIModelIdentifier(inFMI) annotation(Library = {"omcruntime","fmilib"});
end getFMIModelIdentifier;

public function getFMIDescription
  input Integer inFMI;
  output String outFMIDescription;
  external "C" outFMIDescription=FMIImpl__getFMIDescription(inFMI) annotation(Library = {"omcruntime","fmilib"});
end getFMIDescription;

public function getFMIDefaultExperimentStart
  input Integer inFMI;
  output Real outFMIDefaultExperimentStart;
  external "C" outFMIDefaultExperimentStart=FMIImpl__getFMIDefaultExperimentStart(inFMI) annotation(Library = {"omcruntime","fmilib"});
end getFMIDefaultExperimentStart;

public function getFMIDefaultExperimentStop
  input Integer inFMI;
  output Real outFMIDefaultExperimentStop;
  external "C" outFMIDefaultExperimentStop=FMIImpl__getFMIDefaultExperimentStop(inFMI) annotation(Library = {"omcruntime","fmilib"});
end getFMIDefaultExperimentStop;

public function getFMIDefaultExperimentTolerance
  input Integer inFMI;
  output Real outFMIDefaultExperimentTolerance;
  external "C" outFMIDefaultExperimentTolerance=FMIImpl__getFMIDefaultExperimentTolerance(inFMI) annotation(Library = {"omcruntime","fmilib"});
end getFMIDefaultExperimentTolerance;

end FMI;

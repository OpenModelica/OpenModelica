/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef FMI1COMMON__H_
#define FMI1COMMON__H_

#include "FMICommon.h"

/*
 * Structure used as an External Object in the generated Modelica code of the imported FMU.
 * Used for FMI 1.0 Model Exchange.
 */
typedef struct {
  int FMILogLevel;
  jm_callbacks JMCallbacks;
  fmi_import_context_t* FMIImportContext;
  fmi1_callback_functions_t FMICallbackFunctions;
  char* FMIWorkingDirectory;
  fmi1_import_t* FMIImportInstance;
  char* FMIInstanceName;
  int FMIDebugLogging;
  int FMIToleranceControlled;
  double FMIRelativeTolerance;
  fmi1_event_info_t* FMIEventInfo;
} FMI1ModelExchange;

/*
 * Structure used as an External Object in the generated Modelica code of the imported FMU.
 * Used for FMI 1.0 Co-Simulation.
 */
typedef struct {
  int FMILogLevel;
  jm_callbacks JMCallbacks;
  fmi_import_context_t* FMIImportContext;
  fmi1_callback_functions_t FMICallbackFunctions;
  char* FMIWorkingDirectory;
  fmi1_import_t* FMIImportInstance;
  char* FMIInstanceName;
  int FMIDebugLogging;
  char* FMIFmuLocation;
  char* FMIMimeType;
  double FMITimeOut;
  int FMIVisible;
  int FMIInteractive;
  double FMITStart;
  int FMIStopTimeDefined;
  double FMITStop;
} FMI1CoSimulation;

void fmi1logger(fmi1_component_t c, fmi1_string_t instanceName, fmi1_status_t status, fmi1_string_t category, fmi1_string_t message, ...);

#endif

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

#ifndef FMI2COMMON__H_
#define FMI2COMMON__H_

#include "FMICommon.h"

/*
 * type to separate the different solving stages.
 */
typedef enum {
  fmi2_instantiated_mode,
  fmi2_initialization_mode,
  fmi2_continuousTime_mode,
  fmi2_event_mode,
  fmi2_none_mode
} fmi2_solving_mode_t;

/*
 * Structure used as an External Object in the generated Modelica code of the imported FMU.
 * Used for FMI 2.0 Model Exchange.
 */
typedef struct {
  int FMILogLevel;
  jm_callbacks JMCallbacks;
  fmi_import_context_t* FMIImportContext;
  fmi2_callback_functions_t FMICallbackFunctions;
  char* FMIWorkingDirectory;
  fmi2_import_t* FMIImportInstance;
  char* FMIInstanceName;
  int FMIDebugLogging;
  int FMIToleranceControlled;
  double FMIRelativeTolerance;
  fmi2_event_info_t* FMIEventInfo;
  fmi2_solving_mode_t FMISolvingMode;
} FMI2ModelExchange;

void fmi2logger(fmi2_component_t c, fmi2_string_t instanceName, fmi2_status_t status, fmi2_string_t category, fmi2_string_t message, ...);

#endif

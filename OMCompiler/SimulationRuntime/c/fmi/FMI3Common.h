/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#ifndef FMI3COMMON__H_
#define FMI3COMMON__H_

#include "FMICommon.h"

/*
 * type to separate the different solving stages.
 */
typedef enum {
  fmi3_instantiated_mode,
  fmi3_initialization_mode,
  fmi3_continuousTime_mode,
  fmi3_event_mode,
  fmi3_none_mode
} fmi3_solving_mode_t;

/*
 * What fmi3UpdateDiscreteStates reports.
 *
 * FMI 2.0 had an fmi2_event_info_t that fmi2NewDiscreteStates filled in; FMI 3.0
 * returns the same information through out parameters instead, so the event state
 * of the run is kept here between the calls that produce it and the ones that read
 * it.
 */
typedef struct {
  fmi3_boolean_t discreteStatesNeedUpdate;
  fmi3_boolean_t terminateSimulation;
  fmi3_boolean_t nominalsOfContinuousStatesChanged;
  fmi3_boolean_t valuesOfContinuousStatesChanged;
  fmi3_boolean_t nextEventTimeDefined;
  fmi3_float64_t nextEventTime;
} fmi3_event_info_omc_t;

/*
 * Structure used as an External Object in the generated Modelica code of the imported FMU.
 * Used for FMI 3.0 Model Exchange.
 *
 * There is no fmi3_callback_functions_t to hold: FMI 3.0 passes an instance
 * environment and a single log callback to fmi3_import_create_dllfmu instead.
 */
typedef struct {
  int FMILogLevel;
  jm_callbacks JMCallbacks;
  fmi_import_context_t* FMIImportContext;
  char* FMIWorkingDirectory;
  fmi3_import_t* FMIImportInstance;
  char* FMIInstanceName;
  int FMIDebugLogging;
  int FMIToleranceControlled;
  double FMIRelativeTolerance;
  fmi3_event_info_omc_t FMIEventInfo;
  fmi3_solving_mode_t FMISolvingMode;
} FMI3ModelExchange;

void fmi3logger(fmi3_instance_environment_t instanceEnvironment, fmi3_status_t status, fmi3_string_t category, fmi3_string_t message);

#endif

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

#ifdef __cplusplus
extern "C" {
#endif

#include "fmilib.h"

/*
 * FMI version 1.0 Co-Simulation functions
 */

/*
 * Wrapper for the FMI function fmiInstantiateSlave.
 */
void fmi1InstantiateSlave_OMC(void* fmi, char* instanceName, char* fmuLocation, char* mimeType, double timeout, int visible, int interactive, int debugLogging)
{
  fmi1_import_instantiate_slave((fmi1_import_t*)fmi, instanceName, fmuLocation, mimeType, timeout, visible, interactive);
  fmi1_import_set_debug_logging((fmi1_import_t*)fmi, debugLogging);
}

/*
 * Wrapper for the FMI function fmiInitializeSlave.
 */
void fmi1InitializeSlave_OMC(void* fmi, double tStart, int stopTimeDefined, double tStop)
{
  fmi1_import_initialize_slave((fmi1_import_t*)fmi, tStart, stopTimeDefined, tStop);
}

/*
 * Wrapper for the FMI function fmiDoStep.
 * Return value is dummy and is only used to run the equations in sequence.
 */
double fmi1DoStep_OMC(void* fmi, double currentCommunicationPoint, double communicationStepSize, int newStep)
{
  fmi1_import_do_step((fmi1_import_t*)fmi, currentCommunicationPoint, communicationStepSize, newStep);
  return 0.0;
}

/*
 * Wrapper for the FMI function fmiTerminateSlave.
 */
int fmi1TerminateSlave_OMC(void* fmi)
{
  fmi1_status_t fmistatus = fmi1_import_terminate_slave((fmi1_import_t*)fmi);
  return fmistatus;
}

#ifdef __cplusplus
}
#endif

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurentYear, Open Source Modelica Consortium (OSMC),
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

#include "fmu2_model_interface.h"
#include "fmu_read_flags.h"
#include "../simulation/options.h"
#include "../util/simulation_options.h"
#include "../simulation/solver/cvode_solver.h"
#include "../util/omc_mmap.h"
#include "../util/omc_file.h"

/**
 * @ Skips to a given character or end of file
 *
 * @param  str
 * @param  c
 * @return
 */
static inline const char* skipTo(const char *str, char c)
{
  while(*str != c && *str != '\0')
    str++;
  return str;
}

/**
 * @ brief puts double quotes around a string
 *
 * @param  str
 * @return
 */
static inline char* quote(const char *str)
{
  char* tmp;
  const char* quot = "\"";
  tmp = (char*) malloc(sizeof(char) * 200);
  strcpy(tmp, quot);
  strcat(tmp, str);
  strcat(tmp, quot);
  return tmp;
}

/**
 * @brief parseses and sets the solver method string
 *
 * @param  solverInfo
 * @param  str        string that starts at solver method string
 * @return            input string skipped to endline
 */
static inline const char* setSolverMethod(SOLVER_INFO *solverInfo, const char *str)
{
  /* Variables */
  int i;
  int len;
  char* value;
  for(i=1; i<S_MAX; i++)
  {
    value = quote(SOLVER_METHOD_NAME[i]);
    if (strncmp(str, value, strlen(SOLVER_METHOD_NAME[i]) + 2) == 0)
    {
      solverInfo->solverMethod = i;
      break;
    }
  }
  return skipTo(str, '\n');
}

/**
 * @brief parses flags from resources/modelName_flags.json
 *
 * @param solverInfo
 * @param str           string read from file
 */
void parseFlags(SOLVER_INFO *solverInfo, const char *str)
{
  /* Variables */
  int i, k;
  const int k_max = 1000;
  char* value;

  str = skipTo(str, '\"');
  k = 0;
  while(*str != '\0' && k < k_max)
  {
    k++;
    for(i=1; i<FMU_FLAG_MAX; i++)
    {
      // map the fmu flags to regular flags
      value = quote(FLAG_NAME[FMU_FLAG_MAP[i]]);
      if (strncmp(str, value, strlen(FLAG_NAME[FMU_FLAG_MAP[i]]) + 2) == 0)
      {
        str = skipTo(str, ':');
        str = skipTo(str, '\"');

        switch(i) {
          case FMU_FLAG_SOLVER: str = setSolverMethod(solverInfo, str); break;
          default: str = skipTo(str, '\n'); break;
        }
      }
    }
    str = skipTo(str, '\"');
   }
}

/**
 * @brief Initialize solver data.
 *
 * Reads optional FMU simulation flags from <fmiPrefix>.fmu/resources/<fmiPrefix>_flags.json.
 * Initialize solver euler or CVODE.
 *
 * @param comp          FMU component.
 * @return int          Return 0 on success and -1 when an error occured.
 */
int FMI2CS_initializeSolverData(ModelInstance* comp)
{
  /* Variables */
  const fmi2CallbackFunctions* functions;
  DATA* data;
  threadData_t* threadData;
  SOLVER_INFO* solverInfo;

  CVODE_SOLVER* cvodeData;
  int retValue;

  functions = comp->functions;
  data = comp->fmuData;
  threadData = comp->threadData;

  /* Allocate memory */
  solverInfo = (SOLVER_INFO*) functions->allocateMemory(1, sizeof(SOLVER_INFO));

  /* Initialize solverInfo */
  solverInfo->currentTime = 0;
  solverInfo->currentStepSize = 0;
  solverInfo->laststep = 0;
  solverInfo->solverMethod = 0;
  solverInfo->solverRootFinding = 0;
  solverInfo->solverNoEquidistantGrid = 0;
  solverInfo->lastdesiredStep = solverInfo->currentTime + solverInfo->currentStepSize;
  solverInfo->eventLst = NULL;
  solverInfo->didEventStep = 0;
  solverInfo->stateEvents = 0;
  solverInfo->sampleEvents = 0;
  solverInfo->solverStats = NULL;
  solverInfo->solverStatsTmp = NULL;

  /* read fmu flags from flags.json */
  char* flags_filename = functions->allocateMemory(strlen(comp->fmuData->modelData->resourcesDir) + strlen(comp->fmuData->modelData->modelFilePrefix) + 20, sizeof(char));
  flags_filename[0] = 0;
  strcat(flags_filename, comp->fmuData->modelData->resourcesDir);
  strcat(flags_filename, "/");
  strcat(flags_filename, comp->fmuData->modelData->modelFilePrefix);
  strcat(flags_filename, "_flags.json");
  FILTERED_LOG(comp, fmi2OK, LOG_ALL, "fmi2Instantiate: Trying to find simulation settings %s.", flags_filename)

  if( omc_file_exists( flags_filename) )
  {
    FILTERED_LOG(comp, fmi2OK, LOG_ALL, "fmi2Instantiate: Found simulation settings %s.", flags_filename)
    omc_mmap_read mmap_reader = {0};
    mmap_reader = omc_mmap_open_read(flags_filename);
    parseFlags(solverInfo, mmap_reader.data);
    omc_mmap_close_read(mmap_reader);
  }
  else
  {
    FILTERED_LOG(comp, fmi2OK, LOG_ALL, "fmi2Instantiate: Using default simulation settings.")
    solverInfo->solverMethod = S_EULER;
  }

  /* If no states are present, we can use Euler's method since it is doing nothing. */
  if (data->modelData->nStates < 1)
  {
    FILTERED_LOG(comp, fmi2OK, LOG_ALL, "fmi2Instantiate: No states present, continuing without ODE solver.")
    solverInfo->solverMethod = S_EULER;
  }

  switch (solverInfo->solverMethod)
  {
    case S_EULER:
      /* Needs no initialization */
      retValue = 0;
      break;
    case S_CVODE:
      useStream[LOG_SOLVER] = 1;
      cvodeData = NULL;
      FILTERED_LOG(comp, fmi2OK, LOG_ALL, "Initializing CVODE ODE Solver")
      cvodeData = (CVODE_SOLVER*) functions->allocateMemory(1, sizeof(CVODE_SOLVER));
      if (!cvodeData) {
        FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "fmi2Instantiate: Out of memory.")
      }
      retValue = cvode_solver_initial(data, threadData, solverInfo, cvodeData, 1 /* is FMI */);   /* TODO: cvode_solver_initial needs to use malloc and free from fmi2CallbackFunctions */
      solverInfo->solverData = cvodeData;
      useStream[LOG_SOLVER] = 0;
      break;
    default:
      FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "fmi2Instantiate: Unknown solver method.")
      retValue = -1;
  }

  functions->freeMemory(flags_filename);

  comp->solverInfo = solverInfo;

  return retValue;
}

/**
 * @brief Deinitlaize solver data.
 *
 * Use for solver data allocated with FMI2CS_initializeSolverData.
 * Frees everything inside comp->solverInfo.
 *
 * @param comp          FMU component.
 * @return int          Return 0 on success and -1 else.
 */
int FMI2CS_deInitializeSolverData(ModelInstance* comp)
{
  /* Variables */
  DATA* data;
  threadData_t* threadData;
  SOLVER_INFO* solverInfo;
  const fmi2CallbackFunctions* functions;
  int retValue;

  functions = comp->functions;
  data = comp->fmuData;
  threadData = comp->threadData;
  solverInfo = comp->solverInfo;

  /* Log function call */
  FILTERED_LOG(comp, fmi2OK, LOG_ALL, "fmi2FreeInstance: Freeing solver data.")

  switch (solverInfo->solverMethod)
  {
    case S_EULER:
      /* Needs no freeing */
      retValue = 0;
      break;
    case S_CVODE:
      retValue = cvode_solver_deinitial(solverInfo->solverData);
      break;
    default:
      FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "fmi2FreeInstance: Unknown solver method.")
      retValue = -1;
  }

  comp->functions->freeMemory(comp->solverInfo); comp->solverInfo = NULL;

  return retValue;
}

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*! \file mixedSystem.c
 */

#include <math.h>

#include "../../util/omc_error.h"
#include "mixedSystem.h"
#include "mixedSearchSolver.h"
#include "../simulation_info_json.h"

/*! \fn int initializeMixedSystems(DATA *data)
 *
 *  This function allocates memory for all mixed systems.
 *
 *  \param [ref] [data]
 */
int initializeMixedSystems(DATA *data, threadData_t *threadData)
{
  int i;
  int size;
  MIXED_SYSTEM_DATA *system = data->simulationInfo->mixedSystemData;

  infoStreamPrint(LOG_NLS, 1, "initialize mixed system solvers");
  infoStreamPrint(LOG_NLS, 0, "%ld mixed systems", data->modelData->nMixedSystems);

  for(i=0; i<data->modelData->nMixedSystems; ++i)
  {
    size = system[i].size;

    system[i].iterationVarsPtr = (modelica_boolean**) malloc(size*sizeof(modelica_boolean*));
    system[i].iterationPreVarsPtr = (modelica_boolean**) malloc(size*sizeof(modelica_boolean*));

    /* allocate solver data */
    switch(data->simulationInfo->mixedMethod)
    {
    case MIXED_SEARCH:
      allocateMixedSearchData(size, &system[i].solverData);
      break;
    default:
      throwStreamPrint(threadData, "unrecognized mixed solver");
    }
  }

  messageClose(LOG_NLS);
  return 0;
}

/*! \fn freeMixedSystems
 *
 *  Thi function frees memory of mixed systems.
 *
 *  \param [ref] [data]
 */
int freeMixedSystems(DATA *data, threadData_t *threadData)
{
  int i;
  MIXED_SYSTEM_DATA* system = data->simulationInfo->mixedSystemData;

  infoStreamPrint(LOG_NLS, 1, "free mixed system solvers");

  for(i=0;i<data->modelData->nMixedSystems;++i)
  {

    free(system[i].iterationVarsPtr);
    free(system[i].iterationPreVarsPtr);

    /* allocate solver data */
    switch(data->simulationInfo->mixedMethod)
    {
    case MIXED_SEARCH:
      freeMixedSearchData(&system[i].solverData);
      break;
    default:
      throwStreamPrint(threadData, "unrecognized mixed solver");
    }

    free(system[i].solverData);
  }

  messageClose(LOG_NLS);
  return 0;
}

/*! \fn solve mixed systems
 *
 *  \param [in]  [data]
 *                [sysNumber] index of corresponding mixed System
 *
 *  \author wbraun
 */
int solve_mixed_system(DATA *data, threadData_t *threadData, int sysNumber)
{
  int success;
  MIXED_SYSTEM_DATA* system = data->simulationInfo->mixedSystemData;

  /* for now just use lapack solver as before */
  switch(data->simulationInfo->mixedMethod)
  {
  case MIXED_SEARCH:
    success = solveMixedSearch(data, sysNumber);
    break;
  default:
    throwStreamPrint(threadData, "unrecognized mixed solver");
  }
  system[sysNumber].solved = success;

  return 0;
}

/*! \fn check_mixed_solutions
 *   This function checks whether some of the mixed systems
 *   are failed to solve. If one is failed it returns 1 otherwise 0.
 *
 *  \param [in]  [data]
 *  \param [in]  [printFailingSystems]
 *
 *  \author wbraun
 */
int check_mixed_solutions(DATA *data, int printFailingSystems)
{
  MIXED_SYSTEM_DATA* system = data->simulationInfo->mixedSystemData;
  int i, j, retVal=0;

  for(i=0; i<data->modelData->nMixedSystems; ++i)
    if(system[i].solved == 0)
    {
      retVal = 1;
      if(printFailingSystems && ACTIVE_WARNING_STREAM(LOG_NLS))
      {
        warningStreamPrint(LOG_NLS, 1, "mixed system fails: %d at t=%g", modelInfoGetEquation(&data->modelData->modelDataXml, system->equationIndex).id, data->localData[0]->timeValue);
        messageClose(LOG_NLS);
      }
    }

  return retVal;
}

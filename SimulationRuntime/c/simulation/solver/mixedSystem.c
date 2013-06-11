/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file mixedSystem.c
 */

#include <math.h>

#include "omc_error.h"
#include "mixedSystem.h"
#include "mixedSearchSolver.h"
#include "simulation_info_xml.h"

/*! \fn int allocatemixedSystem(DATA *data)
 *
 *  This function allocates memory for all mixed systems.
 *
 *  \param [ref] [data]
 */
int allocatemixedSystem(DATA *data)
{
  int i;
  int size;
  MIXED_SYSTEM_DATA *system = data->simulationInfo.mixedSystemData;

  for(i=0; i<data->modelData.nMixedSystems; ++i)
  {
    size = system[i].size;

    system[i].iterationVarsPtr = (modelica_boolean**) malloc(size*sizeof(modelica_boolean*));
    system[i].iterationPreVarsPtr = (modelica_boolean**) malloc(size*sizeof(modelica_boolean*));

    /* allocate solver data */
    switch(data->simulationInfo.mixedMethod)
    {
    case MIXED_SEARCH:
      allocateMixedSearchData(size, &system[i].solverData);
      break;
    default:
      THROW("unrecognized mixed solver");
    }
  }
  return 0;
}

/*! \fn freemixedSystem
 *
 *  Thi function frees memory of mixed systems.
 *
 *  \param [ref] [data]
 */
int freemixedSystem(DATA *data)
{
  int i;
  MIXED_SYSTEM_DATA* system = data->simulationInfo.mixedSystemData;

  for(i=0;i<data->modelData.nMixedSystems;++i)
  {

    free(system[i].iterationVarsPtr);
    free(system[i].iterationPreVarsPtr);

    /* allocate solver data */
    switch(data->simulationInfo.mixedMethod)
    {
    case MIXED_SEARCH:
      freeMixedSearchData(&system[i].solverData);
      break;
    default:
      THROW("unrecognized mixed solver");
    }

    free(system[i].solverData);
  }

  return 0;
}

/*! \fn solve mixed systems
 *
 *  \param [in]  [data]
 *                [sysNumber] index of corresponding mixed System
 *
 *  \author wbraun
 */
int solve_mixed_system(DATA *data, int sysNumber)
{
  int success;
  MIXED_SYSTEM_DATA* system = data->simulationInfo.mixedSystemData;

  /* for now just use lapack solver as before */
  switch(data->simulationInfo.mixedMethod)
  {
  case MIXED_SEARCH:
    success = solveMixedSearch(data, sysNumber);
    break;
  default:
    THROW("unrecognized mixed solver");
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
  MIXED_SYSTEM_DATA* system = data->simulationInfo.mixedSystemData;
  int i, j, retVal=0;

  for(i=0; i<data->modelData.nMixedSystems; ++i)
    if(system[i].solved == 0)
    {
      retVal = 1;
      if(printFailingSystems)
      {
        WARNING2(LOG_NLS, "mixed system fails: %s at t=%g", modelInfoXmlGetEquation(&data->modelData.modelDataXml, system->equationIndex).name, data->localData[0]->timeValue);
        INDENT(LOG_NLS);
        for(j=0; j<modelInfoXmlGetEquation(&data->modelData.modelDataXml, system->equationIndex).numVar; ++j)
          WARNING2(LOG_NLS, "[%d] %s", j+1, modelInfoXmlGetEquation(&data->modelData.modelDataXml, system->equationIndex).vars[j]->name);
        RELEASE(LOG_NLS);
      }
    }

  return retVal;
}

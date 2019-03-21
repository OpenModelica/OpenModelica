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

/*! \file mixedSearchSolver.c
 */

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "../simulation_info_json.h"
#include "../../util/omc_error.h"
#include "../../util/varinfo.h"
#include "model_help.h"

#include "nonlinearSystem.h"
#include "nonlinearSolverHybrd.h"

typedef struct DATA_SEARCHMIXED_SOLVER
{
  modelica_boolean* iterationVars;
  modelica_boolean* iterationVars2;
  modelica_boolean* iterationVarsPre;

  long* iterationVarsIndex;

  modelica_boolean* stateofSearch;

}DATA_SEARCHMIXED_SOLVER;


/*! \fn allocate memory for mixed systems search solver
 *
 */
int allocateMixedSearchData(int size, void** voiddata)
{
  DATA_SEARCHMIXED_SOLVER* data = (DATA_SEARCHMIXED_SOLVER*) malloc(sizeof(DATA_SEARCHMIXED_SOLVER));
  *voiddata = (void*)data;
  assertStreamPrint(NULL, 0 != data, "allocationHybrdData() failed!");

  data->iterationVars = (modelica_boolean*) malloc(size*sizeof(modelica_boolean));
  data->iterationVars2 = (modelica_boolean*) malloc(size*sizeof(modelica_boolean));
  data->iterationVarsPre = (modelica_boolean*) malloc(size*sizeof(modelica_boolean));

  data->stateofSearch = (modelica_boolean*) malloc(size*sizeof(modelica_boolean));

  assertStreamPrint(NULL, 0 != *voiddata, "allocateMixedSearchData() voiddata failed!");
  return 0;
}

/*! \fn free memory for mixed systems search solver
 *
 */
int freeMixedSearchData(void **voiddata)
{
  DATA_SEARCHMIXED_SOLVER* data = (DATA_SEARCHMIXED_SOLVER*) *voiddata;

  free(data->iterationVars);
  free(data->iterationVars2);
  free(data->iterationVarsPre);

  free(data->stateofSearch);

  return 0;
}

/*! \fn nextVar
 *
 *  function is used in generated code for mixed equation systems
 *  to generate next combination of boolean variables.
 *  Example: for n = 3
 *           generates sequence: 000, 100, 010, 001, 110, 101, 011, 111
 *
 *  \param [ref] [data]
 *
 * \author Jan Silar
 *
 * \brief
 */
modelica_boolean nextVar(modelica_boolean *b, int n) {
  /*number of "1" */
  int n1 = 0;
  int i;
  int last;
  for(i = 0; i < n; i++){
    if(b[i] == 1)
      n1++;
  }
  /*index of last element with "1"*/
  last = n - 1;
  while(last >= 0 && !b[last])
    last--;
  if(n1 == n) /*exit - all combination were already generated*/
    return 0;
  else if(last == -1) { /* 0000 -> 1000 */
    b[0] = 1;
    return 1;
  } else if(last < n - 1) { /* e.g. 1010 -> 1001 */
    b[last] = 0;
    b[last + 1] = 1;
    return 1;
  } else { /*at the end of the array is "1"*/
    /*detect position of last ocurenc of sequence 10 */
    int ip = n - 2; /*actual position in array*/
    int nr1 = 1; /*count of "1"*/
    while(ip >= 0) {
      if(b[ip] && !b[ip + 1]) { /*we found*/
        nr1++;
        break;
      } else if(b[ip]) { /*we didn't find, but 1 - increase nr1*/
        nr1++;
        ip--;
      } else { /*we didnt't find, 0*/
        ip--;
      }
    }
    if(ip >= 0) { /*e.g. 1001 -> 0110*/
      int pn = ip + nr1;
      b[ip] = 0;
      for(i = ip + 1; i <= pn; i++)
        b[i] = 1;
      for(i = pn + 1; i <= n - 1; i++)
        b[i] = 0;
      return 1;
    } else {
      for(i = 0; i <= n1; i++)
        b[i] = 1;
      for(i = n1 + 1; i <= n - 1; i++)
        b[i] = 0;
      return 1;
    }
  }
}

/*! \fn solve mixed system with extended search
 *
 *  \param [in]  [data]
 *                [sysNumber] index of the corresponing mixed system
 *
 *  \author wbraun
 */
int solveMixedSearch(DATA *data, int sysNumber)
{
  MIXED_SYSTEM_DATA* systemData = &(data->simulationInfo->mixedSystemData[sysNumber]);
  DATA_SEARCHMIXED_SOLVER* solverData = (DATA_SEARCHMIXED_SOLVER*)systemData->solverData;

  int eqSystemNumber = systemData->equationIndex;

  int found_solution = 0;
  /*
   * We are given the number of the non-linear system.
   * We want to look it up among all equations.
   */
  int i, ix;

  int stepCount = 0;
  int mixedIterations = 0;
  int success = 0;

  debugStreamPrint(LOG_NLS, 1, "\n####  Start solver mixed equation system at time %f.", data->localData[0]->timeValue);

  memset(solverData->stateofSearch, 0, systemData->size);

  /* update pre iteration vars */
  /* update iteration vars */
  for(i=0;i<systemData->size;++i)
    solverData->iterationVarsPre[i] = *(systemData->iterationVarsPtr[i]);

  do
  {
    /* update pre iteration vars */
    for(i=0;i<systemData->size;++i)
      solverData->iterationVars[i] = *(systemData->iterationVarsPtr[i]);

    /* solve continuous equation part
     * and update iteration variables in model
     */
    systemData->solveContinuousPart(data);
    systemData->updateIterationExps(data);

    /* set new values of boolean variable */
    for(i=0;i<systemData->size;++i)
      solverData->iterationVars2[i] = *(systemData->iterationVarsPtr[i]);


    found_solution = systemData->continuous_solution;
    debugStreamPrint(LOG_NLS, 0, "####  continuous system solution status = %d", found_solution);

    /* restart if any relation has changed */
    if(checkRelations(data))
    {
      updateRelationsPre(data);
      systemData->updateIterationExps(data);
      debugStreamPrint(LOG_NLS, 0, "#### System relation changed restart iteration");
      if(mixedIterations++ > 200)
        found_solution = -4; /* mixedIterations++ > 200 */
    }

    if(found_solution == -1)
    {
      /* system of equations failed */
      found_solution = -2;
      debugStreamPrint(LOG_NLS, 0, "####  NO SOLUTION ");
    }
    else
    {
      found_solution = 1;
      for(i = 0; i < systemData->size; i++)
      {
        debugStreamPrint(LOG_NLS, 0, " check iterationVar[%d] = %d <-> %d", i, solverData->iterationVars[i], solverData->iterationVars2[i]);
        if(solverData->iterationVars[i] != solverData->iterationVars2[i])
        {
          found_solution  = 0;
          break;
        }
      }
      debugStreamPrint(LOG_NLS, 0, "#### SOLUTION = %c", found_solution  ? 'T' : 'F');
    }

    if(!found_solution )
    {
      /* try next set of values*/
      if(nextVar(solverData->stateofSearch, systemData->size))
      {
        debugStreamPrint(LOG_NLS, 0, "#### set next STATE ");
        for(i = 0; i < systemData->size; i++)
          *(systemData->iterationVarsPtr[i]) = *(systemData->iterationPreVarsPtr[i]) != solverData->stateofSearch[i];

        /* debug output */
        if(ACTIVE_STREAM(LOG_NLS))
        {
          const char * __name;
          for(i = 0; i < systemData->size; i++)
          {
            ix = (systemData->iterationVarsPtr[i]-data->localData[0]->booleanVars);
            __name = data->modelData->booleanVarsData[ix].info.name;
            debugStreamPrint(LOG_NLS, 0, "%s changed : %d -> %d", __name, solverData->iterationVars[i], *(systemData->iterationVarsPtr[i]));
          }
        }
      }
      else
      {
        /* while the initialization it's okay not a solution */
        if(!data->simulationInfo->initial)
        {
          warningStreamPrint(LOG_STDOUT, 0,
              "Error solving mixed equation system with index %d at time %e",
              eqSystemNumber, data->localData[0]->timeValue);
        }
        data->simulationInfo->needToIterate = 1;
        found_solution  = -1;
        /*TODO: "break simulation?"*/
      }
    }
    /* we found a solution*/
    if(found_solution  == 1)
    {
      success = 1;
      if(ACTIVE_STREAM(LOG_NLS))
      {
        const char * __name;
        debugStreamPrint(LOG_NLS, 0, "#### SOLUTION FOUND! (system %d)", eqSystemNumber);
        for(i = 0; i < systemData->size; i++)
        {
          ix = (systemData->iterationVarsPtr[i]-data->localData[0]->booleanVars);
          __name = data->modelData->booleanVarsData[ix].info.name;
          debugStreamPrint(LOG_NLS, 0, "%s = %d  pre(%s)= %d", __name, *systemData->iterationVarsPtr[i], __name,
              *systemData->iterationPreVarsPtr[i]);
        }
      }
    }

    stepCount++;
    mixedIterations++;

  }while(!found_solution);

  messageClose(LOG_NLS);
  debugStreamPrint(LOG_NLS, 0, "####  Finished mixed equation system in steps %d.\n", stepCount);
  return success;
}

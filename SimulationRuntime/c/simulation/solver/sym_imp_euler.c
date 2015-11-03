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

/*! \file sym_imp_euler.c
 */

#include <string.h>
#include <float.h>

#include "simulation/simulation_info_json.h"
#include "util/omc_error.h"
#include "util/varinfo.h"
#include "model_help.h"
#include "newtonIteration.h"


#include "sym_imp_euler.h"
#include "external_input.h"

void first_step(DATA* data, SOLVER_INFO* solverInfo);


/*! \fn allocateSymEulerImp
 *
 *   Function allocates memory needed for implicit symbolic euler with step size control.
 *
 *
 */
int allocateSymEulerImp(SOLVER_INFO* solverInfo, int size)
{
  DATA_SYM_IMP_EULER* userdata = (DATA_SYM_IMP_EULER*) malloc(sizeof(DATA_SYM_IMP_EULER));
  solverInfo->solverData = (void*) userdata;

  userdata->firstStep = 1;
  userdata->y05= malloc(sizeof(double)*size);
  userdata->y1 = malloc(sizeof(double)*size);
  userdata->y2 = malloc(sizeof(double)*size);
  userdata->radauVarsOld = malloc(sizeof(double)*size);
  userdata->radauVars = malloc(sizeof(double)*size);

  /* initialize stats */
  userdata->stepsDone = 0;
  userdata->evalFunctionODE = 0;

  userdata->radauStepSizeOld = 0;
  return 0;
}

/*! \fn freeSymEulerImp
 *
 *   Memory needed for solver is set free.
 */
int freeSymEulerImp(SOLVER_INFO* solverInfo)
{
  DATA_SYM_IMP_EULER* userdata = (DATA_SYM_IMP_EULER*) solverInfo->solverData;

  free(userdata->y05);
  free(userdata->y1);
  free(userdata->y2);
  free(userdata->radauVarsOld);
  free(userdata->radauVars);

  return 0;
}

/*! \fn sym_euler_im_with_step_size_control_step
 *
 *   Function does one implicit euler step
 *   and calculates step size for the next step
 *   using the implicit midpoint rule
 *
 */
int sym_euler_im_with_step_size_control_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  int retVal = 0;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_SYM_IMP_EULER* userdata = (DATA_SYM_IMP_EULER*)solverInfo->solverData;

  double sc, err, a, b, diff;
  double Atol = data->simulationInfo.tolerance, Rtol = data->simulationInfo.tolerance;
  int i,j;
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.3;
  double saveTime = sDataOld->timeValue;
  double targetTime = sDataOld->timeValue + solverInfo->currentStepSize;


  if (userdata->firstStep  || solverInfo->didEventStep == 1)
  {
    first_step(data, solverInfo);
    userdata->radauStepSizeOld = 0;
  }

  infoStreamPrint(LOG_SOLVER,0, "new step: time=%e", userdata->radauTime);
  while (userdata->radauTime < targetTime)
  {
    do
    {
      /*** do one step with original step size ***/

      infoStreamPrint(LOG_SOLVER,0, "radauStepSize = %e and time = %e", userdata->radauStepSize, userdata->radauTime);

      /* update time */
      sDataOld->timeValue = userdata->radauTime;
      solverInfo->currentTime = userdata->radauTime + userdata->radauStepSize;
      sData->timeValue = solverInfo->currentTime;

      /* update step size */
      data->callback->symEulerUpdate(data, userdata->radauStepSize);

      memcpy(sDataOld->realVars, userdata->radauVars, data->modelData.nStates*sizeof(double));

      infoStreamPrint(LOG_SOLVER,0, "first system time = %e", sData->timeValue);

      /* evaluate function ODE */
      externalInputUpdate(data);
      data->callback->input_function(data, threadData);
      data->callback->functionODE(data,threadData);

      /* save values in y05 */
      memcpy(userdata->y05, sData->realVars, data->modelData.nStates*sizeof(double));

      /* extrapolate values in y1 */
      for (i=0; i<data->modelData.nStates; i++)
      {
        userdata->y1[i] = 2.0 * userdata->y05[i] - userdata->radauVars[i];
      }

      /*** do another step with original step size ***/
      memcpy(sDataOld->realVars, userdata->y05, data->modelData.nStates*sizeof(double));

      /* update time */
      sDataOld->timeValue = userdata->radauTime + userdata->radauStepSize;
      solverInfo->currentTime = userdata->radauTime + 2.0*userdata->radauStepSize;
      sData->timeValue = solverInfo->currentTime;

      infoStreamPrint(LOG_SOLVER,0, "second system time = %e", sData->timeValue);

      /* update step size */
      data->callback->symEulerUpdate(data, userdata->radauStepSize);

      /* evaluate function ODE */
      externalInputUpdate(data);
      data->callback->input_function(data, threadData);
      data->callback->functionODE(data, threadData);

      /* save values in y2 */
      memcpy(userdata->y2, sData->realVars, data->modelData.nStates*sizeof(double));

      /*** calculate error ***/
      for (i=0, err=0.0; i<data->modelData.nStates; i++)
      {
        sc = Atol + fmax(fabs(userdata->y2[i]),fabs(userdata->y1[i]))*Rtol;
        diff = userdata->y2[i]-userdata->y1[i];
        err += (diff*diff)/(sc*sc);
      }

      err /= data->modelData.nStates;
      err = sqrt(err);

      userdata->stepsDone += 1;
      infoStreamPrint(LOG_SOLVER, 0, "err = %e", err);
      infoStreamPrint(LOG_SOLVER, 0, "min(facmax, max(facmin, fac*sqrt(1/err))) = %e",  fmin(facmax, fmax(facmin, fac*sqrt(1.0/err))));


      /* update step size */
      userdata->radauStepSizeOld = 2.0 * userdata->radauStepSize;
      userdata->radauStepSize *=  fmin(facmax, fmax(facmin, fac*sqrt(1.0/err)));

      if (isnan(userdata->radauStepSize))
      {
        userdata->radauStepSize = 1e-6;
      }

    } while  (err > 1.0 );

    userdata->radauTimeOld =  userdata->radauTime;

    userdata->radauTime += userdata->radauStepSizeOld;

    memcpy(userdata->radauVarsOld, userdata->radauVars, data->modelData.nStates*sizeof(double));
    memcpy(userdata->radauVars, userdata->y2, data->modelData.nStates*sizeof(double));
  }

  sDataOld->timeValue = saveTime;
  solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;
  sData->timeValue = solverInfo->currentTime;


  /* linear interpolation */
  for (i=0; i<data->modelData.nStates; i++)
  {
    sData->realVars[i] = (userdata->radauVars[i] * (sData->timeValue - userdata->radauTimeOld) + userdata->radauVarsOld[i] * (userdata->radauTime - sData->timeValue))/(userdata->radauTime - userdata->radauTimeOld);

  }

  /* update first derivative  */
  infoStreamPrint(LOG_SOLVER,0, "Time  %e", sData->timeValue);
  for(i=0, j=data->modelData.nStates; i<data->modelData.nStates; ++i, ++j)
  {
    a = 4.0 * (userdata->y2[i] - 2.0 * userdata->y05[i] + userdata->radauVarsOld[i]) / (userdata->radauStepSizeOld * userdata->radauStepSizeOld);
    b = 2.0 * (userdata->y2[i] - userdata->y05[i])/userdata->radauStepSizeOld - userdata->radauTime * a;
    data->localData[0]->realVars[j] = a * sData->timeValue + b;
  }

  /* update step size */
  data->callback->symEulerUpdate(data, 0);
  solverInfo->solverStepSize = userdata->radauStepSizeOld;
  infoStreamPrint(LOG_SOLVER,0, "Step done to %f with step size = %e", sData->timeValue, solverInfo->solverStepSize);

  return retVal;
}

/*! \fn first_step
 *
 *  function initializes values and sets
 *  initial step size
 *
 */
void first_step(DATA* data, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_SYM_IMP_EULER* userdata = (DATA_SYM_IMP_EULER*)solverInfo->solverData;

  int i,j;

  /* initialize radau values */
  for (i=0; i<data->modelData.nStates; i++)
  {
    userdata->radauVars[i] = sData->realVars[i];
    userdata->radauVarsOld[i] = sDataOld->realVars[i];
  }

  userdata->radauTime = sDataOld->timeValue;
  userdata->radauTimeOld = sDataOld->timeValue;


  userdata->firstStep = 0;
  solverInfo->didEventStep = 0;

  userdata->radauStepSize = 0.5*solverInfo->currentStepSize;
}


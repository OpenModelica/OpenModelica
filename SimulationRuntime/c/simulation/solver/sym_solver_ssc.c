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

/*! \file sym_solver_ssc.c
 */

#include <string.h>
#include <float.h>

#include "simulation/simulation_info_json.h"
#include "util/omc_error.h"
#include "util/varinfo.h"
#include "model_help.h"
#include "newtonIteration.h"


#include "sym_solver_ssc.h"
#include "external_input.h"

int first_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
int generateTwoApproximationsOfDifferentOrder(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);


/*! \fn allocateSymEulerImp
 *
 *   Function allocates memory needed for implicit symbolic euler with step size control.
 *
 *
 */
int allocateSymSolverSsc(SOLVER_INFO* solverInfo, int size)
{
  DATA_SYM_SOLVER_SSC* userdata = (DATA_SYM_SOLVER_SSC*) malloc(sizeof(DATA_SYM_SOLVER_SSC));
  solverInfo->solverData = (void*) userdata;

  userdata->firstStep = 1;
  userdata->y05= malloc(sizeof(double)*size);
  userdata->y1 = malloc(sizeof(double)*size);
  userdata->y2 = malloc(sizeof(double)*size);
  userdata->radauVarsOld = malloc(sizeof(double)*size);
  userdata->radauVars = malloc(sizeof(double)*size);
  userdata->der_x0 = malloc(sizeof(double)*size);

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
int freeSymSolverSsc(SOLVER_INFO* solverInfo)
{
  DATA_SYM_SOLVER_SSC* userdata = (DATA_SYM_SOLVER_SSC*) solverInfo->solverData;

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
int sym_solver_ssc_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  int retVal = 0;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_SYM_SOLVER_SSC* userdata = (DATA_SYM_SOLVER_SSC*)solverInfo->solverData;
  modelica_real* stateDer = sDataOld->realVars + data->modelData->nStates;

  double sc, err, a, b, diff;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;
  int i,j;
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.3;
  double saveTime = sDataOld->timeValue;
  double targetTime = sDataOld->timeValue + solverInfo->currentStepSize;


  if (userdata->firstStep  || solverInfo->didEventStep == 1)
  {
    retVal = first_step(data, threadData, solverInfo);
    userdata->radauStepSizeOld = 0;

    if (retVal != 0)
    {
      return -1;
    }
  }

  infoStreamPrint(LOG_SOLVER,0, "new step: time=%e", userdata->radauTime);
  while (userdata->radauTime < targetTime)
  {
    do
    {
      retVal = generateTwoApproximationsOfDifferentOrder(data, threadData, solverInfo);

      for (i=0; i<data->modelData->nStates; i++)
      {
        infoStreamPrint(LOG_SOLVER, 0, "y1[%d]=%e", i, userdata->y1[i]);
        infoStreamPrint(LOG_SOLVER, 0, "y2[%d]=%e", i, userdata->y2[i]);
      }

      /*** calculate error ***/
      for (i=0, err=0.0; i<data->modelData->nStates; i++)
      {
        sc = Atol + fmax(fabs(userdata->y2[i]),fabs(userdata->y1[i]))*Rtol;
        diff = userdata->y2[i]-userdata->y1[i];
        err += (diff*diff)/(sc*sc);
      }

      err /= data->modelData->nStates;

      userdata->stepsDone += 1;
      infoStreamPrint(LOG_SOLVER, 0, "err = %e", err);
      infoStreamPrint(LOG_SOLVER, 0, "min(facmax, max(facmin, fac*sqrt(1/err))) = %e",  fmin(facmax, fmax(facmin, fac*pow(1.0/err, 4))));


      /* update step size */
      userdata->radauStepSizeOld = userdata->radauStepSize;
      userdata->radauStepSize *=  fmin(facmax, fmax(facmin, fac*sqrt(1.0/err)));

      if (isnan(userdata->radauStepSize) || userdata->radauStepSize < 1e-13)
      {
        userdata->radauStepSize = 1e-13;
        infoStreamPrint(LOG_SOLVER, 0, "Desired step to small try next one");
        infoStreamPrint(LOG_SOLVER, 0, "Interpolate linear");

        /* explicit euler step*/
        for(i = 0; i < data->modelData->nStates; i++)
        {
          sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
        }
        sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
        solverInfo->currentTime = sData->timeValue;

        userdata->radauTimeOld =  userdata->radauTime;
        userdata->radauTime += userdata->radauStepSizeOld;

        memcpy(userdata->radauVarsOld, userdata->radauVars, data->modelData->nStates*sizeof(double));
        memcpy(userdata->radauVars, userdata->y2, data->modelData->nStates*sizeof(double));

        break;
      }

    } while  (err > 1.0 );

    userdata->radauTimeOld =  userdata->radauTime;

    userdata->radauTime += userdata->radauStepSizeOld;

    memcpy(userdata->radauVarsOld, userdata->radauVars, data->modelData->nStates*sizeof(double));
    memcpy(userdata->radauVars, userdata->y2, data->modelData->nStates*sizeof(double));
  }

  sDataOld->timeValue = saveTime;
  solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;
  sData->timeValue = solverInfo->currentTime;

  if (userdata->radauTime - userdata->radauTimeOld > 1e-13 && userdata->radauStepSizeOld > 1e-13)
  {
    /* linear interpolation */
    for (i=0; i<data->modelData->nStates; i++)
    {
      sData->realVars[i] = (userdata->radauVars[i] * (sData->timeValue - userdata->radauTimeOld) + userdata->radauVarsOld[i] * (userdata->radauTime - sData->timeValue))/(userdata->radauTime - userdata->radauTimeOld);
    }

    /* update first derivative  */
    infoStreamPrint(LOG_SOLVER,0, "Time  %e", sData->timeValue);
    for(i=0; i<data->modelData->nStates; ++i)
    {
      a = 4.0 * (userdata->y2[i] - 2.0 * userdata->y05[i] + userdata->radauVarsOld[i]) / (userdata->radauStepSizeOld * userdata->radauStepSizeOld);
      b = 2.0 * (userdata->y2[i] - userdata->y05[i])/userdata->radauStepSizeOld - userdata->radauTime * a;
      stateDer[i] = a * sData->timeValue + b;
    }
  }
  else
  {
    infoStreamPrint(LOG_SOLVER, 0, "Desired step to small try next one");
    infoStreamPrint(LOG_SOLVER, 0, "Interpolate linear");

    /* explicit euler step*/
    for(i = 0; i < data->modelData->nStates; i++)
    {
      sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
    }
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    solverInfo->currentTime = sData->timeValue;

    userdata->radauTimeOld =  userdata->radauTime;
    userdata->radauTime += userdata->radauStepSizeOld;

    memcpy(userdata->radauVarsOld, userdata->radauVars, data->modelData->nStates*sizeof(double));
    memcpy(userdata->radauVars, userdata->y2, data->modelData->nStates*sizeof(double));
  }

  /* update step size */
  data->simulationInfo->inlineData->dt = userdata->radauStepSize;
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
int first_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_SYM_SOLVER_SSC* userdata = (DATA_SYM_SOLVER_SSC*)solverInfo->solverData;
  const int n = data->modelData->nStates;
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  modelica_real* stateDerOld = sDataOld->realVars + data->modelData->nStates;
  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;
  int i,j,retVal;
/* it seems that jacobian is not used yet!
#if defined(_MSC_VER) // handle crap compilers
  double *jacobian = (double*)malloc(n*n*sizeof(double));
#else
  double jacobian[n*n];
#endif
*/

  /* initialize radau values */
  for (i=0; i<data->modelData->nStates; i++)
  {
    userdata->radauVars[i] = sData->realVars[i];
    userdata->radauVarsOld[i] = sDataOld->realVars[i];
  }

  userdata->radauTime = sDataOld->timeValue;
  userdata->radauTimeOld = sDataOld->timeValue;

  userdata->firstStep = 0;
  solverInfo->didEventStep = 0;

  if (compiledWithSymSolver == 2)  /* compiled with symSolver - explicit euler*/
  {
    /*** calculate starting step size 1st Version ***/

    /* update step size */
    data->simulationInfo->inlineData->dt = 1e-8;

    /* evaluate function */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    retVal = data->callback->symbolicInlineSystems(data, threadData);

    for (i=0; i<data->modelData->nStates; i++)
    {
      stateDer[i] = (sData->realVars[i] - sDataOld->realVars[i])/data->simulationInfo->inlineData->dt;
    }

    if(retVal != 0){
      return -1;
    }

    for (i=0; i<data->modelData->nStates; i++)
    {
      sc = Atol + fabs(sDataOld->realVars[i])*Rtol;
      d0 += ((sDataOld->realVars[i] * sDataOld->realVars[i])/(sc*sc));
      d1 += ((stateDer[i] * stateDer[i]) / (sc*sc));
    }
    d0 /= data->modelData->nStates;
    d1 /= data->modelData->nStates;

    d0 = sqrt(d0);
    d1 = sqrt(d1);


    for (i=0; i<data->modelData->nStates; i++)
    {
      userdata->der_x0[i] = stateDer[i];
    }

    if (d0 < 1e-5 || d1 < 1e-5)
    {
      h0 = 1e-6;
    }
    else
    {
      h0 = 0.01 * d0/d1;
    }


    for (i=0; i<data->modelData->nStates; i++)
    {
      sData->realVars[i] = userdata->radauVars[i] + stateDer[i] * h0;
    }
    sData->timeValue += h0;

    /* update step size */
    data->simulationInfo->inlineData->dt = h0;

    /* evaluate function */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    retVal = data->callback->symbolicInlineSystems(data, threadData);

    for (i=0; i<data->modelData->nStates; i++)
    {
      stateDer[i] = (sData->realVars[i] - sDataOld->realVars[i])/data->simulationInfo->inlineData->dt;
    }

    for (i=0; i<data->modelData->nStates; i++)
    {
      sc = Atol + fabs(userdata->radauVars[i])*Rtol;
      d2 += ((stateDer[i]-userdata->der_x0[i])*(stateDer[i]-userdata->der_x0[i])/(sc*sc));
    }

    d2 = sqrt(d2);
    d2 /= h0;

    d = fmax(d1,d2);

    if (d > 1e-15)
    {
      h1 = sqrt(0.01/d);
    }
    else
    {
      h1 = fmax(1e-6, h0*1e-3);
    }

    userdata->radauStepSize = 0.5*fmin(100*h0,h1);
    data->simulationInfo->inlineData->dt = userdata->radauStepSize;

    /* end calculation new step size */
  }
  else
  {
    userdata->radauStepSize = 0.5*solverInfo->currentStepSize;
  }
/*
#if defined(_MSC_VER) // handle crap compilers
  free(jacobian)
#endif
*/
  return 0;
}


/*! \fn generateTwoApproximationsOfDifferentOrder
 *
 *   Function generates two approximations of
 *   different convergence order for step
 *   size control (stored in userdata->y1, userdata->y2)
 *
 */
int generateTwoApproximationsOfDifferentOrder(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
 {
  int retVal = 0;
  int i;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_SYM_SOLVER_SSC* userdata = (DATA_SYM_SOLVER_SSC*)solverInfo->solverData;
  modelica_real* stateDer = sDataOld->realVars + data->modelData->nStates;
  if (compiledWithSymSolver == 1)  /* compiled with implicit symbolic euler */
  {
    /*** do one step with half step size ***/
    infoStreamPrint(LOG_SOLVER,0, "radauStepSize = %e", userdata->radauStepSize);

    /* update step size */
    userdata->radauStepSize /= 2;
    data->simulationInfo->inlineData->dt = userdata->radauStepSize;

    /* update time */
    sDataOld->timeValue = userdata->radauTime;
    solverInfo->currentTime = userdata->radauTime + userdata->radauStepSize;
    sData->timeValue = solverInfo->currentTime;

    infoStreamPrint(LOG_SOLVER,0, "first system time = %e", sData->timeValue);

    /* update algebraicOld values */
    memcpy(data->simulationInfo->inlineData->algOldVars, userdata->radauVars, data->modelData->nStates * sizeof(double));

    /* evaluate function */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    retVal = data->callback->symbolicInlineSystems(data, threadData);

    if(retVal != 0){
      return -1;
    }

    /* save values in y05 */
    memcpy(userdata->y05, sData->realVars, data->modelData->nStates*sizeof(double));

    /*** extrapolate values in y1 (= y0 + h * f(y(t+h/2),t+h/2)) ***/
    for (i=0; i<data->modelData->nStates; i++)
    {
      userdata->y1[i] = 2.0 * userdata->y05[i] - userdata->radauVars[i];
    }

    /*** do another step with half step size ***/
    memcpy(data->simulationInfo->inlineData->algOldVars, userdata->y05, data->modelData->nStates * sizeof(double));

    /* update time */
    sDataOld->timeValue = userdata->radauTime + userdata->radauStepSize;
    solverInfo->currentTime = userdata->radauTime + 2.0 * userdata->radauStepSize;
    sData->timeValue = solverInfo->currentTime;

    infoStreamPrint(LOG_SOLVER,0, "second system time = %e", sData->timeValue);

    /* update step size */
    data->simulationInfo->inlineData->dt = userdata->radauStepSize;

    /* evaluate function ODE */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    data->callback->symbolicInlineSystems(data, threadData);


    solverInfo->solverStatsTmp[0] += 1;
    solverInfo->solverStatsTmp[1] += 2;

    /* save values in y2 */
    memcpy(userdata->y2, sData->realVars, data->modelData->nStates*sizeof(double));

    userdata->radauStepSize *= 2;
  }
  else if (compiledWithSymSolver == 2) /* compiled with explicit symbolic euler */
  {
    /*** do one step with half step size***/
    infoStreamPrint(LOG_SOLVER,0, "radauStepSize = %e", userdata->radauStepSize);

    /* update step size */
    userdata->radauStepSize /= 2;
    data->simulationInfo->inlineData->dt = userdata->radauStepSize;

    /* update algOldVars */
    memcpy(data->simulationInfo->inlineData->algOldVars, userdata->radauVars, data->modelData->nStates * sizeof(double));

    /* update time */
    sDataOld->timeValue = userdata->radauTime;
    solverInfo->currentTime = userdata->radauTime + userdata->radauStepSize;
    sData->timeValue = solverInfo->currentTime;

    infoStreamPrint(LOG_SOLVER,0, "first system time = %e", sData->timeValue);

    /* evaluate function */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    retVal = data->callback->symbolicInlineSystems(data, threadData);

    if(retVal != 0){
      return -1;
    }

    /* save values in y05 */
    memcpy(userdata->y05, sData->realVars, data->modelData->nStates*sizeof(double));

    /*** extrapolate values in y1 (= y0 + h * f(y,t)) ***/
    for (i=0; i<data->modelData->nStates; i++)
    {
      userdata->y1[i] = 2.0 * userdata->y05[i] - userdata->radauVars[i];
    }

    /*** do another step with half step size ***/
    memcpy(data->simulationInfo->inlineData->algOldVars, userdata->y05, data->modelData->nStates * sizeof(double));

    /* update time */
    sDataOld->timeValue = userdata->radauTime + userdata->radauStepSize;
    solverInfo->currentTime = userdata->radauTime + 2.0 * userdata->radauStepSize;
    sData->timeValue = solverInfo->currentTime;

    infoStreamPrint(LOG_SOLVER,0, "second system time = %e", sData->timeValue);

    /* update step size */
    data->simulationInfo->inlineData->dt = userdata->radauStepSize;

    /* evaluate function ODE */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    data->callback->symbolicInlineSystems(data, threadData);


    solverInfo->solverStatsTmp[0] += 1;
    solverInfo->solverStatsTmp[1] += 2;

    /* save values in y2 */
    memcpy(userdata->y2, sData->realVars, data->modelData->nStates*sizeof(double));

    /*** generate solution of higher order via richardson extrapolation */
    for (i=0; i<data->modelData->nStates; i++)
    {
      userdata->y1[i] = 2.0 * userdata->y2[i] - userdata->y1[i];
    }

    userdata->radauStepSize *= 2;

  }

  return 0;

 }

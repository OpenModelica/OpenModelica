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

/*! \file nonlinearSystem.c
 */

#include <math.h>
#include <string.h>

#include "omc_error.h"
#include "nonlinearSystem.h"
#include "kinsolSolver.h"
#include "nonlinearSolverHybrd.h"
#include "nonlinearSolverNewton.h"
#include "simulation_info_xml.h"
#include "simulation_runtime.h"

/* for try and catch simulationJumpBuffer */
#include "meta_modelica.h"

int check_nonlinear_solution(DATA *data, int printFailingSystems, int sysNumber);

const char *NLS_NAME[NLS_MAX+1] = {
  "NLS_UNKNOWN",

  /* NLS_HYBRID */       "hybrid",
  /* NLS_KINSOL */       "kinsol",
  /* NLS_NEWTON */       "newton",
  /* NLS_MIXED */        "mixed",

  "NLS_MAX"
};

const char *NLS_DESC[NLS_MAX+1] = {
  "unknown",

  /* NLS_HYBRID */       "default method",
  /* NLS_KINSOL */       "sundials/kinsol",
  /* NLS_NEWTON */       "Newton Raphson",
  /* NLS_MIXED */        "Mixed strategy start with Newton and fallback to hybrid",

  "NLS_MAX"
};

const char *NEWTONSTRATEGY_NAME[NEWTON_MAX+1] = {
  "NEWTON_UNKNOWN",

  /* NEWTON_DAMPED */       "damped",
  /* NEWTON_DAMPED2 */      "damped2",
  /* NEWTON_DAMPED_LS */    "damped_ls",
  /* NEWTON_PURE */         "pure",

  "NEWTON_MAX"
};

const char *NEWTONSTRATEGY_DESC[NEWTON_MAX+1] = {
  "unknown",

  /* NEWTON_DAMPED */       "Newton with a damping strategy",
  /* NEWTON_DAMPED2 */      "Newton with a damping strategy 2",
  /* NEWTON_DAMPED_LS */    "Newton with a damping line search",
  /* NEWTON_PURE */         "Newton without damping strategy",

  "NEWTON_MAX"
};

struct dataNewtonAndHybrid {
  void* newtonData;
  void* hybridData;
};

/*! \fn int allocateNonlinearSystem(DATA *data)
 *
 *  This function allocates memory for all nonlinear systems.
 *
 *  \param [ref] [data]
 */
int allocateNonlinearSystem(DATA *data)
{
  int i;
  int size;
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo.nonlinearSystemData;
  struct dataNewtonAndHybrid *mixedSolverData;

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
  {
    size = nonlinsys[i].size;

    /* check if residual function pointer are valid */
    assertStreamPrint(data->threadData, 0 != nonlinsys[i].residualFunc, "residual function pointer is invalid" );

    /* check if analytical jacobian is created */
    if(nonlinsys[i].jacobianIndex != -1){
      assertStreamPrint(data->threadData, 0 != nonlinsys[i].analyticalJacobianColumn, "jacobian function pointer is invalid" );
      if(nonlinsys[i].initialAnalyticalJacobian(data))
      {
        nonlinsys[i].jacobianIndex = -1;
      }
    }

    /* allocate system data */
    nonlinsys[i].nlsx = (double*) malloc(size*sizeof(double));
    nonlinsys[i].nlsxExtrapolation = (double*) malloc(size*sizeof(double));
    nonlinsys[i].nlsxOld = (double*) malloc(size*sizeof(double));

    nonlinsys[i].nominal = (double*) malloc(size*sizeof(double));
    nonlinsys[i].min = (double*) malloc(size*sizeof(double));
    nonlinsys[i].max = (double*) malloc(size*sizeof(double));

    nonlinsys[i].initializeStaticNLSData(data, &nonlinsys[i]);

    /* allocate solver data */
    if(nonlinsys[i].method == 1)
    {
      allocateNewtonData(size, &nonlinsys[i].solverData);
    }
    else
    {
      switch(data->simulationInfo.nlsMethod)
      {
      case NLS_HYBRID:
        allocateHybrdData(size, &nonlinsys[i].solverData);
        break;
      case NLS_KINSOL:
        nls_kinsol_allocate(data, &nonlinsys[i]);
        break;
      case NLS_NEWTON:
        allocateNewtonData(size, &nonlinsys[i].solverData);
        break;
      case NLS_MIXED:
        mixedSolverData = (struct dataNewtonAndHybrid*) malloc(sizeof(struct dataNewtonAndHybrid));
        allocateNewtonData(size, &(mixedSolverData->newtonData));

        allocateHybrdData(size, &(mixedSolverData->hybridData));

        nonlinsys[i].solverData = (void*) mixedSolverData;

        break;
      default:
        throwStreamPrint(data->threadData, "unrecognized nonlinear solver");
      }
    }

  }

  return 0;
}

/*! \fn freeNonlinearSystem
 *
 *  This function frees memory of nonlinear systems.
 *
 *  \param [ref] [data]
 */
int freeNonlinearSystem(DATA *data)
{
  int i;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
  {
    free(nonlinsys[i].nlsx);
    free(nonlinsys[i].nlsxExtrapolation);
    free(nonlinsys[i].nlsxOld);
    free(nonlinsys[i].nominal);
    free(nonlinsys[i].min);
    free(nonlinsys[i].max);

    /* free solver data */
    if(nonlinsys[i].method == 1)
    {
      freeNewtonData(&nonlinsys[i].solverData);
    }
    else
    {
      switch(data->simulationInfo.nlsMethod)
      {
      case NLS_HYBRID:
        freeHybrdData(&nonlinsys[i].solverData);
        break;
      case NLS_KINSOL:
        nls_kinsol_free(&nonlinsys[i]);
        break;
      case NLS_NEWTON:
        freeNewtonData(&nonlinsys[i].solverData);
        break;
      case NLS_MIXED:
        freeNewtonData(&((struct dataNewtonAndHybrid*) nonlinsys[i].solverData)->newtonData);
        freeHybrdData(&((struct dataNewtonAndHybrid*) nonlinsys[i].solverData)->hybridData);
        break;
      default:
        throwStreamPrint(data->threadData, "unrecognized nonlinear solver");
      }
    }
    free(nonlinsys[i].solverData);
  }

  return 0;
}

/*! \fn solve non-linear systems
 *
 *  \param [in]  [data]
 *  \param [in]  [sysNumber] index of corresponding non-linear System
 *
 *  \author wbraun
 */
int solve_nonlinear_system(DATA *data, int sysNumber)
{
  /* NONLINEAR_SYSTEM_DATA* system = &(data->simulationInfo.nonlinearSystemData[sysNumber]); */
  int success = 0, saveJumpState;
  NONLINEAR_SYSTEM_DATA* nonlinsys = &(data->simulationInfo.nonlinearSystemData[sysNumber]);
  threadData_t *threadData = data->threadData;
  struct dataNewtonAndHybrid *mixedSolverData;


  data->simulationInfo.currentNonlinearSystemIndex = sysNumber;

  /* enable to avoid division by zero */
  data->simulationInfo.noThrowDivZero = 1;

  /* strategy for solving nonlinear system
   *
   *
   *
   */

  /* for now just use hybrd solver as before */
  if(nonlinsys->method == 1)
  {
    success = solveNewton(data, sysNumber);
  }
  else
  {
    switch(data->simulationInfo.nlsMethod)
    {
    case NLS_HYBRID:
      saveJumpState = data->threadData->currentErrorStage;
      data->threadData->currentErrorStage = ERROR_NONLINEARSOLVER;
      success = solveHybrd(data, sysNumber);
      data->threadData->currentErrorStage = saveJumpState;
      break;
    case NLS_KINSOL:
      success = nonlinearSolve_kinsol(data, sysNumber);
      break;
    case NLS_NEWTON:
      success = solveNewton(data, sysNumber);
      break;
    case NLS_MIXED:
      mixedSolverData = nonlinsys->solverData;
      nonlinsys->solverData = mixedSolverData->newtonData;

      saveJumpState = data->threadData->currentErrorStage;
      data->threadData->currentErrorStage = ERROR_NONLINEARSOLVER;
#ifndef OMC_EMCC
      /* try */
      MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      success = solveNewton(data, sysNumber);
      /* catch */
#ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
      if (!success) {
        nonlinsys->solverData = mixedSolverData->hybridData;
        success = solveHybrd(data, sysNumber);
      }
      data->threadData->currentErrorStage = saveJumpState;
      nonlinsys->solverData = mixedSolverData;
      break;
    default:
      throwStreamPrint(data->threadData, "unrecognized nonlinear solver");
    }
  }
  nonlinsys->solved = success;

  /* enable to avoid division by zero */
  data->simulationInfo.noThrowDivZero = 0;

  return check_nonlinear_solution(data, 1, sysNumber);
}

/*! \fn check_nonlinear_solutions
 *
 *   This function check whether some of non-linear systems
 *   are failed to solve. If one is failed it returns 1 otherwise 0.
 *
 *  \param [in]  [data]
 *  \param [in]  [printFailingSystems]
 *  \param [out] [returnValue] It returns >0 if fail otherwise 0.
 *
 *  \author wbraun
 */
int check_nonlinear_solutions(DATA *data, int printFailingSystems)
{
  long i;

  for(i=0; i<data->modelData.nNonLinearSystems; ++i) {
     if(check_nonlinear_solution(data, printFailingSystems, i))
       return 1;
  }

  return 0;
}

/*! \fn check_nonlinear_solution
 *
 *   This function check whether one non-linear system
 *   is to solve. If one is failed it returns 1 otherwise 0.
 *
 *  \param [in]  [data]
 *  \param [in]  [printFailingSystems]
 *  \param [in]  [sysNumber] index of corresponding non-linear System
 *  \param [out] [returnValue] It returns 1 if fail otherwise 0.
 *
 *  \author wbraun
 */
int check_nonlinear_solution(DATA *data, int printFailingSystems, int sysNumber)
{
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;
  long j;
  int i = sysNumber;

  if(nonlinsys[i].solved == 0)
  {
    int index = nonlinsys[i].equationIndex, indexes[2] = {1,index};
    if (!printFailingSystems) return 1;
    warningStreamPrintWithEquationIndexes(LOG_NLS, 1, indexes, "nonlinear system %d fails: at t=%g", index, data->localData[0]->timeValue);
    if(data->simulationInfo.initial)
    {
      warningStreamPrint(LOG_NLS, 0, "proper start-values for some of the following iteration variables might help");
    }
    for(j=0; j<modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).numVar; ++j) {
      int done=0;
      long k;
      const MODEL_DATA *mData = &(data->modelData);
      for(k=0; k<mData->nVariablesReal && !done; ++k)
      {
        if (!strcmp(mData->realVarsData[k].info.name, modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).vars[j]))
        {
        done = 1;
        warningStreamPrint(LOG_NLS, 0, "[%ld] Real %s(start=%g, nominal=%g)", j+1,
                                     mData->realVarsData[k].info.name,
                                     mData->realVarsData[k].attribute.start,
                                     mData->realVarsData[k].attribute.nominal);
        }
      }
      if (!done)
      {
        warningStreamPrint(LOG_NLS, 0, "[%ld] Real %s(start=?, nominal=?)", j+1, modelInfoXmlGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).vars[j]);
      }
    }
    messageCloseWarning(LOG_NLS);
    return 1;
  }

  return 0;
}

/*! \fn extraPolate
 *   This function extrapolates linear next value from
 *   the both old values,
 *
 *  \param [in]  [data]
 *
 *  \author wbraun
 */
double extraPolate(DATA *data, double old1, double old2)
{
  double retValue;

  if(data->localData[1]->timeValue == data->localData[2]->timeValue)
  {
    retValue = old1;
  }
  else
  {
    retValue = old2 + ((data->localData[0]->timeValue - data->localData[2]->timeValue)/(data->localData[1]->timeValue - data->localData[2]->timeValue)) * (old1-old2);
  }

  return retValue;
}

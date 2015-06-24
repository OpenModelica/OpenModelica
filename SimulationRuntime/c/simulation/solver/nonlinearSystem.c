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

#include "util/omc_error.h"
#include "nonlinearSystem.h"
#include "kinsolSolver.h"
#include "nonlinearSolverHybrd.h"
#include "nonlinearSolverNewton.h"
#include "nonlinearSolverHomotopy.h"
#include "simulation/simulation_info_xml.h"
#include "simulation/simulation_runtime.h"

/* for try and catch simulationJumpBuffer */
#include "meta/meta_modelica.h"

int check_nonlinear_solution(DATA *data, int printFailingSystems, int sysNumber);

struct dataNewtonAndHybrid {
  void* newtonData;
  void* hybridData;
};

/*! \fn int initializeNonlinearSystems(DATA *data)
 *
 *  This function allocates memory for all nonlinear systems.
 *
 *  \param [ref] [data]
 */
int initializeNonlinearSystems(DATA *data)
{
  TRACE_PUSH
  int i;
  int size;
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo.nonlinearSystemData;
  struct dataNewtonAndHybrid *mixedSolverData;

  infoStreamPrint(LOG_NLS, 1, "initialize non-linear system solvers");

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
  {
    size = nonlinsys[i].size;
    nonlinsys[i].numberOfFEval = 0;
    nonlinsys[i].numberOfIterations = 0;

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
    switch(data->simulationInfo.nlsMethod)
    {
#if !defined(OMC_MINIMAL_RUNTIME)
    case NLS_HYBRID:
      allocateHybrdData(size, &nonlinsys[i].solverData);
      break;
    case NLS_KINSOL:
      nls_kinsol_allocate(data, &nonlinsys[i]);
      break;
    case NLS_NEWTON:
      allocateNewtonData(size, &nonlinsys[i].solverData);
      break;
#endif
    case NLS_HOMOTOPY:
      allocateHomotopyData(size, &nonlinsys[i].solverData);
      break;
#if !defined(OMC_MINIMAL_RUNTIME)
    case NLS_MIXED:
      mixedSolverData = (struct dataNewtonAndHybrid*) malloc(sizeof(struct dataNewtonAndHybrid));
      allocateHomotopyData(size, &(mixedSolverData->newtonData));

      allocateHybrdData(size, &(mixedSolverData->hybridData));

      nonlinsys[i].solverData = (void*) mixedSolverData;

      break;
#endif
    default:
      throwStreamPrint(data->threadData, "unrecognized nonlinear solver");
    }
  }

  messageClose(LOG_NLS);

  TRACE_POP
  return 0;
}

/*! \fn int updateStaticDataOfNonlinearSystems(DATA *data)
 *
 *  This function allocates memory for all nonlinear systems.
 *
 *  \param [ref] [data]
 */
int updateStaticDataOfNonlinearSystems(DATA *data)
{
  TRACE_PUSH
  int i;
  int size;
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo.nonlinearSystemData;
  struct dataNewtonAndHybrid *mixedSolverData;

  infoStreamPrint(LOG_NLS, 1, "update static data of non-linear system solvers");

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
  {
    nonlinsys[i].initializeStaticNLSData(data, &nonlinsys[i]);
  }

  messageClose(LOG_NLS);

  TRACE_POP
  return 0;
}

/*! \fn freeNonlinearSystems
 *
 *  This function frees memory of nonlinear systems.
 *
 *  \param [ref] [data]
 */
int freeNonlinearSystems(DATA *data)
{
  TRACE_PUSH
  int i;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;

  infoStreamPrint(LOG_NLS, 1, "free non-linear system solvers");

  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
  {
    free(nonlinsys[i].nlsx);
    free(nonlinsys[i].nlsxExtrapolation);
    free(nonlinsys[i].nlsxOld);
    free(nonlinsys[i].nominal);
    free(nonlinsys[i].min);
    free(nonlinsys[i].max);

    /* free solver data */
    switch(data->simulationInfo.nlsMethod)
    {
#if !defined(OMC_MINIMAL_RUNTIME)
    case NLS_HYBRID:
      freeHybrdData(&nonlinsys[i].solverData);
      break;
    case NLS_KINSOL:
      nls_kinsol_free(&nonlinsys[i]);
      break;
    case NLS_NEWTON:
      freeNewtonData(&nonlinsys[i].solverData);
      break;
#endif
    case NLS_HOMOTOPY:
      freeHomotopyData(&nonlinsys[i].solverData);
      break;
#if !defined(OMC_MINIMAL_RUNTIME)
    case NLS_MIXED:
      freeHomotopyData(&((struct dataNewtonAndHybrid*) nonlinsys[i].solverData)->newtonData);
      freeHybrdData(&((struct dataNewtonAndHybrid*) nonlinsys[i].solverData)->hybridData);
      break;
#endif
    default:
      throwStreamPrint(data->threadData, "unrecognized nonlinear solver");
    }
    free(nonlinsys[i].solverData);
  }

  messageClose(LOG_NLS);

  TRACE_POP
  return 0;
}

/*! \fn int printNonLinearSystemSolvingStatistics(DATA *data)
 *
 *  This function print memory for all non-linear systems.
 *
 *  \param [ref] [data]
 *         [in]  [sysNumber] index of corresponding non-linear system
 */
void printNonLinearSystemSolvingStatistics(DATA *data, int sysNumber, int logLevel)
{
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo.nonlinearSystemData;
  infoStreamPrint(logLevel, 1, "Non-linear system %d of size %d solver statistics:", (int)nonlinsys[sysNumber].equationIndex, (int)nonlinsys[sysNumber].size);
  infoStreamPrint(logLevel, 0, " number of calls                : %ld", nonlinsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " number of iterations           : %ld", nonlinsys[sysNumber].numberOfIterations);
  infoStreamPrint(logLevel, 0, " number of function evaluations : %ld", nonlinsys[sysNumber].numberOfFEval);
  infoStreamPrint(logLevel, 0, " average time per call          : %f", nonlinsys[sysNumber].totalTime/nonlinsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " total time                     : %f", nonlinsys[sysNumber].totalTime);
  messageClose(logLevel);
}


/*! \fn solve non-linear systems
 *
 *  \param [in]  [data]
 *  \param [in]  [sysNumber] index of corresponding non-linear system
 *
 *  \author wbraun
 */
int solve_nonlinear_system(DATA *data, int sysNumber)
{
  int success = 0, saveJumpState;
  NONLINEAR_SYSTEM_DATA* nonlinsys = &(data->simulationInfo.nonlinearSystemData[sysNumber]);
  threadData_t *threadData = data->threadData;
  struct dataNewtonAndHybrid *mixedSolverData;

  data->simulationInfo.currentNonlinearSystemIndex = sysNumber;

  /* enable to avoid division by zero */
  data->simulationInfo.noThrowDivZero = 1;
  ((DATA*)data)->simulationInfo.solveContinuous = 1;


  rt_ext_tp_tick(&nonlinsys->totalTimeClock);

  if(data->simulationInfo.discreteCall){
    double *fvec = malloc(sizeof(double)*nonlinsys->size);
    int success = 0;

#ifndef OMC_EMCC
    /* try */
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

    ((DATA*)data)->simulationInfo.solveContinuous = 0;
    nonlinsys->residualFunc((void*) data, nonlinsys->nlsx, fvec, (int*)&nonlinsys->size);
    ((DATA*)data)->simulationInfo.solveContinuous = 1;

    success = 1;
#ifndef OMC_EMCC
    /*catch */
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
    if (!success) {
      warningStreamPrint(LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");
    }

    free(fvec);
  }

  /* strategy for solving nonlinear system
   *
   *
   *
   */
#ifndef OMC_EMCC
    /* try */
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  switch(data->simulationInfo.nlsMethod)
  {
#if !defined(OMC_MINIMAL_RUNTIME)
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
#endif
  case NLS_HOMOTOPY:
    saveJumpState = data->threadData->currentErrorStage;
    data->threadData->currentErrorStage = ERROR_NONLINEARSOLVER;
    success = solveHomotopy(data, sysNumber);
    data->threadData->currentErrorStage = saveJumpState;
    break;
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_MIXED:
    mixedSolverData = nonlinsys->solverData;
    nonlinsys->solverData = mixedSolverData->newtonData;

    saveJumpState = data->threadData->currentErrorStage;
    data->threadData->currentErrorStage = ERROR_NONLINEARSOLVER;
    success = solveHomotopy(data, sysNumber);
    if (!success) {
      nonlinsys->solverData = mixedSolverData->hybridData;
      success = solveHybrd(data, sysNumber);
    }
    data->threadData->currentErrorStage = saveJumpState;
    nonlinsys->solverData = mixedSolverData;
    break;
#endif
  default:
    throwStreamPrint(data->threadData, "unrecognized nonlinear solver");
  }
  nonlinsys->solved = success;

#ifndef OMC_EMCC
    /*catch */
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  /* enable to avoid division by zero */
  data->simulationInfo.noThrowDivZero = 0;
  ((DATA*)data)->simulationInfo.solveContinuous = 0;

  nonlinsys->totalTime += rt_ext_tp_tock(&(nonlinsys->totalTimeClock));
  nonlinsys->numberOfCall++;

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
    for(j=0; j<modelInfoGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).numVar; ++j) {
      int done=0;
      long k;
      const MODEL_DATA *mData = &(data->modelData);
      for(k=0; k<mData->nVariablesReal && !done; ++k)
      {
        if (!strcmp(mData->realVarsData[k].info.name, modelInfoGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).vars[j]))
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
        warningStreamPrint(LOG_NLS, 0, "[%ld] Real %s(start=?, nominal=?)", j+1, modelInfoGetEquation(&data->modelData.modelDataXml, (nonlinsys[i]).equationIndex).vars[j]);
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
double extraPolate(DATA *data, const double old1, const double old2, const double minValue, const double maxValue)
{
  double retValue;

  if(data->localData[1]->timeValue == data->localData[2]->timeValue || old1 == old2)
  {
    retValue = old1;
  }
  else
  {
    retValue = old2 + ((data->localData[0]->timeValue - data->localData[2]->timeValue)/(data->localData[1]->timeValue - data->localData[2]->timeValue)) * (old1-old2);

    if(retValue < minValue && old1 > minValue)  retValue = minValue;
    else if(retValue > maxValue && old1 < maxValue ) retValue = maxValue;

  }

  return retValue;
}

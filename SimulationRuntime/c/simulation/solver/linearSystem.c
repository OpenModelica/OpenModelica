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

/*! \file linearSystem.c
 */

#include <math.h>
#include <string.h>

#include "model_help.h"
#include "../../util/omc_error.h"
#include "../../util/rtclock.h"
#include "nonlinearSystem.h"
#include "linearSystem.h"
#include "linearSolverLapack.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "linearSolverKlu.h"
#include "linearSolverLis.h"
#include "linearSolverUmfpack.h"
#endif
#include "linearSolverTotalPivot.h"
#include "../simulation_info_json.h"

static void setAElement(int row, int col, double value, int nth, void *data, threadData_t *);
static void setAElementLis(int row, int col, double value, int nth, void *data, threadData_t *);
static void setAElementUmfpack(int row, int col, double value, int nth, void *data, threadData_t *);
static void setAElementKlu(int row, int col, double value, int nth, void *data, threadData_t *);
static void setBElement(int row, double value, void *data, threadData_t*);
static void setBElementLis(int row, double value, void *data, threadData_t*);

int check_linear_solution(DATA *data, int printFailingSystems, int sysNumber);

/*! \fn int initializeLinearSystems(DATA *data)
 *
 *  This function allocates memory for all linear systems.
 *
 *  \param [ref] [data]
 */
int initializeLinearSystems(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int i, nnz;
  int size;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo->linearSystemData;

  infoStreamPrint(LOG_LS, 1, "initialize linear system solvers");
  infoStreamPrint(LOG_LS, 0, "%ld linear systems", data->modelData->nLinearSystems);

  if (LSS_DEFAULT == data->simulationInfo->lssMethod) {
#ifdef WITH_UMFPACK
    data->simulationInfo->lssMethod = LSS_KLU;
#elif !defined(OMC_MINIMAL_RUNTIME)
    data->simulationInfo->lssMethod = LSS_LIS;
#endif
  }

  for(i=0; i<data->modelData->nLinearSystems; ++i)
  {
    size = linsys[i].size;
    nnz = linsys[i].nnz;

    linsys[i].totalTime = 0;
    linsys[i].failed = 0;

    /* allocate system data */
    linsys[i].b = (double*) malloc(size*sizeof(double));

    /* check if analytical jacobian is created */
    if (1 == linsys[i].method)
    {
      ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[linsys[i].jacobianIndex]);
      if(linsys[i].jacobianIndex != -1)
      {
        assertStreamPrint(threadData, 0 != linsys[i].analyticalJacobianColumn, "jacobian function pointer is invalid" );
      }
      if(linsys[i].initialAnalyticalJacobian(data, threadData, jacobian))
      {
        linsys[i].jacobianIndex = -1;
        throwStreamPrint(threadData, "Failed to initialize the jacobian for torn linear system %d.", (int)linsys[i].equationIndex);
      }
      nnz = jacobian->sparsePattern.numberOfNoneZeros;
      linsys[i].nnz = nnz;
    }

    if(nnz/(double)(size*size)<=linearSparseSolverMaxDensity && size>=linearSparseSolverMinSize)
    {
      linsys[i].useSparseSolver = 1;
      infoStreamPrint(LOG_STDOUT, 0, "Using sparse solver for linear system %d,\nbecause density of %.3f remains under threshold of %.3f and size of %d exceeds threshold of %d.\nThe maximum density and the minimal system size for using sparse solvers can be specified\nusing the runtime flags '<-lssMaxDensity=value>' and '<-lssMinSize=value>'.", i, nnz/(double)(size*size), linearSparseSolverMaxDensity, size, linearSparseSolverMinSize);
    }

    /* allocate more system data */
    linsys[i].nominal = (double*) malloc(size*sizeof(double));
    linsys[i].min = (double*) malloc(size*sizeof(double));
    linsys[i].max = (double*) malloc(size*sizeof(double));

    linsys[i].initializeStaticLSData(data, threadData, &linsys[i]);

    /* allocate solver data */
    /* the implementation of matrix A is solver-specific */
    if(linsys[i].useSparseSolver == 1)
    {
      switch(data->simulationInfo->lssMethod)
      {
    #ifdef WITH_UMFPACK
      case LSS_UMFPACK:
        linsys[i].setAElement = setAElementUmfpack;
        linsys[i].setBElement = setBElement;
        allocateUmfPackData(size, size, nnz, linsys[i].solverData);
        break;
      case LSS_KLU:
        linsys[i].setAElement = setAElementKlu;
        linsys[i].setBElement = setBElement;
        allocateKluData(size, size, nnz, linsys[i].solverData);
        break;
    #else
      case LSS_KLU:
      case LSS_UMFPACK:
        throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use klu or umfpack please compile OMC with UMFPACK.");
        break;
    #endif
    #if !defined(OMC_MINIMAL_RUNTIME)
      case LSS_LIS:
        linsys[i].setAElement = setAElementLis;
        linsys[i].setBElement = setBElementLis;
        allocateLisData(size, size, nnz, linsys[i].solverData);
        break;
    #else
      case LSS_LIS_NOT_AVAILABLE:
        throwStreamPrint(threadData, "OMC is compiled without sparse linear solver Lis.");
        break;
    #endif
    #if defined(OMC_MINIMAL_RUNTIME) && !defined(WITH_UMFPACK)
      case LSS_DEFAULT:
        {
          int indexes[2] = {1, linsys[i].equationIndex};
          infoStreamPrintWithEquationIndexes(LOG_STDOUT, 0, indexes, "The simulation runtime does not have access to sparse solvers. Defaulting to a dense linear system solver instead.");
          linsys[i].useSparseSolver = 0;
          break;
        }
    #endif
      default:
        throwStreamPrint(threadData, "unrecognized sparse linear solver (%d)", data->simulationInfo->lssMethod);
      }
    }
    if(linsys[i].useSparseSolver == 0) { /* Not an else-statement because there might not be a sparse linear solver available */
    switch(data->simulationInfo->lsMethod)
    {
      case LS_LAPACK:
        linsys[i].A = (double*) malloc(size*size*sizeof(double));
        linsys[i].setAElement = setAElement;
        linsys[i].setBElement = setBElement;
        allocateLapackData(size, linsys[i].solverData);
        break;

    #if !defined(OMC_MINIMAL_RUNTIME)
      case LS_LIS:
        linsys[i].setAElement = setAElementLis;
        linsys[i].setBElement = setBElementLis;
        allocateLisData(size, size, nnz, linsys[i].solverData);
        break;
    #endif
    #ifdef WITH_UMFPACK
      case LS_UMFPACK:
        linsys[i].setAElement = setAElementUmfpack;
        linsys[i].setBElement = setBElement;
        allocateUmfPackData(size, size, nnz, linsys[i].solverData);
        break;
      case LS_KLU:
        linsys[i].setAElement = setAElementKlu;
        linsys[i].setBElement = setBElement;
        allocateKluData(size, size, nnz, linsys[i].solverData);
        break;
    #else
      case LS_UMFPACK:
        throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
        break;
    #endif

      case LS_TOTALPIVOT:
        linsys[i].A = (double*) malloc(size*size*sizeof(double));
        linsys[i].setAElement = setAElement;
        linsys[i].setBElement = setBElement;
        allocateTotalPivotData(size, linsys[i].solverData);
        break;

      case LS_DEFAULT:
        linsys[i].A = (double*) malloc(size*size*sizeof(double));
        linsys[i].setAElement = setAElement;
        linsys[i].setBElement = setBElement;

        allocateLapackData(size, linsys[i].solverData);
        allocateTotalPivotData(size, linsys[i].solverData);

        break;

      default:
        throwStreamPrint(threadData, "unrecognized dense linear solver (%d)", data->simulationInfo->lsMethod);
      }
    }
  }

  messageClose(LOG_LS);

  TRACE_POP
  return 0;
}

/*! \fn int updateStaticDataOfLinearSystems(DATA *data)
 *
 *  This function allocates memory for all linear systems.
 *
 *  \param [ref] [data]
 */
int updateStaticDataOfLinearSystems(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int i, nnz;
  int size;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo->linearSystemData;

  infoStreamPrint(LOG_LS_V, 1, "update static data of linear system solvers");

  for(i=0; i<data->modelData->nLinearSystems; ++i)
  {
    linsys[i].initializeStaticLSData(data, threadData, &linsys[i]);
  }

  messageClose(LOG_LS_V);

  TRACE_POP
  return 0;
}

/*! \fn int printLinearSystemStatistics(DATA *data)
 *
 *  This function print memory for all linear systems.
 *
 *  \param [ref] [data]
 *         [in]  [sysNumber] index of corresponding linear System
 */
void printLinearSystemSolvingStatistics(DATA *data, int sysNumber, int logLevel)
{
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo->linearSystemData;
  infoStreamPrint(logLevel, 1, "Linear system %d with (size = %d, nonZeroElements = %d, density = %.2f %%) solver statistics:",
                               (int)linsys[sysNumber].equationIndex, (int)linsys[sysNumber].size, (int)linsys[sysNumber].nnz,
                               (((double) linsys[sysNumber].nnz) / ((double)(linsys[sysNumber].size*linsys[sysNumber].size)))*100 );
  infoStreamPrint(logLevel, 0, " number of calls                : %ld", linsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " average time per call          : %g", linsys[sysNumber].totalTime/linsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " time of jacobian evaluations   : %g", linsys[sysNumber].jacobianTime);
  infoStreamPrint(logLevel, 0, " total time                     : %g", linsys[sysNumber].totalTime);
  messageClose(logLevel);
}

/*! \fn freeLinearSystems
 *
 *  This function frees memory of linear systems.
 *
 *  \param [ref] [data]
 */
int freeLinearSystems(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int i;
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo->linearSystemData;

  infoStreamPrint(LOG_LS_V, 1, "free linear system solvers");
  for(i=0; i<data->modelData->nLinearSystems; ++i)
  {
    /* free system and solver data */
    free(linsys[i].b);
    free(linsys[i].nominal);
    free(linsys[i].min);
    free(linsys[i].max);

    if(linsys[i].useSparseSolver == 1)
    {
      switch(data->simulationInfo->lssMethod)
      {
    #if !defined(OMC_MINIMAL_RUNTIME)
      case LSS_LIS:
        freeLisData(linsys[i].solverData);
        break;
    #endif

    #ifdef WITH_UMFPACK
      case LSS_UMFPACK:
        freeUmfPackData(linsys[i].solverData);
        break;
      case LSS_KLU:
        freeKluData(linsys[i].solverData);
        break;
    #else
      case LSS_UMFPACK:
        throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
        break;
    #endif

      default:
        throwStreamPrint(threadData, "unrecognized sparse linear solver (%d)", data->simulationInfo->lssMethod);
      }
    }

    else{
      switch(data->simulationInfo->lsMethod)
      {
      case LS_LAPACK:
        freeLapackData(linsys[i].solverData);
        free(linsys[i].A);
        break;

  #if !defined(OMC_MINIMAL_RUNTIME)
      case LS_LIS:
        freeLisData(linsys[i].solverData);
        break;
  #endif

  #ifdef WITH_UMFPACK
      case LS_UMFPACK:
        freeUmfPackData(linsys[i].solverData);
        break;
      case LS_KLU:
        freeKluData(linsys[i].solverData);
        break;
  #else
      case LS_UMFPACK:
        throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
        break;
  #endif

      case LS_TOTALPIVOT:
        free(linsys[i].A);
        freeTotalPivotData(linsys[i].solverData);
        break;

      case LS_DEFAULT:
        free(linsys[i].A);
        freeLapackData(linsys[i].solverData);
        freeTotalPivotData(linsys[i].solverData);
        break;

      default:
        throwStreamPrint(threadData, "unrecognized dense linear solver (data->simulationInfo->lsMethod)");
      }
    }

    if (linsys[i].solverData[0]) {
      free(linsys[i].solverData[0]);
      linsys[i].solverData[0] = 0;
    }
    if (linsys[i].solverData[1]) {
      free(linsys[i].solverData[1]);
      linsys[i].solverData[1] = 0;
    }
  }

  messageClose(LOG_LS_V);

  TRACE_POP
  return 0;
}

/*! \fn solve linear system
 *
 *  \param [in]  [data]
 *         [in]  [sysNumber] index of corresponding linear System
 *
 *  \author wbraun
 */
int solve_linear_system(DATA *data, threadData_t *threadData, int sysNumber, double* aux_x)
{
  TRACE_PUSH
  int success;
  int retVal;
  int logLevel;
  LINEAR_SYSTEM_DATA* linsys = &(data->simulationInfo->linearSystemData[sysNumber]);

  rt_ext_tp_tick(&(linsys->totalTimeClock));

  /* enable to avoid division by zero */
  data->simulationInfo->noThrowDivZero = 1;

  if(linsys->useSparseSolver == 1)
  {
    switch(data->simulationInfo->lssMethod)
    {
  #if !defined(OMC_MINIMAL_RUNTIME)
    case LSS_LIS:
      success = solveLis(data, threadData, sysNumber, aux_x);
      break;
  #else
    case LSS_LIS_NOT_AVAILABLE:
      throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
      break;
  #endif
  #ifdef WITH_UMFPACK
    case LSS_KLU:
      success = solveKlu(data, threadData, sysNumber, aux_x);
      break;
    case LSS_UMFPACK:
      success = solveUmfPack(data, threadData, sysNumber, aux_x);
      if (!success && linsys->strictTearingFunctionCall != NULL){
        debugString(LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
        success = linsys->strictTearingFunctionCall(data, threadData);
        if (success) success=2;
      }
      break;
  #else
    case LSS_KLU:
    case LSS_UMFPACK:
      throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
      break;
  #endif
    default:
      throwStreamPrint(threadData, "unrecognized sparse linear solver (%d)", data->simulationInfo->lssMethod);
    }
  }

  else{
    switch(data->simulationInfo->lsMethod)
    {
    case LS_LAPACK:
      success = solveLapack(data, threadData, sysNumber, aux_x);
      break;

  #if !defined(OMC_MINIMAL_RUNTIME)
    case LS_LIS:
      success = solveLis(data, threadData, sysNumber, aux_x);
      break;
  #endif
  #ifdef WITH_UMFPACK
    case LS_KLU:
      success = solveKlu(data, threadData, sysNumber, aux_x);
      break;
    case LS_UMFPACK:
      success = solveUmfPack(data, threadData, sysNumber, aux_x);
      if (!success && linsys->strictTearingFunctionCall != NULL){
        debugString(LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
        success = linsys->strictTearingFunctionCall(data, threadData);
        if (success) success=2;
      }
      break;
  #else
    case LS_UMFPACK:
      throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
      break;
  #endif

    case LS_TOTALPIVOT:
      success = solveTotalPivot(data, threadData, sysNumber, aux_x);
      break;

    case LS_DEFAULT:
      success = solveLapack(data, threadData, sysNumber, aux_x);

      /* check if solution process was successful, if not use alternative tearing set if available (dynamic tearing)*/
      if (!success && linsys->strictTearingFunctionCall != NULL){
        debugString(LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
        success = linsys->strictTearingFunctionCall(data, threadData);
        if (success){
          success=2;
          linsys->failed = 0;
        }
        else{
          linsys->failed = 1;
        }
      }
      else{
      /* if there is no alternative tearing set, use fallback solver */
      if (!success){
        if (linsys->failed){
          logLevel = LOG_LS;
        } else {
          logLevel = LOG_STDOUT;
        }
        warningStreamPrint(logLevel, 0, "The default linear solver fails, the fallback solver with total pivoting is started at time %f. That might raise performance issues, for more information use -lv LOG_LS.", data->localData[0]->timeValue);
        success = solveTotalPivot(data, threadData, sysNumber, aux_x);
        linsys->failed = 1;
      }else{
        linsys->failed = 0;
      }
      }
      break;

    default:
      throwStreamPrint(threadData, "unrecognized dense linear solver (%d)", data->simulationInfo->lsMethod);
    }
  }
  linsys->solved = success;

  linsys->totalTime += rt_ext_tp_tock(&(linsys->totalTimeClock));
  linsys->numberOfCall++;

  retVal = check_linear_solution(data, 1, sysNumber);

  TRACE_POP
  return retVal;
}

/*! \fn check_linear_solutions
 *
 *   This function check whether some of linear systems
 *   are failed to solve. If one is failed it returns 1 otherwise 0.
 *
 *  \param [in]  [data]
 *  \param [in]  [printFailingSystems]
 *  \param [out] [returnValue] It returns >0 if fail otherwise 0.
 *
 *  \author wbraun
 */
int check_linear_solutions(DATA *data, int printFailingSystems)
{
  TRACE_PUSH
  long i;

  for(i=0; i<data->modelData->nLinearSystems; ++i)
  {
    if(check_linear_solution(data, printFailingSystems, i))
    {
      TRACE_POP
      return 1;
    }
  }

  TRACE_POP
  return 0;
}

/*! \fn check_linear_solution
 *   This function check whether some of linear systems
 *   are failed to solve. If one is failed it returns 1 otherwise 0.
 *
 *  \param [in]  [data]
 *  \param [in]  [printFailingSystems]
 *  \param [in]  [sysNumber] index of corresponding linear System
 *  \param [out] [returnValue] It returns 1 if fail otherwise 0.
 *
 *  \author wbraun
 */
int check_linear_solution(DATA *data, int printFailingSystems, int sysNumber)
{
  TRACE_PUSH
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo->linearSystemData;
  long j, i = sysNumber;

  if(linsys[i].solved == 0)
  {
    int index = linsys[i].equationIndex, indexes[2] = {1,index};
    if (!printFailingSystems)
    {
      TRACE_POP
      return 1;
    }
    warningStreamPrintWithEquationIndexes(LOG_STDOUT, 1, indexes, "Solving linear system %d fails at time %g. For more information use -lv LOG_LS.", index, data->localData[0]->timeValue);

    for(j=0; j<modelInfoGetEquation(&data->modelData->modelDataXml, (linsys[i]).equationIndex).numVar; ++j) {
      int done=0;
      long k;
      const MODEL_DATA *mData = data->modelData;
      for(k=0; k<mData->nVariablesReal && !done; ++k)
      {
        if (!strcmp(mData->realVarsData[k].info.name, modelInfoGetEquation(&data->modelData->modelDataXml, (linsys[i]).equationIndex).vars[j]))
        {
        done = 1;
        warningStreamPrint(LOG_LS, 0, "[%ld] Real %s(start=%g, nominal=%g)", j+1,
                                     mData->realVarsData[k].info.name,
                                     mData->realVarsData[k].attribute.start,
                                     mData->realVarsData[k].attribute.nominal);
        }
      }
      if (!done)
      {
        warningStreamPrint(LOG_LS, 0, "[%ld] Real %s(start=?, nominal=?)", j+1, modelInfoGetEquation(&data->modelData->modelDataXml, (linsys[i]).equationIndex).vars[j]);
      }
    }
    messageCloseWarning(LOG_STDOUT);

    TRACE_POP
    return 1;
  }

  if(linsys[i].solved == 2)
  {
    linsys[i].solved = 1;
    return 2;
  }

  TRACE_POP
  return 0;
}

/*! \fn setAElement
 *  This function sets the (col, row)-value of linsys->A.
 *
 *  \param [in]  [row]
 *  \param [in]  [col]
 *  \param [in]  [value]
 *  \param [in]  [nth] number element in matrix,
 *                     is ingored here, used only for sparse
 *  \param [ref] [data]
 *
 */
static void setAElement(int row, int col, double value, int nth, void *data, threadData_t *threadData)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  linsys->A[row + col * linsys->size] = value;
}

/*! \fn setBElement
 *  This function sets the row-th value of linsys->b[row] = value.
 *
 *  \param [in]  [row]
 *  \param [in]  [value]
 *  \param [ref] [data]
 */
static void setBElement(int row, double value, void *data, threadData_t *threadData)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  linsys->b[row] = value;
}

#if !defined(OMC_MINIMAL_RUNTIME)
static void setAElementLis(int row, int col, double value, int nth, void *data, threadData_t *threadData)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  DATA_LIS* sData = (DATA_LIS*) linsys->solverData[0];
  lis_matrix_set_value(LIS_INS_VALUE, row, col, value, sData->A);
}

static void setBElementLis(int row, double value, void *data, threadData_t *threadData)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  DATA_LIS* sData = (DATA_LIS*) linsys->solverData[0];
  lis_vector_set_value(LIS_INS_VALUE, row, value, sData->b);
}
#endif

#ifdef WITH_UMFPACK
static void setAElementUmfpack(int row, int col, double value, int nth, void *data, threadData_t *threadData)
{
  LINEAR_SYSTEM_DATA* linSys = (LINEAR_SYSTEM_DATA*) data;
  DATA_UMFPACK* sData = (DATA_UMFPACK*) linSys->solverData[0];

  infoStreamPrint(LOG_LS_V, 0, " set %d. -> (%d,%d) = %f", nth, row, col, value);
  if (row > 0){
    if (sData->Ap[row] == 0){
      sData->Ap[row] = nth;
    }
  }

  sData->Ai[nth] = col;
  sData->Ax[nth] = value;
}
static void setAElementKlu(int row, int col, double value, int nth, void *data, threadData_t *threadData)
{
  LINEAR_SYSTEM_DATA* linSys = (LINEAR_SYSTEM_DATA*) data;
  DATA_KLU* sData = (DATA_KLU*) linSys->solverData[0];

  if (row > 0){
    if (sData->Ap[row] == 0){
      sData->Ap[row] = nth;
    }
  }

  sData->Ai[nth] = col;
  sData->Ax[nth] = value;
}
#endif

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

#include "util/omc_error.h"
#include "util/rtclock.h"
#include "linearSystem.h"
#include "linearSolverLapack.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "linearSolverKlu.h"
#include "linearSolverLis.h"
#include "linearSolverUmfpack.h"
#endif
#include "linearSolverTotalPivot.h"
#include "simulation/simulation_info_json.h"

static void setAElement(int row, int col, double value, int nth, void *data, threadData_t *);
static void setAElementLis(int row, int col, double value, int nth, void *data, threadData_t *);
static void setAElementUmfpack(int row, int col, double value, int nth, void *data, threadData_t *);
static void setAElementKlu(int row, int col, double value, int nth, void *data, threadData_t *);
static void setBElement(int row, double value, void *data, threadData_t*);
static void setBElementLis(int row, double value, void *data, threadData_t*);

int check_linear_solution(DATA *data, int printFailingSystems, int sysNumber);

/* Data structure for the default solver
 * where two different solverData for lapack and
 * totalpivot as fallback
 */
struct dataLapackAndTotalPivot{
  void* lapackData;
  void* totalpivotData;
};

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
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo.linearSystemData;
  struct dataLapackAndTotalPivot *defaultSolverData;

  infoStreamPrint(LOG_LS_V, 1, "initialize linear system solvers");

  for(i=0; i<data->modelData.nLinearSystems; ++i)
  {
    size = linsys[i].size;
    nnz = linsys[i].nnz;

    linsys[i].totalTime = 0;
    linsys[i].failed = 0;

    /* allocate system data */
    linsys[i].x = (double*) malloc(size*sizeof(double));
    linsys[i].b = (double*) malloc(size*sizeof(double));

    /* check if analytical jacobian is created */
    if (1 == linsys[i].method)
    {
      if(linsys[i].jacobianIndex != -1)
      {
        assertStreamPrint(threadData, 0 != linsys[i].analyticalJacobianColumn, "jacobian function pointer is invalid" );
      }
      if(linsys[i].initialAnalyticalJacobian(data, threadData))
      {
        linsys[i].jacobianIndex = -1;
      }
      nnz = data->simulationInfo.analyticJacobians[linsys[i].jacobianIndex].sparsePattern.numberOfNoneZeros;
      linsys[i].nnz = nnz;
    }

    /* allocate more system data */
    linsys[i].nominal = (double*) malloc(size*sizeof(double));
    linsys[i].min = (double*) malloc(size*sizeof(double));
    linsys[i].max = (double*) malloc(size*sizeof(double));

    linsys[i].initializeStaticLSData(data, threadData, &linsys[i]);

    /* allocate solver data */
    /* the implementation of matrix A is solver-specific */
    switch(data->simulationInfo.lsMethod)
    {
    case LS_LAPACK:
      linsys[i].A = (double*) malloc(size*size*sizeof(double));
      linsys[i].setAElement = setAElement;
      linsys[i].setBElement = setBElement;
      allocateLapackData(size, &linsys[i].solverData);
      break;

#if !defined(OMC_MINIMAL_RUNTIME)
    case LS_LIS:
      linsys[i].setAElement = setAElementLis;
      linsys[i].setBElement = setBElementLis;
      allocateLisData(size, size, nnz, &linsys[i].solverData);
      break;
#endif
#ifdef WITH_UMFPACK
    case LS_UMFPACK:
      linsys[i].setAElement = setAElementUmfpack;
      linsys[i].setBElement = setBElement;
      allocateUmfPackData(size, size, nnz, &linsys[i].solverData);
      break;
    case LS_KLU:
      linsys[i].setAElement = setAElementKlu;
      linsys[i].setBElement = setBElement;
      allocateKluData(size, size, nnz, &linsys[i].solverData);
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
      allocateTotalPivotData(size, &(linsys[i].solverData));
      break;

    case LS_DEFAULT:
      defaultSolverData = (struct dataLapackAndTotalPivot*) malloc(sizeof(struct dataLapackAndTotalPivot));
      linsys[i].A = (double*) malloc(size*size*sizeof(double));
      linsys[i].setAElement = setAElement;
      linsys[i].setBElement = setBElement;

      allocateLapackData(size, &(defaultSolverData->lapackData));
      allocateTotalPivotData(size, &(defaultSolverData->totalpivotData));

      linsys[i].solverData = (void*) defaultSolverData;
      break;

    default:
      throwStreamPrint(threadData, "unrecognized linear solver");
    }
  }

  messageClose(LOG_LS_V);

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
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo.linearSystemData;

  infoStreamPrint(LOG_LS_V, 1, "update static data of linear system solvers");

  for(i=0; i<data->modelData.nLinearSystems; ++i)
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
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;
  infoStreamPrint(logLevel, 1, "Linear system %d with (size = %d, nonZeroElements = %d, density = %.2f %%) solver statistics:",
                               (int)linsys[sysNumber].equationIndex, (int)linsys[sysNumber].size, (int)linsys[sysNumber].nnz,
                               (((double) linsys[sysNumber].nnz) / ((double)(linsys[sysNumber].size*linsys[sysNumber].size)))*100 );
  infoStreamPrint(logLevel, 0, " number of calls                : %ld", linsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " average time per call          : %f", linsys[sysNumber].totalTime/linsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " total time                     : %f", linsys[sysNumber].totalTime);
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
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;

  infoStreamPrint(LOG_LS_V, 1, "free linear system solvers");
  for(i=0; i<data->modelData.nLinearSystems; ++i)
  {
    /* free system and solver data */
    free(linsys[i].x);
    free(linsys[i].b);
    free(linsys[i].nominal);
    free(linsys[i].min);
    free(linsys[i].max);

    switch(data->simulationInfo.lsMethod)
    {
    case LS_LAPACK:
      freeLapackData(&linsys[i].solverData);
      free(linsys[i].A);
      break;

#if !defined(OMC_MINIMAL_RUNTIME)
    case LS_LIS:
      freeLisData(&linsys[i].solverData);
      break;
#endif

#ifdef WITH_UMFPACK
    case LS_UMFPACK:
      freeUmfPackData(&linsys[i].solverData);
      break;
    case LS_KLU:
      freeKluData(&linsys[i].solverData);
      break;
#else
    case LS_UMFPACK:
      throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
      break;
#endif

    case LS_TOTALPIVOT:
      free(linsys[i].A);
      freeTotalPivotData(&(linsys[i].solverData));
      break;

    case LS_DEFAULT:
      free(linsys[i].A);
      freeLapackData(&((struct dataLapackAndTotalPivot*) linsys[i].solverData)->lapackData);
      freeTotalPivotData(&((struct dataLapackAndTotalPivot*) linsys[i].solverData)->totalpivotData);
      break;

    default:
      throwStreamPrint(threadData, "unrecognized linear solver");
    }

    free(linsys[i].solverData);
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
int solve_linear_system(DATA *data, threadData_t *threadData, int sysNumber)
{
  TRACE_PUSH
  int success;
  int retVal;
  int logLevel;
  LINEAR_SYSTEM_DATA* linsys = &(data->simulationInfo.linearSystemData[sysNumber]);
  struct dataLapackAndTotalPivot *defaultSolverData;

  rt_ext_tp_tick(&(linsys->totalTimeClock));
  switch(data->simulationInfo.lsMethod)
  {
  case LS_LAPACK:
    success = solveLapack(data, threadData, sysNumber);
    break;

#if !defined(OMC_MINIMAL_RUNTIME)
  case LS_LIS:
    success = solveLis(data, threadData, sysNumber);
    break;
#endif
#ifdef WITH_UMFPACK
  case LS_KLU:
    success = solveKlu(data, threadData, sysNumber);
    break;
  case LS_UMFPACK:
    success = solveUmfPack(data, threadData, sysNumber);
    break;
#else
  case LS_UMFPACK:
    throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
    break;
#endif

  case LS_TOTALPIVOT:
    success = solveTotalPivot(data, threadData, sysNumber);
    break;

  case LS_DEFAULT:
    defaultSolverData = linsys->solverData;
    linsys->solverData = defaultSolverData->lapackData;

    success = solveLapack(data, threadData, sysNumber);
    if (!success){
      if (linsys->failed){
        logLevel = LOG_LS;
      } else {
        logLevel = LOG_STDOUT;
      }
      warningStreamPrint(logLevel, 0, "The default linear solver fails, the fallback solver with total pivoting is started at time %f. That might raise performance issues, for more information use -lv LOG_LS.", data->localData[0]->timeValue);
      linsys->solverData = defaultSolverData->totalpivotData;
      success = solveTotalPivot(data, threadData, sysNumber);
      linsys->failed = 1;
    }else{
      linsys->failed = 0;
    }
    linsys->solverData = defaultSolverData;
    break;
  default:
    throwStreamPrint(threadData, "unrecognized linear solver");
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

  for(i=0; i<data->modelData.nLinearSystems; ++i)
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

/*! \fn check_linear_solutions
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
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;
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

    for(j=0; j<modelInfoGetEquation(&data->modelData.modelDataXml, (linsys[i]).equationIndex).numVar; ++j) {
      int done=0;
      long k;
      const MODEL_DATA *mData = &(data->modelData);
      for(k=0; k<mData->nVariablesReal && !done; ++k)
      {
        if (!strcmp(mData->realVarsData[k].info.name, modelInfoGetEquation(&data->modelData.modelDataXml, (linsys[i]).equationIndex).vars[j]))
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
        warningStreamPrint(LOG_LS, 0, "[%ld] Real %s(start=?, nominal=?)", j+1, modelInfoGetEquation(&data->modelData.modelDataXml, (linsys[i]).equationIndex).vars[j]);
      }
    }
    messageCloseWarning(LOG_STDOUT);

    TRACE_POP
    return 1;
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
  DATA_LIS* sData = (DATA_LIS*) linsys->solverData;
  lis_matrix_set_value(LIS_INS_VALUE, row, col, value, sData->A);
}

static void setBElementLis(int row, double value, void *data, threadData_t *threadData)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  DATA_LIS* sData = (DATA_LIS*) linsys->solverData;
  lis_vector_set_value(LIS_INS_VALUE, row, value, sData->b);
}
#endif

#ifdef WITH_UMFPACK
static void setAElementUmfpack(int row, int col, double value, int nth, void *data, threadData_t *threadData)
{
  LINEAR_SYSTEM_DATA* linSys = (LINEAR_SYSTEM_DATA*) data;
  DATA_UMFPACK* sData = (DATA_UMFPACK*) linSys->solverData;

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
  DATA_KLU* sData = (DATA_KLU*) linSys->solverData;

  if (row > 0){
    if (sData->Ap[row] == 0){
      sData->Ap[row] = nth;
    }
  }

  sData->Ai[nth] = col;
  sData->Ax[nth] = value;
}
#endif

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

#include "../../../../Compiler/runtime/config.h"
#include "omc_error.h"
#include "rtclock.h"
#include "linearSystem.h"
#include "linearSolverLapack.h"
#include "linearSolverLis.h"
#include "linearSolverUmfpack.h"
#include "linearSolverTotalPivot.h"
#include "simulation_info_xml.h"

int check_linear_solution(DATA *data, int printFailingSystems, int sysNumber);

const char *LS_NAME[LS_MAX+1] = {
  "LS_UNKNOWN",

  /* LS_LAPACK */       "lapack",
  /* LS_LIS */          "lis",
  /* LS_UMFPACK */      "umfpack",
  /* LS_TOTALPIVOT */   "totalpivot",

  "LS_MAX"
};

const char *LS_DESC[LS_MAX+1] = {
  "unknown",

  /* LS_LAPACK */       "method using lapack LU factorization",
  /* LS_LIS */          "method using iterativ solver Lis",
  /* LS_UMFPACK */      "method using umfpack sparse linear solver",
  /* LS_TOTALPIVOT */   "default method - using total pivoting LU factorization",

  "LS_MAX"
};

/*! \fn int initializeLinearSystems(DATA *data)
 *
 *  This function allocates memory for all linear systems.
 *
 *  \param [ref] [data]
 */
int initializeLinearSystems(DATA *data)
{
  TRACE_PUSH
  int i, nnz;
  int size;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo.linearSystemData;

  infoStreamPrint(LOG_LS_V, 1, "initialize linear system solvers");

  for(i=0; i<data->modelData.nLinearSystems; ++i)
  {
    size = linsys[i].size;
    nnz = linsys[i].nnz;

    linsys[i].totalTime = 0;

    /* allocate system data */
    linsys[i].x = (double*) malloc(size*sizeof(double));
    linsys[i].b = (double*) malloc(size*sizeof(double));

    /* check if analytical jacobian is created */
    if (1 == linsys[i].method)
    {
      if(linsys[i].jacobianIndex != -1)
      {
        assertStreamPrint(data->threadData, 0 != linsys[i].analyticalJacobianColumn, "jacobian function pointer is invalid" );
      }
      if(linsys[i].initialAnalyticalJacobian(data))
      {
        linsys[i].jacobianIndex = -1;
      }
    }

    /* allocate more system data */
    linsys[i].nominal = (double*) malloc(size*sizeof(double));
    linsys[i].min = (double*) malloc(size*sizeof(double));
    linsys[i].max = (double*) malloc(size*sizeof(double));

    linsys[i].initializeStaticLSData(data, &linsys[i]);

    /* allocate solver data */
    /* the implementation of matrix A is solver-specific */
    switch(data->simulationInfo.lsMethod)
    {
    case LS_LAPACK:
      linsys[i].A = (double*) malloc(size*size*sizeof(double));
      linsys[i].setAElement = setAElementLAPACK;
      linsys[i].setBElement = setBElementLAPACK;
      allocateLapackData(size, &linsys[i].solverData);
      break;

    case LS_LIS:
      linsys[i].setAElement = setAElementLis;
      linsys[i].setBElement = setBElementLis;
      allocateLisData(size, size, nnz, &linsys[i].solverData);
      break;

#ifdef WITH_UMFPACK
    case LS_UMFPACK:
      linsys[i].setAElement = setAElementUmfpack;
      linsys[i].setBElement = setBElementUmfpack;
      allocateUmfPackData(size, size, nnz, &linsys[i].solverData);
      break;
#else
    case LS_UMFPACK:
      throwStreamPrint(data->threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
      break;
#endif

    case LS_TOTALPIVOT:
      linsys[i].A = (double*) malloc(size*size*sizeof(double));
      linsys[i].setAElement = setAElementTotalPivot;
      linsys[i].setBElement = setBElementTotalPivot;
      allocateTotalPivotData(size, &(linsys[i].solverData));
      break;

    default:
      throwStreamPrint(data->threadData, "unrecognized linear solver");
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
int updateStaticDataOfLinearSystems(DATA *data)
{
  TRACE_PUSH
  int i, nnz;
  int size;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo.linearSystemData;

  infoStreamPrint(LOG_LS_V, 1, "update static data of linear system solvers");

  for(i=0; i<data->modelData.nLinearSystems; ++i)
  {
    linsys[i].initializeStaticLSData(data, &linsys[i]);
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
  infoStreamPrint(logLevel, 1, "Linear system %d of size %d solver statistics:", (int)linsys[sysNumber].equationIndex, (int)linsys[sysNumber].size);
  infoStreamPrint(logLevel, 0, " number of calls       : %ld", linsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " average time per call : %f", linsys[sysNumber].totalTime/linsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " total time            : %f", linsys[sysNumber].totalTime);
  messageClose(logLevel);
}

/*! \fn freeLinearSystems
 *
 *  This function frees memory of linear systems.
 *
 *  \param [ref] [data]
 */
int freeLinearSystems(DATA *data)
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

    case LS_LIS:
      freeLisData(&linsys[i].solverData);
      break;

#ifdef WITH_UMFPACK
    case LS_UMFPACK:
      freeUmfPackData(&linsys[i].solverData);
      break;
#else
    case LS_UMFPACK:
      throwStreamPrint(data->threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
      break;
#endif

    case LS_TOTALPIVOT:
      free(linsys[i].A);
      freeTotalPivotData(&(linsys[i].solverData));
      break;

    default:
      throwStreamPrint(data->threadData, "unrecognized linear solver");
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
int solve_linear_system(DATA *data, int sysNumber)
{
  TRACE_PUSH
  int success;
  int retVal;
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo.linearSystemData;

  rt_ext_tp_tick(&(linsys[sysNumber].totalTimeClock));
  switch(data->simulationInfo.lsMethod)
  {
  case LS_LAPACK:
    success = solveLapack(data, sysNumber);
    break;

  case LS_LIS:
    success = solveLis(data, sysNumber);
    break;
#ifdef WITH_UMFPACK
  case LS_UMFPACK:
    success = solveUmfPack(data, sysNumber);
    break;
#else
  case LS_UMFPACK:
    throwStreamPrint(data->threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
    break;
#endif

  case LS_TOTALPIVOT:
    success = solveTotalPivot(data, sysNumber);
    break;

  default:
    throwStreamPrint(data->threadData, "unrecognized linear solver");
  }
  linsys[sysNumber].solved = success;

  linsys[sysNumber].totalTime += rt_ext_tp_tock(&(linsys[sysNumber].totalTimeClock));
  linsys[sysNumber].numberOfCall++;

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
    warningStreamPrintWithEquationIndexes(LOG_LS, 1, indexes, "linear system %d fails: at t=%g", index, data->localData[0]->timeValue);

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
    messageCloseWarning(LOG_LS);

    TRACE_POP
    return 1;
  }

  TRACE_POP
  return 0;
}

void setAElementLAPACK(int row, int col, double value, int nth, void *data)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  linsys->A[row + col * linsys->size] = value;
}
void setBElementLAPACK(int row, double value, void *data )
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  linsys->b[row] = value;
}


void setAElementLis(int row, int col, double value, int nth, void *data)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  DATA_LIS* sData = (DATA_LIS*) linsys->solverData;
  lis_matrix_set_value(LIS_INS_VALUE, row, col, value, sData->A);
}

void setBElementLis(int row, double value, void *data )
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  DATA_LIS* sData = (DATA_LIS*) linsys->solverData;
  lis_vector_set_value(LIS_INS_VALUE, row, value, sData->b);
}

#ifdef WITH_UMFPACK
void setAElementUmfpack(int row, int col, double value, int nth, void *data)
{
  LINEAR_SYSTEM_DATA* linSys = (LINEAR_SYSTEM_DATA*) data;
  DATA_UMFPACK* sData = (DATA_UMFPACK*) linSys->solverData;

  if (row > 0)
     if (sData->Ap[row] == 0)
       sData->Ap[row] = nth;

   sData->Ai[nth] = col;
   sData->Ax[nth] = value;

}

void setBElementUmfpack(int row, double value, void *data)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  linsys->b[row] = value;
}
#endif

void setAElementTotalPivot(int row, int col, double value, int nth, void *data)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  linsys->A[row + col * linsys->size] = value;
}

void setBElementTotalPivot(int row, double value, void *data)
{
  LINEAR_SYSTEM_DATA* linsys = (LINEAR_SYSTEM_DATA*) data;
  linsys->b[row] = value;
}


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
#include "../../util/parallel_helper.h"
#include "../jacobian_util.h"
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

static void setAElement(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData);
static void setAElementLis(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData);
static void setAElementUmfpack(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData);
static void setAElementKlu(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData);
static void setBElement(int row, double value, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData);
static void setBElementLis(int row, double value, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData);

int check_linear_solution(DATA *data, int printFailingSystems, int sysNumber);

/*! \fn int initializeLinearSystems(DATA *data)
 *
 *  This function allocates memory for all linear systems.
 *
 *  \param [ref] [data]
 */
int initializeLinearSystems(DATA *data, threadData_t *threadData)
{
  int i, nnz;
  int size;
  int res;
  unsigned int j, maxNumberThreads;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo->linearSystemData;
  modelica_boolean someSmallDensity = 0;  /* pretty dumping of flag info */
  modelica_boolean someBigSize = 0;       /* analogous to someSmallDensity */

  maxNumberThreads = omc_get_max_threads();

  infoStreamPrint(OMC_LOG_LS, 1, "initialize linear system solvers");
  infoStreamPrint(OMC_LOG_LS, 0, "%ld linear systems", data->modelData->nLinearSystems);

  if (LSS_DEFAULT == data->simulationInfo->lssMethod) {
#ifdef WITH_SUITESPARSE
    data->simulationInfo->lssMethod = LSS_KLU;
#elif !defined(OMC_MINIMAL_RUNTIME)
    data->simulationInfo->lssMethod = LSS_LIS;
#endif
  }

  for(i=0; i<data->modelData->nLinearSystems; ++i)
  {
    res = allocLinSystThreadData(&(linsys[i]));
    assertStreamPrint(threadData, !res ,"Out of memory");

    size = linsys[i].size;
    nnz = linsys[i].nnz;
    linsys[i].totalTime = 0;
    linsys[i].failed = 0;

    /* allocate system data */
    for (j=0; j<maxNumberThreads; ++j)
    {
      linsys[i].parDynamicData[j].b = (double*) malloc(size*sizeof(double));
    }

    /* check if analytical jacobian is created */
    if (1 == linsys[i].method)
    {
      if(linsys[i].jacobianIndex != -1)
      {
        assertStreamPrint(threadData, 0 != linsys[i].analyticalJacobianColumn, "jacobian function pointer is invalid" );
      }
      JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[linsys[i].jacobianIndex]);
      if(linsys[i].initialAnalyticalJacobian(data, threadData, jacobian))
      {
        linsys[i].jacobianIndex = -1;
        throwStreamPrint(threadData, "Failed to initialize the jacobian for torn linear system %d.", (int)linsys[i].equationIndex);
      }
      nnz = jacobian->sparsePattern->numberOfNonZeros;
      linsys[i].nnz = nnz;

#ifdef USE_PARJAC
      /* Allocate jacobian for parDynamicData */
      for (j=0; j<maxNumberThreads; ++j)
      {
        // ToDo Simplify this. Only have one location for jacobian
        linsys[i].parDynamicData[j].jacobian = copyJacobian(jacobian);
      }
#else
      linsys[i].parDynamicData[0].jacobian = jacobian;
#endif
    }

    if (nnz/(double)(size*size) < linearSparseSolverMaxDensity) {
      linsys[i].useSparseSolver = 1;
      someSmallDensity = 1;
      if (size > linearSparseSolverMinSize) {
        someBigSize = 1;
        infoStreamPrint(OMC_LOG_STDOUT, 0,
                        "Using sparse solver for linear system %d,\n"
                        "because density of %.3f remains under threshold of %.3f\n"
                        "and size of %d exceeds threshold of %d.",
                        i, nnz/(double)(size*size), linearSparseSolverMaxDensity,
                        size, linearSparseSolverMinSize);
      } else {
        infoStreamPrint(OMC_LOG_STDOUT, 0,
                        "Using sparse solver for linear system %d,\n"
                        "because density of %.3f remains under threshold of %.3f.",
                        i, nnz/(double)(size*size), linearSparseSolverMaxDensity);
      }
    } else if (size > linearSparseSolverMinSize) {
      linsys[i].useSparseSolver = 1;
      someBigSize = 1;
        infoStreamPrint(OMC_LOG_STDOUT, 0,
                        "Using sparse solver for linear system %d,\n"
                        "because size of %d exceeds threshold of %d.",
                        i, size, linearSparseSolverMinSize);
    }

    /* Allocate nominal, min and max */
    linsys[i].nominal = (double*) malloc(size*sizeof(double));
    linsys[i].min = (double*) malloc(size*sizeof(double));
    linsys[i].max = (double*) malloc(size*sizeof(double));

    /* Init sparsitiy pattern */
    linsys[i].initializeStaticLSData(data, threadData, &linsys[i], 1 /* true */);

    /* allocate solver data */
    /* the implementation of matrix A is solver-specific */
    if(linsys[i].useSparseSolver == 1)
    {
      switch(data->simulationInfo->lssMethod)
      {
    #ifdef WITH_SUITESPARSE
      case LSS_UMFPACK:
        linsys[i].setAElement = setAElementUmfpack;
        linsys[i].setBElement = setBElement;
        for (j=0; j<maxNumberThreads; ++j)
        {
          allocateUmfPackData(size, size, nnz, linsys[i].parDynamicData[j].solverData);
        }
        break;
      case LSS_KLU:
        linsys[i].setAElement = setAElementKlu;
        linsys[i].setBElement = setBElement;
        for (j=0; j<maxNumberThreads; ++j)
        {
          allocateKluData(size, size, nnz, linsys[i].parDynamicData[j].solverData);
        }
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
        for (j=0; j<maxNumberThreads; ++j)
        {
          allocateLisData(size, size, nnz, linsys[i].parDynamicData[j].solverData);
        }
        break;
    #else
      case LSS_LIS_NOT_AVAILABLE:
        throwStreamPrint(threadData, "OMC is compiled without sparse linear solver Lis.");
        break;
    #endif
    #if defined(OMC_MINIMAL_RUNTIME) && !defined(WITH_SUITESPARSE)
      case LSS_DEFAULT:
        {
          int indexes[2] = {1, linsys[i].equationIndex};
          infoStreamPrintWithEquationIndexes(OMC_LOG_STDOUT, omc_dummyFileInfo, 0, indexes, "The simulation runtime does not have access to sparse solvers. Defaulting to a dense linear system solver instead.");
          linsys[i].useSparseSolver = 0;
          break;
        }
    #endif
      default:
        throwStreamPrint(threadData, "unrecognized sparse linear solver (%d)", data->simulationInfo->lssMethod);
      }
    }
    if(linsys[i].useSparseSolver == 0) /* Not an else-statement because there might not be a sparse linear solver available */
    {
      switch(data->simulationInfo->lsMethod)
      {
      case LS_LAPACK:
        linsys[i].setAElement = setAElement;
        linsys[i].setBElement = setBElement;
        for (j=0; j<maxNumberThreads; ++j)
        {
          linsys[i].parDynamicData[j].A = (double*) malloc(size*size*sizeof(double));
          allocateLapackData(size, linsys[i].parDynamicData[j].solverData);
        }

        break;

    #if !defined(OMC_MINIMAL_RUNTIME)
      case LS_LIS:
        linsys[i].setAElement = setAElementLis;
        linsys[i].setBElement = setBElementLis;
        for (j=0; j<maxNumberThreads; ++j)
        {
          allocateLisData(size, size, nnz, linsys[i].parDynamicData[j].solverData);
        }
        break;
    #endif
    #ifdef WITH_SUITESPARSE
      case LS_UMFPACK:
        linsys[i].setAElement = setAElementUmfpack;
        linsys[i].setBElement = setBElement;
        for (j=0; j<maxNumberThreads; ++j)
        {
          allocateUmfPackData(size, size, nnz, linsys[i].parDynamicData[j].solverData);
        }
        break;
      case LS_KLU:
        linsys[i].setAElement = setAElementKlu;
        linsys[i].setBElement = setBElement;
        for (j=0; j<maxNumberThreads; ++j)
        {
          allocateKluData(size, size, nnz, linsys[i].parDynamicData[j].solverData);
        }
        break;
    #else
      case LS_UMFPACK:
        throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
        break;
    #endif

      case LS_TOTALPIVOT:
        linsys[i].setAElement = setAElement;
        linsys[i].setBElement = setBElement;
        for (j=0; j<maxNumberThreads; ++j)
        {
          linsys[i].parDynamicData[j].A = (double*) malloc(size*size*sizeof(double));
          allocateTotalPivotData(size, linsys[i].parDynamicData[j].solverData);
        }
        break;

      case LS_DEFAULT:
        linsys[i].setAElement = setAElement;
        linsys[i].setBElement = setBElement;
        for (j=0; j<maxNumberThreads; ++j)
        {
          linsys[i].parDynamicData[j].A = (double*) malloc(size*size*sizeof(double));
          allocateLapackData(size, linsys[i].parDynamicData[j].solverData);
          allocateTotalPivotData(size, linsys[i].parDynamicData[j].solverData);
        }
        break;

      default:
        throwStreamPrint(threadData, "unrecognized dense linear solver (%d)", data->simulationInfo->lsMethod);
      }
    }
  }

  /* print relevant flag information */
  if(someSmallDensity) {
    if(someBigSize) {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "The maximum density and the minimal system size for using sparse solvers can be\n"
                                     "specified using the runtime flags '<-lssMaxDensity=value>' and '<-lssMinSize=value>'.");
    } else {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "The maximum density for using sparse solvers can be specified\n"
                                     "using the runtime flag '<-lssMaxDensity=value>'.");
    }
  } else if(someBigSize) {
    infoStreamPrint(OMC_LOG_STDOUT, 0, "The minimal system size for using sparse solvers can be specified\n"
                                   "using the runtime flag '<-lssMinSize=value>'.");
  }

  messageClose(OMC_LOG_LS);

  return 0;
}


/**
 * \brief Allocates memory for thread safe data struct for linear systems.
 *
 *  Allocates memory array of numberOfThreads many LINEAR_SYSTEM_THREAD_DATA structs.
 *  Returns -1 if out of memroy.
 *
 *  \param [in/out]   linsys
 */
int allocLinSystThreadData(LINEAR_SYSTEM_DATA *linsys)
{
  linsys->parDynamicData = (LINEAR_SYSTEM_THREAD_DATA*) malloc(omc_get_max_threads()*sizeof(LINEAR_SYSTEM_THREAD_DATA));
  if (!linsys->parDynamicData)
    return -1;
  return 0;
}

/**
 * \brief Frees memory allocated with `allocLinSystThreadData`
 *
 *  Frees complete array of numberOfThreads many LINEAR_SYSTEM_THREAD_DATA structs.
 *
 *  \param [in/out]   linsys
 */
void freeLinSystThreadData(LINEAR_SYSTEM_DATA *linsys)
{
  free(linsys->parDynamicData);
}

/**
 * @brief Set min, max, nominal for linear systems.
 *
 * This function allocates memory for sparsity pattern and
 * initialized nominal, min, max and spsarsity pattern.
 *
 * @param data          Pointer to data.
 * @param threadData    Thread data for error handling.
 * @return int          Return 0.
 */
int updateStaticDataOfLinearSystems(DATA *data, threadData_t *threadData)
{
  int i, nnz;
  int size;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo->linearSystemData;

  infoStreamPrint(OMC_LOG_LS_V, 1, "update static data of linear system solvers");

  for(i=0; i<data->modelData->nLinearSystems; ++i)
  {
    // check if LS is initialized
    if (linsys[i].nominal == NULL || linsys[i].min == NULL || linsys[i].max==NULL)
    {
      throwStreamPrint(threadData, "Static data of Linear system not initialized for linear system %i",i);
    }
    linsys[i].initializeStaticLSData(data, threadData, &linsys[i], 0 /* false */);
  }

  messageClose(OMC_LOG_LS_V);

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
  int i,j;
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo->linearSystemData;

  infoStreamPrint(OMC_LOG_LS_V, 1, "free linear system solvers");
  for(i=0; i<data->modelData->nLinearSystems; ++i)
  {
    /* free system and solver data */
    free(linsys[i].nominal); linsys[i].nominal = NULL;
    free(linsys[i].min); linsys[i].min = NULL;
    free(linsys[i].max); linsys[i].max = NULL;

    if (linsys[i].parDynamicData != NULL)
    {
      for (j=0; j<omc_get_max_threads(); ++j)
      {
        free(linsys[i].parDynamicData[j].b);
      }
    }

    /* ToDo Implement unique function to free a JACOBIAN */
    if (1 == linsys[i].method) {
      JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[linsys[i].jacobianIndex]);
      freeJacobian(jacobian);
      /* Note: The Jacobian of data->simulationInfo itself will be free later. */

#ifdef USE_PARJAC
      for (j=0; j<omc_get_max_threads(); ++j) {
        // Note: We cannot use neither freeJacobian() nor freeSparsePattern()
        //       since the sparsePattern points to data->simulationInfo->analyticJacobians[linsys[i].jacobianIndex]
        //       which is free some lines above (and are invalid pointers at this point). Thus, free
        //       what is left.
        free(linsys[i].parDynamicData[j].jacobian->seedVars); linsys[i].parDynamicData[j].jacobian->seedVars = NULL;
        free(linsys[i].parDynamicData[j].jacobian->resultVars); linsys[i].parDynamicData[j].jacobian->resultVars = NULL;
        free(linsys[i].parDynamicData[j].jacobian->tmpVars); linsys[i].parDynamicData[j].jacobian->tmpVars = NULL;
        linsys[i].parDynamicData[j].jacobian->sparsePattern = NULL;
        free(linsys[i].parDynamicData[j].jacobian); linsys[i].parDynamicData[j].jacobian = NULL;
      }
#endif
    }

    if(linsys[i].useSparseSolver == 1)
    {
      switch(data->simulationInfo->lssMethod)
      {
    #if !defined(OMC_MINIMAL_RUNTIME)
      case LSS_LIS:
        for (j=0; j<omc_get_max_threads(); ++j)
        {
          freeLisData(linsys[i].parDynamicData[j].solverData);
        }
        break;
    #endif

    #ifdef WITH_SUITESPARSE
      case LSS_UMFPACK:
        for (j=0; j<omc_get_max_threads(); ++j)
        {
          freeUmfPackData(linsys[i].parDynamicData[j].solverData);
        }
        break;
      case LSS_KLU:
        for (j=0; j<omc_get_max_threads(); ++j)
        {
          freeKluData(linsys[i].parDynamicData[j].solverData);
        }
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
    else { // useSparseSolver == 0
      switch(data->simulationInfo->lsMethod) {
      case LS_LAPACK:
        for (j=0; j<omc_get_max_threads(); ++j) {
          free(linsys[i].parDynamicData[j].A);
          freeLapackData(linsys[i].parDynamicData[j].solverData);
        }
        break;

  #if !defined(OMC_MINIMAL_RUNTIME)
      case LS_LIS:
        for (j=0; j<omc_get_max_threads(); ++j) {
          freeLisData(linsys[i].parDynamicData[j].solverData);
        }
        break;
  #endif

  #ifdef WITH_SUITESPARSE
      case LS_UMFPACK:
        for (j=0; j<omc_get_max_threads(); ++j)
        {
          freeUmfPackData(linsys[i].parDynamicData[j].solverData);
        }
        break;
      case LS_KLU:
        for (j=0; j<omc_get_max_threads(); ++j)
        {
          freeKluData(linsys[i].parDynamicData[j].solverData);
        }
        break;
  #else
      case LS_UMFPACK:
        throwStreamPrint(threadData, "OMC is compiled without UMFPACK, if you want use umfpack please compile OMC with UMFPACK.");
        break;
  #endif

      case LS_TOTALPIVOT:
        for (j=0; j<omc_get_max_threads(); ++j)
        {
          free(linsys[i].parDynamicData[j].A);
          freeTotalPivotData(linsys[i].parDynamicData[j].solverData);
        }
        break;

      case LS_DEFAULT:
        for (j=0; j<omc_get_max_threads(); ++j) {
          free(linsys[i].parDynamicData[j].A);
          freeLapackData(linsys[i].parDynamicData[j].solverData);
          freeTotalPivotData(linsys[i].parDynamicData[j].solverData);
        }
        break;

      default:
        throwStreamPrint(threadData, "unrecognized dense linear solver (%d)", data->simulationInfo->lsMethod);
      }
    }

    /* Free linear system thread data */
    freeLinSystThreadData(&(linsys[i]));
  }

  messageClose(OMC_LOG_LS_V);

  return 0;
}

/*! \fn solve linear system
 *
 *  \param  [ref]     data
 *          [ref]     threadData
 *          [in]      sysNumber   index of corresponding linear System
 *          [in/out]  aux_x       Auxiliary vector with values for x. Contains solution on output.
 */
int solve_linear_system(DATA *data, threadData_t *threadData, int sysNumber, double* aux_x)
{
  int retVal;
  int success;
  int logLevel;
  LINEAR_SYSTEM_DATA* linsys = &(data->simulationInfo->linearSystemData[sysNumber]);

  if (!linsys->logActive) {
    deactivateLogging();
  }

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
  #ifdef WITH_SUITESPARSE
    case LSS_KLU:
      success = solveKlu(data, threadData, sysNumber, aux_x);
      break;
    case LSS_UMFPACK:
      success = solveUmfPack(data, threadData, sysNumber, aux_x);
      if (!success && linsys->strictTearingFunctionCall != NULL){
        debugString(OMC_LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
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
  #ifdef WITH_SUITESPARSE
    case LS_KLU:
      success = solveKlu(data, threadData, sysNumber, aux_x);
      break;
    case LS_UMFPACK:
      success = solveUmfPack(data, threadData, sysNumber, aux_x);
      if (!success && linsys->strictTearingFunctionCall != NULL){
        debugString(OMC_LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
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
        debugString(OMC_LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
        success = linsys->strictTearingFunctionCall(data, threadData);
        if (success){
          success=2;
          linsys->failed = 0;
        }
        else {
          linsys->failed = 1;
        }
      }
      else{
      /* if there is no alternative tearing set, use fallback solver */
      if (!success){
        if (linsys->failed){
          logLevel = OMC_LOG_LS;
        } else {
          logLevel = OMC_LOG_STDOUT;
        }
        warningStreamPrintWithLimit(logLevel, 0, linsys->numberOfFailures, data->simulationInfo->maxWarnDisplays,
                                    "The default linear solver fails, the fallback solver with total pivoting is started at time %f. That might raise performance issues, for more information use -lv LOG_LS.", data->localData[0]->timeValue);
        success = solveTotalPivot(data, threadData, sysNumber, aux_x);
        linsys->failed = 1;
      } else {
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

  if (!linsys->logActive) {
    reactivateLogging();
  }

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
  long i;

  for(i=0; i<data->modelData->nLinearSystems; ++i)
  {
    if(check_linear_solution(data, printFailingSystems, i))
    {
      return 1;
    }
  }

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
  LINEAR_SYSTEM_DATA* linsys = data->simulationInfo->linearSystemData;
  long j, i = sysNumber;

  if(linsys[i].solved == 0)
  {
    int index = linsys[i].equationIndex, indexes[2] = {1,index};
    if (!printFailingSystems)
    {
      return 1;
    }
#ifdef USE_PARJAC
    warningStreamPrintWithEquationIndexes(OMC_LOG_STDOUT, omc_dummyFileInfo, 1, indexes, "Thread %u: Solving linear system %d fails at time %g. For more information use -lv LOG_LS.", omc_get_thread_num(), index, data->localData[0]->timeValue);
#else
    warningStreamPrintWithEquationIndexes(OMC_LOG_STDOUT, omc_dummyFileInfo, 1, indexes, "Solving linear system %d fails at time %g. For more information use -lv LOG_LS.", index, data->localData[0]->timeValue);
#endif

    for(j=0; j<modelInfoGetEquation(&data->modelData->modelDataXml, (linsys[i]).equationIndex).numVar; ++j) {
      int done=0;
      long k;
      const MODEL_DATA *mData = data->modelData;
      for(k=0; k<mData->nVariablesRealArray && !done; ++k)
      {
        if (!strcmp(mData->realVarsData[k].info.name, modelInfoGetEquation(&data->modelData->modelDataXml, (linsys[i]).equationIndex).vars[j]))
        {
        done = 1;
        warningStreamPrint(OMC_LOG_LS, 0, "[%ld] Real %s(start=%s, nominal=%s)",
                                     j+1,
                                     mData->realVarsData[k].info.name,
                                     real_vector_to_string(&mData->realVarsData[k].attribute.start, mData->realVarsData[k].dimension.numberOfDimensions == 0),
                                     real_vector_to_string(&mData->realVarsData[k].attribute.nominal, mData->realVarsData[k].dimension.numberOfDimensions == 0));
        }
      }
      if (!done)
      {
        warningStreamPrint(OMC_LOG_LS, 0, "[%ld] Real %s(start=?, nominal=?)", j+1, modelInfoGetEquation(&data->modelData->modelDataXml, (linsys[i]).equationIndex).vars[j]);
      }
    }
    messageCloseWarning(OMC_LOG_STDOUT);

    return 1;
  }

  if(linsys[i].solved == 2)
  {
    linsys[i].solved = 1;
    return 2;
  }

  return 0;
}

/*! \fn setAElement
 *  This function sets the (col, row)-value of linsys->A.
 *
 *  \param [in]  [row]
 *  \param [in]  [col]
 *  \param [in]  [value]
 *  \param [in]  [nth] number element in matrix,
 *                     is ignored here, used only for sparse
 *  \param [ref] [data]
 *
 */
static void setAElement(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData)
{
  linearSystemData->parDynamicData[omc_get_thread_num()].A[row + col * linearSystemData->size] = value;
}

/*! \fn setBElement
 *  This function sets the row-th value of linsys->b[row] = value.
 *
 *  \param [in]  [row]
 *  \param [in]  [value]
 *  \param [ref] [data]
 */
static void setBElement(int row, double value, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t *threadData)
{
  linearSystemData->parDynamicData[omc_get_thread_num()].b[row] = value;
}

#if !defined(OMC_MINIMAL_RUNTIME)
static void setAElementLis(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t *threadData)
{
  DATA_LIS* sData = (DATA_LIS*) linearSystemData->parDynamicData[omc_get_thread_num()].solverData[0];
  lis_matrix_set_value(LIS_INS_VALUE, row, col, value, sData->A);
}

static void setBElementLis(int row, double value, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t *threadData)
{
  DATA_LIS* sData = (DATA_LIS*) linearSystemData->parDynamicData[omc_get_thread_num()].solverData[0];
  lis_vector_set_value(LIS_INS_VALUE, row, value, sData->b);
}
#endif

#ifdef WITH_SUITESPARSE
static void setAElementUmfpack(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t *threadData)
{
  DATA_UMFPACK* sData = (DATA_UMFPACK*) linearSystemData->parDynamicData[omc_get_thread_num()].solverData[0];

  infoStreamPrint(OMC_LOG_LS_V, 0, " set %d. -> (%d,%d) = %f", nth, row, col, value);
  if (row > 0) {
    if (sData->Ap[row] == 0) {
      sData->Ap[row] = nth;
    }
  }

  sData->Ai[nth] = col;
  sData->Ax[nth] = value;
}

static void setAElementKlu(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t *threadData)
{
  DATA_KLU* sData = (DATA_KLU*) linearSystemData->parDynamicData[omc_get_thread_num()].solverData[0];

  if (row > 0) {
    if (sData->Ap[row] == 0) {
      sData->Ap[row] = nth;
    }
  }

  sData->Ai[nth] = col;
  sData->Ax[nth] = value;
}

#endif

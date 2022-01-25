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

#include "../../util/simulation_options.h"
#include "../../util/omc_error.h"
#include "../../util/omc_file.h"
#include "nonlinearSystem.h"
#include "nonlinearValuesList.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "kinsolSolver.h"
#include "nonlinearSolverHybrd.h"
#include "nonlinearSolverNewton.h"
#include "newtonIteration.h"
#include "newton_diagnostics.h"
#endif
#include "nonlinearSolverHomotopy.h"
#include "../options.h"
#include "../simulation_info_json.h"
#include "../simulation_runtime.h"
#include "model_help.h"

/* for try and catch simulationJumpBuffer */
#include "../../meta/meta_modelica.h"

int check_nonlinear_solution(DATA *data, int printFailingSystems, int sysNumber);

extern int init_lambda_steps;

struct dataSolver
{
  void* ordinaryData;
  void* initHomotopyData;
};

struct dataMixedSolver
{
  void* newtonHomotopyData;
  void* hybridData;
};

#if !defined(OMC_MINIMAL_RUNTIME)
#include "../../util/write_csv.h"
/*! \fn int initializeNLScsvData(DATA* data, NONLINEAR_SYSTEM_DATA* systemData)
 *
 *  This function initializes csv files for analysis propose.
 *
 *  \param [ref] [data]
 *  \param [ref] [systemData]
 */
int initializeNLScsvData(DATA* data, NONLINEAR_SYSTEM_DATA* systemData)
{
  struct csvStats* stats = (struct csvStats*) malloc(sizeof(struct csvStats));
  char buffer[100];
  sprintf(buffer, "%s_NLS%dStatsCall.csv", data->modelData->modelFilePrefix, (int)systemData->equationIndex);
  stats->callStats = omc_write_csv_init(buffer, ',', '"');

  sprintf(buffer, "%s_NLS%dStatsIter.csv", data->modelData->modelFilePrefix, (int)systemData->equationIndex);
  stats->iterStats = omc_write_csv_init(buffer, ',', '"');

  systemData->csvData = stats;

  return 0;
}
#else
int initializeNLScsvData(DATA* data, NONLINEAR_SYSTEM_DATA* systemData)
{
  fprintf(stderr, "initializeNLScsvData not implemented for OMC_MINIMAL_RUNTIME");
  abort();
}
#endif

#if !defined(OMC_MINIMAL_RUNTIME)
/*! \fn int print_csvLineCallStatsHeader(OMC_WRITE_CSV* csvData)
 *
 *  This function initializes csv files for analysis propose.
 *
 *  \param [ref] [data]
 *  \param [ref] [systemData]
 */
int print_csvLineCallStatsHeader(OMC_WRITE_CSV* csvData)
{
  char buffer[1024];
  buffer[0] = 0;

  /* number of call */
  sprintf(buffer,"numberOfCall");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* simulation time */
  sprintf(buffer,"simulationTime");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solving iterations */
  sprintf(buffer,"iterations");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solving fCalls */
  sprintf(buffer,"numberOfFunctionCall");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solving Time */
  sprintf(buffer,"solvingTime");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solving Time */
  sprintf(buffer,"solvedSystem");
  omc_write_csv(csvData, buffer);

  /* finish line */
  fputc('\n',csvData->handle);

  return 0;
}

/*! \fn int print_csvLineCallStats(OMC_WRITE_CSV* csvData)
 *
 *  This function initializes csv files for analysis propose.
 *
 *  \param [ref] [csvData]
 *  \param [in] [number of calls]
 *  \param [in] [simulation time]
 *  \param [in] [iterations]
 *  \param [in] [number of function call]
 *  \param [in] [solving time]
 *  \param [in] [solved system]
 */
int print_csvLineCallStats(OMC_WRITE_CSV* csvData, int num, double time,
                           int iterations, int fCalls, double solvingTime,
                           int solved)
{
  char buffer[1024];

  /* number of call */
  sprintf(buffer, "%d", num);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* simulation time */
  sprintf(buffer, "%g", time);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solving iterations */
  sprintf(buffer, "%d", iterations);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solving fCalls */
  sprintf(buffer, "%d", fCalls);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solving Time */
  sprintf(buffer, "%f", solvingTime);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solved system */
  sprintf(buffer, "%s", solved?"TRUE":"FALSE");
  omc_write_csv(csvData, buffer);

  /* finish line */
  fputc('\n',csvData->handle);

  return 0;
}

/*! \fn int print_csvLineIterStatsHeader(OMC_WRITE_CSV* csvData)
 *
 *  This function initializes csv files for analysis propose.
 *
 *  \param [ref] [data]
 *  \param [ref] [systemData]
 */
int print_csvLineIterStatsHeader(DATA* data, NONLINEAR_SYSTEM_DATA* systemData, OMC_WRITE_CSV* csvData)
{
  char buffer[1024];
  int j;
  int size = modelInfoGetEquation(&data->modelData->modelDataXml, systemData->equationIndex).numVar;

  /* number of call */
  sprintf(buffer,"numberOfCall");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* solving iterations */
  sprintf(buffer,"iteration");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* variables x */
  for(j=0; j<size; ++j) {
    sprintf(buffer, "%s", modelInfoGetEquation(&data->modelData->modelDataXml, systemData->equationIndex).vars[j]);
    omc_write_csv(csvData, buffer);
    fputc(csvData->seperator,csvData->handle);
  }

  /* residuals */
  for(j=0; j<size; ++j) {
    sprintf(buffer, "r%d", j+1);
    omc_write_csv(csvData, buffer);
    fputc(csvData->seperator,csvData->handle);
  }

  /* delta x */
  sprintf(buffer,"delta_x");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* delta x scaled */
  sprintf(buffer,"delta_x_scaled");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* error in f */
  sprintf(buffer,"error_f");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* error in f scaled */
  sprintf(buffer,"error_f_scaled");
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* damping lambda */
  sprintf(buffer,"lambda");
  omc_write_csv(csvData, buffer);

  /* finish line */
  fputc('\n',csvData->handle);

  return 0;
}

/*! \fn int print_csvLineIterStatsHeader(OMC_WRITE_CSV* csvData)
 *
 *  This function initializes csv files for analysis propose.
 *
 *  \param [ref] [csvData]
 *  \param [in] [size, num, ...]
 */
int print_csvLineIterStats(void* voidCsvData, int size, int num,
                           int iteration, double* x, double* f, double error_f,
                           double error_fs, double delta_x, double delta_xs,
                           double lambda)
{
  OMC_WRITE_CSV* csvData = voidCsvData;
  char buffer[1024];
  int j;

  /* number of call */
  sprintf(buffer, "%d", num);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* simulation time */
  sprintf(buffer, "%d", iteration);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* x */
  for(j=0; j<size; ++j) {
    sprintf(buffer, "%g", x[j]);
    omc_write_csv(csvData, buffer);
    fputc(csvData->seperator,csvData->handle);
  }

  /* r */
  for(j=0; j<size; ++j) {
    sprintf(buffer, "%g", f[j]);
    omc_write_csv(csvData, buffer);
    fputc(csvData->seperator,csvData->handle);
  }

  /* error_f */
  sprintf(buffer, "%g", error_f);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* error_f */
  sprintf(buffer, "%g", error_fs);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* delta_x */
  sprintf(buffer, "%g", delta_x);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* delta_xs */
  sprintf(buffer, "%g", delta_xs);
  omc_write_csv(csvData, buffer);
  fputc(csvData->seperator,csvData->handle);

  /* lambda */
  sprintf(buffer, "%g", lambda);
  omc_write_csv(csvData, buffer);

  /* finish line */
  fputc('\n',csvData->handle);

  return 0;
}
#endif

/*! \fn int initializeNonlinearSystems(DATA *data)
 *
 *  This function allocates memory for all nonlinear systems.
 *
 *  \param [ref] [data]
 */
int initializeNonlinearSystems(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int i,j;
  int size, nnz;
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo->nonlinearSystemData;
  struct dataSolver *solverData;
  struct dataMixedSolver *mixedSolverData;
  modelica_boolean someSmallDensity = 0;  /* pretty dumping of flag info */
  modelica_boolean someBigSize = 0;       /* analogous to someSmallDensity */

  infoStreamPrint(LOG_NLS, 1, "initialize non-linear system solvers");
  infoStreamPrint(LOG_NLS, 0, "%ld non-linear systems", data->modelData->nNonLinearSystems);

  /* set the default nls linear solver depending on the default nls method */
  if (data->simulationInfo->nlsLinearSolver == NLS_LS_DEFAULT) {
#if !defined(OMC_MINIMAL_RUNTIME)
    /* kinsol works best with KLU,
       they are both sparse so it makes sense to use them together */
    if (data->simulationInfo->nlsMethod == NLS_KINSOL) {
      data->simulationInfo->nlsLinearSolver = NLS_LS_KLU;
    } else {
      data->simulationInfo->nlsLinearSolver = NLS_LS_LAPACK;
    }
#else
    data->simulationInfo->nlsLinearSolver = NLS_LS_LAPACK;
#endif
  }

  for(i=0; i<data->modelData->nNonLinearSystems; ++i)
  {
    size = nonlinsys[i].size;
    nonlinsys[i].numberOfFEval = 0;
    nonlinsys[i].numberOfIterations = 0;

    /* check if residual function pointer are valid */
    assertStreamPrint(threadData, ((0 != nonlinsys[i].residualFunc)) || ((nonlinsys[i].strictTearingFunctionCall != NULL) ? (0 != nonlinsys[i].strictTearingFunctionCall) : 0), "residual function pointer is invalid" );

    /* check if analytical jacobian is created */
    if(nonlinsys[i].jacobianIndex != -1)
    {
      ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[nonlinsys[i].jacobianIndex]);
      assertStreamPrint(threadData, 0 != nonlinsys[i].analyticalJacobianColumn, "jacobian function pointer is invalid" );
      if(nonlinsys[i].initialAnalyticalJacobian(data, threadData, jacobian))
      {
        nonlinsys[i].jacobianIndex = -1;
      }
    }

    /* allocate system data */
    nonlinsys[i].nlsx = (double*) malloc(size*sizeof(double));
    nonlinsys[i].nlsxExtrapolation = (double*) malloc(size*sizeof(double));
    nonlinsys[i].nlsxOld = (double*) malloc(size*sizeof(double));
    nonlinsys[i].resValues = (double*) malloc(size*sizeof(double));

    /* allocate value list*/
    nonlinsys[i].oldValueList = (void*) allocValueList(1);

    nonlinsys[i].lastTimeSolved = 0.0;

    nonlinsys[i].nominal = (double*) malloc(size*sizeof(double));
    nonlinsys[i].min = (double*) malloc(size*sizeof(double));
    nonlinsys[i].max = (double*) malloc(size*sizeof(double));
    nonlinsys[i].initializeStaticNLSData(data, threadData, &nonlinsys[i]);

#if !defined(OMC_MINIMAL_RUNTIME)
    /* csv data call stats*/
    if (data->simulationInfo->nlsCsvInfomation)
    {
      if (initializeNLScsvData(data, &nonlinsys[i]))
      {
        throwStreamPrint(threadData, "csvData initialization failed");
      }
      else
      {
        print_csvLineCallStatsHeader(((struct csvStats*) nonlinsys[i].csvData)->callStats);
        print_csvLineIterStatsHeader(data, &nonlinsys[i], ((struct csvStats*) nonlinsys[i].csvData)->iterStats);
      }
    }
#endif

    /* check if the system is sparse enough to use kinsol
       it is considered sparse if
         * the density (nnz/size^2) is less than a threshold or
         * the size is bigger than a threshold */
    nonlinsys[i].nlsMethod = data->simulationInfo->nlsMethod;
    nonlinsys[i].nlsLinearSolver = data->simulationInfo->nlsLinearSolver;
#if !defined(OMC_MINIMAL_RUNTIME)
    if (nonlinsys[i].isPatternAvailable && data->simulationInfo->nlsMethod != NLS_KINSOL)
    {
      nnz = nonlinsys[i].sparsePattern->numberOfNoneZeros;

      if (nnz/(double)(size*size) < nonlinearSparseSolverMaxDensity) {
        nonlinsys[i].nlsMethod = NLS_KINSOL;
        nonlinsys[i].nlsLinearSolver = NLS_LS_KLU;
        someSmallDensity = 1;
        if (size > nonlinearSparseSolverMinSize) {
          someBigSize = 1;
          infoStreamPrint(LOG_STDOUT, 0,
                          "Using sparse solver kinsol for nonlinear system %d (%d),\n"
                          "because density of %.2f remains under threshold of %.2f\n"
                          "and size of %d exceeds threshold of %d.",
                          i, nonlinsys[i].equationIndex, nnz/(double)(size*size), nonlinearSparseSolverMaxDensity,
                          size, nonlinearSparseSolverMinSize);
        } else {
          infoStreamPrint(LOG_STDOUT, 0,
                          "Using sparse solver kinsol for nonlinear system %d (%d),\n"
                          "because density of %.2f remains under threshold of %.2f.",
                          i, nonlinsys[i].equationIndex, nnz/(double)(size*size), nonlinearSparseSolverMaxDensity);
        }
      } else if (size > nonlinearSparseSolverMinSize) {
        nonlinsys[i].nlsMethod = NLS_KINSOL;
        nonlinsys[i].nlsLinearSolver = NLS_LS_KLU;
        someBigSize = 1;
        infoStreamPrint(LOG_STDOUT, 0,
                        "Using sparse solver kinsol for nonlinear system %d (%d),\n"
                        "because size of %d exceeds threshold of %d.",
                        i, nonlinsys[i].equationIndex, size, nonlinearSparseSolverMinSize);
      }
    }
#endif

    /* allocate stuff depending on the chosen method */
    switch(nonlinsys[i].nlsMethod)
    {
#if !defined(OMC_MINIMAL_RUNTIME)
    case NLS_HYBRID:
      solverData = (struct dataSolver*) malloc(sizeof(struct dataSolver));
      if (nonlinsys[i].homotopySupport && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3)) {
        allocateHybrdData(size-1, &(solverData->ordinaryData));
        allocateHomotopyData(size-1, &(solverData->initHomotopyData));
      } else {
        allocateHybrdData(size, &(solverData->ordinaryData));
      }
      nonlinsys[i].solverData = (void*) solverData;
      break;
    case NLS_KINSOL:
      solverData = (struct dataSolver*) malloc(sizeof(struct dataSolver));
      if (nonlinsys[i].homotopySupport && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3)) {
        // Try without homotopy not supported for kinsol
        // nlsKinsolAllocate(size-1, &nonlinsys[i], data->simulationInfo->nlsLinearSolver);
        // solverData->ordinaryData = nonlinsys[i].solverData;
        allocateHomotopyData(size-1, &(solverData->initHomotopyData));
      } else {
        nlsKinsolAllocate(size, &nonlinsys[i], nonlinsys[i].nlsLinearSolver);
        solverData->ordinaryData = nonlinsys[i].solverData;
      }
      nonlinsys[i].solverData = (void*) solverData;
      break;
    case NLS_NEWTON:
      solverData = (struct dataSolver*) malloc(sizeof(struct dataSolver));
      if (nonlinsys[i].homotopySupport && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3)) {
        allocateNewtonData(size-1, &(solverData->ordinaryData));
        allocateHomotopyData(size-1, &(solverData->initHomotopyData));
      } else {
        allocateNewtonData(size, &(solverData->ordinaryData));
      }
      nonlinsys[i].solverData = (void*) solverData;
      break;
    case NLS_MIXED:
      mixedSolverData = (struct dataMixedSolver*) malloc(sizeof(struct dataMixedSolver));
      if (nonlinsys[i].homotopySupport && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3)) {
        allocateHomotopyData(size-1, &(mixedSolverData->newtonHomotopyData));
        allocateHybrdData(size-1, &(mixedSolverData->hybridData));
      } else {
        allocateHomotopyData(size, &(mixedSolverData->newtonHomotopyData));
        allocateHybrdData(size, &(mixedSolverData->hybridData));
      }
      nonlinsys[i].solverData = (void*) mixedSolverData;
      break;
#endif
    case NLS_HOMOTOPY:
      if (nonlinsys[i].homotopySupport && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3)) {
        allocateHomotopyData(size-1, &nonlinsys[i].solverData);
      } else {
        allocateHomotopyData(size, &nonlinsys[i].solverData);
      }
      break;
    default:
      throwStreamPrint(threadData, "unrecognized nonlinear solver");
    }
  }

  /* print relevant flag information */
  if(someSmallDensity) {
    if(someBigSize) {
      infoStreamPrint(LOG_STDOUT, 0, "The maximum density and the minimal system size for using sparse solvers can be\n"
                                     "specified using the runtime flags '<-nlssMaxDensity=value>' and '<-nlssMinSize=value>'.");
    } else {
      infoStreamPrint(LOG_STDOUT, 0, "The maximum density for using sparse solvers can be specified\n"
                                     "using the runtime flag '<-nlssMaxDensity=value>'.");
    }
  } else if(someBigSize) {
    infoStreamPrint(LOG_STDOUT, 0, "The minimal system size for using sparse solvers can be specified\n"
                                   "using the runtime flag '<-nlssMinSize=value>'.");
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
int updateStaticDataOfNonlinearSystems(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int i;
  int size;
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo->nonlinearSystemData;

  infoStreamPrint(LOG_NLS, 1, "update static data of non-linear system solvers");

  for(i=0; i<data->modelData->nNonLinearSystems; ++i)
  {
    nonlinsys[i].initializeStaticNLSData(data, threadData, &nonlinsys[i]);
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
int freeNonlinearSystems(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int i;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo->nonlinearSystemData;
  struct csvStats* stats;

  infoStreamPrint(LOG_NLS, 1, "free non-linear system solvers");

  for(i=0; i<data->modelData->nNonLinearSystems; ++i)
  {
    free(nonlinsys[i].nlsx);
    free(nonlinsys[i].nlsxExtrapolation);
    free(nonlinsys[i].nlsxOld);
    free(nonlinsys[i].resValues);
    free(nonlinsys[i].nominal);
    free(nonlinsys[i].min);
    free(nonlinsys[i].max);
    freeValueList(nonlinsys[i].oldValueList, 1);


#if !defined(OMC_MINIMAL_RUNTIME)
    if (data->simulationInfo->nlsCsvInfomation)
    {
      stats = nonlinsys[i].csvData;
      omc_write_csv_free(stats->callStats);
      omc_write_csv_free(stats->iterStats);
    }
#endif
    /* free solver data */
    switch(nonlinsys[i].nlsMethod)
    {
#if !defined(OMC_MINIMAL_RUNTIME)
    case NLS_HYBRID:
      freeHybrdData(&((struct dataSolver*) nonlinsys[i].solverData)->ordinaryData);
      if (nonlinsys[i].homotopySupport && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3)) {
        freeHomotopyData(&((struct dataSolver*) nonlinsys[i].solverData)->initHomotopyData);
      }
      free(nonlinsys[i].solverData);
      break;
    case NLS_KINSOL:
      if (nonlinsys[i].homotopySupport && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3)) {
        freeHomotopyData(&((struct dataSolver*) nonlinsys[i].solverData)->initHomotopyData);
      } else {
        nlsKinsolFree(&((struct dataSolver*) nonlinsys[i].solverData)->ordinaryData);
      }
      free(nonlinsys[i].solverData);
      break;
    case NLS_NEWTON:
      freeNewtonData(&((struct dataSolver*) nonlinsys[i].solverData)->ordinaryData);
      if (nonlinsys[i].homotopySupport && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3)) {
        freeHomotopyData(&((struct dataSolver*) nonlinsys[i].solverData)->initHomotopyData);
      }
      free(nonlinsys[i].solverData);
      break;
#endif
    case NLS_HOMOTOPY:
      freeHomotopyData(&nonlinsys[i].solverData);
      free(nonlinsys[i].solverData);
      break;
#if !defined(OMC_MINIMAL_RUNTIME)
    case NLS_MIXED:
      freeHomotopyData(&((struct dataMixedSolver*) nonlinsys[i].solverData)->newtonHomotopyData);
      freeHybrdData(&((struct dataMixedSolver*) nonlinsys[i].solverData)->hybridData);
      free(nonlinsys[i].solverData);
      break;
#endif
    default:
      throwStreamPrint(threadData, "unrecognized nonlinear solver");
    }
  }

  messageClose(LOG_NLS);

  TRACE_POP
  return 0;
}

/*! \fn printNonLinearSystemSolvingStatistics
 *
 *  This function prints memory for all non-linear systems.
 *
 *  \param [ref] [data]
 *         [in]  [sysNumber] index of corresponding non-linear system
 */
void printNonLinearSystemSolvingStatistics(DATA *data, int sysNumber, int logLevel)
{
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo->nonlinearSystemData;
  infoStreamPrint(logLevel, 1, "Non-linear system %d of size %d solver statistics:", (int)nonlinsys[sysNumber].equationIndex, (int)nonlinsys[sysNumber].size);
  infoStreamPrint(logLevel, 0, " number of calls                : %ld", nonlinsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " number of iterations           : %ld", nonlinsys[sysNumber].numberOfIterations);
  infoStreamPrint(logLevel, 0, " number of function evaluations : %ld", nonlinsys[sysNumber].numberOfFEval);
  infoStreamPrint(logLevel, 0, " number of jacobian evaluations : %ld", nonlinsys[sysNumber].numberOfJEval);
  infoStreamPrint(logLevel, 0, " time of jacobian evaluations   : %f", nonlinsys[sysNumber].jacobianTime);
  infoStreamPrint(logLevel, 0, " average time per call          : %f", nonlinsys[sysNumber].totalTime/nonlinsys[sysNumber].numberOfCall);
  infoStreamPrint(logLevel, 0, " total time                     : %f", nonlinsys[sysNumber].totalTime);
  messageClose(logLevel);
}

/*! \fn printNonLinearInitialInfo
 *
 *  This function prints information of an non-linear systems before an solving step.
 *
 *  \param [in]  [logName] log level in general LOG_NLS
 *         [ref] [data]
 *         [ref] [nonlinsys] index of corresponding non-linear system
 */
void printNonLinearInitialInfo(int logName, DATA* data, NONLINEAR_SYSTEM_DATA *nonlinsys)
{
  long i;

  if (!ACTIVE_STREAM(logName)) return;
  infoStreamPrint(logName, 1, "initial variable values:");

  for(i=0; i<nonlinsys->size; i++)
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t nom = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,nonlinsys->equationIndex).vars[i],
                    nonlinsys->nlsx[i], nonlinsys->nominal[i]);
  messageClose(logName);
}

/*! \fn printNonLinearFinishInfo
 *
 *  This function prints information of an non-linear systems after a solving step.
 *
 *  \param [in]  [logName] log level in general LOG_NLS
 *         [ref] [data]
 *         [ref] [nonlinsys] index of corresponding non-linear system
 */
void printNonLinearFinishInfo(int logName, DATA* data, NONLINEAR_SYSTEM_DATA *nonlinsys)
{
  long i;

  if (!ACTIVE_STREAM(logName)) return;

  infoStreamPrint(logName, 1, "Solution status: %s", nonlinsys->solved?"SOLVED":"FAILED");
  infoStreamPrint(logName, 0, " number of iterations           : %ld", nonlinsys->numberOfIterations);
  infoStreamPrint(logName, 0, " number of function evaluations : %ld", nonlinsys->numberOfFEval);
  infoStreamPrint(logName, 0, " number of jacobian evaluations : %ld", nonlinsys->numberOfJEval);
  infoStreamPrint(logName, 0, "solution values:");
  for(i=0; i<nonlinsys->size; i++)
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,nonlinsys->equationIndex).vars[i],
                    nonlinsys->nlsx[i]);

  messageClose(logName);
}

/*! \fn getInitialGuess
 *
 *  This function writes initial guess to nonlinsys->nlsx and nonlinsys->nlsOld.
 *
 *  \param [in]  [nonlinsys]
 *  \param [in]  [time] time for extrapolation
 *
 */
int getInitialGuess(NONLINEAR_SYSTEM_DATA *nonlinsys, double time)
{
  /* value extrapolation */
  printValuesListTimes((VALUES_LIST*)nonlinsys->oldValueList);
  /* if list is empty use current start values */
  if (listLen(((VALUES_LIST*)nonlinsys->oldValueList)->valueList)==0)
  {
    /* use old value if no values are stored in the list */
    memcpy(nonlinsys->nlsx, nonlinsys->nlsxOld, nonlinsys->size*(sizeof(double)));
  }
  else
  {
    /* get extrapolated values */
    getValues((VALUES_LIST*)nonlinsys->oldValueList, time, nonlinsys->nlsxExtrapolation, nonlinsys->nlsxOld);
    memcpy(nonlinsys->nlsx, nonlinsys->nlsxOld, nonlinsys->size*(sizeof(double)));
  }

  return 0;
}

/*! \fn updateInitialGuessDB
 *
 *  This function writes new values to solution list.
 *
 *  \param [in]  [nonlinsys]
 *  \param [in]  [time] time for extrapolation
 *  \param [in]  [context] current context of evaluation
 *
 */
int updateInitialGuessDB(NONLINEAR_SYSTEM_DATA *nonlinsys, double time, int context)
{
  /* write solution to oldValue list for extrapolation */
  if (nonlinsys->solved == 1)
  {
    /* do not use solution of jacobian for next extrapolation */
    if (context < 4)
    {
      addListElement((VALUES_LIST*)nonlinsys->oldValueList,
              createValueElement(nonlinsys->size, time, nonlinsys->nlsx));
    }
  }
  else if (nonlinsys->solved == 2)
  {
    if (listLen(((VALUES_LIST*)nonlinsys->oldValueList)->valueList)>0)
    {
      cleanValueList((VALUES_LIST*)nonlinsys->oldValueList, NULL);
    }
    /* do not use solution of jacobian for next extrapolation */
    if (context < 4)
    {
      addListElement((VALUES_LIST*)nonlinsys->oldValueList,
              createValueElement(nonlinsys->size, time, nonlinsys->nlsx));
    }
  }
  messageClose(LOG_NLS_EXTRAPOLATE);
  return 0;
}

/*! \fn updateInnerEquation
 *
 *  This function updates inner equation with the current x.
 *
 *  \param [ref] [data]
 *         [in]  [sysNumber] index of corresponding non-linear system
 */
int updateInnerEquation(void **dataIn, int sysNumber, int discrete)
{
  DATA *data = (DATA*) ((void**)dataIn[0]);
  threadData_t *threadData = (threadData_t*) ((void**)dataIn[1]);

  NONLINEAR_SYSTEM_DATA* nonlinsys = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  int success = 0;
  int constraintViolated = 0;

  /* solve non continuous at discrete points*/
  if(discrete)
  {
    data->simulationInfo->solveContinuous = 0;
  }

  /* try */
#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* call residual function */
  if (nonlinsys->strictTearingFunctionCall != NULL)
    constraintViolated = nonlinsys->residualFuncConstraints((void*) dataIn, nonlinsys->nlsx, nonlinsys->resValues, (int*)&nonlinsys->size);
  else
    nonlinsys->residualFunc((void*) dataIn, nonlinsys->nlsx, nonlinsys->resValues, (int*)&nonlinsys->size);

  /* replace extrapolated values by current x for discrete step */
  memcpy(nonlinsys->nlsxExtrapolation, nonlinsys->nlsx, nonlinsys->size*(sizeof(double)));

  if (!constraintViolated)
    success = 1;
  /*catch */
#ifndef OMC_EMCC
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success && !constraintViolated)
  {
    warningStreamPrint(LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");
  }

  if(discrete)
  {
    data->simulationInfo->solveContinuous = 1;
  }

  return success;
}


int solveNLS(DATA *data, threadData_t *threadData, int sysNumber)
{
  int success = 0, constraintsSatisfied = 1;
  NONLINEAR_SYSTEM_DATA* nonlinsys = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  int casualTearingSet = nonlinsys->strictTearingFunctionCall != NULL;
  struct dataSolver *solverData;
  struct dataMixedSolver *mixedSolverData;

  /* use the selected solver for solving nonlinear system */
  switch(nonlinsys->nlsMethod)
  {
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_HYBRID:
    solverData = nonlinsys->solverData;
    nonlinsys->solverData = solverData->ordinaryData;
    /* try */
    #ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
    #endif
    success = solveHybrd(data, threadData, sysNumber);
    /*catch */
    #ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
    #endif
    nonlinsys->solverData = solverData;
    break;
  case NLS_KINSOL:
    solverData = nonlinsys->solverData;
    nonlinsys->solverData = solverData->ordinaryData;
    /* try */
    #ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
    #endif
    success = nlsKinsolSolve(data, threadData, sysNumber);
    /*catch */
    #ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
    #endif
    nonlinsys->solverData = solverData;
    break;
  case NLS_NEWTON:
    solverData = nonlinsys->solverData;
    nonlinsys->solverData = solverData->ordinaryData;
    /* try */
    #ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
    #endif
    success = solveNewton(data, threadData, sysNumber);
    /*catch */
    #ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
    #endif
    /* check if solution process was successful, if not use alternative tearing set if available (dynamic tearing)*/
    if (!success && casualTearingSet){
      debugString(LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
      success = nonlinsys->strictTearingFunctionCall(data, threadData);
      if (success) success=2;
    }
    nonlinsys->solverData = solverData;
    break;
#endif
  case NLS_HOMOTOPY:
    success = solveHomotopy(data, threadData, sysNumber);
    break;
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_MIXED:
    mixedSolverData = nonlinsys->solverData;
    nonlinsys->solverData = mixedSolverData->newtonHomotopyData;

    /* try */
    #ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
    #endif
    /* try to solve the system if it is the strict set, only try to solve the casual set if the constraints are satisfied */
    if ((!casualTearingSet) || constraintsSatisfied)
      success = solveHomotopy(data, threadData, sysNumber);

    /* check if solution process was successful, if not use alternative tearing set if available (dynamic tearing)*/
    if (!success && casualTearingSet){
      debugString(LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
      success = nonlinsys->strictTearingFunctionCall(data, threadData);
      if (success){
        success=2;
      }
    }

    if (!success) {
      nonlinsys->solverData = mixedSolverData->hybridData;
      success = solveHybrd(data, threadData, sysNumber);
    }

    /* update iteration variables of nonlinsys->nlsx */
    if (success){
      nonlinsys->getIterationVars(data, nonlinsys->nlsx);
    }

    /*catch */
    #ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
    #endif
    nonlinsys->solverData = mixedSolverData;
    break;
#endif
  default:
    throwStreamPrint(threadData, "unrecognized nonlinear solver");
  }

  return success;
}

/*! \fn solve system with homotopy solver
 *
 *  \param [in]  [data]
 *  \param [in]  [threadData]
 *  \param [in]  [sysNumber] index of corresponding non-linear system
 *
 *  \author ptaeuber
 */
int solveWithInitHomotopy(DATA *data, threadData_t *threadData, int sysNumber)
{
  int success = 0;
  NONLINEAR_SYSTEM_DATA* nonlinsys = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  struct dataSolver *solverData;
  struct dataMixedSolver *mixedSolverData;

  /* use the homotopy solver for solving the initial system */
  switch(nonlinsys->nlsMethod)
  {
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_HYBRID:
  case NLS_KINSOL:
  case NLS_NEWTON:
    solverData = nonlinsys->solverData;
    nonlinsys->solverData = solverData->initHomotopyData;
    success = solveHomotopy(data, threadData, sysNumber);
    nonlinsys->solverData = solverData;
    break;
#endif
  case NLS_HOMOTOPY:
    success = solveHomotopy(data, threadData, sysNumber);
    break;
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_MIXED:
    mixedSolverData = nonlinsys->solverData;
    nonlinsys->solverData = mixedSolverData->newtonHomotopyData;
    success = solveHomotopy(data, threadData, sysNumber);
    nonlinsys->solverData = mixedSolverData;
    break;
#endif
  default:
    throwStreamPrint(threadData, "unrecognized nonlinear solver");
  }

  return success;
}

/*! \fn solve non-linear systems
 *
 *  \param [in]  [data]
 *  \param [in]  [threadData]
 *  \param [in]  [sysNumber] index of corresponding non-linear system
 *
 *  \author ptaeuber
 */
int solve_nonlinear_system(DATA *data, threadData_t *threadData, int sysNumber)
{
  void *dataAndThreadData[2] = {data, threadData};
  int success = 0, saveJumpState, constraintsSatisfied = 1;
  NONLINEAR_SYSTEM_DATA* nonlinsys = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  int casualTearingSet = nonlinsys->strictTearingFunctionCall != NULL;
  int step;
  int equidistantHomotopy = 0;
  int solveWithHomotopySolver = 0;
  int homotopyDeactivated = 0;
  int j;
  int nlsLs;
  int kinsol = 0;
  int res;
  struct dataSolver *solverData;
  struct dataMixedSolver *mixedSolverData;
  char buffer[4096];
  FILE *pFile = NULL;
  double originalLambda = data->simulationInfo->lambda;

#if !defined(OMC_MINIMAL_RUNTIME)
  kinsol = (nonlinsys->nlsMethod == NLS_KINSOL);
#endif

  data->simulationInfo->currentNonlinearSystemIndex = sysNumber;

  /* enable to avoid division by zero */
  data->simulationInfo->noThrowDivZero = 1;
  ((DATA*)data)->simulationInfo->solveContinuous = 1;

  /* performance measurement */
  rt_ext_tp_tick(&nonlinsys->totalTimeClock);

  infoStreamPrint(LOG_NLS_EXTRAPOLATE, 1, "Nonlinear system %ld dump LOG_NLS_EXTRAPOLATE", nonlinsys->equationIndex);
  /* grab the initial guess */
  /* if last solving is too long ago use just old values  */
  if (fabs(data->localData[0]->timeValue - nonlinsys->lastTimeSolved) < 5*data->simulationInfo->stepSize || casualTearingSet)
  {
    getInitialGuess(nonlinsys, data->localData[0]->timeValue);
  }
  else
  {
    nonlinsys->getIterationVars(data, nonlinsys->nlsx);
    memcpy(nonlinsys->nlsx, nonlinsys->nlsxOld, nonlinsys->size*(sizeof(double)));
  }
  /* update non continuous */
  if (data->simulationInfo->discreteCall)
  {
    // TS, 23/08/2021: printf("   #### data->simulationInfo->discreteCall....\n");
    constraintsSatisfied = updateInnerEquation(dataAndThreadData, sysNumber, 1);
  }

  /* print debug initial information */
  infoStreamPrint(LOG_NLS, 1, "############ Solve nonlinear system %ld at time %g ############", nonlinsys->equationIndex, data->localData[0]->timeValue);
  printNonLinearInitialInfo(LOG_NLS, data, nonlinsys);

#if !defined(OMC_MINIMAL_RUNTIME)
  /* Improve start values with newton diagnostics method */
  if(omc_flag[FLAG_NEWTON_DIAGNOSTICS] && data->simulationInfo->initial && sysNumber == 0) {
    infoStreamPrint(LOG_NLS, 0, "Running newton diagnostics");
    newtonDiagnostics(data, threadData, sysNumber);
  }
#endif


  /* try */
#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* handle asserts */
  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_NONLINEARSOLVER;

  equidistantHomotopy = data->simulationInfo->initial
                        && nonlinsys->homotopySupport
                        && (data->callback->useHomotopy == 0 && init_lambda_steps >= 1);

  solveWithHomotopySolver = data->simulationInfo->initial
                            && nonlinsys->homotopySupport
                            && (data->callback->useHomotopy == 2 || data->callback->useHomotopy == 3);

  homotopyDeactivated = !data->simulationInfo->initial           // Not an initialization system
                        || !nonlinsys->homotopySupport           // There is no homotopy in this component
                        || (data->callback->useHomotopy == 1)    // Equidistant homotopy is performed globally in symbolic_initialization()
                        || (data->callback->useHomotopy == 0     // Equidistant local homotopy is selected but homotopy is deactivated ...
                            && init_lambda_steps <= 0);          // ... by the number of steps

  nonlinsys->solved = 0;
  nonlinsys->initHomotopy = 0;

  /* If homotopy is deactivated in this place or flag homotopyOnFirstTry is not set,
     solve the system with the selected solver */
  if (homotopyDeactivated || !omc_flag[FLAG_HOMOTOPY_ON_FIRST_TRY]) {
    if (solveWithHomotopySolver && kinsol) {
      infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "Automatically set -homotopyOnFirstTry, because trying without homotopy first is not supported for the local global approach in combination with KINSOL.");
    } else {
      if (!homotopyDeactivated && !omc_flag[FLAG_HOMOTOPY_ON_FIRST_TRY])
        infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "Try to solve nonlinear initial system %d without homotopy first.", sysNumber);

      /* SOLVE! */
      nonlinsys->solved = solveNLS(data, threadData, sysNumber);
    }
  }

  /* The following cases are only valid for initial systems with homotopy */
  /* **********************************************************************/

  /* If the adaptive local/global homotopy approach is activated and trying without homotopy failed or is not wanted,
     use the HOMOTOPY SOLVER */
  if (solveWithHomotopySolver && !nonlinsys->solved) {
    if (!omc_flag[FLAG_HOMOTOPY_ON_FIRST_TRY] && !kinsol)
      warningStreamPrint(LOG_ASSERT, 0, "Failed to solve the initial system %d without homotopy method.", sysNumber);
    data->simulationInfo->lambda = 0.0;
    if (data->callback->useHomotopy == 3) {
      // First solve the lambda0-system separately
      infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "Local homotopy with adaptive step size started for nonlinear system %d.", sysNumber);
      infoStreamPrint(LOG_INIT_HOMOTOPY, 1, "homotopy process\n---------------------------");
      infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "solve lambda0-system");
      nonlinsys->homotopySupport = 0;
      if (!kinsol) {
        nonlinsys->solved = solveNLS(data, threadData, sysNumber);
      } else {
        nlsLs = data->simulationInfo->nlsLinearSolver;
        data->simulationInfo->nlsLinearSolver = NLS_LS_LAPACK;
        nonlinsys->solved = solveWithInitHomotopy(data, threadData, sysNumber);
        data->simulationInfo->nlsLinearSolver = nlsLs;
      }
      nonlinsys->homotopySupport = 1;
      infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "solving lambda0-system done with%s success\n---------------------------", nonlinsys->solved ? "" : " no");
      messageClose(LOG_INIT_HOMOTOPY);
    }
    /* SOLVE! */
    if (data->callback->useHomotopy == 2 || nonlinsys->solved) {
      infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "run along the homotopy path and solve the actual system");
      nonlinsys->initHomotopy = 1;
      nonlinsys->solved = solveWithInitHomotopy(data, threadData, sysNumber);
    }
  }

  /* If equidistant local homotopy is activated and trying without homotopy failed or is not wanted,
     use EQUIDISTANT LOCAL HOMOTOPY */
  if (equidistantHomotopy && !nonlinsys->solved) {
    if (!omc_flag[FLAG_HOMOTOPY_ON_FIRST_TRY])
      warningStreamPrint(LOG_ASSERT, 0, "Failed to solve the initial system %d without homotopy method. The local homotopy method with equidistant step size is used now.", sysNumber);
    else
      infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "Local homotopy with equidistant step size started for nonlinear system %d.", sysNumber);
#if !defined(OMC_NO_FILESYSTEM)
    const char sep[] = ",";
    if(ACTIVE_STREAM(LOG_INIT_HOMOTOPY))
    {
      sprintf(buffer, "%s_nonlinsys%d_equidistant_local_homotopy.csv", data->modelData->modelFilePrefix, sysNumber);
      infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "The homotopy path of system %d will be exported to %s.", sysNumber, buffer);
      pFile = omc_fopen(buffer, "wt");
      fprintf(pFile, "\"sep=%s\"\n%s", sep, "\"lambda\"");
      for(j=0; j<nonlinsys->size; ++j)
        fprintf(pFile, "%s\"%s\"", sep, modelInfoGetEquation(&data->modelData->modelDataXml, nonlinsys->equationIndex).vars[j]);
      fprintf(pFile, "\n");
    }
#endif

    for(step=0; step<=init_lambda_steps; ++step)
    {
      data->simulationInfo->lambda = ((double)step)/(init_lambda_steps);

      if (data->simulationInfo->lambda > 1.0) {
        data->simulationInfo->lambda = 1.0;
      }

      infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "[system %d] homotopy parameter lambda = %g", sysNumber, data->simulationInfo->lambda);
      /* SOLVE! */
      nonlinsys->solved = solveNLS(data, threadData, sysNumber);
      if (!nonlinsys->solved) break;

#if !defined(OMC_NO_FILESYSTEM)
      if(ACTIVE_STREAM(LOG_INIT_HOMOTOPY))
      {
        infoStreamPrint(LOG_INIT_HOMOTOPY, 0, "[system %d] homotopy parameter lambda = %g done\n---------------------------", sysNumber, data->simulationInfo->lambda);
        fprintf(pFile, "%.16g", data->simulationInfo->lambda);
        for(j=0; j<nonlinsys->size; ++j)
          fprintf(pFile, "%s%.16g", sep, nonlinsys->nlsx[j]);
        fprintf(pFile, "\n");
      }
#endif
    }

#if !defined(OMC_NO_FILESYSTEM)
    if(ACTIVE_STREAM(LOG_INIT_HOMOTOPY))
    {
      fclose(pFile);
    }
#endif
    data->simulationInfo->homotopySteps += init_lambda_steps;
  }

  /* handle asserts */
  threadData->currentErrorStage = saveJumpState;

  /*catch */
#ifndef OMC_EMCC
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  /* update value list database */
  updateInitialGuessDB(nonlinsys, data->localData[0]->timeValue, data->simulationInfo->currentContext);
  if (nonlinsys->solved == 1)
  {
    nonlinsys->lastTimeSolved = data->localData[0]->timeValue;
  }
  printNonLinearFinishInfo(LOG_NLS, data, nonlinsys);
  messageClose(LOG_NLS);


  /* enable to avoid division by zero */
  data->simulationInfo->noThrowDivZero = 0;
  ((DATA*)data)->simulationInfo->solveContinuous = 0;

  /* performance measurement and statistics */
  nonlinsys->totalTime += rt_ext_tp_tock(&(nonlinsys->totalTimeClock));
  nonlinsys->numberOfCall++;

  /* write csv file for debugging */
#if !defined(OMC_MINIMAL_RUNTIME)
  if (data->simulationInfo->nlsCsvInfomation)
  {
    print_csvLineCallStats(((struct csvStats*) nonlinsys->csvData)->callStats,
                           nonlinsys->numberOfCall,
                           data->localData[0]->timeValue,
                           nonlinsys->numberOfIterations,
                           nonlinsys->numberOfFEval,
                           nonlinsys->totalTime,
                           nonlinsys->solved
    );
  }
#endif
  res = check_nonlinear_solution(data, 1, sysNumber);
  data->simulationInfo->lambda = originalLambda;
  return res;
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

  for(i=0; i<data->modelData->nNonLinearSystems; ++i) {
     if(check_nonlinear_solution(data, printFailingSystems, i))
       return 1;
  }

  return 0;
}

/*! \fn check_nonlinear_solution
 *
 *   This function checks if a non-linear system
 *   is solved. Returns a warning and 1 in case it's not
 *   solved otherwise 0.
 *
 *  \param [in]  [data]
 *  \param [in]  [printFailingSystems]
 *  \param [in]  [sysNumber] index of corresponding non-linear System
 *  \param [out] [returnValue] Returns 1 if fail otherwise 0.
 *
 *  \author wbraun
 */
int check_nonlinear_solution(DATA *data, int printFailingSystems, int sysNumber)
{
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo->nonlinearSystemData;
  long j;
  int i = sysNumber;

  if(nonlinsys[i].solved == 0)
  {
    int index = nonlinsys[i].equationIndex, indexes[2] = {1,index};
    if (!printFailingSystems) return 1;
    warningStreamPrintWithEquationIndexes(LOG_NLS, 0, indexes, "nonlinear system %d fails: at t=%g", index, data->localData[0]->timeValue);
    if(data->simulationInfo->initial)
    {
      warningStreamPrint(LOG_INIT, 1, "proper start-values for some of the following iteration variables might help");
    }
    for(j=0; j<modelInfoGetEquation(&data->modelData->modelDataXml, (nonlinsys[i]).equationIndex).numVar; ++j) {
      int done=0;
      long k;
      const MODEL_DATA *mData = data->modelData;
      for(k=0; k<mData->nVariablesReal && !done; ++k)
      {
        if (!strcmp(mData->realVarsData[k].info.name, modelInfoGetEquation(&data->modelData->modelDataXml, (nonlinsys[i]).equationIndex).vars[j]))
        {
        done = 1;
        warningStreamPrint(LOG_INIT, 0, "[%ld] Real %s(start=%g, nominal=%g)", j+1,
                                     mData->realVarsData[k].info.name,
                                     mData->realVarsData[k].attribute.start,
                                     mData->realVarsData[k].attribute.nominal);
        }
      }
      if (!done)
      {
        warningStreamPrint(LOG_INIT, 0, "[%ld] Real %s(start=?, nominal=?)", j+1, modelInfoGetEquation(&data->modelData->modelDataXml, (nonlinsys[i]).equationIndex).vars[j]);
      }
    }
    messageCloseWarning(LOG_INIT);
    return 1;
  }
  if(nonlinsys[i].solved == 2)
  {
    nonlinsys[i].solved = 1;
    return 2;
  }


  return 0;
}

/*! \fn cleanUpOldValueListAfterEvent
 *
 *   This function clean old value list up to parameter time for all
 *   non-linear systems.
 *
 *  \param [in]  [data]
 *  \param [in]  [time]
 *
 *  \author wbraun
 */
void cleanUpOldValueListAfterEvent(DATA *data, double time)
{
  long i;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo->nonlinearSystemData;

  for(i=0; i<data->modelData->nNonLinearSystems; ++i) {
    cleanValueListbyTime(nonlinsys[i].oldValueList, time);
  }
}


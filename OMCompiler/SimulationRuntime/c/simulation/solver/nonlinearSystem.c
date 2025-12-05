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

#include "../jacobian_util.h"
#include "../../util/simulation_options.h"
#include "../../util/omc_error.h"
#include "../../util/omc_file.h"
#include "nonlinearSystem.h"
#include "nonlinearValuesList.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "kinsolSolver.h"
#include "kinsol_b.h"
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
                           NLS_SOLVER_STATUS solved)
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
  sprintf(buffer, "%s", (solved == NLS_SOLVED || solved == NLS_SOLVED_LESS_ACCURACY)?"TRUE":"FALSE");
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

/**
 * @brief Allocate and initialize NLS user data.
 *
 * NLS user data is passed to 3rdParty non-linear solvers, to be used
 * in e.g. residual and Jacobian functions provided by C runtime.
 *
 * @param data              Pointer to data.
 * @param threadData        Pointer to thread data.
 * @param sysNumber         Index of non-linear system.
 *                          A non-negative index indicates that nlsData is a pointer to
 *                          data->simulationInfo->nonlinearSystemData[sysNumber]
 * @param nlsData           Pointer to non-linear system data corresponding to sysNumber.
 * @param analyticJacobian  Pointer to analytic Jacobian. Can be NULL.
 * @return NLS_USERDATA*    Newly allocated struct with NLS user data.
 */
NLS_USERDATA* initNlsUserData(DATA* data, threadData_t* threadData, int sysNumber, NONLINEAR_SYSTEM_DATA* nlsData, JACOBIAN* analyticJacobian) {
  NLS_USERDATA* userData = (NLS_USERDATA*) malloc(sizeof(NLS_USERDATA));
  assertStreamPrint(threadData, userData != NULL, "setNlsUserData failed: userData is NULL");

  userData->data = data;
  userData->threadData = threadData;
  userData->sysNumber = sysNumber;
  userData->nlsData = nlsData;
  userData->analyticJacobian = analyticJacobian;
  userData->solverData = NULL;

  return userData;
}

/**
 * @brief Free NLS user data struct.
 *
 * Only frees memory of NLS data struct, not of its members.
 *
 * @param userData  Pointer to NLS user data.
 */
void freeNlsUserData(NLS_USERDATA* userData) {
  free(userData);
}

/**
 * @brief Initialize internal structure of non-linear system.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param nonlinsys         Pointer to non-linear system.
 * @param sysNum            Number of non-linear system.
 * @param isSparseNls       Becomes true when non-linear system density is
 *                          smaller than maximum allowed density for sparse solvers.
 *                          Otherwise value stays unchanged.
 * @param isBigNls          Becomes true when non-linear system size is greater than
 *                          minimum system size for sparse solvers.
 *                          Otherwise value stays unchanged.
 */
void initializeNonlinearSystemData(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA *nonlinsys, int sysNum, modelica_boolean* isSparseNls, modelica_boolean* isBigNls) {
  modelica_integer size;
  unsigned int nnz;
  struct dataSolver *solverData;
  struct dataMixedSolver *mixedSolverData;
  JACOBIAN* jacobian;

  size = nonlinsys->size;
  nonlinsys->numberOfFEval = 0;
  nonlinsys->numberOfIterations = 0;

  /* check if residual function pointer are valid */
  assertStreamPrint(threadData, (nonlinsys->residualFunc != NULL) || (nonlinsys->strictTearingFunctionCall != NULL), "residual function pointer is invalid");

  /* check if analytical jacobian is created */
  if(nonlinsys->jacobianIndex != -1)
  {
    jacobian = &(data->simulationInfo->analyticJacobians[nonlinsys->jacobianIndex]);
    assertStreamPrint(threadData, 0 != nonlinsys->analyticalJacobianColumn, "jacobian function pointer is invalid" );
    if(nonlinsys->initialAnalyticalJacobian(data, threadData, jacobian))
    {
      nonlinsys->jacobianIndex = -1;
      jacobian = NULL;
    }
  } else {
    jacobian = NULL;
  }

  /* allocate system data */
  nonlinsys->nlsx = (double*) malloc(size*sizeof(double));
  nonlinsys->nlsxExtrapolation = (double*) malloc(size*sizeof(double));
  nonlinsys->nlsxOld = (double*) malloc(size*sizeof(double));
  nonlinsys->resValues = (double*) malloc(size*sizeof(double));

  /* allocate value list*/
  nonlinsys->oldValueList = allocValueList(1, nonlinsys->size);

  nonlinsys->lastTimeSolved = 0.0;

  /* Allocate nomianl, min and max */
  nonlinsys->nominal = (double*) malloc(size*sizeof(double));
  nonlinsys->min = (double*) malloc(size*sizeof(double));
  nonlinsys->max = (double*) malloc(size*sizeof(double));
  /* Init sparsitiy pattern */
  nonlinsys->initializeStaticNLSData(data, threadData, nonlinsys, 1 /* true */, 1 /* true */);

  if(nonlinsys->isPatternAvailable) {
    /* only test for singularity if sparsity pattern is supposed to be there */
    modelica_boolean useSparsityPattern = sparsitySanityCheck(nonlinsys->sparsePattern, nonlinsys->size, OMC_LOG_NLS);
    if (!useSparsityPattern) {
      // free sparsity pattern and don't use scaling
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Sparsity pattern for non-linear system %d is not regular. "
                                        "This indicates that something went wrong during sparsity pattern generation. "
                                        "Removing sparsity pattern and disabling NLS scaling.", sysNum);
      /* DEBUG */
      //printSparseStructure(nonlinsys->sparsePattern, nonlinsys->size, nonlinsys->size, OMC_LOG_NLS, "NLS sparse pattern");
      freeSparsePattern(nonlinsys->sparsePattern);
      free(nonlinsys->sparsePattern);
      nonlinsys->sparsePattern = NULL;
      nonlinsys->isPatternAvailable = FALSE;
      omc_flag[FLAG_NO_SCALING] = TRUE;
    }
  }

#if !defined(OMC_MINIMAL_RUNTIME)
  /* csv data call stats*/
  if (data->simulationInfo->nlsCsvInfomation)
  {
    if (initializeNLScsvData(data, nonlinsys))
    {
      throwStreamPrint(threadData, "csvData initialization failed");
    }
    else
    {
      print_csvLineCallStatsHeader(((struct csvStats*) nonlinsys->csvData)->callStats);
      print_csvLineIterStatsHeader(data, nonlinsys, ((struct csvStats*) nonlinsys->csvData)->iterStats);
    }
  }
#endif

  /* Check if the system is sparse enough to use kinsol.
   * It is considered sparse if
   * the density (nnz/size^2) is less than a threshold or
   * the size is bigger than a threshold */
  nonlinsys->nlsMethod = data->simulationInfo->nlsMethod;
  nonlinsys->nlsLinearSolver = data->simulationInfo->nlsLinearSolver;
#if !defined(OMC_MINIMAL_RUNTIME)
  if (nonlinsys->isPatternAvailable && !(data->simulationInfo->nlsMethod == NLS_KINSOL || data->simulationInfo->nlsMethod == NLS_KINSOL_B))
  {
    nnz = nonlinsys->sparsePattern->numberOfNonZeros;

    if (nnz/(double)(size*size) < nonlinearSparseSolverMaxDensity) {
      nonlinsys->nlsMethod = NLS_KINSOL;
      nonlinsys->nlsLinearSolver = NLS_LS_KLU;
      *isSparseNls = TRUE;
      if (size > nonlinearSparseSolverMinSize) {
        *isBigNls = TRUE;
        infoStreamPrint(OMC_LOG_STDOUT, 0,
                        "Using sparse solver kinsol for nonlinear system %d (%d),\n"
                        "because density of %.2f remains under threshold of %.2f\n"
                        "and size of %d exceeds threshold of %d.",
                        sysNum, (int)nonlinsys->equationIndex, nnz/(double)(size*size), nonlinearSparseSolverMaxDensity,
                        (int)size, nonlinearSparseSolverMinSize);
      } else {
        infoStreamPrint(OMC_LOG_STDOUT, 0,
                        "Using sparse solver kinsol for nonlinear system %d (%d),\n"
                        "because density of %.2f remains under threshold of %.2f.",
                        sysNum, (int)nonlinsys->equationIndex, nnz/(double)(size*size), nonlinearSparseSolverMaxDensity);
      }
    } else if (size > nonlinearSparseSolverMinSize) {
      nonlinsys->nlsMethod = NLS_KINSOL;
      nonlinsys->nlsLinearSolver = NLS_LS_KLU;
      *isBigNls = TRUE;
      infoStreamPrint(OMC_LOG_STDOUT, 0,
                      "Using sparse solver kinsol for nonlinear system %d (%d),\n"
                      "because size of %d exceeds threshold of %d.",
                      sysNum, (int)nonlinsys->equationIndex, (int)size, nonlinearSparseSolverMinSize);
    }
  }
#endif

  /* Set NLS user data */
  NLS_USERDATA* nlsUserData = initNlsUserData(data, threadData, sysNum, nonlinsys, jacobian);

// FIXME: add generation of scalar system (total system size = 1) to codegen
#if !defined(OMC_MINIMAL_RUNTIME)
  /* check for trivial sparsity pattern (is not always generated) */
  if (nonlinsys->size == 1 && !nonlinsys->isPatternAvailable && (nonlinsys->nlsMethod == NLS_KINSOL || nonlinsys->nlsMethod == NLS_KINSOL_B)) {
    nonlinsys->nlsMethod = NLS_HYBRID;
    nonlinsys->nlsLinearSolver = NLS_LS_DEFAULT;
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Sparsity pattern for non-linear system %d with size 1x1 (nnz = 1) does not exist. "
                                           "Can not use the set sparse NLS solver - changing the method to Hybrid.", sysNum);
  }
#endif

  /* allocate stuff depending on the chosen method */
  switch(nonlinsys->nlsMethod)
  {
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_HYBRID:
    solverData = (struct dataSolver*) malloc(sizeof(struct dataSolver));
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      solverData->ordinaryData = allocateHybrdData(size-1, nlsUserData);
      nlsUserData = initNlsUserData(data, threadData, sysNum, nonlinsys, jacobian); /* Seperate userData for homotopy solver */
      solverData->initHomotopyData = (void*) allocateHomotopyData(size-1, nlsUserData);
    } else {
      solverData->ordinaryData = allocateHybrdData(size, nlsUserData);
    }
    nonlinsys->solverData = (void*) solverData;
    break;
  case NLS_KINSOL:
    solverData = (struct dataSolver*) malloc(sizeof(struct dataSolver));
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      solverData->initHomotopyData = (void*) allocateHomotopyData(size-1, nlsUserData);
    } else {
      nonlinsys->solverData = (void*) nlsKinsolAllocate(size, nlsUserData, TRUE, nonlinsys->isPatternAvailable);
      solverData->ordinaryData = nonlinsys->solverData;
    }
    nonlinsys->solverData = (void*) solverData;
    break;
  case NLS_KINSOL_B:
    solverData = (struct dataSolver*) malloc(sizeof(struct dataSolver));
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      solverData->initHomotopyData = (void*) allocateHomotopyData(size-1, nlsUserData);
    } else {
      nonlinsys->solverData = (void*) B_nlsKinsolAllocate(size, nlsUserData, TRUE, nonlinsys->isPatternAvailable);
      solverData->ordinaryData = nonlinsys->solverData;
    }
    nonlinsys->solverData = (void*) solverData;
    break;
  case NLS_NEWTON:
    solverData = (struct dataSolver*) malloc(sizeof(struct dataSolver));
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      solverData->ordinaryData = (void*) allocateNewtonData(size-1, nlsUserData);
      nlsUserData = initNlsUserData(data, threadData, sysNum, nonlinsys, jacobian); /* Seperate userData for homotopy solver */
      solverData->initHomotopyData = (void*) allocateHomotopyData(size-1, nlsUserData);
    } else {
      solverData->ordinaryData = (void*) allocateNewtonData(size, nlsUserData);
    }
    nonlinsys->solverData = (void*) solverData;
    break;
  case NLS_MIXED:
    mixedSolverData = (struct dataMixedSolver*) malloc(sizeof(struct dataMixedSolver));
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      mixedSolverData->newtonHomotopyData = (void*) allocateHomotopyData(size-1, nlsUserData);
      nlsUserData = initNlsUserData(data, threadData, sysNum, nonlinsys, jacobian); /* Seperate userData for hybrid solver */
      mixedSolverData->hybridData = (void*) allocateHybrdData(size-1, nlsUserData);
    } else {
      mixedSolverData->newtonHomotopyData = (void*) allocateHomotopyData(size, nlsUserData);
      nlsUserData = initNlsUserData(data, threadData, sysNum, nonlinsys, jacobian); /* Seperate userData for hybrid solver */
      mixedSolverData->hybridData = (void*) allocateHybrdData(size, nlsUserData);
    }
    nonlinsys->solverData = (void*) mixedSolverData;
    break;
#endif
  case NLS_HOMOTOPY:
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      nonlinsys->solverData = (void*) allocateHomotopyData(size-1, nlsUserData);
    } else {
      nonlinsys->solverData = (void*) allocateHomotopyData(size, nlsUserData);
    }
    break;
  default:
    throwStreamPrint(threadData, "unrecognized nonlinear solver");
  }

  return;
}

/**
 * @brief Initialize all non-linear systems.
 *
 * Loop over all non-linear systems and call initializeNonlinearSystemData.
 * Memory for data->simulationInfo->nonlinearSystemData is already allocated.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @return int          Return 0 on success.
 */
int initializeNonlinearSystems(DATA *data, threadData_t *threadData)
{
  int i;
  modelica_boolean someSmallDensity = FALSE;  /* pretty dumping of flag info */
  modelica_boolean someBigSize = FALSE;       /* analogous to someSmallDensity */
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo->nonlinearSystemData;

  infoStreamPrint(OMC_LOG_NLS, 1, "initialize non-linear system solvers");
  infoStreamPrint(OMC_LOG_NLS, 0, "%ld non-linear systems", data->modelData->nNonLinearSystems);

  /* set the default nls linear solver depending on the default nls method */
  if (data->simulationInfo->nlsLinearSolver == NLS_LS_DEFAULT) {
#if !defined(OMC_MINIMAL_RUNTIME)
    /* kinsol works best with KLU,
       they are both sparse so it makes sense to use them together */
    if (data->simulationInfo->nlsMethod == NLS_KINSOL || data->simulationInfo->nlsMethod == NLS_KINSOL_B) {
      data->simulationInfo->nlsLinearSolver = NLS_LS_KLU;
    } else {
      data->simulationInfo->nlsLinearSolver = NLS_LS_LAPACK;
    }
#else
    data->simulationInfo->nlsLinearSolver = NLS_LS_LAPACK;
#endif
  }

  for (i=0; i<data->modelData->nNonLinearSystems; ++i) {
    initializeNonlinearSystemData(data, threadData, &nonlinsys[i], i, &someSmallDensity, &someBigSize);
  }

  /* print relevant flag information */
  if (someSmallDensity) {
    if (someBigSize) {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "The maximum density and the minimal system size for using sparse solvers can be\n"
                                     "specified using the runtime flags '<-nlssMaxDensity=value>' and '<-nlssMinSize=value>'.");
    } else {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "The maximum density for using sparse solvers can be specified\n"
                                     "using the runtime flag '<-nlssMaxDensity=value>'.");
    }
  } else if (someBigSize) {
    infoStreamPrint(OMC_LOG_STDOUT, 0, "The minimal system size for using sparse solvers can be specified\n"
                                   "using the runtime flag '<-nlssMinSize=value>'.");
  }

  messageClose(OMC_LOG_NLS);

  return 0;
}

/**
 * @brief Initialize min, max, nominal for non-linear systems.
 *
 * This function allocates memory for sparsity pattern and
 * initialized nominal, min, max and spsarsity pattern.
 *
 * @param data          Pointer to data.
 * @param threadData    Thread data for error handling.
 * @return int          Return 0.
 */
int updateStaticDataOfNonlinearSystems(DATA *data, threadData_t *threadData)
{
  int i;
  int size;
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo->nonlinearSystemData;

  infoStreamPrint(OMC_LOG_NLS, 1, "update static data of non-linear system solvers");

  for(i=0; i<data->modelData->nNonLinearSystems; ++i)
  {
    nonlinsys[i].initializeStaticNLSData(data, threadData, &nonlinsys[i], FALSE, FALSE);
  }

  messageClose(OMC_LOG_NLS);

  return 0;
}

/**
 * @brief Free non-linear system data.
 *
 * Freeing non-linear solver data as well.
 *
 * @param data        Pointer to data struct.
 * @param threadData  Pointer to thread data. Used for error handling.
 * @param nonlinsys   Pointer to non-linear system data.
 */
void freeNonlinearSyst(DATA* data, threadData_t* threadData, NONLINEAR_SYSTEM_DATA* nonlinsys)
{
  struct csvStats* stats;
  NLS_USERDATA* userData;

  free(nonlinsys->nlsx);
  free(nonlinsys->nlsxExtrapolation);
  free(nonlinsys->nlsxOld);
  free(nonlinsys->resValues);
  free(nonlinsys->nominal);
  free(nonlinsys->min);
  free(nonlinsys->max);
  nonlinsys->freeStaticNLSData(data, threadData, nonlinsys);

  freeValueList(nonlinsys->oldValueList, 1);
  freeNonlinearPattern(nonlinsys->nonlinearPattern);

  /* Free CSV data */
#if !defined(OMC_MINIMAL_RUNTIME)
  if (data->simulationInfo->nlsCsvInfomation)
  {
    stats = nonlinsys->csvData;
    omc_write_csv_free(stats->callStats);
    omc_write_csv_free(stats->iterStats);
    free(nonlinsys->csvData);
    // TODO: Make a function freeNLScsvData
  }
#endif

  /* free solver data */
  // TODO: Make this simpler. Don't cast nonlinsys->solverData back and forth.
  // Always have a structure accepting two solver methods (primary and backup) and make the missing one NULL.
  // Also just set nonlinsys->solverData->ordinaryData to NULL, if no hybrid solver is available
  // and make freeHybrdData(NULL) work.
  switch(nonlinsys->nlsMethod)
  {
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_HYBRID:
    freeHybrdData(((struct dataSolver*) nonlinsys->solverData)->ordinaryData);
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      freeHomotopyData(((struct dataSolver*) nonlinsys->solverData)->initHomotopyData);
    }
    free(nonlinsys->solverData);
    break;
  case NLS_KINSOL:
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      freeHomotopyData(((struct dataSolver*) nonlinsys->solverData)->initHomotopyData);
    } else {
      nlsKinsolFree(((struct dataSolver*) nonlinsys->solverData)->ordinaryData);
    }
    free(nonlinsys->solverData);
    break;
  case NLS_KINSOL_B:
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      freeHomotopyData(((struct dataSolver*) nonlinsys->solverData)->initHomotopyData);
    } else {
      B_nlsKinsolFree(((struct dataSolver*) nonlinsys->solverData)->ordinaryData);
    }
    free(nonlinsys->solverData);
    break;
  case NLS_NEWTON:
    freeNewtonData(((struct dataSolver*) nonlinsys->solverData)->ordinaryData);
    if (nonlinsys->homotopySupport && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY )) {
      freeHomotopyData(((struct dataSolver*) nonlinsys->solverData)->initHomotopyData);
    }
    free(nonlinsys->solverData);
    break;
#endif
  case NLS_HOMOTOPY:
    freeHomotopyData(nonlinsys->solverData);
    break;
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_MIXED:
    freeHomotopyData(((struct dataMixedSolver*) nonlinsys->solverData)->newtonHomotopyData);
    freeHybrdData(((struct dataMixedSolver*) nonlinsys->solverData)->hybridData);
    free(nonlinsys->solverData);
    break;
#endif
  default:
    throwStreamPrint(threadData, "freeNonlinearSyst: Unrecognized non-linear solver method");
  }

  return;
}

/**
 * @brief Free memory for all non-linear systems in simulationInfo.
 *
 * Free all non-linear systems from array data->simulationInfo->nonlinearSystemData.
 *
 * @param data          Pointer to data struct.
 * @param threadData    Pointer to thread data. Used for error handling.
 */
void freeNonlinearSystems(DATA *data, threadData_t *threadData)
{
  int i;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo->nonlinearSystemData;

  infoStreamPrint(OMC_LOG_NLS, 1, "free non-linear system solvers");
  for(i=0; i<data->modelData->nNonLinearSystems; ++i)
  {
    freeNonlinearSyst(data, threadData, &nonlinsys[i]);
  }

  messageClose(OMC_LOG_NLS);

  return;
}

/**
 * @brief Print non-linear system statistics to stream.
 *
 * @param nonlinsys   Non-linear system data to print.
 * @param stream      Log stream to use for logging.
 */
void printNonLinearSystemSolvingStatistics(NONLINEAR_SYSTEM_DATA* nonlinsys, enum OMC_LOG_STREAM stream)
{
  if (!OMC_ACTIVE_STREAM(stream)) return;
  infoStreamPrint(stream, 1, "Non-linear system %d of size %d solver statistics:", (int)nonlinsys->equationIndex, (int)nonlinsys->size);
  infoStreamPrint(stream, 0, " number of calls                : %ld", nonlinsys->numberOfCall);
  infoStreamPrint(stream, 0, " number of iterations           : %ld", nonlinsys->numberOfIterations);
  infoStreamPrint(stream, 0, " number of function evaluations : %ld", nonlinsys->numberOfFEval);
  infoStreamPrint(stream, 0, " number of jacobian evaluations : %ld", nonlinsys->numberOfJEval);
  infoStreamPrint(stream, 0, " time of jacobian evaluations   : %f", nonlinsys->jacobianTime);
  infoStreamPrint(stream, 0, " average time per call          : %f", nonlinsys->totalTime/nonlinsys->numberOfCall);
  infoStreamPrint(stream, 0, " total time                     : %f", nonlinsys->totalTime);
  messageClose(stream);
}

/*! \fn printNonLinearInitialInfo
 *
 *  This function prints information of an non-linear systems before an solving step.
 *
 *  \param [in]  [logName] log level in general OMC_LOG_NLS
 *         [ref] [data]
 *         [ref] [nonlinsys] index of corresponding non-linear system
 */
void printNonLinearInitialInfo(int logName, DATA* data, NONLINEAR_SYSTEM_DATA *nonlinsys)
{
  long i;

  if (!OMC_ACTIVE_STREAM(logName)) return;
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
 *  \param [in]  [logName] log level in general OMC_LOG_NLS
 *         [ref] [data]
 *         [ref] [nonlinsys] index of corresponding non-linear system
 */
void printNonLinearFinishInfo(int logName, DATA* data, NONLINEAR_SYSTEM_DATA *nonlinsys)
{
  long i;

  if (!OMC_ACTIVE_STREAM(logName)) return;

  switch (nonlinsys->solved)
  {
  case NLS_SOLVED:
    infoStreamPrint(logName, 1, "Solution status: SOLVED");
    break;
  case NLS_SOLVED_LESS_ACCURACY:
    infoStreamPrint(logName, 1, "Solution status: SOLVED with less accuracy");
    break;
  case NLS_FAILED:
    infoStreamPrint(logName, 1, "Solution status: FAILED");
    break;
  default:
    throwStreamPrint(NULL, "Unhandled case in printNonLinearFinishInfo");
    break;
  }
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
  printValuesListTimes(nonlinsys->oldValueList->valueList);
  /* if list is empty use current start values */
  if (listLen(nonlinsys->oldValueList->valueList)==0)
  {
    /* use old value if no values are stored in the list */
    memcpy(nonlinsys->nlsx, nonlinsys->nlsxOld, nonlinsys->size*(sizeof(double)));
  }
  else
  {
    /* get extrapolated values */
    getValues(nonlinsys->oldValueList->valueList, time, nonlinsys->nlsxExtrapolation, nonlinsys->nlsxOld);
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
int updateInitialGuessDB(NONLINEAR_SYSTEM_DATA *nonlinsys, double time, EVAL_CONTEXT context)
{
  /* Variables */
  VALUE* tmpNode;

  /* write solution to oldValue list for extrapolation */
  if (nonlinsys->solved == NLS_SOLVED)
  {
    /* do not use solution of jacobian for next extrapolation */
    if (context == CONTEXT_ODE || context == CONTEXT_ALGEBRAIC || context == CONTEXT_EVENTS)
    {
      tmpNode = createValueElement(nonlinsys->size, time, nonlinsys->nlsx);
      addListElement(nonlinsys->oldValueList->valueList,
                     tmpNode);
      freeValue(tmpNode);
    }
  }
  else if (nonlinsys->solved == NLS_SOLVED_LESS_ACCURACY)
  {
    if (listLen((nonlinsys->oldValueList)->valueList)>0)
    {
      cleanValueList(nonlinsys->oldValueList->valueList, NULL);
    }
    /* do not use solution of jacobian for next extrapolation */
    if (context == CONTEXT_ODE || context == CONTEXT_ALGEBRAIC || context == CONTEXT_EVENTS)
    {
      tmpNode = createValueElement(nonlinsys->size, time, nonlinsys->nlsx);
      addListElement(nonlinsys->oldValueList->valueList,
                     tmpNode);
      freeValue(tmpNode);
    }
  }
  return 0;
}

/*! \fn updateInnerEquation
 *
 *  This function updates inner equation with the current x.
 *
 *  \param [ref] [data]
 *         [in]  [sysNumber] index of corresponding non-linear system
 */
int updateInnerEquation(RESIDUAL_USERDATA* resUserData, int sysNumber, int discrete)
{
  DATA *data = resUserData->data;
  threadData_t *threadData = resUserData->threadData;

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
    constraintViolated = nonlinsys->residualFuncConstraints(resUserData, nonlinsys->nlsx, nonlinsys->resValues, (int*)&nonlinsys->size);
  else
    nonlinsys->residualFunc(resUserData, nonlinsys->nlsx, nonlinsys->resValues, (int*)&nonlinsys->size);

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
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");
  }

  if(discrete)
  {
    data->simulationInfo->solveContinuous = 1;
  }

  return success;
}

/**
 * @brief Solve given non-linear system.
 *
 * @param data                Runtime data struct.
 * @param threadData          Thread data for error handling.
 * @param nonlinsys           Pointer to non-linear system.
 * @return NLS_SOLVER_STATUS  Return NLS_SOLVED on success,
 *                            NLS_SOLVED_LESS_ACCURACY if a less accurate solution was found and
 *                            NLS_FAILED otherwise.
 */
NLS_SOLVER_STATUS solveNLS(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys)
{
  NLS_SOLVER_STATUS solver_status = NLS_FAILED;
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
    solver_status = solveHybrd(data, threadData, nonlinsys);
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
    solver_status = nlsKinsolSolve(data, threadData, nonlinsys);
    /*catch */
    #ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
    #endif
    nonlinsys->solverData = solverData;
    break;
  case NLS_KINSOL_B:
    solverData = nonlinsys->solverData;
    nonlinsys->solverData = solverData->ordinaryData;
    /* try */
    #ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
    #endif
    solver_status = B_nlsKinsolSolve(data, threadData, nonlinsys);
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
    solver_status = solveNewton(data, threadData, nonlinsys);
    /*catch */
    #ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
    #endif
    /* check if solution process was successful, if not use alternative tearing set if available (dynamic tearing)*/
    if (solver_status != NLS_SOLVED && casualTearingSet){
      debugString(OMC_LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
      if(nonlinsys->strictTearingFunctionCall(data, threadData)) {
        solver_status = NLS_SOLVED;
      } else {
        solver_status = NLS_FAILED;
      }
    }
    nonlinsys->solverData = solverData;
    break;
#endif
  case NLS_HOMOTOPY:
    solver_status = solveHomotopy(data, threadData, nonlinsys);
    break;
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_MIXED:
    mixedSolverData = nonlinsys->solverData;
    nonlinsys->solverData = mixedSolverData->newtonHomotopyData;

    /* try */
    #ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
    #endif
    solver_status = solveHomotopy(data, threadData, nonlinsys);

    /* check if solution process was successful, if not use alternative tearing set if available (dynamic tearing)*/
    if (solver_status != NLS_SOLVED && casualTearingSet){
      debugString(OMC_LOG_DT, "Solving the casual tearing set failed! Now the strict tearing set is used.");
      if(nonlinsys->strictTearingFunctionCall(data, threadData)) {
        solver_status = NLS_SOLVED;
      } else {
        solver_status = NLS_FAILED;
      }
    }

    if (solver_status != NLS_SOLVED ) {
      nonlinsys->solverData = mixedSolverData->hybridData;
      solver_status = solveHybrd(data, threadData, nonlinsys);
    }

    /* update iteration variables of nonlinsys->nlsx */
    if (solver_status == NLS_SOLVED){
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

  return solver_status;
}

/**
 * @brief Solve initial non-linear system with homotopy solver
 *
 * @param data                Runtime data struct.
 * @param threadData          Thread data for error handling.
 * @param nonlinsys           Pointer to non-linear system data.
 * @return NLS_SOLVER_STATUS  Return solver status of homotopy solver.
 */
NLS_SOLVER_STATUS solveWithInitHomotopy(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys)
{
  NLS_SOLVER_STATUS success = NLS_FAILED;
  struct dataSolver *solverData;
  struct dataMixedSolver *mixedSolverData;

  /* use the homotopy solver for solving the initial system */
  switch(nonlinsys->nlsMethod)
  {
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_HYBRID:
  case NLS_KINSOL:
  case NLS_KINSOL_B:
  case NLS_NEWTON:
    solverData = nonlinsys->solverData;
    nonlinsys->solverData = solverData->initHomotopyData;
    success = solveHomotopy(data, threadData, nonlinsys);
    nonlinsys->solverData = solverData;
    break;
#endif
  case NLS_HOMOTOPY:
    success = solveHomotopy(data, threadData, nonlinsys);
    break;
#if !defined(OMC_MINIMAL_RUNTIME)
  case NLS_MIXED:
    mixedSolverData = nonlinsys->solverData;
    nonlinsys->solverData = mixedSolverData->newtonHomotopyData;
    success = solveHomotopy(data, threadData, nonlinsys);
    nonlinsys->solverData = mixedSolverData;
    break;
#endif
  default:
    throwStreamPrint(threadData, "unrecognized nonlinear solver");
  }

  return success;
}

/*! \fn Solve all non-linear systems in data->simulationInfo->nonlinearSystemData.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param sysNumber         Index of corresponding non-linear system
 *
 * @author ptaeuber
 */
int solve_nonlinear_system(DATA *data, threadData_t *threadData, int sysNumber)
{
  assertStreamPrint(NULL, NULL != threadData, "threadData is NULL. Something went horribly wrong!");
  assertStreamPrint(threadData, NULL != data, "data is NULL. Something went horribly wrong!");

  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=NULL};
  int saveJumpState, constraintsSatisfied;
  NONLINEAR_SYSTEM_DATA* nonlinsys = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  int casualTearingSet = nonlinsys->strictTearingFunctionCall != NULL;
  int step;
  int equidistantHomotopy = 0;
  int solveWithHomotopySolver = 0;
  int homotopyDeactivated = 0;
  int j;
  int nlsLs;
  modelica_boolean kinsol = FALSE;
  int res;
  struct dataSolver *solverData;
  struct dataMixedSolver *mixedSolverData;
  char buffer[4096];
  FILE *pFile = NULL;
  double originalLambda = data->simulationInfo->lambda;

  if (!nonlinsys->logActive) {
    deactivateLogging();
  }

#if !defined(OMC_MINIMAL_RUNTIME)
  kinsol = (nonlinsys->nlsMethod == NLS_KINSOL) || (nonlinsys->nlsMethod == NLS_KINSOL_B);
#endif

  /* enable to avoid division by zero */
  data->simulationInfo->noThrowDivZero = 1;
  data->simulationInfo->solveContinuous = 1;

  /* performance measurement */
  rt_ext_tp_tick(&nonlinsys->totalTimeClock);

  infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 1, "Nonlinear system %ld dump OMC_LOG_NLS_EXTRAPOLATE", nonlinsys->equationIndex);
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
    // TODO: constraintsSatisfied never used
    constraintsSatisfied = updateInnerEquation(&resUserData, sysNumber, 1);
  }

  /* print debug initial information */
  infoStreamPrint(OMC_LOG_NLS, 1, "############ Solve nonlinear system %ld at time %g ############", nonlinsys->equationIndex, data->localData[0]->timeValue);
  printNonLinearInitialInfo(OMC_LOG_NLS, data, nonlinsys);

#if !defined(OMC_MINIMAL_RUNTIME)

  /* try */
#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* Improve start values with newton diagnostics method */
  if(omc_useStream[OMC_LOG_NLS_NEWTON_DIAGNOSTICS] && data->simulationInfo->initial) {
    EQUATION_INFO eqInfo = modelInfoGetEquation(&data->modelData->modelDataXml, nonlinsys->equationIndex);
    if (eqInfo.section == EQUATION_SECTION_INIT_LAMBDA0 || (eqInfo.section == EQUATION_SECTION_INITIAL && data->callback->functionInitialEquations_lambda0 == NULL)) {
      newtonDiagnostics(data, threadData, sysNumber);
    }
  }

  /*catch */
#ifndef OMC_EMCC
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

#endif


  /* try */
#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  // TODO: refactor this logic

  /* handle asserts */
  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_NONLINEARSOLVER;

  equidistantHomotopy = data->simulationInfo->initial
                        && nonlinsys->homotopySupport
                        && (data->callback->homotopyMethod == LOCAL_EQUIDISTANT_HOMOTOPY && init_lambda_steps >= 1);

  solveWithHomotopySolver = data->simulationInfo->initial
                            && nonlinsys->homotopySupport
                            && (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY );

  homotopyDeactivated = (!data->simulationInfo->initial                                    // Not an initialization system
                        || !nonlinsys->homotopySupport                                     // There is no homotopy in this component
                        || (data->callback->homotopyMethod == GLOBAL_EQUIDISTANT_HOMOTOPY) // Equidistant homotopy is performed globally in symbolic_initialization()
                        || (data->callback->homotopyMethod == LOCAL_EQUIDISTANT_HOMOTOPY   // Equidistant local homotopy is selected but homotopy is deactivated ...
                        && init_lambda_steps <= 0))
                        || data->callback->homotopyMethod == NO_HOMOTOPY ;                 // No Homotopy present

  nonlinsys->solved = NLS_FAILED;
  nonlinsys->initHomotopy = 0;

  /* If homotopy is deactivated in this place or flag homotopyOnFirstTry is not set,
     solve the system with the selected solver */
  if (homotopyDeactivated || !omc_flag[FLAG_HOMOTOPY_ON_FIRST_TRY]) {
    if (solveWithHomotopySolver && kinsol) {
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "Automatically set -homotopyOnFirstTry, because trying without homotopy first is not supported for the local global approach in combination with KINSOL.");
    } else {
      if (!homotopyDeactivated && !omc_flag[FLAG_HOMOTOPY_ON_FIRST_TRY])
        infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "Try to solve nonlinear initial system %d without homotopy first.", sysNumber);

      /* SOLVE! */
      nonlinsys->solved = solveNLS(data, threadData, nonlinsys);
    }
  }

  /* The following cases are only valid for initial systems with homotopy */
  /* **********************************************************************/

  /* If the adaptive local/global homotopy approach is activated and trying without homotopy failed or is not wanted,
     use the HOMOTOPY SOLVER */
  if (solveWithHomotopySolver && nonlinsys->solved != NLS_SOLVED) {
    if (!omc_flag[FLAG_HOMOTOPY_ON_FIRST_TRY] && !kinsol)
      warningStreamPrint(OMC_LOG_ASSERT, 0, "Failed to solve the initial system %d without homotopy method.", sysNumber);
    data->simulationInfo->lambda = 0.0;
    if (data->callback->homotopyMethod == LOCAL_ADAPTIVE_HOMOTOPY ) {
      // First solve the lambda0-system separately
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "Local homotopy with adaptive step size started for nonlinear system %d.", sysNumber);
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 1, "homotopy process\n---------------------------");
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "solve lambda0-system");
      nonlinsys->homotopySupport = 0;
      if (!kinsol) {
        nonlinsys->solved = solveNLS(data, threadData, nonlinsys);
      } else {
        nlsLs = data->simulationInfo->nlsLinearSolver;
        data->simulationInfo->nlsLinearSolver = NLS_LS_LAPACK;
        nonlinsys->solved = solveWithInitHomotopy(data, threadData, nonlinsys);
        data->simulationInfo->nlsLinearSolver = nlsLs;
      }
      nonlinsys->homotopySupport = 1;
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "solving lambda0-system done with%s success\n---------------------------", nonlinsys->solved==NLS_SOLVED ? "" : " no");
      messageClose(OMC_LOG_INIT_HOMOTOPY);
    }
    /* SOLVE! */
    if (data->callback->homotopyMethod == GLOBAL_ADAPTIVE_HOMOTOPY || nonlinsys->solved == NLS_SOLVED) {
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "run along the homotopy path and solve the actual system");
      nonlinsys->initHomotopy = 1;
      nonlinsys->solved = solveWithInitHomotopy(data, threadData, nonlinsys);
    }
  }

  /* If equidistant local homotopy is activated and trying without homotopy failed or is not wanted,
     use EQUIDISTANT LOCAL HOMOTOPY */
  if (equidistantHomotopy && nonlinsys->solved != NLS_SOLVED) {
    if (!omc_flag[FLAG_HOMOTOPY_ON_FIRST_TRY])
      warningStreamPrint(OMC_LOG_ASSERT, 0, "Failed to solve the initial system %d without homotopy method. The local homotopy method with equidistant step size is used now.", sysNumber);
    else
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "Local homotopy with equidistant step size started for nonlinear system %d.", sysNumber);
#if !defined(OMC_NO_FILESYSTEM)
    const char sep[] = ",";
    if(OMC_ACTIVE_STREAM(OMC_LOG_INIT_HOMOTOPY))
    {
      sprintf(buffer, "%s_nonlinsys%d_equidistant_local_homotopy.csv", data->modelData->modelFilePrefix, sysNumber);
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "The homotopy path of system %d will be exported to %s.", sysNumber, buffer);
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

      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "[system %d] homotopy parameter lambda = %g", sysNumber, data->simulationInfo->lambda);
      /* SOLVE! */
      nonlinsys->solved = solveNLS(data, threadData, nonlinsys);
      if (nonlinsys->solved != NLS_SOLVED) break;

#if !defined(OMC_NO_FILESYSTEM)
      if(OMC_ACTIVE_STREAM(OMC_LOG_INIT_HOMOTOPY))
      {
        infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "[system %d] homotopy parameter lambda = %g done\n---------------------------", sysNumber, data->simulationInfo->lambda);
        fprintf(pFile, "%.16g", data->simulationInfo->lambda);
        for(j=0; j<nonlinsys->size; ++j)
          fprintf(pFile, "%s%.16g", sep, nonlinsys->nlsx[j]);
        fprintf(pFile, "\n");
      }
#endif
    }

#if !defined(OMC_NO_FILESYSTEM)
    if(OMC_ACTIVE_STREAM(OMC_LOG_INIT_HOMOTOPY))
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

  messageClose(OMC_LOG_NLS_EXTRAPOLATE);
  /* update value list database */
  updateInitialGuessDB(nonlinsys, data->localData[0]->timeValue, data->simulationInfo->currentContext);
  if (nonlinsys->solved == NLS_SOLVED)
  {
    nonlinsys->lastTimeSolved = data->localData[0]->timeValue;
  }
  printNonLinearFinishInfo(OMC_LOG_NLS, data, nonlinsys);
  messageClose(OMC_LOG_NLS);


  /* enable to avoid division by zero */
  data->simulationInfo->noThrowDivZero = 0;
  data->simulationInfo->solveContinuous = 0;

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

  if (!nonlinsys->logActive) {
    reactivateLogging();
  }

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

  if(nonlinsys[i].solved == NLS_FAILED)
  {
    int index = nonlinsys[i].equationIndex, indexes[2] = {1,index};
    if (!printFailingSystems) return 1;
    warningStreamPrintWithEquationIndexes(OMC_LOG_NLS, omc_dummyFileInfo, 0, indexes, "nonlinear system %d fails: at t=%g", index, data->localData[0]->timeValue);
    if(data->simulationInfo->initial)
    {
      warningStreamPrint(OMC_LOG_INIT, 1, "proper start-values for some of the following iteration variables might help");
    }
    for(j=0; j<modelInfoGetEquation(&data->modelData->modelDataXml, (nonlinsys[i]).equationIndex).numVar; ++j) {
      int done=0;
      long k;
      const MODEL_DATA *mData = data->modelData;
      for(k=0; k<mData->nVariablesRealArray && !done; ++k)
      {
        if (!strcmp(mData->realVarsData[k].info.name, modelInfoGetEquation(&data->modelData->modelDataXml, (nonlinsys[i]).equationIndex).vars[j]))
        {
        done = 1;
        warningStreamPrint(OMC_LOG_INIT, 0, "[%ld] Real %s(start=%s, nominal=%s)",
                                     j+1,
                                     mData->realVarsData[k].info.name,
                                     real_vector_to_string(&mData->realVarsData[k].attribute.start, mData->realVarsData[k].dimension.numberOfDimensions == 0),
                                     real_vector_to_string(&mData->realVarsData[k].attribute.nominal, mData->realVarsData[k].dimension.numberOfDimensions == 0));
        }
      }
      if (!done)
      {
        warningStreamPrint(OMC_LOG_INIT, 0, "[%ld] Real %s(start=?, nominal=?)", j+1, modelInfoGetEquation(&data->modelData->modelDataXml, (nonlinsys[i]).equationIndex).vars[j]);
      }
    }
    if(data->simulationInfo->initial)
    {
      messageCloseWarning(OMC_LOG_INIT);
    }
    return 1;
  }
  if(nonlinsys[i].solved == NLS_SOLVED_LESS_ACCURACY)
  {
    nonlinsys[i].solved = NLS_SOLVED;
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
    cleanValueListbyTime(nonlinsys[i].oldValueList->valueList, time);
  }
}

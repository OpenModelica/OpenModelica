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

/*! \file genericRKmr.c
 *  Implementation of  a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau
 *
 *  \author bbachmann
 */

#include "generic_rk.h"

#include <float.h>
#include <math.h>
#include <string.h>

#include "external_input.h"
#include "jacobianSymbolical.h"
#include "kinsolSolver.h"
#include "model_help.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"
#include "simulation/options.h"
#include "simulation/results/simulation_result.h"
#include "util/omc_error.h"
#include "util/simulation_options.h"
#include "util/varinfo.h"
#include "util/jacobian_util.h"

// help functions
void printVector_genericRK(char name[], double* a, int n, double time);
void printIntVector_genericRK(char name[], int* a, int n, double time);
void printVector_genericRK_MR_fs(char name[], double* a, int n, double time, int nIndx, int* indx);
void printMatrix_genericRK(char name[], double* a, int n, double time);


// singlerate step function
int expl_diag_impl_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

void residual_DIRK_MR(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_DIRK_column_MR(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

// step size control function
double IController(double* err_values, double* stepSize_values, double err_order);
double PIController(double* err_values, double* stepSize_values, double err_order);

double checkForEvents(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double timeLeft, double* leftValues, double timeRight, double* rightValues);

/**
 * @brief Initialize static data of non-linear system for DIRK.
 *
 * Initialize for diagoanl implicit Runge-Kutta (DIRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_DIRK_MR(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys) {

  // Nur für FastStates!!!! Ändern sich während der Simulation
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  nonlinsys->sparsePattern = NULL;
  nonlinsys->isPatternAvailable = FALSE;
  return;
}

struct RK_USER_DATA_MR {
  DATA* data;
  threadData_t* threadData;
  DATA_GMRI* gmriData;
};

struct dataSolver
{
  void* ordinaryData;
  void* initHomotopyData;
};


/**
 * @brief Allocate and initialize non-linear system data for Runge-Kutta method.
 *
 * Runge-Kutta method has to be implicit or diagonal implicit.
 *
 * @param data                        Runtime data struct.
 * @param threadData                  Thread data for error handling.
 * @param gmriData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GMRI* gmriData) {
  assertStreamPrint(threadData, gmriData->type != RK_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  ANALYTIC_JACOBIAN* jacobian = NULL;

  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

  nlsData->size = gmriData->nStates;
  nlsData->equationIndex = -1;

  nlsData->homotopySupport = FALSE;
  nlsData->initHomotopy = FALSE;
  nlsData->mixedSystem = FALSE;

  nlsData->min = NULL;
  nlsData->max = NULL;
  nlsData->nominal = NULL;

  switch (gmriData->type)
  {
  case RK_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK_MR;
    nlsData->analyticalJacobianColumn = NULL;//jacobian_DIRK_column_MR;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_DIRK_MR;
    nlsData->getIterationVars = NULL;

    gmriData->symJacAvailable = FALSE;
    break;
  // case MS_TYPE_IMPLICIT:
  //   nlsData->residualFunc = residual_MS;
  //   nlsData->analyticalJacobianColumn = jacobian_MS_column;
  //   nlsData->initializeStaticNLSData = initializeStaticNLSData_MS;
  //   nlsData->getIterationVars = NULL;

  //   gmriData->symJacAvailable = TRUE;
  //   break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", gmriData->type);
    break;
  }

  /* allocate system data */
  nlsData->nlsx = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxExtrapolation = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxOld = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->resValues = (double*) malloc(nlsData->size*sizeof(double));

  nlsData->lastTimeSolved = 0.0;

  nlsData->nominal = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->min = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->max = (double*) malloc(nlsData->size*sizeof(double));

  // // TODO: Do we need to initialize the Jacobian or is it already initialized?
  // ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  // data->callback->initialAnalyticJacobianA(data, threadData, jacobian_ODE);
  nlsData->initializeStaticNLSData(data, threadData, nlsData);

  // TODO: Set callback to initialize Jacobian
  //       Write said function...
  // TODO: Free memory
  gmriData->jacobian = initAnalyticJacobian(gmriData->nlSystemSize, gmriData->nlSystemSize, gmriData->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Initialize NLS method */
  switch (gmriData->nlsSolverMethod) {
  case RK_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData =(void*) allocateNewtonData(nlsData->size);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case RK_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (gmriData->symJacAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsData->nlsLinearSolver);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    if (gmriData->symJacAvailable) {
      resetKinsolMemory(solverData->ordinaryData, nlsData->sparsePattern->numberOfNonZeros, nlsData->analyticalJacobianColumn);
    } else {
      resetKinsolMemory(solverData->ordinaryData, nlsData->size*nlsData->size, NULL);
      int flag = KINSetJacFn(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, NULL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", RK_NLS_METHOD_NAME[gmriData->nlsSolverMethod]);
    return NULL;
    break;
  }

  return nlsData;
}

/**
 * @brief Function allocates memory needed for chosen RK method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int allocateDataGenericRK_MR(DATA* data, threadData_t *threadData, DATA_GSRI* gsriData)
{
  DATA_GMRI* gmriData = (DATA_GMRI*) malloc(sizeof(DATA_GMRI));
  gsriData->gmriData = gmriData;

  gmriData->nStates = gsriData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gmriData->RK_method = getRK_Method(FLAG_RK_MR);
  gmriData->tableau = initButcherTableau(gmriData->RK_method);
  if (gmriData->tableau == NULL){
    // ERROR
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);
  }

  // Get size of non-linear system
  analyseButcherTableau(gmriData->tableau, gmriData->nStates, &gmriData->nlSystemSize, &gmriData->type);

  switch (gmriData->type)
  {
  case RK_TYPE_EXPLICIT:
    gmriData->isExplicit = TRUE;
    gmriData->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case RK_TYPE_DIRK:
    gmriData->isExplicit = FALSE;
    gmriData->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case RK_TYPE_IMPLICIT:
    errorStreamPrint(LOG_STDOUT, 0, "Fully Implicit RK method is not supported for the fast states integration!");
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);

    break;
  default:
    // Error
    break;
  }

  infoStreamPrint(LOG_SOLVER, 0, "Step control factor is set to %g", gmriData->tableau->fac);

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_RK_STEPSIZE_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    gmriData->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "PIController is use for step size control");
  } else
  {
    gmriData->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "IController is use for step size control");
  }

  // allocate memory for the generic RK method
  gmriData->y = malloc(sizeof(double)*gmriData->nStates);
  gmriData->yOld = malloc(sizeof(double)*gmriData->nStates);
  gmriData->yt = malloc(sizeof(double)*gmriData->nStates);
  gmriData->f = malloc(sizeof(double)*gmriData->nStates);
  if (!gmriData->isExplicit) {
    gmriData->Jf = malloc(sizeof(double)*gmriData->nStates*gmriData->nStates);
    for (int i=0; i<gmriData->nStates*gmriData->nStates; i++)
      gmriData->Jf[i] = 0;

  } else {
    gmriData->Jf = NULL;
  }
  gmriData->k = malloc(sizeof(double)*gmriData->nStates*gmriData->tableau->nStages);
  gmriData->res_const = malloc(sizeof(double)*gmriData->nStates);
  gmriData->errest = malloc(sizeof(double)*gmriData->nStates);
  gmriData->errtol = malloc(sizeof(double)*gmriData->nStates);
  gmriData->err = malloc(sizeof(double)*gmriData->nStates);
  gmriData->ringBufferSize = 5;
  gmriData->errValues = malloc(sizeof(double)*gmriData->ringBufferSize);
  gmriData->stepSizeValues = malloc(sizeof(double)*gmriData->ringBufferSize);

  gmriData->nFastStates = gmriData->nStates;
  gmriData->nSlowStates = 0;

  printButcherTableau(gmriData->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  gmriData->stepsDone = 0;
  gmriData->evalFunctionODE = 0;
  gmriData->evalJacobians = 0;
  gmriData->errorTestFailures = 0;
  gmriData->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available and needed */
  if (!gmriData->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      gmriData->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
    } else {
      gmriData->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
  //gmriData->nlsSolverMethod = getRK_NLS_Method();
    gmriData->nlsSolverMethod = RK_NLS_NEWTON;
    gmriData->nlsData = initRK_NLS_DATA_MR(data, threadData, gmriData);
    if (!gmriData->nlsData) {
      return -1;
    }
  }  else
  {
    gmriData->symJacAvailable = FALSE;
    gmriData->nlsSolverMethod = RK_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    gmriData->nlsData = NULL;
    gmriData->jacobian = NULL;
  }

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGenericRK_MR(DATA_GMRI* gmriData) {
  /* Free non-linear system data */
  if(gmriData->nlsData != NULL) {
    struct dataSolver* dataSolver = gmriData->nlsData->solverData;
    switch (gmriData->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) gsriData->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled RK_NLS_METHOD in freeDataGenericRK. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(gmriData->nlsData);
  }

  freeButcherTableau(gmriData->tableau);

  free(gmriData->y);
  free(gmriData->yOld);
  free(gmriData->yt);
  free(gmriData->f);
  free(gmriData->Jf);
  free(gmriData->k);
  free(gmriData->res_const);
  free(gmriData->errest);
  free(gmriData->errtol);
  free(gmriData->err);
  free(gmriData->errValues);
  free(gmriData->stepSizeValues);

  free(gmriData);
  gmriData = NULL;

  return;
}

/*!	\fn wrapper_Jf_genericRK
 *
 *  calculate the Jacobian of functionODE with respect to the fast states
 *  IMPORTANT: assuming the correct values of the time value and the states are set
 *  \param [in]      n              pointer to number of states
 *  \param [in]      x              pointer to state vector
 *  \param [in]      fvec           pointer to corresponding fODE-values usually
 *                                  stored in gmriData->f (verify before calling)
 *  \param [in/out]  gmriData       data of the integrator (DATA_GMRI)
 *  \param [out]     fODE           pointer to state derivatives
 *
 *  result of the Jacobian is stored in solverData->fjac (DATA_NEWTON) ???????
 *
 */
int wrapper_Jf_genericRK_MR(int n, double t, double* x, double* fODE, void* gmriData_void)
{
  DATA_GMRI* gmriData = (DATA_GMRI*) gmriData_void;

  DATA* data = gmriData->data;
  threadData_t* threadData = gmriData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)gmriData->nlsSolverData;

  int i,ii,j,jj,l,callJacColumns;
  int nFastStates = gmriData->nFastStates;

  // if ((solverData->calculate_jacobian >= 0) && (gmriData->evalJacobians==0))
  {
    /* profiling */
    rt_tick(SIM_TIMER_JACOBIAN);

    gmriData->evalJacobians++;

    if (gmriData->symJacAvailable)
    {
      const int index = data->callback->INDEX_JAC_A;
      ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);
      unsigned int columns = jac->sizeCols;
      unsigned int rows = jac->sizeRows;
      unsigned int sizeTmpVars = jac->sizeTmpVars;
      unsigned int currentIndex, nth;
      SPARSE_PATTERN* spp = jac->sparsePattern;

      /* Evaluate constant equations if available */
      // BB: Do I need this?
      if (jac->constantEqns != NULL) {
        jac->constantEqns(data, threadData, jac, NULL);
      }
      // genericColoredSymbolicJacobianEvaluation(rows, columns, spp, gmriData->Jf, jac,
      //                                     data, threadData, &setJacElementESDIRKSparse_MR);
      /* Reset seed vector */
      // This is necessary, when memory is allocated
      for (j=0; j < columns; j++) {
        jac->seedVars[j] = 0;
      }
      for (i=0; i < spp->maxColors; i++) {
        callJacColumns = FALSE;
        for (jj=0; jj < nFastStates; jj++) {
          j = gmriData->fastStates[jj];
          if (spp->colorCols[j]-1 == i) {
            callJacColumns = TRUE;
            jac->seedVars[j] = 1;
          }
        }

        if (callJacColumns) {
          /* Evaluate with updated seed vector */
          data->callback->functionJacA_column(data, threadData, jac, NULL);
          for (jj=0; jj < nFastStates; jj++) {
            j = gmriData->fastStates[jj];
            if (jac->seedVars[j] == 1) {
              nth = spp->leadindex[j];
              while (nth < spp->leadindex[j+1]) {
                currentIndex = spp->index[nth];
                gmriData->Jf[j*rows + currentIndex] = jac->resultVars[currentIndex];
                nth++;
              }
            }
          }

          /* Reset seed vector */
          for (j=0; j < columns; j++) {
            jac->seedVars[j] = 0;
          }
        }
      }
    }
    else
    {
      warningStreamPrint(LOG_STDOUT, 0, "Numerical Jacobian is used");

      double delta_h = sqrt(solverData->epsfcn);
      double delta_hh;
      double xsave;

      memcpy(gmriData->f, fODE, n * sizeof(double));
      for(ii = 0; ii < nFastStates; ii++)
      {
        i = gmriData->fastStates[ii];
        delta_hh = fmax(delta_h * fmax(fabs(x[i]), fabs(gmriData->f[i])), delta_h);
        delta_hh = ((gmriData->f[i] >= 0) ? delta_hh : -delta_hh);
        delta_hh = x[i] + delta_hh - x[i];
        xsave = x[i];
        x[i] += delta_hh;
        delta_hh = 1. / delta_hh;

        wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);
        // this should not count on function evaluation, since
        // it belongs to jacobian evaluation
        gmriData->evalFunctionODE--;

        /* BB: Is this necessary for the statistics? */
        solverData->nfev++;

        for(j = 0; j < n; j++)
        {
          l = i * n + j;
          gmriData->Jf[l] = (fODE[j] - gmriData->f[j]) * delta_hh;
        }
        x[i] = xsave;
      }
    }

    /* profiling */
    rt_accumulate(SIM_TIMER_JACOBIAN);
  }
  return 0;
}


/**
 * @brief Residual function for non-linear system for diagonal implicit Runge-Kutta methods.
 *
 * TODO: Describe what the residual means.
 *
 * @param dataIn  Userdata provided to non-linear system solver.
 * @param xloc    Input vector for non-linear system.
 * @param res     Residuum vector for given input xloc.
 * @param iflag   Unused.
 */
void residual_DIRK_MR(void **dataIn, const double *xloc, double *res, const int *iflag)
{
  DATA *data = (DATA *)((void **)dataIn[0]);
  threadData_t *threadData = (threadData_t *)((void **)dataIn[1]);
  DATA_GMRI *gmriData = (DATA_GMRI *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gmriData->tableau->nStages;
  int stage_  = gmriData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii<gmriData->nFastStates;ii++) {
    i = gmriData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);

  // Evaluate residual
  for (ii=0; ii<gmriData->nFastStates; ii++) {
    i = gmriData->fastStates[ii];
    res[ii] = gmriData->res_const[i] - xloc[ii] + gmriData->stepSize * gmriData->tableau->A[stage_ * nStages + stage_] * fODE[i];
  }

  return;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gsriData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_DIRK_column_MR(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GMRI* gmriData = (DATA_GMRI*) data->simulationInfo->backupSolverData;

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gmriData->tableau->nStages;
  int stage = gmriData->act_stage;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  memcpy(jacobian_ODE->seedVars, jacobian->seedVars, sizeof(modelica_real)*jacobian->sizeCols);
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (i = 0; i < jacobian->sizeCols; i++) {
    jacobian->resultVars[i] = gmriData->stepSize * gmriData->tableau->A[stage * nStages + stage] * jacobian_ODE->resultVars[i];
    /* -1 on diagonal elements */
    if (jacobian->seedVars[i] == 1) {
      jacobian->resultVars[i] -= 1;
    }
  }

  return 0;
}

/*!	\fn wrapper_DIRK
 *      residual function res = yOld-y+gam*h*(k1+f(tOld+c2*h,y)); c2=2*gam;
 *      i.e. solve for:
 *           y1g = yOld+gam*h*(k1+f(tOld+c2*h,y1g)) = yOld+gam*h*(k1+k2)
 *      <=>  k2  = f(tOld+c2*h,yOld+gam*h*(k1+k2))
 *
 *  calculate function values or jacobian matrix for Newton-solver
 *  \param [in]      n_p            pointer to number of states
 *  \param [in]      x              pointer to unknowns (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  res            pointer to residual function (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  gmriData       data of the integrator (DATA_GMRI)
 *  \param [in]      fj             fj = 1 ==> calculate function values
 *                                  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_DIRK(int* n_p, double* x, double* res, void* gmriData_void, int fj)
{
  DATA_GMRI* gmriData = (DATA_GMRI*) gmriData_void;

  DATA* data = gmriData->data;
  threadData_t* threadData = gmriData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)gmriData->nlsSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;

  //printf("Dimensionen nFastStates = %d, n_nonlinear = %d\n", n, *n_p);

  int i, ii, j, jj, l, ll;
  int nStates = gmriData->nStates;
  int nFastStates = gmriData->nFastStates;
  int nStages = gmriData->tableau->nStages;
  int stage_   = gmriData->act_stage;

if (fj)
  {
    // fODE = f(tOld + c2*h,x); x ~ yOld + h*(ai1*k1+ai2*k2+...+aii*ki)
    // res_const = yOld + h*(ai1*k1+ai2*k2+...+ai{i-1}*k{i-1})
    // set correct time value and states of simulation system
    // the interpolated values are already stored in sData->realVars!!!!
    for (ii=0; ii<nFastStates;ii++) {
      i = gmriData->fastStates[ii];
      sData->realVars[i] = x[ii];
    }
    wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    for (ii=0; ii<nFastStates; ii++)
    {
      i = gmriData->fastStates[ii];
      res[ii] = gmriData->res_const[i] - x[ii] + gmriData->stepSize * gmriData->tableau->A[stage_ * nStages + stage_]  * fODE[i];
    }
  }
  else
  {
    /* Calculate Jacobian of the ODE system, result is in solverData->fjac */
    // set correct time value and states of simulation system
    // sData->timeValue = gmriData->time + gmriData->tableau->c[gmriData->act_stage]*gmriData->stepSize;
    // fODE correct?
    wrapper_Jf_genericRK_MR(gmriData->nStates, sData->timeValue, sData->realVars, fODE, gmriData);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    // jacobian          Jac = -E + gam*h*Jf(tk+c2*h,x))
    for(ii = 0; ii < nFastStates; ii++)
    {
      for(jj = 0; jj < nFastStates; jj++)
      {
        ll = ii * nFastStates + jj;
        i = gmriData->fastStates[ii];
        j = gmriData->fastStates[jj];
        l = i * gmriData->nStates + j;
        solverData->fjac[ll] = gmriData->stepSize * gmriData->tableau->A[stage_ * nStages + stage_] * gmriData->Jf[l];
        if (ii==jj) solverData->fjac[ll] -= 1;
      }
    }
  }
  return 0;
}

/*!	\fn expl_diag_impl_RK
 *
 *  function does one implicit ESDIRK2 step with the stepSize given in stepSize
 *  function omc_newton is used for solving nonlinear system
 *  results will be saved in y and the embedded result in yt
 *
 */
int expl_diag_impl_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;
  DATA_GMRI* gmriData = gsriData->gmriData;

  int i, ii;
  int stage, stage_;

  int nStates = data->modelData->nStates;
  int nFastStates = gmriData->nFastStates;
  int nStages = gmriData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // Is this necessary???
  gmriData->data = (void*) data;
  gmriData->threadData = threadData;

  // interpolate the slow states on the current time of gmriData->yOld for correct evaluation of gmriData->res_const
  linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                          gmriData->endTime,   gmriData->yEnd,
                          gmriData->time, gmriData->yOld, gmriData->nSlowStates, gmriData->slowStates);

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  sData->timeValue = gmriData->time;
  memcpy(sData->realVars, gmriData->yOld, nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);
  memcpy(gmriData->k, fODE, nStates*sizeof(double));

  for (stage = 0; stage < nStages; stage++)
  {
    gmriData->act_stage = stage;
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-i))
    // yOld from integrator is correct for the fast states

    for (i=0; i < nStates; i++)
    {
      gmriData->res_const[i] = gmriData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
        gmriData->res_const[i] += gmriData->stepSize * gmriData->tableau->A[stage * nStages + stage_] * gmriData->k[stage_ * nStates + i];
    }

    // set simulation time with respect to the current stage
    sData->timeValue = gmriData->time + gmriData->tableau->c[stage]*gmriData->stepSize;

    // index of diagonal element of A
    if (gmriData->tableau->A[stage * nStages + stage_] == 0)
    {
      if (stage>0) {
        memcpy(sData->realVars, gmriData->res_const, nStates*sizeof(double));
        wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);
      }
//      memcpy(gmriData->x + stage_ * nStates, gmriData->res_const, nStates*sizeof(double));
    }
    else
    {
      // interpolate the slow states on the time of the current stage
      linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                              gmriData->endTime,   gmriData->yEnd,
                              sData->timeValue, sData->realVars, gmriData->nSlowStates, gmriData->slowStates);

      // BB ToDo: set good starting values for the newton solver (solution of the last newton iteration!)
      // setting the start vector for the newton step
      // for (i=0; i<nFastStates; i++)
      //   solverData->x[i] = gmriData->yOld[gmriData->fastStates[i]];
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gmriData->nlsData;
      nlsData->size = gmriData->nFastStates;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      for (ii=0; ii<nFastStates; ii++) {
          i = gmriData->fastStates[ii];
          nlsData->nlsx[ii] = gmriData->yOld[i] + gmriData->tableau->c[stage_] * gmriData->stepSize * gmriData->k[i];
      }
      //memcpy(nlsData->nlsx, gmriData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      gsriData->multi_rate_phase = 1;
      solved = solveNLS(data, threadData, nlsData, -1);
      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "expl_diag_impl_RK: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(gmriData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  }

  for (ii=0; ii<nFastStates; ii++)
  {
    i = gmriData->fastStates[ii];
    // y   is the new approximation
    // yt  is the approximation of the embedded method for error estimation
    gmriData->y[i]  = gmriData->yOld[i];
    gmriData->yt[i] = gmriData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gmriData->y[i]  += gmriData->stepSize * gmriData->tableau->b[stage_]  * (gmriData->k + stage_ * nStates)[i];
      gmriData->yt[i] += gmriData->stepSize * gmriData->tableau->bt[stage_] * (gmriData->k + stage_ * nStates)[i];
    }
  }

  return 0;
}

/*! \fn genericRK_MR_step
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'genericRK'
 */
int genericRK_MR_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double targetTime)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;
  DATA_GMRI* gmriData = gsriData->gmriData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)gmriData->nlsSolverData;

  double err, eventTime;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;

  int i, ii, l;
  int integrator_step_info;
  int outerIntStepSynchronize = 0;

  int nStates = data->modelData->nStates;
  int nFastStates = gsriData->nFastStates;



  // This is the target time of the main integrator
  if (targetTime > gsriData->timeRight)
  {
    targetTime = gsriData->timeRight;
    outerIntStepSynchronize = 1;
  }

  // BB ToDo: needs to be performed also after an event!!!
  if (solverInfo->didEventStep || !gmriData->stepsDone)
  {
    gmriData->time = gsriData->time;
    gmriData->stepSize = gsriData->lastStepSize*0.5;
    // BB ToDO: Copy only fast states!!
    memcpy(gmriData->yOld, gsriData->yOld, sizeof(double)*gsriData->nStates);
    for (i=0; i<gmriData->nStates*gmriData->tableau->nStages; i++)
      gmriData->k[i] = 0;
    gmriData->didEventStep = TRUE;

  }
  gmriData->stepSize    = fmin(gmriData->stepSize, gsriData->timeRight - gmriData->time);
  gmriData->startTime   = gsriData->timeLeft;
  gmriData->endTime     = gsriData->timeRight;
  gmriData->yStart      = gsriData->yLeft;
  gmriData->yEnd        = gsriData->y;
  gmriData->fastStates  = gsriData->fastStates;
  gmriData->slowStates  = gsriData->slowStates;
  gmriData->nFastStates = gsriData->nFastStates;
  gmriData->nSlowStates = gsriData->nSlowStates;

  // print informations on the calling details
  infoStreamPrint(LOG_SOLVER, 1, "generic Runge-Kutta method (fast states):");
  infoStreamPrint(LOG_SOLVER, 0, "interpolation is done between %10g to %10g (outer simulation time %10g)",
                  gsriData->timeLeft, gsriData->timeRight, gsriData->time);

  while (gmriData->time < targetTime)
  {
    do
    {
      // calculate one step of the integrator
      integrator_step_info = gmriData->step_fun(data, threadData, solverInfo);

            // error handling: try half of the step size!
      if (integrator_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "genericRK_step: Failed to calculate step at time = %5g.", gmriData->time);
        errorStreamPrint(LOG_STDOUT, 0, "Try half of the step size!");
        gmriData->stepSize = gmriData->stepSize/2.;
        continue;
        //return -1;
      }

      for (i=0; i<nFastStates; i++)
      {
        ii = gmriData->fastStates[i];
        // calculate corresponding values for the error estimator and step size control
        gmriData->errtol[ii] = Rtol*fmax(fabs(gmriData->y[ii]),fabs(gmriData->yt[ii])) + Atol;
        gmriData->errest[ii] = fabs(gmriData->y[ii] - gmriData->yt[ii]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i < nFastStates; i++)
      {
        ii = gmriData->fastStates[i];
        gmriData->err[ii] = gmriData->errest[ii]/gmriData->errtol[ii];
        err = fmax(err, gmriData->err[ii]);
      }

      gmriData->errValues[0] = gmriData->tableau->fac * err;
      gmriData->stepSizeValues[0] = gmriData->stepSize;

      // Store performed stepSize for adjusting the time in case of latter interpolation
      gmriData->lastStepSize = gmriData->stepSize;

      // Call the step size control
      gmriData->stepSize *= gmriData->stepSize_control(gmriData->errValues, gmriData->stepSizeValues, gmriData->tableau->error_order);

      // Re-do step, if error is larger than requested
      if (err>1)
      {
        gmriData->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gmriData->time, gmriData->time + gmriData->lastStepSize, err, gmriData->stepSize);
      }
    } while  (err>1);

    // Count succesful integration steps
    gmriData->stepsDone += 1;

    // Rotate ring buffer
    for (i=0; i<(gmriData->ringBufferSize-1); i++) {
      gmriData->errValues[i+1] = gmriData->errValues[i];
      gmriData->stepSizeValues[i+1] = gmriData->stepSizeValues[i];
    }


    // interpolate the slow states to the boundaries of current integration interval, this is used for event detection
    linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                            gmriData->endTime,   gmriData->yEnd,
                            gmriData->time, gmriData->yOld, gmriData->nSlowStates, gmriData->slowStates);
    linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                            gmriData->endTime,   gmriData->yEnd,
                            gmriData->time + gmriData->lastStepSize, gmriData->y, gmriData->nSlowStates, gmriData->slowStates);
    eventTime = checkForEvents(data, threadData, solverInfo, gmriData->time, gmriData->yOld, gmriData->time + gmriData->lastStepSize, gmriData->y);
    if (eventTime > 0)
    {
      // sData->realVars are the "numerical" values on the right hand side of the event
      memcpy(gsriData->yOld, sData->realVars, gmriData->nStates * sizeof(double));
      memcpy(gmriData->yOld, sData->realVars, gmriData->nStates * sizeof(double));

      gmriData->time = eventTime;
      gsriData->time = eventTime;

      solverInfo->currentTime = eventTime;
      sData->timeValue = solverInfo->currentTime;

      if(ACTIVE_STREAM(LOG_SOLVER))
      {
        messageClose(LOG_SOLVER);
      }
      // Get out of the integration routine for event handling
      return 1;
    }

    /* update time with performed stepSize */
    gmriData->time += gmriData->lastStepSize;

    /* step is accepted and yOld needs to be updated, store yOld for later interpolation... */
    copyVector_genericRK_MR(gmriData->yt, gmriData->yOld, nFastStates, gmriData->fastStates);

    /* step is accepted and yOld needs to be updated */
    copyVector_genericRK_MR(gmriData->yOld, gmriData->y, nFastStates, gmriData->fastStates);
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gmriData->time- gmriData->lastStepSize, gmriData->time, err, gmriData->stepSize);

    // Dont disturb the inner step size control!!
    if (gmriData->time + gmriData->stepSize > gsriData->timeRight)
      break;
  }

  // restore the last predicted step size, only necessary if last step size has been reduced to reach the target time
  // gmriData->stepSize = gmriData->stepSize_old;

  // copy error and values of the fast states to the outer integrator routine if outer integration time is reached
  gsriData->err_fast = gmriData->errValues[0];
  if (outerIntStepSynchronize)
  {
    memcpy(gsriData->yOld, gmriData->y, gmriData->nStates * sizeof(double));
    memcpy(gsriData->y, gmriData->y, gmriData->nStates * sizeof(double));

    gsriData->lastStepSize = gmriData->time - gsriData->timeLeft;
    gsriData->timeRight = gmriData->time;
    if (gsriData->time > gsriData->timeLeft)
      gsriData->time = gmriData->time;
    else
      gsriData->time = gsriData->timeLeft;

    // solverInfo->currentTime = eventTime;
    // sData->timeValue = solverInfo->currentTime;
    copyVector_genericRK_MR(gsriData->err, gmriData->err, nFastStates, gmriData->fastStates);
    // copyVector_genericRK_MR(gsriData->y, gmriData->y, nFastStates, gmriData->fastStates);
    // copyVector_genericRK_MR(gsriData->yOld, gmriData->y, nFastStates, gmriData->fastStates);
  }

  if(ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "genericRKmr call statistics: ");
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", gmriData->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", gmriData->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", gmriData->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", gmriData->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", gmriData->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", gmriData->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", gmriData->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = gmriData->stepsDone;
  solverInfo->solverStatsTmp[1] = gmriData->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = gmriData->evalJacobians;
  solverInfo->solverStatsTmp[3] = gmriData->errorTestFailures;
  solverInfo->solverStatsTmp[4] = gmriData->convergenceFailures;

  infoStreamPrint(LOG_SOLVER, 0, "Finished genericRKmr step.");
  messageClose(LOG_SOLVER);

  return 0;
}

//Interpolation only some entries (indices given by idx[nIdx])
void linear_interpolation_MR(double ta, double* fa, double tb, double* fb, double t, double* f, int nIdx, int* idx)
{
  double lambda, h0, h1;
  int ii;

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  for (int i=0; i<nIdx; i++)
  {
    ii = idx[i];
    f[ii] = h0*fa[ii] + h1*fb[ii];
  }
}

void printVector_genericRK_MR(char name[], double* a, int n, double time, int nIndx, int* indx)
{
  printf("%s at time: %g: ", name, time);
  for (int i=0;i<nIndx;i++)
    printf("%6g ", a[indx[i]]);
  printf("\n");
}

void printMatrix_genericRK_MR(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n ", name, time);
  for (int i=0;i<n;i++)
  {
    for (int j=0;j<n;j++)
      printf("%6g ", a[i*n + j]);
    printf("\n");
  }
  printf("\n");
}
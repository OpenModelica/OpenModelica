/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2016, Open Source Modelica Consortium (OSMC),
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

/*! \file ida_solver.c
 */

#ifdef USE_PARJAC
  #include <omp.h>
  #define GC_THREADS
  #include <gc/omc_gc.h>
#endif

#include <string.h>
#include <setjmp.h>

#include "omc_config.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "simulation_data.h"

#include "gc/omc_gc.h"
#include "util/context.h"
#include "util/omc_error.h"
#include "util/parallel_helper.h"

#include "ida_solver.h"

#include "sundials_error.h"
#include "sundials_util.h"

#include "arrayIndex.h"
#include "dae_mode.h"
#include "dassl.h"
#include "epsilon.h"
#include "external_input.h"
#include "jacobianSymbolical.h"
#include "simulation/jacobian_util.h"
#include "model_help.h"
#include "omc_math.h"
#include "simulation/options.h"
#include "simulation/results/simulation_result.h"
#include "simulation/simulation_runtime.h"
#include "solver_main.h"

#ifdef WITH_SUNDIALS


/* Extern function prototypes */
int IDADlsSetDenseJacFn(void* ida_mem, void*);

/* Private function prototypes */
static int callDenseJacobian(realtype tt, realtype cj, N_Vector yy,
                             N_Vector yp, N_Vector rr, SUNMatrix Jac,
                             void *user_data, N_Vector tmp1, N_Vector tmp2,
                             N_Vector tmp3);

static int callSparseJacobian(realtype currentTime, realtype cj,
                              N_Vector yy, N_Vector yp, N_Vector rr, SUNMatrix Jac, void *user_data,
                              N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);

static int residualFunctionIDA(double time, N_Vector yy, N_Vector yp, N_Vector res, void* user_data);
static int rootsFunctionIDA(double time, N_Vector yy, N_Vector yp, double *gout, void* userData);

static int getScalingFactors(DATA* data, IDA_SOLVER *idaData, SUNMatrix scaleMatrix);

static void idaScaleData(IDA_SOLVER *idaData);
static void idaReScaleData(IDA_SOLVER *idaData);
static void idaScaleVector(N_Vector vec, double* factors, unsigned int size);
static void idaReScaleVector(N_Vector vec, double* factors, unsigned int size);

int ida_event_update(DATA* data, threadData_t *threadData);

/* Static variables */
/* TODO: Don't use global variables */
static IDA_SOLVER *idaDataGlobal;


/**
 * @brief Return true if flag signals success.
 *
 * If flag is IDA_SUCCESS or IDA_TSTOP_RETURN return true.
 * Warnings (IDA_WARNING) or encountering roots (IDA_ROOT_RETURN) doesn't count as success.
 *
 * @param flag                Value of IDA/IDAS flag.
 * @return modelica_boolean   Return true if flag signals success, otherwise return false.
 */
modelica_boolean IDAflagIsSuccess(int flag) {
  switch (flag)
  {
  case IDA_SUCCESS:
  case IDA_TSTOP_RETURN:
  case IDA_ROOT_RETURN:
    return TRUE;
  default:
    return FALSE;
  }
}


/**
 * @brief Initialize main IDA data.
 *
 * Allocate memory for IDA_SOLVER struct and initialize IDA solver.
 *
 * @param data        Runtime data struct.
 * @param threadData  Thread data for error handling
 * @param solverInfo  Information about main solver. Unused at the moment.
 * @param idaData     IDA solver data.
 * @return int        Returns 0 on success, aborts with throw on failure.
 */
int ida_solver_initial(DATA* data, threadData_t *threadData,
                       SOLVER_INFO* solverInfo, IDA_SOLVER* idaData)
{
  /* Variables */
  int flag;
  long int i;
  double* tmp;
  int maxOrder;

  /* Initialize constants */
  idaData->setInitialSolution = FALSE;

  /* Instantiate IDA solver object */
  idaData->ida_mem = IDACreate();
  if (idaData->ida_mem == NULL) {
    throwStreamPrint(threadData, "##IDA## Initialization of IDA solver failed!");
  }

  idaData->residualFunction = residualFunctionIDA;

  /* Start measuring time */    /* TODO: Why start here? */
  if (measure_time_flag) {
    rt_tick(SIM_TIMER_SOLVER);
  }

  /* change parameter for DAE mode */
  if (compiledInDAEMode) {
    idaData->daeMode = TRUE;
    idaData->N = (long int) data->modelData->nStates + data->simulationInfo->daeModeData->nAlgebraicDAEVars;
  }
  else {
    idaData->daeMode = FALSE;
    idaData->N = (long int) data->modelData->nStates;
  }
  infoStreamPrint(OMC_LOG_SOLVER, 1, "## IDA ## Initializing solver of size %ld %s.", idaData->N, idaData->daeMode?"in DAE mode":"");
  idaData->NNZ = -1;

  /* initialize states and der(states) */
  if (idaData->daeMode)
  {
    idaData->states = (double*) malloc(idaData->N*sizeof(double));
    idaData->statesDer = (double*) calloc(idaData->N,sizeof(double));

    memcpy(idaData->states, data->localData[0]->realVars, sizeof(double)*data->modelData->nStates);
    // and  also algebraic vars
    getAlgebraicDAEVars(data, idaData->states + data->modelData->nStates);
    memcpy(idaData->statesDer, data->localData[0]->realVars + data->modelData->nStates, sizeof(double)*data->modelData->nStates);

    idaData->y = N_VMake_Serial(idaData->N, idaData->states);
    idaData->yp = N_VMake_Serial(idaData->N, idaData->statesDer);
  }
  else {
    idaData->states = NULL;
    idaData->statesDer = NULL;
    idaData->y = N_VMake_Serial(idaData->N, data->localData[0]->realVars);
    idaData->yp = N_VMake_Serial(idaData->N, data->localData[0]->realVars + data->modelData->nStates);
  }

  flag = IDAInit(idaData->ida_mem, idaData->residualFunction,
                 data->simulationInfo->startTime, idaData->y, idaData->yp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAInit");

  /* Allocate memory for jacobians calculation */
  idaData->ysave = (double*) malloc(idaData->N*sizeof(double));
  idaData->ypsave = (double*) malloc(idaData->N*sizeof(double));
  idaData->delta_hh = (double*) malloc(idaData->N*sizeof(double));
  idaData->errwgt = N_VNew_Serial(idaData->N);
  idaData->newdelta = N_VNew_Serial(idaData->N);

  /* Allocate memory for linear solver */
  idaData->y_linSol = N_VNew_Serial(idaData->N);

  /* Set user data */
  idaData->userData = (IDA_USERDATA*) malloc(sizeof(IDA_USERDATA));
  idaData->userData->data = data;
  idaData->userData->threadData = threadData;
  flag = IDASetUserData(idaData->ida_mem, idaData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetUserData");

  /* Set error handler */
  flag = IDASetErrHandlerFn(idaData->ida_mem, idaErrorHandlerFunction, idaData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetErrHandlerFn");

  /* Set nominal values of the states for absolute tolerances */
  infoStreamPrint(OMC_LOG_SOLVER, 1, "The relative tolerance is %g. Following absolute tolerances are used for the states: ", data->simulationInfo->tolerance);

  /* Allocate memory for initialization process */
  tmp = (double*) malloc(idaData->N*sizeof(double));
  for(i=0; i < data->modelData->nStates; ++i) {
    const modelica_real nominal = getNominalFromScalarIdx(data->simulationInfo, data->modelData, i);
    tmp[i] = fmax(fabs(nominal), 1e-32);   /* TODO: Use some macro for 1e-32?? */
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, "%ld. %s -> %g", i+1, data->modelData->realVarsData[i].info.name, tmp[i]);
  }

  /* daeMode: set nominal values for algebraic variables */
  if (idaData->daeMode) {
    getAlgebraicDAEVarNominals(data, tmp + data->modelData->nStates);
  }
  /* multiply by tolerance to obtain a relative tolerace */
  for(i=0; i < idaData->N; ++i) {
    tmp[i] *= data->simulationInfo->tolerance;
  }
  messageClose(OMC_LOG_SOLVER);
  flag = IDASVtolerances(idaData->ida_mem, data->simulationInfo->tolerance,
                         N_VMake_Serial(idaData->N, tmp));
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASVtolerances");


  if (omc_flag[FLAG_IDA_SCALING]) { /* idaNoScaling */
    /* allocate memory for scaling */
    idaData->yScale   = (double*) malloc(idaData->N*sizeof(double));
    idaData->ypScale  = (double*) malloc(idaData->N*sizeof(double));
    idaData->resScale = (double*) malloc(idaData->N*sizeof(double));

    /* set yScale from nominal values */
    for(i=0; i < data->modelData->nStates; ++i) {
      const modelica_real nominal = getNominalFromScalarIdx(data->simulationInfo, data->modelData, i);
      idaData->yScale[i] = fabs(nominal);
      idaData->ypScale[i] = 1.0; // TODO: 1 is not a good scaling value. Use something like nominal value / number of intervals
    }
    /* daeMode: set nominal values for algebraic variables */
    if (idaData->daeMode) {
      getAlgebraicDAEVarNominals(data, idaData->yScale + data->modelData->nStates);
      for (i=data->modelData->nStates; i < idaData->N; ++i) {
        idaData->ypScale[i] = 1.0;
      }
    }
    infoStreamPrint(OMC_LOG_SOLVER_V, 1, "The scale factors for all ida states: ");
    for (i=0; i < idaData->N; ++i) {
      infoStreamPrint(OMC_LOG_SOLVER_V, 0, "%ld. scaleFactor: %g", i+1, idaData->yScale[i]);
    }
    messageClose(OMC_LOG_SOLVER_V);
  } else {
    idaData->yScale   = NULL;
    idaData->ypScale  = NULL;
    idaData->resScale = NULL;
  }
  /* initialize */
  idaData->useScaling = TRUE;

  /* Set root functions unless flag FLAG_NO_ROOTFINDING is set */
  if (!omc_flag[FLAG_NO_ROOTFINDING]) {
    solverInfo->solverRootFinding = 1;
    flag = IDARootInit(idaData->ida_mem, data->modelData->nZeroCrossings, rootsFunctionIDA);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDARootInit");
  }
  else {
    solverInfo->solverRootFinding = 0;
  }
  infoStreamPrint(OMC_LOG_SOLVER, 0, "IDA uses internal root finding method %s", solverInfo->solverRootFinding?"YES":"NO");

  /* Define maximum integration order of IDA */
  if (omc_flag[FLAG_MAX_ORDER]) {
    maxOrder = atoi(omc_flagValue[FLAG_MAX_ORDER]);

    flag = IDASetMaxOrd(idaData->ida_mem, maxOrder);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetMaxOrd");
  } else {
    maxOrder = 5; /* Default max order for IDA */
  }
  infoStreamPrint(OMC_LOG_SOLVER, 0, "Maximum integration order %d", maxOrder);

  /* if FLAG_NOEQUIDISTANT_GRID is set, choose ida step method */
  if (omc_flag[FLAG_NOEQUIDISTANT_GRID]) {
    idaData->internalSteps = 1; /* TRUE */
    solverInfo->solverNoEquidistantGrid = TRUE;
  } else {
    idaData->internalSteps = 0; /* FALSE */
  }
  infoStreamPrint(OMC_LOG_SOLVER, 0, "use equidistant time grid %s", idaData->internalSteps?"NO":"YES");

  /* check if Flags FLAG_NOEQUIDISTANT_OUT_FREQ or FLAG_NOEQUIDISTANT_OUT_TIME are set */
  if (idaData->internalSteps) {
    if (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ]) {
      idaData->stepsFreq = atoi(omc_flagValue[FLAG_NOEQUIDISTANT_OUT_FREQ]);
    } else if (omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME]) {
      idaData->stepsTime = atof(omc_flagValue[FLAG_NOEQUIDISTANT_OUT_TIME]);
      flag = IDASetMaxStep(idaData->ida_mem, idaData->stepsTime);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetMaxStep");
      infoStreamPrint(OMC_LOG_SOLVER, 0, "maximum step size %g", idaData->stepsTime);
    } else {
      idaData->stepsFreq = 1;
      idaData->stepsTime = 0.0;
    }

    if (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ] && omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME]) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "The flags are  \"noEquidistantOutputFrequency\" "
                                     "and \"noEquidistantOutputTime\" are in opposition "
                                     "to each other. The flag \"noEquidistantOutputFrequency\" superiors.");
     }
     infoStreamPrint(OMC_LOG_SOLVER, 0, "as the output frequency control is used: %d", idaData->stepsFreq);
     infoStreamPrint(OMC_LOG_SOLVER, 0, "as the output frequency time step control is used: %f", idaData->stepsTime);
  }

  /* if FLAG_IDA_LS is set, choose ida linear solver method */
  if (omc_flag[FLAG_IDA_LS]) {
    for (i=1; i< IDA_LS_MAX; i++) {
      if (!strcmp((const char*)omc_flagValue[FLAG_IDA_LS], IDA_LS_METHOD_NAME[i])) {
        idaData->linearSolverMethod = (enum IDA_LS)i;
        break;
      }
    }
    if (idaData->linearSolverMethod == IDA_LS_UNKNOWN) {
      if (OMC_ACTIVE_WARNING_STREAM(OMC_LOG_SOLVER)) {
        warningStreamPrint(OMC_LOG_SOLVER, 1, "unrecognized ida linear solver method %s, current options are:", (const char*)omc_flagValue[FLAG_IDA_LS]);
        for(i=1; i < IDA_LS_MAX; ++i) {
          warningStreamPrint(OMC_LOG_SOLVER, 0, "%-15s [%s]", IDA_LS_METHOD_NAME[i], IDA_LS_METHOD_DESC[i]);
        }
        messageCloseWarning(OMC_LOG_SOLVER);
      }
      throwStreamPrint(threadData,"unrecognized ida linear solver method %s", (const char*)omc_flagValue[FLAG_IDA_LS]);
    }
  } else {
    idaData->linearSolverMethod = IDA_LS_KLU;
  }

  JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  data->callback->initialAnalyticJacobianA(data, threadData, jacobian);
  if(jacobian->availability == JACOBIAN_AVAILABLE || jacobian->availability == JACOBIAN_ONLY_SPARSITY) {
    infoStreamPrint(OMC_LOG_SIMULATION, 1, "Initialized Jacobian:");
    infoStreamPrint(OMC_LOG_SIMULATION, 0, "columns: %zu rows: %zu", jacobian->sizeCols, jacobian->sizeRows);
    infoStreamPrint(OMC_LOG_SIMULATION, 0, "NNZ:  %u colors: %u", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
    messageClose(OMC_LOG_SIMULATION);
  }

  // Compare user flag to availabe Jacobian methods
  const char* flagValue;
  if(omc_flag[FLAG_JACOBIAN]){
    flagValue = omc_flagValue[FLAG_JACOBIAN];
  } else {
    flagValue = NULL;
  }
  idaData->jacobianMethod = setJacobianMethod(threadData, jacobian->availability, flagValue);

  // change IDA specific jacobian method
  if(idaData->jacobianMethod == SYMJAC) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Symbolic Jacobians without coloring are currently not supported by IDA."
                                      " Colored symbolical Jacobian will be used.");
    idaData->jacobianMethod = COLOREDSYMJAC;
  }else if(idaData->jacobianMethod == NUMJAC) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Numerical Jacobians without coloring are currently not supported by IDA."
                                      " Colored numerical Jacobian will be used.");
    idaData->jacobianMethod = COLOREDNUMJAC;
  }else if(idaData->jacobianMethod == INTERNALNUMJAC && idaData->linearSolverMethod == IDA_LS_KLU) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Internal Numerical Jacobians without coloring are currently not supported by IDA with KLU."
                                      " Colored numerical Jacobian will be used.");
    idaData->jacobianMethod = COLOREDNUMJAC;
  }

  /* Set NNZ */
  if (idaData->daeMode) {
    idaData->NNZ = data->simulationInfo->daeModeData->sparsePattern->numberOfNonZeros;
  } else {
    idaData->NNZ = data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern->numberOfNonZeros;
  }

  switch (idaData->linearSolverMethod){
  case IDA_LS_SPGMR:
    idaData->J = NULL;
    idaData->linSol = SUNLinSol_SPGMR(idaData->y_linSol, PREC_NONE, idaData->N);
    if (idaData->linSol == NULL) {
      throwStreamPrint(threadData, "##IDA## In function SUNLinSol_SPGMR: Input incompatible.");
    }
    idaData->jacobianMethod = INTERNALNUMJAC;
    break;
  case IDA_LS_SPBCG:
    idaData->J = NULL;
    idaData->linSol = SUNLinSol_SPBCGS(idaData->y_linSol, PREC_NONE, idaData->N);
    if (idaData->linSol == NULL) {
      throwStreamPrint(threadData, "##IDA## In function SUNLinSol_SPBCGS: Input incompatible.");
    }
    idaData->jacobianMethod = INTERNALNUMJAC;
    break;
  case IDA_LS_SPTFQMR:
    idaData->J = NULL;
    idaData->linSol = SUNLinSol_SPTFQMR(idaData->y_linSol, PREC_NONE, idaData->N);
    if (idaData->linSol == NULL) {
      throwStreamPrint(threadData, "##IDA## In function SUNLinSol_SPTFQMR: Input incompatible.");
    }
    idaData->jacobianMethod = INTERNALNUMJAC;
    break;
  case IDA_LS_DENSE:
    idaData->J = SUNDenseMatrix(idaData->N, idaData->N);
    idaData->linSol = SUNLinSol_Dense(idaData->y_linSol, idaData->J);
    if (idaData->linSol == NULL) {
      throwStreamPrint(threadData, "##IDA## In function SUNLinSol_Dense: Input incompatible.");
    }
    break;
  case IDA_LS_KLU:
    /* Set KLU after initialized sparse pattern of the jacobian for nnz */
    if (idaData->NNZ < 0) {
      throwStreamPrint(threadData, "##IDA## idaData->NNZ not set.");
    }
    idaData->J = SUNSparseMatrix(idaData->N, idaData->N, idaData->NNZ + idaData->N, CSC_MAT);
    idaData->linSol = SUNLinSol_KLU(idaData->y_linSol, idaData->J);
    if (idaData->linSol == NULL) {
      throwStreamPrint(threadData, "##IDA## In function SUNLinSol_KLU: Input incompatible.");
    }
    break;
  default:
    throwStreamPrint(threadData,"unrecognized linear solver method %s", (const char*)omc_flagValue[FLAG_IDA_LS]);
    break;
  }

  flag = IDASetLinearSolver(idaData->ida_mem, idaData->linSol, idaData->J);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDALS_FLAG, "IDASetLinearSolver");
  infoStreamPrint(OMC_LOG_SOLVER, 0, "IDA linear solver method selected %s", IDA_LS_METHOD_DESC[idaData->linearSolverMethod]);

  /* Set Jacobian function */
  /* Use sparse jacobian evaluation */
  if (idaData->linearSolverMethod == IDA_LS_KLU) {
    idaData->allocatedParMem = 0;   /* FALSE */

    /* Set Jacobian function for matrix based linear solvers */
    switch (idaData->jacobianMethod){
    case SYMJAC:
    case NUMJAC:
    case COLOREDSYMJAC:
    case COLOREDNUMJAC:
      flag = IDASetJacFn(idaData->ida_mem, callSparseJacobian);

      checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDALS_FLAG, "IDASetJacFn");
#ifdef USE_PARJAC
      allocateThreadLocalJacobians(data, &(idaData->jacColumns));
      idaData->allocatedParMem = 1;   /* TRUE */
      if (omc_flag[FLAG_IDA_SCALING]) {
        idaData->scaleMatrix = SUNSparseMatrix(idaData->N, idaData->N, idaData->NNZ + idaData->N, CSC_MAT);
      } else {
        idaData->scaleMatrix = NULL;
      }
#endif
      break;
    default:
      throwStreamPrint(threadData,"For the klu solver jacobian calculation method has to be %s or %s", JACOBIAN_METHOD_NAME[COLOREDSYMJAC], JACOBIAN_METHOD_NAME[COLOREDNUMJAC]);
      break;
    }
  /* Use dense jacobian evaluation */
  } else {
    switch (idaData->jacobianMethod){
    case SYMJAC:
    case NUMJAC:
    case COLOREDSYMJAC:
    case COLOREDNUMJAC:
      flag = IDASetJacFn(idaData->ida_mem, callDenseJacobian);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDALS_FLAG, "IDASetJacFn");
#ifdef USE_PARJAC
      allocateThreadLocalJacobians(data, &(idaData->jacColumns));
      idaData->allocatedParMem = 1;   /* TRUE */
#endif
      break;
    case INTERNALNUMJAC:
      /* TODO: Set a preconditioner if possible */
      break;
    default:
      throwStreamPrint(threadData,"unrecognized jacobian calculation method %s", (const char*)omc_flagValue[FLAG_JACOBIAN]);
      break;
    }
  }
  infoStreamPrint(OMC_LOG_SOLVER, 0, "Jacobian is calculated by \"%s\"", JACOBIAN_METHOD_DESC[idaData->jacobianMethod]);

  /* Set max error test fails */
  if (omc_flag[FLAG_IDA_MAXERRORTESTFAIL])
  {
    int maxErrorTestFails = atoi(omc_flagValue[FLAG_IDA_MAXERRORTESTFAIL]);
    flag = IDASetMaxErrTestFails(idaData->ida_mem, maxErrorTestFails);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetMaxErrTestFails");
  }

  /* set maximum number of nonlinear solver iterations at one step */
  if (omc_flag[FLAG_IDA_MAXNONLINITERS])
  {
    int maxNonlinIters = atoi(omc_flagValue[FLAG_IDA_MAXNONLINITERS]);
    flag = IDASetMaxNonlinIters(idaData->ida_mem, maxNonlinIters);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetMaxNonlinIters");
  }

  /* maximum number of nonlinear solver convergence failures at one step */
  if (omc_flag[FLAG_IDA_MAXCONVFAILS])
  {
    int maxConvFails = atoi(omc_flagValue[FLAG_IDA_MAXCONVFAILS]);
    flag = IDASetMaxConvFails(idaData->ida_mem, maxConvFails);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetMaxConvFails");
  }

  /* safety factor in the nonlinear convergence test */
  if (omc_flag[FLAG_IDA_NONLINCONVCOEF])
  {
    double nonlinConvCoef = atof(omc_flagValue[FLAG_IDA_NONLINCONVCOEF]);
    flag = IDASetNonlinConvCoef(idaData->ida_mem, nonlinConvCoef);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetNonlinConvCoef");
  }

  /* configure algebraic variables as such */
  if (idaData->daeMode) {
    if (omc_flag[FLAG_NO_SUPPRESS_ALG]) {
      flag = IDASetSuppressAlg(idaData->ida_mem, 1 /* TRUE */);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetSuppressAlg");
    }
    for (i=0; i<idaData->N; ++i) {
      tmp[i] = (i<data->modelData->nStates)? 1.0: 0.0;
    }

    flag = IDASetId(idaData->ida_mem, N_VMake_Serial(idaData->N,tmp));
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetId");
  }

  /* define initial step size */
  if (omc_flag[FLAG_INITIAL_STEP_SIZE]) {
    double initialStepSize = atof(omc_flagValue[FLAG_INITIAL_STEP_SIZE]);

    assertStreamPrint(threadData, initialStepSize >= DASSL_STEP_EPS, "Selected initial step size %e is too small.", initialStepSize);

    flag = IDASetInitStep(idaData->ida_mem, initialStepSize);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetInitStep");
    infoStreamPrint(OMC_LOG_SOLVER, 0, "initial step size: %g", initialStepSize);
  } else {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "initial step size is set automatically.");
  }

  /* Initialize sensitivities analysis */
  idaData->idaSmode = omc_flag[FLAG_IDAS] ? 1 : 0;

  if (idaData->idaSmode) {
    idaData->Ns = data->modelData->nSensitivityParamVars;
    idaData->yS = N_VCloneVectorArray_Serial(idaData->Ns, idaData->y);
    idaData->ySp = N_VCloneVectorArray_Serial(idaData->Ns, idaData->yp);

    for (i=0; i<idaData->Ns; ++i) {
      N_VConst_Serial(0.0, idaData->yS[i]);
      N_VConst_Serial(0.0, idaData->ySp[i]);
    }

    flag = IDASensInit(idaData->ida_mem, idaData->Ns, IDA_SIMULTANEOUS, NULL, idaData->yS, idaData->ySp);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASensInit");

    flag = IDASetSensParams(idaData->ida_mem, data->simulationInfo->realParameter, NULL, data->simulationInfo->sensitivityParList);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetSensParams");
    flag = IDASetSensDQMethod(idaData->ida_mem, IDA_FORWARD, 0);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetSensDQMethod");

    flag = IDASensEEtolerances(idaData->ida_mem);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASensEEtolerances");
/*
    flag = IDASetSensErrCon(idaData->ida_mem, TRUE);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetSensErrCon");
*/
    /* allocate result workspace */
    idaData->ySResult = N_VCloneVectorArrayEmpty_Serial(idaData->Ns, idaData->y);
    for(i = 0; i < idaData->Ns; ++i)
    {
      N_VSetArrayPointer_Serial((data->simulationInfo->sensitivityMatrix + i*idaData->N), idaData->ySResult[i]);
    }
  }
  if (compiledInDAEMode){
    idaDataGlobal = idaData;
    data->callback->functionDAE = ida_event_update;
  }
  messageClose(OMC_LOG_SOLVER);

  if (measure_time_flag) rt_clear(SIM_TIMER_SOLVER); /* TODO Initialization should not add to this timer... */

  free(tmp);
  return 0;
}

/**
 * @brief Deinitialize IDA data.
 *
 * @param idaData   Pointer to IDA solver data struct.
 */
void ida_solver_deinitial(IDA_SOLVER *idaData)
{
  if (omc_flag[FLAG_IDA_SCALING]) {
    /* free scaling data */
    free(idaData->yScale);
    free(idaData->ypScale);
    free(idaData->resScale);
    SUNMatDestroy(idaData->scaleMatrix);
  }

  /* free work arrays */
  free(idaData->userData);
  free(idaData->ysave);
  free(idaData->ypsave);
  free(idaData->delta_hh);

  /* Free linear solver data */
  N_VDestroy_Serial(idaData->y_linSol);
  SUNMatDestroy(idaData->J);
  SUNLinSolFree(idaData->linSol);

  /* Free dae-mode data */
  if (idaData->daeMode) {
    free(idaData->states);
    free(idaData->statesDer);
  }

  /* Free sensitivity-mode data */
  if (idaData->idaSmode) {
    N_VDestroyVectorArray_Serial(idaData->yS, idaData->Ns);
    N_VDestroyVectorArray_Serial(idaData->ySp, idaData->Ns);
    N_VDestroyVectorArray_Serial(idaData->ySResult, idaData->Ns);
  }

  N_VDestroy_Serial(idaData->errwgt);
  N_VDestroy_Serial(idaData->newdelta);

#ifdef USE_PARJAC
  if (idaData->allocatedParMem) {
      freeAnalyticalJacobian(&(idaData->jacColumns));
      idaData->allocatedParMem = 0;
  }
#endif

  IDAFree(&idaData->ida_mem);
}


/**
 * @brief EventHandle for DAE mode.
 *
 * Handles events by reinitialize main IDA solver, initializing next step and
 * evaluate DAE residual equations.
 *
 * @param data        Runtime data struct.
 * @param threadData  Thread data for error handling.
 * @return int        Return 0.
 */
int ida_event_update(DATA* data, threadData_t *threadData)
{
  IDA_SOLVER *idaData = idaDataGlobal;
  int flag;
  long nonLinIters;
  double init_h;

  if (!compiledInDAEMode){
    throwStreamPrint(threadData, "Function ida_event_update only callable in DAE mode");
  }

  data->simulationInfo->needToIterate = 0 /* FALSE */;

  memcpy(idaData->states, data->localData[0]->realVars, sizeof(double)*data->modelData->nStates);
  getAlgebraicDAEVars(data, idaData->states + data->modelData->nStates);
  memcpy(idaData->statesDer, data->localData[0]->realVars + data->modelData->nStates, sizeof(double)*data->modelData->nStates);

  /* update inner algebraic get new values from data */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  evaluateDAEResiduals_wrapperEventUpdate(data, threadData);
  getAlgebraicDAEVars(data, idaData->states + data->modelData->nStates);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## do event update at %.15g", data->localData[0]->timeValue);
  memcpy(idaData->states, data->localData[0]->realVars, sizeof(double)*data->modelData->nStates);
  memcpy(idaData->statesDer, data->localData[0]->realVars + data->modelData->nStates, sizeof(double)*data->modelData->nStates);
  memcpy(NV_DATA_S(idaData->y), idaData->states, idaData->N);
  memcpy(NV_DATA_S(idaData->yp), idaData->statesDer, idaData->N);
  flag = IDAReInit(idaData->ida_mem,
                    data->localData[0]->timeValue,
                    idaData->y,
                    idaData->yp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAReInit");

  /* get initial step to provide a direction of the solution */
  flag = IDAGetActualInitStep(idaData->ida_mem, &init_h);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAGetActualInitStep");
  /* provide a feasible step-size if it's too small */
  if (init_h < DBL_EPSILON){
    init_h = DBL_EPSILON;
    flag = IDASetInitStep(idaData->ida_mem, init_h);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetInitStep");
    infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## corrected step-size at %.15g", init_h);
  }

  /* increase limits of the non-linear solver */
  IDASetMaxNumStepsIC(idaData->ida_mem, 2*idaData->N*10);
  IDASetMaxNumJacsIC(idaData->ida_mem, 2*idaData->N*10);
  IDASetMaxNumItersIC(idaData->ida_mem, 2*idaData->N*10);
  /* Calc Consistent y_algebraic and y_prime with current y */
  flag = IDACalcIC(idaData->ida_mem, IDA_YA_YDP_INIT, data->localData[0]->timeValue+init_h);

  /* debug */
  IDAGetNumNonlinSolvIters(idaData->ida_mem, &nonLinIters);
  infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## IDACalcIC run status %d.\nIterations : %ld\n", flag, nonLinIters);

  /* try again without line search if first try fails */
  if (!IDAflagIsSuccess(flag)){
    infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## first event iteration failed. Start next try without line search!");
    IDASetLineSearchOffIC(idaData->ida_mem, 1 /* TRUE */);
    flag = IDACalcIC(idaData->ida_mem, IDA_YA_YDP_INIT, data->localData[0]->timeValue+data->simulationInfo->tolerance);
    IDAGetNumNonlinSolvIters(idaData->ida_mem, &nonLinIters);
    infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## IDACalcIC run status %d.\nIterations : %ld\n", flag, nonLinIters);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAGetNumNonlinSolvIters");
  }
  /* obtain consistent values of y_algebraic and y_prime */
  IDAGetConsistentIC(idaData->ida_mem, idaData->y, idaData->yp);

  /* update inner algebraic variables */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  evaluateDAEResiduals_wrapperEventUpdate(data, threadData);

  memcpy(data->localData[0]->realVars, idaData->states, sizeof(double)*data->modelData->nStates);
  // and  also algebraic vars
  setAlgebraicDAEVars(data, idaData->states + data->modelData->nStates);
  memcpy(data->localData[0]->realVars + data->modelData->nStates, idaData->statesDer, sizeof(double)*data->modelData->nStates);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  /* reset initial step size again to default */
  IDASetInitStep(idaData->ida_mem, 0.0);

  return 0;
}

/**
 * @brief Main IDA solver step.
 *
 * Call IDASolve to make solver steps.
 *
 * @param data        Runtime data struct.
 * @param threadData  Thread data for error handling.
 * @param solverInfo  Main ODE/DAE solver info.
 * @return int        Return 0 on success or IDA flag on failure.
 */
int ida_solver_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  double tout = 0;
  int i = 0, flag;
  int retVal = 0, finished = 0 /* FALSE */;
  int saveJumpState;
  long int tmp;
  static unsigned int stepsOutputCounter = 1;
  int stepsMode;    /* Has to be IDA_NORMAL (1) or IDA_ONE_STEP (2) */
  int restartAfterLSFail = 0;

  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  IDA_SOLVER *idaData = (IDA_SOLVER*) solverInfo->solverData;

  SIMULATION_DATA *sData = data->localData[0];
  SIMULATION_DATA *sDataOld = data->localData[1];
  MODEL_DATA *mData = (MODEL_DATA*) data->modelData;


  /* alloc all work arrays */
  if (!idaData->daeMode)
  {
    N_VSetArrayPointer_Serial(data->localData[0]->realVars, idaData->y);
    N_VSetArrayPointer_Serial(data->localData[1]->realVars + data->modelData->nStates, idaData->yp);
  }

  if (solverInfo->didEventStep)
  {
    idaData->setInitialSolution = 0;
  }

  /* reinit solver */
  if (!idaData->setInitialSolution)
  {
    /* initialize states and der(states) */
    if (idaData->daeMode)
    {
      memcpy(idaData->states, data->localData[0]->realVars, sizeof(double)*data->modelData->nStates);
      /* and  also algebraic vars */
      getAlgebraicDAEVars(data, idaData->states + data->modelData->nStates);
      memcpy(idaData->statesDer, data->localData[0]->realVars + data->modelData->nStates, sizeof(double)*data->modelData->nStates);
    }

    /* calculate matrix for residual scaling */
    if (omc_flag[FLAG_IDA_SCALING])
    {
      getScalingFactors(data, idaData, NULL);

      /* scale idaData->y and idaData->yp */
      infoStreamPrint(OMC_LOG_SOLVER_V, 1, "Scale y and yp");
      idaScaleData(idaData);
      messageClose(OMC_LOG_SOLVER_V);
    }

    flag = IDAReInit(idaData->ida_mem,
        solverInfo->currentTime,
        idaData->y,
        idaData->yp);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAReInit");

    /* calculate matrix for residual scaling */
    if (omc_flag[FLAG_IDA_SCALING])
    {
      /* scale idaData->y and idaData->yp */
      idaReScaleData(idaData);
    }

    if (idaData->idaSmode)
    {
      for(i=0; i<idaData->Ns; ++i)
      {
        int j;
        for(j=0; j<idaData->N; ++j)
        {
          NV_Ith_S(idaData->yS[i],j) = 0;
          NV_Ith_S(idaData->ySp[i],j) = 0;
        }
      }
      flag = IDASensReInit(idaData->ida_mem, IDA_SIMULTANEOUS, idaData->yS, idaData->ySp);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASensReInit");
    }
    idaData->setInitialSolution = 1;
  }

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif


  /* Check that tout is not less than timeValue otherwise the solver
   * will come in trouble.
   * If that is the case we skip the current step. */
  if (solverInfo->currentStepSize < DASSL_STEP_EPS)
  {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Desired step to small try next one");
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Interpolate linear");

    /* linear extrapolation */
    for(i = 0; i < idaData->N; i++)
    {
      NV_Ith_S(idaData->y, i) = NV_Ith_S(idaData->y, i) + NV_Ith_S(idaData->yp, i) * solverInfo->currentStepSize;
    }
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
    data->callback->functionODE(data, threadData);
    solverInfo->currentTime = sData->timeValue;

    return 0;
  }


  /* Calculate steps until TOUT is reached */
  if (idaData->internalSteps)
  {
    /* If internalSteps are selected, let IDA run to stopTime or next sample event */
    if (data->simulationInfo->nextSampleEvent < data->simulationInfo->stopTime)
    {
      tout = data->simulationInfo->nextSampleEvent;
    }
    else
    {
      tout = data->simulationInfo->stopTime;
    }
    stepsMode = IDA_ONE_STEP;
    flag = IDASetStopTime(idaData->ida_mem, tout);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDASetStopTime");
  }
  else
  {
    tout = solverInfo->currentTime + solverInfo->currentStepSize;
    stepsMode = IDA_NORMAL;
  }


  do
  {
    infoStreamPrint(OMC_LOG_SOLVER, 1, "##IDA## new step from %.15g to %.15g", solverInfo->currentTime, tout);

    if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

    if (omc_flag[FLAG_IDA_SCALING])
    {
      /* scale idaData->y and idaData->yp */
      idaScaleData(idaData);
    }

    flag = IDASolve(idaData->ida_mem, tout, &solverInfo->currentTime, idaData->y, idaData->yp, stepsMode);

    if (omc_flag[FLAG_IDA_SCALING])
    {
      /* rescale idaData->y and idaData->yp */
      idaReScaleData(idaData);
    }

    /* set time to current time */
    sData->timeValue = solverInfo->currentTime;

    /* error handling */
    if (IDAflagIsSuccess(flag) && solverInfo->currentTime >= tout)
    {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## step done to time = %.15g", solverInfo->currentTime);
      finished = 1 /* TRUE */;
    }
    else if (flag == IDA_ROOT_RETURN)
    {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## root found at time = %.15g", solverInfo->currentTime);
      finished = 1 /* TRUE */;
    }
    else if (flag == IDA_SUCCESS || flag == IDA_TSTOP_RETURN)
    {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## continue integration time = %.15g", solverInfo->currentTime);
    }
    else if (flag == IDA_TOO_MUCH_WORK)
    {
      warningStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## has done too much work with small steps at time = %.15g", solverInfo->currentTime);
    }
    else if (flag == IDA_LSETUP_FAIL && !restartAfterLSFail)
    {
      flag = IDAReInit(idaData->ida_mem,
          solverInfo->currentTime,
          idaData->y,
          idaData->yp);
      restartAfterLSFail = 1;
      warningStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## linear solver failed try once again = %.15g", solverInfo->currentTime);
    }
    else
    {
      if (IDAflagIsSuccess(flag))
      {
        infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## continue integration time = %.15g", solverInfo->currentTime);
      }
      else if (flag == IDA_ROOT_RETURN)
      {
        infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## root found at time = %.15g", solverInfo->currentTime);
        finished = 1 /* TRUE */;
      }
      else if (flag == IDA_TOO_MUCH_WORK)
      {
        warningStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## has done too much work with small steps at time = %.15g", solverInfo->currentTime);
      }
      else if (flag == IDA_LSETUP_FAIL && !restartAfterLSFail )
      {
        flag = IDAReInit(idaData->ida_mem,
            solverInfo->currentTime,
            idaData->y,
            idaData->yp);
        restartAfterLSFail = 1;
        warningStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## linear solver failed try once again = %.15g", solverInfo->currentTime);
      }
      else
      {
        infoStreamPrint(OMC_LOG_STDOUT, 0, "##IDA## %d error occurred at time = %.15g", flag, solverInfo->currentTime);
        finished = 1 /* TRUE */;
        retVal = flag;
      }
    }

    /* closing new step message */
    messageClose(OMC_LOG_SOLVER);

    /* emit step, if step mode is selected */
    if (idaData->internalSteps)
    {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## noEquadistant stepsOutputCounter %d by freq %d at time = %.15g", stepsOutputCounter, idaData->stepsFreq, solverInfo->currentTime);
      if (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ]){
        /* output every n-th time step */
        if (stepsOutputCounter >= idaData->stepsFreq){
          stepsOutputCounter = 1; /* next line set it to one */
          infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## noEquadistant output %d by freq at time = %.15g", stepsOutputCounter, solverInfo->currentTime);
          break;
        }
        stepsOutputCounter++;
      } else if (omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME]){
        /* output when time>=k*timeValue */
        if (solverInfo->currentTime > stepsOutputCounter * idaData->stepsTime){
          stepsOutputCounter++;
          infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## noEquadistant output %d by time freq at time = %.15g", stepsOutputCounter, solverInfo->currentTime);
          break;
        }
      } else {
        break;
      }
    }

  } while(!finished);

#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
  threadData->currentErrorStage = saveJumpState;

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }

  /* initialize states and der(states) */
  if (idaData->daeMode)
  {
    memcpy(data->localData[0]->realVars, idaData->states, sizeof(double)*data->modelData->nStates);
    // and  also algebraic vars
    setAlgebraicDAEVars(data, idaData->states + data->modelData->nStates);
    memcpy(data->localData[0]->realVars + data->modelData->nStates, idaData->statesDer, sizeof(double)*data->modelData->nStates);
    sData->timeValue = solverInfo->currentTime;
  }

  /* sensitivity mode */
  if (idaData->idaSmode)
  {
    flag = IDAGetSens(idaData->ida_mem, &solverInfo->currentTime, idaData->ySResult);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAGetSens");
  }

  /* save stats */
  /* steps */
  tmp = 0;
  flag = IDAGetNumSteps(idaData->ida_mem, &tmp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAGetNumSteps");
  solverInfo->solverStatsTmp.nStepsTaken = tmp;

  /* functionODE evaluations */
  tmp = 0;
  flag = IDAGetNumResEvals(idaData->ida_mem, &tmp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAGetNumResEvals");
  solverInfo->solverStatsTmp.nCallsODE = tmp;

  /* Jacobians evaluations */
  tmp = 0;
  flag = IDAGetNumJacEvals(idaData->ida_mem, &tmp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAGetNumJacEvals");
  solverInfo->solverStatsTmp.nCallsJacobian = tmp;

  /* local error test failures */
  tmp = 0;
  flag = IDAGetNumErrTestFails(idaData->ida_mem, &tmp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAGetNumErrTestFails");
  solverInfo->solverStatsTmp.nErrorTestFailures = tmp;

  /* local error test failures */
  tmp = 0;
  flag = IDAGetNumNonlinSolvConvFails(idaData->ida_mem, &tmp);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_IDA_FLAG, "IDAGetNumNonlinSolvConvFails");
  solverInfo->solverStatsTmp.nConvergenveTestFailures = tmp;

  /* get more statistics */
  if (omc_useStream[OMC_LOG_SOLVER_V])
  {
    long int tmp1,tmp2;
    double dtmp;

    infoStreamPrint(OMC_LOG_SOLVER_V, 1, "### IDAStats ###");
    /* nonlinear stats */
    tmp1 = tmp2 = 0;
    flag = IDAGetNonlinSolvStats(idaData->ida_mem, &tmp1, &tmp2);
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, " ## Cumulative number of nonlinear iterations performed: %ld", tmp1);
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, " ## Cumulative number of nonlinear convergence failures that have occurred: %ld", tmp2);

    /* others */
    flag = IDAGetTolScaleFactor(idaData->ida_mem, &dtmp);
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, " ## Suggested scaling factor for user tolerances: %g", dtmp);

    flag = IDAGetNumLinSolvSetups(idaData->ida_mem, &tmp1);
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, " ## Number of calls made to the linear solver setup function: %ld", tmp1);

    messageClose(OMC_LOG_SOLVER_V);
  }

  infoStreamPrint(OMC_LOG_SOLVER, 0, "##IDA## Finished Integrator step.");
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);

  return retVal;
}

/**
 * @brief Compute residual F(t, y, y').
 *
 * This function has to be of type IDAResFn.
 * See section 4.6.1 Residual function of SUNDIALS v5.4.0 IDA documentation.
 *
 * @param time        Value of the independent variable (time).
 * @param yy          Vector of state variables y(t).
 * @param yp          Vector of derivatives y'(t).
 * @param rr          Output residual vector F(t, y, y').
 * @param user_data   Pointer to user data of type IDA_SOLVER*, set with IDASetUserDat.
 * @return int        Return 0 on success, positive value on recoverable error and negative value otherwise.
 */
static int residualFunctionIDA(double time, N_Vector yy, N_Vector yp, N_Vector rr, void* user_data)
{
  IDA_SOLVER* idaData = (IDA_SOLVER*) user_data;
  DATA* data = idaData->userData->data;
  threadData_t* threadData = idaData->userData->threadData;

  double timeBackup;
  long int i;
  int saveJumpState;
  int success = 0, retVal = 0;
  double *states = N_VGetArrayPointer_Serial(yy);
  double *statesDer = N_VGetArrayPointer_Serial(yp);
  double *delta  = N_VGetArrayPointer_Serial(rr);

  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "### eval residualFunctionIDA ###");
  /* rescale idaData->y and idaData->yp */
  if ((omc_flag[FLAG_IDA_SCALING] && idaData->useScaling))
  {
    idaReScaleData(idaData);
  }

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, time, CONTEXT_ODE);
  }
  data->localData[0]->timeValue = time;

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* if sensitivity mode update also bound parameters*/
  if (idaData->idaSmode)
  {
    data->callback->updateBoundParameters(data, threadData);
  }
  /* if daeMode update also all dynamic algebraic equations */
  if (idaData->daeMode)
  {
    /* set state, state derivative and dynamic algebraic
    * variables for evaluateDAEResiduals evaluation
    */
    memcpy(data->localData[0]->realVars, states, sizeof(double)*data->modelData->nStates);
    memcpy(data->localData[0]->realVars + data->modelData->nStates, statesDer, sizeof(double)*data->modelData->nStates);
    setAlgebraicDAEVars(data, states + data->modelData->nStates);
  }

  /* debug */
  if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER_V)){
    printCurrentStatesVector(OMC_LOG_SOLVER_V, data->localData[0]->realVars, data, time);
    printVector(OMC_LOG_SOLVER_V, "yprime", data->localData[0]->realVars + data->modelData->nStates, data->modelData->nStates, time);
    if (idaData->daeMode)
    {
      printVector(OMC_LOG_SOLVER_V, "yalg", states + data->modelData->nStates, data->simulationInfo->daeModeData->nAlgebraicDAEVars, time);
    }
  }

  /* read input vars */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  if (idaData->daeMode)
  {
    /* eval residual vars */
    if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
    data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_DYNAMIC);
    if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);
    /* get residual variables */
    for(i=0; i < idaData->N; i++)
    {
      NV_Ith_S(rr, i) = data->simulationInfo->daeModeData->residualVars[i];
      infoStreamPrint(OMC_LOG_SOLVER_V, 0, "%ld. residual = %e", i, NV_Ith_S(rr, i));
    }
  }
  else
  {
    /* eval function ODE */
    if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
    data->callback->functionODE(data, threadData);
    if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);
    for(i=0; i < idaData->N; i++)
    {
      NV_Ith_S(rr, i) = data->localData[0]->realVars[data->modelData->nStates + i] - NV_Ith_S(yp, i);
      infoStreamPrint(OMC_LOG_SOLVER_V, 0, "%ld. residual = %e", i, NV_Ith_S(rr, i));
    }
  }

  /* scale ressidual rr */
  if ((omc_flag[FLAG_IDA_SCALING] && idaData->useScaling))
  {
    infoStreamPrint(OMC_LOG_SOLVER_V, 1, "scale residuals");
    idaScaleVector(rr, idaData->resScale, idaData->N);
    messageClose(OMC_LOG_SOLVER_V);
    idaScaleData(idaData);
  }

  printVector(OMC_LOG_DASSL_STATES, "delta", delta, idaData->N, time);
  success = 1;
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success) {
    retVal = -1;  /* Non-recoverable error */
  }

  threadData->currentErrorStage = saveJumpState;

  if (data->simulationInfo->currentContext == CONTEXT_ODE){
    unsetContext(data);
  }
  messageClose(OMC_LOG_SOLVER_V);
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);

  return retVal;
}

/**
 * @brief Evaluate zero crossings for IDA root finding.
 *
 * Set by IDARootInit, has be of type IDARootFn.
 * See section 4.5.6 Rootfinding initialization function of SUNDIALS v5.4.0 IDA documentation.
 *
 * @param time        Independent variable (time).
 * @param yy          Vector of state variables y.
 * @param yp          Vector of state derivatives y'.
 * @param gout        Output array: ZeroCrossings g(t, y, y').
 * @param user_data   Pointer to user data of type `IDA_SOLVER*`.
 * @return int        Return 0 on success and otherwise error.
 */
static int rootsFunctionIDA(double time, N_Vector yy, N_Vector yp, double *gout, void* user_data)
{
  IDA_SOLVER* idaData = (IDA_SOLVER*) user_data;
  DATA* data = idaData->userData->data;
  threadData_t* threadData = idaData->userData->threadData;
  double *states = N_VGetArrayPointer_Serial(yy);
  double *statesDer = N_VGetArrayPointer_Serial(yp);

  int saveJumpState;

  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "### eval rootsFunctionIDA ###");

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, time, CONTEXT_EVENTS);
  }

  /* re-scale idaData->y and idaData->yp to evaluate the equations */
  if (omc_flag[FLAG_IDA_SCALING])
  {
    idaReScaleData(idaData);
  }

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_EVENTSEARCH;

  if (idaData->daeMode)
  {
    memcpy(data->localData[0]->realVars, states, sizeof(double)*data->modelData->nStates);
    setAlgebraicDAEVars(data, states + data->modelData->nStates);
    memcpy(data->localData[0]->realVars + data->modelData->nStates, statesDer, sizeof(double)*data->modelData->nStates);
  }

  data->localData[0]->timeValue = time;

  /* Exlude zero-crossings eval from sim timer */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);

  /* Update inputs and evaluate zero crossings */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  if (idaData->daeMode){
    data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_ZEROCROSS);
  }
  else
  {
    data->callback->function_ZeroCrossingsEquations(data, threadData);
  }
  data->callback->function_ZeroCrossings(data, threadData, gout);

  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);
  threadData->currentErrorStage = saveJumpState;

  /* scale data again */
  if (omc_flag[FLAG_IDA_SCALING])
  {
    idaScaleData(idaData);
  }

  if (data->simulationInfo->currentContext == CONTEXT_EVENTS){
    unsetContext(data);
  }
  messageClose(OMC_LOG_SOLVER_V);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);   // TODO: Why do we have two rt_tick calls? Keep only this one?

  return 0;
}

/**
 * @brief Compute colored numeric Jacobian.
 *
 * Calculate Jacobian matrix using finite differences method
 * with coloring from sparsity pattern.
 *
 * @param currentTime   Independent variable (time).
 * @param cj            Scalar in the system Jacobian, proportional to the inverse of the step size.
 * @param yy            Vector of state variables y.
 * @param yp            Vector of derivatives y'.
 * @param rr            Vector of residual vector F(y,y').
 * @param Jac           Output Jacobian: J = (∂F)/(∂y).
 * @param idaData       Pointer to IDA user data.
 * @return int          Return 0 on success, positive value on recoverable error and negative value otherwise.
*/
static int jacColoredNumericalDense(double currentTime, double cj, N_Vector yy, N_Vector yp,
                                    N_Vector rr, SUNMatrix Jac, IDA_SOLVER *idaData)
{
  DATA* data = idaData->userData->data;
  void* ida_mem = idaData->ida_mem;
  const int index = data->callback->INDEX_JAC_A;

  /* prepare variables */
  double *states = N_VGetArrayPointer_Serial(yy);
  double *yprime = N_VGetArrayPointer_Serial(yp);
  double *delta  = N_VGetArrayPointer_Serial(rr);
  double *newdelta = N_VGetArrayPointer_Serial(idaData->newdelta);
  double *errwgt = N_VGetArrayPointer_Serial(idaData->errwgt);

  double *delta_hh = idaData->delta_hh;
  double *ysave = idaData->ysave;
  double *ypsave = idaData->ypsave;

  double delta_h = numericalDifferentiationDeltaXsolver;    /* Global variable from model_help.c */
  double delta_hhh;
  long int i,j,l,ii;

  double currentStep;

  /* set values */
  IDAGetCurrentStep(ida_mem, &currentStep);
  if (idaData->useScaling){
    IDAGetErrWeights(ida_mem, idaData->errwgt);
  }

  SPARSE_PATTERN* sparsePattern;

  /* set sparse pattern */
  if (idaData->daeMode)
  {
    sparsePattern = data->simulationInfo->daeModeData->sparsePattern;
  }
  else
  {
    sparsePattern = data->simulationInfo->analyticJacobians[index].sparsePattern;
  }

  setContext(data, currentTime, CONTEXT_JACOBIAN);

  for(i = 0; i < sparsePattern->maxColors; i++)
  {
    for(ii=0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        delta_hhh = currentStep * yprime[ii];
        delta_hh[ii] = delta_h * fmax(fmax(fabs(states[ii]),fabs(delta_hhh)), 1./errwgt[ii]);
        delta_hh[ii] = (delta_hhh >= 0 ? delta_hh[ii] : -delta_hh[ii]);
        delta_hh[ii] = (states[ii] + delta_hh[ii]) - states[ii];      // Due to floating-point arithmetic rounding errors can result in: delta_hh[ii] != (states[ii] + delta_hh[ii]) - states[ii]
        ysave[ii] = states[ii];
        states[ii] += delta_hh[ii];

        if (idaData->daeMode){
          ypsave[ii] = yprime[ii];
          yprime[ii] += cj * delta_hh[ii];
        }

        delta_hh[ii] = 1. / delta_hh[ii];
      }
    }

    idaData->residualFunction(currentTime, yy, yp, idaData->newdelta, (void*) idaData);   /* Points to residualFunctionIDA */

    increaseJacContext(data);

    for(ii = 0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        j = sparsePattern->leadindex[ii];
        while(j < sparsePattern->leadindex[ii+1])
        {
          l  =  sparsePattern->index[j];
          SM_ELEMENT_D(Jac, l, ii) = (newdelta[l] - delta[l]) * delta_hh[ii];
          j++;
        };
        states[ii] = ysave[ii];
        if (idaData->daeMode)
        {
          yprime[ii] = ypsave[ii];
        }
      }
    }
  }
  unsetContext(data);

  return 0;
}

/**
 * @brief Compute colored symbolic Jacobian.
 *
 * Calculate Jacobian matrix using analytic Jacobian column function
 * with coloring from sparsity pattern.
 *
 * @param currentTime   Independent variable (time).
 * @param cj            Scalar in the system Jacobian, proportional to the inverse of the step size.
 * @param yy            Vector of state variables y.
 * @param yp            Vector of derivatives y'.
 * @param rr            Vector of residual vector F(y,y').
 * @param Jac           Output Jacobian: J = (∂F)/(∂y) + cj * (∂F)/(∂y').
 * @param idaData       Pointer to IDA user data.
 * @return int          Return 0 on success, positive value on recoverable error and negative value otherwise.
 */
static int jacColoredSymbolicalDense(double currentTime, double cj, N_Vector yy,
                                     N_Vector yp, N_Vector rr, SUNMatrix Jac,
                                     IDA_SOLVER *idaData)
{
  DATA* data = idaData->userData->data;
  threadData_t* threadData = idaData->userData->threadData;
  void* ida_mem = idaData->ida_mem;
  long int N = idaData->N;
  const int index = data->callback->INDEX_JAC_A;
  unsigned int i,ii,j, nth;
  SPARSE_PATTERN* sparsePattern = data->simulationInfo->analyticJacobians[index].sparsePattern;
  JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);
  jac->dae_cj = cj;

  /* prepare variables */
  double *states = N_VGetArrayPointer_Serial(yy);
  double *yprime = N_VGetArrayPointer_Serial(yp);

  setContext(data, currentTime, CONTEXT_SYM_JACOBIAN);      /* Reuse jacobian matrix in KLU solver */

  /* Evaluate constant equations if available */
  if (jac->constantEqns != NULL) {
      jac->constantEqns(data, threadData, jac, NULL);
  }

#ifdef USE_PARJAC
  GC_allow_register_threads();
#endif

#pragma omp parallel default(none) firstprivate(N) shared(i, sparsePattern, idaData, data, threadData, Jac) private(ii, j, nth)
{
#ifdef USE_PARJAC
  /* Register omp-thread in GC */
  if(!GC_thread_is_registered()) {
     struct GC_stack_base sb;
     memset (&sb, 0, sizeof(sb));
     GC_get_stack_base(&sb);
     GC_register_my_thread (&sb);
  }
  // ToDo Use always a thread local analyticJacobians (replace simulationInfo->analyticaJacobians)
  // These are not the Jacobians of the linear systems! (SimulationInfo->linearSystemData[idx].jacobian)
  JACOBIAN* t_jac = &(idaData->jacColumns[omc_get_thread_num()]);
#else
  JACOBIAN* t_jac = jac;
#endif

#pragma omp for
  for(i = 0; i < sparsePattern->maxColors; i++)
  {
    for(ii=0; ii < N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        t_jac->seedVars[ii] = 1;
      }
    }

    data->callback->functionJacA_column(data, threadData, t_jac, NULL);
    increaseJacContext(data);

    for(ii = 0; ii < N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        nth = sparsePattern->leadindex[ii];
        while(nth < sparsePattern->leadindex[ii+1])
        {
          j  =  sparsePattern->index[nth];
          infoStreamPrint(OMC_LOG_JAC, 0, "### symbolical jacobian  at [%d,%d] = %f ###", j, ii, t_jac->resultVars[j]);
          SM_ELEMENT_D(Jac, j, ii) = t_jac->resultVars[j];
          nth++;
        };
      }
    }

    for(ii=0; ii < idaData->N; ii++)
    {
      t_jac->seedVars[ii] = 0;
    }
  } // for column
} // omp parallel

  unsetContext(data);

  return 0;
}

/**
 * @brief Compute colored Jacobian matrix of ODE/DAE system.
 *
 * Available methods:
 *   - Colored Numeric Jacobian  --> jacColoredNumericalDense
 *   - Colored Symbolic Jacobian --> jacColoredSymbolicalDense
 *
 * See Section 4.6.5 in IDA documentation of SUNDIALS v5.4.0 for more details.
 *
 * @param tt          Independent variable (time).
 * @param cj          Scalar in the system Jacobian, proportional to the inverse of the step size.
 * @param yy          Vector of state variables y.
 * @param yp          Vector of state derivatives y'.
 * @param rr          Vector of residual vector F(y,y').
 * @param Jac         Output Jacobian: J = (∂F)/(∂y) + cj * (∂F)/(∂y').
 * @param user_data   Pointer to user data of type `IDA_SOLVER*`.
 * @param tmp1        Work array that can be used by, currently unused.
 * @param tmp2        Work array that can be used by, currently unused.
 * @param tmp3        Work array that can be used by, currently unused.
 * @return int        Return 0 on success, positive value on recoverable error and negative value otherwise.
 */
static int callDenseJacobian(realtype tt, realtype cj, N_Vector yy,
                             N_Vector yp, N_Vector rr, SUNMatrix Jac,
                             void *user_data, N_Vector tmp1, N_Vector tmp2,
                             N_Vector tmp3) {
  IDA_SOLVER* idaData = (IDA_SOLVER*) user_data;
  threadData_t* threadData = idaData->userData->threadData;
  int retVal;

  /* profiling */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  rt_tick(SIM_TIMER_JACOBIAN);

  if (idaData->jacobianMethod == COLOREDNUMJAC || idaData->jacobianMethod == NUMJAC)
  {
    retVal = jacColoredNumericalDense(tt, cj, yy, yp, rr, Jac, idaData);
  }
  else if (idaData->jacobianMethod == COLOREDSYMJAC || idaData->jacobianMethod == SYMJAC)
  {
    retVal = jacColoredSymbolicalDense(tt, cj, yy, yp, rr, Jac, idaData);
  }
  else
  {
    throwStreamPrint(threadData, "##IDA## Something went wrong while obtain Jacobian matrix.");
  }

  /* debug */
  if (OMC_ACTIVE_STREAM(OMC_LOG_JAC)){
    _omc_matrix* dumpJac = _omc_createMatrix(idaData->N, idaData->N, SM_DATA_D(Jac));
    _omc_printMatrix(dumpJac, "IDA-Solver: Matrix A", OMC_LOG_JAC);
    _omc_destroyMatrix(dumpJac);
  }

  /* add cj to diagonal elements and store in Jac */
  if (!idaData->daeMode)
  {
    for(int i = 0; i < SM_COLUMNS_D(Jac); i++)
    {
      SM_ELEMENT_D(Jac, i, i) -= (double) cj;
    }
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  return retVal;
}

/* finish sparse matrix, by fixing colprts */
/* TODO: Unify with finishSparseColPtr from kinsolSolver.c */
static void finishSparseColPtr(SUNMatrix A, int nnz)
{
  int i;

  /* TODO: Remove this check for performance reasons? */
  if (SM_SPARSETYPE_S(A) != CSC_MAT) {
    errorStreamPrint(
        OMC_LOG_STDOUT, 0,
        "In function finishSparseColPtr: Wrong sparse format of SUNMatrix A.");
  }

  /* Check for empty rows */
  for (i = 1; i < SM_COLUMNS_S(A) + 1; ++i) {
    if (SM_INDEXPTRS_S(A)[i] == 0) {
      SM_INDEXPTRS_S(A)[i] = SM_INDEXPTRS_S(A)[i-1];
    }
  }

  /* Set last value of indexptrs to nnz */
  SM_INDEXPTRS_S(A)[SM_COLUMNS_S(A)] = nnz;
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences with coloring
 *  into a sparse SlsMat matrix
 */
static int jacoColoredNumericalSparse(double currentTime, N_Vector yy,
                                      N_Vector yp, N_Vector rr, SUNMatrix Jac,
                                      double cj, void *userData) {
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->userData)->data);
  void* ida_mem = idaData->ida_mem;
  const int index = data->callback->INDEX_JAC_A;

  /* prepare variables */
  double *states = N_VGetArrayPointer_Serial(yy);
  double *yprime = N_VGetArrayPointer_Serial(yp);
  double *delta  = N_VGetArrayPointer_Serial(rr);
  double *newdelta = N_VGetArrayPointer_Serial(idaData->newdelta);
  double *errwgt = N_VGetArrayPointer_Serial(idaData->errwgt);

  SPARSE_PATTERN* sparsePattern;

  double *ysave = idaData->ysave;
  double *ypsave = idaData->ypsave;

  double delta_h = numericalDifferentiationDeltaXsolver;
  double *delta_hh = idaData->delta_hh;
  double delta_hhh;
  double deltaInv;

  long int i,j,ii;
  int nth = 0;
  int disBackup = idaData->useScaling;

  double currentStep;

  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "### eval jacobianSparseNumIDA ###");
  /* set values */
  IDAGetCurrentStep(ida_mem, &currentStep);
  if (idaData->useScaling){
    IDAGetErrWeights(ida_mem, idaData->errwgt);
  }

  /* set sparse pattern */
  if (idaData->daeMode)
  {
    sparsePattern = data->simulationInfo->daeModeData->sparsePattern;
  }
  else
  {
    sparsePattern = data->simulationInfo->analyticJacobians[index].sparsePattern;
  }

  /* Reset Jacobian matrix */
  SUNMatZero(Jac);

  setContext(data, currentTime, CONTEXT_JACOBIAN);

  /* rescale idaData->y and idaData->yp
   * the evaluation of the  residual function
   * needs to be performed on unscaled values
   */
  if (omc_flag[FLAG_IDA_SCALING] && idaData->useScaling)
  {
    idaReScaleVector(rr, idaData->resScale, idaData->N);
    idaReScaleData(idaData);
  }

  for(i = 0; i < sparsePattern->maxColors; i++)
  {
    for(ii=0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        delta_hhh = currentStep * yprime[ii];
        delta_hh[ii] = delta_h * fmax(fmax(fabs(states[ii]), fabs(delta_hhh)), 1./errwgt[ii]);
        delta_hh[ii] = (delta_hhh >= 0 ? delta_hh[ii] : -delta_hh[ii]);
        delta_hh[ii] = (states[ii] + delta_hh[ii]) - states[ii];     // Due to floating-point arithmetic rounding errors can result in: delta_hh[ii] != (states[ii] + delta_hh[ii]) - states[ii]
        ysave[ii] = states[ii];
        states[ii] += delta_hh[ii];

        if (idaData->daeMode){
          ypsave[ii] = yprime[ii];
          yprime[ii] += cj * delta_hh[ii];
        }

        delta_hh[ii] = 1. / delta_hh[ii];
      }
    }
    idaData->useScaling = FALSE;
    idaData->residualFunction(currentTime, yy, yp, idaData->newdelta, userData);  /* Points to residualFunctionIDA */
    idaData->useScaling = disBackup;

    increaseJacContext(data);

    for(ii = 0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        nth = sparsePattern->leadindex[ii];
        while(nth < sparsePattern->leadindex[ii+1])
        {
          j  =  sparsePattern->index[nth];
          /* use row scaling for jacobian elements */
          if (!idaData->useScaling || !omc_flag[FLAG_IDA_SCALING]){
            setJacElementSundialsSparse(j, ii, nth, (newdelta[j] - delta[j]) * delta_hh[ii], Jac, SM_CONTENT_S(Jac)->M);
          } else {
            setJacElementSundialsSparse(j, ii, nth, ((newdelta[j] - delta[j]) * delta_hh[ii]) / idaData->resScale[j] * idaData->yScale[ii], Jac, SM_CONTENT_S(Jac)->M);
          }
          nth++;
        };
        states[ii] = ysave[ii];
        if (idaData->daeMode)
        {
          yprime[ii] = ypsave[ii];
        }
      }
    }
  }
  finishSparseColPtr(Jac, sparsePattern->numberOfNonZeros);

  /* scale idaData->y and idaData->yp again */
  if ((omc_flag[FLAG_IDA_SCALING] && idaData->useScaling))
  {
    idaScaleVector(rr, idaData->resScale, idaData->N);
    idaScaleData(idaData);
  }

  unsetContext(data);
  messageClose(OMC_LOG_SOLVER_V);

  return 0;
}

/*
 * This function calculates the jacobian matrix symbolically while exploiting coloring.
 * ToDo: backend: generate seeds for der(x)
         here: always set der(x) seeds to cj when setting seed for x
 */
int jacColoredSymbolicalSparse(double currentTime, N_Vector yy, N_Vector yp,
                               N_Vector rr, SUNMatrix Jac, double cj,
                               void *userData)
{
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->userData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)idaData->userData)->threadData);
  const int index = data->callback->INDEX_JAC_A;
  JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);
  jac->dae_cj = cj;

  /* prepare variables */
  double *states = N_VGetArrayPointer_Serial(yy);
  double *yprime = N_VGetArrayPointer_Serial(yp);

#ifdef USE_PARJAC
  JACOBIAN* t_jac = (idaData->jacColumns);
#else
  JACOBIAN* t_jac = jac;
#endif
  unsigned int columns = jac->sizeCols;
  unsigned int rows = jac->sizeRows;
  SPARSE_PATTERN* sparsePattern = jac->sparsePattern;
  int maxColors = sparsePattern->maxColors;

  /* Reset Jacobian matrix */
  SUNMatZero(Jac);

  setContext(data, currentTime, CONTEXT_SYM_JACOBIAN);      /* Reuse jacobian matrix in KLU solver */

  /* Evaluate constant equations if available */
  if (jac->constantEqns != NULL) {
      jac->constantEqns(data, threadData, jac, NULL);
  }

  genericColoredSymbolicJacobianEvaluation(rows, columns, sparsePattern, Jac, t_jac,
                                           data, threadData, &setJacElementSundialsSparse);

  finishSparseColPtr(Jac, sparsePattern->numberOfNonZeros);
  unsetContext(data);

  return 0;
}

/*
 * Wrapper function to call numerical or symbolical jacobian matrix
 */
static int callSparseJacobian(double currentTime, double cj,
                              N_Vector yy, N_Vector yp, N_Vector rr,
                              SUNMatrix Jac, void *user_data,
                              N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  IDA_SOLVER* idaData = (IDA_SOLVER*)user_data;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->userData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)user_data)->userData)->threadData);
  int i;
  int flag;

  /* profiling */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  rt_tick(SIM_TIMER_JACOBIAN);

  if (idaData->jacobianMethod == COLOREDSYMJAC || idaData->jacobianMethod == SYMJAC)
  {
    jacColoredSymbolicalSparse(currentTime, yy, yp, rr, Jac, cj, user_data);
  }
  else if (idaData->jacobianMethod == COLOREDNUMJAC || idaData->jacobianMethod == NUMJAC)
  {
    jacoColoredNumericalSparse(currentTime, yy, yp, rr, Jac, cj, user_data);
  }

  /* debug */
  if (OMC_ACTIVE_STREAM(OMC_LOG_JAC)) {
    infoStreamPrint(OMC_LOG_JAC, 0, "##IDA## Sparse Matrix A.");
    SUNSparseMatrix_Print(Jac, stdout);
  }
  if (OMC_ACTIVE_STREAM(OMC_LOG_DEBUG)) {
    sundialsPrintSparseMatrix(Jac, "A", OMC_LOG_JAC);
  }

  /* add cj to diagonal elements and store in Jac */
  if (!idaData->daeMode) {
    flag = _omc_SUNMatScaleIAdd_Sparse(-cj, Jac);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_MATRIX_FLAG, "_omc_SUNMatScaleIAdd_Sparse");
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  return 0;
}


/* TODO: Unify with nlsKinsolFScaling from kinsolSolver.c? */
static int getScalingFactors(DATA* data, IDA_SOLVER* idaData, SUNMatrix inScaleMatrix)
{
  int i;

  N_Vector tmp1 = N_VNew_Serial(idaData->N);
  N_Vector tmp2 = N_VNew_Serial(idaData->N);
  N_Vector tmp3 = N_VNew_Serial(idaData->N);

  N_Vector rres = N_VNew_Serial(idaData->N);

  /* fill errwgt, since it is needed by the Jacobian calculation function */
  double *errwgt = N_VGetArrayPointer_Serial(idaData->errwgt);
  _omc_fillVector(_omc_createVector(idaData->N, errwgt), 1.);

  SUNMatrix denseMatrix;

  if (inScaleMatrix == NULL)
  {
    infoStreamPrint(OMC_LOG_SOLVER_V, 1, "##IDA## get new scaling matrix.");

    /* use y scale to scale jacobian, but y and yp are not scaled */
    idaData->useScaling = FALSE;

    /* eval residual function first */
    idaData->residualFunction(data->localData[0]->timeValue, idaData->y, idaData->yp, rres, (void*) idaData);   /* Points to residualFunctionIDA */

    /*  choose the jacobian sparse vs. dense */
    if (idaData->linearSolverMethod == IDA_LS_KLU)
    {
      if (idaData->NNZ < 0)
      {
        throwStreamPrint(NULL, "##IDA## idaData->NNZ not set.");
      }
      if (idaData->scaleMatrix == NULL) {
        idaData->scaleMatrix = SUNSparseMatrix(idaData->N, idaData->N, idaData->NNZ + idaData->N, CSC_MAT);
      }
      callSparseJacobian(data->localData[0]->timeValue, 1.0, idaData->y, idaData->yp, rres,
                         idaData->scaleMatrix, idaData, tmp1, tmp2, tmp3);
    }
    else
    {
      denseMatrix = SUNDenseMatrix(idaData->N, idaData->N);
      callDenseJacobian(data->localData[0]->timeValue, 1.0, idaData->y,
                        idaData->yp, rres, denseMatrix, idaData, tmp1, tmp2,
                        tmp3);
      SUNMatDestroy(idaData->scaleMatrix);
      idaData->scaleMatrix = SUNSparseFromDenseMatrix(denseMatrix, DBL_MIN, CSC_MAT);
      if (idaData->scaleMatrix == NULL) {
        errorStreamPrint(
            OMC_LOG_STDOUT, 0,
            "##IDA## In function SUNSparseFromDenseMatrix: Requirements are "
            "violated, or matrix storage request cannot be satisfied.");
      }
      SUNMatDestroy(denseMatrix);
    }
    /* enable scaled jacobian again */
    idaData->useScaling = TRUE;
  }
  else
  {
    infoStreamPrint(OMC_LOG_SOLVER_V, 1, "##IDA## use given scaling matrix.");
    idaData->scaleMatrix = inScaleMatrix;
  }

  /* set resScale factors */
  _omc_fillVector(_omc_createVector(idaData->N,idaData->resScale), MINIMAL_SCALE_FACTOR);
  for (i=0; i<SM_INDEXPTRS_S(idaData->scaleMatrix)[idaData->N]; ++i) {
    if (idaData->resScale[SM_INDEXVALS_S(idaData->scaleMatrix)[i]] < fabs(SM_DATA_S(idaData->scaleMatrix)[i])) {
        idaData->resScale[SM_INDEXVALS_S(idaData->scaleMatrix)[i]] = fabs(SM_DATA_S(idaData->scaleMatrix)[i]);
    }
  }

  printVector(OMC_LOG_SOLVER_V, "Prime scale factors", idaData->ypScale, idaData->N, 0.0);
  printVector(OMC_LOG_SOLVER_V, "Residual scale factors", idaData->resScale, idaData->N, 0.0);

  /* Free memory */
  messageClose(OMC_LOG_SOLVER_V);
  N_VDestroy_Serial(tmp1);
  N_VDestroy_Serial(tmp2);
  N_VDestroy_Serial(tmp3);
  N_VDestroy_Serial(rres);

  return 0;
}

/**
 * @brief Scale NVector by factors.
 *
 * @param vec       Vector to scale.
 * @param factors   Array with scaling factors.
 * @param size      Length of array factors and vector vec.
 */
static void idaScaleVector(N_Vector vec, double* factors, unsigned int size)
{
  int i;
  double *data = N_VGetArrayPointer_Serial(vec);
  printVector(OMC_LOG_SOLVER_V, "un-scaled", data, size, 0.0);
  for(i=0; i < size; ++i)
  {
    data[i] = data[i] / factors[i];
  }
  printVector(OMC_LOG_SOLVER_V, "scaled", data, size, 0.0);
}

/**
 * @brief Scale state and state derivate vector.
 *
 * @param idaData   Containing state vector y(t) and state derivate vector y'(t)
 *                  as well as scaling arrays yScale and ypScale.
 */
static void idaScaleData(IDA_SOLVER *idaData)
{
  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "Scale y");
  idaScaleVector(idaData->y, idaData->yScale, idaData->N);
  messageClose(OMC_LOG_SOLVER_V);
  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "Scale yp");
  idaScaleVector(idaData->yp, idaData->ypScale, idaData->N);
  messageClose(OMC_LOG_SOLVER_V);
}

/**
 * @brief Rescale NVector by factors.
 *
 * @param vec       Vector to rescale.
 * @param factors   Array with scaling factors.
 * @param size      Length of array factors and vector vec.
 */
static void idaReScaleVector(N_Vector vec, double* factors, unsigned int size)
{
  int i;
  double *data = N_VGetArrayPointer_Serial(vec);

  printVector(OMC_LOG_SOLVER_V, "scaled", data, size, 0.0);
  for(i=0; i < size; ++i)
  {
    data[i] = data[i] * factors[i];
  }
  printVector(OMC_LOG_SOLVER_V, "un-scaled", data, size, 0.0);
}

/**
 * @brief Rescale state and state derivate vector.
 * Undo scaling of function idaScaleData.
 *
 * @param idaData   Containing state vector y(t) and state derivate vector y'(t)
 *                  as well as scaling arrays yScale and ypScale.
 */
static void idaReScaleData(IDA_SOLVER *idaData)
{
  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "Re-Scale y");
  idaReScaleVector(idaData->y, idaData->yScale, idaData->N);
  messageClose(OMC_LOG_SOLVER_V);
  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "Re-Scale yp");
  idaReScaleVector(idaData->yp, idaData->ypScale, idaData->N);
  messageClose(OMC_LOG_SOLVER_V);
}

#endif /* #ifdef WITH_SUNDIALS */

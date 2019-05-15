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

#include <string.h>
#include <setjmp.h>

#include "omc_config.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "simulation_data.h"

#include "util/omc_error.h"
#include "gc/omc_gc.h"

#include "simulation/options.h"
#include "simulation/simulation_runtime.h"
#include "simulation/results/simulation_result.h"
#include "simulation/solver/solver_main.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/external_input.h"
#include "simulation/solver/epsilon.h"
#include "simulation/solver/omc_math.h"
#include "simulation/solver/ida_solver.h"
#include "simulation/solver/dassl.h"
#include "simulation/solver/dae_mode.h"

#ifdef WITH_SUNDIALS

/* adrpo: on mingw link with static sundials */
#if defined(__MINGW32__)
#define LINK_SUNDIALS_STATIC
#endif

/* readability */
#define SCALE_MODE 0
#define RESCALE_MODE 1


#define MINIMAL_SCALE_FACTOR 1e-8


#include <sundials/sundials_nvector.h>
#include <nvector/nvector_serial.h>
#include <idas/idas.h>
#include <idas/idas_dense.h>
#include <idas/idas_klu.h>
#include <idas/idas_spgmr.h>
#include <idas/idas_spbcgs.h>
#include <idas/idas_sptfqmr.h>

static int callDenseJacobian(long int Neq, double tt, double cj,
    N_Vector yy, N_Vector yp, N_Vector rr,
    DlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);

static int callSparseJacobian(realtype tt, realtype cj,
    N_Vector yy, N_Vector yp, N_Vector rr, SlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);

static int residualFunctionIDA(double time, N_Vector yy, N_Vector yp, N_Vector res, void* userData);
int rootsFunctionIDA(double time, N_Vector yy, N_Vector yp, double *gout, void* userData);

static int getScalingFactors(DATA* data, IDA_SOLVER *idaData, SlsMat scaleMatrix);

static int idaScaleData(IDA_SOLVER *idaData);
static int idaReScaleData(IDA_SOLVER *idaData);
static int idaScaleVector(N_Vector vec, double* factors, unsigned int size);
static int idaReScaleVector(N_Vector vec, double* factors, unsigned int size);

static IDA_SOLVER *idaDataGlobal;
static int initializedSolver = 0;
int ida_event_update(DATA* data, threadData_t *threadData);

int checkIDAflag(int flag)
{
  TRACE_PUSH
  int retVal;
  switch(flag)
  {
  case IDA_SUCCESS:
  case IDA_TSTOP_RETURN:
    retVal = 0;
    break;
  default:
    retVal = 1;
    break;
  }
  TRACE_POP
  return retVal;
}

void errOutputIDA(int error_code, const char *module, const char *function,
    char *msg, void *userData)
{
  TRACE_PUSH
  DATA* data = (DATA*)(((IDA_USERDATA*)((IDA_SOLVER*)userData)->simData)->data);
  infoStreamPrint(LOG_SOLVER, 1, "#### IDA error message #####");
  infoStreamPrint(LOG_SOLVER, 0, " -> error code %d\n -> module %s\n -> function %s", error_code, module, function);
  infoStreamPrint(LOG_SOLVER, 0, " Message: %s", msg);
  messageClose(LOG_SOLVER);
  TRACE_POP
}

/* initial main ida data */
int
ida_solver_initial(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, IDA_SOLVER *idaData){

  TRACE_PUSH

  int flag;
  long int i;
  double* tmp;

  /* default max order */
  int maxOrder = 5;

  /* sim data */
  idaData->simData = (IDA_USERDATA*)malloc(sizeof(IDA_USERDATA));
  idaData->simData->data = data;
  idaData->simData->threadData = threadData;

  /* initialize constants */
  idaData->setInitialSolution = 0;

  /* start initialization routines of sundials */
  idaData->ida_mem = IDACreate();
  if (idaData->ida_mem == NULL){
    throwStreamPrint(threadData, "##IDA## Initialization of IDA solver failed!");
  }

  idaData->daeMode = 0;
  idaData->residualFunction = residualFunctionIDA;
  idaData->N = (long int)data->modelData->nStates;

  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  /* change parameter for DAE mode */
  if (compiledInDAEMode)
  {
    idaData->daeMode = 1;
    idaData->N = (long int) data->modelData->nStates + data->simulationInfo->daeModeData->nAlgebraicDAEVars;
  }
  infoStreamPrint(LOG_SOLVER, 1, "## IDA ## Initializing solver of size %ld %s.", idaData->N, idaData->daeMode?"in DAE mode":"");

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
  else
  {
    idaData->y = N_VMake_Serial(idaData->N, data->localData[0]->realVars);
    idaData->yp = N_VMake_Serial(idaData->N, data->localData[0]->realVars + data->modelData->nStates);
  }


  flag = IDAInit(idaData->ida_mem,
      idaData->residualFunction,
      data->simulationInfo->startTime,
      idaData->y,
      idaData->yp);

  /* allocate memory for jacobians calculation */
  idaData->ysave = (double*) malloc(idaData->N*sizeof(double));
  idaData->ypsave = (double*) malloc(idaData->N*sizeof(double));
  idaData->delta_hh = (double*) malloc(idaData->N*sizeof(double));
  idaData->errwgt = N_VNew_Serial(idaData->N);
  idaData->newdelta = N_VNew_Serial(idaData->N);

  /* allocate memory for initialization process */
  tmp = (double*) malloc(idaData->N*sizeof(double));

  if (checkIDAflag(flag)){
    throwStreamPrint(threadData, "##IDA## Something goes wrong while initialize IDA solver!");
  }

  flag = IDASetUserData(idaData->ida_mem, idaData);
  if (checkIDAflag(flag)){
    throwStreamPrint(threadData, "##IDA## Something goes wrong while initialize IDA solver!");
  }

  flag = IDASetErrHandlerFn(idaData->ida_mem, errOutputIDA, idaData);
  if (checkIDAflag(flag)){
    throwStreamPrint(threadData, "##IDA## Something goes wrong while set error handler!");
  }


  /* set nominal values of the states for absolute tolerances */
  infoStreamPrint(LOG_SOLVER, 1, "The relative tolerance is %g. Following absolute tolerances are used for the states: ", data->simulationInfo->tolerance);

  for(i=0; i < data->modelData->nStates; ++i)
  {
    tmp[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    infoStreamPrint(LOG_SOLVER_V, 0, "%ld. %s -> %g", i+1, data->modelData->realVarsData[i].info.name, tmp[i]);
  }

  /* daeMode: set nominal values for algebraic variables */
  if (idaData->daeMode)
  {
    getAlgebraicDAEVarNominals(data, tmp + data->modelData->nStates);
  }
  /* multiply by tolerance to obtain a relative tolerace */
  for(i=0; i < idaData->N; ++i)
  {
    tmp[i] *= data->simulationInfo->tolerance;
  }
  messageClose(LOG_SOLVER);
  flag = IDASVtolerances(idaData->ida_mem,
      data->simulationInfo->tolerance,
      N_VMake_Serial(idaData->N,tmp));
  if (checkIDAflag(flag)){
    throwStreamPrint(threadData, "##IDA## Setting tolerances fails while initialize IDA solver!");
  }


  if (omc_flag[FLAG_IDA_SCALING]) // idaNoScaling
  {
    /* allocate memory for scaling */
    idaData->yScale  = (double*) malloc(idaData->N*sizeof(double));
    idaData->ypScale = (double*) malloc(idaData->N*sizeof(double));
    idaData->resScale  = (double*) malloc(idaData->N*sizeof(double));

    /* set yScale from nominal values */
    for(i=0; i < data->modelData->nStates; ++i)
    {
      idaData->yScale[i] = fabs(data->modelData->realVarsData[i].attribute.nominal);
      idaData->ypScale[i] = 1.0;
    }
    /* daeMode: set nominal values for algebraic variables */
    if (idaData->daeMode)
    {
     getAlgebraicDAEVarNominals(data, idaData->yScale + data->modelData->nStates);
     for(i=data->modelData->nStates; i < idaData->N; ++i)
     {
       idaData->ypScale[i] = 1.0;
     }
    }
    infoStreamPrint(LOG_SOLVER_V, 1, "The scale factors for all ida states: ");
    for(i=0; i < idaData->N; ++i)
    {
      infoStreamPrint(LOG_SOLVER_V, 0, "%ld. scaleFactor: %g", i+1, idaData->yScale[i]);
    }
    messageClose(LOG_SOLVER_V);
  }
  /* initialize */
  idaData->disableScaling = 0;

  /* set root function */
  /* if FLAG_NO_ROOTFINDING is set, solve perform without internal root finding*/
  if(!omc_flag[FLAG_NO_ROOTFINDING])
  {
    solverInfo->solverRootFinding = 1;
    flag = IDARootInit(idaData->ida_mem, data->modelData->nZeroCrossings, rootsFunctionIDA);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Setting root function fails while initialize IDA solver!");
    }
  }
  infoStreamPrint(LOG_SOLVER, 0, "ida uses internal root finding method %s", solverInfo->solverRootFinding?"YES":"NO");

  /* define maximum integration order of dassl */
  if (omc_flag[FLAG_MAX_ORDER])
  {
    maxOrder = atoi(omc_flagValue[FLAG_MAX_ORDER]);

    flag = IDASetMaxOrd(idaData->ida_mem, maxOrder);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Failed to set max integration order!");
    }
  }
  infoStreamPrint(LOG_SOLVER, 0, "maximum integration order %d", maxOrder);


  /* if FLAG_NOEQUIDISTANT_GRID is set, choose ida step method */
  if (omc_flag[FLAG_NOEQUIDISTANT_GRID])
  {
    idaData->internalSteps = 1; /* TRUE */
    solverInfo->solverNoEquidistantGrid = 1;
  }
  else
  {
    idaData->internalSteps = 0; /* FALSE */
  }
  infoStreamPrint(LOG_SOLVER, 0, "use equidistant time grid %s", idaData->internalSteps?"NO":"YES");

  /* check if Flags FLAG_NOEQUIDISTANT_OUT_FREQ or FLAG_NOEQUIDISTANT_OUT_TIME are set */
  if (idaData->internalSteps){
    if (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ])
    {
      idaData->stepsFreq = atoi(omc_flagValue[FLAG_NOEQUIDISTANT_OUT_FREQ]);
    }
    else if (omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME])
    {
      idaData->stepsTime = atof(omc_flagValue[FLAG_NOEQUIDISTANT_OUT_TIME]);
      flag = IDASetMaxStep(idaData->ida_mem, idaData->stepsTime);
      if (checkIDAflag(flag)){
        throwStreamPrint(threadData, "##IDA## Setting max steps of the IDA solver!");
      }
      infoStreamPrint(LOG_SOLVER, 0, "maximum step size %g", idaData->stepsTime);
    } else {
      idaData->stepsFreq = 1;
      idaData->stepsTime = 0.0;
    }

    if  (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ] && omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME]){
      warningStreamPrint(LOG_STDOUT, 0, "The flags are  \"noEquidistantOutputFrequency\" "
                                     "and \"noEquidistantOutputTime\" are in opposition "
                                     "to each other. The flag \"noEquidistantOutputFrequency\" superiors.");
     }
     infoStreamPrint(LOG_SOLVER, 0, "as the output frequency control is used: %d", idaData->stepsFreq);
     infoStreamPrint(LOG_SOLVER, 0, "as the output frequency time step control is used: %f", idaData->stepsTime);
  }

  /* if FLAG_IDA_LS is set, choose ida linear solver method */
  if (omc_flag[FLAG_IDA_LS])
  {
    for(i=1; i< IDA_LS_MAX;i++)
    {
      if(!strcmp((const char*)omc_flagValue[FLAG_IDA_LS], IDA_LS_METHOD[i])){
        idaData->linearSolverMethod = (int)i;
        break;
      }
    }
    if(idaData->linearSolverMethod == IDA_LS_UNKNOWN)
    {
      if (ACTIVE_WARNING_STREAM(LOG_SOLVER))
      {
        warningStreamPrint(LOG_SOLVER, 1, "unrecognized ida linear solver method %s, current options are:", (const char*)omc_flagValue[FLAG_IDA_LS]);
        for(i=1; i < IDA_LS_MAX; ++i)
        {
          warningStreamPrint(LOG_SOLVER, 0, "%-15s [%s]", IDA_LS_METHOD[i], IDA_LS_METHOD_DESC[i]);
        }
        messageClose(LOG_SOLVER);
      }
      throwStreamPrint(threadData,"unrecognized ida linear solver method %s", (const char*)omc_flagValue[FLAG_IDA_LS]);
    }
  }
  else
  {
    idaData->linearSolverMethod = IDA_LS_KLU;
  }

  switch (idaData->linearSolverMethod){
  case IDA_LS_SPGMR:
    flag = IDASpgmr(idaData->ida_mem, 0);
    break;
  case IDA_LS_SPBCG:
    flag = IDASpbcg(idaData->ida_mem, 0);
    break;
  case IDA_LS_SPTFQMR:
    flag = IDASptfqmr(idaData->ida_mem, 0);
    break;
  case IDA_LS_DENSE:
    flag = IDADense(idaData->ida_mem, idaData->N);
    break;
  case IDA_LS_KLU:
    /* Set KLU after initialized sparse pattern of the jacobian for nnz */
    break;
  default:
    throwStreamPrint(threadData,"unrecognized linear solver method %s", (const char*)omc_flagValue[FLAG_IDA_LS]);
    break;
  }
  if (checkIDAflag(flag)){
    throwStreamPrint(threadData, "##IDA## Setting linear solver method fails while initialize IDA solver!");
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "IDA linear solver method selected %s", IDA_LS_METHOD_DESC[idaData->linearSolverMethod]);
  }


  /* if FLAG_JACOBIAN is set, choose jacobian calculation method */
  if (omc_flag[FLAG_JACOBIAN])
  {
    for(i=1; i< JAC_MAX;i++)
    {
      if(!strcmp((const char*)omc_flagValue[FLAG_JACOBIAN], JACOBIAN_METHOD[i])){
        idaData->jacobianMethod = (int)i;
        break;
      }
    }
    if(idaData->daeMode && ( idaData->jacobianMethod == COLOREDSYMJAC || idaData->jacobianMethod == SYMJAC ))
    {
      warningStreamPrint(LOG_STDOUT, 1, "Symbolic Jacobians are currently not supported by DAE Mode. Switch back to numerical Jacobian!");
      idaData->jacobianMethod = COLOREDNUMJAC;
    }
    if(idaData->jacobianMethod == JAC_UNKNOWN)
    {
      if (ACTIVE_WARNING_STREAM(LOG_SOLVER))
      {
        warningStreamPrint(LOG_SOLVER, 1, "unrecognized jacobian calculation method %s, current options are:", (const char*)omc_flagValue[FLAG_JACOBIAN]);
        for(i=1; i < JAC_MAX; ++i)
        {
          warningStreamPrint(LOG_SOLVER, 0, "%-15s [%s]", JACOBIAN_METHOD[i], JACOBIAN_METHOD_DESC[i]);
        }
        messageClose(LOG_SOLVER);
      }
      throwStreamPrint(threadData,"unrecognized jacobian calculation method %s", (const char*)omc_flagValue[FLAG_JACOBIAN]);
    }
    /* default case colored numerical jacobian */
  }
  else
  {
    idaData->jacobianMethod = COLOREDNUMJAC;
  }

  /* selects the calculation method of the jacobian */
  /* in daeMode sparse pattern is already initialized in DAEMODE_DATA */
  if(!idaData->daeMode && (idaData->jacobianMethod == COLOREDNUMJAC ||
      idaData->jacobianMethod == COLOREDSYMJAC ||
      idaData->jacobianMethod == SYMJAC))
  {
    ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian))
    {
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
      idaData->jacobianMethod = INTERNALNUMJAC;
      if (idaData->linearSolverMethod == IDA_LS_KLU)
      {
        idaData->linearSolverMethod = IDA_LS_DENSE;
        flag = IDADense(idaData->ida_mem, idaData->N);
        warningStreamPrint(LOG_STDOUT, 0, "IDA linear solver method also switched back to %s", IDA_LS_METHOD_DESC[idaData->linearSolverMethod]);
      }
    } else {
      ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SIMULATION, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SIMULATION, 0, "columns: %d rows: %d", jac->sizeCols, jac->sizeRows);
      infoStreamPrint(LOG_SIMULATION, 0, "NNZ:  %d colors: %d", jac->sparsePattern.numberOfNoneZeros, jac->sparsePattern.maxColors);
      messageClose(LOG_SIMULATION);
    }

  }
  /* set up the appropriate function pointer */
  if (idaData->linearSolverMethod == IDA_LS_KLU)
  {
    if (idaData->daeMode)
    {
      idaData->NNZ = data->simulationInfo->daeModeData->sparsePattern->numberOfNoneZeros;
      flag = IDAKLU(idaData->ida_mem, idaData->N, idaData->NNZ);
      idaData->jacobianMethod = COLOREDNUMJAC; /* In DAE mode only numerical matrix is supported */
    }
    else
    {
      idaData->NNZ = data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern.numberOfNoneZeros;
      flag = IDAKLU(idaData->ida_mem, idaData->N, idaData->NNZ);
      /* to add a cj identety matrix */
      idaData->tmpJac = NewSparseMat(idaData->N, idaData->N, idaData->N);
    }
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Setup of linear solver KLU failed!");
    }

    switch (idaData->jacobianMethod){
    case SYMJAC:
    case NUMJAC:
    case COLOREDSYMJAC:
    case COLOREDNUMJAC:
      flag = IDASlsSetSparseJacFn(idaData->ida_mem, callSparseJacobian);
      break;
    default:
      throwStreamPrint(threadData,"For the klu solver jacobian calculation method has to be %s or %s", JACOBIAN_METHOD[COLOREDSYMJAC], JACOBIAN_METHOD[COLOREDNUMJAC]);
      break;
    }
  }
  else
  {
    switch (idaData->jacobianMethod){
    case SYMJAC:
    case COLOREDSYMJAC:
    case COLOREDNUMJAC:
    case NUMJAC:
      /* set jacobian function */
      flag = IDADlsSetDenseJacFn(idaData->ida_mem, callDenseJacobian);
      break;
    case INTERNALNUMJAC:
      break;
    default:
      throwStreamPrint(threadData,"unrecognized jacobian calculation method %s", (const char*)omc_flagValue[FLAG_JACOBIAN]);
      break;
    }
  }

  if (checkIDAflag(flag)){
    throwStreamPrint(threadData, "##IDA## Setting jacobian function fails while initialize IDA solver!");
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "jacobian is calculated by %s", JACOBIAN_METHOD_DESC[idaData->jacobianMethod]);
  }

  /* set max error test fails */
  if (omc_flag[FLAG_IDA_MAXERRORTESTFAIL])
  {
    int maxErrorTestFails = atoi(omc_flagValue[FLAG_IDA_MAXERRORTESTFAIL]);
    flag = IDASetMaxErrTestFails(idaData->ida_mem, maxErrorTestFails);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASetMaxErrTestFails failed!");
    }
  }

  /* set maximum number of nonlinear solver iterations at one step */
  if (omc_flag[FLAG_IDA_MAXNONLINITERS])
  {
    int maxNonlinIters = atoi(omc_flagValue[FLAG_IDA_MAXNONLINITERS]);
    flag = IDASetMaxNonlinIters(idaData->ida_mem, maxNonlinIters);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASetMaxNonlinIters failed!");
    }
  }

  /* maximum number of nonlinear solver convergence failures at one step */
  if (omc_flag[FLAG_IDA_MAXCONVFAILS])
  {
    int maxConvFails = atoi(omc_flagValue[FLAG_IDA_MAXCONVFAILS]);
    flag = IDASetMaxConvFails(idaData->ida_mem, maxConvFails);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASetMaxConvFails failed!");
    }
  }

  /* safety factor in the nonlinear convergence test */
  if (omc_flag[FLAG_IDA_NONLINCONVCOEF])
  {
    double nonlinConvCoef = atof(omc_flagValue[FLAG_IDA_NONLINCONVCOEF]);
    flag = IDASetNonlinConvCoef(idaData->ida_mem, nonlinConvCoef);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASetNonlinConvCoef failed!");
    }
  }

  /* configure algebraic variables as such */
  if (idaData->daeMode)
  {
    if (omc_flag[FLAG_NO_SUPPRESS_ALG])
    {
      flag = IDASetSuppressAlg(idaData->ida_mem, TRUE);
      if (checkIDAflag(flag)){
        throwStreamPrint(threadData, "##IDA## Suppress algebraic variables in the local error test failed");
      }
    }
    for(i=0; i<idaData->N; ++i)
    {
      tmp[i] = (i<data->modelData->nStates)? 1.0: 0.0;
    }

    flag = IDASetId(idaData->ida_mem, N_VMake_Serial(idaData->N,tmp));
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Mark algebraic variables as such failed!");
    }
  }

  /* define initial step size */
  if (omc_flag[FLAG_INITIAL_STEP_SIZE])
  {
    double initialStepSize = atof(omc_flagValue[FLAG_INITIAL_STEP_SIZE]);

    assertStreamPrint(threadData, initialStepSize >= DASSL_STEP_EPS, "Selected initial step size %e is too small.", initialStepSize);

    flag = IDASetInitStep(idaData->ida_mem, initialStepSize);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Set initial step size failed!");
    }
    infoStreamPrint(LOG_SOLVER, 0, "initial step size: %g", initialStepSize);
  }
  else
  {
    infoStreamPrint(LOG_SOLVER, 0, "initial step size is set automatically.");
  }



  /* configure the sensitivities part */
  idaData->idaSmode = omc_flag[FLAG_IDAS] ? 1 : 0;

  if (idaData->idaSmode)
  {
    idaData->Np = data->modelData->nSensitivityParamVars;
    idaData->yS = N_VCloneVectorArray_Serial(idaData->Np, idaData->y);
    idaData->ySp = N_VCloneVectorArray_Serial(idaData->Np, idaData->yp);

    for(i=0; i<idaData->Np; ++i)
    {
      int j;
      for(j=0; j<idaData->N; ++j)
      {
        NV_Ith_S(idaData->yS[i],j) = 0;
        NV_Ith_S(idaData->ySp[i],j) = 0;
      }
    }

    flag = IDASensInit(idaData->ida_mem, idaData->Np, IDA_SIMULTANEOUS, NULL, idaData->yS, idaData->ySp);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASensInit failed!");
    }

    flag = IDASetSensParams(idaData->ida_mem, data->simulationInfo->realParameter, NULL, data->simulationInfo->sensitivityParList);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASetSensParams failed!");
    }

    flag = IDASetSensDQMethod(idaData->ida_mem, IDA_FORWARD, 0);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASetSensDQMethod failed!");
    }

    flag = IDASensEEtolerances(idaData->ida_mem);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASensEEtolerances failed!");
    }
/*
    flag = IDASetSensErrCon(idaData->ida_mem, TRUE);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## set IDASensEEtolerances failed!");
    }
*/
    /* allocate result workspace */
    idaData->ySResult = N_VCloneVectorArrayEmpty_Serial(idaData->Np, idaData->y);
    for(i = 0; i < idaData->Np; ++i)
    {
      N_VSetArrayPointer_Serial((data->simulationInfo->sensitivityMatrix + i*idaData->N), idaData->ySResult[i]);
    }
  }
  if (compiledInDAEMode){
    idaDataGlobal = idaData;
    initializedSolver = 1;
    data->callback->functionDAE = ida_event_update;
  }
  messageClose(LOG_SOLVER);

  if (measure_time_flag) rt_clear(SIM_TIMER_SOLVER); /* Initialization should not add this timer... */

  free(tmp);
  TRACE_POP
  return 0;
}

/* deinitial ida data */
int
ida_solver_deinitial(IDA_SOLVER *idaData){
  TRACE_PUSH


  free(idaData->simData);
  free(idaData->ysave);
  free(idaData->ypsave);
  free(idaData->delta_hh);
  if (!idaData->daeMode && idaData->linearSolverMethod == IDA_LS_KLU){
    DestroySparseMat(idaData->tmpJac);
  }

  if (idaData->daeMode)
  {
    free(idaData->states);
    free(idaData->statesDer);
  }

  if (idaData->idaSmode)
  {
    N_VDestroyVectorArray_Serial(idaData->yS, idaData->Np);
    N_VDestroyVectorArray_Serial(idaData->ySp, idaData->Np);
    N_VDestroyVectorArray_Serial(idaData->ySResult, idaData->Np);
  }

  N_VDestroy_Serial(idaData->errwgt);
  N_VDestroy_Serial(idaData->newdelta);

  IDAFree(&idaData->ida_mem);

  TRACE_POP
  return 0;
}


int
ida_event_update(DATA* data, threadData_t *threadData)
{
  IDA_SOLVER *idaData = idaDataGlobal;
  int flag;
  long nonLinIters;
  double init_h;
  if (compiledInDAEMode){
    if (initializedSolver){

      data->simulationInfo->needToIterate = 0;

      memcpy(idaData->states, data->localData[0]->realVars, sizeof(double)*data->modelData->nStates);
      getAlgebraicDAEVars(data, idaData->states + data->modelData->nStates);
      memcpy(idaData->statesDer, data->localData[0]->realVars + data->modelData->nStates, sizeof(double)*data->modelData->nStates);

      /* update inner algebraic get new values from data */
      if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
      evaluateDAEResiduals_wrapperEventUpdate(data, threadData);
      getAlgebraicDAEVars(data, idaData->states + data->modelData->nStates);
      if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

      infoStreamPrint(LOG_SOLVER, 0, "##IDA## do event update at %.15g", data->localData[0]->timeValue);
      flag = IDAReInit(idaData->ida_mem,
          data->localData[0]->timeValue,
          idaData->y,
          idaData->yp);

      /* get initial step to provide a direction of the solution */
      IDAGetActualInitStep(idaData->ida_mem, &init_h);
      /* provide a feasible step-size if it's too small */
      if (init_h < DBL_EPSILON){
        init_h = DBL_EPSILON;
        IDASetInitStep(idaData->ida_mem, init_h);
        infoStreamPrint(LOG_SOLVER, 0, "##IDA## corrected step-size at %.15g", init_h);
      }

      /* increase limits of the non-linear solver */
      IDASetMaxNumStepsIC(idaData->ida_mem, 2*idaData->N*10);
      IDASetMaxNumJacsIC(idaData->ida_mem, 2*idaData->N*10);
      IDASetMaxNumItersIC(idaData->ida_mem, 2*idaData->N*10);
      /* Calc Consistent y_algebraic and y_prime with current y */
      flag = IDACalcIC(idaData->ida_mem, IDA_YA_YDP_INIT, data->localData[0]->timeValue+init_h);

      /* debug */
      IDAGetNumNonlinSolvIters(idaData->ida_mem, &nonLinIters);
      infoStreamPrint(LOG_SOLVER, 0, "##IDA## IDACalcIC run status %d.\nIterations : %ld\n", flag, nonLinIters);

      /* try again without line search if first try fails */
      if (checkIDAflag(flag)){
        infoStreamPrint(LOG_SOLVER, 0, "##IDA## first event iteration failed. Start next try without line search!");
        IDASetLineSearchOffIC(idaData->ida_mem, TRUE);
        flag = IDACalcIC(idaData->ida_mem, IDA_YA_YDP_INIT, data->localData[0]->timeValue+data->simulationInfo->tolerance);
        IDAGetNumNonlinSolvIters(idaData->ida_mem, &nonLinIters);
        infoStreamPrint(LOG_SOLVER, 0, "##IDA## IDACalcIC run status %d.\nIterations : %ld\n", flag, nonLinIters);
        if (checkIDAflag(flag)){
          throwStreamPrint(threadData, "##IDA## discrete update failed flag %d!", flag);
        }
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
    }
  }
  else{
    if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
    data->callback->functionDAE(data, threadData);
    if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);
  }
}

/* main ida function to make a step */
int
ida_solver_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH
  double tout = 0;
  int i = 0, flag;
  int retVal = 0, finished = FALSE;
  int saveJumpState;
  long int tmp;
  static unsigned int stepsOutputCounter = 1;
  int stepsMode;
  int restartAfterLSFail = 0;

  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  IDA_SOLVER *idaData = (IDA_SOLVER*) solverInfo->solverData;

  SIMULATION_DATA *sData = data->localData[0];
  SIMULATION_DATA *sDataOld = data->localData[1];
  MODEL_DATA *mData = (MODEL_DATA*) data->modelData;


  /* alloc all work arrays */
  if (!idaData->daeMode)
  {
    N_VSetArrayPointer(data->localData[0]->realVars, idaData->y);
    N_VSetArrayPointer(data->localData[1]->realVars + data->modelData->nStates, idaData->yp);
  }

  if (solverInfo->didEventStep)
  {
    idaData->setInitialSolution = 0;
  }

  /* reinit solver */
  if (!idaData->setInitialSolution)
  {
    debugStreamPrint(LOG_SOLVER, 0, "Re-initialized IDA Solver");

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
      infoStreamPrint(LOG_SOLVER_V, 1, "Scale y and yp");
      idaScaleData(idaData);
      messageClose(LOG_SOLVER_V);
    }

    flag = IDAReInit(idaData->ida_mem,
        solverInfo->currentTime,
        idaData->y,
        idaData->yp);

    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Something goes wrong while reinit IDA solver after event!");
    }

    /* calculate matrix for residual scaling */
    if (omc_flag[FLAG_IDA_SCALING])
    {
      /* scale idaData->y and idaData->yp */
      idaReScaleData(idaData);
    }

    if (idaData->idaSmode)
    {
      for(i=0; i<idaData->Np; ++i)
      {
        int j;
        for(j=0; j<idaData->N; ++j)
        {
          NV_Ith_S(idaData->yS[i],j) = 0;
          NV_Ith_S(idaData->ySp[i],j) = 0;
        }
      }
      flag = IDASensReInit(idaData->ida_mem, IDA_SIMULTANEOUS, idaData->yS, idaData->ySp);
      if (checkIDAflag(flag)){
        throwStreamPrint(threadData, "##IDA## set IDASensInit failed!");
      }
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
    infoStreamPrint(LOG_SOLVER, 0, "Desired step to small try next one");
    infoStreamPrint(LOG_SOLVER, 0, "Interpolate linear");

    /* linear extrapolation */
    for(i = 0; i < idaData->N; i++)
    {
      NV_Ith_S(idaData->y, i) = NV_Ith_S(idaData->y, i) + NV_Ith_S(idaData->yp, i) * solverInfo->currentStepSize;
    }
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
    data->callback->functionODE(data, threadData);
    solverInfo->currentTime = sData->timeValue;

    TRACE_POP
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
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Something goes wrong while set stopTime!");
    }
  }
  else
  {
    tout = solverInfo->currentTime + solverInfo->currentStepSize;
    stepsMode = IDA_NORMAL;
  }


  do
  {
    infoStreamPrint(LOG_SOLVER, 1, "##IDA## new step from %.15g to %.15g", solverInfo->currentTime, tout);

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
    if ( !checkIDAflag(flag) && solverInfo->currentTime >= tout)
    {
      infoStreamPrint(LOG_SOLVER, 0, "##IDA## step done to time = %.15g", solverInfo->currentTime);
      finished = TRUE;
    }
    else
    {
      if (!checkIDAflag(flag))
      {
        infoStreamPrint(LOG_SOLVER, 0, "##IDA## continue integration time = %.15g", solverInfo->currentTime);
      }
      else if (flag == IDA_ROOT_RETURN)
      {
        infoStreamPrint(LOG_SOLVER, 0, "##IDA## root found at time = %.15g", solverInfo->currentTime);
        finished = TRUE;
      }
      else if (flag == IDA_TOO_MUCH_WORK)
      {
        warningStreamPrint(LOG_SOLVER, 0, "##IDA## has done too much work with small steps at time = %.15g", solverInfo->currentTime);
      }
      else if (flag == IDA_LSETUP_FAIL && !restartAfterLSFail )
      {
        flag = IDAReInit(idaData->ida_mem,
            solverInfo->currentTime,
            idaData->y,
            idaData->yp);
        restartAfterLSFail = 1;
        warningStreamPrint(LOG_SOLVER, 0, "##IDA## linear solver failed try once again = %.15g", solverInfo->currentTime);
      }
      else
      {
        infoStreamPrint(LOG_STDOUT, 0, "##IDA## %d error occurred at time = %.15g", flag, solverInfo->currentTime);
        finished = TRUE;
        retVal = flag;
      }
    }

    /* closing new step message */
    messageClose(LOG_SOLVER);

    /* emit step, if step mode is selected */
    if (idaData->internalSteps)
    {
      infoStreamPrint(LOG_SOLVER, 0, "##IDA## noEquadistant stepsOutputCounter %d by freq %d at time = %.15g", stepsOutputCounter, idaData->stepsFreq, solverInfo->currentTime);
      if (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ]){
        /* output every n-th time step */
        if (stepsOutputCounter >= idaData->stepsFreq){
          stepsOutputCounter = 1; /* next line set it to one */
          infoStreamPrint(LOG_SOLVER, 0, "##IDA## noEquadistant output %d by freq at time = %.15g", stepsOutputCounter, solverInfo->currentTime);
          break;
        }
        stepsOutputCounter++;
      } else if (omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME]){
        /* output when time>=k*timeValue */
        if (solverInfo->currentTime > stepsOutputCounter * idaData->stepsTime){
          stepsOutputCounter++;
          infoStreamPrint(LOG_SOLVER, 0, "##IDA## noEquadistant output %d by time freq at time = %.15g", stepsOutputCounter, solverInfo->currentTime);
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
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Something goes wrong while obtain results for parameter sensitivities!");
    }
  }

  /* save stats */
  /* steps */
  tmp = 0;
  flag = IDAGetNumSteps(idaData->ida_mem, &tmp);
  if (flag == IDA_SUCCESS)
  {
    solverInfo->solverStatsTmp[0] = tmp;
  }

  /* functionODE evaluations */
  tmp = 0;
  flag = IDAGetNumResEvals(idaData->ida_mem, &tmp);
  if (flag == IDA_SUCCESS)
  {
    solverInfo->solverStatsTmp[1] = tmp;
  }

  /* Jacobians evaluations */
  tmp = 0;
  if (idaData->linearSolverMethod == IDA_LS_KLU)
  {
    flag = IDASlsGetNumJacEvals(idaData->ida_mem, &tmp);
  }
  else
  {
    flag = IDADlsGetNumJacEvals(idaData->ida_mem, &tmp);
  }

  if (flag == IDA_SUCCESS)
  {
    solverInfo->solverStatsTmp[2] = tmp;
  }

  /* local error test failures */
  tmp = 0;
  flag = IDAGetNumErrTestFails(idaData->ida_mem, &tmp);
  if (flag == IDA_SUCCESS)
  {
    solverInfo->solverStatsTmp[3] = tmp;
  }

  /* local error test failures */
  tmp = 0;
  flag = IDAGetNumNonlinSolvConvFails(idaData->ida_mem, &tmp);
  if (flag == IDA_SUCCESS)
  {
    solverInfo->solverStatsTmp[4] = tmp;
  }

  /* get more statistics */
  if (useStream[LOG_SOLVER_V])
  {
    long int tmp1,tmp2;
    double dtmp;

    infoStreamPrint(LOG_SOLVER_V, 1, "### IDAStats ###");
    /* nonlinear stats */
    tmp1 = tmp2 = 0;
    flag = IDAGetNonlinSolvStats(idaData->ida_mem, &tmp1, &tmp2);
    infoStreamPrint(LOG_SOLVER_V, 0, " ## Cumulative number of nonlinear iterations performed: %ld", tmp1);
    infoStreamPrint(LOG_SOLVER_V, 0, " ## Cumulative number of nonlinear convergence failures that have occurred: %ld", tmp2);

    /* others */
    flag = IDAGetTolScaleFactor(idaData->ida_mem, &dtmp);
    infoStreamPrint(LOG_SOLVER_V, 0, " ## Suggested scaling factor for user tolerances: %g", dtmp);

    flag = IDAGetNumLinSolvSetups(idaData->ida_mem, &tmp1);
    infoStreamPrint(LOG_SOLVER_V, 0, " ## Number of calls made to the linear solver setup function: %ld", tmp1);

    messageClose(LOG_SOLVER_V);
  }

  infoStreamPrint(LOG_SOLVER, 0, "##IDA## Finished Integrator step.");
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);

  TRACE_POP
  return retVal;
}

int residualFunctionIDA(double time, N_Vector yy, N_Vector yp, N_Vector res, void* userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)((IDA_SOLVER*)userData)->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)userData)->simData)->threadData);

  double timeBackup;
  long int i;
  int saveJumpState;
  int success = 0, retVal = 0;
  double *states = N_VGetArrayPointer(yy);
  double *statesDer = N_VGetArrayPointer(yp);
  double *delta  = N_VGetArrayPointer(res);

  infoStreamPrint(LOG_SOLVER_V, 1, "### eval residualFunctionIDA ###");
  /* rescale idaData->y and idaData->yp */
  if ((omc_flag[FLAG_IDA_SCALING] && !idaData->disableScaling))
  {
    idaReScaleData(idaData);
  }

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, &time, CONTEXT_ODE);
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
  if (ACTIVE_STREAM(LOG_DASSL_STATES)){
    printCurrentStatesVector(LOG_DASSL_STATES, data->localData[0]->realVars, data, time);
    printVector(LOG_DASSL_STATES, "yprime", data->localData[0]->realVars + data->modelData->nStates, data->modelData->nStates, time);
    if (idaData->daeMode)
    {
      printVector(LOG_DASSL_STATES, "yalg", states + data->modelData->nStates, data->simulationInfo->daeModeData->nAlgebraicDAEVars, time);
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
      NV_Ith_S(res, i) = data->simulationInfo->daeModeData->residualVars[i];
      infoStreamPrint(LOG_SOLVER_V, 0, "%d. residual = %e", i, NV_Ith_S(res, i));
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
      NV_Ith_S(res, i) = data->localData[0]->realVars[data->modelData->nStates + i] - NV_Ith_S(yp, i);
      infoStreamPrint(LOG_SOLVER_V, 0, "%d. residual = %e", i, NV_Ith_S(res, i));
    }
  }

  /* scale res */
  if ((omc_flag[FLAG_IDA_SCALING] && !idaData->disableScaling))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "scale residuals");
    idaScaleVector(res, idaData->resScale, idaData->N);
    messageClose(LOG_SOLVER_V);
    idaScaleData(idaData);
  }

  printVector(LOG_DASSL_STATES, "delta", delta, idaData->N, time);
  success = 1;
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success) {
    retVal = -1;
  }

  threadData->currentErrorStage = saveJumpState;

  if (data->simulationInfo->currentContext == CONTEXT_ODE){
    unsetContext(data);
  }
  messageClose(LOG_SOLVER_V);
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);

  TRACE_POP
  return retVal;
}

int rootsFunctionIDA(double time, N_Vector yy, N_Vector yp, double *gout, void* userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)userData)->simData)->threadData);
  double *states = N_VGetArrayPointer(yy);
  double *statesDer = N_VGetArrayPointer(yp);

  int saveJumpState;

  infoStreamPrint(LOG_SOLVER_V, 1, "### eval rootsFunctionIDA ###");

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, &time, CONTEXT_EVENTS);
  }

  /* re-scale idaData->y and idaData->yp to evaluate the equations*/
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

  /* read input vars */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval needed equations*/
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
  messageClose(LOG_SOLVER_V);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  TRACE_POP
  return 0;
}


/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences with coloring
 *  into a dense DlsMat matrix
 */
static
int jacColoredNumericalDense(double tt, N_Vector yy, N_Vector yp, N_Vector rr, DlsMat Jac, double cj, void *userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  void* ida_mem = idaData->ida_mem;
  const int index = data->callback->INDEX_JAC_A;

  /* prepare variables */
  double *states = N_VGetArrayPointer(yy);
  double *yprime = N_VGetArrayPointer(yp);
  double *delta  = N_VGetArrayPointer(rr);
  double *newdelta = N_VGetArrayPointer(idaData->newdelta);
  double *errwgt = N_VGetArrayPointer(idaData->errwgt);

  double *delta_hh = idaData->delta_hh;
  double *ysave = idaData->ysave;
  double *ypsave = idaData->ypsave;

  double delta_h = numericalDifferentiationDeltaXsolver;
  double delta_hhh;
  long int i,j,l,ii;

  double currentStep;

  /* set values */
  IDAGetCurrentStep(ida_mem, &currentStep);
  if (!idaData->disableScaling){
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
    sparsePattern = &(data->simulationInfo->analyticJacobians[index].sparsePattern);
  }

  setContext(data, &tt, CONTEXT_JACOBIAN);

  for(i = 0; i < sparsePattern->maxColors; i++)
  {
    for(ii=0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        delta_hhh = currentStep * yprime[ii];
        delta_hh[ii] = delta_h * fmax(fmax(fabs(states[ii]),fabs(delta_hhh)),fabs(1./errwgt[ii]));
        delta_hh[ii] = (delta_hhh >= 0 ? delta_hh[ii] : -delta_hh[ii]);
        delta_hh[ii] = (states[ii] + delta_hh[ii]) - states[ii];
        ysave[ii] = states[ii];
        states[ii] += delta_hh[ii];

        if (idaData->daeMode){
          ypsave[ii] = yprime[ii];
          yprime[ii] += cj * delta_hh[ii];
        }

        delta_hh[ii] = 1. / delta_hh[ii];
      }
    }

    (*idaData->residualFunction)(tt, yy, yp, idaData->newdelta, userData);

    increaseJacContext(data);

    for(ii = 0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        j = sparsePattern->leadindex[ii];
        while(j < sparsePattern->leadindex[ii+1])
        {
          l  =  sparsePattern->index[j];
          DENSE_ELEM(Jac, l, ii) = (newdelta[l] - delta[l]) * delta_hh[ii];
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

  TRACE_POP
  return 0;
}

/*
 *  function calculates the Jacobian matrix symbolical
 *  with considering also the coloring and pass it in a
 *  dense DlsMat matrix.
 */
static
int jacColoredSymbolicalDense(double tt, N_Vector yy, N_Vector yp, N_Vector rr, DlsMat Jac, double cj, void *userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)idaData->simData)->threadData);
  void* ida_mem = idaData->ida_mem;
  const int index = data->callback->INDEX_JAC_A;
  unsigned int i,ii,j, nth;
  ANALYTIC_JACOBIAN* jacData = &(data->simulationInfo->analyticJacobians[index]);
  SPARSE_PATTERN* sparsePattern = &(jacData->sparsePattern);

  /* prepare variables */
  double *states = N_VGetArrayPointer(yy);
  double *yprime = N_VGetArrayPointer(yp);

  setContext(data, &tt, CONTEXT_SYM_JACOBIAN);

  for(i = 0; i < sparsePattern->maxColors; i++)
  {
    for(ii=0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        jacData->seedVars[ii] = 1;
      }
    }

    data->callback->functionJacA_column(data, threadData, jacData, NULL);
    increaseJacContext(data);

    for(ii = 0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        nth = sparsePattern->leadindex[ii];
        while(nth < sparsePattern->leadindex[ii+1])
        {
          j  =  sparsePattern->index[nth];
          infoStreamPrint(LOG_JAC, 0, "### symbolical jacobian  at [%d,%d] = %f ###", j, ii, jacData->resultVars[j]);
          DENSE_ELEM(Jac, j, ii) = jacData->resultVars[j];
          nth++;
        };
      }
    }

    for(ii=0; ii < idaData->N; ii++)
    {
      jacData->seedVars[ii] = 0;
    }
  }
  unsetContext(data);

  TRACE_POP
  return 0;
}

/*
 * wrapper function to call dense Jacobian
 */
static int callDenseJacobian(long int Neq, double tt, double cj,
    N_Vector yy, N_Vector yp, N_Vector rr,
    DlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)user_data;
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)user_data)->simData)->threadData);
  int retVal;

  /* profiling */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  rt_tick(SIM_TIMER_JACOBIAN);

  if (idaData->jacobianMethod == COLOREDNUMJAC || idaData->jacobianMethod == NUMJAC)
  {
    retVal = jacColoredNumericalDense(tt, yy, yp, rr, Jac, cj, user_data);
  }
  else if (idaData->jacobianMethod == COLOREDSYMJAC || idaData->jacobianMethod == SYMJAC)
  {
    retVal = jacColoredSymbolicalDense(tt, yy, yp, rr, Jac, cj, user_data);
  }
  else
  {
    throwStreamPrint(threadData, "##IDA## Something goes wrong while obtain jacobian matrix!");
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_JAC)){
    _omc_matrix* dumpJac = _omc_createMatrix(idaData->N, idaData->N, Jac->data);
    _omc_printMatrix(dumpJac, "IDA-Solver: Matrix A", LOG_JAC);
    _omc_destroyMatrix(dumpJac);
  }

  /* add cj to diagonal elements and store in Jac */
  if (!idaData->daeMode)
  {
    long int i;
    for(i = 0; i < Neq; i++)
    {
      DENSE_ELEM(Jac, i, i) -= (double) cj;
    }
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  TRACE_POP
  return retVal;
}

/* Element function for sparse matrix set */
static void setJacElementKluSparse(int row, int col, double value, int nth, SlsMat spJac)
{
  if (col > 0 && spJac->colptrs[col] == 0){
      spJac->colptrs[col] = nth;
  }
  spJac->rowvals[nth] = row;
  spJac->data[nth] = value;
}

/* finish sparse matrix, by fixing colprts */
static void finishSparseColPtr(SlsMat mat, int nnz)
{
  int i;
  for(i=1; i<mat->N+1; ++i){
    if (mat->colptrs[i] == 0){
      mat->colptrs[i] = mat->colptrs[i-1];
    }
  }
  /* finish matrix colptrs */
  mat->colptrs[mat->N] = nnz;
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences with coloring
 *  into a sparse SlsMat matrix
 */
static
int jacoColoredNumericalSparse(double tt, N_Vector yy, N_Vector yp, N_Vector rr, SlsMat Jac, double cj, void *userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  void* ida_mem = idaData->ida_mem;
  const int index = data->callback->INDEX_JAC_A;

  /* prepare variables */
  double *states = N_VGetArrayPointer(yy);
  double *yprime = N_VGetArrayPointer(yp);
  double *delta  = N_VGetArrayPointer(rr);
  double *newdelta = N_VGetArrayPointer(idaData->newdelta);
  double *errwgt = N_VGetArrayPointer(idaData->errwgt);

  SPARSE_PATTERN* sparsePattern;

  double *ysave = idaData->ysave;
  double *ypsave = idaData->ypsave;

  double delta_h = numericalDifferentiationDeltaXsolver;
  double *delta_hh = idaData->delta_hh;
  double delta_hhh;
  double deltaInv;

  long int i,j,ii;
  int nth = 0;
  int disBackup = idaData->disableScaling;

  double currentStep;

  infoStreamPrint(LOG_SOLVER_V, 1, "### eval jacobianSparseNumIDA ###");
  /* set values */
  IDAGetCurrentStep(ida_mem, &currentStep);
  if (!idaData->disableScaling){
    IDAGetErrWeights(ida_mem, idaData->errwgt);
  }

  /* set sparse pattern */
  if (idaData->daeMode)
  {
    sparsePattern = data->simulationInfo->daeModeData->sparsePattern;
  }
  else
  {
    sparsePattern = &(data->simulationInfo->analyticJacobians[index].sparsePattern);
  }

  /* it's needed to clear the matrix */
  SlsSetToZero(Jac);

  setContext(data, &tt, CONTEXT_JACOBIAN);

  /* rescale idaData->y and idaData->yp
   * the evaluation of the  residual function
   * needs to be performed on unscaled values
   */
  if ((omc_flag[FLAG_IDA_SCALING] && !idaData->disableScaling))
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
        delta_hh[ii] = delta_h * fmax(fmax(fabs(states[ii]),fabs(delta_hhh)),fabs(1./errwgt[ii]));
        delta_hh[ii] = (delta_hhh >= 0 ? delta_hh[ii] : -delta_hh[ii]);
        delta_hh[ii] = (states[ii] + delta_hh[ii]) - states[ii];
        ysave[ii] = states[ii];
        states[ii] += delta_hh[ii];

        if (idaData->daeMode){
          ypsave[ii] = yprime[ii];
          yprime[ii] += cj * delta_hh[ii];
        }

        delta_hh[ii] = 1. / delta_hh[ii];
      }
    }
    idaData->disableScaling = 1;
    (*idaData->residualFunction)(tt, yy, yp, idaData->newdelta, userData);
    idaData->disableScaling = disBackup;

    increaseJacContext(data);

    for(ii = 0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        nth = sparsePattern->leadindex[ii];
        while(nth < sparsePattern->leadindex[ii+1])
        {
          j  =  sparsePattern->index[nth];
          //setJacElementKluSparse(j, ii, (newdelta[j] - delta[j]) * delta_hh[ii], nth, Jac);
          /* use row scaling for jacobian elements */
          if (idaData->disableScaling == 1 || !omc_flag[FLAG_IDA_SCALING]){
            setJacElementKluSparse(j, ii, (newdelta[j] - delta[j]) * delta_hh[ii], nth, Jac);
          }else{
            setJacElementKluSparse(j, ii, ((newdelta[j] - delta[j]) * delta_hh[ii]) / idaData->resScale[j] * idaData->yScale[ii], nth, Jac);
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
  finishSparseColPtr(Jac, sparsePattern->numberOfNoneZeros);

  /* scale idaData->y and idaData->yp again */
  if ((omc_flag[FLAG_IDA_SCALING] && !idaData->disableScaling))
  {
    idaScaleVector(rr, idaData->resScale, idaData->N);
    idaScaleData(idaData);
  }

  unsetContext(data);
  messageClose(LOG_SOLVER_V);

  TRACE_POP
  return 0;
}

/* \fn jacColoredSymbolicalSparse(double tt, N_Vector yy, N_Vector yp, N_Vector rr, SlsMat Jac, double cj, void *userData)
 *
 *
 * This function calculates symbolically the jacobian matrix and exploiting the coloring.
 */
int
jacColoredSymbolicalSparse(double tt, N_Vector yy, N_Vector yp, N_Vector rr, SlsMat Jac, double cj, void *userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)idaData->simData)->threadData);
  void* ida_mem = idaData->ida_mem;
  const int index = data->callback->INDEX_JAC_A;
  unsigned int i,ii,j,nth;

  /* prepare variables */
  double *states = N_VGetArrayPointer(yy);
  double *yprime = N_VGetArrayPointer(yp);

  ANALYTIC_JACOBIAN* jacData = &(data->simulationInfo->analyticJacobians[index]);
  SPARSE_PATTERN* sparsePattern = &(jacData->sparsePattern);

  /* it's needed to clear the matrix */
  SlsSetToZero(Jac);

  setContext(data, &tt, CONTEXT_SYM_JACOBIAN);

  for(i = 0; i < sparsePattern->maxColors; i++)
  {
    for(ii=0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        jacData->seedVars[ii] = 1;
      }
    }

    data->callback->functionJacA_column(data, threadData, jacData, NULL);
    increaseJacContext(data);

    for(ii = 0; ii < idaData->N; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        nth = sparsePattern->leadindex[ii];
        while(nth < sparsePattern->leadindex[ii+1])
        {
          j  =  sparsePattern->index[nth];
          setJacElementKluSparse(j, ii, jacData->resultVars[j], nth, Jac);
          nth++;
        };
      }
    }

    for(ii=0; ii < idaData->N; ii++)
    {
      jacData->seedVars[ii] = 0;
    }
  }
  finishSparseColPtr(Jac, sparsePattern->numberOfNoneZeros);
  unsetContext(data);

  TRACE_POP
  return 0;
}

/*
 * Wrapper function to call numerical or symbolical jacobian matrix
 */
static int callSparseJacobian(double tt, double cj,
    N_Vector yy, N_Vector yp, N_Vector rr,
    SlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  TRACE_PUSH
  int retVal;

  IDA_SOLVER* idaData = (IDA_SOLVER*)user_data;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)user_data)->simData)->threadData);

  /* profiling */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  rt_tick(SIM_TIMER_JACOBIAN);

  if (idaData->jacobianMethod == COLOREDSYMJAC || idaData->jacobianMethod == SYMJAC)
  {
    retVal = jacColoredSymbolicalSparse(tt, yy, yp, rr, Jac, cj, user_data);
  }
  else if (idaData->jacobianMethod == COLOREDNUMJAC || idaData->jacobianMethod == NUMJAC)
  {
    retVal = jacoColoredNumericalSparse(tt, yy, yp, rr, Jac, cj, user_data);
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_JAC)){
    infoStreamPrint(LOG_JAC, 0, "##IDA## Sparse Matrix A.");
    PrintSparseMat(Jac);
  }

  /* add cj to diagonal elements and store in Jac */
  if (!idaData->daeMode)
  {
    int i;
    for (i=0; i < idaData->N; ++i){
      idaData->tmpJac->colptrs[i] = i;
      idaData->tmpJac->rowvals[i] = i;
      idaData->tmpJac->data[i] = -cj;
    }
    idaData->tmpJac->colptrs[idaData->N] = idaData->N;
    SlsAddMat(Jac, idaData->tmpJac);
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  TRACE_POP
  return retVal;
}

static
int getScalingFactors(DATA* data, IDA_SOLVER *idaData, SlsMat inScaleMatrix)
{
  int i;

  N_Vector tmp1 = N_VNew_Serial(idaData->N);
  N_Vector tmp2 = N_VNew_Serial(idaData->N);
  N_Vector tmp3 = N_VNew_Serial(idaData->N);

  N_Vector rres = N_VNew_Serial(idaData->N);

  /* fill errwgt, since it is needed by the Jacobian calculation function */
  double *errwgt = N_VGetArrayPointer(idaData->errwgt);
  _omc_fillVector(_omc_createVector(idaData->N, errwgt), 1.);

  SlsMat scaleMatrix;


  if (inScaleMatrix == NULL){

    infoStreamPrint(LOG_SOLVER_V, 1, "##IDA## get new scaling matrix.");

    /* use y scale to scale jacobian, but y and yp are not scaled */
    idaData->disableScaling = 1;

    /* eval residual function first */
    residualFunctionIDA(data->localData[0]->timeValue, idaData->y, idaData->yp, rres, (void*) idaData);

    /*  choose the jacobian sparse vs. dense */
    if (idaData->linearSolverMethod == IDA_LS_KLU)
    {
      scaleMatrix = NewSparseMat(idaData->N, idaData->N, idaData->NNZ);
      callSparseJacobian(data->localData[0]->timeValue, 1.0, idaData->y, idaData->yp, rres,
                        scaleMatrix, idaData, tmp1, tmp2, tmp3);
    }
    else
    {
      DlsMat denseMatrix = NewDenseMat(idaData->N, idaData->N);
      callDenseJacobian(idaData->N, data->localData[0]->timeValue, 1.0, idaData->y, idaData->yp, rres,
                      denseMatrix, idaData, tmp1, tmp2, tmp3);
      scaleMatrix = SlsConvertDls(denseMatrix);
    }
    /* enable scaled jacobian again */
    idaData->disableScaling = 0;
  }
  else
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "##IDA## use given scaling matrix.");
    scaleMatrix = inScaleMatrix;
  }

  /* set resScale factors */
  _omc_fillVector(_omc_createVector(idaData->N,idaData->resScale), MINIMAL_SCALE_FACTOR);
  for(i=0; i<scaleMatrix->NNZ; ++i){
    if (idaData->resScale[scaleMatrix->rowvals[i]] < fabs(scaleMatrix->data[i])){
      idaData->resScale[scaleMatrix->rowvals[i]] = fabs(scaleMatrix->data[i]);
    }
  }

  printVector(LOG_SOLVER_V, "Prime scale factors", idaData->ypScale, idaData->N, 0.0);
  printVector(LOG_SOLVER_V, "Residual scale factors", idaData->resScale, idaData->N, 0.0);

  messageClose(LOG_SOLVER_V);
  N_VDestroy_Serial(tmp1);
  N_VDestroy_Serial(tmp2);
  N_VDestroy_Serial(tmp3);
  N_VDestroy_Serial(rres);

  return 0;
}

static
int idaScaleVector(N_Vector vec, double* factors, unsigned int size)
{
  int i;
  double *data = N_VGetArrayPointer(vec);
  printVector(LOG_SOLVER_V, "un-scaled", data, size, 0.0);
  for(i=0; i < size; ++i)
  {
    data[i] = data[i] / factors[i];
  }
  printVector(LOG_SOLVER_V, "scaled", data, size, 0.0);
  return 0;
}
static
int idaReScaleVector(N_Vector vec, double* factors, unsigned int size)
{
  int i;
  double *data = N_VGetArrayPointer(vec);

  printVector(LOG_SOLVER_V, "scaled", data, size, 0.0);
  for(i=0; i < size; ++i)
  {
    data[i] = data[i] * factors[i];
  }
  printVector(LOG_SOLVER_V, "un-scaled", data, size, 0.0);
  return 0;
}

static
int idaScaleData(IDA_SOLVER *idaData)
{
  infoStreamPrint(LOG_SOLVER_V, 1, "Scale y");
  idaScaleVector(idaData->y, idaData->yScale, idaData->N);
  messageClose(LOG_SOLVER_V);
  infoStreamPrint(LOG_SOLVER_V, 1, "Scale yp");
  idaScaleVector(idaData->yp, idaData->ypScale, idaData->N);
  messageClose(LOG_SOLVER_V);

  return 0;
}

static
int idaReScaleData(IDA_SOLVER *idaData)
{
  infoStreamPrint(LOG_SOLVER_V, 1, "Re-Scale y");
  idaReScaleVector(idaData->y, idaData->yScale, idaData->N);
  messageClose(LOG_SOLVER_V);
  infoStreamPrint(LOG_SOLVER_V, 1, "Re-Scale yp");
  idaReScaleVector(idaData->yp, idaData->ypScale, idaData->N);
  messageClose(LOG_SOLVER_V);

  return 0;
}



#endif

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
#include "util/memory_pool.h"

#include "simulation/options.h"
#include "simulation/simulation_runtime.h"
#include "simulation/results/simulation_result.h"
#include "simulation/solver/solver_main.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/external_input.h"
#include "simulation/solver/epsilon.h"
#include "simulation/solver/omc_math.h"
#include "simulation/solver/ida_solver.h"

#ifdef WITH_SUNDIALS


#include <sundials/sundials_nvector.h>
#include <nvector/nvector_serial.h>
#include <idas/idas.h>
#include <idas/idas_dense.h>
#include <idas/idas_klu.h>
#include <idas/idas_spgmr.h>
#include <idas/idas_spbcgs.h>
#include <idas/idas_sptfqmr.h>


static int jacobianOwnNumColoredIDA(long int Neq, realtype tt, realtype cj,
    N_Vector yy, N_Vector yp, N_Vector rr, DlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);

static int jacobianOwnNumIDA(long int Neq, realtype tt, realtype cj,
    N_Vector yy, N_Vector yp, N_Vector rr, DlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);

static int jacobianSparseNum(realtype tt, realtype cj,
    N_Vector yy, N_Vector yp, N_Vector rr, SlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);

static int jacobiancoloredKLUNum(realtype tt, realtype cj,
    N_Vector yy, N_Vector yp, N_Vector rr, SlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);


static int residualFunctionIDA(double time, N_Vector yy, N_Vector yp, N_Vector res, void* userData);
static int residualFunctionIDADAEmode(double time, N_Vector yy, N_Vector yp, N_Vector res, void* userData);
int rootsFunctionIDA(double time, N_Vector yy, N_Vector yp, double *gout, void* userData);

int checkIDAflag(int flag)
{
  TRACE_PUSH
  int retVal;
  switch(flag)
  {
  case IDA_SUCCESS:
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

  /* change parameter for DAE mode */
  if (omc_flag[FLAG_DAE_MODE])
  {
    if (compiledInDAEMode)
    {
      idaData->daeMode = 1;
      idaData->residualFunction = residualFunctionIDADAEmode;
      idaData->N = data->modelData->nStates + data->simulationInfo->daeModeData->nAlgebraicDAEVars;
    }
    else
    {
      warningStreamPrint(LOG_STDOUT, 0, "-daeMode flag is used, the model is not compiled in DAE mode. See compiler flag: +daeMode. Continue as usual.");
    }
  }

  /* initialize states and der(states) */
  if (idaData->daeMode)
  {
    idaData->states = (double*) malloc(idaData->N*sizeof(double));
    idaData->statesDer = (double*) calloc(idaData->N,sizeof(double));

    memcpy(idaData->states, data->localData[0]->realVars, sizeof(double)*data->modelData->nStates);
    // and  also algebraic vars
    data->simulationInfo->daeModeData->getAlgebraicDAEVars(data, threadData, idaData->states + data->modelData->nStates);
    memcpy(idaData->statesDer, data->localData[1]->realVars + data->modelData->nStates, sizeof(double)*data->modelData->nStates);

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
  idaData->sqrteps = sqrt(DBL_EPSILON);
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

  for(i=0; i<idaData->N; ++i)
  {
    tmp[i] = data->simulationInfo->tolerance * fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    infoStreamPrint(LOG_SOLVER, 0, "%ld. %s -> %g", i+1, data->modelData->realVarsData[i].info.name, tmp[i]);
  }
  messageClose(LOG_SOLVER);
  flag = IDASVtolerances(idaData->ida_mem,
      data->simulationInfo->tolerance,
      N_VMake_Serial(idaData->N,tmp));
  if (checkIDAflag(flag)){
    throwStreamPrint(threadData, "##IDA## Setting tolerances fails while initialize IDA solver!");
  }


  /* set root function */
  flag = IDARootInit(idaData->ida_mem, data->modelData->nZeroCrossings, rootsFunctionIDA);
  if (checkIDAflag(flag)){
    throwStreamPrint(threadData, "##IDA## Setting root function fails while initialize IDA solver!");
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
    idaData->linearSolverMethod = IDA_LS_DENSE;
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


  /* if FLAG_JACOBIAN is set, choose dassl jacobian calculation method */
  if (omc_flag[FLAG_JACOBIAN])
  {
    for(i=1; i< JAC_MAX;i++)
    {
      if(!strcmp((const char*)omc_flagValue[FLAG_JACOBIAN], JACOBIAN_METHOD[i])){
        idaData->jacobianMethod = (int)i;
        break;
      }
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
    /* in dae mode use for now internal Jacobian calculation */
    if (idaData->daeMode)
    {
      idaData->jacobianMethod = NUMJAC;
      warningStreamPrint(LOG_SOLVER, 0, "Running in DAE mode so currently no colored jacobian available, yet!");
    }
    else
    {
      if (idaData->linearSolverMethod == IDA_LS_KLU)
      {
        idaData->jacobianMethod = KLUSPARSE;
      }
      else
      {
        idaData->jacobianMethod = COLOREDNUMJAC;
      }
    }
  }

  /* selects the calculation method of the jacobian */
  if(idaData->jacobianMethod == COLOREDNUMJAC ||
      idaData->jacobianMethod == COLOREDSYMJAC ||
      idaData->jacobianMethod == KLUSPARSE ||
      idaData->jacobianMethod == KLUCOLORED ||
      idaData->jacobianMethod == SYMJAC)
  {
    if (data->callback->initialAnalyticJacobianA(data, threadData))
    {
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
      idaData->jacobianMethod = INTERNALNUMJAC;
    }
  }

  /* set up the appropriate function pointer */
  if (idaData->linearSolverMethod == IDA_LS_KLU)
  {
    flag = IDAKLU(idaData->ida_mem, idaData->N, data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern.numberOfNoneZeros);
    idaData->tmpJac = NewSparseMat(data->modelData->nStates, data->modelData->nStates, data->modelData->nStates);
    switch (idaData->jacobianMethod){
    case KLUSPARSE:
      flag = IDASlsSetSparseJacFn(idaData->ida_mem, jacobianSparseNum);
      break;
    case KLUCOLORED:
      idaData->denseJac = NewDenseMat(data->modelData->nStates, data->modelData->nStates);
      flag = IDASlsSetSparseJacFn(idaData->ida_mem, jacobiancoloredKLUNum);
      break;
    default:
      throwStreamPrint(threadData,"unrecognized jacobian calculation method %s", (const char*)omc_flagValue[FLAG_JACOBIAN]);
      break;
    }
  }
  else
  {
    switch (idaData->jacobianMethod){
    case SYMJAC:
    case COLOREDSYMJAC:
      infoStreamPrint(LOG_STDOUT, 0, "The symbolic jacobian is not implemented, yet! Switch back to internal.");
      break;
    case COLOREDNUMJAC:
      /* set jacobian function */
      flag = IDADlsSetDenseJacFn(idaData->ida_mem, jacobianOwnNumColoredIDA);
      break;
    case NUMJAC:
      /* set jacobian function */
      flag = IDADlsSetDenseJacFn(idaData->ida_mem, jacobianOwnNumIDA);
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

  /* configure algebraic variables as such */
  if (idaData->daeMode)
  {
    flag = IDASetSuppressAlg(idaData->ida_mem, TRUE);
    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Suppress algebraic variables in the local error test failed");
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
  if (idaData->linearSolverMethod == IDA_LS_KLU){
    DestroySparseMat(idaData->tmpJac);
  }
  if (idaData->jacobianMethod == KLUCOLORED)
  {
    DestroyMat(idaData->denseJac);
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
    /* initialize states and der(states) */
    if (idaData->daeMode)
    {
      memcpy(idaData->states, data->localData[0]->realVars, sizeof(double)*data->modelData->nStates);
      /* and  also algebraic vars */
      data->simulationInfo->daeModeData->getAlgebraicDAEVars(data, threadData, idaData->states + data->modelData->nStates);
      memcpy(idaData->statesDer, data->localData[1]->realVars + data->modelData->nStates, sizeof(double)*data->modelData->nStates);
    }
    flag = IDAReInit(idaData->ida_mem,
        solverInfo->currentTime,
        idaData->y,
        idaData->yp);

    debugStreamPrint(LOG_SOLVER, 0, "Re-initialized IDA Solver");

    if (checkIDAflag(flag)){
      throwStreamPrint(threadData, "##IDA## Something goes wrong while reinit IDA solver after event!");
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
      idaData->states[i] = idaData->states[i] + idaData->statesDer[i] * solverInfo->currentStepSize;
    }
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    data->callback->functionODE(data, threadData);
    solverInfo->currentTime = sData->timeValue;

    TRACE_POP
    return 0;
  }


  /* Calculate steps until TOUT is reached */
  tout = solverInfo->currentTime + solverInfo->currentStepSize;


  do
  {
    infoStreamPrint(LOG_SOLVER, 1, "##IDA## new step at time = %.15g", solverInfo->currentTime);

    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);

    flag = IDASolve(idaData->ida_mem, tout, &solverInfo->currentTime, idaData->y, idaData->yp, IDA_NORMAL);

    /* set time to current time */
    sData->timeValue = solverInfo->currentTime;

    /* error handling */
    if ( !checkIDAflag(flag) && solverInfo->currentTime >=tout)
    {
      infoStreamPrint(LOG_SOLVER, 0, "##IDA## step to time = %.15g", solverInfo->currentTime);
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
      else
      {
        infoStreamPrint(LOG_STDOUT, 0, "##IDA## %d error occurred at time = %.15g", flag, solverInfo->currentTime);
        finished = TRUE;
        retVal = flag;
      }
    }

    /* closing new step message */
    messageClose(LOG_SOLVER);

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
    data->simulationInfo->daeModeData->setAlgebraicDAEVars(data, threadData, idaData->states + data->modelData->nStates);
    memcpy(data->localData[0]->realVars + data->modelData->nStates, idaData->statesDer, sizeof(double)*data->modelData->nStates);
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

  infoStreamPrint(LOG_SOLVER, 0, "##IDA## Finished Integrator step.");

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

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, &time, CONTEXT_ODE);
  }
  printCurrentStatesVector(LOG_DASSL_STATES, states, data, time);
  printVector(LOG_DASSL_STATES, "yd", statesDer, data->modelData->nStates, time);

  timeBackup = data->localData[0]->timeValue;
  data->localData[0]->timeValue = time;

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;


  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
  data->simulationInfo->daeModeData->setAlgebraicDAEVars(data, threadData, idaData->states + data->modelData->nStates);
  /* if sensitivity mode update also bound parameters*/
  if (idaData->idaSmode)
  {
    data->callback->updateBoundParameters(data, threadData);
  }

  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);

  /* eval input vars */
  data->callback->functionODE(data, threadData);

  /* get the difference between the temp_xd(=localData->statesDerivatives)
     and xd(=statesDerivativesBackup) */
  for(i=0; i < data->modelData->nStates; i++)
  {
    NV_Ith_S(res, i) = data->localData[0]->realVars[data->modelData->nStates + i] - NV_Ith_S(yp, i);
  }
  printVector(LOG_DASSL_STATES, "dd", delta, data->modelData->nStates, time);
  success = 1;
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success) {
    retVal = -1;
  }

  threadData->currentErrorStage = saveJumpState;

  data->localData[0]->timeValue = timeBackup;

  if (data->simulationInfo->currentContext == CONTEXT_ODE){
    unsetContext(data);
  }

  TRACE_POP
  return retVal;
}


int residualFunctionIDADAEmode(double time, N_Vector yy, N_Vector yp, N_Vector res, void* userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)userData)->simData)->threadData);

  double timeBackup;
  long int i;
  int saveJumpState;
  int success = 0, retVal = 0;
  double *states = N_VGetArrayPointer(yy);
  double *statesDer = N_VGetArrayPointer(yp);
  double *delta  = N_VGetArrayPointer(res);

  /* context */
  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, &time, CONTEXT_ODE);
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_DASSL_STATES)){
    printCurrentStatesVector(LOG_DASSL_STATES, states, data, time);
    printVector(LOG_DASSL_STATES, "yprime", statesDer, data->modelData->nStates, time);
  }

  /* set time */
  timeBackup = data->localData[0]->timeValue;
  data->localData[0]->timeValue = time;

  /* set state, state derivative and dynamic algebraic
   * variables for evaluateDAEResiduals evaluation
   */
  memcpy(data->localData[0]->realVars, idaData->states, sizeof(double)*data->modelData->nStates);
  memcpy(data->localData[0]->realVars + data->modelData->nStates, idaData->statesDer, sizeof(double)*data->modelData->nStates);
  data->simulationInfo->daeModeData->setAlgebraicDAEVars(data, threadData, idaData->states + data->modelData->nStates);

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);

  /* eval residual vars */
  data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData);

  /* get data->simulationInfo->residualVars  */
  for(i=0; i < idaData->N; i++)
  {
    NV_Ith_S(res, i) = data->simulationInfo->daeModeData->residualVars[i];
  }
  printVector(LOG_DASSL_STATES, "residual", delta, idaData->N, time);
  success = 1;
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success) {
    retVal = -1;
  }

  threadData->currentErrorStage = saveJumpState;

  data->localData[0]->timeValue = timeBackup;

  if (data->simulationInfo->currentContext == CONTEXT_ODE){
    unsetContext(data);
  }

  TRACE_POP
  return retVal;
}

int rootsFunctionIDA(double time, N_Vector yy, N_Vector yp, double *gout, void* userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)userData)->simData)->threadData);

  double timeBackup;
  int saveJumpState;

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, &time, CONTEXT_EVENTS);
  }

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_EVENTSEARCH;

  timeBackup = data->localData[0]->timeValue;
  data->localData[0]->timeValue = time;

  if (idaData->daeMode)
  {
    memcpy(data->localData[0]->realVars, idaData->states, sizeof(double)*data->modelData->nStates);
    data->simulationInfo->daeModeData->setAlgebraicDAEVars(data, threadData, idaData->states + data->modelData->nStates);
    memcpy(data->localData[0]->realVars + data->modelData->nStates, idaData->statesDer, sizeof(double)*data->modelData->nStates);
  }

  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval needed equations*/
  data->callback->function_ZeroCrossingsEquations(data, threadData);

  data->callback->function_ZeroCrossings(data, threadData, gout);

  threadData->currentErrorStage = saveJumpState;
  data->localData[0]->timeValue = timeBackup;


  if (data->simulationInfo->currentContext == CONTEXT_EVENTS){
    unsetContext(data);
  }

  TRACE_POP
  return 0;
}


/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
static
int jacOwnNumColoredIDA(double tt, N_Vector yy, N_Vector yp, N_Vector rr, DlsMat Jac, double cj, void *userData)
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

  double delta_h = idaData->sqrteps;
  double delta_hhh;
  long int i,j,l,ii;

  double currentStep;

  /* set values */
  IDAGetCurrentStep(ida_mem, &currentStep);
  IDAGetErrWeights(ida_mem, idaData->errwgt);

  setContext(data, &tt, CONTEXT_JACOBIAN);

  for(i = 0; i < data->simulationInfo->analyticJacobians[index].sparsePattern.maxColors; i++)
  {
    for(ii=0; ii < data->simulationInfo->analyticJacobians[index].sizeCols; ii++)
    {
      if(data->simulationInfo->analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
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

    for(ii = 0; ii < data->simulationInfo->analyticJacobians[index].sizeCols; ii++)
    {
      if(data->simulationInfo->analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
      {
        if(ii==0)
          j = 0;
        else
          j = data->simulationInfo->analyticJacobians[index].sparsePattern.leadindex[ii-1];
        while(j < data->simulationInfo->analyticJacobians[index].sparsePattern.leadindex[ii])
        {
          l  =  data->simulationInfo->analyticJacobians[index].sparsePattern.index[j];
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
 * provides a numerical Jacobian to be used with DASSL
 */
static int jacobianOwnNumColoredIDA(long int Neq, double tt, double cj,
    N_Vector yy, N_Vector yp, N_Vector rr,
    DlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  TRACE_PUSH

  IDA_SOLVER* idaData = (IDA_SOLVER*)user_data;
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)user_data)->simData)->threadData);

  if(jacOwnNumColoredIDA(tt, yy, yp, rr, Jac, cj, user_data))
  {
    throwStreamPrint(threadData, "Error, can not get Matrix A ");
    TRACE_POP
    return 1;
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_JAC)){
    infoStreamPrint(LOG_JAC, 0, "##IDA## Matrix A.");
    PrintMat(Jac);
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

  TRACE_POP
  return 0;
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
static
int jacOwnNumIDA(double tt, N_Vector yy, N_Vector yp, N_Vector rr, DlsMat Jac, double cj, void *userData)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)userData;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  void* ida_mem = idaData->ida_mem;

  /* prepare variables */
  double *states = N_VGetArrayPointer(yy);
  double *yprime = N_VGetArrayPointer(yp);
  double *delta  = N_VGetArrayPointer(rr);
  double *newdelta = N_VGetArrayPointer(idaData->newdelta);
  double *errwgt = N_VGetArrayPointer(idaData->errwgt);

  double ysave, ypsave;

  double delta_h = idaData->sqrteps;
  double delta_hh;
  double delta_hhh;
  double deltaInv;
  long int i,j;

  double currentStep;

  /* set values */
  IDAGetCurrentStep(ida_mem, &currentStep);
  IDAGetErrWeights(ida_mem, idaData->errwgt);

  setContext(data, &tt, CONTEXT_JACOBIAN);

  for(i = 0; i < idaData->N; i++)
  {
    delta_hhh = currentStep * yprime[i];
    delta_hh = delta_h * fmax(fmax(fabs(states[i]),fabs(delta_hhh)),fabs(1./errwgt[i]));
    delta_hh = (delta_hhh >= 0 ? delta_hh : -delta_hh);
    delta_hh = (states[i] + delta_hh) - states[i];
    deltaInv = 1. / delta_hh;
    ysave = states[i];
    states[i] += delta_hh;
    if (idaData->daeMode){
      ypsave = yprime[i];
      yprime[i] += cj * delta_hh;
    }

    (*idaData->residualFunction)(tt, yy, yp, idaData->newdelta, userData);

    increaseJacContext(data);

    for(j = 0; j < idaData->N; j++)
    {
      DENSE_ELEM(Jac, j, i) = (newdelta[j] - delta[j]) * deltaInv;
    }
    states[i] = ysave;
    if (idaData->daeMode){
      yprime[i] = ypsave;
    }
  }
  unsetContext(data);

  TRACE_POP
  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
static int jacobianOwnNumIDA(long int Neq, double tt, double cj,
    N_Vector yy, N_Vector yp, N_Vector rr,
    DlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  TRACE_PUSH
  IDA_SOLVER* idaData = (IDA_SOLVER*)user_data;
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)user_data)->simData)->threadData);

  if(jacOwnNumIDA(tt, yy, yp, rr, Jac, cj, user_data))
  {
    throwStreamPrint(threadData, "Error, can not get Matrix A ");
    TRACE_POP
    return 1;
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

  TRACE_POP
  return 0;
}

static void transposeJac(SlsMat spJac)
{
  int i,j,k,index;
  const int N = spJac->N;
  const int NNZ = spJac->NNZ;
  int *count = (int*) calloc(N, sizeof(int));

  /*  Initialized to zero. */
  SlsMat tmpJac = NewSparseMat(N, N, NNZ);

  /* First find the column lengths for spJac^{T}
   * i.e. the row lengths of A.
   * Temporary counters for each row of A.
   */
  for (i=0; i<N; i++)
  {
    for (j=spJac->colptrs[i];j<spJac->colptrs[i+1];j++)
    {
      k=spJac->rowvals[j];
      count[k]++;
    }
  }

  /* Now set spJac->colptrs. 0th entry stays 0. */
  tmpJac->colptrs[0] = 0;
  for (j=0;j<N;j++)
  {
    tmpJac->colptrs[j+1]=tmpJac->colptrs[j]+count[j];
    count[j]=0;
  }
  /* Main loop.*/
  for (i=0;i<N;i++)
  {
    for (j=spJac->colptrs[i];j<spJac->colptrs[i+1];j++)
    {
      k=spJac->rowvals[j];
      /*Element’s position in column of Jac^T .*/
      index=tmpJac->colptrs[k]+count[k];
      tmpJac->rowvals[index]=i;
      tmpJac->data[index]=spJac->data[j];
      /*Increment counter for next element in that column. */
      count[k]++;
    }
  }
  CopySparseMat(tmpJac,spJac);
  free(count);
}

static void setJacElementKluSparse(int row, int col, double value, int nth, SlsMat spJac)
{
  if (col > 0){
    if (spJac->colptrs[col] == 0){
      spJac->colptrs[col] = nth;
    }
  }
  spJac->rowvals[nth] = row;
  spJac->data[nth] = value;
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
static
int jacobianSparseNumIDA(double tt, N_Vector yy, N_Vector yp, N_Vector rr, SlsMat Jac, double cj, void *userData)
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

  double ysave, ypsave;

  double delta_h = idaData->sqrteps;
  double delta_hh;
  double delta_hhh;
  double deltaInv;

  long int i,j,ii;
  int nth = 0;

  double currentStep;

  /* set values */
  IDAGetCurrentStep(ida_mem, &currentStep);
  IDAGetErrWeights(ida_mem, idaData->errwgt);

  /* it's needed to clear the matrix */
  SlsSetToZero(Jac);

  setContext(data, &tt, CONTEXT_JACOBIAN);

  for(i = 0; i < idaData->N; i++)
  {
    delta_hhh = currentStep * yprime[i];
    delta_hh = delta_h * fmax(fmax(fabs(states[i]),fabs(delta_hhh)),fabs(1./errwgt[i]));
    delta_hh = (delta_hhh >= 0 ? delta_hh : -delta_hh);
    delta_hh = (states[i] + delta_hh) - states[i];
    deltaInv = 1. / delta_hh;
    ysave = states[i];
    states[i] += delta_hh;
    if (idaData->daeMode){
      ypsave = yprime[i];
      yprime[i] += cj * delta_hh;
    }

    (*idaData->residualFunction)(tt, yy, yp, idaData->newdelta, userData);

    increaseJacContext(data);

    ii = (i == 0) ?  0 : data->simulationInfo->analyticJacobians[index].sparsePattern.leadindex[i-1];

    while(ii < data->simulationInfo->analyticJacobians[index].sparsePattern.leadindex[i])
    {
      j  =  data->simulationInfo->analyticJacobians[index].sparsePattern.index[ii];
      setJacElementKluSparse(j, i, (newdelta[j] - delta[j]) * deltaInv, nth, Jac);
      ii++;
      nth++;
    };

    states[i] = ysave;
    if (idaData->daeMode)
    {
      yprime[i] = ypsave;
    }
  }
  /* finish matrix colptrs */
  Jac->colptrs[idaData->N] = nth;

  /* not sure if the transposed matrix is needed */
  /* transposeJac(Jac); */

  unsetContext(data);

  TRACE_POP
  return 0;
}

/*
 * provides a numerical Jacobian to be used with IDA
 */
static int jacobianSparseNum(double tt, double cj,
    N_Vector yy, N_Vector yp, N_Vector rr,
    SlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  TRACE_PUSH

  IDA_SOLVER* idaData = (IDA_SOLVER*)user_data;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)user_data)->simData)->threadData);

  if(jacobianSparseNumIDA(tt, yy, yp, rr, Jac, cj, user_data))
  {
    throwStreamPrint(threadData, "Error, can not get Matrix A ");
    TRACE_POP
    return 1;
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

  TRACE_POP
  return 0;
}

/*
 * provides a numerical Jacobian to be used with IDA
 */
static int jacobiancoloredKLUNum(double tt, double cj,
    N_Vector yy, N_Vector yp, N_Vector rr,
    SlsMat Jac, void *user_data,
    N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  TRACE_PUSH

  IDA_SOLVER* idaData = (IDA_SOLVER*)user_data;
  DATA* data = (DATA*)(((IDA_USERDATA*)idaData->simData)->data);
  threadData_t* threadData = (threadData_t*)(((IDA_USERDATA*)((IDA_SOLVER*)user_data)->simData)->threadData);

  SetToZero(idaData->denseJac);


  if(jacOwnNumColoredIDA(tt, yy, yp, rr, idaData->denseJac, cj, user_data))
  {
    throwStreamPrint(threadData, "Error, can not get Matrix A ");
    TRACE_POP
    return 1;
  }
  CopySparseMat(SlsConvertDls(idaData->denseJac), Jac);

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

  TRACE_POP
  return 0;
}



#endif

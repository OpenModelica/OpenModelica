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

#include <string.h>
#include <setjmp.h>

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

#include "simulation/solver/dassl.h"
#include "meta/meta_modelica.h"

#ifdef __cplusplus
extern "C" {
#endif

/* experimental flag for SKF TLM Master Solver Interface
 *  - it's used with -noEquidistantTimeGrid flag.
 *  - it's set to 1 if the continuous system is evaluated
 *    when dassl finished a step, otherwise it's 0.
 */
int RHSFinalFlag;

/* provides a dummy Jacobian to be used with DASSL */
static int
dummy_Jacobian(double *t, double *y, double *yprime, double *deltaD,
    double *delta, double *cj, double *h, double *wt, double *rpar, int* ipar) {
  return 0;
}
static int
dummy_zeroCrossing(int *neqm, double *t, double *y, double *yp,
                   int *ng, double *gout, double *rpar, int* ipar) {
  return 0;
}

static int callJacobian(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar);
static int jacA_num(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar);
static int jacA_numColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar);
static int jacA_sym(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
       double *rpar, int* ipar);
static int jacA_symColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
       double *rpar, int* ipar);

void  DDASKR(
    int (*res) (double *t, double *y, double *yprime, double* cj, double *delta, int *ires, double *rpar, int* ipar),
    int *neq,
    double *t,
    double *y,
    double *yprime,
    double *tout,
    int *info,
    double *rtol,
    double *atol,
    int *idid,
    double *rwork,
    int *lrw,
    int *iwork,
    int *liw,
    double *rpar,
    int *ipar,
    int (*jac) (double *t, double *y, double *yprime, double *deltaD, double *delta, double *cj, double *h, double *wt, double *rpar, int* ipar),
    int (*psol) (int *neq, double *t, double *y, double *yprime, double *savr, double *pwk, double *cj, double *wt, double *wp, int *iwp, double *b, double eplin, int* ires, double *rpar, int* ipar),
    int (*g) (int *neqm, double *t, double *y, double *yp, int *ng, double *gout, double *rpar, int* ipar),
    int *ng,
    int *jroot
);

static int
dummy_precondition(int *neq, double *t, double *y, double *yprime, double *savr, double *pwk, double *cj, double *wt, double *wp, int *iwp, double *b, double eplin, int* ires, double *rpar, int* ipar){
    return 0;
}

static int continue_DASSL(int* idid, double* tolarence);

/* function for calculating state values on residual form */
static int functionODE_residual(double *t, double *x, double *xprime, double *cj, double *delta, int *ires, double *rpar, int* ipar);
/* function for calculating zeroCrossings */
static int function_ZeroCrossingsDASSL(int *neqm, double *t, double *y, double *yp,
        int *ng, double *gout, double *rpar, int* ipar);

int dassl_initial(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, DASSL_DATA *dasslData)
{
  TRACE_PUSH
  /* work arrays for DASSL */
  unsigned int i;
  long N;
  SIMULATION_DATA tmpSimData = {0};

  dasslData->residualFunction = functionODE_residual;
  N = data->modelData->nStates;

  dasslData->N = N;

  RHSFinalFlag = 0;

  dasslData->liw = 40 + N;
  dasslData->lrw = 60 + ((maxOrder + 4) * N) + (N * N)  + (3*data->modelData->nZeroCrossings);
  dasslData->rwork = (double*) calloc(dasslData->lrw, sizeof(double));
  assertStreamPrint(threadData, 0 != dasslData->rwork,"out of memory");
  dasslData->iwork = (int*)  calloc(dasslData->liw, sizeof(int));
  assertStreamPrint(threadData, 0 != dasslData->iwork,"out of memory");
  dasslData->ng = (int) data->modelData->nZeroCrossings;
  dasslData->jroot = (int*)  calloc(data->modelData->nZeroCrossings, sizeof(int));
  dasslData->rpar = (double**) malloc(3*sizeof(double*));
  dasslData->ipar = (int*) malloc(sizeof(int));
  dasslData->ipar[0] = ACTIVE_STREAM(LOG_JAC);
  assertStreamPrint(threadData, 0 != dasslData->ipar,"out of memory");
  dasslData->atol = (double*) malloc(N*sizeof(double));
  dasslData->rtol = (double*) malloc(N*sizeof(double));
  dasslData->info = (int*) calloc(infoLength, sizeof(int));
  assertStreamPrint(threadData, 0 != dasslData->info,"out of memory");

  dasslData->idid = 0;

  dasslData->ysave = (double*) malloc(N*sizeof(double));
  dasslData->ypsave = (double*) malloc(N*sizeof(double));
  dasslData->delta_hh = (double*) malloc(N*sizeof(double));
  dasslData->newdelta = (double*) malloc(N*sizeof(double));
  dasslData->stateDer = (double*) calloc(N, sizeof(double));
  dasslData->states = (double*) malloc(N*sizeof(double));

  data->simulationInfo->currentContext = CONTEXT_ALGEBRAIC;

  /* ### start configuration of dassl ### */
  infoStreamPrint(LOG_SOLVER, 1, "Configuration of the dassl code:");



  /* set nominal values of the states for absolute tolerances */
  dasslData->info[1] = 1;
  infoStreamPrint(LOG_SOLVER, 1, "The relative tolerance is %g. Following absolute tolerances are used for the states: ", data->simulationInfo->tolerance);
  for(i=0; i<dasslData->N; ++i)
  {
    dasslData->rtol[i] = data->simulationInfo->tolerance;
    dasslData->atol[i] = data->simulationInfo->tolerance * fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    infoStreamPrint(LOG_SOLVER_V, 0, "%d. %s -> %g", i+1, data->modelData->realVarsData[i].info.name, dasslData->atol[i]);
  }
  messageClose(LOG_SOLVER);



  /* let dassl return at every internal step */
  dasslData->info[2] = 1;


  /* define maximum step size, which is dassl is allowed to go */
  if (omc_flag[FLAG_MAX_STEP_SIZE])
  {
    double maxStepSize = atof(omc_flagValue[FLAG_MAX_STEP_SIZE]);

    assertStreamPrint(threadData, maxStepSize >= DASSL_STEP_EPS, "Selected maximum step size %e is too small.", maxStepSize);

    dasslData->rwork[1] = maxStepSize;
    dasslData->info[6] = 1;
    infoStreamPrint(LOG_SOLVER, 0, "maximum step size %g", dasslData->rwork[1]);
  }
  else
  {
    infoStreamPrint(LOG_SOLVER, 0, "maximum step size not set");
  }


  /* define initial step size, which is dassl is used every time it restarts */
  if (omc_flag[FLAG_INITIAL_STEP_SIZE])
  {
    double initialStepSize = atof(omc_flagValue[FLAG_INITIAL_STEP_SIZE]);

    assertStreamPrint(threadData, initialStepSize >= DASSL_STEP_EPS, "Selected initial step size %e is too small.", initialStepSize);

    dasslData->rwork[2] = initialStepSize;
    dasslData->info[7] = 1;
    infoStreamPrint(LOG_SOLVER, 0, "initial step size %g", dasslData->rwork[2]);
  }
  else
  {
    infoStreamPrint(LOG_SOLVER, 0, "initial step size not set");
  }


  /* define maximum integration order of dassl */
  if (omc_flag[FLAG_MAX_ORDER])
  {
    int maxOrder = atoi(omc_flagValue[FLAG_MAX_ORDER]);

    assertStreamPrint(threadData, maxOrder >= 1 && maxOrder <= 5, "Selected maximum order %d is out of range (1-5).", maxOrder);

    dasslData->iwork[2] = maxOrder;
    dasslData->info[8] = 1;
  }
  infoStreamPrint(LOG_SOLVER, 0, "maximum integration order %d", dasslData->info[8]?dasslData->iwork[2]:maxOrder);


  /* if FLAG_NOEQUIDISTANT_GRID is set, choose dassl step method */
  if (omc_flag[FLAG_NOEQUIDISTANT_GRID])
  {
    dasslData->dasslSteps = 1; /* TRUE */
    solverInfo->solverNoEquidistantGrid = 1;
  }
  else
  {
    dasslData->dasslSteps = 0; /* FALSE */
  }
  infoStreamPrint(LOG_SOLVER, 0, "use equidistant time grid %s", dasslData->dasslSteps?"NO":"YES");

  /* check if Flags FLAG_NOEQUIDISTANT_OUT_FREQ or FLAG_NOEQUIDISTANT_OUT_TIME are set */
  if (dasslData->dasslSteps){
    if (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ])
    {
      dasslData->dasslStepsFreq = atoi(omc_flagValue[FLAG_NOEQUIDISTANT_OUT_FREQ]);
    }
    else if (omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME])
    {
      dasslData->dasslStepsTime = atof(omc_flagValue[FLAG_NOEQUIDISTANT_OUT_TIME]);
      dasslData->rwork[1] = dasslData->dasslStepsTime;
      dasslData->info[6] = 1;
      infoStreamPrint(LOG_SOLVER, 0, "maximum step size %g", dasslData->rwork[1]);
    } else {
      dasslData->dasslStepsFreq = 1;
      dasslData->dasslStepsTime = 0.0;
    }

    if  (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ] && omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME]){
      warningStreamPrint(LOG_STDOUT, 0, "The flags are  \"noEquidistantOutputFrequency\" "
                                     "and \"noEquidistantOutputTime\" are in opposition "
                                     "to each other. The flag \"noEquidistantOutputFrequency\" superiors.");
     }
     infoStreamPrint(LOG_SOLVER, 0, "as the output frequency control is used: %d", dasslData->dasslStepsFreq);
     infoStreamPrint(LOG_SOLVER, 0, "as the output frequency time step control is used: %f", dasslData->dasslStepsTime);
  }

  /* if FLAG_JACOBIAN is set, choose dassl jacobian calculation method */
  if (omc_flag[FLAG_JACOBIAN])
  {
    for(i=1; i< JAC_MAX;i++)
    {
      if(!strcmp((const char*)omc_flagValue[FLAG_JACOBIAN], JACOBIAN_METHOD[i])){
        dasslData->dasslJacobian = (int)i;
        break;
      }
    }
    if(dasslData->dasslJacobian == JAC_UNKNOWN)
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
    dasslData->dasslJacobian = COLOREDNUMJAC;
  }

  /* selects the calculation method of the jacobian */
  if(dasslData->dasslJacobian == COLOREDNUMJAC ||
     dasslData->dasslJacobian == COLOREDSYMJAC ||
     dasslData->dasslJacobian == SYMJAC)
  {
    ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian))
    {
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
      dasslData->dasslJacobian = INTERNALNUMJAC;
    } else {
      ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SIMULATION, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SIMULATION, 0, "columns: %d rows: %d", jac->sizeCols, jac->sizeRows);
      infoStreamPrint(LOG_SIMULATION, 0, "NNZ:  %d colors: %d", jac->sparsePattern.numberOfNoneZeros, jac->sparsePattern.maxColors);
      messageClose(LOG_SIMULATION);
    }
  }
  /* default use a user sub-routine for JAC */
  dasslData->info[4] = 1;

  /* set up the appropriate function pointer */
  switch (dasslData->dasslJacobian){
    case COLOREDNUMJAC:
      data->simulationInfo->jacobianEvals = data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern.maxColors;
      dasslData->jacobianFunction =  jacA_numColored;
      break;
    case COLOREDSYMJAC:
      data->simulationInfo->jacobianEvals = data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern.maxColors;
      dasslData->jacobianFunction =  jacA_symColored;
      break;
    case SYMJAC:
      dasslData->jacobianFunction =  jacA_sym;
      break;
    case NUMJAC:
      dasslData->jacobianFunction =  jacA_num;
      break;
    case INTERNALNUMJAC:
      dasslData->jacobianFunction =  dummy_Jacobian;
      /* no user sub-routine for JAC */
      dasslData->info[4] = 0;
      break;
    default:
      throwStreamPrint(threadData,"unrecognized jacobian calculation method %s", (const char*)omc_flagValue[FLAG_JACOBIAN]);
      break;
  }
  infoStreamPrint(LOG_SOLVER, 0, "jacobian is calculated by %s", JACOBIAN_METHOD_DESC[dasslData->dasslJacobian]);

  /* if FLAG_NO_ROOTFINDING is set, choose dassl with out internal root finding */
  if(omc_flag[FLAG_NO_ROOTFINDING])
  {
    dasslData->dasslRootFinding = 0;
    dasslData->zeroCrossingFunction = dummy_zeroCrossing;
    dasslData->ng = 0;
  }
  else
  {
    solverInfo->solverRootFinding = 1;
    dasslData->dasslRootFinding = 1;
    dasslData->zeroCrossingFunction = function_ZeroCrossingsDASSL;
  }
  infoStreamPrint(LOG_SOLVER, 0, "dassl uses internal root finding method %s", dasslData->dasslRootFinding?"YES":"NO");


  /* if FLAG_NO_RESTART is set, choose dassl step method */
  if (omc_flag[FLAG_NO_RESTART])
  {
    dasslData->dasslAvoidEventRestart = 1; /* TRUE */
  }
  else
  {
    dasslData->dasslAvoidEventRestart = 0; /* FALSE */
  }
  infoStreamPrint(LOG_SOLVER, 0, "dassl performs an restart after an event occurs %s", dasslData->dasslAvoidEventRestart?"NO":"YES");

  /* ### end configuration of dassl ### */


  messageClose(LOG_SOLVER);
  TRACE_POP
  return 0;
}


int dassl_deinitial(DASSL_DATA *dasslData)
{
  TRACE_PUSH
  unsigned int i;

  /* free work arrays for DASSL */
  free(dasslData->rwork);
  free(dasslData->iwork);
  free(dasslData->rpar);
  free(dasslData->ipar);
  free(dasslData->atol);
  free(dasslData->rtol);
  free(dasslData->info);
  free(dasslData->jroot);
  free(dasslData->ysave);
  free(dasslData->delta_hh);
  free(dasslData->newdelta);
  free(dasslData->states);
  free(dasslData->stateDer);

  free(dasslData);

  TRACE_POP
  return 0;
}

/* \fn printCurrentStatesVector(int logLevel, double* y, DATA* data, double time)
 *
 * \param [in] [logLevel]
 * \param [in] [states]
 * \param [in] [data]
 * \param [in] [time]
 *
 * This function outputs states vector.
 *
 */
int printCurrentStatesVector(int logLevel, double* states, DATA* data, double time)
{
  int i;
  infoStreamPrint(logLevel, 1, "states at time=%g", time);
  for(i=0;i<data->modelData->nStates;++i)
  {
    infoStreamPrint(logLevel, 0, "%d. %s = %g", i+1, data->modelData->realVarsData[i].info.name, states[i]);
  }
  messageClose(logLevel);

  return 0;
}

/* \fn printVector(int logLevel, double* y, DATA* data, double time)
 *
 * \param [in] [logLevel]
 * \param [in] [name]
 * \param [in] [vec]
 * \param [in] [size]
 * \param [in] [time]
 *
 * This function outputs a vector of size
 *
 */
int printVector(int logLevel, const char* name,  double* vec, int n, double time)
{
  int i;
  infoStreamPrint(logLevel, 1, "%s at time=%g", name, time);
  for(i=0; i<n; ++i)
  {
    infoStreamPrint(logLevel, 0, "%d. %g", i+1, vec[i]);
  }
  messageClose(logLevel);

  return 0;
}


/**********************************************************************************************
 * DASSL with synchronous treating of when equation
 *   - without integrated ZeroCrossing method.
 *   + ZeroCrossing are handled outside DASSL.
 *   + if no event occurs outside DASSL performs a warm-start
 **********************************************************************************************/
int dassl_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH
  double tout = 0;
  int i = 0;
  unsigned int ui = 0;
  int retVal = 0;
  int saveJumpState;
  static unsigned int dasslStepsOutputCounter = 1;

  DASSL_DATA *dasslData = (DASSL_DATA*) solverInfo->solverData;

  SIMULATION_DATA *sData = data->localData[0];
  SIMULATION_DATA *sDataOld = data->localData[1];

  modelica_real* states = sData->realVars;
  modelica_real* stateDer = dasslData->stateDer;


  MODEL_DATA *mData = (MODEL_DATA*) data->modelData;

  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  memcpy(stateDer, data->localData[1]->realVars + data->modelData->nStates, sizeof(double)*data->modelData->nStates);

  dasslData->rpar[0] = (double*) (void*) data;
  dasslData->rpar[1] = (double*) (void*) dasslData;
  dasslData->rpar[2] = (double*) (void*) threadData;

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  assertStreamPrint(threadData, 0 != dasslData->rpar, "could not passed to DDASKR");

  /* If an event is triggered and processed restart dassl. */
  if(!dasslData->dasslAvoidEventRestart && (solverInfo->didEventStep || 0 == dasslData->idid))
  {
    debugStreamPrint(LOG_EVENTS_V, 0, "Event-management forced reset of DDASKR");
    /* obtain reset */
    dasslData->info[0] = 0;
    dasslData->idid = 0;

  }

  /* Calculate steps until TOUT is reached */
  if (dasslData->dasslSteps)
  {
    /* If dasslsteps is selected, the dassl run to stopTime or next sample event */
    if (data->simulationInfo->nextSampleEvent < data->simulationInfo->stopTime)
    {
      tout = data->simulationInfo->nextSampleEvent;
    }
    else
    {
      tout = data->simulationInfo->stopTime;
    }
  }
  else
  {
    tout = solverInfo->currentTime + solverInfo->currentStepSize;
  }

  /* Check that tout is not less than timeValue
   * else will dassl get in trouble. If that is the case we skip the current step. */
  if (solverInfo->currentStepSize < DASSL_STEP_EPS)
  {
    infoStreamPrint(LOG_DASSL, 0, "Desired step to small try next one");
    infoStreamPrint(LOG_DASSL, 0, "Interpolate linear");

    /*euler step*/
    for(i = 0; i < data->modelData->nStates; i++)
    {
      sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
    }
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    data->callback->functionODE(data, threadData);
    solverInfo->currentTime = sData->timeValue;

    TRACE_POP
    return 0;
  }

  do
  {
    infoStreamPrint(LOG_DASSL, 1, "new step at time = %.15g", solverInfo->currentTime);

    /* rhs final flag is FALSE during for dassl evaluation */
    RHSFinalFlag = 0;

    if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

    DDASKR(dasslData->residualFunction, (int*) &dasslData->N,
            &solverInfo->currentTime, states, stateDer, &tout,
            dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
            dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
            (double*) (void*) dasslData->rpar, dasslData->ipar, callJacobian, dummy_precondition,
            dasslData->zeroCrossingFunction, (int*) &dasslData->ng, dasslData->jroot);

    /* closing new step message */
    messageClose(LOG_DASSL);

    /* set ringbuffer time to current time */
    sData->timeValue = solverInfo->currentTime;

    /* rhs final flag is TRUE during for output evaluation */
    RHSFinalFlag = 1;

    if(dasslData->idid == -1)
    {
      fflush(stderr);
      fflush(stdout);
      warningStreamPrint(LOG_DASSL, 0, "A large amount of work has been expended.(About 500 steps). Trying to continue ...");
      infoStreamPrint(LOG_DASSL, 0, "DASSL will try again...");
      dasslData->info[0] = 1; /* try again */
      if (solverInfo->currentTime <= data->simulationInfo->stopTime)
        continue;
    }
    else if(dasslData->idid < 0)
    {
      fflush(stderr);
      fflush(stdout);
      retVal = continue_DASSL(&dasslData->idid, &data->simulationInfo->tolerance);
      warningStreamPrint(LOG_STDOUT, 0, "can't continue. time = %f", sData->timeValue);
      TRACE_POP
      break;
    }
    else if(dasslData->idid == 5)
    {
      threadData->currentErrorStage = ERROR_EVENTSEARCH;
    }

    /* emit step, if dasslsteps is selected */
    if (dasslData->dasslSteps)
    {
      if (omc_flag[FLAG_NOEQUIDISTANT_OUT_FREQ]){
        /* output every n-th time step */
        if (dasslStepsOutputCounter >= dasslData->dasslStepsFreq){
          dasslStepsOutputCounter = 1; /* next line set it to one */
          break;
        }
        dasslStepsOutputCounter++;
      } else if (omc_flag[FLAG_NOEQUIDISTANT_OUT_TIME]){
        /* output when time>=k*timeValue */
        if (solverInfo->currentTime > dasslStepsOutputCounter * dasslData->dasslStepsTime){
          dasslStepsOutputCounter++;
          break;
        }
      } else {
        break;
      }
    }

  } while(dasslData->idid == 1);

  states = dasslData->states;

#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
  threadData->currentErrorStage = saveJumpState;

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }


  if(ACTIVE_STREAM(LOG_DASSL))
  {
    infoStreamPrint(LOG_DASSL, 1, "dassl call statistics: ");
    infoStreamPrint(LOG_DASSL, 0, "value of idid: %d", (int)dasslData->idid);
    infoStreamPrint(LOG_DASSL, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_DASSL, 0, "current integration time value: %0.4g", dasslData->rwork[3]);
    infoStreamPrint(LOG_DASSL, 0, "step size H to be attempted on next step: %0.4g", dasslData->rwork[2]);
    infoStreamPrint(LOG_DASSL, 0, "step size used on last successful step: %0.4g", dasslData->rwork[6]);
    infoStreamPrint(LOG_DASSL, 0, "the order of the method used on the last step: %d", dasslData->iwork[7]);
    infoStreamPrint(LOG_DASSL, 0, "the order of the method to be attempted on the next step: %d", dasslData->iwork[8]);
    infoStreamPrint(LOG_DASSL, 0, "number of steps taken so far: %d", (int)dasslData->iwork[10]);
    infoStreamPrint(LOG_DASSL, 0, "number of calls of functionODE() : %d", (int)dasslData->iwork[11]);
    infoStreamPrint(LOG_DASSL, 0, "number of calculation of jacobian : %d", (int)dasslData->iwork[12]);
    infoStreamPrint(LOG_DASSL, 0, "total number of convergence test failures: %d", (int)dasslData->iwork[13]);
    infoStreamPrint(LOG_DASSL, 0, "total number of error test failures: %d", (int)dasslData->iwork[14]);
    messageClose(LOG_DASSL);
  }

  /* save dassl stats */
  for(ui = 0; ui < numStatistics; ui++)
  {
    assert(10 + ui < dasslData->liw);
    solverInfo->solverStatsTmp[ui] = dasslData->iwork[10 + ui];
  }

  infoStreamPrint(LOG_DASSL, 0, "Finished DASSL step.");
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);

  TRACE_POP
  return retVal;
}

static int
continue_DASSL(int* idid, double* atol)
{
  TRACE_PUSH
  int retValue = -1;

  switch(*idid)
  {
  case 1:
  case 2:
  case 3:
    /* 1-4 means success */
    break;
  case -1:
    warningStreamPrint(LOG_DASSL, 0, "A large amount of work has been expended.(About 500 steps). Trying to continue ...");
    retValue = 1; /* adrpo: try to continue */
    break;
  case -2:
    warningStreamPrint(LOG_STDOUT, 0, "The error tolerances are too stringent");
    retValue = -2;
    break;
  case -3:
    /* wbraun: don't throw at this point let the solver handle it */
    /* throwStreamPrint("DDASKR: THE LAST STEP TERMINATED WITH A NEGATIVE IDID value"); */
    retValue = -3;
    break;
  case -6:
    warningStreamPrint(LOG_STDOUT, 0, "DDASSL had repeated error test failures on the last attempted step.");
    retValue = -6;
    break;
  case -7:
    warningStreamPrint(LOG_STDOUT, 0, "The corrector could not converge.");
    retValue = -7;
    break;
  case -8:
    warningStreamPrint(LOG_STDOUT, 0, "The matrix of partial derivatives is singular.");
    retValue = -8;
    break;
  case -9:
    warningStreamPrint(LOG_STDOUT, 0, "The corrector could not converge. There were repeated error test failures in this step.");
    retValue = -9;
    break;
  case -10:
    warningStreamPrint(LOG_STDOUT, 0, "A Modelica assert prevents the integrator to continue. For more information use -lv LOG_SOLVER");
    retValue = -10;
    break;
  case -11:
    warningStreamPrint(LOG_STDOUT, 0, "IRES equal to -2 was encountered and control is being returned to the calling program.");
    retValue = -11;
    break;
  case -12:
    warningStreamPrint(LOG_STDOUT, 0, "DDASSL failed to compute the initial YPRIME.");
    retValue = -12;
    break;
  case -33:
    warningStreamPrint(LOG_STDOUT, 0, "The code has encountered trouble from which it cannot recover.");
    retValue = -33;
    break;
  }

  TRACE_POP
  return retValue;
}


int functionODE_residual(double *t, double *y, double *yd, double* cj, double *delta,
                    int *ires, double *rpar, int *ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)((double**)rpar)[2];

  double timeBackup;
  long i;
  int saveJumpState;
  int success = 0;

  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  if (measure_time_flag) rt_tick(SIM_TIMER_RESIDUALS);

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, t, CONTEXT_ODE);
  }
  printCurrentStatesVector(LOG_DASSL_STATES, y, data, *t);
  printVector(LOG_DASSL_STATES, "yd", yd, data->modelData->nStates, *t);

  timeBackup = data->localData[0]->timeValue;
  data->localData[0]->timeValue = *t;

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);

  /* eval input vars */
  data->callback->functionODE(data, threadData);

  /* get the difference between the temp_xd(=localData->statesDerivatives)
     and xd(=statesDerivativesBackup) */
  for(i=0; i < data->modelData->nStates; i++)
  {
    delta[i] = data->localData[0]->realVars[data->modelData->nStates + i] - yd[i];
  }
  printVector(LOG_DASSL_STATES, "dd", delta, data->modelData->nStates, *t);
  success = 1;
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success) {
    *ires = -1;
  }

  threadData->currentErrorStage = saveJumpState;

  data->localData[0]->timeValue = timeBackup;

  if (data->simulationInfo->currentContext == CONTEXT_ODE){
    unsetContext(data);
  }

  if (measure_time_flag) rt_accumulate(SIM_TIMER_RESIDUALS);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  TRACE_POP
  return 0;
}

int function_ZeroCrossingsDASSL(int *neqm, double *t, double *y, double *yp,
        int *ng, double *gout, double *rpar, int* ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];

  double timeBackup;
  int saveJumpState;

  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  if (measure_time_flag) rt_tick(SIM_TIMER_EVENT);

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, t, CONTEXT_EVENTS);
  }

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_EVENTSEARCH;

  timeBackup = data->localData[0]->timeValue;
  data->localData[0]->timeValue = *t;

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

  if (measure_time_flag) rt_accumulate(SIM_TIMER_EVENT);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  TRACE_POP
  return 0;
}

/* \fn jacA_symColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar)
 *
 *
 * This function calculates symbolically the jacobian matrix and exploiting the coloring.
 */
int jacA_symColored(double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, int *ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];

  const int index = data->callback->INDEX_JAC_A;
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);

  unsigned int i,j,l,k,ii;

  /* set symbolical jacobian to reuse the matrix A and the factorization
   * in the Linear loops of  functionJacA_column */
  setContext(data, t, CONTEXT_SYM_JACOBIAN);

  for(i=0; i < jacobian->sparsePattern.maxColors; i++)
  {
    for(ii=0; ii < jacobian->sizeCols; ii++)
      if(jacobian->sparsePattern.colorCols[ii]-1 == i)
        jacobian->seedVars[ii] = 1;

    data->callback->functionJacA_column(data, threadData, jacobian, NULL);

    increaseJacContext(data);

    for(j = 0; j < jacobian->sizeCols; j++)
    {
      if(jacobian->seedVars[j] == 1)
      {
        ii = jacobian->sparsePattern.leadindex[j];
        while(ii < jacobian->sparsePattern.leadindex[j+1])
        {
          l  = jacobian->sparsePattern.index[ii];
          k  = j*jacobian->sizeRows + l;
          matrixA[k] = jacobian->resultVars[l];
          ii++;
        };
      }
    }
    for(ii=0; ii < jacobian->sizeCols; ii++)
      if(jacobian->sparsePattern.colorCols[ii]-1 == i) jacobian->seedVars[ii] = 0;

  }

  TRACE_POP
  return 0;
}

/* \fn jacA_sym(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar)
 *
 *
 * This function calculates symbolically the jacobian matrix.
 */
int jacA_sym(double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, int *ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];

  const int index = data->callback->INDEX_JAC_A;
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);

  unsigned int i,j,k;

  /* set symbolical jacobian to reuse the matrix A and the factorization
   * in the Linear loops of  functionJacA_column */
  setContext(data, t, CONTEXT_SYM_JACOBIAN);

  k = 0;
  for(i=0; i < jacobian->sizeCols; i++)
  {
   jacobian->seedVars[i] = 1.0;

    data->callback->functionJacA_column(data, threadData, jacobian, NULL);

    increaseJacContext(data);

    for(j = 0; j < jacobian->sizeRows; j++)
    {
      matrixA[i*jacobian->sizeCols+j] = jacobian->resultVars[j];
    }

    jacobian->seedVars[i] = 0.0;
  }

  TRACE_POP
  return 0;
}

/* \fn jacA_num(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar)
 *
 *
 * This function calculates a jacobian matrix by
 * numerical with forward finite differences.
 */
int jacA_num(double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, int *ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];

  double delta_h = numericalDifferentiationDeltaXsolver;
  double delta_hh,delta_hhh, deltaInv;
  double ysave;
  double ypsave;
  int ires;
  int i,j;

  /* set context for the start values extrapolation of non-linear algebraic loops */
  setContext(data, t, CONTEXT_JACOBIAN);

  for(i=dasslData->N-1; i >= 0; i--)
  {
    delta_hhh = *h * yprime[i];
    delta_hh = delta_h * fmax(fmax(fabs(y[i]),fabs(delta_hhh)),fabs(1. / wt[i]));
    delta_hh = (delta_hhh >= 0 ? delta_hh : -delta_hh);
    delta_hh = y[i] + delta_hh - y[i];
    deltaInv = 1. / delta_hh;
    ysave = y[i];
    y[i] += delta_hh;

    /* internal dassl numerical jacobian is
     * calculated by adding cj to yprime.
     * This lead to numerical cancellations.
     */
    /*yprime[i] += *cj * delta_hh;*/

    (*dasslData->residualFunction)(t, y, yprime, cj, dasslData->newdelta, &ires, rpar, ipar);

    increaseJacContext(data);

    for(j = dasslData->N-1; j >= 0 ; j--)
    {
      matrixA[i*dasslData->N+j] = (dasslData->newdelta[j] - delta[j]) * deltaInv;
    }
    y[i] = ysave;
  }

  TRACE_POP
  return 0;
}

/* \fn jacA_numColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar)
 *
 *
 * This function calculates a jacobian matrix by
 * numerical with forward finite differences and exploiting the coloring.
 */
int jacA_numColored(double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, int *ipar)
{
  TRACE_PUSH

  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];

  const int index = data->callback->INDEX_JAC_A;
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);

  double delta_h = numericalDifferentiationDeltaXsolver;
  double delta_hhh;
  int ires;
  double* delta_hh = dasslData->delta_hh;
  double* ysave = dasslData->ysave;
  double* ypsave = dasslData->ypsave;

  unsigned int i,j,l,k,ii;

  /* set context for the start values extrapolation of non-linear algebraic loops */
  setContext(data, t, CONTEXT_JACOBIAN);

  for(i = 0; i < jacobian->sparsePattern.maxColors; i++)
  {
    for(ii=0; ii < jacobian->sizeCols; ii++)
    {
      if(jacobian->sparsePattern.colorCols[ii]-1 == i)
      {
        delta_hhh = *h * yprime[ii];
        delta_hh[ii] = delta_h * fmax(fmax(fabs(y[ii]),fabs(delta_hhh)),fabs(1./wt[ii]));
        delta_hh[ii] = (delta_hhh >= 0 ? delta_hh[ii] : -delta_hh[ii]);
        delta_hh[ii] = y[ii] + delta_hh[ii] - y[ii];

        ysave[ii] = y[ii];
        y[ii] += delta_hh[ii];

        delta_hh[ii] = 1. / delta_hh[ii];
      }
    }

    (*dasslData->residualFunction)(t, y, yprime, cj, dasslData->newdelta, &ires, rpar, ipar);

    increaseJacContext(data);

    for(ii = 0; ii < jacobian->sizeCols; ii++)
    {
      if(jacobian->sparsePattern.colorCols[ii]-1 == i)
      {
        j = jacobian->sparsePattern.leadindex[ii];
        while(j < jacobian->sparsePattern.leadindex[ii+1])
        {
          l  =  jacobian->sparsePattern.index[j];
          k  = l + ii*jacobian->sizeRows;
          matrixA[k] = (dasslData->newdelta[l] - delta[l]) * delta_hh[ii];
          j++;
        };
        y[ii] = ysave[ii];
      }
    }
  }

  TRACE_POP
  return 0;
}

/* \fn callJacobian(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar)
 *
 *
 * This function is called by dassl to calculate the jacobian matrix.
 *
 */
static int callJacobian(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];

  /* profiling */
  if (measure_time_flag) rt_accumulate(SIM_TIMER_SOLVER);
  rt_tick(SIM_TIMER_JACOBIAN);

  if(dasslData->jacobianFunction(t, y, yprime, deltaD, pd, cj, h, wt, rpar, ipar))
  {
    throwStreamPrint(threadData, "Error, can not get Matrix A ");
    TRACE_POP
    return 1;
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_JAC)){
    _omc_matrix* dumpJac = _omc_createMatrix(dasslData->N, dasslData->N, pd);
    _omc_printMatrix(dumpJac, "DASSL-Solver: Matrix A", LOG_JAC);
    _omc_destroyMatrix(dumpJac);
  }

  int i,j = 0;
  for(i = 0; i < dasslData->N; i++)
  {
    pd[j] -= (double) *cj;
    j += dasslData->N + 1;
  }
  /* set context for the start values extrapolation of non-linear algebraic loops */
  unsetContext(data);

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
  if (measure_time_flag) rt_tick(SIM_TIMER_SOLVER);

  TRACE_POP
  return 0;
}

#ifdef __cplusplus
}
#endif

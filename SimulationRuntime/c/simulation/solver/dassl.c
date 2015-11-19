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
#include "util/memory_pool.h"

#include "simulation/options.h"
#include "simulation/simulation_runtime.h"
#include "simulation/results/simulation_result.h"
#include "simulation/solver/solver_main.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/external_input.h"
#include "simulation/solver/epsilon.h"

#include "simulation/solver/dassl.h"
#include "meta/meta_modelica.h"

#ifdef __cplusplus
extern "C" {
#endif

static const char *dasslJacobianMethodStr[DASSL_JAC_MAX] = {"unknown",
                                                "coloredNumerical",
                                                "coloredSymbolical",
                                                "internalNumerical",
                                                "symbolical",
                                                "numerical"
                                                };

static const char *dasslJacobianMethodDescStr[DASSL_JAC_MAX] = {"unknown",
                                                       "colored numerical jacobian - default.",
                                                       "colored symbolic jacobian - needs omc compiler flags +generateSymbolicJacobian or +generateSymbolicLinearization.",
                                                       "internal numerical jacobian."
                                                       "symbolic jacobian - needs omc compiler flags +generateSymbolicJacobian or +generateSymbolicLinearization.",
                                                       "numerical jacobian."
                                                      };

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

static int JacobianSymbolic(double *t, double *y, double *yprime,  double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, int* ipar);
static int JacobianSymbolicColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, int* ipar);
static int JacobianOwnNum(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, int* ipar);
static int JacobianOwnNumColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
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
  SIMULATION_DATA tmpSimData = {0};

  RHSFinalFlag = 0;

  dasslData->liw = 40 + data->modelData.nStates;
  dasslData->lrw = 60 + ((maxOrder + 4) * data->modelData.nStates) + (data->modelData.nStates * data->modelData.nStates)  + (3*data->modelData.nZeroCrossings);
  dasslData->rwork = (double*) calloc(dasslData->lrw, sizeof(double));
  assertStreamPrint(threadData, 0 != dasslData->rwork,"out of memory");
  dasslData->iwork = (int*)  calloc(dasslData->liw, sizeof(int));
  assertStreamPrint(threadData, 0 != dasslData->iwork,"out of memory");
  dasslData->ng = (int) data->modelData.nZeroCrossings;
  dasslData->jroot = (int*)  calloc(data->modelData.nZeroCrossings, sizeof(int));
  dasslData->rpar = (double**) malloc(3*sizeof(double*));
  dasslData->ipar = (int*) malloc(sizeof(int));
  dasslData->ipar[0] = ACTIVE_STREAM(LOG_JAC);
  assertStreamPrint(threadData, 0 != dasslData->ipar,"out of memory");
  dasslData->atol = (double*) malloc(data->modelData.nStates*sizeof(double));
  dasslData->rtol = (double*) malloc(data->modelData.nStates*sizeof(double));
  dasslData->info = (int*) calloc(infoLength, sizeof(int));
  assertStreamPrint(threadData, 0 != dasslData->info,"out of memory");
  dasslData->dasslStatistics = (unsigned int*) calloc(numStatistics, sizeof(unsigned int));
  assertStreamPrint(threadData, 0 != dasslData->dasslStatistics,"out of memory");
  dasslData->dasslStatisticsTmp = (unsigned int*) calloc(numStatistics, sizeof(unsigned int));
  assertStreamPrint(threadData, 0 != dasslData->dasslStatisticsTmp,"out of memory");

  dasslData->idid = 0;

  dasslData->sqrteps = sqrt(DBL_EPSILON);
  dasslData->ysave = (double*) malloc(data->modelData.nStates*sizeof(double));
  dasslData->delta_hh = (double*) malloc(data->modelData.nStates*sizeof(double));
  dasslData->newdelta = (double*) malloc(data->modelData.nStates*sizeof(double));
  dasslData->stateDer = (double*) malloc(data->modelData.nStates*sizeof(double));

  data->simulationInfo.currentContext = CONTEXT_ALGEBRAIC;

  /* setup internal ring buffer for dassl */

  /* RingBuffer */
  dasslData->simulationData = 0;
  dasslData->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));
  if(!data->simulationData)
  {
    throwStreamPrint(threadData, "Your memory is not strong enough for our Ringbuffer!");
  }

  /* prepare RingBuffer */
  for(i=0; i<SIZERINGBUFFER; i++)
  {
    /* set time value */
    tmpSimData.timeValue = 0;
    /* buffer for all variable values */
    tmpSimData.realVars = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
    assertStreamPrint(threadData, 0 != tmpSimData.realVars, "out of memory");
    tmpSimData.integerVars = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
    assertStreamPrint(threadData, 0 != tmpSimData.integerVars, "out of memory");
    tmpSimData.booleanVars = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
    assertStreamPrint(threadData, 0 != tmpSimData.booleanVars, "out of memory");
    tmpSimData.stringVars = (modelica_string*) GC_malloc_uncollectable(data->modelData.nVariablesString * sizeof(modelica_string));
    assertStreamPrint(threadData, 0 != tmpSimData.stringVars, "out of memory");
    appendRingData(dasslData->simulationData, &tmpSimData);
  }
  dasslData->localData = (SIMULATION_DATA**) GC_malloc_uncollectable(SIZERINGBUFFER * sizeof(SIMULATION_DATA));
  memset(dasslData->localData, 0, SIZERINGBUFFER * sizeof(SIMULATION_DATA));
  rotateRingBuffer(dasslData->simulationData, 0, (void**) dasslData->localData);

  /* end setup internal ring buffer for dassl */

  /* ### start configuration of dassl ### */
  infoStreamPrint(LOG_SOLVER, 1, "Configuration of the dassl code:");



  /* set nominal values of the states for absolute tolerances */
  dasslData->info[1] = 1;
  infoStreamPrint(LOG_SOLVER, 1, "The relative tolerance is %g. Following absolute tolerances are used for the states: ", data->simulationInfo.tolerance);
  for(i=0; i<data->modelData.nStates; ++i)
  {
    dasslData->rtol[i] = data->simulationInfo.tolerance;
    dasslData->atol[i] = data->simulationInfo.tolerance * fmax(fabs(data->modelData.realVarsData[i].attribute.nominal), 1e-32);
    infoStreamPrint(LOG_SOLVER, 0, "%d. %s -> %g", i+1, data->modelData.realVarsData[i].info.name, dasslData->atol[i]);
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

  /* if FLAG_DASSL_JACOBIAN is set, choose dassl jacobian calculation method */
  if (omc_flag[FLAG_DASSL_JACOBIAN])
  {
    for(i=1; i< DASSL_JAC_MAX;i++)
    {
      if(!strcmp((const char*)omc_flagValue[FLAG_DASSL_JACOBIAN], dasslJacobianMethodStr[i])){
        dasslData->dasslJacobian = (int)i;
        break;
      }
    }
    if(dasslData->dasslJacobian == DASSL_JAC_UNKNOWN)
    {
      if (ACTIVE_WARNING_STREAM(LOG_SOLVER))
      {
        warningStreamPrint(LOG_SOLVER, 1, "unrecognized jacobian calculation method %s, current options are:", (const char*)omc_flagValue[FLAG_DASSL_JACOBIAN]);
        for(i=1; i < DASSL_JAC_MAX; ++i)
        {
          warningStreamPrint(LOG_SOLVER, 0, "%-15s [%s]", dasslJacobianMethodStr[i], dasslJacobianMethodDescStr[i]);
        }
        messageClose(LOG_SOLVER);
      }
      throwStreamPrint(threadData,"unrecognized jacobian calculation method %s", (const char*)omc_flagValue[FLAG_DASSL_JACOBIAN]);
    }
  /* default case colored numerical jacobian */
  }
  else
  {
    dasslData->dasslJacobian = DASSL_COLOREDNUMJAC;
  }


  /* selects the calculation method of the jacobian */
  if(dasslData->dasslJacobian == DASSL_COLOREDNUMJAC ||
     dasslData->dasslJacobian == DASSL_COLOREDSYMJAC ||
     dasslData->dasslJacobian == DASSL_NUMJAC ||
     dasslData->dasslJacobian == DASSL_SYMJAC)
  {
    if (data->callback->initialAnalyticJacobianA(data, threadData))
    {
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
      dasslData->dasslJacobian = DASSL_INTERNALNUMJAC;
    }
    else
    {
      dasslData->info[4] = 1; /* use sub-routine JAC */
    }
  }
  /* set up the appropriate function pointer */
  switch (dasslData->dasslJacobian){
    case DASSL_COLOREDNUMJAC:
      data->simulationInfo.jacobianEvals = data->simulationInfo.analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern.maxColors;
      dasslData->jacobianFunction =  JacobianOwnNumColored;
      break;
    case DASSL_COLOREDSYMJAC:
      data->simulationInfo.jacobianEvals = data->simulationInfo.analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern.maxColors;
      dasslData->jacobianFunction =  JacobianSymbolicColored;
      break;
    case DASSL_SYMJAC:
      dasslData->jacobianFunction =  JacobianSymbolic;
      break;
    case DASSL_NUMJAC:
      dasslData->jacobianFunction =  JacobianOwnNum;
      break;
    case DASSL_INTERNALNUMJAC:
      dasslData->jacobianFunction =  dummy_Jacobian;
      break;
    default:
      throwStreamPrint(threadData,"unrecognized jacobian calculation method %s", (const char*)omc_flagValue[FLAG_DASSL_JACOBIAN]);
      break;
  }
  infoStreamPrint(LOG_SOLVER, 0, "jacobian is calculated by %s", dasslJacobianMethodDescStr[dasslData->dasslJacobian]);


  /* if FLAG_DASSL_NO_ROOTFINDING is set, choose dassl with out internal root finding */
  if(omc_flag[FLAG_DASSL_NO_ROOTFINDING])
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


  /* if FLAG_DASSL_NO_RESTART is set, choose dassl step method */
  if (omc_flag[FLAG_DASSL_NO_RESTART])
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
  free(dasslData->stateDer);
  free(dasslData->dasslStatistics);
  free(dasslData->dasslStatisticsTmp);

  for(i=0; i<SIZERINGBUFFER; i++){
    SIMULATION_DATA* tmpSimData = (SIMULATION_DATA*) dasslData->localData[i];
    /* free buffer for all variable values */
    free(tmpSimData->realVars);
    free(tmpSimData->integerVars);
    free(tmpSimData->booleanVars);
    GC_free(tmpSimData->stringVars);
  }
  GC_free(dasslData->localData);
  freeRingBuffer(dasslData->simulationData);

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
  for(i=0;i<data->modelData.nStates;++i)
  {
    infoStreamPrint(logLevel, 0, "%d. %s = %g", i+1, data->modelData.realVarsData[i].info.name, states[i]);
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

  RINGBUFFER *ringBufferBackup = data->simulationData;
  SIMULATION_DATA **localDataBackup = data->localData;

  SIMULATION_DATA *sData = data->localData[0];
  SIMULATION_DATA *sDataOld = data->localData[1];

  MODEL_DATA *mData = (MODEL_DATA*) &data->modelData;

  modelica_real* stateDer = dasslData->stateDer;

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

    copyRingBufferSimulationData(data, threadData, dasslData->localData, dasslData->simulationData);
    memcpy(stateDer, data->localData[1]->realVars + data->modelData.nStates, sizeof(double)*data->modelData.nStates);
  }

  /* Calculate steps until TOUT is reached */
  /* If dasslsteps is selected, the dassl run to stopTime */
  if (dasslData->dasslSteps)
  {
    /* rhs final flag is FALSE during dassl evaulation */
    RHSFinalFlag = 0;

    if (data->simulationInfo.nextSampleEvent < data->simulationInfo.stopTime)
    {
      tout = data->simulationInfo.nextSampleEvent;
    }
    else
    {
      tout = data->simulationInfo.stopTime;
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
    for(i = 0; i < data->modelData.nStates; i++)
    {
      sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
    }
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    data->callback->functionODE(data, threadData);
    solverInfo->currentTime = sData->timeValue;

    TRACE_POP
    return 0;
  }

  /* If dasslsteps is selected, we just use the outer ring buffer */
  if (!dasslData->dasslSteps)
  {
    data->simulationData = dasslData->simulationData;
    data->localData = dasslData->localData;
  }

  sData = (SIMULATION_DATA*) data->localData[0];

  infoStreamPrint(LOG_DASSL, 0, "Calling DASSL from %.15g to %.15g", solverInfo->currentTime, tout);
  do
  {
    infoStreamPrint(LOG_SOLVER, 0, "new step: time=%.15g", solverInfo->currentTime);
    if(dasslData->idid == 1)
    {
      /* rotate RingBuffer before step is calculated */
      rotateRingBuffer(data->simulationData, 1, (void**) data->localData);
      sData = (SIMULATION_DATA*) data->localData[0];
    }

    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);

    DDASKR(functionODE_residual, (int*) &mData->nStates,
            &solverInfo->currentTime, sData->realVars, stateDer, &tout,
            dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
            dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
            (double*) (void*) dasslData->rpar, dasslData->ipar, dasslData->jacobianFunction, dummy_precondition,
            dasslData->zeroCrossingFunction, (int*) &dasslData->ng, dasslData->jroot);

    /* set ringbuffer time to current time */
    sData->timeValue = solverInfo->currentTime;

    if(dasslData->idid == -1)
    {
      fflush(stderr);
      fflush(stdout);
      warningStreamPrint(LOG_DASSL, 0, "A large amount of work has been expended.(About 500 steps). Trying to continue ...");
      infoStreamPrint(LOG_DASSL, 0, "DASSL will try again...");
      dasslData->info[0] = 1; /* try again */
    }
    else if(dasslData->idid < 0)
    {
      fflush(stderr);
      fflush(stdout);
      retVal = continue_DASSL(&dasslData->idid, &data->simulationInfo.tolerance);
      /* take the states from the inner ring buffer to the outer one */
      memcpy(localDataBackup[0]->realVars, data->localData[0]->realVars, sizeof(double)*data->modelData.nStates);
      data->simulationData = ringBufferBackup;
      data->localData = localDataBackup;
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
      /* rhs final flag is TRUE during output evaulation */
      RHSFinalFlag = 1;

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
      RHSFinalFlag = 0;

    }
    else if (dasslData->idid == 1)
    {
      /* to be consistent we need to evaluate functionODE again,
       * since dassl does not evaluate functionODE with the freshest states.
       */
      data->callback->functionODE(data, threadData);
      data->callback->function_ZeroCrossingsEquations(data, threadData);
    }

  } while(dasslData->idid == 1 ||
          (dasslData->idid == -1 && solverInfo->currentTime <= data->simulationInfo.stopTime));

#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
  threadData->currentErrorStage = saveJumpState;


  if (!dasslData->dasslSteps)
  {
    /* take the states from the inner ring buffer to the outer one */
    memcpy(localDataBackup[0]->realVars, data->localData[0]->realVars, sizeof(double)*data->modelData.nStates);
    data->simulationData = ringBufferBackup;
    data->localData = localDataBackup;
    /* set ringbuffer time to current time */
    data->localData[0]->timeValue = solverInfo->currentTime;
  }
  else
  {
    if (data->simulationInfo.sampleActivated && solverInfo->currentTime < data->simulationInfo.nextSampleEvent)
      data->simulationInfo.sampleActivated = 0;
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
    dasslData->dasslStatisticsTmp[ui] = dasslData->iwork[10 + ui];
  }

  infoStreamPrint(LOG_DASSL, 0, "Finished DDASKR step.");

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

  if (data->simulationInfo.currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, t, CONTEXT_ODE);
  }
  printCurrentStatesVector(LOG_DASSL_STATES, y, data, *t);

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
  for(i=0; i < data->modelData.nStates; i++)
  {
    delta[i] = data->localData[0]->realVars[data->modelData.nStates + i] - yd[i];
  }
  success = 1;
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success) {
    *ires = -1;
  }

  threadData->currentErrorStage = saveJumpState;

  data->localData[0]->timeValue = timeBackup;

  if (data->simulationInfo.currentContext == CONTEXT_ODE){
    unsetContext(data);
  }

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

  if (data->simulationInfo.currentContext == CONTEXT_ALGEBRAIC)
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

  if (data->simulationInfo.currentContext == CONTEXT_EVENTS){
    unsetContext(data);
  }

  TRACE_POP
  return 0;
}


int functionJacAColored(DATA* data, threadData_t *threadData, double* jac)
{
  TRACE_PUSH
  const int index = data->callback->INDEX_JAC_A;
  unsigned int i,j,l,k,ii;

  for(i=0; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors; i++)
  {
    for(ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1;

    /*
    // debug output
    if(ACTIVE_STREAM((LOG_JAC | LOG_ENDJAC))){
      printf("Caluculate one col:\n");
      for(l=0;  l < data->simulationInfo.analyticJacobians[index].sizeCols;l++)
        infoStreamPrint((LOG_JAC | LOG_ENDJAC),"seed: data->simulationInfo.analyticJacobians[index].seedVars[%d]= %f",l,data->simulationInfo.analyticJacobians[index].seedVars[l]);
    }
    */

    data->callback->functionJacA_column(data, threadData);

    for(j = 0; j < data->simulationInfo.analyticJacobians[index].sizeCols; j++)
    {
      if(data->simulationInfo.analyticJacobians[index].seedVars[j] == 1)
      {
        if(j==0)
          ii = 0;
        else
          ii = data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j-1];
        while(ii < data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j])
        {
          l  = data->simulationInfo.analyticJacobians[index].sparsePattern.index[ii];
          k  = j*data->simulationInfo.analyticJacobians[index].sizeRows + l;
          jac[k] = data->simulationInfo.analyticJacobians[index].resultVars[l];
          /*infoStreamPrint((LOG_JAC | LOG_ENDJAC),"write %d. in jac[%d]-[%d,%d]=%f from col[%d]=%f",ii,k,l,j,jac[k],l,data->simulationInfo.analyticJacobians[index].resultVars[l]);*/
          ii++;
        };
      }
    }
    for(ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i) data->simulationInfo.analyticJacobians[index].seedVars[ii] = 0;

    /*
   // debug output
    if(ACTIVE_STREAM((LOG_JAC | LOG_ENDJAC))){
      infoStreamPrint("Print jac:");
      for(l=0;  l < data->simulationInfo.analyticJacobians[index].sizeCols;l++)
      {
        for(k=0;  k < data->simulationInfo.analyticJacobians[index].sizeRows;k++)
          printf("% .5e ",jac[l+k*data->simulationInfo.analyticJacobians[index].sizeRows]);
        printf("\n");
      }
    }
    */
  }

  TRACE_POP
  return 0;
}


int functionJacASym(DATA* data, threadData_t *threadData, double* jac)
{
  TRACE_PUSH
  const int index = data->callback->INDEX_JAC_A;
  unsigned int i,j,k;

  k = 0;
  for(i=0; i < data->simulationInfo.analyticJacobians[index].sizeCols; i++)
  {
    data->simulationInfo.analyticJacobians[index].seedVars[i] = 1.0;

    /*
    // debug output
    if(ACTIVE_STREAM((LOG_JAC | LOG_ENDJAC)))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < data->simulationInfo.analyticJacobians[index].sizeCols;j++)
        infoStreamPrint((LOG_JAC | LOG_ENDJAC),"seed: data->simulationInfo.analyticJacobians[index].seedVars[%d]= %f",j,data->simulationInfo.analyticJacobians[index].seedVars[j]);
    }
    */

    data->callback->functionJacA_column(data, threadData);

    for(j = 0; j < data->simulationInfo.analyticJacobians[index].sizeRows; j++)
    {
      jac[k++] = data->simulationInfo.analyticJacobians[index].resultVars[j];
      /*infoStreamPrint((LOG_JAC | LOG_ENDJAC),"write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k,i,j,jac[k-1],j,data->simulationInfo.analyticJacobians[index].resultVars[j]);*/
    }

    data->simulationInfo.analyticJacobians[index].seedVars[i] = 0.0;
  }
  // debug output; would be optimized away if the code compiled
  /* if(DEBUG_STREAM(LOG_DEBUG))
  {
    infoStreamPrint("Print jac:");
    for(i=0;  i < data->simulationInfo.analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo.analyticJacobians[index].sizeCols;j++)
        printf("% .5e ",jac[i+j*data->simulationInfo.analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  } */

  TRACE_POP
  return 0;
}

/*
 * provides a analytical Jacobian to be used with DASSL
 */

static int JacobianSymbolicColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
         double *rpar, int* ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];
  double* backupStates;
  double timeBackup;
  int i;
  int j;

  setContext(data, t, CONTEXT_JACOBIAN);

  backupStates = data->localData[0]->realVars;
  timeBackup = data->localData[0]->timeValue;

  data->localData[0]->timeValue = *t;
  data->localData[0]->realVars = y;
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval ode*/
  data->callback->functionODE(data, threadData);
  functionJacAColored(data, threadData, pd);

  /* add cj to the diagonal elements of the matrix */
  j = 0;
  for(i = 0; i < data->modelData.nStates; i++)
  {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }
  data->localData[0]->realVars = backupStates;
  data->localData[0]->timeValue = timeBackup;

  unsetContext(data);

  TRACE_POP
  return 0;
}

/*
 * provides a analytical Jacobian to be used with DASSL
 */
static int JacobianSymbolic(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
         double *rpar, int* ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];
  double* backupStates;
  double timeBackup;
  int i;
  int j;

  setContext(data, t, CONTEXT_JACOBIAN);

  backupStates = data->localData[0]->realVars;
  timeBackup = data->localData[0]->timeValue;

  data->localData[0]->timeValue = *t;
  data->localData[0]->realVars = y;
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval ode*/
  data->callback->functionODE(data, threadData);
  functionJacASym(data, threadData, pd);

  /* add cj to the diagonal elements of the matrix */
  j = 0;
  for(i = 0; i < data->modelData.nStates; i++)
  {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }
  data->localData[0]->realVars = backupStates;
  data->localData[0]->timeValue = timeBackup;

  unsetContext(data);

  TRACE_POP
  return 0;
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
int jacA_num(DATA* data, double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, int *ipar)
{
  TRACE_PUSH
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];

  double delta_h = dasslData->sqrteps;
  double delta_hh,delta_hhh, deltaInv;
  double ysave;
  int ires;
  int i,j;


  for(i=data->modelData.nStates-1; i >= 0; i--)
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

    functionODE_residual(t, y, yprime, cj, dasslData->newdelta, &ires, rpar, ipar);

    for(j = data->modelData.nStates-1; j >= 0 ; j--)
    {
      matrixA[i*data->modelData.nStates+j] = (dasslData->newdelta[j] - delta[j]) * deltaInv;
    }
    y[i] = ysave;
  }

  /*
   * Debug output
  if(ACTIVE_STREAM(LOG_JAC))
  {
    infoStreamPrint(LOG_SOLVER, "Print jac:");
    for(i=0;  i < data->simulationInfo.analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo.analyticJacobians[index].sizeCols;j++)
        printf("%.20e ",matrixA[i+j*data->simulationInfo.analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  }
  */

  TRACE_POP
  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
static int JacobianOwnNum(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, int* ipar)
{
  TRACE_PUSH
  int i,j;
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];

  setContext(data, t, CONTEXT_JACOBIAN);

  if(jacA_num(data, t, y, yprime, deltaD, pd, cj, h, wt, rpar, ipar))
  {
    throwStreamPrint(threadData, "Error, can not get Matrix A ");
    TRACE_POP
    return 1;
  }
  j = 0;
  /* add cj to diagonal elements and store in pd */
  for(i = 0; i < data->modelData.nStates; i++)
  {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }
  unsetContext(data);

  TRACE_POP
  return 0;
}


/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
int jacA_numColored(DATA* data, double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, int *ipar)
{
  TRACE_PUSH
  const int index = data->callback->INDEX_JAC_A;
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  double delta_h = dasslData->sqrteps;
  double delta_hhh;
  int ires;
  double* delta_hh = dasslData->delta_hh;
  double* ysave = dasslData->ysave;

  unsigned int i,j,l,k,ii;

  for(i = 0; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors; i++)
  {
    for(ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
    {
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
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

    functionODE_residual(t, y, yprime, cj, dasslData->newdelta, &ires, rpar, ipar);

    increaseJacContext(data);

    for(ii = 0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
    {
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
      {
        if(ii==0)
          j = 0;
        else
          j = data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[ii-1];
        while(j < data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[ii])
        {
          l  =  data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
          k  = l + ii*data->simulationInfo.analyticJacobians[index].sizeRows;
          matrixA[k] = (dasslData->newdelta[l] - delta[l]) * delta_hh[ii];
          /*infoStreamPrint(ACTIVE_STREAM(LOG_JAC),"write %d. in jac[%d]-[%d,%d]=%e",ii,k,j,l,matrixA[k]);*/
          j++;
        };
        y[ii] = ysave[ii];
      }
    }
  }

  /*
   * Debug output
  if(ACTIVE_STREAM(LOG_JAC))
  {
    infoStreamPrint(LOG_SOLVER, "Print jac:");
    for(i=0;  i < data->simulationInfo.analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo.analyticJacobians[index].sizeCols;j++)
        printf("%.20e ",matrixA[i+j*data->simulationInfo.analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  }
  */

  TRACE_POP
  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
static int JacobianOwnNumColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, int* ipar)
{
  TRACE_PUSH
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  threadData_t *threadData = (threadData_t*)(void*)((double**)rpar)[2];
  int i,j;

  setContext(data, t, CONTEXT_JACOBIAN);

  if(jacA_numColored(data, t, y, yprime, deltaD, pd, cj, h, wt, rpar, ipar))
  {
    throwStreamPrint(threadData, "Error, can not get Matrix A ");
    TRACE_POP
    return 1;
  }

  /* add cj to diagonal elements and store in pd */
  j = 0;
  for(i = 0; i < data->modelData.nStates; i++)
  {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }
  unsetContext(data);

  TRACE_POP
  return 0;
}

#ifdef __cplusplus
}
#endif

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <string.h>
#include <setjmp.h>

#include "openmodelica.h"
#include "openmodelica_func.h"
#include "simulation_data.h"

#include "util/omc_error.h"
#include "util/memory_pool.h"

#include "simulation/simulation_runtime.h"
#include "simulation/solver/solver_main.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/external_input.h"
#include "simulation/solver/epsilon.h"

#include "simulation/solver/dassl.h"
#include "f2c.h"
#include "meta_modelica.h"


static const char *dasslMethodStr[DASSL_MAX] = {"unknown",
                                                "dassl",
                                                "dasslwort",
                                                "dasslSymJac",
                                                "dasslNumJac",
                                                "dasslColorSymJac",
                                                "dasslInternalNumJac",
                                                "dassltest"};

static const char *dasslMethodStrDescStr[DASSL_MAX] = {"unknown",
                                                       "dassl with colored numerical jacobian, with interval root finding",
                                                       "dassl without internal root finding",
                                                       "dassl with symbolic jacobian",
                                                       "dassl with numerical jacobian",
                                                       "dassl with colored symbolic jacobian",
                                                       "dassl with internal numerical jacobian",
                                                       "dassl for debug propose"};



/* provides a dummy Jacobian to be used with DASSL */
static int
dummy_Jacobian(double *t, double *y, double *yprime, double *deltaD,
    double *delta, double *cj, double *h, double *wt, double *rpar, fortran_integer* ipar) {
  return 0;
}
static int
dummy_zeroCrossing(fortran_integer *neqm, double *t, double *y, double *yp,
                   fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar) {
  return 0;
}

static int JacobianSymbolic(double *t, double *y, double *yprime,  double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, fortran_integer* ipar);
static int JacobianSymbolicColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, fortran_integer* ipar);
static int JacobianOwnNum(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, fortran_integer* ipar);
static int JacobianOwnNumColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, fortran_integer* ipar);

void  DDASKR(
    int (*res) (double *t, double *y, double *yprime, double* cj, double *delta, fortran_integer *ires, double *rpar, fortran_integer* ipar),
    fortran_integer *neq,
    double *t,
    double *y,
    double *yprime,
    double *tout,
    fortran_integer *info,
    double *rtol,
    double *atol,
    fortran_integer *idid,
    double *rwork,
    fortran_integer *lrw,
    fortran_integer *iwork,
    fortran_integer *liw,
    double *rpar,
    fortran_integer *ipar,
    int (*jac) (double *t, double *y, double *yprime, double *deltaD, double *delta, double *cj, double *h, double *wt, double *rpar, fortran_integer* ipar),
    int (*psol) (fortran_integer *neq, double *t, double *y, double *yprime, double *savr, double *pwk, double *cj, double *wt, double *wp, fortran_integer *iwp, double *b, double eplin, fortran_integer* ires, double *rpar, fortran_integer* ipar),
    int (*g) (fortran_integer *neqm, double *t, double *y, double *yp, fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar),
    fortran_integer *ng,
    fortran_integer *jroot
);

static int
dummy_precondition(fortran_integer *neq, double *t, double *y, double *yprime, double *savr, double *pwk, double *cj, double *wt, double *wp, fortran_integer *iwp, double *b, double eplin, fortran_integer* ires, double *rpar, fortran_integer* ipar){
    return 0;
}


static int
continue_DASSL(fortran_integer* idid, double* tolarence);



/* function for calculating state values on residual form */
static int functionODE_residual(double *t, double *x, double *xprime, double *cj, double *delta, fortran_integer *ires, double *rpar, fortran_integer* ipar);

/* function for calculating zeroCrossings */
static int function_ZeroCrossingsDASSL(fortran_integer *neqm, double *t, double *y, double *yp,
        fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar);

int
dassl_initial(DATA* simData, SOLVER_INFO* solverInfo, DASSL_DATA *dasslData){

  /* work arrays for DASSL */
  int i;
  SIMULATION_INFO *simInfo = &(simData->simulationInfo);

  dasslData->dasslMethod = 0;

  for(i=1; i< DASSL_MAX;i++) {
    if(!strcmp((const char*)simInfo->solverMethod, dasslMethodStr[i])){
      dasslData->dasslMethod = i;
      break;
    }
  }

  if(dasslData->dasslMethod == DASSL_UNKNOWN) {
    if (ACTIVE_WARNING_STREAM(LOG_SOLVER)) {
      warningStreamPrint(LOG_SOLVER, 1, "unrecognized solver method %s, current options are:", simInfo->solverMethod);
      for(i=1; i < DASSL_MAX; ++i) {
        warningStreamPrint(LOG_SOLVER, 0, "  %-15s [%s]", dasslMethodStr[i], dasslMethodStrDescStr[i]);
      }
      messageClose(LOG_SOLVER);
    }
    throwStreamPrint(simData->threadData,"unrecognized dassl solver method %s", simInfo->solverMethod);
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "| solver | Use solver method: %s\t%s",dasslMethodStr[dasslData->dasslMethod],dasslMethodStrDescStr[dasslData->dasslMethod]);
  }


  dasslData->liw = 40 + simData->modelData.nStates;
  dasslData->lrw = 60 + ((maxOrder + 4) * simData->modelData.nStates)
              + (simData->modelData.nStates * simData->modelData.nStates)  + (3*simData->modelData.nZeroCrossings);
  dasslData->rwork = (double*) calloc(dasslData->lrw, sizeof(double));
  assertStreamPrint(simData->threadData, 0 != dasslData->rwork,"out of memory");
  dasslData->iwork = (fortran_integer*)  calloc(dasslData->liw, sizeof(fortran_integer));
  assertStreamPrint(simData->threadData, 0 != dasslData->iwork,"out of memory");
  dasslData->ng = (fortran_integer) simData->modelData.nZeroCrossings;
  dasslData->ngdummy = (fortran_integer) 0;
  dasslData->jroot = (fortran_integer*)  calloc(simData->modelData.nZeroCrossings, sizeof(fortran_integer));
  dasslData->rpar = (double**) malloc(2*sizeof(double*));
  dasslData->ipar = (fortran_integer*) malloc(sizeof(fortran_integer));
  dasslData->ipar[0] = ACTIVE_STREAM(LOG_JAC);
  assertStreamPrint(simData->threadData, 0 != dasslData->ipar,"out of memory");
  dasslData->atol = (double*) malloc(simData->modelData.nStates*sizeof(double));
  dasslData->rtol = (double*) malloc(simData->modelData.nStates*sizeof(double));
  dasslData->info = (fortran_integer*) calloc(infoLength, sizeof(fortran_integer));
  assertStreamPrint(simData->threadData, 0 != dasslData->info,"out of memory");
  dasslData->dasslStatistics = (unsigned int*) calloc(numStatistics, sizeof(unsigned int));
  assertStreamPrint(simData->threadData, 0 != dasslData->dasslStatistics,"out of memory");
  dasslData->dasslStatisticsTmp = (unsigned int*) calloc(numStatistics, sizeof(unsigned int));
  assertStreamPrint(simData->threadData, 0 != dasslData->dasslStatisticsTmp,"out of memory");

  dasslData->idid = 0;

  dasslData->sqrteps = sqrt(DBL_EPSILON);
  dasslData->ysave = (double*) malloc(simData->modelData.nStates*sizeof(double));
  dasslData->delta_hh = (double*) malloc(simData->modelData.nStates*sizeof(double));
  dasslData->newdelta = (double*) malloc(simData->modelData.nStates*sizeof(double));


  dasslData->info[2] = 1;
  /*********************************************************************
   *info[3] = 1;  //go not past TSTOP
   *rwork[0] = stop;  //TSTOP
   *********************************************************************
   *info[6] = 1;  //prohibit code to decide max. stepsize on its own
   *rwork[1] = *step;  //define max. stepsize
   *********************************************************************/

  if(dasslData->dasslMethod == DASSL_SYMJAC ||
      dasslData->dasslMethod == DASSL_COLOREDSYMJAC ||
      dasslData->dasslMethod == DASSL_NUMJAC ||
      dasslData->dasslMethod == DASSL_WORT ||
      dasslData->dasslMethod == DASSL_RT ||
      dasslData->dasslMethod == DASSL_TEST){
    if (simData->callback->initialAnalyticJacobianA(simData)){
      /* TODO: check that the one states is dummy */
      if(simData->modelData.nStates == 1) {
        infoStreamPrint(LOG_SOLVER, 0, "No SparsePattern, since there are no states! Switch back to normal.");
      } else {
        infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
      }
      dasslData->dasslMethod = DASSL_INTERNALNUMJAC;
    }else{
      dasslData->info[4] = 1; /* use sub-routine JAC */
    }
  }

  if(dasslData->dasslMethod != DASSL_WORT)
    solverInfo->solverRootFinding = 1;

  /* Setup nominal values of the states
   * as relative tolerances */
  dasslData->info[1] = 1;
  for(i=0;i<simData->modelData.nStates;++i){
    dasslData->rtol[i] = simData->simulationInfo.tolerance;
    dasslData->atol[i] = simData->simulationInfo.tolerance * simData->modelData.realVarsData[i].attribute.nominal;
  }

  return 0;
}


int
dassl_deinitial(DASSL_DATA *dasslData){

  /* free work arrays for DASSL */
  free(dasslData->rwork);
  free(dasslData->iwork);
  free(dasslData->ipar);
  free(dasslData->info);
  free(dasslData->dasslStatistics);
  free(dasslData->dasslStatisticsTmp);
  free(dasslData);
  return 0;
}

/**********************************************************************************************
 * DASSL with synchronous treating of when equation
 *   - without integrated ZeroCrossing method.
 *   + ZeroCrossing are handled outside DASSL.
 *   + if no event occurs outside DASSL performs a warm-start
 **********************************************************************************************/
int dassl_step(DATA* simData, SOLVER_INFO* solverInfo)
{
  double tout = 0;
  int i = 0;
  unsigned int ui = 0;
  int retVal = 0;

  SIMULATION_DATA *sData = (SIMULATION_DATA*) simData->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*) simData->localData[1];
  MODEL_DATA *mData = (MODEL_DATA*) &simData->modelData;
  DASSL_DATA *dasslData = (DASSL_DATA*) solverInfo->solverData;
  modelica_real* stateDer = sDataOld->realVars + simData->modelData.nStates;
  dasslData->rpar[0] = (double*) (void*) simData;
  dasslData->rpar[1] = (double*) (void*) dasslData;
  assertStreamPrint(simData->threadData, 0 != dasslData->rpar, "could not passed to DDASKR");

  /* If an event is triggered and processed restart dassl. */
  if(solverInfo->didEventStep)
  {
    debugStreamPrint(LOG_EVENTS_V, 0, "Event-management forced reset of DDASKR");
    /* obtain reset */
    dasslData->info[0] = 0;
    dasslData->idid = 0;
  }

  /* Calculate time steps until TOUT is reached
   * (DASSL calculates beyond TOUT unless info[6] is set to 1!) */
  tout = solverInfo->currentTime + solverInfo->currentStepSize;

  /* Check that tout is not less than timeValue
   * else will dassl get in trouble. If that is the case we skip the current step. */
  if (solverInfo->currentStepSize < DASSL_STEP_EPS)
  {
    infoStreamPrint(LOG_DASSL, 0, "Desired step to small try next one");
    infoStreamPrint(LOG_DASSL, 0, "Interpolate linear");

    /*euler step*/
    for(i = 0; i < simData->modelData.nStates; i++)
    {
      sData->realVars[i] = sDataOld->realVars[i] + stateDer[i] * solverInfo->currentStepSize;
    }
    sData->timeValue = tout;
    simData->callback->functionODE(simData);
    solverInfo->currentTime = tout;

    /* TODO: interpolate states and evaluate the system again */
    return retVal;
  }

  infoStreamPrint(LOG_DASSL, 0, "Calling DASSL from %.15g to %.15g", solverInfo->currentTime, tout);
  do
  {
    infoStreamPrint(LOG_SOLVER, 0, "Start step %.15g to %.15g", solverInfo->currentTime, tout);
    if(dasslData->idid == 1)
    {
      /* rotate RingBuffer before step is calculated */
      rotateRingBuffer(simData->simulationData, 1, (void**) simData->localData);
      sData = (SIMULATION_DATA*) simData->localData[0];
      sDataOld = (SIMULATION_DATA*) simData->localData[1];
      stateDer = sDataOld->realVars + mData->nStates;
      sData->timeValue = solverInfo->currentTime;
    }

    /* read input vars */
    externalInputUpdate(simData);
    simData->callback->input_function(simData);

    if(dasslData->dasslMethod ==  DASSL_SYMJAC) {
      DDASKR(functionODE_residual, &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          (double*) (void*) dasslData->rpar, dasslData->ipar, JacobianSymbolic, dummy_precondition,
          function_ZeroCrossingsDASSL, (fortran_integer*) &dasslData->ng, dasslData->jroot);
    } else if(dasslData->dasslMethod ==  DASSL_NUMJAC) {
      DDASKR(functionODE_residual, &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          (double*) (void*) dasslData->rpar, dasslData->ipar, JacobianOwnNum, dummy_precondition,
          function_ZeroCrossingsDASSL,(fortran_integer*) &dasslData->ng, dasslData->jroot);
    } else if(dasslData->dasslMethod ==  DASSL_COLOREDSYMJAC) {
      DDASKR(functionODE_residual, &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          (double*) (void*) dasslData->rpar, dasslData->ipar, JacobianSymbolicColored, dummy_precondition,
          function_ZeroCrossingsDASSL, (fortran_integer*) &dasslData->ng, dasslData->jroot);
    } else if(dasslData->dasslMethod ==  DASSL_INTERNALNUMJAC) {
      DDASKR(functionODE_residual, &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          (double*) (void*) dasslData->rpar, dasslData->ipar, dummy_Jacobian, dummy_precondition,
          function_ZeroCrossingsDASSL, (fortran_integer*) &dasslData->ng, dasslData->jroot);
    } else if(dasslData->dasslMethod ==  DASSL_TEST) {
      DDASKR(functionODE_residual, &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          (double*) (void*) dasslData->rpar, dasslData->ipar, JacobianOwnNumColored, dummy_precondition,
          dummy_zeroCrossing, &dasslData->ngdummy, NULL);
    } else if(dasslData->dasslMethod ==  DASSL_WORT) {
      DDASKR(functionODE_residual, &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          (double*) (void*)dasslData->rpar, dasslData->ipar, JacobianOwnNumColored,  dummy_precondition,
          dummy_zeroCrossing, &dasslData->ngdummy, NULL);
    } else {
      DDASKR(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          (double*) (void*) dasslData->rpar, dasslData->ipar, JacobianOwnNumColored,  dummy_precondition,
          function_ZeroCrossingsDASSL, (fortran_integer*) &dasslData->ng, dasslData->jroot);
    }

    if(dasslData->idid == -1) {
      fflush(stderr);
      fflush(stdout);
      warningStreamPrint(LOG_DASSL, 0, "A large amount of work has been expended.(About 500 steps). Trying to continue ...");
      infoStreamPrint(LOG_DASSL, 0, "DASSL will try again...");
      dasslData->info[0] = 1; /* try again */
    } else if(dasslData->idid < 0) {
      fflush(stderr);
      fflush(stdout);
      retVal = continue_DASSL(&dasslData->idid, &simData->simulationInfo.tolerance);
      /* read input vars */
      externalInputUpdate(simData);
      simData->callback->input_function(simData);
      simData->callback->functionODE(simData);
      warningStreamPrint(LOG_STDOUT, 0, "can't continue. time = %f", sData->timeValue);
      return retVal;
    } else if(dasslData->idid == 5) {
      simData->threadData->currentErrorStage = ERROR_EVENTSEARCH;
    }

  } while(dasslData->idid == 1 ||
          (dasslData->idid == -1 && solverInfo->currentTime <= simData->simulationInfo.stopTime));

  sData->timeValue = solverInfo->currentTime;

  if(ACTIVE_STREAM(LOG_DASSL)) {
    infoStreamPrint(LOG_DASSL, 1, "dassl call staistics: ");
    infoStreamPrint(LOG_DASSL, 0, "value of idid: %d", (int)dasslData->idid);
    infoStreamPrint(LOG_DASSL, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_DASSL, 0, "current integration time value: %0.4g", dasslData->rwork[3]);
    infoStreamPrint(LOG_DASSL, 0, "step size H to be attempted on next step: %0.4g", dasslData->rwork[2]);
    infoStreamPrint(LOG_DASSL, 0, "step size used on last successful step: %0.4g", dasslData->rwork[6]);
    infoStreamPrint(LOG_DASSL, 0, "number of steps taken so far: %d", (int)dasslData->iwork[10]);
    infoStreamPrint(LOG_DASSL, 0, "number of calls of functionODE() : %d", (int)dasslData->iwork[11]);
    infoStreamPrint(LOG_DASSL, 0, "number of calculation of jacobian : %d", (int)dasslData->iwork[12]);
    infoStreamPrint(LOG_DASSL, 0, "total number of convergence test failures: %d", (int)dasslData->iwork[13]);
    infoStreamPrint(LOG_DASSL, 0, "total number of error test failures: %d", (int)dasslData->iwork[14]);
    messageClose(LOG_DASSL);
  }

  /* save dassl stats */
  for(ui = 0; ui < numStatistics; ui++) {
    assert(10 + ui < dasslData->liw);
    dasslData->dasslStatisticsTmp[ui] = dasslData->iwork[10 + ui];
  }

  infoStreamPrint(LOG_DASSL, 0, "Finished DDASKR step.");

  return retVal;
}

static int
continue_DASSL(fortran_integer* idid, double* atol)
{
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
    warningStreamPrint(LOG_STDOUT, 0, "A Modelica assert prevents the integrator to continue. For more information use -lv LOG_DASSL");
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
  return retValue;
}


int functionODE_residual(double *t, double *y, double *yd, double* cj, double *delta,
                    fortran_integer *ires, double *rpar, fortran_integer *ipar)
{
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  threadData_t *threadData = data->threadData;

  double timeBackup;
  long i;
  int saveJumpState;
  int success = 0;

  timeBackup = data->localData[0]->timeValue;
  data->localData[0]->timeValue = *t;

  saveJumpState = data->threadData->currentErrorStage;
  data->threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data);

  /* eval input vars */
  data->callback->functionODE(data);

    /* get the difference between the temp_xd(=localData->statesDerivatives)
       and xd(=statesDerivativesBackup) */
    for(i=0; i < data->modelData.nStates; i++) {
      delta[i] = data->localData[0]->realVars[data->modelData.nStates + i] - yd[i];
    }
    success = 1;
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success) {
    *ires = -1;
  }
  
  data->threadData->currentErrorStage = saveJumpState;

  data->localData[0]->timeValue = timeBackup;

  return 0;
}

int function_ZeroCrossingsDASSL(fortran_integer *neqm, double *t, double *y, double *yp,
        fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar)
{
  DATA* data = (DATA*)(void*)((double**)rpar)[0];

  double timeBackup;
  int saveJumpState;

  saveJumpState = data->threadData->currentErrorStage;
  data->threadData->currentErrorStage = ERROR_EVENTSEARCH;

  timeBackup = data->localData[0]->timeValue;

  data->localData[0]->timeValue = *t;
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data);
  /* eval needed equations*/
  data->callback->function_ZeroCrossingsEquations(data);

  data->callback->function_ZeroCrossings(data, gout);

  data->threadData->currentErrorStage = saveJumpState;
  data->localData[0]->timeValue = timeBackup;

  return 0;
}


int functionJacAColored(DATA* data, double* jac)
{
  const int index = data->callback->INDEX_JAC_A;
  int i,j,l,k,ii;
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

    data->callback->functionJacA_column(data);

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
  return 0;
}


int functionJacASym(DATA* data, double* jac)
{
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

    data->callback->functionJacA_column(data);

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
  return 0;
}

/*
 * provides a analytical Jacobian to be used with DASSL
 */

static int JacobianSymbolicColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
         double *rpar, fortran_integer* ipar)
{
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  double* backupStates;
  double timeBackup;
  int i;
  int j;

  backupStates = data->localData[0]->realVars;
  timeBackup = data->localData[0]->timeValue;


  data->localData[0]->timeValue = *t;
  data->localData[0]->realVars = y;
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data);
  /* eval ode*/
  data->callback->functionODE(data);
  functionJacAColored(data, pd);

  /* add cj to the diagonal elements of the matrix */
  j = 0;
  for(i = 0; i < data->modelData.nStates; i++)
  {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }
  data->localData[0]->realVars = backupStates;
  data->localData[0]->timeValue = timeBackup;

  return 0;
}

/*
 * provides a analytical Jacobian to be used with DASSL
 */
static int JacobianSymbolic(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
         double *rpar, fortran_integer* ipar)
{
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  double* backupStates;
  double timeBackup;
  int i;
  int j;

  backupStates = data->localData[0]->realVars;
  timeBackup = data->localData[0]->timeValue;

  data->localData[0]->timeValue = *t;
  data->localData[0]->realVars = y;
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data);
  /* eval ode*/
  data->callback->functionODE(data);
  functionJacASym(data, pd);

  /* add cj to the diagonal elements of the matrix */
  j = 0;
  for(i = 0; i < data->modelData.nStates; i++)
  {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }
  data->localData[0]->realVars = backupStates;
  data->localData[0]->timeValue = timeBackup;

  return 0;
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
int jacA_num(DATA* data, double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, fortran_integer *ipar)
{
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  /* const int index = INDEX_JAC_A; */

  double delta_h = dasslData->sqrteps;
  double delta_hh,delta_hhh, deltaInv;
  double ysave;
  fortran_integer ires;
  int i,j;

  for(i = data->modelData.nStates-1; i >=0 ; i--)
  {
    delta_hhh = *h * yprime[i];
    delta_hh = delta_h * fmax(fmax(abs(y[i]),abs(delta_hhh)),abs(1. / wt[i]));
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

  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
static int JacobianOwnNum(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, fortran_integer* ipar)
{
  int i,j;
  DATA* data = (DATA*)(void*)((double**)rpar)[0];


  if(jacA_num(data, t, y, yprime, deltaD, pd, cj, h, wt, rpar, ipar))
  {
    throwStreamPrint(data->threadData, "Error, can not get Matrix A ");
    return 1;
  }
  j = 0;
  /* add cj to diagonal elements and store in pd */
  for(i = 0; i < data->modelData.nStates; i++)
  {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }

  return 0;
}


/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
int jacA_numColored(DATA* data, double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, fortran_integer *ipar)
{
  const int index = data->callback->INDEX_JAC_A;
  DASSL_DATA* dasslData = (DASSL_DATA*)(void*)((double**)rpar)[1];
  double delta_h = dasslData->sqrteps;
  double delta_hhh;
  fortran_integer ires;
  double* delta_hh = dasslData->delta_hh;
  double* ysave = dasslData->ysave;

  int i,j,l,k,ii;

  for(i = 0; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors; i++)
  {
    for(ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
    {
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
      {
        delta_hhh = *h * yprime[ii];
        delta_hh[ii] = delta_h * fmax(fmax(abs(y[ii]),abs(delta_hhh)),abs(1./wt[ii]));
        delta_hh[ii] = (delta_hhh >= 0 ? delta_hh[ii] : -delta_hh[ii]);
        delta_hh[ii] = y[ii] + delta_hh[ii] - y[ii];

        ysave[ii] = y[ii];
        y[ii] += delta_hh[ii];

        delta_hh[ii] = 1. / delta_hh[ii];
      }
    }

    functionODE_residual(t, y, yprime, cj, dasslData->newdelta, &ires, rpar, ipar);

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

  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
static int JacobianOwnNumColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, fortran_integer* ipar)
{
  DATA* data = (DATA*)(void*)((double**)rpar)[0];
  int i,j;


  if(jacA_numColored(data, t, y, yprime, deltaD, pd, cj, h, wt, rpar, ipar))
  {
    throwStreamPrint(data->threadData, "Error, can not get Matrix A ");
    return 1;
  }

  /* add cj to diagonal elements and store in pd */
  j = 0;
  for(i = 0; i < data->modelData.nStates; i++)
  {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }

  return 0;
}


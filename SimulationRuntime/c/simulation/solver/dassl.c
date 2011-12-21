/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link?ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link?ping, Sweden.
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
 * from Link?ping University, either from the above address,
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

#include "dassl.h"
#include "error.h"
#include "simulation_data.h"
#include "simulation_runtime.h"
#include "solver_main.h"
#include "openmodelica_func.h"
#include "openmodelica.h"

#include <string.h>


/* provides a dummy Jacobian to be used with DASSL */
int
dummy_Jacobian(double *t, double *y, double *yprime, double *pd,
               double *cj, double *rpar, fortran_integer* ipar) {
  return 0;
}
int
dummy_zeroCrossing(fortran_integer *neqm, double *t, double *y,
                   fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar) {
  return 0;
}


int Jacobian(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar);
int Jacobian_num(double *t, double *y, double *yprime, double *pd, double *cj,
    double *rpar, fortran_integer* ipar);


void  DDASRT(
    int (*res) (double *t, double *y, double *yprime, double *delta, fortran_integer *ires, double *rpar, fortran_integer* ipar),
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
    int (*jac) (double *t, double *y, double *yprime, double *delta, double *cj, double *rpar, fortran_integer* ipar),
    int (*g) (fortran_integer *neqm, double *t, double *y, fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar),
    fortran_integer *ng,
    fortran_integer *jroot
);


int
continue_DASRT(fortran_integer* idid, double* tolarence);



int
dasrt_initial(_X_DATA* simData, SOLVER_INFO* solverInfo, DASSL_DATA *dasslData){

  /* int i; */

  /*will remove -> DASSL
	for (i = 0; i < DASSLSTATS; i++) {
			dasslStats[i] = 0;
			dasslStatsTmp[i] = 0;
		}
   */
  /* work arrays for DASSL */
  dasslData->liw = 20 + simData->modelData.nStates;
  dasslData->lrw =  52 + (maxOrder + 4) * simData->modelData.nStates
      + simData->modelData.nStates * simData->modelData.nStates;
  dasslData->rwork = (double*) calloc(dasslData->lrw, sizeof(double));
  ASSERT(dasslData->rwork,"out of memory");
  dasslData->iwork = (fortran_integer*)  calloc(dasslData->liw, sizeof(fortran_integer));
  ASSERT(dasslData->iwork,"out of memory");
  dasslData->jroot = NULL;
  dasslData->rpar = NULL;
  dasslData->ipar = (fortran_integer*) calloc(noStatistics, sizeof(fortran_integer));
  ASSERT(dasslData->ipar,"out of memory");
  dasslData->ipar[0] = globalDebugFlags;
  dasslData->ipar[1] = LOG_JAC;
  dasslData->ipar[2] = LOG_ENDJAC;
  dasslData->info = (fortran_integer*) calloc(infoLength, sizeof(fortran_integer));

  /*********************************************************************
   *info[2] = 1;  //intermediate-output mode
   *********************************************************************
   *info[3] = 1;  //go not past TSTOP
   *rwork[0] = stop;  //TSTOP
   *********************************************************************
   *info[6] = 1;  //prohibit code to decide max. stepsize on its own
   *rwork[1] = *step;  //define max. stepsize
   *********************************************************************/

  if (jac_flag || num_jac_flag)
    dasslData->info[4] = 1; /* use sub-routine JAC */

  return 0;
}


int
dasrt_deinitial(DASSL_DATA *dasslData){

  /* free work arrays for DASSL */
  free(dasslData->rwork);
  free(dasslData->iwork);
  free(dasslData->ipar);
  free(dasslData->info);

  return 0;
}

/**********************************************************************************************
 * DASSL with synchronous treating of when equation
 *   - without integrated ZeroCrossing method.
 *   + ZeroCrossing are handled outside DASSL.
 *   + if no event occurs outside DASSL performs a warm-start
 **********************************************************************************************/
int dasrt_step(_X_DATA* simData, SOLVER_INFO* solverInfo)
{
  double tout = 0;
  int i = 0;

  SIMULATION_DATA *sData = (SIMULATION_DATA*) simData->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*) simData->localData[1];
  MODEL_DATA *mData = (MODEL_DATA*) &simData->modelData;
  DASSL_DATA *dasslData = (DASSL_DATA*) solverInfo->solverData;
  modelica_real* stateDer = sDataOld->realVars + simData->modelData.nStates;
  fortran_integer tmpZero = 0;
  dasslData->rpar = (double*) (void*) simData;
  ASSERT(dasslData->rpar, "simDat could not passed to DASSL");

  /* If an event is triggered and processed restart dassl. */
  if (solverInfo->didEventStep)
  {
    DEBUG_INFO(LOG_EVENTS, "Event-management forced reset of DDASRT");
    /* obtain reset */
    dasslData->info[0] = 0;
  }

  /* Calculate time steps until TOUT is reached
   * (DASSL calculates beyond TOUT unless info[6] is set to 1!) */
  do
  {

    tout = solverInfo->currentTime + solverInfo->currentStepSize;
    /* Check that tout is not less than timeValue
     * else will dassl get in trouble. If that is the case we skip the current step. */
    if (solverInfo->currentTime - tout >= -1e-13)
    {
      DEBUG_INFO(LOG_SOLVER, "**Desired step to small try next one");
      DEBUG_INFO(LOG_SOLVER, "**Interpolate linear");

      for (i = 0; i < simData->modelData.nStates; i++)
      {
        sData->realVars[i] = sDataOld->realVars[i]
            + stateDer[i] * solverInfo->currentStepSize;
      }
      sData->timeValue = tout;
      functionODE(simData);
      solverInfo->currentTime = tout;
      /*TODO: interpolate states and evaluate the system again */
      return 2;
    }

    DEBUG_INFO2(LOG_SOLVER, "**Calling DDASRT from %g to %g",
        solverInfo->currentTime, tout);
    /*
     DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
     &solverInfo->currentTime, sData->realVars, stateDer, &tout,
     dasslData->info, &simData->simulationInfo.tolerance, &simData->simulationInfo.tolerance,
     &dasslData->idid, dasslData->rwork, &dasslData->lrw, dasslData->iwork,
     &dasslData->liw,dasslData->rpar, dasslData->ipar, dummy_Jacobian,
     dummy_zeroCrossing, &tmpZero, NULL);
     */

    if (jac_flag)
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, &simData->simulationInfo.tolerance,
          &simData->simulationInfo.tolerance, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, Jacobian, dummy_zeroCrossing,
          &tmpZero, NULL);
    }
    else if (num_jac_flag)
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, &simData->simulationInfo.tolerance,
          &simData->simulationInfo.tolerance, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, Jacobian_num, dummy_zeroCrossing,
          &tmpZero, NULL);
    }
    else
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, &simData->simulationInfo.tolerance,
          &simData->simulationInfo.tolerance, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, dummy_Jacobian, dummy_zeroCrossing,
          &tmpZero, NULL);
    }
    /*
     if(sim_verbose == LOG_SOLVER)
     {
     INFO("DASSL call | value of idid: %ld", idid);
     INFO("DASSL call | current time value: %0.4g", globalData->timeValue);
     INFO("DASSL call | current integration time value: %0.4g", rwork[3]);
     INFO("DASSL call | step size H to be attempted on next step: %0.4g", rwork[2]);
     INFO("DASSL call | step size used on last successful step: %0.4g", rwork[6]);
     INFO("DASSL call | number of steps taken so far: %ld", iwork[10]);
     INFO("DASSL call | number of calls of functionODE() : %ld", iwork[11]);
     INFO("DASSL call | number of calculation of jacobian : %ld", iwork[12]);
     INFO("DASSL call | total number of convergence test failures: %ld", iwork[13]);
     INFO("DASSL call | total number of error test failures: %ld", iwork[14]);
     }
     */
    /* save dassl stats */
    /*    for (i = 0; i < DASSLSTATS; i++) {
     assert(10 + i < liw);
     tmpStats[i] = iwork[10 + i];
     }
     */
    if (dasslData->idid == -1)
    {
      fflush(stderr);
      fflush(stdout);
      DEBUG_INFO(LOG_SOLVER, "DDASRT will try again...");
      dasslData->info[0] = 1; /* try again */
    }
    else if (dasslData->idid < 0)
    {
      fflush(stderr);
      fflush(stdout);
      if (!continue_DASRT(&dasslData->idid, &simData->simulationInfo.tolerance))
        solverInfo->currentTime = solverInfo->currentTime
            + solverInfo->currentStepSize;
      sData->timeValue = solverInfo->currentTime;
      functionODE(simData);
      INFO1("DASRT can't continue. time = %f", sData->timeValue);
      return 1;
    }
    sData->timeValue = solverInfo->currentTime;
    functionODE(simData);
  } while (dasslData->idid == -1
      && solverInfo->currentTime <= simData->simulationInfo.stopTime);

  if (simData->simulationInfo.stopTime >= solverInfo->currentTime)
  {
    DEBUG_INFO(LOG_SOLVER, "DDASRT finished");
  }
  return 0;
}

int
continue_DASRT(fortran_integer* idid, double* atol) {
  int retValue = 1;

  switch (*idid) {
  case 1:
  case 2:
  case 3:
    /* 1-4 means success */
    break;
  case -1:
    WARNING("DDASRT: A large amount of work has been expended.(About 500 steps). Trying to continue ...");
    retValue = 1; /* adrpo: try to continue */
    break;
  case -2:
    WARNING("DDASRT: The error tolerances are too stringent");
    retValue = 0;
    break;
  case -3:
    /* wbraun: don't throw at this point let the solver handle it */
    /* THROW("DDASRT: THE LAST STEP TERMINATED WITH A NEGATIVE IDID value"); */
    retValue = 0;
    break;
  case -6:
    WARNING("DDASRT: DDASSL had repeated error test failures on the last attempted step.");
    retValue = 0;
    break;
  case -7:
    WARNING("DDASRT: The corrector could not converge.");
    retValue = 0;
    break;
  case -8:
    WARNING("DDASRT: The matrix of partial derivatives is singular.");
    retValue = 0;
    break;
  case -9:
    WARNING("DDASRT: The corrector could not converge. There were repeated error test failures in this step.");
    retValue = 0;
    break;
  case -10:
    INFO("DDASRT: The corrector could not converge because IRES was equal to minus one.");
    retValue = 0;
    break;
  case -11:
    WARNING("DDASRT: IRES equal to -2 was encountered and control is being returned to the calling program.");
    retValue = 0;
    break;
  case -12:
    WARNING("DDASRT: DDASSL failed to compute the initial YPRIME.");
    retValue = 0;
    break;
  case -33:
    WARNING("DDASRT: The code has encountered trouble from which it cannot recover.");
    retValue = 0;
    break;
  }
  return retValue;
}


int functionODE_residual(double *t, double *x, double *xd, double *delta,
                    fortran_integer *ires, double *rpar, fortran_integer *ipar)
{
  _X_DATA* data = (_X_DATA*)(void*)rpar;
  /*DASSL_DATA* dasslData = (DASSL_DATA*)(void*)rpar[1];*/
  double timeBackup;
  double* statesBackup;
  long i;

  timeBackup = data->localData[0]->timeValue;
  statesBackup = data->localData[0]->realVars;

  data->localData[0]->timeValue = *t;
  data->localData[0]->realVars = x;
  functionODE(data);

  /* get the difference between the temp_xd(=localData->statesDerivatives)
     and xd(=statesDerivativesBackup) */
  for (i=0; i < data->modelData.nStates; i++) {
    delta[i] = data->localData[0]->realVars[data->modelData.nStates + i] - xd[i];
  }

  data->localData[0]->realVars = statesBackup;
  data->localData[0]->timeValue = timeBackup;

  return 0;
}

/*
 * provides a analytical Jacobian to be used with DASSL
 */

int
Jacobian(double *t, double *y, double *yprime, double *pd, double *cj,
         double *rpar, fortran_integer* ipar) {

  _X_DATA* data = (_X_DATA*)(void*)rpar;
  double* backupStates;
  double timeBackup;
  int i;
  int j;

  backupStates = data->localData[0]->realVars;
  timeBackup = data->localData[0]->timeValue;


  data->localData[0]->timeValue = *t;
  data->localData[0]->realVars = y;
  functionODE(data);
  functionJacA(data, pd);

  /* add cj to the diagonal elements of the matrix */
  j = 0;
  for (i = 0; i < data->modelData.nStates; i++) {
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
int
jacA_num(_X_DATA* data, double *t, double *y, double *matrixA) {

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  double delta_h = 1.e-10;
  double delta_hh;
  double* yprime = (double*) malloc(data->modelData.nStates * sizeof(double));

  double* backupStates;
  double backupTime;
  int i,j,l;
  backupStates = data->localData[0]->realVars;
  backupTime = data->localData[0]->timeValue;

  data->localData[0]->realVars = y;
  data->localData[0]->timeValue = *t;

  functionODE(data);
  memcpy(yprime, sData->realVars + data->modelData.nStates,
      data->modelData.nStates * sizeof(double));

  /* matrix A, add cj to diagonal elements and store in pd */
  for (i = 0; i < data->modelData.nStates; i++) {
    delta_hh = delta_h * (sData->realVars[i] > 0 ? sData->realVars[i]
                                                                         : -sData->realVars[i]);
    delta_hh = ((delta_h > delta_hh) ? delta_h : delta_hh);
    sData->realVars[i] += delta_hh;
    functionODE(data);
    sData->realVars[i] -= delta_hh;

    l = i * data->modelData.nStates;
    for (j = 0; j < data->modelData.nStates; j++) {
      matrixA[l+j] = ((sData->realVars + data->modelData.nStates)[j] - yprime[j]) / delta_hh;
    }
  }

  data->localData[0]->realVars = backupStates;
  data->localData[0]->timeValue = backupTime;
  free(yprime);

  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
int Jacobian_num(double *t, double *y, double *yprime, double *pd, double *cj,
   double *rpar, fortran_integer* ipar) {

  _X_DATA* data = (_X_DATA*)(void*)rpar;
  int i,j;
  if (jacA_num(data, t, y, pd)) {
	  THROW("Error, can not get Matrix A ");
    return 1;
  }

  /* add cj to diagonal elements and store in pd */
  j = 0;
  for (i = 0; i < data->modelData.nStates; i++) {
    pd[j] -= (double) *cj;
    j += data->modelData.nStates + 1;
  }
  return 0;
}



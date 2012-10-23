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

#include "dassl.h"
#include "omc_error.h"
#include "simulation_data.h"
#include "simulation_runtime.h"
#include "solver_main.h"
#include "openmodelica.h"
#include "openmodelica_func.h"

#include <string.h>

const char *dasslMethodStr[DASSL_MAX] = {"unknown", 
                                         "dassl", 
                                         "dasslwort",
                                         "dasslSymJac",
                                         "dasslNumJac",
                                         "dasslColorSymJac",
                                         "dasslColorNumJac",
                                         "dassltest",
                                        };

const char *dasslMethodStrDescStr[DASSL_MAX] = {"unknown", 
                                                "normal dassl",
                                                "dassl without internal root finding",
                                                "dassl with symbolic jacobian",
                                                "dassl with numerical jacobian",
                                                "dassl with colored symbolic jacobian",
                                                "dassl with colored numerical jacobian",
                                                "dassl for debug propose"
                                               };



/* provides a dummy Jacobian to be used with DASSL */
int
dummy_Jacobian(double *t, double *y, double *yprime, double *deltaD,
    double *delta, double *cj, double *h, double *wt, double *rpar, fortran_integer* ipar) {
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

int JacobianSymbolic(double *t, double *y, double *yprime,  double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, fortran_integer* ipar);
int JacobianSymbolicColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, fortran_integer* ipar);
int JacobianOwnNum(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
    double *rpar, fortran_integer* ipar);
int JacobianOwnNumColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
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
    int (*jac) (double *t, double *y, double *yprime, double *deltaD, double *delta, double *cj, double *h, double *wt, double *rpar, fortran_integer* ipar),
    int (*g) (fortran_integer *neqm, double *t, double *y, fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar),
    fortran_integer *ng,
    fortran_integer *jroot
);


int
continue_DASRT(fortran_integer* idid, double* tolarence);



int
dasrt_initial(DATA* simData, SOLVER_INFO* solverInfo, DASSL_DATA *dasslData){

  /* work arrays for DASSL */
  int i;
  SIMULATION_INFO *simInfo = &(simData->simulationInfo);

  for(i=0; i< DASSL_MAX;i++){
    if(!strcmp((const char*)simInfo->solverMethod, dasslMethodStr[i])){
      dasslData->dasslMethod = i;
    }
  }

  if(dasslData->dasslMethod == DASSL_UNKNOWN)
  {
    WARNING1("unrecognized solver method %s", simInfo->solverMethod);
    WARNING_AL("current options are:");
    for(i=1; i < DASSL_MAX; ++i)
      WARNING_AL2("  %-15s [%s]", dasslMethodStr[i], dasslMethodStrDescStr[i]);
    THROW("see last warning");
  }else{
    DEBUG_INFO2(LOG_SOLVER,"Use solver method: %s\t%s",dasslMethodStr[dasslData->dasslMethod],dasslMethodStrDescStr[dasslData->dasslMethod]);
  }


  dasslData->liw = 20 + simData->modelData.nStates;
  dasslData->lrw = 50 + ((maxOrder + 4) * simData->modelData.nStates)
              + (simData->modelData.nStates * simData->modelData.nStates)  + (3*simData->modelData.nZeroCrossings);
  dasslData->rwork = (double*) calloc(dasslData->lrw, sizeof(double));
  ASSERT(dasslData->rwork,"out of memory");
  dasslData->iwork = (fortran_integer*)  calloc(dasslData->liw, sizeof(fortran_integer));
  ASSERT(dasslData->iwork,"out of memory");
  dasslData->ng = (fortran_integer) simData->modelData.nZeroCrossings;
  dasslData->ngdummy = (fortran_integer) 0;
  dasslData->jroot = (fortran_integer*)  calloc(simData->modelData.nZeroCrossings, sizeof(fortran_integer));
  dasslData->rpar = NULL;
  dasslData->ipar = (fortran_integer*) calloc(numStatistics, sizeof(fortran_integer));
  ASSERT(dasslData->ipar,"out of memory");
  dasslData->atol = (double*) malloc(simData->modelData.nStates*sizeof(double));
  dasslData->rtol = (double*) malloc(simData->modelData.nStates*sizeof(double));
  dasslData->ipar[0] = DEBUG_FLAG(LOG_JAC);
  dasslData->ipar[1] = DEBUG_FLAG(LOG_ENDJAC);
  dasslData->info = (fortran_integer*) calloc(infoLength, sizeof(fortran_integer));
  ASSERT(dasslData->info,"out of memory");
  dasslData->dasslStatistics = (unsigned int*) calloc(numStatistics, sizeof(unsigned int));
  ASSERT(dasslData->dasslStatistics,"out of memory");
  dasslData->dasslStatisticsTmp = (unsigned int*) calloc(numStatistics, sizeof(unsigned int));
  ASSERT(dasslData->dasslStatisticsTmp,"out of memory");

  dasslData->info[2] = 1;
  /*********************************************************************
   *info[2] = 1;  //intermediate-output mode
   *********************************************************************
   *info[3] = 1;  //go not past TSTOP
   *rwork[0] = stop;  //TSTOP
   *********************************************************************
   *info[6] = 1;  //prohibit code to decide max. stepsize on its own
   *rwork[1] = *step;  //define max. stepsize
   *********************************************************************/

  if (dasslData->dasslMethod == DASSL_SYMJAC ||
      dasslData->dasslMethod == DASSL_COLOREDSYMJAC ||
      dasslData->dasslMethod == DASSL_NUMJAC ||
      dasslData->dasslMethod == DASSL_COLOREDNUMJAC ||
      dasslData->dasslMethod == DASSL_TEST){
    if (initialAnalyticJacobianA(simData)){
      DEBUG_INFO(LOG_SOLVER,"Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
      dasslData->dasslMethod = DASSL_RT;
    }else{
      dasslData->info[4] = 1; /* use sub-routine JAC */
    }
  }

  if (dasslData->dasslMethod != DASSL_WORT)
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
dasrt_deinitial(DASSL_DATA *dasslData){

  /* free work arrays for DASSL */
  free(dasslData->rwork);
  free(dasslData->iwork);
  free(dasslData->ipar);
  free(dasslData->info);
  free(dasslData->dasslStatistics);
  free(dasslData->dasslStatisticsTmp);
  return 0;
}

/**********************************************************************************************
 * DASSL with synchronous treating of when equation
 *   - without integrated ZeroCrossing method.
 *   + ZeroCrossing are handled outside DASSL.
 *   + if no event occurs outside DASSL performs a warm-start
 **********************************************************************************************/
int dasrt_step(DATA* simData, SOLVER_INFO* solverInfo)
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
  dasslData->rpar = (double*) (void*) simData;
  ASSERT(dasslData->rpar, "simDat could not passed to DASSL");

  /* If an event is triggered and processed restart dassl. */
  if (solverInfo->didEventStep)
  {
    DEBUG_INFO(LOG_EVENTS, "Event-management forced reset of DDASRT");
    /* obtain reset */
    dasslData->info[0] = 0;
    dasslData->idid = 0;
  }

  /* Calculate time steps until TOUT is reached
   * (DASSL calculates beyond TOUT unless info[6] is set to 1!) */
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
    return retVal;
  }

  DEBUG_INFO2(LOG_SOLVER, "**Calling DDASRT from %.10f to %.10f",
      solverInfo->currentTime, tout);
  do
  {
    DEBUG_INFO2(LOG_SOLVER, "**Start step %.10f to %.10f", solverInfo->currentTime, tout);
    if (dasslData->idid == 1){
      /* rotate RingBuffer before step is calculated */
      rotateRingBuffer(simData->simulationData, 1, (void**) simData->localData);
      sData = (SIMULATION_DATA*) simData->localData[0];
      sDataOld = (SIMULATION_DATA*) simData->localData[1];
      stateDer = sDataOld->realVars + mData->nStates;
      sData->timeValue = solverInfo->currentTime;

    }
    /* read input vars */
    input_function(simData);

    if (dasslData->dasslMethod ==  DASSL_SYMJAC)
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, JacobianSymbolic,  function_ZeroCrossingsDASSL,
          (fortran_integer*) &dasslData->ng, dasslData->jroot);
    }
    else if (dasslData->dasslMethod ==  DASSL_NUMJAC)
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, JacobianOwnNum,  function_ZeroCrossingsDASSL,
          (fortran_integer*) &dasslData->ng, dasslData->jroot);
    }
    else if (dasslData->dasslMethod ==  DASSL_COLOREDSYMJAC)
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, JacobianSymbolicColored,  function_ZeroCrossingsDASSL,
          (fortran_integer*) &dasslData->ng, dasslData->jroot);
    }
    else if (dasslData->dasslMethod ==  DASSL_COLOREDNUMJAC)
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, JacobianOwnNumColored,  function_ZeroCrossingsDASSL,
          (fortran_integer*) &dasslData->ng, dasslData->jroot);
    }
    else if (dasslData->dasslMethod ==  DASSL_TEST)
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, JacobianOwnNumColored, dummy_zeroCrossing,
          &dasslData->ngdummy, NULL);
    }
    else if (dasslData->dasslMethod ==  DASSL_WORT)
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, dummy_Jacobian, dummy_zeroCrossing,
          &dasslData->ngdummy, NULL);
    }
    else
    {
      DDASRT(functionODE_residual, (fortran_integer*) &mData->nStates,
          &solverInfo->currentTime, sData->realVars, stateDer, &tout,
          dasslData->info, dasslData->rtol, dasslData->atol, &dasslData->idid,
          dasslData->rwork, &dasslData->lrw, dasslData->iwork, &dasslData->liw,
          dasslData->rpar, dasslData->ipar, dummy_Jacobian, function_ZeroCrossingsDASSL,
          (fortran_integer*) &dasslData->ng, dasslData->jroot);
    }

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
      retVal = continue_DASRT(&dasslData->idid, &simData->simulationInfo.tolerance);
      solverInfo->currentTime = solverInfo->currentTime + solverInfo->currentStepSize;
      sData->timeValue = solverInfo->currentTime;
      functionODE(simData);
      INFO1("DASRT can't continue. time = %f", sData->timeValue);
      return retVal;
    }

  } while (dasslData->idid == 1 || (dasslData->idid == -1
      && solverInfo->currentTime <= simData->simulationInfo.stopTime));


  /* at the of one step evaluate the system again */
  sData->timeValue = solverInfo->currentTime;



  if (DEBUG_FLAG(LOG_SOLVER))
  {
    INFO1("DASSL call | value of idid: %d", dasslData->idid);
    INFO1("DASSL call | current time value: %0.4g", solverInfo->currentTime);
    INFO1("DASSL call | current integration time value: %0.4g", dasslData->rwork[3]);
    INFO1("DASSL call | step size H to be attempted on next step: %0.4g", dasslData->rwork[2]);
    INFO1("DASSL call | step size used on last successful step: %0.4g", dasslData->rwork[6]);
    INFO1("DASSL call | number of steps taken so far: %d", dasslData->iwork[10]);
    INFO1("DASSL call | number of calls of functionODE() : %d", dasslData->iwork[11]);
    INFO1("DASSL call | number of calculation of jacobian : %d", dasslData->iwork[12]);
    INFO1("DASSL call | total number of convergence test failures: %d", dasslData->iwork[13]);
    INFO1("DASSL call | total number of error test failures: %d", dasslData->iwork[14]);
  }
  /* save dassl stats */
  for (ui = 0; ui < numStatistics; ui++)
  {
   assert(10 + ui < dasslData->liw);
   dasslData->dasslStatisticsTmp[ui] = dasslData->iwork[10 + ui];
  }


  DEBUG_INFO(LOG_SOLVER, "*** Finished DDASRT step! ***");

  return retVal;
}

int
continue_DASRT(fortran_integer* idid, double* atol) {
  int retValue = -1;

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
    retValue = -2;
    break;
  case -3:
    /* wbraun: don't throw at this point let the solver handle it */
    /* THROW("DDASRT: THE LAST STEP TERMINATED WITH A NEGATIVE IDID value"); */
    retValue = -3;
    break;
  case -6:
    WARNING("DDASRT: DDASSL had repeated error test failures on the last attempted step.");
    retValue = -6;
    break;
  case -7:
    WARNING("DDASRT: The corrector could not converge.");
    retValue = -7;
    break;
  case -8:
    WARNING("DDASRT: The matrix of partial derivatives is singular.");
    retValue = -8;
    break;
  case -9:
    WARNING("DDASRT: The corrector could not converge. There were repeated error test failures in this step.");
    retValue = -9;
    break;
  case -10:
    INFO("DDASRT: The corrector could not converge because IRES was equal to minus one.");
    retValue = -10;
    break;
  case -11:
    WARNING("DDASRT: IRES equal to -2 was encountered and control is being returned to the calling program.");
    retValue = -11;
    break;
  case -12:
    WARNING("DDASRT: DDASSL failed to compute the initial YPRIME.");
    retValue = -12;
    break;
  case -33:
    WARNING("DDASRT: The code has encountered trouble from which it cannot recover.");
    retValue = -33;
    break;
  }
  return retValue;
}


int functionODE_residual(double *t, double *x, double *xd, double *delta,
                    fortran_integer *ires, double *rpar, fortran_integer *ipar)
{
  DATA* data = (DATA*)(void*)rpar;

  double timeBackup;
  long i;

  timeBackup = data->localData[0]->timeValue;

  data->localData[0]->timeValue = *t;
  functionODE(data);

  /* get the difference between the temp_xd(=localData->statesDerivatives)
     and xd(=statesDerivativesBackup) */
  for (i=0; i < data->modelData.nStates; i++) {
    delta[i] = data->localData[0]->realVars[data->modelData.nStates + i] - xd[i];
  }

  data->localData[0]->timeValue = timeBackup;

  return 0;
}

int function_ZeroCrossingsDASSL(fortran_integer *neqm, double *t, double *y,
        fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar)
{
  DATA* data = (DATA*)(void*)rpar;

  double timeBackup;

  fortran_integer i;

  timeBackup = data->localData[0]->timeValue;

  data->localData[0]->timeValue = *t;
  functionODE(data);
  functionAlgebraics(data);

  function_ZeroCrossings(data, gout, t);

  DEBUG_INFO1(LOG_ZEROCROSSINGS, "Check ZeroCrossing at time: %g", *t);
  for (i=0; i < *ng; i++) {
    DEBUG_INFO_NELA1(LOG_ZEROCROSSINGS, "ZeroCrossing %d : ", i);
    DEBUG_INFO_NELA1(LOG_ZEROCROSSINGS, " %d ", data->simulationInfo.zeroCrossingEnabled[i]);

    DEBUG_INFO_NELA1(LOG_ZEROCROSSINGS, " %g \n", gout[i]);

    /* For the first evaluation  gout[i] != 0 has to be
     * of ZeroCrossings by dassl.
     *
     */
    /*
    if (!(data->simulationInfo.zeroCrossingEnabled[i]==0)){
      if (gout[i] == 0.0 && data->simulationInfo.zeroCrossingEnabled[i] >=1){
        gout[i] = DBL_EPSILON;
      } else if (gout[i] == 0.0 && data->simulationInfo.zeroCrossingEnabled[i] <= -1){
        gout[i] = -DBL_EPSILON;
      }
    }else{
      if (data->simulationInfo.zeroCrossingEnabled[i]==1)
        gout[i] = 0.1;
      else if (data->simulationInfo.zeroCrossingEnabled[i]==-1)
        gout[i] = -0.1;
      else{
        if (data->simulationInfo.zeroCrossingsPre[i]>=0)
          gout[i] = 1;
        else if (data->simulationInfo.zeroCrossingsPre[i]<0)
            gout[i] = -1;
        else
          gout[i] = 1;
      }
    }
    */
  }
  data->localData[0]->timeValue = timeBackup;

  return 0;
}


int functionJacAColored(DATA* data, double* jac){

  const int index = INDEX_JAC_A;
  int i,j,l,k,ii;
  for(i=0; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors; i++)
  {
    for (ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
      if (data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1;

    if (DEBUG_FLAG((LOG_JAC | LOG_ENDJAC))){
      printf("Caluculate one col:\n");
      for(l=0;  l < data->simulationInfo.analyticJacobians[index].sizeCols;l++)
        DEBUG_INFO2((LOG_JAC | LOG_ENDJAC),"seed: data->simulationInfo.analyticJacobians[index].seedVars[%d]= %f",l,data->simulationInfo.analyticJacobians[index].seedVars[l]);
    }


    functionJacA_column(data);

    for(j = 0; j < data->simulationInfo.analyticJacobians[index].sizeCols; j++)
    {
      if ( data->simulationInfo.analyticJacobians[index].seedVars[j] == 1)
      {
        if (j==0)
          ii = 0;
        else
          ii = data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j-1];
        DEBUG_INFO2((LOG_JAC | LOG_ENDJAC)," take for %d -> %d\n",j,ii);
        while(ii < data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j])
        {
          l  = data->simulationInfo.analyticJacobians[index].sparsePattern.index[ii];
          k  = j*data->simulationInfo.analyticJacobians[index].sizeRows + l;
          jac[k] = data->simulationInfo.analyticJacobians[index].resultVars[l];
          DEBUG_INFO7((LOG_JAC | LOG_ENDJAC),"write %d. in jac[%d]-[%d,%d]=%f from col[%d]=%f",ii,k,l,j,jac[k],l,data->simulationInfo.analyticJacobians[index].resultVars[l]);
          ii++;
        };
      }
    }
    for (ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
      if (data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i) data->simulationInfo.analyticJacobians[index].seedVars[ii] = 0;


    /*
    if (DEBUG_FLAG((LOG_JAC | LOG_ENDJAC))){
      INFO("Print jac:");
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


int functionJacASym(DATA* data, double* jac){

  const int index = INDEX_JAC_A;
  unsigned int i,j,k;
  k = 0;
  for(i=0; i < data->simulationInfo.analyticJacobians[index].sizeCols; i++)
  {
    data->simulationInfo.analyticJacobians[index].seedVars[i] = 1.0;

    if (DEBUG_FLAG((LOG_JAC | LOG_ENDJAC)))
    {
      printf("Caluculate one col:\n");
      for(j=0;  j < data->simulationInfo.analyticJacobians[index].sizeCols;j++)
        DEBUG_INFO2((LOG_JAC | LOG_ENDJAC),"seed: data->simulationInfo.analyticJacobians[index].seedVars[%d]= %f",j,data->simulationInfo.analyticJacobians[index].seedVars[j]);
    }


    functionJacA_column(data);

    for(j = 0; j < data->simulationInfo.analyticJacobians[index].sizeRows; j++)
    {
      jac[k++] = data->simulationInfo.analyticJacobians[index].resultVars[j];
      DEBUG_INFO6((LOG_JAC | LOG_ENDJAC),"write in jac[%d]-[%d,%d]=%g from row[%d]=%g",k,i,j,jac[k-1],j,data->simulationInfo.analyticJacobians[index].resultVars[j]);
    }

    data->simulationInfo.analyticJacobians[index].seedVars[i] = 0.0;
  }
  /*
  if (DEBUG_FLAG(LOG_DEBUG))
  {
    INFO("Print jac:");
    for(i=0;  i < data->simulationInfo.analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo.analyticJacobians[index].sizeCols;j++)
        printf("% .5e ",jac[i+j*data->simulationInfo.analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  }
  */
  return 0;
}

/*
 * provides a analytical Jacobian to be used with DASSL
 */

int
JacobianSymbolicColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
         double *rpar, fortran_integer* ipar) {

  DATA* data = (DATA*)(void*)rpar;
  double* backupStates;
  double timeBackup;
  int i;
  int j;

  backupStates = data->localData[0]->realVars;
  timeBackup = data->localData[0]->timeValue;


  data->localData[0]->timeValue = *t;
  data->localData[0]->realVars = y;
  functionODE(data);
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

int
JacobianSymbolic(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
         double *rpar, fortran_integer* ipar) {

  DATA* data = (DATA*)(void*)rpar;
  double* backupStates;
  double timeBackup;
  int i;
  int j;

  backupStates = data->localData[0]->realVars;
  timeBackup = data->localData[0]->timeValue;


  data->localData[0]->timeValue = *t;
  data->localData[0]->realVars = y;
  functionODE(data);
  functionJacASym(data, pd);

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
jacA_num(DATA* data, double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, fortran_integer *ipar) {

  const int index = INDEX_JAC_A;

  double delta_h = sqrt(DBL_EPSILON);
  double delta_hh,delta_hhh, deltaInv;
  double ysave, ypsave;
  double* yprimeD = (double*) malloc(data->modelData.nStates  * sizeof(double));
  double* e = (double*) malloc(data->modelData.nStates * sizeof(double));
  int ires;
  int i,j,l=0;

  memcpy(yprimeD, yprime, data->modelData.nStates * sizeof(double));

  /* matrix A, add cj to diagonal elements and store in pd */
  for (i = 0; i < data->modelData.nStates; i++) {
    delta_hhh = *h * yprime[i];
    delta_hh = delta_h * fmax(fmax(abs(y[i]),abs(delta_hhh)),abs(wt[i]));
    delta_hh = (delta_hhh >= 0 ? delta_hh : -delta_hh);
    delta_hh = y[i] + delta_hh - y[i];
    ysave = y[i];
    ypsave = yprime[i];
    y[i] += delta_hh;
    yprime[i] += *cj * delta_hh;

    functionODE_residual(t, y, yprime, e, &ires, rpar, ipar);

    deltaInv = 1. / delta_hh;

    DEBUG_INFO1((LOG_JAC | LOG_ENDJAC),"Caluculate one col: %d", i);
    for (j = 0; j < data->modelData.nStates; j++) {
      matrixA[l++] = (e[j] - delta[j]) * deltaInv;
      if (DEBUG_FLAG(LOG_JAC | LOG_ENDJAC)) {
        printf("%e ",matrixA[l-1]);
      }
    }
    DEBUG_INFO((LOG_JAC | LOG_ENDJAC)," ");
    y[i] = ysave;
    yprime[i] = ypsave;
  }

  if (DEBUG_FLAG(LOG_JAC | LOG_ENDJAC)) {
    INFO("Print jac:");
    for(i=0;  i < data->simulationInfo.analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo.analyticJacobians[index].sizeCols;j++)
        printf("% .5g ",matrixA[i+j*data->simulationInfo.analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  }

  memcpy(yprime, yprimeD, data->modelData.nStates * sizeof(double));


  free(yprimeD);
  free(e);

  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
int JacobianOwnNum(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, fortran_integer* ipar) {

  DATA* data = (DATA*)(void*)rpar;
  if (jacA_num(data, t, y, yprime, deltaD, pd, cj, h, wt, rpar, ipar)) {
    THROW("Error, can not get Matrix A ");
    return 1;
  }

  return 0;
}


/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
int
jacA_numColored(DATA* data, double *t, double *y, double *yprime, double *delta, double *matrixA, double *cj, double *h, double *wt, double *rpar, fortran_integer *ipar) {

  const int index = INDEX_JAC_A;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  double delta_h = sqrt(DBL_EPSILON);
  double delta_hhh;
  int ires;
  double* delta_hh = (double*) malloc(data->modelData.nStates * sizeof(double));
  double* deltaInv = (double*) malloc(data->modelData.nStates * sizeof(double));
  double* ysave = (double*) malloc(data->modelData.nStates * sizeof(double));
  double* ypsave = (double*) malloc(data->modelData.nStates * sizeof(double));
  double* yprimeD = (double*) malloc(data->modelData.nStates * sizeof(double));
  double* e = (double*) malloc(data->modelData.nStates * sizeof(double));


  int i,j,l,k,kk,ii, hh;

  memcpy(yprimeD, yprime, data->modelData.nStates * sizeof(double));

  /* matrix A, add cj to diagonal elements and store in pd */
  for (i = 0; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors; i++) {

    for (ii=0, kk = 0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++){
      if (data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i){
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1.0;
        delta_hhh = *h * yprime[ii];
        delta_hh[kk] = delta_h * fmax(fmax(abs(y[ii]),abs(delta_hhh)),abs(wt[ii]));
        delta_hh[kk] = (delta_hhh >= 0 ? delta_hh[kk] : -delta_hh[kk]);
        delta_hh[kk] = y[ii] + delta_hh[kk] - y[ii];
        deltaInv[kk] = 1. / delta_hh[kk];
        kk++;
        hh = ii;
      }
    }

    DEBUG_INFO(LOG_JAC | LOG_ENDJAC,"Set Seed Vars:");
    for (ii=0, kk = 0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++){
      if (data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i){

        ysave[ii] = y[ii];
        ypsave[ii] = yprime[ii];
        y[ii] += delta_hh[kk];
        DEBUG_INFO3(LOG_JAC | LOG_ENDJAC,"seed:  sData->realVars[%d]= %e\t = %e",ii,y[ii],sData->realVars[ii]);
        kk++;
      }
    }

    functionODE_residual(t, y, yprime, e, &ires, rpar, ipar);

    for (ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
        DEBUG_INFO3(LOG_JAC | LOG_ENDJAC,"result:  yprime[%d]= %e\t = %e",ii,yprime[ii],(e[ii] - delta[ii]) * delta_h);


    for(j = 0,kk=0; j < data->simulationInfo.analyticJacobians[index].sizeCols; j++){
      if ( data->simulationInfo.analyticJacobians[index].seedVars[j] == 1.0) {
        if (j==0)
          ii = 0;
        else
          ii = data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j-1];
        DEBUG_INFO2((LOG_JAC | LOG_ENDJAC)," take for %d -> %d\n",j,ii);
        while(ii < data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j]){
          l  =  data->simulationInfo.analyticJacobians[index].sparsePattern.index[ii];
          k  = l + j*data->simulationInfo.analyticJacobians[index].sizeRows;
          matrixA[k] = (e[l] - delta[l]) * deltaInv[kk];
          DEBUG_INFO5(LOG_JAC | LOG_ENDJAC,"write %d. in jac[%d]-[%d,%d]=%e",ii,k,j,l,matrixA[k]);
          ii++;
        };
        kk++;
      }
    }

    for (ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++){
      if (data->simulationInfo.analyticJacobians[index].seedVars[ii] == 1.0){
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 0.0;
        y[ii] = ysave[ii];
        yprime[ii] = ypsave[ii];
      }
    }
  }

  if (DEBUG_FLAG(LOG_JAC | LOG_ENDJAC)) {
    INFO("Print jac:");
    for(i=0;  i < data->simulationInfo.analyticJacobians[index].sizeRows;i++)
    {
      for(j=0;  j < data->simulationInfo.analyticJacobians[index].sizeCols;j++)
        printf("% .5g ",matrixA[i+j*data->simulationInfo.analyticJacobians[index].sizeCols]);
      printf("\n");
    }
  }

  memcpy(yprime, yprimeD, data->modelData.nStates * sizeof(double));

  free(yprimeD);
  free(ypsave);
  free(ysave);
  free(e);
  free(delta_hh);
  free(deltaInv);

  return 0;
}

/*
 * provides a numerical Jacobian to be used with DASSL
 */
int JacobianOwnNumColored(double *t, double *y, double *yprime, double *deltaD, double *pd, double *cj, double *h, double *wt,
   double *rpar, fortran_integer* ipar) {

  DATA* data = (DATA*)(void*)rpar;
  int i,j;
  if (jacA_numColored(data, t, y, yprime, deltaD, pd, cj, h, wt, rpar, ipar)) {
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


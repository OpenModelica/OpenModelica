/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file nonlinear_solver.c
 */

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "simulation_data.h"
#include "omc_error.h"
#include "varinfo.h"
#include "model_help.h"

#include "nonlinearSystem.h"
#include "nonlinearSolverHybrd.h"

/*! \fn allocate memory for nonlinear system solver hybrd
 *
 */
int allocateHybrdData(int* size, void** voiddata)
{
  DATA_HYBRD* data = (DATA_HYBRD*) malloc(sizeof(DATA_HYBRD));

  *voiddata = (void*)data;
  ASSERT(data, "allocationHybrdData() failed!");

  data->initialized = 0;
  data->resScaling = (double*) malloc(*size*sizeof(double));
  data->useXScaling = 1;

  data->n = *size;
  data->x = (double*) malloc(*size*sizeof(double));
  data->fvec = (double*) calloc(*size,sizeof(double));
  data->xtol = 1e-12;
  data->maxfev = *size*10000;
  data->ml = *size - 1;
  data->mu = *size - 1;
  data->epsfcn = 1e-12;
  data->diag = (double*) malloc(*size*sizeof(double));
  data->diagres = (double*) malloc(*size*sizeof(double));
  data->mode = 1;
  data->factor = 100.0;
  data->nprint = 0;
  data->info = 0;
  data->nfev = 0;
  data->fjac = (double*) malloc((*size**size)*sizeof(double));
  data->fjacobian = (double*) malloc((*size**size)*sizeof(double));
  data->ldfjac = *size;
  data->r__ = (double*) malloc(((*size*(*size+1))/2)*sizeof(double));
  data->lr = (*size*(*size + 1)) / 2;
  data->qtf = (double*) malloc(*size*sizeof(double));
  data->wa1 = (double*) malloc(*size*sizeof(double));
  data->wa2 = (double*) malloc(*size*sizeof(double));
  data->wa3 = (double*) malloc(*size*sizeof(double));
  data->wa4 = (double*) malloc(*size*sizeof(double));

  ASSERT(*voiddata, "allocationHybrdData() voiddata failed!");
  return 0;
}

/*! \fn free memory for nonlinear solver hybrd
 *
 */
int freeHybrdData(void **voiddata){

  DATA_HYBRD* data = (DATA_HYBRD*) *voiddata;

  free(data->resScaling);
  free(data->x);
  free(data->fvec);
  free(data->diag);
  free(data->diagres);
  free(data->fjac);
  free(data->fjacobian);
  free(data->r__);
  free(data->qtf);
  free(data->wa1);
  free(data->wa2);
  free(data->wa3);
  free(data->wa4);

  return 0;
}


/*! \fn wrapper function of tensolve for the residual Function
 *   tensolve calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *
 */
void wrapper_fvec_hybrd(int* n, double* x, double* f, int* iflag, void* data){

  int i,currentSys = ((DATA*)data)->simulationInfo.currentNonlinearSystemIndex;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)(((SOLVER_DATA*)systemData->solverData)->hybrdData);

  ASSERT(solverData,"SolverData not valid!");
  /* Debug output */
  if (DEBUG_STREAM(LOG_NONLIN_SYS_V)){
    INFO(LOG_NONLIN_SYS_V,"Call residual function:");
    INDENT(LOG_NONLIN_SYS_V);
    INFO(LOG_NONLIN_SYS_V,"Iteration variable values scaled:");
    INDENT(LOG_NONLIN_SYS_V);
    for(i=0;i<*n;i++){
      INFO2(LOG_NONLIN_SYS_V, " [%d]. %.15e", i, x[i]);
    }
    RELEASE(LOG_NONLIN_SYS_V);
  }

  /* re-scaling x vector */
  if (solverData->useXScaling ){
    for(i=0;i<*n;i++){
      x[i] = x[i]*systemData->nlsxScaling[i];
    }
  }

  /* Debug output */

  if (DEBUG_STREAM(LOG_NONLIN_SYS_V)){
    INFO(LOG_NONLIN_SYS_V,"Iteration variable values:");
    INDENT(LOG_NONLIN_SYS_V);
    for(i=0;i<*n;i++){
      INFO2(LOG_NONLIN_SYS_V, " [%d]. %.15e", i, x[i]);
    }
    RELEASE(LOG_NONLIN_SYS_V);
  }

  /* call residual function */
  (*((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys].residualFunc)(data,
      x, f, iflag);

  /* Scaling x vector */
  if (solverData->useXScaling ){
    for(i=0;i<*n;i++){
      x[i] = (1.0/systemData->nlsxScaling[i]) * x[i];
    }
  }

  /* Debug output */

  if (DEBUG_STREAM(LOG_NONLIN_SYS_V)){
    INFO(LOG_NONLIN_SYS_V,"Residual values:");
    INDENT(LOG_NONLIN_SYS_V);
    for(i=0;i<*n;i++){
      INFO2(LOG_NONLIN_SYS_V, " [%d]. %.15e", i, f[i]);
    }
    RELEASE(LOG_NONLIN_SYS_V);
    RELEASE(LOG_NONLIN_SYS_V);
  }

}


/*! \fn printStatus
 *
 *  \param  [in]  [solverData]
 *                [logLevel]
 *
 *  \author wbraun
 */
void printStatus(DATA_HYBRD *solverData, const int *nfunc_evals,const double *xerror,const double *xerror_scaled, const int logLevel){
  int i;

  INDENT(logLevel);
  INDENT(logLevel);
  INFO3(logLevel, "nfunc = %d +++ error = %.20e +++ error_scaled = %.20e", *nfunc_evals, *xerror, *xerror_scaled);
  RELEASE(logLevel);
  for (i = 0; i < solverData->n; i++) {
    INDENT(logLevel);
    INFO3(logLevel, "x[%d] = %.20e\n\tscaling factor = %f", i, solverData->x[i],solverData->diag[i]);
    RELEASE(logLevel);
  }
  for (i = 0; i < solverData->n; i++) {
    INDENT(logLevel);
    INFO3(logLevel, "res[%d] = %.20e\n\tscaling factor = %f", i, solverData->fvec[i], solverData->resScaling[i]);
    RELEASE(logLevel);
  }
  RELEASE(logLevel);
}


/*! \fn solve non-linear system with hybrd method
 *
 *  \param  [in]  [data]
 *                [sysNumber] index of the corresponing non-linear system
 *
 *  \author wbraun
 */
int solveHybrd(DATA *data, int sysNumber) {


  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.nonlinearSystemData[sysNumber]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)(((SOLVER_DATA*)systemData->solverData)->hybrdData);
  /* We are given the number of the non-linear system. We want to look it up among all equations. */
  int eqSystemNumber = data->modelData.equationInfo_reverse_prof_index[systemData->simProfEqNr];

  int i, iflag=0;
  double xerror, xerror_scaled;
  int success = 0;
  double local_tol = 1e-12;
  double initial_factor = solverData->factor;
  int nfunc_evals = 0;
  int continuous = 1;

  int giveUp = 0;
  int retries = 0;
  int retries2 = 0;
  int retries3 = 0;

  /* debug output */
  if(DEBUG_STREAM(LOG_NONLIN_SYS))
  {
    INFO2(LOG_NONLIN_SYS, "Start solving Non-Linear System %s at time %e",
      data->modelData.equationInfo[eqSystemNumber].name,
      data->localData[0]->timeValue);
    INDENT(LOG_NONLIN_SYS);

    INDENT(LOG_NONLIN_SYS);
    for(i = 0; i < solverData->n; i++)
    {
      INDENT(LOG_NONLIN_SYS);
      INFO2(LOG_NONLIN_SYS, "x[%d] = %.20e", i, systemData->nlsx[i]);
      INDENT(LOG_NONLIN_SYS);
      INFO3(LOG_NONLIN_SYS, "scaling = %f +++ old = %.20e +++ extrapolated = %.20e",
            systemData->nlsxScaling[i], systemData->nlsxOld[i], systemData->nlsxExtrapolation[i]);
      RELEASE(LOG_NONLIN_SYS);
      RELEASE(LOG_NONLIN_SYS);
    }
    RELEASE(LOG_NONLIN_SYS);
  }

  /* set x vector */
  if (data->simulationInfo.discreteCall)
    memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
  else
    memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));


  /* evaluate with discontinuities */
  {
    int scaling = solverData->useXScaling;
    if (scaling)
      solverData->useXScaling = 0;
    wrapper_fvec_hybrd(&solverData->n, solverData->x,  solverData->fvec, &iflag,  data);
    if (scaling)
      solverData->useXScaling = 1;
  }
 

  /* start solving loop */
  while (!giveUp && !success) {

    /* debug output */
    INFO(LOG_NONLIN_SYS_V,"Iteration variable values scaled:");
    INDENT(LOG_NONLIN_SYS_V);
    for(i=0;i<solverData->n;i++){
      INFO2(LOG_NONLIN_SYS_V, " [%d]. %.15e", i, solverData->x[i]);
    }
    RELEASE(LOG_NONLIN_SYS_V);

    /* Scaling x vector */
    if (solverData->useXScaling){
      for(i=0;i<solverData->n;i++){
        solverData->x[i] = (1.0/systemData->nlsxScaling[i]) * solverData->x[i];
      }
    }

    /* debug output */
    INFO(LOG_NONLIN_SYS_V,"Iteration variable values scaled:");
    INDENT(LOG_NONLIN_SYS_V);
    for(i=0;i<solverData->n;i++){
      INFO2(LOG_NONLIN_SYS_V, " [%d]. %.15e", i, solverData->x[i]);
    }
    RELEASE(LOG_NONLIN_SYS_V);


    /* set residual function continuous
     */
    if (continuous)
      ((DATA*)data)->simulationInfo.solveContinuous = 1;
    else
      ((DATA*)data)->simulationInfo.solveContinuous = 0;

    giveUp = 1;
    _omc_hybrd_(wrapper_fvec_hybrd, &solverData->n, solverData->x,
        solverData->fvec, &solverData->xtol, &solverData->maxfev, &solverData->ml,
        &solverData->mu, &solverData->epsfcn, solverData->diag, &solverData->mode,
        &solverData->factor, &solverData->nprint, &solverData->info,
        &solverData->nfev, solverData->fjac, solverData->fjacobian, &solverData->ldfjac,
        solverData->r__, &solverData->lr, solverData->qtf, solverData->wa1,
        solverData->wa2, solverData->wa3, solverData->wa4, data);

    /* set residual function continuous */
    if (continuous)
      ((DATA*)data)->simulationInfo.solveContinuous = 0;
    else
      ((DATA*)data)->simulationInfo.solveContinuous = 1;

    /* re-scaling x vector */
    if (solverData->useXScaling){
      for(i=0;i<solverData->n;i++){
        solverData->x[i] = solverData->x[i]*systemData->nlsxScaling[i];
      }
    }
    /* check for proper inputs */
    if (solverData->info == 0) {
      printErrorEqSyst(IMPROPER_INPUT, data->modelData.equationInfo[eqSystemNumber],
          data->localData[0]->timeValue);
      data->simulationInfo.found_solution = -1;
    }

    /* evaluate with discontinuities */
    if (data->simulationInfo.discreteCall){
      int scaling = solverData->useXScaling;
      if (scaling)
        solverData->useXScaling = 0;

      ((DATA*)data)->simulationInfo.solveContinuous = 0;

      wrapper_fvec_hybrd(&solverData->n, solverData->x,  solverData->fvec, &iflag,  data);

      if (scaling)
        solverData->useXScaling = 1;

      storeRelations(data);
    }

    /* Debug output */
    if (DEBUG_STREAM(LOG_NONLIN_SYS_V)) {
      int i,j,l=0;
      INFO(LOG_NONLIN_SYS_V,"Jacobi-Matrix");
      for(i=0;i<solverData->n;i++){
        printf("%d : ", i);
        for(j=0;j<solverData->n;j++){
          printf("%e ",solverData->fjac[l++]);
        }
        printf("\n");
      }
    }

    /* Scaling residual vector */
    {
      int i,j,l=0;
      INDENT(LOG_NONLIN_SYS_V);
      INFO(LOG_NONLIN_SYS_V, "scaling factors for residual vector");
      INDENT(LOG_NONLIN_SYS_V);
      for(i=0;i<solverData->n;i++){
        solverData->resScaling[i] = 1e-16;
        for(j=0;j<solverData->n;j++){
          solverData->resScaling[i] = (fabs(solverData->fjacobian[l]) > solverData->resScaling[i])
              ? fabs(solverData->fjacobian[l]) : solverData->resScaling[i];
          l++;
        }
        INFO2(LOG_NONLIN_SYS_V, "[%d] : %.20e", i, solverData->resScaling[i]);
        solverData->resScaling[i] = solverData->fvec[i] * (1 / solverData->resScaling[i]);
      }
      RELEASE(LOG_NONLIN_SYS_V);
      RELEASE(LOG_NONLIN_SYS_V);
    }

    /* check for error  */
    xerror_scaled = enorm_(&solverData->n, solverData->resScaling);
    xerror = enorm_(&solverData->n, solverData->fvec);
    if (solverData->info == 1 && (xerror > local_tol && xerror_scaled > local_tol))
      solverData->info = 4;


    /* solution found */
    if (solverData->info == 1 || xerror <= local_tol || xerror_scaled <= local_tol) {
      success = 1;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        RELEASE(LOG_NONLIN_SYS);
        INFO2(LOG_NONLIN_SYS, "*** System solved ***\n%d retries +++ %d restarts", retries,
            retries2+retries3);

        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS);

      }
    /* try to vary the initial values */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries < 1) {
        for (i = 0; i < solverData->n; i++) {
          solverData->x[i] += systemData->nlsxScaling[i] * 0.1;
        };
        solverData->useXScaling = 1;
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
          INFO(LOG_NONLIN_SYS, 
              " - iteration making no progress:\t vary solution point by 1%%.");
          printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
        }
    /* try to deactivate x-Scaling */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries < 2) {
        solverData->useXScaling = 0;
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
          INFO(LOG_NONLIN_SYS,
              " - iteration making no progress:\t try without scaling at all.");
          printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
        }
    /* first try to decrease factor*/
    } else if ((solverData->info == 4 || solverData->info == 5) && retries < 5) {
        /* set x vector */
        if (data->simulationInfo.discreteCall)
          memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
        else
          memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

        solverData->factor = solverData->factor / 10.0;

        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
          INFO1(LOG_NONLIN_SYS, " - iteration making no progress:\t decreasing initial step bound to %f.",
              solverData->factor);
          printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
        }
    /* try to solve non-continuous
     * work-a-round: since other wise some model does
     * stuck in event iteration. e.g.: Modelica.Mechanics.Rotational.Examples.HeatLosses
     */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries < 6  && data->simulationInfo.discreteCall) {

      memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));

      retries++;
      solverData->useXScaling = 1;
      solverData->factor = initial_factor;

      /* try to solve a discontinuous system */
      continuous = 0;

      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        INFO(LOG_NONLIN_SYS, " - iteration making no progress:\t try to solve a discontinuous system.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
      }
    /* Then try with old values (instead of extrapolating )*/
    } else if ((solverData->info == 4 || solverData->info == 5) && retries2 < 1) {
      /* set x vector */
      memcpy(solverData->x, systemData->nlsxOld, solverData->n*(sizeof(double)));

      continuous = 1;
      solverData->factor = initial_factor;

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        INFO(LOG_NONLIN_SYS, " - iteration making no progress:\t use old values instead extrapolated.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
      }
    /* try to vary the initial values */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries2 < 2) {
      /* set x vector */
      if (data->simulationInfo.discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] *= 1.01;
      };

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        INFO(LOG_NONLIN_SYS,
            " - iteration making no progress:\t vary initial point by adding 1%%.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
      }
    /* try to vary the initial values */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries2 < 3) {
      /* set x vector */
      if (data->simulationInfo.discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] *= 0.99;
      };

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        INFO(LOG_NONLIN_SYS, " - iteration making no progress:\t vary initial point by -1%%.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
      }
    /* try to vary the initial values */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries2 < 4) {
      /* set x vector */
      memcpy(solverData->x, systemData->nlsxScaling, solverData->n*(sizeof(double)));
      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        INFO(LOG_NONLIN_SYS, " - iteration making no progress:\t try scaling factor as initial point.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
      }
    /* try own scaling factors */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries2 < 5) {
      /* set x vector */
      if (data->simulationInfo.discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      for (i = 0; i < solverData->n; i++) {
        solverData->diag[i] = fabs(solverData->resScaling[i]);
        if (solverData->diag[i] <= 0)
          solverData->diag[i] = 1e-16;
      }
      retries = 0;
      retries2++;
      giveUp = 0;
      solverData->mode = 2;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        INFO(LOG_NONLIN_SYS, " - iteration making no progress:\t try with own scaling factors.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
      }
    /* try without internal scaling */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries3 < 1) {
      /* set x vector */
      if (data->simulationInfo.discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      for (i = 0; i < solverData->n; i++)
        solverData->diag[i] = 1.0;

      retries = 0;
      retries2 = 0;
      retries3++;
      solverData->mode = 2;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        INFO(LOG_NONLIN_SYS, " - iteration making no progress:\t disable solver internal scaling.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
      }
    /* try to reduce the tolerance a bit */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries3 < 6) {
      /* set x vector */
      if (data->simulationInfo.discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      /* reduce tolarance */
      local_tol = local_tol*10;

      solverData->factor = initial_factor;

      retries = 0;
      retries2 = 0;
      retries3++;

      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        INFO1(LOG_NONLIN_SYS, " - iteration making no progress:\t reduce the tolerance slightly to %e.",local_tol);
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS_V);
      }
    } else if (solverData->info >= 2 && solverData->info <= 5) {
      data->simulationInfo.found_solution = -1;

      /* while the initialization it's ok to every time a solution */
      if (!data->simulationInfo.initial){
        printErrorEqSyst(ERROR_AT_TIME, data->modelData.equationInfo[eqSystemNumber], data->localData[0]->timeValue);
      }
      if (DEBUG_STREAM(LOG_NONLIN_SYS)) {
        RELEASE(LOG_NONLIN_SYS);
        INFO1(LOG_NONLIN_SYS, "### No Solution! ###\n after %d restarts", retries+retries2+retries3);
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NONLIN_SYS);
      }
    }
  }


  /* take the best approximation */
  memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));


  /* reset some solving data */
  solverData->factor = initial_factor;

  return success;
}

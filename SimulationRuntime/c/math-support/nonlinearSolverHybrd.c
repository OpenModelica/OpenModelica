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

#include "nonlinearSystem.h"
#include "nonlinearSolverHybrd.h"





/*! \fn allocate memory for nonlinear system solver hybrd
 *
 */
int allocateHybrdData(int* size, void** voiddata){

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

  /* re-scaling x vector */
  if (solverData->useXScaling ){
    for(i=0;i<*n;i++){
      x[i] = x[i]*systemData->nlsxScaling[i];
    }
  }

  (*((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys].residualFunc)(data,
      x, f, iflag);

  /* Scaling x vector */
  if (solverData->useXScaling ){
    for(i=0;i<*n;i++){
      x[i] = (1.0/systemData->nlsxScaling[i]) * x[i];
    }
  }
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

  int i;
  double xerror, xerror_scaled;
  char success = 0;
  double local_tol = 1e-12;
  double initial_factor = solverData->factor;
  int nfunc_evals = 0;

  int giveUp = 0;
  int retries = 0;
  int retries2 = 0;
  int retries3 = 0;

  memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));


  if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
    INFO2("Start solving Non-Linear System %s at time %f",
        data->modelData.equationInfo[systemData->simProfEqNr].name,
        data->localData[0]->timeValue);
    if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
      for (i = 0; i < solverData->n; i++) {
        INFO_AL1("\t%d:", i);
        INFO_AL2("\tx-scale = %e\tx = %e",
            systemData->nlsxScaling[i], systemData->nlsx[i]);
        INFO_AL2("\tnlsxOld = %e\tExtrapolation = %e",
            systemData->nlsxOld[i], systemData->nlsxExtrapolation[i]);
      }
    }
  }

  /* start solving loop */
  while (!giveUp && !success) {

    /* Scaling x vector */
    if (solverData->useXScaling){
      for(i=0;i<solverData->n;i++){
        solverData->x[i] = (1.0/systemData->nlsxScaling[i]) * solverData->x[i];
      }
    }


    giveUp = 1;
    _omc_hybrd_(wrapper_fvec_hybrd, &solverData->n, solverData->x,
        solverData->fvec, &solverData->xtol, &solverData->maxfev, &solverData->ml,
        &solverData->mu, &solverData->epsfcn, solverData->diag, &solverData->mode,
        &solverData->factor, &solverData->nprint, &solverData->info,
        &solverData->nfev, solverData->fjac, solverData->fjacobian, &solverData->ldfjac,
        solverData->r__, &solverData->lr, solverData->qtf, solverData->wa1,
        solverData->wa2, solverData->wa3, solverData->wa4, data);


    /* re-scaling x vector */
    if (solverData->useXScaling){
      for(i=0;i<solverData->n;i++){
        solverData->x[i] = solverData->x[i]*systemData->nlsxScaling[i];
      }
    }
    /* check for proper inputs */
    if (solverData->info == 0) {
      printErrorEqSyst(IMPROPER_INPUT, data->modelData.equationInfo[systemData->simProfEqNr],
          data->localData[0]->timeValue);
      data->simulationInfo.found_solution = -1;
    }

    if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
      int i,j,l=0;
      printf("Jacobi-Matrix\n");
      for(i=0;i<solverData->n;i++){
        printf("%d : ", i);
        for(j=0;j<solverData->n;j++){
          printf("%e ",solverData->fjac[l++]);
        }
        printf("\n");
      }
    }

    /* Scaling Residual vector */
    {
      int i,j,l=0;
      for(i=0;i<solverData->n;i++){
        solverData->resScaling[i] = 1e-16;
        for(j=0;j<solverData->n;j++){
          solverData->resScaling[i] = (fabs(solverData->fjacobian[l]) > solverData->resScaling[i])
              ? fabs(solverData->fjacobian[l]) : solverData->resScaling[i];
          l++;
        }
        solverData->resScaling[i] = solverData->fvec[i] * (1 / solverData->resScaling[i]);
      }
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
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL("### System solved! ###");
        INFO_AL2("\tSolution after:\t%d retries\t%d restarts", retries,
            retries2+retries3);
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
        }
      }
      }
    /* first try to decrease factor*/
    } else if ((solverData->info == 4 || solverData->info == 5) && retries < 3) {
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        solverData->factor = solverData->factor / 10.0;
        if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
          INFO_AL1(" - iteration making no progress:\tdecrease factor to %f",
              solverData->factor);
          INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
          if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
            for (i = 0; i < solverData->n; i++) {
              INFO_AL1("\t%d:", i);
              INFO_AL2("\tdiag = %e\tx = %e",
                  solverData->diag[i], solverData->x[i]);
              INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                  solverData->resScaling[i], solverData->fvec[i]);
          }
          }
        }
    /* try to vary the initial values */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries < 5) {
        for (i = 0; i < solverData->n; i++) {
          solverData->x[i] += systemData->nlsxScaling[i] * 0.1;
        };
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
          INFO_AL(
              " - iteration making no progress:\tvary solution point by +1%%");
          INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
          if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
            for (i = 0; i < solverData->n; i++) {
              INFO_AL1("%d:", i);
              INFO_AL2("x-scale = %e\tx = %e",
                  systemData->nlsxScaling[i], solverData->x[i]);
              INFO_AL2("residual Scale = %e\tresidual = %e",
                  solverData->diag[i], solverData->fvec[i]);
            }
          }
        }
    /* try to deactivate x-Scaling */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries < 4) {
        solverData->useXScaling = 0;
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
          INFO_AL(
              " - iteration making no progress:\tdeactivaed Xscaling +1%%");
          INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
          if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
            for (i = 0; i < solverData->n; i++) {
              INFO_AL1("%d:", i);
              INFO_AL2("x-scale = %e\tx = %e",
                  systemData->nlsxScaling[i], solverData->x[i]);
              INFO_AL2("residual Scale = %e\tresidual = %e",
                  solverData->diag[i], solverData->fvec[i]);
            }
          }
        }
    /* try to vary the initial values */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries2 < 1) {
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] = systemData->nlsxExtrapolation[i] * 1.01;
      };
      solverData->useXScaling = 1;
      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(
            " - iteration making no progress:\t*restart* vary initial point by adding 1%%");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    /* try to vary the initial values */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries2 < 2) {
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] = systemData->nlsxExtrapolation[i] * 0.99;
      };
      solverData->useXScaling = 1;
      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(" - iteration making no progress:\t*restart* vary initial point by -1%%");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    /* Then try with old values (instead of extrapolating )*/
    } else if ((solverData->info == 4 || solverData->info == 5) && retries2 < 3) {
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] = systemData->nlsxOld[i];
      }
      solverData->factor = initial_factor;
      solverData->useXScaling = 1;
      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(" - iteration making no progress:\t*restart*use old values instead extrapolated");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    /* try to use own calculates scaling variables */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries3 < 1) {
      for (i = 0; i < solverData->n; i++) {
        solverData->diag[i] = fabs(solverData->resScaling[i]);
        if (solverData->diag[i] <= 0)
          solverData->diag[i] = 1e-16;
      }
      solverData->factor = initial_factor;
      solverData->useXScaling = 1;
      retries = 0;
      retries2 = 0;
      solverData->mode = 2;
      retries3++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(" - iteration making no progress:\tchanged to own scaling factors");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    /* try to use own calculates scaling variables */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries3 < 2) {
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] = systemData->nlsxScaling[i];
      }
      solverData->factor = initial_factor;
      solverData->useXScaling = 1;
      retries = 0;
      retries2 = 0;
      solverData->mode = 1;
      retries3++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(" - iteration making no progress:\tchange scaling factors");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
      /* try to use own calculates scaling variables */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries3 < 3) {
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] = 1.0;
      }
      solverData->factor = initial_factor;
      solverData->useXScaling = 1;
      retries = 0;
      retries2 = 0;
      solverData->mode = 1;
      retries3++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(" - iteration making no progress:\tchange scaling factors");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    } else if ((solverData->info == 4 || solverData->info == 5) && retries3 < 4) {
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] = 0.0;
      }
      solverData->factor = initial_factor;
      solverData->useXScaling = 1;
      retries = 0;
      retries2 = 0;
      solverData->mode = 1;
      retries3++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(" - iteration making no progress:\tchange scaling factors");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    } else if ((solverData->info == 4 || solverData->info == 5) && retries3 < 5) {
      for (i = 0; i < solverData->n; i++) {
        solverData->x[i] = systemData->nlsxExtrapolation[i];
        solverData->diag[i] = 1.0;
      }
      solverData->factor = initial_factor;
      solverData->useXScaling = 1;
      retries = 0;
      retries2 = 0;
      retries3++;
      solverData->mode = 2;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(" - iteration making no progress:\tremove scaling factor at all!");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    /* try reduce the tolerance a bit */
    } else if ((solverData->info == 4 || solverData->info == 5) && retries3 < 7) {
      solverData->factor = initial_factor;
      solverData->useXScaling = 1;
      local_tol = local_tol*10;
      retries = 0;
      retries2 = 0;
      retries3++;
      solverData->mode = 2;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL(" - iteration making no progress:\tremove scaling factor at all!");
        INFO_AL3("\tnfunc = %d\terror = %e\terror_scaled = %e", nfunc_evals, xerror, xerror_scaled );
        if (DEBUG_FLAG(LOG_NONLIN_SYS_V)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tdiag = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    } else if (solverData->info >= 2 && solverData->info <= 5) {
      data->simulationInfo.found_solution = -1;

      /* while the initialization it's ok to every time a solution */
      if (!data->simulationInfo.initial){
        data->simulationInfo.modelErrorCode = ERROR_NONLINSYS;
        printErrorEqSyst(ERROR_AT_TIME, data->modelData.equationInfo[systemData->simProfEqNr], data->localData[0]->timeValue);
      }
      if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
        INFO_AL2("\tNo Solution after:\t%d retries\t%d restarts", retries,
            retries2+retries3);
        INFO_AL2("\tnfunc = %d\terror = %e", nfunc_evals, xerror);
        if (DEBUG_FLAG(LOG_NONLIN_SYS)) {
          for (i = 0; i < solverData->n; i++) {
            INFO_AL1("\t%d:", i);
            INFO_AL2("\tx-scale = %e\tx = %e",
                solverData->diag[i], solverData->x[i]);
            INFO_AL2("\tresidual Scale = %e\tresidual = %e",
                solverData->resScaling[i], solverData->fvec[i]);
          }
        }
      }
    }
  }


  /* take the best approximation */
  memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));


  /* reset some solving data */
  solverData->factor = initial_factor;

  return 0;
}

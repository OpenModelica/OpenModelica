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

/*
 * Developed by:
 * FH-Bielefeld
 * Developer: Vitalij Ruge
 * Contact: vitalij.ruge@fh-bielefeld.de
 */


#include "../localFunction.h"
#include "../ipoptODEstruct.h"
#include "../simulation/solver/dassl.h"
#include "../../simulation/options.h"
#include "../../simulation/results/simulation_result.h"
#include "simulation/solver/external_input.h"
#include "simulation/solver/model_help.h"

#ifdef WITH_IPOPT

static int initial_guess_ipopt_cflag(IPOPT_DATA_ *iData,char* cflags);
static int initial_guess_ipopt_sim(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo);
static int pre_ipopt_sim(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo);
static int optimizer_time_setings_update(IPOPT_DATA_ *iData);
static int smallIntSolverStep(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo, double stime);

/*!
 *  create initial guess
 *  author: Vitalij Ruge
 **/
int initial_guess_ipopt(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo)
{
  char *cflags;
  int opt = 1;
  cflags = (char*)omc_flagValue[FLAG_IPOPT_INIT];

  if(cflags){
    opt = initial_guess_ipopt_cflag(iData, cflags);
    if(opt != 1)
      return 0;
  }
  if(opt == 1)
    initial_guess_ipopt_sim(iData, solverInfo);

  return 0;

}

/*!
 *  create initial guess clfag option
 *  author: Vitalij Ruge
 **/
static int initial_guess_ipopt_cflag(IPOPT_DATA_ *iData,char* cflags)
{
  if(!strcmp(cflags,"const") || !strcmp(cflags,"CONST")){
    int i, id;

    for(i = 0, id=0; i<iData->dim.NV;i++,++id){
      if(id >=iData->dim.nv)
        id = 0;

      if(id <iData->dim.nx){
        iData->v[i] = iData->data->localData[0]->realVars[id]*iData->scaling.scalVar[id];
      }else if(id< iData->dim.nv){
        iData->v[i] = iData->helper.start_u[id-iData->dim.nx]*iData->scaling.scalVar[id];
      }
    }
    iData->sopt.updateM = 1;
    refreshSimData(iData->v, iData->v + iData->dim.nx, 0, iData);

    for(i = 0; i< iData->dim.nt; ++i)
      memcpy(iData->evalf.v[i], iData->data->localData[0]->realVars, sizeof(double)*iData->dim.nReal);

    infoStreamPrint(LOG_IPOPT, 0, "Using const trajectory as initial guess.");
    return 0;

  }else if(!strcmp(cflags,"sim") || !strcmp(cflags,"SIM")){

    infoStreamPrint(LOG_IPOPT, 0, "Using simulation as initial guess.");
    return 1;
  }

  warningStreamPrint(LOG_STDOUT, 1, "not support ipopt_init=%s", cflags);
  return 1;
}

/*!
 *  create initial guess dasslColorSymJac
 *  author: Vitalij Ruge
 **/
static int initial_guess_ipopt_sim(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo)
{
  double *u0;
  int i,j,k,ii,jj,id;
  double *v;
  long double tol;
  short printGuess;

  DATA* data = iData->data;
  SIMULATION_INFO *sInfo = &(data->simulationInfo);
  OPTIMIZER_DIM_VARS* dim = &iData->dim;
  OPTIMIZER_EVALF *evalf = &iData->evalf;

  if(!data->simulationInfo.external_input.active){
     externalInputallocate(data);
  }

   /* Initial DASSL solver */
   DASSL_DATA* dasslData = (DASSL_DATA*) malloc(sizeof(DASSL_DATA));

   tol = data->simulationInfo.tolerance;
   data->simulationInfo.tolerance = fmin(fmax(tol,1e-8),1e-3);
   infoStreamPrint(LOG_SOLVER, 0, "Initializing DASSL");
   sInfo->solverMethod = "dassl";
   solverInfo->solverMethod = S_DASSL;
   dassl_initial(iData->data, solverInfo, dasslData);
   solverInfo->solverMethod = S_OPTIMIZATION;
   solverInfo->solverData = dasslData;

   u0 = iData->helper.start_u;
   v = iData->v;

   for(ii=dim->nx,j=0; j < dim->nu; ++j, ++ii){
     v[ii] = u0[j]*iData->scaling.scalVar[j + dim->nx];
   }

   if(!data->simulationInfo.external_input.active)
     for(i = 0; i<dim->nu;++i)
       data->simulationInfo.inputVars[i] = u0[i];
   else
     externalInputUpdate(data);

   memcpy(evalf->v[0], data->localData[0]->realVars, sizeof(double)*iData->dim.nReal);
   if(iData->sopt.preSim){
     printf("\n========================================================");
     printf("\nstart pre simulation");
     printf("\n--------------------------------------------------------");
     printf("\nfrom %g to %g", (double)iData->dtime.t0, (double)iData->dtime.startTimeOpt );
     pre_ipopt_sim(iData, solverInfo);
     printf("\nfinished pre simulation");
     printf("\n========================================================\n");
   }

   printGuess = (short)(ACTIVE_STREAM(LOG_INIT) && !ACTIVE_STREAM(LOG_SOLVER));
   if(printGuess){
     printf("\nInitial Guess");
     printf("\n========================================================\n");
     printf("\ndone: time[%i] = %g",0,(double)iData->dtime.time[0]);
   }

   for(i=0, k=1, v=iData->v + dim->nv; i<dim->nsi; ++i){
     for(jj=0; jj<dim->deg; ++jj, ++k){
      smallIntSolverStep(iData, solverInfo, (double)iData->dtime.time[k]);

       if(printGuess)
         printf("\ndone: time[%i] = %g\n", k, (double)iData->dtime.time[k]);

       for(j=0; j< dim->nx; ++j){
         v[j] = data->localData[0]->realVars[j] * iData->scaling.scalVar[j];
       }
       for(; j< dim->nv; ++j)
         v[j] = data->simulationInfo.inputVars[j-dim->nx] * iData->scaling.scalVar[j];

       memcpy(evalf->v[k], data->localData[0]->realVars, sizeof(double)*iData->dim.nReal);

       v += dim->nv;
     }
  }

  for(i = 0, id=0; i<dim->NV;i++,++id){
    if(id >=dim->nv)
    id = 0;
    if(id <dim->nx){
     iData->v[i] =fmin(fmax(iData->bounds.vmin[id],iData->v[i]),iData->bounds.vmax[id]);
    }else if(id< dim->nv){
     iData->v[i] = fmin(fmax(iData->bounds.vmin[id],iData->v[i]),iData->bounds.vmax[id]);
    }
  }

  if(printGuess){
    printf("\n--------------------------------------------------------");
    printf("\nfinished: Initial Guess");
    printf("\n========================================================\n");
  }

  dassl_deinitial(solverInfo->solverData);
  externalInputFree(data);
  data->simulationInfo.external_input.active = 0;

  solverInfo->solverData = (void*)iData;
  sInfo->solverMethod = "optimization";
  data->simulationInfo.tolerance = tol;

  return 0;
}

static int pre_ipopt_sim(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo)
{
   int k = 1,i,j,err;
   double t;
   DATA * data = iData->data;
   
   if(iData->dtime.time[0] > iData->dtime.startTimeOpt)
    iData->dtime.time[0] = iData->dtime.startTimeOpt;
   solverInfo->currentTime = iData->dtime.time[0];

   while(iData->data->localData[0]->timeValue < iData->dtime.startTimeOpt){
     t = iData->dtime.time[k];
     if(t>iData->dtime.startTimeOpt){
       t = iData->dtime.startTimeOpt;
       solverInfo->currentTime = iData->data->localData[0]->timeValue;
      }

     smallIntSolverStep(iData, solverInfo, t);
     sim_result.emit(&sim_result,data);
     ++k; 
    }
  iData->dtime.t0 = iData->data->localData[0]->timeValue;

  /*ToDo*/
  for(i=0; i< iData->dim.nx; ++i)
  {
    iData->bounds.Vmin[i] = iData->bounds.Vmax[i] = iData->data->localData[1]->realVars[i]*iData->scaling.scalVar[i];
    iData->v[i] = iData->bounds.Vmin[i];
  }
  for(j=0; i< iData->dim.nv; ++i,++j){
    iData->bounds.Vmin[i] = iData->bounds.Vmax[i] = data->simulationInfo.inputVars[j]*iData->scaling.scalVar[i];
    iData->v[i] = iData->bounds.Vmin[i];
  }
  optimizer_time_setings_update(iData);

  return 0;
}

static int optimizer_time_setings_update(IPOPT_DATA_ *iData)
{
  int i,k,id,j;
  long double t;
  OPTIMIZER_MBASE *mbase = &iData->mbase;
  OPTIMIZER_TIME *dtime = &iData->dtime;

  assert(iData->dim.nsi > 0);

  dtime->time[0] = dtime->t0;
  dtime->dt[0] = (dtime->tf - dtime->t0)/(iData->dim.nsi);

  t = dtime->t0 + dtime->dt[0];

  for(i=1;i<iData->dim.nsi; ++i){
    dtime->dt[i] = dtime->dt[i-1];
    t += dtime->dt[i];
  }

  dtime->dt[iData->dim.nsi-1] = dtime->dt[0] + (dtime->tf - t);

  for(i = 0, k=0, id=0; i<1; ++i,id += iData->dim.deg)
      for(j =0; j<iData->dim.deg; ++j)
        dtime->time[++k] = dtime->time[id] + mbase->c[0][j]*dtime->dt[i];


  for(; i<iData->dim.nsi; ++i,id += iData->dim.deg)
    for(j =0; j<iData->dim.deg; ++j)
      dtime->time[++k] = dtime->time[id] + mbase->c[1][j]*dtime->dt[i];


  dtime->time[k] = dtime->tf;
  return 0;
}


static int smallIntSolverStep(IPOPT_DATA_ *iData, SOLVER_INFO* solverInfo, double tstop){
  long double a;
  int iter;
  int err, i;

  solverInfo->currentTime = iData->data->localData[0]->timeValue;
  while(solverInfo->currentTime < tstop){
    a = 1.0;
    iter = 0;

    rotateRingBuffer(iData->data->simulationData, 1, (void**) iData->data->localData);
    do{

      solverInfo->currentStepSize = a*(tstop - solverInfo->currentTime);
      err = dassl_step(iData->data, solverInfo);
      a *= 0.5;
      if(++iter >  10){
        warningStreamPrint(LOG_STDOUT, 0, "Initial guess failure at time %.12g", solverInfo->currentTime);
        break;
      }
    }while(err < 0);

    updateContinuousSystem(iData->data);

  }
  return 0;
}



#endif

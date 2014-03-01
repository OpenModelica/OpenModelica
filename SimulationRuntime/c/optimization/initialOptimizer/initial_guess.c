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
  cflags = (char*)omc_flagValue[FLAG_IPOPT_INIT];

  if(cflags){
    if(!initial_guess_ipopt_cflag(iData, cflags))
      return 0;
  }
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
  for(i = 0, id=0; i<iData->NV;i++,++id){
    if(id >=iData->nv)
      id = 0;
    if(id <iData->nx){
      iData->v[i] = iData->data->modelData.realVarsData[id].attribute.start*iData->scalVar[id];
    }else if(id< iData->nv){
      iData->v[i] = iData->start_u[id-iData->nx]*iData->scalVar[id];
    }
  }
    return 0;
  }else if(!strcmp(cflags,"sim") || !strcmp(cflags,"SIM"))
    return 1;

  warningStreamPrint(LOG_STDOUT, 1, "not support ipopt_init=%s", cflags);
  return 1;
}

/*!
 *  create initial guess dasslColorSymJac
 *  author: Vitalij Ruge
 **/
static int initial_guess_ipopt_sim(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo)
{
  double *u0, *x, uu,tmp ,lhs, rhs;
  int i,j,k,ii,jj,id;
  double *v;
  long double tol;
  short printGuess;

  DATA* data = iData->data;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  if(!data->simulationInfo.external_input.active)
     externalInputallocate(data);

   /* Initial DASSL solver */
   DASSL_DATA* dasslData = (DASSL_DATA*) malloc(sizeof(DASSL_DATA));

   tol = data->simulationInfo.tolerance;
   data->simulationInfo.tolerance = fmin(fmax(tol,1e-8),1e-3);
   infoStreamPrint(LOG_SOLVER, 0, "Initializing DASSL");
   sInfo->solverMethod = "dassl";
   solverInfo->solverMethod = S_DASSL;
   dasrt_initial(iData->data, solverInfo, dasslData);
   solverInfo->solverMethod = S_OPTIMIZATION;
   solverInfo->solverData = dasslData;

   u0 = iData->start_u;
   x = data->localData[0]->realVars;
   v = iData->v;

   for(ii=iData->nx,j=0; j < iData->nu; ++j, ++ii){
     u0[j] = fmin(fmax(u0[j],iData->umin[j]),iData->umax[j]);
     v[ii] = u0[j]*iData->scalVar[j + iData->nx];
   }

   if(!data->simulationInfo.external_input.active)
     for(i = 0; i<iData->nu;++i)
       data->simulationInfo.inputVars[i] = u0[i];
   else
     externalInputUpdate(data);

   if(iData->preSim){
   printf("\n========================================================");
     printf("\nstart pre simulation");
     printf("\n--------------------------------------------------------");
     printf("\nfrom %g to %g", iData->t0, iData->startTimeOpt );
     pre_ipopt_sim(iData, solverInfo);
     printf("\nfinished pre simulation");
     printf("\n========================================================\n");
   }

   printGuess = (short)(ACTIVE_STREAM(LOG_INIT) && !ACTIVE_STREAM(LOG_SOLVER));
   if(printGuess){
     printf("\nInitial Guess");
     printf("\n========================================================\n");
   printf("\ndone: time[%i] = %g",0,iData->time[0]);
   }

   for(i=0, k=1, v=iData->v + iData->nv; i<iData->nsi; ++i){
     for(jj=0; jj<iData->deg; ++jj, ++k){
      smallIntSolverStep(iData, solverInfo, iData->time[k]);
     //iData->data->localData[0]->timeValue = solverInfo->currentTime = iData->time[k];

     if(printGuess)
       printf("\ndone: time[%i] = %g", k, iData->time[k]);

     for(j=0; j< iData->nx; ++j)
       v[j] = sData->realVars[j] * iData->scalVar[j];

     for(; j< iData->nv; ++j)
       v[j] = data->simulationInfo.inputVars[j-iData->nx] * iData->scalVar[j];

     v += iData->nv;
     /* updateContinuousSystem(iData->data); */
     rotateRingBuffer(iData->data->simulationData, 1, (void**) iData->data->localData);
     }
  }

  for(i = 0, id=0; i<iData->NV;i++,++id){
    if(id >=iData->nv)
    id = 0;
    if(id <iData->nx){
     iData->v[i] =fmin(fmax(iData->vmin[id],iData->v[i]),iData->vmax[id]);
    }else if(id< iData->nv){
     iData->v[i] = fmin(fmax(iData->vmin[id],iData->v[i]),iData->vmax[id]);
    }
  }

  if(printGuess){
    printf("\n--------------------------------------------------------");
    printf("\nfinished: Initial Guess");
    printf("\n========================================================\n");
  }

  dasrt_deinitial(solverInfo->solverData);
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
   
   if(iData->time[0] > iData->startTimeOpt)
    iData->time[0] = iData->startTimeOpt;
   solverInfo->currentTime = iData->time[0];

   while(iData->data->localData[0]->timeValue < iData->startTimeOpt){
     t = iData->time[k];
     if(t>iData->startTimeOpt){
       t = iData->startTimeOpt;
       solverInfo->currentTime = iData->data->localData[0]->timeValue;
      }

     smallIntSolverStep(iData, solverInfo, t);
     data->simulationInfo.terminal = 1;
     sim_result.emit(&sim_result,data);
     data->simulationInfo.terminal = 0;
     rotateRingBuffer(iData->data->simulationData, 1, (void**) iData->data->localData);
     ++k; 
    }
  iData->t0 = iData->data->localData[0]->timeValue;
  /*ToDo*/
  for(i=0; i< iData->nx; ++i)
  {
    iData->Vmin[i] = (*iData).Vmax[i] = iData->data->localData[1]->realVars[i]*iData->scalVar[i];
    iData->v[i] = iData->Vmin[i];
  }
  for(j=0; i< iData->nv; ++i,++j){
    iData->Vmin[i] = iData->Vmax[i] = data->simulationInfo.inputVars[j]*iData->scalVar[i];
    iData->v[i] = iData->Vmin[i];
  }

  optimizer_time_setings_update(iData);
  return 0;
}

static int optimizer_time_setings_update(IPOPT_DATA_ *iData)
{
  int i,k,id;
  double t;

  iData->time[0] = iData->t0;
  t = iData->t0;
  iData->dt_default = (iData->tf - iData->t0)/(iData->nsi);
  for(i=0;i<iData->nsi; ++i){
    iData->dt[i] = iData->dt_default;
    t = iData->t0 + (i+1)*iData->dt_default;
  }

  iData->dt[iData->nsi-1] = iData->dt_default + (iData->tf - t );

  if(iData->deg == 3){
    for(i = 0,k=0,id=0; i<iData->nsi; ++i,id += iData->deg){
      if(i){
        if(iData->deg == 3){
          iData->time[++k] = iData->time[id] + iData->c1*iData->dt[i];
          iData->time[++k] = iData->time[id] + iData->c2*iData->dt[i];
        }
        iData->time[++k] = iData->time[0]+ (i+1)*iData->dt[i];
      }else{
        if(iData->deg == 3){
          iData->time[++k] = iData->time[id] + iData->e1*iData->dt[i];
          iData->time[++k] = iData->time[id] + iData->e2*iData->dt[i];
        }
      iData->time[++k] = iData->time[0]+ (i+1)*iData->dt[i];
     }
   }
  }
  iData->time[k] = iData->tf;
  return 0;
}

static int smallIntSolverStep(IPOPT_DATA_ *iData, SOLVER_INFO* solverInfo, double tstop){
  long double a;
  int iter;
  int err;

  solverInfo->currentTime = iData->data->localData[1]->timeValue;
  while(solverInfo->currentTime < tstop){
    a = 1.0;
    iter = 0;
    do{

      solverInfo->currentStepSize = a*(tstop - solverInfo->currentTime);
      err = dasrt_step(iData->data, solverInfo);
      a *= 0.5;
      if(++iter >  10)
        break;
    }while(err < 0);

    if(iData->data->localData[0]->timeValue < tstop){
      rotateRingBuffer(iData->data->simulationData, 1, (void**) iData->data->localData);
      solverInfo->currentTime = iData->data->localData[0]->timeValue;
    }else{
      solverInfo->currentTime = tstop;
    }
  }
  return 0;
}



#endif

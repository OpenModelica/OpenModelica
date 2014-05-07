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

/*! InitialGuess.c
 */

#include "../OptimizerData.h"
#include "../OptimizerLocalFunction.h"

#include "../simulation/solver/dassl.h"
#include "../../simulation/options.h"
#include "../../simulation/results/simulation_result.h"
#include "simulation/solver/external_input.h"
#include "simulation/solver/model_help.h"


static int initial_guess_ipopt_cflag(OptData *optData, char* cflags);
static inline void smallIntSolverStep(DATA* data, SOLVER_INFO* solverInfo, double tstop);
static inline void initial_guess_ipopt_sim(OptData *optData, SOLVER_INFO* solverInfo);
static inline void init_ipopt_data(OptData *optData);

/*!
 *  create initial guess
 *  author: Vitalij Ruge
 **/
inline void initial_guess_optimizer(OptData *optData, SOLVER_INFO* solverInfo){

  char *cflags;
  int opt = 1;
  int i, j;

  cflags = (char*)omc_flagValue[FLAG_IPOPT_INIT];

  if(cflags){
    opt = initial_guess_ipopt_cflag(optData, cflags);
  }

  if(opt == 1)
    initial_guess_ipopt_sim(optData, solverInfo);

  init_ipopt_data(optData);
}


/*!
 *  create initial guess dasslColorSymJac
 *  author: Vitalij Ruge
 **/
static inline void initial_guess_ipopt_sim(OptData *optData, SOLVER_INFO* solverInfo)
{
  double *u0;
  int i,j,k,l;
  modelica_real ***v;
  long double tol;
  short printGuess;

  const int nx = optData->dim.nx;
  const int nu = optData->dim.nu;
  const int nv = optData->dim.nv;
  const int np = optData->dim.np;
  const int nsi = optData->dim.nsi;
  const int nReal = optData->dim.nReal;


  DATA* data = optData->data;
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  if(!data->simulationInfo.external_input.active){
     externalInputallocate(data);
  }

   /* Initial DASSL solver */
   DASSL_DATA* dasslData = (DASSL_DATA*) malloc(sizeof(DASSL_DATA));
   tol = data->simulationInfo.tolerance;
   data->simulationInfo.tolerance = fmin(fmax(tol,1e-8),1e-3);

   infoStreamPrint(LOG_SOLVER, 0, "Initial Guess: Initializing DASSL");
   sInfo->solverMethod = "dassl";
   solverInfo->solverMethod = S_DASSL;
   dassl_initial(data, solverInfo, dasslData);
   solverInfo->solverMethod = S_OPTIMIZATION;
   solverInfo->solverData = dasslData;

   u0 = optData->bounds.u0;
   v = optData->v;

   if(!data->simulationInfo.external_input.active)
     for(i = 0; i< nu;++i)
       data->simulationInfo.inputVars[i] = u0[i]/*optData->bounds.scalF[i + nx]*/;

   printGuess = (short)(ACTIVE_STREAM(LOG_INIT) && !ACTIVE_STREAM(LOG_SOLVER));

   if(printGuess){
     printf("\nInitial Guess");
     printf("\n========================================================\n");
     printf("\ndone: time[%i] = %g",0,(double)optData->time.t0);
   }

   for(i = 0, k=1; i < nsi; ++i){
     for(j = 0; j < np; ++j, ++k){
       externalInputUpdate(data);
       smallIntSolverStep(data, solverInfo, (double)optData->time.t[i][j]);

       if(printGuess)
         printf("\ndone: time[%i] = %g", k, (double)optData->time.t[i][j]);

       memcpy(v[i][j], data->localData[0]->realVars, nReal*sizeof(double));

       for(l = 0; l < nx; ++l){

         if( (v[i][j][l] < optData->bounds.vmin[l]*optData->bounds.vnom[l]) || (v[i][j][l] > optData->bounds.vmax[l]*optData->bounds.vnom[l])){
           printf("\n********************************************\n");
           warningStreamPrint(LOG_STDOUT, 0, "Initial guess failure at time %.12g",(double)optData->time.t[i][j]);
           warningStreamPrint(LOG_STDOUT, 0, "%.12g<= %s = %.12g <=.12%g",
               optData->bounds.vmin[l]*optData->bounds.vnom[l],
               data->modelData.realVarsData[l].info.name,v[i][j][l],
               optData->bounds.vmax[l]*optData->bounds.vnom[l]);
           printf("\n********************************************");
           for(; i < nsi; ++i){
             for(j = 0; j < np; ++j){
               memcpy(optData->v[i][j], optData->v0, nReal*sizeof(modelica_real));
             }
           }
           break;
         }
       }
     }
  }

  if(printGuess){
    printf("\n--------------------------------------------------------");
    printf("\nfinished: Initial Guess");
    printf("\n========================================================\n");
  }

  dassl_deinitial(solverInfo->solverData);
  solverInfo->solverData = (void*)optData;
  sInfo->solverMethod = "optimization";
  data->simulationInfo.tolerance = tol;

}


/*!
 *  helper for initial_guess_optimizer (pick up clfag option)
 *  author: Vitalij Ruge
 **/
static int initial_guess_ipopt_cflag(OptData *optData, char* cflags){
  if(!strcmp(cflags,"const") || !strcmp(cflags,"CONST")){
    int i, j;
    const int nsi = optData->dim.nsi;
    const int np = optData->dim.np;
    const int nu = optData->dim.nu;
    const int nReal = optData->dim.nReal;

    for(i = 0; i< nu; ++i )
    optData->data->simulationInfo.inputVars[i] = optData->bounds.u0[i];
    for(i = 0; i < nsi; ++i){
      for(j = 0; j < np; ++j){
        memcpy(optData->v[i][j], optData->v0, nReal*sizeof(modelica_real));
      }
    }

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
 *  init ipopt data struct
 *  author: Vitalij Ruge
 **/
static inline void init_ipopt_data(OptData *optData){
  OptDataIpopt* ipop = &optData->ipop;
  DATA * data = optData->data;
  const int NV = optData->dim.NV;
  const int NRes = optData->dim.NRes;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const int nv = optData->dim.nv;
  const int nc = optData->dim.nc;
  const int nJ = optData->dim.nJ;
  const int nx = optData->dim.nx;
  const int nReal = optData->dim.nReal;

  int i,j,l,shift;

  ipop->vopt =  malloc(NV*sizeof(double));
  ipop->mult_x_L =  calloc(NV, sizeof(double));
  ipop->mult_x_U =  calloc(NV, sizeof(double));

  ipop->gmin =  calloc(NRes, sizeof(double));
  ipop->gmax =  calloc(NRes, sizeof(double));
  ipop->mult_g =  calloc(NRes, sizeof(double));

  for(i = 0, shift = 0; i < nsi; ++i){
    for(j = 0; j < np; ++j, shift+=nv){
      memcpy(data->localData[0]->realVars, optData->v[i][j], nReal*sizeof(double));
      externalInputUpdate(data);
      data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];
    
      for(l = 0; l<nx; ++l)
        ipop->vopt[l + shift] = optData->v[i][j][l]*optData->bounds.scalF[l];

      for(; l< nv; ++l)
        ipop->vopt[l + shift] = data->simulationInfo.inputVars[l-nx] * optData->bounds.scalF[l];

    }
  }

  externalInputFree(data);

  for(j = 0; j< nc; ++j)
    for(i = nx; i < NRes; i += nJ)
      ipop->gmin[i+j] = -1e21;

}

static inline void smallIntSolverStep(DATA* data, SOLVER_INFO* solverInfo, double tstop){
  long double a;
  int iter;
  int err;

  solverInfo->currentTime = data->localData[0]->timeValue;
  while(solverInfo->currentTime < tstop){
    a = 1.0;
    iter = 0;

    rotateRingBuffer(data->simulationData, 1, (void**) data->localData);
    do{
      solverInfo->currentStepSize = a*(tstop - solverInfo->currentTime);
      err = dassl_step(data, solverInfo);
      a *= 0.5;
      if(++iter >  10){
        printf("\n");
        warningStreamPrint(LOG_STDOUT, 0, "Initial guess failure at time %.12g", solverInfo->currentTime);
        break;
      }
    }while(err < 0);

    updateContinuousSystem(data);

  }
}

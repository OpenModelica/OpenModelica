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

#include "simulation/solver/dassl.h"
#include "simulation/options.h"
#include "simulation/results/simulation_result.h"
#include "simulation/solver/external_input.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/initialization/initialization.h"


static int initial_guess_ipopt_cflag(OptData *optData, char* cflags);
static inline void smallIntSolverStep(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, const double tstop);
static short initial_guess_ipopt_sim(OptData *optData, SOLVER_INFO* solverInfo, const short o);
static inline void init_ipopt_data(OptData *optData, const short o);

/*!
 *  create initial guess
 *  author: Vitalij Ruge
 **/
inline void initial_guess_optimizer(OptData *optData, SOLVER_INFO* solverInfo){

  char *cflags;
  int opt = 1;
  int i, j;
  char buffer[4096];
  const int nu = optData->dim.nu;

  optData->pFile = fopen("optimizeInput.csv", "wt");
  fprintf(optData->pFile, "%s ", "time");
  for(i=0; i < nu; ++i){
    sprintf(buffer, "%s", optData->dim.inputName[i]);
    fprintf(optData->pFile, "%s ", buffer);
  }
  fprintf(optData->pFile, "%s", "\n");

  cflags = (char*)omc_flagValue[FLAG_IPOPT_INIT];

  if(cflags){
    opt = initial_guess_ipopt_cflag(optData, cflags);
  }

  if(opt > 0)
    opt = initial_guess_ipopt_sim(optData, solverInfo, opt);

  init_ipopt_data(optData, opt);
}


/*!
 *  create initial guess dasslColorSymJac
 *  author: Vitalij Ruge
 **/
static short initial_guess_ipopt_sim(OptData *optData, SOLVER_INFO* solverInfo, const short o)
{
  double *u0;
  int i,j,k,l;
  modelica_real ***v;
  long double tol;
  short printGuess, op=1;

  const int nx = optData->dim.nx;
  const int nu = optData->dim.nu;
  const int np = optData->dim.np;
  const int nsi = optData->dim.nsi;
  const int nReal = optData->dim.nReal;
  char *cflags = (char*)omc_flagValue[FLAG_IIF];

  DATA* data = optData->data;
  threadData_t *threadData = optData->threadData;
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
   dassl_initial(data, threadData, solverInfo, dasslData);
   solverInfo->solverMethod = S_OPTIMIZATION;
   solverInfo->solverData = dasslData;

   u0 = optData->bounds.u0;
   v = optData->v;

   if(!data->simulationInfo.external_input.active)
     for(i = 0; i< nu;++i)
       data->simulationInfo.inputVars[i] = u0[i]/*optData->bounds.scalF[i + nx]*/;

   printGuess = (short)(ACTIVE_STREAM(LOG_INIT) && !ACTIVE_STREAM(LOG_SOLVER));

   if((double)data->simulationInfo.startTime < optData->time.t0){
     double t = data->simulationInfo.startTime;
     const int nBoolean = data->modelData.nVariablesBoolean;
     const int nInteger = data->modelData.nVariablesInteger;
     const int nRelations =  data->modelData.nRelations;

     FILE * pFile = optData->pFile;
     fprintf(pFile, "%lf ",(double)t);
     for(i = 0; i < nu; ++i){
       fprintf(pFile, "%lf ", (float)data->simulationInfo.inputVars[i]);
     }
     fprintf(pFile, "%s", "\n");
     if(1){
       printf("\nPreSim");
       printf("\n========================================================\n");
       printf("\ndone: time[%i] = %g",0,(double)data->simulationInfo.startTime);
     }
     while(t < optData->time.t0){
       externalInputUpdate(data);
       smallIntSolverStep(data, threadData, solverInfo, fmin(t += optData->time.dt[0], optData->time.t0));
       printf("\ndone: time[%i] = %g",0,(double)data->localData[0]->timeValue);
       sim_result.emit(&sim_result,data,threadData);
       fprintf(pFile, "%lf ",(double)data->localData[0]->timeValue);
       for(i = 0; i < nu; ++i){
         fprintf(pFile, "%lf ", (float)data->simulationInfo.inputVars[i]);
       }
       fprintf(pFile, "%s", "\n");
     }
     memcpy(optData->v0, data->localData[0]->realVars, nReal*sizeof(modelica_real));
     memcpy(optData->i0, data->localData[0]->integerVars, nInteger*sizeof(modelica_integer));
     memcpy(optData->b0, data->localData[0]->booleanVars, nBoolean*sizeof(modelica_boolean));
     memcpy(optData->i0Pre, data->simulationInfo.integerVarsPre, nInteger*sizeof(modelica_integer));
     memcpy(optData->b0Pre, data->simulationInfo.booleanVarsPre, nBoolean*sizeof(modelica_boolean));
     memcpy(optData->v0Pre, data->simulationInfo.realVarsPre, nReal*sizeof(modelica_real));
     memcpy(optData->rePre, data->simulationInfo.relationsPre, nRelations*sizeof(modelica_boolean));
     memcpy(optData->re, data->simulationInfo.relations, nRelations*sizeof(modelica_boolean));
     memcpy(optData->storeR, data->simulationInfo.storedRelations, nRelations*sizeof(modelica_boolean));

     if(1){
       printf("\n--------------------------------------------------------");
       printf("\nfinished: PreSim");
       printf("\n========================================================\n");
     }
   }

   if(o == 2 && cflags && strcmp(cflags, ""))
     op = 2;

   if(printGuess ){
     printf("\nInitial Guess");
     printf("\n========================================================\n");
     printf("\ndone: time[%i] = %g",0,(double)optData->time.t0);
   }

   for(i = 0, k=1; i < nsi; ++i){
     for(j = 0; j < np; ++j, ++k){
       externalInputUpdate(data);
       if(op==1)
         smallIntSolverStep(data, threadData, solverInfo, (double)optData->time.t[i][j]);
       else{
         rotateRingBuffer(data->simulationData, 1, (void**) data->localData);
         importStartValues(data, threadData, cflags, (double)optData->time.t[i][j]);
         for(l=0; l<nReal; ++l){
            data->localData[0]->realVars[l] = data->modelData.realVarsData[l].attribute.start;
         }
       }

       if(printGuess)
         printf("\ndone: time[%i] = %g", k, (double)optData->time.t[i][j]);

       memcpy(v[i][j], data->localData[0]->realVars, nReal*sizeof(double));
       for(l = 0; l < nx; ++l){

         if(((double) v[i][j][l] < (double)optData->bounds.vmin[l]*optData->bounds.vnom[l])
             || (double) (v[i][j][l] > (double) optData->bounds.vmax[l]*optData->bounds.vnom[l])){
           printf("\n********************************************\n");
           warningStreamPrint(LOG_STDOUT, 0, "Initial guess failure at time %g",(double)optData->time.t[i][j]);
           warningStreamPrint(LOG_STDOUT, 0, "%g<= (%s=%g) <=%g",
               (double)optData->bounds.vmin[l]*optData->bounds.vnom[l],
               data->modelData.realVarsData[l].info.name,
               (double)v[i][j][l],
               (double)optData->bounds.vmax[l]*optData->bounds.vnom[l]);
           printf("\n********************************************");
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

  externalInputFree(data);
  return op;
}


/*!
 *  helper for initial_guess_optimizer (pick up clfag option)
 *  author: Vitalij Ruge
 **/
static int initial_guess_ipopt_cflag(OptData *optData, char* cflags)
{
  if(!strcmp(cflags,"const") || !strcmp(cflags,"CONST"))
  {
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
  }else if(!strcmp(cflags,"file") || !strcmp(cflags,"FILE")){
    infoStreamPrint(LOG_STDOUT, 0, "Using values from file as initial guess.");
    return 2;
  }

  warningStreamPrint(LOG_STDOUT, 0, "not support ipopt_init=%s", cflags);
  return 1;

}

/*!
 *  init ipopt data struct
 *  author: Vitalij Ruge
 **/
static inline void init_ipopt_data(OptData *optData, const short op){
  OptDataIpopt* ipop = &optData->ipop;
  DATA * data = optData->data;
  const int NV = optData->dim.NV;
  const int NRes = optData->dim.NRes;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const int nv = optData->dim.nv;
  const int nc = optData->dim.nc;
  const int ncf = optData->dim.ncf;
  const int nJ = optData->dim.nJ;
  const int nx = optData->dim.nx;
  const int nReal = optData->dim.nReal;
  const int index_con = optData->dim.index_con;
  const int index_conf = optData->dim.index_conf;

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
      optData->data->callback->setInputData(optData->data, op == 2);
      for(l = 0; l<nx; ++l){
        ipop->vopt[l + shift] = optData->v[i][j][l]*optData->bounds.scalF[l];
      }
      for(;l<nv;++l){
        ipop->vopt[l + shift] = data->simulationInfo.inputVars[l-nx] * optData->bounds.scalF[l];
      }
    }
  }


  l = NRes-ncf;
  for(j = 0; j< nc; ++j){
    for(i = nx; i < l; i += nJ){
      ipop->gmin[i+j] = data->modelData.realVarsData[j + index_con].attribute.min;
      ipop->gmax[i+j] = data->modelData.realVarsData[j + index_con].attribute.max;
    }
  }

  /*terminal constraint(s)*/
  for(j = 0; j < ncf; ++j, ++i){
    ipop->gmin[l+j] = data->modelData.realVarsData[j + index_conf].attribute.min;
    ipop->gmax[l+j] = data->modelData.realVarsData[j + index_conf].attribute.max;
  }


}

static inline void smallIntSolverStep(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, const double tstop){
  long double a;
  int iter;
  int err;

  solverInfo->currentTime = data->localData[0]->timeValue;
  while(solverInfo->currentTime < tstop){
    a = 1.0;
    iter = 0;

    rotateRingBuffer(data->simulationData, 1, (void**) data->localData);
    do{
      if(data->modelData.nStates < 1){
        solverInfo->currentTime = tstop;
        data->localData[0]->timeValue = tstop;
        break;
      }
      solverInfo->currentStepSize = a*(tstop - solverInfo->currentTime);
      err = dassl_step(data, threadData, solverInfo);
      a *= 0.5;
      if(++iter >  10){
        printf("\n");
        warningStreamPrint(LOG_STDOUT, 0, "Initial guess failure at time %.12g", solverInfo->currentTime);
        assert(0);
      }
    }while(err < 0);

    data->callback->updateContinuousSystem(data, threadData);

  }
}

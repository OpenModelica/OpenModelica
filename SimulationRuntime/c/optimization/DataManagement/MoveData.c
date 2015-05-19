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

/*! MoveData.c
 */

#include "../../openmodelica.h"
#include "../../openmodelica_types.h"
#include "../../meta/meta_modelica.h"
#include "../OptimizerData.h"
#include "../OptimizerLocalFunction.h"
#include "../../simulation/results/simulation_result.h"
#include "../../simulation/options.h"
#include "../../simulation/solver/model_help.h"

static inline void pickUpDim(OptDataDim * dim, DATA* data, OptDataTime * time);
static inline void pickUpTime(OptDataTime * time, OptDataDim * dim, DATA* data, const double preSimTime);
static inline void pickUpBounds(OptDataBounds * bounds, OptDataDim * dim, DATA* data);
static inline void check_nominal(OptDataBounds * bounds, const double min, const double max,
                                 const double nominal, const modelica_boolean set, const int i, const double x0);
static inline void calculatedScalingHelper(OptDataBounds * bounds, OptDataTime * time, OptDataDim * dim,OptDataRK * rk);

static inline void setRKCoeff(OptDataRK *rk, const int np);
static inline void printSomeModelInfos(OptDataBounds * bounds, OptDataDim * dim, DATA* data);
static inline void pickUpStates(OptData* optdata);
static inline void updateDOSystem(OptData * optData, DATA * data, threadData_t *threadData,
                                   const int i, const int j, const int index, const int m);

static inline void setLocalVars(OptData * optData, DATA * data, const double * const vopt,
                                const int i, const int j, const int shift);

static inline int getNsi(char*, const int, modelica_boolean*);
static inline void overwriteTimeGridFile(OptDataTime * time, char* filename, long double c[], const int np, const int nsi);
static inline void overwriteTimeGridModel(OptDataTime * time, long double c[], const int np, const int nsi);

/* pick up model data
 * author: Vitalij Ruge
 */
int pickUpModelData(DATA* data, SOLVER_INFO* solverInfo)
{
  const int nReal = data->modelData.nVariablesReal;
  const int nBoolean = data->modelData.nVariablesBoolean;
  const int nInteger = data->modelData.nVariablesInteger;
  const int nRelations =  data->modelData.nRelations;

  int i, j;
  OptData *optData =  (OptData*) solverInfo->solverData;
  OptDataDim *dim;

  pickUpDim(&optData->dim, data, &optData->time);
  pickUpBounds(&optData->bounds, &optData->dim, data);
  pickUpTime(&optData->time, &optData->dim, data, optData->bounds.preSim);
  setRKCoeff(&optData->rk, optData->dim.np);
  calculatedScalingHelper(&optData->bounds,&optData->time, &optData->dim, &optData->rk);
  messageClose(LOG_SOLVER);

  dim = &optData->dim;

  optData->v = (modelica_real***) malloc(dim->nsi*sizeof(modelica_real**));
  for(i = 0; i< dim->nsi; ++i){
    optData->v[i] = (modelica_real**)malloc(dim->np*sizeof(modelica_real*));
    for(j = 0; j<dim->np;++j)
      optData->v[i][j] = (modelica_real*)malloc(nReal*sizeof(modelica_real));
  }
  optData->data = data;

  optData->v0 = (modelica_real*)malloc(nReal*sizeof(modelica_real));
  memcpy(optData->v0, data->localData[0]->realVars, nReal*sizeof(modelica_real));

  pickUpStates(optData);

  optData->sv0 = (modelica_real*)malloc(dim->nx*sizeof(modelica_real));
  for(i = 0; i<dim->nx; ++i)
    optData->sv0[i] = optData->v0[i] * optData->bounds.scalF[i];

  optData->i0 = (modelica_integer*)malloc(nInteger*sizeof(modelica_integer));
  memcpy(optData->i0, data->localData[0]->integerVars, nInteger*sizeof(modelica_integer));

  optData->b0 = (modelica_boolean*)malloc(nBoolean*sizeof(modelica_boolean));
  memcpy(optData->b0, data->localData[0]->booleanVars, nBoolean*sizeof(modelica_boolean));

  optData->re = (modelica_boolean*)malloc(nRelations*sizeof(modelica_boolean));
  memcpy(optData->re, data->simulationInfo.relations, nRelations*sizeof(modelica_boolean));

  optData->i0Pre = (modelica_integer*)malloc(nInteger*sizeof(modelica_integer));
  memcpy(optData->i0Pre, data->simulationInfo.integerVarsPre, nInteger*sizeof(modelica_integer));

  optData->b0Pre = (modelica_boolean*)malloc(nBoolean*sizeof(modelica_boolean));
  memcpy(optData->b0Pre, data->simulationInfo.booleanVarsPre, nBoolean*sizeof(modelica_boolean));

  optData->v0Pre = (modelica_real*)malloc(nReal*sizeof(modelica_real));
  memcpy(optData->v0Pre, data->simulationInfo.realVarsPre, nReal*sizeof(modelica_real));

  optData->rePre = (modelica_boolean*)malloc(nRelations*sizeof(modelica_boolean));
  memcpy(optData->rePre, data->simulationInfo.relationsPre, nRelations*sizeof(modelica_boolean));

  optData->storeR = (modelica_boolean*)malloc(nRelations*sizeof(modelica_boolean));
  memcpy(optData->storeR, data->simulationInfo.storedRelations, nRelations*sizeof(modelica_boolean));

  printSomeModelInfos(&optData->bounds, &optData->dim, data);

  return 0;
}

/* pick up information(nStates...) from model data to optimizer struct
 * author: Vitalij Ruge
 */
static inline void pickUpDim(OptDataDim * dim, DATA* data, OptDataTime * time){

  char * cflags = NULL;
  cflags = (char*)omc_flagValue[FLAG_OPTIMIZER_NP];
  if(cflags){
    dim->np = atoi(cflags);
    if(dim->np != 1 && dim->np!=3){
      warningStreamPrint(LOG_STDOUT, 0, "FLAG_OPTIZER_NP is %i. Currently optimizer support only 1 and 3.\nFLAG_OPTIZER_NP set of 3", dim->np);
      dim->np = 3;
    }
  }else
    dim->np = 3; /*ToDo*/
  dim->nx = data->modelData.nStates;
  dim->nu = data->modelData.nInputVars;
  dim->nv = dim->nx + dim->nu;
  dim->nc = data->modelData.nOptimizeConstraints;
  dim->ncf = data->modelData.nOptimizeFinalConstraints;
  dim->nJ = dim->nx + dim->nc;
  dim->nJ2 = dim->nJ + 2;
  dim->nReal = data->modelData.nVariablesReal;

  cflags = (char*)omc_flagValue[FLAG_OPTIMIZER_TGRID];
  data->callback->getTimeGrid(data, &dim->nsi, &time->tt);
  time->model_grid = (modelica_boolean)(dim->nsi > 0);

  if(!time->model_grid)
    dim->nsi = data->simulationInfo.numSteps;

  if(cflags)
    dim->nsi = getNsi(cflags, dim->nsi, &dim->exTimeGrid);

  dim->nt = dim->nsi*dim->np;
  dim->NV = dim->nt*dim->nv;
  dim->NRes = dim->nt*dim->nJ + dim->ncf;
  dim->index_con = dim->nReal - (dim->nc + dim->ncf);
  dim->index_conf = dim->index_con + dim->nc;
  assert(dim->nt > 0);
}



/* pick up information(startTime, stopTime, dt) from model data to optimizer struct
 * author: Vitalij Ruge
 */
static inline void pickUpTime(OptDataTime * time, OptDataDim * dim, DATA* data, const double preSimTime){
  const int nsi = dim->nsi;
  const int np = dim->np;
  const int np1 = np - 1;
  long double c[np];
  long double dc[np];
  int i, k;
  double t;
  char * cflags = NULL;

  time->t0 = (long double)fmax(data->simulationInfo.startTime, preSimTime);
  time->tf = (long double)data->simulationInfo.stopTime;

  time->dt = (long double*) malloc((nsi+1)*sizeof(long double));
  time->dt[0] = (time->tf - time->t0)/nsi;

  time->t = (long double**)malloc(nsi*sizeof(long double*));
  for(i = 0; i<nsi; ++i)
    time->t[i] = (long double*)malloc(np*sizeof(long double));
  if(nsi < 1){
    errorStreamPrint(LOG_STDOUT, 0, "Not support numberOfIntervals = %i < 1", nsi);
    assert(0);
  }

  if(np == 1){
    c[0] = 1.0;
  }else if(np == 3){
    c[0] = 0.15505102572168219018027159252941086080340525193433;
    c[1] = 0.64494897427831780981972840747058913919659474806567;
    c[2] = 1.00000;
  }else{
    errorStreamPrint(LOG_STDOUT, 0, "Not support np = %i", np);
    assert(0);
  }

  for(k = 0; k < np; ++k){
    dc[k] = c[k]*time->dt[0];
    time->t[0][k] = time->t0 + dc[k];
  }

  for(i = 1; i < nsi; ++i){
    time->dt[i] = time->dt[i-1];
    for(k = 0; k < np; ++k)
      time->t[i][k] = time->t[i-1][np1] + dc[k];
  }
  time->t[nsi-1][np1] = time->tf;

  if(nsi > 1){
    i = nsi - 1;
    time->dt[nsi-1] = time->t[i][np1] - time->t[i-1][np1];
    for(k = 0; k < np; ++k)
      time->t[i][k] = time->t[i-1][np1] + c[k]*time->dt[nsi-1];
  }else
    time->dt[1] = time->dt[0];

  cflags = (char*)omc_flagValue[FLAG_OPTIMIZER_TGRID];

  if(cflags)
    overwriteTimeGridFile(time, cflags, c, np, nsi);
  if(time->model_grid)
    overwriteTimeGridModel(time, c, np, nsi);
}

static int getNsi(char*filename, const int nsi, modelica_boolean * exTimeGrid){
  int n = 0, c;
  FILE * pFile = NULL;

  *exTimeGrid = 0;
  pFile = fopen(filename,"r");
  if(pFile == NULL){
    warningStreamPrint(LOG_STDOUT, 0, "OMC can't find the file %s.", filename);
    fclose(pFile);
    return nsi;
  }
   while(1){
    c = fgetc(pFile);
    if (c==EOF) break;
    if (c=='\n') ++n;
   }
   // check if csv file is empty!
   if (n == 0){
    warningStreamPrint(LOG_STDOUT, 0, "time grid file: %s is empty", filename);
    fclose(pFile);
    return nsi;
   }
   *exTimeGrid = 1;
   return n-1;
}

static inline void overwriteTimeGridFile(OptDataTime * time, char* filename, long double c[], const int np, const int nsi){
  int i,k;
  long double dc[np];
  const int np1 = np - 1;
  double t;
  FILE * pFile = NULL;
  pFile = fopen(filename,"r");

  fscanf(pFile, "%lf", &t);
  time->t0 = t;
  fscanf(pFile, "%lf", &t);
  time->t[0][np1] = t;
  time->dt[0] = time->t[0][np1] - time->t0;

  if(time->dt[0] <= 0){
    warningStreamPrint(LOG_STDOUT, 0, "read time grid from file fail!");
    warningStreamPrint(LOG_STDOUT, 0, "line %i: %g <= %g",0, (double)time->t[0][np1], (double)time->t0);
    EXIT(0);
  }


  for(k = 0; k < np; ++k){
    dc[k] = c[k]*time->dt[0];
    time->t[0][k] = time->t0 + dc[k];
  }

  for(i=1;i<nsi;++i){
    fscanf(pFile, "%lf", &t);
    time->t[i][np1] = t;
    time->dt[i] = time->t[i][np1] - time->t[i-1][np1];

    for(k = 0; k < np; ++k){
      dc[k] = c[k]*time->dt[i];
      time->t[i][k] = time->t[i-1][np1] + dc[k];
    }

    if(time->dt[i] <= 0){
      warningStreamPrint(LOG_STDOUT, 0, "read time grid");
      warningStreamPrint(LOG_STDOUT, 0, "line %i/%i: %g <= %g",i, nsi, (double)time->t[i][np1], (double)time->t[i-1][np1]);
      warningStreamPrint(LOG_STDOUT, 0, "failed!");
      EXIT(0);
    }

  }
  time->tf = time->t[nsi-1][np1];
  fclose(pFile);
}

int cmp_modelica_real(const void *v1, const void *v2) {
           return (*(modelica_real*)v1 - *(modelica_real*)v2);
}

static inline void overwriteTimeGridModel(OptDataTime * time, long double c[], const int np, const int nsi){
  int i,k;
  const int np1 = np - 1;
  time->t0 = time->tt[0];
  time->tf = time->tt[nsi];

  qsort((void*) time->tt, nsi+1, sizeof(modelica_real), &cmp_modelica_real);

  for(i = 0; i<nsi; ++i){
    time->dt[i] = time->tt[i+1] - time->tt[i];
    for(k=0; k<np; ++k){
      time->t[i][k] = time->tt[i] + c[k]*time->dt[i];
      /*printf("\nt[%i][%i] = %g",i,k,(double)time->t[i][k]);*/
    }
  }

  free(time->tt);

}

/* pick up information(startTime, stopTime, dt) from model data to optimizer struct
 * author: Vitalij Ruge
 */
static inline void pickUpBounds(OptDataBounds * bounds, OptDataDim * dim, DATA* data){
  char ** inputName;
  double min, max, nominal, x0;
  double *umin, *umax, *unom;
  modelica_boolean nominalWasSet;
  modelica_boolean * nominalWasSetInput;

  const int nx = dim->nx;
  const int nv = dim->nv;
  const int nu = dim->nu;
  const int nt = dim->nt;
  const int NV = dim->NV;

  long double tmp;

  int i, j;

  dim->inputName = (char**) malloc(nv*sizeof(char*));
  bounds->vnom = malloc(nv*sizeof(double));
  bounds->scalF = malloc(nv*sizeof(long double));

  bounds->vmin = malloc(nv*sizeof(double));
  bounds->vmax = malloc(nv*sizeof(double));

  bounds->u0 = malloc(nu*sizeof(double));

  nominalWasSetInput = (modelica_boolean*)malloc(nv*sizeof(modelica_boolean));
  inputName = dim->inputName;

  umin = bounds->vmin + nx;
  umax = bounds->vmax + nx;
  unom = bounds->vnom + nx;

  data->callback->pickUpBoundsForInputsInOptimization(data,umin, umax, unom, nominalWasSetInput, inputName, bounds->u0, &bounds->preSim);

  for(i = 0; i < nx; ++i){
    min = data->modelData.realVarsData[i].attribute.min;
    max = data->modelData.realVarsData[i].attribute.max;
    nominal = data->modelData.realVarsData[i].attribute.nominal;
    nominalWasSet = data->modelData.realVarsData[i].attribute.useNominal;
    x0 = data->localData[1]->realVars[i];

    check_nominal(bounds, min, max, nominal, nominalWasSet, i, x0);
    data->modelData.realVarsData[i].attribute.nominal = bounds->vnom[i];
    bounds->scalF[i] = 1.0/bounds->vnom[i];
    bounds->vmin[i] = min * bounds->scalF[i];
    bounds->vmax[i] = max * bounds->scalF[i];

  }
  for(j=0; i<dim->nv; ++i,++j){

    bounds->u0[j] = fmin(fmax(bounds->u0[j], umin[j]), umax[j]);
    check_nominal(bounds, umin[j], umax[j], unom[j], nominalWasSetInput[j], i, fabs(bounds->u0[j]));

    bounds->scalF[i] = 1.0 / bounds->vnom[i];
    bounds->vmin[i] *= bounds->scalF[i];
    bounds->vmax[i] *= bounds->scalF[i];

  }
  free(nominalWasSetInput);

  bounds->Vmin = malloc(NV*sizeof(double));
  bounds->Vmax = malloc(NV*sizeof(double));

  for(i = 0, j = 0; i < nt ; ++i, j += nv){
    memcpy(bounds->Vmin + j, bounds->vmin, nv*sizeof(double));
    memcpy(bounds->Vmax + j, bounds->vmax, nv*sizeof(double));
  }

}

/*!
 *  heuristic for nominal value
 *  author: Vitalij Ruge
 **/
static inline void check_nominal(OptDataBounds * bounds, const double min, const double max,
                                 const double nominal, const modelica_boolean set, const int i, const double x0){

  if(set){
    bounds->vnom[i] = fmax(fabs(nominal),1e-16);
  }else{
    double amax, amin;

    amax = fabs(max);
    amin = fabs(min);

    bounds->vnom[i] = fmax(amax,amin);

    if(bounds->vnom[i] > 1e12){
        double tmp = fmin(amax,amin);
        double ax0 = fabs(x0);
        bounds->vnom[i] = (tmp < 1e12) ? fmax(tmp,ax0) : 1.0 + ax0;
      }

    bounds->vnom[i] = fmax(bounds->vnom[i], 1e-16);
  }
}

/*!
 *  calculated helper vars for scaling
 *  author: Vitalij Ruge
 **/
static inline void calculatedScalingHelper(OptDataBounds * bounds, OptDataTime * time, OptDataDim * dim, OptDataRK *rk){
  const int nx = dim->nx;
  const int nsi = dim->nsi;
  const int np = dim->np;

  int i, j, k, l;
  assert(nsi > 0);
  bounds->scaldt = (long double**)malloc(nsi*sizeof(long double*));
  for(i = 0; i < nsi; ++i)
    bounds->scaldt[i] = (long double*) malloc(nx*sizeof(long double));

  for(i = 0; i < nsi; ++i)
    for(j = 0; j < nx; ++j){
      bounds->scaldt[i][j] = bounds->scalF[j]*time->dt[i];
    }

  bounds->scalb = (long double**)malloc(nsi*sizeof(long double*));
  for(i = 0; i < nsi; ++i){
    bounds->scalb[i] = (long double*)malloc(np*sizeof(long double));
    for(j = 0; j < np; ++j){
      bounds->scalb[i][j] = time->dt[i]*rk->b[j];
    }
  }
}

/*!
 *  set RK coeffs
 *  author: Vitalij Ruge
 **/
static inline void setRKCoeff(OptDataRK *rk, const int np){

  if(np == 3){

    rk->a[0][0] = 4.1393876913398137178367408896470696703591369767880;
    rk->a[0][1] = 3.2247448713915890490986420373529456959829737403284;
    rk->a[0][2] = 1.1678400846904054949240412722156950122337492313015;
    rk->a[0][3] = 0.25319726474218082618594241992157103785758599484179;

    rk->a[1][0] = 1.7393876913398137178367408896470696703591369767880;
    rk->a[1][1] = 3.5678400846904054949240412722156950122337492313015;
    rk->a[1][2] = 0.7752551286084109509013579626470543040170262596716;
    rk->a[1][3] = 1.0531972647421808261859424199215710378575859948418;

    rk->a[2][0] = 3.0;
    rk->a[2][1] = 5.5319726474218082618594241992157103785758599484179;
    rk->a[2][2] = 7.5319726474218082618594241992157103785758599484179;
    rk->a[2][3] = 5.0;

    rk->b[0] = 0.37640306270046727505007544236928079466761256998175;
    rk->b[1] = 0.51248582618842161383881344651960809422127631890713;
    rk->b[2] = 1 - (rk->b[0] + rk->b[1]);

  }else if(np == 1){
    rk->a[0][0] = 1.000;
    rk->b[0] = rk->a[0][0];
  }
}

/*!
 *  print some model infos
 *  author: Vitalij Ruge
 **/
static inline void printSomeModelInfos(OptDataBounds * bounds, OptDataDim * dim, DATA* data)
{
  const int nx = dim->nx;
  const int nc = dim->nc;
  const int nv = dim->nv;

  double *umin, *umax, *unom, *u0;
  double *xmin, *xmax, *xnom;
  double tmpStart;

  char buffer[200];
  char ** inputName;
  int i,j,k;

  inputName = dim->inputName;

  umin = bounds->vmin + nx;
  umax = bounds->vmax + nx;
  unom = bounds->vnom + nx;
  u0 = bounds->u0;

  xmin = bounds->vmin;
  xmax = bounds->vmax;
  xnom = bounds->vnom;

  printf("\nOptimizer Variables");
  printf("\n========================================================");

  for(i = 0; i < nx; ++i){

    if (xmin[i] > -1e20)
      sprintf(buffer, ", min = %g", data->modelData.realVarsData[i].attribute.min);
    else
      sprintf(buffer, ", min = -Inf");

    tmpStart = data->modelData.realVarsData[i].attribute.start;

    printf("\nState[%i]:%s(start = %g, nominal = %g%s", i, data->modelData.realVarsData[i].info.name, tmpStart, xnom[i], buffer);

    if(xmax[i] < 1e20)
      sprintf(buffer, ", max = %g", data->modelData.realVarsData[i].attribute.max);
    else
      sprintf(buffer, ", max = +Inf");

    printf("%s",buffer);
    printf(", init = %g)", data->localData[1]->realVars[i]);
  }

  for(k = 0; i < nv; ++i, ++k){

    if (umin[k] > -1e20)
      sprintf(buffer, ", min = %g", umin[k]*unom[k]);
    else
      sprintf(buffer, ", min = -Inf");

    printf("\nInput[%i]:%s(start = %g, nominal = %g%s",i, inputName[k], u0[k], unom[k], buffer);

    if(umax[k] < 1e20)
      sprintf(buffer, ", max = %g", umax[k]*unom[k]);
    else
      sprintf(buffer, ", max = +Inf");

    printf("%s)",buffer);
  }
  printf("\n--------------------------------------------------------");
  printf("\nnumber of nonlinear constraints: %i", nc);
  printf("\n========================================================\n");

}


/*!
 *  write results in result file
 *  author: Vitalij Ruge
 **/
void res2file(OptData *optData, SOLVER_INFO* solverInfo, double *vopt){
  const int nu = optData->dim.nu;
  const int nx = optData->dim.nx;
  const int nv = optData->dim.nv;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const int nReal = optData->dim.nReal;
  const int nBoolean = optData->data->modelData.nVariablesBoolean;
  const int nInteger = optData->data->modelData.nVariablesInteger;
  const int nRelations =  optData->data->modelData.nRelations;
  const int nvnp = nv*np;
  long double a[np];
  modelica_real *** v = optData->v;
  float tmp_u;

  int i,j,k, ii, jj;
  char buffer[4096];
  DATA * data = optData->data;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  FILE * pFile = optData->pFile;
  double * v0 = optData->v0;
  double *vnom = optData->bounds.vnom;
  long double **t = optData->time.t;
  long double t0 = optData->time.t0;
  long double tmpv;

  if(np == 3){
    a[0] = 1.5580782047249223824319753706862790293163070736617;
    a[1] = -0.89141153805825571576530870401961236264964040699507;
    a[2] = 0.33333333333333333333333333333333333333333333333333;
  }else if(np == 1){
    a[0] = 1.000;
  }else{
    errorStreamPrint(LOG_STDOUT, 0, "Not support np = %i", np);
    assert(0);
  }

  optData2ModelData(optData, vopt, 0);

  /******************/
  fprintf(pFile, "%lf ",(double)t0);

  for(i=0,j = nx; i < nu; ++i,++j){
    for(k = 0, tmpv = 0.0; k < np; ++k){
      tmpv += a[k]*vopt[k*nv + j];
    }
    tmpv = fmin(fmax(tmpv,optData->bounds.vmin[j]),optData->bounds.vmax[j]);
    data->simulationInfo.inputVars[i] = (double)tmpv*vnom[j];
    fprintf(pFile, "%lf ", (float)data->simulationInfo.inputVars[i]);
  }
  fprintf(pFile, "%s", "\n");
  /******************/
  memcpy(sData->realVars, v0, nReal*sizeof(modelica_real));
  memcpy(data->localData[0]->integerVars, optData->i0, nInteger*sizeof(modelica_integer));
  memcpy(data->localData[0]->booleanVars, optData->b0, nBoolean*sizeof(modelica_boolean));
  memcpy(data->simulationInfo.integerVarsPre, optData->i0Pre, nInteger*sizeof(modelica_integer));
  memcpy(data->simulationInfo.booleanVarsPre, optData->b0Pre, nBoolean*sizeof(modelica_boolean));
  memcpy(data->simulationInfo.realVarsPre, optData->v0Pre, nReal*sizeof(modelica_real));
  memcpy(data->simulationInfo.relationsPre, optData->rePre, nRelations*sizeof(modelica_boolean));
  memcpy(data->simulationInfo.relations, optData->re, nRelations*sizeof(modelica_boolean));
  memcpy(data->simulationInfo.storedRelations, optData->storeR, nRelations*sizeof(modelica_boolean));
  /******************/
  solverInfo->currentTime = (double)t0;
  sData->timeValue = solverInfo->currentTime;

  /*updateDiscreteSystem(data);*/
  data->callback->input_function(data);
  /*data->callback->functionDAE(data);*/
  updateDiscreteSystem(data);

  sim_result.emit(&sim_result,data);
  /******************/

  for(ii = 0; ii < nsi; ++ii){
    for(jj = 0; jj < np; ++jj){
      /******************/
      memcpy(sData->realVars, v[ii][jj], nReal*sizeof(modelica_real));
      /******************/
      fprintf(pFile, "%lf ",(double)t[ii][jj]);
      for(i = 0; i < nu; ++i){
      tmp_u = (float)(vopt[ii*nvnp+jj*nv+nx+i]*vnom[i + nx]);
        fprintf(pFile, "%lf ", tmp_u);
      }
      fprintf(pFile, "%s", "\n");
      /******************/
      solverInfo->currentTime = (double)t[ii][jj];
      sData->timeValue = solverInfo->currentTime;
      sim_result.emit(&sim_result,data);
    }
  }
  fclose(pFile);
}

/*!
 *  transfer optimizer data to model data
 *  author: Vitalij Ruge
 **/
void optData2ModelData(OptData *optData, double *vopt, const int index){
  const int nv = optData->dim.nv;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;

  const int nBoolean = optData->data->modelData.nVariablesBoolean;
  const int nInteger = optData->data->modelData.nVariablesInteger;
  const int nReal = optData->dim.nReal;
  const int nRelations =  optData->data->modelData.nRelations;


  modelica_real * realVars[3];
  modelica_real * tmpVars[2];

  int i, j, k, shift, l;
  DATA * data = optData->data;
  const int * indexBC = optData->s.indexABCD + 3;
  threadData_t *threadData = data->threadData;

  for(l = 0; l < 3; ++l)
    realVars[l] = data->localData[l]->realVars;

  for(l = 0; l< 2; ++l){
    if(optData->s.matrix[l])
      tmpVars[l] = data->simulationInfo.analyticJacobians[indexBC[l]].tmpVars;
  }

  memcpy(data->localData[0]->integerVars, optData->i0, nInteger*sizeof(modelica_integer));
  memcpy(data->localData[0]->booleanVars, optData->b0, nBoolean*sizeof(modelica_boolean));
  memcpy(data->simulationInfo.integerVarsPre, optData->i0Pre, nInteger*sizeof(modelica_integer));
  memcpy(data->simulationInfo.booleanVarsPre, optData->b0Pre, nBoolean*sizeof(modelica_boolean));
  memcpy(data->simulationInfo.realVarsPre, optData->v0Pre, nReal*sizeof(modelica_real));
  memcpy(data->simulationInfo.relationsPre, optData->rePre, nRelations*sizeof(modelica_boolean));
  memcpy(data->simulationInfo.relations, optData->re, nRelations*sizeof(modelica_boolean));
  memcpy(data->simulationInfo.storedRelations, optData->storeR, nRelations*sizeof(modelica_boolean));


  for(i = 0, shift = 0; i < nsi-1; ++i){
    for(j = 0; j < np; ++j, shift += nv){
      setLocalVars(optData, data, vopt, i, j, shift);
      updateDOSystem(optData, data, threadData, i, j, index, 2);
    }
  }

  for(j = 0; j < np-1; ++j, shift += nv){
    setLocalVars(optData, data, vopt, i, j, shift);
    updateDOSystem(optData, data, threadData, i, j, index, 2);
  }
  setLocalVars(optData, data, vopt, i, j, shift);
  updateDOSystem(optData, data, threadData, i, j, index, 3);

  /*terminal constraint(s)*/
  if(index){
    if(optData->s.matrix[3])
      diffSynColoredOptimizerSystemF(optData, optData->Jf);
  }

  for(l = 0; l < 3; ++l)
    data->localData[l]->realVars = realVars[l];

  for(l = 0; l< 2; ++l)
    if(optData->s.matrix[l])
      data->simulationInfo.analyticJacobians[indexBC[l]].tmpVars = tmpVars[l];

}


/*!
 *  helper optData2ModelData
 *  author: Vitalij Ruge
 **/
static inline void updateDOSystem(OptData * optData, DATA * data, threadData_t *threadData,
                                   const int i, const int j, const int index, const int m){

    /* try */
  optData->scc = 0;
#if !defined(OMC_EMCC)
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
    data->callback->input_function(data);
    /*data->callback->functionDAE(data);*/
    updateDiscreteSystem(data);

    if(index){
      diffSynColoredOptimizerSystem(optData, optData->J[i][j], i, j, m);
    }
    optData->scc = 1;
#if !defined(OMC_EMCC)
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
}

/*!
 *  helper optData2ModelData
 *  author: Vitalij Ruge
 **/
static inline void setLocalVars(OptData * optData, DATA * data, const double * const vopt,
                                const int i, const int j, const int shift){
  short l;
  int k;

  const int * indexBC = optData->s.indexABCD + 3;
  OptDataDim * dim = &optData->dim;
  const modelica_real * vnom = optData->bounds.vnom;
  const int nx = optData->dim.nx;
  const int nv = optData->dim.nv;

  for(l = 0; l < 3; ++l){
    data->localData[l]->realVars = optData->v[i][j];
    data->localData[l]->timeValue = (modelica_real) optData->time.t[i][j];
  }
  for(l = 0; l < 2; ++l)
    if(optData->s.matrix[l])
      data->simulationInfo.analyticJacobians[indexBC[l]].tmpVars = dim->analyticJacobians_tmpVars[l][i][j];

  for(k = 0; k < nx; ++k)
    data->localData[0]->realVars[k] = vopt[shift + k]*vnom[k];

  for(; k <nv; ++k){
    data->simulationInfo.inputVars[k-nx] = (modelica_real) vopt[shift + k]*vnom[k];
  }

};


/*
 *  function calculates a symbolic colored jacobian matrix of the optimization system
 *  authors: Willi Braun, Vitalij Ruge
 */
void diffSynColoredOptimizerSystem(OptData *optData, modelica_real **J, const int m, const int n, const int index){
  DATA * data = optData->data;
  int i,j,l,ii, ll;

  const int h_index = optData->s.indexABCD[index];
  const long double * scaldt = optData->bounds.scaldt[m];
  const unsigned int * const cC = data->simulationInfo.analyticJacobians[h_index].sparsePattern.colorCols;
  const unsigned int * const lindex  = optData->s.lindex[index];
  const int nx = data->simulationInfo.analyticJacobians[h_index].sizeCols;
  const int Cmax = data->simulationInfo.analyticJacobians[h_index].sparsePattern.maxColors + 1;
  const int dnx = optData->dim.nx;
  const int dnxnc = optData->dim.nJ;
  const modelica_real * const resultVars = data->simulationInfo.analyticJacobians[h_index].resultVars;
  const unsigned int * const sPindex = data->simulationInfo.analyticJacobians[h_index].sparsePattern.index;
  long double  scalb = optData->bounds.scalb[m][n];

  const int * index_J = (index == 3)? optData->s.indexJ3 : optData->s.indexJ2;
  const int nJ1 = optData->dim.nJ + 1;

  modelica_real **sV = optData->s.seedVec[index];

  for(i = 1; i < Cmax; ++i){
    data->simulationInfo.analyticJacobians[h_index].seedVars = sV[i];

    if(index == 2){
      data->callback->functionJacB_column(data);
    }else if(index == 3){
      data->callback->functionJacC_column(data);
    }else
      assert(0);

    for(ii = 0; ii < nx; ++ii){
      if(cC[ii] == i){
        for(j = lindex[ii]; j < lindex[ii + 1]; ++j){
          ll = sPindex[j];
          l = index_J[ll];
          if(l < dnx){
            J[l][ii] = (modelica_real) resultVars[ll] * scaldt[l];
          }else if(l < dnxnc){
            J[l][ii] = (modelica_real) resultVars[ll];
          }else if(l == optData->dim.nJ && optData->s.lagrange){
            J[l][ii] = (modelica_real) resultVars[ll]* scalb;
          }else if(l == nJ1 && optData->s.mayer){
            J[l][ii] = (modelica_real) resultVars[ll];
          }
        }
      }

    }
  }
}

void diffSynColoredOptimizerSystemF(OptData *optData, modelica_real **J){
  if(optData->dim.ncf > 0){
    DATA * data = optData->data;
    int i,j,l,ii, ll;
    const int index = 4;
    const int h_index = optData->s.indexABCD[index];
    const unsigned int * const cC = data->simulationInfo.analyticJacobians[h_index].sparsePattern.colorCols;
    const unsigned int * const lindex  = optData->s.lindex[index];
    const int nx = data->simulationInfo.analyticJacobians[h_index].sizeCols;
    const int Cmax = data->simulationInfo.analyticJacobians[h_index].sparsePattern.maxColors + 1;
    const modelica_real * const resultVars = data->simulationInfo.analyticJacobians[h_index].resultVars;
    const unsigned int * const sPindex = data->simulationInfo.analyticJacobians[h_index].sparsePattern.index;

    modelica_real **sV = optData->s.seedVec[index];

    for(i = 1; i < Cmax; ++i){
      data->simulationInfo.analyticJacobians[h_index].seedVars = sV[i];

      data->callback->functionJacD_column(data);

      for(ii = 0; ii < nx; ++ii){
        if(cC[ii] == i){
          for(j = lindex[ii]; j < lindex[ii + 1]; ++j){
            ll = sPindex[j];
            J[ll][ii] = resultVars[ll];
          }
        }
      }
    }
  }
}

/*!
 *  pick up start values from csv for states
 *  author: Vitalij Ruge
 **/
static inline void pickUpStates(OptData* optData){
  char* cflags;
  cflags = (char*)omc_flagValue[FLAG_INPUT_FILE_STATES];

  if(cflags){
    FILE * pFile = NULL;
    pFile = fopen(cflags,"r");
    if(pFile == NULL){
      warningStreamPrint(LOG_STDOUT, 0, "OMC can't find the file %s.",cflags);
    }else{
      int c, n = 0;
      modelica_boolean b;
      while(1){
          c = fgetc(pFile);
          if (c==EOF) break;
          if (c=='\n') ++n;
      }
      // check if csv file is empty!
      if(n == 0){
        fprintf(stderr, "External input file: externalInput.csv is empty!\n"); fflush(NULL);
        EXIT(1);
      }else{
        int i, j;
        double start_value;
        char buffer[200];
        const int nReal = optData->data->modelData.nVariablesReal;
        rewind(pFile);
        for(i =0; i< n; ++i){
          fscanf(pFile, "%s", buffer);
          if (fscanf(pFile, "%lf", &start_value) <= 0) continue;

          for(j = 0, b = 0; j < nReal; ++j){
            if(!strcmp(optData->data->modelData.realVarsData[j].info.name, buffer)){
              optData->data->localData[0]->realVars[j] = start_value;
              optData->data->localData[1]->realVars[j] = start_value;
              optData->data->localData[2]->realVars[j] = start_value;
              optData->v0[i] = start_value;
              b = 1;
              continue;
            }
          }
          if(!b)
            warningStreamPrint(LOG_STDOUT, 0, "it was impossible to set %s.start %g", buffer,start_value);
          else
          printf("\n[%i]set %s.start %g", i, buffer,start_value);

        }
        fclose(pFile);
        printf("\n");
        /*update system*/
        optData->data->callback->input_function(optData->data);
        /*optData->data->callback->functionDAE(optData->data);*/
        updateDiscreteSystem(optData->data);
      }
    }
  }
}

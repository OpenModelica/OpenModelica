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

#include "../OptimizerData.h"
#include "../OptimizerLocalFunction.h"
#include "../../simulation/results/simulation_result.h"
#include "../../simulation/options.h"

static inline void pickUpDim(OptDataDim * dim, DATA* data);
static inline void pickUpTime(OptDataTime * time, OptDataDim * dim, DATA* data, const double preSimTime);
static inline void pickUpBounds(OptDataBounds * bounds, OptDataDim * dim, DATA* data);
static inline void check_nominal(OptDataBounds * bounds, const double min, const double max,
                                 const double nominal, const modelica_boolean set, const int i, const double x0);
static inline void calculatedScalingHelper(OptDataBounds * bounds, OptDataTime * time, OptDataDim * dim,OptDataRK * rk);

static inline void setRKCoeff(OptDataRK *rk, const int np);
static inline void printSomeModelInfos(OptDataBounds * bounds, OptDataDim * dim, DATA* data);

/* pick up model data
 * author: Vitalij Ruge
 */
int pickUpModelData(DATA* data, SOLVER_INFO* solverInfo)
{
  const int nReal = data->modelData.nVariablesReal;
  int i, j;
  OptData *optData =  (OptData*) solverInfo->solverData;
  OptDataDim *dim;

  pickUpDim(&optData->dim, data);
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
  optData->v0 = (modelica_real*)malloc(nReal*sizeof(modelica_real));
  memcpy(optData->v0, data->localData[1]->realVars, nReal*sizeof(modelica_real));

  optData->sv0 = (modelica_real*)malloc(dim->nx*sizeof(modelica_real));
  for(i = 0; i<dim->nx; ++i)
    optData->sv0[i] = optData->v0[i] * optData->bounds.scalF[i];

  optData->data = data;
  printSomeModelInfos(&optData->bounds, &optData->dim, data);

  return 0;
}

/* pick up information(nStates...) from model data to optimizer struct
 * author: Vitalij Ruge
 */
static inline void pickUpDim(OptDataDim * dim, DATA* data){

  char * cflags = NULL;
  cflags = (char*)omc_flagValue[FLAG_OPTIZER_NP];
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
  dim->nJ = dim->nx + dim->nc;
  dim->nJ2 = dim->nJ + 2;
  dim->nReal = data->modelData.nVariablesReal;
  dim->nsi = data->simulationInfo.numSteps;
  dim->nt = dim->nsi*dim->np;
  dim->NV = dim->nt*dim->nv;
  dim->NRes = dim->nt*dim->nJ;
  dim->index_con = dim->nReal - dim->nc;

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

  time->t0 = (long double)fmax(data->simulationInfo.startTime, preSimTime);
  time->tf = (long double)data->simulationInfo.stopTime;

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

  for(i = 1; i < nsi; ++i)
    for(k = 0; k < np; ++k)
      time->t[i][k] = time->t[i-1][np1] + dc[k];

  time->t[nsi-1][np1] = time->tf;

  if(nsi > 1){
    i = nsi - 1;
    time->dt[1] = time->t[i][np1] - time->t[i-1][np1];
    for(k = 0; k < np; ++k)
      time->t[i][k] = time->t[i-1][np1] + c[k]*time->dt[1];

  }else
    time->dt[1] = time->dt[0];
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

  for(i = 0; i+1 < nsi; ++i)
    for(j = 0; j < nx; ++j){
      bounds->scaldt[i][j] = bounds->scalF[j]*time->dt[0];
    }
  for(j = 0; j < nx; ++j){
    bounds->scaldt[i][j] = bounds->scalF[j]*time->dt[1];
  }

  bounds->scalb = (long double**)malloc(nsi*sizeof(long double*));
  for(i = 0; i < nsi; ++i){
    bounds->scalb[i] = (long double*)malloc(np*sizeof(long double));
    l = (i + 1 < nsi ) ? 0 : 1;
    for(j = 0; j < np; ++j){
      bounds->scalb[i][j] = time->dt[l]*rk->b[j];
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
  const int nvnp = nv*np;
  long double a[np];
  modelica_real *** v = optData->v;

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
    data->simulationInfo.inputVars[i] = (double)tmpv*vnom[j];
    fprintf(pFile, "%lf ", (float)data->simulationInfo.inputVars[i]);
  }
  fprintf(pFile, "%s", "\n");
  /******************/
  memcpy(sData->realVars, v0, nReal*sizeof(modelica_real));
  /******************/
  solverInfo->currentTime = (double)t0;
  sData->timeValue = solverInfo->currentTime;

  /*updateDiscreteSystem(data);*/
  data->callback->input_function(data);
  data->callback->functionDAE(data);

  sim_result.emit(&sim_result,data);
  /******************/

  for(ii = 0; ii < nsi; ++ii){
    for(jj = 0; jj < np; ++jj){
      /******************/
      memcpy(sData->realVars, v[ii][jj], nReal*sizeof(modelica_real));
      /******************/
      fprintf(pFile, "%lf ",(double)t[ii][jj]);
      for(i = 0; i < nu; ++i){
      data->simulationInfo.inputVars[i] = vopt[ii*nvnp+nx+i]*vnom[i + nx];
        fprintf(pFile, "%lf ", (float)data->simulationInfo.inputVars[i]);
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
  const int nx = optData->dim.nx;
  const int nv = optData->dim.nv;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;

  const modelica_real * vnom = optData->bounds.vnom;

  modelica_real * realVars[3];

  int i, j, k, shift, l;
  DATA * data = optData->data;

  for(l = 0; l < 3; ++l)
    realVars[l] = data->localData[l]->realVars;

  for(i = 0, shift = 0; i < nsi-1; ++i){
    for(j = 0; j < np; ++j, shift += nv){

      for(l = 0; l < 3; ++l){
        data->localData[l]->realVars = optData->v[i][j];
        data->localData[l]->timeValue = (modelica_real) optData->time.t[i][j];
      }

      for(k = 0; k < nx; ++k)
        data->localData[0]->realVars[k] = vopt[shift + k]*vnom[k];

      for(; k <nv; ++k){
        data->simulationInfo.inputVars[k-nx] = (modelica_real) vopt[shift + k]*vnom[k];
      }

      data->callback->input_function(data);
      data->callback->functionDAE(data);

      if(index){
        diffSynColoredOptimizerSystem(optData, optData->J[i][j], i,j,0);
      }

    }
  }


  for(j = 0; j < np; ++j, shift += nv){

    for(l = 0; l < 3; ++l){
      data->localData[l]->realVars = optData->v[i][j];
      data->localData[l]->timeValue = (modelica_real) optData->time.t[i][j];
    }

    for(k = 0; k < nx; ++k)
      data->localData[0]->realVars[k] = vopt[shift + k]*vnom[k];

    for(; k <nv; ++k){
      data->simulationInfo.inputVars[k-nx] = (modelica_real) vopt[shift + k]*vnom[k];
    }

    data->callback->input_function(data);
    data->callback->functionDAE(data);

    if(index){
      diffSynColoredOptimizerSystem(optData, optData->J[i][j], i,j, (j+1 == np)? 1 : 0);
    }
  }

  for(l = 0; l < 3; ++l)
    data->localData[l]->realVars = realVars[l];

}

/*
 *  function calculates a symbolic colored jacobian matrix of the optimization system
 *  authors: Willi Braun, Vitalij Ruge
 */
void diffSynColoredOptimizerSystem(OptData *optData, modelica_real **J, const int m, const int n, const int index){
  DATA * data = optData->data;
  int i,j,l,ii, ll;
  const int indexBC[2] = {data->callback->INDEX_JAC_B, data->callback->INDEX_JAC_C};
  const int jj = indexBC[index]; 

  const long double * scaldt = optData->bounds.scaldt[m];
  const unsigned int * const cC = data->simulationInfo.analyticJacobians[jj].sparsePattern.colorCols;
  const unsigned int * const lindex  = optData->s.lindex[index];
  const int nx = data->simulationInfo.analyticJacobians[jj].sizeCols;
  const int Cmax = data->simulationInfo.analyticJacobians[jj].sparsePattern.maxColors + 1;
  const int dnx = optData->dim.nx;
  const int dnxnc = optData->dim.nJ;
  const modelica_real * const resultVars = data->simulationInfo.analyticJacobians[jj].resultVars;
  const unsigned int * const sPindex = data->simulationInfo.analyticJacobians[jj].sparsePattern.index;
  long double  scalb = optData->bounds.scalb[m][n];

  const int * index_J = (index)? optData->s.indexJ3 : optData->s.indexJ2;
  const int nJ1 = optData->dim.nJ + 1;
  for(i = 1; i < Cmax; ++i){
    data->simulationInfo.analyticJacobians[jj].seedVars = optData->s.seedVec[index][i];

    if(index){
      data->callback->functionJacC_column(data);
    }else{
      data->callback->functionJacB_column(data);
    }

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


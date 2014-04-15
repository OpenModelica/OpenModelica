/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

/*
 * Developed by:
 * FH-Bielefeld
 * Developer: Vitalij Ruge
 * Contact: vitalij.ruge@fh-bielefeld.de
 */

#include "../ipoptODEstruct.h"
#include "simulation_data.h"
#include "../../simulation/options.h"

#ifdef WITH_IPOPT

#include "../localFunction.h"
#include "../../simulation/solver/external_input.h"

int allocateIpoptData(IPOPT_DATA_ *iData);

static int set_local_jac_struct(IPOPT_DATA_ *iData, int *nng);
static int local_jac_struct(IPOPT_DATA_ *iData, int *nng);
static void local_jac_struct_print(IPOPT_DATA_ *iData);
static int check_nominal(IPOPT_DATA_ *iData, double min, double max, double nominal, modelica_boolean set, int i, double x0);
static int optimizer_coeff_setings(IPOPT_DATA_ *iData);
static int optimizer_bounds_setings(DATA *data, IPOPT_DATA_ *iData);
static int optimizer_time_setings(IPOPT_DATA_ *iData);
static int optimizer_print_step(IPOPT_DATA_ *iData);
static int local_diffObject_struct(IPOPT_DATA_ *iData);
static int move_grid(IPOPT_DATA_ *iData);



/*!
 *  set data from model
 *  author: Vitalij Ruge
 **/
int loadDAEmodel(DATA *data, IPOPT_DATA_ *iData)
{
  int id, nH, i;
  double *c;
  OPTIMIZER_DIM_VARS *dim = &iData->dim;
  dim->deg = 3;
  dim->nx = data->modelData.nStates;
  dim->nu = data->modelData.nInputVars;
  dim->nc = data->modelData.nOptimizeConstraints;
  dim->nReal = data->modelData.nVariablesReal;

  dim->nsi = data->simulationInfo.numSteps;
  iData->dtime.t0 = (long double)data->simulationInfo.startTime;
  iData->dtime.tf = (long double)data->simulationInfo.stopTime;

  /***********************/
  dim->nX = dim->nx * dim->deg;
  dim->nU = dim->nu * dim->deg;

  dim->NX = dim->nX * dim->nsi + dim->nx;
  dim->NU = dim->nU * dim->nsi + dim->nu;

  dim->nv = dim->nx + dim->nu;
  dim->nV = dim->nX + dim->nU;
  dim->NV = dim->NX + dim->NU;

  dim->nRes = dim->nx*dim->deg;
  dim->NRes = dim->nRes * dim->nsi;
  dim->endN = dim->NV - dim->nv;
  dim->nt = dim->nsi*dim->deg + 1;

  /***********************/
  allocateIpoptData(iData);
  move_grid(iData);
  optimizer_coeff_setings(iData);
  /***********************/
  local_diffObject_struct(iData);
  set_local_jac_struct(iData, &id);

  dim->njac = dim->deg*(dim->nlocalJac-dim->nx+dim->nsi*dim->nlocalJac+dim->deg*dim->nsi*dim->nx)-dim->deg*id;
  dim->nhess = dim->nH*(1+dim->deg*dim->nsi);
  /***********************/
  iData->helper.x0 = iData->data->localData[1]->realVars;
  optimizer_bounds_setings(data, iData);
  optimizer_time_setings(iData);

  /***********************/
  if(ACTIVE_STREAM(LOG_IPOPT_FULL))
    optimizer_print_step(iData);

  if(ACTIVE_STREAM(LOG_IPOPT_JAC) || ACTIVE_STREAM(LOG_IPOPT_HESSE))
    local_jac_struct_print(iData);

  for(i =0; i <iData->dim.deg; ++i)
    iData->helper.tmp[i] = iData->dtime.dt[0]*iData->mbase.d[i][4];

  return 0;
}


/*!
 *  time grid for optimization
 *  author: Vitalij Ruge
 **/
int move_grid(IPOPT_DATA_ *iData)
{
  int i;
  long double t;
  OPTIMIZER_TIME *dtime = &iData->dtime;

  OPTIMIZER_DIM_VARS* dim = &iData->dim;
  dtime->dt[0] = (dtime->tf - dtime->t0)/(dim->nsi);

  assert(dim->nsi>0);

  t = dtime->t0 + dtime->dt[0];

  for(i=1;i<dim->nsi; ++i){
    dtime->dt[i] = dtime->dt[i-1];
    t += dtime->dt[i];
  }
  assert(dim->nsi>0);
  dtime->dt[dim->nsi-1] = (dtime->tf - t) + dtime->dt[0] ;
  return 0;
}

/*
 *  function calculates a jacobian matrix struct
 *  author: Willi
 */
static int local_jac_struct(IPOPT_DATA_ *iData, int * nng)
{
  const int index = 2;

  DATA * data = iData->data;
  OPTIMIZER_DIM_VARS* dim = &iData->dim;

  modelica_boolean **J;
  modelica_boolean **Hg;
  modelica_boolean ** dF;

  int i,j,l,ii,nx, id;
  int *cC,*lindex;
  int nJ = dim->nJ;

  id = 0;
  dim->nH = 0;

  J = iData->sopt.knowedJ;
  Hg = iData->sopt.Hg;
  dF = iData->sopt.gradFs;

  nx = data->simulationInfo.analyticJacobians[index].sizeCols;
  cC =  (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
  lindex = (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;

  for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i){
    for(ii = 0; ii<nx; ++ii){
      if(cC[ii] == i){
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1.0;
      }
    }

    for(ii = 0; ii < nx; ii++){
      if(cC[ii] == i){
        if(0 == ii)
          j = 0;
        else
          j = lindex[ii-1];

        for(; j<lindex[ii]; ++j){
          l = data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
          J[l][ii] = 1;
          ++(dim->nlocalJac);
          if(l>= dim->nx) ++id;
        }
      }
    }

    for(ii = 0; ii<nx; ++ii){
      if(cC[ii] == i){
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 0.0;
      }
    }
  }


  for(i = 0; i <dim->nv; ++i)
    for(j = 0; j < dim->nv; ++j)
    {
      for(ii = 0; ii < nJ; ++ii)
        if(J[ii][i]*J[ii][j])
          Hg[i][j] = 1;

      for(ii = 0; ii < 2; ++ii)
        if(dF[ii][i]*dF[ii][j])
          Hg[i][j] = 1;
    }

  for(i = 0; i <dim->nv; ++i)
    for(j = 0; j < i+1; ++j)
      if(Hg[i][j])
        ++dim->nH;

  for(ii = 0; ii < dim->nx; ii++){
    if(J[ii][ii] == 0)
      ++dim->nlocalJac;
    J[ii][ii] = 1.0;
  }

  *nng = id;
  return 0;
}

static int set_local_jac_struct(IPOPT_DATA_ *iData, int *nng)
{
  char *cflags;
  iData->sopt.useNumJac = 0;

  cflags = (char*)omc_flagValue[FLAG_IPOPT_JAC];

  if(cflags){
   if(!strcmp(cflags,"SYM") || !strcmp(cflags,"sym"))
     iData->sopt.useNumJac = 0;
   else{
     warningStreamPrint(LOG_STDOUT, 1, "not support ipopt_hesse=%s",cflags);
     iData->sopt.useNumJac = 0;
   }
  }

  if(iData->sopt.useNumJac == 0)
    local_jac_struct(iData, nng);

  return 0;
}

/*
 *  function calculates struct of symbolic colored gradient "matrix"
 *  author: vitalij
 */
static int local_diffObject_struct(IPOPT_DATA_ *iData)
{
    DATA * data = iData->data;
    const int index = 3;
    int i,j,l,ii,nx;
    int *cC,*lindex;

    nx = data->simulationInfo.analyticJacobians[index].sizeCols;

    cC =  (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
    lindex = (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;

    for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i){
      for(ii = 0; ii<nx; ++ii){
        if(cC[ii] == i){
          data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1.0;
        }
      }

      data->callback->functionJacC_column(data);

      for(ii = 0; ii < nx; ++ii){
        if(cC[ii] == i){
          if(ii == 0) j = 0;
          else j = lindex[ii-1];

          for(; j<lindex[ii]; ++j){
            l = data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
            iData->sopt.gradFs[l][ii] = (modelica_boolean)1;
          }
        }
      }

      for(ii = 0; ii<nx; ++ii){
        if(cC[ii] == i){
          data->simulationInfo.analyticJacobians[index].seedVars[ii] = 0.0;
        }
      }
  }
  return 0;
}

static void local_jac_struct_print(IPOPT_DATA_ *iData)
{
  int ii,j;
  modelica_boolean **J;
  modelica_boolean **Hg;
  modelica_boolean ** dF;
  OPTIMIZER_DIM_VARS* dim = &iData->dim;
  int nJ = dim->nJ;

  J = iData->sopt.knowedJ;
  Hg = iData->sopt.Hg;
  dF = iData->sopt.gradFs;

  printf("\nJacabian Structure %i x %i",nJ,dim->nv);
  printf("\n========================================================");
  for(ii = 0; ii < nJ; ++ii){
    printf("\n");
    for(j =0;j<dim->nv;++j)
      if(J[ii][j])
        printf("* ");
      else
        printf("0 ");
  }
  printf("\n========================================================");
  printf("\nGradient Structure");
  printf("\n========================================================");
  if(iData->sopt.lagrange){
    printf("\n");
    for(j =0;j<dim->nv;++j)
      if(dF[iData->lagrange_index][j])
        printf("* ");
      else
        printf("0 ");
  }

  if(iData->sopt.mayer){
    printf("\n");
    for(j =0;j<dim->nv;++j)
      if(dF[iData->mayer_index][j])
        printf("* ");
      else
        printf("0 ");
  }

  printf("\n========================================================");
  printf("\nHessian Structure %i x %i",dim->nv,dim->nv);
  printf("\n========================================================");
  for(ii = 0; ii < dim->nv; ++ii){
    printf("\n");
    for(j =0;j<dim->nv;++j)
      if(Hg[ii][j])
        printf("* ");
      else
        printf("0 ");
  }
  printf("\n========================================================");

}


/*!
 *  heuristic for nominal value
 *  author: Vitalij Ruge
 **/
static int check_nominal(IPOPT_DATA_ *iData, double min, double max, double nominal, modelica_boolean set, int i, double x0)
{
  if(set){
    iData->scaling.vnom[i] = fmax(fabs(nominal),1e-16);
  }else{
    double amax, amin;
    amax = fabs(max);
    amin = fabs(min);
    iData->scaling.vnom[i] = fmax(amax,amin);
    if(iData->scaling.vnom[i] > 1e12){
        double tmp = fmin(amax,amin);
        if(tmp<1e12){
          iData->scaling.vnom[i] = fmax(tmp,x0);
        }else{
          iData->scaling.vnom[i] = 1.0 + x0;
        }
      }
      
    iData->scaling.vnom[i] = fmax(iData->scaling.vnom[i],1e-16);
  }
  return 0;
}


/*!
 *  seting collocation coeff
 *  author: Vitalij Ruge
 **/
static int optimizer_coeff_setings(IPOPT_DATA_ *iData)
{
  OPTIMIZER_MBASE *mbase = &iData->mbase;

  mbase->c[0][0] = 0.27639320225002103035908263312687237645593816403885;
  mbase->c[0][1] = 0.72360679774997896964091736687312762354406183596115;
  mbase->c[0][2] = 1.0;

  mbase->c[1][0] = 0.15505102572168219018027159252941086080340525193433;
  mbase->c[1][1] = 0.64494897427831780981972840747058913919659474806567;
  mbase->c[1][2] = 1.0;

  mbase->a[0][0] = 4.1393876913398137178367408896470696703591369767880;
  mbase->a[0][1] = 3.2247448713915890490986420373529456959829737403284;
  mbase->a[0][2] = 1.1678400846904054949240412722156950122337492313015;
  mbase->a[0][3] = 0.25319726474218082618594241992157103785758599484179;

  mbase->a[1][0] = 1.7393876913398137178367408896470696703591369767880;
  mbase->a[1][1] = 3.5678400846904054949240412722156950122337492313015;
  mbase->a[1][2] = 0.7752551286084109509013579626470543040170262596716;
  mbase->a[1][3] = 1.0531972647421808261859424199215710378575859948418;

  mbase->a[2][0] = 3.0;
  mbase->a[2][1] = 5.5319726474218082618594241992157103785758599484179;
  mbase->a[2][2] = 7.5319726474218082618594241992157103785758599484179;
  mbase->a[2][3] = 5.0;

  mbase->d[0][0] = 4.3013155617496424838955952368431696002490512113396;
  mbase->d[0][1] = 3.6180339887498948482045868343656381177203091798058;
  mbase->d[0][2] = 0.8541019662496845446137605030969143531609275394172;
  mbase->d[0][3] = 0.17082039324993690892275210061938287063218550788345;
  mbase->d[0][4] = 0.44721359549995793928183473374625524708812367192230;
  mbase->invd1_4 = 2.2360679774997896964091736687312762354406183596115;

  mbase->d[1][0] = 3.3013155617496424838955952368431696002490512113396;
  mbase->d[1][1] = 5.8541019662496845446137605030969143531609275394172;
  mbase->d[1][2] = 1.3819660112501051517954131656343618822796908201942;
  mbase->d[1][3] = 1.1708203932499369089227521006193828706321855078834;
  mbase->d[1][4] = 0.44721359549995793928183473374625524708812367192230;

  mbase->d[2][0] = 7.0;
  mbase->d[2][1] = 11.180339887498948482045868343656381177203091798058;
  mbase->d[2][2] = 11.180339887498948482045868343656381177203091798058;
  mbase->d[2][3] = 7.0;
  mbase->d[2][4] = 1.0;

  mbase->b[0][0] = 0.083333333333333333333333333333333333333333333333333;
  mbase->b[0][1] = 0.41666666666666666666666666666666666666666666666667;
  mbase->b[0][2] = mbase->b[0][1];
  mbase->b[0][3] = 1.0 - (mbase->b[0][0]+mbase->b[0][1]+mbase->b[0][2]);

  mbase->b[1][2] = 0.11111111111111111111111111111111111111111111111111;
  mbase->b[1][1] = 0.51248582618842161383881344651960809422127631890713;
  mbase->b[1][0] = 1.0 - (mbase->b[1][1] + mbase->b[1][2]);

  return 0;
}


/*!
 *  seting vars bounds
 *  author: Vitalij Ruge
 **/
static int optimizer_bounds_setings(DATA *data, IPOPT_DATA_ *iData)
{
  int i, j, k;
  OPTIMIZER_DIM_VARS* dim = &iData->dim;
  modelica_boolean *tmp = (modelica_boolean*)malloc(dim->nv*sizeof(modelica_boolean));
  char **tmpname = iData->input_name;

  double *start = iData->helper.start_u;
  double ttmp;

  for(i =0; i<dim->nx; ++i){
    check_nominal(iData, data->modelData.realVarsData[i].attribute.min, data->modelData.realVarsData[i].attribute.max, data->modelData.realVarsData[i].attribute.nominal, data->modelData.realVarsData[i].attribute.useNominal, i, fabs(iData->helper.x0[i]));
    iData->scaling.scalVar[i] = 1.0 / iData->scaling.vnom[i];
    iData->scaling.scalf[i] = iData->scaling.scalVar[i];
    iData->bounds.xmin[i] = data->modelData.realVarsData[i].attribute.min*iData->scaling.scalVar[i];
    iData->bounds.xmax[i] = data->modelData.realVarsData[i].attribute.max*iData->scaling.scalVar[i];
  }

  for(i =0; i<dim->nx; ++i)
    for(j = 0; j<dim->nsi; ++j)
      iData->scaling.scaldt[i][j] = iData->scaling.scalf[i]*iData->dtime.dt[j];

  iData->data->callback->pickUpBoundsForInputsInOptimization(data,
      iData->bounds.umin, iData->bounds.umax, &iData->scaling.vnom[dim->nx], tmp, tmpname, start,
      &ttmp);
  iData->dtime.startTimeOpt = ttmp;

  iData->sopt.preSim = (iData->dtime.t0 < iData->dtime.startTimeOpt) ? 1 : 0;

  if(ACTIVE_STREAM(LOG_IPOPT)|| ACTIVE_STREAM(LOG_IPOPT_ERROR)){
  char buffer[200];
    printf("Optimizer Variables");
    printf("\n========================================================");
    for(i=0; i<dim->nx; ++i){

      if (iData->bounds.xmin[i] > -1e20)
        sprintf(buffer, ", min = %g", data->modelData.realVarsData[i].attribute.min);
      else
        sprintf(buffer, ", min = -Inf");

      if( data->modelData.realVarsData[i].attribute.useNominal)
        printf("\nState[%i]:%s(start = %g, nominal = %g%s",i, iData->data->modelData.realVarsData[i].info.name, data->modelData.realVarsData[i].attribute.start, (double)iData->scaling.vnom[i], buffer);
      else
        printf("\nState[%i]:%s(start = %g, nominal = ?%s",i, iData->data->modelData.realVarsData[i].info.name, data->modelData.realVarsData[i].attribute.start, buffer);

      if (iData->bounds.xmax[i] < 1e20)
        sprintf(buffer, ", max = %g", data->modelData.realVarsData[i].attribute.max);
      else
        sprintf(buffer, ", max = +Inf");

      printf("%s",buffer);
      printf(", init = %g)",iData->data->localData[1]->realVars[i]);
    }

    for(; i<dim->nv; ++i){
      k = i - dim->nx;

      if (iData->bounds.umin[k] > -1e20)
        sprintf(buffer, ", min = %g", iData->bounds.umin[k]);
      else
        sprintf(buffer, ", min = -Inf");

      if( data->modelData.realVarsData[i].attribute.useNominal)
        printf("\nInput[%i]:%s(start = %g, nominal = %g%s",i, tmpname[k] ,start[k], (double) iData->scaling.vnom[i], buffer);
      else
        printf("\nInput[%i]:%s(start = %g, nominal = ?%s",i, tmpname[k] ,start[k], buffer);

      if (iData->bounds.umax[k] < 1e20)
        sprintf(buffer, ", max = %g", iData->bounds.umax[k]);
      else
        sprintf(buffer, ", max = +Inf");

      printf("%s)",buffer);
    }
    printf("\n--------------------------------------------------------");
    if(dim->nc > 0)
      printf("\nnumber of constraints: %i", dim->nc);
    printf("\n========================================================\n");
  }

  for(i =0,j = dim->nx;i<dim->nu;++i,++j){
    check_nominal(iData, iData->bounds.umin[i], iData->bounds.umax[i], iData->scaling.vnom[j], tmp[i], j, fabs(start[i]));
    iData->helper.start_u[i] = fmin(fmax(iData->helper.start_u[i], iData->bounds.umin[i]), iData->bounds.umax[i]);
    iData->scaling.scalVar[j] = 1.0 / iData->scaling.vnom[j];
    iData->bounds.umin[i] *= iData->scaling.scalVar[j];
    iData->bounds.umax[i] *= iData->scaling.scalVar[j];
  }

  memcpy(iData->bounds.vmin, iData->bounds.xmin, sizeof(double)*dim->nx);
  memcpy(iData->bounds.vmin + dim->nx, iData->bounds.umin, sizeof(double)*dim->nu);

  memcpy(iData->bounds.vmax, iData->bounds.xmax, sizeof(double)*dim->nx);
  memcpy(iData->bounds.vmax + dim->nx, iData->bounds.umax, sizeof(double)*dim->nu);

  memcpy(iData->bounds.Vmin, iData->bounds.vmin, sizeof(double)*dim->nv);
  memcpy(iData->bounds.Vmax, iData->bounds.vmax, sizeof(double)*dim->nv);

  for(i = 0,j = dim->nv; i < dim->nsi*dim->deg;i++, j += dim->nv){
  memcpy(iData->bounds.Vmin + j, iData->bounds.vmin, sizeof(double)*dim->nv);
    memcpy(iData->bounds.Vmax + j, iData->bounds.vmax, sizeof(double)*dim->nv);
  }

  free(tmp);
  return 0;
}


/*!
 *  seting time vector
 *  author: Vitalij Ruge
 **/
static int optimizer_time_setings(IPOPT_DATA_ *iData)
{
  int i,k,id,j;
  OPTIMIZER_MBASE *mbase = &iData->mbase;
  OPTIMIZER_TIME *dtime = &iData->dtime;

  dtime->time[0] = dtime->t0;

  for(i = 0,k=0,id=0; i<1; ++i,id += iData->dim.deg)
    for(j = 0; j < iData->dim.deg; ++j)
      dtime->time[++k] = dtime->time[id] + mbase->c[0][j]*dtime->dt[i];


  for(; i<iData->dim.nsi; ++i,id += iData->dim.deg)
      for(j = 0; j < iData->dim.deg; ++j)
        dtime->time[++k] = dtime->time[id] + mbase->c[1][j]*dtime->dt[i];


  dtime->time[k] = dtime->tf;
  return 0;
}

/*!
 *  file for optimizer steps
 *  author: Vitalij Ruge
 **/
static int optimizer_print_step(IPOPT_DATA_ *iData)
{
  char buffer[4096];
  int i,j,k;
  iData->pFile = (FILE**) calloc(iData->dim.nv, sizeof(FILE*));
  for(i=0, j=0; i<iData->dim.nv; i++, ++j){
    if(j <iData->dim.nx)
      sprintf(buffer, "./%s_ipoptPath_states.csv", iData->data->modelData.realVarsData[j].info.name);
    else if(j< iData->dim.nv)
      sprintf(buffer, "./%s_ipoptPath_input.csv", "u");

    iData->pFile[j] = fopen(buffer, "wt");
    fprintf(iData->pFile[j], "%s,", "iteration");
  }

  for(i = 0 ,k = 0,j = 0; i<iData->dim.NV; ++i,++j){
    if(j >= iData->dim.nv){
      j = 0; ++k;
    }

    if(j < iData->dim.nx)
      fprintf(iData->pFile[j], "%s_%i,", iData->data->modelData.realVarsData[j].info.name, k);
    else if(j < iData->dim.nv)
      fprintf(iData->pFile[j], "%s_%s,", "u", iData->input_name[j-iData->dim.nx]);
  }
  return 0;
}

#endif

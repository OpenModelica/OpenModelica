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
 * OpenModelica Optimization (Ver 0.1)
 * Last Modification: 05. September 2013
 *
 * Developed by:
 * FH-Bielefeld
 * Developer: Vitalij Ruge
 * Contact: vitalij.ruge@fh-bielefeld.de
 */

#include "../ipoptODEstruct.h"
#include "../localFunction.h"



#ifdef WITH_IPOPT
#define DF_STEP(x,s) ( (fmin(fmax(1e-4*fabs(s*x),1e-8),1e-1)))
static inline int evalG11(Number *g, IPOPT_DATA_ *iData, double *x0, int i);
static inline int evalG12(Number *g, IPOPT_DATA_ *iData, double *x0, int i);
static inline int evalG13(Number *g, IPOPT_DATA_ *iData, double *x0, int i);
static inline int evalG21(Number *g, IPOPT_DATA_ *iData, double *x0, int i);
static inline int evalG22(Number *g, IPOPT_DATA_ *iData, double *x0, int i);
static inline int evalG23(Number *g, IPOPT_DATA_ *iData, double *x0, int i);
static int diff_symColoredODE(double *v, double t, IPOPT_DATA_ *iData, double **J);
static int num_diff_symColoredODE(double *v, double t, IPOPT_DATA_ *iData, double **J);
static int printMaxError(IPOPT_DATA_ *iData, double *g,double time, double * max_err , double * tt, int *xi);

/*!
 *  eval s.t.
 *  author: Vitalij Ruge
 **/
Bool evalfG(Index n, double * v, Bool new_x, int m, Number *g, void * useData)
{
   IPOPT_DATA_ *iData;
   int i,k,j;
   double *x0;
   double max_err = -1;
   double max_err_time = -1;
   int max_err_xi = -1;

   iData = (IPOPT_DATA_ *) useData;
   for(i=0, k=0, x0=v; i<1; ++i, x0=iData->x3){
     iData->x1 = x0 + iData->nv; /* 0 + 3 = 3;2*/
     iData->x2 = iData->x1 + iData->nv; /*3 + 3 = 6;5*/
     iData->x3 = iData->x2 + iData->nv; /*6 + 3  = 9*/

     iData->u1 = iData->x1 + iData->nx; /*3 + 2 = 5*/
     iData->u2 = iData->x2 + iData->nx; /*6 + 2 = 8*/
     iData->u3 = iData->x3 + iData->nx;

     /*1*/
     functionODE_(x0, x0 + iData->nx, iData->time[0], iData->dotx0, iData);
     functionODE_(iData->x1, iData->u1, iData->time[1], iData->dotx1, iData);
     evalG21(g + k, iData, x0, i);
     if(ACTIVE_STREAM(LOG_IPOPT_ERROR))
       printMaxError(iData,g,iData->time[1],&max_err, &max_err_time, &max_err_xi);

     k += iData->nJ;

     /*2*/
     functionODE_(iData->x2, iData->u2, iData->time[2], iData->dotx2, iData);
     evalG22(g + k, iData, x0, i);
     if(ACTIVE_STREAM(LOG_IPOPT_ERROR))
       printMaxError(iData,g,iData->time[2],&max_err, &max_err_time, &max_err_xi);
     k += iData->nJ;

     /*3*/
     functionODE_(iData->x3, iData->u3, iData->time[3], iData->dotx3, iData);
     evalG23(g + k, iData, x0, i);
     if(ACTIVE_STREAM(LOG_IPOPT_ERROR))
       printMaxError(iData,g,iData->time[3],&max_err, &max_err_time, &max_err_xi);
     k += iData->nJ;
  }

  for(; i<iData->nsi; ++i, x0=iData->x3){
    iData->x1 = x0 + iData->nv; /* 0 + 3 = 3;2*/
    iData->x2 = iData->x1 + iData->nv; /*3 + 3 = 6;5*/
    iData->x3 = iData->x2 + iData->nv; /*6 + 3  = 9*/

    iData->u1 = iData->x1 + iData->nx; /*3 + 2 = 5*/
    iData->u2 = iData->x2 + iData->nx; /*6 + 2 = 8*/
    iData->u3 = iData->x3 + iData->nx;

    /*1*/
    functionODE_(iData->x1, iData->u1, iData->time[i*iData->deg + 1], iData->dotx1, iData);
    evalG11(g + k, iData, x0, i);
    if(ACTIVE_STREAM(LOG_IPOPT_ERROR))
      printMaxError(iData,g,iData->time[i*iData->deg + 1],&max_err, &max_err_time, &max_err_xi);
    k += iData->nJ;

    /*2*/
    functionODE_(iData->x2, iData->u2, iData->time[i*iData->deg + 2], iData->dotx2, iData);
    evalG12(g + k, iData, x0, i);
    if(ACTIVE_STREAM(LOG_IPOPT))
      printMaxError(iData,g,iData->time[i*iData->deg + 2],&max_err, &max_err_time, &max_err_xi);
    k += iData->nJ;

    /*3*/
    functionODE_(iData->x3, iData->u3, iData->time[i*iData->deg + 3], iData->dotx3, iData);
    evalG13(g + k, iData, x0, i);
    if(ACTIVE_STREAM(LOG_IPOPT_ERROR))
      printMaxError(iData,g,iData->time[i*iData->deg + 3],&max_err, &max_err_time, &max_err_xi);
    k += iData->nJ;
  }
  if(ACTIVE_STREAM(LOG_IPOPT_ERROR)){

    if(max_err_xi < iData->nx)
      printf("\nmax error for |%s(%g) - collocation_poly| = %g\n",iData->data->modelData.realVarsData[max_err_xi].info.name,max_err_time,max_err);
    else
      printf("\nmax error for |cosntrain[%i](%g)| = %g\n", (int)max_err_xi-(int)iData->nx, max_err_time, max_err);
  }
  return TRUE;
}

/*!
 *  eval modell ODE
 *  author: Vitalij Ruge
 **/
int functionODE_(double * x, double *u, double t, double * dotx, IPOPT_DATA_ *iData)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)iData->data->localData[0];
  refreshSimData(x, u,  t, iData);
  memcpy(dotx, sData->realVars + iData->nx, sizeof(double)*iData->nx);
  return 0;
}

/*!
 *  eval a part from the derivate of s.t.
 *  author: Vitalij Ruge
 **/
int diff_functionODE(double* v, double t, IPOPT_DATA_ *iData, double **J)
{
  int i, j;
  double *x, *u;
  int nJ = (int)iData->nJ;
  x = v;
  u = v + iData->nx;

  if(iData->useNumJac>0){

    num_diff_symColoredODE(v,t,iData,J);
    for(i = 0;i<iData->nv;++i)
      for(j = 0; j <iData->nx; ++j)
        iData->numJ[j][i] *= iData->scalf[j];

  }else{
    refreshSimData(x,u,t,iData);
    diff_symColoredODE(v,t,iData,J);
    for(i = 0;i<iData->nv;++i){
      for(j = 0; j <iData->nx; ++j)
        J[j][i] *= iData->scalf[j]*iData->vnom[i];
      for(; j <nJ; ++j)
        J[j][i] *= iData->vnom[i];
    }
 }

  /*
  #ifdef JAC_ADOLC
  for(j = 0; j<iData->nv;++j)
    iData->sv[j] = v[j]*iData->vnom[j];

  jacobian(0, iData->nx, iData->nv, iData->sv, iData->J);
  for(i = 0;i<iData->nv;++i)
    for(j = 0; j <iData->nx; ++j)
      J[j][i] *= iData->scalf[j]*iData->vnom[i];
  #endif
  */
  
  return 0;
}

/*
 *  function calculates a symbolic colored jacobian matrix by
 *  author: Willi Braun
 */
int num_diff_symColoredODE(double *v, double t, IPOPT_DATA_ *iData, double **J)
{
  DATA * data = iData->data;
  const int index = 2;
  double*x,*u;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)iData->data->localData[0];
  int i,j,l,ii,nx;
  int *cC,*lindex;

  x = v;
  u = x + iData->nx;

  nx = data->simulationInfo.analyticJacobians[index].sizeCols;
  cC =  (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
  lindex = (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;

  memcpy(iData->vsave, v, sizeof(double)*nx);

  for(ii = 0; ii<nx; ++ii){
  iData->eps[ii] = DF_STEP(v[ii], iData->vnom[ii]);
  }

  for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i){

    for(ii = 0; ii<nx; ++ii)
      if(cC[ii] == i){
      v[ii] = iData->vsave[ii] + iData->eps[ii];
      //printf("\nlv[%i] = %g\t eps[%i] = %g",ii,v[ii], ii,iData->eps[ii]);
      }

    functionODE_(x, u, t, iData->lhs, iData);
    if(iData->nc > 0)
      memcpy(iData->lhs + iData->nx, &iData->data->localData[0]->realVars[iData->data->modelData.nVariablesReal - iData->nc], sizeof(double)*iData->nc);

    for(ii = 0; ii<nx; ++ii)
      if(cC[ii] == i)
      {
      v[ii] = iData->vsave[ii] - iData->eps[ii];
      //printf("\nrv[%i] = %g\t eps[%i] = %g",ii,v[ii], ii,iData->eps[ii]);
      }

    functionODE_(x, u, t, iData->rhs, iData);
    if(iData->nc > 0)
      memcpy(iData->rhs + iData->nx, &iData->data->localData[0]->realVars[iData->data->modelData.nVariablesReal - iData->nc], sizeof(double)*iData->nc);

    memcpy(v, iData->vsave, sizeof(double)*nx);

    for(ii = 0; ii < nx; ii++){
      if(cC[ii] == i){
        if(ii == 0)  j = 0;
        else j = lindex[ii-1];
        
        for(; j<lindex[ii]; ++j){
          l = data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
          J[l][ii] = (iData->lhs[l] - iData->rhs[l])/(2.0*iData->eps[ii]);
        }
      }
    }
  }

  return 0;
}


/*
 *  function calculates a symbolic colored jacobian matrix by
 *  author: Willi Braun
 */
int diff_symColoredODE(double *v, double t, IPOPT_DATA_ *iData, double **J)
{
  DATA * data = iData->data;
  const int index = 2;
  double*x,*u;

  int i,j,l,ii,nx;
  int *cC,*lindex;

  x = v;
  u = x + iData->nx;

  nx = data->simulationInfo.analyticJacobians[index].sizeCols;
  cC =  (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
  lindex = (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;

  for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i){
    for(ii = 0; ii<nx; ++ii){
      if(cC[ii] == i){
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1.0;
      }
    }

    data->callback->functionJacB_column(data);

    for(ii = 0; ii < nx; ii++){
      if(cC[ii] == i){
        if(ii == 0)  j = 0;
        else j = lindex[ii-1];

        for(; j<lindex[ii]; ++j){
          l = data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
          J[l][ii] = data->simulationInfo.analyticJacobians[index].resultVars[l];
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


/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static inline int evalG11(Number *g, IPOPT_DATA_ *iData, double *x0, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->a1[0]*x0[j] + iData->a1[3]*iData->x3[j] + iData->scalf[j]*iData->dt[i]*iData->dotx1[j]) - (iData->a1[1]*iData->x1[j] + iData->a1[2]*iData->x2[j]);

  memcpy(g + iData->nx, &iData->data->localData[0]->realVars[iData->data->modelData.nVariablesReal - iData->nc], sizeof(double)*iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static inline int evalG12(Number *g, IPOPT_DATA_ *iData, double *x0, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->a2[1]*iData->x1[j] + iData->scalf[j]*iData->dt[i]*iData->dotx2[j]) - (iData->a2[0]*x0[j] + iData->a2[2]*iData->x2[j] + iData->a2[3]*iData->x3[j]);

  memcpy(g + iData->nx, &iData->data->localData[0]->realVars[iData->data->modelData.nVariablesReal - iData->nc], sizeof(double)*iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static inline int evalG13(Number *g, IPOPT_DATA_ *iData, double *x0, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->a3[0]*x0[j] + iData->a3[2]*iData->x2[j] + iData->scalf[j]*iData->dt[i]*iData->dotx3[j]) - (iData->a3[1]*iData->x1[j] + iData->a3[3]*iData->x3[j]);

  memcpy(g + iData->nx, &iData->data->localData[0]->realVars[iData->data->modelData.nVariablesReal - iData->nc], sizeof(double)*iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static inline int evalG21(Number *g, IPOPT_DATA_ *iData, double *x0, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->scalf[j]*iData->dt[i]*(iData->dotx1[j] + iData->d1[4]*iData->dotx0[j]) + iData->d1[0]*x0[j] + iData->d1[3]*iData->x3[j]) - (iData->d1[1]*iData->x1[j] + iData->d1[2]*iData->x2[j]);

  memcpy(g + iData->nx, &iData->data->localData[0]->realVars[iData->data->modelData.nVariablesReal - iData->nc], sizeof(double)*iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static inline int evalG22(Number *g, IPOPT_DATA_ *iData, double *x0, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->scalf[j]*iData->dt[i]*iData->dotx2[j] + iData->d2[1]*iData->x1[j]) - (iData->scalf[j]*iData->dt[i]*iData->d2[4]*iData->dotx0[j] + iData->d2[0]*x0[j] + iData->d2[2]*iData->x2[j] + iData->d2[3]*iData->x3[j]);

  memcpy(g + iData->nx, &iData->data->localData[0]->realVars[iData->data->modelData.nVariablesReal - iData->nc], sizeof(double)*iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static inline int evalG23(Number *g, IPOPT_DATA_ *iData, double *x0, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->scalf[j]*iData->dt[i]*(iData->d3[4]*iData->dotx0[j] + iData->dotx3[j]) + iData->d3[0]*x0[j] + iData->d3[2]*iData->x2[j]) - (iData->d3[1]*iData->x1[j] + iData->d3[3]*iData->x3[j]);

  memcpy(g + iData->nx, &iData->data->localData[0]->realVars[iData->data->modelData.nVariablesReal - iData->nc], sizeof(double)*iData->nc);
  return 0;

}

static int printMaxError(IPOPT_DATA_ *iData, double *g,double t, double * max_err, double * tt, int *xi)
{
  double tmp;
  int j;

  for(j = 0; j<(int)iData->nx; ++j){
    tmp = fabs(g[j]);
    //printf("\n time %g vs. %g | %g vs. %g",t,*tt,tmp,*max_err);
    if((double) tmp > (double)*max_err){
      *max_err = tmp;
      *tt = t;
      *xi = j;
    }
  }

  for(; j<(int)iData->nJ; ++j){
    if((double)g[j]> (double)*max_err){
      *max_err = tmp;
      *tt = t;
      *xi = j;
    }
  }
}


#undef DF_STEP
#endif

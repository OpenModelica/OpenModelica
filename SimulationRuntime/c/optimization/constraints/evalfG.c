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
#include "../OptimizationFlags.h"
#include "../localFunction.h"



#ifdef WITH_IPOPT
static int evalG11(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i);
static int evalG12(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i);
static int evalG13(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i);
static int evalG21(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i);
static int evalG22(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i);
static int evalG23(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i);

/*!
 *  eval s.t.
 *  author: Vitalij Ruge
 **/
Bool evalfG(Index n, double * v, Bool new_x, int m, Number *g, void * useData)
{
  IPOPT_DATA_ *iData;
  int i,k;
  double *x0,*x1,*x2,*x3;

  iData = (IPOPT_DATA_ *) useData;
  for(i=0, k=0, x0=v; i<1; ++i, x0=x3){
    x1 = x0 + iData->nv; /* 0 + 3 = 3;2*/
    x2 = x1 + iData->nv; /*3 + 3 = 6;5*/
    x3 = x2 + iData->nv; /*6 + 3  = 9*/

    iData->u1 = x1 + iData->nx; /*3 + 2 = 5*/
    iData->u2 = x2 + iData->nx; /*6 + 2 = 8*/
    iData->u3 = x3 + iData->nx;

    /*1*/
    functionODE_(x0, x0 + iData->nx, iData->time[0], iData->dotx0, iData);
    functionODE_(x1, iData->u1, iData->time[1], iData->dotx1, iData);
    evalG21(g + k, iData, x0, x1, x2, x3, i);
    k += iData->nJ;

    /*2*/
    functionODE_(x2, iData->u2, iData->time[2], iData->dotx2, iData);
    evalG22(g + k, iData, x0, x1, x2, x3, i);
    k += iData->nJ;

    /*3*/
    functionODE_(x3, iData->u3, iData->time[3], iData->dotx3, iData);
    evalG23(g + k, iData, x0, x1, x2, x3, i);
    k += iData->nJ;
  }

  for(; i<iData->nsi; ++i, x0=x3){
    x1 = x0 + iData->nv; /* 0 + 3 = 3;2*/
    x2 = x1 + iData->nv; /*3 + 3 = 6;5*/
    x3 = x2 + iData->nv; /*6 + 3  = 9*/

    iData->u1 = x1 + iData->nx; /*3 + 2 = 5*/
    iData->u2 = x2 + iData->nx; /*6 + 2 = 8*/
    iData->u3 = x3 + iData->nx;

    /*1*/
    functionODE_(x1, iData->u1, iData->time[i*iData->deg + 1], iData->dotx1, iData);
    evalG11(g + k, iData, x0, x1, x2, x3, i);
    k += iData->nJ;

    /*2*/
    functionODE_(x2, iData->u2, iData->time[i*iData->deg + 2], iData->dotx2, iData);
    evalG12(g + k, iData, x0, x1, x2, x3, i);
    k += iData->nJ;

    /*3*/
    functionODE_(x3, iData->u3, iData->time[i*iData->deg + 3], iData->dotx3, iData);
    evalG13(g + k, iData, x0, x1, x2, x3, i);
    k += iData->nJ;
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
  double h;
  int i, j, k;
  double vsave;
  double tmp;
  double *x, *u;
  long double rcal;
  int nJ = iData->nx + iData->nc;
  x = v;
  u = v + iData->nx;

  refreshSimData(x,u,t,iData);
  diff_symColoredODE(v,t,iData,J);
  for(i = 0;i<iData->nv;++i){
    for(j = 0; j <iData->nx; ++j)
      J[j][i] *= iData->scalf[j]*iData->vnom[i];
    for(; j <nJ; ++j)
      J[j][i] *= iData->vnom[i];
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

  for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i)
  {
    for(ii = 0; ii<nx; ++ii)
    {
      if(cC[ii] == i)
      {
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1.0;
      }
    }

    data->callback->functionJacB_column(data);

    for(ii = 0; ii < nx; ii++)
    {
      if(cC[ii] == i)
      {
        if(ii == 0)j = 0;
        else j = lindex[ii-1];
        
        for(; j<lindex[ii]; ++j)
        {
          l = data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
          J[l][ii] = data->simulationInfo.analyticJacobians[index].resultVars[l];
        }
      }
    }

    for(ii = 0; ii<nx; ++ii)
    {
      if(cC[ii] == i)
      {
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
static int evalG11(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->a1[0]*x0[j] + iData->a1[3]*x3[j] + iData->scalf[j]*iData->dt[i]*iData->dotx1[j]) - (iData->a1[1]*x1[j] + iData->a1[2]*x2[j]);

  iData->data->callback->pathConstraints(iData->data,g + iData->nx,&iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static int evalG12(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->a2[1]*x1[j] + iData->scalf[j]*iData->dt[i]*iData->dotx2[j]) - (iData->a2[0]*x0[j] + iData->a2[2]*x2[j] + iData->a2[3]*x3[j]);

  iData->data->callback->pathConstraints(iData->data,g + iData->nx,&iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static int evalG13(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->a3[0]*x0[j] + iData->a3[2]*x2[j] + iData->scalf[j]*iData->dt[i]*iData->dotx3[j]) - (iData->a3[1]*x1[j] + iData->a3[3]*x3[j]);

  iData->data->callback->pathConstraints(iData->data,g + iData->nx,&iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static int evalG21(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->scalf[j]*iData->dt[i]*(iData->dotx1[j] + iData->d1[4]*iData->dotx0[j]) + iData->d1[0]*x0[j] + iData->d1[3]*x3[j]) - (iData->d1[1]*x1[j] + iData->d1[2]*x2[j]);

  iData->data->callback->pathConstraints(iData->data,g + iData->nx,&iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static int evalG22(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->scalf[j]*iData->dt[i]*iData->dotx2[j] + iData->d2[1]*x1[j]) - (iData->scalf[j]*iData->dt[i]*iData->d2[4]*iData->dotx0[j] + iData->d2[0]*x0[j] + iData->d2[2]*x2[j] + iData->d2[3]*x3[j]);

  iData->data->callback->pathConstraints(iData->data, g + iData->nx, &iData->nc);
  return 0;

}

/*!
 *  helper evalfG
 *  author: Vitalij Ruge
 **/
static int evalG23(Number *g, IPOPT_DATA_ *iData, double *x0, double *x1, double *x2, double *x3, int i)
{
  int j;
  for(j=0; j<iData->nx; ++j)
    g[j] = (iData->scalf[j]*iData->dt[i]*(iData->d3[4]*iData->dotx0[j] + iData->dotx3[j]) + iData->d3[0]*x0[j] + iData->d3[2]*x2[j]) - (iData->d3[1]*x1[j] + iData->d3[3]*x3[j]);

  iData->data->callback->pathConstraints(iData->data, g + iData->nx, &iData->nc);
  return 0;

}



#endif

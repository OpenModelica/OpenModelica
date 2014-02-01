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

int diff_functionODE_debug(double* v, double t, IPOPT_DATA_ *iData);

/*!
 *  eval s.t.
 *  author: Vitalij Ruge
 **/
Bool evalfG(Index n, double * v, Bool new_x, int m, Number *g, void * useData)
{
  IPOPT_DATA_ *iData;
  int i,j,k;
  double *dt;
  double *x0,*x1,*x2,*x3;
  double *dotx0,*dotx1, *dotx2, *dotx3;
  double *a1,*a2,*a3;
  double *scaldf;
  DATA *data;

  iData = (IPOPT_DATA_ *) useData;
  if(iData->deg == 3){
  data = iData->data;
  dotx0 = iData->dotx0;
  dotx1 = iData->dotx1;
  dotx2 = iData->dotx2;
  dotx3 = iData->dotx3;
  scaldf = iData->scalf;
  a1 = iData->a1;
  a2 = iData->a2;
  a3 = iData->a3;
  dt = iData->dt;
  

  for(i=0, k=0, x0=v; i<iData->nsi; ++i, x0=x3)
  {
    x1 = x0 + iData->nv; /* 0 + 3 = 3;2*/
    x2 = x1 + iData->nv; /*3 + 3 = 6;5*/
    x3 = x2 + iData->nv; /*6 + 3  = 9*/

    iData->u1 = x1 + iData->nx; /*3 + 2 = 5*/
    iData->u2 = x2 + iData->nx; /*6 + 2 = 8*/
    iData->u3 = x3 + iData->nx;

    if(i)
    {
      /*1*/
      functionODE_(x1, iData->u1, iData->time[i*iData->deg + 1], dotx1, iData);
      for(j=0; j<iData->nx; ++j)
      {
        g[k++] = (a1[0]*x0[j] + a1[3]*x3[j] + scaldf[j]*dt[i]*dotx1[j]) - (a1[1]*x1[j] + a1[2]*x2[j]);
      }
      iData->data->callback->pathConstraints(data,&g[k],&iData->nc);

      /*2*/
      k += iData->nc;
      functionODE_(x2, iData->u2, iData->time[i*iData->deg + 2], dotx2, iData);

      for(j=0; j<iData->nx; ++j)
      {
        g[k++] = (a2[1]*x1[j] + scaldf[j]*dt[i]*dotx2[j]) - (a2[0]*x0[j] + a2[2]*x2[j] + a2[3]*x3[j]);
      }
      iData->data->callback->pathConstraints(data,&g[k],&iData->nc);

      /*3*/
      k += iData->nc;
      functionODE_(x3, iData->u3, iData->time[i*iData->deg + 3], dotx3, iData);

      for(j=0; j<iData->nx; ++j)
      {
        g[k++] = (a3[0]*x0[j] + a3[2]*x2[j] + scaldf[j]*dt[i]*dotx3[j]) - (a3[1]*x1[j] + a3[3]*x3[j]);
      }
      iData->data->callback->pathConstraints(data,&g[k],&iData->nc);
      k += iData->nc;
    }
    else
    {
      double *d1, *d2, *d3;

      functionODE_(x0, x0 + iData->nx, iData->time[0], dotx0, iData);

      d1 = iData->d1;
      d2 = iData->d2;
      d3 = iData->d3;

      functionODE_(x1, iData->u1, iData->time[1], dotx1, iData);
      for(j=0; j<iData->nx; ++j)
      {
        g[k++] = (scaldf[j]*dt[i]*(dotx1[j] + d1[4]*dotx0[j]) + d1[0]*x0[j] + d1[3]*x3[j]) - (d1[1]*x1[j] + d1[2]*x2[j]);
        //g[k-1] *= 10.0;
      }
      iData->data->callback->pathConstraints(data,&g[k],&iData->nc);
      k += iData->nc;

      functionODE_(x2, iData->u2, iData->time[2], dotx2, iData);
      for(j=0; j<iData->nx; ++j)
      {
        g[k++] = (scaldf[j]*dt[i]*dotx2[j] + d2[1]*x1[j]) - (scaldf[j]*dt[i]*d2[4]*dotx0[j] + d2[0]*x0[j] + d2[2]*x2[j] + d2[3]*x3[j]);
        //g[k-1] *= 10.0;
      }
      iData->data->callback->pathConstraints(data,&g[k],&iData->nc);
      k += iData->nc;
      
      functionODE_(x3, iData->u3, iData->time[3], dotx3, iData);
      for(j=0; j<iData->nx; ++j)
      {
        g[k++] = (scaldf[j]*dt[i]*(d3[4]*dotx0[j] + dotx3[j]) + d3[0]*x0[j] + d3[2]*x2[j]) - (d3[1]*x1[j] + d3[3]*x3[j]);
        //g[k-1] *= 10.0;
      }
      iData->data->callback->pathConstraints(data,&g[k],&iData->nc);
      k += iData->nc;
    }
  }
  }else{
	  data = iData->data;
	  dotx0 = iData->dotx0;
	  dotx1 = iData->dotx1;

	  for(i=0, k=0, x0=v; i<iData->nsi; ++i, x0=x1){
		    x1 = x0 + iData->nv; /* 0 + 3 = 3;2*/
		    x2 = x1 + iData->nv; /*3 + 3 = 6;5*/
		    if(i){
		      functionODE_(x1, iData->u1, iData->time[1], dotx1, iData);
		      for(j=0; j<iData->nx; ++j)
		        g[k++] = x0[j] + dt[i]*dotx1[j];
		      iData->data->callback->pathConstraints(data,&g[k],&iData->nc);
		      k += iData->nc;

		    }else{
		    	functionODE_(x0, x0 + iData->nx, iData->time[0], dotx0, iData);
		    	for(j=0; j<iData->nx; ++j)
		    		g[k++] = x0[j] + 0.5*dt[i]*(dotx0[j] + dotx1[j]);
		    }

	  }
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

/*!
 *  eval a part from the derivate of s.t.
 *  author: Vitalij Ruge
 **/
int diff_functionODE0(double* v, double t, IPOPT_DATA_ *iData)
{
  diff_functionODE(v, t, iData, iData->J0);
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

#endif

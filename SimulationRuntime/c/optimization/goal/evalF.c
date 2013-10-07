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

#include "../ipoptODEstruct.h"
#include "../OptimizationFlags.h"

#ifdef WITH_IPOPT

static int eval_diff_mayer(IPOPT_DATA_ *iData, double* gradF, double *v);
static int eval_diff_lagrange1(IPOPT_DATA_ *iData, double *x, int *id_, double* gradF);
static int eval_diff_lagrange2(IPOPT_DATA_ *iData, double *x, int *id_, double* gradF);


/*!
 *  eval object function
 *  author: Vitalij Ruge
 **/
Bool evalfF(Index n, double * v, Bool new_x, Number *objValue, void * useData)
{
  IPOPT_DATA_ *iData = (IPOPT_DATA_*) useData;
  double mayer = 0.0;
  double lagrange = 0.0;

  if(iData->mayer){
    goal_func_mayer(v + iData->endN, &mayer,iData);
  }

  if(iData->lagrange){
    double *x;
    double tmp;
    int i,k,j;
    long double erg,erg_;

    erg_ = 0.0;

    for(i=0, k=0, x=v; i<1; ++i)
    {
      erg = 0.0;
      for(j=0; j<iData->deg+1; ++j, x+=iData->nv, ++k)
      {
        goal_func_lagrange(x, &tmp,iData->time[k], iData);
        erg += iData->bl[j]*tmp;
      }
      erg_+= erg*iData->dt[i];
    }

    for(; i<iData->nsi; ++i)
    {
      for(j=0; j<iData->deg; ++j, x+=iData->nv, ++k)
      {
        goal_func_lagrange(x, &tmp, iData->time[k], iData);
        erg += iData->br[j]*tmp;
      }

      erg_ += erg*iData->dt[i];
    }

    lagrange = (double) erg_;
  }

  *objValue = mayer + lagrange;
  return TRUE;
}

/*!
 *  eval mayer term
 *  author: Vitalij Ruge
 **/
Bool goal_func_mayer(double* vn, double *obj_value, IPOPT_DATA_ *iData)
{
  double *x = vn;
  double *u = vn + iData->nx;
  
  refreshSimData(x, u, iData->tf, iData);
  functionAlgebraics(iData->data);
  mayer(iData->data, obj_value, 0);
  
  return TRUE;
}

/*!
 *  eval lagrange term
 *  author: Vitalij Ruge
 **/
Bool goal_func_lagrange(double* vn, double *obj_value, double t, IPOPT_DATA_ *iData)
{
  double *x = vn;
  double *u = vn + iData->nx;
  
  refreshSimData(x, u, iData->tf, iData);
  functionAlgebraics(iData->data);
  lagrange(iData->data, obj_value, 0);
  
  return TRUE;
}

/*!
 *  eval derivation (object func)
 *  author: Vitalij Ruge
 **/
Bool evalfDiffF(Index n, double * v, Bool new_x, Number *gradF, void * useData)
{
  int i,j,k,id;
  double obj0,tmp;
  long double tmp2;
  double vsave;
  double *x;
  long double h;
  IPOPT_DATA_ *iData = (IPOPT_DATA_*) useData;

  if(iData->lagrange)
  {
    x = v;
    id = 0;
    
    for(i=0, k=1; i<iData->nsi; ++i)
    {
      if(i>0)
      {
        for(k=0; k<iData->deg; ++k, x+=iData->nv)
        {

          diff_symColoredObject(x, iData->time[i*iData->deg+k], iData, iData->gradF, iData->lagrange_index);
          for(j = 0; j<iData->nv; ++j)
          {
            gradF[id++] =  iData->dt[i]*iData->br[k]*iData->gradF[j]*iData->vnom[j];
            /* printf("\n gradF(%i) = %g, %s, %g", id-1, gradF[id-1], iData->data->modelData.realVarsData[j].info.name, x[j]*iData->vnom[j]); */
          }
        }
      }
      else
      {
        for(k=0; k<iData->deg+1; ++k, x+=iData->nv)
        {
          diff_symColoredObject(x, iData->time[i*iData->deg+k], iData, iData->gradF,iData->lagrange_index);
          for(j=0; j<iData->nv; ++j)
          {
            gradF[id++] = iData->dt[i]*iData->bl[k]*iData->gradF[j]*iData->vnom[j];
            /* printf("\n gradF(%i) = %g, %s, %g", id-1, gradF[id-1], iData->data->modelData.realVarsData[j].info.name, x[j]*iData->vnom[j]); */
          }
        }
      }
    }
  } else {
    for(i=0; i<n; ++i)
      gradF[i] = 0.0;
  }
  if(iData->mayer){
    x = v + iData->endN;
    diff_symColoredObject(x, iData->tf, iData, iData->gradF, iData->mayer_index);
    for(j=0; j<iData->nv; ++j)
    {
      if(iData->lagrange){
        gradF[iData->endN + j] +=  iData->gradF[j]*iData->vnom[j];
      } else {
        gradF[iData->endN + j] = iData->gradF[j]*iData->vnom[j];
      }
    }
  }
  return TRUE;
}


/*
 *  function calculates a symbolic colored gradient "matrix"
 *  author: vitalij
 */
int diff_symColoredObject(double *v, double t, IPOPT_DATA_ *iData, double *dF, int this_it)
{
  DATA * data = iData->data;
  const int index1 = 3;
  const int index2 = 4;
  double*x,*u;

  int i,k;

  x = v;
  u = x + iData->nx;
  refreshSimData(x,u,t,iData);

  if(iData->matrixC ==0){
    for(i= 0, k = 0; i<iData->nx; ++i, ++k)
    {
    data->simulationInfo.analyticJacobians[index1].seedVars[i] = 1.0;
    functionJacC_column(data);
    data->simulationInfo.analyticJacobians[index1].seedVars[i] = 0.0;
    if(this_it ==0)
      mayer(iData->data, &dF[k],1);
    else
      lagrange(iData->data, &dF[k],1);

    /*printf("\tdF[%i] = %g\t",k,dF[k]);*/
    }
  }
  if(iData->matrixD ==0){
    for(k =iData->nx, i = 0 ; i<iData->nu; ++i, ++k)
    {
    data->simulationInfo.analyticJacobians[index2].seedVars[i] = 1.0;
    functionJacD_column(data);
    data->simulationInfo.analyticJacobians[index2].seedVars[i] = 0.0;
    if(this_it ==0)
      mayer(iData->data, &dF[k],2);
    else
      lagrange(iData->data, &dF[k],2);
    /*printf("dF[%i] = %g\t",k,dF[k]);*/
    }
  }

  return 0;
}
#endif

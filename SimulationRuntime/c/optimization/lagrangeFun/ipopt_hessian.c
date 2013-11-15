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

#include"../ipoptODEstruct.h"
#include "../OptimizationFlags.h"

#ifdef WITH_IPOPT

static int num_hessian(double *v, double t, IPOPT_DATA_ *iData, double *lambda, short lagrange_yes, short mayer_yes, double obj_factor);
static int diff_symColoredObject_hess(double *v, double t, IPOPT_DATA_ *iData, double *dF, int this_it);

/*!
 *  calc hessian
 *  autor: Vitalij Ruge
 **/
Bool ipopt_h(int n, double *v, Bool new_x, double obj_factor, int m, double *lambda, Bool new_lambda,
                    int nele_hess, int *iRow, int *iCol, double *values, void* useData)
{

  int i,j,k;
  IPOPT_DATA_ *iData;

  iData = (IPOPT_DATA_ *) useData;
  k = 0;
  if(values == NULL)
  {
    int c,r,l,p;
    r = 0;
    c = 0;
    for(i = 0; i<iData->nsi; ++i)
    {

      if(i == 0)
      {
        /*0*/
        for(p = 0;p <iData->deg+1;++p)
        {
          for(j=0;j< iData->nv;++j)
            for(l = 0; l< j+1; ++l)
             {
              iRow[k] = r + j;
              iCol[k++] = c + l;
             }
          r += iData->nv;
          c += iData->nv;
        }
      }
      else{
        for(p = 1;p <iData->deg+1;++p)
        {
          for(j=0;j< iData->nv;++j)
            for(l = 0; l< j+1; ++l)
             {
              iRow[k] = r + j;
              iCol[k++] = c + l;
             }
          r += iData->nv;
          c += iData->nv;
        }
      }
    }
       /*
    for(i=0;i<nele_hess;++i)
      printf("\nH(%i,%i) = 1;", iRow[i]+1, iCol[i]+1);
      */
  }
  else
  {
    /*obj_factor*/
    double *x;
    double *ll;
    int ii;
    int c,r,p,id,l;
    double t;
    long double sum;
    long double mayer_term;
    short mayer_yes;
    r = 0;
    c = 0;
    k = 0;
    for(ii = 0; ii <1; ++ii)
    {
      for(p = 0, x= v, ll = lambda;p <iData->deg+1;++p, x += iData->nv)
      {
         if(!p)
          {
            for(j = 0; j<iData->nx; ++j)
              iData->sh[j] = iData->d1[4]*(ll[j] - ll[j + iData->nx]) + ll[j + 2*iData->nx];
            num_hessian(x, iData->time[p], iData,iData->sh,iData->lagrange,0,obj_factor);
          }else{
             num_hessian(x, iData->time[p], iData, ll, iData->lagrange, 0, obj_factor);
          }

        for(i=0;i< iData->nv;++i)
          for(j = 0; j< i+1; ++j)
          {
            sum = 0.0;
            for(l = 0; l<iData->nx; ++l)
              sum += iData->H[l][i][j];

            if(iData->lagrange)
              sum += iData->bl[p]*iData->oH[i][j];

            sum = iData->dt[ii]*sum;

            values[k++] = (double) sum;
          }
        r += iData->nv;
        c += iData->nv;

        if(p >0)
          ll += iData->nx;

      }

    }

    for(; ii <iData->nsi; ++ii)
    {
      for(p = 1;p <iData->deg +1;++p,x += iData->nv)
      {
        mayer_yes = iData->mayer && ii+1 == iData->nsi && p == iData->deg;
        num_hessian(x, iData->time[p], iData,ll,iData->lagrange,mayer_yes,obj_factor);

        for(i=0;i< iData->nv;++i)
          for(j = 0; j< i+1; ++j)
          {
            sum = 0.0;
            for(l = 0; l<iData->nx; ++l)
              sum += iData->H[l][i][j];

           if(iData->lagrange)
             sum += iData->br[p-1]*iData->oH[i][j];

           sum = iData->dt[ii]*sum;
           if(mayer_yes)
             sum += iData->mH[i][j];

            values[k++] = (double)sum;
          }
        r += iData->nv;
        c += iData->nv;
        ll += iData->nx;

      }

    }
  }
   //printf("\n k = %i \t %i",k, (int)nele_hess);
   //assert(k == nele_hess);
  return TRUE;
}

/*!
 *  cal hessian (mayer part)
 *  autor: Vitalij Ruge
 **/
static int num_hessian(double *v, double t, IPOPT_DATA_ *iData, double *lambda, short lagrange_yes, short mayer_yes, double obj_factor)
{
  long double v_save;
  long double h;
  int i, j, l;

  diff_functionODE(v, t , iData, iData->J0);
  if(lagrange_yes || mayer_yes)
    functionAlgebraics(iData->data);

  if(lagrange_yes)
    diff_symColoredObject_hess(v, t, iData, iData->gradF0, iData->lagrange_index);

  if(mayer_yes)
    diff_symColoredObject_hess(v, t, iData, iData->gradF00, iData->mayer_index);

  for(i = 0; i<iData->nv; ++i)
  {
    v_save = (long double)v[i];
    h = (long double)DF_STEP(v_save, iData->vnom[i]);
    v[i] += h;
    diff_functionODE(v, t , iData, iData->J);

    if(lagrange_yes || mayer_yes)
      functionAlgebraics(iData->data);

    if(lagrange_yes)
      diff_symColoredObject_hess(v, t, iData, iData->gradF, iData->lagrange_index);

    if(mayer_yes)
      diff_symColoredObject_hess(v, t, iData, iData->gradF_, iData->mayer_index);

    v[i] = v_save;
    for(l = 0; l< iData->nx; ++l)
    {
      for(j = i; j < iData->nv; ++j)
      {
        if(iData->knowedJ[l][j] + iData->knowedJ[l][i] >= 2)
          iData->H[l][i][j]  = lambda[l]*(iData->J[l][j] - iData->J0[l][j])/h;
        else
          iData->H[l][i][j] = (long double) 0.0;
        iData->H[l][j][i] = iData->H[l][i][j];
      }
    }
    if(lagrange_yes){
      for(j = i; j < iData->nv; ++j)
      {
       iData->oH[i][j]  = (long double) obj_factor/h* (iData->gradF[j] - iData->gradF0[j]);
       iData->oH[j][i]  = iData->oH[i][j] ; 
      }
    }
    if(mayer_yes){
      for(j = i; j < iData->nv; ++j)
      {
       iData->mH[i][j]  = (long double) obj_factor/h* (iData->gradF_[j] - iData->gradF00[j]);
       iData->mH[j][i]  = iData->mH[i][j] ; 
      }
    }
  }
}


/*
 *  function calculates a symbolic colored gradient "matrix" only for hess
 *  author: vitalij
 */
int diff_symColoredObject_hess(double *v, double t, IPOPT_DATA_ *iData, double *dF, int this_it)
{
  DATA * data = iData->data;
  const int index1 = 3;
  const int index2 = 4;
  double*x,*u;

  int i,k;

  x = v;
  u = x + iData->nx;
  

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

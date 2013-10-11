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

static int hessian_ode(double *v, double t, IPOPT_DATA_ *iData, double *lambda);
static int hessian_lagrange(double *v, double t, IPOPT_DATA_ *iData, double obj_factor);
static int hessian_mayer(double *v, double t, IPOPT_DATA_ *iData, double obj_factor);


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
      hessian_ode(x, iData->time[p], iData,ll);

        if(iData->lagrange)
           hessian_lagrange(x, iData->time[p], iData,obj_factor);

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
        hessian_ode(x, iData->time[ii*iData->deg + p], iData,ll);

        if(iData->lagrange)
         hessian_lagrange(x, iData->time[ii*iData->deg + p], iData, obj_factor);
        mayer_yes = iData->mayer && ii+1 == iData->nsi && p == iData->deg;
        if(mayer_yes)
         hessian_mayer(x, iData->time[ii*iData->deg + p], iData,obj_factor);

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
static int hessian_mayer(double *v, double t, IPOPT_DATA_ *iData, double obj_factor)
{
  long double v_save;
  long double h;
  long int i, j, l;
  diff_symColoredObject(v, t, iData, iData->gradF0, iData->mayer_index);
  for(i = 0; i<iData->nv; ++i)
  {
    v_save = (long double)v[i];
    h = (long double)DF_STEP(v_save, iData->vnom[i]);
    v[i] += h;
    diff_symColoredObject(v, t, iData, iData->gradF, iData->mayer_index);
    v[i] = v_save;

    for(j = i; j < iData->nv; ++j)
    {
     iData->mH[i][j]  = (long double) obj_factor/h* (iData->gradF[j] - iData->gradF0[j]);
     iData->mH[j][i]  = iData->mH[i][j] ; 
    }
  }

  return 0;

}

/*!
 *  cal hessian (lagrange part)
 *  autor: Vitalij Ruge
 **/
static int hessian_lagrange(double *v, double t, IPOPT_DATA_ *iData, double obj_factor)
{
  long double v_save;
  long double h;
  long int i, j, l;
  diff_symColoredObject(v, t, iData, iData->gradF0, iData->lagrange_index);
  for(i = 0; i<iData->nv; ++i)
  {
    v_save = (long double)v[i];
    h = (long double)DF_STEP(v_save, iData->vnom[i]);
    v[i] += h;
    diff_symColoredObject(v, t, iData, iData->gradF, iData->lagrange_index);
    v[i] = v_save;

    for(j = i; j < iData->nv; ++j)
    {
     iData->oH[i][j]  = (long double) obj_factor/h* (iData->gradF[j] - iData->gradF0[j]);
     iData->oH[j][i]  = iData->oH[i][j] ; 
    }
  }

  return 0;
}

/*!
 *  cal hessian (mayer part)
 *  autor: Vitalij Ruge
 **/
static int hessian_ode(double *v, double t, IPOPT_DATA_ *iData, double *lambda)
{
  long double v_save;
  long double h;
  int i, j, l;

  diff_functionODE(v, t , iData, iData->J0);
  for(i = 0; i<iData->nv; ++i)
  {
    v_save = (long double)v[i];
    h = (long double)DF_STEP(v_save, iData->vnom[i]);
    v[i] += h;
    diff_functionODE(v, t , iData, iData->J);
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
/*
        tmp = (double) iData->H[l][j][i];
        printf("H[%i][%i][%i] = %g \tindex = %i \t",l,j,i,(double)tmp, (int)(iData->knowedJ[l][j] + iData->knowedJ[l][i]));
        printf("h = %g", (double) h);
        printf("lambda[%i] = %g", l,(double) lambda[l]);
        printf("\tv_save = %g\n", (double)v_save);
        printf("\tlhs = %g\n", iData->J[l][j]);
        printf("\trhs = %g\n", iData->J0[l][j]);
        tmp = lambda[l]*(iData->J[l][j] - iData->J0[l][j])/h;
        printf("\tlhs - rhs = %g\n", (double) tmp);
*/
      }
    }
  }
}


#endif

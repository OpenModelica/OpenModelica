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

  if(0 == iData->mayer)
  {
    goal_func_mayer(v + iData->endN + 1, &mayer,iData);
  }

  if(0 == iData->lagrange)
  {
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
  mayer(iData->data, obj_value);
  
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
  lagrange(iData->data, obj_value);
  
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

  if(iData->lagrange == 0)
  {
    x = v;
    id = 0;
    
    for(i=0, k=1; i<iData->nsi; ++i)
    {
      if(i>0)
      {
        for(k=0; k<iData->deg; ++k, x+=iData->nv)
        {
          for(j = 0; j<iData->nv; ++j)
          {
            vsave = x[j];
            /* tmp = fabs(vsave); */
            /* h = (long double) (vsave + fmin(fmax(tmp*1e-3,1e-6),1e3))-vsave; */
            h = DF_STEP(vsave, iData->vnom[j]);
            x[j] = vsave + h;
            goal_func_lagrange(x, &obj0,iData->time[i*iData->deg+k], iData);
            x[j] = vsave - h;
            goal_func_lagrange(x, &tmp, iData->time[i*iData->deg+k], iData);
            x[j] = vsave;

            gradF[id++] = iData->dt[i]*iData->br[k]*(obj0-tmp)/(2*h);
            /* printf("\n gradF(%i) = %g, %s, %g", id-1, gradF[id-1], iData->data->modelData.realVarsData[j].info.name, x[j]*iData->vnom[j]); */
          }
        }
      }
      else
      {
        for(k=0; k<iData->deg+1; ++k, x+=iData->nv)
        {
          for(j=0; j<iData->nv; ++j)
          {
            vsave = x[j];
            h = DF_STEP(vsave, iData->vnom[j]);
            /* h = (long double) ( vsave + fmin(fmax(tmp*1e-3,1e-6),1e3))-vsave; */
            x[j] = vsave + h;
            goal_func_lagrange(x, &obj0,iData->time[i*iData->deg+k], iData);
            x[j] = vsave - h;
            goal_func_lagrange(x, &tmp,iData->time[i*iData->deg+k], iData);
            x[j] = vsave;
            gradF[id++] = iData->dt[i]*iData->bl[k]*(obj0-tmp)/(2*h);
            /* printf("\n gradF(%i) = %g, %s, %g", id-1, gradF[id-1], iData->data->modelData.realVarsData[j].info.name, x[j]*iData->vnom[j]); */
          }
        }
      }
    }
  }
  else
  {
    for(i=0; i<n; ++i)
      gradF[i] = 0.0;
  }
  if(0 == iData->mayer)
  {
    x = v + iData->endN + 1;
    for(j=0; j<iData->nv; ++j)
    {
      vsave = x[j];
      h = DF_STEP(vsave, iData->vnom[j]);
      x[j] = vsave + h;
      goal_func_mayer(x, &obj0, iData);
      x[j] = vsave - h;
      goal_func_mayer(x, &tmp, iData);
      x[j] = vsave;

      if(iData->lagrange == 0)
      {
        gradF[iData->endN + j + 1] += (obj0 - tmp)/(2*h);
      }
      else
      {
        gradF[iData->endN + j + 1] = (obj0 - tmp)/(2*h);
      }
    }
  }
  return TRUE;
}
#endif

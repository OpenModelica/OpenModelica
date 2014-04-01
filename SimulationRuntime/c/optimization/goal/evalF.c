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
#include "../localFunction.h"

#ifdef WITH_IPOPT

static int sym_diff_symColoredObject(IPOPT_DATA_ *iData, long double *dF, int this_it);

/*!
 *  eval object function
 *  author: Vitalij Ruge
 **/
Bool evalfF(Index n, double * v, Bool new_x, Number *objValue, void * useData)
{
  IPOPT_DATA_ *iData = (IPOPT_DATA_*) useData;
  double mayer = 0.0;
  double lagrange = 0.0;
  OPTIMIZER_MBASE *mbase = &iData->mbase;

  if(iData->sopt.mayer){
    goal_func_mayer(v + iData->dim.endN, &mayer,iData);
  }

  if(iData->sopt.lagrange){
    double *x;
    double tmp;
    int i,k,j;
    long double erg,erg_;

    erg_ = 0.0;

    for(i=0, k=0, x=v; i<1; ++i)
    {
      erg = 0.0;
      for(j=0; j<iData->dim.deg+1; ++j, x+=iData->dim.nv, ++k)
      {
        goal_func_lagrange(x, &tmp,k, iData);
        erg += mbase->b[0][j]*tmp;
      }
      erg_+= erg*iData->dtime.dt[i];
    }

    for(; i<iData->dim.nsi; ++i)
    {
      erg = 0.0;
      for(j=0; j<iData->dim.deg; ++j, x+=iData->dim.nv, ++k)
      {
        goal_func_lagrange(x, &tmp, k, iData);
        erg += mbase->b[1][j]*tmp;
      }

      erg_ += erg*iData->dtime.dt[i];
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
  refreshSimData(vn, vn + iData->dim.nx, iData->dim.nt-1, iData);
  iData->data->callback->mayer(iData->data, obj_value);
  
  return TRUE;
}

/*!
 *  eval lagrange term
 *  author: Vitalij Ruge
 **/
Bool goal_func_lagrange(double* vn, double *obj_value, int k, IPOPT_DATA_ *iData)
{  
  refreshSimData(vn, vn + iData->dim.nx, k, iData);
  iData->data->callback->lagrange(iData->data, obj_value);
  
  return TRUE;
}

/*!
 *  eval derivation (object func)
 *  author: Vitalij Ruge
 **/
Bool evalfDiffF(Index n, double * v, Bool new_x, Number *gradF, void * useData)
{
  int i,j,k,id;
  int tmpk;
  double obj0,tmp;
  long double tmp2;
  double vsave;
  double *x;
  long double h;
  IPOPT_DATA_ *iData = (IPOPT_DATA_*) useData;
  OPTIMIZER_MBASE *mbase = &iData->mbase;

  if(iData->sopt.lagrange) {
    x = v;
    id = 0;
    
    for(i=0; i<1; ++i){
      for(k=0; k<iData->dim.deg+1; ++k, x+=iData->dim.nv){
        tmpk = i*iData->dim.deg+k;
        refreshSimData(x,x+ iData->dim.nx, tmpk, iData);
        iData->cv = x;
        /*iData->data->callback->functionAlgebraics(iData->data);*/
        diff_symColoredObject(iData, iData->df.dLagrange[i], iData->lagrange_index);
        iData->scaling.scald = iData->dtime.dt[i]*mbase->b[0][k];
        for(j=0; j<iData->dim.nv; ++j)
          gradF[id++] = iData->scaling.scald*iData->df.dLagrange[i][j];
      }
    }

    for(; i<iData->dim.nsi; ++i){
      for(k=0; k<iData->dim.deg; ++k, x+=iData->dim.nv){
        tmpk = i*iData->dim.deg+k +1 ;
        refreshSimData(x,x+ iData->dim.nx,tmpk, iData);
        iData->cv = x;
        /*iData->data->callback->functionAlgebraics(iData->data);*/
        diff_symColoredObject(iData, iData->df.dLagrange[i], iData->lagrange_index);
        iData->scaling.scald = iData->dtime.dt[i]*mbase->b[1][k];
        for(j = 0; j<iData->dim.nv; ++j)
          gradF[id++] = iData->scaling.scald*iData->df.dLagrange[i][j];
      }
    }

  } else {
    /*ToDo */
    for(i=0; i<iData->dim.endN; ++i)
      gradF[i] = 0.0;
  }
  if(iData->sopt.mayer){
    x = v + iData->dim.endN;
    refreshSimData(x, x +iData->dim.nx, iData->dim.nt-1, iData);
    iData->cv = x;
    /*iData->data->callback->functionAlgebraics(iData->data);*/
    diff_symColoredObject(iData, iData->df.dMayer, iData->mayer_index);
    for(j=0; j<iData->dim.nv; ++j)
    {
      if(iData->sopt.lagrange){
        gradF[iData->dim.endN + j] += iData->df.dMayer[j];
      } else {
        gradF[iData->dim.endN + j] = iData->df.dMayer[j];
      }
    }
  }else if(!iData->sopt.lagrange){
    /*ToDo */
    for(j=0; j<iData->dim.nv; ++j)
      gradF[iData->dim.endN + j] = 0.0;
  }
  return TRUE;
}


/*
 *  function calculates a symbolic/num colored gradient "matrix"
 *  author: vitalij
 */
int diff_symColoredObject(IPOPT_DATA_ *iData, long double *dF, int this_it)
{
  if(iData->sopt.useNumJac==0)
    sym_diff_symColoredObject(iData,dF,this_it);
  return 0;

}

/*
 *  function calculates a symbolic colored gradient "matrix"
 *  author: vitalij
 */
int sym_diff_symColoredObject(IPOPT_DATA_ *iData, long double *dF, int this_it)
{
    DATA * data = iData->data;
    const int index = 3;
    int i,j,l,ii,nx;
    int *cC,*lindex;

    nx = data->simulationInfo.analyticJacobians[index].sizeCols;

    cC =  (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
    lindex = (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;

    for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i)
    {
      for(ii = 0; ii<nx; ++ii)
      {
        if(cC[ii] == i)
        {
          data->simulationInfo.analyticJacobians[index].seedVars[ii] = iData->scaling.vnom[ii];
        }
      }

      data->callback->functionJacC_column(data);

      for(ii = 0; ii < nx; ++ii)
      {
        if(cC[ii] == i)
        {
          if(ii == 0) j = 0;
          else j = lindex[ii-1];

          for(; j<lindex[ii]; ++j)
          {
            l = data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
            iData->df.gradFomc[l][ii] = data->simulationInfo.analyticJacobians[index].resultVars[l];
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
  memcpy(dF, iData->df.gradFomc[this_it], sizeof(long double)*iData->dim.nv);
  return 0;
}

#endif

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
#define DF_STEP(x,s) ( (fmin(fmax(1e-4*fabs(s*x),1e-8),1e-1)))
static int eval_diff_mayer(IPOPT_DATA_ *iData, double* gradF, double *v);
static int eval_diff_lagrange1(IPOPT_DATA_ *iData, double *x, int *id_, double* gradF);
static int eval_diff_lagrange2(IPOPT_DATA_ *iData, double *x, int *id_, double* gradF);

int sym_diff_symColoredObject(IPOPT_DATA_ *iData, double *dF, int this_it);
int num_diff_symColoredObject(IPOPT_DATA_ *iData, double *dF, int this_it);

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
      erg = 0.0;
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
  refreshSimData(vn, vn + iData->nx, iData->tf, iData);
  iData->data->callback->mayer(iData->data, obj_value);
  
  return TRUE;
}

/*!
 *  eval lagrange term
 *  author: Vitalij Ruge
 **/
Bool goal_func_lagrange(double* vn, double *obj_value, double t, IPOPT_DATA_ *iData)
{  
  refreshSimData(vn, vn + iData->nx, t, iData);
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
  double obj0,tmp;
  long double tmp2;
  double vsave;
  double *x;
  long double h;
  IPOPT_DATA_ *iData = (IPOPT_DATA_*) useData;

  if(iData->lagrange) {
    x = v;
    id = 0;
    
    for(i=0; i<iData->nsi; ++i){
      if(i){
        for(k=0; k<iData->deg; ++k, x+=iData->nv){
          refreshSimData(x,x+ iData->nx,iData->time[i*iData->deg+k+1],iData);
          iData->cv = x;
          /*iData->data->callback->functionAlgebraics(iData->data);*/
          diff_symColoredObject(iData, iData->gradF, iData->lagrange_index);
          for(j = 0; j<iData->nv; ++j){
            gradF[id++] =  iData->dt[i]*iData->br[k]*iData->gradF[j]*iData->vnom[j];
            /* printf("\n gradF(%i) = %g, %s, %g", id-1, gradF[id-1], iData->data->modelData.realVarsData[j].info.name, x[j]*iData->vnom[j]); */
          }
        }
      }else{
        for(k=0; k<iData->deg+1; ++k, x+=iData->nv){
          refreshSimData(x,x+ iData->nx,iData->time[i*iData->deg+k],iData);
          iData->cv = x;
          /*iData->data->callback->functionAlgebraics(iData->data);*/
          diff_symColoredObject(iData, iData->gradF,iData->lagrange_index);
          for(j=0; j<iData->nv; ++j){
            gradF[id++] = iData->dt[i]*iData->bl[k]*iData->gradF[j]*iData->vnom[j];
            /* printf("\n gradF(%i) = %g, %s, %g", id-1, gradF[id-1], iData->data->modelData.realVarsData[j].info.name, x[j]*iData->vnom[j]); */
          }
        }
      }
    }
  } else {
    for(i=0; i<iData->endN; ++i)
      gradF[i] = 0.0;
  }
  if(iData->mayer){
    x = v + iData->endN;

    refreshSimData(x, x +iData->nx, iData->tf, iData);
    iData->cv = x;
    /*iData->data->callback->functionAlgebraics(iData->data);*/
    diff_symColoredObject(iData, iData->gradF, iData->mayer_index);
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
 *  function calculates a symbolic/num colored gradient "matrix"
 *  author: vitalij
 */
int diff_symColoredObject(IPOPT_DATA_ *iData, double *dF, int this_it)
{
  if(iData->useNumJac==0)
    sym_diff_symColoredObject(iData,dF,this_it);
  else
    num_diff_symColoredObject(iData,dF,this_it);
  return 0;

}

/*
 *  function calculates a symbolic colored gradient "matrix"
 *  author: vitalij
 */
int sym_diff_symColoredObject(IPOPT_DATA_ *iData, double *dF, int this_it)
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
          data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1.0;
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
            iData->gradFomc[l][ii] = data->simulationInfo.analyticJacobians[index].resultVars[l];
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
  memcpy(dF, iData->gradFomc[this_it], sizeof(double)*iData->nv);
  return 0;
}

/*
 *  function calculates a num colored gradient "matrix"
 *  author: vitalij
 */
int num_diff_symColoredObject(IPOPT_DATA_ *iData, double *dF, int this_it)
{
  DATA * data = iData->data;
  const int index = 2;
  /*double*x,*u*/;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)iData->data->localData[0];
  int i,j,l,ii,nx,k;
  /*int *cC,*lindex;*/
  double lhs, rhs;
  double *v;
  double t = (double)sData->timeValue;

  v = iData->cv;
  /*x = v;*/
  /*u = x + iData->nx;*/

  nx = data->simulationInfo.analyticJacobians[index].sizeCols;
  /*cC =  (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
  lindex = (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;*/
  memcpy(iData->vsave, v, sizeof(double)*iData->nv);

  for(ii = 0; ii<nx; ++ii){
    iData->eps[ii] = DF_STEP(v[ii], iData->vnom[ii]);
  }

  for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i){
    for(ii = 0; ii<nx; ++ii){

    v[ii] = iData->vsave[ii] + iData->eps[ii];

      if((int)iData->mayer_index == (int)this_it)
        goal_func_mayer(v, &lhs, iData);
      else
        goal_func_lagrange(v, &lhs, t, iData);


    v[ii] = iData->vsave[ii] - iData->eps[ii];
        //printf("\nrv[%i] = %g\t eps[%i] = %g",ii,v[ii], ii,iData->eps[ii]);

      if( (int)iData->mayer_index == (int) this_it)
        goal_func_mayer(v, &rhs, iData);
      else
        goal_func_lagrange(v, &rhs, t, iData);

    v[ii] = iData->vsave[ii];
    dF[ii] = (lhs - rhs)/(2.0*iData->eps[ii]);
    dF[ii] /= iData->vnom[ii];
    }
  }
  return 0;
}

#undef DF_STEP
#endif

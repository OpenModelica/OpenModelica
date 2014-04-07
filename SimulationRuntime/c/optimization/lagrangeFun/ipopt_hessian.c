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
#include "../localFunction.h"

#ifdef WITH_IPOPT
#define DF_STEP(x) ((fmin(fmax(1e-4*fabs(x),1e-8),1e2)))

static int num_hessian(double *v, int k, IPOPT_DATA_ *iData, double *lambda, modelica_boolean lagrange_yes, modelica_boolean mayer_yes, double obj_factor);
static int updateCost(double *v, int k, IPOPT_DATA_ *iData, modelica_boolean lagrange_yes, modelica_boolean mayer_yes,long double *F1, long double *F2);
static int sumLagrange(IPOPT_DATA_ *iData, double * erg,int ii, int i, int j, int p, modelica_boolean mayer_yes);
static int diff_functionODE_con(double *v, int k, IPOPT_DATA_ *iData, long double **J);

/*!
 *  calc hessian
 *  autor: Vitalij Ruge
 **/
Bool ipopt_h(int n, double *v, Bool new_x, double obj_factor, int m, double *lambda, Bool new_lambda,
                    int nele_hess, int *iRow, int *iCol, double *values, void* useData)
{

  int i,j,k;
  IPOPT_DATA_ *iData;
  OPTIMIZER_DIM_VARS* dim;
  iData = (IPOPT_DATA_ *) useData;
  dim = &iData->dim;
  iData->sopt.updateH = new_x;

  k = 0;
  if(values == NULL)
  {
    int c,r,l,p;
    r = 0;
    c = 0;
    for(i = 0; i<dim->nsi; ++i){

      if(i == 0){
        /*0*/
        for(p = 0;p < dim->deg+1;++p){
          for(j=0;j< dim->nv;++j){
            for(l = 0; l< j+1; ++l){
              if(iData->sopt.Hg[j][l]){
                iRow[k] = r + j;
                iCol[k++] = c + l;
              }
             }
          }
          r += dim->nv;
          c += dim->nv;
        }
      }else{
        for(p = 1;p < dim->deg+1;++p){
          for(j=0;j< dim->nv;++j){
            for(l = 0; l< j+1; ++l){
              if(iData->sopt.Hg[j][l]){
                iRow[k] = r + j;
                iCol[k++] = c + l;
              }
            }
          }
          r += dim->nv;
          c += dim->nv;
        }
      }
    }
#if 0
    {
    FILE *pFile;
    char buffer[4096];
    pFile = fopen("hesse_struct.m", "wt");
    if(pFile == NULL)
      printf("\n\nError");
    fprintf(pFile, "%s", "clear H\n");
    fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
    fprintf(pFile, "%s", "nz = ");
    fprintf(pFile, "%i", nele_hess);
    fprintf(pFile, "%s", "\nnumberVars = ");
    fprintf(pFile, "%i", n);
    fprintf(pFile, "%s", "\nnumberconstraints = ");
    fprintf(pFile, "%i", m);
    fprintf(pFile, "%s", "\nNumberOfIntervalls = ");
    fprintf(pFile, "%i", dim->nsi);
    fprintf(pFile, "%s", "\nH=[];\n");
    fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
    for(i=0; i< nele_hess; ++i){
      sprintf(buffer, "H(%i,%i) = 1;\n", iRow[i]+1, iCol[i]+1);
      fprintf(pFile,"%s", buffer);
    }
    fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
    fprintf(pFile, "%s", "spy(H)\n");
    }
#endif

  }else{
    double *x;
    double *ll;
    int ii;
    int p,id,l;
    double sum;
    modelica_boolean mayer_yes;
    int nJ;
    int tmp_index;
    OPTIMIZER_MBASE *mbase = &iData->mbase;
    iData->helper.i = -1;
    nJ = (int) dim->nJ;
    for(ii = 0; ii <1; ++ii){

      for(p = 0, x= v, ll = lambda;p < dim->deg+1;++p, x += dim->nv){
         mayer_yes = iData->sopt.mayer && ii+1 == dim->nsi && p == dim->deg;
         ++iData->helper.i;
         if(p){
           num_hessian(x, p, iData, ll,iData->sopt.lagrange,mayer_yes,obj_factor);
           ll += nJ;
         }else{
           for(i = 0; i< dim->nx; ++i){
             if(ll[i] != ll[i + nJ]){
               if(mbase->invd1_4*ll[i+2*nJ] != ll[i + nJ])
                 iData->sh[i] = mbase->d[0][4]*(ll[i] + (mbase->invd1_4*ll[i+2*nJ] - ll[i + nJ]));
               else
                 iData->sh[i] = mbase->d[0][4]*ll[i];
             }else{
               iData->sh[i] = ll[i+2*nJ];
             }
           }
           //for(; i< nJ; ++i)
            // iData->sh[i] = 0;
           num_hessian(x, p, iData, iData->sh, iData->sopt.lagrange, mayer_yes, obj_factor);
         }

        for(i=0;i< dim->nv;++i)
          for(j = 0; j< i+1; ++j){
            if(iData->sopt.Hg[i][j]){
              sumLagrange(iData, &sum, ii, i, j,  p, mayer_yes);
              values[k++] =  sum;
            }
          }
      }

    }

    for(; ii <dim->nsi; ++ii){
      tmp_index = ii*dim->deg;
      for(p = 1;p < dim->deg +1;++p,x += dim->nv){
        mayer_yes = iData->sopt.mayer && ii+1 == dim->nsi && p == dim->deg;
        ++iData->helper.i;
        num_hessian(x, tmp_index + p, iData,ll, iData->sopt.lagrange, mayer_yes,obj_factor);

        for(i=0;i< dim->nv;++i)
          for(j = 0; j< i+1; ++j){
            if(iData->sopt.Hg[i][j]){
                sumLagrange(iData, &sum, ii, i, j, p, mayer_yes);
                values[k++] = sum;
            }
          }
        ll += nJ;

      }

    }
  }
   /*printf("\n k = %i \t %i",k, (int)nele_hess);
   assert(k == nele_hess);*/
  return TRUE;
}

/*!
 *  lamda^\top \cdot H + sigma*((?)dd_lagrange + (?)dd_mayer)
 *  autor: Vitalij Ruge
 **/
static int sumLagrange(IPOPT_DATA_ *iData, double * erg,int ii, int i, int j, int p, modelica_boolean mayer_yes)
{
  long double sum;
  int l;

  OPTIMIZER_DIM_VARS *dim = &iData->dim;
  OPTIMIZER_MBASE *mbase = &iData->mbase;

  int nJ = (p) ? dim->nJ : dim->nx;

  sum = 0.0;

  for(l = 0; l<dim->nx; ++l)
    if(iData->sopt.knowedJ[l][j] + iData->sopt.knowedJ[l][i] >= 2)
      sum += iData->df.H[l][i][j];

  if(iData->sopt.lagrange &&
      iData->sopt.gradFs[iData->lagrange_index][i]*iData->sopt.gradFs[iData->lagrange_index][j])
  {
    if(ii)
      sum += mbase->b[1][p-1]*iData->df.oH[i][j];
    else
      sum += mbase->b[0][p]*iData->df.oH[i][j];
  }

  sum = iData->dtime.dt[ii]*sum;

  for(l = dim->nx; l<nJ; ++l)
    if(iData->sopt.knowedJ[l][j] + iData->sopt.knowedJ[l][i] >= 2)
      sum += iData->df.H[l][i][j];

  if(mayer_yes && iData->sopt.gradFs[iData->mayer_index][i]*iData->sopt.gradFs[iData->mayer_index][j])
    sum += iData->df.mH[i][j];

  *erg = (double) sum;
  return 0;
}

/*!
 *  cal numerical hessian
 *  autor: Vitalij Ruge
 **/
static int num_hessian(double *v, int k, IPOPT_DATA_ *iData, double *lambda, modelica_boolean lagrange_yes, modelica_boolean mayer_yes, double obj_factor)
{
  long double v_save;
  long double h;
  int i, j, l;
  short upCost;
  OPTIMIZER_DIM_VARS *dim = &iData->dim;
  int nJ = (k>0) ? dim->nJ : dim->nx;
  long double **Jrhs;
  long double *lagrangeFrhs, *maeyrFrhs;

  if(!iData->sopt.updateH){
    diff_functionODE_con(v, k , iData, iData->df.Jh[0]);
    Jrhs = iData->df.Jh[0];
  }else{
    Jrhs = iData->df.J[iData->helper.i];
  }

  upCost = (lagrange_yes || mayer_yes) && (obj_factor!=0);   

  if(upCost){
    if(!iData->sopt.updateH){
      updateCost(v,k,iData,lagrange_yes,mayer_yes, iData->df.gradFh[2], iData->df.gradFh[3]);
      lagrangeFrhs = iData->df.gradFh[2];
      maeyrFrhs = iData->df.gradFh[3];
    }else{
      lagrangeFrhs = iData->df.dLagrange[i];
      maeyrFrhs = iData->df.dMayer;
    }
  }

  for(i = 0; i<dim->nv; ++i){
    v_save = (long double)v[i];
    h = (long double)DF_STEP(v_save);
    v[i] += h;
    if(v[i] > iData->bounds.vmax[i]){
      h = iData->bounds.vmax[i] - v_save;
      v[i] = v_save +  h;
    }
    diff_functionODE_con(v, k , iData, iData->df.Jh[1]);

    if(upCost)
      updateCost(v,k,iData,lagrange_yes,mayer_yes, iData->df.gradFh[0], iData->df.gradFh[1]);

    v[i] = v_save;

    for(j = i; j < dim->nv; ++j){
      if(iData->sopt.Hg[i][j]){
       for(l = 0; l< nJ; ++l){
        if(iData->sopt.knowedJ[l][j] + iData->sopt.knowedJ[l][i] >= 2 && lambda[l] != 0.0)
          iData->df.H[l][i][j]  = (long double)(iData->df.Jh[1][l][j] - Jrhs[l][j])*lambda[l]/h;
        else
          iData->df.H[l][i][j] = (long double) 0.0;
        iData->df.H[l][j][i] = iData->df.H[l][i][j];
       }
      }
    }
    h = obj_factor/h; 
    if(lagrange_yes){
      for(j = i; j < dim->nv; ++j){
       if(iData->sopt.gradFs[iData->lagrange_index][i]*iData->sopt.gradFs[iData->lagrange_index][j] && obj_factor!=0)
         iData->df.oH[i][j]  = (long double) (iData->df.gradFh[0][j] - lagrangeFrhs[j])*h*iData->scaling.vnom[j];
       else
         iData->df.oH[i][j] = 0.0;
       iData->df.oH[j][i]  = iData->df.oH[i][j] ;
      }
    }

    if(mayer_yes){
      for(j = i; j < dim->nv; ++j){
       if(iData->sopt.gradFs[iData->mayer_index][i]*iData->sopt.gradFs[iData->mayer_index][j] && obj_factor!=0)
         iData->df.mH[i][j]  = (long double) (iData->df.gradFh[1][j] - maeyrFrhs[j])*h* iData->scaling.vnom[j];
       else
         iData->df.mH[i][j] = 0.0;
       iData->df.mH[j][i]  = iData->df.mH[i][j] ;
      }
    }

  }
  return 0;
}



/*
 *  function update goal function 
 *  author: vitalij
 */
static int updateCost(double *v, int k, IPOPT_DATA_ *iData, modelica_boolean lagrange_yes, modelica_boolean mayer_yes, long double *F1, long double *F2)
{
  /*iData->data->callback->functionAlgebraics(iData->data);*/
  if(lagrange_yes)
    diff_symColoredObject(iData, F1, iData->lagrange_index);

  if(mayer_yes)
    diff_symColoredObject(iData, F2, iData->mayer_index);
  
  return 0;
}

/*!
 *  eval a part from the derivate of s.t.
 *  author: Vitalij Ruge
 **/
static int diff_functionODE_con(double* v, int k, IPOPT_DATA_ *iData, long double **J)
{
  int i, j;
  double *x, *u;
  x = v;
  u = v + iData->dim.nx;

  {
    DATA* data = iData->data;
    SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
    OPTIMIZER_EVALF *evalf = &iData->evalf;
    long double t = iData->dtime.time[k];

    memcpy(data->localData[0]->realVars, evalf->v[k], sizeof(double)*iData->dim.nReal);
    memcpy(data->localData[1]->realVars, evalf->v[k], sizeof(double)*iData->dim.nReal);
    memcpy(data->localData[2]->realVars, evalf->v[k], sizeof(double)*iData->dim.nReal);

    for(j = 0; j<iData->dim.nx;++j){
      sData->realVars[j] = x[j]*iData->scaling.vnom[j];
    }

    for(i = 0; i<iData->dim.nu;++i,++j){
      data->simulationInfo.inputVars[i] = u[i]*iData->scaling.vnom[j];
    }

    data->callback->input_function(data);
    sData->timeValue = (double) t;

    data->callback->functionODE(data);
    data->callback->functionAlgebraics(data);
  }
  diff_symColoredODE(v,k,iData,J);

  return 0;
}

#undef DF_STEP
#endif

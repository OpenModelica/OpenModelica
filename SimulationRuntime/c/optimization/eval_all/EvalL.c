/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*! EvalL.c
 */

#include "../OptimizerData.h"
#include "../OptimizerLocalFunction.h"

static inline void num_hessian0(double * v, const double * const lambda, const double objFactor , OptData *optData, const int i, const int j);
static inline void sumLagrange0(const int i, const int j, double * res,  const modelica_boolean upC, OptData *optData);
static inline void num_hessian1(double * v, const double * const lambda, const double objFactor, OptData *optData, const int i, const int j);
static inline void sumLagrange1(const int i, const int j, double * res,  const modelica_boolean upC, const modelica_boolean upC2, OptData *optData);
static inline void updateDerF(OptData *optData);

/* eval hessian
 * author: Vitalij Ruge
 */
Bool ipopt_h(int n, double *vopt, Bool new_x, double obj_factor, int m, double *lambda, Bool new_lambda,
                    int nele_hess, int *iRow, int *iCol, double *values, void* useData){

  OptData *optData = (OptData*)useData;
  const int np = optData->dim.np;
  const int np1 = np + 1;
  const int nv = optData->dim.nv;
  const int nsi = optData->dim.nsi;

  if(values == NULL){
    int i, j, k, p, l, r, c;

    for(i = 0, r = 0, c = 0, k = 0; i + 1 < nsi; ++i){
      for(p = 1; p < np1; ++p, r += nv, c += nv){

        /*******************/
        for(j = 0; j< nv; ++j){
          for(l = 0; l< j+1; ++l){
            if(optData->s.H0[j][l]){
              iRow[k] = r + j;
              iCol[k++] = c + l;
            }
          }
        }
        /*******************/
      }
    }

    for(p = 1; p < np1; ++p, r += nv, c += nv){
      /*******************/
      for(j = 0; j< nv; ++j){
        for(l = 0; l< j+1; ++l){
          if(optData->s.H1[j][l] && np == p){
            iRow[k] = r + j;
            iCol[k++] = c + l;
          }else if(optData->s.H0[j][l]){
            iRow[k] = r + j;
            iCol[k++] = c + l;
          }
        }
      }
      /*******************/
    }

#if 0
    {
    printf("\nnele_hess = %i, %i",nele_hess,k);
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
    fprintf(pFile, "%i", optData->dim.NV);
    fprintf(pFile, "%s", "\nnumberconstraints = ");
    fprintf(pFile, "%i", m);
    fprintf(pFile, "%s", "\nNumberOfIntervalls = ");
    fprintf(pFile, "%i", nsi);
    fprintf(pFile, "\nH=sparse(%i,%i);", optData->dim.NV,optData->dim.NV);
    fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
    for(i=0; i< k; ++i){
      sprintf(buffer, "H(%i,%i) = 1;\n", iRow[i]+1, iCol[i]+1);
      fprintf(pFile,"%s", buffer);
    }
    fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
    fprintf(pFile, "%s", "spy(H)\n");
    }
    assert(0);
#endif


  }else{
    int ii, p, i, j, k;
    double * v;
    double * la;
    const int nJ = optData->dim.nJ;
    modelica_boolean upC;
    modelica_boolean upC2;
    upC = obj_factor != 0;
    if(new_x){
      optData2ModelData(optData, vopt, 4);
      if(upC)
        updateDerF(optData);
    }

    upC2 = upC && optData->s.mayer;
    upC = upC && optData->s.lagrange;

    for(ii = 0, k = 0, v = vopt, la = lambda; ii + 1 < nsi; ++ii){
      for(p = 1; p < np1; ++p, v += nv, la += nJ){
        num_hessian0(v, la, obj_factor, optData, ii, p-1);
        /*******************/
        for(i = 0; i < nv; ++i){
          for(j = 0; j < i + 1; ++j){
            if(optData->s.H0[i][j]){
              sumLagrange0(i, j, values + (k++),upC,optData);
            }
          }
        }
        /*******************/
      }
    }
    /*******************/
    for(p = 1; p < np1; ++p, v += nv, la += nJ){
      num_hessian1(v, la, obj_factor, optData, ii, p-1);
      /*******************/
      for(i = 0; i < nv; ++i){
        for(j = 0; j < i + 1; ++j){
          if(optData->s.H1[i][j] && np == p){
            sumLagrange1(i, j, values + (k++),upC, upC2,optData);
          }else if(optData->s.H0[i][j]){
            sumLagrange0(i, j, values + (k++),upC,optData);
          }
        }
      }
      /*******************/

      /*for(i=0; i< nele_hess; ++i){
        printf("values[%i] = %g\n",i,values[i]);
      }*/
    }

  }


  return TRUE;
}

/* numerical approximation
 *  hessian
 * author: Vitalij Ruge
 */
static inline void num_hessian0(double * v, const double * const lambda,
    const double objFactor , OptData *optData, const int i, const int j){

  const modelica_boolean la = optData->s.lagrange;
  const int index_la = optData->s.derIndex[0];
  const modelica_boolean upCost = la && objFactor != 0;
  const long double * const scalb = optData->bounds.scalb[i][j];
  DATA * data = optData->data;

  const int nv = optData->dim.nv;
  const int nx = optData->dim.nx;
  const int nJ = optData->dim.nJ;
  const modelica_real * const vmax = optData->bounds.vmax;
  const modelica_real * const vnom = optData->bounds.vnom;

  int ii,jj, l;
  long double v_save, h;

  modelica_real * realV[3];

  for(l = 1; l<3; ++l){
    realV[l] = data->localData[l]->realVars;
    data->localData[l]->realVars = optData->v[i][j];
  }

  for(ii = 0; ii < nv; ++ii){
    /********************/
    v_save = (long double) v[ii];
    h = (long double)(1e-4 *fmin(fabs(v_save),1e6) + 1e-8);
    h = (1.0 + h) - 1.0;
    if(v[ii] + h <= vmax[ii]){
      v[ii] += h;
    }else{
      h = vmax[ii] - v[ii];
      h = (1.0 + h) - 1.0;
      v[ii] += h;
    }
    /********************/
    for(l = 0; l < nx; ++l)
      data->localData[0]->realVars[l] = v[l]*vnom[l];
    for(; l <nv; ++l)
      data->simulationInfo.inputVars[l-nx] = (modelica_real) v[l]*vnom[l];
    data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];
    data->callback->input_function(data);
    data->callback->functionDAE(data);
    /********************/
    v[ii] = (double)v_save;
    /********************/
    if(upCost)
      diff_symColoredLagrange(optData, &optData->tmpJ[index_la], 2, scalb);
    diff_symColoredODE(optData, optData->tmpJ, 4, optData->bounds.scaldt[i]);
    /********************/
    for(jj = 0; jj <ii+1; ++jj){
      if(optData->s.H0[ii][jj]){
        for(l = 0; l < nJ; ++l){
          if(optData->s.Hg[l][ii][jj] && lambda[l] != 0){
            optData->H[l][ii][jj] = (long double)(optData->tmpJ[l][jj] - optData->J[i][j][l][jj])*lambda[l]/h;
          }else{
            optData->H[l][ii][jj] = (long double)0.0;
          }
          optData->H[l][jj][ii] = optData->H[l][ii][jj];
        }
      }
    }
    /********************/
    if(upCost){
      const int index_la = optData->s.derIndex[0];
      h = objFactor/h;
      for(jj = 0; jj <ii+1; ++jj){
        if(optData->s.Hl[ii][jj]){
          optData->Hl[ii][jj] = (long double)(optData->tmpJ[index_la][jj] - optData->J[i][j][index_la][jj])*h;
        }else{
          optData->Hl[ii][jj] = 0.0;
          optData->Hl[jj][ii] = optData->Hl[ii][jj];
        }
      }
    }
    /********************/
  }

  for(l = 1; l<3; ++l){
    data->localData[l]->realVars = realV[l];
  }

}



/* numerical approximation
 *  hessian
 * author: Vitalij Ruge
 */
static inline void num_hessian1(double * v, const double * const lambda,
    const double objFactor, OptData *optData, const int i, const int j){

  const modelica_boolean la = optData->s.lagrange;
  const modelica_boolean ma = optData->s.mayer;
  const modelica_boolean upCost = la && objFactor != 0;
  const long double * const scalb = optData->bounds.scalb[i][j];
  const int index_la = optData->s.derIndex[0];

  const int nv = optData->dim.nv;
  const int nx = optData->dim.nx;
  const int np = optData->dim.np;
  const int nJ = optData->dim.nJ;
  const modelica_real * const vmax = optData->bounds.vmax;
  const modelica_real * const vnom = optData->bounds.vnom;
  const modelica_boolean upCost2 = objFactor != 0 && ma && np == j + 1;

  int ii,jj, l;
  long double v_save, h;
  DATA * data = optData->data;

  modelica_real * realV[3];

  for(l = 1; l<3; ++l){
    realV[l] = data->localData[l]->realVars;
    data->localData[l]->realVars = optData->v[i][j];
  }

  for(ii = 0; ii < nv; ++ii){
    /********************/
    v_save = (long double) v[ii];
    h = (long double)(1e-4 *fmax(fabs(v_save),1e2) + 1e-8);
    h = (1.0 + h) - 1.0;
    if(v[ii] + h <= vmax[ii]){
      v[ii] += h;
    }else{
      h = vmax[ii] - v[ii];
      h = (1.0 + h) - 1.0;
      v[ii] += h;
    }
    /********************/
    for(l = 0; l < nx; ++l)
      data->localData[0]->realVars[l] = v[l]*vnom[l];
    for(; l <nv; ++l)
      data->simulationInfo.inputVars[l-nx] = (modelica_real) v[l]*vnom[l];
    data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];
    data->callback->input_function(data);
    data->callback->functionDAE(data);
    /********************/
    v[ii] = (double)v_save;
    /********************/
    if(upCost)
      diff_symColoredLagrange(optData, &optData->tmpJ[index_la], 2, scalb);
    diff_symColoredODE(optData, optData->tmpJ, 4, optData->bounds.scaldt[i]);
    /********************/
    for(jj = 0; jj <ii+1; ++jj){
      if(optData->s.H0[ii][jj]){
        for(l = 0; l < nJ; ++l){
          if(optData->s.Hg[l][ii][jj])
            optData->H[l][ii][jj] = (long double)(optData->tmpJ[l][jj] - optData->J[i][j][l][jj])*lambda[l]/h;
          else
            optData->H[l][ii][jj] = 0.0;
          optData->H[l][jj][ii] = optData->H[l][ii][jj];
        }
      }
    }
    /********************/
    if(upCost){
      const int index_la = optData->s.derIndex[0];
      long double hh;
      hh = objFactor/h;
      for(jj = 0; jj <ii+1; ++jj){
        if(optData->s.Hl[ii][jj]){
          optData->Hl[ii][jj] = (long double)(optData->tmpJ[index_la][jj] - optData->J[i][j][index_la][jj])*hh;
        }else{
          optData->Hl[ii][jj] = 0.0;
        }
        optData->Hl[jj][ii] = optData->Hl[ii][jj];
      }
    }
    /********************/
    if(upCost2){
      const int index_ma = optData->s.derIndex[1];
      long double hh;
      diff_symColoredMayer(optData, &optData->tmpJ[index_ma], 3);
      hh = objFactor/h;
      for(jj = 0; jj <ii+1; ++jj){
        if(optData->s.Hm[ii][jj]){
          optData->Hm[ii][jj] = (long double)(optData->tmpJ[index_ma][jj] - optData->J[i][j][index_ma][jj])*hh;
        }else{
          optData->Hm[ii][jj] = 0.0;
          optData->Hm[jj][ii] = optData->Hm[ii][jj];
        }
      }
    }
    /********************/
  }

  for(l = 1; l<3; ++l){
    data->localData[l]->realVars = realV[l];
  }

}


/* eval hessian for lagrange
 * author: Vitalij Ruge
 */
static inline void sumLagrange0(const int i, const int j, double * res,
    const modelica_boolean upC, OptData *optData){
  const int nJ = optData->dim.nJ;

  long double sum = 0.0;
  int l;

  for(l = 0; l< nJ; ++l){
    if(optData->s.Hg[l][i][j])
      sum += optData->H[l][i][j];
  }

  if(upC && optData->s.Hl[i][j])
    sum += optData->Hl[i][j];

  *res = (double) sum;

}

/* eval hessian for lagrange
 * author: Vitalij Ruge
 */
static inline void sumLagrange1(const int i, const int j, double * res,
    const modelica_boolean upC, const modelica_boolean upC2, OptData *optData){
  const int nJ = optData->dim.nJ;

  long double sum = 0.0;

  if(optData->s.H0[i][j]){
    int l;
    for(l = 0; l< nJ; ++l){
      if(optData->s.Hg[l][i][j])
        sum += optData->H[l][i][j];
    }

    if(upC && optData->s.Hl[i][j])
      sum += optData->Hl[i][j];
  }

  if(upC2 && optData->s.Hm[i][j])
    sum += optData->Hm[i][j];

  *res = (double) sum;

}

/*!
 *  update jacobian matrix C,B
 *  author: Vitalij Ruge
 **/
static inline void updateDerF(OptData *optData){
  const int nReal = optData->dim.nReal;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const modelica_boolean la = optData->s.lagrange;
  const modelica_boolean ma = optData->s.mayer;
  DATA * data = optData->data;

  if(la){
    const int index_la = optData->s.derIndex[0];
    long double *** scalb = optData->bounds.scalb;
    int i, j;
    for(i = 0; i < nsi; ++i){
      for(j = 0; j < np; ++j){
        memcpy(data->localData[0]->realVars, optData->v[i][j], nReal*sizeof(double));
        data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];
        diff_symColoredLagrange(optData, &optData->J[i][j][index_la], 2, scalb[i][j]);
      }
    }
  }

  if(ma){
    const int index_ma = optData->s.derIndex[1];
    const int i = nsi - 1;
    const int j = np - 1;
    memcpy(data->localData[0]->realVars, optData->v[i][j], nReal*sizeof(double));
    data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];
    diff_symColoredMayer(optData, &optData->J[i][j][index_ma], 3);
  }

}

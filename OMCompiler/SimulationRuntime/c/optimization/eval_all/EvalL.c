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
#include "../../simulation/solver/model_help.h"

static inline void calculate_hessian_matrix_numerical(double * v, const double * const lambda, const double objFactor , OptData *optData, const int i, const int j);
static inline void calculate_weighted_sum_with_lagrange_multiplicator_from_tensor(const int i, const int j, double * res,  const modelica_boolean upC, OptData *optData);
static inline void calculate_hessian_matrix_numerical_last_time_intervall(double * v, const double * const lambda, const double objFactor, OptData *optData, const int i, const int j);
static inline void calculate_weighted_sum_with_lagrange_multiplicator_from_tensor_last_time_intervall(const int i, const int j, double * res,  const modelica_boolean upC, const modelica_boolean upC2, OptData *optData);


static inline long double guess_step_size_for_numerical_differentiation(const long double v)
{
  return 1e-5*fabsl(v) + 1e-8;
}


static void init_hessian_structure(int *iRow, int *iCol, OptData *optData){
    int i, j, k, p, l, r, c;
    const int nsi = optData->dim.nsi;
    const int np = optData->dim.np;
    const int np1 = np + 1;
    const int nv = optData->dim.nv;

    for(i = 0, r = 0, c = 0, k = 0; i + 1 < nsi; ++i){
      for(p = 1; p < np1; ++p, r += nv, c += nv){
        for(j = 0; j < nv; ++j){
          for(l = 0; l < j+1; ++l){
            if(optData->s.H0[j][l]){
              iRow[k] = r + j;
              iCol[k++] = c + l;
            }
          }
        }
      }
    }

    /* init_hessian_structure_last_time_intervall */
    for(p = 1; p < np1; ++p, r += nv, c += nv){
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
    }
}

static void fill_hessian_values(double *vopt, double *lambda, double obj_factor, OptData *optData, double *values){
    const int nJ = optData->dim.nJ;
    const modelica_boolean do_update_cost_function = obj_factor != 0;
    const modelica_boolean do_update_mayer_cost_function = do_update_cost_function && optData->s.mayer;
    const modelica_boolean do_update_lagrange_cost_function = do_update_cost_function && optData->s.lagrange;
    const int np = optData->dim.np;
    const int np1 = np + 1;
    const int nv = optData->dim.nv;
    const int nsi = optData->dim.nsi;

    int ii, p, i, j, k;
    double * v;
    double * la;

    DATA * data = optData->data;

    ++optData->dim.iter;
    optData->dim.iter_updateHessian = 0;
    copy_initial_values(optData, data);

    for(ii = 0, k = 0, v = vopt, la = lambda; ii + 1 < nsi; ++ii){
      for(p = 1; p < np1; ++p, v += nv, la += nJ){
        calculate_hessian_matrix_numerical(v, la, obj_factor, optData, ii, p-1);
        /*******************/
        for(i = 0; i < nv; ++i){
          for(j = 0; j < i + 1; ++j){
            if(optData->s.H0[i][j]){
              calculate_weighted_sum_with_lagrange_multiplicator_from_tensor(i, j, values + (k++), do_update_lagrange_cost_function, optData);
            }
          }
        }
        /*******************/
      }
    }

    /* fill_hessian_values last time intervall */
    for(p = 1; p < np1; ++p, v += nv, la += nJ){
      calculate_hessian_matrix_numerical_last_time_intervall(v, la, obj_factor, optData, ii, p-1);
      for(i = 0; i < nv; ++i){
        for(j = 0; j < i + 1; ++j){
          if(optData->s.H1[i][j] && np == p){
            calculate_weighted_sum_with_lagrange_multiplicator_from_tensor_last_time_intervall(i, j, values + (k++), do_update_lagrange_cost_function, do_update_mayer_cost_function, optData);
          }else if(optData->s.H0[i][j]){
            calculate_weighted_sum_with_lagrange_multiplicator_from_tensor(i, j, values + (k++),do_update_lagrange_cost_function, optData);
          }
        }
      }
    }

}

/* eval hessian
 */
Bool ipopt_h(int n, double *vopt, Bool new_x, double obj_factor, int m, double *lambda, Bool new_lambda,
                    int nele_hess, int *iRow, int *iCol, double *values, void* useData){

  OptData *optData = (OptData*)useData;
  modelica_boolean keepH = optData->dim.updateHessian > optData->dim.iter_updateHessian++;

  if(values == NULL){
      init_hessian_structure(iRow, iCol, optData);
  }else if(keepH){
    memcpy(values,optData->oldH,nele_hess*sizeof(double));
  }else{
    if(optData->ipop.csvOstep)
      debugeSteps(optData, vopt, lambda);
    fill_hessian_values(vopt,lambda, obj_factor, optData, values);
    if(optData->dim.updateHessian > 0)
      memcpy(optData->oldH, values, nele_hess*sizeof(double));
  }


  return TRUE;
}

/* numerical approximation
 *  hessian
 */
static inline void calculate_hessian_matrix_numerical(double * v, const double * const lambda,
    const double objFactor , OptData *optData, const int i, const int j){

  const modelica_boolean la = optData->s.lagrange;
  const modelica_boolean upCost = la && objFactor != 0;
  DATA * data = optData->data;
  threadData_t *threadData = optData->threadData;

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
    data->localData[l]->timeValue = (modelica_real) optData->time.t[i][j];
  }
  data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];

  for(ii = 0; ii < nv; ++ii){
    /********************/
    v_save = (long double) v[ii];
    h = (long double)guess_step_size_for_numerical_differentiation(v_save);
    v[ii] += h;
    if( v[ii] >=  vmax[ii]){
      h *= -1.0;
      v[ii] = v_save + h;
    }
    /********************/
    for(l = 0; l < nx; ++l)
      data->localData[0]->realVars[l] = v[l]*vnom[l];
    for(; l <nv; ++l)
      data->simulationInfo->inputVars[l-nx] = (modelica_real) v[l]*vnom[l];
    data->callback->input_function(data, threadData);
    /*data->callback->functionDAE(data);*/
    updateDiscreteSystem(data, threadData);
    /********************/
    diffSynColoredOptimizerSystem(optData, optData->tmpJ, i,j,2);
    /********************/
    v[ii] = (double)v_save;
    /********************/
    for(jj = 0; jj <ii+1; ++jj){
      if(optData->s.H0[ii][jj]){
        for(l = 0; l < nJ; ++l){
          if(optData->s.Hg[l][ii][jj] && lambda[l] != 0)
              optData->H[l][ii][jj] = (long double)(optData->tmpJ[l][jj] - optData->J[i][j][l][jj])*lambda[l]/h;
        }
      }
    }
    /********************/
    if(upCost){
      h = objFactor/h;
      for(jj = 0; jj <ii+1; ++jj){
        if(optData->s.Hl[ii][jj]){
          optData->Hl[ii][jj] = (long double)(optData->tmpJ[nJ][jj] - optData->J[i][j][nJ][jj])*h;
        }else{
          optData->Hl[ii][jj] = 0.0;
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
 */
static inline void calculate_hessian_matrix_numerical_last_time_intervall(double * v, const double * const lambda,
    const double objFactor, OptData *optData, const int i, const int j){

  const modelica_boolean la = optData->s.lagrange;
  const modelica_boolean ma = optData->s.mayer;
  const modelica_boolean upCost = la && objFactor != 0;

  const int nv = optData->dim.nv;
  const int nx = optData->dim.nx;
  const int np = optData->dim.np;
  const int nJ = optData->dim.nJ;
  const int nJ1 = optData->dim.nJ + 1;
  const int nsi = optData->dim.nsi;
  const int ncf = optData->dim.ncf;
  const modelica_real * const vmax = optData->bounds.vmax;
  const modelica_real * const vnom = optData->bounds.vnom;
  const modelica_boolean upFinalCon = np == j + 1 && nsi == i  +1;
  const modelica_boolean upCost2 = upFinalCon && ma && objFactor != 0;
  const short indexJ = (upCost2) ? 3 : 2;
  int ii,jj, l,k;
  long double v_save, h;
  DATA * data = optData->data;
  threadData_t *threadData = optData->threadData;

  modelica_real * realV[3];

  data->localData[0]->timeValue = (modelica_real) optData->time.t[i][j];
  for(l = 1; l<3; ++l){
    realV[l] = data->localData[l]->realVars;
    data->localData[l]->realVars = optData->v[i][j];
    data->localData[l]->timeValue = (modelica_real) optData->time.t[i][j];
  }

  for(ii = 0; ii < nv; ++ii){
    /********************/
    v_save = (long double) v[ii];
    h = (long double)guess_step_size_for_numerical_differentiation(v_save);
    v[ii] += h;
    if(v[ii] > vmax[ii]){
      h *= -1.0;
      v[ii] = v_save + h;
    }
    /********************/
    for(l = 0; l < nx; ++l)
      data->localData[0]->realVars[l] = v[l]*vnom[l];
    for(; l <nv; ++l)
      data->simulationInfo->inputVars[l-nx] = (modelica_real) v[l]*vnom[l];

    data->callback->input_function(data, threadData);
    /*data->callback->functionDAE(data);*/
    updateDiscreteSystem(data, threadData);
    /********************/
    diffSynColoredOptimizerSystem(optData, optData->tmpJ, i,j,indexJ);
    /********************/
    v[ii] = (double)v_save;
    /********************/
    for(jj = 0; jj <ii+1; ++jj){
      if(optData->s.H0[ii][jj]){
        for(l = 0; l < nJ; ++l){
          if(optData->s.Hg[l][ii][jj])
            optData->H[l][ii][jj] = (long double)(optData->tmpJ[l][jj] - optData->J[i][j][l][jj])*lambda[l]/h;
        }
      }
    }
    /********************/
    if(upCost){
      long double hh;
      hh = objFactor/h;
      for(jj = 0; jj <ii+1; ++jj){
        if(optData->s.Hl[ii][jj]){
          optData->Hl[ii][jj] = (long double)(optData->tmpJ[nJ][jj] - optData->J[i][j][nJ][jj])*hh;
        }
      }
    }
    /********************/
    if(upCost2){
      long double hh;
      hh = objFactor/h;
      for(jj = 0; jj <ii+1; ++jj){
        if(optData->s.Hm[ii][jj]){
          optData->Hm[ii][jj] = (long double)(optData->tmpJ[nJ1][jj] - optData->J[i][j][nJ1][jj])*hh;
        }
      }
    }
    /********************/
    if(upFinalCon && ncf > 0){
      diffSynColoredOptimizerSystemF(optData, optData->tmpJf);
      for(jj = 0; jj <ii+1; ++jj){
        if(optData->s.H0[ii][jj]){
          for(l = 0; l < ncf; ++l){
            if(optData->s.Hcf[l][ii][jj]){
              optData->Hcf[l][ii][jj] = (long double)(optData->tmpJf[l][jj] - optData->Jf[l][jj])*lambda[nJ+l]/h;
            }
          }
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
 */
static inline void calculate_weighted_sum_with_lagrange_multiplicator_from_tensor(const int i, const int j, double * res,
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
 */
static inline void calculate_weighted_sum_with_lagrange_multiplicator_from_tensor_last_time_intervall(const int i, const int j, double * res,
    const modelica_boolean upC, const modelica_boolean upC2, OptData *optData){
  const int nJ = optData->dim.nJ;
  const int ncf = optData->dim.ncf;

  long double sum = 0.0;
  int l;

  if(optData->s.H0[i][j]){
    for(l = 0; l< nJ; ++l){
      if(optData->s.Hg[l][i][j])
        sum += optData->H[l][i][j];
    }

    if(upC && optData->s.Hl[i][j])
      sum += optData->Hl[i][j];
  }
  for(l = 0; l< ncf; ++l){
    if(optData->s.Hcf[l][i][j])
        sum += optData->Hcf[l][i][j];
    }
  if(upC2 && optData->s.Hm[i][j])
    sum += optData->Hm[i][j];

  *res = (double) sum;

}


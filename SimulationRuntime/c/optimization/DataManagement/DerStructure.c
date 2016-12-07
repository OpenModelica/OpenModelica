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

/*! DerStructure.c
 */

#include "../OptimizerData.h"
#include "../OptimizerLocalFunction.h"
#include "../../simulation/options.h"

static inline void local_jac_struct(DATA * data, OptDataDim * dim, OptDataStructure *s, const modelica_real* const vnom);
static inline void print_local_jac_struct(DATA * data, OptDataDim * dim, OptDataStructure *s);
static inline void local_hessian_struct(DATA * data, OptDataDim * dim, OptDataStructure *s);
static inline void print_local_hessian_struct(DATA * data, OptDataDim * dim, OptDataStructure *s);
static inline void update_local_jac_struct(OptDataDim * dim, OptDataStructure *s);
static inline void copy_JacVars(OptData *optData);

/* pick up jac struct
 * author: Vitalij Ruge
 */
inline void allocate_der_struct(OptDataStructure *s, OptDataDim * dim, DATA* data, OptData *optData){
  threadData_t *threadData = optData->threadData;
  const int nv = dim->nv;
  const int nsi = dim->nsi;
  const int np = dim->np;
  const int nJ = dim->nJ;
  const int nJ2 = dim->nJ2;
  const int ncf = dim->ncf;
  int i, j, k;
  char * cflags;
  cflags = (char*)omc_flagValue[FLAG_UP_HESSIAN];
  if(cflags)
  {
    optData->dim.updateHessian = atoi(cflags);
    if(optData->dim.updateHessian < 0)
    {
      warningStreamPrint(LOG_STDOUT, 0, "not support %i for keep hessian-matrix constant.", optData->dim.updateHessian);
      optData->dim.updateHessian = 0;
    }
  }else{
    optData->dim.updateHessian = 0;
  }

  s->indexABCD[0] = -1;
  s->indexABCD[1] = data->callback->INDEX_JAC_A;
  s->indexABCD[2] = data->callback->INDEX_JAC_B;
  s->indexABCD[3] = data->callback->INDEX_JAC_C;
  s->indexABCD[4] = data->callback->INDEX_JAC_D;
  s->matrix[0] = (modelica_boolean)0;
  s->matrix[1] = (modelica_boolean)(data->callback->initialAnalyticJacobianA((void*) data, threadData) == 0);
  s->matrix[2] = (modelica_boolean)(data->callback->initialAnalyticJacobianB((void*) data, threadData) == 0);
  s->matrix[3] = (modelica_boolean)(data->callback->initialAnalyticJacobianC((void*) data, threadData) == 0);
  s->matrix[4] = (modelica_boolean)(data->callback->initialAnalyticJacobianD((void*) data, threadData) == 0);

  dim->nJderx = 0;
  dim->nJfderx = 0;
  /*************************/
  s->J =  (modelica_boolean***) malloc(3*sizeof(modelica_boolean**));
  s->J[0] =  (modelica_boolean**) malloc((nJ +1)*sizeof(modelica_boolean*));
  for(i = 0; i < (nJ +1); ++i)
    s->J[0][i] = (modelica_boolean*)calloc(nv, sizeof(modelica_boolean));

  s->J[1] =  (modelica_boolean**) malloc(nJ2*sizeof(modelica_boolean*));
  for(i = 0; i < nJ2; ++i)
    s->J[1][i] = (modelica_boolean*)calloc(nv, sizeof(modelica_boolean));

  s->J[2] =  (modelica_boolean**) malloc(ncf*sizeof(modelica_boolean*));
  for(i = 0; i < ncf; ++i)
    s->J[2][i] = (modelica_boolean*)calloc(nv, sizeof(modelica_boolean));

  s->derIndex[0] = s->derIndex[1] = s->derIndex[2] = -1;
  s->mayer = (modelica_boolean) (data->callback->mayer(data, &s->pmayer, &s->derIndex[0]) >= 0);
  s->lagrange = (modelica_boolean) (data->callback->lagrange(data, &s->plagrange, &s->derIndex[1], &s->derIndex[2]) >= 0);

  if(!s->mayer)
    s->pmayer = NULL;
  if(!s->lagrange)
    s->plagrange = NULL;

  local_jac_struct(data, dim, s, optData->bounds.vnom);
  copy_JacVars(optData);

  if(ACTIVE_STREAM(LOG_IPOPT_JAC) || ACTIVE_STREAM(LOG_IPOPT_HESSE))
    print_local_jac_struct(data, dim, s);

  local_hessian_struct(data, dim, s);
  if(ACTIVE_STREAM(LOG_IPOPT_JAC) || ACTIVE_STREAM(LOG_IPOPT_HESSE))
    print_local_hessian_struct(data, dim, s);

  update_local_jac_struct(dim, s);

  optData->J = (modelica_real****) malloc(nsi*sizeof(modelica_real***));
  for(i = 0; i < nsi; ++i){
    optData->J[i] = (modelica_real***) malloc(np*sizeof(modelica_real**));
    for(j = 0; j< np; ++j){
      optData->J[i][j] = (modelica_real**) malloc(nJ2*sizeof(modelica_real*));
      for(k = 0; k < nJ2; ++k){
        optData->J[i][j][k] = (modelica_real*) calloc(nv, sizeof(modelica_real));
      }
    }
  }

  optData->tmpJ = (modelica_real**) malloc(nJ2*sizeof(modelica_real*));
  for(k = 0; k < nJ2; ++k){
    optData->tmpJ[k] = (modelica_real*) calloc(nv, sizeof(modelica_real));
  }

  optData->Jf = (modelica_real**) malloc(ncf*sizeof(modelica_real*));
  for(k = 0; k < ncf; ++k){
    optData->Jf[k] = (modelica_real*) calloc(nv, sizeof(modelica_real));
  }
  optData->tmpJf = (modelica_real**) malloc(ncf*sizeof(modelica_real*));
  for(k = 0; k < ncf; ++k){
    optData->tmpJf[k] = (modelica_real*) calloc(nv, sizeof(modelica_real));
  }

  if(s->mayer){
    const int nReal = dim->nReal;
    dim->index_mayer = -1;
    for(i = 0; i < nReal; ++i){
       if(&data->localData[0]->realVars[i] == s->pmayer){
         dim->index_mayer = i;
         break;
       }
    }
  }

  if(s->lagrange){
    const int nReal = dim->nReal;
    dim->index_lagrange = -1;
    for(i = 0; i < nReal; ++i){
       if(&data->localData[0]->realVars[i] == s->plagrange){
         dim->index_lagrange = i;
         break;
       }
    }
  }

  optData->H = (long double ***) malloc(nJ*sizeof(long double**));
  for(i = 0; i < nJ; ++i){
    optData->H[i] = (long double **) malloc(nv*sizeof(long double*));
    for(j = 0; j < nv; ++j)
      optData->H[i][j] = (long double *) calloc(nv, sizeof(long double));
  }

  optData->Hcf = (long double ***) malloc(ncf*sizeof(long double**));
  for(i = 0; i < ncf; ++i){
    optData->Hcf[i] = (long double **) malloc(nv*sizeof(long double*));
    for(j = 0; j < nv; ++j)
      optData->Hcf[i][j] = (long double *) calloc(nv, sizeof(long double));
  }

  optData->Hm = (long double **)malloc(nv*sizeof(long double*));
  for(j = 0; j < nv; ++j)
    optData->Hm[j] = (long double *)calloc(nv, sizeof(long double));

  optData->Hl = (long double **) malloc(nv*sizeof(long double*));
  for(j = 0; j < nv; ++j)
    optData->Hl[j] = (long double *)calloc(nv, sizeof(long double));

  if(optData->dim.updateHessian > 0){
    const int nH0 = optData->dim.nH0_;
    const int nH1 = optData->dim.nH1_;
    const int nhess = (nsi*np-1)*nH0+nH1;
    optData->oldH = (double *)malloc(nhess*sizeof(double));
  }

  optData->dim.iter_updateHessian = optData->dim.updateHessian-1;
}


/*
 *  pick up the jacobian matrix struct
 *  author: Vitalij Ruge
 */
static inline void local_jac_struct(DATA * data, OptDataDim * dim, OptDataStructure *s, const modelica_real * const vnom){
  int sizeCols;
  int maxColors;
  int i,ii, j, l, index, tmp_index, tmpnJ, h_index;
  unsigned int* lindex, *cC, *pindex;

  s->lindex = (unsigned int**)malloc(5*sizeof(unsigned int*));
  s->seedVec = (modelica_real ***)malloc(5*sizeof(modelica_real**));

  s->JderCon = (modelica_boolean **)malloc(dim->nJ*sizeof(modelica_boolean*));
  for(i = 0; i < dim->nJ; ++i)
    s->JderCon[i] = (modelica_boolean *)calloc(dim->nv, sizeof(modelica_boolean));

  s->gradM = (modelica_boolean *)calloc(dim->nv, sizeof(modelica_boolean));
  s->gradL = (modelica_boolean *)calloc(dim->nv, sizeof(modelica_boolean));
  s->indexCon2 = (int *)malloc(dim->nc* sizeof(int));
  s->indexCon3 = (int *)malloc(dim->nc* sizeof(int));

  for(index = 2; index < 5; ++index){

    if(s->matrix[index]){
      tmp_index = index-2;
      h_index = s->indexABCD[index];
      /******************************/
      sizeCols = data->simulationInfo->analyticJacobians[h_index].sizeCols;
      maxColors = data->simulationInfo->analyticJacobians[h_index].sparsePattern.maxColors + 1;
      cC = (unsigned int*) data->simulationInfo->analyticJacobians[h_index].sparsePattern.colorCols;
      lindex = (unsigned int*) data->simulationInfo->analyticJacobians[h_index].sparsePattern.leadindex;
      pindex = data->simulationInfo->analyticJacobians[h_index].sparsePattern.index;

      s->seedVec[index] = (modelica_real **)malloc((maxColors)*sizeof(modelica_real*));
      /**********************/
      if(sizeCols > 0){
        for(ii = 1; ii < maxColors; ++ii){
          s->seedVec[index][ii] = (modelica_real*)calloc(sizeCols, sizeof(modelica_real));
          for(i = 0; i < sizeCols; i++){
            if(cC[i] == ii){
              s->seedVec[index][ii][i] = vnom[i];
              for(j = lindex[i]; j < lindex[i + 1]; ++j){
                l = pindex[j];
                s->J[tmp_index][l][i] = (modelica_boolean)1;
              }
            }
          }
        }

        tmpnJ = dim->nJ;
        if(s->lagrange) ++tmpnJ;
        if(s->mayer && index == 3) ++tmpnJ;

        for(ii = dim->nx, j= 0; ii < tmpnJ; ++ii){
          if(index == 2 && ii != s->derIndex[1])
            s->indexCon2[j++] = ii;
          else if(index == 3 && ii != s->derIndex[2] && ii != s->derIndex[0])
            s->indexCon3[j++] = ii;
        }
      }
      /**********************/
      free(data->simulationInfo->analyticJacobians[h_index].seedVars);
    }
  }


  for(i = 0; i < dim->nJ ; ++i){
    for(j = 0; j < dim->nv; ++j){
      if(i < dim->nx){
        if(s->J[0][i][j]){
          s->JderCon[i][j] = (modelica_boolean)1;
          ++dim->nJderx;
        }
      }else{
        if(s->J[0][s->indexCon2[i - dim->nx]][j]){
          s->JderCon[i][j] = (modelica_boolean)1;
          ++dim->nJderx;
        }
      }
    }
  }

 for(i = 0; i < dim->ncf ; ++i){
   for(j = 0; j < dim->nv; ++j){
     if(s->J[2][i][j])
       ++dim->nJfderx;
   }
 }

  if(s->lagrange)
    for(j = 0; j < dim->nv; ++j){
      if(s->J[0][s->derIndex[1]][j])
        s->gradL[j] = (modelica_boolean)1;
    }

  if(s->mayer)
    for(j = 0; j < dim->nv; ++j){
      if(s->J[1][s->derIndex[0]][j])
        s->gradM[j] = (modelica_boolean)1;
    }

  s->indexJ2 = (int *) malloc((dim->nJ+1)* sizeof(int));
  s->indexJ3 = (int *) malloc(dim->nJ2* sizeof(int));

  j = 0;
  for(i = 0; i < dim->nJ +1 ; ++i){
    if(i == s->derIndex[1]){
      s->indexJ2[i] = dim->nJ;
    }else{
      s->indexJ2[i] = j++;
    }
  }

  j = 0;
  for(i = 0; i < dim->nJ2 ; ++i){
    if(i == s->derIndex[2]){
      s->indexJ3[i] = dim->nJ;
    }else if(i == s->derIndex[0]){
      s->indexJ3[i] = dim->nJ + 1;
    }else{
      s->indexJ3[i] = j++;
    }
  }
 }

/*
 *  copy analytic jacobians vars for each subintervall
 *  author: Vitalij Ruge
 */
static inline void copy_JacVars(OptData *optData){
  int i,j,l;

  DATA* data = optData->data;
  int * indexBC = &optData->s.indexABCD[2];
  modelica_boolean * s= &optData->s.matrix[2];
  const int nn = 3;
  OptDataDim * dim = &optData->dim;
  const int np = dim->np;
  const int nsi = dim->nsi;

  dim->analyticJacobians_tmpVars = (modelica_real ****) malloc(nn*sizeof(modelica_real***));
  for(l = 0; l < nn ; ++l){
    if(s[l]){
      dim->dim_tmpVars[l] = data->simulationInfo->analyticJacobians[indexBC[l]].sizeTmpVars;
      dim->analyticJacobians_tmpVars[l] = (modelica_real ***) malloc(nsi*sizeof(modelica_real**));
      for(i = 0; i< nsi; ++i){
        dim->analyticJacobians_tmpVars[l][i] = (modelica_real **) malloc(np*sizeof(modelica_real*));
        for(j = 0; j< np; ++j){
          dim->analyticJacobians_tmpVars[l][i][j] = (modelica_real *) malloc(dim->dim_tmpVars[l]*sizeof(modelica_real));
          memcpy(dim->analyticJacobians_tmpVars[l][i][j],data->simulationInfo->analyticJacobians[indexBC[l]].tmpVars,dim->dim_tmpVars[l]*sizeof(modelica_real));
        }
      }
    }
  }
}

/*
 *  print the jacobian matrix struct
 *  author: Vitalij Ruge
 */
static inline void print_local_jac_struct(DATA * data, OptDataDim * dim, OptDataStructure *s){

  const int nv = dim->nv;
  const int nJ = dim->nJ;
  const int ncf = dim->ncf;

  int i, j;

  printf("\nJacabian Structure %i x %i", nJ, nv);
  printf("\n========================================================");
  for(i = 0; i < nJ; ++i){
      printf("\n");
      for(j =0; j< nv; ++j)
        printf("%s ", (s->JderCon[i][j])? "*":"0");
  }
  if(ncf > 0){
    printf("\n-------------------------------------------------------");
    printf("\nfinal constraint(s)");
    for(i = 0; i < ncf; ++i){
        printf("\n");
        for(j =0; j< nv; ++j)
          printf("%s ", (s->J[2][i][j])? "*":"0");
    }
  }

  printf("\n========================================================");
  printf("\nGradient Structure");
  printf("\n========================================================");
  if(s->lagrange){
    printf("\nlagrange");
    printf("\n-------------------------------------------------------");
    printf("\n");
    for(j = 0; j < nv; ++j)
      printf("%s ", (s->gradL[j])? "*":"0");
  }
  if(s->mayer){
    printf("\nmayer");
    printf("\n-------------------------------------------------------");
    printf("\n");
    for(j = 0; j < nv; ++j)
      printf("%s ", (s->gradM[j])? "*":"0");
  }
}


/*
 *  overestimation hessian matrix struct
 *  author: Vitalij Ruge
 */
static inline void local_hessian_struct(DATA * data, OptDataDim * dim, OptDataStructure *s){
  const int nv = dim->nv;
  const int nJ = dim->nJ;
  const int ncf = dim->ncf;

  int i, j, l;

  modelica_boolean ***Hg;
  modelica_boolean ** Hm;
  modelica_boolean ** Hl;
  modelica_boolean ** H0;
  modelica_boolean ** H1;
  modelica_boolean *** Hcf;
  modelica_boolean **J;
  modelica_boolean tmp;

  dim->nH0 = 0;
  dim->nH1 = 0;
  dim->nH0_ = 0;
  dim->nH1_ = 0;

  s->Hg = (modelica_boolean ***) malloc(nJ*sizeof(modelica_boolean**));

  for(i = 0; i<nJ; ++i){
    s->Hg[i] = (modelica_boolean **) malloc(nv*sizeof(modelica_boolean*));
    for(j = 0; j < nv; ++j)
      s->Hg[i][j] = (modelica_boolean *) calloc(nv, sizeof(modelica_boolean));
  }

  s->Hcf = (modelica_boolean ***) malloc(ncf*sizeof(modelica_boolean**));
  for(i = 0; i<ncf; ++i){
    s->Hcf[i] = (modelica_boolean **) malloc(nv*sizeof(modelica_boolean*));
    for(j = 0; j < nv; ++j)
      s->Hcf[i][j] = (modelica_boolean *) calloc(nv, sizeof(modelica_boolean));
  }

  s->Hm = (modelica_boolean **) malloc(nv*sizeof(modelica_boolean*));
  s->Hl = (modelica_boolean **) malloc(nv*sizeof(modelica_boolean*));
  s->H0 = (modelica_boolean **) malloc(nv*sizeof(modelica_boolean*));
  s->H1 = (modelica_boolean **) malloc(nv*sizeof(modelica_boolean*));


  for(j = 0; j < nv; ++j){
    s->Hm[j] = (modelica_boolean *) calloc(nv, sizeof(modelica_boolean));
    s->Hl[j] = (modelica_boolean *) calloc(nv, sizeof(modelica_boolean));
    s->H0[j] = (modelica_boolean *) calloc(nv, sizeof(modelica_boolean));
    s->H1[j] = (modelica_boolean *) calloc(nv, sizeof(modelica_boolean));
  }

  /***********************************/
  Hg = s->Hg;
  Hm = s->Hm;
  Hl = s->Hl;
  H0 = s->H0;
  H1 = s->H1;
  J = s->JderCon;
  Hcf = s->Hcf;

  /***********************************/
  for(l = 0; l < nJ; ++l){
    for(i = 0; i < nv; ++i){
      for(j = 0; j <nv; ++j){
        if(J[l][i]*J[l][j])
          Hg[l][i][j] = (modelica_boolean)1;
      }
    }
  }
  /***********************************/
  for(l = 0; l < ncf; ++l){
    for(i = 0; i < nv; ++i){
      for(j = 0; j <nv; ++j){
        if(s->J[2][l][i]*s->J[2][l][j])
          Hcf[l][i][j] = (modelica_boolean)1;
      }
    }
  }

  /***********************************/
  if(s->lagrange){
    for(i = 0; i< nv; ++i){
      for(j = 0; j <nv; ++j){
        if(s->gradL[i]*s->gradL[j]){
          Hl[i][j] = (modelica_boolean)1;
         }
      }
    }
  }

  /***********************************/
  if(s->mayer){
    for(i = 0; i< nv; ++i){
      for(j = 0; j <nv; ++j){
        if(s->gradM[i]*s->gradM[j])
          Hm[i][j] = (modelica_boolean)1;
      }
    }
  }

  /***********************************/
  for(i = 0; i< nv; ++i){
    for(j = 0; j <nv; ++j){
      if(nJ>0){
        for(l = 0; l <nJ; ++l){
          tmp = Hg[l][i][j] || Hl[i][j];
          if(tmp && !H0[i][j]){
            H0[i][j] = (modelica_boolean)1;
            ++dim->nH0;
            if(i <= j)
              ++dim->nH0_;
          }
          if((tmp || Hm[i][j]) && !H1[i][j]){
            H1[i][j] = (modelica_boolean)1;
            ++dim->nH1;
            if(i <= j)
              ++dim->nH1_;
          }
          if(H0[i][j] && H1[i][j])
            break;
        }
     }else{
       if(Hl[i][j]){
         H0[i][j] = (modelica_boolean)1;
         ++dim->nH0;
         if(i <= j)
           ++dim->nH0_;
       }
       if(H0[i][j] || Hm[i][j]){
         H1[i][j] = (modelica_boolean)1;
         ++dim->nH1;
         if(i <= j)
           ++dim->nH1_;
       }
    }
   }
  }

  /*******************************/
  if(ncf > 0){
    for(i = 0; i< nv; ++i){
      for(j = 0; j <nv; ++j){
        for(l = 0; l <ncf; ++l){
          if(Hcf[l][i][j] && !H1[i][j]){
            H1[i][j] = (modelica_boolean)1;
            ++dim->nH1;
            if(i <= j)
              ++dim->nH1_;
            break;
          }
        }
      }
    }
  }

}

/*
 *  print hessian matrix struct
 *  author: Vitalij Ruge
 */
static inline void print_local_hessian_struct(DATA * data, OptDataDim * dim, OptDataStructure *s){
  modelica_boolean **H0 = s->H0;
  modelica_boolean **H1 = s->H1;
  const int nv = dim->nv;
  const int n1 = dim->nH1;
  const int n0 = dim->nH0;

  int i, j, l;

  printf("\n========================================================");
  printf("\nHessian Structure %i x %i\tnz = %i", nv, nv,n0);
  printf("\n========================================================");
  for(i = 0; i < nv; ++i){
    printf("\n");
    for(j =0; j< nv; ++j)
      printf("%s ", (H0[i][j])? "*":"0");
  }

  if(dim->nH1 != dim->nH0){
    printf("\n========================================================");
    printf("\nHessian Structure %i x %i for t = stopTime \tnz = %i", nv, nv, n1);
    printf("\n========================================================");
    for(i = 0; i < nv; ++i){
      printf("\n");
      for(j =0; j< nv; ++j)
        printf("%s ", (H1[i][j])? "*":"0");
    }
  }
}

/*
 *  update the jacobian matrix struct
 *  author: Vitalij Ruge
 */
static inline void update_local_jac_struct(OptDataDim * dim, OptDataStructure *s){
  const int nx = dim->nx;
  int i;
  modelica_boolean ** J;

  J = s->JderCon;
  for(i = 0; i < nx; ++i){
    if(!J[i][i]){
      J[i][i] = (modelica_boolean)1;
      ++dim->nJderx;
    }
  }
}


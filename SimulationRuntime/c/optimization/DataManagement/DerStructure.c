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

static inline void local_jac_struct(DATA * data, OptDataDim * dim, OptDataStructure *s, const modelica_real* const vnom);
static inline void print_local_jac_struct(DATA * data, OptDataDim * dim, OptDataStructure *s);
static inline void local_hessian_struct(DATA * data, OptDataDim * dim, OptDataStructure *s);
static inline void print_local_hessian_struct(DATA * data, OptDataDim * dim, OptDataStructure *s);
static inline void update_local_jac_struct(OptDataDim * dim, OptDataStructure *s);

/* pick up jac struct
 * author: Vitalij Ruge
 */
inline void allocate_der_struct(OptDataStructure *s, OptDataDim * dim, DATA* data, OptData *optData){
  const int nv = dim->nv;
  const int nsi = dim->nsi;
  const int np = dim->np;
  const int nJ = dim->nJ;
  const int nJ2 = dim->nJ2;
  const int nx = dim->nx;
  int i, j, k;

  s->matrix[1] = (modelica_boolean)(data->callback->initialAnalyticJacobianA((void*) data) == 0);
  s->matrix[2] = (modelica_boolean)(data->callback->initialAnalyticJacobianB((void*) data) == 0);
  s->matrix[3] = (modelica_boolean)(data->callback->initialAnalyticJacobianC((void*) data) == 0);
  s->matrix[4] = (modelica_boolean)(data->callback->initialAnalyticJacobianD((void*) data) == 0);

  dim->nJderx = 0;
  /*************************/
  s->J =  (modelica_boolean***) malloc((5)*sizeof(modelica_boolean**));
  s->J[1] = (modelica_boolean**) malloc(nx* sizeof(modelica_boolean*));
  for(i = 0; i < nx; ++i)
    s->J[1][i] = (modelica_boolean*)calloc(nv, sizeof(modelica_boolean));
  /****************************/
  s->J[2] = (modelica_boolean**) malloc(sizeof(modelica_boolean*));
  s->J[2][0] = (modelica_boolean*)calloc(nv, sizeof(modelica_boolean));
  /*****************************/
  s->J[3] = (modelica_boolean**) malloc(sizeof(modelica_boolean*));
  s->J[3][0] = (modelica_boolean*)calloc(nv, sizeof(modelica_boolean));
  /*****************************/
  s->J[4] = (modelica_boolean**) malloc(nJ* sizeof(modelica_boolean*));
  for(i = 0; i < nJ ; ++i)
    s->J[4][i] = (modelica_boolean*)calloc(nv, sizeof(modelica_boolean));


  s->mayer = (modelica_boolean) (data->callback->mayer(data, &s->pmayer) >= 0);
  s->lagrange = (modelica_boolean) (data->callback->lagrange(data, &s->plagrange) >= 0);

  if(!s->mayer)
    s->pmayer = NULL;
  if(!s->lagrange)
    s->plagrange = NULL;

  local_jac_struct(data, dim, s, optData->bounds.vnom);

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

  optData->Hm = (long double **)malloc(nv*sizeof(long double*));
  for(j = 0; j < nv; ++j)
    optData->Hm[j] = (long double *)calloc(nv, sizeof(long double));

  optData->Hl = (long double **) malloc(nv*sizeof(long double*));
  for(j = 0; j < nv; ++j)
    optData->Hl[j] = (long double *)calloc(nv, sizeof(long double));

}


/*
 *  pick up the jacobian matrix struct
 *  author: Vitalij Ruge
 */
static inline void local_jac_struct(DATA * data, OptDataDim * dim, OptDataStructure *s, const modelica_real * const vnom){
  const int nJ = dim->nJ;
  int sizeCols;
  int maxColors;

  modelica_boolean **J;
  int i, ii, j, l, index;
  unsigned int* lindex, *cC, *pindex;

  s->lindex = (unsigned int**)malloc(5*sizeof(unsigned int*));
  s->seedVec = (modelica_real ***)malloc(5*sizeof(modelica_real**));

  for(index = 2; index < 5; ++index){
      if(s->matrix[index]){
        J = s->J[index];
        sizeCols = data->simulationInfo.analyticJacobians[index].sizeCols;
        maxColors = data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1;
        cC = (unsigned int*) data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
        lindex = (unsigned int*) data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;
        pindex = data->simulationInfo.analyticJacobians[index].sparsePattern.index;

        s->lindex[index] = (unsigned int*)calloc((sizeCols+1), sizeof(unsigned int));
        memcpy(&s->lindex[index][1], lindex, sizeCols*sizeof(unsigned int));
        lindex = s->lindex[index];
        s->seedVec[index] = (modelica_real **)malloc((maxColors)*sizeof(modelica_real*));
        free(data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex);
        /**********************/
        if(sizeCols > 0){
          for(ii = 1; ii < maxColors; ++ii){
            s->seedVec[index][ii] = (modelica_real*)calloc(sizeCols, sizeof(modelica_real));
            for(i = 0; i < sizeCols; i++){
              if(cC[i] == ii){
                s->seedVec[index][ii][i] = vnom[i];
                for(j = lindex[i]; j < lindex[i + 1]; ++j){
                  l = pindex[j];
                  J[l][i] = (modelica_boolean)1;
                  if(index == 4)
                    ++dim->nJderx;
                }
              }
            }
          }
        }
        /**********************/
        free(data->simulationInfo.analyticJacobians[index].seedVars);
      }
    }

    s->derIndex[0] = (s->lagrange)? nJ : nJ - 1;
    s->derIndex[1] = s->derIndex[0] + 1;
}

/*
 *  print the jacobian matrix struct
 *  author: Vitalij Ruge
 */
static inline void print_local_jac_struct(DATA * data, OptDataDim * dim, OptDataStructure *s){

  modelica_boolean **J;
  const int nv = dim->nv;
  const int nJ = dim->nJ;

  int i, j;

  J = s->J[4];
  printf("\nJacabian Structure %i x %i", nJ, nv);
  printf("\n========================================================");
  for(i = 0; i < nJ; ++i){
    printf("\n");
    for(j =0; j< nv; ++j)
      printf("%s ", (J[i][j])? "*":"0");
  }

  printf("\n========================================================");
  printf("\nGradient Structure");
  printf("\n========================================================");
  if(s->lagrange){
    printf("\nlagrange");
    printf("\n-------------------------------------------------------");
    printf("\n");
    J = s->J[2];
    for(j = 0; j < nv; ++j)
      printf("%s ", (J[0][j])? "*":"0");
  }
  if(s->mayer){
    printf("\nmayer");
    printf("\n-------------------------------------------------------");
    printf("\n");
    J = s->J[3];
    for(j = 0; j < nv; ++j)
      printf("%s ", (J[0][j])? "*":"0");
  }

}


/*
 *  overestimation hessian matrix struct
 *  author: Vitalij Ruge
 */
static inline void local_hessian_struct(DATA * data, OptDataDim * dim, OptDataStructure *s){
  const int nv = dim->nv;
  const int nJ = dim->nJ;

  int i, j, l;

  modelica_boolean ***Hg;
  modelica_boolean ** Hm;
  modelica_boolean ** Hl;
  modelica_boolean ** H0;
  modelica_boolean ** H1;
  modelica_boolean *** J;
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
  J = s->J;

  /***********************************/
  for(l = 0; l <nJ; ++l){
    for(i = 0; i< nv; ++i){
      for(j = 0; j <nv; ++j){
        if(J[4][l][i]*J[4][l][j])
          Hg[l][i][j] = (modelica_boolean)1;
      }
    }
  }

  /***********************************/
  if(s->lagrange){
    for(i = 0; i< nv; ++i){
      for(j = 0; j <nv; ++j){
        if(J[2][0][i]*J[2][0][j])
          Hl[i][j] = (modelica_boolean)1;
      }
    }
  }

  /***********************************/
  if(s->mayer){
    for(i = 0; i< nv; ++i){
      for(j = 0; j <nv; ++j){
        if(J[3][0][i]*J[3][0][j])
          Hm[i][j] = (modelica_boolean)1;
      }
    }
  }

  /***********************************/
  for(i = 0; i< nv; ++i){
    for(j = 0; j <nv; ++j){
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

  J = s->J[4];
  for(i = 0; i < nx; ++i){
    if(!J[i][i]){
      J[i][i] = (modelica_boolean)1;
      ++dim->nJderx;
    }
  }
}

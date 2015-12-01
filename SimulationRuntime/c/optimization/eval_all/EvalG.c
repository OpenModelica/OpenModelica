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

/*! EvalG.c
 */

#include "../OptimizerData.h"
#include "../OptimizerLocalFunction.h"
#include "../../simulation/results/simulation_result.h"
#include "../../simulation/options.h"

static inline void generated_jac_struc(OptData *, int*, int*);
static inline void set_row(int *, int *, int *, const modelica_boolean *const,
    const int, const int , const int );

static inline void set_cell(int*, int*, int*, const int, const int);

static inline void structJac01(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj);

static inline void structJac1(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj);

static inline void structJac02(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj);

static inline void structJac2(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj);

static inline void structJac03(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj);

static inline void structJac3(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj);

static inline void structJacC(const modelica_real *const J, double *values,
    const int nv, int *k, const modelica_boolean * const Jj);

static inline void printMaxError(Number *g, const int m, const int nx, const int nJ, long double **t,
    const int np, const int nsi, DATA * data, OptData * optData);

static inline void debugeJac(OptData * optData,Number* vopt);


/* eval constraints
 * author: Vitalij Ruge
 */
Bool evalfG(Index n, double * vopt, Bool new_x, int m, Number *g, void * useData){
  OptData *optData = (OptData*)useData;

  const int nx = optData->dim.nx;
  const int nv = optData->dim.nv;
  const int nc = optData->dim.nc;
  const int ncf = optData->dim.ncf;
  const int nsi = optData->dim.nsi;
  const int np = optData->dim.np;
  const int index_con = optData->dim.index_con;
  const int index_conf = optData->dim.index_conf;

  modelica_real ***v;
  long double a[5][5];
  long double *sdt;
  double * vv[np+1];
  int i, j, k, shift;


  if(new_x){
    optData2ModelData(optData, vopt, optData->index);
  }

  v = optData->v;
  memcpy(a ,optData->rk.a, sizeof(optData->rk.a));

  vv[0] = optData->sv0;
  vv[1] = vopt;
  for(j = 1; j < np; ++j){
    vv[j + 1] = vv[j] + nv;
  }

  if(np == 3){
    for(i = 0, shift = 0; i <nsi; ++i){
      sdt = optData->bounds.scaldt[i];
      /*1*/
      for(k=0; k< nx; ++k){
        g[shift++] = (a[0][0]*vv[0][k] + a[0][3]*vv[3][k] + sdt[k]*v[i][0][k+nx])
                    -(a[0][1]*vv[1][k] + a[0][2]*vv[2][k]);
      }
      memcpy(g + shift, &v[i][0][index_con], nc*sizeof(double));
      shift += nc;

      /*2*/
      for(k=0; k< nx; ++k){
        g[shift++] = (a[1][1]*vv[1][k] + sdt[k]*v[i][1][k+nx])
                     - (a[1][0]*vv[0][k] + a[1][2]*vv[2][k] + a[1][3]*vv[3][k]);
      }
      memcpy(g + shift, &v[i][1][index_con], nc*sizeof(double));
      shift +=nc;

      /*3*/
      for(k=0; k< nx; ++k){
        g[shift++] = (a[2][0]*vv[0][k] + a[2][2]*vv[2][k] + sdt[k]*v[i][2][nx+k])
                     -(a[2][1]*vv[1][k] + a[2][3]*vv[3][k]);
      }
      memcpy(g + shift, &v[i][2][index_con], nc*sizeof(double));
      shift +=nc;
      vv[0] = vv[np];
      for(j = 0; j < np; ++j)
        vv[j + 1] = vv[j] + nv;
    }
    /*terminal constraint(s)*/
    memcpy(g + shift, &v[nsi-1][2][index_conf], ncf*sizeof(double));

  }else if(np == 1){
    for(i = 0, shift = 0; i <nsi; ++i){
      sdt = optData->bounds.scaldt[i];
      for(k = 0; k < nx; ++k)
        g[shift++] = vv[0][k] + (sdt[k]*v[i][0][k+nx] - vv[1][k]);

      memcpy(g + shift, &v[i][0][index_con], nc*sizeof(double));
      shift += nc;
      vv[0] = vv[np];
      for(j = 0; j < np; ++j)
        vv[j + 1] = vv[j] + nv;
    }
    /*terminal constraint(s)*/
    memcpy(g + m - ncf, &v[nsi-1][0][index_conf], ncf*sizeof(double));
  }
  if(ACTIVE_STREAM(LOG_IPOPT_ERROR)){
    const int nJ = optData->dim.nJ;
    printMaxError(g, m, nx, nJ, optData->time.t, np ,nsi ,optData->data, optData);
  }
  return TRUE;
}

/*!
 *  eval derivation of s.t.
 *  author: Vitalij Ruge
 **/
Bool evalfDiffG(Index n, double * vopt, Bool new_x, Index m, Index njac, Index *iRow, Index *iCol, Number *values, void * useData){
  OptData *optData = (OptData*)useData;

  if(!values){
    generated_jac_struc(optData, iRow, iCol);
#if 0
    {
      const int nsi = optData->dim.nsi;
      int i;
      FILE *pFile;
      char buffer[4096];
      pFile = fopen("jac_struct.m", "wt");
      if(pFile == NULL)
        printf("\n\nError");
      fprintf(pFile, "%s", "clear J\n");
      fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
      fprintf(pFile, "%s", "nz = ");
      fprintf(pFile, "%i", njac);
      fprintf(pFile, "%s", "\nnumberVars = ");
      fprintf(pFile, "%i", n);
      fprintf(pFile, "%s", "\nnumberconstraints = ");
      fprintf(pFile, "%i", m);
      fprintf(pFile, "%s", "\nNumberOfIntervalls = ");
      fprintf(pFile, "%i", nsi);
      fprintf(pFile, "\nH = sparse(%i,%i);\n",m,n);
      fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
      for(i=0; i< njac; ++i){
        sprintf(buffer, "H(%i,%i) = 1;\n", iRow[i]+1, iCol[i]+1);
        fprintf(pFile,"%s", buffer);
      }
      fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
      fprintf(pFile, "%s", "spy(H)\n");
    }
    assert(0);
#endif
  }else{
    const int nsi = optData->dim.nsi;
    const int np = optData->dim.np;
    const int nx = optData->dim.nx;
    const int nv = optData->dim.nv;
    const int nJ = optData->dim.nJ;
    const int ncf = optData->dim.ncf;
    modelica_boolean ** J = optData->s.JderCon;
    modelica_boolean ** Jf = optData->s.J[2];
    int i, j, k, l, ii, cindex;
    ++optData->iter_;
    if(new_x){
      optData2ModelData(optData, vopt, 1);
    }
    if(np == 3){
      /*****************************/
      for(j = 0, k = 0; j < np; ++j){
        for(l = 0; l < nx; ++l){
          switch(j){
            case 0:
              structJac01(optData->rk.a[j], optData->J[0][j][l],
                  values, nv, &k, l, J[l]);
              break;
            case 1:
              structJac02(optData->rk.a[j], optData->J[0][j][l],
                  values, nv, &k, l, J[l]);
              break;
            case 2:
              structJac03(optData->rk.a[j], optData->J[0][j][l],
                  values, nv, &k, l, J[l]);
              break;
          }
        }
        for(; l< nJ; ++l){
          structJacC(optData->J[0][j][l], values, nv, &k, J[l]);
        }
      }

      /*****************************/
      for(i = 1; i < nsi; ++i){
        for(j = 0; j < np; ++j){
          for(l = 0; l < nx; ++l){
            switch(j){
              case 0:
                structJac1(optData->rk.a[j], optData->J[i][j][l],
                    values, nv, &k, l, J[l]);
                break;
              case 1:
                structJac2(optData->rk.a[j], optData->J[i][j][l],
                    values, nv, &k, l, J[l]);
                break;
              case 2:
                structJac3(optData->rk.a[j], optData->J[i][j][l],
                    values, nv, &k, l, J[l]);
                break;
            }
          }
          for(; l< nJ; ++l){
            structJacC(optData->J[i][j][l], values, nv, &k, J[l]);
          }
        }
      }
      /*terminal constraint(s)*/
      for(l = 0; l< ncf; ++l){
        structJacC(optData->Jf[l], values, nv, &k, Jf[l]);
      }

    }else if(np == 1){
      /*****************************/
      for(j = 0, k = 0; j < np; ++j){
        for(l = 0; l < nx; ++l){
          for(ii = 0; ii < nv; ++ii)
            if(J[l][ii]){
              values[k++] = (modelica_real)((ii == l) ? optData->J[0][j][l][ii] - 1.0 : optData->J[0][j][l][ii]);
            }
          }
        for(; l < nJ; ++l){
          for(ii = 0; ii < nv; ++ii)
            if(J[l][ii]){
              values[k++] = (modelica_real)(optData->J[0][j][l][ii]);
            }
          }

        }
      /*****************************/
      for(i = 1; i < nsi; ++i){
        for(j = 0; j < np; ++j){
          for(l = 0; l < nx; ++l){
            if(l < nx)
              values[k++] = 1.0;
            for(ii = 0; ii < nv; ++ii){
              if(J[l][ii]){
                values[k++] = (modelica_real)((ii == l) ? optData->J[i][j][l][ii] - 1.0 : optData->J[i][j][l][ii]);
              }
            }
          }
          for(; l < nJ; ++l){
            for(ii = 0; ii < nv; ++ii){
              if(J[l][ii]){
                values[k++] = (modelica_real)(optData->J[i][j][l][ii]);
              }
            }
          }
        }
      }
      /*terminal constraint(s)*/
      for(l=0; l< ncf; ++l){
        structJacC(optData->Jf[l], values, nv, &k, Jf[l]);
      }
    }
    /*****************************/
    /*
    {
    printf("\n\n%i = %i",njac,k);
    assert(0);
    }
    */
    /*
    for(i = 0; i< njac; ++i)
    printf("\nvalues[%i] = %g",i,values[i]);
    assert(0);
    */
   {
    char *cflags;
    int ijac = 0;
    cflags = (char*)omc_flagValue[FLAG_OPTDEBUGEJAC];
    if(cflags){
      ijac = atoi(cflags);
      if(ijac >= optData->iter_)
        debugeJac(optData, vopt);
    }
   }
  }

  return TRUE;
}

/*!
 *  helper evalfDiffG
 *  author: Vitalij Ruge
 **/
static inline void structJac01(const long double * const a, const modelica_real *const Jj,  double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj){

  int l;

  /*1*/
  for(l = 0; l < nv; ++l){
    if(sJj[l]){
      values[(*k)++] = (modelica_real)((j == l) ? Jj[l] - a[1] : Jj[l]);
    }
  }

  /*2*/
  values[(*k)++] = -a[2];

  /*3*/
  values[(*k)++] = a[3];
}

/*!
 *  helper evalfDiffG
 *  author: Vitalij Ruge
 **/
static inline void structJac1(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj){

  int l;
  values[(*k)++] = a[0];
  /*1*/
  for(l = 0; l < nv; ++l){
    if(sJj[l]){
      values[(*k)++] = (j == l) ? Jj[l] - a[1] : Jj[l];
    }
  }

  /*2*/
  values[(*k)++] = -a[2];

  /*3*/
  values[(*k)++] = a[3];
}

/*!
 *  helper evalfDiffG
 *  author: Vitalij Ruge
 **/
static inline void structJac02(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj){

  int l;

  /*1*/
  values[(*k)++] = a[1];

  /*2*/
  for(l = 0; l< nv; ++l){
    if(sJj[l]){
      values[(*k)++] = ((j == l)? Jj[l] - a[2] : Jj[l]);
    }
  }

  /*3*/
  values[(*k)++] = -a[3];
}

/*!
 *  helper evalfDiffG
 *  author: Vitalij Ruge
 **/
static inline void structJac2(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj){

  int l;
  /*0*/
  values[(*k)++] = -a[0];

  /*1*/
  values[(*k)++] = a[1];

  /*2*/
  for(l = 0; l< nv; ++l){
    if(sJj[l]){
      values[(*k)++] = ((j == l)? Jj[l] - a[2] : Jj[l]);
    }
  }

  /*3*/
  values[(*k)++] = -a[3];
}


/*!
 *  helper evalfDiffG
 *  author: Vitalij Ruge
 **/
static inline void structJac03(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj){

  int l;
  /*1*/
  values[(*k)++] = -a[1];
  /*2*/
  values[(*k)++] = a[2];
  /*3*/
  for(l = 0; l< nv; ++l)
    if(sJj[l])
      values[(*k)++] = ((j == l)? Jj[l] - a[3] : Jj[l]);

}

/*!
 *  helper evalfDiffG
 *  author: Vitalij Ruge
 **/
static inline void structJac3(const long double * const a, const modelica_real *const Jj, double * values, const int nv, int *k, const int j,
    const modelica_boolean * const sJj){

  int l;
  /*0*/
  values[(*k)++] = a[0];
  /*1*/
  values[(*k)++] = -a[1];
  /*2*/
  values[(*k)++] = a[2];
  /*3*/
  for(l = 0; l< nv; ++l)
    if(sJj[l])
      values[(*k)++] = ((j == l)? Jj[l] - a[3] : Jj[l]);

}

/*!
 *  helper evalfDiffG
 *  author: Vitalij Ruge
 **/
static inline void structJacC(const modelica_real *const J, double *values,
    const int nv, int *k, const modelica_boolean * const Jj){
  int l;
  for(l = 0; l<nv; ++l)
    if(Jj[l]){
      values[(*k)++] = J[l];
    }
}


/*!
 *  helper for generated_jac_struc (row)
 *  author: Vitalij Ruge
 **/
static inline void set_row(int *k, int *iRow, int *iCol, const modelica_boolean * const Jj,
    const int nv, const int r, const int c){

  int i;
  for(i = 0; i<nv; ++i){
    if(Jj[i]){
      iRow[*k] = r;
      iCol[(*k)++] = c + i;
    }
  }

}

/*!
 *  helper for generated_jac_struc (cell)
 *  author: Vitalij Ruge
 **/
static inline void set_cell(int*k, int*iRow, int*iCol, const int r, const int c){
  iRow[*k] = r;
  iCol[(*k)++] = c;
}

/*!
 *  generated global jacobian struct
 *  author: Vitalij Ruge
 **/
static inline void generated_jac_struc(OptData * optData, int *iRow, int* iCol){

  const int nv = optData->dim.nv;
  const int nx = optData->dim.nx;
  const int nsi = optData->dim.nsi;
  const int nJ = optData->dim.nJ;
  const int np = optData->dim.np;
  const int npv = np*nv;
  const int ncf = optData->dim.ncf;

  modelica_boolean **  J = optData->s.JderCon;
  modelica_boolean **  Jf = optData->s.J[2];
  int r, c, tmp_r, tmp_c;
  int i, j, k;

  /**********************************/
  r = 0;
  c = 0;
  k = 0;
  if(np == 3){
    /* 1 */
    for(j = 0; j <nx; ++j){
      tmp_r = r + j;
      tmp_c = c + j;

     set_row(&k, iRow, iCol, J[j], nv, tmp_r, c);
     set_cell(&k, iRow, iCol, tmp_r, tmp_c + nv);
     set_cell(&k, iRow, iCol, tmp_r, tmp_c + 2*nv);

    }
    for(; j<nJ; ++j){
      set_row(&k, iRow, iCol, J[j], nv, r+j, c);
    }

    r += nJ;
    /* 2 */
    for(j = 0; j <nx; ++j){
      tmp_r = r + j;
      tmp_c = c + j;

      set_cell(&k, iRow, iCol, tmp_r, tmp_c);
      set_row(&k, iRow, iCol, J[j], nv, tmp_r, c + nv);
      set_cell(&k, iRow, iCol, tmp_r, tmp_c + 2*nv);
    }
    for(; j<nJ; ++j){
      set_row(&k, iRow, iCol, J[j], nv, r+j, c + nv);
    }

    r += nJ;
    /* 3 */
    for(j = 0; j <nx; ++j){
      tmp_r = r + j;
      tmp_c = c + j;

      set_cell(&k, iRow, iCol, tmp_r, tmp_c);
      set_cell(&k, iRow, iCol, tmp_r, tmp_c + nv);
      set_row(&k, iRow, iCol, J[j], nv, tmp_r, c + 2*nv);
    }
    for(; j<nJ; ++j){
      set_row(&k, iRow, iCol, J[j], nv, r+j, c + 2*nv);
    }

    /**********************************/
    r += nJ;
    c = (np-1)*nv;
    for(i = 1; i < nsi; ++i,  r += nJ, c += npv){
      /* 1 */
      for(j = 0; j <nx; ++j){
        tmp_r = r + j;
        tmp_c = c + j;

        set_cell(&k, iRow, iCol, tmp_r, tmp_c);
        set_row(&k, iRow, iCol, J[j], nv, tmp_r, c + nv);
        set_cell(&k, iRow, iCol, tmp_r, tmp_c + 2*nv);
        set_cell(&k, iRow, iCol, tmp_r, tmp_c + 3*nv);
      }
      for(; j<nJ; ++j){
        set_row(&k, iRow, iCol, J[j], nv, r + j, c+nv);
      }

      r += nJ;
      /* 2 */
      for(j = 0; j <nx; ++j){
        tmp_r = r + j;
        tmp_c = c + j;

        set_cell(&k, iRow, iCol, tmp_r, tmp_c);
        set_cell(&k, iRow, iCol, tmp_r, tmp_c + nv);
        set_row(&k, iRow, iCol, J[j], nv, tmp_r, c + 2*nv);
        set_cell(&k, iRow, iCol, tmp_r, tmp_c + 3*nv);
      }
      for(; j<nJ; ++j){
        set_row(&k, iRow, iCol, J[j], nv, r+j, c+2*nv);
      }

      r += nJ;
      /* 3 */
      for(j = 0; j <nx; ++j){
        tmp_r = r + j;
        tmp_c = c + j;

        set_cell(&k, iRow, iCol, tmp_r, tmp_c);
        set_cell(&k, iRow, iCol, tmp_r, tmp_c + nv);
        set_cell(&k, iRow, iCol, tmp_r, tmp_c + 2*nv);
        set_row(&k, iRow, iCol, J[j], nv, tmp_r, c + 3*nv);
      }
      for(; j<nJ; ++j){
        set_row(&k, iRow, iCol, J[j], nv, r+j, c+3*nv);
      }
    }
    /*terminal constraint(s)*/
    for(j = 0; j<ncf; ++j){
      set_row(&k, iRow, iCol, Jf[j], nv, r+j, c);
    }
  }else if(np == 1){

    for(j = 0; j <nJ; ++j){
      set_row(&k, iRow, iCol, J[j], nv, r+j, c);
    }

    r += nJ;
    c = (np-1)*nv;

    for(i = 1; i < nsi; ++i,  r += nJ, c += npv){
      for(j = 0; j <nx; ++j){
        tmp_r = r + j;
        tmp_c = c + j;

        set_cell(&k, iRow, iCol, tmp_r, tmp_c);
        set_row(&k, iRow, iCol, J[j], nv, tmp_r, c + nv);
      }
      for(; j<nJ; ++j){
        set_row(&k, iRow, iCol, J[j], nv, r+j, c+nv);
      }

    }
    /*terminal constraint(s)*/
    for(j = 0; j<ncf; ++j){
      set_row(&k, iRow, iCol, Jf[j], nv, r+j, c);
    }

  }
/*
  {
      const int NJ = optData->dim.nJderx;
      int njac = np*(NJ*nsi + nx*(np*nsi - 1));
      printf("\n\n%i = %i",njac,k);
      assert(0);
  }
*/

}


static inline void printMaxError(Number *g, const int m, const int nx, const int nJ,
    long double **t, const int np, const int nsi, DATA * data, OptData * optData){

  int index = 0;
  int index_x = 0;
  double gmax = -1;
  int i, j, k, l;
  int ii=-1, jj=-1, kk = -1;
  double tmp, tmp1;

  for(i = 0, l = 0; i < nsi; ++i){
    for(j = 0; j < np; ++j){
      for(k=0; k< nx; ++k){
        tmp = fabs(g[l++]);
        if(tmp > gmax){
          ii = i;
          jj = j;
          kk = k;
          gmax = tmp;
        }
      }
      for(; k< nJ; ++k, ++l){
        tmp1 = g[l] - optData->ipop.gmax[l]; // > 0
        tmp  = optData->ipop.gmin[l] - g[l]; // >0
        tmp = fmaxl(fmaxl(tmp, tmp1),0.0);
        if(tmp > gmax){
          ii = i;
          jj = j;
          kk = k;
          gmax = tmp;
        }
      }
    }
  }

  /*final constraints*/
  for(k=nJ; k< nJ+optData->dim.ncf; ++k, ++l){
    tmp1 = g[l] - optData->ipop.gmax[l]; // > 0
    tmp  = optData->ipop.gmin[l] - g[l]; // >0
    tmp = fmaxl(fmaxl(tmp, tmp1),0.0);
    if(tmp > gmax){
      ii = nsi- 1;
      jj = np-1;
      kk = k;
      gmax = tmp;
    }
  }

  if(kk>-1){
    if(kk < nx){
      infoStreamPrint(LOG_IPOPT_ERROR, 0, "max error is %g for the approximation of the state %s(time = %g)\n",
              gmax, data->modelData->realVarsData[kk].info.name, (double)t[ii][jj]);
    }else if(kk < nJ){
      const int ll = kk - nx + optData->dim.index_con;
      infoStreamPrint(LOG_IPOPT_ERROR, 0,"max violation is %g for the constraint %s(time = %g)\n",
              gmax, data->modelData->realVarsData[ll].info.name, (double)t[ii][jj]);
    }else{
      const int ll = kk - nx + optData->dim.index_con;
      infoStreamPrint(LOG_IPOPT_ERROR, 0,"max violation is %g for the final constraint %s(time = %g)\n", gmax, data->modelData->realVarsData[ll].info.name, (double)t[ii][jj]);
    }
  }
}

/*!
 *  generated csv and python script for jacobian
 *  author: Vitalij Ruge
 **/
static inline void debugeJac(OptData * optData, Number* vopt){
  int i,j,k, jj, kk ,ii;
  const int nv = optData->dim.nv;
  const int nx = optData->dim.nx;
  const int nu = optData->dim.nu;
  const int nsi = optData->dim.nsi;
  const int nJ = optData->dim.nJ;
  const int np = optData->dim.np;
  const int nc = optData->dim.nc;
  const int npv = np*nv;
  const int nt = optData->dim.nt;
  const int NRes = optData->dim.NRes;
  const int nReal = optData->data->modelData->nVariablesReal;
  const int NV = optData->dim.NV;
  Number vopt_shift[NV];
  long double h[nv][nsi][np];
  long double hh;
  const modelica_real * const vmax = optData->bounds.vmax;
  const modelica_real * const vmin = optData->bounds.vmin;
  const modelica_real * vnom = optData->bounds.vnom;
  modelica_real vv[nsi][np][nReal];
  FILE *pFile;
  char buffer[4096];
  long double *sdt;
  modelica_real JJ[nsi][np][nv][nx];
  modelica_boolean **sJ;
  modelica_real tmpJ;

  sJ = optData->s.JderCon;
  sprintf(buffer, "jac_ana_step_%i.csv", optData->iter_);
  pFile = fopen(buffer, "wt");

  fprintf(pFile,"name;time;");
  for(j = 0; j < nx; ++j)
    fprintf(pFile,"%s;",optData->data->modelData->realVarsData[j].info.name);
  for(j = 0; j < nu; ++j)
    fprintf(pFile, "%s;", optData->dim.inputName[j]);
  fprintf(pFile,"\n");

  for(i=0;i < nsi; ++i){
    for(j = 0; j < np; ++j){
      for(k = 0; k < nx; ++k){
        fprintf(pFile,"%s;%f;",optData->data->modelData->realVarsData[k].info.name,(float)optData->time.t[i][j]);
        for(jj = 0; jj < nv; ++jj){
          tmpJ = (sJ[k][jj]) ? (optData->J[i][j][k][jj]) : 0.0;
          fprintf(pFile,"%lf;", tmpJ);
        }
        fprintf(pFile,"\n");
      }
    }
  }
  fclose(pFile);


#define DF_STEP(v) (1e-5*fabsl(v) + 1e-7)
  memcpy(vopt_shift ,vopt, NV*sizeof(Number));
  optData->index = 0;
  for(k=0; k < nv; ++k){
    for(i=0, jj=k; i < nsi; ++i){
      for(j = 0; j < np; ++j, jj += nv){
        hh = DF_STEP(vopt_shift[jj]);
        while(vopt_shift[jj]  + hh >=  vmax[k]){
         hh *= -1.0;
         if(vopt_shift[jj]  + hh <= vmin[k])
           hh *= 0.9;
         else
           break;
         if(fabsl(hh) < 1e-32){
           printf("\nWarning: StepSize for FD became very small!\n");
           break;
         }
        }
        vopt_shift[jj] += hh;
        h[k][i][j] = hh;
        memcpy(vv[i][j] , optData->v[i][j], nReal*sizeof(modelica_real));
      }
     }

     optData2ModelData(optData, vopt_shift, optData->index);
     memcpy(vopt_shift,vopt , NV*sizeof(modelica_real));

    for(i = 0; i < nsi; ++i){
      sdt = optData->bounds.scaldt[i];
      for(j = 0; j < np; ++j){
        for(kk = 0, ii = nx; kk<nx;++kk, ++ii){
           hh = h[k][i][j];
           JJ[i][j][kk][k] = (optData->v[i][j][ii] - vv[i][j][ii])*sdt[kk]/hh;
        }
        memcpy(optData->v[i][j] , vv[i][j], nReal*sizeof(modelica_real));
      }
     }
   }

  optData->index = 1;
#undef DF_STEP
  sprintf(buffer, "jac_num_step_%i.csv", optData->iter_);
  pFile = fopen(buffer, "wt");

  fprintf(pFile,"name;time;");
  for(j = 0; j < nx; ++j)
    fprintf(pFile,"%s;",optData->data->modelData->realVarsData[j].info.name);
  for(j = 0; j < nu; ++j)
    fprintf(pFile, "%s;", optData->dim.inputName[j]);
  fprintf(pFile,"\n");

  for(i=0;i < nsi; ++i){
    for(j = 0; j < np; ++j){
      for(k = 0; k < nx; ++k){
        fprintf(pFile,"%s;%f;",optData->data->modelData->realVarsData[k].info.name,(float)optData->time.t[i][j]);
        for(jj = 0; jj < nv; ++jj){
          tmpJ = (sJ[k][jj]) ? (JJ[i][j][k][jj]) : 0.0;
          fprintf(pFile,"%lf;",tmpJ);
        }
        fprintf(pFile,"\n");
      }
    }
  }
  fclose(pFile);

  optData2ModelData(optData, vopt, optData->index);

  if(optData->iter_ < 2){
    pFile = fopen("omc_check_jac.py", "wt");
    fprintf(pFile,"\"\"\"\nautomatically generated code for analyse derivatives\n\n");
    fprintf(pFile,"  Input i:\n");
    for(j = 0; j < nx; ++j)
      fprintf(pFile,"   i = %i -> der(%s)\n",j,optData->data->modelData->realVarsData[j].info.name);
    fprintf(pFile," Input j:\n");
    for(j = 0; j < nx; ++j)
      fprintf(pFile,"   j = %i -> %s\n",j,optData->data->modelData->realVarsData[j].info.name);
    for(j = 0; j < nu; ++j)
      fprintf(pFile,"   j = %i -> %s\n",nx+j,optData->dim.inputName[j]);
    fprintf(pFile,"\n\nVitalij Ruge, vruge@fh-bielefeld.de\n\"\"\"\n\n");

    fprintf(pFile,"%s\n%s\n%s\n\n","import numpy as np","import matplotlib.pyplot as plt","from numpy import linalg as LA");
    fprintf(pFile,"class OMC_JAC:\n  def __init__(self, filename):\n    self.filename = filename\n");
    fprintf(pFile,"    self.states = [");
    if(nx > 0)
     fprintf(pFile,"'%s'",optData->data->modelData->realVarsData[0].info.name);
    for(j = 1; j < nx; ++j)
      fprintf(pFile,",'%s'",optData->data->modelData->realVarsData[j].info.name);
    fprintf(pFile,"]\n");
    fprintf(pFile,"    self.inputs = [");
    if(nu > 0)
      fprintf(pFile,"'%s'",optData->dim.inputName[0]);
    for(j = 1; j < nu; ++j)
      fprintf(pFile,",'%s'",optData->dim.inputName[j]);
    fprintf(pFile,"]\n");
    fprintf(pFile,"    self.number_of_states = %i\n",nx);
    fprintf(pFile,"    self.number_of_inputs = %i\n",nu);
    fprintf(pFile,"    self.number_of_constraints = %i\n",nc);
    fprintf(pFile,"    self.number_of_timepoints = %i\n",nt);
    fprintf(pFile,"    self.t = np.zeros(self.number_of_timepoints)\n");
    fprintf(pFile,"    self.dx = np.zeros(self.number_of_states)\n");
    fprintf(pFile,"    self.J = np.zeros([self.number_of_states, self.number_of_states + self.number_of_inputs, self.number_of_timepoints])\n");
    fprintf(pFile,"    self.__read_csv__()\n\n");
    fprintf(pFile,"  def __read_csv__(self):\n");
    fprintf(pFile,"    with open(self.filename,'r') as f:\n");
    fprintf(pFile,"%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n",
                  "      f.readline() # name",
                  "      for l in xrange(self.number_of_timepoints):",
                  "        for k in xrange(self.number_of_states):",
                  "          l1 = f.readline()",
                  "          l1 = l1.split(\";\")",
                  "          l1 = [e for e in l1]",
                  "          if len(l1) <= 1:",
                  "            break",
                  "          self.t[l] = float(l1[1])",
                  "          for n,r in enumerate(l1[2:-1]):",
                  "            self.J[k,n,l] = float(r)",
                  "      f.close()\n",
                  "  def __str__(self):",
                  "    print \"read file %s\"%self.filename","    print \"states: \", self.states",
                  "    print \"inputs: \", self.inputs","    print \"t0 = %g, t = %g\"%(self.t[0],self.t[-1])",
                  "    return \"\"\n");
    fprintf(pFile,"  def get_value_of_jacobian(self,i, j):\n\n");
    fprintf(pFile,"   return self.J[i,j,:]\n\n");
    fprintf(pFile,"  def plot_jacobian_element(self, i, j, filename):\n");
    fprintf(pFile,"%s\n","    J = self.get_value_of_jacobian(i, j)");
    fprintf(pFile,"%s\n","    plt.figure()");
    fprintf(pFile,"%s\n","    plt.show(False)");
    fprintf(pFile,"%s\n","    plt.plot(self.t, J)");
    fprintf(pFile,"%s\n","    if j < self.number_of_states:");
    fprintf(pFile,"%s\n","      plt_name = \"der(\" + self.states[i] + \")/\" + self.states[j]");
    fprintf(pFile,"%s\n","    else:");
    fprintf(pFile,"%s\n","      plt_name = \"der(\" + self.states[i] + \")/\" + self.inputs[j-self.number_of_states]");
    fprintf(pFile,"%s\n","    plt.legend([plt_name])");
    fprintf(pFile,"%s\n","    plt.xlabel('time')");
    fprintf(pFile,"%s\n\n\n","    plt.savefig(filename = filename, format='png')");

    fprintf(pFile,"%s\n","  def plot_jacian_elements_nz(self,i,filename):");
    fprintf(pFile,"%s\n","    for j in xrange(self.number_of_states):");
    fprintf(pFile,"%s\n","      J = self.get_value_of_jacobian(i, j)");
    fprintf(pFile,"%s\n","      if LA.norm(J) > 0:");
    fprintf(pFile,"%s\n","        plt.figure()");
    fprintf(pFile,"%s\n","        plt.plot(self.t, J)");
    fprintf(pFile,"%s\n","        plt_name = \"der(\" + self.states[i] + \")/\" + self.states[j]");
    fprintf(pFile,"%s\n","        plt.legend([plt_name])");
    fprintf(pFile,"%s\n","        plt.xlabel('time')");
    fprintf(pFile,"%s\n","        plt.savefig(filename = \"der_\"+ str(i) +\"_state\"+ str(j) + filename, format='png')\n");
    fprintf(pFile,"%s\n","    for j in xrange(self.number_of_inputs):");
    fprintf(pFile,"%s\n","      J = self.get_value_of_jacobian(i, j + self.number_of_states)");
    fprintf(pFile,"%s\n","      if LA.norm(J) > 0:");
    fprintf(pFile,"%s\n","        plt.figure()");
    fprintf(pFile,"%s\n","        plt.plot(self.t, J)");
    fprintf(pFile,"%s\n","        plt_name = \"der(\" + self.states[i] + \")/\" + self.inputs[j]");
    fprintf(pFile,"%s\n","        plt.legend([plt_name])");
    fprintf(pFile,"%s\n","        plt.xlabel('time')");
    fprintf(pFile,"%s\n\n\n","        plt.savefig(filename = \"der_\"+ str(i) +\"_input\"+ str(j) + filename, format='png')");

    fprintf(pFile,"%s\n","  def compare_plt_jac(self, i, J2, filename):");
    fprintf(pFile,"%s\n","    for j in xrange(self.number_of_states):");
    fprintf(pFile,"%s\n","      J = self.get_value_of_jacobian(i, j)");
    fprintf(pFile,"%s\n","      J_ = J2.get_value_of_jacobian(i, j)");
    fprintf(pFile,"%s\n","      if LA.norm(J-J_)> 0:");
    fprintf(pFile,"%s\n","        plt.figure()");
    fprintf(pFile,"%s\n","        plt.hold(False)");
    fprintf(pFile,"%s\n","        plt.plot(self.t, J,'r', self.t,J_,'k--', linewidth=2.0)");
    fprintf(pFile,"%s\n","        plt_name = \"der(\" + self.states[i] + \")/\" + self.states[j]");
    fprintf(pFile,"%s\n","        plt.legend([plt_name, plt_name + '_'])");
    fprintf(pFile,"%s\n","        plt.xlabel('time')");
    fprintf(pFile,"%s\n","        plt.savefig(filename = \"der_\"+ str(i) +\"_state\"+ str(j) + filename, format='png')\n");
    fprintf(pFile,"%s\n","    for j in xrange(self.number_of_inputs):");
    fprintf(pFile,"%s\n","      J = self.get_value_of_jacobian(i, j+self.number_of_states)");
    fprintf(pFile,"%s\n","      J_ = J2.get_value_of_jacobian(i, j+self.number_of_states)");
    fprintf(pFile,"%s\n","      if LA.norm(J-J_) > 0:");
    fprintf(pFile,"%s\n","        plt.figure()");
    fprintf(pFile,"%s\n","        plt.hold(False)");
    fprintf(pFile,"%s\n","        plt.plot(self.t, J,'r',self.t,J_,'k--',linewidth=2.0)");
    fprintf(pFile,"%s\n","        plt_name = \"der(\" + self.states[i] + \")/\" + self.inputs[j]");
    fprintf(pFile,"%s\n","        plt.legend([plt_name, plt_name + '_'])");
    fprintf(pFile,"%s\n","        plt.xlabel('time')");
    fprintf(pFile,"%s\n\n\n","        plt.savefig(filename = \"der_\"+ str(i) +\"_input\"+ str(j) + filename, format='png')");


    fprintf(pFile,"%s\n","J_ana = OMC_JAC('jac_ana_step_1.csv')");
    fprintf(pFile,"%s\n","#J_ana.plot_jacian_elements_nz(0,'pltJac_ana.png')");
    fprintf(pFile,"%s\n","J_num = OMC_JAC('jac_num_step_1.csv')");
    fprintf(pFile,"%s\n","#J_num.plot_jacian_elements_nz(0,'pltJac_num.png')");
    fprintf(pFile,"%s\n","for i  in xrange(J_ana.number_of_states):");
    fprintf(pFile,"%s\n","  J_ana.compare_plt_jac(i,J_num,'pltJac_compare.png')");


    fclose(pFile);
  }
}

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

static inline void printMaxError(ipnumber *g, const int m, const int nx, const int nJ, long double **t,
    const int np, const int nsi, DATA * data, OptData * optData);


/* eval constraints
 */
Bool evalfG(ipindex n, double * vopt, Bool new_x, int m, ipnumber *g, void * useData){
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
  if(OMC_ACTIVE_STREAM(OMC_LOG_IPOPT_ERROR)){
    const int nJ = optData->dim.nJ;
    printMaxError(g, m, nx, nJ, optData->time.t, np ,nsi ,optData->data, optData);
  }
  return TRUE;
}

/*!
 *  eval derivation of s.t.
 *  author: Vitalij Ruge
 **/
Bool evalfDiffG(ipindex n, double * vopt, Bool new_x, ipindex m, ipindex njac, ipindex *iRow, ipindex *iCol, ipnumber *values, void * useData){
  OptData *optData = (OptData*)useData;

  if(!values){
    generated_jac_struc(optData, iRow, iCol);
#if 0
    {
      const int nsi = optData->dim.nsi;
      int i;
      FILE *pFile;
      char buffer[4096];
      pFile = omc_fopen("jac_struct.m", "wt");
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
    if(optData->ipop.debugeJ){
      int ijac = 0;
      ijac = atoi(optData->ipop.debugeJ);
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


static inline void printMaxError(ipnumber *g, const int m, const int nx, const int nJ,
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
      infoStreamPrint(OMC_LOG_IPOPT_ERROR, 0, "max error is %g for the approximation of the state %s(time = %g)\n",
              gmax, data->modelData->realVarsData[kk].info.name, (double)t[ii][jj]);
    }else if(kk < nJ){
      const int ll = kk - nx + optData->dim.index_con;
      infoStreamPrint(OMC_LOG_IPOPT_ERROR, 0,"max violation is %g for the constraint %s(time = %g)\n",
              gmax, data->modelData->realVarsData[ll].info.name, (double)t[ii][jj]);
    }else{
      const int ll = kk - nx + optData->dim.index_con;
      infoStreamPrint(OMC_LOG_IPOPT_ERROR, 0,"max violation is %g for the final constraint %s(time = %g)\n", gmax, data->modelData->realVarsData[ll].info.name, (double)t[ii][jj]);
    }
  }
}




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

/* static  int jac_struc(Index *iRow, Index *iCol, long int nx, long int nv, int nsi); */
static  int radauJac1(long double *a, long double *J, long double dt, double * values, int nv, int *k, int j,IPOPT_DATA_ *iData);
static  int lobattoJac1(long double *a, long double *J, long double *J0, long double dt, double * values, int nv, int *k, int j, long double tmp,IPOPT_DATA_ *iData);
static  int radauJac2(long double *a, long double *J, long double dt, double * values, int nv, int *k, int j,IPOPT_DATA_ *iData);
static  int lobattoJac2(long double *a, long double *J, long double *J0, long double dt, double * values, int nv, int *k, int j, long double tmp,IPOPT_DATA_ *iData);
static  int radauJac3(long double *a, long double *J, long double dt, double * values, int nv, int *k, int j,IPOPT_DATA_ *iData);
static  int lobattoJac3(long double *a, long double *J, long double *J0, long double dt, double * values, int nv, int *k, int j, long double tmp,IPOPT_DATA_ *iData);
static int jac_struc(IPOPT_DATA_ *iData,int *iRow, int *iCol);
static int conJac(long double *J, double * values, int nv, int *k, int j,IPOPT_DATA_ *iData);

static int diff_functionODE(double *v, int k, IPOPT_DATA_ *iData, long double **J);

/*!
 *  eval derivation of s.t.
 *  author: Vitalij Ruge
 **/
Bool evalfDiffG(Index n, double * x, Bool new_x, Index m, Index njac, Index *iRow, Index *iCol, Number *values, void * useData)
{
  IPOPT_DATA_ *iData;
  iData = (IPOPT_DATA_ *) useData;
  if(values == NULL){
   jac_struc(iData, iRow, iCol);

   /*
    printf("\n m = %i , %i",m ,iData->NRes);
    printf("\nk = %i , %i" ,k ,njac);
    for(i = 0; i< njac; ++i)
      printf("\nJ(%i,%i) = 1; i= %i;",iRow[i]+1, iCol[i]+1,i);

    assert(0);
    */

#if 0
    {
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
    fprintf(pFile, "%i", iData->nsi);
    fprintf(pFile, "%s", "\nH=[];\n");
    fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
    for(i=0; i< njac; ++i){
      sprintf(buffer, "H(%i,%i) = 1;\n", iRow[i]+1, iCol[i]+1);
      fprintf(pFile,"%s", buffer);
    }
    fprintf(pFile, "%s", "%%%%%%%%%%%%%%%%%%%%%%\n");
    fprintf(pFile, "%s", "spy(H)\n");
    }
#endif

  }else{
    int i,j,k,l,ii;
    long double *tmp;
    int id;
    int tmp_index;
    OPTIMIZER_DIM_VARS* dim = &iData->dim;
    int nng = dim->nJ;
    OPTIMIZER_MBASE *mbase = &iData->mbase;
    OPTIMIZER_TIME *dtime = &iData->dtime;
    OPTIMIZER_DF *df = &iData->df;
    iData->helper.i = 0;
    iData->sopt.updateM = !new_x;
    ipoptDebuge(iData,x);

    tmp =  &iData->helper.tmp;

    diff_functionODE(x, 0 , iData, df->J[iData->helper.i]);

    for(i = 0, id = dim->nv, k = 0; i<1; ++i){
      tmp_index = i*dim->deg;
      for(l=0; l<dim->deg; ++l, id += dim->nv){

        ++iData->helper.i;
        diff_functionODE(x+id , tmp_index + l , iData, iData->df.J[iData->helper.i]);

        for(j=0; j<dim->nx; ++j){
          switch(l){
          case 0:
            lobattoJac1(mbase->d[l], df->J[iData->helper.i][j], df->J[i][j], dtime->dt[i], values, dim->nv, &k, j, tmp[l], iData);
            break;
          case 1:
            lobattoJac2(mbase->d[l], df->J[iData->helper.i][j], df->J[i][j], dtime->dt[i], values, dim->nv, &k, j, tmp[l], iData);
            break;
          case 2:
            lobattoJac3(mbase->d[l], df->J[iData->helper.i][j], df->J[i][j], dtime->dt[i], values, dim->nv, &k, j, tmp[l], iData);
            break;
          }
        }
        for(;j<nng; ++j){
          conJac(df->J[iData->helper.i][j], values, dim->nv, &k, j, iData);
        }
      }
    }

    for(; i<dim->nsi; ++i){
      tmp_index = i*iData->dim.deg;
      for(l=0; l<dim->deg; ++l, id += dim->nv){

        ++iData->helper.i;
        diff_functionODE(x+id, tmp_index + l, iData, df->J[iData->helper.i]);

        for(j=0; j<dim->nx; ++j){
          switch(l){
          case 0:
            radauJac1(mbase->a[l], df->J[iData->helper.i][j], dtime->dt[i], values, dim->nv, &k, j, iData);
            break;
          case 1:
            radauJac2(mbase->a[l], df->J[iData->helper.i][j], dtime->dt[i], values, dim->nv, &k, j, iData);
            break;
          case 2:
            radauJac3(mbase->a[l], df->J[iData->helper.i][j], dtime->dt[i], values, dim->nv, &k, j, iData);
            break;
          }
        }
        for(;j<nng; ++j)
          conJac(df->J[iData->helper.i][j], values, dim->nv, &k, j, iData);
      }
    }
     /*assert(k == njac);*/
  }
  return TRUE;
}

/* static  int jac_struc(Index *iRow, Index *iCol, long int nx, long int nv, int nsi) */

/*!
 *  special jacobian struct
 *  author: Vitalij Ruge
 **/
static  int radauJac1(long double *a, long double *J, long double dt, double * values, int nv, int *k, int j,IPOPT_DATA_ *iData)
{
  int l;
  values[(*k)++] = a[0];
  /*1*/
  for(l=0; l<nv; ++l){
    if(iData->sopt.knowedJ[j][l]){
      values[(*k)++] = (j == l) ? dt*J[l] - a[1] : dt*J[l];
    }
  }

  /*2*/
  values[(*k)++] = -a[2];

  /*3*/
  values[(*k)++] = a[3];
  return 0;
}

/*!
 *  special jacobian struct
 *  author: Vitalij Ruge
 **/
static  int lobattoJac1(long double *a, long double *J, long double *J0, long double dt, double * values, int nv, int *k, int j, long double tmp,IPOPT_DATA_ *iData)
{
  int l;
  /*0*/
  for(l = 0; l< nv; ++l)
    if(iData->sopt.knowedJ[j][l])
      values[(*k)++] = (j == l) ? tmp*J0[l] + a[0] : tmp*J0[l];

  /*1*/
  for(l = 0; l< nv; ++l)
    if(iData->sopt.knowedJ[j][l])
      values[(*k)++] = ((j == l)? dt*J[l] - a[1] : dt*J[l]);

  /*2*/
  values[(*k)++] = -a[2];

  /*3*/
  values[(*k)++] = a[3];
  return 0;
}


/*!
 *  special jacobian struct
 *  author: Vitalij Ruge
 **/
static  int radauJac2(long double *a, long double *J, long double dt, double * values, int nv, int *k, int j,IPOPT_DATA_ *iData)
{
  int l;
  /*0*/
  values[(*k)++] = -a[0];

  /*1*/
  values[(*k)++] = a[1];

  /*2*/
  for(l = 0; l< nv; ++l){
    if(iData->sopt.knowedJ[j][l]){
      values[(*k)++] = ((j == l)? dt*J[l] - a[2] : dt*J[l]);
    }
  }

  /*3*/
  values[(*k)++] = -a[3];
  return 0;
}

/*!
 *  special jacobian struct
 *  author: Vitalij Ruge
 **/
static  int lobattoJac2(long double *a, long double *J, long double *J0, long double dt, double * values, int nv, int *k, int j, long double tmp,IPOPT_DATA_ *iData)
{
  int l;
  /*0*/
  for(l = 0; l< nv; ++l)
    if(iData->sopt.knowedJ[j][l])
      values[(*k)++]  = ( j==l)? -(tmp*J0[l] + a[0]) : -tmp*J0[l];
  /*1*/
  values[(*k)++] = a[1];

  /*2*/
  for(l = 0; l< nv; ++l)
    if(iData->sopt.knowedJ[j][l])
      values[(*k)++] = ((j == l)? dt*J[l]-a[2] : dt*J[l]);

  /*3*/
  values[(*k)++] = -a[3];
  return 0;
}

/*!
 *  special jacobian struct
 *  author: Vitalij Ruge
 **/
static  int radauJac3(long double *a, long double *J, long double dt, double * values, int nv, int *k, int j,IPOPT_DATA_ *iData)
{
  int l;
  /*0*/
  values[(*k)++] = a[0];
  /*1*/
  values[(*k)++] = -a[1];
  /*2*/
  values[(*k)++] = a[2];
  /*3*/
  for(l = 0; l< nv; ++l)
    if(iData->sopt.knowedJ[j][l])
      values[(*k)++] = ((j == l)? dt*J[l] - a[3] : dt*J[l]);

  return 0;
}

/*!
 *  special jacobian struct
 *  author: Vitalij Ruge
 **/
static  int lobattoJac3(long double *a, long double *J, long double *J0, long double dt, double * values, int nv, int *k, int j, long double tmp,IPOPT_DATA_ *iData)
{
  int l;
  /*0*/
  for(l=0; l<nv; ++l)
    if(iData->sopt.knowedJ[j][l])
      values[(*k)++] = (j==l) ? tmp*J0[l] + a[0]: tmp*J0[l];

  /*1*/
  values[(*k)++] = -a[1];
  /*2*/
  values[(*k)++] = a[2];
  /*3*/
  for(l=0; l<nv; ++l)
    if(iData->sopt.knowedJ[j][l])
      values[(*k)++] = ((j == l)? dt*J[l] - a[3] : dt*J[l]);

  return 0;
}

static int conJac(long double *J, double *values, int nv, int *k, int j,IPOPT_DATA_ *iData)
{
  int l;
  for(l=0; l<nv; ++l)
    if(iData->sopt.knowedJ[j][l])
      values[(*k)++] = J[l];

  return 0;
}

/*!
 *  special jacobian struct
 *  author: Vitalij Ruge
 **/
static int jac_struc(IPOPT_DATA_ *iData, int *iRow, int *iCol)
{
  int nr, nc, r, c, nv, nsi, nx, nJ, mv, ir, ic;
  int i, j, k=0, l;

  nv  = iData->dim.nv;
  nx  = iData->dim.nx;
  nsi = iData->dim.nsi;
  nJ  = iData->dim.nJ;

  /*=====================================================================================*/
  /*=====================================================================================*/
  
  for(i=0, r = 0, c = nv ; i < 1; ++i){
  /******************************* 1  *****************************/
    for(j=0; j <nx; ++j){
      /* 0 */
      ir = r + j;
      for(l=0; l < nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = ir;
          iCol[k++] = l;
        }
      }
      /* 1 */
      for(l = 0; l <nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = ir;
          iCol[k++] = c + l;
        }
      }

      /* 2 */
      ic = c + j + nv;
      iRow[k] = ir;
      iCol[k++] = ic;

      /* 3 */
      iRow[k] = ir;
      iCol[k++] = ic + nv;
    }

    for(;j<nJ; ++j){
      /*1*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = r + j;
          iCol[k++] = c + l;
        }
      }
    }

  /******************************* 2 *****************************/
    r += nJ;
    c += nv;

    for(j=0; j<nx; ++j){
      ir = r + j;
      /*0*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = ir;
          iCol[k++] = l;
        }
      }

      /*1*/
      ic = c + j;
      iRow[k] = ir;
      iCol[k++] =  ic - nv;

      /*2*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = ir;
          iCol[k++] = c + l;
        }
      }

      /*3*/
       iRow[k] = ir;
       iCol[k++] = ic + nv;
    }

    for(;j<nJ; ++j){
    /*2*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = r + j;
          iCol[k++] = c + l;
        }
      }
    }

  /******************************* 3 *****************************/
    r += nJ;
    c += nv;

    for(j=0; j<nx; ++j){
      ir = r + j;
      /*0*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = ir;
          iCol[k++] = l;
        }
      }

      /*1*/
      ic = c + j;
      iRow[k] = ir;
      iCol[k++] = ic - 2*nv;

      /*2*/
      iRow[k] = ir;
      iCol[k++] = ic - nv;

      /*3*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = ir;
          iCol[k++] = c + l;
        }
      }
    }

    for(;j<nJ; ++j){
        /*3*/
        for(l=0; l<nv; ++l){
          if(iData->sopt.knowedJ[j][l]){
            iRow[k] = r + j;
            iCol[k++] = c + l;
          }
        }
    }
    r += nJ;
    c += nv;
  } /* end i*/

  /*********************************************/
  /*********************************************/
  /*********************************************/

  for(; i<nsi; ++i){
    /*1*/
    for(j=0; j<nx; ++j){
      /*0*/
      iRow[k] = r + j;
      iCol[k++] = c - nv + j;

      /*1*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = r + j;
          iCol[k++] = c + l;
        }
      }

      /*2*/
      iRow[k] = r + j;
      iCol[k++] = c + nv + j;
      /*3*/
      iRow[k] = r + j;
      iCol[k++] = c + 2*nv + j;
    }

    for(;j<nJ; ++j){
        /*1*/
        for(l=0; l<nv; ++l){
          if(iData->sopt.knowedJ[j][l]){
            iRow[k] = r + j;
            iCol[k++] = c + l;
          }
        }
    }

    /*2*/
    r += nJ;
    c += nv;

    for(j=0; j<nx; ++j){
      /*0*/
      iRow[k] = r + j;
      iCol[k++] = c - 2*nv + j;

      /*1*/
      iRow[k] = iRow[k-1];
      iCol[k++] =  c - nv + j;

      /*2*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = iRow[k-1];
          iCol[k++] = c + l;
        }
      }

      /*3*/
       iRow[k] = iRow[k-1];
       iCol[k++] = c + nv + j;
    }
    for(;j<nJ; ++j){
        /*2*/
        for(l=0; l<nv; ++l){
          if(iData->sopt.knowedJ[j][l]){
            iRow[k] = r + j;
            iCol[k++] = c + l;
          }
        }
    }

    /*3*/
    r += nJ;
    c += nv;

    for(j=0; j<nx; ++j){
      /*0*/
      iRow[k] = r + j;
      iCol[k++] = c - 3*nv + j;

      /*1*/
      iRow[k] = iRow[k-1];
      iCol[k++] = c - 2*nv + j;

      /*2*/
      iRow[k] = iRow[k-1];
      iCol[k++] = c - nv + j;

      /*3*/
      for(l=0; l<nv; ++l){
        if(iData->sopt.knowedJ[j][l]){
          iRow[k] = r + j;
          iCol[k++] = c + l;
        }
      }
    }

    for(;j<nJ; ++j){
        /*3*/
        for(l=0; l<nv; ++l){
          if(iData->sopt.knowedJ[j][l]){
            iRow[k] = r + j;
            iCol[k++] = c + l;
          }
        }
    }

    r += nJ;
    c += nv;
  }

    /*
    printf("\n\n%i = %i",iData->njac,k);
    assert(0);
    */


  return 0;
}

/*!
 *  eval a part from the derivate of s.t.
 *  author: Vitalij Ruge
 **/
static int diff_functionODE(double* v, int k, IPOPT_DATA_ *iData, long double **J)
{
  int i, j;
  double *x, *u;
  x = v;
  u = v + iData->dim.nx;

  refreshSimData(x,u,k,iData);
  diff_symColoredODE(v,k,iData,J);

  return 0;
}

/*
 *  function calculates a symbolic colored jacobian matrix by
 *  author: Willi Braun
 */
int diff_symColoredODE(double *v, int k, IPOPT_DATA_ *iData, long double **J)
{
  DATA * data = iData->data;
  const int index = 2;

  int i,j,l,ii,nx;
  int *cC,*lindex;

  nx = data->simulationInfo.analyticJacobians[index].sizeCols;
  cC =  (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols;
  lindex = (int*)data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex;

  for(i = 1; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors + 1; ++i){
    for(ii = 0; ii<nx; ++ii){
      if(cC[ii] == i){
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = iData->scaling.vnom[ii];
      }
    }

    data->callback->functionJacB_column(data);

    for(ii = 0; ii < nx; ii++){
      if(cC[ii] == i){
        if(ii == 0)  j = 0;
        else j = lindex[ii-1];

        for(; j<lindex[ii]; ++j){
          l = data->simulationInfo.analyticJacobians[index].sparsePattern.index[j];
          if(l < iData->dim.nx)
            J[l][ii] = data->simulationInfo.analyticJacobians[index].resultVars[l]*iData->scaling.scalf[l];
          else
            J[l][ii] = data->simulationInfo.analyticJacobians[index].resultVars[l];
        }
      }
    }

    for(ii = 0; ii<nx; ++ii){
      if(cC[ii] == i){
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 0.0;
      }
    }
  }


  return 0;
}


#endif

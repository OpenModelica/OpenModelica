/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2023, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/** \file sundials_util.c
 */

#include "util/omc_error.h"

#include "sundials_util.h"
#include <sunmatrix/sunmatrix_sparse.h>
#include <nvector/nvector_serial.h>


#ifdef WITH_SUNDIALS

#define UNUSED(x) (void)(x)   /* Surpress compiler warnings for unused function input */

/**
 * @brief Set element of sparse Sundials matrix.
 *
 * Jac(row, column) = val.
 *
 * @param row       Row of matrix element.
 * @param column    Column of matrix element.
 * @param nth       Sparsity pattern lead index.
 * @param value     Value to set in position (i,j).
 * @param Jac       Pointer to double array storing matrix.
 * @param nRows     Number of rows of Jacobian matrix, unused.
 */
void setJacElementSundialsSparse(int row, int column, int nth, double value, void* Jac, int nRows)
{
  UNUSED(nRows);   /* Disables compiler warning */

  SUNMatrix A = (SUNMatrix) Jac;
  /* TODO: Remove this check for performance reasons? */
  if (SM_SPARSETYPE_S(A) != CSC_MAT) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "In function setJacElementSundialsSparse: Wrong sparse format "
                     "of SUNMatrix A.");
  }

  if (column > 0 && SM_INDEXPTRS_S(A)[column] == 0) {
    SM_INDEXPTRS_S(A)[column] = nth;
  }
  SM_INDEXVALS_S(A)[nth] = row;
  SM_DATA_S(A)[nth] = value;
}

/**
 * @brief Set Sundials sparse pattern from SimRuntime SPARSE_PATTERN
 *
 * @param jacobian  Jacobian
 * @param Jac       Sundials Matrix
 */
void setSundialsSparsePattern(JACOBIAN* jacobian, SUNMatrix Jac) {
  const SPARSE_PATTERN* sp = jacobian->sparsePattern;
  long int column, row, nz;

  for (column = 0; column < jacobian->sizeCols; column++) {
    for (nz = sp->leadindex[column]; nz < sp->leadindex[column + 1]; nz++) {
      /* set row, col */
      row = sp->index[nz];
      if (column > 0 && SM_INDEXPTRS_S(Jac)[column] == 0) {
        SM_INDEXPTRS_S(Jac)[column] = nz;
      }
      SM_INDEXVALS_S(Jac)[nz] = row;
    }
  }
}

/**
 * @brief             Scaling of a sparse matrix column-wise by a vector
 *
 * @param A           Sparse matrix in CSC. Will be scaled on return.
 * @param vScale      Vector for scaling.
 * @return            Return `SUNMAT_SUCCESS` on success.
 */
int _omc_SUNSparseMatrixVecScaling(SUNMatrix A, N_Vector vScale)
{

  /* should not be called unless A is a sparse matrix in CSC format;
    otherwise return immediately */
  if (SUNMatGetID(A) != SUNMATRIX_SPARSE || SM_SPARSETYPE_S(A) == CSR_MAT) {
    return SUNMAT_ILL_INPUT;
  }

  sunindextype i, j;
  char *matrixtype;
  char *indexname;
  realtype *vScaling = N_VGetArrayPointer(vScale);

  for (j=0; j<SM_NP_S(A); j++) {
    for (i=(SM_INDEXPTRS_S(A))[j]; i<(SM_INDEXPTRS_S(A))[j+1]; i++) {
      (SM_DATA_S(A))[i] = (SM_DATA_S(A))[i]/vScaling[j];
    }
  }

  return SUNMAT_SUCCESS;
}

/**
 * @brief Calculates A+c*I and stores the result in A.
 *
 * TODO: put this into sundials or use another library in the future.
 *
 * @param c     Constant to scale identity matrix I.
 * @param A     Sparse matrix in CSC or CSR format.
 * @return int  Returns SUNMAT_SUCCESS on success
 *              or SUNMAT_MEM_FAIL if failed to allocate memory.
 */
int _omc_SUNMatScaleIAdd_Sparse(realtype c, SUNMatrix A)
{
  sunindextype j, i, p, nz, newvals, M, N, cend, nw;
  booleantype newmat, found;
  sunindextype *w, *Ap, *Ai, *Cp, *Ci;
  realtype *x, *Ax, *Cx;
  SUNMatrix C;

  /* store shortcuts to matrix dimensions (M is inner dimension, N is outer) */
  if (SM_SPARSETYPE_S(A) == CSC_MAT) {
    M = SM_ROWS_S(A);
    N = SM_COLUMNS_S(A);
  }
  else {
    M = SM_COLUMNS_S(A);
    N = SM_ROWS_S(A);
  }

  /* access data arrays from A (return if failure) */
  Ap = Ai = NULL;
  Ax = NULL;
  if (SM_INDEXPTRS_S(A))  Ap = SM_INDEXPTRS_S(A);
  else  return (SUNMAT_MEM_FAIL);
  if (SM_INDEXVALS_S(A))  Ai = SM_INDEXVALS_S(A);
  else  return (SUNMAT_MEM_FAIL);
  if (SM_DATA_S(A))       Ax = SM_DATA_S(A);
  else  return (SUNMAT_MEM_FAIL);


  /* determine if A: contains values on the diagonal (so c*I can just be added in);
     if not, then increment counter for extra storage that should be required. */
  newvals = 0;
  for (j = 0; j < (M < N ? M : N); j++) {
    /* scan column (row if CSR) of A, searching for diagonal value */
    found = SUNFALSE;
    for (i = Ap[j]; i < Ap[j+1]; i++) {
      if (Ai[i] == j) {
        found = SUNTRUE;
        break;
      }
    }
    /* if no diagonal found, increment necessary storage counter */
    if (!found)  newvals += 1;
  }

  /* If extra nonzeros required, check whether matrix has sufficient storage space
     for new nonzero entries  (so c*I can be inserted into existing storage) */
  newmat = SUNFALSE;   /* no reallocation needed */
  if (newvals > (SM_NNZ_S(A) - Ap[N]))
    newmat = SUNTRUE;


  /* perform operation based on existing/necessary structure */

  /*   case 1: A already contains the diagonal */
  if (newvals == 0) {

    /* iterate through diagonal, adding c */
    for (j = 0; j < (M < N ? M : N); j++)
      for (i = Ap[j]; i < Ap[j+1]; i++)
        if (Ai[i] == j) {
          Ax[i] += c;
          break;
        }


  /*   case 2: A has sufficient storage, but does not already contain a diagonal */
  } else if (!newmat) {

    /* create work arrays for nonzero row (column) indices and values in a single column (row) */
    w = (sunindextype *) malloc(M * sizeof(sunindextype));
    x = (realtype *) malloc(M * sizeof(realtype));

    /* determine storage location where last column (row) should end */
    nz = Ap[N] + newvals;

    /* store pointer past last column (row) from original A,
       and store updated value in revised A */
    cend = Ap[N];
    Ap[N] = nz;

    /* iterate through columns (rows) backwards */
    for (j = N-1; j >= 0; j--) {

      /* reset diagonal entry, in case it's not in A */
      x[j] = 0.0;

      /* iterate down column (row) of A, collecting nonzeros */
      for (p = Ap[j], i = 0; p < cend; p++, i++) {
        w[i] = Ai[p];          /* collect index */
        x[Ai[p]] = Ax[p];      /* collect value */
      }

      /* store nnz of this column (row) */
      nw = cend - Ap[j];

      /* add identity to this column (row) */
      if (j < M) {
        x[j] += c;     /* update value */
      }

      /* fill entries of A with this column's (row's) data */
      /* fill entries past diagonal */
      for (i = nw-1; i >= 0 && w[i] > j; i--) {
        Ai[--nz] = w[i];
        Ax[nz] = x[w[i]];
      }
      /* fill diagonal if applicable */
      if (w[i] != j) {
        Ai[--nz] = j;
        Ax[nz] = x[j];
      }
      /* fill entries before diagonal */
      for (; i >= 0; i--) {
        Ai[--nz] = w[i];
        Ax[nz] = x[w[i]];
      }

      /* store ptr past this col (row) from orig A, update value for new A */
      cend = Ap[j];
      Ap[j] = nz;

    }

    /* clean up */
    free(w);
    free(x);


  /*   case 3: A must be reallocated with sufficient storage */
  } else {

    /* create work array for nonzero values in a single column (row) */
    x = (realtype *) malloc(M * sizeof(realtype));

    /* create new matrix for sum */
    C = SUNSparseMatrix(SM_ROWS_S(A), SM_COLUMNS_S(A),
                        Ap[N] + newvals,
                        SM_SPARSETYPE_S(A));

    /* access data from CSR structures (return if failure) */
    Cp = Ci = NULL;
    Cx = NULL;
    if (SM_INDEXPTRS_S(C))  Cp = SM_INDEXPTRS_S(C);
    else  return (SUNMAT_MEM_FAIL);
    if (SM_INDEXVALS_S(C))  Ci = SM_INDEXVALS_S(C);
    else  return (SUNMAT_MEM_FAIL);
    if (SM_DATA_S(C))       Cx = SM_DATA_S(C);
    else  return (SUNMAT_MEM_FAIL);

    /* initialize total nonzero count */
    nz = 0;

    /* iterate through columns (rows for CSR) */
    for (j = 0; j < N; j++) {

      /* set current column (row) pointer to current # nonzeros */
      Cp[j] = nz;

      /* reset diagonal entry, in case it's not in A */
      x[j] = 0.0;

      /* iterate down column (along row) of A, collecting nonzeros */
      for (p = Ap[j]; p < Ap[j+1]; p++) {
        x[Ai[p]] = Ax[p];      /* collect value */
      }

      /* add identity to this column (row) */
      if (j < M) {
        x[j] += c;     /* update value */
      }

      /* fill entries of C with this column's (row's) data */
      /* fill entries before diagonal */
      for (p = Ap[j]; p < Ap[j+1] && Ai[p] < j; p++) {
        Ci[nz] = Ai[p];
        Cx[nz++] = x[Ai[p]];
      }
      /* fill diagonal if applicable */
      if (Ai[p] != j || Ap[j] == Ap[j+1]) {
        Ci[nz] = j;
        Cx[nz++] = x[j];
      }
      /* fill entries past diagonal */
      for (; p < Ap[j+1]; p++) {
        Ci[nz] = Ai[p];
        Cx[nz++] = x[Ai[p]];
      }
    }

    /* indicate end of data */
    Cp[N] = nz;

    /* update A's structure with C's values; nullify C's pointers */
    SM_NNZ_S(A) = SM_NNZ_S(C);

    if (SM_DATA_S(A))
      free(SM_DATA_S(A));
    SM_DATA_S(A) = SM_DATA_S(C);
    SM_DATA_S(C) = NULL;

    if (SM_INDEXVALS_S(A))
      free(SM_INDEXVALS_S(A));
    SM_INDEXVALS_S(A) = SM_INDEXVALS_S(C);
    SM_INDEXVALS_S(C) = NULL;

    if (SM_INDEXPTRS_S(A))
      free(SM_INDEXPTRS_S(A));
    SM_INDEXPTRS_S(A) = SM_INDEXPTRS_S(C);
    SM_INDEXPTRS_S(C) = NULL;

    /* clean up */
    SUNMatDestroy_Sparse(C);
    free(x);

  }
  return SUNMAT_SUCCESS;

}

#endif /* WITH_SUNDIALS */

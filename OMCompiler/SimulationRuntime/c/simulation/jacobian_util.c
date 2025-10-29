/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2019, Open Source Modelica Consortium (OSMC),
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

/*! File jac_util.c
 */

#include "jacobian_util.h"
#include "options.h"
#include "../util/omc_file.h"

/**
 * @brief Initialize analytic jacobian.
 *
 * Jacobian has to be allocatd already.
 *
 * @param jacobian                  Jacobian to initialized.
 * @param sizeCols                  Number of columns of Jacobian
 * @param sizeRows                  Number of rows of Jacobian
 * @param sizeTmpVars               Size of tmp vars array.
 * @param constantEqns              Function pointer for constant equations of Jacobian.
 *                                  NULL if not available.
 * @param sparsePattern             Pointer to sparsity pattern of Jacobian.
 */
void initJacobian(JACOBIAN* jacobian, unsigned int sizeCols, unsigned int sizeRows, unsigned int sizeTmpVars, jacobianColumn_func_ptr evalColumn, jacobianColumn_func_ptr constantEqns, SPARSE_PATTERN* sparsePattern)
{
  jacobian->sizeCols = sizeCols;
  jacobian->sizeRows = sizeRows;
  jacobian->sizeTmpVars = sizeTmpVars;
  jacobian->seedVars = (modelica_real*) calloc(sizeCols, sizeof(modelica_real));
  jacobian->resultVars = (modelica_real*) calloc(sizeRows, sizeof(modelica_real));
  jacobian->tmpVars = (modelica_real*) calloc(sizeTmpVars, sizeof(modelica_real));
  jacobian->evalColumn = evalColumn;
  jacobian->constantEqns = constantEqns;
  jacobian->sparsePattern = sparsePattern;
  jacobian->availability = JACOBIAN_UNKNOWN;
  jacobian->dae_cj = 0;
}

/**
 * @brief Copy analytic Jacobian.
 *
 * Sparsity pattern is not copied, only the pointer to it.
 *
 * @param source                  Jacobian that should be copied.
 * @return JACOBIAN*              Copy of source.
 */
JACOBIAN* copyJacobian(JACOBIAN* source)
{
  JACOBIAN* jacobian = (JACOBIAN*) malloc(sizeof(JACOBIAN));
  initJacobian(jacobian,
    source->sizeCols,
    source->sizeRows,
    source->sizeTmpVars,
    source->evalColumn,
    source->constantEqns,
    source->sparsePattern);

  return jacobian;
}

/**
 * @brief Free memory of analytic Jacobian.
 *
 * Also frees sparse pattern.
 *
 * @param jac   Pointer to Jacobian.
 */
void freeJacobian(JACOBIAN *jac)
{
  if (jac == NULL) {
    return;
  }
  free(jac->seedVars); jac->seedVars = NULL;
  free(jac->tmpVars); jac->tmpVars = NULL;
  free(jac->resultVars); jac->resultVars = NULL;
  freeSparsePattern(jac->sparsePattern);
  free(jac->sparsePattern); jac->sparsePattern = NULL;
}

/*! \fn evalJacobian
 *
 *  compute entries of Jacobian in sparse CSC or dense format
 *  uses coloring (sparsePattern non NULL)
 *
 *  \param [ref] [data]
 *  \param [ref] [threadData]
 *  \param [ref] [jacobian]        Pointer to Jacobian
 *  \param [ref] [parentJacobian]  Pointer to parent Jacobian
 *  \param [out] [jac]             Output buffer, size nnz (sparse) or #rows * #cols (dense), non zero-initialized
 *  \param [ref] [isDense]         Flag to set dense / sparse output
 */
void evalJacobian(DATA* data, threadData_t *threadData, JACOBIAN* jacobian, JACOBIAN* parentJacobian, modelica_real* jac, modelica_boolean isDense)
{
  int color, column, row, nz;
  const SPARSE_PATTERN* sp = jacobian->sparsePattern;
  int sizeDirection = jacobian->isRowEval ? jacobian->sizeRows : jacobian->sizeCols;


  /* evaluate constant equations of Jacobian */
  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, parentJacobian);
  }

  if (isDense) {
    /* memset to zero for dense, since solvers might destroy "hard zeros"
     * does not apply for sparse, since the values are overwritten */
    memset(jac, 0.0, jacobian->sizeRows * jacobian->sizeCols * sizeof(modelica_real));
  }

  /* evaluate Jacobian */
  for (color = 0; color < sp->maxColors; color++) {
    /* activate seed variable for the corresponding color */
    // direction = 0; direction < sizeDirection; direction++
    for (column = 0; column < jacobian->sizeCols; column++)
      if (sp->colorCols[column]-1 == color)
        jacobian->seedVars[column] = 1.0;

    /* evaluate Jacobian column */
    jacobian->evalColumn(data, threadData, jacobian, parentJacobian);

    for (column = 0; column < jacobian->sizeCols; column++) {
      if (sp->colorCols[column]-1 == color) {
        for (nz = sp->leadindex[column]; nz < sp->leadindex[column+1]; nz++) {
          row = sp->index[nz];
          if (!isDense) {
            /* sparse case */
            jac[nz] = jacobian->resultVars[row]; //* solverData->xScaling[j];
          }
          else {
            /* dense case */
            jac[column * jacobian->sizeRows + row] = jacobian->resultVars[row]; //* solverData->xScaling[j];
          }
        }
        /* de-activate seed variable for the corresponding color */
        jacobian->seedVars[column] = 0.0;
      }
    }
  }
}


/**
 * @brief Compute Jacobian-vector product y = J * s without forming J explicitly.
 *
 * Uses the sparsity coloring to activate multiple independent seed directions at once.
 * Assumes column-wise evaluation (seedVars has length sizeCols, resultVars has length sizeRows).
 *
 * @param data            Runtime data struct.
 * @param threadData      Thread data for error handling.
 * @param jacobian        Jacobian object (must have evalColumn and sparsePattern set).
 * @param parentJacobian  Parent Jacobian (if nested), can be NULL.
 * @param seed            Input seed vector s, length = jacobian->sizeCols.
 * @param out             Output vector y, length = jacobian->sizeRows.
 * @param zero_out        If true, zero-initialize out before accumulation.
 */
void jvp(DATA* data, threadData_t *threadData,
         JACOBIAN* jacobian, JACOBIAN* parentJacobian,
         const modelica_real* seed, modelica_real* out,
         modelica_boolean zero_out)
{
  const SPARSE_PATTERN* sp = jacobian->sparsePattern;
  const unsigned int nCols = jacobian->sizeCols;
  const unsigned int nRows = jacobian->sizeRows;

  /* Optional: zero output before accumulation */
  if (zero_out) {
    memset(out, 0, nRows * sizeof(modelica_real));
  }

  /* Ensure seeds are zeroed before use */
  memset(jacobian->seedVars, 0, nCols * sizeof(modelica_real));

  /* Evaluate constant equations (if any) */
  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, parentJacobian);
  }

  /* Temporary bitmap for touched rows (to avoid O(nRows) accumulation) */
  unsigned char* touched = (unsigned char*) calloc(nRows, sizeof(unsigned char));

  /* Process one color group at a time */
  for (unsigned int color = 0; color < sp->maxColors; color++) {
    int anyActive = 0;

    /* Activate seeds for this color and mark touched rows */
    for (unsigned int col = 0; col < nCols; col++) {
      if (sp->colorCols[col] - 1 == color) {
        const modelica_real s = seed[col];
        if (s != 0.0) {
          jacobian->seedVars[col] = s;
          anyActive = 1;

          /* Mark rows affected by this column via the sparsity pattern */
          for (unsigned int nz = sp->leadindex[col]; nz < sp->leadindex[col+1]; nz++) {
            const unsigned int row = sp->index[nz];
            touched[row] = 1;
          }
        }
      }
    }

    /* Skip if no non-zero seeds in this color */
    if (!anyActive) {
      continue;
    }

    /* Evaluate J * s_color into resultVars */
    jacobian->evalColumn(data, threadData, jacobian, parentJacobian);

    /* Accumulate only touched rows */
    for (unsigned int row = 0; row < nRows; row++) {
      if (touched[row]) {
        out[row] += jacobian->resultVars[row];
        touched[row] = 0; /* reset for next color */
      }
    }

    /* Deactivate seeds of this color */
    for (unsigned int col = 0; col < nCols; col++) {
      if (sp->colorCols[col] - 1 == color) {
        jacobian->seedVars[col] = 0.0;
      }
    }
  }

  free(touched);
}

/**
 * @brief Allocate memory for sparsity pattern.
 *
 * @param n_leadIndex         Number of rows or columns of Matrix.
 *                            Depending on compression type CSR (-->rows) or CSC (-->columns).
 * @param numberOfNonZeros    Number of non-zero elements in Matrix.
 * @param maxColors           Maximum number of colors of Matrix.
 * @return SPARSE_PATTERN*    Pointer to allocated sparsity pattern of Matrix.
 */
SPARSE_PATTERN* allocSparsePattern(unsigned int n_leadIndex, unsigned int numberOfNonZeros, unsigned int maxColors)
{
  SPARSE_PATTERN* sparsePattern = (SPARSE_PATTERN*) malloc(sizeof(SPARSE_PATTERN));
  sparsePattern->leadindex = (unsigned int*) malloc((n_leadIndex+1)*sizeof(unsigned int));
  sparsePattern->index = (unsigned int*) malloc(numberOfNonZeros*sizeof(unsigned int));
  sparsePattern->sizeofIndex = numberOfNonZeros;
  sparsePattern->numberOfNonZeros = numberOfNonZeros;
  sparsePattern->colorCols = (unsigned int*) malloc(n_leadIndex*sizeof(unsigned int));
  sparsePattern->maxColors = maxColors;

  return sparsePattern;
}


/**
 * @brief Convert a CSC-format sparsity pattern to CSR-format.
 *
 * Input CSC (A):
 *   - Ap = csc->leadindex (size nCols+1), column pointers
 *   - Ai = csc->index     (size nnz),      row indices
 *
 * Output CSR (B):
 *   - Bp = csr->leadindex (size nRows+1), row pointers
 *   - Bj = csr->index     (size nnz),     column indices
 *
 * Complexity: O(nnz + max(nRows, nCols))
 */
SPARSE_PATTERN* csc_to_csr(const SPARSE_PATTERN* csc,
                           unsigned int nRows,
                           unsigned int nCols)
{
  if (!csc) return NULL;

  const unsigned int nnz = csc->sizeofIndex; /* == csc->numberOfNonZeros */

  /* Allocate CSR pattern: leadindex size = nRows+1, index size = nnz */
  SPARSE_PATTERN* csr = allocSparsePattern(nRows, nnz, /*maxColors*/ 0);
  if (!csr) return NULL;

  /* Aliases for clarity */
  const unsigned int* Ap = csc->leadindex; /* col pointer (CSC) */
  const unsigned int* Ai = csc->index;     /* row indices (CSC) */
  unsigned int* Bp = csr->leadindex;       /* row pointer (CSR) */
  unsigned int* Bj = csr->index;           /* col indices (CSR) */

  /* 1) Count nnz per row (Bp[0..nRows-1]) */
  memset(Bp, 0, (nRows+1) * sizeof(unsigned int));
  for (unsigned int k = 0; k < nnz; k++) {
    const unsigned int row = Ai[k];
    if (row >= nRows) {
      /* Out of bounds. Clean up and abort. */
      freeSparsePattern(csr);
      free(csr);
      return NULL;
    }
    Bp[row]++;
  }

  /* 2) Exclusive prefix sum over Bp to get row pointers; set Bp[nRows] = nnz */
  {
    unsigned int cumsum = 0;
    for (unsigned int r = 0; r < nRows; r++) {
      const unsigned int tmp = Bp[r];
      Bp[r] = cumsum;
      cumsum += tmp;
    }
    Bp[nRows] = nnz;
  }

  /* 3) Fill CSR column indices Bj using running heads in Bp */
  for (unsigned int col = 0; col < nCols; col++) {
    const unsigned int start = Ap[col];
    const unsigned int stop  = Ap[col + 1];
    if (stop < start || stop > nnz) {
      /* Corrupt CSC pointers. Clean up and abort. */
      freeSparsePattern(csr);
      free(csr);
      return NULL;
    }
    for (unsigned int jj = start; jj < stop; jj++) {
      const unsigned int row = Ai[jj];
      const unsigned int dest = Bp[row]; /* next free slot in this row */
      Bj[dest] = col;
      Bp[row]++; /* advance head */
    }
  }

  /* 4) Restore Bp to row pointers by shifting heads back */
  {
    unsigned int last = 0;
    for (unsigned int r = 0; r <= nRows; r++) {
      const unsigned int tmp = Bp[r];
      Bp[r] = last;
      last = tmp;
    }
  }

  /* We don't have row coloring here; keep defaults (zeros). */
  csr->maxColors = 0;
  /* numberOfNonZeros/sizeofIndex were set by allocSparsePattern */

  return csr;
}


/**
 * @brief Free sparsity pattern
 *
 * @param spp   Pointer to sparsity pattern
 */
void freeSparsePattern(SPARSE_PATTERN *spp)
{
  if (spp != NULL) {
    free(spp->index); spp->index = NULL;
    free(spp->colorCols); spp->colorCols = NULL;
    free(spp->leadindex); spp->leadindex = NULL;
  }
}

/**
 * @brief Opens sparsity pattern file
 *
 * @param data        Runtime data struct.
 * @param threadData  Thread data for error handling.
 * @param filename    String for the filename.
 * @return FILE*      Pointer to sparsity pattern stream.
 */
FILE * openSparsePatternFile(DATA* data, threadData_t *threadData, const char* filename)
{
  FILE* pFile;
  const char* fullPath = NULL;

  if (omc_flag[FLAG_INPUT_PATH]) {
    GC_asprintf(&fullPath, "%s/%s", omc_flagValue[FLAG_INPUT_PATH], filename);
  } else if (data->modelData->resourcesDir) {
    GC_asprintf(&fullPath, "%s/%s", data->modelData->resourcesDir, filename);
  } else {
    GC_asprintf(&fullPath, "%s", filename);
  }
  pFile = omc_fopen(fullPath, "rb");
  if (pFile == NULL) {
    throwStreamPrint(threadData, "Could not open sparsity pattern file %s.", fullPath);
  }
  return pFile;
}

/**
 * @brief Reads one color of sparsity pattern and sets colorCols.
 *
 * @param threadData    Used for error handling.
 * @param pFile         Pointer to file stream.
 * @param colorCols     Array of column coloring.
 * @param color         Current color index.
 * @param length        Number of columns in color `color`.
 */
void readSparsePatternColor(threadData_t* threadData, FILE * pFile, unsigned int* colorCols, unsigned int color, unsigned int length, unsigned int maxIndex)
{
  unsigned int i, index;
  size_t count;

  for (i = 0; i < length; i++) {
    count = omc_fread(&index, sizeof(unsigned int), 1, pFile, FALSE);
    if (count != 1) {
      throwStreamPrint(threadData, "Error while reading color %u of sparsity pattern.", color);
    }
    if (index < 0 || index >= maxIndex) {
      throwStreamPrint(threadData, "Error while reading color %u of sparsity pattern. Index %d out of bounds", color, index);
    }
    colorCols[index] = color;
  }
}

/**
 * @brief Set Jacobian method from user flag and available Jacobian.
 *
 * @param threadData              Used for error handling.
 * @param availability            Is the Jacobian available, only the sparsity pattern available or nothing available.
 * @param flagValue               Flag value of FLAG_JACOBIAN. Can be NULL.
 * @return JACOBIAN_METHOD   Returns jacobian method that is availble.
 */
JACOBIAN_METHOD setJacobianMethod(threadData_t* threadData, JACOBIAN_AVAILABILITY availability, const char* flagValue)
{
  JACOBIAN_METHOD jacobianMethod = JAC_UNKNOWN;
  assertStreamPrint(threadData, availability != JACOBIAN_UNKNOWN, "Jacobian availability status is unknown.");

  /* if FLAG_JACOBIAN is set, choose jacobian calculation method */
  if (flagValue) {
    for (int method=1; method < JAC_MAX; method++) {
      if (!strcmp(flagValue, JACOBIAN_METHOD_NAME[method])) {
        jacobianMethod = (JACOBIAN_METHOD) method;
        break;
      }
    }
    // Error case
    if (jacobianMethod == JAC_UNKNOWN) {
      errorStreamPrint(OMC_LOG_STDOUT, 0, "Unknown value `%s` for flag `-jacobian`", flagValue);
      infoStreamPrint(OMC_LOG_STDOUT, 1, "Available options are");
      for (int method=1; method < JAC_MAX; method++) {
        infoStreamPrint(OMC_LOG_STDOUT, 0, "%s", JACOBIAN_METHOD_NAME[method]);
      }
      messageClose(OMC_LOG_STDOUT);
      omc_throw(threadData);
    }
  }

  /* Check if method is available */
  switch (availability)
  {
  case JACOBIAN_NOT_AVAILABLE:
    if (jacobianMethod != INTERNALNUMJAC && jacobianMethod != JAC_UNKNOWN) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Jacobian not available, switching to internal numerical Jacobian.");
    }
    jacobianMethod = INTERNALNUMJAC;
    break;
  case JACOBIAN_ONLY_SPARSITY:
    if (jacobianMethod == COLOREDSYMJAC) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Symbolic Jacobian not available, only sparsity pattern. Switching to colored numerical Jacobian.");
      jacobianMethod = COLOREDNUMJAC;
    } else if(jacobianMethod == SYMJAC) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Symbolic Jacobian not available, only sparsity pattern. Switching to numerical Jacobian.");
      jacobianMethod = NUMJAC;
    } else if(jacobianMethod == JAC_UNKNOWN) {
      jacobianMethod = COLOREDNUMJAC;
    }
    break;
  case JACOBIAN_AVAILABLE:
    if (jacobianMethod == JAC_UNKNOWN) {
      jacobianMethod = COLOREDSYMJAC;
    }
    break;
  default:
    throwStreamPrint(threadData, "Unhandled case in setJacobianMethod");
    break;
  }

  /* Log Jacobian method */
  switch (jacobianMethod)
  {
  case INTERNALNUMJAC:
    infoStreamPrint(OMC_LOG_JAC, 0, "Using Jacobian method: Internal numerical Jacobian.");
    break;
  case NUMJAC:
    infoStreamPrint(OMC_LOG_JAC, 0, "Using Jacobian method: Numerical Jacobian.");
    break;
  case COLOREDNUMJAC:
    infoStreamPrint(OMC_LOG_JAC, 0, "Using Jacobian method: Colored numerical Jacobian.");
    break;
  case SYMJAC:
    infoStreamPrint(OMC_LOG_JAC, 0, "Using Jacobian method: Symbolical Jacobian.");
    break;
  case COLOREDSYMJAC:
    infoStreamPrint(OMC_LOG_JAC, 0, "Using Jacobian method: Colored symbolical Jacobian.");
    break;
  default:
    throwStreamPrint(threadData, "Unhandled case in setJacobianMethod");
    break;
  }
  return jacobianMethod;
}

void freeNonlinearPattern(NONLINEAR_PATTERN *nlp)
{
  if (nlp != NULL) {
    free(nlp->indexVar); nlp->indexVar = NULL;
    free(nlp->indexEqn); nlp->indexEqn = NULL;
    free(nlp->columns);  nlp->columns = NULL;
    free(nlp->rows);     nlp->rows = NULL;
  }
}

unsigned int* getNonlinearPatternCol(NONLINEAR_PATTERN *nlp, int var_idx)
{
  unsigned int idx_start = nlp->indexVar[var_idx];
  unsigned int idx_stop;
  if (var_idx == nlp->numberOfVars) {
    idx_stop = nlp->numberOfNonlinear;
  } else {
    idx_stop = nlp->indexVar[var_idx + 1];
  }

  unsigned int* col = (unsigned int*) malloc((idx_stop - idx_start + 1)*sizeof(unsigned int));

  int index = 0;
  for (int i = idx_start; i < idx_stop + 1; i++) {
    col[index] = nlp->columns[i];
    index++;
  }

  //for(int j = 0; j < nlp->numberOfNonlinear; j++)
  //  printf("nlp->columns[%d] = %d\n", j, nlp->columns[j]);
  //for(int j = 0; j < nlp->numberOfVars+1; j++)
  //  printf("nlp->indexVar[%d] = %d\n", j, nlp->indexVar[j]);

  return col;
}

unsigned int* getNonlinearPatternRow(NONLINEAR_PATTERN *nlp, int eqn_idx)
{
  unsigned int idx_start = nlp->indexEqn[eqn_idx];
  unsigned int idx_stop;
  if (eqn_idx == nlp->numberOfEqns) {
    idx_stop = nlp->numberOfNonlinear;
  } else {
    idx_stop = nlp->indexEqn[eqn_idx + 1];
  }
  //printf("   eqn_idx   = %d\n", eqn_idx);
  //printf("   idx_start = %d\n", idx_start);
  //printf("   idx_stop  = %d\n", idx_stop);
  unsigned int* row = (unsigned int*) malloc((idx_stop - idx_start + 1)*sizeof(unsigned int));

  int index = 0;
  for (int i = idx_start; i < idx_stop + 1; i++) {
    row[index] = nlp->rows[i];
    //printf("      row[index] = row[%d] = %d\n", index, row[index]);
    index++;
  }

  //for(int j = 0; j < nlp->numberOfNonlinear; j++)
  //  printf("nlp->rows[%d] = %d\n", j, nlp->rows[j]);
  //for(int j = 0; j < nlp->numberOfEqns; j++)
  //  printf("nlp->indexEqn[%d] = %d\n", j, nlp->indexEqn[j]);

  return row;
}


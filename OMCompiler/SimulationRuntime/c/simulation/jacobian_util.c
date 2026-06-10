/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/*! File jac_util.c
 */

#include "jacobian_util.h"
#include "options.h"
#include "../util/omc_file.h"
#include "eval_dep.h"

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
void initJacobian(JACOBIAN* jacobian, unsigned int sizeCols, unsigned int sizeRows, unsigned int sizeTmpVars, EVAL_DAG* dag, jacobianColumn_func_ptr evalColumn, jacobianColumn_func_ptr constantEqns, SPARSE_PATTERN* sparsePattern)
{
  jacobian->sizeCols = sizeCols;
  jacobian->sizeRows = sizeRows;
  jacobian->sizeTmpVars = sizeTmpVars;
  jacobian->seedVars = (modelica_real*) calloc(sizeCols, sizeof(modelica_real));
  jacobian->resultVars = (modelica_real*) calloc(sizeRows, sizeof(modelica_real));
  jacobian->tmpVars = (modelica_real*) calloc(sizeTmpVars, sizeof(modelica_real));
  jacobian->dag = dag;
  jacobian->evalSelection = NULL;
  jacobian->evalColumn = evalColumn;
  jacobian->constantEqns = constantEqns;
  jacobian->sparsePattern = sparsePattern;
  jacobian->availability = JACOBIAN_UNKNOWN;
  jacobian->dae_cj = 0;
  jacobian->isRowEval = FALSE;
  jacobian->isBidirectional = FALSE;
  jacobian->adjointJacobian = NULL;
  jacobian->recoverMask = NULL;
  jacobian->csrToCscMap = NULL;
}

/**
 * @brief Copy analytic Jacobian.
 *
 * Sparsity pattern and DAG are not copied, only their pointers.
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
    source->dag,
    source->evalColumn,
    source->constantEqns,
    source->sparsePattern);

  jacobian->isBidirectional = source->isBidirectional;
  jacobian->adjointJacobian = source->adjointJacobian;  /* shared pointer, not deep copy */
  jacobian->recoverMask = source->recoverMask;           /* shared pointer, not deep copy */
  jacobian->csrToCscMap = source->csrToCscMap;           /* shared pointer, not deep copy */

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
  if (jac) {
    free(jac->seedVars); jac->seedVars = NULL;
    free(jac->tmpVars); jac->tmpVars = NULL;
    free(jac->resultVars); jac->resultVars = NULL;
    freeSparsePattern(jac->sparsePattern);
    free(jac->sparsePattern); jac->sparsePattern = NULL;
    freeEvalDAG(jac->dag); jac->dag = NULL;
    freeEvalSelection(jac->evalSelection); jac->evalSelection = NULL;
    free(jac->recoverMask); jac->recoverMask = NULL;
    free(jac->csrToCscMap); jac->csrToCscMap = NULL;
    /* adjointJacobian is not owned; do not free */
    jac->adjointJacobian = NULL;
  }
}

/**
 * @brief Free memory of analytic Jacobian.
 *
 * Does not free sparsity pattern and DAG.
 * Call this for Jacobians that were copied from another Jacobian.
 *
 * @param jac   Pointer to Jacobian.
 */
void freeJacobianCopy(JACOBIAN *jac)
{
  if (jac) {
    free(jac->seedVars);
    free(jac->tmpVars);
    free(jac->resultVars);
    freeEvalSelection(jac->evalSelection);
    free(jac);
  }
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

  /* Dispatch to bidirectional evaluation if applicable */
  if (jacobian->isBidirectional && jacobian->adjointJacobian) {
    evalJacobianBidirectional(data, threadData, jacobian, parentJacobian, jac, isDense);
    return;
  }

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
            /* dense case (row major layout for csc format) */
            jac[column * jacobian->sizeRows + row] = jacobian->resultVars[row]; //* solverData->xScaling[j];
          }
        }
        /* de-activate seed variable for the corresponding color */
        jacobian->seedVars[column] = 0.0;
      }
    }
  }
}

/*!
 * \brief Row-wise Jacobian evaluation.
 *
 * Assumptions:
 *  - jacobian->evalColumn evaluates a row-direction seed (i.e., is a row evaluator)
 *  - sparsePattern is in CSR format:
 *      leadindex: sizeRows + 1 (row pointers)
 *      index:     nnz (column indices)
 *  - colorCols encodes row coloring (1-based color ids)
 *
 * Output:
 *  - If isDense == false: jac is nnz-sized buffer aligned with CSR index order.
 *  - If isDense == true:  jac is dense column-major buffer of size sizeRows*sizeCols
 *                         with J(row, col) stored at jac[col*sizeRows + row].
 */
void evalJacobianRow(DATA* data, threadData_t *threadData,
                     JACOBIAN* jacobian, JACOBIAN* parentJacobian,
                     modelica_real* jac, modelica_boolean isDense)
{
  int color, row, col, nz;
  const SPARSE_PATTERN* sp = jacobian->sparsePattern;
  const unsigned int nRows = jacobian->sizeRows;
  const unsigned int nCols = jacobian->sizeCols;

  if (!jacobian->isRowEval) {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "cant perform row-wise evaluation on column-evaluation Jacobian\n");
    return;
  }

  /* evaluate constant equations of Jacobian (if any) */
  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, parentJacobian);
  }

  /* memset to zero for dense, since solvers might destroy "hard zeros" */
  if (isDense) {
    memset(jac, 0, nRows * nCols * sizeof(modelica_real));
  }

  /* Ensure seeds are zeroed before use (row seeds) */
  memset(jacobian->seedVars, 0, nRows * sizeof(modelica_real));

  /* evaluate Jacobian row-wise using row-coloring */
  for (color = 0; color < (int)sp->maxColors; color++) {
    /* activate seed variable(s) for the corresponding color (rows) */
    for (row = 0; row < (int)nRows; row++) {
      if ((int)sp->colorCols[row] - 1 == color) {
        jacobian->seedVars[row] = 1.0;
      }
    }

    /* evaluate all active rows at once (evalColumn acts as evalRow here) */
    jacobian->evalColumn(data, threadData, jacobian, parentJacobian);

    /* scatter results */
    for (row = 0; row < (int)nRows; row++) {
      if ((int)sp->colorCols[row] - 1 == color) {
        for (nz = sp->leadindex[row]; nz < (int)sp->leadindex[row + 1]; nz++) {
          col = sp->index[nz];
          if (!isDense) {
            /* sparse case (CSR value buffer aligned with index order) */
            jac[nz] = jacobian->resultVars[col];
          } else {
            /* dense case (row-major layout for csr format) */
            jac[row * nCols + col] = jacobian->resultVars[col];
          }
        }
        /* de-activate seed variable for the corresponding color (row) */
        jacobian->seedVars[row] = 0.0;
      }
    }
  }
}

/**
 * @brief Initialize bidirectional recovery masks for star bicoloring.
 *
 * For each nonzero in forward (CSC) and adjoint (CSR) patterns, determines
 * whether the entry is recoverable from the respective direction.
 * Also computes CSR-to-CSC index mapping for sparse output.
 *
 * Must be called after both jacobians are fully initialized (patterns + colors)
 * and linked (fwd->adjointJacobian != NULL).
 *
 * @param fwd   Forward jacobian with CSC pattern + column coloring.
 */
void initBidirectionalRecovery(JACOBIAN* fwd)
{
  JACOBIAN* adj = fwd->adjointJacobian;
  if (!adj) return;

  const SPARSE_PATTERN* fwdsp = fwd->sparsePattern;
  const SPARSE_PATTERN* adjsp = adj->sparsePattern;
  const unsigned int nCols = fwd->sizeCols;
  const unsigned int nRows = fwd->sizeRows;
  const unsigned int nnz = fwdsp->nnz;
  unsigned int j, i, nz, k, j2, i2;

  fwd->recoverMask = (unsigned char*) calloc(nnz, sizeof(unsigned char));
  adj->recoverMask = (unsigned char*) calloc(nnz, sizeof(unsigned char));
  adj->csrToCscMap = (unsigned int*) malloc(nnz * sizeof(unsigned int));

  /* Forward recoverMask: entry (i,j) is column-recoverable if j is the ONLY
   * column with its column color among all columns having a nonzero in row i. */
  // iterate over all columns
  for (j = 0; j < nCols; j++) {
    unsigned int cj = fwdsp->colorCols[j];
    // iterate over nonzeros (rows with nonzero) in this column via forward CSC pattern
    for (nz = fwdsp->leadindex[j]; nz < fwdsp->leadindex[j+1]; nz++) {
      i = fwdsp->index[nz]; // row index of current nonzero
      int unique = 1; // assume current column is unique for this nonzero until we find otherwise
      // check all other columns with nonzero in the same row i via adjoint CSR pattern
      for (k = adjsp->leadindex[i]; k < adjsp->leadindex[i+1]; k++) {
        j2 = adjsp->index[k]; // column index of nonzero in same row
        // check its a different column and has the same color, if so current column is not unique for this nonzero
        if (j2 != j && fwdsp->colorCols[j2] == cj) {
          unique = 0;
          break;
        }
      }
      // mark as unique (column-recoverable) or not
      // if unique, this nonzero can be recovered from forward evaluation when column j is seeded, otherwise it cannot and must be recovered from adjoint evaluation
      // if not unique, it gives a wrong value when recovered from forward evaluation and thus can not be written into result vector
      fwd->recoverMask[nz] = (unsigned char)unique;
    }
  }

  /* Adjoint recoverMask: entry (i,j) is row-recoverable if i is the ONLY
   * row with its row color among all rows having a nonzero in column j. */
  // same logic as forward, but now iterate over rows and check uniqueness of row color among rows with nonzero in same column via forward pattern
  for (i = 0; i < nRows; i++) {
    unsigned int ri = adjsp->colorCols[i];
    for (nz = adjsp->leadindex[i]; nz < adjsp->leadindex[i+1]; nz++) {
      j = adjsp->index[nz];
      int unique = 1;
      for (k = fwdsp->leadindex[j]; k < fwdsp->leadindex[j+1]; k++) {
        i2 = fwdsp->index[k];
        if (i2 != i && adjsp->colorCols[i2] == ri) {
          unique = 0;
          break;
        }
      }
      adj->recoverMask[nz] = (unsigned char)unique;
    }
  }

  /* CSR-to-CSC mapping: for each adjoint CSR position (nonzero), find forward CSC position */
  // iterate over all rows
  for (i = 0; i < nRows; i++) {
    // iterate over all nonzeros in this row via adjoint CSR pattern
    for (nz = adjsp->leadindex[i]; nz < adjsp->leadindex[i+1]; nz++) {
      j = adjsp->index[nz]; // get column index of current nonzero
      adj->csrToCscMap[nz] = 0;
      // iterate over all nonzeros in this column via forward CSC pattern, so the nonzero rows
      for (k = fwdsp->leadindex[j]; k < fwdsp->leadindex[j+1]; k++) {
        // if row index matches, we found the same nonzero in forward pattern
        // and can record its position k for later indexing into forward result vector when recovering this nonzero from adjoint evaluation
        if (fwdsp->index[k] == i) {
          adj->csrToCscMap[nz] = k;
          break;
        }
      }
    }
  }
}

/**
 * @brief Evaluate Jacobian using bidirectional (star bicoloring) approach.
 *
 * Uses both forward (column) and adjoint (row) evaluations to recover all
 * nonzero entries with fewer total colors than unidirectional coloring.
 *
 * Dense output: column-major jac[col * nRows + row].
 * Sparse output: CSC-indexed jac[nz] matching forward sparse pattern.
 *
 * @param data            Runtime data struct.
 * @param threadData      Thread data for error handling.
 * @param fwd             Forward jacobian (isBidirectional=TRUE, adjointJacobian set).
 * @param parentJacobian  Parent Jacobian for nested use (can be NULL).
 * @param jac             Output buffer.
 * @param isDense         TRUE for dense, FALSE for sparse CSC.
 */
void evalJacobianBidirectional(DATA* data, threadData_t *threadData,
                               JACOBIAN* fwd, JACOBIAN* parentJacobian,
                               modelica_real* jac, modelica_boolean isDense)
{
  JACOBIAN* adj = fwd->adjointJacobian;
  const SPARSE_PATTERN* fwdsp = fwd->sparsePattern;
  const SPARSE_PATTERN* adjsp = adj->sparsePattern;
  const int nRows = (int)fwd->sizeRows;
  const int nCols = (int)fwd->sizeCols;
  int color, column, row, nz, j;

  if (fwd->constantEqns) fwd->constantEqns(data, threadData, fwd, parentJacobian);
  if (adj->constantEqns) adj->constantEqns(data, threadData, adj, parentJacobian);

  if (isDense) {
    memset(jac, 0, (size_t)nRows * (size_t)nCols * sizeof(modelica_real));
  }

  /* Column phase (forward mode, CSC + column coloring) */
  for (color = 0; color < (int)fwdsp->maxColors; color++) {
    for (column = 0; column < nCols; column++)
      if ((int)fwdsp->colorCols[column] - 1 == color)
        fwd->seedVars[column] = 1.0;

    fwd->evalColumn(data, threadData, fwd, parentJacobian);

    for (column = 0; column < nCols; column++) {
      if ((int)fwdsp->colorCols[column] - 1 == color) {
        for (nz = (int)fwdsp->leadindex[column]; nz < (int)fwdsp->leadindex[column + 1]; nz++) {
          if (fwd->recoverMask[nz]) {
            row = (int)fwdsp->index[nz];
            if (isDense)
              jac[column * nRows + row] = fwd->resultVars[row];
            else
              jac[nz] = fwd->resultVars[row];
          }
        }
        fwd->seedVars[column] = 0.0;
      }
    }
  }

  /* Row phase (adjoint mode, CSR + row coloring) */
  for (color = 0; color < (int)adjsp->maxColors; color++) {
    for (row = 0; row < nRows; row++)
      if ((int)adjsp->colorCols[row] - 1 == color)
        adj->seedVars[row] = 1.0;

    adj->evalColumn(data, threadData, adj, parentJacobian);

    for (row = 0; row < nRows; row++) {
      if ((int)adjsp->colorCols[row] - 1 == color) {
        for (nz = (int)adjsp->leadindex[row]; nz < (int)adjsp->leadindex[row + 1]; nz++) {
          if (adj->recoverMask[nz]) {
            column = (int)adjsp->index[nz];
            if (isDense)
              jac[column * nRows + row] = adj->resultVars[column];
            else
              jac[adj->csrToCscMap[nz]] = adj->resultVars[column];
          }
        }
        adj->seedVars[row] = 0.0;
      }
    }
    /* Reset adjoint result vars to zero after reading to prevent accumulation across colors */
    memset(adj->resultVars, 0, (size_t)nRows * sizeof(modelica_real));
    // also for tmp vars
    memset(adj->tmpVars, 0, (size_t)adj->sizeTmpVars * sizeof(modelica_real));
  }
}

/**
 * @brief Compute Jacobian-Vector product y = J * s.
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
  if (jacobian->isRowEval) {
    /* Error: jvp called on row-evaluation Jacobian */
    errorStreamPrint(OMC_LOG_STDOUT, 0, "cant perform jvp on row-evaluation Jacobian\n");
    return;
  }
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

  /* Set all seeds */
  for (unsigned int col = 0; col < nCols; col++) {
      jacobian->seedVars[col] = seed[col];
  }

  /* Evaluate J * s into resultVars */
  jacobian->evalColumn(data, threadData, jacobian, parentJacobian);

  /* Accumulate results into out */
  for (unsigned int row = 0; row < nRows; row++) {
    out[row] += jacobian->resultVars[row];
  }
}


/**
 * @brief Compute Vector-Jacobian product y = J^T * s.
 *
 * @param data            Runtime data struct.
 * @param threadData      Thread data for error handling.
 * @param jacobian        Jacobian object (must have evalColumn and sparsePattern set).
 * @param parentJacobian  Parent Jacobian (if nested), can be NULL.
 * @param seed            Input seed vector s, length = jacobian->sizeRows.
 * @param out             Output vector y, length = jacobian->sizeCols.
 * @param zero_out        If true, zero-initialize out before accumulation.
 */
void vjp(DATA* data, threadData_t *threadData,
         JACOBIAN* jacobian, JACOBIAN* parentJacobian,
         const modelica_real* seed, modelica_real* out,
         modelica_boolean zero_out)
{
  if (!jacobian->isRowEval) {
    /* Error: vjp called on column-evaluation Jacobian */
    errorStreamPrint(OMC_LOG_STDOUT, 0, "cant perform vjp on column-evaluation Jacobian\n");
    return;
  }
  const unsigned int nCols = jacobian->sizeCols;
  const unsigned int nRows = jacobian->sizeRows;

  /* Optional: zero output before accumulation */
  if (zero_out) {
    memset(out, 0, nCols * sizeof(modelica_real));
  }

  /* Ensure seeds are zeroed before use */
  memset(jacobian->seedVars, 0, nRows * sizeof(modelica_real));

  /* Evaluate constant equations (if any) */
  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, parentJacobian);
  }

  /* Set all seeds */
  for (unsigned int row = 0; row < nRows; row++) {
      jacobian->seedVars[row] = seed[row];
  }

  /* Evaluate J * s into resultVars */
  // this is actually evalRow
  jacobian->evalColumn(data, threadData, jacobian, parentJacobian);

  /* Accumulate results into out */
  for (unsigned int col = 0; col < nCols; col++) {
    out[col] += jacobian->resultVars[col];
  }
}

/**
 * @brief Allocate memory for sparsity pattern.
 *
 * @param n_leadIndex         Number of rows or columns of Matrix.
 *                            Depending on compression type CSR (-->rows) or CSC (-->columns).
 * @param nnz                 Number of non-zero elements in Matrix.
 * @param maxColors           Maximum number of colors of Matrix.
 * @return SPARSE_PATTERN*    Pointer to allocated sparsity pattern of Matrix.
 */
SPARSE_PATTERN* allocSparsePattern(unsigned int n_leadIndex, unsigned int nnz, unsigned int maxColors)
{
  SPARSE_PATTERN* sparsePattern = (SPARSE_PATTERN*) malloc(sizeof(SPARSE_PATTERN));
  sparsePattern->nnz = nnz;
  sparsePattern->leadindex = (unsigned int*) malloc((n_leadIndex+1)*sizeof(unsigned int));
  sparsePattern->index = (unsigned int*) malloc(nnz*sizeof(unsigned int));
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

  const unsigned int nnz = csc->nnz;

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
  /* nnz was set by allocSparsePattern */

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
JACOBIAN_METHOD setJacobianMethod(threadData_t* threadData, JACOBIAN_AVAILABILITY availability)
{
  JACOBIAN_METHOD jacobianMethod = JAC_UNKNOWN;
  assertStreamPrint(threadData, availability != JACOBIAN_UNKNOWN, "Jacobian availability status is unknown.");

  /* if FLAG_JACOBIAN is set, choose jacobian calculation method */
  if (omc_flag[FLAG_JACOBIAN]) {
    for (int method=1; method < JAC_MAX; method++) {
      if (!strcmp(omc_flagValue[FLAG_JACOBIAN], JACOBIAN_METHOD_NAME[method])) {
        jacobianMethod = (JACOBIAN_METHOD) method;
        break;
      }
    }
    // Error case
    if (jacobianMethod == JAC_UNKNOWN) {
      errorStreamPrint(OMC_LOG_STDOUT, 0, "Unknown value `%s` for flag `-jacobian`", omc_flagValue[FLAG_JACOBIAN]);
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
    } else if(jacobianMethod == BICOLOREDSYMJAC) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Symbolic Jacobian not available, only sparsity pattern. Switching to colored numerical Jacobian.");
      jacobianMethod = COLOREDNUMJAC;
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
  case COLOREDSYMJACADJ:
    infoStreamPrint(OMC_LOG_JAC, 0, "Using Jacobian method: Colored symbolical adjoint Jacobian.");
    break;
  case BICOLOREDSYMJAC:
    infoStreamPrint(OMC_LOG_JAC, 0, "Using Jacobian method: Bicolored (bidirectional) symbolical Jacobian.");
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


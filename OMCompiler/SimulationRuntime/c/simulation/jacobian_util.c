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

#ifdef USE_PARJAC
  #define GC_THREADS
  #include <gc/omc_gc.h>
  #include "util/parallel_helper.h"
#endif

/**
 * @brief setJacElementFunc-compatible setter for a sparse CSC raw buffer.
 *
 * Writes value at the CSC position: jac[nth] = value.
 * row, col, and nRows are unused; the position is determined solely by nth.
 */
void setJacElementRawSparse(int row, int col, int nth, double value, void* jac, int nRows)
{
  (void)row; (void)col; (void)nRows;
  ((modelica_real*)jac)[nth] = value;
}

/**
 * @brief setJacElementFunc-compatible setter for a dense column-major raw buffer.
 *
 * Writes value at: jac[col * nRows + row] = value.
 * nth is unused.
 */
void setJacElementRawDenseColumnMajor(int row, int col, int nth, double value, void* jac, int nRows)
{
  (void)nth;
  ((modelica_real*)jac)[col * nRows + row] = value;
}


/**
 * @brief setJacElementFunc-compatible setter for a dense column-major raw buffer.
 *
 * Used in row-wise (adjoint) evaluation where setElement is called as
 * setElement(currentIndex=col, j=row, nth, value, jac, nRows).
 * Writes value at: jac[col * nRows + row] = value.
 * nth is unused.
 */
void setJacElementRawDenseColumnMajorRowEval(int col, int row, int nth, double value, void* jac, int nRows)
{
  (void)nth;
  ((modelica_real*)jac)[col * nRows + row] = value;
}

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

  jacobian->isRowEval = source->isRowEval;
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
    freeSparsePattern(jac->sparsePattern); jac->sparsePattern = NULL;
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

/**
 * @brief Evaluate a colored Jacobian, auto-selecting fwd/adj setter from jacobian->isRowEval.
 *
 * Thin convenience wrapper around evalJacobianEx for the common case: colored
 * (non-bicolored) evaluation into a dense or raw-sparse buffer, no custom setters,
 * no explicit method/t_jac needed. Equivalent to the old evalJacobian().
 */
void evalJacobian(DATA* data, threadData_t* threadData, JACOBIAN* jacobian,
                   JACOBIAN* parentJacobian, modelica_real* jac,
                   modelica_boolean isDense)
{
  JACOBIAN_METHOD method = jacobian->isRowEval ? COLOREDSYMJACADJ : COLOREDSYMJAC;
  evalJacobianExtended(data, threadData, method, jacobian, parentJacobian, /*t_jac=*/NULL,
                 jac, isDense ? JAC_OUTPUT_DENSE : JAC_OUTPUT_SPARSE_RAW,
                 /*setFwd=*/NULL, /*setAdj=*/NULL);
}

#ifdef USE_PARJAC
/**
 * @brief Evaluate a colored Jacobian in parallel across OpenMP threads.
 *
 * Each worker evaluates assigned colors using its own thread-local Jacobian.
 * Thread-local Jacobians do not have evalColumn set, so the generated callback
 * is selected from data->callback based on the evaluation orientation.
 */
void evalJacobianColoredParallel(DATA* data, threadData_t* threadData,
                                        JACOBIAN* jacColumns,
                                        SPARSE_PATTERN* spp,
                                        void* matrixA, setJacElementFunc setElement,
                                        modelica_real dae_cj)
{
  const int isRowEval = (jacColumns[0].isRowEval == TRUE);
  jacobianColumn_func_ptr evalFunc = isRowEval
      ? data->callback->functionJacADJ_column
      : data->callback->functionJacA_column;

  GC_allow_register_threads();

#pragma omp parallel default(none) shared(data, threadData, jacColumns, spp, matrixA, setElement, evalFunc, isRowEval)
{
  if (!GC_thread_is_registered()) {
    struct GC_stack_base sb;
    memset(&sb, 0, sizeof(sb));
    GC_get_stack_base(&sb);
    GC_register_my_thread(&sb);
  }

  JACOBIAN* t_jac = &(jacColumns[omc_get_thread_num()]);
  const unsigned int activeDim = t_jac->sizeCols;
  const int nRows = (int)(isRowEval ? t_jac->sizeCols : t_jac->sizeRows);
  jacobianCleanup_func_ptr cleanupFunc = isRowEval ? evalJacobianCleanupRowEval : NULL;

  t_jac->dae_cj = dae_cj;

  unsigned int color;
#pragma omp for
  for (color = 0; color < spp->maxColors; color++) {
    evalJacobianOneColor(data, threadData, t_jac, NULL, spp, (int)color,
                         activeDim, nRows, matrixA, setElement, evalFunc, cleanupFunc);
  }
}
}

/**
 * @brief Allocate one thread-local Jacobian per OpenMP worker.
 *
 * Dimensions and the sparse pattern are shared with source. Work arrays are
 * private to each worker so colors can be evaluated independently.
 */
void allocateThreadLocalJacobians(JACOBIAN* source, JACOBIAN** jacColumns)
{
  int maxTh = omc_get_max_threads();
  *jacColumns = (JACOBIAN*) malloc(maxTh * sizeof(JACOBIAN));
  SPARSE_PATTERN* sparsePattern = source->sparsePattern;
  unsigned int columns     = source->sizeCols;
  unsigned int rows        = source->sizeRows;
  unsigned int sizeTmpVars = source->sizeTmpVars;
  modelica_boolean isRowEval = source->isRowEval;
  unsigned int i;

  GC_allow_register_threads();

#pragma omp parallel default(none) firstprivate(maxTh, columns, rows, sizeTmpVars, isRowEval) shared(sparsePattern, jacColumns, i)
  {
  if (!GC_thread_is_registered()) {
    struct GC_stack_base sb;
    memset(&sb, 0, sizeof(sb));
    GC_get_stack_base(&sb);
    GC_register_my_thread(&sb);
  }
#pragma omp for schedule(runtime)
  for (i = 0; i < maxTh; ++i) {
    (*jacColumns)[i].sizeCols      = columns;
    (*jacColumns)[i].sizeRows      = rows;
    (*jacColumns)[i].sizeTmpVars   = sizeTmpVars;
    (*jacColumns)[i].tmpVars       = (modelica_real*) calloc(sizeTmpVars, sizeof(modelica_real));
    (*jacColumns)[i].resultVars    = (modelica_real*) calloc(rows, sizeof(modelica_real));
    (*jacColumns)[i].seedVars      = (modelica_real*) calloc(columns, sizeof(modelica_real));
    (*jacColumns)[i].sparsePattern = sparsePattern;
    (*jacColumns)[i].isRowEval     = isRowEval;
  }
  }
}

/** Free thread-local Jacobians allocated by allocateThreadLocalJacobians. */
void freeAnalyticalJacobian(JACOBIAN** jacColumns)
{
  int maxTh = omc_get_max_threads();
  unsigned int i;

  for (i = 0; i < maxTh; ++i) {
    free((*jacColumns)[i].tmpVars);
    free((*jacColumns)[i].resultVars);
    free((*jacColumns)[i].seedVars);
  }

  free(*jacColumns);
}
#endif

/**
 * @brief Evaluate a Jacobian using the specified method and output format.
 *
 * Colored methods (COLOREDSYMJAC/SYMJAC/COLOREDSYMJACADJ) dispatch through
 * evalJacobianColored[Parallel]; the fwd/adj setter choice for built-in formats
 * is derived from jacobian->isRowEval, so the three colored enum values behave
 * identically here (kept only for external/legacy compatibility).
 * BICOLOREDSYMJAC dispatches through evalJacobianBidirectional using setFwd.
 *
 * Caller responsibilities: set jac->dae_cj if needed, call setContext/unsetContext
 * around this function. Dense output is zeroed internally; other formats are not.
 *
 * @param jacobian       Primary/meta Jacobian (sizeRows/sizeCols/sparsePattern/isRowEval).
 * @param parentJacobian Parent context forwarded to evalJacobianColored, or NULL.
 * @param t_jac          Thread-local copy for parallel eval; pass NULL to use jacobian itself (serial).
 * @param format         JAC_OUTPUT_DENSE / JAC_OUTPUT_SPARSE_RAW / JAC_OUTPUT_CUSTOM.
 * @param setFwd/setAdj  Only consulted for JAC_OUTPUT_CUSTOM. BICOLOREDSYMJAC
 *                        uses setFwd regardless of format.
 */
void evalJacobianExtended(DATA* data, threadData_t* threadData,
                   JACOBIAN_METHOD method,
                   JACOBIAN* jacobian, JACOBIAN* parentJacobian, JACOBIAN* t_jac,
                   void* outputMatrix, JACOBIAN_OUTPUT_FORMAT format,
                   setJacElementFunc setFwd, setJacElementFunc setAdj)
{
  jacobianCleanup_func_ptr cleanup = jacobian->isRowEval ? evalJacobianCleanupRowEval : NULL;
  JACOBIAN* evalJac = t_jac ? t_jac : jacobian;

  /* Resolve setter(s) for the built-in formats; JAC_OUTPUT_CUSTOM keeps whatever
   * the caller passed in (e.g. a SUNDIALS sparse setter). */
  switch (format) {
  case JAC_OUTPUT_DENSE:
    memset(outputMatrix, 0, jacobian->sizeRows * jacobian->sizeCols * sizeof(modelica_real));
    setFwd = setAdj = jacobian->isRowEval
        ? setJacElementRawDenseColumnMajorRowEval
        : setJacElementRawDenseColumnMajor;
    break;
  case JAC_OUTPUT_SPARSE_RAW:
    setFwd = setAdj = setJacElementRawSparse;
    break;
  case JAC_OUTPUT_CUSTOM:
    break; /* setFwd/setAdj supplied by caller */
  }

  switch (method) {
  case COLOREDSYMJAC:
  case SYMJAC:
  case COLOREDSYMJACADJ: {
    setJacElementFunc setter = jacobian->isRowEval ? setAdj : setFwd;
#ifndef USE_PARJAC
    evalJacobianColored(data, threadData, evalJac, parentJacobian, outputMatrix, setter, cleanup);
#else
  evalJacobianColoredParallel(data, threadData, evalJac, jacobian->sparsePattern,
                outputMatrix, setter, jacobian->dae_cj);
#endif
    break;
  }
  case BICOLOREDSYMJAC: {
    if (jacobian->isBidirectional && jacobian->adjointJacobian != NULL &&
        jacobian->recoverMask != NULL && jacobian->adjointJacobian->recoverMask != NULL &&
        jacobian->adjointJacobian->csrToCscMap != NULL) {
      evalJacobianBidirectional(data, threadData, jacobian, parentJacobian,
                                outputMatrix, setFwd, evalJacobianCleanupRowEval);
    } else {
      warningStreamPrint(OMC_LOG_JAC, 0,
          "Bidirectional Jacobian data unavailable; falling back to colored symbolic evaluation.");
      evalJacobianColored(data, threadData, jacobian, parentJacobian,
                          outputMatrix, setFwd, cleanup);
    }
    break;
  }
  default:
    throwStreamPrint(threadData, "evalJacobian: unsupported method %d", (int)method);
    break;
  }
}

/**
 * @brief Row-eval cleanup: zeros resultVars and tmpVars after each color.
 *
 * Required for row-wise (adjoint) evaluation to prevent accumulation across colors.
 */
void evalJacobianCleanupRowEval(JACOBIAN* jac)
{
  memset(jac->resultVars, 0, jac->sizeRows * sizeof(modelica_real));
  memset(jac->tmpVars,    0, jac->sizeTmpVars * sizeof(modelica_real));
}

/**
 * @brief Evaluate one color of a Jacobian using a generic element setter.
 *
 * Single-color kernel shared by evalJacobianColored (serial) and
 * evalJacobianColoredParallel (OpenMP). See jacobian_util.h for full documentation.
 */
void evalJacobianOneColor(DATA* data, threadData_t* threadData,
                           JACOBIAN* jacobian, JACOBIAN* parentJac,
                           const SPARSE_PATTERN* sp, int color,
                           unsigned int activeDim, int nRows,
                           void* matrixA, setJacElementFunc setElement,
                           jacobianColumn_func_ptr evalFunc,
                           jacobianCleanup_func_ptr cleanupFunc)
{
  int j, nth, currentIndex;

  /* Activate seeds for this color */
  for (j = 0; j < (int)activeDim; j++)
    if ((int)sp->colorCols[j] - 1 == color)
      jacobian->seedVars[j] = 1.0;

  evalFunc(data, threadData, jacobian, parentJac);

  /* Scatter results.
   * Convention: setElement(currentIndex, j, nth, value, matrixA, nRows)
   * where j is the active (seeded) index and currentIndex is the passive index.
   * For column eval: j=col, currentIndex=row  => setElement(row, col, nth, ...)
   * For row eval:    j=row, currentIndex=col  => setElement(col, row, nth, ...)
   * The caller selects a setter that interprets its arguments accordingly.
   */
  for (j = 0; j < (int)activeDim; j++) {
    if ((int)sp->colorCols[j] - 1 == color) {
      nth = (int)sp->leadindex[j];
      while (nth < (int)sp->leadindex[j + 1]) {
        currentIndex = (int)sp->index[nth];
        setElement(currentIndex, j, nth, jacobian->resultVars[currentIndex], matrixA, nRows);
        infoStreamPrint(OMC_LOG_JAC, 0, "evalJacobianOneColor: color=%d, j=%d, nth=%d, currentIndex=%d, value=%g",
              color, j, nth, currentIndex, jacobian->resultVars[currentIndex]);
        nth++;
      }
      jacobian->seedVars[j] = 0.0;
    }
  }

  if (cleanupFunc != NULL)
    cleanupFunc(jacobian);
}

/**
 * @brief Evaluate Jacobian using coloring with a generic element setter.
 *
 * Unified evaluation for both column-wise (forward) and row-wise (adjoint) mode,
 * selected by jacobian->isRowEval.
 *
 * Column-wise (isRowEval == FALSE):
 *   - Seeds are set on columns; sparsePattern is CSC.
 *   - setElement called as (currentIndex=row, j=col, nz, resultVars[row], ...).
 *
 * Row-wise (isRowEval == TRUE):
 *   - Seeds are set on rows; sparsePattern is CSR.
 *   - setElement called as (currentIndex=col, j=row, nz, resultVars[col], ...).
 *   - cleanupFunc should be evalJacobianCleanupRowEval to reset state between colors.
 *
 * The caller is responsible for zeroing matrixA before this call if needed.
 * constantEqns is called internally when present.
 *
 * @param data            Runtime data struct.
 * @param threadData      Thread data for error handling.
 * @param jacobian        Jacobian to evaluate.
 * @param parentJacobian  Parent Jacobian (can be NULL).
 * @param matrixA         Opaque pointer to output matrix; passed through to setElement.
 * @param setElement      Setter: (row, col, nz_index, value, matrixA, nRows).
 * @param cleanupFunc     Called after each color; NULL is treated as a no-op.
 */
void evalJacobianColored(DATA* data, threadData_t *threadData,
                         JACOBIAN* jacobian, JACOBIAN* parentJacobian,
                         void* matrixA, setJacElementFunc setElement,
                         jacobianCleanup_func_ptr cleanupFunc)
{
  const SPARSE_PATTERN* sp = jacobian->sparsePattern;
  const int isRowEval = (jacobian->isRowEval == TRUE);
  const unsigned int activeDim = jacobian->sizeCols;
  const int nRows = (int)(isRowEval ? jacobian->sizeCols : jacobian->sizeRows);
  int color;

  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, parentJacobian);
  }

  for (color = 0; color < (int)sp->maxColors; color++) {
    evalJacobianOneColor(data, threadData, jacobian, parentJacobian, sp, color,
                         activeDim, nRows, matrixA, setElement,
                         jacobian->evalColumn, cleanupFunc);
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
  JACOBIAN* adj = fwd ? fwd->adjointJacobian : NULL;
  if (!adj || !fwd->sparsePattern || !adj->sparsePattern) return;

  SPARSE_PATTERN* fwdsp = fwd->sparsePattern;
  SPARSE_PATTERN* adjsp = adj->sparsePattern;
  const unsigned int nCols = fwd->sizeCols;
  const unsigned int nRows = fwd->sizeRows;
  const unsigned int nnz = fwdsp->nnz;
  unsigned int j, i, nz, k, j2, i2;

  if (adj->sizeCols != nRows || adj->sizeRows != nCols || adjsp->nnz != nnz) return;

#ifdef OMC_RUNTIME_USE_COLPACK
  /* The adjoint pattern is CSR(J), which is the format expected by ColPack.
   * Replace the independent distance-1 colorings with one joint star
   * bicoloring. If ColPack fails, retain the valid independent colorings. */
  if (computeColPackStarBicoloring(nRows, nCols,
                                   adjsp->leadindex, adjsp->index,
                                   adjsp->colorCols, &adjsp->maxColors,
                                   fwdsp->colorCols, &fwdsp->maxColors)) {
    infoStreamPrint(OMC_LOG_JAC, 0,
                    "Runtime star bicoloring: %u column colors, %u row colors.",
                    fwdsp->maxColors, adjsp->maxColors);
  } else {
    warningStreamPrint(OMC_LOG_JAC, 0,
                       "Runtime star bicoloring failed; using independent distance-1 colorings.");
  }
#endif

  fwd->recoverMask = (unsigned char*) calloc(nnz, sizeof(unsigned char));
  adj->recoverMask = (unsigned char*) calloc(nnz, sizeof(unsigned char));
  adj->csrToCscMap = (unsigned int*) calloc(nnz, sizeof(unsigned int));
  if (nnz > 0 && (!fwd->recoverMask || !adj->recoverMask || !adj->csrToCscMap)) {
    free(fwd->recoverMask); fwd->recoverMask = NULL;
    free(adj->recoverMask); adj->recoverMask = NULL;
    free(adj->csrToCscMap); adj->csrToCscMap = NULL;
    return;
  }

  /* Forward recoverMask: entry (i,j) is column-recoverable if j is the ONLY
   * column with its column color among all columns having a nonzero in row i. */
  // iterate over all columns
  for (j = 0; j < nCols; j++) {
    unsigned int cj = fwdsp->colorCols[j];
    // iterate over nonzeros (rows with nonzero) in this column via forward CSC pattern
    for (nz = fwdsp->leadindex[j]; nz < fwdsp->leadindex[j+1]; nz++) {
      i = fwdsp->index[nz]; // row index of current nonzero
      int unique = cj > 0; // color 0 means this column is covered by row evaluation
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
      int unique = ri > 0; // color 0 means this row is covered by column evaluation
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
  // this could maybe be done with initAdjointCSRtoCSCMap
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
 * The forward and adjoint phases both call setElement as
 * setElement(row, column, forwardCscNz, value, matrixA, nRows). This lets the
 * caller select any output format, while the CSR-to-CSC mapping keeps the
 * adjoint phase's sparsity index compatible with the forward pattern.
 *
 * cleanupFunc is invoked for the adjoint Jacobian after each row color. The
 * forward phase deliberately needs no cleanup: its generated forward code
 * overwrites its result state for each seed color. Row evaluation accumulates
 * intermediate state, so it normally uses evalJacobianCleanupRowEval.
 *
 * @param data            Runtime data struct.
 * @param threadData      Thread data for error handling.
 * @param fwd             Forward jacobian (isBidirectional=TRUE, adjointJacobian set).
 * @param parentJacobian  Parent Jacobian for nested use (can be NULL).
 * @param matrixA         Opaque output matrix; forwarded to setElement.
 * @param setElement      Setter called for each recovered entry in forward
 *                        Jacobian orientation.
 * @param cleanupFunc     Invoked on the adjoint Jacobian after every row color;
 *                        NULL is a no-op.
 */
void evalJacobianBidirectional(DATA* data, threadData_t *threadData,
                               JACOBIAN* fwd, JACOBIAN* parentJacobian,
                               void* matrixA, setJacElementFunc setElement,
                               jacobianCleanup_func_ptr cleanupFunc)
{
  JACOBIAN* adj = fwd->adjointJacobian;
  const SPARSE_PATTERN* fwdsp = fwd->sparsePattern;
  const SPARSE_PATTERN* adjsp = adj->sparsePattern;
  const int nRows = (int)fwd->sizeRows;
  const int nCols = (int)fwd->sizeCols;
  int color, column, row, nz;

  if (fwd->constantEqns) fwd->constantEqns(data, threadData, fwd, parentJacobian);
  if (adj->constantEqns) adj->constantEqns(data, threadData, adj, parentJacobian);

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
            setElement(row, column, nz, fwd->resultVars[row], matrixA, nRows);
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
            setElement(row, column, (int)adj->csrToCscMap[nz],
                       adj->resultVars[column], matrixA, nRows);
          }
        }
        adj->seedVars[row] = 0.0;
      }
    }
    if (cleanupFunc != NULL)
      cleanupFunc(adj);
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

  memset(jacobian->seedVars, 0, nCols * sizeof(modelica_real));
}


/**
 * @brief Compute Vector-Jacobian product y = J^T * s.
 *
 * @param data            Runtime data struct.
 * @param threadData      Thread data for error handling.
 * @param jacobian        Jacobian object (must have evalColumn and sparsePattern set).
 * @param parentJacobian  Parent Jacobian (if nested), can be NULL.
 * For a row-evaluation Jacobian, sizeCols is the primal row/seed count and
 * sizeRows is the primal column/result count.
 *
 * @param seed            Input seed vector s, length = jacobian->sizeCols.
 * @param out             Output vector y, length = jacobian->sizeRows.
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

  evalJacobianCleanupRowEval(jacobian);

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
  for (unsigned int row = 0; row < nCols; row++) {
      jacobian->seedVars[row] = seed[row];
  }

  /* Evaluate J * s into resultVars */
  // this is actually evalRow
  jacobian->evalColumn(data, threadData, jacobian, parentJacobian);

  /* Accumulate results into out */
  for (unsigned int col = 0; col < nRows; col++) {
    out[col] += jacobian->resultVars[col];
  }

  memset(jacobian->seedVars, 0, nCols * sizeof(modelica_real));
  evalJacobianCleanupRowEval(jacobian);
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
 * @brief Map compressed source positions to positions in its transpose.
 *
 * The source's inner indices become the transpose's outer indices. If
 * targetLeadindex is non-NULL, it is filled with the transpose's outer
 * pointers. The map preserves the canonical transpose ordering obtained by
 * scanning source outer indices in ascending order.
 */
static unsigned int* sparsePatternTransposeMap(const SPARSE_PATTERN* source,
                                                unsigned int sourceOuterCount,
                                                unsigned int targetOuterCount,
                                                unsigned int* targetLeadindex)
{
  unsigned int* targetHeads;
  unsigned int* sourceToTargetMap;
  unsigned int position = 0;

  targetHeads = (unsigned int*) calloc((targetOuterCount ? targetOuterCount : 1), sizeof(unsigned int));
  sourceToTargetMap = (unsigned int*) malloc((source->nnz ? source->nnz : 1) * sizeof(unsigned int));
  if (targetHeads == NULL || sourceToTargetMap == NULL) {
    free(targetHeads);
    free(sourceToTargetMap);
    return NULL;
  }

  /* Count entries in each target outer dimension. */
  for (unsigned int nz = 0; nz < source->nnz; nz++) {
    if (source->index[nz] >= targetOuterCount) {
      free(targetHeads);
      free(sourceToTargetMap);
      return NULL;
    }
    targetHeads[source->index[nz]]++;
  }

  /* Turn counts into target offsets. targetHeads remains the running head. */
  for (unsigned int target = 0; target < targetOuterCount; target++) {
    const unsigned int count = targetHeads[target];
    targetHeads[target] = position;
    if (targetLeadindex != NULL) {
      targetLeadindex[target] = position;
    }
    position += count;
  }
  if (targetLeadindex != NULL) {
    targetLeadindex[targetOuterCount] = position;
  }

  /* Map every source position to its canonical position in the transpose. */
  for (unsigned int sourceOuter = 0; sourceOuter < sourceOuterCount; sourceOuter++) {
    const unsigned int start = source->leadindex[sourceOuter];
    const unsigned int stop = source->leadindex[sourceOuter + 1];
    if (stop < start || stop > source->nnz) {
      free(targetHeads);
      free(sourceToTargetMap);
      return NULL;
    }
    for (unsigned int nz = start; nz < stop; nz++) {
      const unsigned int target = source->index[nz];
      sourceToTargetMap[nz] = targetHeads[target]++;
    }
  }

  free(targetHeads);
  return sourceToTargetMap;
}

/**
 * @brief Convert a CSC-format sparsity pattern to CSR-format.
 *
 * Complexity: O(nnz + max(nRows, nCols))
 */
SPARSE_PATTERN* cscToCsr(const SPARSE_PATTERN* csc,
                           unsigned int nRows,
                           unsigned int nCols)
{
  unsigned int* cscToCsrMap;

  if (!csc) return NULL;

  /* Allocate CSR pattern: leadindex size = nRows+1, index size = nnz */
  SPARSE_PATTERN* csr = allocSparsePattern(nRows, csc->nnz, /*maxColors*/ 0);
  if (!csr) return NULL;

  cscToCsrMap = sparsePatternTransposeMap(csc, nCols, nRows, csr->leadindex);
  if (cscToCsrMap == NULL) {
    freeSparsePattern(csr);
    return NULL;
  }

  /* Fill CSR index array using the mapping from CSC to CSR. */
  for (unsigned int column = 0; column < nCols; column++) {
    for (unsigned int nz = csc->leadindex[column]; nz < csc->leadindex[column + 1]; nz++) {
      csr->index[cscToCsrMap[nz]] = column;
    }
  }

  free(cscToCsrMap);
  return csr;
}


/**
 * @brief Free sparsity pattern
 *
 * @param spp   Pointer to sparsity pattern
 */
void freeSparsePattern(SPARSE_PATTERN *spp)
{
  if (spp) {
    free(spp->index);
    free(spp->colorCols);
    free(spp->leadindex);
    free(spp);
  }
}

/**
 * @brief Greedy distance-1 column coloring of a CSC sparse pattern.
 *
 * Two columns may share a color only if they have no non-zero row in common.
 * Uses the existing cscToCsr helper to build the row→columns map, then
 * assigns the smallest available color to each column in order.
 *
 * Needed for the resizable analytic Jacobian path: the C sparsity pattern
 * is built at runtime from WHOLEDIM loops that over-approximate array
 * equations as dense blocks, so the compile-time coloring (derived from the
 * exact symbolic sparsity) is invalid for the runtime pattern.  Recomputing
 * it here guarantees correctness.
 *
 * @param sp     CSC sparse pattern (leadindex, index, colorCols already allocated).
 * @param nRows  Number of rows in the Jacobian.
 * @param nCols  Number of columns (== size of sp->colorCols).
 */
void computeColumnColoring(SPARSE_PATTERN* sp, unsigned int nRows, unsigned int nCols)
{
  if (!sp || nCols == 0) return;

  SPARSE_PATTERN* csr = cscToCsr(sp, nRows, nCols);
  if (!csr) {
    /* Fallback: trivial one-column-per-color coloring. */
    for (unsigned int c = 0; c < nCols; c++) sp->colorCols[c] = c + 1;
    sp->maxColors = nCols;
    return;
  }

  /* forbidden[k] == 1 if color k is already used by an adjacent column.
   * Index 0 unused; colors are 1-based, max is nCols. */
  unsigned char* forbidden = (unsigned char*) calloc(nCols + 2, sizeof(unsigned char));
  /* Track which forbidden slots were set so we can reset without a full memset. */
  unsigned int* setColors  = (unsigned int*)  malloc(nCols * sizeof(unsigned int));

  if (!forbidden || !setColors) {
    free(forbidden); free(setColors);
    freeSparsePattern(csr);
    for (unsigned int c = 0; c < nCols; c++) sp->colorCols[c] = c + 1;
    sp->maxColors = nCols;
    return;
  }

  unsigned int maxColor = 0;

  for (unsigned int c = 0; c < nCols; c++) {
    unsigned int nSet = 0;

    /* Mark colors of already-colored columns that share a row with c. */
    for (unsigned int nz = sp->leadindex[c]; nz < sp->leadindex[c + 1]; nz++) {
      const unsigned int row = sp->index[nz];
      if (row >= nRows) continue;
      for (unsigned int nz2 = csr->leadindex[row]; nz2 < csr->leadindex[row + 1]; nz2++) {
        const unsigned int c2 = csr->index[nz2];
        if (c2 < c) {
          const unsigned int used = sp->colorCols[c2];
          if (used > 0 && used <= nCols && !forbidden[used]) {
            forbidden[used] = 1;
            setColors[nSet++] = used;
          }
        }
      }
    }

    /* Smallest color not forbidden. */
    unsigned int color = 1;
    while (color <= nCols && forbidden[color]) color++;
    sp->colorCols[c] = color;
    if (color > maxColor) maxColor = color;

    /* Reset forbidden markers for next iteration. */
    for (unsigned int k = 0; k < nSet; k++) forbidden[setColors[k]] = 0;
  }

  sp->maxColors = maxColor;

  free(setColors);
  free(forbidden);
  freeSparsePattern(csr);
}

/**
 * @brief Sort row indices within each column of a CSC sparse pattern.
 *
 * KLU and printSparseStructure both require that row indices within each
 * column are in strictly ascending order.  The NBackend-generated
 * initialResizableAnalyticJacobianA fills entries in equation order which
 * may not be sorted (e.g. column 0 gets row 10 from one equation and row 0
 * from another).  Call this function once after the pattern is built and
 * before it is handed to KLU or the print helpers.
 *
 * @param sp    CSC sparse pattern (leadindex and index already filled).
 * @param nCols Number of columns (== size of sp->leadindex - 1).
 */
void sortSparseColumns(SPARSE_PATTERN* sp, unsigned int nCols)
{
  if (!sp) return;
  for (unsigned int c = 0; c < nCols; c++) {
    unsigned int start = sp->leadindex[c];
    unsigned int end   = sp->leadindex[c + 1];
    if (end <= start + 1) continue;
    /* Insertion sort — columns typically have very few entries. */
    for (unsigned int i = start + 1; i < end; i++) {
      unsigned int key = sp->index[i];
      unsigned int j   = i;
      while (j > start && sp->index[j - 1] > key) {
        sp->index[j] = sp->index[j - 1];
        j--;
      }
      sp->index[j] = key;
    }
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

void initAdjointCSRtoCSCMap(JACOBIAN* jacobian)
{
  if (jacobian->csrToCscMap != NULL) {
    return;
  }
  /* Row-evaluation dimensions describe its vectors: sizeCols is the number
   * of seeded primal rows (CSR outer dimension), while sizeRows is the number
   * of resulting primal columns (CSC outer dimension after transposition). */
  jacobian->csrToCscMap = sparsePatternTransposeMap(jacobian->sparsePattern,
                                                     jacobian->sizeCols,
                                                     jacobian->sizeRows,
                                                     NULL);
}

/**
 * @brief Set Jacobian method from user flag and available Jacobian.
 *
 * @param threadData              Used for error handling.
 * @param availability            Is the Jacobian available, only the sparsity pattern available or nothing available.
 * @param flagValue               Flag value of FLAG_JACOBIAN. Can be NULL.
 * @return JACOBIAN_METHOD   Returns jacobian method that is availble.
 */
JACOBIAN_METHOD setJacobianMethod(threadData_t* threadData, DATA* data, JACOBIAN** jacobian)
{
  JACOBIAN_METHOD jacobianMethod = JAC_UNKNOWN;
  JACOBIAN_AVAILABILITY availability;

  /* if FLAG_JACOBIAN is set, choose jacobian calculation method */
  if (omc_flag[FLAG_JACOBIAN]) {
    for (int method=1; method < JAC_MAX; method++) {
      if (!strcmp(omc_flagValue[FLAG_JACOBIAN], JACOBIAN_METHOD_NAME[method])) {
        jacobianMethod = (JACOBIAN_METHOD) method;
        infoStreamPrint(OMC_LOG_STDOUT, 1, "Jacobian method in if: %s", JACOBIAN_METHOD_NAME[jacobianMethod]);
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

  if (jacobianMethod == COLOREDSYMJACADJ) {
    *jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_ADJ]);
    if ((*jacobian)->availability == JACOBIAN_UNKNOWN) {
      data->callback->initialAnalyticJacobianADJ(data, threadData, *jacobian);
    }

    /* An adjoint sparsity pattern alone cannot evaluate an adjoint symbolic
     * Jacobian. Fall back to the forward Jacobian for numerical evaluation. */
    if ((*jacobian)->availability != JACOBIAN_AVAILABLE) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Adjoint symbolic Jacobian not available, switching to internal numerical Jacobian.");
      *jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
      if ((*jacobian)->availability == JACOBIAN_UNKNOWN) {
        data->callback->initialAnalyticJacobianA(data, threadData, *jacobian);
      }
      jacobianMethod = INTERNALNUMJAC;
    }
  } else {
    *jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    if ((*jacobian)->availability == JACOBIAN_UNKNOWN) {
      data->callback->initialAnalyticJacobianA(data, threadData, *jacobian);
    }
  }

  availability = (*jacobian)->availability;
  assertStreamPrint(threadData, availability != JACOBIAN_UNKNOWN, "Jacobian availability status is unknown.");

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
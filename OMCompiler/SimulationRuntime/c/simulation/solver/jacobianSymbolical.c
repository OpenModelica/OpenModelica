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

 /*! \file jacobian_symbolical.c
 */

#ifdef USE_PARJAC
  #define GC_THREADS
  #include <gc/omc_gc.h>
#endif

#include "jacobianSymbolical.h"
#include "../jacobian_util.h"

#ifdef USE_PARJAC
/**
 * @brief Parallel evaluation of a colored Jacobian.
 *
 * Distributes colors across OpenMP threads. Each thread works on its own
 * thread-local Jacobian from the jacColumns array, calling the shared
 * evalJacobianOneColor kernel for each color assigned to it.
 *
 * evalFunc is derived from data->callback because thread-local Jacobians
 * allocated by allocateThreadLocalJacobians do not have evalColumn set.
 *
 * @param jacColumns  Array of thread-local Jacobians (one per thread).
 * @param spp         Sparse pattern (must match the pattern in jacColumns[i]).
 * @param matrixA     Opaque output matrix; forwarded to setElement.
 * @param setElement  Setter: (row, col, nz_index, value, matrixA, nRows).
 */
static void evalJacobianColoredParallel(DATA* data, threadData_t* threadData,
                                        JACOBIAN* jacColumns,
                                        SPARSE_PATTERN* spp,
                                        void* matrixA, setJacElementFunc setElement)
{
  const int isRowEval = (jacColumns[0].isRowEval == TRUE);
  jacobianColumn_func_ptr evalFunc = isRowEval
      ? data->callback->functionJacADJ_column
      : data->callback->functionJacA_column;

  GC_allow_register_threads();

#pragma omp parallel default(none) shared(data, threadData, jacColumns, spp, matrixA, setElement, evalFunc, isRowEval)
{
  /* Register omp-thread in GC */
  if (!GC_thread_is_registered()) {
    struct GC_stack_base sb;
    memset(&sb, 0, sizeof(sb));
    GC_get_stack_base(&sb);
    GC_register_my_thread(&sb);
  }

  JACOBIAN* t_jac = &(jacColumns[omc_get_thread_num()]);
  const unsigned int activeDim = isRowEval ? t_jac->sizeRows : t_jac->sizeCols;
  const int nRows = (int)t_jac->sizeRows;
  jacobianCleanup_func_ptr cleanupFunc = isRowEval ? evalJacobianCleanupRowEval : evalJacobianCleanupNoop;

  unsigned int color;
#pragma omp for
  for (color = 0; color < spp->maxColors; color++) {
    evalJacobianOneColor(data, threadData, t_jac, NULL, spp, (int)color,
                         activeDim, nRows, matrixA, setElement, evalFunc, cleanupFunc);
  }
} // omp parallel
}
#endif /* USE_PARJAC */


#ifdef USE_PARJAC
/**
 * @brief Allocate thread-local Jacobians for OpenMP-parallel Jacobian evaluation.
 *
 * Creates one JACOBIAN copy per thread, sharing dimensions and sparsePattern
 * from source. source->isRowEval is propagated so adjoint jacColumns work correctly
 * with evalJacobianColoredParallel without extra setup.
 *
 * @param source     Template Jacobian (INDEX_JAC_A for forward, INDEX_JAC_ADJ for adjoint).
 * @param jacColumns Output: array of maxTh JACOBIAN copies.
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
    (*jacColumns)[i].tmpVars       = (double*) calloc(sizeTmpVars, sizeof(double));
    (*jacColumns)[i].resultVars    = (double*) calloc(rows,        sizeof(double));
    (*jacColumns)[i].seedVars      = (double*) calloc(columns,     sizeof(double));
    (*jacColumns)[i].sparsePattern = sparsePattern;
    (*jacColumns)[i].isRowEval     = isRowEval;
  }
  }
}
#endif


/**
 * @brief Evaluate a symbolic Jacobian using the specified method.
 *
 * Dispatches forward (COLOREDSYMJAC/SYMJAC), adjoint (COLOREDSYMJACADJ), and
 * bidirectional (BICOLOREDSYMJAC) evaluation.  All three paths use jac->sparsePattern
 * and the provided setter(s) to write results into outputMatrix.
 *
 * Caller responsibilities before calling:
 *   - set jac->dae_cj if needed
 *   - call setContext / unsetContext around this function
 *   - zero outputMatrix if the format requires it (e.g. sparse SUNDIALS matrix)
 *
 * @param method        COLOREDSYMJAC, SYMJAC, COLOREDSYMJACADJ, or BICOLOREDSYMJAC.
 * @param data          Runtime data.
 * @param threadData    Thread data.
 * @param jac           Primary Jacobian for the method (INDEX_JAC_A or INDEX_JAC_ADJ).
 * @param t_jac         Thread-local copy for parallel eval (equals jac in serial mode).
 * @param outputMatrix  Opaque output buffer forwarded to setFwd / setAdj.
 * @param setFwd        Setter for forward (column) evaluation; also used for BICOLOREDSYMJAC scatter.
 * @param setAdj        Setter for adjoint (row) evaluation; may be NULL for non-adjoint methods.
 */
void evalJacobianByMethod(JACOBIAN_METHOD method,
                          DATA* data, threadData_t* threadData,
                          JACOBIAN* jac, JACOBIAN* t_jac,
                          void* outputMatrix,
                          setJacElementFunc setFwd,
                          setJacElementFunc setAdj)
{
  switch (method)
  {
  case COLOREDSYMJAC:
  case SYMJAC:
#ifndef USE_PARJAC
    evalJacobianColored(data, threadData, t_jac, NULL, outputMatrix, setFwd, NULL);
#else
    evalJacobianColoredParallel(data, threadData, t_jac, jac->sparsePattern, outputMatrix, setFwd);
#endif
    break;

  case COLOREDSYMJACADJ:
#ifndef USE_PARJAC
    evalJacobianColored(data, threadData, t_jac, NULL, outputMatrix, setAdj, evalJacobianCleanupRowEval);
#else
    evalJacobianColoredParallel(data, threadData, t_jac, jac->sparsePattern, outputMatrix, setAdj);
#endif
    break;

  case BICOLOREDSYMJAC: {
    const SPARSE_PATTERN* sp = jac->sparsePattern;
    unsigned int col, nz;
    double* buf = (double*) malloc(sp->nnz * sizeof(double));
    if (!buf) {
      throwStreamPrint(threadData, "evalJacobianByMethod: out of memory (nnz=%u)", sp->nnz);
      return;
    }
    evalJacobianBidirectional(data, threadData, jac, NULL, buf, 0 /* sparse CSC */);
    // scatter into dense?
    for (col = 0; col < jac->sizeCols; col++) {
      for (nz = sp->leadindex[col]; nz < sp->leadindex[col + 1]; nz++) {
        setFwd((int)sp->index[nz], (int)col, (int)nz, buf[nz], outputMatrix, (int)jac->sizeRows);
      }
    }
    free(buf);
    break;
  }

  default:
    throwStreamPrint(threadData, "evalJacobianByMethod: unsupported method %d", (int)method);
    break;
  }
}



#ifdef USE_PARJAC
/** Free JACOBIAN struct */
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




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
/** Allocate thread local Jacobians in case of OpenMP-parallel Jacobian computation.
 *
 * (symbolical only), used in IDA and Dassl.
 */
// ToDo: Make this usable without OpenMP and use it as default!
void allocateThreadLocalJacobians(DATA* data, JACOBIAN** jacColumns)
{
  int maxTh = omc_get_max_threads();
  *jacColumns = (JACOBIAN*) malloc(maxTh*sizeof(JACOBIAN));
  const int index = data->callback->INDEX_JAC_A;
  JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);
  SPARSE_PATTERN* sparsePattern = data->simulationInfo->analyticJacobians[index].sparsePattern;

  unsigned int columns = jac->sizeCols;
  unsigned int rows = jac->sizeRows;
  unsigned int sizeTmpVars = jac->sizeTmpVars;

  unsigned int i;

#ifdef USE_PARJAC
  GC_allow_register_threads();
#endif

#pragma omp parallel default(none) firstprivate(maxTh, columns, rows, sizeTmpVars, index) shared(sparsePattern, jacColumns, i)
  /* Benchmarks indicate that it is beneficial to initialize and malloc the jacColumns using a parallel for loop. */
  {
  /* Register omp-thread in GC */
  if(!GC_thread_is_registered()) {
     struct GC_stack_base sb;
     memset (&sb, 0, sizeof(sb));
     GC_get_stack_base(&sb);
     GC_register_my_thread (&sb);
  }

#pragma omp for schedule(runtime)
  for (i = 0; i < maxTh; ++i) {
    (*jacColumns)[i].sizeCols = columns;
    (*jacColumns)[i].sizeRows = rows;
    (*jacColumns)[i].sizeTmpVars = sizeTmpVars;
    (*jacColumns)[i].tmpVars    = (double*) calloc(sizeTmpVars, sizeof(double));
    (*jacColumns)[i].resultVars = (double*) calloc(rows, sizeof(double));
    (*jacColumns)[i].seedVars   = (double*) calloc(columns, sizeof(double));
    (*jacColumns)[i].sparsePattern = sparsePattern;
  }
  }
}
#endif


/**
 * \brief Generic parallel computation of the colored Jacobian.
 *
 * Exploiting coloring and sparse structure. Used from DASSL and IDA solvers.
 * Only matrix storing format differs for them and therefore setJacElement function
 * is used to access matrix A.
 *
 * \param rows                Number of rows of jacobian.
 * \param columns             Number of columns of jacobian.
 * \param spp                 Pointer to sparse pattern.
 * \param matrixA             Internal data of solvers to store jacobian.
 * \param jacColumns          Analytic Jacobian.
 * \param data                Runtime data struct.
 * \param threadData          Thread data for error handling
 * \param setJacElement       Function to set element (i,j) in matrix A.
 */
void genericColoredSymbolicJacobianEvaluation(int rows, int columns, SPARSE_PATTERN* spp,
                                              void* matrixA, JACOBIAN* jacColumns, DATA* data,
                                              threadData_t* threadData,
                                              setJacElementFunc setJacElement)
{
  (void)rows; (void)columns;

#ifndef USE_PARJAC
  {
    jacobianCleanup_func_ptr cleanup = jacColumns->isRowEval
        ? evalJacobianCleanupRowEval : NULL;
    evalJacobianColored(data, threadData, jacColumns, NULL, matrixA, setJacElement, cleanup);
  }
#else
  evalJacobianColoredParallel(data, threadData, jacColumns, spp, matrixA, setJacElement);
#endif
}

#ifdef USE_PARJAC
/**
 * @brief Allocate thread local Jacobians for adjoint (row-wise) symbolic Jacobian.
 *
 * Like allocateThreadLocalJacobians but uses INDEX_JAC_ADJ and marks each
 * thread-local Jacobian with isRowEval = TRUE so that evalJacobianColoredParallel
 * dispatches to functionJacADJ_column instead of functionJacA_column.
 */
void allocateThreadLocalJacobiansAdj(DATA* data, JACOBIAN** jacColumns)
{
  int maxTh = omc_get_max_threads();
  *jacColumns = (JACOBIAN*) malloc(maxTh * sizeof(JACOBIAN));
  const int index = data->callback->INDEX_JAC_ADJ;
  JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);
  SPARSE_PATTERN* sparsePattern = jac->sparsePattern;

  unsigned int columns     = jac->sizeCols;
  unsigned int rows        = jac->sizeRows;
  unsigned int sizeTmpVars = jac->sizeTmpVars;

  unsigned int i;

  GC_allow_register_threads();

#pragma omp parallel default(none) firstprivate(maxTh, columns, rows, sizeTmpVars, index) shared(sparsePattern, jacColumns, i)
  {
  if (!GC_thread_is_registered()) {
    struct GC_stack_base sb;
    memset(&sb, 0, sizeof(sb));
    GC_get_stack_base(&sb);
    GC_register_my_thread(&sb);
  }

#pragma omp for schedule(runtime)
  for (i = 0; i < maxTh; ++i) {
    (*jacColumns)[i].sizeCols    = columns;
    (*jacColumns)[i].sizeRows    = rows;
    (*jacColumns)[i].sizeTmpVars = sizeTmpVars;
    (*jacColumns)[i].tmpVars     = (double*) calloc(sizeTmpVars, sizeof(double));
    (*jacColumns)[i].resultVars  = (double*) calloc(rows,        sizeof(double));
    (*jacColumns)[i].seedVars    = (double*) calloc(columns,     sizeof(double));
    (*jacColumns)[i].sparsePattern = sparsePattern;
    (*jacColumns)[i].isRowEval   = TRUE;  /* adjoint: seed rows, read column results */
  }
  }
}
#endif

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




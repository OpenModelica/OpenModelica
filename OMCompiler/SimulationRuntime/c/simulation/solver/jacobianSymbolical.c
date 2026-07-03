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

typedef void (*jacobianScatter_func_ptr)(setJacElementFunc setJacElement,
                                         unsigned int activeIndex,
                                         unsigned int currentIndex,
                                         unsigned int nth,
                                         const JACOBIAN* t_jac,
                                         void* matrixA,
                                         int rows);

typedef void (*jacobianCleanup_func_ptr)(JACOBIAN* t_jac, unsigned int rows);

static void scatterRowEval(setJacElementFunc setJacElement,
                           unsigned int activeIndex,
                           unsigned int currentIndex,
                           unsigned int nth,
                           const JACOBIAN* t_jac,
                           void* matrixA,
                           int rows)
{
  (*setJacElement)(activeIndex, currentIndex, nth, t_jac->resultVars[currentIndex], matrixA, rows);
}

static void scatterColumnEval(setJacElementFunc setJacElement,
                              unsigned int activeIndex,
                              unsigned int currentIndex,
                              unsigned int nth,
                              const JACOBIAN* t_jac,
                              void* matrixA,
                              int rows)
{
  (*setJacElement)(currentIndex, activeIndex, nth, t_jac->resultVars[currentIndex], matrixA, rows);
}

static void cleanupRowEval(JACOBIAN* t_jac, unsigned int rows)
{
  unsigned int j;

  /* Avoid accumulation of resultVars and tmpVars between colors for row evaluation. */
  for (j = 0; j < rows; j++) {
    t_jac->resultVars[j] = 0;
  }
  for (j = 0; j < t_jac->sizeTmpVars; j++) {
    t_jac->tmpVars[j] = 0;
  }
}

static void cleanupNoop(JACOBIAN* t_jac, unsigned int rows)
{
  (void)t_jac;
  (void)rows;
}

static void evaluateOneColor(unsigned int color,
                             unsigned int activeDim,
                             unsigned int rows,
                             SPARSE_PATTERN* spp,
                             JACOBIAN* t_jac,
                             DATA* data,
                             threadData_t* threadData,
                             void* matrixA,
                             setJacElementFunc setJacElement,
                             jacobianColumn_func_ptr evalFunc,
                             jacobianScatter_func_ptr scatterFunc,
                             jacobianCleanup_func_ptr cleanupFunc)
{
  unsigned int j, nth, currentIndex;

  for (j = 0; j < activeDim; j++) {
    if (spp->colorCols[j] - 1 == color) {
      t_jac->seedVars[j] = 1;
    }
  }

  evalFunc(data, threadData, t_jac, NULL);

  for (j = 0; j < activeDim; j++) {
    if (spp->colorCols[j] - 1 == color) {
      nth = spp->leadindex[j];
      while (nth < spp->leadindex[j + 1]) {
        currentIndex = spp->index[nth];
        scatterFunc(setJacElement, j, currentIndex, nth, t_jac, matrixA, rows);
        nth++;
      }
      t_jac->seedVars[j] = 0;
    }
  }

  cleanupFunc(t_jac, rows);
}

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

#ifndef USE_PARJAC
  /* Non-parallel path: for column eval, delegate to evalJacobian, which uses the same
   * coloring algorithm through the jacobian->evalColumn function pointer and produces
   * column-major dense output (jac[col * sizeRows + row]) — identical to what
   * setJacElementDasslSparse writes.  This unifies the single-threaded evaluation of
   * jacA_symColored with the evalJacobian path that jacA_symBiColored already uses.
   *
   * Note: the caller may already have invoked constantEqns before this call; evalJacobian
   * will call it again internally.  The double call is redundant and should be cleaned up.
   *
   * Row eval (isRowEval == TRUE) falls through to the serial omp block below because
   * evalJacobian and evalJacobianRow both produce row-major dense output for CSR patterns,
   * whereas setJacElementDasslSparseAdj expects column-major.
   * TODO: Unify the row-eval path once evalJacobianRow output layout is made column-major. */
  // this is now dense output with row major set to reflect the layout of the numerical Jacobian in DASSL
  if (!jacColumns->isRowEval) {
    evalJacobianWithSetDenseElement(data, threadData, jacColumns, NULL, (modelica_real*)matrixA, 1 /* isDense */, setJacobianDenseElementRowMajor);
    return;
  }
#endif /* !USE_PARJAC */

#ifdef USE_PARJAC
  GC_allow_register_threads();
#endif

#pragma omp parallel default(none) firstprivate(columns, rows) \
                                   shared(spp, matrixA, jacColumns, data, threadData, setJacElement)
{
#ifdef USE_PARJAC
  /* Register omp-thread in GC */
  if(!GC_thread_is_registered()) {
     struct GC_stack_base sb;
     memset (&sb, 0, sizeof(sb));
     GC_get_stack_base(&sb);
     GC_register_my_thread (&sb);
  }
  //  printf("My id = %d of max threads= %d\n", omc_get_thread_num(), omp_get_num_threads());
#endif
  JACOBIAN* t_jac = &(jacColumns[omc_get_thread_num()]);

  unsigned int i;
  const int isRowEval = (t_jac->isRowEval == 1);
  const unsigned int activeDim = isRowEval ? (unsigned int) rows : (unsigned int) columns;
  jacobianColumn_func_ptr evalFunc = isRowEval
      ? data->callback->functionJacADJ_column
      : data->callback->functionJacA_column;
  jacobianScatter_func_ptr scatterFunc = isRowEval ? scatterRowEval : scatterColumnEval;
  jacobianCleanup_func_ptr cleanupFunc = isRowEval ? cleanupRowEval : cleanupNoop;

#pragma omp for
  for (i=0; i < spp->maxColors; i++) {
    evaluateOneColor(i, activeDim, (unsigned int) rows, spp, t_jac, data, threadData,
                     matrixA, setJacElement, evalFunc, scatterFunc, cleanupFunc);
   }

} // omp parallel
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




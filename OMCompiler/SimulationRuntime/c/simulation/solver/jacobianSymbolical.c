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
  /* GC_THREADS is normally already set by the build system (the omcgc target
     defines it PUBLIC-ly); define it here as well for builds that do not. */
  #ifndef GC_THREADS
    #define GC_THREADS
  #endif
  #include <gc/omc_gc.h>
#endif

#include <string.h>

#include "jacobianSymbolical.h"
#include "util/omc_error.h"

#ifdef USE_PARJAC
/** Allocate thread local Jacobians in case of OpenMP-parallel Jacobian computation.
 *
 * (symbolical only), used in IDA and Dassl.
 *
 * Each thread gets its own seedVars/tmpVars/resultVars working vectors. Everything
 * else (sparse pattern, evaluation DAG, function pointers, coloring direction, ...)
 * is read-only during the evaluation and is shared with the Jacobian the copies were
 * made from.
 *
 * \param data            Runtime data struct.
 * \param jacColumns      On output an array of omc_get_max_threads() Jacobians.
 * \param jacobianIndex   Index into data->simulationInfo->analyticJacobians of the
 *                        Jacobian that is evaluated in parallel (INDEX_JAC_A or
 *                        INDEX_JAC_ADJ).
 */
// ToDo: Make this usable without OpenMP and use it as default!
void allocateThreadLocalJacobians(DATA* data, JACOBIAN** jacColumns, int jacobianIndex)
{
  const int maxTh = omc_get_max_threads();
  JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[jacobianIndex]);
  int i;

  *jacColumns = (JACOBIAN*) malloc(maxTh*sizeof(JACOBIAN));
  assertStreamPrint(NULL, *jacColumns != NULL, "allocateThreadLocalJacobians: Out of memory.");

  for (i = 0; i < maxTh; ++i) {
    JACOBIAN* t_jac = &((*jacColumns)[i]);
    /* Start from an exact copy so that all fields that the generated column
       function relies on (evalColumn, dag, isRowEval, dae_cj, bidirectional
       data, ...) are set, then hand out private working vectors. */
    memcpy(t_jac, jac, sizeof(JACOBIAN));
    t_jac->seedVars   = (modelica_real*) calloc(jac->sizeCols, sizeof(modelica_real));
    t_jac->resultVars = (modelica_real*) calloc(jac->sizeRows, sizeof(modelica_real));
    t_jac->tmpVars    = (modelica_real*) calloc(jac->sizeTmpVars, sizeof(modelica_real));
    assertStreamPrint(NULL, t_jac->seedVars != NULL && t_jac->resultVars != NULL
                            && (jac->sizeTmpVars == 0 || t_jac->tmpVars != NULL),
                      "allocateThreadLocalJacobians: Out of memory.");
  }
}

/** Propagate the per-evaluation state of the master Jacobian to the thread local copies.
 *
 * Has to be called before every parallel evaluation and after the constant equations
 * of the Jacobian have been evaluated: the constant equations write seed independent
 * partial derivatives into jac->tmpVars which every column evaluation reads, so each
 * thread needs its own up to date copy of them.
 *
 * \param jacColumns  Array of thread local Jacobians.
 * \param jac         Jacobian the copies were made from.
 */
void syncThreadLocalJacobians(JACOBIAN* jacColumns, const JACOBIAN* jac)
{
  const int maxTh = omc_get_max_threads();
  int i;

  for (i = 0; i < maxTh; ++i) {
    jacColumns[i].dae_cj = jac->dae_cj;
    if (jac->sizeTmpVars > 0) {
      memcpy(jacColumns[i].tmpVars, jac->tmpVars, jac->sizeTmpVars*sizeof(modelica_real));
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

  unsigned int i, j, currentIndex, nth;

#pragma omp for
  for (i=0; i < spp->maxColors; i++) {
     if (t_jac->isRowEval == 1) {
       /* Row evaluation: sparse pattern is CSR, colorCols encodes row colors. */
       for (j=0; j < rows; j++) {
         if (spp->colorCols[j]-1 == i) {
           t_jac->seedVars[j] = 1;
         }
       }

       data->callback->functionJacADJ_column(data, threadData, t_jac, NULL);

       for (j=0; j < rows; j++) {
         if (spp->colorCols[j]-1 == i) {
           nth = spp->leadindex[j];
           while (nth < spp->leadindex[j+1]) {
             currentIndex = spp->index[nth];
             (*setJacElement)(j, currentIndex, nth, t_jac->resultVars[currentIndex], matrixA, rows);
             nth++;
           }
           t_jac->seedVars[j] = 0;
         }
       }
       // avoid accumulation
       for (j=0; j < rows; j++) {
          t_jac->resultVars[j] = 0;
       }
       // reset tmp vars
       for (j=0; j < t_jac->sizeTmpVars; j++) {
          t_jac->tmpVars[j] = 0;
       }
     } else {
       /* Column evaluation: sparse pattern is CSC, colorCols encodes column colors. */
       for (j=0; j < columns; j++) {
         if (spp->colorCols[j]-1 == i) {
           t_jac->seedVars[j] = 1;
         }
       }

       data->callback->functionJacA_column(data, threadData, t_jac, NULL);

       for (j=0; j < columns; j++) {
         if (spp->colorCols[j]-1 == i) {
           nth = spp->leadindex[j];
           while (nth < spp->leadindex[j+1]) {
             currentIndex = spp->index[nth];
             (*setJacElement)(currentIndex, j, nth, t_jac->resultVars[currentIndex], matrixA, rows);
             nth++;
           }
           t_jac->seedVars[j] = 0;
         }
       }
     }
   }

} // omp parallel
}

#ifdef USE_PARJAC
/** Free the thread local Jacobians allocated by allocateThreadLocalJacobians().
 *
 * Only the private working vectors are owned by the copies; the sparse pattern,
 * the evaluation DAG and the bidirectional data belong to the Jacobian they were
 * copied from and must not be freed here.
 */
void freeAnalyticalJacobian(JACOBIAN** jacColumns)
{
  const int maxTh = omc_get_max_threads();
  int i;

  if (*jacColumns == NULL) {
    return;
  }

  for (i = 0; i < maxTh; ++i) {
    free((*jacColumns)[i].tmpVars);
    free((*jacColumns)[i].resultVars);
    free((*jacColumns)[i].seedVars);
  }

  free(*jacColumns);
  *jacColumns = NULL;
}
#endif




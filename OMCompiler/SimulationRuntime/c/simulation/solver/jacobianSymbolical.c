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

 /*! \file jacobian_symbolical.c
 */

#ifdef USE_PARJAC
  #define GC_THREADS
  #include <gc/omc_gc.h>
#endif

#include "simulation/solver/jacobianSymbolical.h"

#ifdef USE_PARJAC
/** Allocate thread local Jacobians in case of OpenMP-parallel Jacobian computation.
 *
 * (symbolical only), used in IDA and Dassl.
 */
// ToDo: Make this usable without OpenMP and use it as default!
void allocateThreadLocalJacobians(DATA* data, ANALYTIC_JACOBIAN** jacColumns)
{
  int maxTh = omc_get_max_threads();
  *jacColumns = (ANALYTIC_JACOBIAN*) malloc(maxTh*sizeof(ANALYTIC_JACOBIAN));
  const int index = data->callback->INDEX_JAC_A;
  ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);
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
 * Only matrix storing format differs for them and therefore setJacElementFunc
 * is used to access matrix A.
 *
 * \param [in]      rows                Number of rows of jacobian.
 * \param [in]      columns             Number of columns of jacobian.
 * \param [in]      spp                 Pointer to sparse pattern.
 * \param [in/out]  matrixA             Internal data of solvers to store jacobian.
 * \param [in]      jacColumns          Number of colors (=number of columns for compressed structure) of jacobian.
 * \param [in]      data
 * \param [in]      threadData
 * \param [in]      setJacElementFunc   Function to set element (i,j) in matrix A.
 */
void genericColoredSymbolicJacobianEvaluation(int rows, int columns, SPARSE_PATTERN* spp,
                                              void* matrixA, ANALYTIC_JACOBIAN* jacColumns, DATA* data,
                                              threadData_t* threadData,
                                              void (*setJacElement)(int, int, int, double, void*, int))
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
  ANALYTIC_JACOBIAN* t_jac = &(jacColumns[omc_get_thread_num()]);

  unsigned int i, j, currentIndex, nth;

#pragma omp for
  for (i=0; i < spp->maxColors; i++) {
    /* Set seed vector for current color */
    for (j=0; j < columns; j++) {
      if (spp->colorCols[j]-1 == i) {
        t_jac->seedVars[j] = 1;
      }
    }

    /* Evaluate with updated seed vector */
    data->callback->functionJacA_column(data, threadData, t_jac, NULL);
    /* Save jacobian elements in matrixA*/
    for (j=0; j < columns; j++) {
      if (t_jac->seedVars[j] == 1) {
        nth = spp->leadindex[j];
        while (nth < spp->leadindex[j+1]) {
          currentIndex = spp->index[nth];
          (*setJacElement)(currentIndex, j, nth, t_jac->resultVars[currentIndex], matrixA, rows);
          nth++;
        }
      }
    }

    /* Reset seed vector */
    for (j=0; j < columns; j++) {
      t_jac->seedVars[j] = 0;
    }
  }
} // omp parallel
}

#ifdef USE_PARJAC
/** Free ANALYTIC_JACOBIAN struct */
void freeAnalyticalJacobian(ANALYTIC_JACOBIAN** jacColumns)
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

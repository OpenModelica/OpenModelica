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
void initAnalyticJacobian(ANALYTIC_JACOBIAN* jacobian, unsigned int sizeCols, unsigned int sizeRows, unsigned int sizeTmpVars, int (*constantEqns)(void* data, threadData_t *threadData, void* thisJacobian, void* parentJacobian), SPARSE_PATTERN* sparsePattern) {
  jacobian->sizeCols = sizeCols;
  jacobian->sizeRows = sizeRows;
  jacobian->sizeTmpVars = sizeTmpVars;
  jacobian->seedVars = (modelica_real*) calloc(sizeCols, sizeof(modelica_real));
  jacobian->resultVars = (modelica_real*) calloc(sizeRows, sizeof(modelica_real));
  jacobian->tmpVars = (modelica_real*) calloc(sizeTmpVars, sizeof(modelica_real));
  jacobian->constantEqns = constantEqns;
  jacobian->sparsePattern = sparsePattern;
}

/**
 * @brief Copy analytic Jacobian.
 *
 * Sparsity pattern is not copied, only the pointer to it.
 *
 * @param source                  Jacobian that should be copied.
 * @return ANALYTIC_JACOBIAN*     Copy of source.
 */
ANALYTIC_JACOBIAN* copyAnalyticJacobian(ANALYTIC_JACOBIAN* source) {
  ANALYTIC_JACOBIAN* jacobian = (ANALYTIC_JACOBIAN*) malloc(sizeof(ANALYTIC_JACOBIAN));
  initAnalyticJacobian(jacobian,
                       source->sizeCols,
                       source->sizeRows,
                       source->sizeTmpVars,
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
void freeAnalyticJacobian(ANALYTIC_JACOBIAN *jac) {
  if (jac == NULL) {
    return;
  }
  free(jac->seedVars); jac->seedVars = NULL;
  free(jac->tmpVars); jac->tmpVars = NULL;
  free(jac->resultVars); jac->resultVars = NULL;
  freeSparsePattern(jac->sparsePattern);
  free(jac->sparsePattern); jac->sparsePattern = NULL;
}

/**
 * @brief Allocate memory for sparsity pattern.
 *
 * @param n_leadIndex         Number of rows or columns of Matrix.
 *                            Depending on compression type CSR (-->rows) or CSC (-->columns).
 * @param numberOfNonZeros    Numbe rof non-zero elements in Matrix.
 * @param maxColors           Maximum number of colors of Matrix.
 * @return SPARSE_PATTERN*    Pointer ot allocated sparsity pattern of Matrix.
 */
SPARSE_PATTERN* allocSparsePattern(unsigned int n_leadIndex, unsigned int numberOfNonZeros, unsigned int maxColors) {
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
 * @brief Free sparsity pattern
 *
 * @param spp   Pointer to sparsity pattern
 */
void freeSparsePattern(SPARSE_PATTERN *spp) {
  if (spp != NULL) {
    free(spp->index); spp->index = NULL;
    free(spp->colorCols); spp->colorCols = NULL;
    free(spp->leadindex); spp->leadindex = NULL;
  }
}


const char* COLORS[8] = {"\x1B[0m",
                         "\x1B[31m",
                         "\x1B[32m",
                         "\x1B[33m",
                         "\x1B[34m",
                         "\x1B[35m",
                         "\x1B[36m",
                         "\x1B[37m"};

/**
 * @brief Print Jacobian with colored columns.
 *
 * jacobianData needs to have all jacobianColumns.
 * Basically copy each column from jac->resultVars into jacobianData.
 *
 * Can only print colors if sparsePattern->maxColors smaller then 8.
 *
 * @param jac             Analytic Jacobian.
 * @param sparsePattern   Sparsity pattern of Jacobian.
 * @param jacobianData    Array with all columns from Jacobian column evaluations.
 * @param stream          Stream to print to.
 * @param name            Name of Jacobian
 */
void printSparseJacobian(ANALYTIC_JACOBIAN *jac, SPARSE_PATTERN *sparsePattern, double* jacobianData, int stream, const char* name)
{
  /* Variables */
  unsigned int row, col, i, j;
  unsigned int buffer_idx;
  unsigned int color;
  modelica_boolean useColor;
  int sizeRows;
  int sizeCols;
  char *buffer;

  if (!ACTIVE_STREAM(stream))
  {
    return;
  }

  /* Catch empty jacobian */
  if (jac == NULL)
  {
    infoStreamPrint(stream, 0, "No sparse structure available for \"%s\".", name);
    return;
  }
  sizeRows = jac->sizeRows;
  sizeCols = jac->sizeCols;

  /* Catch empty sparsePattern */
  if (sparsePattern == NULL || sizeRows <= 0 || sizeCols <= 0)
  {
    infoStreamPrint(stream, 0, "No sparse structure available for \"%s\".", name);
    return;
  }

  useColor = sparsePattern->maxColors < 8;
  //useColor = 0;

  buffer = (char*)omc_alloc_interface.malloc(sizeof(char)*16*sizeCols + 4);

  infoStreamPrint(stream, 1, "%s [size: %ux%u]", name, sizeRows, sizeCols);
  infoStreamPrint(stream, 0, "%u non-zero elements", sparsePattern->numberOfNonZeros);

  int cnt = 0;
  i=0;
  for(row=0; row < sizeRows; row++)
  {
    j=0;
    buffer_idx = 0;
    for(col=0; i < sparsePattern->leadindex[row+1]; col++)
    {
      if(sparsePattern->index[i] == col)
      {
        if (jacobianData[cnt] >= 0) {
          buffer_idx += sprintf(&buffer[buffer_idx], " ");
        }
        if (useColor) {
           color = sparsePattern->colorCols[col];
        } else {
          color = 0;
        }
        buffer_idx += sprintf(&buffer[buffer_idx], "%s%e\e[0m", COLORS[color], jacobianData[cnt]);
        cnt++;
        i++;
        j++;
      }
      else
      {
        buffer_idx += sprintf(&buffer[buffer_idx], "             ");
      }
      buffer_idx += sprintf(&buffer[buffer_idx], "  ");
    }
    infoStreamPrint(stream, 0, "%s", buffer);
  }
  messageClose(stream);
}

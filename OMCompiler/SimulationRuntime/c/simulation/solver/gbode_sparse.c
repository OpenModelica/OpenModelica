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

/*! \file gbode_sparse.c
 */

#include "gbode_main.h"
#include "gbode_util.h"

#include "model_help.h"
#include "simulation_data.h"
#include "solver_main.h"

#include <limits.h>

/**
 * Greedily pack structurally independent columns into colors.
 *
 * This works directly on CSC data in O(colors * (nnz + columns)) time and
 * O(rows) workspace.
 */
static void colorSparsePattern(SPARSE_PATTERN *pattern, int sizeRows, int sizeCols, int nStages, unsigned int *work)
{
  assertStreamPrint(NULL, sizeRows >= 0 && sizeCols >= 0 && nStages > 0 && sizeCols % nStages == 0,
                    "Invalid GBODE sparse coloring dimensions %d x %d with %d stages.", sizeRows, sizeCols, nStages);
  if (sizeCols == 0)
  {
    pattern->maxColors = 0;
    return;
  }
  modelica_boolean ownsWork = work == NULL;
  if (ownsWork)
  {
    work = malloc(sizeRows * sizeof(unsigned int));
  }

  unsigned int color = 0;
  const int stageSize = sizeCols / nStages;
  memset(pattern->colorCols, 0, sizeCols * sizeof(unsigned int));
  memset(work, 0, sizeRows * sizeof(unsigned int));
  for (int stage = 0; stage < nStages; stage++)
  {
    const int firstCol = stage * stageSize;
    const int endCol = firstCol + stageSize;
    int remaining = stageSize;
    while (remaining > 0)
    {
      color++;

      for (int col = firstCol; col < endCol; col++)
      {
        if (pattern->colorCols[col])
        {
          continue;
        }

        modelica_boolean conflict = FALSE;
        for (unsigned int nz = pattern->leadindex[col]; nz < pattern->leadindex[col + 1]; nz++)
        {
          if (work[pattern->index[nz]] == color)
          {
            conflict = TRUE;
            break;
          }
        }
        if (conflict)
        {
          continue;
        }

        pattern->colorCols[col] = color;
        remaining--;
        for (unsigned int nz = pattern->leadindex[col]; nz < pattern->leadindex[col + 1]; nz++)
        {
          work[pattern->index[nz]] = color;
        }
      }
    }
  }

  pattern->maxColors = color;
  if (ownsWork)
  {
    free(work);
  }
}

static SPARSE_PATTERN *copySparsePattern(const SPARSE_PATTERN *source, int size, modelica_boolean copyColoring)
{
  SPARSE_PATTERN *copy = allocSparsePattern(size, source->nnz, size);
  memcpy(copy->leadindex, source->leadindex, (size + 1) * sizeof(unsigned int));
  memcpy(copy->index, source->index, source->nnz * sizeof(unsigned int));
  if (copyColoring)
  {
    memcpy(copy->colorCols, source->colorCols, size * sizeof(unsigned int));
    copy->maxColors = source->maxColors;
  }
  else
  {
    memset(copy->colorCols, 0, size * sizeof(unsigned int));
    copy->maxColors = 0;
  }
  return copy;
}

// Build struct(I + J), optionally coloring it, allocating a pattern when target is NULL
static SPARSE_PATTERN *sparsePatternWithDiagonal(const SPARSE_PATTERN *source, int size, SPARSE_PATTERN *target, unsigned int *work,
                                                 modelica_boolean colorPattern, modelica_boolean reuseSourceColoring)
{
  int diagonalCount = 0;

  if (target == NULL)
  {
    for (int col = 0; col < size; col++)
    {
      for (unsigned int nz = source->leadindex[col]; nz < source->leadindex[col + 1]; nz++)
      {
        if (source->index[nz] == col)
        {
          diagonalCount++;
          break;
        }
      }
    }
    target = allocSparsePattern(size, source->nnz + size - diagonalCount, size);
  }

  unsigned int targetNz = 0;
  diagonalCount = 0;
  target->leadindex[0] = 0;
  for (int col = 0; col < size; col++)
  {
    modelica_boolean diagonalPresent = FALSE;
    for (unsigned int nz = source->leadindex[col]; nz < source->leadindex[col + 1]; nz++)
    {
      unsigned int row = source->index[nz];
      if (!diagonalPresent && row > col)
      {
        target->index[targetNz++] = col;
        diagonalPresent = TRUE;
      }
      if (row == col)
      {
        diagonalPresent = TRUE;
        diagonalCount++;
      }
      target->index[targetNz++] = row;
    }
    if (!diagonalPresent)
    {
      target->index[targetNz++] = col;
    }
    target->leadindex[col + 1] = targetNz;
  }
  target->nnz = targetNz;

  if (!colorPattern)
  {
    memset(target->colorCols, 0, size * sizeof(unsigned int));
    target->maxColors = 0;
  }
  else if (reuseSourceColoring && diagonalCount == size && source->maxColors > 0)
  {
    memcpy(target->colorCols, source->colorCols, size * sizeof(unsigned int));
    target->maxColors = source->maxColors;
  }
  else
  {
    colorSparsePattern(target, size, size, 1, work);
  }

  return target;
}

// Reduce a square CSC pattern to the principal submatrix selected by indices
static void reduceSparsePattern(const SPARSE_PATTERN *source, int sourceSize, SPARSE_PATTERN *target,
                                const int *indices, int targetSize, unsigned int *work)
{
  for (int i = 0; i < sourceSize; i++)
  {
    work[i] = UINT_MAX;
  }
  for (int i = 0; i < targetSize; i++)
  {
    work[indices[i]] = i;
  }

  unsigned int targetNz = 0;
  target->leadindex[0] = 0;
  for (int col = 0; col < targetSize; col++)
  {
    int sourceCol = indices[col];
    for (unsigned int nz = source->leadindex[sourceCol]; nz < source->leadindex[sourceCol + 1]; nz++)
    {
      unsigned int row = work[source->index[nz]];
      if (row != UINT_MAX)
      {
        target->index[targetNz++] = row;
      }
    }
    target->leadindex[col + 1] = targetNz;
  }
  target->nnz = targetNz;
  memset(target->colorCols, 0, targetSize * sizeof(unsigned int));
  target->maxColors = 0;
}

void gbodeMapSparsePattern(const SPARSE_PATTERN *source, const SPARSE_PATTERN *target,
                           int size, int *sourceToTarget, int *targetDiagonal)
{
  for (int col = 0; col < size; col++)
  {
    unsigned int sourceNz = source->leadindex[col];
    unsigned int sourceEnd = source->leadindex[col + 1];
    targetDiagonal[col] = -1;

    for (unsigned int targetNz = target->leadindex[col]; targetNz < target->leadindex[col + 1]; targetNz++)
    {
      unsigned int targetRow = target->index[targetNz];
      if (targetRow == col)
      {
        targetDiagonal[col] = targetNz;
      }
      if (sourceNz < sourceEnd && source->index[sourceNz] == targetRow)
      {
        sourceToTarget[sourceNz++] = targetNz;
      }
    }

    assertStreamPrint(NULL, targetDiagonal[col] >= 0 && sourceNz == sourceEnd, "GBODE sparse pattern mapping failed in column %d.", col);
  }
}

// Create the struct(I + J) pattern used by block solves
static SPARSE_PATTERN* initializeSparsePatternBlock(DATA* data, modelica_boolean colorPattern)
{
  JACOBIAN *jacobian = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
  return sparsePatternWithDiagonal(jacobian->sparsePattern, jacobian->sizeRows, NULL, NULL, colorPattern, TRUE);
}

static SPARSE_PATTERN* initializeSparsePattern_IRK(DATA* data);

void initializeSparsePattern_GBODE(DATA* data, DATA_GBODE* gbData)
{
  assertStreamPrint(NULL, !gbData->isExplicit,
                    "Cannot initialize GBODE sparsity for an explicit method.");
  if (gbData->type == GM_TYPE_IMPLICIT && gbData->nlsSolverMethod != GB_NLS_INTERNAL)
  {
    gbData->sparsePattern_NLS = initializeSparsePattern_IRK(data);
  }
  else
  {
    gbData->sparsePattern_NLS = initializeSparsePatternBlock(data, gbData->nlsSolverMethod != GB_NLS_INTERNAL);
  }
}

void initializeSparsePattern_GBODEF(DATA* data, DATA_GBODEF* gbfData)
{
  assertStreamPrint(NULL, !gbfData->isExplicit,
                    "Cannot initialize GBODEF sparsity for an explicit method.");
  JACOBIAN *jacobian = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
  const modelica_boolean useInternal = gbfData->nlsSolverMethod == GB_NLS_INTERNAL;
  gbfData->sparseWork = malloc(jacobian->sizeRows * sizeof(unsigned int));
  gbfData->sparsePattern_ODE = copySparsePattern(jacobian->sparsePattern, jacobian->sizeRows, useInternal);
  gbfData->sparsePattern_NLS = sparsePatternWithDiagonal(jacobian->sparsePattern, jacobian->sizeRows,
                                                         NULL, gbfData->sparseWork, !useInternal, TRUE);
}

void updateSparsePattern_GBODEF(DATA* data, DATA_GBODE* gbData)
{
  DATA_GBODEF *gbfData = gbData->gbfData;
  SPARSE_PATTERN *fullPattern = data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern;

  reduceSparsePattern(fullPattern, gbData->nStates, gbfData->sparsePattern_ODE, gbData->fastStatesIdx, gbData->nFastStates, gbfData->sparseWork);
  if (gbfData->nlsSolverMethod == GB_NLS_INTERNAL)
  {
    colorSparsePattern(gbfData->sparsePattern_ODE, gbData->nFastStates, gbData->nFastStates, 1, gbfData->sparseWork);
  }

  sparsePatternWithDiagonal(gbfData->sparsePattern_ODE, gbData->nFastStates, gbfData->sparsePattern_NLS,
                            gbfData->sparseWork, gbfData->nlsSolverMethod != GB_NLS_INTERNAL, FALSE);

  printSparseStructure(gbfData->sparsePattern_NLS, gbData->nFastStates, gbData->nFastStates, OMC_LOG_GBODE_V, "sparsePattern_MR");
}

/**
 * @brief Initialize sparsity pattern for non-linear system of full implicit Runge-Kutta methods.
 *
 * Get sparsity pattern of ODE Jacobian and map it on the different stages taking into account
 * the non-zero elements of the A matrix in the Butcher-tableau
 * Coloring will be calculated, whereby different stages will have different colors, due to the
 * column-wise calculation of the Jacobian
 *
 * @param data                Runtime data struct.
 * @return SPARSE_PATTERN*    Pointer to sparsity pattern of non-linear system.
 */
static SPARSE_PATTERN* initializeSparsePattern_IRK(DATA* data)
{
  unsigned int i,j,k,l;
  unsigned int row, col;
  unsigned int missingZeros = 0;
  unsigned int nDiags = 0, nDiags_A, nnz_A;
  unsigned int shift = 0;
  modelica_boolean diagElemNonZero;
  SPARSE_PATTERN* sparsePattern_IRK;
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;

  /* Get Sparsity of ODE Jacobian */
  JACOBIAN* jacobian = getSymbolicOdeJacobian(data);
  SPARSE_PATTERN* sparsePattern_ODE = getJacobianCscPattern(jacobian);

  int sizeRows = jacobian->sizeRows;
  int sizeCols = jacobian->sizeCols;
  int nStages  = gbData->tableau->nStages;
  int nStates  = gbData->nStates;
  double* A    = gbData->tableau->A;

  printSparseStructure(sparsePattern_ODE,
                       sizeRows,
                       sizeCols,
                       OMC_LOG_GBODE_V,
                       "sparsePatternODE");

  nnz_A = 0;
  nDiags_A = 0;
  for (i=0; i<nStages; i++) {
     if (A[i*nStages + i] != 0) nDiags_A++;
     for (j=0; j<nStages; j++) {
       if (A[i*nStages + j] != 0) nnz_A++;
     }
  }

  i = 0;
  for(col=0; col < sizeRows; col++) {
    for(; i < sparsePattern_ODE->leadindex[col+1];) {
      if(sparsePattern_ODE->index[i++] == col) {
        nDiags++;
      }
    }
  }
  int missingDiags = jacobian->sizeRows - nDiags;
  int nnz = nnz_A*sparsePattern_ODE->nnz + nDiags_A*missingDiags + (nStages-nDiags_A)*nStates;

  // first generated a coordinate format and transform this later to Column pressed format
  int *coo_col = (int*) malloc(nnz*sizeof(int));
  int *coo_row = (int*) malloc(nnz*sizeof(int));

  i = 0;
  for (k=0; k<nStages; k++)
  {
    for (col=0; col < nStates; col++)
    {
      diagElemNonZero = FALSE;
      for (l=0; l<nStages; l++)
      {
        for (j=sparsePattern_ODE->leadindex[col]; j<sparsePattern_ODE->leadindex[col+1]; j++)
        {
          if (((col + k*nStates) < (sparsePattern_ODE->index[j] + l*nStates)) && !diagElemNonZero)
          {
            coo_col[i] = col + k*nStates;
            coo_row[i] = col + k*nStates;
            i++;
            diagElemNonZero = TRUE;
          }
          // if the entry in A is non-zero, the sparsity pattern of the ODE-Jacobian will be inserted,
          // respectively
          if (A[l*nStages + k] != 0)
          {
            if ((col + k*nStates) == (sparsePattern_ODE->index[j] + l*nStates))
              diagElemNonZero = TRUE;
            coo_col[i] = col + k*nStates;
            coo_row[i] = sparsePattern_ODE->index[j] + l*nStates;
            i++;
          }
        }
      }
      if (!diagElemNonZero) {
        coo_col[i] = col + k*nStates;
        coo_row[i] = col + k*nStates;
        i++;
        diagElemNonZero = TRUE;
      }
    }
  }

  nnz = i;

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)){
    printIntVector_gb(OMC_LOG_GBODE_V, "rows", coo_row, nnz, 0.0);
    printIntVector_gb(OMC_LOG_GBODE_V, "cols", coo_col, nnz, 0.0);
  }

  int length_row_indices = jacobian->sizeCols*nStages+1;

  // Allocate memory for new sparsity pattern
  sparsePattern_IRK = allocSparsePattern(jacobian->sizeCols*nStages, nnz, jacobian->sizeCols*nStages);

  /* Set diagonal elements of sparsitiy pattern to non-zero */
  for (i=0; i<length_row_indices; i++)
    sparsePattern_IRK->leadindex[i] = 0;

  for (int i = 0; i < nnz; i++)
  {
    sparsePattern_IRK->index[i] = coo_row[i];
    sparsePattern_IRK->leadindex[coo_col[i] + 1]++;
  }
  for (int i = 0; i < sizeCols*nStages; i++)
  {
    sparsePattern_IRK->leadindex[i + 1] += sparsePattern_IRK->leadindex[i];
  }

  free(coo_col);
  free(coo_row);

  colorSparsePattern(sparsePattern_IRK, sizeRows*nStages, sizeCols*nStages, nStages, NULL);

  return sparsePattern_IRK;
}

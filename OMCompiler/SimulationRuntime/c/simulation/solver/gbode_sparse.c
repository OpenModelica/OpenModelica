/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2022, Open Source Modelica Consortium (OSMC),
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

/*! \file gbode_sparse.c
 */

#include "gbode_main.h"
#include "gbode_util.h"

#include "model_help.h"
#include "simulation_data.h"
#include "solver_main.h"

// TODO: Describe me
// TODO: Don't allocate memory for leadindex at each call but give it a work array
void sparsePatternTranspose(int sizeRows, int sizeCols, SPARSE_PATTERN* sparsePattern, SPARSE_PATTERN* sparsePatternT)
{
  unsigned int i, j, loc;
  int* leadindex = calloc(sizeCols, sizeof(int));

  for (i=0; i < sparsePattern->numberOfNonZeros; i++)
  {
    leadindex[sparsePattern->index[i]]++;
  }
  sparsePatternT->leadindex[0] = 0;
  for(i=1;i<sizeCols+1;i++)
  {
    sparsePatternT->leadindex[i] = sparsePatternT->leadindex[i-1] + leadindex[i-1];
  }
  memcpy(leadindex, sparsePatternT->leadindex, sizeof(unsigned int)*sizeCols);
  for (i=0,j=0;i<sizeRows;i++)
  {
    for(; j < sparsePattern->leadindex[i+1];) {
      loc = leadindex[sparsePattern->index[j]];
      sparsePatternT->index[loc] = i;
      leadindex[sparsePattern->index[j]]++;
      j++;
    }
  }
  printSparseStructure(sparsePattern,
                       sizeRows,
                       sizeCols,
                       OMC_LOG_GBODE_V,
                       "sparsePattern");
  printSparseStructure(sparsePatternT,
                       sizeRows,
                       sizeCols,
                       OMC_LOG_GBODE_V,
                       "sparsePatternT");

  free(leadindex);
}

/**
 * @brief Simple sparse matrix coloring.
 *
 * Determine column by column the next possible color,
 * by looking at columns with values in corresponding rows (transpose matrix necessary)
 *
 * @param sparsePattern Sparse pattern of the matirx
 * @param sizeRows      Number or rows
 * @param sizeCols      Number of columns
 * @param nStages       Number of stages (different stages will get different color for full
 *                      implicit RK methods)
 */
void ColoringAlg(SPARSE_PATTERN* sparsePattern, int sizeRows, int sizeCols, int nStages)
{
  SPARSE_PATTERN* sparsePatternT;
  int row, col, nCols, leadIdx;
  int i, j, maxColors = 0;

  // initialize array to zeros
  int* tabu;
  tabu = (int*) calloc(sizeCols*sizeCols, sizeof(int));

  // Allocate memory for new sparsity pattern
  sparsePatternT = allocSparsePattern(sizeCols, sparsePattern->numberOfNonZeros, sizeCols);

  // Determine the sparse pattern of the transposed matrix
  sparsePatternTranspose(sizeRows, sizeCols, sparsePattern, sparsePatternT);

  // Projection of the stages on the ODE jacobian
  int sizeCols_ODE = sizeCols/nStages;
  int act_stage;

  for (col=0; col<sizeCols; col++)
  {
    // Look for the next free color, based on the tabu list
    for (i=0; i<sizeCols ; i++)
    {
      if (tabu[col*sizeCols + i] == 0)
      {
        sparsePattern->colorCols[col] = i+1;
        maxColors = fmax(maxColors, i+1);

        // set tabu for columns that have entries in the same row!
        for (row=sparsePattern->leadindex[col]; row<sparsePattern->leadindex[col+1]; row++)
        {
          int rowIdx = sparsePattern->index[row];
          for (j=sparsePatternT->leadindex[rowIdx]; j<sparsePatternT->leadindex[rowIdx+1]; j++)
          {
            tabu[sparsePatternT->index[j]*sizeCols + i]=1;
          }
        }

        // each stage has different colors, due to the columnwise jacobian calculation
        // only important and utilized, if a fully implicit RK-method is used
        act_stage = col/sizeCols_ODE;
        for (j=(act_stage+1)*sizeCols_ODE; j<sizeCols; j++)
        {
          tabu[j*sizeCols + i]=1;
        }

        break;
      }
    }
  }
  sparsePattern->maxColors = maxColors;

  // free memory allocation for the transposed sprasity pattern
  freeSparsePattern(sparsePatternT);
  free(sparsePatternT);
  free(tabu);
}


/**
 * @brief Initialize sparsity pattern for non-linear system of diagonal implicit Runge-Kutta methods.
 *
 * Get sparsity pattern of ODE Jacobian and edit to be non-zero on diagonal elements.
 * Coloring of ODE Jacobian will be used, if it had non-zero elements on all diagonal entries.
 * Calculate coloring otherwise.
 *
 * @param data                Runtime data struct.
 * @param sysData             Non-linear system.
 * @return SPARSE_PATTERN*    Pointer to sparsity pattern of non-linear system.
 */
SPARSE_PATTERN* initializeSparsePattern_SR(DATA* data, NONLINEAR_SYSTEM_DATA* sysData)
{
  unsigned int i,j;
  unsigned int row, col;
  unsigned int missingZeros = 0;
  unsigned int nDiags = 0;
  unsigned int shift = 0;
  modelica_boolean diagElemNonZero;
  SPARSE_PATTERN* sparsePattern_DIRK;

  /* Get Sparsity of ODE Jacobian */
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  SPARSE_PATTERN* sparsePattern_ODE = jacobian->sparsePattern;

  int sizeRows = jacobian->sizeRows;
  int sizeCols = jacobian->sizeCols;

  /* Compute size of new sparsitiy pattern
   * Increase the size to contain non-zero elements on diagonal. */
  i = 0;
  for(row=0; row < sizeRows; row++) {
    for(; i < sparsePattern_ODE->leadindex[row+1]; i++) {
      if(sparsePattern_ODE->index[i] == row) {
        nDiags++;
      }
    }
  }
  int missingDiags = jacobian->sizeRows - nDiags;
  int length_index = jacobian->sparsePattern->numberOfNonZeros + missingDiags;

  // Allocate memory for new sparsity pattern
  sparsePattern_DIRK = allocSparsePattern(sizeRows, length_index, sizeCols);

  /* Set diagonal elements of sparsitiy pattern to non-zero */
  i = 0;
  j = 0;
  sparsePattern_DIRK->leadindex[0] = sparsePattern_ODE->leadindex[0];
  for(row=0; row < sizeRows; row++) {
    diagElemNonZero = FALSE;
    int leadIdx = sparsePattern_ODE->leadindex[row+1];
    for(; j < leadIdx;) {
      if(sparsePattern_ODE->index[j] == row) {
        diagElemNonZero = TRUE;
        sparsePattern_DIRK->leadindex[row+1] = sparsePattern_ODE->leadindex[row+1] + shift;
      }
      if(sparsePattern_ODE->index[j] > row && !diagElemNonZero) {
        sparsePattern_DIRK->index[i] = row;
        shift++;
        sparsePattern_DIRK->leadindex[row+1] = sparsePattern_ODE->leadindex[row+1] + shift;
        i++;
        diagElemNonZero = TRUE;
      }
      sparsePattern_DIRK->index[i] = sparsePattern_ODE->index[j];
      i++;
      j++;
    }
    if (!diagElemNonZero) {
      sparsePattern_DIRK->index[i] = row;
      shift++;
      sparsePattern_DIRK->leadindex[row+1] = sparsePattern_ODE->leadindex[row+1] + shift;
      i++;
    }
  }

  if (missingDiags == 0) {
    // If missingDiags=0 we can re-use coloring (and everything else)
    sparsePattern_DIRK->maxColors = sparsePattern_ODE->maxColors;
    memcpy(sparsePattern_DIRK->colorCols, sparsePattern_ODE->colorCols, jacobian->sizeCols*sizeof(unsigned int));
  } else {
    // Calculate new coloring, because of additional nonZeroDiagonals
    ColoringAlg(sparsePattern_DIRK, sizeRows, sizeCols, 1);
  }

  return sparsePattern_DIRK;
}


/**
 * @brief Update sparsity pattern for non-linear system of diagonal implicit Runge-Kutta methods.
 *
 * Get sparsity pattern of ODE Jacobian and edit to be non-zero on diagonal elements.
 * Coloring of ODE Jacobian will be used, if it had non-zero elements on all diagonal entries.
 * Calculate coloring otherwise.
 *
 * @param data                Runtime data struct.
 * @param sysData             Non-linear system.
 * @return SPARSE_PATTERN*    Pointer to sparsity pattern of non-linear system.
 */
void updateSparsePattern_MR(DATA_GBODE* gbData, SPARSE_PATTERN *sparsePattern_MR)
{
  DATA_GBODEF* gbfData = gbData->gbfData;
  int nFastStates = gbData->nFastStates;
  int i, j, l, r, ii, jj, ll, rr;

  // The following assumes that the fastStates are sorted (i.e. [0, 2, 6, 7, ...])
  SPARSE_PATTERN *sparsePattern_DIRK = gbfData->sparsePattern_DIRK;

  /* Set sparsity pattern for the fast states */
  ii = 0;
  jj = 0;
  ll = 0;

  sparsePattern_MR->leadindex[0] = sparsePattern_DIRK->leadindex[0];
  for (rr = 0; rr < nFastStates; rr++)
  {
    r = gbData->fastStatesIdx[rr];
    ii = 0;
    for (jj = sparsePattern_DIRK->leadindex[r]; jj < sparsePattern_DIRK->leadindex[r + 1];)
    {
      i = gbData->fastStatesIdx[ii];
      j = sparsePattern_DIRK->index[jj];
      if (i == j)
      {
        sparsePattern_MR->index[ll] = ii;
        ll++;
      }
      if (j > i)
      {
        ii++;
        if (ii >= nFastStates)
          break;
      }
      else
        jj++;
    }
    sparsePattern_MR->leadindex[rr + 1] = ll;
  }

  sparsePattern_MR->numberOfNonZeros = ll;
  sparsePattern_MR->sizeofIndex = ll;

  ColoringAlg(sparsePattern_MR, nFastStates, nFastStates, 1);

  printSparseStructure(sparsePattern_MR,
                       nFastStates,
                       nFastStates,
                       OMC_LOG_GBODE_V,
                       "sparsePattern_MR");


  return;
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
 * @param sysData             Non-linear system.
 * @return SPARSE_PATTERN*    Pointer to sparsity pattern of non-linear system.
 */
SPARSE_PATTERN* initializeSparsePattern_IRK(DATA* data, NONLINEAR_SYSTEM_DATA* sysData)
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
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  SPARSE_PATTERN* sparsePattern_ODE = jacobian->sparsePattern;

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
  int numberOfNonZeros = nnz_A*sparsePattern_ODE->numberOfNonZeros + nDiags_A*missingDiags + (nStages-nDiags_A)*nStates;

  // first generated a coordinate format and transform this later to Column pressed format
  int *coo_col = (int*) malloc(numberOfNonZeros*sizeof(int));
  int *coo_row = (int*) malloc(numberOfNonZeros*sizeof(int));

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

  numberOfNonZeros = i;

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)){
    printIntVector_gb(OMC_LOG_GBODE_V, "rows", coo_row, numberOfNonZeros, 0.0);
    printIntVector_gb(OMC_LOG_GBODE_V, "cols", coo_col, numberOfNonZeros, 0.0);
  }

  int length_row_indices = jacobian->sizeCols*nStages+1;

  // Allocate memory for new sparsity pattern
  sparsePattern_IRK = allocSparsePattern(jacobian->sizeCols*nStages, numberOfNonZeros, jacobian->sizeCols*nStages);

  /* Set diagonal elements of sparsitiy pattern to non-zero */
  for (i=0; i<length_row_indices; i++)
    sparsePattern_IRK->leadindex[i] = 0;

  for (int i = 0; i < numberOfNonZeros; i++)
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

  ColoringAlg(sparsePattern_IRK, sizeRows*nStages, sizeCols*nStages, nStages);

  // for (int k=0; k<nStages; k++)
  //   printIntVector_gb("colorCols: ", &sparsePattern_IRK->colorCols[k*nStates], sizeCols, 0);

  return sparsePattern_IRK;
}

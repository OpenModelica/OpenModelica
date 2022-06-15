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

/*! \file gbode_util.c
 */
#include "gbode_util.h"

/**
 * @brief Linear interpolation of all vector components
 *
 * @param ta      Time value at the left hand side
 * @param fa      Function values at the left hand side
 * @param tb      Time value at the right hand side
 * @param fb      Function values at the right hand side
 * @param t       Time value at the interpolated time point
 * @param f       Function values at the interpolated time point
 * @param n       Size of the vector
 */
void linear_interpolation_gb(double ta, double* fa, double tb, double* fb, double t, double* f, int n)
{
  double lambda, h0, h1;

  if (tb == ta) {
    // omit division by zero
    memcpy(f, fb, n*sizeof(double));
  } else {
    lambda = (t-ta)/(tb-ta);
    h0 = 1-lambda;
    h1 = lambda;

    for (int i=0; i<n; i++)
    {
      f[i] = h0*fa[i] + h1*fb[i];
    }
  }
}

/**
 * @brief Hermite interpolation of all vector components
 *
 * @param ta      Time value at the left hand side
 * @param fa      Function values at the left hand side
 * @param dfa     Derivative function values at the left hand side
 * @param tb      Time value at the right hand side
 * @param fb      Function values at the right hand side
 * @param dfb     Derivative function values at the right hand side
 * @param t       Time value at the interpolated time point
 * @param f       Function values at the interpolated time point
 * @param n       Size of the vector
 */
void hermite_interpolation_gb(double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f, int n)
{
  double tt, h00, h01, h10, h11;
  int i;

  if (tb == ta) {
    // omit division by zero
    memcpy(f, fb, n*sizeof(double));
  } else {
    tt = (t-ta)/(tb-ta);
    h00 = (1+2*tt)*(1-tt)*(1-tt);
    h10 = (tb-ta)*tt*(1-tt)*(1-tt);
    h01 = (3-2*tt)*tt*tt;
    h11 = (tb-ta)*(tt-1)*tt*tt;

    for (i=0; i<n; i++)
    {
      f[i] = h00*fa[i]+h10*dfa[i]+h01*fb[i]+h11*dfb[i];
    }
  }
}

/**
 * @brief         Linear interpolation of specific vector components
 *
 * @param ta      Time value at the left hand side
 * @param fa      Function values at the left hand side
 * @param tb      Time value at the right hand side
 * @param fb      Function values at the right hand side
 * @param t       Time value at the interpolated time point
 * @param f       Function values at the interpolated time point
 * @param nIdx    Size of index vector
 * @param idx     Index vector
 */
void linear_interpolation_gbf(double ta, double* fa, double tb, double* fb, double t, double* f, int nIdx, int* idx)
{
  double lambda, h0, h1;
  int i, ii;

  if (tb == ta) {
    // omit division by zero
    copyVector_gbf(f, fb, nIdx, idx);
  } else {
    lambda = (t-ta)/(tb-ta);
    h0 = 1-lambda;
    h1 = lambda;

    for (ii=0; ii<nIdx; ii++)
    {
      i = idx[ii];
      f[i] = h0*fa[i] + h1*fb[i];
    }
  }
}

/**
 * @brief Hermite interpolation of specific vector components
 *
 * @param ta      Time value at the left hand side
 * @param fa      Function values at the left hand side
 * @param dfa     Derivative function values at the left hand side
 * @param tb      Time value at the right hand side
 * @param fb      Function values at the right hand side
 * @param dfb     Derivative function values at the right hand side
 * @param t       Time value at the interpolated time point
 * @param f       Function values at the interpolated time point
 * @param nIdx    Size of index vector
 * @param idx     Index vector
 */
void hermite_interpolation_gbf(double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f, int nIdx, int* idx)
{
  double tt, h00, h01, h10, h11;
  int i, ii;

  if (tb == ta) {
    // omit division by zero
    copyVector_gbf(f, fb, nIdx, idx);
  } else {
    tt = (t-ta)/(tb-ta);
    h00 = (1+2*tt)*(1-tt)*(1-tt);
    h10 = (tb-ta)*tt*(1-tt)*(1-tt);
    h01 = (3-2*tt)*tt*tt;
    h11 = (tb-ta)*(tt-1)*tt*tt;

    for (ii=0; ii<nIdx; ii++)
    {
      i = idx[ii];
      f[i] = h00*fa[i]+h10*dfa[i]+h01*fb[i]+h11*dfb[i];
    }
  }
}

/**
 * @brief Copy specific vector components given by an index vector
 *
 * @param a       Target vector
 * @param b       Source vector
 * @param nIndx   Size of the index vector
 * @param indx    Index vector
 */
void copyVector_gbf(double* a, double* b, int nIndx, int* indx) {
  for (int i=0;i<nIndx;i++)
    a[indx[i]] = b[indx[i]];
}

void projVector_gbf(double* a, double* b, int nIndx, int* indx) {
  for (int i=0;i<nIndx;i++)
    a[i] = b[indx[i]];
}

// debug ring buffer for the states and derviatives of the states
void debugRingBuffer(enum LOG_STREAM stream, double* x, double* k, int nStates, BUTCHER_TABLEAU* tableau, double time, double stepSize) {

  // If stream is not active do nothing
  if (!ACTIVE_STREAM(stream)) return;

  int nStages = tableau->nStages, stage_;

  infoStreamPrint(stream, 0, "states:");
  for (int stage_ = 0; stage_ < nStages; stage_++) {
    printVector_gb(stream, "x", x + stage_ * nStates, nStates, time + tableau->c[stage_] * stepSize);
  }
  infoStreamPrint(stream, 0, "derivatives:");
  for (int stage_ = 0; stage_ < nStages; stage_++) {
    printVector_gb(stream, "k", k + stage_ * nStates, nStates, time + tableau->c[stage_] * stepSize);
  }
}

/**
 * @brief Prints a vector
 *
 * @param stream  Prints only, if stream is active
 * @param name    Specific string to print (usually name of the vector)
 * @param a       Vector to print
 * @param n       Size of the vector
 * @param time    Time value
 */
void printVector_gb(enum LOG_STREAM stream, char name[], double* a, int n, double time) {

  // If stream is not active or size of vector to big do nothing
  if (!ACTIVE_STREAM(stream) || n>100) return;

  // BB ToDo: This only works for number of states less than 10!
  // For large arrays, this is not a good output format!
  char row_to_print[40960];
  sprintf(row_to_print, "%s(%8g) =\t", name, time);
  for (int i=0;i<n;i++)
    sprintf(row_to_print, "%s %18.12g", row_to_print, a[i]);
  infoStreamPrint(stream, 0, "%s", row_to_print);
}

/**
 * @brief Prints an integer vector
 *
 * @param name    Specific string to print (usually name of the vector)
 * @param a       Integer vector to print
 * @param n       Size of the vector
 * @param time    Time value
 */
void printIntVector_gb(enum LOG_STREAM stream, char name[], int* a, int n, double time) {

  // If stream is not active or size of vector to big do nothing
  if (!ACTIVE_STREAM(stream) || n>100) return;

  char row_to_print[1024];
  sprintf(row_to_print, "%s(%8g) =\t", name, time);
  for (int i=0;i<n;i++)
    sprintf(row_to_print, "%s %d", row_to_print, a[i]);
  infoStreamPrint(stream, 0, "%s", row_to_print);
}

/**
 * @brief Prints a square matrix
 *
 * @param name    Specific string to print (usually name of the matrix)
 * @param a       Matrix to print
 * @param n       number of columns and rows
 * @param time    Time value
 */
void printMatrix_gb(char name[], double* a, int n, double time) {
  printf("\n%s at time: %g: \n ", name, time);
  for (int i=0;i<n;i++)
  {
    for (int j=0;j<n;j++)
      printf("%6g ", a[i*n + j]);
    printf("\n");
  }
  printf("\n");
}

/**
 * @brief Prints selected vector components given by an index vector
 *
 * @param name    Specific string to print (usually name of the vector)
 * @param a       Vector to print
 * @param n       Size of the vector
 * @param time    Time value
 * @param nIndx   Size of index vector
 * @param indx    Index vector
 */

void printVector_gbf(enum LOG_STREAM stream, char name[], double* a, int n, double time, int nIndx, int* indx) {

  // If stream is not active or size of vector to big do nothing
  if (!ACTIVE_STREAM(stream) || nIndx>100) return;

  // BB ToDo: This only works for number of states less than 10!
  // For large arrays, this is not a good output format!
  char row_to_print[40960];
  sprintf(row_to_print, "%s(%8g) =\t", name, time);
  for (int i=0;i<nIndx;i++)
    sprintf(row_to_print, "%s %16.12g", row_to_print, a[indx[i]]);
  infoStreamPrint(stream, 0, "%s", row_to_print);
}

/**
 * @brief Prints sparse structure.
 *
 * Use to print e.g. sparse Jacobian matrix.
 * Only prints if stream is active and sparse pattern is non NULL and of size > 0.
 *
 * @param sparsePattern   Matrix to print.
 * @param sizeRows        Number of rows of matrix.
 * @param sizeCols        Number of columns of matrix.
 * @param stream          Steam to print to.
 * @param name            Name of matrix.
 */
void printSparseJacobianLocal(ANALYTIC_JACOBIAN* jacobian, const char* name) {
  /* Variables */
  unsigned int row, col, i, j;
  infoStreamPrint(LOG_STDOUT, 0, "Sparse structure of %s [size: %ux%u]", name, jacobian->sizeRows, jacobian->sizeCols);
  infoStreamPrint(LOG_STDOUT, 0, "%u non-zero elements", jacobian->sparsePattern->numberOfNonZeros);
  infoStreamPrint(LOG_STDOUT, 0, "Values of the transposed matrix (rows: states)");

  printf("\n");
  i=0;
  for(row=0; row < jacobian->sizeRows; row++)
  {
    j=0;
    for(col=0; i < jacobian->sparsePattern->leadindex[row+1]; col++)
    {
      if(jacobian->sparsePattern->index[i] == col)
      {
        printf("%20.16g ", jacobian->resultVars[col]);
        ++i;
      }
      else
      {
        printf("%20.16g ", 0.0);
      }
    }
    printf("\n");
  }
  printf("\n");
}

void dumpFastStates_gb(DATA_GBODE* gbData, modelica_boolean event) {
    char fastStates_row[2048];
    sprintf(fastStates_row, "%15.10g ", gbData->time);
    for (int i = 0; i < gbData->nStates; i++) {
      if (event)
        sprintf(fastStates_row, "%s 0", fastStates_row);
      else
        sprintf(fastStates_row, "%s 1", fastStates_row);
    }
    fprintf(gbData->gbfData->fastStatesDebugFile, "%s\n", fastStates_row);
}

void dumpFastStates_gbf(DATA_GBODE* gbData) {
  char fastStates_row[2048];
  int i, ii;
  sprintf(fastStates_row, "%15.10g ", gbData->gbfData->time);
  for (i = 0, ii = 0; i < gbData->nStates;) {
    if (i == gbData->fastStates[ii]) {
      sprintf(fastStates_row, "%s 1", fastStates_row);
      i++;
      ii++;
    } else {
      sprintf(fastStates_row, "%s 0", fastStates_row);
      i++;
    }
  }
  fprintf(gbData->gbfData->fastStatesDebugFile, "%s\n", fastStates_row);
}

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

#define GBODE_EPSILON DBL_EPSILON


// LA functions
// TODO: Describe me
void addSmultVec_gbf(double* a, double* b, double *c, double s, int nIdx, int* idx) {
  int i, ii;

  for (ii=0; ii<nIdx; ii++) {
    i = idx[ii];
    a[i] = b[i] + s*c[i];
  }
}

// TODO: Describe me
void addSmultVec_gb(double* a, double* b, double *c, double s, int n) {
  int i;

  for (i=0; i<n; i++) {
    a[i] = b[i] + s*c[i];
  }
}

/*
 * ============================================================================
 *   Interpolation functions
 * ============================================================================
 */

/**
 * @brief         Linear interpolation of specific vector components
 *
 * @param ta      Time value at the left hand side
 * @param fa      Function values at the left hand side
 * @param tb      Time value at the right hand side
 * @param fb      Function values at the right hand side
 * @param t       Time value at the interpolated time point
 * @param f       Function values at the interpolated time point
 * @param n       Size of vector f or size of index vector if non-NULL.
 * @param idx     Index vector, can be NULL.
 *                Specifies which parts of f should be interpolated.
 */
void linear_interpolation(double ta, double* fa, double tb, double* fb, double t, double* f, int n, int* idx)
{
  double lambda, h0, h1;
  int i, ii;

  // omit division by zero
  if (fabs(tb-ta) <= GBODE_EPSILON) {
    if(idx != NULL) {
      copyVector_gbf(f, fb, n, idx);
    } else {
      memcpy(f, fb, n*sizeof(double));
    }
    return;
  }

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  if (idx == NULL) {
    for (i=0; i<n; i++)
    {
      f[i] = h0*fa[i] + h1*fb[i];
    }
  } else {
    for (ii=0; ii<n; ii++)
    {
      i = idx[ii];
      f[i] = h0*fa[i] + h1*fb[i];
    }
  }
  return;
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
 * @param n       Size of vector f or size of index vector if non-NULL.
 * @param idx     Index vector, can be NULL.
 *                Specifies which parts of f should be interpolated.
 */
void hermite_interpolation(double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f, int n, int* idx)
{
  double tt, h00, h01, h10, h11;
  int i, ii;

  // omit division by zero
  if (fabs(tb-ta) <= GBODE_EPSILON) {
    if(idx != NULL) {
      copyVector_gbf(f, fb, n, idx);
    } else {
      memcpy(f, fb, n*sizeof(double));
    }
    return;
  }

  tt = (t-ta)/(tb-ta);
  h00 = (1+2*tt)*(1-tt)*(1-tt);
  h10 = (tb-ta)*tt*(1-tt)*(1-tt);
  h01 = (3-2*tt)*tt*tt;
  h11 = (tb-ta)*(tt-1)*tt*tt;

  if (idx == NULL) {
    for (i=0; i<n; i++)
    {
      f[i] = h00*fa[i]+h10*dfa[i]+h01*fb[i]+h11*dfb[i];
    }
  } else {
    for (ii=0; ii<n; ii++)
    {
      i = idx[ii];
      f[i] = h00*fa[i]+h10*dfa[i]+h01*fb[i]+h11*dfb[i];
    }
  }

  return;
}

/**
 * @brief Hermite interpolation of specific vector components (only right derivative used)
 *
 * @param ta      Time value at the left hand side
 * @param fa      Function values at the left hand side
 * @param tb      Time value at the right hand side
 * @param fb      Function values at the right hand side
 * @param dfb     Derivative function values at the right hand side
 * @param t       Time value at the interpolated time point
 * @param f       Function values at the interpolated time point
 * @param n       Size of vector f or size of index vector if non-NULL.
 * @param idx     Index vector, can be NULL.
 *                Specifies which parts of f should be interpolated.
 */
void hermite_interpolation_b(double ta, double* fa, double tb, double* fb, double* dfb, double t, double* f, int n, int* idx)
{
  double tat,tbt,tbta, h00, h01, h11;
  int i, ii;

  // omit division by zero
  if (fabs(tb-ta) <= GBODE_EPSILON) {
    if(idx != NULL) {
      copyVector_gbf(f, fb, n, idx);
    } else {
      memcpy(f, fb, n*sizeof(double));
    }
    return;
  }

  tat  = (ta-t);
  tbt  = (tb-t);
  tbta = (tb-ta);
  h00  = tbt*tbt/(tbta*tbta);
  h01  = tat*(tat - tbt)/(tbta*tbta);
  h11  = tat*tbt/tbta;

  if (idx == NULL) {
    for (i=0; i<n; i++)
    {
      f[i] = h00*fa[i]+h01*fb[i]+h11*dfb[i];
    }
  } else {
    for (ii=0; ii<n; ii++)
    {
      i = idx[ii];
      f[i] = h00*fa[i]+h01*fb[i]+h11*dfb[i];
    }
  }

  return;
}

/**
 * @brief Hermite interpolation of specific vector components
 *
 * @param interpolMethod
 * @param ta              Time value at the left hand side
 * @param fa              Function values at the left hand side
 * @param dfa             Derivative function values at the left hand side.
 *                        Can be NULL for linear interpolation.
 * @param tb              Time value at the right hand side
 * @param fb              Function values at the right hand side
 * @param dfb             Derivative function values at the right hand side.
 *                        Can be NULL for linear interpolation.
 * @param t               Time value at the interpolated time point
 * @param f               Function values at the interpolated time point
 * @param n               Size of vector f or size of index vector if non-NULL.
 * @param idx             Index vector, can be NULL.
 *                        Specifies which parts of f should be interpolated.
 */
void gb_interpolation(enum GB_INTERPOL_METHOD interpolMethod, double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f,
                      int nIdx, int* idx, int nStates, BUTCHER_TABLEAU* tableau, double* x, double *k) {
  switch (interpolMethod)
  {
  case GB_INTERPOL_LIN:
    linear_interpolation(ta, fa, tb, fb, t, f, nIdx, idx);
    break;
  case GB_DENSE_OUTPUT:
  case GB_DENSE_OUTPUT_ERRCTRL:
    if (tableau->withDenseOutput) {
      tableau->dense_output(tableau, fa, x, k, (t - ta)/(tb-ta), (tb - ta), f, nIdx, idx, nStates);
      break;
    }
  case GB_INTERPOL_HERMITE_b:
    hermite_interpolation_b(ta, fa, tb, fb, dfb, t, f, nIdx, idx);
  case GB_INTERPOL_HERMITE:
  case GB_INTERPOL_HERMITE_ERRCTRL:
    hermite_interpolation(ta, fa, dfa, tb, fb, dfb, t, f, nIdx, idx);
    break;
  default:
    throwStreamPrint(NULL, "Not handled case in gb_interpolation. Unknown interpolation method %i.", interpolMethod);
  }
}
/**
 * @brief  Difference between linear and hermite interpolation at intermediate points.
 *
 * @param gbData
 */
void error_interpolation_gbf(DATA_GBODE* gbData) {
  int i, ii;

  if (gbData->interpolation == GB_INTERPOL_HERMITE_ERRCTRL || gbData->interpolation == GB_INTERPOL_HERMITE || gbData->interpolation == GB_INTERPOL_HERMITE_b ) {
    linear_interpolation(gbData->timeLeft,  gbData->yLeft,
                        gbData->timeRight, gbData->yRight,
                        (gbData->timeLeft + gbData->timeRight)/2, gbData->y1,
                         gbData->nSlowStates, gbData->slowStatesIdx);
  } else {
    gb_interpolation(gbData->interpolation, gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                     gbData->timeRight, gbData->yRight, gbData->kRight,
                     (gbData->timeLeft + gbData->timeRight)/2, gbData->y1,
                      gbData->nSlowStates, gbData->slowStatesIdx, gbData->nStates, gbData->tableau, gbData->x, gbData->k);

  }
  hermite_interpolation(gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                        gbData->timeRight, gbData->yRight, gbData->kRight,
                        (gbData->timeLeft + gbData->timeRight)/2, gbData->errest,
                         gbData->nSlowStates, gbData->slowStatesIdx);

  for (ii=0; ii<gbData->nSlowStates; ii++) {
    i = gbData->slowStatesIdx[ii];
    gbData->errest[i] = fabs(gbData->errest[i] - gbData->y1[i]);
  }
}

/**
 * @brief Extrapolation for fast states.
 *
 * Using interpolation method specified in gbData->interpolation.
 *
 * @param gbData              Generic ODE solver data.
 * @param nlsxExtrapolation   On output contains function values at extrapolation point time.
 * @param time                Extrapolation time.
 */
void extrapolation_gbf(DATA_GBODE* gbData, double* nlsxExtrapolation, double time)
{
  DATA_GBODEF* gbfData = gbData->gbfData;
  int nStates = gbData->nStates;
  int nFastStates = gbData->nFastStates;

  if (fabs(gbfData->tv[1]-gbfData->tv[0]) <= GBODE_EPSILON) {
    addSmultVec_gbf(nlsxExtrapolation, gbfData->yv, gbfData->kv, time - gbfData->tv[0], nFastStates, gbData->fastStatesIdx);
  } else {
    // this is actually extrapolation...
    gb_interpolation(GB_INTERPOL_HERMITE,
                     gbfData->tv[1], gbfData->yv + nStates,  gbfData->kv + nStates,
                     gbfData->tv[0], gbfData->yv,            gbfData->kv,
                     time, nlsxExtrapolation,
                     nFastStates, gbData->fastStatesIdx, nStates, gbfData->tableau, gbfData->x, gbfData->k);
  }
}

/**
 * @brief Extrapolation for all states.
 *
 * Using interpolation method specified in gbData->interpolation.
 *
 * @param gbData              Generic ODE solver data.
 * @param nlsxExtrapolation   On output contains function values at extrapolation point time.
 * @param time                Extrapolation time.
 */
void extrapolation_gb(DATA_GBODE* gbData, double* nlsxExtrapolation, double time)
{
  int nStates = gbData->nStates;

  if (fabs(gbData->tv[1]-gbData->tv[0]) <= GBODE_EPSILON) {
    addSmultVec_gb(nlsxExtrapolation, gbData->yv, gbData->kv, time - gbData->tv[0], nStates);
  } else {
    // this is actually extrapolation...
    gb_interpolation(GB_INTERPOL_HERMITE,
                     gbData->tv[1], gbData->yv + nStates,  gbData->kv + nStates,
                     gbData->tv[0], gbData->yv,            gbData->kv,
                     time, nlsxExtrapolation,
                     nStates, NULL, nStates, gbData->tableau, gbData->x, gbData->k);
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

// TODO: Describe me
void projVector_gbf(double* a, double* b, int nIndx, int* indx) {
  for (int i=0;i<nIndx;i++)
    a[i] = b[indx[i]];
}

// TODO: Describe me
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
  if (!ACTIVE_STREAM(stream) || n>1000) return;

  // This only works for number of states less than 10!
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
  if (!ACTIVE_STREAM(stream) || n>1000) return;

  char row_to_print[40960];
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
  if (!ACTIVE_STREAM(stream) || nIndx>1000) return;

  // This only works for number of states less than 10!
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

// TODO: Describe me
void dumpFastStates_gb(DATA_GBODE* gbData, modelica_boolean event, double time) {
    char fastStates_row[4096];
    sprintf(fastStates_row, "%15.10g %15.10g %15.10g %15.10g", time, gbData->err_slow, gbData->err_int, gbData->err_fast);
    for (int i = 0; i < gbData->nStates; i++) {
      if (event)
        sprintf(fastStates_row, "%s 0", fastStates_row);
      else
        sprintf(fastStates_row, "%s 1", fastStates_row);
    }
    fprintf(gbData->gbfData->fastStatesDebugFile, "%s\n", fastStates_row);
}

// TODO: Describe me
void dumpFastStates_gbf(DATA_GBODE* gbData, double time) {
  char fastStates_row[4096];
  int i, ii;
  sprintf(fastStates_row, "%15.10g %15.10g %15.10g %15.10g", time, gbData->err_slow, gbData->err_int, gbData->err_fast);
  for (i = 0, ii = 0; i < gbData->nStates;) {
    if (i == gbData->fastStatesIdx[ii]) {
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

/**
 * @brief Check if indices of fast states changed and update indices.
 *
 * @param gbData              Pointer to gbode data.
 * @return modelica_boolean   TRUE if at least one fast state changed, FALSE otherwise.
 */
modelica_boolean checkFastStatesChange(DATA_GBODE* gbData) {
  DATA_GBODEF* gbfData = gbData->gbfData;
  modelica_boolean fastStatesChange = FALSE;

  gbfData->nFastStates = gbData->nFastStates;
  gbfData->fastStatesIdx  = gbData->fastStatesIdx;

  if (gbfData->nFastStates_old != gbData->nFastStates) {
    if (ACTIVE_STREAM(LOG_SOLVER) && !fastStatesChange)
    {
      printIntVector_gb(LOG_SOLVER, "old fast States:", gbfData->fastStates_old, gbfData->nFastStates_old, gbfData->time);
      printIntVector_gb(LOG_SOLVER, "new fast States:", gbData->fastStatesIdx, gbData->nFastStates, gbfData->time);
    }
    gbfData->nFastStates_old = gbData->nFastStates;
    fastStatesChange = TRUE;
  }

  for (int k = 0; k < gbData->nFastStates; k++) {
    if (gbfData->fastStates_old[k] != gbData->fastStatesIdx[k]) {
      if (ACTIVE_STREAM(LOG_SOLVER) && !fastStatesChange)
      {
        printIntVector_gb(LOG_SOLVER, "old fast States:", gbfData->fastStates_old, gbfData->nFastStates_old, gbfData->time);
        printIntVector_gb(LOG_SOLVER, "new fast States:", gbData->fastStatesIdx, gbData->nFastStates, gbfData->time);
      }
      fastStatesChange = TRUE;
      gbfData->fastStates_old[k] = gbData->fastStatesIdx[k];
    }
  }
  return fastStatesChange;
}

/**
 * @brief Log ODE integrator solver stats.
 *
 * @param name            Name of ODE integrator.
 * @param timeValue       Current time value.
 * @param integratorTime  Time value of integrator.
 * @param stepSize        ODE integrator step size.
 * @param stats           Pointer to stats struct.
 */
void logSolverStats(const char* name, double timeValue, double integratorTime, double stepSize, SOLVERSTATS* stats) {
  if (ACTIVE_STREAM(LOG_SOLVER_V)) {
    infoStreamPrint(LOG_SOLVER_V, 1, "%s call statistics:", name);
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", timeValue);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", integratorTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", stats->nStepsTaken);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", stats->nCallsODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", stats->nCallsJacobian);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", stats->nErrorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", stats->nConvergenveTestFailures);
    messageClose(LOG_SOLVER_V);
  }
}

/**
 * @brief Set solver stats.
 *
 * @param solverStats   Pointer to solverStats to set.
 * @param stats         Values to set in solverStats.
 */
void setSolverStats(unsigned int* solverStats, SOLVERSTATS* stats) {
  solverStats[0] = stats->nStepsTaken;
  solverStats[1] = stats->nCallsODE;
  solverStats[2] = stats->nCallsJacobian;
  solverStats[3] = stats->nErrorTestFailures;
  solverStats[4] = stats->nConvergenveTestFailures;
}

/**
 * @brief Set all solver stats to zero.
 *
 * @param stats   Pointer to solver stats.
 */
void resetSolverStats(SOLVERSTATS* stats) {
  stats->nStepsTaken = 0;
  stats->nCallsODE = 0;
  stats->nCallsJacobian = 0;
  stats->nErrorTestFailures = 0;
  stats->nConvergenveTestFailures = 0;
}

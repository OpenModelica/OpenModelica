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
/**
 * @brief Scalar multiplication and vector addition a = b + s*c for selected indices.
 *
 * Determines the scalar multiplication of an vector and adds the result
 * to another vector only for selected indices.
 *
 * a = b + s*c
 *
 * @return a    Output vector
 * @param  b    Input vector
 * @param  c    Input vector
 * @param  s    Scalar value
 * @param  nIdx Length of index vector
 * @param  idx  Index vector
 */
void addSmultVec_gbf(double* a, double* b, double *c, double s, int nIdx, int* idx)
{
  int i, ii;

  for (ii=0; ii<nIdx; ii++) {
    i = idx[ii];
    a[i] = b[i] + s*c[i];
  }
}

/**
 * @brief Scalar multiplication and vector addition a = b + s*c.
 *
 * Determines the scalar multiplication of an vector and adds the result
 * to another vector.
 *
 * a = b + s*c
 *
 * @return a    Output vector
 * @param  b    Input vector
 * @param  c    Input vector
 * @param  s    Scalar value
 * @param  n    Length of the vectors
 */
void addSmultVec_gb(double* a, double* b, double *c, double s, int n)
{
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
    copyVector_gbf(f, fb, n, idx);
    return;
  }

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  if (idx == NULL) {
    for (i=0; i<n; i++) {
      f[i] = h0*fa[i] + h1*fb[i];
    }
  } else {
    for (ii=0; ii<n; ii++) {
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
    copyVector_gbf(f, fb, n, idx);
    return;
  }

  tt = (t-ta)/(tb-ta);
  h00 = (1+2*tt)*(1-tt)*(1-tt);
  h10 = (tb-ta)*tt*(1-tt)*(1-tt);
  h01 = (3-2*tt)*tt*tt;
  h11 = (tb-ta)*(tt-1)*tt*tt;

  if (idx == NULL) {
    for (i=0; i<n; i++) {
      f[i] = h00*fa[i]+h10*dfa[i]+h01*fb[i]+h11*dfb[i];
    }
  } else {
    for (ii=0; ii<n; ii++) {
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
    copyVector_gbf(f, fb, n, idx);
    return;
  }

  tat  = (ta-t);
  tbt  = (tb-t);
  tbta = (tb-ta);
  h00  = tbt*tbt/(tbta*tbta);
  h01  = tat*(tat - tbt)/(tbta*tbta);
  h11  = tat*tbt/tbta;

  if (idx == NULL) {
    for (i=0; i<n; i++) {
      f[i] = h00*fa[i]+h01*fb[i]+h11*dfb[i];
    }
  } else {
    for (ii=0; ii<n; ii++) {
      i = idx[ii];
      f[i] = h00*fa[i]+h01*fb[i]+h11*dfb[i];
    }
  }

  return;
}

/**
 * @brief Hermite interpolation of specific vector components (only left derivative used)
 *
 * @param ta      Time value at the left hand side
 * @param fa      Function values at the left hand side
 * @param dfa     Derivative function values at the left hand side
 * @param tb      Time value at the right hand side
 * @param fb      Function values at the right hand side
 * @param t       Time value at the interpolated time point
 * @param f       Function values at the interpolated time point
 * @param n       Size of vector f or size of index vector if non-NULL.
 * @param idx     Index vector, can be NULL.
 *                Specifies which parts of f should be interpolated.
 */
void hermite_interpolation_a(double ta, double* fa, double* dfa, double tb, double* fb, double t, double* f, int n, int* idx)
{
  double tat,tbt,tbta, h00, h01, h10;
  int i, ii;

  // omit division by zero
  if (fabs(tb-ta) <= GBODE_EPSILON) {
    copyVector_gbf(f, fb, n, idx);
    return;
  }

  tat  = (ta-t);
  tbt  = (tb-t);
  tbta = (tb-ta);
  h01  = tat*tat/(tbta*tbta);
  h00  = 1 - h01;
  h10  = -tat*tbt/tbta;

  if (idx == NULL) {
    for (i=0; i<n; i++) {
      f[i] = h00*fa[i]+h01*fb[i]+h10*dfa[i];
    }
  } else {
    for (ii=0; ii<n; ii++) {
      i = idx[ii];
      f[i] = h00*fa[i]+h01*fb[i]+h10*dfa[i];
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
                      int nIdx, int* idx, int nStates, BUTCHER_TABLEAU* tableau, double* x, double *k)
{
  switch (interpolMethod)
  {
  case GB_INTERPOL_LIN:
    linear_interpolation(ta, fa, tb, fb, t, f, nIdx, idx);
    break;
  case GB_DENSE_OUTPUT:
  case GB_DENSE_OUTPUT_ERRCTRL:
    if (tableau->withDenseOutput) {
      // FIXME omit division by zero if fabs(tb-ta) <= GBODE_EPSILON
      tableau->dense_output(tableau, fa, x, k, (t - ta)/(tb - ta), (tb - ta), f, nIdx, idx, nStates);
      break;
    }
  case GB_INTERPOL_HERMITE_a:
    hermite_interpolation_a(ta, fa, dfa, tb, fb, t, f, nIdx, idx);
    break;
  case GB_INTERPOL_HERMITE_b:
    hermite_interpolation_b(ta, fa, tb, fb, dfb, t, f, nIdx, idx);
    break;
  case GB_INTERPOL_HERMITE_ERRCTRL:
  case GB_INTERPOL_HERMITE:
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
double error_interpolation_gb(DATA_GBODE* gbData, int nIdx, int* idx, double tol)
{
  int i, ii;
  double errint = 0.0, errtol;

  if (gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL || gbData->interpolation == GB_DENSE_OUTPUT) {
    gb_interpolation(gbData->interpolation, gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                      gbData->timeRight, gbData->yRight, gbData->kRight,
                      (gbData->timeLeft + gbData->timeRight)/2, gbData->y1,
                        nIdx, idx, gbData->nStates, gbData->tableau, gbData->x, gbData->k);
  } else {
    hermite_interpolation_a(gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                            gbData->timeRight, gbData->yRight,
                            (gbData->timeLeft + gbData->timeRight)/2, gbData->y1,
                            nIdx, idx);
  }
  hermite_interpolation(gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                        gbData->timeRight, gbData->yRight, gbData->kRight,
                        (gbData->timeLeft + gbData->timeRight)/2, gbData->y2,
                         nIdx, idx);
  if (idx == NULL) {
    for (i=0; i<nIdx; i++) {
      errtol = tol * fmax(fabs(gbData->yLeft[i]), fabs(gbData->yRight[i])) + tol;
      gbData->errest[i] = fabs(gbData->y2[i] - gbData->y1[i]) / errtol;
      errint = fmax(errint, gbData->errest[i]);
    }
  } else {
    for (ii=0; ii<nIdx; ii++) {
      i = idx[ii];
      errtol = tol * fmax(fabs(gbData->yLeft[i]), fabs(gbData->yRight[i])) + tol;
      gbData->errest[i] = fabs(gbData->y2[i] - gbData->y1[i]) / errtol;
      errint = fmax(errint, gbData->errest[i]);
    }
  }
  return errint;
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
  const int nStates = gbData->nStates;
  const int nFastStates = gbData->nFastStates;

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
void extrapolation_hermite_gb(double* nlsxExtrapolation, int nStates, double t0, double *x0, double* k0, double t1, double *x1, double* k1, double time)
{
  gb_interpolation(GB_INTERPOL_HERMITE,
                   t0, x0,  k0,
                   t1, x1,  k1,
                   time, nlsxExtrapolation,
                   nStates, NULL, nStates, NULL, NULL, NULL);
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

  if (fabs(gbData->tv[1]-gbData->tv[0]) <= GBODE_EPSILON || gbData->multi_rate) {
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
 *  if indx == NULL, the full vector is copied
 *
 * @param a       Target vector
 * @param b       Source vector
 * @param nIndx   Size of the index vector
 * @param indx    Index vector
 */
void copyVector_gbf(double* dest, double* src, int nIndx, int* indx)
{
  if (indx != NULL) {
    for (int i = 0; i < nIndx; i++)
      dest[indx[i]] = src[indx[i]];
  } else {
    memcpy(dest, src, nIndx*sizeof(double));
  }
}

/**
 * @brief Projection function
 *
 * Collects the values in the vector for given indices (idx)
 * and copy them in an corresponding vector of size (nIdx).
 *
 * @return a     Target vector
 * @param  b     Source Vector
 * @param  nIndx Length of index vector
 * @param  indx  Index vector
 */
void projVector_gbf(double* a, double* b, int nIndx, int* indx)
{
  for (int i = 0; i < nIndx; i++)
    a[i] = b[indx[i]];
}

/**
 * @brief Output debug information of the states and derivatives
 *
 * that have been evaluated at the past accepted time points.
 *
 * @param stream   Prints only, if stream is active
 * @param x        States at the past accepted time points
 * @param k        Derivatives at the past accepted time points
 * @param t        Past accepted time points
 * @param nStates  Number of states
 * @param size     Size of buffer
 */
void debugRingBufferSteps_gb(enum OMC_LOG_STREAM stream, double* x, double* k, double *t, int nStates, int size)
{
  // If stream is not active do nothing
  if (!OMC_ACTIVE_STREAM(stream)) return;

  infoStreamPrint(stream, 1, "States and derivatives at past accepted time steps:");

  int i;

  infoStreamPrint(stream, 0, "states:");
  for (i = 0; i < size; i++) {
    printVector_gb(stream, "x", x + i * nStates, nStates, t[i]);
  }
  infoStreamPrint(stream, 0, "derivatives:");
  for (i = 0; i < size; i++) {
    printVector_gb(stream, "k", k + i * nStates, nStates, t[i]);
  }
  messageClose(stream);
}

/**
 * @brief Output debug information of the states and derivatives
 *
 * that have been evaluated at the past accepted time points.
 *
 * @param stream   Prints only, if stream is active
 * @param x        States at the past accepted time points
 * @param k        Derivatives at the past accepted time points
 * @param t        Past accepted time points
 * @param nStates  Number of states
 * @param size     Size of buffer
 * @param nIndx    Size of index vector
 * @param indx     Index vector
 */
void debugRingBufferSteps_gbf(enum OMC_LOG_STREAM stream, double* x, double* k, double *t, int nStates, int size, int nIndx, int* indx)
{
  // If stream is not active do nothing
  if (!OMC_ACTIVE_STREAM(stream)) return;

  infoStreamPrint(stream, 1, "States and derivatives at past accepted time steps (inner integration):");

  int i;

  infoStreamPrint(stream, 0, "states:");
  for (i = 0; i < size; i++) {
    printVector_gbf(stream, "x", x + i * nStates, nStates, t[i], nIndx, indx);
  }
  infoStreamPrint(stream, 0, "derivatives:");
  for (i = 0; i < size; i++) {
    printVector_gbf(stream, "k", k + i * nStates, nStates, t[i], nIndx, indx);
  }
  messageClose(stream);
}

/**
 * @brief Output debug information of the states and derivatives
 *
 * that have been evaluated at the intermediate points given by the
 * Butcher tableau.
 *
 * @param stream   Prints only, if stream is active
 * @param x        States at the intermediate time points
 * @param k        Derivatives at the intermediate time points
 * @param nStates  Number of states
 * @param tableau  Tableau of the Runge Kutta method
 * @param time     Current time of the inegrator (left hand side)
 * @param stepSize Current step size of the integrator
 */
void debugRingBuffer_gb(enum OMC_LOG_STREAM stream, double* x, double* k, int nStates, BUTCHER_TABLEAU* tableau, double time, double stepSize)
{
  // If stream is not active do nothing
  if (!OMC_ACTIVE_STREAM(stream)) return;

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
 * @brief Output debug information of the states and derivatives
 *
 * that have been evaluated at the intermediate points given by the
 * Butcher tableau.
 *
 * @param stream   Prints only, if stream is active
 * @param x        States at the intermediate time points
 * @param k        Derivatives at the intermediate time points
 * @param nStates  Number of states
 * @param tableau  Tableau of the Runge Kutta method
 * @param time     Current time of the inegrator (left hand side)
 * @param stepSize Current step size of the integrator
 * @param nIndx    Size of index vector
 * @param indx     Index vector
 */
void debugRingBuffer_gbf(enum OMC_LOG_STREAM stream, double* x, double* k, int nStates, BUTCHER_TABLEAU* tableau, double time, double stepSize, int nIndx, int* indx)
{
  // If stream is not active do nothing
  if (!OMC_ACTIVE_STREAM(stream)) return;

  int nStages = tableau->nStages, stage_;

  infoStreamPrint(stream, 0, "states:");
  for (int stage_ = 0; stage_ < nStages; stage_++) {
    printVector_gbf(stream, "x", x + stage_ * nStates, nStates, time + tableau->c[stage_] * stepSize, nIndx, indx);
  }
  infoStreamPrint(stream, 0, "derivatives:");
  for (int stage_ = 0; stage_ < nStages; stage_++) {
    printVector_gbf(stream, "k", k + stage_ * nStates, nStates, time + tableau->c[stage_] * stepSize, nIndx, indx);
  }
}

/**
 * @brief Prints a vector to stream.
 *
 * If vector is larger than 1000 nothing is printed.
 *
 * @param stream  Prints only, if stream is active
 * @param name    Specific string to print (usually name of the vector)
 * @param a       Vector to print
 * @param n       Size of the vector
 * @param time    Time value
 */
void printVector_gb(enum OMC_LOG_STREAM stream, char name[], double* a, int n, double time)
{
  // If stream is not active or size of vector to big do nothing
  if (!OMC_ACTIVE_STREAM(stream) || n>1000) return;

  // This only works for number of states less than 10!
  // For large arrays, this is not a good output format!
  char row_to_print[40960];
  unsigned int bufSize = 40960;
  unsigned int ct;
  ct = snprintf(row_to_print, bufSize, "%s(%8g) =\t", name, time);
  for (int i=0;i<n;i++)
    ct += snprintf(row_to_print+ct, bufSize-ct, " %16.12g", a[i]);
  infoStreamPrint(stream, 0, "%s", row_to_print);
}

/**
 * @brief Prints an integer vector to stream.
 *
 * If vector is larger than 1000 nothing is printed.
 *
 * @param name    Specific string to print (usually name of the vector)
 * @param a       Integer vector to print
 * @param n       Size of the vector
 * @param time    Time value
 */
void printIntVector_gb(enum OMC_LOG_STREAM stream, char name[], int* a, int n, double time)
{
  // If stream is not active or size of vector to big do nothing
  if (!OMC_ACTIVE_STREAM(stream) || n>1000) return;

  char row_to_print[40960];
  unsigned int bufSize = 40960;
  unsigned int ct;
  ct = snprintf(row_to_print, bufSize, "%s(%8g) =\t", name, time);
  for (int i=0;i<n;i++)
    ct += snprintf(row_to_print+ct, bufSize-ct, " %d", a[i]);
  infoStreamPrint(stream, 0, "%s", row_to_print);
}

/**
 * @brief Prints selected vector components given by an index vector.
 *
 * If more than 1000 elements should be printed do nothing.
 *
 * @param name    Specific string to print (usually name of the vector)
 * @param a       Vector to print
 * @param n       Size of the vector
 * @param time    Time value
 * @param nIndx   Size of index vector
 * @param indx    Index vector
 */
void printVector_gbf(enum OMC_LOG_STREAM stream, char name[], double* a, int n, double time, int nIndx, int* indx)
{
  // If stream is not active or size of vector to big do nothing
  if (!OMC_ACTIVE_STREAM(stream) || nIndx>1000) return;

  // This only works for number of states less than 10!
  // For large arrays, this is not a good output format!
  char row_to_print[40960];
  unsigned int bufSize = 40960;
  unsigned int ct;
  ct = snprintf(row_to_print, bufSize, "%s(%8g) =\t", name, time);
  for (int i=0;i<nIndx;i++)
    ct += snprintf(row_to_print+ct, bufSize-ct, " %16.12g", a[indx[i]]);
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
void printSparseJacobianLocal(JACOBIAN* jacobian, const char* name)
{
  /* Variables */
  unsigned int row, col, i;
  infoStreamPrint(OMC_LOG_STDOUT, 0, "Sparse structure of %s [size: %zux%zu]", name, jacobian->sizeRows, jacobian->sizeCols);
  infoStreamPrint(OMC_LOG_STDOUT, 0, "%u non-zero elements", jacobian->sparsePattern->numberOfNonZeros);
  infoStreamPrint(OMC_LOG_STDOUT, 0, "Values of the transposed matrix (rows: states)");

  printf("\n");
  i=0;
  for (row = 0; row < jacobian->sizeRows; row++) {
    for (col = 0; col < jacobian->sizeRows; col++) {
      if(jacobian->sparsePattern->index[i] == col) {
        printf("%20.16g ", jacobian->resultVars[col]);
        ++i;
      } else {
        printf("%20.16g ", 0.0);
      }
    }
    printf("\n");
  }
  printf("\n");
}

/**
 * @brief Write information on the active fast states on file (activity diagram)
 *
 * @param gbData       Pointer to generic GBODE data struct.
 * @param event        If an event has happened, write zeros else ones
 * @param time         Actual time of reporting
 * @param rejectedType Type of rejection
 *                     0  <= no rejection
 *                     1  <= error of slow states greater than the tolerance
 *                     2  <= interpolation error is too large
 *                     3  <= rejected because solving the NLS failed
 *                    -1  <= step is preliminary accepted but needs refinement
 */
void dumpFastStates_gb(DATA_GBODE* gbData, modelica_boolean event, double time, int rejectedType)
{
  char fastStates_row[4096];
  unsigned int bufSize = 4096;
  unsigned int ct;
  ct = snprintf(fastStates_row, bufSize, "%15.10g %2d %15.10g %15.10g %15.10g", time, rejectedType, gbData->err_slow, gbData->err_int, gbData->err_fast);
  for (int i = 0; i < gbData->nStates; i++) {
    if (event)
      ct += snprintf(fastStates_row+ct, bufSize-ct, " 0");
    else
      ct += snprintf(fastStates_row+ct, bufSize-ct, " 1");
  }
  fprintf(gbData->gbfData->fastStatesDebugFile, "%s\n", fastStates_row);
}

/**
 * @brief Write information on the active fast states on file (activity diagram)
 *
 * @param gbData  Pointer to generic GBODE data struct.
 * @param time    Actual time of reporting
 * @param rejectedType Type of rejection
 *                     0  <= no rejection
 *                     1  <= error of slow states greater than the tolerance
 *                     2  <= interpolation error is too large
 *                     3  <= rejected because solving the NLS failed
 *                    -1  <= step is preliminary accepted but needs refinement
 */
void dumpFastStates_gbf(DATA_GBODE* gbData, double time, int rejectedType)
{
  char fastStates_row[40960];
  unsigned int bufSize = 40960;
  unsigned int ct;
  int i, ii;
  ct = snprintf(fastStates_row, bufSize, "%15.10g %2d %15.10g %15.10g %15.10g", time, rejectedType, gbData->err_slow, gbData->err_int, gbData->err_fast);
  for (i = 0, ii = 0; i < gbData->nStates;) {
    if (i == gbData->fastStatesIdx[ii]) {
      ct += snprintf(fastStates_row+ct, bufSize-ct, " 1");
      i++;
      if (ii < gbData->nFastStates-1) ii++;
    } else {
      ct += snprintf(fastStates_row+ct, bufSize-ct, " 0");
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
modelica_boolean checkFastStatesChange(DATA_GBODE* gbData)
{
  DATA_GBODEF* gbfData = gbData->gbfData;
  modelica_boolean fastStatesChange = FALSE;

  gbfData->nFastStates = gbData->nFastStates;
  gbfData->fastStatesIdx = gbData->fastStatesIdx;

  // check if number of fast states changed
  if (gbfData->nFastStates_old != gbData->nFastStates) {
    fastStatesChange = TRUE;
  } else {
    // look for changes in the ordering
    // TODO memcmp() faster?
    for (int k = 0; k < gbData->nFastStates; k++) {
      if (gbfData->fastStates_old[k] != gbData->fastStatesIdx[k]) {
        fastStatesChange = TRUE;
        break;
      }
    }
  }

  if (fastStatesChange) {
    if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) {
      printIntVector_gb(OMC_LOG_SOLVER, "old fast States:", gbfData->fastStates_old, gbfData->nFastStates_old, gbfData->time);
      printIntVector_gb(OMC_LOG_SOLVER, "new fast States:", gbData->fastStatesIdx, gbData->nFastStates, gbfData->time);
    }

    // Update indices for the current fast states and corresponding counting
    gbfData->nFastStates_old = gbData->nFastStates;
    // TODO memcpy() faster?
    for (int k = 0; k < gbData->nFastStates; k++) {
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
void logSolverStats(enum OMC_LOG_STREAM stream, const char* name, double timeValue, double integratorTime, double stepSize, SOLVERSTATS* stats)
{
  if (OMC_ACTIVE_STREAM(stream)) {
    infoStreamPrint(stream, 1, "%s call statistics:", name);
    infoStreamPrint(stream, 0, "number of steps taken so far: %d", stats->nStepsTaken);
    infoStreamPrint(stream, 0, "number of calls of functionODE() : %d", stats->nCallsODE);
    infoStreamPrint(stream, 0, "number of calculation of jacobian : %d", stats->nCallsJacobian);
    infoStreamPrint(stream, 0, "error test failure : %d", stats->nErrorTestFailures);
    infoStreamPrint(stream, 0, "convergence failure : %d", stats->nConvergenceTestFailures);
    messageClose(stream);
  }
}

/**
 * @brief Info message for GBODE replacement.
 *
 * Dumps simulation flags to use to OMC_LOG_STDOUT.
 *
 * @param gbMethod  GBODE method to use.
 * @param constant  If true use constant step size.
 */
void replacementString(enum GB_METHOD gbMethod, modelica_boolean constant)
{
  if (constant) {
    infoStreamPrint(OMC_LOG_STDOUT, 1, "Use integration method GBODE with method '%s' and constant step size instead:", GB_METHOD_NAME[gbMethod]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Choose integration method '%s' in Simulation Setup->General and additional simulation flags '-%s=%s -%s=%s' in Simulation Setup->Simulation Flags.",
                    SOLVER_METHOD_NAME[S_GBODE], FLAG_NAME[FLAG_SR], GB_METHOD_NAME[gbMethod], FLAG_NAME[FLAG_SR_CTRL], GB_CTRL_METHOD_NAME[GB_CTRL_CNST]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "or");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Simulation flags '-s=%s -%s=%s -%s=%s'.",
                    SOLVER_METHOD_NAME[S_GBODE], FLAG_NAME[FLAG_SR], GB_METHOD_NAME[gbMethod], FLAG_NAME[FLAG_SR_CTRL], GB_CTRL_METHOD_NAME[GB_CTRL_CNST]);
  } else {
    infoStreamPrint(OMC_LOG_STDOUT, 1, "Use integration method GBODE with method '%s' instead:", GB_METHOD_NAME[gbMethod]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Choose integration method '%s' in Simulation Setup->General and additional simulation flags '-%s=%s' in Simulation Setup->Simulation Flags.",
                    SOLVER_METHOD_NAME[S_GBODE], FLAG_NAME[FLAG_SR], GB_METHOD_NAME[gbMethod]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "or");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Simulation flags '-s=%s -%s=%s'.",
                    SOLVER_METHOD_NAME[S_GBODE], FLAG_NAME[FLAG_SR], GB_METHOD_NAME[gbMethod]);
  }
  messageClose(OMC_LOG_STDOUT);
}

/**
 * @brief Display deprecation warning for integration methods replaced by GBODE.
 *
 * Deprecated methods: None
 *
 * @param solverMethod  Integration method.
 */
void deprecationWarningGBODE(enum SOLVER_METHOD method)
{
  switch (method) {
    case S_RUNGEKUTTA:
      break;
    default:
      return;
  }

  warningStreamPrint(OMC_LOG_STDOUT, 1, "Integration method '%s' is deprecated and will be removed in a future version of OpenModelica.", SOLVER_METHOD_NAME[method]);
  switch (method) {
    case S_RUNGEKUTTA:
      replacementString(RK_RUNGEKUTTA, TRUE);
      break;
    default:
      throwStreamPrint(NULL, "Not reachable state");
  }

  infoStreamPrint(OMC_LOG_STDOUT, 0 , "See OpenModelica User's Guide section on GBODE for more details: https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/solving.html#gbode");
  messageCloseWarning(OMC_LOG_STDOUT);
  return;
}

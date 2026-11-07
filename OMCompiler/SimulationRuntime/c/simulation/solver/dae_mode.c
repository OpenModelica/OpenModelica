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

#include <float.h>
#include <math.h>
#include <string.h>

#include "../arrayIndex.h"

#include "dae_mode.h"

#ifdef __cplusplus
extern "C" {
#endif

/* EVAL_DYNAMIC = 1000 */
const int EVAL_DYNAMIC = 1;
/* EVAL_ALGEBRAIC = 0100 */
const int EVAL_ALGEBRAIC = 2;
/* EVAL_ZEROCROSS = 0010 */
const int EVAL_ZEROCROSS = 4;
/* EVAL_DISCRETE = 0001 */
const int EVAL_DISCRETE = 8;
/* EVAL_ALL = 1111 */
const int EVAL_ALL = 15;


/*! \fn void evaluateDAEResiduals_wrapperEventUpdate
 *
 * wrapper function of the main evaluation function for DAE mode
 */
int evaluateDAEResiduals_wrapperEventUpdate(DATA* data, threadData_t* threadData)
{
  int retVal;

  data->simulationInfo->discreteCall = 1;
  retVal = data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_DISCRETE);
  data->simulationInfo->discreteCall = 0;

  return retVal;
}

/*! \fn void evaluateDAEResiduals_wrapperZeroCrossingsEquations
 *
 * wrapper function of the ZeroCrossing function for DAE mode
 */
int evaluateDAEResiduals_wrapperZeroCrossingsEquations(DATA* data, threadData_t* threadData)
{
  int retVal;
  retVal = data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_ZEROCROSS);

  return retVal;
}

/*! \fn void getAlgebraicDAEVarNominals
 *
 *  collects DAE mode algebraic nominal values from modelData
 */
void getAlgebraicDAEVarNominals(DATA* data, double *algebraicNominals)
{
  int i;

  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    algebraicNominals[i] = getNominalFromScalarIdx(data->simulationInfo, data->modelData, VAR_KIND_VARIABLE, daeModeData->algIndexes[i]);
  }
}

/*! \fn getAlgebraicVars
 *
 *  function obtains algebraic variable values for DAEmode
 */
void getAlgebraicDAEVars(DATA *data, double* algebraic)
{
  int i;
  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    algebraic[i] = data->localData[0]->realVars[daeModeData->algIndexes[i]];
  }
}

/*! \fn setAlgebraicVars
 *
 *  function set algebraic variable values for DAEmode
 */
void setAlgebraicDAEVars(DATA *data, double* algebraic)
{
  int i;
  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    data->localData[0]->realVars[daeModeData->algIndexes[i]] = algebraic[i];
  }
}

/* Gaussian elimination with partial pivoting on the row-major a; b becomes the
 * solution. Returns 0 for a singular matrix. */
static int luSolve(double *a, double *b, size_t n)
{
  size_t i, j, k, p;
  double best, v, f, s;
  for (k = 0; k < n; k++) {
    p = k;
    best = fabs(a[k*n+k]);
    for (i = k+1; i < n; i++) {
      v = fabs(a[i*n+k]);
      if (v > best) {
        best = v;
        p = i;
      }
    }
    if (!(best > 0.0) || !isfinite(best)) {
      return 0;
    }
    if (p != k) {
      for (j = 0; j < n; j++) {
        v = a[k*n+j]; a[k*n+j] = a[p*n+j]; a[p*n+j] = v;
      }
      v = b[k]; b[k] = b[p]; b[p] = v;
    }
    for (i = k+1; i < n; i++) {
      f = a[i*n+k] / a[k*n+k];
      if (f == 0.0) {
        continue;
      }
      for (j = k; j < n; j++) {
        a[i*n+j] -= f * a[k*n+j];
      }
      b[i] -= f * b[k];
    }
  }
  for (k = n; k-- > 0;) {
    s = b[k];
    for (j = k+1; j < n; j++) {
      s -= a[k*n+j] * b[j];
    }
    b[k] = s / a[k*n+k];
  }
  return 1;
}

/* NaN when an element is NaN */
static double maxNorm(const double *f, int n)
{
  int i;
  double m = 0.0;
  for (i = 0; i < n; i++) {
    if (!(fabs(f[i]) <= m)) {
      m = fabs(f[i]);
    }
  }
  return m;
}

/* The unknowns of the residual: der(x), then the algebraic DAE variables. */
static double* daeUnknown(DATA *data, int j)
{
  long nStates = data->modelData->nStates;
  return j < nStates ? &data->localData[0]->realVars[nStates + j]
                     : &data->localData[0]->realVars[data->simulationInfo->daeModeData->algIndexes[j - nStates]];
}

static void daeResidual(DATA *data, threadData_t *threadData, const double *u, double *f, int n)
{
  int j;
  DAEMODE_DATA *daeModeData = data->simulationInfo->daeModeData;
  for (j = 0; j < n; j++) {
    *daeUnknown(data, j) = u[j];
  }
  daeModeData->evaluateDAEResiduals(data, threadData, EVAL_DYNAMIC);
  memcpy(f, daeModeData->residualVars, n * sizeof(double));
}

/* The coloring of the residual's sparsity pattern, or NULL to difference each
 * column on its own. */
static const SPARSE_PATTERN* usablePattern(DAEMODE_DATA *daeModeData)
{
  const SPARSE_PATTERN *sp = daeModeData->sparsePattern;
  unsigned int c, k, n = daeModeData->nResidualVars;
  if (!sp || sp->sizeCols != n || sp->maxColors == 0) {
    return NULL;
  }
  for (c = 0; c < n; c++) {
    if (sp->colorCols[c] == 0 || sp->colorCols[c] > sp->maxColors) {
      return NULL;
    }
    for (k = sp->leadindex[c]; k < sp->leadindex[c+1]; k++) {
      if (sp->index[k] >= n) {
        return NULL;
      }
    }
  }
  return sp;
}

size_t solveDAEModeExplicitWorkSize(DATA *data)
{
  size_t n = data->simulationInfo->daeModeData->nResidualVars;
  return n*n + 7*n;
}

/*! \fn solveDAEModeExplicit
 *
 *  Solves F(t, x, der(x), z) = 0 for der(x) and the algebraic DAE variables z,
 *  for an FMU of a --daeMode model that runs as an ODE. Damped Newton from the
 *  current values, with a difference-quotient Jacobian by the colors of the
 *  residual's sparsity pattern; a der(x) column has the pattern of x's column.
 *  work holds solveDAEModeExplicitWorkSize doubles.
 *
 *  Returns 0 on success.
 */
int solveDAEModeExplicit(DATA *data, threadData_t *threadData, double *work)
{
  const int maxIter = 100;
  const double rtol = 1e-10;
  DAEMODE_DATA *daeModeData = data->simulationInfo->daeModeData;
  const SPARSE_PATTERN *sp = usablePattern(daeModeData);
  int n = daeModeData->nResidualVars, nStates = data->modelData->nStates;
  int i, j, k, iter, ls, color, nColors, accepted, converged;
  size_t nn = (size_t) n * (size_t) n;
  double *jac = work, *u = jac + nn, *scale = u + n, *f0 = scale + n, *f1 = f0 + n;
  double *delta = f1 + n, *trial = delta + n, *saved = trial + n;
  double fnorm, fn1, lambda, nom, *tmp;

  if (n <= 0) {
    return 0;
  }
  if (daeModeData->nAlgebraicDAEVars + nStates != n) {
    return -1;
  }
  for (j = 0; j < n; j++) {
    u[j] = *daeUnknown(data, j);
    scale[j] = 1.0;
  }
  getAlgebraicDAEVarNominals(data, scale + nStates);
  for (j = nStates; j < n; j++) {
    nom = fabs(scale[j]);
    scale[j] = nom > 0.0 && isfinite(nom) ? nom : 1.0;
  }
  nColors = sp ? (int) sp->maxColors : n;

  daeResidual(data, threadData, u, f0, n);
  fnorm = maxNorm(f0, n);
  for (iter = 0; iter < maxIter; iter++) {
    if (!isfinite(fnorm)) {
      return -1;
    }
    if (fnorm == 0.0) {
      return 0;
    }
    memset(jac, 0, nn*sizeof(double));
    for (color = 0; color < nColors; color++) {
      for (j = 0; j < n; j++) {
        if (sp ? (int) sp->colorCols[j] == color + 1 : j == color) {
          saved[j] = u[j];
          u[j] += sqrt(DBL_EPSILON) * fmax(fabs(u[j]), scale[j]);
        }
      }
      daeResidual(data, threadData, u, f1, n);
      for (j = 0; j < n; j++) {
        if (sp ? (int) sp->colorCols[j] == color + 1 : j == color) {
          double h = u[j] - saved[j];
          u[j] = saved[j];
          if (sp) {
            for (k = sp->leadindex[j]; k < (int) sp->leadindex[j+1]; k++) {
              i = sp->index[k];
              jac[(size_t)i*n+j] = (f1[i] - f0[i]) / h;
            }
          } else {
            for (i = 0; i < n; i++) {
              jac[(size_t)i*n+j] = (f1[i] - f0[i]) / h;
            }
          }
        }
      }
    }
    for (i = 0; i < n; i++) {
      delta[i] = -f0[i];
    }
    if (!luSolve(jac, delta, n)) {
      return -1;
    }
    lambda = 1.0;
    accepted = 0;
    for (ls = 0; ls < 8; ls++) {
      for (i = 0; i < n; i++) {
        trial[i] = u[i] + lambda * delta[i];
      }
      daeResidual(data, threadData, trial, f1, n);
      fn1 = maxNorm(f1, n);
      if (isfinite(fn1) && fn1 < fnorm * (1.0 - 1e-4 * lambda)) {
        accepted = 1;
        break;
      }
      lambda *= 0.5;
    }
    if (!accepted) {
      lambda = 1.0;
      for (i = 0; i < n; i++) {
        trial[i] = u[i] + delta[i];
      }
      daeResidual(data, threadData, trial, f1, n);
    }
    converged = 1;
    for (i = 0; i < n; i++) {
      if (!(fabs(lambda * delta[i]) <= rtol * fmax(fabs(u[i]), scale[i]))) {
        converged = 0;
      }
    }
    memcpy(u, trial, n*sizeof(double));
    tmp = f0; f0 = f1; f1 = tmp;
    fnorm = maxNorm(f0, n);
    if (converged && isfinite(fnorm)) {
      return 0;
    }
  }
  return fnorm == 0.0 ? 0 : -1;
}

#ifdef __cplusplus
}
#endif

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

#include "gbode_err.h"
#include "gbode_internal_nls.h"

#include <float.h>
#include <math.h>

/* some constants for less verbose BLAS calls */
static const double DBL_ZERO = 0.0;
static const double DBL_ONE = 1.0;
static const double DBL_MINUS_ONE = -1.0;
static const int INT_ONE = 1;
static const char CHAR_NO_TRANS = 'N';

/* y := a * x + y */
extern void daxpy_(const int *n,
                   const double *alpha,
                   const double *x, const int *incX,
                   double *y, const int *incY);

/* y := alpha * A * x + beta * y */
extern void dgemv_(const char *trans,
                   const int *m,
                   const int *n,
                   const double *alpha, const double *A, const int *ldA,
                   const double *x, const int *incX,
                   const double *beta, double *y, const int *incY
);

/* x := alpha * x */
extern void dscal_(const int *n,
                   const double *alpha,
                   double *x, const int *incX);

static inline void setErrorEstimatorOrder(GB_ERROR_CONTEXT *context, int order)
{
  if (context->isFast)
  {
    context->gbfData->currentErrorOrder = order;
  }
  else
  {
    context->gbData->currentErrorOrder = order;
  }
}

static inline int evaluateError(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator)
{
  if (estimator == NULL || estimator->type == GB_ERROR_UNKNOWN || estimator->evaluate == NULL)
  {
    return GB_ERROR_ESTIMATOR_FAILED;
  }

  return estimator->evaluate(context, estimator);
}

int gbEstimateError(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator)
{
  int order = evaluateError(context, estimator);
  if (order < 0)
  {
    return order;
  }

  setErrorEstimatorOrder(context, order);
  return order;
}

double gbScaledErrorTolerance(double tol, int methodOrder, int estimatorOrder, modelica_boolean richardson)
{
  if (richardson || estimatorOrder >= methodOrder)
  {
    return tol;
  }

  const double order_quot = ((double) estimatorOrder + 1.0) / ((double) methodOrder + 1.0);
  const double rtol_pred = GB_TOLERANCE_SCALING_SAFETY * pow(tol, order_quot);

  return fmax(tol, rtol_pred);
}

static void embeddedErrorEstimate_gb(BUTCHER_TABLEAU *tableau, const double *weights, const double *K, double stepSize, int nStates, double *err)
{
  double factors[MAX_GBODE_STAGES];
  int nStages = tableau->nStages;

  for (int stage = 0; stage < nStages; stage++)
  {
    factors[stage] = stepSize * (tableau->b[stage] - weights[stage]);
  }

  /* err := stepSize * (K otimes I) * (b - weights) */
  dgemv_(&CHAR_NO_TRANS,
         &nStates,
         &nStages,
         &DBL_ONE, K, &nStates,
         factors, &INT_ONE,
         &DBL_ZERO, err, &INT_ONE);
}

static inline void absErrorEstimate_gb(int nStates, double *errest)
{
  for (int i = 0; i < nStates; i++)
  {
    errest[i] = fabs(errest[i]);
  }
}

static void embeddedErrorEstimate_gbf(BUTCHER_TABLEAU *tableau, const double *weights, DATA_GBODE *gbData, DATA_GBODEF *gbfData, const double *K, double *err)
{
  int nStates = gbData->nStates;
  int nFastStates = gbData->nFastStates;
  int nStages = tableau->nStages;
  double factors[MAX_GBODE_STAGES];

  for (int stage = 0; stage < nStages; stage++)
  {
    factors[stage] = gbfData->stepSize * (tableau->b[stage] - weights[stage]);
  }

  for (int fast_idx = 0; fast_idx < nFastStates; fast_idx++)
  {
    int full_idx = gbData->fastStatesIdx[fast_idx];
    err[full_idx] = 0.0;
    for (int stage = 0; stage < nStages; stage++)
    {
      err[full_idx] += factors[stage] * K[stage * nStates + full_idx];
    }
  }
}

static void absErrorEstimate_gbf(DATA_GBODE *gbData, DATA_GBODEF *gbfData)
{
  for (int fast_idx = 0; fast_idx < gbData->nFastStates; fast_idx++)
  {
    int full_idx = gbData->fastStatesIdx[fast_idx];
    gbfData->errest[full_idx] = fabs(gbfData->errest[full_idx]);
  }
}

int gbEmbeddedErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator)
{
  const double *weights = (const double *) estimator->data;

  if (weights == NULL)
  {
    return GB_ERROR_ESTIMATOR_FAILED;
  }

  if (context->isFast)
  {
    embeddedErrorEstimate_gbf(context->gbfData->tableau, weights, context->gbData, context->gbfData, context->gbfData->k, context->gbfData->errest);
    absErrorEstimate_gbf(context->gbData, context->gbfData);
  }
  else
  {
    DATA_GBODE *gbData = context->gbData;
    embeddedErrorEstimate_gb(gbData->tableau, weights, gbData->k, gbData->stepSize, gbData->nStates, gbData->errest);
    absErrorEstimate_gb(gbData->nStates, gbData->errest);
  }

  return estimator->order;
}

int gbContractiveDefectErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator)
{
  CONTRACTIVE_DEFECT *contractive = (CONTRACTIVE_DEFECT *) estimator->data;

  if (contractive == NULL)
  {
    return GB_ERROR_ESTIMATOR_FAILED;
  }

  if (context->isFast)
  {
    DATA_GBODE *gbData = context->gbData;
    DATA_GBODEF *gbfData = context->gbfData;

    if (gbfData->tableau->t_transform == NULL || gbfData->nlsSolverMethod != GB_NLS_INTERNAL)
    {
      return GB_ERROR_ESTIMATOR_FAILED;
    }

    double *work = gbInternalGetWorkPointer(((struct dataSolver *)gbfData->nlsData->solverData)->ordinaryData);
    gbInternalContractiveDefect(context->data, context->threadData, gbfData->nlsData, gbData, contractive, work);
    for (int fast_idx = 0; fast_idx < gbData->nFastStates; fast_idx++)
    {
      int full_idx = gbData->fastStatesIdx[fast_idx];
      gbfData->errest[full_idx] = fabs(work[fast_idx]);
    }
  }
  else
  {
    DATA_GBODE *gbData = context->gbData;

    if (gbData->tableau->t_transform == NULL || gbData->nlsSolverMethod != GB_NLS_INTERNAL)
    {
      return GB_ERROR_ESTIMATOR_FAILED;
    }

    gbInternalContractiveDefect(context->data, context->threadData, gbData->nlsData, gbData, contractive, gbData->errest);
    absErrorEstimate_gb(gbData->nStates, gbData->errest);
  }

  return estimator->order;
}

int gbContractiveFilterErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator)
{
  if (context->isFast)
  {
    const double *weights = (const double *) context->gbfData->tableau->error.embedded.data;
    if (weights == NULL || context->gbfData->nlsSolverMethod != GB_NLS_INTERNAL)
    {
      return GB_ERROR_ESTIMATOR_FAILED;
    }
    embeddedErrorEstimate_gbf(context->gbfData->tableau, weights, context->gbData, context->gbfData, context->gbfData->k, context->gbfData->errest);
    gbInternalContractiveFilterError(context->gbfData->nlsData, context->gbData, context->gbfData->errest);
    absErrorEstimate_gbf(context->gbData, context->gbfData);
  }
  else
  {
    DATA_GBODE *gbData = context->gbData;
    const double *weights = (const double *) gbData->tableau->error.embedded.data;
    if (weights == NULL || gbData->nlsSolverMethod != GB_NLS_INTERNAL)
    {
      return GB_ERROR_ESTIMATOR_FAILED;
    }
    embeddedErrorEstimate_gb(gbData->tableau, weights, gbData->k, gbData->stepSize, gbData->nStates, gbData->errest);
    gbInternalContractiveFilterError(gbData->nlsData, gbData, gbData->errest);
    absErrorEstimate_gb(gbData->nStates, gbData->errest);
  }

  return estimator->order;
}

static inline modelica_boolean twoStepScaleMu(double tol,
                                              int methodOrder,
                                              int estimatorOrder,
                                              modelica_boolean richardson,
                                              double *mu)
{
  const double scaled_tol = gbScaledErrorTolerance(tol, methodOrder, estimatorOrder, richardson);
  const double order_quot = ((double) estimatorOrder + 1.0) / ((double) methodOrder + 1.0);

  *mu *= scaled_tol / pow(tol, order_quot);

  // These cases should not occur for a well-conditioned two-step estimator:
  //     - num(r) -> 0, then mu(r) -> inf: the raw estimator loses its leading term and becomes locally one order higher than designed
  //     - den(r) -> 0, then mu(r) -> 0:   the coefficient part already has a pole
  // in both cases the estimator is invalid / inadequate

  if (!isfinite(*mu))
  {
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) warningStreamPrint(OMC_LOG_GBODE, 0, "Two-step estimator mu(r) is not finite - falling back.");
    return FALSE;
  }
  else if (fabs(*mu) < 1e-6)
  {
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) warningStreamPrint(OMC_LOG_GBODE, 0, "Two-step estimator mu(r) is below 1e-6 - falling back.");
    return FALSE;
  }
  else if (fabs(*mu) > 1e6)
  {
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) warningStreamPrint(OMC_LOG_GBODE, 0, "Two-step estimator mu(r) is above 1e6 - falling back.");
    return FALSE;
  }

  return TRUE;
}

static int twoStepEstimate_gb(TWO_STEP_ESTIMATOR *two_step, DATA_GBODE *gbData, double tol, int estimatorOrder)
{
  BUTCHER_TABLEAU *tableau = gbData->tableau;
  double d_old[MAX_GBODE_FIRK_STAGES];
  double g_new[MAX_GBODE_FIRK_STAGES];
  double mu;
  double minus_mu;
  int nStages = tableau->nStages;
  int nStates = gbData->nStates;

  if (tableau->nStages > MAX_GBODE_FIRK_STAGES || gbData->lastStepSize <= 0.0 || gbData->extrapolationBaseTime == INFINITY || gbData->eventHappened || gbData->didFastStep)
  {
    return GB_ERROR_ESTIMATOR_FAILED;
  }

  double r = gbData->stepSize / gbData->lastStepSize;
  two_step->weights(r, d_old, g_new, &mu);
  if (!twoStepScaleMu(tol, tableau->order_b, estimatorOrder, tableau->richardson, &mu))
  {
    return GB_ERROR_ESTIMATOR_FAILED;
  }

  for (int stage = 0; stage < nStages; stage++)
  {
    d_old[stage] *= gbData->lastStepSize;
    g_new[stage] *= gbData->stepSize;
  }

  dgemv_(&CHAR_NO_TRANS,
         &nStates,
         &nStages,
         &DBL_ONE, gbData->kLast, &nStates,
         d_old, &INT_ONE,
         &DBL_ZERO, gbData->errest, &INT_ONE);

  dgemv_(&CHAR_NO_TRANS,
         &nStates,
         &nStages,
         &DBL_ONE, gbData->k, &nStates,
         g_new, &INT_ONE,
         &DBL_ONE, gbData->errest, &INT_ONE);

  daxpy_(&nStates, &DBL_ONE, gbData->yOld, &INT_ONE, gbData->errest, &INT_ONE);

  /* errest := abs(mu * (y - y_emb)) */
  minus_mu = DBL_MINUS_ONE * mu;
  dscal_(&nStates, &minus_mu, gbData->errest, &INT_ONE);
  daxpy_(&nStates, &mu, gbData->y, &INT_ONE, gbData->errest, &INT_ONE);
  absErrorEstimate_gb(nStates, gbData->errest);

  return 0;
}

static int twoStepEstimate_gbf(TWO_STEP_ESTIMATOR *two_step, DATA_GBODE *gbData, DATA_GBODEF *gbfData, double tol, int estimatorOrder)
{
  BUTCHER_TABLEAU *tableau = gbfData->tableau;
  double d_old[MAX_GBODE_FIRK_STAGES];
  double g_new[MAX_GBODE_FIRK_STAGES];
  double mu;
  int nStates = gbData->nStates;
  int nFastStates = gbData->nFastStates;
  int nStages = tableau->nStages;

  if (tableau->nStages > MAX_GBODE_FIRK_STAGES || gbfData->lastStepSize <= 0.0 || !gbfData->extrapolationValid)
  {
    return GB_ERROR_ESTIMATOR_FAILED;
  }

  double r = gbfData->stepSize / gbfData->lastStepSize;
  two_step->weights(r, d_old, g_new, &mu);
  if (!twoStepScaleMu(tol, tableau->order_b, estimatorOrder, tableau->richardson, &mu))
  {
    return GB_ERROR_ESTIMATOR_FAILED;
  }

  for (int stage = 0; stage < nStages; stage++)
  {
    d_old[stage] *= gbfData->lastStepSize;
    g_new[stage] *= gbfData->stepSize;
  }

  for (int fast_idx = 0; fast_idx < nFastStates; fast_idx++)
  {
    int full_idx = gbData->fastStatesIdx[fast_idx];
    double y_emb = gbfData->yOld[full_idx];
    for (int stage = 0; stage < nStages; stage++)
    {
      double k_new = gbfData->nlsSolverMethod == GB_NLS_INTERNAL
                   ? gbfData->kCurrPacked[stage * nFastStates + fast_idx]
                   : gbfData->k[stage * nStates + full_idx];
      y_emb += d_old[stage] * gbfData->kLast[stage * nFastStates + fast_idx] + g_new[stage] * k_new;
    }
    gbfData->errest[full_idx] = fabs(mu * (gbfData->y[full_idx] - y_emb));
  }

  return 0;
}

int gbTwoStepErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator)
{
  TWO_STEP_ESTIMATOR *two_step = (TWO_STEP_ESTIMATOR *) estimator->data;

  if (two_step == NULL)
  {
    return GB_ERROR_ESTIMATOR_FAILED;
  }

  const double tol = context->data->simulationInfo->tolerance;
  int order = context->isFast ? twoStepEstimate_gbf(two_step, context->gbData, context->gbfData, tol, estimator->order)
                              : twoStepEstimate_gb(two_step, context->gbData, tol, estimator->order);
  if (order >= 0)
  {
    return estimator->order;
  }

  return evaluateError(context, two_step->fallback);
}

int gbRichardsonErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator)
{
  (void) context; // suppress it.
  return estimator->order;
}

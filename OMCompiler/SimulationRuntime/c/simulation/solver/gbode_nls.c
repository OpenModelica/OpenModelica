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

/*! \file gbode_nls.c
 */

#include "gbode_main.h"
#include "gbode_nls.h"
#include "gbode_util.h"
#include "gbode_sparse.h"

#include "../../simulation_data.h"

#include "solver_main.h"
#include "kinsolSolver.h"
#include "kinsol_b.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"

#include "../jacobian_util.h"
#include "../../util/rtclock.h"

/* forward declarations */
int jacobian_SR_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian);
int jacobian_MR_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian);
int jacobian_IRK_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian);

void mapSparsePatterns(SPARSE_PATTERN *I_plus_J_pat, JACOBIAN *jacobian_ODE, GB_INTERNAL_NLS_DATA *nls, int size);

typedef struct KLUInternals
{
    klu_common common;
    klu_symbolic *symbolic;
    klu_numeric *numeric;
} KLUInternals;

SPARSE_PATTERN* buildSparsePatternWithDiagonal(const SPARSE_PATTERN *pat_ode,
                                               int n)
{
  unsigned int i = 0, j = 0;
  unsigned int diags = 0;
  unsigned int row;
  unsigned int shift = 0;
  modelica_boolean diag_elem_nonzero;

  for (row = 0; row < n; row++) {
    for (; i < pat_ode->leadindex[row+1]; i++) {
      if (pat_ode->index[i] == row)
        diags++;
    }
  }

  int missing_diags = n - diags;
  int new_nnz = pat_ode->numberOfNonZeros + missing_diags;

  SPARSE_PATTERN *pat = allocSparsePattern(n, new_nnz, n);

  i = 0;
  j = 0;
  pat->leadindex[0] = pat_ode->leadindex[0];

  for (row = 0; row < n; row++) {
    diag_elem_nonzero = FALSE;

    int ode_end = pat_ode->leadindex[row+1];

    for (; j < ode_end; ) {
      int r = pat_ode->index[j];

      if (r > row && !diag_elem_nonzero) {
        pat->index[i++] = row;
        shift++;
        pat->leadindex[row+1] = pat_ode->leadindex[row+1] + shift;
        diag_elem_nonzero = TRUE;
      }

      if (r == row)
      {
        diag_elem_nonzero = TRUE;
      }

      pat->index[i++] = r;
      j++;
    }

    if (!diag_elem_nonzero) {
      pat->index[i++] = row;
      shift++;
    }

    pat->leadindex[row+1] = pat_ode->leadindex[row+1] + shift;
  }

  pat->numberOfNonZeros = i;
  pat->sizeofIndex = i;

  return pat;
}

int gbInternal_KLU_analyze(KLUInternals *internals, int size, int *Ap, int *Ai)
{
  klu_defaults(&internals->common);
  internals->symbolic = klu_analyze(size, Ap, Ai, &internals->common);
  return internals->common.status;
}

int gbInternal_dKLU_factorize(KLUInternals *internals, int size, int *Ap, int *Ai, double *values)
{
  internals->numeric = klu_factor(Ap, Ai, values, internals->symbolic, &internals->common);
  return internals->common.status;
}

int gbInternal_dKLU_solve(KLUInternals *internals, int size, int *Ap, int *Ai, double *rhs)
{
  int nrhs = 1; /* we could solve all of ESDIRK at once this way */
  int ok = klu_solve(internals->symbolic, internals->numeric, size, nrhs, rhs, &internals->common);
  return ok;
}

int gbInternal_zKLU_factorize(KLUInternals *internals, int size, int *Ap, int *Ai, double *values)
{
  internals->numeric = klu_z_factor(Ap, Ai, values, internals->symbolic, &internals->common);
  return internals->common.status;
}

int gbInternal_zKLU_solve(KLUInternals *internals, int size, int *Ap, int *Ai, double *rhs)
{
  int nrhs = 1;
  int ok = klu_z_solve(internals->symbolic, internals->numeric, size, nrhs, rhs, &internals->common);
  return ok;
}

GB_INTERNAL_NLS_DATA *gbInternalNlsAllocate(int size, NLS_USERDATA* userData, modelica_boolean attemptRetry, modelica_boolean isPatternAvailable)
{
  BUTCHER_TABLEAU *tabl = ((DATA_GBODE *)userData->solverData)->tableau;
  T_TRANSFORM *trfm = tabl->t_transform;
  JACOBIAN* jacobian_ODE = &(userData->data->simulationInfo->analyticJacobians[userData->data->callback->INDEX_JAC_A]);

  GB_INTERNAL_NLS_DATA *nls = (GB_INTERNAL_NLS_DATA *) malloc(sizeof(GB_INTERNAL_NLS_DATA));
  nls->nls_user_data = userData;
  nls->size = jacobian_ODE->sizeRows;
  nls->jacobian_callback = (double *) malloc(jacobian_ODE->sparsePattern->numberOfNonZeros * sizeof(double));
  nls->ode_to_nls = malloc(jacobian_ODE->sparsePattern->numberOfNonZeros * sizeof(int));
  nls->nls_diag_indices = malloc(jacobian_ODE->sizeRows * sizeof(int));
  nls->tabl = tabl;
  nls->use_t_transform = (trfm != NULL);
  if (nls->use_t_transform)
  {
    nls->sparsePattern = buildSparsePatternWithDiagonal(jacobian_ODE->sparsePattern, jacobian_ODE->sizeRows);
  }
  else
  {
    nls->sparsePattern = userData->nlsData->sparsePattern;
  }

  // create ODE Jac -> NLS Jacobian mapping
  mapSparsePatterns(nls->sparsePattern, jacobian_ODE, nls, jacobian_ODE->sizeRows);

  nls->scal = (double *) malloc(jacobian_ODE->sizeRows * sizeof(double));
  nls->etas = (double *) malloc(tabl->nStages * sizeof(double));
  for (int i = 0; i < tabl->nStages; i++)
  {
    nls->etas[i] = 1e300;
  }

  // TODO: some refactoring for tolerances here?
  // TODO: is this transform of ATOL and RTOL only valid for superconvergened FIRK (Radau, Lobatto, Gauss)?
  // TODO: check leaks
  // TODO: add dense output for FIRK
  // TODO: update guess routines
  // TODO: update embedded for FIRK with real eigenvalue

  nls->rtol = userData->data->simulationInfo->tolerance;
  nls->atol = userData->data->simulationInfo->tolerance;
  double order_quot = ((double)tabl->order_bt + 1.0) / ((double)tabl->order_b + 1.0);
  double quot = nls->atol / nls->rtol;
  nls->rtol_sc = pow(nls->rtol, order_quot > 1 && !trfm ? 1.0 : order_quot);
  nls->atol_sc = quot * nls->rtol_sc;
  nls->fnewt = fmax(10 * DBL_EPSILON / nls->rtol_sc, fmin(3e-2, pow(nls->rtol_sc, 1.0 / order_quot - 1.0)));
  nls->theta_keep = pow(10.0, -4.0 + 2.0 * log(1.0 + (double)jacobian_ODE->sparsePattern->maxColors) / log(1.0 + (double)nls->size));
  nls->call_jac = TRUE;
  nls->theta_divergence = 0.99;
  nls->max_newton_it = !trfm ? 5 : 4 + 2 * trfm->size; // = 5 for each (E)SDIRK stage and e.g. 10 for full RadauIIA 3-step

  if (!trfm)
  {
    nls->klu_internals_real = (KLUInternals *) malloc(sizeof(KLUInternals));
    nls->klu_internals_cmplx = NULL;
    nls->real_nls_jacs = (double **) malloc(sizeof(double));
    nls->real_nls_jacs[0] = (double *) malloc(nls->sparsePattern->numberOfNonZeros * sizeof(double));
    gbInternal_KLU_analyze(nls->klu_internals_real, nls->size, nls->sparsePattern->leadindex, nls->sparsePattern->index);
  }
  else
  {
    nls->klu_internals_real = (KLUInternals *) malloc(trfm->nRealEigenvalues * sizeof(KLUInternals));
    nls->klu_internals_cmplx = (KLUInternals *) malloc(trfm->nComplexEigenpairs * sizeof(KLUInternals));

    nls->real_nls_jacs = (double **) malloc(trfm->nRealEigenvalues * sizeof(double));
    nls->real_nls_res = (double **) malloc(trfm->nRealEigenvalues * sizeof(double));
    nls->cmplx_nls_jacs = (double **) malloc(trfm->nComplexEigenpairs * sizeof(double));
    nls->cmplx_nls_res = (double **) malloc(trfm->nComplexEigenpairs * sizeof(double));

    for (int sys_real = 0; sys_real < trfm->nRealEigenvalues; sys_real++)
    {
      nls->real_nls_res[sys_real] = (double *) malloc(nls->size * sizeof(double));
      nls->real_nls_jacs[sys_real] = (double *) malloc(nls->sparsePattern->numberOfNonZeros * sizeof(double));
      gbInternal_KLU_analyze(&nls->klu_internals_real[sys_real], nls->size, nls->sparsePattern->leadindex, nls->sparsePattern->index);
    }
    for (int sys_cmplx = 0; sys_cmplx < trfm->nComplexEigenpairs; sys_cmplx++)
    {
      nls->cmplx_nls_res[sys_cmplx] = (double *) malloc(2 * nls->size * sizeof(double));
      nls->cmplx_nls_jacs[sys_cmplx] = (double *) malloc(2 * nls->sparsePattern->numberOfNonZeros * sizeof(double));
      gbInternal_KLU_analyze(&nls->klu_internals_cmplx[sys_cmplx], nls->size, nls->sparsePattern->leadindex, nls->sparsePattern->index);
    }

    // iterate
    nls->Z = (double *) malloc(nls->size * trfm->size * sizeof(double));
    nls->W = (double *) malloc(nls->size * trfm->size * sizeof(double));

    // auxiliary memory
    nls->work = (double *) malloc(nls->size * trfm->size * sizeof(double));
  }

  return nls;
}

void gbInternalNlsFree(GB_INTERNAL_NLS_DATA *nls)
{
  free(nls->jacobian_callback);
  free(nls->ode_to_nls);
  free(nls->nls_diag_indices);
  free(nls->scal);
  free(nls->etas);

  if (!nls->tabl->t_transform)
  {
    if (nls->klu_internals_real->numeric) klu_free_numeric(&nls->klu_internals_real->numeric, &nls->klu_internals_real->common);
    if (nls->klu_internals_real->symbolic) klu_free_symbolic(&nls->klu_internals_real->symbolic, &nls->klu_internals_real->common);
    free(nls->klu_internals_real);
    free(nls->real_nls_jacs[0]);
    free(nls->real_nls_jacs);
  }
  else
  {
    for (int sys_real = 0; sys_real < nls->tabl->t_transform->nRealEigenvalues; sys_real++)
    {
      free(nls->real_nls_jacs[sys_real]);
      free(nls->real_nls_res[sys_real]);
      if (nls->klu_internals_real[sys_real].numeric) klu_free_numeric(&nls->klu_internals_real[sys_real].numeric, &nls->klu_internals_real->common);
      if (nls->klu_internals_real[sys_real].symbolic) klu_free_symbolic(&nls->klu_internals_real[sys_real].symbolic, &nls->klu_internals_real->common);
    }
    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      free(nls->cmplx_nls_jacs[sys_cmplx]);
      free(nls->cmplx_nls_res[sys_cmplx]);
      if (nls->klu_internals_cmplx[sys_cmplx].numeric) klu_free_numeric(&nls->klu_internals_cmplx[sys_cmplx].numeric, &nls->klu_internals_cmplx->common);
      if (nls->klu_internals_cmplx[sys_cmplx].symbolic) klu_free_symbolic(&nls->klu_internals_cmplx[sys_cmplx].symbolic, &nls->klu_internals_cmplx->common);
    }

    free(nls->real_nls_jacs);
    free(nls->real_nls_res);
    free(nls->cmplx_nls_jacs);
    free(nls->cmplx_nls_res);

    if (nls->klu_internals_real) free(nls->klu_internals_real);
    if (nls->klu_internals_cmplx) free(nls->klu_internals_cmplx);

    free(nls->Z);
    free(nls->W);
    free(nls->work);
  }

  free(nls);
}

static void createGbScales(GB_INTERNAL_NLS_DATA *nls, double *y1, double *y2)
{
  for (int i = 0; i < nls->size; i++)
  {
    nls->scal[i] = 1. / (nls->atol_sc * nls->nls_user_data->data->modelData->realVarsData[i].attribute.nominal + fmax(fabs(y1[i]), fabs(y2[i])) * nls->rtol_sc);
  }
}

static double gbScalesNorm(GB_INTERNAL_NLS_DATA *nls, double *vec, int stack_size)
{
  double sum = 0.0;
  for (int j = 0; j < stack_size; j++)
  {
    double *vec_stride = &vec[j * nls->size];
    for (int i = 0; i < nls->size; i++)
    {
      double tmp = vec_stride[i] * nls->scal[i];
      sum += tmp * tmp;
    }
  }

  return sqrt(sum / ((double)nls->size * (double)stack_size));
}

static NLS_SOLVER_STATUS solveNLS_gbInternal_DIRK(DATA *data,
                                                  threadData_t *threadData,
                                                  NONLINEAR_SYSTEM_DATA* nonlinsys,
                                                  DATA_GBODE* gbData,
                                                  GB_INTERNAL_NLS_DATA *nls)
{
  int size = nonlinsys->size;
  int stage = gbData->act_stage;
  double *x = nonlinsys->nlsx;
  double *x_start = nonlinsys->nlsxOld;              // currently the extrapolated (e.g. dense output / hermite guess) | Its awful for Robertson! Something is fishy here!
  // double *x_start = nonlinsys->nlsxExtrapolation; // currently the constant guess (k = 0)
  double *res = nonlinsys->resValues;

  createGbScales(nls, x, x_start);
  double *scal = nls->scal;

  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=gbData};
  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  const int flag = 1;
  modelica_boolean jac_called = FALSE;

  modelica_boolean sdirk_first_stage = (stage == 0 && gbData->tableau->A[0] != 0);
  modelica_boolean esdirk_first_stage = (stage == 1 && gbData->tableau->A[0] == 0);

  if ((sdirk_first_stage || esdirk_first_stage) && gbData->type == GM_TYPE_DIRK)
  {
    if (nls->call_jac)
    {
      /* set values for known last point (simplified Newton) */
      memcpy(data->localData[0]->realVars, gbData->yOld, size * sizeof(double));
      data->localData[0]->timeValue = gbData->timeRight;

      /* callback ODE + callback Jacobian of ODE -> nls_jacobian buffer */
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      evalJacobian(data, threadData, jacobian_ODE, NULL, nls->jacobian_callback, FALSE);
      gbData->stats.nCallsJacobian++;

      jac_called = TRUE;
    }

    if (jac_called || gbData->stepSize != gbData->lastStepSize)
    {
      /* fill NLS Jacobian as h * gamma * J_f - I, where J_f is old or newly computed ODE Jacobian nls->nls->jacobian_callback */
      jacobian_SR_DIRK_assemble(data, threadData, gbData, nls, jacobian_ODE, nls->jacobian_callback, nls->real_nls_jacs[0]);

      /* perform factorization */
      gbInternal_dKLU_factorize(nls->klu_internals_real, size, nonlinsys->sparsePattern->leadindex, nonlinsys->sparsePattern->index, nls->real_nls_jacs[0]);
      gbData->stats.nJacobianFactorizations++;
    }
  }

  memcpy(x, x_start, size * sizeof(double));

  // norms, convergence rate
  double nrm_delta = 0;
  double nrm_delta_prev = 0;
  double theta = 0;

  // Newton iteration count - we start with newt_it = 1, because we need this for the step size selection and conditions below
  for (int newt_it = 1 ;; newt_it++)
  {
    nonlinsys->residualFunc(&resUserData, x, res, &flag);

    gbData->stats.nNewtonStepsTotal++;
    gbInternal_dKLU_solve(nls->klu_internals_real, size, nonlinsys->sparsePattern->leadindex, nonlinsys->sparsePattern->index, res);

    for (int i = 0; i < size; i++)
    {
        x[i] -= res[i];
    }

    nrm_delta_prev = nrm_delta;
    nrm_delta = gbScalesNorm(nls, res, 1);

    if (newt_it > 1)
    {
      theta = nrm_delta / nrm_delta_prev;

      // Newton failed -> divergence
      if (theta >= nls->theta_divergence)
      {
        nls->call_jac = TRUE;
        return NLS_FAILED;
      }

      nls->etas[stage] = theta / (1 - theta);
    }
    else
    {
      nls->etas[stage] = pow(fmax(nls->etas[stage], DBL_EPSILON), 0.8);
    }

      // Newton converged
    if (nls->etas[stage] * nrm_delta < nls->fnewt)
    {
        if (theta < nls->theta_keep)
        {
          nls->call_jac = FALSE;
        }
        else
        {
          nls->call_jac = TRUE;
        }
        return NLS_SOLVED;
    }

    // Newton failed -> iteration limit exceeded or too slow convergence
    if (newt_it == nls->max_newton_it || (pow(theta, nls->max_newton_it - newt_it) / (1 - theta) * nrm_delta > nls->fnewt))
    {
      nls->call_jac = TRUE;
      return NLS_FAILED;
    }
  }
}

static const double ONE = 1.0;
static const double MINUS_ONE = -1.0;
static const double ZERO = 0.0;
static const int INC_ONE = 1;
static const int INC_TWO = 2;
static const char TRANS = 'T';
static const char NO_TRANS = 'N';

extern void daxpy_(const int *n,
                   const double *alpha,
                   const double *x, const int *incX,
                   double *y, const int *incY);

extern void dgemm_(
    const char *trans_A,
    const char *trans_B,
    const int *m,
    const int *n,
    const int *k,
    const double *alpha, const double *A, const int *incA,
    const double *B, const int *incB,
    const double *beta, double *C, const int *incC
);

// we have to use this awful hand written int version, as sundials overwrites the BLAS standard with long instead of int (same for dscal_)
void stride_copy(int *n, const double *x, const int *incx,
                 double *y, const int *incy)
{
  int N = *n;
  int ix = 0;
  int iy = 0;

  int sx = *incx;
  int sy = *incy;

  for (int k = 0; k < N; k++) {
    y[iy] = x[ix];
    ix += sx;
    iy += sy;
  }
}

// Compute out[j] := (T otimes I) * v[j] (block-wise)
void dense_kron_id_vec(int block_count,
                       int block_size,
                       const double *T,
                       const double *v,
                       double *out)
{
  dgemm_(
    &NO_TRANS, &NO_TRANS,
    &block_size, &block_count, &block_count,
    &ONE,
    v, &block_size,
    T, &block_count,
    &ZERO,
    out, &block_size
  );
}

/**
 * @brief Multiply a stacked vector by a scaled block-diagonal 1x1 and 2x2 matrix
 * @par Runtime: O(m * n)
 *
 * Each block is either:
 *   - 1x1 (first / real blocks):  out += gamma * v
 *
 *   - 2x2 (remaining blocks): out0 += a*v0 - b*v1
 *                             out1 += b*v0 + a*v1
 *
 * Each block vector has length block_size. The coefficients alpha and beta are
 * scaled by the input factor.
 *
 * @param[in]  transform   T-transformation data
 * @param[in]  block_size  Size of each block (n)
 * @param[in]  factor      Scaling factor applied to all alpha/beta/gamma coefficients
 * @param[in]  v           Input vector of size m*n, stacked by block:
 *                         v = [v0; v1; ...; v_{m-1}], each v_j is length n
 * @param[out] out         Output vector of size m*n, same layout as v
 */
void scaled_blockdiag_matvec(T_TRANSFORM *transform,
                             int block_size,
                             const double factor,
                             const double *v,
                             double *out)
{
  // use macro for size, so compiler doesnt complain about stack allocation
  double alphas_scaled[MAX_GBODE_FIRK_STAGES];
  double betas_scaled[MAX_GBODE_FIRK_STAGES];
  double gammas_scaled[MAX_GBODE_FIRK_STAGES];

  for (int real_eig = 0; real_eig < transform->nRealEigenvalues; real_eig++)
  {
    gammas_scaled[real_eig] = factor * transform->gamma[real_eig];
  }

  for (int cmplx_eig = 0; cmplx_eig < transform->nComplexEigenpairs; cmplx_eig++)
  {
    alphas_scaled[cmplx_eig] = factor * transform->alpha[cmplx_eig];
    betas_scaled[cmplx_eig] = factor * transform->beta[cmplx_eig];
  }

  // 1x1 real blocks: out_i += a_i * v
  for (int real_eig = 0; real_eig < transform->nRealEigenvalues; real_eig++)
  {
    daxpy_(&block_size, &gammas_scaled[0], &v[real_eig * block_size], &INC_ONE, &out[real_eig * block_size], &INC_ONE);
  }

  int offset = transform->nRealEigenvalues * block_size;

  // 2x2 blocks: out[j]   += [a_j, -b_j] * v[j]
  //             out[j+1] += [b_j,  a_j]   v[j+1]
  for (int cmplx_eig = 0; cmplx_eig < transform->nComplexEigenpairs; cmplx_eig++)
  {
    double a = alphas_scaled[cmplx_eig];
    double b = betas_scaled[cmplx_eig];
    double mb = -b;

    const double *v0 = &v[offset];
    const double *v1 = &v[offset + block_size];

    double *out0 = &out[offset];
    double *out1 = &out[offset + block_size];

    // out0 = a*v0 - b*v1
    daxpy_(&block_size, &a, v0, &INC_ONE, out0, &INC_ONE);  // out0 += a*v0
    daxpy_(&block_size, &mb, v1, &INC_ONE, out0, &INC_ONE); // out0 -= b*v1

    // out1 = a*v1 + b*v0
    daxpy_(&block_size, &a, v1, &INC_ONE, out1, &INC_ONE);  // out1 += a*v1
    daxpy_(&block_size, &b, v0, &INC_ONE, out1, &INC_ONE);  // out1 += b*v0

    offset += 2 * block_size;
  }
}

static NLS_SOLVER_STATUS solveNLS_gbInternal_T_Transform(DATA *data,
                                                         threadData_t *threadData,
                                                         NONLINEAR_SYSTEM_DATA* nonlinsys,
                                                         DATA_GBODE* gbData,
                                                         GB_INTERNAL_NLS_DATA *nls)
{
  int size = nls->size;
  int w_size = nls->size * nls->tabl->t_transform->size;
  double invh = 1.0 / gbData->stepSize;
  double minvh = -invh;
  double *x = nonlinsys->nlsx;
  double *x_start = nonlinsys->nlsxOld;
  double *flat_res = nonlinsys->resValues;

  createGbScales(nls, x, x_start);
  double *scal = nls->scal;

  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=gbData};
  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  T_TRANSFORM *transform = nls->tabl->t_transform;

  const int flag = 1;
  modelica_boolean jac_called = FALSE;

  if (nls->call_jac || transform->firstRowZero)
  {
    /* set values for known last point (simplified Newton) */
    memcpy(data->localData[0]->realVars, gbData->yOld, size * sizeof(double));
    data->localData[0]->timeValue = gbData->timeRight;

    /* callback ODE + callback Jacobian of ODE -> nls_jacobian buffer */
    gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

    if (transform->firstRowZero)
    {
      // save explicit stage (e.g. Lobatto IIIA)
      memcpy(gbData->k, &data->localData[0]->realVars[size], size * sizeof(double));
    }

    if (nls->call_jac)
    {
      evalJacobian(data, threadData, jacobian_ODE, NULL, nls->jacobian_callback, FALSE);
      gbData->stats.nCallsJacobian++;

      jac_called = TRUE;
    }
  }

  if (jac_called || gbData->stepSize != gbData->lastStepSize)
  {
    for (int sys_real = 0; sys_real < nls->tabl->t_transform->nRealEigenvalues; sys_real++)
    {
      /* create Jacobian real: gamma/h * I - J_f */
      jacobian_SR_real_assemble(data, threadData, gbData, nls, nls->tabl->t_transform->gamma[sys_real],
                                jacobian_ODE, nls->jacobian_callback, nls->real_nls_jacs[sys_real]);
      gbInternal_dKLU_factorize(&nls->klu_internals_real[sys_real], size, nls->sparsePattern->leadindex,
                                nls->sparsePattern->index, nls->real_nls_jacs[sys_real]);
    }
    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      /* create Jacobian complex: (alpha + i * beta)/h * I - J_f */
      jacobian_SR_cmplx_assemble(data, threadData, gbData, nls, nls->tabl->t_transform->alpha[sys_cmplx], nls->tabl->t_transform->beta[sys_cmplx],
                                jacobian_ODE, nls->jacobian_callback, nls->cmplx_nls_jacs[sys_cmplx]);
      gbInternal_zKLU_factorize(&nls->klu_internals_cmplx[sys_cmplx], size, nls->sparsePattern->leadindex,
                                nls->sparsePattern->index, nls->cmplx_nls_jacs[sys_cmplx]);
    }

    gbData->stats.nJacobianFactorizations++;
  }

  // we solve for Z = X(t_ij) - X0 or W = (T^{-1} otimes I) * Z, then get K back via K = 1/h * A^{-1} * Z
  double *x0 = gbData->yOld;

  // set guess Z[j] = X_start[j] - X_0
  for (int j = 0; j < transform->size; j++)
  {
    memcpy(&nls->Z[j * size], &x_start[j * size], size * sizeof(double));
    daxpy_(&size, &MINUS_ONE, x0, &INC_ONE, &nls->Z[j * size], &INC_ONE);
  }

  // W = (T^{-1} otimes I) * Z
  dense_kron_id_vec(transform->size, size, transform->T_inv, nls->Z, nls->W);

  // norms, convergence rate
  double nrm_delta = 0;
  double nrm_delta_prev = 0;
  double theta = 0;

  // Newton iteration count - we start with newt_it = 1, because we need this for the step size selection and conditions below
  for (int newt_it = 1 ;; newt_it++)
  {
    // Z = (T otimes I) * W
    if (newt_it != 1)
    {
      dense_kron_id_vec(transform->size, size, transform->T, nls->W, nls->Z);
    }

    // compute residuals: rhs := -1 / h (Lambda otimes I) * W + (T^{-1} * I) * F((T otimes I) * W) + Phi (Phi = T^{-1} A_part^{-1} * K_1 if (K_1 explicit else 0))

    // work[j] = F((T otimes I) * W)[j]
    for (int j = 0; j < transform->size; j++)
    {
      memcpy(data->localData[0]->realVars, x0, size * sizeof(double));
      daxpy_(&size, &ONE, &nls->Z[j * size], &INC_ONE, data->localData[0]->realVars, &INC_ONE);
      data->localData[0]->timeValue = gbData->time + gbData->tableau->c[j + (int)transform->firstRowZero] * gbData->stepSize;
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      memcpy(&nls->work[j * size], &data->localData[0]->realVars[size], size * sizeof(double));
    }

    // rhs[j] = (T^{-1} otimes I) * F((T otimes I) * W)
    dense_kron_id_vec(transform->size, size, transform->T_inv, nls->work, flat_res);

    // rhs[j] += -1 / h * (Lambda otimes I) * W
    scaled_blockdiag_matvec(transform, size, minvh, nls->W, flat_res);

    // add Phi = T^{-1} * A_part^{-1} * a{:, 1} * K_1 if first stage is explicit, else skip (we computed nls->phi = T^{-1} * A_part^{-1} * a{:, 1})
    if (transform->firstRowZero)
    {
      for (int j = 0; j < transform->size; j++)
      {
        daxpy_(&size, &transform->phi[j], gbData->k, &INC_ONE, &flat_res[j * size], &INC_ONE);
      }
    }

    // prepare complex linear system RHS's
    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      stride_copy(&size, &flat_res[(2 * sys_cmplx + transform->nRealEigenvalues) * size],
                  &INC_ONE, &nls->cmplx_nls_res[sys_cmplx][0], &INC_TWO);     // .real
      stride_copy(&size, &flat_res[(2 * sys_cmplx + transform->nRealEigenvalues + 1) * size],
                  &INC_ONE, &nls->cmplx_nls_res[sys_cmplx][1], &INC_TWO);     // .imag
    }

    // solve linear systems
    for (int sys_real = 0; sys_real < nls->tabl->t_transform->nRealEigenvalues; sys_real++)
    {
      gbInternal_dKLU_solve(&nls->klu_internals_real[sys_real], size, nls->sparsePattern->leadindex,
                            nls->sparsePattern->index, &flat_res[sys_real * size]);
    }

    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      gbInternal_zKLU_solve(&nls->klu_internals_cmplx[sys_cmplx], size, nls->sparsePattern->leadindex,
                            nls->sparsePattern->index, &nls->cmplx_nls_res[sys_cmplx][0]);
    }

    // copy solutions of complex systems back to flat buffer
    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      stride_copy(&size, &nls->cmplx_nls_res[sys_cmplx][0], &INC_TWO,
                  &flat_res[(2 * sys_cmplx + transform->nRealEigenvalues) * size], &INC_ONE);     // r1
      stride_copy(&size, &nls->cmplx_nls_res[sys_cmplx][1], &INC_TWO,
                  &flat_res[(2 * sys_cmplx + transform->nRealEigenvalues + 1) * size], &INC_ONE); // r2
    }

    // Newton step (we must do W += dW)
    daxpy_(&w_size, &ONE, flat_res, &INC_ONE, nls->W, &INC_ONE);
    gbData->stats.nNewtonStepsTotal++;

    nrm_delta_prev = nrm_delta;
    nrm_delta = gbScalesNorm(nls, flat_res, nls->tabl->t_transform->size);

    if (newt_it > 1)
    {
      theta = nrm_delta / nrm_delta_prev;

      // Newton failed -> divergence
      if (theta >= nls->theta_divergence)
      {
        nls->call_jac = TRUE;
        return NLS_FAILED;
      }

      *nls->etas = theta / (1 - theta);
    }
    else
    {
      *nls->etas = pow(fmax(*nls->etas, DBL_EPSILON), 0.8);
    }

    // Newton converged
    if (*nls->etas * nrm_delta < nls->fnewt)
    {
      if (theta < nls->theta_keep)
      {
        nls->call_jac = FALSE;
      }
      else
      {
        nls->call_jac = TRUE;
      }

      // Z = (T otimes I) * W
      dense_kron_id_vec(transform->size, size, transform->T, nls->W, nls->Z);

      // set solution X[j] = X_0 + Z[j]
      int offset = transform->firstRowZero ? size : 0;
      for (int j = 0; j < transform->size; j++)
      {
        memcpy(&x[j * size + offset], &nls->Z[j * size], size * sizeof(double));
        daxpy_(&size, &ONE, x0, &INC_ONE, &x[j * size + offset], &INC_ONE);
      }

      // recompute weights K from Z via K = 1 / h * (A^{-1} otimes I) * Z + rho * k_1 if k_1 explicit else 0 (rho := -A_part^{-1} * A_{:, 1})
      dense_kron_id_vec(transform->size, size, transform->A_part_inv, nls->Z, &gbData->k[offset]);
      for (int i = offset; i < w_size + offset; i++)
      {
        gbData->k[i] *= invh; // dscal_
      }

      if (transform->firstRowZero)
      {
        // add k[j] += rho[j] * k_1 or k[j] -= (-A_part^{-1} * A_{:, 1} * k_1)[j] * k_1
        for (int j = 0; j < transform->size; j++)
        {
          daxpy_(&size, &transform->rho[j], gbData->k, &INC_ONE, &gbData->k[offset + j * size], &INC_ONE);
        }
      }

      // for explicit first stage: copy x0 into x (e.g. Lobatto IIIA)
      if (transform->firstRowZero)
      {
        memcpy(x, x0, size * sizeof(double));
      }

      // for explicit last stage: compute final K_s and X_s
      if (transform->lastColumnZero)
      {
        int s_minus1 = nls->tabl->nStages - 1;

        // X_s = x0 + h * sum{j=1}^{s-1} A_{s, j} * k_j as A_{s, s} == 0!
        memcpy(&x[size * s_minus1], x0, size * sizeof(double));
        dgemm_(&NO_TRANS, &TRANS,
               &size, &INC_ONE, &s_minus1,
               &gbData->stepSize,
               gbData->k, &size,
               &gbData->tableau->A[s_minus1 * nls->tabl->nStages], &INC_ONE,
               &ONE,
               &x[size * s_minus1], &size);

        memcpy(data->localData[0]->realVars, &x[size * s_minus1], size * sizeof(double));
        data->localData[0]->timeValue = gbData->timeRight + gbData->stepSize * nls->tabl->c[s_minus1];
        gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

        // k_s = f(t + h * c_s, x0 + h * sum{j=1}^{s-1} A_{s, j} * k_j)
        memcpy(&gbData->k[size * s_minus1], &data->localData[0]->realVars[size], size * sizeof(double));
      }

      return NLS_SOLVED;
    }

    // Newton failed -> iteration limit exceeded or too slow convergence
    if (newt_it == nls->max_newton_it || (pow(theta, nls->max_newton_it - newt_it) / (1 - theta) * nrm_delta > nls->fnewt))
    {
      nls->call_jac = TRUE;
      return NLS_FAILED;
    }
  }
}

// wrap everyhting for now
static NLS_SOLVER_STATUS solveNLS_gbInternal(DATA *data,
                                             threadData_t *threadData,
                                             NONLINEAR_SYSTEM_DATA* nonlinsys,
                                             DATA_GBODE* gbData,
                                             GB_INTERNAL_NLS_DATA *nls)
{
  if (nls->use_t_transform)
  {
    return solveNLS_gbInternal_T_Transform(data, threadData, nonlinsys, gbData, nls);
  }
  else
  {
    return solveNLS_gbInternal_DIRK(data, threadData, nonlinsys, gbData, nls);
  }
}

/**
 * @brief Specific error handling of kinsol for gbode
 *
 * @param error_code  Reported error code
 * @param module      Module of failure
 * @param function    Nonlinear function
 * @param msg         Message of failure
 * @param data        Pointer to userData
 */
void GB_KINErrHandler(int error_code, const char *module, const char *function, char *msg, void *data)
{
// Preparation for specific error handling of the solution process of kinsol for gbode
// This is needed to speed up simulation in case of failure
}

/**
 * @brief Initialize static data of non-linear system for DIRK.
 *
 * Initialize for diagonal implicit Runge-Kutta (DIRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_SR(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsePattern, modelica_boolean initNonlinearPattern)
{
  for (int i = 0; i < nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = data->modelData->realVarsData[i].attribute.min;
    nonlinsys->max[i]     = data->modelData->realVarsData[i].attribute.max;
  }

  /* Initialize sparsity pattern */
  if (initSparsePattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_SR(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
}

/**
 * @brief Initialize static data of non-linear system for DIRK.
 *
 * Initialize for diagonal implicit Runge-Kutta (DIRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_MR(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsePattern, modelica_boolean initNonlinearPattern)
{
  // This needs to be done each time, the fast states change!
  for (int i = 0; i < nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = data->modelData->realVarsData[i].attribute.min;
    nonlinsys->max[i]     = data->modelData->realVarsData[i].attribute.max;
  }

  /* Initialize sparsity pattern, First guess (all states are fast states) */
  if (initSparsePattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_SR(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
}

/**
 * @brief Initialize static data of non-linear system for IRK.
 *
 * Initialize for implicit Runge-Kutta (IRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_IRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsePattern, modelica_boolean initNonlinearPattern)
{

  for (int i = 0; i < nonlinsys->size; i++) {
    // Get the nominal values of the states, the non-linear system has size stages*nStates, i.e. [states, states, ...]
    int ii = i % data->modelData->nStates;
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[ii].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = data->modelData->realVarsData[ii].attribute.min;
    nonlinsys->max[i]     = data->modelData->realVarsData[ii].attribute.max;
  }

  /* Initialize sparsity pattern */
  if (initSparsePattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_IRK(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
}

/**
 * @brief Allocate memory for non-linear system data.
 *
 * Initialize varaibles with 0.
 * Free memory with freeNlsDataGB.
 *
 * @param threadData                Used for error handling
 * @param size                      Size of non-linear system
 * @return NONLINEAR_SYSTEM_DATA*   Allocated non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* allocNlsDataGB(threadData_t* threadData, const int size)
{
  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  nlsData->size = size;

  nlsData->nlsx              = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxExtrapolation = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxOld           = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->resValues         = (double*) malloc(nlsData->size*sizeof(double));

  nlsData->nominal = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->min     = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->max     = (double*) malloc(nlsData->size*sizeof(double));
  return nlsData;
}

/**
 * @brief Free non-linear system data.
 *
 * @param nlsData   Pointer to nls-data.
 */
void freeNlsDataGB(NONLINEAR_SYSTEM_DATA* nlsData)
{
  free(nlsData->nlsx);
  free(nlsData->nlsxExtrapolation);
  free(nlsData->nlsxOld);
  free(nlsData->resValues);
  free(nlsData->nominal);
  free(nlsData->min);
  free(nlsData->max);
  free(nlsData);
}

/**
 * @brief Allocate and initialize non-linear system data for Runge-Kutta method.
 *
 * Runge-Kutta method has to be implicit or diagonal implicit.
 *
 * @param data                        Runtime data struct.
 * @param threadData                  Thread data for error handling.
 * @param gbData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GBODE* gbData)
{
  assertStreamPrint(threadData, gbData->type != GM_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  NONLINEAR_SYSTEM_DATA* nlsData;

  nlsData = allocNlsDataGB(threadData, gbData->nlSystemSize);
  nlsData->equationIndex = -1;

  switch (gbData->type)
  {
  case GM_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK;
    if (gbData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_SR_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_SR;
    nlsData->getIterationVars = NULL;

    break;
  case GM_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_IRK;
    if (gbData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_IRK_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_IRK;
    nlsData->getIterationVars = NULL;

    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS;
    if (gbData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_SR_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_SR;
    nlsData->getIterationVars = NULL;

    break;
  default:
    throwStreamPrint(NULL, "Residual function for NLS type %i not yet implemented.", gbData->type);
  }

  nlsData->initializeStaticNLSData(data, threadData, nlsData, TRUE, TRUE);

  gbData->jacobian = (JACOBIAN*) malloc(sizeof(JACOBIAN));
  initJacobian(gbData->jacobian, gbData->nlSystemSize, gbData->nlSystemSize, gbData->nlSystemSize, nlsData->analyticalJacobianColumn, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Set NLS user data */
  NLS_USERDATA* nlsUserData = initNlsUserData(data, threadData, -1, nlsData, gbData->jacobian);
  nlsUserData->solverData = (void*) gbData;

  /* Initialize NLS method */
  switch (gbData->nlsSolverMethod) {
  case GB_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData = (void*) allocateNewtonData(nlsData->size, nlsUserData);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_KINSOL_B:
    nlsData->nlsMethod = NLS_KINSOL_B;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) B_nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_INTERNAL:
      nlsData->nlsMethod = NLS_GB_INTERNAL;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) gbInternalNlsAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  default:
    throwStreamPrint(NULL, "Memory allocation for NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbData->nlsSolverMethod]);
  }

  return nlsData;
}

/**
 * @brief Allocate and initialize non-linear system data for Runge-Kutta method.
 *
 * Runge-Kutta method has to be implicit or diagonal implicit.
 *
 * @param data                        Runtime data struct.
 * @param threadData                  Thread data for error handling.
 * @param gbfData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GBODEF* gbfData)
{
  assertStreamPrint(threadData, gbfData->type != GM_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  struct dataSolver *solverData = (struct dataSolver*) calloc(1, sizeof(struct dataSolver));

  NONLINEAR_SYSTEM_DATA* nlsData;

  nlsData = allocNlsDataGB(threadData, gbfData->nStates);
  nlsData->equationIndex = -1;

  switch (gbfData->type)
  {
  case GM_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK_MR;
    if (gbfData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_MR_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS_MR;
    if (gbfData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_MR_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    break;
  default:
    throwStreamPrint(NULL, "Residual function for NLS type %i not yet implemented.", gbfData->type);
  }

  nlsData->initializeStaticNLSData(data, threadData, nlsData, TRUE, TRUE);

  gbfData->jacobian = (JACOBIAN*) malloc(sizeof(JACOBIAN));
  initJacobian(gbfData->jacobian, gbfData->nlSystemSize, gbfData->nlSystemSize, gbfData->nlSystemSize, nlsData->analyticalJacobianColumn, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Set NLS user data */
  NLS_USERDATA* nlsUserData = initNlsUserData(data, threadData, -1, nlsData, gbfData->jacobian);
  nlsUserData->solverData = (void*) gbfData;

  /* Initialize NLS method */
  switch (gbfData->nlsSolverMethod) {
  case GB_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData =(void*) allocateNewtonData(nlsData->size, nlsUserData);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_KINSOL_B:
    nlsData->nlsMethod = NLS_KINSOL_B;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) B_nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_INTERNAL:
    nlsData->nlsMethod = NLS_GB_INTERNAL;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) gbInternalNlsAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  default:
    throwStreamPrint(NULL, "Memory allocation for NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbfData->nlsSolverMethod]);
  }

  return nlsData;
}

/**
 * @brief Free memory of gbode non-linear system data.
 *
 * Free memory allocated with initRK_NLS_DATA or initRK_NLS_DATA_MR
 *
 * @param nlsData           Pointer to non-linear system data.
 */
void freeRK_NLS_DATA(NONLINEAR_SYSTEM_DATA* nlsData)
{
  if (nlsData == NULL) return;

  struct dataSolver *dataSolver = nlsData->solverData;
  switch (nlsData->nlsMethod)
  {
  case NLS_NEWTON:
    freeNewtonData(dataSolver->ordinaryData);
    break;
  case NLS_KINSOL:
    nlsKinsolFree(dataSolver->ordinaryData);
    break;
  case NLS_KINSOL_B:
    B_nlsKinsolFree(dataSolver->ordinaryData);
    break;
  case NLS_GB_INTERNAL:
    gbInternalNlsFree(dataSolver->ordinaryData);
    break;
  default:
    throwStreamPrint(NULL, "Not handled NONLINEAR_SOLVER in gbode_freeData. Are we leaking memroy?");
  }
  free(dataSolver);
  freeNlsDataGB(nlsData);
}

/**
 * @brief Set kinsol parameters
 *
 * @param kin_mem       Pointer to kinsol data object
 * @param numIter       Number of nonlinear iterations
 * @param jacUpdate     Update of jacobian necessary (SUNFALSE => yes)
 * @param maxJacUpdate  Maximal number of constant jacobian
 */
void set_kinsol_parameters(void* kin_mem, int numIter, int jacUpdate, int maxJacUpdate, double tolerance)
{
    int flag;

    flag = KINSetNumMaxIters(kin_mem, numIter);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNumMaxIters");
    flag = KINSetNoInitSetup(kin_mem, jacUpdate);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNoInitSetup");
    flag = KINSetMaxSetupCalls(kin_mem, maxJacUpdate);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetMaxSetupCalls");
    flag = KINSetFuncNormTol(kin_mem, tolerance);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetFuncNormTol");
}

/**
 * @brief Get the kinsol statistics object
 *
 * @param kin_mem Pointer to kinsol data object
 */
void get_kinsol_statistics(NLS_KINSOL_DATA* kin_mem)
{
  int flag;
  long int nIters, nFuncEvals, nJacEvals;
  double fnorm;

  // Get number of nonlinear iteration steps
  flag = KINGetNumNonlinSolvIters(kin_mem, &nIters);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetNumNonlinSolvIters");

  // Get the error of the residual function
  flag = KINGetFuncNorm(kin_mem, &fnorm);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetFuncNorm");

  // Get the number of jacobian evaluation
  flag = KINGetNumJacEvals(kin_mem, &nJacEvals);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetNumJacEvals");

  // Get the number of function evaluation
  flag = KINGetNumFuncEvals(kin_mem, &nFuncEvals);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetNumFuncEvals");

  // Report numbers
  infoStreamPrint(OMC_LOG_GBODE_NLS, 0, "Kinsol statistics: nIters = %ld, nFuncEvals = %ld, nJacEvals = %ld,  fnorm:  %14.12g", nIters, nFuncEvals, nJacEvals, fnorm);
}

/**
 * @brief Special treatment when solving non linear systems of equations
 *
 *        Will be described, when it is ready
 *
 * @param data                Pointer to runtime data struct.
 * @param threadData          Thread data for error handling.
 * @param nlsData             Non-linear solver data.
 * @param gbData              Runge-Kutta method.
 * @return NLS_SOLVER_STATUS  Return NLS_SOLVED on success and NLS_FAILED otherwise.
 */
NLS_SOLVER_STATUS solveNLS_gb(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nlsData, DATA_GBODE* gbData)
{
  struct dataSolver * solverData = (struct dataSolver *)nlsData->solverData;
  NLS_SOLVER_STATUS solved = NLS_FAILED;

  // Debug nonlinear solution process
  rtclock_t clock;
  double cpu_time_used;
  double newtonTol = fmax(newtonFTol, newtonXTol);
  double newtonMaxStepsValue = fmax(newtonMaxSteps, 10*nlsData->size);

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    rt_ext_tp_tick(&clock);
  }

  if (gbData->nlsSolverMethod == GB_NLS_INTERNAL)
  {
    GB_INTERNAL_NLS_DATA *internal_nls_data = (GB_INTERNAL_NLS_DATA *) solverData->ordinaryData;
    solved = solveNLS_gbInternal(data, threadData, nlsData, gbData, internal_nls_data);
  }
  else if (gbData->nlsSolverMethod == GB_NLS_KINSOL || gbData->nlsSolverMethod == GB_NLS_KINSOL_B) {
    // Get kinsol data object
    void* kin_mem;
    if (gbData->nlsSolverMethod == GB_NLS_KINSOL){
       kin_mem = ((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory;
    }
    else {
       kin_mem = ((B_NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory;
    }
    if (maxJacUpdate[0] > 0) {
      set_kinsol_parameters(kin_mem, newtonMaxSteps, SUNTRUE, maxJacUpdate[0], newtonTol);
      solved = solveNLS(data, threadData, nlsData);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) get_kinsol_statistics(kin_mem);
    }
    if (!solved && maxJacUpdate[1] > 0) {
      if (maxJacUpdate[0] > 0)
        infoStreamPrint(OMC_LOG_GBODE_NLS, 0, "GBODE: Solution of NLS failed. Try with updated Jacobian.");
      set_kinsol_parameters(kin_mem, newtonMaxStepsValue, SUNFALSE, maxJacUpdate[1], newtonTol);
      solved = solveNLS(data, threadData, nlsData);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) get_kinsol_statistics(kin_mem);
    }
    if (!solved && maxJacUpdate[2] > 0) {
      infoStreamPrint(OMC_LOG_GBODE_NLS, 0, "GBODE: Solution of NLS failed, Try with extrapolated start value.");
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsxOld,  nlsData->size*sizeof(modelica_real));
      set_kinsol_parameters(kin_mem, newtonMaxStepsValue, SUNFALSE, maxJacUpdate[2], newtonTol);
      solved = solveNLS(data, threadData, nlsData);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) get_kinsol_statistics(kin_mem);
    }
    if (!solved && maxJacUpdate[3] > 0) {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "GBODE: Solution of NLS failed, Try with less accuracy.");
      memcpy(nlsData->nlsxExtrapolation,    nlsData->nlsx, nlsData->size*sizeof(modelica_real));
      set_kinsol_parameters(kin_mem, newtonMaxStepsValue, SUNFALSE, maxJacUpdate[3], 10*newtonTol);
      solved = solveNLS(data, threadData, nlsData);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) get_kinsol_statistics(kin_mem);
    }
  } else {
    solved = solveNLS(data, threadData, nlsData);
  }

  if (solved)
    infoStreamPrint(OMC_LOG_GBODE_NLS_V, 0, "GBODE: NLS solved.");

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    cpu_time_used = rt_ext_tp_tock(&clock);
    infoStreamPrint(OMC_LOG_GBODE_NLS, 0, "Time needed for solving the NLS:  %20.16g", cpu_time_used);
  }

  return solved;
}

/**
 * @brief Residual function for non-linear system of generic multi-step methods.
 *
 * Based on the values of the multi-step method the following nonlinear residuals
 * will be calculated:
 * res = -sum(c[j]*x[j], i=1..stage) + h*sum(b[j]*k[j], i=1..stage)
 * When calling, the following is already calculated:
 *  sData->timeValue = tOld + h
 *  res_const = -sum(c[j]*x[j], i=1..stage-1) + h*sum(b[j]*k[j], i=1..stage-1)
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_MS(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODE *gbData = (DATA_GBODE *)userData->solverData;
  assertStreamPrint(threadData, gbData != NULL, "residual_MS: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i;
  const int nStates = data->modelData->nStates;
  const int nStages = gbData->tableau->nStages;

  // Set states
  for (i = 0; i < nStates; i++)
    assertStreamPrint(threadData, !isnan(xloc[i]), "residual_MS: xloc is NAN");
  memcpy(sData->realVars, xloc, nStates*sizeof(modelica_real));
  // Evaluate right hand side of ODE
  gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
  for (i = 0; i < nStates; i++)
    assertStreamPrint(threadData, !isnan(fODE[i]), "residual_MS: fODE is NAN");

  // Evaluate residuals
  for (i = 0; i < nStates; i++) {
    res[i] = gbData->res_const[i]
             - xloc[i] * gbData->tableau->c[nStages-1]
             + fODE[i] * gbData->tableau->b[nStages-1] * gbData->stepSize;
  }
}

/**
 * @brief Residual function for non-linear system of generic multi-step methods.
 *
 * For the fast states:
 * Based on the values of the multi-step method the following nonlinear residuals
 * will be calculated:
 * res = -sum(c[j]*x[j], i=1..stage) + h*sum(b[j]*k[j], i=1..stage)
 * When calling, the following is already calculated:
 *  sData->timeValue = tOld + h
 *  res_const = -sum(c[j]*x[j], i=1..stage-1) + h*sum(b[j]*k[j], i=1..stage-1)
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_MS_MR(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODEF *gbfData = (DATA_GBODEF *)userData->solverData;
  assertStreamPrint(threadData, gbfData != NULL, "residual_MS_MR: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  const int nFastStates = gbfData->nFastStates;
  const int nStages = gbfData->tableau->nStages;

  // Set fast states
  // ph: are slow states interpolated and set correctly?
  for (ii = 0; ii < nFastStates; ii++) {
    assertStreamPrint(threadData, !isnan(xloc[ii]), "residual_MS_MR: xloc is NAN");
    i = gbfData->fastStatesIdx[ii];
    sData->realVars[i] = xloc[ii];
  }
  // Evaluate right hand side of ODE
  gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE));

  // Evaluate residuals
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbfData->fastStatesIdx[ii];
    assertStreamPrint(threadData, !isnan(fODE[i]), "residual_MS_MR: fODE is NAN");
    res[ii] = gbfData->res_const[i]
              - xloc[ii] * gbfData->tableau->c[nStages-1]
              + fODE[i]  * gbfData->tableau->b[nStages-1] * gbfData->stepSize;
  }
}

/**
 * @brief Residual function for non-linear system for diagonal implicit Runge-Kutta methods.
 *
 * Based on the Butcher tableau the following nonlinear residuals will be calculated:
 * res = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], j=1..act_stage))
 * When calling, the following is already calculated:
 *  sData->timeValue = tOld + c[i]*h
 *  res_const = yOld + h*sum(A[i,j]*k[j], j=1..act_stage-1)
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_DIRK(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODE *gbData = (DATA_GBODE *)userData->solverData;
  assertStreamPrint(threadData, gbData != NULL, "residual_DIRK: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i;
  const int nStates = data->modelData->nStates;
  const int nStages = gbData->tableau->nStages;
  const int stage_  = gbData->act_stage;
  const modelica_real fac = gbData->stepSize * gbData->tableau->A[stage_ * nStages + stage_];

  sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;
  // Set states
  for (i = 0; i < nStates; i++)
    assertStreamPrint(threadData, !isnan(xloc[i]), "residual_DIRK: xloc is NAN");
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  // Evaluate right hand side of ODE
  gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

  // Evaluate residuals
  for (i = 0; i < nStates; i++) {
    assertStreamPrint(threadData, !isnan(fODE[i]), "residual_DIRK: fODE is NAN");
    res[i] = gbData->res_const[i] - xloc[i] + fac * fODE[i];
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    infoStreamPrint(OMC_LOG_GBODE_NLS, 1, "NLS - x and residual:");
    printVector_gb(OMC_LOG_GBODE_NLS, "x", (double *)xloc, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
    printVector_gb(OMC_LOG_GBODE_NLS, "r", res, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
    messageClose(OMC_LOG_GBODE_NLS);
  }
}

/**
 * @brief Residual function for non-linear system for diagonal implicit Runge-Kutta methods.
 *
 * For the fast states:
 * Based on the Butcher tableau the following nonlinear residuals will be calculated:
 *   y[j] = yOld + h*sum(A[i,j]*k[j], j=1..act_stage)
 *   res_const[j] = yOld + h*sum(A[i,j]*k[j], j=1..act_stage-1)
 * res = res_const[j] - y[j] + f(tOld + c[i]*h, y[j])
 * When calling, the following is already calculated:
 *  sData->timeValue = tOld + c[i]*h
 *  res_const = yOld + h*sum(A[i,j]*k[j], j=1..act_stage-1)
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_DIRK_MR(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODEF *gbfData = (DATA_GBODEF *)userData->solverData;
  assertStreamPrint(threadData, gbfData != NULL, "residual_DIRK_MR: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  const int nFastStates = gbfData->nFastStates;
  const int nStages = gbfData->tableau->nStages;
  const int stage_  = gbfData->act_stage;
  const modelica_real fac = gbfData->stepSize * gbfData->tableau->A[stage_ * nStages + stage_];

  // Set fast states
  // ph: are slow states interpolated and set correctly?
  for (ii = 0; ii < nFastStates; ii++) {
    assertStreamPrint(threadData, !isnan(xloc[ii]), "residual_DIRK_MR: xloc is NAN");
    i = gbfData->fastStatesIdx[ii];
    sData->realVars[i] = xloc[ii];
  }
  // Evaluate right hand side of ODE
  gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE));

  // Evaluate residuals
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbfData->fastStatesIdx[ii];
    assertStreamPrint(threadData, !isnan(fODE[i]), "residual_DIRK_MR: fODE is NAN");
    res[ii] = gbfData->res_const[i] - xloc[ii] + fac * fODE[i];
  }
}

/**
 * @brief Evaluate residual for non-linear system of implicit Runge-Kutta method.
 *
 * Based on the Butcher tableau the following nonlinear residuals will be calculated:
 *
 * for i=1 .. stage
 *  res[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], j=1..stage))
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_IRK(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag) {

  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODE *gbData = (DATA_GBODE *)userData->solverData;
  assertStreamPrint(threadData, gbData != NULL, "residual_IRK: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;

  int i;
  const int nStages = gbData->tableau->nStages;
  const int nStates = data->modelData->nStates;
  int stage, stage_;

  for (i = 0; i < nStages*nStates; i++)
    assertStreamPrint(threadData, !isnan(xloc[i]), "residual_IRK: xloc is NAN");

  // Update the derivatives for current estimate of the states
  for (stage_ = 0; stage_ < nStages; stage_++) {
    /* Evaluate ODE for each stage_ */
    if (!gbData->tableau->isKLeftAvailable || stage_ > 0) {
      sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;
      memcpy(sData->realVars, xloc + stage_ * nStates, nStates*sizeof(double));
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      for (i = 0; i < nStates; i++)
        assertStreamPrint(threadData, !isnan(fODE[i]), "residual_IRK: fODE is NAN");
      memcpy(gbData->k + stage_ * nStates, fODE, nStates*sizeof(double));
    } else {
      // memcpy(sData->realVars, gbData->yLeft, nStates*sizeof(double));
      memcpy(gbData->k + stage_ * nStates, gbData->kLeft, nStates*sizeof(double));
    }
  }

  // Calculate residuum for the full implicit RK method based on stages and A matrix
  for (stage = 0; stage < nStages; stage++) {
    for (i = 0; i < nStates; i++) {
      res[stage * nStates + i] = gbData->yOld[i] - xloc[stage * nStates + i];
      for (stage_ = 0; stage_ < nStages; stage_++) {
        res[stage * nStates + i] += gbData->stepSize * gbData->tableau->A[stage * nStages + stage_] * (gbData->k + stage_*nStates)[i];
      }
    }
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    infoStreamPrint(OMC_LOG_GBODE_NLS, 1, "NLS - residual:");
    for (stage = 0; stage < nStages; stage++) {
      printVector_gb(OMC_LOG_GBODE_NLS, "r", res + stage*nStates, nStates, gbData->time + gbData->tableau->c[stage] * gbData->stepSize);
    }
    messageClose(OMC_LOG_GBODE_NLS);
  }
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param data              Pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData            Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_SR_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;

  int i;
  const int nStages = gbData->tableau->nStages;
  const int stage = gbData->act_stage;
  modelica_real fac;

  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  /* Evaluate column of Jacobian ODE */
  memcpy(jacobian_ODE->seedVars, jacobian->seedVars, sizeof(modelica_real)*jacobian->sizeCols);
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  if (gbData->type == MS_TYPE_IMPLICIT) {
    fac = gbData->stepSize * gbData->tableau->b[nStages-1];
  } else {
    fac = gbData->stepSize * gbData->tableau->A[stage * nStages + stage];
  }

  for (i = 0; i < jacobian->sizeCols; i++) {
    assertStreamPrint(threadData, !isnan(jacobian_ODE->resultVars[i]), "jacobian_SR_column: jacobian_ODE is NAN");
    jacobian->resultVars[i] = fac * jacobian_ODE->resultVars[i] - jacobian->seedVars[i];
  }

  return 0;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param data              Pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData            Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_MR_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  /* define callback to column function of Jacobian ODE */
  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  int i, ii;
  const int nStages = gbfData->tableau->nStages;
  const int nFastStates = gbData->nFastStates;
  const int stage_ = gbfData->act_stage;
  modelica_real fac;

  for (i = 0; i < jacobian_ODE->sizeCols; i++) {
    jacobian_ODE->seedVars[i] = 0;
  }

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbData->fastStatesIdx[ii];
    if (jacobian->seedVars[ii])
      jacobian_ODE->seedVars[i] = 1;
  }

  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  if (gbfData->type == MS_TYPE_IMPLICIT) {
    fac = gbfData->stepSize * gbfData->tableau->b[nStages-1];
  } else {
    fac = gbfData->stepSize * gbfData->tableau->A[stage_ * nStages + stage_];
  }

  for (ii = 0; ii < nFastStates; ii++) {
    i = gbData->fastStatesIdx[ii];
    assertStreamPrint(threadData, !isnan(jacobian_ODE->resultVars[i]), "jacobian_MR_column: jacobian_ODE is NAN");
    jacobian->resultVars[ii] = fac * jacobian_ODE->resultVars[i] - jacobian->seedVars[ii];
  }

  return 0;
}

/**
 * @brief Evaluate column of IRK Jacobian.
 *
 * @param data              Pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData            Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_IRK_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  const double* xloc = gbData->nlsData->nlsx;

  int i;
  int stage, stage_;
  const int nStages = gbData->tableau->nStages;
  const int nStates = data->modelData->nStates;

  /* Evaluate column of Jacobian ODE */
  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  // and find out which stage is active; different stages have different colors
  // reset jacobian_ODE->seedVars
  for (i = 0; i < jacobian_ODE->sizeCols; i++) {
    jacobian_ODE->seedVars[i] = 0;
  }

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (i = 0, stage_ = 0; i < jacobian->sizeCols; i++) {
    if (jacobian->seedVars[i]) {
      stage_ = i; /* store last index, for determining the active stage */
      jacobian_ODE->seedVars[i%jacobian_ODE->sizeCols] = 1;
    }
  }

  // Determine active stage
  stage_ = stage_/jacobian_ODE->sizeCols;

  // update timeValue and unknown vector based on the active column "stage_"
  sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;
  memcpy(sData->realVars, &(xloc[stage_*nStates]), nStates*sizeof(double));

  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);
  for (i = 0; i < nStates; i++)
    assertStreamPrint(threadData, !isnan(jacobian_ODE->resultVars[i]), "jacobian_SR_column: jacobian_ODE is NAN");

  /* Update resultVars array for corresponding jacobian->seedVars*/
  for (stage = 0; stage < nStages; stage++) {
    for (i = 0; i < nStates; i++) {
      jacobian->resultVars[stage * nStates + i] = gbData->stepSize * gbData->tableau->A[stage * nStages + stage_]  * jacobian_ODE->resultVars[i] - jacobian->seedVars[stage * nStates + i];
    }
  }

  return 0;
}

void mapSparsePatterns(SPARSE_PATTERN *I_plus_J_pat,
                       JACOBIAN *jacobian_ODE,
                       GB_INTERNAL_NLS_DATA *nls,
                       int size)
{
  for (int col = 0; col < size; col++)
  {
    for (int nz = I_plus_J_pat->leadindex[col]; nz < I_plus_J_pat->leadindex[col + 1]; nz++)
    {
      int row = I_plus_J_pat->index[nz];
      if (row == col)
      {
        nls->nls_diag_indices[col] = nz;
        break;
      }
  }
  }

  SPARSE_PATTERN *pat_ode = jacobian_ODE->sparsePattern;

  for (int col = 0; col < size; col++)
  {
    int ode_start = pat_ode->leadindex[col];
    int ode_end   = pat_ode->leadindex[col + 1];
    int nls_start = I_plus_J_pat->leadindex[col];
    int nls_end   = I_plus_J_pat->leadindex[col + 1];

    int ptr_ode = ode_start;
    int ptr_nls = nls_start;

    while (ptr_ode < ode_end && ptr_nls < nls_end)
    {
      int row_ode = pat_ode->index[ptr_ode];
      int row_nls = I_plus_J_pat->index[ptr_nls];

      if (row_ode == row_nls)
      {
        nls->ode_to_nls[ptr_ode++] = ptr_nls++;
      }
      else
      {
        ptr_nls++;
      }
    }
  }
}

/**
 * @brief Assemble (E)SDIRK stage Jacobian for the nonlinear system.
 *
 * Scales the ODE Jacobian by `h * gamma`, maps it into the NLS Jacobian buffer,
 * and subtracts the identity on the diagonal:  J = -I + h*a_ii * dfdx.
 *
 * @param data        Runtime data (unused)
 * @param threadData  Thread data
 * @param gbData      GBODE integrator data (step size, tableau, stage)
 * @param nls         Internal NLS data with index mapping
 * @param jac_ode     ODE Jacobian (structures)
 * @param jac_buf_ode ODE Jacobian values
 * @param jac_buf_nls Output buffer for NLS Jacobian
 * @return 0 on success
 */
int jacobian_SR_DIRK_assemble(DATA *data,
                              threadData_t *threadData,
                              DATA_GBODE* gbData,
                              GB_INTERNAL_NLS_DATA *nls,
                              JACOBIAN *jac_ode,
                              double *jac_buf_ode,
                              double *jac_buf_nls)
{
  SPARSE_PATTERN *ode_jac_sp = jac_ode->sparsePattern;

  memset(jac_buf_nls, 0, nls->sparsePattern->numberOfNonZeros * sizeof(double));

  const double fac = gbData->stepSize * gbData->tableau->A[gbData->act_stage * gbData->tableau->nStages + gbData->act_stage];

  for (int nz = 0; nz < ode_jac_sp->numberOfNonZeros; nz++)
  {
    int idx = nls->ode_to_nls[nz];
    jac_buf_nls[idx] = fac * jac_buf_ode[nz];
  }

  for (int d = 0; d < jac_ode->sizeRows; d++)
  {
    jac_buf_nls[nls->nls_diag_indices[d]] -= 1.0;
  }

  return 0;
}

/**
 * @brief Assemble Jacobian for the nonlinear system.
 *
 * Jacobian has form gamma / h * I - J_f
 *
 * @param data        Runtime data (unused)
 * @param threadData  Thread data
 * @param gbData      GBODE integrator data (step size, tableau, stage)
 * @param nls         Internal NLS data with index mapping
 * @param jac_ode     ODE Jacobian (structures)
 * @param jac_buf_ode ODE Jacobian values
 * @param jac_buf_nls Output buffer for NLS Jacobian
 * @return 0 on success
 */
int jacobian_SR_real_assemble(DATA *data,
                              threadData_t *threadData,
                              DATA_GBODE* gbData,
                              GB_INTERNAL_NLS_DATA *nls,
                              double gamma,
                              JACOBIAN *jac_ode,
                              double *jac_buf_ode,
                              double *jac_buf_nls)
{
  SPARSE_PATTERN *ode_jac_sp = jac_ode->sparsePattern;

  memset(jac_buf_nls, 0, nls->sparsePattern->numberOfNonZeros * sizeof(double));

  const double weight = gamma / gbData->stepSize;

  for (int nz = 0; nz < ode_jac_sp->numberOfNonZeros; nz++)
  {
    int idx = nls->ode_to_nls[nz];
    jac_buf_nls[idx] = -jac_buf_ode[nz];
  }

  for (int d = 0; d < jac_ode->sizeRows; d++)
  {
    jac_buf_nls[nls->nls_diag_indices[d]] += weight;
  }

  return 0;
}

/**
 * @brief Assemble complex Jacobian for the nonlinear system.
 *
 * Jacobian has form (alpha + i * beta) / h * I - J_f
 *
 * @param data        Runtime data (unused)
 * @param threadData  Thread data
 * @param gbData      GBODE integrator data (step size, tableau, stage)
 * @param nls         Internal NLS data with index mapping
 * @param alpha       Real part of complex weight
 * @param beta        Imaginary part of complex weight
 * @param jac_ode     ODE Jacobian (structures)
 * @param jac_buf_ode ODE Jacobian values
 * @param jac_buf_nls Output buffer for NLS Jacobian
 * @return 0 on success
 */
int jacobian_SR_cmplx_assemble(DATA *data,
                               threadData_t *threadData,
                               DATA_GBODE* gbData,
                               GB_INTERNAL_NLS_DATA *nls,
                               double alpha,
                               double beta,
                               JACOBIAN *jac_ode,
                               double *jac_buf_ode,
                               double *jac_buf_nls)
{
  SPARSE_PATTERN *ode_jac_sp = jac_ode->sparsePattern;

  memset(jac_buf_nls, 0, 2 * nls->sparsePattern->numberOfNonZeros * sizeof(double));

  const double weight_real = alpha / gbData->stepSize;
  const double weight_imag = beta / gbData->stepSize;

  for (int nz = 0; nz < ode_jac_sp->numberOfNonZeros; nz++)
  {
    int idx = nls->ode_to_nls[nz];
    jac_buf_nls[2 * idx] = -jac_buf_ode[nz];
  }

  for (int d = 0; d < jac_ode->sizeRows; d++)
  {
    jac_buf_nls[2 * nls->nls_diag_indices[d]] += weight_real;
    jac_buf_nls[2 * nls->nls_diag_indices[d] + 1] += weight_imag;
  }

  return 0;
}


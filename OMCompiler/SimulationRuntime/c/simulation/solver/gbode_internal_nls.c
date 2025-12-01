/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Open Source Modelica Consortium (OSMC),
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

#include <klu.h>

#include "gbode_main.h"
#include "gbode_internal_nls.h"

// TODO: How to choose TOL for Richardson???
// TODO: Calibrate safety factor for internal tolerances
// TODO: update guess routines (stage value predictors for (E)SDIRK)
// TODO: update embedded for FIRK with real eigenvalue: we have the contractive error, but
//       it looks like its only useful for defect-based errors in collocation methods

/* some constants for less verbose BLAS calls */
static const double DBL_ZERO = 0.0;
static const double DBL_ONE = 1.0;
static const double DBL_MINUS_ONE = -1.0;
static const int INT_ONE = 1;
static const int INT_TWO = 2;
static const char CHAR_TRANS = 'T';
static const char CHAR_NO_TRANS = 'N';

/* y := a * x + y */
extern void daxpy_(const int *n,
                   const double *alpha,
                   const double *x, const int *incX,
                   double *y, const int *incY);

/* C := alpha * A * B + beta * C */
extern void dgemm_(const char *transA,
                   const char *transB,
                   const int *m,
                   const int *n,
                   const int *k,
                   const double *alpha, const double *A, const int *ldA,
                   const double *B, const int *ldB,
                   const double *beta, double *C, const int *ldC
);

/* x := alpha * x */
extern void dscal_(const int *n,
                   const double *alpha,
                   double *x, const int *incX
);

/* y[incY * i] := x[incX * i] for i = 0 ... n - 1 */
extern void dcopy_(const int *n,
                   const double *x, const int *incX,
                   double *y, const int *incY
);

typedef struct KLUInternals
{
  klu_common common;
  klu_symbolic *symbolic;
  klu_numeric *numeric;
} KLUInternals;

typedef struct GB_INTERNAL_NLS_DATA
{
  NLS_USERDATA *nls_user_data;       // pointer to data, gbode data, etc.
  KLUInternals *klu_internals_real;  // internal data structures for real systems with klu linear solver (might change for ptr + enum, e.g. to have LAPACK)
  KLUInternals *klu_internals_cmplx; // internal data structures for complex systems with klu linear solver (might change for ptr + enum, e.g. to have LAPACK)
  SPARSE_PATTERN *sparsePattern;     // sparse pattern struct(I + J) (for DIRK == NLS sparse pattern, else created)
  modelica_boolean createdPattern;   // true if sparse pattern was created or false if taken from the NLS
  double *jacobian_callback;         // buffer for continuous ODE Jacobian (size = nnz(J_f))
  int *ode_to_nls;                   // mapping ODE Jacobian nnz -> NLS Jacobian nnz
  int *nls_diag_indices;             // all diagonal nz indices of NLS Jacobian (size = cols)
  double *scal;                      // scaling vector for termination of Newton loop
  double *etas;                      // Newton contraction factors for each NLS stage (size == number of stages)
  Tolerances tol_integrator;         // Integrator / user provided tolerances
  Tolerances tol_scaled;             // scaled Integrator tolerances
  double fnewt;                      // Newton tolerance: if eta * norm(dx) <= fnewt -> convergence
  double theta_keep;                 // if norm(dx_k) / norm(dx_{k-1}) = theta_{k} < theta_keep -> keep old jacobian_callback
  modelica_boolean call_jac;         // call jacobian in the next call to NLS solve
  int retry;                         // retry count for current Newton iteration
  double theta_divergence;           // if norm(dx_k) / norm(dx_{k-1}) = theta_{k} > theta_divergence (<= 1.0) -> divergence of Newton
  int max_newton_it;                 // maximum number of Newton iterations
  int size;                          // size of the system
  BUTCHER_TABLEAU *tabl;             // butcher tableau of the method
  modelica_boolean use_t_transform;  // use T transform to solve the system (false for (E)SDIRK, true for FIRK)
  double **real_nls_jacs;            // real NLS jacobians
  double **cmplx_nls_jacs;           // complex NLS jacobians (packed as real, imag - memory layout is struct{double real, double imag}[])
  double **real_nls_res;             // real NLS residuum
  double **cmplx_nls_res;            // complex NLS residuum (packed as real, imag - memory layout is struct{double real, double imag}[])
  double *Z;                         // update variables Z = Y(t_ij) - Y0 for T-transformation (coupled space)
  double *W;                         // update variables W = (T^{-1} otimes I) Z for T-transformation (decoupled space)
  double *work;                      // some work memory for the T transformation (size: transform->size * x.size)
} GB_INTERNAL_NLS_DATA;

/**
 * @brief Map ODE sparsity pattern indices into the enlarged (I+J) pattern.
 *
 * Locates diagonal entries of (I + J) and records their positions in `nls_diag_indices`.
 * Builds a mapping `ode_to_nls` from ODE Jacobian nonzero positions to the corresponding
 * positions in the (I + J) pattern column-wise.
 */
static void mapSparsePatterns(SPARSE_PATTERN *I_plus_J_pat,
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
 * @brief Build a new CSC sparsity pattern containing base_pat plus identity: struct(I + J).
 *
 * @param base_pat  Input CSC pattern
 * @param size      Matrix dimension (cols / rows)
 *
 * @note This should be somewhere in GBODE already!!
 */
/**
 * @brief Build a new CSC sparsity pattern containing base_pat plus identity: struct(I + J).
 *
 * @param base_pat  Input CSC pattern
 * @param size      Matrix dimension (cols / rows)
 *
 * @note This should be somewhere in GBODE already!!
 */
static SPARSE_PATTERN* buildSparsePatternWithDiagonal(const SPARSE_PATTERN *base_pat, int size)
{
  int diag_cnt = 0;

  /* Count existing diagonal entries */
  for (int col = 0; col < size; col++)
  {
    for (int nz = base_pat->leadindex[col]; nz < base_pat->leadindex[col + 1]; nz++)
    {
      if (base_pat->index[nz] == col)
      {
        diag_cnt++;
      }
    }
  }

  int missing_diags = size - diag_cnt;
  int total_nnz = base_pat->numberOfNonZeros + missing_diags;

  // accumulate pattern = struct(I + J), where J is base_pat
  SPARSE_PATTERN *acc_pat = allocSparsePattern(size, total_nnz, size);

  int acc_nz = 0;
  acc_pat->leadindex[0] = 0;

  for (int col = 0; col < size; col++) {

    modelica_boolean diag_present = FALSE;

    for (int ode_nz = base_pat->leadindex[col]; ode_nz < base_pat->leadindex[col + 1]; ode_nz++)
    {
      int row = base_pat->index[ode_nz];

      if (!diag_present && row > col)
      {
        acc_pat->index[acc_nz++] = col;
        diag_present = TRUE;
      }

      if (row == col)
      {
        diag_present = TRUE;
      }

      acc_pat->index[acc_nz++] = row;
    }

    if (!diag_present)
    {
      acc_pat->index[acc_nz++] = col;
    }

    acc_pat->leadindex[col + 1] = acc_nz;
  }

  acc_pat->numberOfNonZeros = acc_nz;
  acc_pat->sizeofIndex = acc_nz;

  return acc_pat;
}

/**
 * @brief Assemble (E)SDIRK stage Jacobian for the nonlinear system.
 *
 * Scales the ODE Jacobian by `h * gamma`, maps it into the NLS Jacobian buffer,
 * and subtracts the identity on the diagonal:  J = -I + h*a_ii * dfdx.
 *
 * @param[in]  data         Runtime data (unused)
 * @param[in]  threadData   Thread data
 * @param[in]  gbData       GBODE integrator data
 * @param[in]  nls          Internal NLS data with index mapping
 * @param[in]  jac_ode      ODE Jacobian (structures)
 * @param[in]  jac_buf_ode  ODE Jacobian values (already filled)
 * @param[out] jac_buf_nls  Output buffer for NLS Jacobian
 * @return 0 on success
 */
static int jacobian_SR_DIRK_assemble(DATA *data,
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
 * @param[in]  data         Runtime data (unused)
 * @param[in]  threadData   Thread data
 * @param[in]  gbData       GBODE integrator data
 * @param[in]  nls          Internal NLS data with index mapping
 * @param[in]  jac_ode      ODE Jacobian (structures)
 * @param[in]  jac_buf_ode  ODE Jacobian values
 * @param[out] jac_buf_nls  Output buffer for NLS Jacobian
 * @return 0 on success
 */
static int jacobian_SR_real_assemble(DATA *data,
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
 * @param[in]  data         Runtime data (unused)
 * @param[in]  threadData   Thread data
 * @param[in]  gbData       GBODE integrator data (step size, tableau, stage)
 * @param[in]  nls          Internal NLS data with index mapping
 * @param[in]  alpha        Real part of complex weight
 * @param[in]  beta         Imaginary part of complex weight
 * @param[in]  jac_ode      ODE Jacobian (structures)
 * @param[in]  jac_buf_ode  ODE Jacobian values
 * @param[out] jac_buf_nls  Output buffer for NLS Jacobian
 * @return 0 on success
 */
static int jacobian_SR_cmplx_assemble(DATA *data,
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

  const double inv_step = 1.0 / gbData->stepSize;
  const double weight_real = inv_step * alpha;
  const double weight_imag = inv_step * beta;

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

/** @brief Run symbolic analysis for a CSC matrix using KLU. */
static int gbInternal_KLU_analyze(KLUInternals *internals, int size, int *Ap, int *Ai)
{
  klu_defaults(&internals->common);
  internals->symbolic = klu_analyze(size, Ap, Ai, &internals->common);
  return internals->common.status;
}

/** @brief Perform or update real-valued KLU numeric factorization. */
static int gbInternal_dKLU_factorize(KLUInternals *internals, int size, int *Ap, int *Ai, double *values)
{
  if (internals->numeric)
  {
    klu_refactor(Ap, Ai, values, internals->symbolic, internals->numeric, &internals->common);
  }
  else
  {
    internals->numeric = klu_factor(Ap, Ai, values, internals->symbolic, &internals->common);
  }
  return internals->common.status;
}

/** @brief Solve a real linear system using KLU. */
static int gbInternal_dKLU_solve(KLUInternals *internals, int size, int *Ap, int *Ai, double *rhs)
{
  int nrhs = 1; /* we could solve all of ESDIRK at once this way */
  int ok = klu_solve(internals->symbolic, internals->numeric, size, nrhs, rhs, &internals->common);
  return ok;
}

/** @brief Perform or update complex-valued KLU numeric factorization (values packed as struct {double real, double imag}). */
static int gbInternal_zKLU_factorize(KLUInternals *internals, int size, int *Ap, int *Ai, double *values)
{
  if (internals->numeric)
  {
    klu_z_refactor(Ap, Ai, values, internals->symbolic, internals->numeric, &internals->common);
  }
  else
  {
    internals->numeric = klu_z_factor(Ap, Ai, values, internals->symbolic, &internals->common);
  }
  return internals->common.status;
}

/** @brief Solve a complex linear system using KLU (values packed as struct {double real, double imag}). */
static int gbInternal_zKLU_solve(KLUInternals *internals, int size, int *Ap, int *Ai, double *rhs)
{
  int nrhs = 1;
  int ok = klu_z_solve(internals->symbolic, internals->numeric, size, nrhs, rhs, &internals->common);
  return ok;
}

/** @brief Create scalings for scaled 2-norms: used for Newton convergence and integration acceptance criteria. */
static void createGbScales(GB_INTERNAL_NLS_DATA *nls, double *y1, double *y2)
{
  for (int i = 0; i < nls->size; i++)
  {
    nls->scal[i] = 1. / (nls->tol_scaled.atol * nls->nls_user_data->data->modelData->realVarsData[i].attribute.nominal + fmax(fabs(y1[i]), fabs(y2[i])) * nls->tol_scaled.rtol);
  }
}

/** @brief Compute scaled norm of possible vector stack vec = (v1, v2, ..., v_{stacksize}). */
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

/** @brief Solve one stage of a DIRK method with the internal solve routine. */
static NLS_SOLVER_STATUS gbInternalSolveNls_DIRK(DATA *data,
                                                 threadData_t *threadData,
                                                 NONLINEAR_SYSTEM_DATA* nonlinsys,
                                                 DATA_GBODE* gbData,
                                                 GB_INTERNAL_NLS_DATA *nls)
{
  int size = nonlinsys->size;
  int stage = gbData->act_stage;
  double *x = nonlinsys->nlsx;
  double *x_start = nonlinsys->nlsxOld;              // currently the extrapolated (e.g. dense output / hermite guess)
  double *res = nonlinsys->resValues;

  createGbScales(nls, x, x_start);
  double *scal = nls->scal;

  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=gbData};
  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  const int flag = 1;
  modelica_boolean jac_called = FALSE;

  modelica_boolean is_esdirk = (gbData->tableau->A[0] == 0.0);
  modelica_boolean sdirk_first_stage = (stage == 0 && !is_esdirk);
  modelica_boolean esdirk_first_stage = (stage == 1 && is_esdirk);

  if ((sdirk_first_stage || esdirk_first_stage) && gbData->type == GM_TYPE_DIRK)
  {
    nls->retry = 0;

    if (nls->call_jac)
    {
      /* set values for known last point (simplified Newton) */
      memcpy(data->localData[0]->realVars, gbData->yOld, size * sizeof(double));
      data->localData[0]->timeValue = gbData->time;

      /* callback ODE + callback Jacobian of ODE -> nls_jacobian buffer */
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      /* performance measurement */
      rt_tick(SIM_TIMER_JACOBIAN);
      evalJacobian(data, threadData, jacobian_ODE, NULL, nls->jacobian_callback, FALSE);
      rt_accumulate(SIM_TIMER_JACOBIAN);
      gbData->stats.nCallsJacobian++;

      jac_called = TRUE;
    }

    if (jac_called || gbData->stepSize != gbData->lastStepSize)
    {
      /* fill NLS Jacobian as h * gamma * J_f - I, where J_f is old or newly computed ODE Jacobian nls->nls->jacobian_callback */
      jacobian_SR_DIRK_assemble(data, threadData, gbData, nls, jacobian_ODE, nls->jacobian_callback, nls->real_nls_jacs[0]);

      /* perform factorization */
      gbInternal_dKLU_factorize(nls->klu_internals_real, size, nonlinsys->sparsePattern->leadindex, nonlinsys->sparsePattern->index, nls->real_nls_jacs[0]);
    }
  }

  memcpy(x, x_start, size * sizeof(double));

  /* start DIRK retry loop */
  while (1)
  {
    // norms, convergence rate
    double nrm_delta = 0;
    double nrm_delta_prev = 0;
    double theta = 0;

    modelica_boolean retry_requested = FALSE;

    // Newton iteration count - we start with newt_it = 1, because we need this for the step size selection and conditions below
    for (int newt_it = 1 ;; newt_it++)
    {
      nonlinsys->residualFunc(&resUserData, x, res, &flag);

      gbInternal_dKLU_solve(nls->klu_internals_real, size, nonlinsys->sparsePattern->leadindex, nonlinsys->sparsePattern->index, res);
      daxpy_(&size, &DBL_MINUS_ONE, res, &INT_ONE, x, &INT_ONE);

      nrm_delta_prev = nrm_delta;
      nrm_delta = gbScalesNorm(nls, res, 1);

      if (newt_it > 1)
      {
        theta = nrm_delta / nrm_delta_prev;

        // Newton failed -> divergence
        if (theta >= nls->theta_divergence)
        {
          retry_requested = TRUE;
          break;
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
        retry_requested = TRUE;
        break;
      }
    }

    /* retry_dirk for constant step size */
    if (retry_requested && nls->retry < 5 && gbData->ctrl_method == GB_CTRL_CNST)
    {
      /* try fresh Jacobian at start point */
      nls->retry++;

      memcpy(x, x_start, size * sizeof(double));

      memcpy(data->localData[0]->realVars, x, size * sizeof(double));
      data->localData[0]->timeValue = gbData->time + gbData->tableau->c[stage] * gbData->stepSize;

      /* callback ODE + callback Jacobian of ODE -> nls_jacobian buffer */
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

      /* performance measurement */
      rt_tick(SIM_TIMER_JACOBIAN);
      evalJacobian(data, threadData, jacobian_ODE, NULL, nls->jacobian_callback, FALSE);
      rt_accumulate(SIM_TIMER_JACOBIAN);
      gbData->stats.nCallsJacobian++;

      jacobian_SR_DIRK_assemble(data, threadData, gbData, nls, jacobian_ODE,
                                nls->jacobian_callback, nls->real_nls_jacs[0]);

      gbInternal_dKLU_factorize(nls->klu_internals_real, size,
                                nonlinsys->sparsePattern->leadindex,
                                nonlinsys->sparsePattern->index,
                                nls->real_nls_jacs[0]);

      continue;
    }

    /* final failure */
    break;
  }

  nls->call_jac = TRUE;
  return NLS_FAILED;
}

/** @brief Compute (T otimes I) * v for block vectors (applies T to block_count blocks of size block_size). */
static void dense_kron_id_vec(int block_count,
                              int block_size,
                              const double *T,
                              const double *v,
                              double *out)
{
  dgemm_(
    &CHAR_NO_TRANS, &CHAR_NO_TRANS,
    &block_size, &block_count, &block_count,
    &DBL_ONE,
    v, &block_size,
    T, &block_count,
    &DBL_ZERO,
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
static void scaled_blockdiag_matvec(T_TRANSFORM *transform,
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
    daxpy_(&block_size, &gammas_scaled[0], &v[real_eig * block_size], &INT_ONE, &out[real_eig * block_size], &INT_ONE);
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
    daxpy_(&block_size, &a, v0, &INT_ONE, out0, &INT_ONE);  // out0 += a*v0
    daxpy_(&block_size, &mb, v1, &INT_ONE, out0, &INT_ONE); // out0 -= b*v1

    // out1 = a*v1 + b*v0
    daxpy_(&block_size, &a, v1, &INT_ONE, out1, &INT_ONE);  // out1 += a*v1
    daxpy_(&block_size, &b, v0, &INT_ONE, out1, &INT_ONE);  // out1 += b*v0

    offset += 2 * block_size;
  }
}

/** @brief Solve entire NLS of FIRK with possibly singular Runge-Kutta matrix
 *         via the T-transformation (decoupled space).
 *
 * After convergence the solutions are written into nonlinsys->x and the stage updates are
 * written into gbData->k.
*/
static NLS_SOLVER_STATUS gbInternalSolveNls_T_Transform(DATA *data,
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
  JACOBIAN *jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  T_TRANSFORM *transform = nls->tabl->t_transform;

  modelica_boolean jac_called = FALSE;

  if (nls->call_jac || transform->firstRowZero)
  {
    /* set values for known last point (simplified Newton) */
    memcpy(data->localData[0]->realVars, gbData->yOld, size * sizeof(double));
    data->localData[0]->timeValue = gbData->time;

    /* callback ODE + callback Jacobian of ODE -> nls_jacobian buffer */
    gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

    if (transform->firstRowZero)
    {
      // save explicit stage (e.g. Lobatto IIIA)
      memcpy(gbData->k, &data->localData[0]->realVars[size], size * sizeof(double));
    }

    if (nls->call_jac)
    {
      /* performance measurement */
      rt_tick(SIM_TIMER_JACOBIAN);
      evalJacobian(data, threadData, jacobian_ODE, NULL, nls->jacobian_callback, FALSE);
      rt_accumulate(SIM_TIMER_JACOBIAN);
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
  }

  // we solve for Z = X(t_ij) - X0 or W = (T^{-1} otimes I) * Z, then get K back via K = 1/h * A^{-1} * Z
  double *x0 = gbData->yOld;

  // set guess Z[j] = X_start[j] - X_0
  for (int j = 0; j < transform->size; j++)
  {
    memcpy(&nls->Z[j * size], &x_start[j * size], size * sizeof(double));
    daxpy_(&size, &DBL_MINUS_ONE, x0, &INT_ONE, &nls->Z[j * size], &INT_ONE);
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
      daxpy_(&size, &DBL_ONE, &nls->Z[j * size], &INT_ONE, data->localData[0]->realVars, &INT_ONE);
      data->localData[0]->timeValue = gbData->time + gbData->tableau->c[j + (int)transform->firstRowZero] * gbData->stepSize;
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      memcpy(&nls->work[j * size], &data->localData[0]->realVars[size], size * sizeof(double));
    }

    // rhs[j] = (T^{-1} otimes I) * F((T otimes I) * W)
    dense_kron_id_vec(transform->size, size, transform->T_inv, nls->work, flat_res);

    // rhs[j] += -1 / h * (Lambda otimes I) * W
    scaled_blockdiag_matvec(transform, size, minvh, nls->W, flat_res);

    // add Phi = T^{-1} * A_part^{-1} * a{r, 1} * K_1 if first stage is explicit, else skip (we computed nls->phi = T^{-1} * A_part^{-1} * a{r, 1})
    // where r are all rows that belong to A_part
    if (transform->firstRowZero)
    {
      for (int j = 0; j < transform->size; j++)
      {
        daxpy_(&size, &transform->phi[j], gbData->k, &INT_ONE, &flat_res[j * size], &INT_ONE);
      }
    }

    // prepare complex linear system RHS's
    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      dcopy_(&size, &flat_res[(2 * sys_cmplx + transform->nRealEigenvalues) * size],
             &INT_ONE, &nls->cmplx_nls_res[sys_cmplx][0], &INT_TWO);     // .real
      dcopy_(&size, &flat_res[(2 * sys_cmplx + transform->nRealEigenvalues + 1) * size],
             &INT_ONE, &nls->cmplx_nls_res[sys_cmplx][1], &INT_TWO);     // .imag
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
      dcopy_(&size, &nls->cmplx_nls_res[sys_cmplx][0], &INT_TWO,
             &flat_res[(2 * sys_cmplx + transform->nRealEigenvalues) * size], &INT_ONE);     // r1
      dcopy_(&size, &nls->cmplx_nls_res[sys_cmplx][1], &INT_TWO,
             &flat_res[(2 * sys_cmplx + transform->nRealEigenvalues + 1) * size], &INT_ONE); // r2
    }

    // Newton step (we must do W += dW)
    daxpy_(&w_size, &DBL_ONE, flat_res, &INT_ONE, nls->W, &INT_ONE);

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
        daxpy_(&size, &DBL_ONE, x0, &INT_ONE, &x[j * size + offset], &INT_ONE);
      }

      // recompute weights K from Z via K = 1 / h * (A_part^{-1} otimes I) * Z + rho * k_1 if k_1 explicit else 0 (rho := -A_part^{-1} * A_{r, 1})
      // where r are all rows that belong to A_part
      dense_kron_id_vec(transform->size, size, transform->A_part_inv, nls->Z, &gbData->k[offset]);
      dscal_(&w_size, &invh, &gbData->k[offset], &INT_ONE);

      if (transform->firstRowZero)
      {
        // add k[j] += rho[j] * k_1 or k[j] -= (-A_part^{-1} * A_{r, 1} * k_1)[j] * k_1
        for (int j = 0; j < transform->size; j++)
        {
          daxpy_(&size, &transform->rho[j], gbData->k, &INT_ONE, &gbData->k[offset + j * size], &INT_ONE);
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
        dgemm_(&CHAR_NO_TRANS, &CHAR_TRANS,
               &size, &INT_ONE, &s_minus1,
               &gbData->stepSize,
               gbData->k, &size,
               &gbData->tableau->A[s_minus1 * nls->tabl->nStages], &INT_ONE,
               &DBL_ONE,
               &x[size * s_minus1], &size);

        memcpy(data->localData[0]->realVars, &x[size * s_minus1], size * sizeof(double));
        data->localData[0]->timeValue = gbData->time + gbData->stepSize * nls->tabl->c[s_minus1];
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

/* Allocate the internal memory + do symbolic analysis. */
void *gbInternalNlsAllocate(int size,
                            NLS_USERDATA* userData,
                            modelica_boolean attemptRetry,
                            modelica_boolean isPatternAvailable)
{
  DATA_GBODE *gbData = (DATA_GBODE *)userData->solverData;
  BUTCHER_TABLEAU *tabl = gbData->tableau;
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
    nls->createdPattern = TRUE;
  }
  else
  {
    nls->sparsePattern = userData->nlsData->sparsePattern;
    nls->createdPattern = FALSE;
  }

  // create ODE Jac -> NLS Jacobian mapping
  mapSparsePatterns(nls->sparsePattern, jacobian_ODE, nls, jacobian_ODE->sizeRows);

  nls->scal = (double *) malloc(jacobian_ODE->sizeRows * sizeof(double));
  nls->etas = (double *) malloc(tabl->nStages * sizeof(double));
  for (int i = 0; i < tabl->nStages; i++)
  {
    nls->etas[i] = 1e300;
  }

  nls->tol_integrator = (Tolerances){ userData->data->simulationInfo->tolerance, userData->data->simulationInfo->tolerance };


  // We transform the error such that the error term err = || v || = sqrt(1/n * sum (v[i] / scal[i])^2) is scaled with same measure
  // As we later have v = sum (b - bt) * k = min of local error of b and bt -> scale ATOL and RTOL w.r.t. (min(b, bt) + 1) / (b + 1)

  if (tabl->richardson)
  {
    nls->tol_scaled.rtol = nls->tol_integrator.rtol;
    nls->tol_scaled.atol = nls->tol_integrator.atol;
    nls->fnewt = fmax(10 * DBL_EPSILON / nls->tol_scaled.rtol, 3e-2);
  }
  else
  {
    // scale error measure to embedded method
    const double safety = 0.2; /* TODO: TBD: which coefficient should be used here, given as tableau specific tableau->fac? See "A comparison of Rosenbrock and ESDIRK methods
                                             combined with iterative solvers for unsteady compressible flows" for a calibration technique */
    double quot = nls->tol_integrator.atol / nls->tol_integrator.rtol;
    double order_quot = ((double)tabl->error_order + 1.0) / ((double)tabl->order_b + 1.0);
    double rtol_pred = safety * pow(nls->tol_integrator.rtol, order_quot);
    double atol_pred = quot * rtol_pred;
    nls->tol_scaled.rtol = fmax(nls->tol_integrator.rtol, rtol_pred);
    nls->tol_scaled.atol = fmax(nls->tol_integrator.atol, atol_pred);
    nls->fnewt = fmax(10 * DBL_EPSILON / nls->tol_scaled.rtol, fmin(3e-2, pow(nls->tol_scaled.rtol, 1.0 / order_quot - 1.0)));
  }

  // add a history of thetas_last + #newt iterations to detect nearly linear systems, similar to err controller
  nls->theta_keep = pow(10.0, -3.0 + 1.75 * log(1.0 + (double)jacobian_ODE->sparsePattern->maxColors) / log(1.0 + (double)nls->size));
  nls->call_jac = TRUE;
  nls->theta_divergence = 0.99;
  nls->max_newton_it = !trfm ? 5 : 4 + 2 * trfm->size; // = 5 for each (E)SDIRK stage and e.g. 10 for full RadauIIA 3-step

  if (!trfm)
  {
    nls->klu_internals_real = (KLUInternals *) malloc(sizeof(KLUInternals));
    nls->klu_internals_real->numeric = NULL;
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

    // We might be able to remove these redundant analysis parts, as we can use 1 analysis (symbolic) and compute different factorizations.
    for (int sys_real = 0; sys_real < trfm->nRealEigenvalues; sys_real++)
    {
      nls->real_nls_res[sys_real] = (double *) malloc(nls->size * sizeof(double));
      nls->real_nls_jacs[sys_real] = (double *) malloc(nls->sparsePattern->numberOfNonZeros * sizeof(double));
      gbInternal_KLU_analyze(&nls->klu_internals_real[sys_real], nls->size, nls->sparsePattern->leadindex, nls->sparsePattern->index);
      nls->klu_internals_real[sys_real].numeric = NULL;
    }
    for (int sys_cmplx = 0; sys_cmplx < trfm->nComplexEigenpairs; sys_cmplx++)
    {
      nls->cmplx_nls_res[sys_cmplx] = (double *) malloc(2 * nls->size * sizeof(double));
      nls->cmplx_nls_jacs[sys_cmplx] = (double *) malloc(2 * nls->sparsePattern->numberOfNonZeros * sizeof(double));
      gbInternal_KLU_analyze(&nls->klu_internals_cmplx[sys_cmplx], nls->size, nls->sparsePattern->leadindex, nls->sparsePattern->index);
      nls->klu_internals_cmplx[sys_cmplx].numeric = NULL;
    }

    // iterate
    nls->Z = (double *) malloc(nls->size * trfm->size * sizeof(double));
    nls->W = (double *) malloc(nls->size * trfm->size * sizeof(double));

    // auxiliary memory
    nls->work = (double *) malloc(nls->size * trfm->size * sizeof(double));
  }

  return (void *) nls;
}

/* Free the internal memory. */
void gbInternalNlsFree(void *nls_ptr)
{
  GB_INTERNAL_NLS_DATA *nls = (GB_INTERNAL_NLS_DATA *) nls_ptr;
  free(nls->jacobian_callback);
  free(nls->ode_to_nls);
  free(nls->nls_diag_indices);
  free(nls->scal);
  free(nls->etas);

  if (nls->createdPattern)
  {
    freeSparsePattern(nls->sparsePattern);
    free(nls->sparsePattern);
  }

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

/* Get internal, scaled tolerances. */
Tolerances *gbInternalNlsGetScaledTolerances(void *nls_ptr)
{
  return &((GB_INTERNAL_NLS_DATA *) nls_ptr)->tol_scaled;
}

/* Entry point for `internal` solve routine: DIRK or FIRK */
NLS_SOLVER_STATUS gbInternalSolveNls(DATA *data,
                                     threadData_t *threadData,
                                     NONLINEAR_SYSTEM_DATA* nonlinsys,
                                     DATA_GBODE* gbData,
                                     void *nls_ptr)
{
  GB_INTERNAL_NLS_DATA *nls = (GB_INTERNAL_NLS_DATA *) nls_ptr;

  if (nls->use_t_transform)
  {
    return gbInternalSolveNls_T_Transform(data, threadData, nonlinsys, gbData, nls);
  }
  else
  {
    return gbInternalSolveNls_DIRK(data, threadData, nonlinsys, gbData, nls);
  }
}

/**
 * Contractive error estimate for stiff problems. (stiffness filter)
 *
 * Its unclear if this is what is really needed see e.g. `https://sperezr.webs.ull.es/investigacion/estimadores-9-art.pdf`
 * as they inspect similar to Hairer (ODE II) the defect of the collocation polynomial at t = 0 (which is inherently unstable).
 * I am not sure if this inversion (gamma / h * I - J)^{-1} * (gamma * sum (b - bt) * k) is beneficial in general,
 * esp. if the embedded method is not A-stable.
 *
 * However, tested on Gauss5 for the Robertson example at TOL = 1e-10, it worked pretty well compared to the standard error estimate.
 *
 * This might only be useful for defect-based error estimates: err = h * gamma * f(t0, x0) + sum (b - bt) * (k or z). Since that is
 * O(h * gamma * lambda * y0) for h * lambda -> inf, we must contract the term to get -> -1 asympotically. This allows for 1 order
 * higher error estimate, but requires 1 additional RHS call and 1 additional LU solve. TODO: inspect this.
 *
 */
void gbInternalContraction(DATA *data,
                           threadData_t *threadData,
                           NONLINEAR_SYSTEM_DATA *nonlinsys,
                           DATA_GBODE *gbData,
                           double *yt,
                           double *y)
{
  GB_INTERNAL_NLS_DATA *nls = (GB_INTERNAL_NLS_DATA *) (((struct dataSolver *)nonlinsys->solverData)->ordinaryData);
  BUTCHER_TABLEAU *tabl = nls->tabl;

  double factors[MAX_GBODE_FIRK_STAGES];
  int size = nls->size;

  // compute y
  if (tabl->c[tabl->nStages - 1] == 1.0)
  {
    // y := y0 + Z_s (since c_s == 1)
    memcpy(y, &nonlinsys->nlsx[nls->size * (tabl->nStages - 1)], nls->size * sizeof(double));
  }
  else
  {
    // y := y0 + h * sum b_j * k_j
    for (int stage = 0; stage < tabl->nStages; stage++)
    {
      factors[stage] = gbData->stepSize * tabl->b[stage];
    }
    memcpy(y, gbData->yOld, nls->size * sizeof(double));
    dgemm_(&CHAR_NO_TRANS, &CHAR_NO_TRANS,
           &size,
           &INT_ONE,
           &tabl->nStages,
           &DBL_ONE, gbData->k, &size,
           factors, &tabl->nStages,
           &DBL_ONE, y, &size);
  }

  // compute yt
  for (int stage = 0; stage < tabl->nStages; stage++)
  {
    factors[stage] = tabl->t_transform->gamma[0] * (tabl->b[stage] - tabl->bt[stage]);
  }

  // yt := gamma * sum (b_j - bt_j) * k_j
  dgemm_(&CHAR_NO_TRANS, &CHAR_NO_TRANS,
         &size,
         &INT_ONE,
         &tabl->nStages,
         &DBL_ONE, gbData->k, &size,
         factors, &tabl->nStages,
         &DBL_ZERO, yt, &size);

  // yt := (gamma / h * I - J)^{-1} * yt = (gamma / h * I - J)^{-1} * (gamma * sum (b_j - bt_j) * k_j)
  gbInternal_dKLU_solve(&nls->klu_internals_real[0], nls->size, nls->sparsePattern->leadindex,
                        nls->sparsePattern->index, yt);

  // yt := y + yt = y + (gamma / h * I - J)^{-1} * (gamma * sum (b_j - bt_j) * k_j)
  daxpy_(&size, &DBL_ONE, y, &INT_ONE, yt, &INT_ONE);
}

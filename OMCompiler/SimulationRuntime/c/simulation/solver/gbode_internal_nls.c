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
#include "gbode_util.h"
#include "gbode_internal_nls.h"

#include "../options.h"
#include "../arrayIndex.h"

// TODO: Calibrate safety factor for internal tolerances

#define DBL_ABSORPTION (10 * DBL_EPSILON)
#define MAX(a,b) (((a)>(b))?(a):(b))

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

/* y := alpha * A * x + beta * y */
extern void dgemv_(const char *trans,
                   const int *m,
                   const int *n,
                   const double *alpha, const double *A, const int *ldA,
                   const double *x, const int *incX,
                   const double *beta, double *y, const int *incY
);

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
  SPARSE_PATTERN *nlsPattern;        // sparse pattern struct(I + J) (for DIRK == NLS sparse pattern, else created)
  modelica_boolean ownsNlsPattern;   // true if sparse pattern was created or false if taken from the NLS
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
  double *work;                      // some work memory for the T transformation (size: transform->size * x.size) or other stuff, at least 32 * N_STATES bytes

  // stuff for multirate
  modelica_boolean multirate;         // multirate or singlerate system?
  modelica_boolean new_fast_states;   // if the selection changed and we need to update sparse pattern and symbolic factorization - set from NLS routine
  SPARSE_PATTERN *odePatternMR;         // pattern of the ODE / fast states ODE
  modelica_boolean ownsODEPatternMR; // true if sparse pattern was created or false if taken from the NLS
  unsigned int* colorCols_stub;       // contains the coloring for evalJacobian
  unsigned int maxColors_stub;        // Number of colors
} GB_INTERNAL_NLS_DATA;

/**
 * @brief Map ODE sparsity pattern indices into the enlarged (I+J) pattern.
 *
 * Locates diagonal entries of (I + J) and records their positions in `nls_diag_indices`.
 * Builds a mapping `ode_to_nls` from ODE Jacobian nonzero positions to the corresponding
 * positions in the (I + J) pattern column-wise.
 *
 * @param I_plus_J_pat  Sparse pattern of (I + J)
 * @param J_pat         ODE Jacobian structure
 * @param nls           Internal NLS data (nls_diag_indices and ode_to_nls members are filled)
 * @param size          Number of States
 *
 */
static void updateSparsePatternMappings(SPARSE_PATTERN *I_plus_J_pat,
                              SPARSE_PATTERN *J_pat,
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

  for (int col = 0; col < size; col++)
  {
    int ode_start = J_pat->leadindex[col];
    int ode_end   = J_pat->leadindex[col + 1];
    int nls_start = I_plus_J_pat->leadindex[col];
    int nls_end   = I_plus_J_pat->leadindex[col + 1];

    int ptr_ode = ode_start;
    int ptr_nls = nls_start;

    while (ptr_ode < ode_end && ptr_nls < nls_end)
    {
      int row_ode = J_pat->index[ptr_ode];
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
 * @param blueprint Potential Input / Output CSC pattern. Must be allocated with sufficient size. If != NULL it is filled, else new allocation.
 *
 * @note This should be somewhere in GBODE already!!
 */
static SPARSE_PATTERN* buildSparsePatternWithDiagonal(const SPARSE_PATTERN *base_pat, int size, SPARSE_PATTERN *blueprint)
{
  SPARSE_PATTERN *acc_pat;
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
  if (blueprint != NULL)
  {
    // if we have a blueprint, then simply override the entries of the blueprint, we sure that it is allocated with sufficient size though!
    acc_pat = blueprint;
    acc_pat->numberOfNonZeros = total_nnz;
    acc_pat->sizeofIndex = total_nnz;
    acc_pat->maxColors = size;
  }
  else
  {
    // if we dont have a blueprint we allocate a new sparse pattern from scratch
    acc_pat = allocSparsePattern(size, total_nnz, size);
  }

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

static void gbInternal_evalJacobianMR(DATA* data,
                                      threadData_t *threadData,
                                      DATA_GBODE *gbData,
                                      JACOBIAN* fullJac,
                                      GB_INTERNAL_NLS_DATA *nls,
                                      double* smallJac)
{
  const SPARSE_PATTERN* fullSp  = fullJac->sparsePattern;
  const SPARSE_PATTERN* smallSp = nls->odePatternMR;

  unsigned int* fast_idx = gbData->fastStatesIdx;
  unsigned int  size_fast = gbData->nFastStates;

  fullJac->evalSelection = NULL; // TODO: set evalSelection for Jacobian gbData->gbfData->jacobian->evalSelection;

  int color, col, nz;

  for (color = 0; color < nls->maxColors_stub; color++)
  {
    for (col = 0; col < size_fast; col++)
    {
      unsigned int big_col = fast_idx[col];

      if (nls->colorCols_stub[big_col] - 1 == color)
      {
        fullJac->seedVars[big_col] = 1.0;
      }
    }

    fullJac->evalColumn(data, threadData, fullJac, NULL);

    for (col = 0; col < size_fast; col++)
    {
      unsigned int big_col = fast_idx[col];

      if (nls->colorCols_stub[big_col] - 1 == color)
      {
        for (nz = smallSp->leadindex[col]; nz < smallSp->leadindex[col + 1]; nz++)
        {
          unsigned int small_row = smallSp->index[nz];
          unsigned int full_row = fast_idx[small_row];

          smallJac[nz] = fullJac->resultVars[full_row];
        }

        fullJac->seedVars[big_col] = 0.0;
      }
    }
  }

  fullJac->evalSelection = NULL;
}

static void gbInternal_evalNumericalJacobian(DATA *data,
                                             threadData_t *threadData,
                                             DATA_GBODE *gbData,
                                             GB_INTERNAL_NLS_DATA *nls,
                                             JACOBIAN *jacobian_ODE)
{
  const double delta_h = numericalDifferentiationDeltaXsolver;

  const SPARSE_PATTERN *sparsity;
  EVAL_SELECTION *selection = NULL;
  unsigned int *state_map = NULL;

  int size;
  unsigned int max_colors;
  unsigned int *color_cols;
  int full_size = gbData->nStates;

  if (nls->multirate)
  {
    sparsity = nls->odePatternMR;
    state_map = gbData->fastStatesIdx;
    size = gbData->nFastStates;
    selection = gbData->gbfData->evalSelectionFast;
    max_colors = nls->maxColors_stub;
    color_cols = nls->colorCols_stub;
  }
  else
  {
    sparsity = jacobian_ODE->sparsePattern;
    size = gbData->nStates;
    max_colors = sparsity->maxColors;
    color_cols = sparsity->colorCols;
  }

  double *x = data->localData[0]->realVars;
  double *der_x = &data->localData[0]->realVars[full_size];

  // work 0 ... full_size - 1 is used already by the backup data
  double *der_x_ref = &nls->work[full_size];
  double *x_save = &nls->work[2 * full_size];
  double *delta_hh = &nls->work[3 * full_size];

  memcpy(der_x_ref, der_x, full_size * sizeof(double));

  for (unsigned int color = 0; color < max_colors; color++)
  {
    // careful perturbation of the variables (a la DASSL interface)
    for (unsigned int col = 0; col < size; col++)
    {
      unsigned int big_col = state_map ? state_map[col] : col;

      if (color_cols[big_col] - 1 == color)
      {
        // we follow the procedure of the DASSL interface for the selection of perturbation h_i

        // h * f(x)_i
        double delta_hhh = delta_h * der_x_ref[big_col];

        const double nominal = getNominalFromScalarIdx(data->simulationInfo, data->modelData, VAR_KIND_STATE, big_col);

        // scal_raw = ATOL * NOMINAL + RTOL * abs(x_i), we use the real (un-transformed) integrator tolerances though
        double raw_weight = nls->tol_integrator.atol * nominal + nls->tol_integrator.rtol * fabs(x[big_col]);

        // choose h_i := h * max(abs(x_i), h * f(x)_i, ATOL * NOMINAL + RTOL * abs(x_i), 1e-3)
        delta_hh[big_col] = delta_h * fmax(fmax(fmax(fabs(x[big_col]), 1e-3), fabs(delta_hhh)), fabs(raw_weight));
        delta_hh[big_col] = x[big_col] + delta_hh[big_col] - x[big_col];

        if (x[big_col] + delta_hh[big_col] >= getMaxFromScalarIdx(data->simulationInfo, data->modelData, VAR_TYPE_REAL, VAR_KIND_STATE, big_col))
        {
          delta_hh[big_col] *= -1;
        }

        x_save[big_col] = x[big_col];
        x[big_col] += delta_hh[big_col];
        delta_hh[big_col] = 1.0 / delta_hh[big_col];
      }
    }

    // eval f(x + h)
    gbode_fODE(data, threadData, NULL, selection);

    // do forward finite differencing (f(x + h) - f(x)) / h and reset states
    for (unsigned int col = 0; col < size; col++)
    {
      unsigned int big_col = state_map ? state_map[col] : col;

      if (color_cols[big_col] - 1 == color)
      {
        for (unsigned int nz = sparsity->leadindex[col]; nz < sparsity->leadindex[col + 1]; nz++)
        {
          unsigned int small_row = sparsity->index[nz];
          unsigned int big_row   = state_map ? state_map[small_row] : small_row;

          nls->jacobian_callback[nz] = (der_x[big_row] - der_x_ref[big_row]) * delta_hh[big_col];
        }

        x[big_col] = x_save[big_col];
      }
    }
  }
}

/**
 * @brief Calculate ODE Jacobian (numerical or analytic) depending on availability of
 *        analytic Jacobian.
 *
 * Fills the nls->jacobian_callback callback buffer with the ODE Jacobian.
 * It requires the sparsity pattern and a work array of size 3 * #states in nls.
 * This is just a wrapper around evalJacobian to also support numerical ODE Jacobians.
 *
 * @param data        DATA object
 * @param threadData  Thread data
 * @param gbData      GBODE solver data
 * @param nls         Internal strategy data (nls->jacobian_callback will be filled)
 */
static int gbInternal_evalJacobian(DATA *data, threadData_t *threadData, DATA_GBODE *gbData, GB_INTERNAL_NLS_DATA *nls)
{
  int ret = -1;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  rt_tick(SIM_TIMER_JACOBIAN);
  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  if (nls->multirate && jacobian_ODE->availability == JACOBIAN_AVAILABLE)
  {
    gbInternal_evalJacobianMR(data, threadData, gbData, jacobian_ODE, nls, nls->jacobian_callback);
  }
  else if (!nls->multirate && jacobian_ODE->availability == JACOBIAN_AVAILABLE)
  {
    evalJacobian(data, threadData, jacobian_ODE, NULL, nls->jacobian_callback, FALSE);
  }
  else
  {
    gbInternal_evalNumericalJacobian(data, threadData, gbData, nls, jacobian_ODE);
  }

  ret = 0;

  #if !defined(OMC_EMCC)
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
  #endif

  if (nls->multirate)
  {
    gbData->gbfData->stats.nCallsJacobian++;
  }
  else
  {
    gbData->stats.nCallsJacobian++;
  }

  rt_accumulate(SIM_TIMER_JACOBIAN);

  return ret;
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
static int jacobian_DIRK_assemble(DATA *data,
                                  threadData_t *threadData,
                                  DATA_GBODE* gbData,
                                  GB_INTERNAL_NLS_DATA *nls,
                                  SPARSE_PATTERN *ode_jac_sp,
                                  double *jac_buf_ode,
                                  double *jac_buf_nls)
{
  memset(jac_buf_nls, 0, nls->nlsPattern->numberOfNonZeros * sizeof(double));

  DATA_GBODEF *gbfData = gbData->gbfData;

  const double fac = (nls->multirate ? gbfData->stepSize * gbfData->tableau->A[gbfData->act_stage * gbfData->tableau->nStages + gbfData->act_stage]
                                     : gbData->stepSize * gbData->tableau->A[gbData->act_stage * gbData->tableau->nStages + gbData->act_stage]);

  for (int nz = 0; nz < ode_jac_sp->numberOfNonZeros; nz++)
  {
    int idx = nls->ode_to_nls[nz];
    jac_buf_nls[idx] = fac * jac_buf_ode[nz];
  }

  for (int d = 0; d < nls->size; d++)
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
static int jacobian_real_assemble(DATA *data,
                                  threadData_t *threadData,
                                  DATA_GBODE* gbData,
                                  GB_INTERNAL_NLS_DATA *nls,
                                  double gamma,
                                  SPARSE_PATTERN *ode_jac_sp,
                                  double *jac_buf_ode,
                                  double *jac_buf_nls)
{
  memset(jac_buf_nls, 0, nls->nlsPattern->numberOfNonZeros * sizeof(double));

  const double inv_step = 1.0 / (nls->multirate ? gbData->gbfData->stepSize : gbData->stepSize);
  const double weight = inv_step * gamma;

  for (int nz = 0; nz < ode_jac_sp->numberOfNonZeros; nz++)
  {
    int idx = nls->ode_to_nls[nz];
    jac_buf_nls[idx] = -jac_buf_ode[nz];
  }

  for (int d = 0; d < nls->size; d++)
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
static int jacobian_cmplx_assemble(DATA *data,
                                   threadData_t *threadData,
                                   DATA_GBODE* gbData,
                                   GB_INTERNAL_NLS_DATA *nls,
                                   double alpha,
                                   double beta,
                                   SPARSE_PATTERN *ode_jac_sp,
                                   double *jac_buf_ode,
                                   double *jac_buf_nls)
{
  memset(jac_buf_nls, 0, 2 * nls->nlsPattern->numberOfNonZeros * sizeof(double));

  const double inv_step = 1.0 / (nls->multirate ? gbData->gbfData->stepSize : gbData->stepSize);
  const double weight_real = inv_step * alpha;
  const double weight_imag = inv_step * beta;

  for (int nz = 0; nz < ode_jac_sp->numberOfNonZeros; nz++)
  {
    int idx = nls->ode_to_nls[nz];
    jac_buf_nls[2 * idx] = -jac_buf_ode[nz];
  }

  for (int d = 0; d < nls->size; d++)
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
  if (internals->common.status < 0) throwStreamPrint(NULL, "Error in gbInternal_KLU_analyze. Symbolic analysis with KLU failed.");
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
static int gbInternal_dKLU_solve(KLUInternals *internals, int size, double *rhs)
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
static int gbInternal_zKLU_solve(KLUInternals *internals, int size, double *rhs)
{
  int nrhs = 1;
  int ok = klu_z_solve(internals->symbolic, internals->numeric, size, nrhs, rhs, &internals->common);
  return ok;
}

/** @brief Create scalings for scaled 2-norms: used for Newton convergence and integration acceptance criteria. */
static void createGbScales(GB_INTERNAL_NLS_DATA *nls, DATA_GBODE *gbData, double *y1, double *y2)
{
  if (!nls->multirate)
  {
    for (int i = 0; i < nls->size; i++)
    {
      const modelica_real nominal = getNominalFromScalarIdx(nls->nls_user_data->data->simulationInfo, nls->nls_user_data->data->modelData, VAR_KIND_STATE, i);
      nls->scal[i] = 1.0 / (nls->tol_scaled.atol * fabs(nominal) + fmax(fabs(y1[i]), fabs(y2[i])) * nls->tol_scaled.rtol);
    }
  }
  else
  {
    for (int i = 0; i < nls->size; i++)
    {
      const size_t fast_idx = (size_t) gbData->fastStatesIdx[i];
      const modelica_real nominal = getNominalFromScalarIdx(nls->nls_user_data->data->simulationInfo, nls->nls_user_data->data->modelData, VAR_KIND_STATE, fast_idx);
      nls->scal[i] = 1.0 / (nls->tol_scaled.atol * fabs(nominal) + fmax(fabs(y1[i]), fabs(y2[i])) * nls->tol_scaled.rtol);
    }
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

/** @brief Compute scaled norm of possible vector stack vec = (x + v1, x + v2, ..., x + v_{stacksize}). */
static double gbScalesNormXPlusZ(GB_INTERNAL_NLS_DATA *nls, double *x, double *z, int stack_size)
{
  double sum = 0.0;
  for (int j = 0; j < stack_size; j++)
  {
    double *vec_stride = &z[j * nls->size];
    for (int i = 0; i < nls->size; i++)
    {
      double tmp = (x[i] + vec_stride[i]) * nls->scal[i];
      sum += tmp * tmp;
    }
  }

  return sqrt(sum / ((double)nls->size * (double)stack_size));
}

static int gbInternalEvaluateSimplifiedJacobian(DATA *data,
                                                threadData_t *threadData,
                                                DATA_GBODE* gbData,
                                                GB_INTERNAL_NLS_DATA *nls,
                                                modelica_boolean *jac_called,
                                                modelica_boolean isDIRK)
{
  int ret;
  double time_backup;
  int full_size = gbData->nStates;
  SOLVERSTATS *stats = (nls->multirate ? &gbData->gbfData->stats : &gbData->stats);
  double *y_eval = (nls->multirate ? gbData->gbfData->yOld : gbData->yOld);

  // we need to backup potential interpolation data (e.g. in SDIRK realVars already contains Y_full(t0 + h * c1))
  // backup the time and all the states and apply them after the simplified Jacobian computation
  if (isDIRK)
  {
    time_backup = data->localData[0]->timeValue;
    if (nls->multirate) memcpy(nls->work, data->localData[0]->realVars, full_size * sizeof(double));
  }

  // set values for known last point y_eval (simplified Newton)
  memcpy(data->localData[0]->realVars, y_eval, full_size * sizeof(double));
  data->localData[0]->timeValue = (nls->multirate ? gbData->gbfData->time : gbData->time);

  // callback ODE + callback Jacobian of ODE -> nls_jacobian buffer
  ret = gbode_fODE(data, threadData, &(stats->nCallsODE), nls->multirate ? gbData->gbfData->evalSelectionFast : NULL); // TODO: is this correct?
  if (ret < 0) return ret;

  ret = gbInternal_evalJacobian(data, threadData, gbData, nls);
  if (ret < 0) return ret;

  *jac_called = TRUE;

  // reapply the interpolated data
  if (isDIRK)
  {
    data->localData[0]->timeValue = time_backup;
    if (nls->multirate) memcpy(data->localData[0]->realVars, nls->work, full_size * sizeof(double));
  }

  return 0;
}

/** @brief Solve one stage of a DIRK method with the internal solve routine. */
static NLS_SOLVER_STATUS gbInternalSolveNls_DIRK(DATA *data,
                                                 threadData_t *threadData,
                                                 NONLINEAR_SYSTEM_DATA* nonlinsys,
                                                 DATA_GBODE* gbData,
                                                 GB_INTERNAL_NLS_DATA *nls)
{
  int size = nls->size;
  int stage = (nls->multirate ? gbData->gbfData->act_stage : gbData->act_stage);
  double *x = nonlinsys->nlsx;
  double *x_start = nonlinsys->nlsxOld;              // currently the extrapolated (e.g. dense output / hermite guess)
  double *res = nonlinsys->resValues;
  BUTCHER_TABLEAU *tabl = (nls->multirate ? gbData->gbfData->tableau : gbData->tableau);

  double stepSize = (nls->multirate ? gbData->gbfData->stepSize : gbData->stepSize);
  double lastStepSize = (nls->multirate ? gbData->gbfData->lastStepSize : gbData->lastStepSize);

  // return code from KLU or RHS / Jac calls
  int ret;

  createGbScales(nls, gbData, x, x_start);
  double *scal = nls->scal;

  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=(nls->multirate ? (void *) gbData->gbfData : (void *) gbData)};
  SPARSE_PATTERN *ode_pattern = (nls->multirate ? nls->odePatternMR : data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern);

  const int flag = 1;
  modelica_boolean jac_called = FALSE;

  modelica_boolean is_esdirk = (tabl->A[0] == 0.0);
  modelica_boolean sdirk_first_stage = (stage == 0 && !is_esdirk);
  modelica_boolean esdirk_first_stage = (stage == 1 && is_esdirk);

  if (sdirk_first_stage || esdirk_first_stage)
  {
    if (nls->call_jac || gbData->eventHappened)
    {
      ret = gbInternalEvaluateSimplifiedJacobian(data, threadData, gbData, nls, &jac_called, TRUE);
      if (ret < 0) return NLS_FAILED;
    }

    if (jac_called || stepSize != lastStepSize)
    {
      /* fill NLS Jacobian as h * gamma * J_f - I, where J_f is old or newly computed ODE Jacobian nls->jacobian_callback */
      jacobian_DIRK_assemble(data, threadData, gbData, nls, ode_pattern, nls->jacobian_callback, nls->real_nls_jacs[0]);

      /* perform factorization */
      ret = gbInternal_dKLU_factorize(nls->klu_internals_real, size, (int *) nls->nlsPattern->leadindex, (int *) nls->nlsPattern->index, nls->real_nls_jacs[0]);
      if (ret < 0) return NLS_FAILED;
    }
  }

  /* invalidate eta of stage if an event happened */
  if (gbData->eventHappened) nls->etas[stage] = DBL_MAX;

  memcpy(x, x_start, size * sizeof(double));

  // norms, convergence rate
  double nrm_x = 0;
  double nrm_delta = 0;
  double nrm_delta_prev = 0;
  double theta = 0;

  // Newton iteration count - we start with newt_it = 1, because we need this for the step size selection and conditions below
  for (int newt_it = 1 ;; newt_it++)
  {
    nonlinsys->residualFunc(&resUserData, x, res, &flag);

    ret = gbInternal_dKLU_solve(nls->klu_internals_real, size, res);
    if (ret < 0) return NLS_FAILED;
    daxpy_(&size, &DBL_MINUS_ONE, res, &INT_ONE, x, &INT_ONE);

    nrm_delta_prev = fmax(DBL_EPSILON, nrm_delta);
    nrm_delta = gbScalesNorm(nls, res, 1);

    // handle absorption effects
    nrm_x = gbScalesNorm(nls, x, 1);
    modelica_boolean absorption = (nrm_delta <= DBL_ABSORPTION * nrm_x);

    if (newt_it > 1)
    {
      theta = nrm_delta / nrm_delta_prev;

      // Newton failed -> divergence
      if (theta >= nls->theta_divergence && !absorption)
      {
        break;
      }

      nls->etas[stage] = theta / (1 - theta);
    }
    else
    {
      nls->etas[stage] = pow(fmax(nls->etas[stage], DBL_EPSILON), 0.8);
    }

    if (!isfinite(nls->etas[stage]) || !isfinite(nrm_delta))
    {
      // Inf or NaN detected
      // Either RHS or Jacobian or solution of the system contained a Inf or NaN
      return NLS_FAILED;
    }

    // Newton converged
    if (nls->etas[stage] * nrm_delta < nls->fnewt || absorption)
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
      break;
    }
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
    daxpy_(&block_size, &gammas_scaled[real_eig], &v[real_eig * block_size], &INT_ONE, &out[real_eig * block_size], &INT_ONE);
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

#define GB_INTERNAL_LEFT_BOUNDARY -1

/**
 * @brief Set states and time for a T-transform stage evaluation
 * @par Runtime: O(nStates)
 *
 * In multirate mode, slow states are restored from the slow-state cache and
 * fast states are overwritten from the input vector using the fast state index
 * mapping. In single-rate mode, the full state vector is copied from the input.
 *
 * The simulation time is set to the corresponding stage time using the tableau
 * coefficient. If stage < 0, the left interval boundary time is used.
 *
 * @param[in,out] data   Data
 * @param[in]     gbData GBODE data
 * @param[in]     nls    Internal nonlinear system data
 * @param[in]     y_fast   Input state vector (size nls->size)
 * @param[in]     stage  Stage index of the tableau, or negative for left boundary (use macro GB_INTERNAL_LEFT_BOUNDARY)
 */
static inline void gbInternal_T_Transform_set_states(DATA *data, DATA_GBODE *gbData, GB_INTERNAL_NLS_DATA *nls, const double *y_fast, int stage)
{
  if (nls->multirate)
  {
    DATA_GBODEF *gbfData = gbData->gbfData;

    if (stage >= 0)
    {
      slowStateCache_overwrite_stage(gbData, gbfData->slowStateCache, stage, data->localData[0]->realVars);
    }
    else
    {
      slowStateCache_overwrite_left(gbData, gbfData->slowStateCache, data->localData[0]->realVars);
    }

    for (int fast_idx = 0; fast_idx < nls->size; fast_idx++)
    {
      int full_idx = gbData->fastStatesIdx[fast_idx];
      data->localData[0]->realVars[full_idx] = y_fast[fast_idx];
    }

    data->localData[0]->timeValue = (stage >= 0 ? gbfData->time + gbfData->tableau->c[stage] * gbfData->stepSize : gbfData->time);
  }
  else
  {
    memcpy(data->localData[0]->realVars, y_fast, nls->size * sizeof(double));
    data->localData[0]->timeValue = (stage >= 0 ? gbData->time + gbData->tableau->c[stage] * gbData->stepSize : gbData->time);
  }
}

static inline void gbInternal_T_Transform_copy_full_to_fast(DATA_GBODE *gbData, GB_INTERNAL_NLS_DATA *nls, const double *src_full, double *dest_fast)
{
  if (nls->multirate)
  {
    for (int fast_idx = 0; fast_idx < nls->size; fast_idx++)
    {
      int full_idx = gbData->fastStatesIdx[fast_idx];
      dest_fast[fast_idx] = src_full[full_idx];
    }
  }
  else
  {
    memcpy(dest_fast, src_full, nls->size * sizeof(double));
  }
}

static inline void gbInternal_T_Transform_copy_fast_to_full(DATA_GBODE *gbData, GB_INTERNAL_NLS_DATA *nls, const double *src_fast, double *dest_full)
{
  if (nls->multirate)
  {
    for (int fast_idx = 0; fast_idx < nls->size; fast_idx++)
    {
      int full_idx = gbData->fastStatesIdx[fast_idx];
      dest_full[full_idx] = src_fast[fast_idx];
    }
  }
  else
  {
    memcpy(dest_full, src_fast, nls->size * sizeof(double));
  }
}

static inline void gbInternal_T_Transform_fast_to_full_axpy(DATA_GBODE *gbData, GB_INTERNAL_NLS_DATA *nls, const double alpha, const double *x_fast, double *y_full)
{
  if (nls->multirate)
  {
    for (int fast_idx = 0; fast_idx < nls->size; fast_idx++)
    {
      int full_idx = gbData->fastStatesIdx[fast_idx];
      y_full[full_idx] += alpha * x_fast[fast_idx];
    }
  }
  else
  {
    daxpy_(&nls->size, &alpha, x_fast, &INT_ONE, y_full, &INT_ONE);
  }
}

static inline void gbInternal_T_Transform_full_to_fast_axpy(DATA_GBODE *gbData, GB_INTERNAL_NLS_DATA *nls, const double alpha, const double *x_full, double *y_fast)
{
  if (nls->multirate)
  {
    for (int fast_idx = 0; fast_idx < nls->size; fast_idx++)
    {
      int full_idx = gbData->fastStatesIdx[fast_idx];
      y_fast[fast_idx] += alpha * x_full[full_idx];
    }
  }
  else
  {
    daxpy_(&nls->size, &alpha, x_full, &INT_ONE, y_fast, &INT_ONE);
  }
}

static inline void gbInternal_T_Transform_copy_full_to_full_axpy(DATA_GBODE *gbData, GB_INTERNAL_NLS_DATA *nls, const double alpha, const double *x_full, double *y_full)
{
  if (nls->multirate)
  {
    for (int fast_idx = 0; fast_idx < nls->size; fast_idx++)
    {
      int full_idx = gbData->fastStatesIdx[fast_idx];
      y_full[full_idx] += alpha * x_full[full_idx];
    }
  }
  else
  {
    daxpy_(&nls->size, &alpha, x_full, &INT_ONE, y_full, &INT_ONE);
  }
}

/** @brief Solve entire NLS of FIRK with possibly singular Runge-Kutta matrix
 *         via the T-transformation (decoupled space).
 *
 * After convergence the solutions are written into nonlinsys->x and the stage updates are
 * written into gbData->k or gbfData->kCurrPacked.
*/
static NLS_SOLVER_STATUS gbInternalSolveNls_T_Transform(DATA *data,
                                                        threadData_t *threadData,
                                                        NONLINEAR_SYSTEM_DATA* nonlinsys,
                                                        DATA_GBODE* gbData,
                                                        GB_INTERNAL_NLS_DATA *nls)
{
  int size = nls->size;
  int w_size = nls->size * nls->tabl->t_transform->size;
  double stepSize = (nls->multirate ? gbData->gbfData->stepSize : gbData->stepSize);
  double lastStepSize = (nls->multirate ? gbData->gbfData->lastStepSize : gbData->lastStepSize);
  double invh = 1.0 / stepSize;
  double minvh = -invh;
  double *x = nonlinsys->nlsx;
  double *x_start = nonlinsys->nlsxOld;
  double *flat_res = nonlinsys->resValues;

  double *yOld = (nls->multirate ? gbData->gbfData->yOldPacked : gbData->yOld);
  double *kPacked = (nls->multirate ? gbData->gbfData->kCurrPacked : gbData->k);

  EVAL_SELECTION *selection = (nls->multirate ? gbData->gbfData->evalSelectionFast : NULL);

  SOLVERSTATS *stats = (nls->multirate ? &gbData->gbfData->stats : &gbData->stats);

  // return code from KLU or RHS / Jac calls
  int ret;

  createGbScales(nls, gbData, x, x_start);
  double *scal = nls->scal;

  SPARSE_PATTERN *ode_pattern = (nls->multirate ? nls->odePatternMR : data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern);
  T_TRANSFORM *transform = nls->tabl->t_transform;

  modelica_boolean jac_called = FALSE;

  if (nls->call_jac || transform->firstRowZero || gbData->eventHappened)
  {
    /* set values for known last point (simplified Newton) */
    gbInternal_T_Transform_set_states(data, gbData, nls, yOld, GB_INTERNAL_LEFT_BOUNDARY);

    /* callback ODE + callback Jacobian of ODE -> nls_jacobian buffer
       => TODO: if method has property a_{s,:} = b, i.e. FSAL or kLeft is available, we could recycle the k_s from before here
                or does fODE set algebraic variables that may be needed for the Jacobian? */
    ret = gbode_fODE(data, threadData, &stats->nCallsODE, selection);
    if (ret < 0) return NLS_FAILED;

    if (transform->firstRowZero)
    {
      // save explicit stage (e.g. Lobatto IIIA)
      gbInternal_T_Transform_copy_full_to_fast(gbData, nls, &data->localData[0]->realVars[gbData->nStates], kPacked);
    }

    if (nls->call_jac || gbData->eventHappened)
    {
      gbInternal_evalJacobian(data, threadData, gbData, nls);

      jac_called = TRUE;
    }
  }

  if (jac_called || stepSize != lastStepSize)
  {
    for (int sys_real = 0; sys_real < nls->tabl->t_transform->nRealEigenvalues; sys_real++)
    {
      /* create Jacobian real: gamma/h * I - J_f */
      jacobian_real_assemble(data, threadData, gbData, nls, nls->tabl->t_transform->gamma[sys_real],
                             ode_pattern, nls->jacobian_callback, nls->real_nls_jacs[sys_real]);
      ret = gbInternal_dKLU_factorize(&nls->klu_internals_real[sys_real],
                                      size,
                                      (int *) nls->nlsPattern->leadindex,
                                      (int *) nls->nlsPattern->index,
                                      nls->real_nls_jacs[sys_real]);
      if (ret < 0) return NLS_FAILED;
    }
    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      /* create Jacobian complex: (alpha + i * beta)/h * I - J_f */
      jacobian_cmplx_assemble(data, threadData, gbData, nls, nls->tabl->t_transform->alpha[sys_cmplx], nls->tabl->t_transform->beta[sys_cmplx],
                              ode_pattern, nls->jacobian_callback, nls->cmplx_nls_jacs[sys_cmplx]);
      ret = gbInternal_zKLU_factorize(&nls->klu_internals_cmplx[sys_cmplx],
                                      size,
                                      (int *) nls->nlsPattern->leadindex,
                                      (int *) nls->nlsPattern->index,
                                      nls->cmplx_nls_jacs[sys_cmplx]);
      if (ret < 0) return NLS_FAILED;
    }
  }

  // we solve for Z = X(t_ij) - yOld or W = (T^{-1} otimes I) * Z, then get K back via K = 1/h * A^{-1} * Z

  // set guess Z[j] = X_start[j] - yOld
  for (int j = 0; j < transform->size; j++)
  {
    memcpy(&nls->Z[j * size], &x_start[j * size], size * sizeof(double));
    daxpy_(&size, &DBL_MINUS_ONE, yOld, &INT_ONE, &nls->Z[j * size], &INT_ONE);
  }

  // W = (T^{-1} otimes I) * Z
  dense_kron_id_vec(transform->size, size, transform->T_inv, nls->Z, nls->W);

  // norms, convergence rate
  double nrm_x = 0;
  double nrm_delta = 0;
  double nrm_delta_prev = 0;
  double theta = 0;

  /* invalidate eta if an event happened */
  if (gbData->eventHappened) *nls->etas = DBL_MAX;

  // Newton iteration count - we start with newt_it = 1, because we need this for the step size selection and conditions below
  for (int newt_it = 1 ;; newt_it++)
  {
    // compute residuals: rhs := -1 / h (Lambda otimes I) * W + (T^{-1} * I) * F((T otimes I) * W) + Phi (Phi = T^{-1} A_part^{-1} * K_1 if (K_1 explicit else 0))

    // work[j] = F((T otimes I) * W)[j]
    for (int j = 0; j < transform->size; j++)
    {
      gbInternal_T_Transform_set_states(data, gbData, nls, yOld, j + (int)transform->firstRowZero);
      gbInternal_T_Transform_fast_to_full_axpy(gbData, nls, DBL_ONE, &nls->Z[j * size], data->localData[0]->realVars);
      ret = gbode_fODE(data, threadData, &stats->nCallsODE, selection);
      if (ret < 0) return NLS_FAILED;

      gbInternal_T_Transform_copy_full_to_fast(gbData, nls, &data->localData[0]->realVars[gbData->nStates], &nls->work[j * size]);
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
        daxpy_(&size, &transform->phi[j], kPacked,
               &INT_ONE, &flat_res[j * size], &INT_ONE);
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
      ret = gbInternal_dKLU_solve(&nls->klu_internals_real[sys_real], size, &flat_res[sys_real * size]);
      if (ret < 0) return NLS_FAILED;
    }

    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      ret = gbInternal_zKLU_solve(&nls->klu_internals_cmplx[sys_cmplx], size, &nls->cmplx_nls_res[sys_cmplx][0]);
      if (ret < 0) return NLS_FAILED;
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

    // Z = (T otimes I) * W
    dense_kron_id_vec(transform->size, size, transform->T, nls->W, nls->Z);

    nrm_delta_prev = fmax(DBL_EPSILON, nrm_delta);
    nrm_delta = gbScalesNorm(nls, flat_res, nls->tabl->t_transform->size);

    // handle absorption effects
    nrm_x = gbScalesNormXPlusZ(nls, yOld, nls->Z, transform->size);
    modelica_boolean absorption = (nrm_delta <= DBL_ABSORPTION * nrm_x);

    if (newt_it > 1)
    {
      theta = nrm_delta / nrm_delta_prev;

      // Newton failed -> divergence
      if (theta >= nls->theta_divergence && !absorption)
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

    if (!isfinite(*nls->etas) || !isfinite(nrm_delta))
    {
      // Inf or NaN detected
      // Either RHS or Jacobian or solution of the system contained a Inf or NaN
      return NLS_FAILED;
    }

    // Newton converged
    if (*nls->etas * nrm_delta < nls->fnewt || absorption)
    {
      if (theta < nls->theta_keep)
      {
        nls->call_jac = FALSE;
      }
      else
      {
        nls->call_jac = TRUE;
      }

      // set solution X[j] = X_0 + Z[j]
      int offset = transform->firstRowZero ? size : 0;
      for (int j = 0; j < transform->size; j++)
      {
        memcpy(&x[j * size + offset], &nls->Z[j * size], size * sizeof(double));
        daxpy_(&size, &DBL_ONE, yOld, &INT_ONE, &x[j * size + offset], &INT_ONE);
      }

      // recompute weights K from Z via K = 1 / h * (A_part^{-1} otimes I) * Z + rho * k_1 if k_1 explicit else 0 (rho := -A_part^{-1} * A_{r, 1})
      // where r are all rows that belong to A_part
      dense_kron_id_vec(transform->size, size, transform->A_part_inv, nls->Z,
                        &kPacked[offset]);
      dscal_(&w_size, &invh, &kPacked[offset], &INT_ONE);

      if (transform->firstRowZero)
      {
        // add k[j] += rho[j] * k_1 or k[j] -= (-A_part^{-1} * A_{r, 1} * k_1)[j] * k_1
        for (int j = 0; j < transform->size; j++)
        {
          daxpy_(&size, &transform->rho[j], kPacked,
            &INT_ONE, &kPacked[offset + j * size], &INT_ONE);
        }
      }

      // for explicit first stage: copy x0 into x (e.g. Lobatto IIIA)
      if (transform->firstRowZero)
      {
        memcpy(x, yOld, size * sizeof(double));
      }

      // for explicit last stage: compute final K_s and X_s
      if (transform->lastColumnZero)
      {
        int s_minus1 = nls->tabl->nStages - 1;

        // X_s = x0 + h * sum{j=1}^{s-1} A_{s, j} * k_j as A_{s, s} == 0!
        memcpy(&x[size * s_minus1], yOld, size * sizeof(double));
        dgemm_(&CHAR_NO_TRANS, &CHAR_TRANS,
               &size, &INT_ONE, &s_minus1,
               &stepSize,
               kPacked, &size,
               &nls->tabl->A[s_minus1 * nls->tabl->nStages], &INT_ONE,
               &DBL_ONE,
               &x[size * s_minus1], &size);

        gbInternal_T_Transform_set_states(data, gbData, nls, &x[size * s_minus1], s_minus1);
        ret = gbode_fODE(data, threadData, &stats->nCallsODE, selection);
        if (ret < 0) return NLS_FAILED;

        // k_s = f(t + h * c_s, x0 + h * sum{j=1}^{s-1} A_{s, j} * k_j)
        gbInternal_T_Transform_copy_full_to_fast(gbData, nls, &data->localData[0]->realVars[gbData->nStates], &kPacked[size * s_minus1]);
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
                            modelica_boolean isPatternAvailable,
                            modelica_boolean isFast)
{
  BUTCHER_TABLEAU *tabl = (isFast ? ((DATA_GBODEF *) userData->solverData)->tableau
                                  : ((DATA_GBODE *) userData->solverData)->tableau);
  T_TRANSFORM *trfm = tabl->t_transform;
  JACOBIAN* jacobian_ODE = &(userData->data->simulationInfo->analyticJacobians[userData->data->callback->INDEX_JAC_A]);

  GB_INTERNAL_NLS_DATA *nls = (GB_INTERNAL_NLS_DATA *) malloc(sizeof(GB_INTERNAL_NLS_DATA));

  // multirate stuff
  nls->multirate = isFast;
  nls->new_fast_states = FALSE;

  // to have sufficiently large buffers, we need an overestimate for the system of the form struct(I + J) * v = b
  unsigned int nls_nnz_estimate = 0;

  nls->nls_user_data = userData;
  nls->size = jacobian_ODE->sizeRows;
  nls->jacobian_callback = (double *) malloc(jacobian_ODE->sparsePattern->numberOfNonZeros * sizeof(double));
  nls->ode_to_nls = (int *) malloc(jacobian_ODE->sparsePattern->numberOfNonZeros * sizeof(int));
  nls->nls_diag_indices = (int *) malloc(jacobian_ODE->sizeRows * sizeof(int));

  nls->tabl = tabl;
  nls->use_t_transform = (trfm != NULL);

  // we have to delay setting the sparse pattern and the symbolic analysis of KLU
  // until we know the structure of the fast state system, in case of singlerate everything is known at allocation time
  if (nls->multirate)
  {
    // overestimate the nnz for the buffer sizes and allocate enough memory for the pattern I + J
    nls_nnz_estimate = jacobian_ODE->sparsePattern->numberOfNonZeros + jacobian_ODE->sizeRows;

    nls->nlsPattern = allocSparsePattern(jacobian_ODE->sizeRows, nls_nnz_estimate, jacobian_ODE->sizeRows);
    nls->ownsNlsPattern = TRUE;

    nls->odePatternMR = allocSparsePattern(jacobian_ODE->sizeRows, nls_nnz_estimate, jacobian_ODE->sizeRows);
    nls->ownsODEPatternMR = TRUE;

    // we also need to allocate the stub data
    nls->colorCols_stub = (unsigned int *) malloc(jacobian_ODE->sizeRows * sizeof(unsigned int));
    nls->maxColors_stub = 0;
  }
  else if (nls->use_t_transform)
  {
    // allocate the correct sparse pattern directly
    nls->nlsPattern = buildSparsePatternWithDiagonal(jacobian_ODE->sparsePattern, jacobian_ODE->sizeRows, NULL);
    nls->ownsNlsPattern = TRUE;
  }
  else
  {
    // use the sparse pattern from the user data
    nls->nlsPattern = userData->nlsData->sparsePattern;
    nls->ownsNlsPattern = FALSE;
  }

  if (!nls->multirate)
  {
    // create ODE Jac -> NLS Jacobian mapping
    updateSparsePatternMappings(nls->nlsPattern, jacobian_ODE->sparsePattern, nls, jacobian_ODE->sizeRows);

    nls->odePatternMR = NULL;
    nls->ownsODEPatternMR = FALSE;

    // set exact value
    nls_nnz_estimate = nls->nlsPattern->numberOfNonZeros;
  }

  nls->scal = (double *) malloc(jacobian_ODE->sizeRows * sizeof(double));
  nls->etas = (double *) malloc(tabl->nStages * sizeof(double));

  for (int i = 0; i < tabl->nStages; i++)
  {
    nls->etas[i] = DBL_MAX;
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

    // default if no tolerance scaling is performed (scaled norm == actual TOL norm)
    const double alpha_default = 3e-2;
    const double alpha_maximal = 5e-2;
    const double safety_newt = 0.1;
    double fnewt_prop = alpha_default;

    if (nls->tol_scaled.rtol != nls->tol_integrator.rtol)
    {
      // undo the tolerance scaling, s.t. raw residual <= alpha * actual TOL, where per default alpha = 3e-2, unless severe tolerance scaling is done
      double target_alpha = alpha_default;

      if (tabl->order_b - tabl->error_order != 1)
      {
        // severe tolerance scaling, possibly be more conservative for high orders / many stages
        // choose to loosen safety a bit more: act as if safety was given by safety_newt
        target_alpha = pow(safety_newt, 1.0 / order_quot);
      }

      target_alpha = fmin(alpha_maximal, target_alpha);

      const double tol_times_one = pow(nls->tol_scaled.rtol, 1.0 / order_quot - 1.0) * pow(safety, -1.0 / order_quot);
      fnewt_prop = tol_times_one * target_alpha;
    }

    // in all branches: fnewt * tol_scaled = alpha_eff * rtol_integrator, where
    //     alpha_eff = alpha_default                                        (no scaling)
    //     alpha_eff = fmin(alpha_maximal, alpha_default)                   (normal, p-q=1)
    //     alpha_eff = fmin(alpha_maximal, safety_newt^((order_b+1)/(error_order+1)))  (severe, p-q!=1)
    nls->fnewt = fmax(DBL_ABSORPTION / nls->tol_scaled.rtol, fmin(alpha_maximal, fnewt_prop));
  }

  // add a history of thetas_last + #newt iterations to detect nearly linear systems, similar to err controller
  if(omc_flag[FLAG_SR_NLS_INTERNAL_JACKEEP])
  {
    double keep_flag_value = atof(omc_flagValue[FLAG_SR_NLS_INTERNAL_JACKEEP]);
    if (keep_flag_value >= 1.0)
    {
      throwStreamPrint(NULL, "Invalid value %1.6e for flag '-gbnls_internal_jackeep'. Value must be strictly less than 1.", keep_flag_value);
    }
    else
    {
      nls->theta_keep = keep_flag_value;
    }
  }
  else
  {
    // heuristic that takes sparsity into account
    if (nls->size > 8)
    {
      nls->theta_keep = pow(10.0, -3.0 + 1.75 * log(1.0 + (double)jacobian_ODE->sparsePattern->maxColors) / log(1.0 + (double)nls->size));
    }
    else
    {
      // for very small systems we can compute the Jacobian frequently
      nls->theta_keep = 1e-3;
    }
  }

  nls->call_jac = TRUE;
  nls->theta_divergence = 0.99;
  nls->max_newton_it = !trfm ? 5 : 4 + 2 * trfm->size; // = 5 for each (E)SDIRK stage and e.g. 10 for full RadauIIA 3-step

  if (!trfm)
  {
    nls->klu_internals_real = (KLUInternals *) calloc(1, sizeof(KLUInternals));
    nls->klu_internals_real->numeric = NULL;
    nls->klu_internals_cmplx = NULL;
    nls->real_nls_jacs = (double **) malloc(sizeof(double *));
    nls->real_nls_jacs[0] = (double *) malloc(nls_nnz_estimate * sizeof(double));

    // auxiliary memory
    nls->work = (double *) malloc(4 * nls->size * sizeof(double));

    if (!nls->multirate)
    {
      gbInternal_KLU_analyze(nls->klu_internals_real, nls->size, (int *) nls->nlsPattern->leadindex, (int *) nls->nlsPattern->index);
    }
  }
  else
  {
    nls->klu_internals_real = (KLUInternals *) calloc(trfm->nRealEigenvalues, sizeof(KLUInternals));
    nls->klu_internals_cmplx = (KLUInternals *) calloc(trfm->nComplexEigenpairs, sizeof(KLUInternals));

    nls->real_nls_jacs = (double **) malloc(trfm->nRealEigenvalues * sizeof(double *));
    nls->real_nls_res = (double **) malloc(trfm->nRealEigenvalues * sizeof(double *));
    nls->cmplx_nls_jacs = (double **) malloc(trfm->nComplexEigenpairs * sizeof(double *));
    nls->cmplx_nls_res = (double **) malloc(trfm->nComplexEigenpairs * sizeof(double *));

    // TODO: We are able to remove these redundant analysis parts, as we can use 1 analysis (symbolic) and compute different factorizations.
    for (int sys_real = 0; sys_real < trfm->nRealEigenvalues; sys_real++)
    {
      nls->real_nls_res[sys_real] = (double *) malloc(nls->size * sizeof(double));
      nls->real_nls_jacs[sys_real] = (double *) malloc(nls_nnz_estimate * sizeof(double));

      if (!nls->multirate)
      {
        gbInternal_KLU_analyze(&nls->klu_internals_real[sys_real], nls->size, (int *) nls->nlsPattern->leadindex, (int *) nls->nlsPattern->index);
      }

      nls->klu_internals_real[sys_real].numeric = NULL;
    }
    for (int sys_cmplx = 0; sys_cmplx < trfm->nComplexEigenpairs; sys_cmplx++)
    {
      nls->cmplx_nls_res[sys_cmplx] = (double *) malloc(2 * nls->size * sizeof(double));
      nls->cmplx_nls_jacs[sys_cmplx] = (double *) malloc(2 * nls_nnz_estimate * sizeof(double));

      if (!nls->multirate)
      {
        gbInternal_KLU_analyze(&nls->klu_internals_cmplx[sys_cmplx], nls->size, (int *) nls->nlsPattern->leadindex, (int *) nls->nlsPattern->index);
      }

      nls->klu_internals_cmplx[sys_cmplx].numeric = NULL;
    }

    // iterate
    nls->Z = (double *) malloc(nls->size * trfm->size * sizeof(double));
    nls->W = (double *) malloc(nls->size * trfm->size * sizeof(double));

    // auxiliary memory
    nls->work = (double *) malloc(nls->size * MAX(trfm->size, 4) * sizeof(double));
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
  free(nls->work);

  if (nls->ownsNlsPattern)
  {
    freeSparsePattern(nls->nlsPattern);
    free(nls->nlsPattern);
  }

  if (nls->ownsODEPatternMR)
  {
    freeSparsePattern(nls->odePatternMR);
    free(nls->odePatternMR);
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
      if (nls->klu_internals_real[sys_real].numeric) klu_free_numeric(&nls->klu_internals_real[sys_real].numeric, &nls->klu_internals_real[sys_real].common);
      if (nls->klu_internals_real[sys_real].symbolic) klu_free_symbolic(&nls->klu_internals_real[sys_real].symbolic, &nls->klu_internals_real[sys_real].common);
    }
    for (int sys_cmplx = 0; sys_cmplx < nls->tabl->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      free(nls->cmplx_nls_jacs[sys_cmplx]);
      free(nls->cmplx_nls_res[sys_cmplx]);
      if (nls->klu_internals_cmplx[sys_cmplx].numeric) klu_free_numeric(&nls->klu_internals_cmplx[sys_cmplx].numeric, &nls->klu_internals_cmplx[sys_cmplx].common);
      if (nls->klu_internals_cmplx[sys_cmplx].symbolic) klu_free_symbolic(&nls->klu_internals_cmplx[sys_cmplx].symbolic, &nls->klu_internals_cmplx[sys_cmplx].common);
    }

    free(nls->real_nls_jacs);
    free(nls->real_nls_res);
    free(nls->cmplx_nls_jacs);
    free(nls->cmplx_nls_res);

    if (nls->klu_internals_real) free(nls->klu_internals_real);
    if (nls->klu_internals_cmplx) free(nls->klu_internals_cmplx);

    free(nls->Z);
    free(nls->W);
  }

  if (nls->multirate)
  {
    free(nls->colorCols_stub);
  }

  free(nls);
}

/* Get internal, scaled tolerances. */
Tolerances *gbInternalNlsGetScaledTolerances(void *nls_ptr)
{
  return &((GB_INTERNAL_NLS_DATA *) nls_ptr)->tol_scaled;
}

void gbInternalScheduleFastStatesUpdate(void *nls_ptr)
{
  assert(((GB_INTERNAL_NLS_DATA *) nls_ptr)->multirate);
  ((GB_INTERNAL_NLS_DATA *) nls_ptr)->new_fast_states = TRUE;
}

static void transferFastColoring(GB_INTERNAL_NLS_DATA *nls,
                                 DATA_GBODE *gbData,
                                 SPARSE_PATTERN *fast_ode_pattern)
{
  nls->maxColors_stub = fast_ode_pattern->maxColors;
  memset(nls->colorCols_stub, 0, gbData->nStates * sizeof(unsigned int));

  for (unsigned int i = 0; i < nls->size; i++)
  {
    unsigned int fast_idx = gbData->fastStatesIdx[i];
    nls->colorCols_stub[fast_idx] = fast_ode_pattern->colorCols[i];
  }
}

/**
 * @brief Reduces a full sparse CSC pattern to a smaller subpattern.
 *
 * Extracts only the rows and columns specified in the `indices` array.
 * The output pattern `out` must be preallocated with sufficient size.
 * Coloring is not handled in this function.
 *
 * @param[in]  full         Pointer to the full sparse pattern (CSC format).
 * @param[in]  size_full    Total number of columns/rows in the full matrix.
 * @param[out] out          Pointer to the preallocated sparse pattern to fill.
 * @param[in]  indices      Array of indices to keep (both rows and columns).
 * @param[in]  size_indices Number of indices in the `indices` array.
 * @param[in,out] work      Temporary workspace of size `size_full` (mutated).
 */
static void reduceFullToFastPattern(const SPARSE_PATTERN *full,
                                    int size_full,
                                    SPARSE_PATTERN *out,
                                    const int *indices,
                                    int size_indices,
                                    unsigned int *work)
{
  unsigned int nnz = 0;

  for (int i = 0; i < size_full; i++)
  {
    work[i] = UINT_MAX;
  }

  for (int i = 0; i < size_indices; i++)
  {
    work[indices[i]] = i;
  }

  out->leadindex[0] = 0;

  for (int small_col = 0; small_col < size_indices; small_col++)
  {
    unsigned int full_col = indices[small_col];

    for (unsigned int nz_full = full->leadindex[full_col]; nz_full < full->leadindex[full_col + 1]; nz_full++)
    {
      unsigned int full_row = full->index[nz_full];
      unsigned int small_row = work[full_row];

      if (small_row != UINT_MAX)
      {
        out->index[nnz++] = small_row;
      }
    }

    out->leadindex[small_col + 1] = nnz;
  }

  out->numberOfNonZeros = nnz;
  out->sizeofIndex      = nnz;
}

static void createGreedyColoring(SPARSE_PATTERN *pattern,
                                 unsigned int size,
                                 unsigned int *work)
{
  unsigned int *rowUsed = work;
  unsigned int remaining = size;
  unsigned int color = 1;

  for (unsigned int i = 0; i < size; i++)
    pattern->colorCols[i] = 0;

  while (remaining > 0)
  {
    memset(rowUsed, 0, size * sizeof(unsigned int));

    for (unsigned int col = 0; col < size; col++)
    {
      if (pattern->colorCols[col] != 0) continue;

      int conflict = 0;

      for (unsigned int nz = pattern->leadindex[col]; nz < pattern->leadindex[col+1]; nz++)
      {
        unsigned int row = pattern->index[nz];
        if (rowUsed[row])
        {
          conflict = 1;
          break;
        }
      }

      if (!conflict)
      {
        pattern->colorCols[col] = color;
        remaining--;

        for (unsigned int nz = pattern->leadindex[col]; nz < pattern->leadindex[col+1]; nz++)
        {
          unsigned int row = pattern->index[nz];
          rowUsed[row] = 1;
        }
      }
    }

    color++;
  }

  pattern->maxColors = color - 1;
}

modelica_boolean updateFastStates(DATA *data,
                                  threadData_t *threadData,
                                  NONLINEAR_SYSTEM_DATA* nonlinsys,
                                  DATA_GBODE* gbData,
                                  GB_INTERNAL_NLS_DATA *nls)
{
  SPARSE_PATTERN *full_ode_pattern = data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A].sparsePattern;
  DATA_GBODEF *gbfData = gbData->gbfData;

  // update size
  nls->size = gbData->nFastStates;
  nls->call_jac = TRUE;

  for (int stage = 0; stage < gbfData->tableau->nStages; stage++)
  {
    nls->etas[stage] = DBL_MAX;
  }

  // fill preallocated nls->odePatternMR with struct(J)_fast
  reduceFullToFastPattern(full_ode_pattern, gbData->nStates, nls->odePatternMR, gbData->fastStatesIdx, gbData->nFastStates, (unsigned int *) nls->work);

  // create the coloring for struct(J)_fast
  createGreedyColoring(nls->odePatternMR, gbData->nFastStates, (unsigned int *) nls->work);

  // transfer the coloring of struct(J)_fast -> struct(J)_fast embedded into J itself for selective evaluation
  transferFastColoring(nls, gbData, nls->odePatternMR);

  // fill preallocated nls->nlsPattern with struct(I + J)_fast
  buildSparsePatternWithDiagonal(nls->odePatternMR, gbfData->nFastStates, nls->nlsPattern);

  // update mappings: ode_to_nls and nls_diag_indices
  updateSparsePatternMappings(nls->nlsPattern, nls->odePatternMR, nls, nls->size);

  // create new symbolic factorization
  if (gbfData->tableau->t_transform == NULL)
  {
    if (nls->klu_internals_real->numeric) klu_free_numeric(&nls->klu_internals_real->numeric, &nls->klu_internals_real->common);
    if (nls->klu_internals_real->symbolic) klu_free_symbolic(&nls->klu_internals_real->symbolic, &nls->klu_internals_real->common);
    gbInternal_KLU_analyze(nls->klu_internals_real, nls->size, (int *) nls->nlsPattern->leadindex, (int *) nls->nlsPattern->index);
    nls->klu_internals_real->numeric = NULL;
  }
  else
  {
    // TODO: same as in allocation: we are able to remove these redundant analysis parts, as we can use 1 analysis (symbolic) and compute different factorizations.
    for (int sys_real = 0; sys_real < gbfData->tableau->t_transform->nRealEigenvalues; sys_real++)
    {
      if (nls->klu_internals_real[sys_real].numeric) klu_free_numeric(&nls->klu_internals_real[sys_real].numeric, &nls->klu_internals_real[sys_real].common);
      if (nls->klu_internals_real[sys_real].symbolic) klu_free_symbolic(&nls->klu_internals_real[sys_real].symbolic, &nls->klu_internals_real[sys_real].common);
      gbInternal_KLU_analyze(&nls->klu_internals_real[sys_real], nls->size, (int *) nls->nlsPattern->leadindex, (int *) nls->nlsPattern->index);
      nls->klu_internals_real[sys_real].numeric = NULL;
    }
    for (int sys_cmplx = 0; sys_cmplx < gbfData->tableau->t_transform->nComplexEigenpairs; sys_cmplx++)
    {
      if (nls->klu_internals_cmplx[sys_cmplx].numeric) klu_free_numeric(&nls->klu_internals_cmplx[sys_cmplx].numeric, &nls->klu_internals_cmplx[sys_cmplx].common);
      if (nls->klu_internals_cmplx[sys_cmplx].symbolic) klu_free_symbolic(&nls->klu_internals_cmplx[sys_cmplx].symbolic, &nls->klu_internals_cmplx[sys_cmplx].common);
      gbInternal_KLU_analyze(&nls->klu_internals_cmplx[sys_cmplx], nls->size, (int *) nls->nlsPattern->leadindex, (int *) nls->nlsPattern->index);
      nls->klu_internals_cmplx[sys_cmplx].numeric = NULL;
    }
  }

  return TRUE;
}

/* Entry point for `internal` solve routine: DIRK or FIRK */
NLS_SOLVER_STATUS gbInternalSolveNls(DATA *data,
                                     threadData_t *threadData,
                                     NONLINEAR_SYSTEM_DATA* nonlinsys,
                                     DATA_GBODE* gbData,
                                     void *nls_ptr)
{
  GB_INTERNAL_NLS_DATA *nls = (GB_INTERNAL_NLS_DATA *) nls_ptr;

  if (nls->new_fast_states)
  {
    // update sparse pattern struct(I + J) and create a new symbolic factorization
    modelica_boolean success = updateFastStates(data, threadData, nonlinsys, gbData, nls);
    if (!success) return NLS_FAILED;
    nls->new_fast_states = FALSE;
  }

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
 * @brief Contractive error estimate for stiff problems. (stiffness filter)
 *
 * Construct an embedded method of order `nStages` for a given collocation method
 * with at least one real eigenvalue and uncollocated point 0.0. We exclude
 * complex eigenvalues as this work would be even more expensive then.
 *
 * This estimate is A-stable and of one order higher than the naive embedded method, which
 * is crucial for stiff problems.
 *
 * See notes on struct CONTRACTIVE_ERROR for more context.
 */
void gbInternalContractiveDefect(DATA *data,
                           threadData_t *threadData,
                           NONLINEAR_SYSTEM_DATA *nonlinsys,
                           DATA_GBODE *gbData,
                           double *err)
{
  GB_INTERNAL_NLS_DATA *nls = (GB_INTERNAL_NLS_DATA *) (((struct dataSolver *)nonlinsys->solverData)->ordinaryData);
  BUTCHER_TABLEAU *tabl = nls->tabl;
  CONTRACTIVE_ERROR *contraction = tabl->contraction;
  SOLVERSTATS *stats = (nls->multirate ? &gbData->gbfData->stats : &gbData->stats);

  int nStates = gbData->nStates;
  int size = nls->size;
  int nStages = (int)tabl->nStages;

  double *yOld = (nls->multirate ? gbData->gbfData->yOldPacked : gbData->yOld);
  double *kPacked = (nls->multirate ? gbData->gbfData->kCurrPacked : gbData->k);

  // ERR := -d(0)^T * A * k
  dgemm_(&CHAR_NO_TRANS, &CHAR_NO_TRANS,
         &size,
         &INT_ONE,
         &nStages,
         &DBL_MINUS_ONE, kPacked, &size,
         contraction->dT_A, &nStages,
         &DBL_ZERO, err, &size);

  modelica_boolean sr_valid = (!nls->multirate && !gbData->didFastStep && gbData->time != data->simulationInfo->startTime && !gbData->eventHappened && gbData->extrapolationBaseTime != INFINITY);
  modelica_boolean mr_valid = (nls->multirate && gbData->didFastStep && gbData->gbfData->extrapolationValid);

  if (tabl->isKRightAvailable && (sr_valid || mr_valid))
  {
    // f(t_n, y(t_n)) == k_right == f(t_n-1 + h_n-1, y(t_n-1 + h_n-1)) of the previous step up to NLS precision
    //   similar to the FSAL property of ESDIRK or ERK, but the method by itself does not have c_0 = 0 as a node!
    // Note that the order of this k_right is the order p of the method (e.g. p = 2s-1 for Radau IIA), since kRight is a collocated node
    // of the previous interval. Therefore, the computed defect will still be O(h^s) even though f(x0, y0) = k_right + O(h^p)
    double *k0Packed = (nls->multirate ? &gbData->gbfData->kLast[(tabl->nStages - 1) * gbData->nFastStates]
                                       : &gbData->kLast[(tabl->nStages - 1) * gbData->nStates]);

    // ERR := f(t_n, y(t_n)) - d(0)^T * A * k
    daxpy_(&nls->size, &DBL_ONE, k0Packed, &INT_ONE, err, &INT_ONE);
  }
  else
  {
    // fresh computation of f(t_n, y(t_n)) as previous step is not valid or method does not collocate node 1
    gbInternal_T_Transform_set_states(data, gbData, nls, yOld, GB_INTERNAL_LEFT_BOUNDARY);
    gbode_fODE(data, threadData, &stats->nCallsODE, (nls->multirate ? gbData->gbfData->evalSelectionFast : NULL));

    // ERR := f(t_n, y(t_n)) - d(0)^T * A * k
    gbInternal_T_Transform_full_to_fast_axpy(gbData, nls, DBL_ONE, &data->localData[0]->realVars[nStates], err);
  }

  // ERR := (gamma / h * I - J)^{-1} * yt = (gamma / h * I - J)^{-1} * (f(t_n, y(t_n)) - d(0)^T * A * k) (exact error measure)
  gbInternal_dKLU_solve(&nls->klu_internals_real[0], size, err);
}

void gbInternalContractiveFilter(DATA *data,
                                 threadData_t *threadData,
                                 NONLINEAR_SYSTEM_DATA *nonlinsys,
                                 DATA_GBODE *gbData,
                                 double *y,
                                 double *yt)
{
  GB_INTERNAL_NLS_DATA *nls = (GB_INTERNAL_NLS_DATA *) (((struct dataSolver *)nonlinsys->solverData)->ordinaryData);
  int size = nls->size;

  assert(nls->tabl->contraction->apply_filter_only);

  if (!nls->multirate)
  {
    // yt := yt - y
    daxpy_(&size, &DBL_MINUS_ONE, y, &INT_ONE, yt, &INT_ONE);

    // yt := (I - h * gamma * J)^{-1} (yt - y); no need to dscal_ with some 1 / (h * gamma) as system is written with factor of I = 1
    gbInternal_dKLU_solve(&nls->klu_internals_real[0], size, yt);

    // yt := yt + y
    daxpy_(&size, &DBL_ONE, y, &INT_ONE, yt, &INT_ONE);
  }
  else
  {
    double *work = nls->work;

    // work := fast(yt - y)
    gbInternal_T_Transform_copy_full_to_fast(gbData, nls, yt, work);
    gbInternal_T_Transform_full_to_fast_axpy(gbData, nls, -1.0, y, work);

    // work := (I - h * gamma * J)^{-1} (yt - y); no need to dscal_ with some 1 / (h * gamma) as system is written with factor of I = 1
    gbInternal_dKLU_solve(&nls->klu_internals_real[0], size, work);

    // yt := full(work)
    gbInternal_T_Transform_copy_fast_to_full(gbData, nls, work, yt);

    // yt := y + full(work)
    gbInternal_T_Transform_copy_full_to_full_axpy(gbData, nls, 1.0, y, yt);
  }
}

// returns a work pointer of at least 32 * N_STATES bytes == 4 * N_STATES * sizeof(double)
double *gbInternalGetWorkPointer(void *nls_ptr)
{
  return ((GB_INTERNAL_NLS_DATA *) nls_ptr)->work;
}

/**
 * @brief Perform intrastep stage-value-prediction (linear combination of known stage values k).
 *
 * Calculates y_predictor := y0 + h * A_predictor[1] * k[1] + A_predictor[2] * k[2] + ... + A_predictor[s-1] * k[s-1]),
 * where values of A_predictor are choosen such that order and stability properties are nice.
 *
 * @note This function is located in gbode_internal_nls.c as we get symbol conflicts with
 *       SUNDIALS BLAS symbols that use long int as index type and are included transitively.
 */
void gbInternalLinearCombinationSVP(STAGE_VALUE_PREDICTORS *svp,
                                    int active_stage,
                                    int nStates,
                                    double stepSize,
                                    const double *K,
                                    const double *y0,
                                    double *ypred)
{
  memcpy(ypred, y0, nStates * sizeof(double));

  dgemv_(
    &CHAR_NO_TRANS,
    &nStates,
    &active_stage,
    &stepSize, K, &nStates,
    &svp->A_predictor[active_stage * svp->nStages], &INT_ONE,
    &DBL_ONE, ypred, &INT_ONE
  );
}

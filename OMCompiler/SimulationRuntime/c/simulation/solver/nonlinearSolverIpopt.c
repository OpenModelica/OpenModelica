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

/*! \file nonlinearSolverIpopt.c
 *
 * Solve a nonlinear system g(z) = 0 with the IPOPT interior-point solver, using
 * the min/max attributes of the unknowns as box constraints z_L <= z <= z_U.
 * The residuals are passed to IPOPT as equality constraints (g_L = g_U = 0) and
 * the objective is a constant. IPOPT's logarithmic-barrier method is generally
 * more robust to poor initial guesses than a plain Newton/Hybrid solver, so this
 * is offered as a fallback (and, via -initNlsIpopt, as a direct solver). See
 * ticket #14104.
 */

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <float.h>

#include "nonlinearSolverIpopt.h"
#include "../../util/omc_error.h"
#include "../../meta/meta_modelica.h"
#include "../jacobian_util.h"
#include "nonlinearSystem.h"

#ifdef OMC_HAVE_IPOPT

#include <IpStdCInterface.h>

/* Bounds with magnitude >= this are treated by IPOPT as +/- infinity. */
#define IPOPT_NLS_INF 2e19

typedef struct IPOPT_NLS_USERDATA {
  DATA* data;
  threadData_t* threadData;
  NONLINEAR_SYSTEM_DATA* nlsData;
  int n;
  double* scale;    /* per-variable scale; IPOPT works on z = x/scale (x ~ O(1)) */
  double* resScale; /* per-equation scale; IPOPT sees g_i/resScale_i (~ O(1))    */
  double* xPhys;    /* physical point x = scale .* z, passed to the residual */
  double* gBase;    /* residual at the base point, reused for finite differences */
  double* xWork;    /* perturbed physical point buffer for finite differences */
  JACOBIAN* jacobian; /* analytic Jacobian (else NULL) */
  double* jacBuf;   /* nnz buffer for the sparse analytic Jacobian values */
  const SPARSE_PATTERN* fdPattern; /* sparsity for colored finite differences (else NULL) */
  const double* xL; /* scaled lower bounds (for bound-aware FD steps) */
  const double* xU; /* scaled upper bounds */
} IPOPT_NLS_USERDATA;

/**
 * @brief Evaluate the residual g(x); returns 1 on success, 0 if an assertion or
 *        division-by-zero was raised during the evaluation (caught here so it
 *        does not longjmp out of the IPOPT callback).
 */
static int nlsIpoptResidual(IPOPT_NLS_USERDATA* ud, const double* x, double* g)
{
  NONLINEAR_SYSTEM_DATA* nlsData = ud->nlsData;
  threadData_t* threadData = ud->threadData;
  RESIDUAL_USERDATA resUserData = {.data = ud->data, .threadData = ud->threadData, .solverData = NULL};
  int iflag = 0;
  int ok = 0;

#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
  nlsData->residualFunc(&resUserData, x, g, &iflag);
  ok = 1;
#ifndef OMC_EMCC
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  /* Reject non-finite residuals (e.g. NaN returned by a medium property outside
   * its valid range) as a failed evaluation, so IPOPT backtracks instead of
   * aborting with Invalid_Number_Detected. */
  if (ok) {
    int i;
    for (i = 0; i < ud->n; i++) {
      if (!isfinite(g[i])) { ok = 0; break; }
    }
  }

  return ok;
}

/* IPOPT callback: constant objective (we only want feasibility g(z) = 0). */
static bool nlsIpopt_f(ipindex n, ipnumber* x, bool new_x, ipnumber* obj_value, UserDataPtr user_data)
{
  (void)n; (void)x; (void)new_x; (void)user_data;
  *obj_value = 0.0;
  return true;
}

/* IPOPT callback: gradient of the constant objective is zero. */
static bool nlsIpopt_grad_f(ipindex n, ipnumber* x, bool new_x, ipnumber* grad_f, UserDataPtr user_data)
{
  int i;
  (void)x; (void)new_x; (void)user_data;
  for (i = 0; i < n; i++) grad_f[i] = 0.0;
  return true;
}

/* IPOPT callback: scaled constraints g_i(z) = residual_i(scale .* z) / resScale_i. */
static bool nlsIpopt_g(ipindex n, ipnumber* x, bool new_x, ipindex m, ipnumber* g, UserDataPtr user_data)
{
  IPOPT_NLS_USERDATA* ud = (IPOPT_NLS_USERDATA*) user_data;
  int i;
  (void)new_x;
  for (i = 0; i < n; i++) ud->xPhys[i] = x[i] * ud->scale[i];
  if (!nlsIpoptResidual(ud, ud->xPhys, g)) return false;
  for (i = 0; i < m; i++) g[i] /= ud->resScale[i];
  return true;
}

/* Evaluate the analytic Jacobian dF/dx at the current model state into ud->jacBuf
 * (sparse CSC, nnz values). Returns 1 on success, 0 on assertion / non-finite. */
static int nlsIpoptAnalyticJac(IPOPT_NLS_USERDATA* ud)
{
  threadData_t* threadData = ud->threadData;
  int ok = 0;

#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
  evalJacobian(ud->data, ud->threadData, ud->jacobian, NULL, ud->jacBuf, 0 /* sparse CSC */);
  ok = 1;
#ifndef OMC_EMCC
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (ok) {
    int i, nnz = (int) ud->jacobian->sparsePattern->nnz;
    for (i = 0; i < nnz; i++) {
      if (!isfinite(ud->jacBuf[i])) { ok = 0; break; }
    }
  }
  return ok;
}

/* Single-column finite difference into the sparse value array (CSC positions),
 * trying forward then backward; leaves the column at zero if both fail. Used as
 * the per-column fall-back when a colored joint perturbation lands in an invalid
 * region. Assumes ud->xWork currently equals the base physical point. */
static void nlsIpoptFdColumn(IPOPT_NLS_USERDATA* ud, const double* x, int col,
                             const SPARSE_PATTERN* sp, const double* g0, double* values)
{
  double* g1 = ud->gBase + ud->n;
  double h = 1e-8 * (1.0 + fabs(x[col]));
  double sgn;
  int nz, ok = 0;

  for (sgn = 1.0; sgn >= -1.0 && !ok; sgn -= 2.0) {
    ud->xWork[col] = (x[col] + sgn * h) * ud->scale[col];
    if (nlsIpoptResidual(ud, ud->xWork, g1)) {
      for (nz = sp->leadindex[col]; nz < (int) sp->leadindex[col + 1]; nz++) {
        int row = sp->index[nz];
        values[nz] = (g1[row] - g0[row]) / (sgn * h) / ud->resScale[row];
      }
      ok = 1;
    }
  }
  ud->xWork[col] = x[col] * ud->scale[col]; /* restore */
  if (!ok) {
    for (nz = sp->leadindex[col]; nz < (int) sp->leadindex[col + 1]; nz++) values[nz] = 0.0;
  }
}

/* IPOPT callback: Jacobian of the constraints. Uses, in order of preference, the
 * analytic sparse Jacobian (CSC), colored sparse finite differences, or dense
 * finite differences. The scaled entry is
 * d g_row / d z_col = (dF_row/dx_col) * scale_col / resScale_row. */
static bool nlsIpopt_jac_g(ipindex n, ipnumber* x, bool new_x, ipindex m, ipindex nele_jac,
                           ipindex* iRow, ipindex* jCol, ipnumber* values, UserDataPtr user_data)
{
  IPOPT_NLS_USERDATA* ud = (IPOPT_NLS_USERDATA*) user_data;
  double* g0 = ud->gBase;       /* residual at the base point      */
  double* g1 = ud->gBase + n;   /* residual at the perturbed point */
  int i, j;
  (void)new_x; (void)nele_jac;

  /* ---- analytic sparse Jacobian ---- */
  if (ud->jacobian != NULL) {
    const SPARSE_PATTERN* sp = ud->jacobian->sparsePattern;
    int col, nz, k = 0;

    if (values == NULL) {
      /* sparsity structure in CSC order (column by column) */
      for (col = 0; col < n; col++) {
        for (nz = sp->leadindex[col]; nz < (int) sp->leadindex[col + 1]; nz++) {
          iRow[k] = sp->index[nz];
          jCol[k] = col;
          k++;
        }
      }
      return true;
    }

    /* set the model state to x, then evaluate the analytic Jacobian there */
    for (i = 0; i < n; i++) ud->xPhys[i] = x[i] * ud->scale[i];
    if (!nlsIpoptResidual(ud, ud->xPhys, g0)) return false;
    if (!nlsIpoptAnalyticJac(ud)) return false;

    for (col = 0; col < n; col++) {
      for (nz = sp->leadindex[col]; nz < (int) sp->leadindex[col + 1]; nz++) {
        int row = sp->index[nz];
        values[k++] = ud->jacBuf[nz] * ud->scale[col] / ud->resScale[row];
      }
    }
    return true;
  }

  /* ---- colored sparse finite differences ---- */
  if (ud->fdPattern != NULL) {
    const SPARSE_PATTERN* sp = ud->fdPattern;
    int col, nz, k = 0, color;

    if (values == NULL) {
      for (col = 0; col < n; col++) {
        for (nz = sp->leadindex[col]; nz < (int) sp->leadindex[col + 1]; nz++) {
          iRow[k] = sp->index[nz];
          jCol[k] = col;
          k++;
        }
      }
      return true;
    }

    for (i = 0; i < n; i++) ud->xPhys[i] = x[i] * ud->scale[i];
    if (!nlsIpoptResidual(ud, ud->xPhys, g0)) return false;
    memcpy(ud->xWork, ud->xPhys, n * sizeof(double));

    /* one residual evaluation per color: perturb every column of that color at
     * once (their row patterns do not overlap, so the differences are unambiguous) */
    for (color = 0; color < (int) sp->maxColors; color++) {
      for (col = 0; col < n; col++) {
        if ((int) sp->colorCols[col] - 1 == color) {
          double h = 1e-8 * (1.0 + fabs(x[col]));
          /* step backward instead if a forward step would leave the upper bound */
          if (x[col] + h > ud->xU[col]) h = -h;
          ud->xWork[col] = (x[col] + h) * ud->scale[col];
        }
      }
      if (nlsIpoptResidual(ud, ud->xWork, g1)) {
        for (col = 0; col < n; col++) {
          if ((int) sp->colorCols[col] - 1 == color) {
            double h = 1e-8 * (1.0 + fabs(x[col]));
            if (x[col] + h > ud->xU[col]) h = -h;
            for (nz = sp->leadindex[col]; nz < (int) sp->leadindex[col + 1]; nz++) {
              int row = sp->index[nz];
              values[nz] = (g1[row] - g0[row]) / h / ud->resScale[row];
            }
            ud->xWork[col] = ud->xPhys[col]; /* restore */
          }
        }
      } else {
        /* joint perturbation hit an invalid region; redo this color column by column */
        for (col = 0; col < n; col++) {
          if ((int) sp->colorCols[col] - 1 == color) {
            ud->xWork[col] = ud->xPhys[col]; /* restore before single-column FD */
          }
        }
        for (col = 0; col < n; col++) {
          if ((int) sp->colorCols[col] - 1 == color) {
            nlsIpoptFdColumn(ud, x, col, sp, g0, values);
          }
        }
      }
    }
    return true;
  }

  /* ---- dense finite-difference Jacobian (fallback) ---- */
  if (values == NULL) {
    /* return the (dense) sparsity structure, row-major: entry (i, j) at i*n + j */
    int k = 0;
    for (i = 0; i < m; i++) {
      for (j = 0; j < n; j++) {
        iRow[k] = i;
        jCol[k] = j;
        k++;
      }
    }
    return true;
  }

  /* finite differences with respect to the scaled variables z:
   * d g_i / d z_j = (g_i(x + scale_j*h e_j) - g_i(x)) / h.
   * If a forward step lands in an invalid region (non-finite residual) try a
   * backward step; if both fail, leave that column at zero rather than failing
   * the whole Jacobian, so IPOPT can still make progress. */
  for (i = 0; i < n; i++) ud->xPhys[i] = x[i] * ud->scale[i];
  if (!nlsIpoptResidual(ud, ud->xPhys, g0)) return false;
  memcpy(ud->xWork, ud->xPhys, n * sizeof(double));

  for (j = 0; j < n; j++) {
    double h = 1e-8 * (1.0 + fabs(x[j]));   /* step in scaled space */
    double sgn;
    int ok = 0;
    for (sgn = 1.0; sgn >= -1.0 && !ok; sgn -= 2.0) { /* try forward then backward */
      ud->xWork[j] = (x[j] + sgn * h) * ud->scale[j];
      if (nlsIpoptResidual(ud, ud->xWork, g1)) {
        for (i = 0; i < m; i++) values[i * n + j] = (g1[i] - g0[i]) / (sgn * h) / ud->resScale[i];
        ok = 1;
      }
    }
    ud->xWork[j] = ud->xPhys[j];
    if (!ok) {
      for (i = 0; i < m; i++) values[i * n + j] = 0.0;
    }
  }
  return true;
}

/* IPOPT callback: Hessian of the Lagrangian. Never actually evaluated because
 * we request the limited-memory (quasi-Newton) Hessian approximation, but the C
 * interface requires a non-NULL pointer at problem creation. */
static bool nlsIpopt_h(ipindex n, ipnumber* x, bool new_x, ipnumber obj_factor, ipindex m,
                       ipnumber* lambda, bool new_lambda, ipindex nele_hess,
                       ipindex* iRow, ipindex* jCol, ipnumber* values, UserDataPtr user_data)
{
  (void)n; (void)x; (void)new_x; (void)obj_factor; (void)m; (void)lambda;
  (void)new_lambda; (void)nele_hess; (void)iRow; (void)jCol; (void)values; (void)user_data;
  return false; /* not provided; limited-memory approximation is used instead */
}

NLS_SOLVER_STATUS solveNlsIpopt(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nlsData)
{
  int n = (int) nlsData->size;
  int i;
  int nele_jac;
  IpoptProblem nlp = NULL; /* see nlsIpopt_h for the Hessian stub */
  IPOPT_NLS_USERDATA ud;
  double *x_L, *x_U, *g_L, *g_U, *x;
  double obj = 0.0;
  enum ApplicationReturnStatus status;
  NLS_SOLVER_STATUS result = NLS_FAILED;
  int savedNoThrowDivZero = data->simulationInfo->noThrowDivZero;

  x_L = (double*) malloc(n * sizeof(double));
  x_U = (double*) malloc(n * sizeof(double));
  g_L = (double*) malloc(n * sizeof(double));
  g_U = (double*) malloc(n * sizeof(double));
  x   = (double*) malloc(n * sizeof(double));   /* scaled variables z passed to IPOPT */
  /* gBase holds [g0 (n) | g1 (n)] so the finite-difference code can keep both */
  ud.gBase = (double*) malloc(2 * n * sizeof(double));
  ud.xWork = (double*) malloc(n * sizeof(double));
  ud.xPhys = (double*) malloc(n * sizeof(double));
  ud.scale = (double*) malloc(n * sizeof(double));
  ud.resScale = (double*) malloc(n * sizeof(double));
  ud.data = data;
  ud.threadData = threadData;
  ud.nlsData = nlsData;
  ud.n = n;

  /* Choose the Jacobian, in order of preference:
   *   1. analytic sparse Jacobian (CSC) when the system provides one,
   *   2. colored sparse finite differences when a sparsity pattern is available,
   *   3. dense finite differences otherwise. */
  ud.jacobian = NULL;
  ud.jacBuf = NULL;
  ud.fdPattern = NULL;
  if (nlsData->jacobianIndex != -1) {
    JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[nlsData->jacobianIndex]);
    if (jac->sparsePattern != NULL && (int) jac->sizeCols == n && (int) jac->sizeRows == n) {
      ud.jacobian = jac;
      ud.jacBuf = (double*) malloc(jac->sparsePattern->nnz * sizeof(double));
    }
  }
  if (ud.jacobian == NULL && nlsData->isPatternAvailable && nlsData->sparsePattern != NULL
      && nlsData->sparsePattern->colorCols != NULL && nlsData->sparsePattern->maxColors >= 1
      && nlsData->sparsePattern->nnz > 0) {
    ud.fdPattern = nlsData->sparsePattern;
  }
  if (ud.jacobian != NULL) {
    nele_jac = (int) ud.jacobian->sparsePattern->nnz;
  } else if (ud.fdPattern != NULL) {
    nele_jac = (int) ud.fdPattern->nnz;
  } else {
    nele_jac = n * n;
  }

  /* IPOPT works on the scaled variables z = x / scale so that they are of order
   * one (these systems are often badly scaled, e.g. pressures ~1e6 next to
   * temperatures ~3e2). scale is the nominal magnitude of each unknown. */
  for (i = 0; i < n; i++) {
    /* a failed previous solve may have left a non-finite iteration value; fall
     * back to the nominal value (or 0) so the start point and scaling are sane */
    double x0 = isfinite(nlsData->nlsx[i]) ? nlsData->nlsx[i]
              : (isfinite(nlsData->nominal[i]) ? nlsData->nominal[i] : 0.0);
    double nom = isfinite(nlsData->nominal[i]) ? nlsData->nominal[i] : 0.0;
    double s = fmax(fabs(x0), fabs(nom));
    if (!(s > 0.0)) s = 1.0;
    ud.scale[i] = s;

    x_L[i] = (nlsData->min[i] <= -DBL_MAX) ? -IPOPT_NLS_INF : nlsData->min[i] / s;
    x_U[i] = (nlsData->max[i] >=  DBL_MAX) ?  IPOPT_NLS_INF : nlsData->max[i] / s;
    g_L[i] = 0.0;
    g_U[i] = 0.0;
    ud.resScale[i] = 1.0;   /* refined below from the initial residual magnitude */
    /* start from the (sanitized) current iteration values (scaled), projected into the bounds */
    x[i] = x0 / s;
    if (x[i] < x_L[i]) x[i] = x_L[i];
    if (x[i] > x_U[i]) x[i] = x_U[i];
  }
  ud.xL = x_L;   /* used by the colored finite differences for bound-aware steps */
  ud.xU = x_U;

  /* Equation scaling: divide each residual by the magnitude of the initial
   * residual so the equations are of order one (these systems often have
   * residuals spanning many orders of magnitude). */
  for (i = 0; i < n; i++) ud.xPhys[i] = x[i] * ud.scale[i];
  if (nlsIpoptResidual(&ud, ud.xPhys, ud.gBase)) {
    for (i = 0; i < n; i++) ud.resScale[i] = fmax(fabs(ud.gBase[i]), 1.0);
  }

  /* nele_jac entries (sparse analytic or dense FD), no Hessian (limited-memory) */
  nlp = CreateIpoptProblem(n, x_L, x_U, n, g_L, g_U, nele_jac, 0, 0,
                           &nlsIpopt_f, &nlsIpopt_g, &nlsIpopt_grad_f, &nlsIpopt_jac_g, &nlsIpopt_h);

  if (nlp == NULL) {
    warningStreamPrint(OMC_LOG_NLS, 0, "IPOPT nonlinear solver: failed to create the problem for system %d.",
                       (int) nlsData->equationIndex);
    free(x_L); free(x_U); free(g_L); free(g_U); free(x);
    free(ud.gBase); free(ud.xWork); free(ud.xPhys); free(ud.scale); free(ud.resScale); free(ud.jacBuf);
    return NLS_FAILED;
  }

  AddIpoptStrOption(nlp, "hessian_approximation", "limited-memory");
  AddIpoptStrOption(nlp, "sb", "yes");                 /* suppress the IPOPT banner */
  AddIpoptStrOption(nlp, "mu_strategy", "adaptive");
  AddIpoptIntOption(nlp, "print_level", OMC_ACTIVE_STREAM(OMC_LOG_NLS_V) ? 5 : 0);
  AddIpoptNumOption(nlp, "tol", 1e-12);
  AddIpoptNumOption(nlp, "constr_viol_tol", 1e-10);
  AddIpoptNumOption(nlp, "acceptable_tol", 1e-8);
  AddIpoptNumOption(nlp, "acceptable_constr_viol_tol", 1e-8);

  /* Evaluate residuals in continuous mode. Let numerical/domain errors throw
   * (noThrowDivZero = 0) so they are caught in nlsIpoptResidual() and reported to
   * IPOPT as a failed evaluation (return false); IPOPT then backtracks, instead
   * of a NaN poisoning the solve (which IPOPT reports as Invalid_Number). */
  data->simulationInfo->solveContinuous = 1;
  data->simulationInfo->noThrowDivZero = 0;

  if (ud.fdPattern != NULL) {
    infoStreamPrint(OMC_LOG_NLS, 0, "Solving nonlinear system %d with IPOPT (size %d, colored sparse "
                    "finite-difference Jacobian, %d entries, %d colors).",
                    (int) nlsData->equationIndex, n, nele_jac, (int) ud.fdPattern->maxColors);
  } else {
    infoStreamPrint(OMC_LOG_NLS, 0, "Solving nonlinear system %d with IPOPT (size %d, %s Jacobian, %d entries).",
                    (int) nlsData->equationIndex, n,
                    ud.jacobian != NULL ? "analytic sparse" : "dense finite-difference", nele_jac);
  }

  status = IpoptSolve(nlp, x, NULL, &obj, NULL, NULL, NULL, (UserDataPtr) &ud);
  data->simulationInfo->noThrowDivZero = savedNoThrowDivZero;

  if (status == Solve_Succeeded || status == Solved_To_Acceptable_Level) {
    /* unscale the solution z back to physical variables x = scale .* z */
    for (i = 0; i < n; i++) nlsData->nlsx[i] = x[i] * ud.scale[i];
    /* evaluate the residual once more at the solution so the model variables are
     * left consistent with the returned solution (IPOPT's last evaluation may
     * have been at a trial point) */
    nlsIpoptResidual(&ud, nlsData->nlsx, ud.gBase);
    result = NLS_SOLVED;
    infoStreamPrint(OMC_LOG_NLS, 0, "IPOPT solved nonlinear system %d (status %d).",
                    (int) nlsData->equationIndex, (int) status);
  } else {
    warningStreamPrint(OMC_LOG_NLS, 0, "IPOPT did not solve nonlinear system %d (status %d).",
                       (int) nlsData->equationIndex, (int) status);
  }

  FreeIpoptProblem(nlp);
  free(x_L); free(x_U); free(g_L); free(g_U); free(x);
  free(ud.gBase); free(ud.xWork); free(ud.xPhys); free(ud.scale); free(ud.resScale); free(ud.jacBuf);
  return result;
}

#else /* !OMC_HAVE_IPOPT */

NLS_SOLVER_STATUS solveNlsIpopt(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nlsData)
{
  (void)data; (void)threadData;
  warningStreamPrint(OMC_LOG_NLS, 0,
    "IPOPT nonlinear solver requested for system %d, but this runtime was built without IPOPT support.",
    (int) nlsData->equationIndex);
  return NLS_FAILED;
}

#endif /* OMC_HAVE_IPOPT */

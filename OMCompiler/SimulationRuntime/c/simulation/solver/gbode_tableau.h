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

/*! \file gbode_tableau.h
 *
 * Containing Butcher tableau for generic Runge-Kutta methods.
 */

#ifndef GBODE_TABLEAU_H
#define GBODE_TABLEAU_H

#include "../../util/simulation_options.h"
#include "../../openmodelica_types.h"

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct BUTCHER_TABLEAU BUTCHER_TABLEAU;
typedef struct GB_ERROR_ESTIMATOR GB_ERROR_ESTIMATOR;
typedef struct GB_ERROR_CONTEXT GB_ERROR_CONTEXT;

/**
 * @brief Function to compute interpolation using dense output.
 */
typedef void (*gb_dense_output)(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates);

/**
 * @brief Function to compute variable-step two-step weights.
 *
 * The weights always act in K-space:
 *     y_emb = y_n + h_old * d_old(r)^T * K_old + h_new * g_new(r)^T * K_new,
 * where r = h_new / h_old.
 * The callback also returns mu(r), used by the estimate as
 *     err = mu(r) * (y_main - y_emb).
 */
typedef void (*gb_two_step_weights)(double r, double *d_old, double *g_new, double *mu);

/**
 * @brief General error estimator interface function.
 */
typedef int (*gb_error_estimator_fn)(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator);

#define GB_ERROR_ESTIMATOR_FAILED -1

// some macros for stack arrays
#define MAX_GBODE_STAGES 35
#define MAX_GBODE_FIRK_STAGES 8

// accessor for t_transform->L fields
#define GBODE_L_INDEX(row, col) (((row) * ((row) - 1)) / 2 + (col))

/**
 * @brief Data for contractive defect error estimates (requires T-Transformation + internal NLS strategy).
 *
 * Error estimates for superconvergent FIRK methods are extremely difficult as an embedded method can obtain a
 * maximum order of s-1 for s stages, while the methods have order 2s (Gauss), 2s-1 (Radau), 2s-2 (Lobatto). This
 * leads to poor and non-A-stable error estimates.
 *
 * However, for collocation methods with at least one real eigenvalue (gamma) and 0 as a non-collocated point, we can get
 * an A-stable error estimate of order s by using one additional function evaluation and one LU-solve:
 *
 *    ERR = (I - h * gamma * J)^(-1) * h * gamma * (f(x0, y0) - d(0)^T * A * k),
 *
 * where d(0) are the weights of the differentiation matrix at node 0.
 *
 * Note that the LU decomposition of (1 / (h * gamma ) * I - * J)^(-1) is already available from the Newtion iteration, so we actually just compute
 *
 *    ERR = (1 / (h * gamma) * I - J)^(-1) * (f(x0, y0) - d(0)^T * A * k).

 * One extension could be to perform another contraction, i.e. ERR_2 := (I - h * gamma * J)^(-1) * h * gamma * (f(x0 + u * h, y0 + h * ERR) - d(0)^T * A * k),
 * which is L-stable for Gauss, Radau. Clearly, this would be double the cost.
 *
 * For theory of these estimates refer to
 *     Shampine & Baka "Error estimators for stiff differential equations" (original literature),
 *     Hairer & Wanner pp.123 "Solving Ordinary Differential Equations II" (Radau IIA estimate),
 *     Gonzalez-Pinto et al. "Two-step error estimators for implicit Runge-Kutta methods applied to stiff systems" (gives an overview of such ideas and
 *                                                                                                                  an alternative 2-step estimator),
 */
typedef struct CONTRACTIVE_DEFECT {
  /**
   * @brief Weights d(0)^T * A for the K-space defect f(t_n, y_n) - d(0)^T * A * K.
   */
  double *dT_A;
} CONTRACTIVE_DEFECT;

/**
 * @brief Data for variable-step two-step error estimates, in the spirit of Gonzalez-Pinto et al.
 *        "Two-step error estimators for implicit Runge-Kutta methods applied to stiff systems".
 *
 * Uses the stage derivatives from the previous accepted step and the current step.
 * With r = h / h_old, the generated K-space weights form
 *    y_emb = y_n + h_old * sum_i d_i(r) * K_old_i + h * sum_i g_i(r) * K_i,
 *
 * and the estimator writes abs(mu(r) * (y_{n+1} - y_emb)) directly to errest.
 *
 * The pole-free weights d and g are constructed such that the estimator has a fixed
 * exact order for all r > 0, without degenerate points of higher or lower order.
 *
 *    The calibration for the factor mu(r) is done as follows:
 *
 * For the linear test equation, the exact local error of the main method is
 *    E_exact(z) = abs(R(z) - exp(z)).
 *
 * An ideal I-controller based on this exact error would use the feedback signal
 *    S_exact = (TOL / E_exact(z))^(1 / (p + 1)).
 *
 * The two-step estimator gives
 *    E_est(z,r) = abs(y_{n+1} - y_emb),
 *
 * and therefore the controller feedback is
 *    S_est = (TOL_ref' / (abs(mu(r)) * E_est(z,r)))^(1 / (q + 1)).
 *
 * We compare S_est and S_exact with the reference tolerance scaling
 *    TOL_ref' = TOL^a,  a = (q + 1) / (p + 1),
 *
 * so the powers of TOL cancel in S_est / S_exact. This ratio is then studied as
 * a function of r > 0 and z in the complex plane. Ideally it would be globally constant 1, but
 * this is impossible; values <= 1 mean that the estimator proposes no larger step than the exact-error controller.
 *
 * The scalar mu(r) is calibrated from the non-stiff Taylor expansion of this
 * controller-feedback ratio. For z -> 0,
 *    E_exact(z) = abs(C_main * z^(p + 1)) + ...
 *    E_est(z,r) = abs(C_est(r) * z^(q + 1)) + ...
 *
 * and setting S_est / S_exact = target for the leading term gives
 *    abs(mu(r) * C_est(r)) = abs(C_main)^a / target^(q + 1).
 *
 * Hence mu(r) = scale / abs(C_est(r)). If C_est(r) = N(r) / D(r), the generated C table stores this as
 *    mu(r) = scale * abs(D(r) / N(r)).
 *
 * Thus mu(r) removes the step-ratio dependence of the leading non-stiff controller feedback. Gonzalez-Pinto et al.
 * achieve the same leading cancellation by modifying the error controller. Here we treat it as a property of
 * the error estimate itself: the estimate is scaled before it is passed to a standard controller.
 *
 * The full ratio S_est / S_exact is checked in the relevant complex-plane regions, especially z -> 0, Re(z) < 0,
 * and a small strip into Re(z) > 0, to detect underestimation away from the leading non-stiff term.
 *
 * The tabulated mu(r) is independent of the numerical tolerance. Since GBODE uses another scaled tolerance, twoStepScaleMu()
 * maps the table value to that runtime convention by multiplying with gbScaledErrorTolerance(...) / TOL_ref'.
 *
 * If no valid previous step is available, e.g. at startup or after events, the
 * one-step fallback estimator is used.
 */
typedef struct TWO_STEP_ESTIMATOR
{
  /**
   * @brief Callback evaluating d_old(r), g_new(r), and mu(r) for K-space two-step estimates.
   */
  gb_two_step_weights weights;

  /**
   * @brief One-step estimator used when no previous step is available.
   */
  const GB_ERROR_ESTIMATOR *fallback;
} TWO_STEP_ESTIMATOR;

struct GB_ERROR_ESTIMATOR
{
  enum GB_ERROR_METHOD type;
  int order;

  gb_error_estimator_fn evaluate;
  void *data;
};

typedef struct GB_ERROR_ESTIMATOR_SET
{
  GB_ERROR_ESTIMATOR active;
  GB_ERROR_ESTIMATOR embedded;
  GB_ERROR_ESTIMATOR contractive_defect;
  GB_ERROR_ESTIMATOR contractive_filter;
  GB_ERROR_ESTIMATOR two_step;
} GB_ERROR_ESTIMATOR_SET;

/**
 * @brief Transformation structures for decoupling fully implicit Runge–Kutta systems.
 *
 * Fully implicit Runge–Kutta (FIRK) schemes require solving a coupled system of
 * size (S * N) x (S * N), where S is the number of stages and N is the number
 * of ODE states, which is (almost impractically) costly.
 *
 * The T-transformation (T^{-1} * A^{-1} * T = Lambda + L) diagonalizes (L = 0, Lambda = diagonal), block-diagonalizes (L = 0, Lambda contains cmplx blocks),
 * or lower block-triangularizes (L != 0, Lambda = diagonal or block-diagonal) the Runge–Kutta coefficient matrix A, converting the single
 * large system into several sequential N x N systems. The diagonal blocks are solved either as:
 *   - real-valued systems (for real eigenvalues of A^{-1}), or
 *   - 2×2 real block systems (for complex conjugate eigenpairs of A^{-1})
 *     Exploiting complex arithmetic, work can be further reduced
 *     for complex conjugate eigenpairs to a single N × N system.
 *
 * For dense systems, this T-transformation avoids the O((S * N)^3) cost of solving the fully
 * coupled system and instead reduces the work to
 *    C * S * O(N^3), with C <= 2 + an neglectable transformation overhead of O(S^2 * N).
 *    For example, 3-step RadauIIA: 27 * N^3 -> 5 * N^3; 6-step Gauss: 216 * N^3 -> 12 * N^3
 *
 * For methods with explicit stages (e.g. Lobatto IIIA/IIIB), only the implicit
 * parts are transformed and solved via T; explicit stages are evaluated normally.
 * Thus, the system we transform is only of size S_r = size member in T_TRANSFORM.
 *
 * @attention The T, T^{-1} and Lambda(alpha, beta, gamma) + L matrices must be permutated such that
 *            real scalar rows come first and complex 2x2 blocks follow. Any additional coupling is stored
 *            in the strict lower triangular L and is handled by forward substitution:
 *
 *            *
 *               *  *
 *               *  *       = Lambda of Gauss 5-step (2 complex blocks, 1 real block)
 *                    *  *
 *                    *  *
 *            *                0 0 0 0 0 0
 *               *             * 0 0 0 0 0
 *                  *       +  * * 0 0 0 0 = (Lambda + L) of 5-step FIRK7(6)5L[4]SA (triple Jordan single real eigenvalue with L contribution + 1 complex block)
 *                    *  *     0 0 0 0 0 0
 *                    *  *     0 0 0 0 0 0
 *
 */
typedef struct T_TRANSFORM {
  /**
   * @brief Inverse of the Runge-Kutta matrix (used for mapping Z -> K)
   *        If A is not invertible, this is only the invertible part of A.
   *        For the standard methods A_part_inv = A_part^{-1} is given by:
   *          - Gauss, RadauIA, RadauIIA, LobattoIIIC are invertible: A^{-1} = A_part_inv
   *          - LobattoIIIA: A(2:s, 2:s)^{-1} = A_part_inv (bottom right square, first stage explicit)
   *          - LobattoIIIB: A(1:s-1, 1:s-1)^{-1} = A_part_inv (top left square, last stage explicit)
   *          - LobattoIIIC*: A(2:s-1, 2:s-1)^{-1} = A_part_inv (middle square: remove first and last rows and cols from A,
   *                                                             first and last stage explicit)
   *
   * Stored row-major, dimension S_r × S_r.
   */
  double *A_part_inv;

  /**
   * @brief Inverse transformation matrix T^{-1} such that:
   *        vec(W) = (T_inv otimes I_N) * vec(Z)
   *
   * Maps the coupled stage vector Z into the decoupled stage vector W.
   * Stored row-major, dimension S_r × S_r.
   */
  double *T_inv;

  /**
   * @brief Transformation matrix T such that:
   *        vec(Z) = (T otimes I_N) * vec(W)
   *
   * Reconstructs the coupled stage values from the decoupled values.
   * Stored row-major, dimension S_r × S_r.
   */
  double *T;

  /**
   * @brief Unique real eigenvalues of A^{-1} for real scalar rows.
   *
   * Size: nRealEigenvalues (<= nRealBlocks). Repeated real rows point to these entries via realEigenvalueIndex.
   */
  double *gamma;

  /**
   * @brief Unique real parts of complex eigenvalues of A^{-1} (for complex pairs).
   *
   * Size: nComplexEigenpairs (<= nComplexBlocks). Paired with `beta` to form conjugate pairs
   * (alpha, beta) and (alpha, -beta) which produce 2×2 real block systems or a 1x1 complex system in the decoupled basis.
   */
  double *alpha;

  /**
   * @brief Unique imaginary parts of complex eigenvalues of A^{-1}.
   *
   * Size: nComplexEigenpairs.
   */
  double *beta;

  /**
   * @brief Maps real rows and complex 2x2 blocks to the unique eigenvalue/factorization.
   *
   * realEigenvalueIndex has size nRealBlocks, complexEigenpairIndex has size nComplexBlocks.
   */
  int *realEigenvalueIndex;
  int *complexEigenpairIndex;

  /**
   * @brief Strict lower triangular coupling of T^{-1} * A_part^{-1} * T after extracting real/complex diagonal blocks.
   *
   * Stored packed lower triangular: L[GBODE_L_INDEX(row, col)] == L(row, col), col < row.
   * hasL[row] is true if row has any non-zero lower coupling and should be applied.
   */
  double *L;
  modelica_boolean *hasL;

  /**
   * @brief Factor for weighting the residual k1. If firstRowZero, then stage 1 is explicit and we need to
   *        weight the k1 vector with this phi vector in the residual of the decoupled system.
   *              phi := T^{-1} * A_part^{-1} * A_{r,1} = -T^{-1} * rho, where r are all rows that belong to A_part.
   *
   * Size: S - 1.
   */
  double *phi;

  /**
  * @brief Offset for reconstructing K when the first stage is explicit.
  *        rho = -A_part_inv * A_{r,1} = -T * phi; used in
  *        K_{r} = (1/h) * A_part_inv * Z + rho * k1, where r are all rows that belong to A_part.
  *
  * Size: S - 1.
  */
  double *rho;

  /**
   * @brief True if the first stage is explicit, i.e. a_{1,:} == 0 (e.g. in Lobatto IIIA).
   *
   * When true, the first stage does not need to be included in the implicit
   * decoupled solve and can be evaluated explicitly.
   */
  modelica_boolean firstRowZero;

  /**
   * @brief True if the last stage is explicit and not involved in the NLS, i.e. a_{:,s} == 0 (e.g. in Lobatto IIIB).
   */
  modelica_boolean lastColumnZero;

  /**
   * @brief Number of unique real eigenvalues / complex eigenpairs.
   */
  int nRealEigenvalues;
  int nComplexEigenpairs;

  /**
   * @brief Number of real eigenvalue and complex eigenpair blocks in the diagonalization. (also counting repeated eigenvalues)
   */
  int nRealBlocks;
  int nComplexBlocks;

  /**
   * @brief Size S_r of the T-transformations size_{transform} = #stages - int(explicit_first) - int(explicit_last)
   */
  int size;
} T_TRANSFORM;

typedef enum STAGE_VALUE_PREDICTOR_TYPE
{
  SVP_NOT_AVAILABLE = 0,
  SVP_LINEAR_COMBINATION = 1,
  SVP_DENSE_OUTPUT = 2
} STAGE_VALUE_PREDICTOR_TYPE;

/**
 * @brief Stage-value predictors (SVPs) for ESDIRK and SDIRK methods
 *
 * As (E)SDIRK methods can be solved sequentially (stage by stage in order),
 * it is possible to get good and stable predictions of the stage k_s by doing a linear
 * combination of the previous stages k_1, ..., k_{s-1}. This can be interpreted as a
 * so-called EDIRK method (see "Intrastep, Stage-Value Predictors for Diagonally-Implicit Runge–Kutta Methods"
 * by Carpenter et al: https://ntrs.nasa.gov/api/citations/20240008442/downloads/NASA-TM-20240008442.pdf).
 *
 * This structure contains the additional explicit EDIRK row for stage s, to predict the (E)SDIRK row s.
 */
typedef struct STAGE_VALUE_PREDICTORS {
  /**
   * @brief Row s of this predictor matrix builds the predicton for stage s of the real system (A_predictor is referred to as beta in the literature):
   *            y_pred^{s} := y0 + h * sum_{i=1}^{s-1} A_predictor[s, i] * k[i]
   *
   * @note We express this predictor such that it outputs y_pred^{s}, as this way we dont need to form k_pred^{s} and then y^{s} from it again.
   */
  double *A_predictor;

  /**
   * @brief Stable dense output SVP. This predictor is not a standard dense output, i.e. a smooth
   *        interpolation of the solution on the last interval, but rather a stable, medium order interpolation
   *        that can be used for extrapolation e.g. for stages 2 or 3 of an ESDIRK method.
   *
   * @note If no dedicated stable dense output exists, one may just keep this as NULL and fallback to standard
   *       dense output / Hermite extrapolation for the stage 2 or 3 guesses.
   */
  gb_dense_output dense_output_predictor;

  /**
   * @brief Stage type for predictors.
   *            type[s] == SVP_NOT_AVAILABLE: no predictor, use default (constant, dense output, Hermite) initial guess
   *            type[s] == SVP_LINEAR_COMBINATION: use row s of `A_predictor` field to form the linear combination guess
   *            type[s] == SVP_DENSE_OUTPUT: use the provided stable `dense_output_predictor` guess.
   */
  STAGE_VALUE_PREDICTOR_TYPE *type;

  /**
   * @brief Number of stages in the original Butcher tableau.
   */
  int nStages;
} STAGE_VALUE_PREDICTORS;

/**
 * @brief Butcher tableau specifiying a Runge-Kutta method.
 *
 * c | A
 * -------
 *   | b
 *   | bt
 *
 *
 *    c_1 | a_1_1   a_1_2   ...   a_1_s
 *    c_2 | a_2_1   a_2_2   ...   a_2_s
 *    c_3 | a_3_1   a_3_2   ...   a_3_s
 *    ... |
 *    c_s | a_s_1   a_s_2   ...   a_s_s
 *    ---------------------------------
 *        | b_1     b_2     ...   b_s
 *        | bt_1    bt_2    ...   bt_s
 */
typedef struct BUTCHER_TABLEAU {
  double *A;                          /* Runge-Kutta matrix A */
  double *b;                          /* Weights vector */
  double *bt;                         /* Weights vector of embedded formula */
  double *b_dt;                       /* Weights vector for dense output */
  double *c;                          /* Nodes vector */
  int nStages;                        /* Number of stages */
  int order_b;                        /* Order of the Runge-Kutta method */
  int order_bt;                       /* Order of the embedded Runge-Kutta method */
  int error_order;                    /* Usually min(order_b, order_bt) */
  double fac;                         /* Security factor for step size control */
  modelica_boolean  richardson;       /* if no embedded version is available, Richardson
                                         extrapolation can be used for step size control */
  modelica_boolean withDenseOutput;   /* Availability of dense output interpolation formulas */
  modelica_boolean isKLeftAvailable;  /* Availability of function values on left hand side */
  modelica_boolean isKRightAvailable; /* Availability of function values on right hand side */
  gb_dense_output dense_output;       /* Generic dense output function */
  T_TRANSFORM *t_transform;           /* T-transformation for FIRK methods */
  STAGE_VALUE_PREDICTORS *svp;        /* Stage-Value-Predictors for (E)SDIRK methods */
  GB_ERROR_ESTIMATOR_SET error;       /* Available and active error estimators */
  enum GB_ERROR_METHOD error_method; /* Requested error estimator */
} BUTCHER_TABLEAU;

/**
 * @brief Type of Runge-Kutta method
 */
enum GM_TYPE {
  GM_TYPE_UNDEF = 0,    /* Undefined type */
  GM_TYPE_EXPLICIT,     /* Explicit: A is lower triangular matrix */
  GM_TYPE_DIRK,         /* Diagonal implicit: A is triangular matrix */
  GM_TYPE_IMPLICIT,     /* Implicit: A has elements above diagonal */
  MS_TYPE_IMPLICIT      /* NEW: Implicit multi-step method, A is completely zero! */
};

/* Function prototypes */

BUTCHER_TABLEAU* initButcherTableau(enum GB_METHOD method, enum _FLAG flag);
void freeButcherTableau(BUTCHER_TABLEAU* tableau);
void finalizeButcherTableauError(BUTCHER_TABLEAU *tableau, enum GB_NLS_METHOD nlsMethod);

void analyseButcherTableau(BUTCHER_TABLEAU* tableau, int nStates, unsigned int* nlSystemSize, enum GM_TYPE* expl);

void printButcherTableau(BUTCHER_TABLEAU* tableau);

#if defined(__cplusplus)
};
#endif

#endif // GBODE_TABLEAU_H

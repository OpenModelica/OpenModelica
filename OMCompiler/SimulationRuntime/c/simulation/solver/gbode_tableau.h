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
/**
 * @brief Function to compute interpolation using dense output.
 */
typedef void (*gb_dense_output)(BUTCHER_TABLEAU* tableau, double* yOld, double* x, double* k, double dt, double stepSize, double* y, int nIdx, int* idx, int nStates);

#define MAX_GBODE_FIRK_STAGES 6

/**
 * @brief Transformation structures for decoupling fully implicit Runge–Kutta systems.
 *
 * Fully implicit Runge–Kutta (FIRK) schemes require solving a coupled system of
 * size (S * N) × (S * N), where S is the number of stages and N is the number
 * of ODE states, which is (almost impractically) costly.
 *
 * The T-transformation (T^{-1} * A^{-1} * T = Lambda) diagonalizes (or block-diagonalizes)
 * the Runge–Kutta coefficient matrix A, converting the single large system into several
 * independent N × N systems. These can be solved either as:
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
 * @attention The T, T^{-1} and the block diagonal Lambda(alpha, beta, gamma) matrices must be permutated such that
 *            the real blocks are in the left upper corner and the complex blocks in right bottom corner:
 *
 *            *
 *               *  *
 *               *  *       = Lambda of Gauss 5-step (2 complex blocks, 1 real block)
 *                    *  *
 *                    *  *
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
   * @brief Real eigenvalues of A^{-1} for modes that diagonalize to real scalars.
   *
   * Size: nRealEigenvalues (<= S_r).
   */
  double *gamma;

  /**
   * @brief Real parts of complex eigenvalues of A^{-1} (for complex pairs).
   *
   * Size: nComplexEigenpairs. Paired with `beta` to form conjugate pairs
   * (alpha, beta) and (alpha, -beta) which produce 2×2 real block systems or a 1x1 complex system in the decoupled basis.
   */
  double *alpha;

  /**
   * @brief Imaginary parts of complex eigenvalues of A^{-1}.
   *
   * Size: nComplexEigenpairs.
   */
  double *beta;

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
   * @brief Number of real eigenvalues and complex eigenpairs.
   */
  int nRealEigenvalues;
  int nComplexEigenpairs;

  /**
   * @brief Size S_r of the T-transformations size_{transform} = #stages - int(explicit_first) - int(explicit_last)
   */
  int size;
} T_TRANSFORM;

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
  unsigned int nStages;               /* Number of stages */
  unsigned int order_b;               /* Order of the Runge-Kutta method */
  unsigned int order_bt;              /* Order of the embedded Runge-Kutta method */
  unsigned int error_order;           /* Usually min(order_b, order_bt) */
  double fac;                         /* Security factor for step size control */
  modelica_boolean  richardson;       /* if no embedded version is available, Richardson
                                         extrapolation can be used for step size control */
  modelica_boolean withDenseOutput;   /* Availability of dense output interpolation formulas */
  modelica_boolean isKLeftAvailable;  /* Availability of function values on left hand side */
  modelica_boolean isKRightAvailable; /* Availability of function values on right hand side */
  gb_dense_output dense_output;       /* Generic dense output function */
  T_TRANSFORM *t_transform;           /* T-transformation for FIRK methods */
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

void analyseButcherTableau(BUTCHER_TABLEAU* tableau, int nStates, unsigned int* nlSystemSize, enum GM_TYPE* expl);

void printButcherTableau(BUTCHER_TABLEAU* tableau);

#if defined(__cplusplus)
};
#endif

#endif // GBODE_TABLEAU_H

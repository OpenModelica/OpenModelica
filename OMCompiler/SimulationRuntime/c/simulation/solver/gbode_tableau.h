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
  gb_dense_output dense_output;
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

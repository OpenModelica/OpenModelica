/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#ifndef RK_BUTCHER_H
#define RK_BUTCHER_H

#if defined(__cplusplus)
extern "C" {
#endif

#include "util/simulation_options.h"
#include "openmodelica_types.h"

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
  double *A;                /* Runge-Kutta matrix A */
  double *b;                /* Weights vector */
  double *bt;
  double *c;                /* Nodes vector */
  unsigned int nStages;     /* Number of stages */
  unsigned int order_b;     /* Order of the Runge-Kutta method */
  unsigned int order_bt;    /* Order of the embeddet Runge-Kutta method */
  unsigned int error_order;
  double fac;               /* Security factor for step size control */
} BUTCHER_TABLEAU;

/**
 * @brief Type of Runge-Kutta method
 */
enum RK_type {
  RK_TYPE_UNDEF = 0,    /* Undefined type */
  RK_TYPE_EXPLICIT,     /* Explicit: A is lower triangular matrix */
  RK_TYPE_DIRK,         /* Diagonal implicit: A is triangular matrix */
  RK_TYPE_IMPLICIT      /* Implicit: A has elements above diagonal */
};

/* Function prototypes */

BUTCHER_TABLEAU* initButcherTableau(enum RK_SINGLERATE_METHOD RK_method);
void freeButcherTableau(BUTCHER_TABLEAU* tableau);

void analyseButcherTableau(BUTCHER_TABLEAU* tableau, int nStates, unsigned int* nlSystemSize, enum RK_type* expl);

void printButcherTableau(BUTCHER_TABLEAU* tableau);


#if defined(__cplusplus)
}
#endif

#endif // RK_BUTCHER_H
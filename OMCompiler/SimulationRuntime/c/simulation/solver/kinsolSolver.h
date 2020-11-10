/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

/*! \file kinsolSolver.h
 */

#ifndef _KINSOL_SOLVER_H_
#define _KINSOL_SOLVER_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "sundials_error.h"
#include "simulation_data.h"
#include "util/simulation_options.h"

#include <kinsol/kinsol.h>
#include <nvector/nvector_serial.h>
#include <sunlinsol/sunlinsol_dense.h>       /* Default dense linear solver */
#include <sunlinsol/sunlinsol_klu.h>         /* Linear solver KLU */
#include <sunlinsol/sunlinsol_lapackdense.h> /* Lapack dense linear solver */

/* constants */
#define RETRY_MAX 5
#define FTOL_WITH_LESS_ACCURANCY 1.e-6

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

/* readability */
typedef enum initialMode {
  INITIAL_EXTRAPOLATION = 0,
  INITIAL_OLDVALUES
} initialMode;

typedef enum scalingMode {
  SCALING_NOMINALSTART = 1, /* Scale with nomian values */
  SCALING_ONES,             /* Scale with ones (no scaling) */
  SCALING_JACOBIAN          /* Scale jacobian */
} scalingMode;

typedef struct NLS_KINSOL_USERDATA {
  DATA *data;
  threadData_t *threadData;

  int sysNumber;
} NLS_KINSOL_USERDATA;

typedef struct NLS_KINSOL_DATA {
  /* ### configuration  ### */
  enum NLS_LS linearSolverMethod; /* specifies the method to solve the
                                  underlying linear problem */
  int nonLinearSystemNumber;
  int kinsolStrategy; /* Strategy used to solve nonlinear systems. Has to be one
                       * of: KIN NONE, KIN_LINESEARCH, KIN_FP, KIN_PICARD */
  int retries;        /* Number of retries after failed solve of KINSOL */
  int solved;         /* If the system is once solved reuse linear matrix information */
  int nominalJac;     /* 1 for enabled scaling on Jacobian, 0 for disabled scaling */

  /* ### tolerances ### */
  double fnormtol;      /* function-norm stopping tolerance */
  double scsteptol;     /* step tolerance */
  double maxstepfactor; /* maximum newton step factor mxnewtstep = maxstepfactor
                         * norm2(xScaling) */
  double mxnstepin;     /* Maximum allowable scaled length of Newton step */

  /* ### work arrays ### */
  N_Vector initialGuess;
  N_Vector xScale;
  N_Vector fScale;
  N_Vector fRes;
  N_Vector fTmp;

  int iflag;
  long countResCalls; /* case of sparse function not avaiable */

  /* ### kinsol internal data */
  void *kinsolMemory;           /* Internal memroy block for KINSOL */
  NLS_KINSOL_USERDATA userData; /* User data provided to KINSOL */

  /* linear solver data */
  SUNLinearSolver linSol; /* Linear solver object used by KINSOL */
  N_Vector y;  /* Template for cloning vectors needed inside linear solver */
  SUNMatrix J; /* (Non-)Sparse matrix template for cloning matrices needed within
                  linear solver */

  /* Properties of non-linear system */
  int size;   /* Size of non-linear problem */
  int nnz;    /* Number of non-zero elements */

} NLS_KINSOL_DATA;

int nlsKinsolAllocate(int size, NONLINEAR_SYSTEM_DATA *nonlinsys,
                      enum NLS_LS linearSolverMethod);
int nlsKinsolFree(void **solverData);
int nlsKinsolSolve(DATA *data, threadData_t *threadData, int sysNumber);

#ifdef __cplusplus
};
#endif

#endif  /* _KINSOL_SOLVER_H_ */

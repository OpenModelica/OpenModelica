/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file radau.h
 * author: Ru(n)ge, wbraun
 */

#ifndef _RADAU_H_
#define _RADAU_H_

#include <string.h>
#include <math.h>

#include "omc_config.h"
#include "simulation_data.h"
#include "solver_main.h"

#ifdef WITH_SUNDIALS

#include "sundials_error.h"

#include <kinsol/kinsol.h>                  /* Main KINSOL header file */
#include <nvector/nvector_serial.h>         /* Serial vector implementation */
#include <sunlinsol/sunlinsol_dense.h>      /* Default dense linear solver */
#include <sunlinsol/sunlinsol_spgmr.h>      /* Scaled, Preconditioned, Generalized Minimum Residual iterative linear solver */
#include <sunlinsol/sunlinsol_spbcgs.h>     /* Scaled, Preconditioned, Bi-Conjugate Gradient, Stabilized iterative linear solver */
#include <sunlinsol/sunlinsol_sptfqmr.h>    /* Scaled, Preconditioned Transpose-Free Quasi-Minimal Residual iterative linear solver */

#define DEFAULT_IMPRK_ORDER 5

#ifdef __cplusplus
extern "C" {
#endif

typedef struct KDATAODE {
  N_Vector x;         /* Initial guess on input; solution vector */
  N_Vector sVars;     /* Scaling vector for variable x */
  N_Vector sEqns;     /* scaling vector for residual eqns */
  N_Vector c;         /* Vector with inequality constrains for solution vector x */

  void *kin_mem;      /* KINSOL memory block */
  int glstr;          /* Global strategy for KINSOL. Can be one of
                       * KIN_NONE, KIN_LINESEARCH, KIN_PICARD or KIN_FP */
  int mset;
  double fnormtol;
  double scsteptol;

  /* Linear solver object data */
  SUNLinearSolver linSol;   /* Linear solver object used by KINSOL */
  N_Vector y;               /* Template for cloning vectors needed inside linear solver */
  SUNMatrix J;              /* Sparse matrix template for cloning matrices needed within
                             * linear solver */
} KDATAODE;

typedef struct NLPODE {
  double *x0;
  double *f0;
  double *x;
  int nStates;            /* Number of states */
  double dt;
  double currentStep;
  double t0;
  double *min;
  double *max;
  double *derx;
  double *s;
  long double **c;        /* vector c of Butcher tableau TODO> OR is it A____ */
  double *a;
} NLPODE;

/**
 * @brief Solver data for KINSOL solver
 */
typedef struct KINODE {
  KDATAODE *kData;
  NLPODE *nlp;
  DATA *data;                   /* OMC data */
  threadData_t *threadData;     /* OMC threadData block */
  SOLVER_INFO *solverInfo;      /* Solver info */
  int N;
  int order;                    /* Integration order */
  enum IMPRK_LS lsMethod;       /* Specifies method used for solving linear systems */
} KINODE;

#else
typedef struct {
  void *kData;
  void *nlp;
  DATA *data;
  SOLVER_INFO *solverInfo;
  int N;
  int order;
} KINODE;

#endif /* SUNDIALS */
int allocateKinOde(DATA *data, threadData_t *threadData,
                   SOLVER_INFO *solverInfo, int order);
void freeKinOde(KINODE *kinOde);
int kinsolOde(SOLVER_INFO *solverInfo);
#ifdef __cplusplus
};
#endif

#endif /* _RADAU_H_ */

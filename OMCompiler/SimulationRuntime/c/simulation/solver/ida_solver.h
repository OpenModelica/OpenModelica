/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2016, Open Source Modelica Consortium (OSMC),
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

 /*! \file ida_solver.h
 */

#ifndef OMC_IDA_SOLVER_H
#define OMC_IDA_SOLVER_H

#include "openmodelica.h"
#include "simulation_data.h"
#include "util/simulation_options.h"
#include "sundials_error.h"
#include "simulation/solver/solver_main.h"
#include "omc_config.h" /* for WITH_SUNDIALS */

#ifdef WITH_SUNDIALS

#include <idas/idas.h>
#include <nvector/nvector_serial.h>
#include <sunlinsol/sunlinsol_dense.h>       /* Default dense linear solver */
#include <sunlinsol/sunlinsol_klu.h>         /* Sparse linear solver KLU */
#include <sunlinsol/sunlinsol_spgmr.h>      /* Scaled, Preconditioned, Generalized Minimum Residual iterative linear solver */
#include <sunlinsol/sunlinsol_spbcgs.h>     /* Scaled, Preconditioned, Bi-Conjugate Gradient, Stabilized iterative linear solver */
#include <sunlinsol/sunlinsol_sptfqmr.h>    /* Scaled, Preconditioned Transpose-Free Quasi-Minimal Residual iterative linear solver */


/* readability */
#define MINIMAL_SCALE_FACTOR 1e-8

typedef struct IDA_USERDATA
{
  DATA* data;
  threadData_t* threadData;
} IDA_USERDATA;

typedef struct IDA_SOLVER
{
  /* ### configuration  ### */
  int setInitialSolution;
  enum JACOBIAN_METHOD jacobianMethod;  /* specifies the method to calculate the Jacobian matrix */
  enum IDA_LS linearSolverMethod;       /* specifies the method to solve the linear problem */
  int internalSteps;                    /* if = 1 internal step of the integrator are used  */
  unsigned int stepsFreq;               /* value specifies the output frequency regarding to time steps. Used in internal steps mode. */
  double stepsTime;                     /* value specifies the time increment when output happens. Used in internal steps mode. */

  /* ### work arrays ### */
  N_Vector y;                   /* State vector */
  N_Vector yp;                  /* State derivative vector */

  /* ### scaling data ### */
  double *yScale;
  double *ypScale;
  double *resScale;
  int disableScaling;           /* = 1 disables scaling temporary for particular calculations */

  /* ### work array used in jacobian calculation ### */
  double sqrteps;
  double *ysave;
  double *ypsave;
  double *delta_hh;
  N_Vector errwgt;
  N_Vector newdelta;

  /* ### ida internal data ### */
  void* ida_mem;
  int (*residualFunction)(double time, N_Vector yy, N_Vector yp, N_Vector res, void* userData);
  IDA_USERDATA* userData;
  SUNMatrix tmpJac;
  SUNMatrix denseJac;

  /* linear solver data */
  SUNLinearSolver linSol;   /* Linear solver object */
  N_Vector y_linSol;        /* Template for cloning vectors needed inside linear solver */
  SUNMatrix J;              /* Sparse matrix template for cloning matrices needed within
                               linear solver */

  /* ### daeMode ### */
  booleantype daeMode;      /* If TRUE then solve dae more with a reals residual function */
  long int N;               /* Number of unknowns */
  long int NNZ;             /* Number of non-zero elemetes of ... */
  double *states;           /* Array of states. Only used in DAE mode, NULL otherwise */
  double *statesDer;        /* Array of state derivatives. Only used in DAE mode, NULL otherwise */

  /* ### ida sensitivities ### */
  int idaSmode;             /* 1 if used, 0 else */
  int Ns;                   /* Number of sensitivitys parameters which the IVP depends on */
  N_Vector* yS;             /* Array of sensitifity vectors of state vector */
  N_Vector* ySp;            /* Array of sensitfity vectors of state derivatives */
  N_Vector* ySResult;

#ifdef USE_PARJAC
  ANALYTIC_JACOBIAN* jacColumns;
#endif
  int allocatedParMem; /* indicated if parallel memory was allocated, 0=false, 1=true*/
} IDA_SOLVER;

/* initialize main ida Data */
int ida_solver_initial(DATA* data, threadData_t *threadData,
                       SOLVER_INFO* solverInfo, IDA_SOLVER *idaData);

/* deinitialize main ida Data */
int ida_solver_deinitial(IDA_SOLVER *idaData);

/* main ida function to make a step */
int ida_solver_step(DATA* simData, threadData_t *threadData, SOLVER_INFO* solverInfo);

/* event handing reinitialization function  */
int ida_event_update(DATA* data, threadData_t *threadData);

#endif  /* #ifdef WITH_SUNDIALS */

#endif  /* #ifndef OMC_IDA_SOLVER_H*/

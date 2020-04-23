/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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

#ifdef WITH_SUNDIALS

/* adrpo: on mingw link with static sundials */
#if defined(__MINGW32__)
#define LINK_SUNDIALS_STATIC
#endif


#include <idas/idas.h>
#include <nvector/nvector_serial.h>
#include <sunlinsol/sunlinsol_dense.h>       /* Default dense linear solver */
#include <sunlinsol/sunlinsol_klu.h>         /* Linear solver KLU */
//#include <sunlinsol/sunlinsol_lapackdense.h> /* Lapack dense linear solver */
#include <sunlinsol/sunlinsol_spgmr.h>
#include <sunlinsol/sunlinsol_spbcgs.h>
#include <sunlinsol/sunlinsol_sptfqmr.h>


#if 0 /* TODO: Remove */
#include <sundials/sundials_types.h>
#include <sundials/sundials_nvector.h>
#include <nvector/nvector_serial.h>

#include <idas/idas_dense.h>
#include <idas/idas_klu.h>
#include <idas/idas_spgmr.h>
#include <idas/idas_spbcgs.h>
#include <idas/idas_sptfqmr.h>


#include <sundials/sundials_nvector.h>
#include <nvector/nvector_serial.h>

#include <idas/idas_dense.h>
#include <idas/idas_sparse.h>
#endif


/* readability */
#define SCALE_MODE 0
#define RESCALE_MODE 1

#define MINIMAL_SCALE_FACTOR 1e-8

#ifndef booleantype
#define booleantype int
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif


typedef struct IDA_USERDATA
{
  DATA* data;
  threadData_t* threadData;
} IDA_USERDATA;

typedef struct IDA_SOLVER
{
  /* ### configuration  ### */
  int setInitialSolution;
  int jacobianMethod;            /* specifies the method to calculate the Jacobian matrix */
  int linearSolverMethod;        /* specifies the method to solve the linear problem */
  int internalSteps;             /* if = 1 internal step of the integrator are used  */
  unsigned int stepsFreq;        /* value specifies the output frequency regarding to time steps. Used in internal steps mode. */
  double stepsTime;              /* value specifies the time increment when output happens. Used in internal steps mode. */

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
  SUNLinearSolver linSol; /* Linear solver object used by KINSOL */
  N_Vector y_linSol; /* Template for cloning vectors needed inside linear solver */
  SUNMatrix J; /* Sparse matrix template for cloning matrices needed within
                  linear solver */
  /* TODO: AHeu: Free memory !!! */

  /* ### daeMode ### */
  booleantype daeMode;          /* If TRUE then solve dae more with a reals residual function */
  long int N;                   /* Number of unknowns */
  long int NNZ;                 /* Number of non-zero elemetes of ... */
  double *states;
  double *statesDer;

  /* ### ida sensitivities ### */
  int idaSmode;
  int Np;
  N_Vector* yS;
  N_Vector* ySp;
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

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurentYear, Open Source Modelica Consortium (OSMC),
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

#ifndef CVODE_SOLVER_H
#define CVODE_SOLVER_H

#ifndef OMC_FMI_RUNTIME
  #include "omc_config.h"
#endif
#include "../../simulation_data.h"
#include "../../util/simulation_options.h"
#include "sundials_error.h"
#include "solver_main.h"

#ifdef WITH_SUNDIALS

#include <cvode/cvode.h>             /* prototypes for CVODE fcts., consts. */
#include <nvector/nvector_serial.h>  /* serial N_Vector types, fcts., macros */
#include <sunlinsol/sunlinsol_dense.h>              /* Default dense linear solver */
#include <sunnonlinsol/sunnonlinsol_fixedpoint.h>   /* Default dense linear solver */

/**
 * @brief Non-linear solver method for internal use of CVODE.
 *
 * Can be Fixed-Point iteration or Newton iteration.
 */
typedef enum CVODE_ITER
{
  CV_ITER_UNKNOWN      =0,

  CV_ITER_FIXED_POINT  =1,   /* Fixed point iteration */
  CV_ITER_NEWTON       =2,   /* Newton iteration (default) */

  CV_ITER_MAX
}CVODE_ITER;

typedef struct CVODE_USERDATA
{
  DATA *data;
  threadData_t *threadData;
} CVODE_USERDATA;

typedef struct CVODE_CONFIG
{
  /* Mandatory configurations */
  int lmm;                     /* Linear multistep method
                                * CV_ADAMS = 1 for non-stiff problems
                                * CV_BDF = 2 for stiff problems */
  CVODE_ITER iter;             /* Nonlinear solver iteration
                                * CV_ITER_FIXED_POINT = 1 for fixed-point-iteration
                                * CV_ITER_NEWTON = 2 for Newton iterations */

  booleantype internalSteps;           /* if TRUE internal step of the integrator are used, default FALSE */
  enum JACOBIAN_METHOD jacobianMethod; /* Method for Jacobian computation */

  /* Optional configurations */
  double minStepSize;          /* Lower bound on the magnitude of the step size.
                                * Minimum value is 0.0, default value is 1e-12. */
  double maxStepSize;          /* Upper bound on the magnitude of the step size.
                                * Set to 0.0 to obtain default value infinity. */
  double initStepSize;         /* Initial step size for CVODE.
                                * Set to 0.0 for default value. */
  int maxOrderLinearMultistep; /* Maximum order of linear multistep function.
                                * Must be positive and smaller than default.
                                * For CV_ADAMS defaults to ADAMS_Q_MAX=12.
                                * For CV_BDF defaults to BDF_Q_MAX=5. */
  int maxConvFailPerStep;      /* Maximum number of nonlinear solver convergence failures permitted during one step.
                                * Default value is 10. */
  booleantype BDFStabDetect;   /* BDF stability limit detection.
                                * Only usable for lmm=CV_BDF. */
  booleantype solverRootFinding;  /* True if internal root finding should be used, false otherwiese.
                                   * Disable for FMI */
} CVODE_CONFIG;

typedef struct CVODE_SOLVER
{
  CVODE_CONFIG config;        /* CVODE configuration */
  booleantype isInitialized;  /* Boolean flag if problem is initilaized with start value for y */
  long int N;                 /* NUmber of unknowns / states */

  /* work arrays */
  N_Vector y;                 /* dependent variable vector of ODE */
  N_Vector absoluteTolerance; /* vector of absolute integrator tolerances for CVODE */

  /* linear solver data */
  SUNLinearSolver linSol;     /* Linear solver object */
  N_Vector y_linSol;          /* Template for cloning vectors needed inside linear solver */
  SUNMatrix J;                /* Sparse matrix template for cloning matrices needed within
                               linear solver */

  /* Non-linear solver data */
  SUNNonlinearSolver nonLinSol; /* Non-linear solver object */
  N_Vector y_nonLinSol;         /* Template for cloning vectors needed inside non-linear solver */

  /* CVODE internal data */
  void *cvode_mem;            /* Internal CVODE memory block */
  CVODE_USERDATA *simData;
} CVODE_SOLVER;

/* Function prototypes */
int cvode_solver_initial(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData, int isFMI);
int cvode_solver_reinit(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData);
int cvode_solver_deinitial(CVODE_SOLVER *cvodeData);
int cvode_solver_step(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo);
int cvode_solver_fmi_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double tNext, double* states, void* fmuComponent);

#else /* WITH_SUNDIALS */
typedef void CVODE_SOLVER;

// TODO: Move to .c file
int cvode_solver_initial(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData, int isFMI)
{
#ifdef OMC_FMI_RUNTIME
  printf("##CVODE## SUNDIALS not available in FMU. See OpenModelica command line flag \"--fmiFlags\" from \"omc --help\" on how to enable CVODE in FMUs.\n");
  return -1;
#else
  throwStreamPrint(threadData, "##CVODE## SUNDIALS not available. Reconfigure omc with SUNDIALS.\n");
#endif
}

int cvode_solver_deinitial(CVODE_SOLVER *cvodeData)
{
#ifdef OMC_FMI_RUNTIME
  printf("##CVODE## SUNDIALS not available in FMU. See OpenModelica command line flag \"--fmiFlags\" from \"omc --help\" on how to enable CVODE in FMUs.\n");
  return -1;
#else
  throwStreamPrint(NULL, "##CVODE## SUNDIALS not available. Reconfigure omc with SUNDIALS.\n");
#endif
}

int cvode_solver_step(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo)
{
#ifdef OMC_FMI_RUNTIME
  printf("##CVODE## SUNDIALS not available in FMU. See OpenModelica command line flag \"--fmiFlags\" from \"omc --help\" on how to enable CVODE in FMUs.\n");
  return -1;
#else
  throwStreamPrint(threadData, "##CVODE## SUNDIALS not available. Reconfigure omc with SUNDIALS.\n");
#endif
}

int cvode_solver_fmi_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double tNext, double* states, void* fmuComponent)
{
#ifdef OMC_FMI_RUNTIME
  printf("##CVODE## SUNDIALS not available in FMU. See OpenModelica command line flag \"--fmiFlags\" from \"omc --help\" on how to enable CVODE in FMUs.\n");
  return -1;
#else
  throwStreamPrint(threadData, "##CVODE## SUNDIALS not available. Reconfigure omc with SUNDIALS.\n");
#endif
}


#endif /* WITH_SUNDIALS */

#endif /* #ifndef CVODE_SOLVER_H */

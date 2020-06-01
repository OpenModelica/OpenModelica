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

#ifndef CVODE_SOLVER_H
#define CVODE_SOLVER_H

/* link sundials static on Windows */
#if defined(__MINGW32__) || defined(_MSV_VER)
#define LINK_SUNDIALS_STATIC 1
#endif

#include "cvode/cvode.h"             /* prototypes for CVODE fcts., consts. */
#include "cvode/cvode_impl.h"        /* prototypes for CVODE internal consts.*/
#include "cvode/cvode_dense.h"       /* prototype for CVODE dense matrix functions and constants */
#include "nvector/nvector_serial.h"  /* serial N_Vector types, fcts., macros */
#include "sundials/sundials_types.h" /* definition of type realtype */

#include "simulation_data.h"
#include "util/simulation_options.h"

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
  int iter;                    /* Nonlinear solver iteration
                                * CV_FUNCTIONAL = 1 for functional iterations
                                * CV_NEWTON = 2 for Newton iterations */

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
} CVODE_CONFIG;

typedef struct CVODE_SOLVER
{
  CVODE_CONFIG config;        /* CVODE configuration */
  booleantype isInitialized;  /* Boolean flag if problem is initilaized with start value for y */

  /* work arrays */
  N_Vector y;                 /* dependent variable vector of ODE */
  N_Vector absoluteTolerance; /* vector of absolute integrator tolerances for CVODE */

  /* CVODE internal data */
  void *cvode_mem;            /* Internal CVODE memory block */
  CVODE_USERDATA *simData;
} CVODE_SOLVER;

/* Function prototypes */
int cvode_solver_initial(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData);
int cvode_solver_deinitial(CVODE_SOLVER *cvodeData);
int cvode_solver_step(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo);

#endif /* #ifndef CVODE_SOLVER_H */

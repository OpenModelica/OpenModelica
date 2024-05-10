/* -----------------------------------------------------------------------------
 * Programmer(s): David J. Gardner @ LLNL
 * -----------------------------------------------------------------------------
 * Based on CPODES by Radu Serban @ LLNL
 * -----------------------------------------------------------------------------
 * SUNDIALS Copyright Start
 * Copyright (c) 2002-2020, Lawrence Livermore National Security
 * and Southern Methodist University.
 * All rights reserved.
 *
 * See the top-level LICENSE and NOTICE files for details.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 * SUNDIALS Copyright End
 * -----------------------------------------------------------------------------
 * This is the header file for CVODE's projection interface.
 * ---------------------------------------------------------------------------*/

#ifndef _CVPROJ_H
#define _CVPROJ_H

#include <sundials/sundials_nvector.h>

#ifdef __cplusplus  /* wrapper to enable C++ usage */
extern "C" {
#endif

/* -----------------------------------------------------------------------------
 * CVProj user-supplied function prototypes
 * ---------------------------------------------------------------------------*/

typedef int (*CVProjFn)(realtype t, N_Vector ycur, N_Vector corr,
                        realtype epsProj, N_Vector err, void *user_data);


/* -----------------------------------------------------------------------------
 * CVProj Exported functions
 * ---------------------------------------------------------------------------*/

/* Projection initialization functions */
SUNDIALS_EXPORT int CVodeSetProjFn(void *cvode_mem, CVProjFn pfun);

/* Optional input functions */
SUNDIALS_EXPORT int CVodeSetProjErrEst(void *cvode_mem, booleantype onoff);
SUNDIALS_EXPORT int CVodeSetProjFrequency(void *cvode_mem, long int proj_freq);
SUNDIALS_EXPORT int CVodeSetMaxNumProjFails(void *cvode_mem, int max_fails);
SUNDIALS_EXPORT int CVodeSetEpsProj(void *cvode_mem, realtype eps);
SUNDIALS_EXPORT int CVodeSetProjFailEta(void *cvode_mem, realtype eta);

/* Optional output functions */
SUNDIALS_EXPORT int CVodeGetNumProjEvals(void *cvode_mem, long int *nproj);
SUNDIALS_EXPORT int CVodeGetNumProjFails(void *cvode_mem, long int *nprf);

#ifdef __cplusplus
}
#endif

#endif

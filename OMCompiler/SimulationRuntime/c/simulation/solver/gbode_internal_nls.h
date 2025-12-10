/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Open Source Modelica Consortium (OSMC),
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

#ifndef GBODE_INTERNAL_NLS_H
#define GBODE_INTERNAL_NLS_H

#include "simulation_data.h"
#include "nonlinearSystem.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct DATA_GBODE DATA_GBODE;

typedef struct Tolerances
{
    double atol;
    double rtol;
} Tolerances;

Tolerances *gbInternalNlsGetScaledTolerances(void *nls_ptr);

void *gbInternalNlsAllocate(int size,
                            NLS_USERDATA *userData,
                            modelica_boolean attemptRetry,
                            modelica_boolean isPatternAvailable);

void gbInternalNlsFree(void *nls_ptr);

NLS_SOLVER_STATUS gbInternalSolveNls(DATA *data,
                                     threadData_t *threadData,
                                     NONLINEAR_SYSTEM_DATA *nonlinsys,
                                     DATA_GBODE *gbData,
                                     void *nls_ptr);

void gbInternalContraction(DATA *data,
                           threadData_t *threadData,
                           NONLINEAR_SYSTEM_DATA *nonlinsys,
                           DATA_GBODE *gbData,
                           double *yt,
                           double *y);

#ifdef __cplusplus
};
#endif

#endif  /* GBODE_INTERNAL_NLS_H */

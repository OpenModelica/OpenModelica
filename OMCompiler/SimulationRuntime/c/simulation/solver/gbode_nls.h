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

/*! \file gbode_nls.h
 */

#ifndef GBODE_NLS_H
#define GBODE_NLS_H

#include "simulation_data.h"
#include "nonlinearSystem.h"

#include "gbode_main.h"

#ifdef __cplusplus
extern "C" {
#endif

NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GBODE* gbData);
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GBODEF* gbfData);
void freeRK_NLS_DATA( NONLINEAR_SYSTEM_DATA* nlsData);

//Specific treatment of NLS within gbode
NLS_SOLVER_STATUS solveNLS_gb(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, DATA_GBODE* gbData);

// Residuum and Jacobian functions for diagonal implicit (DIRK) and implicit (IRK) Runge-Kutta methods.
void residual_MS(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);
void residual_DIRK(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);
void residual_IRK(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);

void residual_MS_MR(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);
void residual_DIRK_MR(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag);

#ifdef __cplusplus
};
#endif

#endif  /* #ifndef GBODE_NLS_H*/

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

/*! \file DATA_GBODEF.h
 */

#ifndef _DATA_GBODEF_H_
#define _DATA_GBODEF_H_

#include "simulation_data.h"
#include "solver_main.h"

#include "gbode_tableau.h"
#include "gbode.h"

/**
 * @brief Function to compute single Runge-Kutta step.
 */
typedef int (*gm_step_function)(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
typedef double (*gm_stepSize_control_function)(double* err_values, double* stepSize_values, double err_order);


void gbodef_freeData(DATA_GBODEF* data);
int gbodef_main(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, double targetTime);

#endif /* _DATA_GBODEF_H_ */

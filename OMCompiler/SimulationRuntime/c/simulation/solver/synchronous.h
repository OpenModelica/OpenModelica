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

/*! \file synchronous.h
 */

#ifndef _SYNCHRONOUS_H_
#define _SYNCHRONOUS_H_

#include "../../simulation_data.h"
#include "solver_main.h"
#include "../../util/list.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Type of Clock fireing
 *
 */
typedef enum {
  NO_TIMER_FIRED,   /**< No clock was fired*/
  TIMER_FIRED,      /**< A clockwas fired that didn't fire an event */
  TIMER_FIRED_EVENT /**< A clock was fired that triggered an event */
} fire_timer_t;

void initSynchronous(DATA* data, threadData_t *threadData, modelica_real startTime);
void checkForSynchronous(DATA *data, SOLVER_INFO* solverInfo);
modelica_boolean handleBaseClock(DATA* data, threadData_t *threadData, long idx, double curTime);
fire_timer_t handleTimers(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
int handleTimersFMI(DATA* data, threadData_t *threadData, double currentTime, int *nextTimerDefined, double *nextTimerActivationTime);

#ifdef __cplusplus
}
#endif

#endif

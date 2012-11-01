/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file events.h
 */

#ifndef _EVENTS_H_
#define _EVENTS_H_

#include "simulation_data.h"
#include "solver_main.h"
#include "list.h"

modelica_boolean sample(DATA *data, double start, double interval, int hindex);
void initSample(DATA *data, double start, double stop);
modelica_boolean activateSampleEvents(DATA *data);
void deactivateSampleEvents(DATA *data);
void deactivateSampleEventsandEquations(DATA *data);

modelica_boolean checkForSampleEvent(DATA *data, SOLVER_INFO* solverInfo);
modelica_boolean checkForNewEvent(DATA* data, LIST *eventList);
modelica_boolean checkStateorSampleEvent(DATA* data, LIST* eventLst, double *eventTime);

int handleStateEvent(DATA* data, LIST* eventLst, double *eventTime);
int handleSampleEvent(DATA* data);

void findRoot(DATA *data, LIST *eventList, double*);

#endif

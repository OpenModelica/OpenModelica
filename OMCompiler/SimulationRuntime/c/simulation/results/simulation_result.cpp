/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include "simulation_result.h"

#include <stdlib.h>

extern "C" {

static void sim_result_doNothing(simulation_result* self, DATA *data, threadData_t *threadData)
{
  /* Do nothing */
}

simulation_result sim_result = {
  NULL, /* filename */
  0, /* numpoints */
  0, /* cpuTime */
  NULL, /* extra data */
  sim_result_doNothing, /* init */
  sim_result_doNothing, /* emit */
  sim_result_doNothing, /* writeParam */
  sim_result_doNothing, /* free */
};

void deinitializeResultData(DATA *data, threadData_t *threadData)
{
  if (sim_result.free) {
    sim_result.free(&sim_result, data, threadData);
  }
  free((void*) sim_result.filename);
  sim_result.filename = NULL;
  sim_result.numpoints = 0;
  sim_result.cpuTime = 0;
  sim_result.storage = NULL;
  sim_result.init = sim_result_doNothing;
  sim_result.emit = sim_result_doNothing;
  sim_result.writeParameterData = sim_result_doNothing;
  sim_result.free = sim_result_doNothing;
}

}

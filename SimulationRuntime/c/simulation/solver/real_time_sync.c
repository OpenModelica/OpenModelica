/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#include "real_time_sync.h"

#if defined(__linux__)
#include <sys/mman.h>
#include <errno.h>
#endif

void omc_real_time_sync_init(threadData_t *threadData, DATA *data)
{
  data->real_time_sync.maxLate = INT64_MIN;

#if defined(__linux__)
  if (mlockall(MCL_CURRENT | MCL_FUTURE) == -1) {
    warningStreamPrint(LOG_RT, 0, __FILE__ ": mlockall failed (recommended to run as root to lock memory into RAM while doing real-time simulation): %s\n", strerror(errno));
  }
  struct sched_param param = {.sched_priority = 49 /* 50=interrupt handler */ };
  if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
    warningStreamPrint(LOG_RT, 0, __FILE__ ": sched_setscheduler failed: %s\n", strerror(errno));
  }
#endif

  omc_real_time_sync_update(data, data->real_time_sync.scaling);

  if (data->real_time_sync.enabled == 0) {
    return;
  }
}

void omc_real_time_sync_update(DATA *data, double scaling)
{
  data->real_time_sync.scaling = scaling;
  if (scaling == 0) {
    data->real_time_sync.enabled = 0;
    return;
  }
  data->real_time_sync.enabled = 1;
  data->real_time_sync.time = data->localData[0]->timeValue;
  rt_ext_tp_tick_realtime(&data->real_time_sync.clock);
}

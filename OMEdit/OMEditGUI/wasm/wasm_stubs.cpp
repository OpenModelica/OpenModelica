/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

// Startup symbols OMEdit links from libOpenModelicaCompiler.so natively but that
// the wasm build (omc in a Web Worker) has no cdylib for. See wasm/HANDOFF.md.

#include <cstdlib>
#include <ctime>
#include <util/rtclock.h>

extern "C" {

// OMEditApplication aborts startup if this returns null; no install tree on wasm,
// so a non-null placeholder (the page's OPENMODELICAHOME, else "/usr") suffices.
const char *SettingsImpl__getInstallationDirectoryPath()
{
  const char *home = getenv("OPENMODELICAHOME");
  return (home && *home) ? home : "/usr";
}

// Animation/TimeManager.cpp is compiled for wasm (drives the result-replay time
// slider) but rtclock.c is not (it pulls in the Boehm GC headers). These two are
// the only rtclock entry points TimeManager uses; the rest of rtclock is unneeded.
void rt_ext_tp_tick_realtime(rtclock_t *tick_tp)
{
  clock_gettime(CLOCK_MONOTONIC, &tick_tp->time);
}

double rt_ext_tp_tock(rtclock_t *tick_tp)
{
  struct timespec now;
  clock_gettime(CLOCK_MONOTONIC, &now);
  return (now.tv_sec - tick_tp->time.tv_sec) + (now.tv_nsec - tick_tp->time.tv_nsec) * 1e-9;
}

} // extern "C"

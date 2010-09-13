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

#include "rtclock.h"

#if defined(__MINGW32__) || defined(_MSC_VER)

#include <windows.h>

LARGE_INTEGER performance_frequency;
LARGE_INTEGER tick_tp[NUM_RT_CLOCKS];

void rt_tick(int ix) {
  static int init = 0;
  if (!init) {
    init = 1;
    QueryPerformanceFrequency(&performance_frequency);
  }
  QueryPerformanceCounter(&tick_tp[ix]);
}

double rt_tock(int ix) {
  LARGE_INTEGER tock_tp;
  double d1,d2;
  QueryPerformanceCounter(&tock_tp);
  d1 = (double)(tock_tp.QuadPart - tick_tp[ix].QuadPart);
  d2 = (double) performance_frequency.QuadPart;
  return d1 / d2;
}

#elif defined(__APPLE_CC__)

#include <mach/mach_time.h>
#include <time.h>

uint64_t tick_tp[NUM_RT_CLOCKS];

void rt_tick(int ix) {
  tick_tp[ix] = mach_absolute_time();
}

double rt_tock(int ix) {
  uint64_t tock_tp = mach_absolute_time();
  uint64_t nsec;
  static mach_timebase_info_data_t info = {0,0};
  if (info.denom == 0)
    mach_timebase_info(&info);
  uint64_t elapsednano = (tock_tp-tick_tp[ix]) * (info.numer / info.denom);
  return elapsednano * 1e-9;
}

#else

#include <time.h>

struct timespec tick_tp[NUM_RT_CLOCKS];

void rt_tick(int ix) {
  clock_gettime(CLOCK_MONOTONIC, &tick_tp[ix]);
}

double rt_tock(int ix) {
  struct timespec tock_tp = {0,0};
  clock_gettime(CLOCK_MONOTONIC, &tock_tp);
  return (tock_tp.tv_sec - tick_tp[ix].tv_sec) + (tock_tp.tv_nsec - tick_tp[ix].tv_nsec)*1e-9;
}

#endif

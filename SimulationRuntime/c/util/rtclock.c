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
#include <assert.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>

#if defined(__MINGW32__) || defined(_MSC_VER)
#include <windows.h>
#if defined(_MSC_VER)
#include <intrin.h>
#endif
typedef LARGE_INTEGER rtclock_t;
#elif defined(__APPLE_CC__)
#include <mach/mach_time.h>
#include <time.h>
typedef uint64_t rtclock_t;
#else
#include <time.h>
typedef struct timespec rtclock_t;
#endif

static unsigned long default_rt_clock_ncall[NUM_RT_CLOCKS] = { 0 };
static unsigned long default_rt_clock_ncall_min[NUM_RT_CLOCKS] = { 0 };
static unsigned long default_rt_clock_ncall_max[NUM_RT_CLOCKS] = { 0 };
static unsigned long default_rt_clock_ncall_total[NUM_RT_CLOCKS] = { 0 };
static unsigned long *rt_clock_ncall = default_rt_clock_ncall;
static unsigned long *rt_clock_ncall_min = default_rt_clock_ncall_min;
static unsigned long *rt_clock_ncall_max = default_rt_clock_ncall_max;
static unsigned long *rt_clock_ncall_total = default_rt_clock_ncall_total;

static rtclock_t default_total_tp[NUM_RT_CLOCKS];
static rtclock_t default_max_tp[NUM_RT_CLOCKS];
static rtclock_t default_acc_tp[NUM_RT_CLOCKS];
static rtclock_t default_tick_tp[NUM_RT_CLOCKS];

static rtclock_t *total_tp = default_total_tp;
static rtclock_t *max_tp = default_max_tp;
static rtclock_t *acc_tp = default_acc_tp;
static rtclock_t *tick_tp = default_tick_tp;

static int rtclock_compare(rtclock_t, rtclock_t);

static rtclock_t max_rtclock(rtclock_t t1, rtclock_t t2) {
  if (rtclock_compare(t1, t2) < 0)
    return t2;
  return t1;
}

static double rtclock_value(rtclock_t);

void rt_add_ncall(int ix, int n) {
  rt_clock_ncall[ix] += n;
}

unsigned long rt_ncall(int ix) {
  return rt_clock_ncall[ix];
}

unsigned long rt_ncall_min(int ix) {
  return rt_clock_ncall_min[ix];
}

unsigned long rt_ncall_max(int ix) {
  return rt_clock_ncall_max[ix];
}

unsigned long rt_ncall_total(int ix) {
  return rt_clock_ncall_total[ix];
}

void rt_update_min_max_ncall(int ix) {
  unsigned long nmin = rt_clock_ncall_min[ix];
  unsigned long nmax = rt_clock_ncall_max[ix];
  unsigned long n = rt_clock_ncall[ix];
  if (n == 0)
    return;
  rt_clock_ncall_min[ix] = nmin && nmin < n ? nmin : n;
  rt_clock_ncall_max[ix] = nmax > n ? nmax : n;
}

void rt_clear_total_ncall(int ix) {
  rt_clock_ncall[ix] = 0;
  rt_clock_ncall_total[ix] = 0;
  rt_clock_ncall_min[ix] = ULONG_MAX;
  rt_clock_ncall_max[ix] = 0;
}

double rt_accumulated(int ix) {
  return rtclock_value(acc_tp[ix]);
}

double rt_max_accumulated(int ix) {
  return rtclock_value(max_tp[ix]);
}

double rt_total(int ix) {
  return rtclock_value(total_tp[ix]);
}

#if defined(__MINGW32__) || defined(_MSC_VER)

static enum omc_rt_clock_t selectedClock = OMC_CLOCK_REALTIME;

#if defined(__MINGW32__)
inline long long RDTSC() {
   register long long TSC asm("eax");
   asm volatile (".byte 15, 49" : : : "eax", "edx");
   return TSC;
//    unsigned int hi, lo;
//    asm volatile("rdtscp" : "=a"(lo), "=d"(hi));
//    return (unsigned long long)lo | ((unsigned long long)hi << 32);
}
#else
long long RDTSC() {
//  unsigned int ui;
//  return __rdtscp(&ui);
   return __rdtsc();
}
#endif

int rt_set_clock(enum omc_rt_clock_t newClock) {
  if (newClock != OMC_CLOCK_REALTIME && newClock != OMC_CPU_CYCLES)
    return 1;

  selectedClock = newClock;
  return 0;
}

static LARGE_INTEGER performance_frequency;

void rt_tick(int ix) {
  if(selectedClock == OMC_CLOCK_REALTIME)
  {
    static int init = 0;
    if (!init) {

      init = 1;
      QueryPerformanceFrequency(&performance_frequency);
    }
    QueryPerformanceCounter(&tick_tp[ix]);
  }
  else
  {
    LARGE_INTEGER time;
    time.QuadPart = RDTSC();
    tick_tp[ix] = time;
  }
  rt_clock_ncall[ix]++;
}

double rt_tock(int ix) {
  if(selectedClock == OMC_CLOCK_REALTIME)
  {
    LARGE_INTEGER tock_tp;
    double d1, d2;
    QueryPerformanceCounter(&tock_tp);
    d1 = (double) (tock_tp.QuadPart - tick_tp[ix].QuadPart);
    d2 = (double) performance_frequency.QuadPart;
    return d1 / d2;
  }
  else
  {
    LARGE_INTEGER tock_tp;
    tock_tp.QuadPart = RDTSC();
    return (double) (tock_tp.QuadPart - tick_tp[ix].QuadPart);
  }
}

void rt_clear(int ix) {
  total_tp[ix].QuadPart += acc_tp[ix].QuadPart;
  rt_clock_ncall_total[ix] += rt_clock_ncall[ix];
  max_tp[ix] = max_rtclock(max_tp[ix], acc_tp[ix]);
  rt_update_min_max_ncall(ix);
  acc_tp[ix].QuadPart = 0;
  rt_clock_ncall[ix] = 0;
}

void rt_clear_total(int ix) {
  total_tp[ix].QuadPart = 0;
  acc_tp[ix].QuadPart = 0;
  rt_clear_total_ncall(ix);
}

void rt_accumulate(int ix) {
  if(selectedClock == OMC_CLOCK_REALTIME)
  {
    LARGE_INTEGER tock_tp;
    QueryPerformanceCounter(&tock_tp);
    acc_tp[ix].QuadPart += tock_tp.QuadPart - tick_tp[ix].QuadPart;
  }
  else
  {
    LARGE_INTEGER tock_tp;
    tock_tp.QuadPart = RDTSC();
    acc_tp[ix].QuadPart += tock_tp.QuadPart - tick_tp[ix].QuadPart;
  }
}

int rtclock_compare(rtclock_t t1, rtclock_t t2) {
  return t1.QuadPart - t2.QuadPart;
}

double rtclock_value(LARGE_INTEGER tp) {
  if(selectedClock == OMC_CLOCK_REALTIME)
  {
    double d1, d2;
    d1 = (double) (tp.QuadPart);
    d2 = (double) performance_frequency.QuadPart;
    return d1 / d2;
  }
  else
  {
    return (double) (tp.QuadPart);
  }
}

#elif defined(__APPLE_CC__)

int rt_set_clock(enum omc_rt_clock_t newClock) {
  return newClock != OMC_CLOCK_REALTIME;
}

void rt_tick(int ix) {
  tick_tp[ix] = mach_absolute_time();
  rt_clock_ncall[ix]++;
}

double rt_tock(int ix) {
  uint64_t tock_tp = mach_absolute_time();
  uint64_t nsec;
  static mach_timebase_info_data_t info = {0,0};
  if(info.denom == 0)
  mach_timebase_info(&info);
  uint64_t elapsednano = (tock_tp-tick_tp[ix]) * (info.numer / info.denom);
  return elapsednano * 1e-9;
}

void rt_clear(int ix)
{
  total_tp[ix] += acc_tp[ix];
  rt_clock_ncall_total[ix] += rt_clock_ncall[ix];
  max_tp[ix] = max_rtclock(max_tp[ix],acc_tp[ix]);
  rt_update_min_max_ncall(ix);
  acc_tp[ix] = 0;
  rt_clock_ncall[ix] = 0;
}

void rt_clear_total(int ix)
{
  total_tp[ix] = 0;
  rt_clock_ncall_total[ix] = 0;
  acc_tp[ix] = 0;
  rt_clock_ncall[ix] = 0;
}

void rt_accumulate(int ix) {
  uint64_t tock_tp = mach_absolute_time();
  acc_tp[ix] += tock_tp - tick_tp[ix];
}

double rtclock_value(uint64_t tp) {
  static mach_timebase_info_data_t info = {0,0};
  if(info.denom == 0)
  mach_timebase_info(&info);
  uint64_t elapsednano = tp * (info.numer / info.denom);
  return elapsednano * 1e-9;
}

int rtclock_compare(uint64_t t1, uint64_t t2) {
  return t1-t2;
}

#else

/* CLOCK_MONOTONIC_RAW: since Linux 2.6.28 */
#ifdef CLOCK_MONOTONIC_RAW
#define OMC_CLOCK_MONOTONIC CLOCK_MONOTONIC_RAW
#else
#define OMC_CLOCK_MONOTONIC CLOCK_MONOTONIC
#endif
static clockid_t omc_clock = OMC_CLOCK_MONOTONIC;

int rt_set_clock(enum omc_rt_clock_t newClock) {
#if defined(linux)
  omc_clock = newClock == OMC_CLOCK_REALTIME ? OMC_CLOCK_MONOTONIC : CLOCK_PROCESS_CPUTIME_ID;
#else
  omc_clock = OMC_CLOCK_MONOTONIC;
#endif
  return 0;
}

void rt_tick(int ix) {
  clock_gettime(omc_clock, &tick_tp[ix]);
  rt_clock_ncall[ix]++;
}

double rt_tock(int ix) {
  struct timespec tock_tp = {0,0};
  clock_gettime(omc_clock, &tock_tp);
  return (tock_tp.tv_sec - tick_tp[ix].tv_sec) + (tock_tp.tv_nsec - tick_tp[ix].tv_nsec)*1e-9;
}

void rt_clear(int ix)
{
  total_tp[ix].tv_sec += acc_tp[ix].tv_sec;
  total_tp[ix].tv_nsec += acc_tp[ix].tv_nsec;
  rt_clock_ncall_total[ix] += rt_clock_ncall[ix];
  max_tp[ix] = max_rtclock(max_tp[ix],acc_tp[ix]);
  rt_update_min_max_ncall(ix);

  acc_tp[ix].tv_sec = 0;
  acc_tp[ix].tv_nsec = 0;
  rt_clock_ncall[ix] = 0;
}

void rt_clear_total(int ix)
{
  total_tp[ix].tv_sec = 0;
  total_tp[ix].tv_nsec = 0;
  rt_clock_ncall_total[ix] = 0;

  acc_tp[ix].tv_sec = 0;
  acc_tp[ix].tv_nsec = 0;
  rt_clock_ncall[ix] = 0;
}

void rt_accumulate(int ix) {
  struct timespec tock_tp = {0,0};
  clock_gettime(omc_clock, &tock_tp);
  acc_tp[ix].tv_sec += tock_tp.tv_sec -tick_tp[ix].tv_sec;
  acc_tp[ix].tv_nsec += tock_tp.tv_nsec-tick_tp[ix].tv_nsec;
  if(acc_tp[ix].tv_nsec >= 1e9) {
    acc_tp[ix].tv_sec++;
    acc_tp[ix].tv_nsec -= 1e9;
  }
}

static double rtclock_value(rtclock_t tp) {
  return tp.tv_sec + tp.tv_nsec*1e-9;
}

int rtclock_compare(rtclock_t t1, rtclock_t t2) {
  if(t1.tv_sec == t2.tv_sec) {
    return t1.tv_nsec-t2.tv_nsec;
  }
  return t1.tv_sec-t2.tv_sec;
}

#endif

void rt_init(int numTimers) {
  if (numTimers < NUM_RT_CLOCKS)
    return; /* We already have more than we need statically allocated */
  acc_tp = calloc(numTimers, sizeof(rtclock_t));
  max_tp = calloc(numTimers, sizeof(rtclock_t));
  total_tp = calloc(numTimers, sizeof(rtclock_t));
  tick_tp = calloc(numTimers, sizeof(rtclock_t));
  rt_clock_ncall = calloc(numTimers, sizeof(long));
  rt_clock_ncall_total = calloc(numTimers, sizeof(long));
  rt_clock_ncall_min = malloc(numTimers * sizeof(long));
  rt_clock_ncall_max = calloc(numTimers, sizeof(long));
  memset(rt_clock_ncall_min, 0xFF, numTimers * sizeof(long));
  assert(acc_tp != 0);
  assert(max_tp != 0);
  assert(total_tp != 0);
  assert(tick_tp != 0);
  assert(rt_clock_ncall != 0);
  assert(rt_clock_ncall_min != 0);
  assert(rt_clock_ncall_max != 0);
  assert(rt_clock_ncall_total != 0);
}

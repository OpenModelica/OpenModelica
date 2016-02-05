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

#include "rtclock.h"
#include <assert.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include "omc_msvc.h"
#include "memory_pool.h"

/* If min_time is set, subtract this amount from measured times to avoid
 * including the time of measuring in reported statistics */
static double min_time = 0;
static uint32_t default_rt_clock_ncall[NUM_RT_CLOCKS] = { 0 };
static uint32_t default_rt_clock_ncall_min[NUM_RT_CLOCKS] = { 0 };
static uint32_t default_rt_clock_ncall_max[NUM_RT_CLOCKS] = { 0 };
static uint32_t default_rt_clock_ncall_total[NUM_RT_CLOCKS] = { 0 };
static uint32_t *rt_clock_ncall = default_rt_clock_ncall;
static uint32_t *rt_clock_ncall_min = default_rt_clock_ncall_min;
static uint32_t *rt_clock_ncall_max = default_rt_clock_ncall_max;
static uint32_t *rt_clock_ncall_total = default_rt_clock_ncall_total;

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

uint32_t rt_ncall(int ix) {
  return rt_clock_ncall[ix];
}

uint32_t* rt_ncall_arr(int ix) {
  return rt_clock_ncall+ix;
}

uint32_t rt_ncall_min(int ix) {
  return rt_clock_ncall_min[ix];
}

uint32_t rt_ncall_max(int ix) {
  return rt_clock_ncall_max[ix];
}

uint32_t rt_ncall_total(int ix) {
  return rt_clock_ncall_total[ix];
}

void rt_update_min_max_ncall(int ix) {
  unsigned long nmin = rt_clock_ncall_min[ix];
  unsigned long nmax = rt_clock_ncall_max[ix];
  unsigned long n = rt_clock_ncall[ix];
  if (n == 0) {
    return;
  }
  rt_clock_ncall_min[ix] = nmin && nmin < n ? nmin : n;
  rt_clock_ncall_max[ix] = nmax > n ? nmax : n;
}

void rt_clear_total_ncall(int ix) {
  rt_clock_ncall[ix] = 0;
  rt_clock_ncall_total[ix] = 0;
  rt_clock_ncall_min[ix] = UINT32_MAX;
  rt_clock_ncall_max[ix] = 0;
}

double rt_accumulated(int ix) {
  double d = rtclock_value(acc_tp[ix]);
  if (d == 0) {
    return d;
  }
  if (d > 0 && d < min_time * rt_clock_ncall[ix]) {
    min_time = d / rt_clock_ncall[ix];
  }
  return d - min_time * rt_clock_ncall[ix];
}

double rt_max_accumulated(int ix) {
  double d = rtclock_value(max_tp[ix]);
  if (d == 0) {
    return d;
  }
  if (d > 0 && d < min_time) {
    min_time = d;
  }
  return d - min_time;
}

double rt_total(int ix) {
  double d = rtclock_value(total_tp[ix]);
  if (d == 0) {
    return d;
  }
  d = d - min_time * rt_clock_ncall_total[ix];
  assert(d >= 0);
  return d;
}

#if defined(__MINGW32__) || defined(_MSC_VER)

static enum omc_rt_clock_t selectedClock = OMC_CLOCK_REALTIME;

#if !defined(_MSC_VER)
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
  if (newClock != OMC_CLOCK_REALTIME && newClock != OMC_CPU_CYCLES) {
    return 1;
  }

  selectedClock = newClock;
  return 0;
}

static LARGE_INTEGER performance_frequency;

void rt_tick(int ix) {
  if(selectedClock == OMC_CLOCK_REALTIME) {
    static int init = 0;
    if (!init) {

      init = 1;
      QueryPerformanceFrequency(&performance_frequency);
    }
    QueryPerformanceCounter(&tick_tp[ix]);
  } else {
    LARGE_INTEGER time;
    time.QuadPart = RDTSC();
    tick_tp[ix] = time;
  }
  rt_clock_ncall[ix]++;
}

double rt_tock(int ix) {
  double d;
  if(selectedClock == OMC_CLOCK_REALTIME) {
    LARGE_INTEGER tock_tp;
    double d1, d2;
    QueryPerformanceCounter(&tock_tp);
    d1 = (double) (tock_tp.QuadPart - tick_tp[ix].QuadPart);
    d2 = (double) performance_frequency.QuadPart;
    d = d1 / d2;
  } else {
    LARGE_INTEGER tock_tp;
    tock_tp.QuadPart = RDTSC();
    d = (double) (tock_tp.QuadPart - tick_tp[ix].QuadPart);
  }
  if (d < min_time) {
    min_time = d;
  }
  return d - min_time;
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
  if(selectedClock == OMC_CLOCK_REALTIME) {
    LARGE_INTEGER tock_tp;
    QueryPerformanceCounter(&tock_tp);
    acc_tp[ix].QuadPart += tock_tp.QuadPart - tick_tp[ix].QuadPart;
  } else {
    LARGE_INTEGER tock_tp;
    tock_tp.QuadPart = RDTSC();
    acc_tp[ix].QuadPart += tock_tp.QuadPart - tick_tp[ix].QuadPart;
  }
}

int rtclock_compare(rtclock_t t1, rtclock_t t2) {
  return t1.QuadPart - t2.QuadPart;
}

double rtclock_value(LARGE_INTEGER tp) {
  if(selectedClock == OMC_CLOCK_REALTIME) {
    double d1, d2;
    d1 = (double) (tp.QuadPart);
    d2 = (double) performance_frequency.QuadPart;
    return d1 / d2;
  } else {
    return (double) (tp.QuadPart);
  }
}

void rt_ext_tp_tick(rtclock_t* tick_tp) {
  if(selectedClock == OMC_CLOCK_REALTIME) {
    static int init = 0;
    if (!init) {

      init = 1;
      QueryPerformanceFrequency(&performance_frequency);
    }
    QueryPerformanceCounter(tick_tp);
  } else {
    LARGE_INTEGER time;
    time.QuadPart = RDTSC();
    *tick_tp = time;
  }
}

double rt_ext_tp_tock(rtclock_t* tick_tp) {
  double d;
  if(selectedClock == OMC_CLOCK_REALTIME) {
    LARGE_INTEGER tock_tp;
    double d1, d2;
    QueryPerformanceCounter(&tock_tp);
    d1 = (double) (tock_tp.QuadPart - tick_tp->QuadPart);
    d2 = (double) performance_frequency.QuadPart;
    d = d1 / d2;
  } else {
    LARGE_INTEGER tock_tp;
    tock_tp.QuadPart = RDTSC();
    d = (double) (tock_tp.QuadPart - tick_tp->QuadPart);
  }
  if (d < min_time) {
    min_time = d;
  }
  return d - min_time;
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
  double d = elapsednano * 1e-9;
  if (d < min_time) {
    min_time = d;
  }
  return d - min_time;
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

void rt_ext_tp_tick(rtclock_t* tick_tp) {
  *tick_tp = mach_absolute_time();
}

double rt_ext_tp_tock(rtclock_t* tick_tp) {
  uint64_t tock_tp = mach_absolute_time();
  uint64_t nsec;
  static mach_timebase_info_data_t info = {0,0};
  if(info.denom == 0)
  mach_timebase_info(&info);
  uint64_t elapsednano = (tock_tp-*tick_tp) * (info.numer / info.denom);
  double d = elapsednano * 1e-9;
  if (d < min_time) {
    min_time = d;
  }
  return d - min_time;
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

#if defined(__i386__)
static inline unsigned long long RDTSC(void)
{
  unsigned long long int x;
  __asm__ volatile (".byte 0x0f, 0x31" : "=A" (x));
  return x;
}
#elif defined(__x86_64__)
static inline unsigned long long RDTSC(void)
{
  unsigned hi, lo;
  __asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));
  return ( (unsigned long long)lo)|( ((unsigned long long)hi)<<32 );
}
#else
#include <stdio.h>

static inline unsigned long long RDTSC(void)
{
  fprintf(stderr, "No CPU clock implemented on this processor architecture\n");
  abort();
}
#endif

void rt_tick(int ix) {
  if(omc_clock == OMC_CPU_CYCLES) {
    tick_tp[ix].cycles = RDTSC();
  } else {
    clock_gettime(omc_clock, &tick_tp[ix].time);
  }
  rt_clock_ncall[ix]++;
}

double rt_tock(int ix) {
  double d;
  if(omc_clock == OMC_CPU_CYCLES) {
    unsigned long long timer = RDTSC();
    d = (double) (timer - tick_tp[ix].cycles);
  } else {
    struct timespec tock_tp = {0,0};
    clock_gettime(omc_clock, &tock_tp);
    d = (tock_tp.tv_sec - tick_tp[ix].time.tv_sec) + (tock_tp.tv_nsec - tick_tp[ix].time.tv_nsec)*1e-9;
    if (d < min_time) {
      min_time = d;
    }
  }
  return d - min_time;
}

void rt_clear(int ix)
{
  if(omc_clock == OMC_CPU_CYCLES) {
    total_tp[ix].cycles += acc_tp[ix].cycles;
    rt_clock_ncall_total[ix] += rt_clock_ncall[ix];
    max_tp[ix] = max_rtclock(max_tp[ix],acc_tp[ix]);
    rt_update_min_max_ncall(ix);

    acc_tp[ix].cycles = 0;
    acc_tp[ix].cycles = 0;
    rt_clock_ncall[ix] = 0;
  } else {
    total_tp[ix].time.tv_sec += acc_tp[ix].time.tv_sec;
    total_tp[ix].time.tv_nsec += acc_tp[ix].time.tv_nsec;
    rt_clock_ncall_total[ix] += rt_clock_ncall[ix];
    max_tp[ix] = max_rtclock(max_tp[ix],acc_tp[ix]);
    rt_update_min_max_ncall(ix);

    acc_tp[ix].time.tv_sec = 0;
    acc_tp[ix].time.tv_nsec = 0;
    rt_clock_ncall[ix] = 0;
  }
}

void rt_clear_total(int ix)
{
  if(omc_clock == OMC_CPU_CYCLES) {
    total_tp[ix].cycles = 0;
    rt_clock_ncall_total[ix] = 0;

    acc_tp[ix].cycles = 0;
    rt_clock_ncall[ix] = 0;
  } else {
    total_tp[ix].time.tv_sec = 0;
    total_tp[ix].time.tv_nsec = 0;
    rt_clock_ncall_total[ix] = 0;

    acc_tp[ix].time.tv_sec = 0;
    acc_tp[ix].time.tv_nsec = 0;
    rt_clock_ncall[ix] = 0;
  }
}

void rt_accumulate(int ix) {
  if(omc_clock == OMC_CPU_CYCLES) {
    long long cycles = RDTSC();
    acc_tp[ix].cycles += cycles -tick_tp[ix].cycles;
  } else {
    struct timespec tock_tp = {0,0};
    clock_gettime(omc_clock, &tock_tp);
    acc_tp[ix].time.tv_sec += tock_tp.tv_sec -tick_tp[ix].time.tv_sec;
    acc_tp[ix].time.tv_nsec += tock_tp.tv_nsec-tick_tp[ix].time.tv_nsec;
    if(acc_tp[ix].time.tv_nsec >= 1e9) {
      acc_tp[ix].time.tv_sec++;
      acc_tp[ix].time.tv_nsec -= 1e9;
    }
  }
}

static double rtclock_value(rtclock_t tp) {
  double d;
  if(omc_clock == OMC_CPU_CYCLES) {
    d = tp.cycles;
  } else {
    d = tp.time.tv_sec + tp.time.tv_nsec*1e-9;
  }
  return d;
}

int rtclock_compare(rtclock_t t1, rtclock_t t2)
{
  if(omc_clock == OMC_CPU_CYCLES) {
    return t1.cycles-t2.cycles;
  } else {
    if(t1.time.tv_sec == t2.time.tv_sec) {
      return t1.time.tv_nsec-t2.time.tv_nsec;
    }
    return t1.time.tv_sec-t2.time.tv_sec;
  }
}

void rt_ext_tp_tick(rtclock_t* tick_tp) {
  if(omc_clock == OMC_CPU_CYCLES) {
    tick_tp->cycles = RDTSC();
  } else {
    clock_gettime(omc_clock, &tick_tp->time);
  }
}

double rt_ext_tp_tock(rtclock_t* tick_tp) {
  double d;
  if(omc_clock == OMC_CPU_CYCLES) {
    unsigned long long timer = RDTSC();
    d = (double) (timer - tick_tp->cycles);
  } else {
    struct timespec tock_tp = {0,0};
    clock_gettime(omc_clock, &tock_tp);
    d = (tock_tp.tv_sec - tick_tp->time.tv_sec) + (tock_tp.tv_nsec - tick_tp->time.tv_nsec)*1e-9;
    if (d < min_time) {
      min_time = d;
    }
  }
  return d - min_time;
}

#endif

static OMC_INLINE void alloc_and_copy(void **ptr, size_t n, size_t sz)
{
  void *newmemory = omc_alloc_interface.malloc(n*sz);
  assert(newmemory != 0);
  memcpy(newmemory,*ptr,NUM_RT_CLOCKS*sz);
  *ptr = newmemory;
}

void rt_init(int numTimers) {
  if (numTimers < NUM_RT_CLOCKS) {
    return; /* We already have more than we need statically allocated */
  }
  alloc_and_copy((void**)&acc_tp,numTimers,sizeof(rtclock_t));
  alloc_and_copy((void**)&max_tp,numTimers,sizeof(rtclock_t));
  alloc_and_copy((void**)&total_tp,numTimers,sizeof(rtclock_t));
  alloc_and_copy((void**)&tick_tp,numTimers,sizeof(rtclock_t));
  alloc_and_copy((void**)&rt_clock_ncall,numTimers,sizeof(uint32_t));
  alloc_and_copy((void**)&rt_clock_ncall_total,numTimers,sizeof(uint32_t));
  alloc_and_copy((void**)&rt_clock_ncall_min,numTimers,sizeof(uint32_t));
  alloc_and_copy((void**)&rt_clock_ncall_max,numTimers,sizeof(uint32_t));
  /* This memset-command is not working properly, especially on windows.
   * It's writing into the rt_clock_ncall_total-array and thus the values are wrong.
   * However, the profiling-functionality seems to work without it. */
  //memset(rt_clock_ncall_min + NUM_RT_CLOCKS*sizeof(uint32_t), 0xFF, (numTimers-NUM_RT_CLOCKS) * sizeof(uint32_t));
}

void rt_measure_overhead(int ix)
{
  int i;
  min_time = 0;
  rt_tick(ix);
  min_time = rt_tock(ix);
  for (i=0; i<300; i++) {
    rt_tick(ix);
    rt_tock(ix);
  }
}

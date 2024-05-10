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
#ifndef __RTCLOCK__H
#define __RTCLOCK__H

#ifdef __cplusplus
extern "C" {
#endif

#define NUM_RT_CLOCKS 33
#define NUM_USER_RT_CLOCKS 32
#define RT_CLOCK_SPECIAL_STOPWATCH 32 /* The 33rd clock */

/* Simulation-specific timing macros */
#define SIM_TIMER_TOTAL          0
#define SIM_TIMER_INIT           1
#define SIM_TIMER_STEP           2
#define SIM_TIMER_OUTPUT         3
#define SIM_TIMER_EVENT          4
#define SIM_TIMER_JACOBIAN       5
#define SIM_TIMER_PREINIT        6
#define SIM_TIMER_OVERHEAD       7
#define SIM_TIMER_FUNCTION_ODE   8
#define SIM_TIMER_RESIDUALS      9
#define SIM_TIMER_ALGEBRAICS     10
#define SIM_TIMER_ZC             11
#define SIM_TIMER_SOLVER         12
#define SIM_TIMER_INIT_XML       13
#define SIM_TIMER_INFO_XML       14
#define SIM_TIMER_DAE            15
#define SIM_TIMER_FIRST_FUNCTION 16

#if defined(OMC_MINIMAL_RUNTIME)

typedef int rtclock_t;
static inline void rt_ext_tp_tick(rtclock_t* tick_tp) {}
static inline double rt_ext_tp_tock(rtclock_t* tick_tp) {return 0.0;}
static inline void rt_tick(int ix) {}
static inline void rt_accumulate(int ix) {}
static inline void rt_clear(int ix) {}
static inline double rt_tock(int ix) {return 0.0;}

#else

#include <stdint.h>

#define SIM_PROF_TICK_FN(ix) rt_tick(ix+SIM_TIMER_FIRST_FUNCTION)
#define SIM_PROF_ACC_FN(ix) rt_accumulate(ix+SIM_TIMER_FIRST_FUNCTION)

/* These functions are used for profileBlocks, not for equations */
#define SIM_PROF_TICK_EQ(ix) rt_tick(ix+SIM_TIMER_FIRST_FUNCTION+data->modelData->modelDataXml.nFunctions)
#define SIM_PROF_ACC_EQ(ix) rt_accumulate(ix+SIM_TIMER_FIRST_FUNCTION+data->modelData->modelDataXml.nFunctions)
#define SIM_PROF_ADD_NCALL_EQ(ix,num) rt_add_ncall(ix+SIM_TIMER_FIRST_FUNCTION+data->modelData->modelDataXml.nFunctions,num)

#define SIM_PROF_TICK_EQEXT(ix) rt_tick(ix+SIM_TIMER_FIRST_FUNCTION+data->modelData->modelDataXml.nFunctions+data->modelData->modelDataXml.nProfileBlocks)
#define SIM_PROF_ACC_EQEXT(ix) rt_accumulate(ix+SIM_TIMER_FIRST_FUNCTION+data->modelData->modelDataXml.nFunctions+data->modelData->modelDataXml.nProfileBlocks)
#define SIM_PROF_ACCED_EQEXT(ix) rt_accumulated(ix+SIM_TIMER_FIRST_FUNCTION+data->modelData->modelDataXml.nFunctions+data->modelData->modelDataXml.nProfileBlocks)
#define SIM_PROF_NCALL_EQEXT(ix) rt_ncall(ix+SIM_TIMER_FIRST_FUNCTION+data->modelData->modelDataXml.nFunctions+data->modelData->modelDataXml.nProfileBlocks)

enum omc_rt_clock_t {
  OMC_CLOCK_REALTIME, /* CLOCK_MONOTONIC_RAW if available; else CLOCK_MONOTONIC */
  OMC_CLOCK_CPUTIME, /* Per-process CPU-time */
  OMC_CPU_CYCLES /* Number of CPU-Cycles */
};

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
typedef union rtclock_t {
  struct timespec time;
  unsigned long long cycles;
} rtclock_t;
#endif

int rt_set_clock(enum omc_rt_clock_t clockType); /* non-zero on failure */
enum omc_rt_clock_t rt_get_clock(); /* non-zero on failure */
void rt_init(int numTimer);

void rt_tick(int ix);
/* tick() ... tock() -> returns the number of seconds since the tick */
double rt_tock(int ix);

/* clear() ... tick() ... accumulate() ... tick() ... accumulate() ... accumuluated()
 * returns the total number of seconds accumulated between the tick() and accumulate() calls */
void rt_clear_total(int ix);
/* clear zeros out the accumulated data, and adds it to the total (we have two levels of accumulation) */
void rt_clear(int ix);
void rt_accumulate(int ix); /* Uses integer addition for maximum accuracy and good speed. */
double rt_accumulated(int ix);
double rt_max_accumulated(int ix);
double rt_total(int ix);
/* Returns the number of times tick() was called since the last clear() */
uint32_t rt_ncall(int ix);
uint32_t* rt_ncall_arr(int offsetIndex);
uint32_t rt_ncall_min(int ix);
uint32_t rt_ncall_max(int ix);
uint32_t rt_ncall_total(int ix);
void rt_add_ncall(int ix, int n);

void rt_measure_overhead(int ix);

/* tick() ... tock() with external rtclock_t -> returns the number of seconds since the tick */
void rt_ext_tp_tick(rtclock_t* tick_tp);
void rt_ext_tp_tick_realtime(rtclock_t* tick_tp);
double rt_ext_tp_tock(rtclock_t* tick_tp);
/* sleep nsec nanoseconds since the call to tick_tp. Returns the number of nanoseconds we are late for the deadline. */
int64_t rt_ext_tp_sync_nanosec(rtclock_t* tick_tp, uint64_t nsec);

#endif

#ifdef __cplusplus
}
#endif

#endif

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

/* Stack overflow handling */

#ifndef META_MODELICA_SEGV_H_
#define META_MODELICA_SEGV_H_

#include <pthread.h>
#include <setjmp.h>
#define MMC_INIT_STACK_OVERFLOW()
#define MMC_TRY_STACK() { jmp_buf *oldMMCJumper = threadData->mmc_jumper; { MMC_TRY_INTERNAL(mmc_stack_overflow_jumper) threadData->mmc_jumper = &new_mmc_jumper; threadData->mmc_stack_overflow_jumper = &new_mmc_jumper;
#define MMC_ELSE_STACK() } else { threadData->mmc_jumper = oldMMCJumper; threadData->mmc_jumper = old_jumper;
#define MMC_CATCH_STACK() MMC_CATCH_INTERNAL(mmc_stack_overflow_jumper) } threadData->mmc_jumper = oldMMCJumper; }

void printStacktraceMessages();
void mmc_setStacktraceMessages(int numSkip, int numFrames);
void mmc_setStacktraceMessages_threadData(threadData_t *threadData, int numSkip, int numFrames);
void init_metamodelica_segv_handler();
void mmc_init_stackoverflow(threadData_t *threadData);

#ifndef __has_builtin
  #define __has_builtin(x) 0  /* Compatibility with non-clang compilers */
#endif

/* Does not work very well with many stack frames because we are close to the stack end when we need this data... */
#define MMC_SEGV_TRACE_NFRAMES 1024

static inline void mmc_check_stackoverflow(threadData_t *threadData)
{
#if __has_builtin(__builtin_frame_address) || defined(__GNUC__)
  if (__builtin_frame_address(0) < threadData->stackBottom)
#else
  /* No way of getting the frame address except hoping for the best */
  int addr;
  if ((void*) &addr < threadData->stackBottom)
#endif
  {
    /* Do the jump */
    mmc_setStacktraceMessages_threadData(threadData, 1, MMC_SEGV_TRACE_NFRAMES);
    longjmp(*threadData->mmc_stack_overflow_jumper, 1);
  }
}

#define MMC_SO() mmc_check_stackoverflow(threadData)

#endif

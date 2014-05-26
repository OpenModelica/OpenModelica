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

#include "omc_msvc.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#if defined(__MINGW32__) || defined(_MSC_VER)
#include <windows.h>
#include <time.h>

int asprintf(char **strp, const char *fmt, ...) {
  int len;
  va_list ap;
  va_start(ap, fmt);

  len = vsnprintf(NULL, 0, fmt, ap);
  *strp = malloc(len+1);
  len = vsnprintf(*strp, len+1, fmt, ap);

  va_end(ap);
  return len;
}

int vasprintf(char **strp, const char *fmt, va_list ap) {
  int len;
  len = vsnprintf(NULL, 0, fmt, ap);
  *strp = malloc(len+1);
  len = vsnprintf(*strp, len+1, fmt, ap);
  return len;
}

#ifndef SIGALRM
#define SIGALRM         SIGTERM
#endif

static HANDLE thread    = 0; // thread handle

static DWORD WINAPI killProcess (LPVOID arg)
{
  Sleep (1000 * ((unsigned int)arg));
  fprintf(stdout, "Killed"); fflush(NULL);
  TerminateProcess(GetCurrentProcess(), 1);
  return 0;
}

unsigned int alarm (unsigned int seconds)
{
  static unsigned pending = 0;   // previous alarm() argument
  static time_t t0        = 0;   // start of previous alarm()
  time_t unslept          = 0;   // seconds until previous alarm expires

  if (thread) {
      // previous alarm is still pending, cancel it
      unslept = pending - (time (0) - t0);
      TerminateThread (thread, 0);
      CloseHandle (thread);
      thread = 0;
  }

  pending = seconds;

  if (seconds) {
      time (&t0);   // keep track of when count down started
      DWORD threadId;
      thread = CreateThread (0, 0, killProcess, (void*)seconds, 0, &threadId);
  }

  return (unsigned int)(unslept);
}

#endif

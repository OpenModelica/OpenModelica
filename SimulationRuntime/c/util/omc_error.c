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

#include "setjmp.h"
#include <stdio.h>
#include "omc_error.h"
/* For MMC_THROW, so we can end this thing */
#include "meta_modelica.h"

/* Global JumpBuffer */
jmp_buf globalJmpbuf;

const char *LOG_STREAM_NAME[LOG_MAX] = {
  "LOG_UNKNOWN",
  "LOG_STDOUT",
  "LOG_UTIL",
  "LOG_SIMULATION",
  "LOG_STATS",
  "LOG_INIT",
  "LOG_SOTI",  /* LOG_INIT_SOLUTION */
  "LOG_RES_INIT",
  "LOG_SOLVER",
  "LOG_DDASRT",
  "LOG_JAC",
  "LOG_ENDJAC",
  "LOG_NONLIN_SYS",
  "LOG_NONLIN_SYS_V",
  "LOG_EVENTS",
  "LOG_ZEROCROSSINGS",
  "LOG_DEBUG",
  "LOG_ASSERT",
};

const char *LOG_STREAM_DESC[LOG_MAX] = {
  "unknown",
  "stdout",
  "util",
  "simulation",
  "stats",
  "init",
  "init solution",
  "res_init",
  "solver",
  "ddasrt",
  "jac",
  "endjac",
  "nonlin_sys",
  "nonlin_sys_v",
  "events",
  "zerocrossings",
  "debug",
  ""
};

static const char *LOG_TYPE_DESC[LOG_TYPE_MAX] = {
  "unknown",
  "info",
  "warning",
  "error",
  "assert",
  "debug"
};

int useStream[LOG_MAX];
int level[LOG_MAX];
int lastType[LOG_MAX];
int lastStream = LOG_UNKNOWN;
char logBuffer[2048];

void printInfo(FILE *stream, FILE_INFO info)
{
  fprintf(stream, "[%s:%d:%d-%d:%d:%s]", info.filename, info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly ? "readonly" : "writable");
}

void omc_assert_function(const char *msg, FILE_INFO info)
{
  printInfo(stderr, info);
  fprintf(stderr,"Modelica Assert: %s!\n", msg);
  fflush(NULL);
  MMC_THROW();
}

void omc_assert_warning_function(const char *msg, FILE_INFO info)
{
  printInfo(stderr, info);
  fprintf(stderr,"Warning, assertion triggered: %s!\n", msg);
  fflush(NULL);
}

void omc_throw_function()
{
  MMC_THROW();
}

void omc_terminate_function(const char *msg, FILE_INFO info)
{
  printInfo(stderr, info);
  fprintf(stderr,"Modelica Terminate: %s!\n", msg);
  fflush(NULL);
  MMC_THROW();
}

void Message(int type, int stream, char *msg, int subline)
{
  int i;

  if((type != LOG_TYPE_ERROR) && !useStream[stream])
    return;

  printf("%-13s | ", (subline || (lastStream == stream && level[stream] > 0)) ? "|" : LOG_STREAM_DESC[stream]);
  printf("%-7s | ", (subline || (lastStream == stream && lastType[stream] == type && level[stream] > 0)) ? "|" : LOG_TYPE_DESC[type]);
  lastType[stream] = type;
  lastStream = stream;

  for(i=0; i<level[stream]; ++i)
      printf("| ");
  
  for(i=0; msg[i]; i++)
  {
    if(msg[i] == '\n')
    {
      msg[i] = '\0';
      printf("%s\n", msg);
      Message(type, stream, &msg[i+1], 1);
      return;
    }
  }

  printf("%s\n", msg);
  fflush(NULL);
}

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

const unsigned int LOG_NONE          = 0;
const unsigned int LOG_STATS         = (1<<0);
const unsigned int LOG_INIT          = (1<<1);
const unsigned int LOG_RES_INIT      = (1<<2);
const unsigned int LOG_SOLVER        = (1<<3);
const unsigned int LOG_JAC           = (1<<4);
const unsigned int LOG_ENDJAC        = (1<<5);
const unsigned int LOG_NONLIN_SYS    = (1<<6);
const unsigned int LOG_NONLIN_SYS_V  = (1<<7);  /* verbose */
const unsigned int LOG_EVENTS        = (1<<8);
const unsigned int LOG_ZEROCROSSINGS = (1<<9);
const unsigned int LOG_DEBUG         = (1<<10);

/* Flags for modelErrorCodes */
extern const int ERROR_NONLINSYS = -1;
extern const int ERROR_LINSYS = -2;

unsigned int globalDebugFlags = 0;

void printInfo(FILE *stream, FILE_INFO info) {
  fprintf(stream, "[%s:%d:%d-%d:%d:%s]", info.filename, info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly ? "readonly" : "writable");
}

void omc_assert_function(const char *msg, FILE_INFO info) {
  printInfo(stderr, info);
  fprintf(stderr,"Modelica Assert: %s!\n", msg);
  fflush(NULL);
  MMC_THROW();
}

void omc_assert_warning_function(const char *msg, FILE_INFO info) {
  printInfo(stderr, info);
  fprintf(stderr,"Warning, assertion triggered: %s!\n", msg);
  fflush(NULL);
}

void omc_throw_function() {
  MMC_THROW();
}

void omc_terminate_function(const char *msg, FILE_INFO info) {
  printInfo(stderr, info);
  fprintf(stderr,"Modelica Terminate: %s!\n", msg);
  fflush(NULL);
  MMC_THROW();
}

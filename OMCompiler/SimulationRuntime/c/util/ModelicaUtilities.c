/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include "../ModelicaUtilities.h"
#include "modelica_string.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "omc_error.h"
#include "ModelicaUtilitiesExtra.h"
#include "../gc/omc_rc.h"

void OpenModelica_Simulation_ModelicaVFormatMessage(const char*string, va_list args) {
  va_infoStreamPrint(OMC_LOG_STDOUT, 0, string, args);
}

void OpenModelica_Simulation_ModelicaVFormatWarning(const char*string, va_list args) {
  va_warningStreamPrint(OMC_LOG_STDOUT, 0, string, args);
}

/* Like OpenModelica_Modelica{,V}FormatError below: a host that runs the
   simulation in its own process (the Rust omc's wasm-jit target) rebinds these
   to route an external function's messages into its simulation log. */
void (*OpenModelica_ModelicaVFormatMessage)(const char*,va_list) = OpenModelica_Simulation_ModelicaVFormatMessage;
void (*OpenModelica_ModelicaVFormatWarning)(const char*,va_list) = OpenModelica_Simulation_ModelicaVFormatWarning;

void ModelicaMessage(const char* string) {
  ModelicaFormatMessage("%s", string);
}

extern void ModelicaVFormatMessage(const char*string, va_list args) {
  OpenModelica_ModelicaVFormatMessage(string, args);
}

void ModelicaFormatMessage(const char* string,...) {
  va_list args;
  va_start(args, string);
  ModelicaVFormatMessage(string, args);
  va_end(args);
}

void ModelicaWarning(const char* string) {
  ModelicaFormatWarning("%s", string);
}

extern void ModelicaVFormatWarning(const char*string, va_list args) {
  OpenModelica_ModelicaVFormatWarning(string, args);
}

void ModelicaFormatWarning(const char* string,...) {
  va_list args;
  va_start(args, string);
  ModelicaVFormatWarning(string, args);
  va_end(args);
}

MODELICA_NORETURN void OpenModelica_Simulation_ModelicaError(const char* string) MODELICA_NORETURNATTR;
void OpenModelica_Simulation_ModelicaError(const char* string) {
  throwStreamPrint(NULL, "%s", string);
}

MODELICA_NORETURN void OpenModelica_Simulation_ModelicaVFormatError(const char*string, va_list args) MODELICA_NORETURNATTR;
void OpenModelica_Simulation_ModelicaVFormatError(const char*string, va_list args) {
  va_throwStreamPrint(NULL, string, args);
}

void (*OpenModelica_ModelicaError)(const char*) MODELICA_NORETURNATTR = OpenModelica_Simulation_ModelicaError;
void (*OpenModelica_ModelicaVFormatError)(const char*,va_list) MODELICA_NORETURNATTR = OpenModelica_Simulation_ModelicaVFormatError;

void ModelicaError(const char* string) {
  OpenModelica_ModelicaError(string);
  abort();  // Silence invalid noreturn warning. This is never reached.
}

void ModelicaVFormatError(const char*string, va_list args) {
  OpenModelica_ModelicaVFormatError(string,args);
  abort();  // Silence invalid noreturn warning. This is never reached.
}

/* omc installs its own error handlers, but a function library dlopened into it
   links its own runtime and so its own copies of these. */
void omc_set_modelica_error_handlers(void (*err)(const char*), void (*verr)(const char*,va_list))
{
  if (err) {
    OpenModelica_ModelicaError = err;
  }
  if (verr) {
    OpenModelica_ModelicaVFormatError = verr;
  }
}

void ModelicaFormatError(const char* string, ...) {
  va_list args;
  va_start(args, string);
  OpenModelica_ModelicaVFormatError(string,args);
  va_end(args);
  abort();  // Silence invalid noreturn warning. This is never reached.
}

#if defined(OMC_METAMODELICA_RUNTIME)

size_t omc_external_strings_mark(void) { return 0; }
void omc_external_strings_release(size_t mark) { (void) mark; }
#define omc_external_strings_push(P) ((void) (P))

#else

#if defined(_MSC_VER)
#define OMC_THREAD_LOCAL __declspec(thread)
#else
#define OMC_THREAD_LOCAL __thread
#endif

/* A fixed per-thread array; the heap is touched only by a call that overflows
   it, and that is freed once the call drains. */
#define OMC_EXT_STRINGS_FIXED 64

static OMC_THREAD_LOCAL void *extStringsFixed[OMC_EXT_STRINGS_FIXED];
static OMC_THREAD_LOCAL void **extStringsHeap = NULL;
static OMC_THREAD_LOCAL size_t extStringsUsed = 0;
static OMC_THREAD_LOCAL size_t extStringsSize = OMC_EXT_STRINGS_FIXED;

static void omc_external_strings_push(void *p)
{
  if (extStringsUsed == extStringsSize) {
    size_t grown = 2*extStringsSize;
    void **buf = (void**) realloc(extStringsHeap, grown*sizeof(void*));
    if (!buf) {
      mmc_do_out_of_memory();
    }
    if (!extStringsHeap) {
      memcpy(buf, extStringsFixed, OMC_EXT_STRINGS_FIXED*sizeof(void*));
    }
    extStringsHeap = buf;
    extStringsSize = grown;
  }
  (extStringsHeap ? extStringsHeap : extStringsFixed)[extStringsUsed++] = p;
}

size_t omc_external_strings_mark(void)
{
  return extStringsUsed;
}

void omc_external_strings_release(size_t mark)
{
  void **buf = extStringsHeap ? extStringsHeap : extStringsFixed;

  while (extStringsUsed > mark) {
    omc_rc_release_inline(buf[--extStringsUsed]);
  }
  if (extStringsUsed == 0 && extStringsHeap) {
    free(extStringsHeap);
    extStringsHeap = NULL;
    extStringsSize = OMC_EXT_STRINGS_FIXED;
  }
}

#endif

char* ModelicaAllocateString(size_t len) {
  char *res = ModelicaAllocateStringWithErrorReturn(len);
  if (!res) {
    ModelicaFormatError("%s:%d: ModelicaAllocateString failed", __FILE__, __LINE__);
  }
  return res;
}

char* ModelicaAllocateStringWithErrorReturn(size_t len) {
  char *res = omc_alloc_interface.malloc_string(len+1);
  if (res != NULL) {
    res[len] = '\0';
    omc_external_strings_push(res);
  }
  return res;
}

char* ModelicaDuplicateString(const char *str) {
  char *res = omc_alloc_interface.malloc_strdup(str);
  if (!res) {
    ModelicaFormatError("%s:%d: ModelicaAllocateString failed", __FILE__, __LINE__);
  }
  omc_external_strings_push(res);
  return res;
}

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

#include "../ModelicaUtilities.h"
#include "modelica_string.h"

#include <stdio.h>
#include <stdlib.h>
#include "omc_error.h"

void ModelicaMessage(const char* string) {
  ModelicaFormatMessage("%s", string);
}

extern void ModelicaVFormatMessage(const char*string, va_list args) {
  va_infoStreamPrint(LOG_STDOUT, 0, string, args);
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
  va_warningStreamPrint(LOG_STDOUT, 0, string, args);
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

void ModelicaFormatError(const char* string, ...) {
  va_list args;
  va_start(args, string);
  OpenModelica_ModelicaVFormatError(string,args);
  va_end(args);
  abort();  // Silence invalid noreturn warning. This is never reached.
}

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
  }
  return res;
}

char* ModelicaDuplicateString(const char *str) {
  char *res = omc_alloc_interface.malloc_strdup(str);
  if (!res) {
    ModelicaFormatError("%s:%d: ModelicaAllocateString failed", __FILE__, __LINE__);
  }
  return res;
}

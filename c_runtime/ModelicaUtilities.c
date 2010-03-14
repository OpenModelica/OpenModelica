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

#include "ModelicaUtilities.h"
#include "modelica_string.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

void ModelicaMessage(const char* string) {
  ModelicaFormatMessage("%s", string);
}

void ModelicaFormatMessage(const char* string,...) {
  va_list args;
  va_start(args, string);
  vfprintf(stdout, string, args);
  va_end(args);
  fflush(stdout);
}

void ModelicaError(const char* string) {
  ModelicaFormatError("%s", string);
}

void ModelicaFormatError(const char* string, ...) {
  va_list args;
  va_start(args, string);
  vfprintf(stderr, string, args);
  va_end(args);
  fflush(stderr);
}

char* ModelicaAllocateString(size_t len) {
  char* res;
  alloc_modelica_string(&res,len);
  return res;
}

char* ModelicaAllocateStringWithErrorReturn(size_t len) {
  char* res;
  alloc_modelica_string(&res,len);
  return res;
}

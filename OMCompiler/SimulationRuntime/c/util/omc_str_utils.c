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


/* Plain C string helpers: no Modelica or MetaModelica string type involved, so
   both runtimes use them. */

#include "omc_str_utils.h"
#include "../gc/omc_gc.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int omc__escapedStringLength(const char* str, int nl, int *hasEscape)
{
  int i=0;
  while(*str) {
    switch (*str) {
      case '"':
      case '\\':
      case '\a':
      case '\b':
      case '\f':
      case '\v': i++; *hasEscape=1; break;
      case '\r':
      case '\n': if(nl) {i++; *hasEscape=1;} break;
      default: break;
    }
    i++;
    str++;
  }
  return i;
}

/* "\b",_ => "\\b"
 * "\n",true => "\\n"
 */
extern char* omc__escapedString(const char* str, int nl)
{
  int len;
  char *res;
  const char *origstr = str;
  int i=0;
  int hasEscape = 0;
  len = omc__escapedStringLength(str,nl,&hasEscape);
  if (!hasEscape) {
    return NULL;
  }
  res = (char*) omc_alloc_interface.malloc_atomic(len+1);
  while(*str) {
    switch (*str) {
      case '"': res[i++] = '\\'; res[i++] = '"'; break;
      case '\\': res[i++] = '\\'; res[i++] = '\\'; break;
      case '\a': res[i++] = '\\'; res[i++] = 'a'; break;
      case '\b': res[i++] = '\\'; res[i++] = 'b'; break;
      case '\f': res[i++] = '\\'; res[i++] = 'f'; break;
      case '\v': res[i++] = '\\'; res[i++] = 'v'; break;
      case '\r': if(nl) {res[i++] = '\\'; res[i++] = 'r';} else {res[i++] = *str;} break;
      case '\n': if(nl) {res[i++] = '\\'; res[i++] = 'n';} else {res[i++] = *str;} break;
      default: res[i++] = *str;
    }
    str++;
  }
  res[i] = '\0';
  return res;
}

int GC_vasprintf(const char **strp, const char *fmt, va_list ap) {
  int len;
  char *tmp;
  if (0==strstr(fmt, "%")) {
    /* A no-op; we don't actually create a copy of the string which might be unexpected... */
    *strp = fmt;
    return strlen(fmt);
  }
  va_list ap2;
  va_copy(ap2, ap);
  len = vsnprintf(NULL, 0, fmt, ap);
  tmp = mmc_check_out_of_memory(omc_alloc_interface.malloc_atomic(len+1));
  len = vsnprintf(tmp, len+1, fmt, ap2);
  *strp = tmp;
  return len;
}

int GC_asprintf(const char **strp, const char *fmt, ...) {
  int len;
  va_list ap;
  va_start(ap, fmt);

  len = GC_vasprintf(strp, fmt, ap);

  va_end(ap);
  return len;
}


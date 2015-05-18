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


#include "modelica_string.h"
#include "memory_pool.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "gc.h"
#include "meta/meta_modelica.h"

#define FMT_BUFSIZE 400

static const FILE_INFO dummyFILE_INFO = omc_dummyFileInfo;

static inline void checkBufSize(const char *str, int n)
{
  if (n >= FMT_BUFSIZE) {
    omc_assert(NULL, dummyFILE_INFO, "Could not parse format string; ran out of buffer size (%d): %s", FMT_BUFSIZE, str);
  }
}

modelica_string modelica_string_format_to_c_string_format(modelica_string format)
{
  char buf[FMT_BUFSIZE];
  const char *str = MMC_STRINGDATA(format), *tmp = str;
  int cont=1, n=0;
  buf[n++] = '%';
  while (cont) { /* Parse flag characters */
    switch (*tmp) {
    /* Extended flags? ',I */
    case '#':
    case '0':
    case '-':
    case ' ':
    case '+':
      buf[n] = *(tmp++);
      checkBufSize(str, n++);
      break;
    default:
      cont = 0;
    }
  }
  // width: [1-9][0-9]*
  if ((*tmp >= '1') || (*tmp <= '9')) {
    while (*tmp >= '0' && *tmp <= '9') {
      buf[n] = *(tmp++);
      checkBufSize(str, n++);
    }
  }
  // precision: .[0-9]*
  if (*tmp == '.') {
    buf[n] = *(tmp++);
    checkBufSize(str, n++);
    while (*tmp >= '0' && *tmp <= '9') {
      buf[n] = *(tmp++);
      checkBufSize(str, n++);
    }
  }

  switch (*tmp) {
  case 'f':
  case 'e':
  case 'E':
  case 'g':
  case 'G':
    /* double */
  case 'c':
    /* int */
    buf[n] = *(tmp++);
    checkBufSize(str, n++);
    break;
  case 'd':
  case 'i':
    /* int */
  case 'o':
  case 'x':
  case 'X':
  case 'u':
    /* uint */
    buf[n] = 'l'; /* we use long in OpenModelica */
    checkBufSize(str, n++);
    buf[n] = *(tmp++);
    checkBufSize(str, n++);
    break;
  case 'h':
  case 'l':
  case 'L':
  case 'q':
  case 'j':
  case 'z':
  case 't':
    omc_assert(NULL, dummyFILE_INFO, "Length modifiers are not legal in Modelica format strings: %s", str);
    break;
  default:
    omc_assert(NULL, dummyFILE_INFO, "Could not parse format string: invalid conversion specifier: %c in %s", *tmp, str);
  }
  if (*tmp) {
    omc_assert(NULL, dummyFILE_INFO, "Could not parse format string: trailing data after the format directive", *tmp, str);
  }
  buf[n] = '\0';
  return mmc_mk_scon(buf);
}

/* Convert a modelica_integer to a modelica_string, used in String(integer, format="xxx") */
modelica_string modelica_integer_to_modelica_string_format(modelica_integer i,modelica_string format)
{
  void *res;
  size_t sz;

  void *c_fmt = modelica_string_format_to_c_string_format(format);

  switch (MMC_STRINGDATA(c_fmt)[MMC_STRLEN(c_fmt)-1]) {
  case 'f':
  case 'e':
  case 'E':
  case 'g':
  case 'G':
    /* double */
    sz = snprintf(NULL, 0, MMC_STRINGDATA(c_fmt), (double) i);
    res = alloc_modelica_string(sz);
    sprintf(MMC_STRINGDATA(res), MMC_STRINGDATA(c_fmt), (double) i);
    break;
  case 'c':
  case 'd':
  case 'i':
    /* int */
    sz = snprintf(NULL, 0, MMC_STRINGDATA(c_fmt), (long) i);
    res = alloc_modelica_string(sz);
    sprintf(MMC_STRINGDATA(res), MMC_STRINGDATA(c_fmt), (long) i);
    break;
  case 'o':
  case 'x':
  case 'X':
  case 'u':
    /* uint */
    sz = snprintf(NULL, 0, MMC_STRINGDATA(c_fmt), (unsigned long) i);
    res = alloc_modelica_string(sz);
    sprintf(MMC_STRINGDATA(res), MMC_STRINGDATA(c_fmt), (unsigned long) i);
    break;
  default:
    /* integer values, etc */
    omc_assert(NULL, dummyFILE_INFO, "Invalid conversion specifier for Real: %c", MMC_STRINGDATA(c_fmt)[MMC_STRLEN(c_fmt)-1]);
  }
  return res;
}

/* Convert a modelica_real to a modelica_string, used in String(real, format="xxx") */
modelica_string modelica_real_to_modelica_string_format(modelica_real r,modelica_string format)
{
  void *res;
  size_t sz;

  void *c_fmt = modelica_string_format_to_c_string_format(format);

  switch (MMC_STRINGDATA(c_fmt)[MMC_STRLEN(c_fmt)-1]) {
  case 'f':
  case 'e':
  case 'E':
  case 'g':
  case 'G':
    /* double */
    sz = snprintf(NULL, 0, MMC_STRINGDATA(c_fmt), (double) r);
    res = alloc_modelica_string(sz);
    sprintf(MMC_STRINGDATA(res), MMC_STRINGDATA(c_fmt), (double) r);
    break;
  default:
    /* integer values, etc */
    omc_assert(NULL, dummyFILE_INFO, "Invalid conversion specifier for Real: %c", MMC_STRINGDATA(c_fmt)[MMC_STRLEN(c_fmt)-1]);
  }
  return res;
}

/* Convert a modelica_integer to a modelica_string, used in String(i) */

modelica_string modelica_integer_to_modelica_string(modelica_integer i, modelica_integer minLen, modelica_boolean leftJustified)
{
  size_t sz = snprintf(NULL, 0, leftJustified ? "%-*ld" : "%*ld", (int) minLen, i);
  void *res = alloc_modelica_string(sz);
  sprintf(MMC_STRINGDATA(res), leftJustified ? "%-*ld" : "%*ld", (int) minLen, i);
  return res;
}

/* Convert a modelica_real to a modelica_string, used in String(r) */

modelica_string modelica_real_to_modelica_string(modelica_real r,modelica_integer minLen,modelica_boolean leftJustified,modelica_integer signDigits)
{
  size_t sz = snprintf(NULL, 0, leftJustified ? "%-*.*g" : "%*.*g", (int) minLen, (int) signDigits, r);
  void *res = alloc_modelica_string(sz);
  sprintf(MMC_STRINGDATA(res), leftJustified ? "%-*.*g" : "%*.*g", (int) minLen, (int) signDigits, r);
  return res;
}

/* Convert a modelica_boolean to a modelica_string, used in String(b) */

modelica_string modelica_boolean_to_modelica_string(modelica_boolean b, modelica_integer minLen, modelica_boolean leftJustified)
{
  size_t sz = snprintf(NULL, 0, leftJustified ? "%-*s" : "%*s", (int) minLen, b ? "true" : "false");
  void *res = alloc_modelica_string(sz);
  sprintf(MMC_STRINGDATA(res), leftJustified ? "%-*s" : "%*s", (int) minLen, b ? "true" : "false");
  return res;
}

/* Convert a modelica_enumeration to a modelica_string, used in String(b) */

modelica_string modelica_enumeration_to_modelica_string(modelica_integer nr,const modelica_string e[],modelica_integer minLen, modelica_boolean leftJustified)
{
  return mmc_mk_scon(e[nr-1]);
}

modelica_string alloc_modelica_string(int length)
{
    /* Reserve place for null terminator too.*/
    return mmc_alloc_scon(length);
}

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
      case '\r': if(nl) {i++; *hasEscape=1; if(str[1] == '\n') str++;} break;
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
  res = (char*) GC_malloc(len+1);
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

int GC_vasprintf(char **strp, const char *fmt, va_list ap) {
  int len;
  len = vsnprintf(NULL, 0, fmt, ap);
  *strp = GC_malloc_atomic(len+1);
  len = vsnprintf(*strp, len+1, fmt, ap);
  return len;
}

int GC_asprintf(char **strp, const char *fmt, ...) {
  int len;
  va_list ap;
  va_start(ap, fmt);

  len = GC_vasprintf(strp, fmt, ap);

  va_end(ap);
  return len;
}

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


#include "modelica_string.h"
#if defined(OMC_METAMODELICA_RUNTIME)
/* The string vocabulary of this runtime; util/omc_string.h stands down here.
   The String(x) formatters below are built for both. */
#include "../meta/meta_modelica_string.h"
#endif
#include "../gc/omc_gc.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "omc_error.h"

#define FMT_BUFSIZE 400

static inline void checkBufSize(const char *str, int n)
{
  if (n >= FMT_BUFSIZE) {
    omc_assert(NULL, omc_dummyFileInfo, "Could not parse format string; ran out of buffer size (%d): %s", FMT_BUFSIZE, str);
  }
}

modelica_string modelica_string_format_to_c_string_format(modelica_string format)
{
  char buf[FMT_BUFSIZE];
  const char *str = omc_string_data(format), *tmp = str;
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
    omc_assert(NULL, omc_dummyFileInfo, "Length modifiers are not legal in Modelica format strings: %s", str);
    break;
  default:
    omc_assert(NULL, omc_dummyFileInfo, "Could not parse format string: invalid conversion specifier: %c in %s", *tmp, str);
  }
  if (*tmp) {
    omc_assert(NULL, omc_dummyFileInfo, "Could not parse format string: trailing data after the format directive", *tmp, str);
  }
  buf[n] = '\0';
  return omc_string_new(buf);
}

/* Convert a modelica_integer to a modelica_string, used in String(integer, format="xxx") */
modelica_string modelica_integer_to_modelica_string_format(modelica_integer i,modelica_string format)
{
  void *res;
  size_t sz;

  void *c_fmt = modelica_string_format_to_c_string_format(format);

  switch (omc_string_data(c_fmt)[omc_string_len(c_fmt)-1]) {
  case 'f':
  case 'e':
  case 'E':
  case 'g':
  case 'G':
    /* double */
    sz = snprintf(NULL, 0, omc_string_data(c_fmt), (double) i);
    res = omc_string_alloc(sz);
    sprintf(omc_string_data(res), omc_string_data(c_fmt), (double) i);
    break;
  case 'c':
  case 'd':
  case 'i':
    /* int */
    sz = snprintf(NULL, 0, omc_string_data(c_fmt), (long) i);
    res = omc_string_alloc(sz);
    sprintf(omc_string_data(res), omc_string_data(c_fmt), (long) i);
    break;
  case 'o':
  case 'x':
  case 'X':
  case 'u':
    /* uint */
    sz = snprintf(NULL, 0, omc_string_data(c_fmt), (unsigned long) i);
    res = omc_string_alloc(sz);
    sprintf(omc_string_data(res), omc_string_data(c_fmt), (unsigned long) i);
    break;
  default:
    /* integer values, etc */
    omc_assert(NULL, omc_dummyFileInfo, "Invalid conversion specifier for Real: %c", omc_string_data(c_fmt)[omc_string_len(c_fmt)-1]);
  }
  return res;
}

/* Convert a modelica_real to a modelica_string, used in String(real, format="xxx") */
modelica_string modelica_real_to_modelica_string_format(modelica_real r,modelica_string format)
{
  void *res;
  size_t sz;

  void *c_fmt = modelica_string_format_to_c_string_format(format);

  switch (omc_string_data(c_fmt)[omc_string_len(c_fmt)-1]) {
  case 'f':
  case 'e':
  case 'E':
  case 'g':
  case 'G':
    /* double */
    sz = snprintf(NULL, 0, omc_string_data(c_fmt), (double) r);
    res = omc_string_alloc(sz);
    sprintf(omc_string_data(res), omc_string_data(c_fmt), (double) r);
    break;
  default:
    /* integer values, etc */
    omc_assert(NULL, omc_dummyFileInfo, "Invalid conversion specifier for Real: %c", omc_string_data(c_fmt)[omc_string_len(c_fmt)-1]);
  }
  return res;
}

/* Convert a modelica_string to a modelica_string, used in String(s) */
modelica_string modelica_string_to_modelica_string(modelica_string s)
{
  return omc_string_retain(s);
}

/* Convert a modelica_integer to a modelica_string, used in String(i) */
modelica_string modelica_integer_to_modelica_string(modelica_integer i, modelica_integer minLen, modelica_boolean leftJustified)
{
  size_t sz = snprintf(NULL, 0, leftJustified ? OMC_INT_WIDTH_LEFT_FORMAT : OMC_INT_WIDTH_FORMAT, (int) minLen, i);
  void *res = omc_string_alloc(sz);
  sprintf(omc_string_data(res), leftJustified ? OMC_INT_WIDTH_LEFT_FORMAT : OMC_INT_WIDTH_FORMAT, (int) minLen, i);
  return res;
}

/* Convert a modelica_real to a modelica_string, used in String(r) */

modelica_string modelica_real_to_modelica_string(modelica_real r, modelica_integer signDigits, modelica_integer minLen, modelica_boolean leftJustified)
{
  size_t sz = snprintf(NULL, 0, leftJustified ? "%-*.*g" : "%*.*g", (int) minLen, (int) signDigits, r);
  void *res = omc_string_alloc(sz);
  sprintf(omc_string_data(res), leftJustified ? "%-*.*g" : "%*.*g", (int) minLen, (int) signDigits, r);
  return res;
}

/* Convert a modelica_boolean to a modelica_string, used in String(b) */

modelica_string modelica_boolean_to_modelica_string(modelica_boolean b, modelica_integer minLen, modelica_boolean leftJustified)
{
  size_t sz = snprintf(NULL, 0, leftJustified ? "%-*s" : "%*s", (int) minLen, b ? "true" : "false");
  void *res = omc_string_alloc(sz);
  sprintf(omc_string_data(res), leftJustified ? "%-*s" : "%*s", (int) minLen, b ? "true" : "false");
  return res;
}

/* Convert a modelica_enumeration to a modelica_string, used in String(b) */

modelica_string enum_to_modelica_string(modelica_integer nr, const char *e[],modelica_integer minLen, modelica_boolean leftJustified)
{
  size_t sz = snprintf(NULL, 0, leftJustified ? "%-*s" : "%*s", (int) minLen, e[nr-1]);
  void *res = omc_string_alloc(sz);
  sprintf(omc_string_data(res), leftJustified ? "%-*s" : "%*s", (int) minLen, e[nr-1]);
  return res;
}

#if !defined(OMC_METAMODELICA_RUNTIME)
modelica_string alloc_modelica_string(int length)
{
    /* Reserve place for null terminator too.*/
    return omc_string_alloc(length);
}

modelica_string stringAppend(modelica_string s1, modelica_string s2)
{
  unsigned len1 = 0, len2 = 0, nbytes = 0;
  modelica_string res = NULL;

  len1 = omc_string_len(s1);
  len2 = omc_string_len(s2);

  /* An argument returned unchanged is still a reference of the caller's own. */
  if (len1==0) {
    return omc_string_retain(s2);
  } else if (len2==0) {
    return omc_string_retain(s1);
  }

  nbytes = len1+len2;
  res = omc_string_alloc(nbytes);

  memcpy(omc_string_data(res), omc_string_data(s1), len1);
  memcpy(omc_string_data(res) + len1, omc_string_data(s2), len2 + 1);

  return res;
}

modelica_integer stringCompare(modelica_string str1, modelica_string str2)
{
  int res;
  res = strcmp(omc_string_data(str1),omc_string_data(str2));
  if (res < 0)
    return -1;
  if (res > 0)
    return 1;
  return 0;
}
#endif /* !OMC_METAMODELICA_RUNTIME */

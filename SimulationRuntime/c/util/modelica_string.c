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

/* Convert a modelica_real to a modelica_string, used in String(real, format="xxx") */
modelica_string modelica_real_to_modelica_string_format(modelica_real r,modelica_string format)
{
  char buf[400];
  sprintf(buf,MMC_STRINGDATA(stringAppend(mmc_strings_len1['%'],format)),r);
  return mmc_mk_scon(buf);
}
/* Convert a modelica_integer to a modelica_string, used in String(integer, format="xxx") */
modelica_string modelica_integer_to_modelica_string_format(modelica_integer i,modelica_string format)
{
  char buf[400];
  sprintf(buf,MMC_STRINGDATA(stringAppend(mmc_strings_len1['%'],format)),i);
  return mmc_mk_scon(buf);
}
/* Convert a modelica_integer to a modelica_string, used in String(string, format="xxx") */
modelica_string modelica_stringo_modelica_string_format(modelica_string s,modelica_string format)
{
  char buf[4000];
  sprintf(buf,MMC_STRINGDATA(stringAppend(mmc_strings_len1['%'],format)),s);
  return mmc_mk_scon(buf);
}

/* Convert a modelica_integer to a modelica_string, used in String(i) */

modelica_string modelica_integer_to_modelica_string(modelica_integer i, modelica_integer minLen, modelica_boolean leftJustified)
{
  char buf[400];
  size_t sz = snprintf(buf, 400, leftJustified ? "%-*ld" : "%*ld", (int) minLen, i);
  if (sz > 400) {
    void *res = alloc_modelica_string(sz-1);
    sprintf(MMC_STRINGDATA(res), leftJustified ? "%-*ld" : "%*ld", (int) minLen, i);
    return res;
  } else {
    return mmc_mk_scon(buf);
  }
}

/* Convert a modelica_real to a modelica_string, used in String(r) */

modelica_string modelica_real_to_modelica_string(modelica_real r,modelica_integer minLen,modelica_boolean leftJustified,modelica_integer signDigits)
{
  char buf[400];
  size_t sz = snprintf(buf, 400, leftJustified ? "%-*.*g" : "%*.*g", (int) minLen, (int) signDigits, r);
  if (sz > 400) {
    void *res = alloc_modelica_string(sz-1);
    sprintf(MMC_STRINGDATA(res), leftJustified ? "%-*.*g" : "%*.*g", (int) minLen, (int) signDigits, r);
    return res;
  } else {
    return mmc_mk_scon(buf);
  }
}

/* Convert a modelica_boolean to a modelica_string, used in String(b) */

modelica_string modelica_boolean_to_modelica_string(modelica_boolean b, modelica_integer minLen, modelica_boolean leftJustified)
{
  char buf[400];
  size_t sz = snprintf(buf, 400, leftJustified ? "%-*s" : "%*s", (int) minLen, b ? "true" : "false");
  if (sz > 400) {
    void *res = alloc_modelica_string(sz-1);
    sprintf(MMC_STRINGDATA(res), leftJustified ? "%-*s" : "%*s", (int) minLen, b ? "true" : "false");
    return res;
  } else {
    return mmc_mk_scon(buf);
  }
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
      case '\r': if(nl) {res[i++] = '\\'; res[i++] = 'n'; if(str[1] == '\n') str++;} else {res[i++] = *str;} break;
      case '\n': if(nl) {res[i++] = '\\'; res[i++] = 'n';} else {res[i++] = *str;} break;
      default: res[i++] = *str;
    }
    str++;
  }
  res[i] = '\0';
  return res;
}


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


#include "modelica_string.h"
#include "memory_pool.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "gc.h"

int modelica_string_ok(const modelica_string_t* a)
{
  /* Since a modelica string is a char* check that it is not null.*/
    return ((a != NULL) ? 1 : 0);
}

int modelica_string_length(modelica_string_const a)
{
    return strlen(a);
}

/* Convert a modelica_real to a modelica_string, used in String(real, format="xxx") */
modelica_string_const modelica_real_to_modelica_string_format(modelica_real r,modelica_string_const format)
{
  char formatStr[40];
  char buf[400];
  formatStr[0]='%';
  strcpy(&formatStr[1], format);
  sprintf(buf,formatStr,r);
  return init_modelica_string(buf);
}
/* Convert a modelica_integer to a modelica_string, used in String(integer, format="xxx") */
modelica_string_const modelica_integer_to_modelica_string_format(modelica_integer i,modelica_string_const format)
{
  char formatStr[40];
  char buf[400];
  formatStr[0]='%';
  strcpy(&formatStr[1], format);
  sprintf(buf,formatStr,i);
  return init_modelica_string(buf);
}
/* Convert a modelica_integer to a modelica_string, used in String(string, format="xxx") */
modelica_string_const modelica_string_to_modelica_string_format(modelica_string_const s,modelica_string_const format)
{
  char formatStr[40];
  char buf[4000];
  formatStr[0]='%';
  strcpy(&formatStr[1], format);
  sprintf(buf,formatStr,s);
  return init_modelica_string(buf);
}

/* Convert a modelica_integer to a modelica_string, used in String(i) */

modelica_string_const modelica_integer_to_modelica_string(modelica_integer i, modelica_integer minLen, modelica_boolean leftJustified)
{
  char formatStr[40];
  char buf[400];
  formatStr[0]='%';
  if(leftJustified) {
    sprintf(&formatStr[1],"-%dd",(int)minLen);
  } else {
    sprintf(&formatStr[1],"%dd",(int)minLen);
  }
  sprintf(buf,formatStr,i);
  return init_modelica_string(buf);
}

/* Convert a modelica_real to a modelica_string, used in String(r) */

modelica_string_const modelica_real_to_modelica_string(modelica_real r,modelica_integer minLen,modelica_boolean leftJustified,modelica_integer signDigits)
{
  char formatStr[40];
  char buf[400];
  formatStr[0]='%';
  if(leftJustified) {
    sprintf(&formatStr[1],"-%d.%dg",(int)minLen,(int)signDigits);
  } else {
    sprintf(&formatStr[1],"%d.%dg",(int)minLen,(int)signDigits);
  }
  sprintf(buf,formatStr,r);
  return init_modelica_string(buf);
}

/* Convert a modelica_boolean to a modelica_string, used in String(b) */

modelica_string_const modelica_boolean_to_modelica_string(modelica_boolean b, modelica_integer minLen, modelica_boolean leftJustified)
{
  if(b) {
    return "true";
  } else {
    return "false";
  }
}

/* Convert a modelica_enumeration to a modelica_string, used in String(b) */

modelica_string_const modelica_enumeration_to_modelica_string(modelica_integer nr,const modelica_string_t e[],modelica_integer minLen, modelica_boolean leftJustified)
{
  return init_modelica_string(e[nr-1]);
}


modelica_string_const init_modelica_string(modelica_string_const str)
{
  int length = strlen(str);
  modelica_string_t dest = alloc_modelica_string(length);
  memcpy(dest, str, length);
  return dest;
}

modelica_string_t alloc_modelica_string(int length)
{
    /* Reserve place for null terminator too.*/
    modelica_string_t dest = (modelica_string_t) GC_malloc(length+1);
    if (dest != 0) {
      dest[length]=0;
    }
    return dest;
}

void free_modelica_string(modelica_string_t* a)
{
    /* int length; */

    assert(modelica_string_ok(a));

    /* length = modelica_string_length(*a); */
    /* Free also null terminator.*/
    /* free(a); */ /* char_free(length+1); */
}

modelica_string_const copy_modelica_string(modelica_string_const source)
{
  int len = strlen(source);
  modelica_string_t dest = alloc_modelica_string(len);
  memcpy(dest, source, len);
  return dest;
}

modelica_string_const cat_modelica_string(modelica_string_const s1, modelica_string_const s2)
{
  char *dest;
  int len1 = modelica_string_length(s1);
  int len2 = modelica_string_length(s2);
  dest = alloc_modelica_string(len1+len2);
  memcpy(dest, s1, len1);
  memcpy(dest + len1, s2, len2);
  return dest;
}

extern int omc__escapedStringLength(const char* str, int nl)
{
  int i=0;
  while(*str) {
    switch (*str) {
      case '"':
      case '\\':
      case '\a':
      case '\b':
      case '\f':
      case '\v': i++; break;
      case '\r': if(nl) {i++; if(str[1] == '\n') str++;} break;
      case '\n': if(nl) {i++; if(str[1] == '\r') str++;} break;
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
  int len1,len2;
  char *res;
  int i=0;
  len1 = strlen(str);
  len2 = omc__escapedStringLength(str,nl);
  if(len1 == len2) return NULL;
  res = (char*) malloc(len2+1);
  while(*str) {
    switch (*str) {
      case '"': res[i++] = '\\'; res[i++] = '"'; break;
      case '\\': res[i++] = '\\'; res[i++] = '\\'; break;
      case '\a': res[i++] = '\\'; res[i++] = 'a'; break;
      case '\b': res[i++] = '\\'; res[i++] = 'b'; break;
      case '\f': res[i++] = '\\'; res[i++] = 'f'; break;
      case '\v': res[i++] = '\\'; res[i++] = 'v'; break;
      case '\r': if(nl) {res[i++] = '\\'; res[i++] = 'n'; if(str[1] == '\n') str++;} else {res[i++] = *str;} break;
      case '\n': if(nl) {res[i++] = '\\'; res[i++] = 'n'; if(str[1] == '\r') str++;} else {res[i++] = *str;} break;
      default: res[i++] = *str;
    }
    str++;
  }
  res[i] = '\0';
  return res;
}


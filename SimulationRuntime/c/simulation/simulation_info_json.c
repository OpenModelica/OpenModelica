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

#include "simulation_info_json.h"
#include "simulation_runtime.h"
#include "options.h"
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include "../util/rtclock.h"
#include "../util/omc_mmap.h"
#include "solver/model_help.h"

static inline const char* skipSpace(const char* str)
{
  do {
    switch (*str) {
    case '\0': return str;
    case ' ':
    case '\n':
    case '\r':
     str++;
     break;
    default: return str;
    }
  } while (1);
}

static const char* skipValue(const char* str);

static inline const char* skipObjectRest(const char* str, int first)
{
  str=skipSpace(str);
  while (*str != '}') {
    if (!first) {
      if (*str != ',') {
        fprintf(stderr, "JSON object expected ',' or '}', got: %.20s\n", str);
        abort();
      }
      str++;
    } else {
      first = 0;
    }
    str = skipValue(str);
    str = skipSpace(str);
    if (*str++ != ':') {
      fprintf(stderr, "JSON object expected ':', got: %.20s\n", str);
      abort();
    }
    str = skipValue(str);
    str = skipSpace(str);
  }
  return str+1;
}

static const char* skipValue(const char* str)
{
  str = skipSpace(str);
  switch (*str) {
  case '{':
  {
    str = skipObjectRest(str+1,1);
    return str;
  }
  case '[':
  {
    int first = 1;
    str = skipSpace(str+1);
    while (*str != ']') {
      if (!first && *str++ != ',') {
        fprintf(stderr, "JSON array expected ',' or ']', got: %.20s\n", str);
        abort();
      }
      first = 0;
      str = skipValue(str);
      str = skipSpace(str);
    }
    return str+1;
  }
  case '"':
    str++;
    do {
      switch (*str) {
      case '\0': fprintf(stderr, "Found end of file, expected end of string"); abort();
      case '\\':
        if (str+1 == '\0') {
          fprintf(stderr, "Found end of file, expected end of string"); abort();
        }
        str+=2;
        break;
      case '"':
        return str+1;
      default:
        str++;
      }
    } while (1);
    abort();
  case '-':
  case '0':
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
  case '9':
  {
    char *endptr = NULL;
    strtod(str,&endptr);
    if (str == endptr) {
      fprintf(stderr, "Not a number, got %.20s\n", str);
       abort();
    }
    return endptr;
  }
  default:
    fprintf(stderr, "JSON value expected, got: %.20s\n", str);
    abort();
  }
}

/* Does not work for escaped strings. Returns the rest of the string to parse. */
static inline const char* assertStringValue(const char *str, const char *value)
{
  int len = strlen(value);
  str = skipSpace(str);
  if ('\"' != *str || strncmp(str+1,value,len) || str[len+1] != '\"') {
    fprintf(stderr, "JSON string value %s expected, got: %.20s\n", value, str);
    abort();
  }
  return str + len + 2;
}

static inline const char* assertChar(const char *str, char c)
{
  str = skipSpace(str);
  if (c != *str) {
    fprintf(stderr, "Expected '%c', got: %.20s\n", c, str);
     abort();
  }
  return str + 1;
}

static inline const char* assertNumber(const char *str, double expected)
{
  char *endptr = NULL;
  double d;
  str = skipSpace(str);
  d = strtod(str, &endptr);
  if (str == endptr) {
    fprintf(stderr, "Expected number, got: %.20s\n", str);
    abort();
  }
  if (d != expected) {
    fprintf(stderr, "Got number %f, expected: %f\n", d, expected);
    abort();
  }
  return endptr;
}

static inline const char *skipFieldIfExist(const char *str,const char *name)
{
  const char *s = str;
  int len = strlen(name);
  if (*s != ',') {
    return str;
  }
  s++;
  if (*s != '\"' || strncmp(s+1,name,len)) {
    return str;
  }
  s += len + 1;
  if (strncmp("\":", s, 2)) {
    return str;
  }
  s += 2;
  s = skipSpace(s);
  s = skipValue(s);
  s = skipSpace(s);
  s = skipSpace(s);
  return s;
}

static const char* readEquation(const char *str,EQUATION_INFO *xml,int i)
{
  int n=0,j;
  const char *str2;
  str=assertChar(str,'{');
  str=assertStringValue(str,"eqIndex");
  str=assertChar(str,':');
  str=assertNumber(str,i);
  str=skipSpace(str);
  xml->id = i;
  str = skipFieldIfExist(str, "parent");
  str = skipFieldIfExist(str, "section");
  if ((measure_time_flag & 1) && 0==strncmp(",\"tag\":\"system\"", str, 15)) {
    xml->profileBlockIndex = -1;
    str += 15;
  } else if ((measure_time_flag & 1) && 0==strncmp(",\"tag\":\"tornsystem\"", str, 19)) {
    xml->profileBlockIndex = -1;
    str += 19;
  } else {
    xml->profileBlockIndex = 0;
  }
  str = skipFieldIfExist(str, "tag");
  str = skipFieldIfExist(str, "display");
  str = skipFieldIfExist(str, "unknowns");
  if (strncmp(",\"defines\":[", str, 12)) {
    xml->numVar = 0;
    xml->vars = 0;
    str = skipObjectRest(str,0);
    return str;
  }
  str += 12;
  str = skipSpace(str);
  if (*str == ']') {
    xml->numVar = 0;
    xml->vars = 0;
    return skipObjectRest(str-1,0);
  }
  str2 = skipSpace(str);
  while (1) {
    str=skipValue(str);
    n++;
    str=skipSpace(str);
    if (*str != ',') {
      break;
    }
    str++;
  };
  assertChar(str, ']');
  xml->numVar = n;
  xml->vars = malloc(sizeof(const char*)*n);
  str = str2;
  for (j=0; j<n; j++) {
    const char *str3 = skipSpace(str);
    char *tmp;
    int len=0;
    str = assertChar(str, '\"');
    while (*str != '\"' && *str) {
      len++;
      str++;
    }
    str = assertChar(str, '\"');
    tmp = malloc(len+1);
    strncpy(tmp, str3+1, len);
    tmp[len] = '\0';
    xml->vars[j] = tmp;
    if (j != n-1) {
      str = assertChar(str, ',');
    }
  }
  str = assertChar(skipSpace(str), ']');
  return skipObjectRest(str,0);
}

static const char* readEquations(const char *str,MODEL_DATA_XML *xml)
{
  int i;
  xml->nProfileBlocks = measure_time_flag & 2 ? 1 : 0;
  str=assertChar(str,'[');
  str = readEquation(str,xml->equationInfo,0);
  for (i=1; i<xml->nEquations; i++) {
    str = assertChar(str,',');
    str = readEquation(str,xml->equationInfo+i,i);
    /* TODO: Odd, it seems there is 1 fewer equation than expected... */
    /*
    if (i != xml->nEquations-1) {
      str=assertChar(str,',');
    }
    */
    if (measure_time_flag & 2 || ((measure_time_flag & 1) && xml->equationInfo[i].profileBlockIndex == -1)) {
      xml->equationInfo[i].profileBlockIndex = xml->nProfileBlocks++;
    }
  }
  str=assertChar(str,']');
  return str;
}

static const char* readFunction(const char *str,FUNCTION_INFO *xml,int i)
{
  FILE_INFO info = omc_dummyFileInfo;
  size_t len;
  char *name;
  const char *str2;
  str=skipSpace(str);
  str2=assertChar(str,'"');
  str=skipValue(str);
  xml->id = i;
  len = str-str2;
  name = malloc(len);
  memcpy(name, str2, len-1);
  name[len-1] = '\0';
  xml->name = name;
  xml->info = info;
  return str;
}

static const char* readFunctions(const char *str,MODEL_DATA_XML *xml)
{
  int i;
  if (xml->nFunctions == 0) {
    str=assertChar(str,'[');
    str=assertChar(str,']');
    return str;
  }
  str=assertChar(str,'[');
  for (i=0; i<xml->nFunctions; i++) {
    str = readFunction(str,xml->functionNames+i,i);
    str=assertChar(str,xml->nFunctions==i+1 ? ']' : ',');
  }
  return str;
}

static void readInfoJson(const char *str,MODEL_DATA_XML *xml)
{
  str=assertChar(str,'{');
  str=assertStringValue(str,"format");
  str=assertChar(str,':');
  str=assertStringValue(str,"Transformational debugger info");
  str=assertChar(str,',');
  str=assertStringValue(str,"version");
  str=assertChar(str,':');
  str=assertChar(str,'1');
  str=assertChar(str,',');
  str=assertStringValue(str,"info");
  str=assertChar(str,':');
  str=skipValue(str);
  str=assertChar(str,',');
  str=assertStringValue(str,"variables");
  str=assertChar(str,':');
  str=skipValue(str);
  str=assertChar(str,',');
  str=assertStringValue(str,"equations");
  str=assertChar(str,':');
  str=readEquations(str,xml);
  str=assertChar(str,',');
  str=assertStringValue(str,"functions");
  str=assertChar(str,':');
  str=readFunctions(str,xml);
  assertChar(str,'}');
}

void modelInfoInit(MODEL_DATA_XML* xml)
{
#if !defined(OMC_NO_FILESYSTEM)
  omc_mmap_read mmap_reader = {0};
#endif
  //rt_tick(0);
#if !defined(OMC_NO_FILESYSTEM)
  if (!xml->infoXMLData) {
    const char *filename;
    if (omc_flag[FLAG_INPUT_PATH]) { /* read the input path from the command line (if any) */
      if (0 > GC_asprintf(&filename, "%s/%s", omc_flagValue[FLAG_INPUT_PATH], xml->fileName)) {
        throwStreamPrint(NULL, "simulation_info_json.c: Error: can not allocate memory.");
      }
      mmap_reader = omc_mmap_open_read(filename);
    } else {
      mmap_reader = omc_mmap_open_read(xml->fileName);
    }
    xml->infoXMLData = mmap_reader.data;
    xml->modelInfoXmlLength = mmap_reader.size;
    // fprintf(stderr, "Loaded the JSON (%ld kB)...\n", (long) (s.st_size+1023)/1024);
  }
#endif
  xml->functionNames = (FUNCTION_INFO*) calloc(xml->nFunctions, sizeof(FUNCTION_INFO));
  xml->equationInfo = (EQUATION_INFO*) calloc(1+xml->nEquations, sizeof(EQUATION_INFO));
  xml->equationInfo[0].id = 0;
  xml->equationInfo[0].profileBlockIndex = -1;
  xml->equationInfo[0].numVar = 0;
  xml->equationInfo[0].vars = NULL;

  // fprintf(stderr, "Loaded the JSON file in %fms...\n", rt_tock(0) * 1000.0);
  // fprintf(stderr, "Parse the JSON %s\n", xml->infoXMLData);
  // fprintf(stderr, "Parse the JSON %ld...\n", (long) xml->infoXMLData);
  readInfoJson(xml->infoXMLData, xml);
  // fprintf(stderr, "Parsed the JSON in %fms...\n", rt_tock(0) * 1000.0);
#if !defined(OMC_NO_FILESYSTEM)
  omc_mmap_close_read(mmap_reader);
#endif
}

FUNCTION_INFO modelInfoGetFunction(MODEL_DATA_XML* xml, size_t ix)
{
  if(xml->functionNames == NULL)
  {
    modelInfoInit(xml);
  }
  assert(xml->functionNames);
  return xml->functionNames[ix];
}

EQUATION_INFO modelInfoGetEquation(MODEL_DATA_XML* xml, size_t ix)
{
  if (xml->equationInfo == NULL) {
    modelInfoInit(xml);
  }
  assert(xml->equationInfo);
  return xml->equationInfo[ix];
}

EQUATION_INFO modelInfoGetEquationIndexByProfileBlock(MODEL_DATA_XML* xml, size_t ix)
{
  int i;
  if(xml->equationInfo == NULL)
  {
    modelInfoInit(xml);
  }
  if(ix > xml->nProfileBlocks)
  {
    throwStreamPrint(NULL, "Requested equation with profiler index %ld, but we only have %ld such blocks", (long int)ix, xml->nProfileBlocks);
  }
  for(i=0; i<xml->nEquations; i++)
  {
    if(xml->equationInfo[i].profileBlockIndex == ix)
    {
      return xml->equationInfo[i];
    }
  }
  throwStreamPrint(NULL, "Requested equation with profiler index %ld, but could not find it!", (long int)ix);
}

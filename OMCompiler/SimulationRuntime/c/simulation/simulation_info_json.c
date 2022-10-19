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
#include "../util/omc_numbers.h"
#include "solver/model_help.h"
#include "../util/omc_file.h"

/**
 * @brief Skip whitespace.
 *
 * @param str           Points to some locating inside JSON.
 * @return const char*  Points to next non-whitespace character.
 */
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

static const char* skipValue(const char* str, const char* fileName);

/**
 * @brief Skip rest of JSON object.
 *
 * Move forward until next '}' is reached.
 *
 * @param str           Points to some locating inside JSON object.
 * @param first         1 if first location in JSON object, 0 otherwise.
 * @param fileName      Name of JSON to parse. Used for error messages.
 * @return const char*  Points to location directly after JSON obbject.
 */
static inline const char* skipObjectRest(const char* str, int first, const char* fileName)
{
  str=skipSpace(str);
  while (*str != '}') {
    if (!first) {
      if (*str != ',') {
        errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
        errorStreamPrint(LOG_STDOUT, 0, "JSON object expected ',' or '}', got: %.20s\n", str);
        messageClose(LOG_STDOUT);
        omc_throw_function(NULL);
      }
      str++;
    } else {
      first = 0;
    }
    str = skipValue(str, fileName);
    str = skipSpace(str);
    if (*str++ != ':') {
      errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
      errorStreamPrint(LOG_STDOUT, 0, "JSON object expected ':', got: %.20s\n", str);
      messageClose(LOG_STDOUT);
      omc_throw_function(NULL);
    }
    str = skipValue(str, fileName);
    str = skipSpace(str);
  }
  return str+1;
}

/**
 * @brief Skip JSON value.
 *
 * @param str           Points to beginning of JSON value.
 * @param fileName      Name of JSON to parse. Used for error messages.
 * @return const char*  Points to location directly after JSON value.
 */
static const char* skipValue(const char* str, const char* fileName)
{
  str = skipSpace(str);
  switch (*str) {
  case '{':
  {
    str = skipObjectRest(str+1, 1, fileName);
    return str;
  }
  case '[':
  {
    int first = 1;
    str = skipSpace(str+1);
    while (*str != ']') {
      if (!first && *str++ != ',') {
        errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
        errorStreamPrint(LOG_STDOUT, 0, "JSON array expected ',' or ']', got: %.20s\n", str);
        messageClose(LOG_STDOUT);
        omc_throw_function(NULL);
      }
      first = 0;
      str = skipValue(str, fileName);
      str = skipSpace(str);
    }
    return str+1;
  }
  case '"':
    str++;
    do {
      switch (*str) {
      case '\0':
        errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
        errorStreamPrint(LOG_STDOUT, 0, "Found end of file, expected end of string");
        messageClose(LOG_STDOUT);
        omc_throw_function(NULL);
      case '\\':
        if (*(str+1) == '\0') {
          errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
          errorStreamPrint(LOG_STDOUT, 0, "Found end of file, expected end of string");
          messageClose(LOG_STDOUT);
          omc_throw_function(NULL);
        }
        str+=2;
        break;
      case '"':
        return str+1;
      default:
        str++;
      }
    } while (1);
    errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
    errorStreamPrint(LOG_STDOUT, 0, "Reached state that should be impossible to reach.");
    messageClose(LOG_STDOUT);
    omc_throw_function(NULL);
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
    om_strtod(str,&endptr);
    if (str == endptr) {
      errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
      errorStreamPrint(LOG_STDOUT, 0, "Not a number, got %.20s\n", str);
      messageClose(LOG_STDOUT);
      omc_throw_function(NULL);
    }
    return endptr;
  }
  default:
    errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
    errorStreamPrint(LOG_STDOUT, 0, "JSON value expected, got: %.20s\n", str);
    messageClose(LOG_STDOUT);
    omc_throw_function(NULL);
  }
}

/**
 * @brief Assert str points to given string.
 *
 * Does not work for escaped strings. Returns the rest of the string to parse.
 *
 * @param str           Points to beginning of string to assert.
 * @param value         Expected value of string.
 * @param fileName      Name of JSON to parse. Used for error messages.
 * @return const char*  Points to location directly after string.
 */
static inline const char* assertStringValue(const char *str, const char *value, const char* fileName)
{
  int len = strlen(value);
  str = skipSpace(str);
  if ('\"' != *str || strncmp(str+1,value,len) || str[len+1] != '\"') {
    errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
    errorStreamPrint(LOG_STDOUT, 0, "JSON string value %s expected, got: %.20s\n", value, str);
    messageClose(LOG_STDOUT);
    omc_throw_function(NULL);
  }
  return str + len + 2;
}

/**
 * @brief Assert str points to specific character.
 *
 * @param str             Pointer to character to assert.
 * @param c               Character str should be equal to.
 * @param fileName        Name of JSON to parse. Used for error messages.
 * @return const char*    Point to next locatin after character.
 */
static inline const char* assertChar(const char *str, char c, const char *fileName)
{
  str = skipSpace(str);
  if (c != *str) {
    errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
    errorStreamPrint(LOG_STDOUT, 0,"Expected '%c', got: %.20s\n", c, str);
    messageClose(LOG_STDOUT);
    omc_throw_function(NULL);
  }
  return str + 1;
}

/**
 * @brief Assert str point to specific number.
 *
 * @param str             Pointer to number to assert.
 * @param expected        Expected number.
 * @param fileName        Name of JSON to parse. Used for error messages.
 * @return const char*    Point to next locatin after number.
 */
static inline const char* assertNumber(const char *str, double expected, const char *fileName)
{
  char *endptr = NULL;
  double d;
  str = skipSpace(str);
  d = om_strtod(str, &endptr);
  if (str == endptr) {
    errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
    errorStreamPrint(LOG_STDOUT, 0, "Expected number, got: %.20s\n", str);
    messageClose(LOG_STDOUT);
    omc_throw_function(NULL);
  }
  if (d != expected) {
    errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", fileName);
    errorStreamPrint(LOG_STDOUT, 0, "Got number %f, expected: %f\n", d, expected);
    messageClose(LOG_STDOUT);
    omc_throw_function(NULL);
  }
  return endptr;
}

/**
 * @brief Skipp JSON object if it exists.
 *
 * @param str             Pointer to object/filed to skip.
 * @param name            Name of object to skip.
 * @param fileName        Name of JSON to parse. Used for error messages.
 * @return const char*    Point to next locatin after object.
 */
static inline const char *skipFieldIfExist(const char *str, const char *name, const char* fileName)
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
  s = skipValue(s, fileName);
  s = skipSpace(s);
  s = skipSpace(s);
  return s;
}

/**
 * @brief Parse single equation info from JSON.
 *
 * @param str             Points to beginning of equation object.
 * @param xml             Equation info to fill
 * @param i               Index of equation inside "equations" array.
 * @param fileName        Name of JSON to parse. Used for error messages.
 * @return const char*    Point to next locatin after character.
 */
static const char* readEquation(const char *str, EQUATION_INFO *xml, int i, const char* fileName)
{
  int n=0,j;
  const char *str2;
  str=assertChar(str,'{', fileName);
  str=assertStringValue(str,"eqIndex", fileName);
  str=assertChar(str,':', fileName);
  str=assertNumber(str,i,fileName);
  str=skipSpace(str);
  xml->id = i;
  str = skipFieldIfExist(str, "parent", fileName);
  str = skipFieldIfExist(str, "section", fileName);
  if ((measure_time_flag & 1) && 0==strncmp(",\"tag\":\"system\"", str, 15)) {
    xml->profileBlockIndex = -1;
    str += 15;
  } else if ((measure_time_flag & 1) && 0==strncmp(",\"tag\":\"tornsystem\"", str, 19)) {
    xml->profileBlockIndex = -1;
    str += 19;
  } else {
    xml->profileBlockIndex = 0;
  }
  str = skipFieldIfExist(str, "tag", fileName);
  str = skipFieldIfExist(str, "display", fileName);
  str = skipFieldIfExist(str, "unknowns", fileName);
  if (strncmp(",\"defines\":[", str, 12)) {
    xml->numVar = 0;
    xml->vars = 0;
    str = skipObjectRest(str,0, fileName);
    return str;
  }
  str += 12;
  str = skipSpace(str);
  if (*str == ']') {
    xml->numVar = 0;
    xml->vars = 0;
    return skipObjectRest(str-1,0, fileName);
  }
  str2 = skipSpace(str);
  while (1) {
    str=skipValue(str, fileName);
    n++;
    str=skipSpace(str);
    if (*str != ',') {
      break;
    }
    str++;
  };
  assertChar(str, ']', fileName);
  xml->numVar = n;
  xml->vars = malloc(sizeof(const char*)*n);
  str = str2;
  for (j=0; j<n; j++) {
    const char *str3 = skipSpace(str);
    char *tmp;
    int len=0;
    str = assertChar(str, '\"', fileName);
    while (*str != '\"' && *str) {
      len++;
      str++;
    }
    str = assertChar(str, '\"', fileName);
    tmp = malloc(len+1);
    strncpy(tmp, str3+1, len);
    tmp[len] = '\0';
    xml->vars[j] = tmp;
    if (j != n-1) {
      str = assertChar(str, ',', fileName);
    }
  }
  str = assertChar(skipSpace(str), ']', fileName);
  return skipObjectRest(str,0, fileName);
}

/**
 * @brief Parse equations from info.json.
 *
 * @param str           Point to beginning of equation array at '['.
 * @param xml           Model data from xml
 * @return const char*  Point to end of equation array dirreclty after ']'.
 */
static const char* readEquations(const char *str, MODEL_DATA_XML *xml)
{
  int i;
  xml->nProfileBlocks = measure_time_flag & 2 ? 1 : 0;
  str=assertChar(str,'[', xml->fileName);
  str = readEquation(str, xml->equationInfo, 0, xml->fileName);
  for (i=1; i<xml->nEquations; i++) {
    if (*str != ',') {
      errorStreamPrint(LOG_STDOUT, 1, "Failed to parse %s", xml->fileName);
      errorStreamPrint(LOG_STDOUT, 0, "Expected %ld equations, but only found %i equations.",  xml->nEquations, i-1);
      messageClose(LOG_STDOUT);
      omc_throw_function(NULL);
    } else {
      str = str + 1;
    }
    str = readEquation(str, xml->equationInfo+i, i, xml->fileName);
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
  str=assertChar(str,']', xml->fileName);
  return str;
}

static const char* readFunction(const char *str, FUNCTION_INFO *xml, int i, const char* fileName)
{
  FILE_INFO info = omc_dummyFileInfo;
  size_t len;
  char *name;
  const char *str2;
  str=skipSpace(str);
  str2=assertChar(str,'"', fileName);
  str=skipValue(str, fileName);
  xml->id = i;
  len = str-str2;
  name = malloc(len);
  memcpy(name, str2, len-1);
  name[len-1] = '\0';
  xml->name = name;
  xml->info = info;
  return str;
}

static const char* readFunctions(const char *str, MODEL_DATA_XML *xml)
{
  int i;
  if (xml->nFunctions == 0) {
    str=assertChar(str,'[', xml->fileName);
    str=assertChar(str,']', xml->fileName);
    return str;
  }
  str=assertChar(str,'[', xml->fileName);
  for (i=0; i<xml->nFunctions; i++) {
    str = readFunction(str, xml->functionNames+i, i, xml->fileName);
    str=assertChar(str,xml->nFunctions==i+1 ? ']' : ',', xml->fileName);
  }
  return str;
}

static void readInfoJson(const char *str, MODEL_DATA_XML *xml)
{
  str=assertChar(str,'{', xml->fileName);
  str=assertStringValue(str,"format", xml->fileName);
  str=assertChar(str,':', xml->fileName);
  str=assertStringValue(str,"Transformational debugger info", xml->fileName);
  str=assertChar(str,',', xml->fileName);
  str=assertStringValue(str,"version", xml->fileName);
  str=assertChar(str,':', xml->fileName);
  str=assertChar(str,'1', xml->fileName);
  str=assertChar(str,',', xml->fileName);
  str=assertStringValue(str,"info", xml->fileName);
  str=assertChar(str,':', xml->fileName);
  str=skipValue(str, xml->fileName);
  str=assertChar(str,',', xml->fileName);
  str=assertStringValue(str,"variables", xml->fileName);
  str=assertChar(str,':', xml->fileName);
  str=skipValue(str, xml->fileName);
  str=assertChar(str,',', xml->fileName);
  str=assertStringValue(str,"equations", xml->fileName);
  str=assertChar(str,':', xml->fileName);
  str=readEquations(str,xml);
  str=assertChar(str,',', xml->fileName);
  str=assertStringValue(str,"functions", xml->fileName);
  str=assertChar(str,':', xml->fileName);
  str=readFunctions(str,xml);
  assertChar(str,'}', xml->fileName);
}

/**
 * @brief Initialize model data xml structure by parsing info.json.
 *
 * @param xml     Model info struct to initialize.
 */
void modelInfoInit(MODEL_DATA_XML* xml)
{
  // check for file exists, as --fmiFilter=blackBox or protected will not export the _info.json file
  int fileExists;
  if (omc_flag[FLAG_INPUT_PATH])
  {
    const char *jsonFile;
    GC_asprintf(&jsonFile, "%s/%s", omc_flagValue[FLAG_INPUT_PATH], xml->fileName);
    fileExists = omc_file_exists(jsonFile);
  }
  else
  {
    fileExists = omc_file_exists(xml->fileName);
  }

  if (!fileExists)
  {
    xml->fileName = NULL;
    return;
  }

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
  assert(xml->functionNames == NULL);
  xml->functionNames = (FUNCTION_INFO*) calloc(xml->nFunctions, sizeof(FUNCTION_INFO));
  assert(xml->equationInfo == NULL);
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

/**
 * @brief Deinitialize memory allocated by modelInfoInit
 *
 * @param xml   Pointer to model info xml data.
 */
void modelInfoDeinit(MODEL_DATA_XML* xml)
{
  free(xml->functionNames); xml->functionNames = NULL;
  free(xml->equationInfo); xml->equationInfo = NULL;
}

FUNCTION_INFO modelInfoGetFunction(MODEL_DATA_XML* xml, size_t ix)
{
  /* check for xml->fileName == NULL for --fmiFilter=blackBox and protected
   * and return dummy function info to make the fmu's simulation work, as
   * the _json.info will not be exported for the above --fmiFilter combinations
  */
  if (xml->fileName == NULL)
    return modelInfoGetDummyFunction(xml);

  if(xml->functionNames == NULL)
  {
    modelInfoInit(xml);
  }
  assert(xml->functionNames);
  return xml->functionNames[ix];
}

FUNCTION_INFO modelInfoGetDummyFunction(MODEL_DATA_XML* xml)
{
  FUNCTION_INFO functionInfo = omc_dummyFunctionInfo;
  return functionInfo;
}

EQUATION_INFO modelInfoGetDummyEquation(MODEL_DATA_XML* xml)
{
  const char * var = "";
  EQUATION_INFO equationInfo = {-1, 0, 0, -1, &var}; // omc_dummyEquationInfo is not working in mingw
  return equationInfo;
}

/**
 * @brief Get equation info for equation with index `ix`.
 *
 * Return dummy equation info if xml->fileName == NULL, e.g. for
 * --fmiFilter=blackBox and protected.
 * Return dummy equation info if `ix` is out of range.
 *
 * @param xml             Model info XML.
 * @param ix              Equation index.
 * @return EQUATION_INFO  Equation info for equation `ix`.
 */
EQUATION_INFO modelInfoGetEquation(MODEL_DATA_XML* xml, size_t ix)
{
  /* check for xml->fileName == NULL for --fmiFilter=blackBox and protected
   * and return dummy equation info to make the fmu's simulation work, as
   * the _json.info will not be exported for the above --fmiFilter combinations
  */
  if (xml->fileName == NULL)
    return modelInfoGetDummyEquation(xml);

  if (xml->equationInfo == NULL) {
    modelInfoInit(xml);
  }
  assert(xml->equationInfo);
  if (ix<0 || ix > xml->nEquations) {
    errorStreamPrint(LOG_STDOUT, 0, "modelInfoGetEquation failed to get info for equation %zu, out of range.\n", ix);
    return modelInfoGetDummyEquation(xml);
  }
  return xml->equationInfo[ix];
}

EQUATION_INFO modelInfoGetEquationIndexByProfileBlock(MODEL_DATA_XML* xml, size_t ix)
{
  /* check for xml->fileName == NULL for --fmiFilter=blackBox and protected
   * and return dummy equation info to make the fmu's simulation work, as
   * the _json.info will not be exported for the above --fmiFilter combinations
  */
  if (xml->fileName == NULL)
    return modelInfoGetDummyEquation(xml);

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

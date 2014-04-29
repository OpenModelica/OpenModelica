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

#ifndef _GNU_SOURCE
  #define _GNU_SOURCE /* for asprintf */
#endif

#include "simulation_info_xml.h"
#include "simulation_runtime.h"
#include "omc_msvc.h" /* for asprintf */
#include <expat.h>
#include <errno.h>
#include <string.h>
#include "uthash.h"
#include <stdio.h>
#include "util/rtclock.h"

#if 1

typedef struct {
  MODEL_DATA_XML *xml;
  long curIndex;
  long curProfileIndex;
  long curFunctionIndex;
} userData_t;

typedef struct hash_variable
{
  const char *id;
  VAR_INFO var_info;
  UT_hash_handle hh;
} hash_variable;

static hash_variable *variables = NULL;
static VAR_INFO var_info;
static FILE_INFO file_info;
static int maxVarsBuffer = 0;
static const char **varsBuffer = 0;
static int isChild = 0;

static void add_variable(VAR_INFO vi)
{
  hash_variable *s = (hash_variable*)malloc(sizeof(hash_variable));
  s->id = vi.name;
  s->var_info = vi;
  HASH_ADD_KEYPTR(hh, variables, s->id, strlen(s->id), s);
}

static VAR_INFO* findVariable(const char *name)
{
  hash_variable *s;
  HASH_FIND_STR(variables, name, s);
  if (0==s && 0!=strstr(name, "dummyVarStateSetJac")) {
    static VAR_INFO dummyInfo = omc_dummyVarInfo;
    return &dummyInfo;
  }
  assertStreamPrint(NULL, 0!=s, "Referenced '%s' that was not declared as <variable>", name);
  return &s->var_info;
}

static void XMLCALL startElement(void *voidData, const char *name, const char **attr)
{
  userData_t *userData = (userData_t*) voidData;

  if(0==strcmp("defines", name))
  {
    assertStreamPrint(NULL, ((0==strcmp(attr[0], "name")) && attr[2] == NULL), "<defines> needs to have exactly one attribute: name");
    if(varsBuffer == 0 || maxVarsBuffer == 0)
    {
      maxVarsBuffer = 32;
      varsBuffer = (const char**) malloc(sizeof(const char*)*maxVarsBuffer);
    }
    else if(userData->xml->equationInfo[userData->curIndex].numVar+2 >= maxVarsBuffer)
    {
      maxVarsBuffer *= 2;
      varsBuffer = realloc(varsBuffer, sizeof(const char*)*maxVarsBuffer);
    }
    varsBuffer[userData->xml->equationInfo[userData->curIndex].numVar++] = attr[1];
    return;
  }
  if(0==strcmp("info", name))
  {
    while(attr[0])
    {
      if(0 == strcmp("file", attr[0]))
      {
        file_info.filename = strdup(attr[1]);
      }
      else if(0 == strcmp("lineStart", attr[0]))
      {
        file_info.lineStart = strtol(attr[1], NULL, 10);
      }
      else if(0 == strcmp("lineEnd", attr[0]))
      {
        file_info.lineEnd = strtol(attr[1], NULL, 10);
      }
      else if(0 == strcmp("colStart", attr[0]))
      {
        file_info.colStart = strtol(attr[1], NULL, 10);
      }
      else if(0 == strcmp("colEnd", attr[0]))
      {
        file_info.colEnd = strtol(attr[1], NULL, 10);
      }
      else if(0 == strcmp("readonly", attr[0]))
      {
        file_info.readonly = 0==strcmp(attr[1], "true");
      }
      else
      {
        throwStreamPrint(NULL, "%s: Unknown attribute in <info>", userData->xml->fileName);
      }
      attr += 2;
    }
    return;
  }
  if(0 == strcmp("equation", name))
  {
    long ix;
    if(userData->curIndex > userData->xml->nEquations) {
      throwStreamPrint(NULL, "%s: Info XML %s contained more equations than expected (%ld)", __FILE__, userData->xml->fileName, userData->xml->nEquations);
    }
    if(!attr[0] || strcmp("index", attr[0])) {
      throwStreamPrint(NULL, "%s: Info XML %s contained equation without index", __FILE__, userData->xml->fileName);
    }
    ix = strtol(attr[1], NULL, 10);
    if (attr[2] && 0==strcmp("parent", attr[2])) {
      userData->xml->equationInfo[userData->curIndex].parent = strtol(attr[3], NULL, 10);
    } else {
      userData->xml->equationInfo[userData->curIndex].parent = 0;
    }
    if(userData->curIndex != ix) {
      throwStreamPrint(NULL, "%s: Info XML %s got equation with index %ld, expected %ld", __FILE__, userData->xml->fileName, ix, userData->curIndex);
    }
    userData->xml->equationInfo[userData->curIndex].id = userData->curIndex;
    userData->xml->equationInfo[userData->curIndex].profileBlockIndex = measure_time_flag & 2 ? userData->curIndex : -1; /* TODO: Set when parsing other tags */
    userData->xml->equationInfo[userData->curIndex].numVar = 0; /* TODO: Set when parsing other tags */
    userData->xml->equationInfo[userData->curIndex].vars = NULL; /* Set when parsing other tags (on close). */
  }
  if(0 == strcmp("variable", name))
  {
    var_info.name = NULL;
    var_info.comment = NULL;
    while (attr[0]) {
      if(0 == strcmp(attr[0], "name"))
      {
        var_info.name = strdup(attr[1]);
      }
      else if(0 == strcmp(attr[0], "comment"))
      {
        var_info.comment = strdup(attr[1]);
      }
      attr+=2;
    }
    assertStreamPrint(NULL, var_info.name && var_info.comment, "<var>-tag did not set name and comment");
    var_info.id = -1; /* ??? */
    var_info.info = file_info;
    return;
  }
  if(0 == strcmp("function", name))
  {
    userData->xml->functionNames[userData->curFunctionIndex].id = userData->curFunctionIndex;
    userData->xml->functionNames[userData->curFunctionIndex].name = "#FIXME#";
    userData->xml->functionNames[userData->curFunctionIndex].name = strdup(attr[1]);
    userData->xml->functionNames[userData->curFunctionIndex].info.filename = "TODO: Set me up!!!";
  }
}

static void XMLCALL endElement(void *voidData, const char *name)
{
  userData_t *userData = (userData_t*) voidData;

  if(0 == strcmp("variable", name))
  {
    add_variable(var_info);
    return;
  }
  if(0 == strcmp("equation", name))
  {
    int i;
    userData->xml->equationInfo[userData->curIndex].vars = (const char**) malloc(sizeof(const char*)*userData->xml->equationInfo[userData->curIndex].numVar);
    for(i=0; i<userData->xml->equationInfo[userData->curIndex].numVar; i++)
    {
      userData->xml->equationInfo[userData->curIndex].vars[i] = strdup(varsBuffer[i]);
    }
    userData->curIndex++;

    return;
  }
  if (measure_time_flag & 1) {
    if(0 == strcmp("linear", name))
    {
      userData->xml->equationInfo[userData->curIndex].profileBlockIndex = userData->curProfileIndex;
      userData->curProfileIndex++;
      return;
    }
    if(0 == strcmp("nonlinear", name))
    {
      userData->xml->equationInfo[userData->curIndex].profileBlockIndex = userData->curProfileIndex;
      userData->curProfileIndex++;
      return;
    }
  }
  if(0 == strcmp("function", name))
  {
    userData->curFunctionIndex++;
    return;
  }
}

FUNCTION_INFO modelInfoXmlGetFunction(MODEL_DATA_XML* xml, size_t ix)
{
  if(xml->equationInfo == NULL)
  {
    modelInfoXmlInit(xml);
  }
  return xml->functionNames[ix];
}

void modelInfoXmlInit(MODEL_DATA_XML* xml)
{
  FILE* file = NULL;
  XML_Parser parser = NULL;
  userData_t userData = {xml, 1, 0, 0};
  if(!xml->infoXMLData)
  {
    file = fopen(xml->fileName, "r");
    if(!file)
    {
      const char *str = strerror(errno);
      throwStreamPrint(NULL, "Failed to open file %s: %s\n", xml->fileName, str);
    }
  }
  parser = XML_ParserCreate(NULL);
  if(!parser)
  {
    throwStreamPrint(NULL, "Failed to create expat object");
  }
  xml->functionNames = (FUNCTION_INFO*) calloc(xml->nFunctions, sizeof(FUNCTION_INFO));
  xml->equationInfo = (EQUATION_INFO*) calloc(1+xml->nEquations, sizeof(EQUATION_INFO));
  xml->equationInfo[0].id = 0;
  xml->equationInfo[0].profileBlockIndex = measure_time_flag & 2 ? 0 : -1;
  xml->equationInfo[0].numVar = 0;
  xml->equationInfo[0].vars = NULL;
  XML_SetUserData(parser, (void*) &userData);
  XML_SetElementHandler(parser, startElement, endElement);
  if(!xml->infoXMLData)
  {
    char buf[BUFSIZ] = {0};
    int done;
    do {
      size_t len = fread(buf, 1, sizeof(buf), file);
      done = len < sizeof(buf);
      if(XML_Parse(parser, buf, len, done) == XML_STATUS_ERROR) {
        const char *err = XML_ErrorString(XML_GetErrorCode(parser));
        unsigned long line = XML_GetCurrentLineNumber(parser);
        fclose(file);
        XML_ParserFree(parser);
        throwStreamPrint(NULL, "%s: Error: failed to read the XML file %s: %s at line %lu", __FILE__, xml->fileName, err, line);
      }
    } while(!done);
    fclose(file);
  } else {
    if(XML_Parse(parser, xml->infoXMLData, strlen(xml->infoXMLData), 1) == XML_STATUS_ERROR) {
      const char *err = XML_ErrorString(XML_GetErrorCode(parser));
      unsigned long line = XML_GetCurrentLineNumber(parser);
      XML_ParserFree(parser);
      throwStreamPrint(NULL, "%s: Error: failed to read the XML data %s: %s at line %lu", __FILE__, xml->infoXMLData, err, line);
    }
  }
  assert(xml->nEquations == userData.curIndex);
  xml->nProfileBlocks = measure_time_flag & 1 ? userData.curProfileIndex : measure_time_flag & 2 ? xml->nEquations : 0; /* Set the number of profile blocks to the number we read */
  assert(xml->nFunctions == userData.curFunctionIndex);
}

EQUATION_INFO modelInfoXmlGetEquation(MODEL_DATA_XML* xml, size_t ix)
{
  if(xml->equationInfo == NULL)
  {
    modelInfoXmlInit(xml);
  }
  return xml->equationInfo[ix];
}

EQUATION_INFO modelInfoXmlGetEquationIndexByProfileBlock(MODEL_DATA_XML* xml, size_t ix)
{
  int i;
  if(xml->equationInfo == NULL)
  {
    modelInfoXmlInit(xml);
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

void freeModelInfoXml(MODEL_DATA_XML* xml)
{
  if(xml->functionNames)
  {
    free(xml->functionNames);
    xml->functionNames = 0;
  }
  if(xml->equationInfo)
  {
    int i;
    for(i=0;i<xml->nEquations;++i) {
      free(xml->equationInfo[i].vars);
      xml->equationInfo[i].vars = 0;
    }
    free(xml->equationInfo);
    xml->equationInfo = 0;
  }
}

#else
/* JSON */

#if !defined(HAVE_MMAP)
#if defined(unix)
#include <unistd.h>
#endif
#if _POSIX_MAPPED_FILES>0
#define HAVE_MMAP 1
#else
#define HAVE_MMAP 0
#endif
#endif

#if HAVE_MMAP
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#endif

#include "string_util.h"

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
        throwStreamPrint(NULL, "JSON object expected ',' or '}', got: %.20s\n", str);
      }
      str++;
    } else {
      first = 0;
    }
    str = skipValue(str);
    str = skipSpace(str);
    if (*str++ != ':') {
      throwStreamPrint(NULL, "JSON object expected ':', got: %.20s\n", str);
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
        throwStreamPrint(NULL, "JSON array expected ',' or ']', got: %.20s\n", str);
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
      case '\0': throwStreamPrint(NULL, "Found end of file, expected end of string");
      case '\\':
        if (str+1 == '\0') {
          throwStreamPrint(NULL, "Found end of file, expected end of string");
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
    double d = om_strtod(str,&endptr);
    if (str == endptr) {
      throwStreamPrint(NULL, "Not a number, got %.20s\n", str);
    }
    return endptr;
  }
  default:
    throwStreamPrint(NULL, "JSON value expected, got: %.20s\n", str);
  }
}

/* Does not work for escaped strings. Returns the rest of the string to parse. */
static inline const char* assertStringValue(const char *str, const char *value)
{
  int len = strlen(value);
  str = skipSpace(str);
  if ('\"' != *str || strncmp(str+1,value,len) || str[len+1] != '\"') {
    throwStreamPrint(NULL, "JSON string value %s expected, got: %.20s\n", value, str);
  }
  return str + len + 2;
}

static inline const char* assertChar(const char *str, char c)
{
  str = skipSpace(str);
  if (c != *str) {
    throwStreamPrint(NULL, "Expected '%c', got: %.20s\n", c, str);
  }
  return str + 1;
}

static inline const char* assertNumber(const char *str, double expected)
{
  char *endptr = NULL;
  double d;
  str = skipSpace(str);
  d = om_strtod(str, &endptr);
  if (str == endptr) {
    throwStreamPrint(NULL, "Expected number, got: %.20s\n", str);
  }
  if (d != expected) {
    throwStreamPrint(NULL, "Got number %f, expected: %f\n", d, expected);
  }
  return endptr;
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
  xml->profileBlockIndex = 0;
  if (strncmp(",\"defines\":[", str, 12)) {
    xml->numVar = 0;
    xml->vars = 0;
    return skipObjectRest(str,0);
  }
  str += 12;
  str = skipSpace(str);
  if (*str == ']') {
    xml->numVar = 0;
    xml->vars = 0;
    return skipObjectRest(str,0);
  }
  str2 = str;
  while (1) {
    str=skipValue(str);
    n++;
    str=skipSpace(str);
    if (*str != ',') {
      break;
    }
    str++;
  };
  str = assertChar(str, ']');
  xml->numVar = n;
  xml->vars = malloc(sizeof(const char*)*i);
  for (j=0; j<n; j++) {
    xml->vars[j] = "some variable";
  }
  return skipObjectRest(str,0);
}

static const char* readEquations(const char *str,MODEL_DATA_XML *xml)
{
  int i;
  str=assertChar(str,'[');
  str = readEquation(str,xml->equationInfo,0);
  str = assertChar(str,',');
  for (i=1; i<xml->nEquations; i++) {
    str = readEquation(str,xml->equationInfo+i,i);
    /* TODO: Odd, it seems there is 1 fewer equation than expected... */
    if (i != xml->nEquations-1) {
      str=assertChar(str,',');
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

static void readInfoXml(const char *str,MODEL_DATA_XML *xml)
{
  str=assertChar(str,'{');
  str=assertStringValue(str,"format");
  str=assertChar(str,':');
  str=assertStringValue(str,"OpenModelica debug info");
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
  str=assertChar(str,'}');
}

void modelInfoXmlInit(MODEL_DATA_XML* xml)
{
  rt_tick(0);
  if (!xml->infoXMLData) {
    struct stat s;
    int fd;
    int len = strlen(xml->fileName);
    char *fileName = malloc(len + 2);
    assert(len > 4);
    strcpy(fileName, xml->fileName);
    strcpy(fileName+len-3, "json");
    fd = open(fileName, O_RDONLY);
    free(fileName);
    fileName = (char*) xml->fileName;
    if (fd < 0) {
      throwStreamPrint(NULL, "Failed to open file %s for reading: %s\n", fileName, strerror(errno));
    }
    if (fstat(fd, &s) < 0) {
      close(fd);
      throwStreamPrint(NULL, "fstat %s failed: %s\n", fileName, strerror(errno));
    }
    xml->modelInfoXmlLength = s.st_size;
    xml->infoXMLData = (char*) mmap(0, xml->modelInfoXmlLength, PROT_READ, MAP_SHARED, fd, 0);
    if (xml->infoXMLData == MAP_FAILED) {
      close(fd);
      throwStreamPrint(NULL, "mmap(file=\"%s\",fd=%d,size=%ld kB) failed: %s\n", fileName, fd, (long) s.st_size, strerror(errno));
    }
    close(fd);
    // fprintf(stderr, "Loaded the JSON (%ld kB)...\n", (long) (s.st_size+1023)/1024);
  }

  xml->functionNames = (FUNCTION_INFO*) calloc(xml->nFunctions, sizeof(FUNCTION_INFO));
  xml->equationInfo = (EQUATION_INFO*) calloc(1+xml->nEquations, sizeof(EQUATION_INFO));
  xml->equationInfo[0].id = 0;
  xml->equationInfo[0].profileBlockIndex = -1;
  xml->equationInfo[0].numVar = 0;
  xml->equationInfo[0].vars = NULL;

  // fprintf(stderr, "Loaded the JSON file in %fms...\n", rt_tock(0) * 1000.0);
  // fprintf(stderr, "Parse the JSON %s\n", xml->infoXMLData);
  // fprintf(stderr, "Parse the JSON %ld...\n", (long) xml->infoXMLData);
  readInfoXml(xml->infoXMLData, xml);
  // fprintf(stderr, "Parsed the JSON in %fms...\n", rt_tock(0) * 1000.0);
}

FUNCTION_INFO modelInfoXmlGetFunction(MODEL_DATA_XML* xml, size_t ix)
{
  if(xml->functionNames == NULL)
  {
    modelInfoXmlInit(xml);
  }
  return xml->functionNames[ix];
}

EQUATION_INFO modelInfoXmlGetEquation(MODEL_DATA_XML* xml, size_t ix)
{
  if(xml->equationInfo == NULL)
  {
    modelInfoXmlInit(xml);
  }
  return xml->equationInfo[ix];
}

EQUATION_INFO modelInfoXmlGetEquationIndexByProfileBlock(MODEL_DATA_XML* xml, size_t ix)
{
  abort();
}

void freeModelInfoXml(MODEL_DATA_XML* xml)
{
  if (xml->modelInfoXmlLength) {
    munmap((void*)xml->infoXMLData, xml->modelInfoXmlLength);
  }
}

#endif

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
#include "simulation_info_json.h"

#include "simulation_runtime.h"
#include "util/omc_msvc.h" /* for asprintf */
#include "meta/meta_modelica.h" /* for mmc_sint_t types */
#include <expat.h>
#include <errno.h>
#include <string.h>
#include "util/uthash.h"
#include <stdio.h>
#include "util/rtclock.h"

FUNCTION_INFO modelInfoXmlGetFunction(MODEL_DATA_XML*,size_t);
void modelInfoXmlInit(MODEL_DATA_XML*);
EQUATION_INFO modelInfoXmlGetEquation(MODEL_DATA_XML*,size_t);
EQUATION_INFO modelInfoXmlGetEquationIndexByProfileBlock(MODEL_DATA_XML*,size_t);
void freeModelInfoXml(MODEL_DATA_XML*);

typedef struct {
  MODEL_DATA_XML *xml;
  mmc_sint_t curIndex;
  mmc_sint_t curProfileIndex;
  mmc_sint_t curFunctionIndex;
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
static mmc_sint_t maxVarsBuffer = 0;
static const char **varsBuffer = 0;
static mmc_sint_t isChild = 0;

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
    varsBuffer[userData->xml->equationInfo[userData->curIndex].numVar++] = strdup(attr[1]);
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
    mmc_sint_t ix;
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
    mmc_sint_t i;
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
  if (!xml->infoXMLData)
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
    mmc_sint_t done;
    do {
      size_t len = fread(buf, 1, sizeof(buf), file);
      done = len < sizeof(buf);
      if(XML_Parse(parser, buf, len, done) == XML_STATUS_ERROR) {
        const char *err = XML_ErrorString(XML_GetErrorCode(parser));
        mmc_uint_t line = XML_GetCurrentLineNumber(parser);
        fclose(file);
        XML_ParserFree(parser);
        throwStreamPrint(NULL, "%s: Error: failed to read the XML file %s: %s at line %lu", __FILE__, xml->fileName, err, line);
      }
    } while(!done);
    fclose(file);
  } else {
    if(XML_Parse(parser, xml->infoXMLData, strlen(xml->infoXMLData), 1) == XML_STATUS_ERROR) {
      const char *err = XML_ErrorString(XML_GetErrorCode(parser));
      mmc_uint_t line = XML_GetCurrentLineNumber(parser);
      XML_ParserFree(parser);
      throwStreamPrint(NULL, "%s: Error: failed to read the XML data %s: %s at line %lu", __FILE__, xml->infoXMLData, err, line);
    }
  }
  assert(xml->nEquations == userData.curIndex);
  xml->nProfileBlocks = measure_time_flag & 1 ? userData.curProfileIndex : measure_time_flag & 2 ? xml->nEquations : 0; /* Set the number of profile blocks to the number we read */
  assert(xml->nFunctions == userData.curFunctionIndex);
  XML_ParserFree(parser);
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
  mmc_sint_t i;
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
    mmc_sint_t i;
    for(i=0;i<xml->nEquations;++i) {
      free(xml->equationInfo[i].vars);
      xml->equationInfo[i].vars = 0;
    }
    free(xml->equationInfo);
    xml->equationInfo = 0;
  }
}

FUNCTION_INFO (*modelInfoGetFunction)(MODEL_DATA_XML*,size_t) = 0;
void (*modelInfoInit)(MODEL_DATA_XML*) = 0;
EQUATION_INFO (*modelInfoGetEquation)(MODEL_DATA_XML*,size_t) = 0;
EQUATION_INFO (*modelInfoGetEquationIndexByProfileBlock)(MODEL_DATA_XML*,size_t) = 0;
void (*freeModelInfo)(MODEL_DATA_XML*) = 0;

/* NOTE: Once we use JSON everywhere, remove the XML parts in order to make FMU's work better (can't mix xml and json FMU's) */
void setupModelInfoFunctions(int isJson)
{
  if (isJson) {
    modelInfoGetFunction = modelInfoJsonGetFunction;
    modelInfoInit = modelInfoJsonInit;
    modelInfoGetEquation = modelInfoJsonGetEquation;
    modelInfoGetEquationIndexByProfileBlock = modelInfoJsonGetEquationIndexByProfileBlock;
    freeModelInfo = freeModelInfoJson;
  } else {
    modelInfoGetFunction = modelInfoXmlGetFunction;
    modelInfoInit = modelInfoXmlInit;
    modelInfoGetEquation = modelInfoXmlGetEquation;
    modelInfoGetEquationIndexByProfileBlock = modelInfoXmlGetEquationIndexByProfileBlock;
    freeModelInfo = freeModelInfoXml;
  }
}

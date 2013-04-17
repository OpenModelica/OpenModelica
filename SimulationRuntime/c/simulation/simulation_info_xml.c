/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#include "simulation_info_xml.h"
#include "omc_msvc.h" /* for asprintf */
#include <expat.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

static void XMLCALL startElement(void *userData, const char *name, const char **attr) {
  MODEL_DATA_XML* xml = (MODEL_DATA_XML*) ((void**)userData)[0];
  long curIndex = (long) ((void**)userData)[1];
  //long curProfileIndex = (long) ((void**)userData)[2];
  long curFunctionIndex = (long) ((void**)userData)[3];

  if (0==strcmp("equation",name)) {
    long ix;
    if (curIndex > xml->nEquations) {
      THROW3("%s: Info XML %s contained more equations than expected (%ld)", __FILE__, xml->fileName, xml->nEquations);
    }
    if (strcmp("index",attr[0])) {
      THROW2("%s: Info XML %s contained equation without index", __FILE__, xml->fileName);
    }
    ix = strtol(attr[1], NULL, 10);
    if (curIndex != ix) {
      THROW4("%s: Info XML %s got equation with index %ld, expected %ld", __FILE__, xml->fileName, ix, curIndex);
    }
    xml->equationInfo[curIndex].id = curIndex;
    xml->equationInfo[curIndex].profileBlockIndex = -1; /* TODO: Set when parsing other tags */
    xml->equationInfo[curIndex].name = "SOME NICE EQUATION NAME (to be set a little later)"; /* TODO: Set when parsing other tags */
    xml->equationInfo[curIndex].numVar = 0; /* TODO: Set when parsing other tags */
    xml->equationInfo[curIndex].vars = NULL; /* TODO: Set when parsing other tags. Also needs to be... Bla bla bla. Not sure we need this anymore */
    return;
  }
  if (0==strcmp("function",name)) {
    xml->functionNames[curFunctionIndex].id = curFunctionIndex;
    xml->functionNames[curFunctionIndex].name = "#FIXME#";
    xml->functionNames[curFunctionIndex].name = strdup(attr[1]);
    xml->functionNames[curFunctionIndex].info.filename = "TODO: Set me up!!!";
  }
}

static void XMLCALL endElement(void *userData, const char *name) {
  MODEL_DATA_XML* xml = (MODEL_DATA_XML*) ((void**)userData)[0];
  long curIndex = (long) ((void**)userData)[1];
  long curProfileIndex = (long) ((void**)userData)[2];
  long curFunctionIndex = (long) ((void**)userData)[3];

  if (0==strcmp("equation",name)) {
    ((void**)userData)[1] = (void*) (curIndex+1);
    return;
  }
  if (0==strcmp("var",name)) {
    xml->equationInfo[curIndex].numVar++;
    return;
  }
  if (0==strcmp("nonlinear",name)) {
    asprintf(&xml->equationInfo[curIndex].name, "Nonlinear function (residualFunc%d, size %d)", curIndex, xml->equationInfo[curIndex].numVar);
    xml->equationInfo[curIndex].profileBlockIndex = curProfileIndex;
    ((void**)userData)[2] = (void*) (curProfileIndex+1);
    return;
  }
  if (0==strcmp("function",name)) {
    ((void**)userData)[3] = (void*) (curFunctionIndex+1);
    return;
  }
}

FUNCTION_INFO modelInfoXmlGetFunction(MODEL_DATA_XML* xml, size_t ix) {
  if (xml->equationInfo == NULL) {
    modelInfoXmlInit(xml);
  }
  return xml->functionNames[ix];
}

void modelInfoXmlInit(MODEL_DATA_XML* xml)
{
  int done=0;
  char buf[BUFSIZ] = {0};
  FILE* file = fopen(strdup(xml->fileName),"r");
  XML_Parser parser = NULL;
  void* userData[4] = {xml,(void*)1,(void*)0,(void*)0};
  if (!file) {
    const char *str = strerror(errno);
    THROW2("Failed to open file %s: %s\n", xml->fileName, str);
  }
  parser = XML_ParserCreate(NULL);
  if (!parser) {
    THROW("Failed to create expat object");
  }
  xml->functionNames = (FUNCTION_INFO*) calloc(xml->nFunctions, sizeof(FUNCTION_INFO));
  xml->equationInfo = (EQUATION_INFO*) calloc(1+xml->nEquations, sizeof(EQUATION_INFO));
  xml->equationInfo[0].id = 0;
  xml->equationInfo[0].profileBlockIndex = -1;
  xml->equationInfo[0].name = "Dummy equation so we can index from 1";
  xml->equationInfo[0].numVar = 0;
  xml->equationInfo[0].vars = NULL;
  XML_SetUserData(parser, userData);
  XML_SetElementHandler(parser, startElement, endElement);
  do {
    size_t len = fread(buf, 1, sizeof(buf), file);
    done = len < sizeof(buf);
    if(XML_Parse(parser, buf, len, done) == XML_STATUS_ERROR) {
      const char *err = XML_ErrorString(XML_GetErrorCode(parser));
      unsigned long line = XML_GetCurrentLineNumber(parser);
      fclose(file);
      XML_ParserFree(parser);
      THROW4("%s: Error: failed to read the XML file %s: %s at line %lu", __FILE__, xml->fileName, err, line);
    }
  } while(!done);
  assert(xml->nEquations == (long) userData[1]);
  xml->nProfileBlocks = (long) userData[2];
  assert(xml->nFunctions == (long) userData[3]);
  fclose(file);
}

EQUATION_INFO modelInfoXmlGetEquation(MODEL_DATA_XML* xml, size_t ix) {
  if (xml->equationInfo == NULL) {
    modelInfoXmlInit(xml);
  }
  return xml->equationInfo[ix];
}

EQUATION_INFO modelInfoXmlGetEquationIndexByProfileBlock(MODEL_DATA_XML* xml, size_t ix) {
  int i;
  if (xml->equationInfo == NULL) {
    modelInfoXmlInit(xml);
  }
  if (ix < 0 || ix > xml->nProfileBlocks) {
    THROW2("Requested equation with profiler index %ld, but we only have %ld such blocks", (long int)ix, xml->nProfileBlocks);
  }
  for (i=0; i<xml->nEquations; i++) {
    if (xml->equationInfo[i].profileBlockIndex == ix) {
      return xml->equationInfo[i];
    }
  }
  THROW1("Requested equation with profiler index %ld, but could not find it!", (long int)ix);
}

void freeModelInfoXml(MODEL_DATA_XML* xml) {
  int i;
  if (xml->functionNames) {
    free(xml->functionNames);
    xml->functionNames = 0;
  }
  if (xml->equationInfo) {
    for(i=0;i<xml->nEquations;++i) {
      free(xml->equationInfo[i].vars);
      xml->equationInfo[i].vars = 0;
    }
    free(xml->equationInfo);
    xml->equationInfo = 0;
  }
}


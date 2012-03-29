/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

extern "C" {

#include "meta_modelica.h"
#include "rml_compatibility.h"
#include "parse.c"

void* ParserExt_parse(const char* filename, int acceptedGrammer, const char* encoding, int runningTestsuite)
{
  int flags = PARSE_MODELICA;
  if(acceptedGrammer == 2) flags |= PARSE_META_MODELICA;
  else if(acceptedGrammer == 3) flags |= PARSE_PAR_MODELICA;

  void *res = parseFile(filename, flags, encoding, runningTestsuite);
  if (res == NULL)
    MMC_THROW();
  // printAny(res);
  return res;
}

void* ParserExt_parseexp(const char* filename, int acceptedGrammer, int runningTestsuite)
{
  int flags = PARSE_EXPRESSION;
  if(acceptedGrammer == 2) flags |= PARSE_META_MODELICA;
  else if(acceptedGrammer == 3) flags |= PARSE_PAR_MODELICA;
  
  void *res = parseFile(filename, flags, "UTF-8", runningTestsuite);
  if (res == NULL)
    MMC_THROW();
  return res;
}

void* ParserExt_parsestring(const char* data, const char* filename, int acceptedGrammer, int runningTestsuite)
{
  int flags = PARSE_MODELICA;
  if(acceptedGrammer == 2) flags |= PARSE_META_MODELICA;
  else if(acceptedGrammer == 3) flags |= PARSE_PAR_MODELICA;

  void *res = parseString(data, filename, flags, runningTestsuite);
  if (res != NULL) {
    return res;
  } else {
    MMC_THROW();
  }
}

void* ParserExt_parsestringexp(const char* data, const char* filename, int acceptedGrammer, int runningTestsuite)
{
  int flags = PARSE_EXPRESSION;
  if(acceptedGrammer == 2) flags |= PARSE_META_MODELICA;
  else if(acceptedGrammer == 3) flags |= PARSE_PAR_MODELICA;

  void *res = parseString(data, filename, flags, runningTestsuite);
  if (res != NULL) {
    return res;
  } else {
    MMC_THROW();
  }
}

}

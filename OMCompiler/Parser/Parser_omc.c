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

#if defined(_MSC_VER) || defined(__MINGW32__)
 #include <windows.h>
#endif

#include "meta/meta_modelica.h"
#include "parse.c"

static int set_grammar_flag(int flags, int grammar)
{
  switch (grammar) {
    case 2: flags |= PARSE_META_MODELICA; break;
    case 3: flags |= PARSE_PARMODELICA;   break;
    case 4: flags |= PARSE_OPTIMICA;      break;
    case 5: flags |= PARSE_PDEMODELICA;   break;
  }

  return flags;
}

void* ParserExt_parse(const char* filename, const char* infoname, int acceptedGrammar, int langStd, int strict, const char* encoding, int runningTestsuite, const char* libraryPath, void* lveInstance)
{
  int flags = set_grammar_flag(PARSE_MODELICA, acceptedGrammar);

  void *res = parseFile(filename, infoname, flags, encoding, langStd, strict, runningTestsuite, libraryPath, lveInstance);
  if (res == NULL)
    MMC_THROW();
  // printAny(res);
  return res;
}

void* ParserExt_parseexp(const char* filename, const char* infoname, int acceptedGrammar, int langStd, int runningTestsuite)
{
  int flags = set_grammar_flag(PARSE_EXPRESSION, acceptedGrammar);

  void *res = parseFile(filename, infoname, flags, "UTF-8", langStd, 0, runningTestsuite, "", 0);
  if (res == NULL)
    MMC_THROW();
  return res;
}

void* ParserExt_parsestring(const char* data, const char* filename, int acceptedGrammar, int langStd, int strict, int runningTestsuite)
{
  int flags = set_grammar_flag(PARSE_MODELICA, acceptedGrammar);

  void *res = parseString(data, filename, flags, langStd, strict, runningTestsuite);
  if (res != NULL) {
    return res;
  } else {
    MMC_THROW();
  }
}

void* ParserExt_parsestringexp(const char* data, const char* filename, int acceptedGrammar, int langStd, int runningTestsuite)
{
  int flags = set_grammar_flag(PARSE_EXPRESSION, acceptedGrammar);

  void *res = parseString(data, filename, flags, langStd, 0, runningTestsuite);
  if (res != NULL) {
    return res;
  } else {
    MMC_THROW();
  }
}

void* ParserExt_stringPath(const char* data, const char* filename, int acceptedGrammar, int langStd, int runningTestsuite)
{
  int flags = set_grammar_flag(PARSE_PATH, acceptedGrammar);

  void *res = parseString(data, filename, flags, langStd, 0, runningTestsuite);
  if (res != NULL) {
    return res;
  } else {
    MMC_THROW();
  }
}

void* ParserExt_stringCref(const char* data, const char* filename, int acceptedGrammar, int langStd, int runningTestsuite)
{
  int flags = set_grammar_flag(PARSE_CREF, acceptedGrammar);

  void *res = parseString(data, filename, flags, langStd, 0, runningTestsuite);
  if (res != NULL) {
    return res;
  } else {
    MMC_THROW();
  }
}

void* ParserExt_stringMod(const char* data, const char* filename, int acceptedGrammar, int langStd, int runningTestsuite)
{
  int flags = set_grammar_flag(PARSE_MODIFIER, acceptedGrammar);

  void *res = parseString(data, filename, flags, langStd, 0, runningTestsuite);
  if (res != NULL) {
    return res;
  } else {
    MMC_THROW();
  }
}

int ParserExt_startLibraryVendorExecutable(const char* path, void** lveInstance)
{
  return startLibraryVendorExecutable(path, lveInstance);
}

int ParserExt_checkLVEToolLicense(void** lveInstance, const char* packageName)
{
  return checkLVEToolLicense(lveInstance, packageName);
}

int ParserExt_checkLVEToolFeature(void** lveInstance, const char* feature)
{
  return checkLVEToolFeature(lveInstance, feature);
}

void ParserExt_stopLibraryVendorExecutable(void** lveInstance)
{
  stopLibraryVendorExecutable(lveInstance);
}

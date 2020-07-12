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


#include "openmodelica.h"
#include "meta/meta_modelica.h"
#include "util/modelica_string.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif

#include "util/ModelicaUtilitiesExtra.h"

#if !defined(Util__notrans)
#define Util__notrans Gettext__notrans
#endif
#if !defined(Error__INTERNAL_3dBOX0)
#define Error__INTERNAL ErrorTypes__INTERNAL
#define Error__NOTIFICATION ErrorTypes__NOTIFICATION
#define Error__WARNING ErrorTypes__WARNING
#define Error__ERROR ErrorTypes__ERROR
#define Error__SYNTAX ErrorTypes__SYNTAX
#define Error__TRANSLATION ErrorTypes__TRANSLATION
#define Error__SYMBOLIC ErrorTypes__SYMBOLIC
#define Error__SCRIPTING ErrorTypes__SCRIPTING
#define Error__GRAMMAR ErrorTypes__GRAMMAR
#define Error__SIMULATION ErrorTypes__SIMULATION
#define Error__MESSAGE ErrorTypes__MESSAGE
#define Error__TOTALMESSAGE ErrorTypes__TOTALMESSAGE
#define Error__SYNTAX_3dBOX0 ErrorTypes__SYNTAX_3dBOX0
#define Error__INTERNAL_3dBOX0 ErrorTypes__INTERNAL_3dBOX0
#endif

}

#include "errorext.cpp"

extern "C" {

void Error_registerModelicaFormatError()
{
  OpenModelica_ModelicaError = OpenModelica_ErrorModule_ModelicaError;
  OpenModelica_ModelicaVFormatError = OpenModelica_ErrorModule_ModelicaVFormatError;
}

extern void* Error_getMessages(threadData_t *threadData)
{
  return listReverse(ErrorImpl__getMessages(threadData));
}

extern const char* Error_printErrorsNoWarning(threadData_t *threadData)
{
  std::string res = ErrorImpl__printErrorsNoWarning(threadData);
  return omc_alloc_interface.malloc_strdup(res.c_str());
}

extern const char* Error_printMessagesStr(threadData_t *threadData,int warningsAsErrors)
{
  std::string res = ErrorImpl__printMessagesStr(threadData,warningsAsErrors);
  return omc_alloc_interface.malloc_strdup(res.c_str());
}

#if defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1)
extern void Error_addMessage(threadData_t *threadData,int errorID, void *msg_type, void *severity, const char* message, modelica_metatype tokenlst)
{
  ErrorMessage::TokenList tokens;
  while (MMC_GETHDR(tokenlst) != MMC_NILHDR) {
    const char* token = MMC_STRINGDATA(MMC_CAR(tokenlst));
    tokens.push_back(string(token));
    tokenlst=MMC_CDR(tokenlst);
  }
  add_source_message(threadData,errorID,
              (ErrorType) (MMC_HDRCTOR(MMC_GETHDR(msg_type))-Error__SYNTAX_3dBOX0),
              (ErrorLevel) (MMC_HDRCTOR(MMC_GETHDR(severity))-Error__INTERNAL_3dBOX0),
              message,tokens,0,0,0,0,0,"");
}
#endif

extern void Error_addSourceMessage(threadData_t *threadData,int _id, void *msg_type, void *severity, int _sline, int _scol, int _eline, int _ecol, int _read_only, const char* _filename, const char* _msg, void* tokenlst)
{
  ErrorMessage::TokenList tokens;
  while(MMC_GETHDR(tokenlst) != MMC_NILHDR) {
    tokens.push_back(string(MMC_STRINGDATA(MMC_CAR(tokenlst))));
    tokenlst=MMC_CDR(tokenlst);
  }
  add_source_message(threadData,_id,
                     (ErrorType) (MMC_HDRCTOR(MMC_GETHDR(msg_type))-Error__SYNTAX_3dBOX0),
                     (ErrorLevel) (MMC_HDRCTOR(MMC_GETHDR(severity))-Error__INTERNAL_3dBOX0),
                     _msg,tokens,_sline,_scol,_eline,_ecol,_read_only,_filename);
}

extern int Error_getNumMessages(threadData_t *threadData)
{
  return getMembers(threadData)->errorMessageQueue->size();
}

void Error_setShowErrorMessages(threadData_t *threadData,int show)
{
  getMembers(threadData)->showErrorMessages = show ? 1 : 0;
}

static void omc_assert_compiler_common(threadData_t *threadData,ErrorLevel severity, FILE_INFO info, const char *msg, va_list args)
{
  ErrorMessage::TokenList tokens;
  const char *str;
  GC_vasprintf(&str, msg, args);
  add_source_message(threadData, 0, ErrorType_runtime, severity, str, tokens, info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly, info.filename);
}

static void omc_assert_compiler(threadData_t *threadData, FILE_INFO info, const char *msg, ...) __attribute__ ((noreturn));
static void omc_assert_compiler(threadData_t *threadData, FILE_INFO info, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  omc_assert_compiler_common(threadData, ErrorLevel_error, info, msg, args);
  va_end(args);
  MMC_THROW_INTERNAL();
}

static void omc_assert_compiler_warning(FILE_INFO info, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  omc_assert_compiler_common(NULL, ErrorLevel_warning, info, msg, args);
  va_end(args);
}

void Error_initAssertionFunctions()
{
#if !defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1)
  omc_assert = omc_assert_compiler;
  omc_assert_warning = omc_assert_compiler_warning;
#endif
}

}

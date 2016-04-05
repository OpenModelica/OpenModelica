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
#include "meta_modelica.h"
#define ADD_METARECORD_DEFINITIONS static
#include "OpenModelicaBootstrappingHeader.h"
#include "ModelicaUtilitiesExtra.h"

}

#include "errorext.cpp"

extern "C" {

void Error_registerModelicaFormatError()
{
  OpenModelica_ModelicaError = OpenModelica_ErrorModule_ModelicaError;
  OpenModelica_ModelicaVFormatError = OpenModelica_ErrorModule_ModelicaVFormatError;
}

void Error_addMessage(threadData_t *threadData,int errorID, void *msg_type, void *severity, const char* message, modelica_metatype tokenlst)
{
  ErrorMessage::TokenList tokens;
  while (MMC_GETHDR(tokenlst) != MMC_NILHDR) {
    const char* token = MMC_STRINGDATA(MMC_CAR(tokenlst));
    tokens.push_back(string(token));
    tokenlst=MMC_CDR(tokenlst);
  }
  add_message(threadData,errorID,
              (ErrorType) (MMC_HDRCTOR(MMC_GETHDR(msg_type))-Error__SYNTAX_3dBOX0),
              (ErrorLevel) (MMC_HDRCTOR(MMC_GETHDR(severity))-Error__INTERNAL_3dBOX0),
              message,tokens);
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

}

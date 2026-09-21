/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/**
 * \file OMC.cpp
 * \brief Implementation of the libOMCDLL public C API (see OMC.h): a thin
 *        wrapper that drives libOpenModelicaCompiler in-process.
 */

#include "OMC.h"
#include "OMCFunctions.h"

#include <cstring>
#include <iostream>
#include <string>

namespace {
  const int OMC_STATUS_OK    = 1;
  const int OMC_STATUS_ERROR = -1;
}

/** Full definition of the handle declared opaque in OMC.h. */
struct OMCData {
  explicit OMCData(threadData_t *threadData) : threadData(threadData) {}
  threadData_t *threadData;
};

// After every call into omc the local `threadData` (managed by the MMC_TRY_TOP
// machinery) must be copied back into the instance so the next call sees the
// updated state.
#define CP_TD() (memcpy(omcData->threadData, threadData, sizeof(threadData_t)))

extern "C" {

void OMC_DLL InitMetaOMC(void)
{
  MMC_INIT();
  mmc_GC_init();
}

int OMC_DLL InitOMC(OMCData **omcDataPtr, const char *compiler, const char *openModelicaHome)
{
  (void) compiler;

  OMCData *omcData = new OMCData(static_cast<threadData_t *>(GC_malloc_uncollectable(sizeof(threadData_t))));
  *omcDataPtr = omcData;
  memset(omcData->threadData, 0, sizeof(threadData_t));

  MMC_TRY_TOP_SET(omcData->threadData)
  omc_Main_init(threadData, mmc_mk_nil());
  CP_TD();
#if defined(_WIN32)
  omc_Main_setWindowsPaths(threadData, mmc_mk_scon(openModelicaHome));
  CP_TD();
#else
  (void) openModelicaHome;
#endif
  omc_Main_readSettings(threadData, mmc_mk_nil());
  CP_TD();
  MMC_CATCH_TOP(return OMC_STATUS_ERROR)

  if (SetCommandLineOptions(omcData, "-d=newInst") == OMC_STATUS_ERROR) {
    char *errorMsg = nullptr;
    GetError(omcData, &errorMsg);
    std::cerr << "omcCAPI: could not set default options '-d=newInst': "
              << (errorMsg ? errorMsg : "") << std::endl;
    return OMC_STATUS_ERROR;
  }
  return OMC_STATUS_OK;
}

int OMC_DLL InitOMCWithZeroMQ(OMCData **omcDataPtr, const char *compiler, const char *codetarget,
                              const char *openModelicaHome, const char *zeromqOptions, int debug)
{
  if (InitOMC(omcDataPtr, compiler, openModelicaHome) == OMC_STATUS_ERROR) {
    return OMC_STATUS_ERROR;
  }
  OMCData *omcData = *omcDataPtr;

  const std::string options = "--simCodeTarget=" + std::string(codetarget) +
                              " --target=" + std::string(compiler) +
                              " " + std::string(zeromqOptions);
  if (debug) {
    std::cout << "omcCAPI: OpenModelica home '" << openModelicaHome << "'\n"
              << "omcCAPI: options           '" << options << "'" << std::endl;
  }

  if (SetCommandLineOptions(omcData, options.c_str()) == OMC_STATUS_ERROR) {
    char *errorMsg = nullptr;
    GetError(omcData, &errorMsg);
    std::cerr << "omcCAPI: could not set options '" << options << "': "
              << (errorMsg ? errorMsg : "") << std::endl;
    return OMC_STATUS_ERROR;
  }
  return OMC_STATUS_OK;
}

void OMC_DLL FreeOMC(OMCData *omcData)
{
  GC_free(omcData->threadData);
  delete omcData;
}

int OMC_DLL GetOMCVersion(OMCData *omcData, char **result)
{
  void *result_mm = nullptr;

  MMC_TRY_TOP_SET(omcData->threadData)
  result_mm = omc_OpenModelicaScriptingAPI_getVersion(threadData, mmc_mk_scon("OpenModelica"));
  CP_TD();
  MMC_CATCH_TOP(return OMC_STATUS_ERROR)

  *result = MMC_STRINGDATA(result_mm);
  return OMC_STATUS_OK;
}

int OMC_DLL GetError(OMCData *omcData, char **result)
{
  const modelica_boolean warningsAsErrors = true;
  void *result_mm = nullptr;

  MMC_TRY_TOP_SET(omcData->threadData)
  result_mm = omc_OpenModelicaScriptingAPI_getErrorString(threadData, warningsAsErrors);
  CP_TD();
  *result = MMC_STRINGDATA(result_mm);
  MMC_CATCH_TOP(return OMC_STATUS_ERROR)

  return OMC_STATUS_OK;
}

int OMC_DLL LoadModel(OMCData *omcData, const char *className)
{
  void *priorityVersion = mmc_mk_cons(mmc_mk_scon("default"), mmc_mk_nil());
  modelica_boolean result = false;

  MMC_TRY_TOP_SET(omcData->threadData)
  result = omc_OpenModelicaScriptingAPI_loadModel(threadData, mmc_mk_scon(className), priorityVersion,
                                                  /*notify*/ false, mmc_mk_scon(""),
                                                  /*requireExactVersion*/ false);
  CP_TD();
  MMC_CATCH_TOP(return OMC_STATUS_ERROR)

  return result ? OMC_STATUS_OK : OMC_STATUS_ERROR;
}

int OMC_DLL LoadFile(OMCData *omcData, const char *fileName)
{
  modelica_boolean result = false;

  MMC_TRY_TOP_SET(omcData->threadData)
  result = omc_OpenModelicaScriptingAPI_loadFile(threadData, mmc_mk_scon(fileName), mmc_mk_scon("UTF-8"),
                                                 /*uses*/ true, /*notify*/ false,
                                                 /*requireExactVersion*/ false, /*allowWithin*/ false);
  CP_TD();
  MMC_CATCH_TOP(return OMC_STATUS_ERROR)

  return result ? OMC_STATUS_OK : OMC_STATUS_ERROR;
}

int OMC_DLL SetCommandLineOptions(OMCData *omcData, const char *expression)
{
  modelica_boolean result = false;

  MMC_TRY_TOP_SET(omcData->threadData)
  result = omc_OpenModelicaScriptingAPI_setCommandLineOptions(threadData, mmc_mk_scon(expression));
  CP_TD();
  MMC_CATCH_TOP(return OMC_STATUS_ERROR)

  return result ? OMC_STATUS_OK : OMC_STATUS_ERROR;
}

int OMC_DLL SetWorkingDirectory(OMCData *omcData, const char *directory, char **result)
{
  void *reply = nullptr;

  MMC_TRY_TOP_SET(omcData->threadData)
  reply = omc_OpenModelicaScriptingAPI_cd(threadData, mmc_mk_scon(directory));
  CP_TD();
  *result = MMC_STRINGDATA(reply);
  MMC_CATCH_TOP(return OMC_STATUS_ERROR)

  return OMC_STATUS_OK;
}

int OMC_DLL SendCommand(OMCData *omcData, const char *expression, char **result)
{
  int flagError = 0;
  void *reply = nullptr;

  MMC_TRY_TOP_SET(omcData->threadData)
  MMC_TRY_STACK()
  if (omc_Main_handleCommand(threadData, mmc_mk_scon(expression), &reply)) {
    *result = MMC_STRINGDATA(reply);
  } else {
    flagError = 1;
  }
  CP_TD();
  MMC_ELSE()
  return OMC_STATUS_ERROR;
  MMC_CATCH_STACK()
  MMC_CATCH_TOP();

  return flagError ? OMC_STATUS_ERROR : OMC_STATUS_OK;
}

} // extern "C"

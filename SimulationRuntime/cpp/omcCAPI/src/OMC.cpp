
#include "OMC.h"
#include "OMCFunctions.h"
#include <string>
#include <iostream>

/**
Complete definition for OMCData
*/
OMC_DLL typedef struct OMCData
{
   OMCData(threadData_t *threadData);
   ~OMCData();
   threadData_t *threadData;
} data;


OMC_DLL OMCData::~OMCData()
{


}

OMC_DLL OMCData::OMCData(threadData_t *data)
  : threadData(data)
{


}

#define CP_TD() (memcpy(omcData->threadData, threadData, sizeof(threadData_t)))

extern "C" {

  void OMC_DLL InitMetaOMC()
  {
    MMC_INIT();
    // initialize garbage collector
    mmc_GC_init();
  }

  int InitOMC(OMCData** omcDataPtr, const char* compiler, const char* openModelicaHome)
  {
    // alloc omcData
    OMCData* omcData = new OMCData((threadData_t*)GC_malloc_uncollectable(sizeof(threadData_t)));
    *omcDataPtr = omcData;
    memset(omcData->threadData, 0, sizeof(threadData_t));

    MMC_TRY_TOP_SET(omcData->threadData)
      void *args = mmc_mk_nil();
      omc_Main_init(threadData, mmc_mk_nil());
      CP_TD();
#ifdef WIN32
      omc_Main_setWindowsPaths(threadData, mmc_mk_scon(openModelicaHome));
      CP_TD();
#endif
      omc_Main_readSettings(threadData, mmc_mk_nil());
      CP_TD();
    MMC_CATCH_TOP(return -1)

    std::string options = "+d=execstat +simCodeTarget=Cpp +target=" + std::string(compiler);
    std::cout << "options " << options << "\n";
    if (SetCommandLineOptions(omcData, options.c_str()) == -1)
    {
      std::cout << "could not set OpenModelica options: " << options << std::endl;
      return -1;
    }
  }

  int SetCommandLineOptions(data* omcData, const char* expression)
  {
    modelica_boolean result;

    MMC_TRY_TOP_SET(omcData->threadData)
      result = omc_OpenModelicaScriptingAPI_setCommandLineOptions(threadData, mmc_mk_scon(expression));
      CP_TD();
    MMC_CATCH_TOP(return -1)

    if (result == true)
      return 1;
    else
      return -1;
  }

  int GetOMCVersion(OMCData* omcData, char** result)
  {
    void *result_mm = NULL;
    std::string name = "OpenModelica";

    MMC_TRY_TOP_SET(omcData->threadData)
      result_mm = omc_OpenModelicaScriptingAPI_getVersion(threadData, mmc_mk_scon(name.c_str()));
      CP_TD();
    MMC_CATCH_TOP(return -1)
    *result = MMC_STRINGDATA(result_mm);
    return 1;
  }

  void FreeOMC(OMCData* omcData)
  {
    GC_free(omcData->threadData);
    delete omcData;
  }

  int LoadModel(OMCData* omcData, const char* className)
  {
    threadData_t *threadData = (threadData_t *)omcData->threadData;
    std::string priorityVersion = "default";
    void *priorityVersion_lst = mmc_mk_nil();
    priorityVersion_lst = mmc_mk_cons(mmc_mk_scon(priorityVersion.c_str()), priorityVersion_lst);
    modelica_boolean notify = false;
    std::string languageStandard = "";
    modelica_boolean requireExactVersion = false;
    modelica_boolean result = false;

    MMC_TRY_TOP_SET(omcData->threadData)
      result = omc_OpenModelicaScriptingAPI_loadModel(threadData, mmc_mk_scon(className), priorityVersion_lst, notify, mmc_mk_scon(languageStandard.c_str()), requireExactVersion);
      CP_TD();
    MMC_CATCH_TOP(return -1)

    if (result == true)
      return 1;
    else
      return -1;
  }

  int LoadFile(data* omcData, const char* fileName)
  {
    modelica_boolean result;
    std::string encoding = "UTF-8";
    modelica_boolean uses = true; //Uses-annotations

    MMC_TRY_TOP_SET(omcData->threadData)
      result = omc_OpenModelicaScriptingAPI_loadFile(threadData, mmc_mk_scon(fileName), mmc_mk_scon(encoding.c_str()), uses);
      CP_TD();
    MMC_CATCH_TOP(return -1)

    if (result == true)
      return 1;
    else
      return -1;
  }

  int GetError(data* omcData, char** result)
  {
    modelica_boolean warningsAsErrors = true;
    void *result_mm = NULL;

    MMC_TRY_TOP_SET(omcData->threadData)
      result_mm = omc_OpenModelicaScriptingAPI_getErrorString(threadData, warningsAsErrors);
      CP_TD();
      (*result) = MMC_STRINGDATA(result_mm);
    MMC_CATCH_TOP(return -1)

    return 1;
  }

  int SetWorkingDirectory(data* omcData, const char* directory, char** result)
  {
    void *reply_str = NULL;
    MMC_TRY_TOP_SET(omcData->threadData)
      reply_str = omc_OpenModelicaScriptingAPI_cd(threadData, mmc_mk_scon(directory));
      CP_TD();
      (*result) = MMC_STRINGDATA(reply_str);
    MMC_CATCH_TOP(return -1)

    return 1;
  }

  int SendCommand(data* omcData, const char* expression, char** result)
  {
    int flagError = 0;
    void *reply_str = NULL;

    MMC_TRY_TOP_SET(omcData->threadData)
    MMC_TRY_STACK()
      if (omc_Main_handleCommand(threadData, mmc_mk_scon(expression), &reply_str))
      {
        (*result) = MMC_STRINGDATA(reply_str);
      }
      else
      {
        flagError = 1;
      }
      CP_TD();
    MMC_ELSE()
      return -1;
    MMC_CATCH_STACK()
    MMC_CATCH_TOP();

    if (flagError) return -1;
    return 1;
  }
}



#include "OMC.h"
#include "OMCFunctions.h"
#include <string>
#include <iostream>

OMC_DLL OMCData::~OMCData()
{


}

OMC_DLL OMCData::OMCData(void *data)
  : threadData(data)
{


}

extern "C" {

  void OMC_DLL InitMetaOMC()
  {
    MMC_INIT();
    // initialize garbage collector
    mmc_GC_init();
  }

  int InitOMC(OMCData* omcData, const char* compiler, const char* openModelicaHome, int initThreadData)
  {
    threadData_t *threadData = 0;
    // thread data is not initialized, do so
    if (initThreadData)
    {
      MMC_ALLOC_AND_INIT_THREADDATA(threadData);
      omcData->threadData = (void*)threadData;
    }
    else
    {
      threadData = (threadData_t *)omcData->threadData;
    }
    try
    {
      MMC_TRY_TOP_INTERNAL()
      void *args = mmc_mk_nil();
      omc_Main_init(threadData, mmc_mk_nil());
#ifdef WIN32
      omc_Main_setWindowsPaths(threadData, mmc_mk_scon(openModelicaHome));
#endif
      omc_Main_readSettings(threadData, mmc_mk_nil());
      MMC_CATCH_TOP()
    }
    catch (std::exception &exception)
    {
      return -1;
    }

    std::string options = "+d=execstat +simCodeTarget=Cpp +target=" + std::string(compiler);
    std::cout << "options " << options << "\n";
    if (SetCommandLineOptions(omcData, options.c_str()))
      return 1;
    else
      return -1;
  }

  int SetCommandLineOptions(data* omcData, const char* expression)
  {
    modelica_boolean result;
    threadData_t *threadData = (threadData_t *)omcData->threadData;
    try
    {
      MMC_TRY_TOP_INTERNAL()
      result = omc_OpenModelicaScriptingAPI_setCommandLineOptions(threadData, mmc_mk_scon(expression));
      MMC_CATCH_TOP()
    }
    catch (std::exception &exception)
    {
      return -1;
    }
    if (result == true)
      return 1;
    else
      return -1;
  }

  int GetOMCVersion(OMCData* omcData, char** result)
  {
    threadData_t *threadData = (threadData_t *)omcData->threadData;
    void *result_mm = NULL;
    MMC_TRY_TOP_INTERNAL()
    std::string name = "OpenModelica";
    result_mm = omc_OpenModelicaScriptingAPI_getVersion(threadData, mmc_mk_scon(name.c_str()));
    MMC_CATCH_TOP()
    *result = MMC_STRINGDATA(result_mm);

    return 1;
  }

  void FreeOMC(OMCData* omcData)
  {
    // GC_free(omcData->threadData);
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

    try
    {
      MMC_TRY_TOP_INTERNAL()
        result = omc_OpenModelicaScriptingAPI_loadModel(threadData, mmc_mk_scon(className), priorityVersion_lst, notify, mmc_mk_scon(languageStandard.c_str()), requireExactVersion);
      MMC_CATCH_TOP()
    }
    catch (std::exception &exception)
    {
      return -1;
    }
    if (result == true)
      return 1;
    else
      return -1;
  }

  int LoadFile(data* omcData, const char* fileName)
  {
    threadData_t *threadData = (threadData_t *)omcData->threadData;
    modelica_boolean result;
    std::string encoding = "UTF-8";
    modelica_boolean uses = true; //Uses-annotations

    try
    {
      MMC_TRY_TOP_INTERNAL()
        result = omc_OpenModelicaScriptingAPI_loadFile(threadData, mmc_mk_scon(fileName), mmc_mk_scon(encoding.c_str()), uses);
      MMC_CATCH_TOP()
    }
    catch (std::exception &ex)
    {
      return -1;
    }
    if (result == true)
      return 1;
    else
      return -1;
  }

  int GetError(data* omcData, char** result)
  {
    threadData_t *threadData = (threadData_t *)omcData->threadData;
    modelica_boolean warningsAsErrors = true;
    void *result_mm = NULL;

    try
    {
      MMC_TRY_TOP_INTERNAL()
        result_mm = omc_OpenModelicaScriptingAPI_getErrorString(threadData, warningsAsErrors);
      (*result) = MMC_STRINGDATA(result_mm);
      MMC_CATCH_TOP()
    }
    catch (std::exception &ex)
    {
      return -1;
    }
    return 1;
  }

  int SetWorkingDirectory(data* omcData, const char* directory, char** result)
  {
    threadData_t *threadData = (threadData_t *)omcData->threadData;
    void *reply_str = NULL;
    try
    {
      MMC_TRY_TOP_INTERNAL()
        reply_str = omc_OpenModelicaScriptingAPI_cd(threadData, mmc_mk_scon(directory));
        (*result) = MMC_STRINGDATA(reply_str);
      MMC_CATCH_TOP()
    }
    catch (std::exception &ex)
    {
      return -1;
    }

    return 1;
  }

  int SendCommand(data* omcData, const char* expression, char** result)
  {
    threadData_t *threadData = (threadData_t *)omcData->threadData;
    void *reply_str = NULL;
    MMC_TRY_TOP_INTERNAL()
    MMC_TRY_STACK()
      if (!omc_Main_handleCommand(threadData, mmc_mk_scon(expression), &reply_str))
      {
        return -1;
      }
      (*result) = MMC_STRINGDATA(reply_str);
    MMC_ELSE()
      return -1;
    MMC_CATCH_STACK()
    MMC_CATCH_TOP();
    return 1;
  }
}


#include "OMC.h"
#include "OMCFunctions.h"
#include <string>
#include <iostream>

OMCData::~OMCData()
{


}
OMCData::OMCData(void *s, threadData_t *data)
	:st(s)
	, threadData(data)
{


}
extern "C" {

   void OMC_DLL InitMetaOMC()
	{
		MMC_INIT();
	}

	int InitOMC(OMCData** omcPtr, const char* compiler, const char* openModelicaHome)
	{

		void *st = 0;
		threadData_t *threadData = (threadData_t *)calloc(1, sizeof(threadData_t));
		try
		{
			MMC_TRY_TOP_INTERNAL()
			void *args = mmc_mk_nil();
			omc_Main_init(threadData, mmc_mk_nil());
#ifdef WIN32
			omc_Main_setWindowsPaths(threadData, mmc_mk_scon(openModelicaHome));
#endif
			st = omc_Main_readSettings(threadData, mmc_mk_nil());
			MMC_CATCH_TOP()
		}
		catch (std::exception &exception)
		{
			return -1;
		}
		OMCData* omcData = new OMCData(st, threadData);
		(*omcPtr) = omcData;

		std::string options = "+simCodeTarget=Cpp +target=" + std::string(compiler);
		std::cout << "options " << options << "/n";
		if (SetCommandLineOptions(omcData, options.c_str()))
			return 1;
		else
			return -1;
	}

	int SetCommandLineOptions(data* omcPtr, const char* expression)
	{
		modelica_boolean result;
		threadData_t *threadData = omcPtr->threadData;
		try
		{
			MMC_TRY_TOP_INTERNAL()
				omcPtr->st = omc_OpenModelicaScriptingAPI_setCommandLineOptions(threadData, omcPtr->st, mmc_mk_scon(expression), &result);
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

	int GetOMCVersion(OMCData* omcPtr, char** result)
	{
		threadData_t *threadData = omcPtr->threadData;
		void *result_mm = NULL;
		MMC_TRY_TOP_INTERNAL()
			std::string name = "OpenModelica";
		omcPtr->st = omc_OpenModelicaScriptingAPI_getVersion(threadData, omcPtr->st, mmc_mk_scon(name.c_str()), &result_mm);
		MMC_CATCH_TOP()
			*result = MMC_STRINGDATA(result_mm);

		return 1;
	}
	void FreeOMC(OMCData* omcPtr)
	{
		free(omcPtr->threadData);
		delete omcPtr;
	}

	int LoadModel(OMCData* omcPtr, const char* className)
	{
		threadData_t *threadData = omcPtr->threadData;
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
				omcPtr->st = omc_OpenModelicaScriptingAPI_loadModel(threadData, omcPtr->st, mmc_mk_scon(className), priorityVersion_lst, notify, mmc_mk_scon(languageStandard.c_str()), requireExactVersion, &result);
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

	int LoadFile(data* omcPtr, const char* fileName)
	{
		threadData_t *threadData = omcPtr->threadData;
		modelica_boolean result;
		std::string encoding = "UTF-8";
		modelica_boolean uses = true; //Uses-annotations

		try
		{
			MMC_TRY_TOP_INTERNAL()
				omcPtr->st = omc_OpenModelicaScriptingAPI_loadFile(threadData, omcPtr->st, mmc_mk_scon(fileName), mmc_mk_scon(encoding.c_str()), uses, &result);
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

	int GetError(data* omcPtr, char** result)
	{
		threadData_t *threadData = omcPtr->threadData;
		modelica_boolean warningsAsErrors = true;
		void *result_mm = NULL;

		try
		{
			MMC_TRY_TOP_INTERNAL()
				omcPtr->st = omc_OpenModelicaScriptingAPI_getErrorString(threadData, omcPtr->st, warningsAsErrors, &result_mm);
			(*result) = MMC_STRINGDATA(result_mm);
			MMC_CATCH_TOP()
		}
		catch (std::exception &ex)
		{
			return -1;
		}
		return 1;
	}

	int SetWorkingDirectory(data* omcPtr, const char* directory, char** result)
	{
		threadData_t *threadData = omcPtr->threadData;
		void *reply_str = NULL;
		try
		{
			MMC_TRY_TOP_INTERNAL()
				omcPtr->st = omc_OpenModelicaScriptingAPI_cd(threadData, omcPtr->st, mmc_mk_scon(directory), &reply_str);
			(*result) = MMC_STRINGDATA(reply_str);
			MMC_CATCH_TOP()
		}
		catch (std::exception &ex)
		{
			return -1;
		}

		return 1;
	}

	int SendCommand(data* omcPtr, const char* expression, char** result)
	{
		threadData_t *threadData = omcPtr->threadData;
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

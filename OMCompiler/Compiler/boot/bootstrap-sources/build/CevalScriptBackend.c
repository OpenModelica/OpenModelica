#include "omc_simulation_settings.h"
#include "CevalScriptBackend.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,2,3) {&Values_Value_INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "CevalScriptBackend.getSimulationOption"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,38,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "CevalScriptBackend.buildSimulationOptionsFromModelExperimentAnnotation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,70,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "CevalScriptBackend"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,18,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "CevalScriptBackend.getSimulationResultType"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,42,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "static"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,6,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,1) {_OMC_LIT5,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "CevalScriptBackend.callBuildModelFMU"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,36,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "CevalScriptBackend.translateModel"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,33,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "CevalScriptBackend.runFrontEnd"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,30,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#include "util/modelica.h"
#include "CevalScriptBackend_includes.h"
DLLDirection
modelica_metatype omc_CevalScriptBackend_cevalInteractiveFunctions3(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _inFunctionName, modelica_metatype _inVals, modelica_metatype _msg, modelica_metatype *out_outValue)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outValue = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = _inCache;
_outValue = _OMC_LIT0;
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outCache;
}
DLLDirection
modelica_metatype omc_CevalScriptBackend_getSimulationOption(threadData_t *threadData, modelica_metatype _inSimOpt, modelica_string _optionName)
{
modelica_metatype _outOptionValue = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"CevalScriptBackend.mo",114,3,114,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
return _outOptionValue;
}
DLLDirection
modelica_metatype omc_CevalScriptBackend_buildSimulationOptionsFromModelExperimentAnnotation(threadData_t *threadData, modelica_metatype _inModelPath, modelica_string _inFileNamePrefix, modelica_metatype _defaultOption)
{
modelica_metatype _outSimOpt = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"CevalScriptBackend.mo",106,3,106,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT2));
}
}
}
_return: OMC_LABEL_UNUSED
return _outSimOpt;
}
DLLDirection
modelica_metatype omc_CevalScriptBackend_getDrModelicaSimulationResultType(threadData_t *threadData)
{
modelica_metatype _t = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"CevalScriptBackend.mo",95,3,95,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT3));
}
}
}
_return: OMC_LABEL_UNUSED
return _t;
}
DLLDirection
modelica_metatype omc_CevalScriptBackend_getSimulationResultType(threadData_t *threadData)
{
modelica_metatype _t = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"CevalScriptBackend.mo",95,3,95,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT4));
}
}
}
_return: OMC_LABEL_UNUSED
return _t;
}
DLLDirection
modelica_metatype omc_CevalScriptBackend_callBuildModelFMU(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_string _FMUVersion, modelica_string _inFMUType, modelica_string _inFileNamePrefix, modelica_boolean _addDummy, modelica_metatype _platforms, modelica_metatype _inSimSettings, modelica_metatype *out_outValue)
{
modelica_metatype _cache = NULL;
modelica_metatype _outValue = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"CevalScriptBackend.mo",89,3,89,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT7));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _cache;
}
modelica_metatype boxptr_CevalScriptBackend_callBuildModelFMU(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_metatype _FMUVersion, modelica_metatype _inFMUType, modelica_metatype _inFileNamePrefix, modelica_metatype _addDummy, modelica_metatype _platforms, modelica_metatype _inSimSettings, modelica_metatype *out_outValue)
{
modelica_integer tmp1;
modelica_metatype _cache = NULL;
tmp1 = mmc_unbox_integer(_addDummy);
_cache = omc_CevalScriptBackend_callBuildModelFMU(threadData, _inCache, _inEnv, _className, _FMUVersion, _inFMUType, _inFileNamePrefix, tmp1, _platforms, _inSimSettings, out_outValue);
return _cache;
}
DLLDirection
modelica_boolean omc_CevalScriptBackend_translateModel(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_string _inFileNamePrefix, modelica_boolean _runBackend, modelica_boolean _runSilent, modelica_metatype _inSimSettingsOpt, modelica_metatype *out_outCache, modelica_metatype *out_outLibs, modelica_string *out_outFileDir, modelica_metatype *out_resultValues)
{
modelica_boolean _success;
modelica_metatype _outCache = NULL;
modelica_metatype _outLibs = NULL;
modelica_string _outFileDir = NULL;
modelica_metatype _resultValues = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"CevalScriptBackend.mo",73,3,73,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT8));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
if (out_outLibs) { *out_outLibs = _outLibs; }
if (out_outFileDir) { *out_outFileDir = _outFileDir; }
if (out_resultValues) { *out_resultValues = _resultValues; }
return _success;
}
modelica_metatype boxptr_CevalScriptBackend_translateModel(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_metatype _inFileNamePrefix, modelica_metatype _runBackend, modelica_metatype _runSilent, modelica_metatype _inSimSettingsOpt, modelica_metatype *out_outCache, modelica_metatype *out_outLibs, modelica_metatype *out_outFileDir, modelica_metatype *out_resultValues)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_boolean _success;
modelica_metatype out_success;
tmp1 = mmc_unbox_integer(_runBackend);
tmp2 = mmc_unbox_integer(_runSilent);
_success = omc_CevalScriptBackend_translateModel(threadData, _inCache, _inEnv, _className, _inFileNamePrefix, tmp1, tmp2, _inSimSettingsOpt, out_outCache, out_outLibs, out_outFileDir, out_resultValues);
out_success = mmc_mk_icon(_success);
return out_success;
}
DLLDirection
modelica_metatype omc_CevalScriptBackend_runFrontEnd(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_boolean _relaxedFrontEnd, modelica_boolean _dumpFlat, modelica_metatype *out_env, modelica_metatype *out_dae, modelica_string *out_flatString)
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _dae = NULL;
modelica_string _flatString = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"CevalScriptBackend.mo",56,3,56,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT9));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_env) { *out_env = _env; }
if (out_dae) { *out_dae = _dae; }
if (out_flatString) { *out_flatString = _flatString; }
return _cache;
}
modelica_metatype boxptr_CevalScriptBackend_runFrontEnd(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_metatype _relaxedFrontEnd, modelica_metatype _dumpFlat, modelica_metatype *out_env, modelica_metatype *out_dae, modelica_metatype *out_flatString)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _cache = NULL;
tmp1 = mmc_unbox_integer(_relaxedFrontEnd);
tmp2 = mmc_unbox_integer(_dumpFlat);
_cache = omc_CevalScriptBackend_runFrontEnd(threadData, _inCache, _inEnv, _className, tmp1, tmp2, out_env, out_dae, out_flatString);
return _cache;
}

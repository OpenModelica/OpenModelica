#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/CevalScriptBackend.c"
#endif
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
#define _OMC_LIT5_data "CevalScriptBackend.runFrontEnd"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,30,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#include "util/modelica.h"
#include "CevalScriptBackend_includes.h"
DLLExport
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
DLLExport
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
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/CevalScriptBackend.mo",45,3,45,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
return _outOptionValue;
}
DLLExport
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
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/CevalScriptBackend.mo",37,3,37,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT2));
}
}
}
_return: OMC_LABEL_UNUSED
return _outSimOpt;
}
DLLExport
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
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/CevalScriptBackend.mo",26,3,26,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT3));
}
}
}
_return: OMC_LABEL_UNUSED
return _t;
}
DLLExport
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
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/CevalScriptBackend.mo",26,3,26,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT4));
}
}
}
_return: OMC_LABEL_UNUSED
return _t;
}
DLLExport
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
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/CevalScriptBackend.mo",20,3,20,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT5));
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

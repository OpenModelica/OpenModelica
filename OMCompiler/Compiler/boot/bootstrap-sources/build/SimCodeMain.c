#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/SimCodeMain.c"
#endif
#include "omc_simulation_settings.h"
#include "SimCodeMain.h"
#define _OMC_LIT0_data "SimCodeMain.translateModel"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,26,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "SimCodeMain.generateModelCode"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,29,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "SimCodeMain.createSimulationSettings"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,36,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#include "util/modelica.h"
#include "SimCodeMain_includes.h"
DLLExport
modelica_metatype omc_SimCodeMain_translateModel(threadData_t *threadData, modelica_metatype _x, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_metatype _inInteractiveSymbolTable, modelica_string _inFileNamePrefix, modelica_boolean _addDummy, modelica_metatype _inSimSettingsOpt, modelica_metatype _args, modelica_metatype *out_outInteractiveSymbolTable, modelica_metatype *out_outBackendDAE, modelica_metatype *out_outStringLst, modelica_string *out_outFileDir, modelica_metatype *out_resultValues)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outInteractiveSymbolTable = NULL;
modelica_metatype _outBackendDAE = NULL;
modelica_metatype _outStringLst = NULL;
modelica_string _outFileDir = NULL;
modelica_metatype _resultValues = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeMain.mo",58,3,58,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_outInteractiveSymbolTable) { *out_outInteractiveSymbolTable = _outInteractiveSymbolTable; }
if (out_outBackendDAE) { *out_outBackendDAE = _outBackendDAE; }
if (out_outStringLst) { *out_outStringLst = _outStringLst; }
if (out_outFileDir) { *out_outFileDir = _outFileDir; }
if (out_resultValues) { *out_resultValues = _resultValues; }
return _outCache;
}
modelica_metatype boxptr_SimCodeMain_translateModel(threadData_t *threadData, modelica_metatype _x, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_metatype _inInteractiveSymbolTable, modelica_metatype _inFileNamePrefix, modelica_metatype _addDummy, modelica_metatype _inSimSettingsOpt, modelica_metatype _args, modelica_metatype *out_outInteractiveSymbolTable, modelica_metatype *out_outBackendDAE, modelica_metatype *out_outStringLst, modelica_metatype *out_outFileDir, modelica_metatype *out_resultValues)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_addDummy);
_outCache = omc_SimCodeMain_translateModel(threadData, _x, _inCache, _inEnv, _className, _inInteractiveSymbolTable, _inFileNamePrefix, tmp1, _inSimSettingsOpt, _args, out_outInteractiveSymbolTable, out_outBackendDAE, out_outStringLst, out_outFileDir, out_resultValues);
return _outCache;
}
DLLExport
modelica_metatype omc_SimCodeMain_generateModelCode(threadData_t *threadData, modelica_metatype _inBackendDAE, modelica_metatype _inInitDAE, modelica_metatype _inInitDAE_lambda0, modelica_metatype _inInlineDAE, modelica_metatype _inRemovedInitialEquationLst, modelica_metatype _p, modelica_metatype _className, modelica_string _filenamePrefix, modelica_metatype _simSettingsOpt, modelica_metatype _args, modelica_string *out_fileDir, modelica_real *out_timeSimCode, modelica_real *out_timeTemplates)
{
modelica_metatype _libs = NULL;
modelica_string _fileDir = NULL;
modelica_real _timeSimCode;
modelica_real _timeTemplates;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeMain.mo",38,3,38,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_fileDir) { *out_fileDir = _fileDir; }
if (out_timeSimCode) { *out_timeSimCode = _timeSimCode; }
if (out_timeTemplates) { *out_timeTemplates = _timeTemplates; }
return _libs;
}
modelica_metatype boxptr_SimCodeMain_generateModelCode(threadData_t *threadData, modelica_metatype _inBackendDAE, modelica_metatype _inInitDAE, modelica_metatype _inInitDAE_lambda0, modelica_metatype _inInlineDAE, modelica_metatype _inRemovedInitialEquationLst, modelica_metatype _p, modelica_metatype _className, modelica_metatype _filenamePrefix, modelica_metatype _simSettingsOpt, modelica_metatype _args, modelica_metatype *out_fileDir, modelica_metatype *out_timeSimCode, modelica_metatype *out_timeTemplates)
{
modelica_real _timeSimCode;
modelica_real _timeTemplates;
modelica_metatype _libs = NULL;
_libs = omc_SimCodeMain_generateModelCode(threadData, _inBackendDAE, _inInitDAE, _inInitDAE_lambda0, _inInlineDAE, _inRemovedInitialEquationLst, _p, _className, _filenamePrefix, _simSettingsOpt, _args, out_fileDir, &_timeSimCode, &_timeTemplates);
if (out_timeSimCode) { *out_timeSimCode = mmc_mk_rcon(_timeSimCode); }
if (out_timeTemplates) { *out_timeTemplates = mmc_mk_rcon(_timeTemplates); }
return _libs;
}
DLLExport
modelica_integer omc_SimCodeMain_createSimulationSettings(threadData_t *threadData, modelica_real _startTime, modelica_real _stopTime, modelica_integer _inumberOfIntervals, modelica_real _tolerance, modelica_string _method, modelica_string _options, modelica_string _outputFormat, modelica_string _variableFilter, modelica_string _cflags)
{
modelica_integer _simSettings;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeMain.mo",19,3,19,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT2));
}
}
}
_return: OMC_LABEL_UNUSED
return _simSettings;
}
modelica_metatype boxptr_SimCodeMain_createSimulationSettings(threadData_t *threadData, modelica_metatype _startTime, modelica_metatype _stopTime, modelica_metatype _inumberOfIntervals, modelica_metatype _tolerance, modelica_metatype _method, modelica_metatype _options, modelica_metatype _outputFormat, modelica_metatype _variableFilter, modelica_metatype _cflags)
{
modelica_real tmp1;
modelica_real tmp2;
modelica_integer tmp3;
modelica_real tmp4;
modelica_integer _simSettings;
modelica_metatype out_simSettings;
tmp1 = mmc_unbox_real(_startTime);
tmp2 = mmc_unbox_real(_stopTime);
tmp3 = mmc_unbox_integer(_inumberOfIntervals);
tmp4 = mmc_unbox_real(_tolerance);
_simSettings = omc_SimCodeMain_createSimulationSettings(threadData, tmp1, tmp2, tmp3, tmp4, _method, _options, _outputFormat, _variableFilter, _cflags);
out_simSettings = mmc_mk_icon(_simSettings);
return out_simSettings;
}

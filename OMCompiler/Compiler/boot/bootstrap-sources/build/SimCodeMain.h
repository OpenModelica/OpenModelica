#ifndef SimCodeMain__H
#define SimCodeMain__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_SimCodeMain_translateModel(threadData_t *threadData, modelica_metatype _x, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_metatype _inInteractiveSymbolTable, modelica_string _inFileNamePrefix, modelica_boolean _addDummy, modelica_metatype _inSimSettingsOpt, modelica_metatype _args, modelica_metatype *out_outInteractiveSymbolTable, modelica_metatype *out_outBackendDAE, modelica_metatype *out_outStringLst, modelica_string *out_outFileDir, modelica_metatype *out_resultValues);
DLLExport
modelica_metatype boxptr_SimCodeMain_translateModel(threadData_t *threadData, modelica_metatype _x, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _className, modelica_metatype _inInteractiveSymbolTable, modelica_metatype _inFileNamePrefix, modelica_metatype _addDummy, modelica_metatype _inSimSettingsOpt, modelica_metatype _args, modelica_metatype *out_outInteractiveSymbolTable, modelica_metatype *out_outBackendDAE, modelica_metatype *out_outStringLst, modelica_metatype *out_outFileDir, modelica_metatype *out_resultValues);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeMain_translateModel,2,0) {(void*) boxptr_SimCodeMain_translateModel,0}};
#define boxvar_SimCodeMain_translateModel MMC_REFSTRUCTLIT(boxvar_lit_SimCodeMain_translateModel)
DLLExport
modelica_metatype omc_SimCodeMain_generateModelCode(threadData_t *threadData, modelica_metatype _inBackendDAE, modelica_metatype _inInitDAE, modelica_metatype _inInitDAE_lambda0, modelica_metatype _inInlineDAE, modelica_metatype _inRemovedInitialEquationLst, modelica_metatype _p, modelica_metatype _className, modelica_string _filenamePrefix, modelica_metatype _simSettingsOpt, modelica_metatype _args, modelica_string *out_fileDir, modelica_real *out_timeSimCode, modelica_real *out_timeTemplates);
DLLExport
modelica_metatype boxptr_SimCodeMain_generateModelCode(threadData_t *threadData, modelica_metatype _inBackendDAE, modelica_metatype _inInitDAE, modelica_metatype _inInitDAE_lambda0, modelica_metatype _inInlineDAE, modelica_metatype _inRemovedInitialEquationLst, modelica_metatype _p, modelica_metatype _className, modelica_metatype _filenamePrefix, modelica_metatype _simSettingsOpt, modelica_metatype _args, modelica_metatype *out_fileDir, modelica_metatype *out_timeSimCode, modelica_metatype *out_timeTemplates);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeMain_generateModelCode,2,0) {(void*) boxptr_SimCodeMain_generateModelCode,0}};
#define boxvar_SimCodeMain_generateModelCode MMC_REFSTRUCTLIT(boxvar_lit_SimCodeMain_generateModelCode)
DLLExport
modelica_integer omc_SimCodeMain_createSimulationSettings(threadData_t *threadData, modelica_real _startTime, modelica_real _stopTime, modelica_integer _inumberOfIntervals, modelica_real _tolerance, modelica_string _method, modelica_string _options, modelica_string _outputFormat, modelica_string _variableFilter, modelica_string _cflags);
DLLExport
modelica_metatype boxptr_SimCodeMain_createSimulationSettings(threadData_t *threadData, modelica_metatype _startTime, modelica_metatype _stopTime, modelica_metatype _inumberOfIntervals, modelica_metatype _tolerance, modelica_metatype _method, modelica_metatype _options, modelica_metatype _outputFormat, modelica_metatype _variableFilter, modelica_metatype _cflags);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeMain_createSimulationSettings,2,0) {(void*) boxptr_SimCodeMain_createSimulationSettings,0}};
#define boxvar_SimCodeMain_createSimulationSettings MMC_REFSTRUCTLIT(boxvar_lit_SimCodeMain_createSimulationSettings)
#ifdef __cplusplus
}
#endif
#endif

#ifndef Main__H
#define Main__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Absyn_FunctionArgs_FUNCTIONARGS__desc;
extern struct record_description BackendDAE_ExtraInfo_EXTRA__INFO__desc;
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_SCRIPTING__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Flags_FlagData_INT__FLAG__desc;
extern struct record_description Flags_FlagData_STRING__FLAG__desc;
extern struct record_description Flags_FlagVisibility_EXTERNAL__desc;
extern struct record_description Flags_ValidOptions_STRING__DESC__OPTION__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
#define boxptr_Main_main2 omc_Main_main2
DLLExport
void omc_Main_main(threadData_t *threadData, modelica_metatype _args);
#define boxptr_Main_main omc_Main_main
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_main,2,0) {(void*) boxptr_Main_main,0}};
#define boxvar_Main_main MMC_REFSTRUCTLIT(boxvar_lit_Main_main)
DLLExport
modelica_metatype omc_Main_init(threadData_t *threadData, modelica_metatype _args);
#define boxptr_Main_init omc_Main_init
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_init,2,0) {(void*) boxptr_Main_init,0}};
#define boxvar_Main_init MMC_REFSTRUCTLIT(boxvar_lit_Main_init)
#define boxptr_Main_setDefaultCC omc_Main_setDefaultCC
DLLExport
void omc_Main_setWindowsPaths(threadData_t *threadData, modelica_string _inOMHome);
#define boxptr_Main_setWindowsPaths omc_Main_setWindowsPaths
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_setWindowsPaths,2,0) {(void*) boxptr_Main_setWindowsPaths,0}};
#define boxvar_Main_setWindowsPaths MMC_REFSTRUCTLIT(boxvar_lit_Main_setWindowsPaths)
#define boxptr_Main_readSettingsFile omc_Main_readSettingsFile
DLLExport
void omc_Main_readSettings(threadData_t *threadData, modelica_metatype _inArguments);
#define boxptr_Main_readSettings omc_Main_readSettings
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_readSettings,2,0) {(void*) boxptr_Main_readSettings,0}};
#define boxvar_Main_readSettings MMC_REFSTRUCTLIT(boxvar_lit_Main_readSettings)
#define boxptr_Main_serverLoopCorba omc_Main_serverLoopCorba
#define boxptr_Main_interactivemodeZMQ omc_Main_interactivemodeZMQ
#define boxptr_Main_interactivemodeCorba omc_Main_interactivemodeCorba
#define boxptr_Main_interactivemode omc_Main_interactivemode
#define boxptr_Main_simcodegen omc_Main_simcodegen
#define boxptr_Main_optimizeDae omc_Main_optimizeDae
#define boxptr_Main_instantiate omc_Main_instantiate
#define boxptr_Main_translateFile omc_Main_translateFile
#define boxptr_Main_loadLib omc_Main_loadLib
#define boxptr_Main_showErrors omc_Main_showErrors
#define boxptr_Main_isCodegenTemplateFile omc_Main_isCodegenTemplateFile
#define boxptr_Main_isModelicaScriptFile omc_Main_isModelicaScriptFile
#define boxptr_Main_isFlatModelicaFile omc_Main_isFlatModelicaFile
#define boxptr_Main_isEmptyOrFirstIsModelicaFile omc_Main_isEmptyOrFirstIsModelicaFile
#define boxptr_Main_makeClassDefResult omc_Main_makeClassDefResult
#define boxptr_Main_handleCommand2 omc_Main_handleCommand2
DLLExport
modelica_boolean omc_Main_handleCommand(threadData_t *threadData, modelica_string _inCommand, modelica_string *out_outResult);
DLLExport
modelica_metatype boxptr_Main_handleCommand(threadData_t *threadData, modelica_metatype _inCommand, modelica_metatype *out_outResult);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Main_handleCommand,2,0) {(void*) boxptr_Main_handleCommand,0}};
#define boxvar_Main_handleCommand MMC_REFSTRUCTLIT(boxvar_lit_Main_handleCommand)
#define boxptr_Main_parseCommand omc_Main_parseCommand
#define boxptr_Main_makeDebugResult omc_Main_makeDebugResult
#ifdef __cplusplus
}
#endif
#endif

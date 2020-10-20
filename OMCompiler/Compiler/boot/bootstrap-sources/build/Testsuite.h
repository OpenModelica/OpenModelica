#ifndef Testsuite__H
#define Testsuite__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_FlagData_STRING__FLAG__desc;
extern struct record_description Flags_FlagVisibility_INTERNAL__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
DLLExport
modelica_string omc_Testsuite_friendlyPath(threadData_t *threadData, modelica_string _inPath);
#define boxptr_Testsuite_friendlyPath omc_Testsuite_friendlyPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Testsuite_friendlyPath,2,0) {(void*) boxptr_Testsuite_friendlyPath,0}};
#define boxvar_Testsuite_friendlyPath MMC_REFSTRUCTLIT(boxvar_lit_Testsuite_friendlyPath)
DLLExport
modelica_string omc_Testsuite_friendly(threadData_t *threadData, modelica_string _name);
#define boxptr_Testsuite_friendly omc_Testsuite_friendly
static const MMC_DEFSTRUCTLIT(boxvar_lit_Testsuite_friendly,2,0) {(void*) boxptr_Testsuite_friendly,0}};
#define boxvar_Testsuite_friendly MMC_REFSTRUCTLIT(boxvar_lit_Testsuite_friendly)
DLLExport
modelica_string omc_Testsuite_getTempFilesFile(threadData_t *threadData);
#define boxptr_Testsuite_getTempFilesFile omc_Testsuite_getTempFilesFile
static const MMC_DEFSTRUCTLIT(boxvar_lit_Testsuite_getTempFilesFile,2,0) {(void*) boxptr_Testsuite_getTempFilesFile,0}};
#define boxvar_Testsuite_getTempFilesFile MMC_REFSTRUCTLIT(boxvar_lit_Testsuite_getTempFilesFile)
DLLExport
modelica_boolean omc_Testsuite_isRunning(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Testsuite_isRunning(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Testsuite_isRunning,2,0) {(void*) boxptr_Testsuite_isRunning,0}};
#define boxvar_Testsuite_isRunning MMC_REFSTRUCTLIT(boxvar_lit_Testsuite_isRunning)
#ifdef __cplusplus
}
#endif
#endif

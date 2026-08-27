#ifndef Flags__H
#define Flags__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_integer omc_Flags_getConfigEnum(threadData_t *threadData, modelica_metatype _inFlag);
DLLExport
modelica_metatype boxptr_Flags_getConfigEnum(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigEnum,2,0) {(void*) boxptr_Flags_getConfigEnum,0}};
#define boxvar_Flags_getConfigEnum MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigEnum)
DLLExport
modelica_metatype omc_Flags_getConfigStringList(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigStringList omc_Flags_getConfigStringList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigStringList,2,0) {(void*) boxptr_Flags_getConfigStringList,0}};
#define boxvar_Flags_getConfigStringList MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigStringList)
DLLExport
modelica_string omc_Flags_getConfigString(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigString omc_Flags_getConfigString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigString,2,0) {(void*) boxptr_Flags_getConfigString,0}};
#define boxvar_Flags_getConfigString MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigString)
DLLExport
modelica_real omc_Flags_getConfigReal(threadData_t *threadData, modelica_metatype _inFlag);
DLLExport
modelica_metatype boxptr_Flags_getConfigReal(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigReal,2,0) {(void*) boxptr_Flags_getConfigReal,0}};
#define boxvar_Flags_getConfigReal MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigReal)
DLLExport
modelica_metatype omc_Flags_getConfigIntList(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigIntList omc_Flags_getConfigIntList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigIntList,2,0) {(void*) boxptr_Flags_getConfigIntList,0}};
#define boxvar_Flags_getConfigIntList MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigIntList)
DLLExport
modelica_integer omc_Flags_getConfigInt(threadData_t *threadData, modelica_metatype _inFlag);
DLLExport
modelica_metatype boxptr_Flags_getConfigInt(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigInt,2,0) {(void*) boxptr_Flags_getConfigInt,0}};
#define boxvar_Flags_getConfigInt MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigInt)
DLLExport
modelica_boolean omc_Flags_getConfigBool(threadData_t *threadData, modelica_metatype _inFlag);
DLLExport
modelica_metatype boxptr_Flags_getConfigBool(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigBool,2,0) {(void*) boxptr_Flags_getConfigBool,0}};
#define boxvar_Flags_getConfigBool MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigBool)
DLLExport
modelica_metatype omc_Flags_getConfigValue(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigValue omc_Flags_getConfigValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigValue,2,0) {(void*) boxptr_Flags_getConfigValue,0}};
#define boxvar_Flags_getConfigValue MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigValue)
DLLExport
modelica_boolean omc_Flags_isSet(threadData_t *threadData, modelica_metatype _inFlag);
DLLExport
modelica_metatype boxptr_Flags_isSet(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_isSet,2,0) {(void*) boxptr_Flags_isSet,0}};
#define boxvar_Flags_isSet MMC_REFSTRUCTLIT(boxvar_lit_Flags_isSet)
DLLExport
modelica_metatype omc_Flags_getFlags(threadData_t *threadData, modelica_boolean _initialize);
DLLExport
modelica_metatype boxptr_Flags_getFlags(threadData_t *threadData, modelica_metatype _initialize);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getFlags,2,0) {(void*) boxptr_Flags_getFlags,0}};
#define boxvar_Flags_getFlags MMC_REFSTRUCTLIT(boxvar_lit_Flags_getFlags)
#ifdef __cplusplus
}
#endif
#endif

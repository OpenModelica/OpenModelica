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
DLLDirection
modelica_integer omc_Flags_getConfigEnum(threadData_t *threadData, modelica_metatype _inFlag);
DLLDirection
modelica_metatype boxptr_Flags_getConfigEnum(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigEnum,2,0) {(void*) boxptr_Flags_getConfigEnum,0}};
#define boxvar_Flags_getConfigEnum MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigEnum)
DLLDirection
modelica_metatype omc_Flags_getConfigStringList(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigStringList omc_Flags_getConfigStringList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigStringList,2,0) {(void*) boxptr_Flags_getConfigStringList,0}};
#define boxvar_Flags_getConfigStringList MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigStringList)
DLLDirection
modelica_string omc_Flags_getConfigString(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigString omc_Flags_getConfigString
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigString,2,0) {(void*) boxptr_Flags_getConfigString,0}};
#define boxvar_Flags_getConfigString MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigString)
DLLDirection
modelica_real omc_Flags_getConfigReal(threadData_t *threadData, modelica_metatype _inFlag);
DLLDirection
modelica_metatype boxptr_Flags_getConfigReal(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigReal,2,0) {(void*) boxptr_Flags_getConfigReal,0}};
#define boxvar_Flags_getConfigReal MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigReal)
DLLDirection
modelica_metatype omc_Flags_getConfigIntList(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigIntList omc_Flags_getConfigIntList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigIntList,2,0) {(void*) boxptr_Flags_getConfigIntList,0}};
#define boxvar_Flags_getConfigIntList MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigIntList)
DLLDirection
modelica_integer omc_Flags_getConfigInt(threadData_t *threadData, modelica_metatype _inFlag);
DLLDirection
modelica_metatype boxptr_Flags_getConfigInt(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigInt,2,0) {(void*) boxptr_Flags_getConfigInt,0}};
#define boxvar_Flags_getConfigInt MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigInt)
DLLDirection
modelica_boolean omc_Flags_getConfigBool(threadData_t *threadData, modelica_metatype _inFlag);
DLLDirection
modelica_metatype boxptr_Flags_getConfigBool(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigBool,2,0) {(void*) boxptr_Flags_getConfigBool,0}};
#define boxvar_Flags_getConfigBool MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigBool)
DLLDirection
modelica_metatype omc_Flags_getConfigValue(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigValue omc_Flags_getConfigValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigValue,2,0) {(void*) boxptr_Flags_getConfigValue,0}};
#define boxvar_Flags_getConfigValue MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigValue)
DLLDirection
modelica_string omc_Flags_getConfigName(threadData_t *threadData, modelica_metatype _inFlag);
#define boxptr_Flags_getConfigName omc_Flags_getConfigName
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getConfigName,2,0) {(void*) boxptr_Flags_getConfigName,0}};
#define boxvar_Flags_getConfigName MMC_REFSTRUCTLIT(boxvar_lit_Flags_getConfigName)
DLLDirection
modelica_boolean omc_Flags_isConfigFlagSet(threadData_t *threadData, modelica_metatype _inFlag, modelica_string _hasMember);
DLLDirection
modelica_metatype boxptr_Flags_isConfigFlagSet(threadData_t *threadData, modelica_metatype _inFlag, modelica_metatype _hasMember);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_isConfigFlagSet,2,0) {(void*) boxptr_Flags_isConfigFlagSet,0}};
#define boxvar_Flags_isConfigFlagSet MMC_REFSTRUCTLIT(boxvar_lit_Flags_isConfigFlagSet)
DLLDirection
modelica_boolean omc_Flags_isSet(threadData_t *threadData, modelica_metatype _inFlag);
DLLDirection
modelica_metatype boxptr_Flags_isSet(threadData_t *threadData, modelica_metatype _inFlag);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_isSet,2,0) {(void*) boxptr_Flags_isSet,0}};
#define boxvar_Flags_isSet MMC_REFSTRUCTLIT(boxvar_lit_Flags_isSet)
DLLDirection
modelica_metatype omc_Flags_getFlags(threadData_t *threadData, modelica_boolean _initialize);
DLLDirection
modelica_metatype boxptr_Flags_getFlags(threadData_t *threadData, modelica_metatype _initialize);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Flags_getFlags,2,0) {(void*) boxptr_Flags_getFlags,0}};
#define boxvar_Flags_getFlags MMC_REFSTRUCTLIT(boxvar_lit_Flags_getFlags)
#ifdef __cplusplus
}
#endif
#endif

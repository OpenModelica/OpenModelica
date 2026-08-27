#ifndef InstHashTable__H
#define InstHashTable__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Flags_FlagData_INT__FLAG__desc;
extern struct record_description Flags_FlagVisibility_EXTERNAL__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
#define boxptr_InstHashTable_emptyInstHashTable omc_InstHashTable_emptyInstHashTable
#define boxptr_InstHashTable_opaqVal omc_InstHashTable_opaqVal
DLLExport
void omc_InstHashTable_addToInstCache(threadData_t *threadData, modelica_metatype _fullEnvPathPlusClass, modelica_metatype _fullInstOpt, modelica_metatype _partialInstOpt);
#define boxptr_InstHashTable_addToInstCache omc_InstHashTable_addToInstCache
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstHashTable_addToInstCache,2,0) {(void*) boxptr_InstHashTable_addToInstCache,0}};
#define boxvar_InstHashTable_addToInstCache MMC_REFSTRUCTLIT(boxvar_lit_InstHashTable_addToInstCache)
DLLExport
modelica_metatype omc_InstHashTable_get(threadData_t *threadData, modelica_metatype _k);
#define boxptr_InstHashTable_get omc_InstHashTable_get
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstHashTable_get,2,0) {(void*) boxptr_InstHashTable_get,0}};
#define boxvar_InstHashTable_get MMC_REFSTRUCTLIT(boxvar_lit_InstHashTable_get)
DLLExport
void omc_InstHashTable_release(threadData_t *threadData);
#define boxptr_InstHashTable_release omc_InstHashTable_release
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstHashTable_release,2,0) {(void*) boxptr_InstHashTable_release,0}};
#define boxvar_InstHashTable_release MMC_REFSTRUCTLIT(boxvar_lit_InstHashTable_release)
DLLExport
void omc_InstHashTable_init(threadData_t *threadData);
#define boxptr_InstHashTable_init omc_InstHashTable_init
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstHashTable_init,2,0) {(void*) boxptr_InstHashTable_init,0}};
#define boxvar_InstHashTable_init MMC_REFSTRUCTLIT(boxvar_lit_InstHashTable_init)
#ifdef __cplusplus
}
#endif
#endif

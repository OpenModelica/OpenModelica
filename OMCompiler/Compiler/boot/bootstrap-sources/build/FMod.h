#ifndef FMod__H
#define FMod__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description SCode_Mod_MOD__desc;
extern struct record_description SCode_SubMod_NAMEMOD__desc;
#define boxptr_FMod_printModScope omc_FMod_printModScope
#define boxptr_FMod_mergeSubModsInSameScope omc_FMod_mergeSubModsInSameScope
#define boxptr_FMod_compactSubMod omc_FMod_compactSubMod
DLLExport
modelica_metatype omc_FMod_compactSubMods(threadData_t *threadData, modelica_metatype _inSubMods, modelica_metatype _inModScope);
#define boxptr_FMod_compactSubMods omc_FMod_compactSubMods
static const MMC_DEFSTRUCTLIT(boxvar_lit_FMod_compactSubMods,2,0) {(void*) boxptr_FMod_compactSubMods,0}};
#define boxvar_FMod_compactSubMods MMC_REFSTRUCTLIT(boxvar_lit_FMod_compactSubMods)
DLLExport
modelica_metatype omc_FMod_apply(threadData_t *threadData, modelica_metatype _inTargetRef, modelica_metatype _inModRef, modelica_metatype _inGraph, modelica_metatype *out_outNodeRef);
#define boxptr_FMod_apply omc_FMod_apply
static const MMC_DEFSTRUCTLIT(boxvar_lit_FMod_apply,2,0) {(void*) boxptr_FMod_apply,0}};
#define boxvar_FMod_apply MMC_REFSTRUCTLIT(boxvar_lit_FMod_apply)
DLLExport
modelica_metatype omc_FMod_merge(threadData_t *threadData, modelica_metatype _inParentRef, modelica_metatype _inOuterModRef, modelica_metatype _inInnerModRef, modelica_metatype _inGraph, modelica_metatype *out_outMergedModRef);
#define boxptr_FMod_merge omc_FMod_merge
static const MMC_DEFSTRUCTLIT(boxvar_lit_FMod_merge,2,0) {(void*) boxptr_FMod_merge,0}};
#define boxvar_FMod_merge MMC_REFSTRUCTLIT(boxvar_lit_FMod_merge)
#ifdef __cplusplus
}
#endif
#endif

#ifndef InstMeta__H
#define InstMeta__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description DAE_EvaluateSingletonType_EVAL__SINGLETON__TYPE__FUNCTION__desc;
extern struct record_description DAE_EvaluateSingletonType_NOT__SINGLETON__desc;
extern struct record_description DAE_Type_T__METAPOLYMORPHIC__desc;
extern struct record_description DAE_Type_T__METAUNIONTYPE__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description SourceInfo_SOURCEINFO__desc;
DLLExport
void omc_InstMeta_checkArrayType(threadData_t *threadData, modelica_metatype _inType);
#define boxptr_InstMeta_checkArrayType omc_InstMeta_checkArrayType
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstMeta_checkArrayType,2,0) {(void*) boxptr_InstMeta_checkArrayType,0}};
#define boxvar_InstMeta_checkArrayType MMC_REFSTRUCTLIT(boxvar_lit_InstMeta_checkArrayType)
#define boxptr_InstMeta_fixUniontype2 omc_InstMeta_fixUniontype2
DLLExport
modelica_metatype omc_InstMeta_fixUniontype(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inState, modelica_metatype _inClassDef, modelica_metatype *out_outType);
#define boxptr_InstMeta_fixUniontype omc_InstMeta_fixUniontype
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstMeta_fixUniontype,2,0) {(void*) boxptr_InstMeta_fixUniontype,0}};
#define boxvar_InstMeta_fixUniontype MMC_REFSTRUCTLIT(boxvar_lit_InstMeta_fixUniontype)
#ifdef __cplusplus
}
#endif
#endif

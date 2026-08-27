#ifndef FLookup__H
#define FLookup__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description FLookup_Options_OPTIONS__desc;
DLLExport
modelica_metatype omc_FLookup_cr(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_metatype _inCref, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
#define boxptr_FLookup_cr omc_FLookup_cr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_cr,2,0) {(void*) boxptr_FLookup_cr,0}};
#define boxvar_FLookup_cr MMC_REFSTRUCTLIT(boxvar_lit_FLookup_cr)
DLLExport
modelica_metatype omc_FLookup_fq(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
#define boxptr_FLookup_fq omc_FLookup_fq
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_fq,2,0) {(void*) boxptr_FLookup_fq,0}};
#define boxvar_FLookup_fq MMC_REFSTRUCTLIT(boxvar_lit_FLookup_fq)
DLLExport
modelica_metatype omc_FLookup_imp__unqual(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inImports, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
#define boxptr_FLookup_imp__unqual omc_FLookup_imp__unqual
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_imp__unqual,2,0) {(void*) boxptr_FLookup_imp__unqual,0}};
#define boxvar_FLookup_imp__unqual MMC_REFSTRUCTLIT(boxvar_lit_FLookup_imp__unqual)
#define boxptr_FLookup_imp__qual omc_FLookup_imp__qual
DLLExport
modelica_metatype omc_FLookup_imp(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
#define boxptr_FLookup_imp omc_FLookup_imp
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_imp,2,0) {(void*) boxptr_FLookup_imp,0}};
#define boxvar_FLookup_imp MMC_REFSTRUCTLIT(boxvar_lit_FLookup_imp)
DLLExport
modelica_metatype omc_FLookup_ext(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
#define boxptr_FLookup_ext omc_FLookup_ext
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_ext,2,0) {(void*) boxptr_FLookup_ext,0}};
#define boxvar_FLookup_ext MMC_REFSTRUCTLIT(boxvar_lit_FLookup_ext)
DLLExport
modelica_metatype omc_FLookup_name(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_metatype _inPath, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
#define boxptr_FLookup_name omc_FLookup_name
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_name,2,0) {(void*) boxptr_FLookup_name,0}};
#define boxvar_FLookup_name MMC_REFSTRUCTLIT(boxvar_lit_FLookup_name)
DLLExport
modelica_metatype omc_FLookup_search(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRefs, modelica_string _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
#define boxptr_FLookup_search omc_FLookup_search
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_search,2,0) {(void*) boxptr_FLookup_search,0}};
#define boxvar_FLookup_search MMC_REFSTRUCTLIT(boxvar_lit_FLookup_search)
DLLExport
modelica_metatype omc_FLookup_id(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inRef, modelica_string _inName, modelica_metatype _inOptions, modelica_metatype _inMsg, modelica_metatype *out_outRef);
#define boxptr_FLookup_id omc_FLookup_id
static const MMC_DEFSTRUCTLIT(boxvar_lit_FLookup_id,2,0) {(void*) boxptr_FLookup_id,0}};
#define boxvar_FLookup_id MMC_REFSTRUCTLIT(boxvar_lit_FLookup_id)
#ifdef __cplusplus
}
#endif
#endif

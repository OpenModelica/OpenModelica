#ifndef Pointer__H
#define Pointer__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_Pointer_applyMapFold(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmutable, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
#define boxptr_Pointer_applyMapFold omc_Pointer_applyMapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_Pointer_applyMapFold,2,0) {(void*) boxptr_Pointer_applyMapFold,0}};
#define boxvar_Pointer_applyMapFold MMC_REFSTRUCTLIT(boxvar_lit_Pointer_applyMapFold)
DLLExport
modelica_metatype omc_Pointer_applyFold(threadData_t *threadData, modelica_metatype _mutable, modelica_fnptr _func);
#define boxptr_Pointer_applyFold omc_Pointer_applyFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_Pointer_applyFold,2,0) {(void*) boxptr_Pointer_applyFold,0}};
#define boxvar_Pointer_applyFold MMC_REFSTRUCTLIT(boxvar_lit_Pointer_applyFold)
DLLExport
modelica_metatype omc_Pointer_apply(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmutable, modelica_fnptr _func);
#define boxptr_Pointer_apply omc_Pointer_apply
static const MMC_DEFSTRUCTLIT(boxvar_lit_Pointer_apply,2,0) {(void*) boxptr_Pointer_apply,0}};
#define boxvar_Pointer_apply MMC_REFSTRUCTLIT(boxvar_lit_Pointer_apply)
DLLExport
modelica_metatype omc_Pointer_access(threadData_t *threadData, modelica_metatype _mutable);
#define boxptr_Pointer_access omc_Pointer_access
static const MMC_DEFSTRUCTLIT(boxvar_lit_Pointer_access,2,0) {(void*) boxptr_Pointer_access,0}};
#define boxvar_Pointer_access MMC_REFSTRUCTLIT(boxvar_lit_Pointer_access)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype pointerAccess(modelica_metatype (*_mutable*));
*/
DLLExport
void omc_Pointer_update(threadData_t *threadData, modelica_metatype _mutable, modelica_metatype _data);
#define boxptr_Pointer_update omc_Pointer_update
static const MMC_DEFSTRUCTLIT(boxvar_lit_Pointer_update,2,0) {(void*) boxptr_Pointer_update,0}};
#define boxvar_Pointer_update MMC_REFSTRUCTLIT(boxvar_lit_Pointer_update)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void pointerUpdate(OpenModelica_threadData_ThreadData*, modelica_metatype (*_mutable*), modelica_metatype (*_data*));
*/
DLLExport
modelica_metatype omc_Pointer_createImmutable(threadData_t *threadData, modelica_metatype _data);
#define boxptr_Pointer_createImmutable omc_Pointer_createImmutable
static const MMC_DEFSTRUCTLIT(boxvar_lit_Pointer_createImmutable,2,0) {(void*) boxptr_Pointer_createImmutable,0}};
#define boxvar_Pointer_createImmutable MMC_REFSTRUCTLIT(boxvar_lit_Pointer_createImmutable)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype mmc_mk_some(modelica_metatype (*_data*));
*/
DLLExport
modelica_metatype omc_Pointer_create(threadData_t *threadData, modelica_metatype _data);
#define boxptr_Pointer_create omc_Pointer_create
static const MMC_DEFSTRUCTLIT(boxvar_lit_Pointer_create,2,0) {(void*) boxptr_Pointer_create,0}};
#define boxvar_Pointer_create MMC_REFSTRUCTLIT(boxvar_lit_Pointer_create)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype pointerCreate(modelica_metatype (*_data*));
*/
#ifdef __cplusplus
}
#endif
#endif

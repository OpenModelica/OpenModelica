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

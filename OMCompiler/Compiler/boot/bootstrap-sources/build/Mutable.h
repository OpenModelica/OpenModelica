#ifndef Mutable__H
#define Mutable__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_Mutable_access(threadData_t *threadData, modelica_metatype _mutable);
#define boxptr_Mutable_access omc_Mutable_access
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mutable_access,2,0) {(void*) boxptr_Mutable_access,0}};
#define boxvar_Mutable_access MMC_REFSTRUCTLIT(boxvar_lit_Mutable_access)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype mutableAccess(modelica_metatype (*_mutable*));
*/
DLLExport
void omc_Mutable_update(threadData_t *threadData, modelica_metatype _mutable, modelica_metatype _data);
#define boxptr_Mutable_update omc_Mutable_update
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mutable_update,2,0) {(void*) boxptr_Mutable_update,0}};
#define boxvar_Mutable_update MMC_REFSTRUCTLIT(boxvar_lit_Mutable_update)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern void mutableUpdate(modelica_metatype (*_mutable*), modelica_metatype (*_data*));
*/
DLLExport
modelica_metatype omc_Mutable_create(threadData_t *threadData, modelica_metatype _data);
#define boxptr_Mutable_create omc_Mutable_create
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mutable_create,2,0) {(void*) boxptr_Mutable_create,0}};
#define boxvar_Mutable_create MMC_REFSTRUCTLIT(boxvar_lit_Mutable_create)
/*
* The function has annotation(Include=...>) or is builtin
* the external function definition should be present
* in one of these files and have this prototype:
* extern modelica_metatype mutableCreate(modelica_metatype (*_data*));
*/
#ifdef __cplusplus
}
#endif
#endif

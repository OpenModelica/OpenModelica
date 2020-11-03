#ifndef HashSetString__H
#define HashSetString__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_HashSetString_emptyHashSetSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashSetString_emptyHashSetSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashSetString_emptyHashSetSized,2,0) {(void*) boxptr_HashSetString_emptyHashSetSized,0}};
#define boxvar_HashSetString_emptyHashSetSized MMC_REFSTRUCTLIT(boxvar_lit_HashSetString_emptyHashSetSized)
DLLExport
modelica_metatype omc_HashSetString_emptyHashSet(threadData_t *threadData);
#define boxptr_HashSetString_emptyHashSet omc_HashSetString_emptyHashSet
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashSetString_emptyHashSet,2,0) {(void*) boxptr_HashSetString_emptyHashSet,0}};
#define boxvar_HashSetString_emptyHashSet MMC_REFSTRUCTLIT(boxvar_lit_HashSetString_emptyHashSet)
#ifdef __cplusplus
}
#endif
#endif

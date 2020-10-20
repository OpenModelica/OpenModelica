#ifndef HashSet__H
#define HashSet__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_HashSet_emptyHashSetSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashSet_emptyHashSetSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashSet_emptyHashSetSized,2,0) {(void*) boxptr_HashSet_emptyHashSetSized,0}};
#define boxvar_HashSet_emptyHashSetSized MMC_REFSTRUCTLIT(boxvar_lit_HashSet_emptyHashSetSized)
DLLExport
modelica_metatype omc_HashSet_emptyHashSet(threadData_t *threadData);
#define boxptr_HashSet_emptyHashSet omc_HashSet_emptyHashSet
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashSet_emptyHashSet,2,0) {(void*) boxptr_HashSet_emptyHashSet,0}};
#define boxvar_HashSet_emptyHashSet MMC_REFSTRUCTLIT(boxvar_lit_HashSet_emptyHashSet)
#ifdef __cplusplus
}
#endif
#endif

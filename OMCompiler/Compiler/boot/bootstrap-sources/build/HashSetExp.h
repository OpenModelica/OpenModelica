#ifndef HashSetExp__H
#define HashSetExp__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_HashSetExp_emptyHashSetSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashSetExp_emptyHashSetSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashSetExp_emptyHashSetSized,2,0) {(void*) boxptr_HashSetExp_emptyHashSetSized,0}};
#define boxvar_HashSetExp_emptyHashSetSized MMC_REFSTRUCTLIT(boxvar_lit_HashSetExp_emptyHashSetSized)
DLLExport
modelica_metatype omc_HashSetExp_emptyHashSet(threadData_t *threadData);
#define boxptr_HashSetExp_emptyHashSet omc_HashSetExp_emptyHashSet
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashSetExp_emptyHashSet,2,0) {(void*) boxptr_HashSetExp_emptyHashSet,0}};
#define boxvar_HashSetExp_emptyHashSet MMC_REFSTRUCTLIT(boxvar_lit_HashSetExp_emptyHashSet)
#ifdef __cplusplus
}
#endif
#endif

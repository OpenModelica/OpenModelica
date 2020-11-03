#ifndef HashTableStringToPath__H
#define HashTableStringToPath__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_HashTableStringToPath_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTableStringToPath_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableStringToPath_emptyHashTableSized,2,0) {(void*) boxptr_HashTableStringToPath_emptyHashTableSized,0}};
#define boxvar_HashTableStringToPath_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTableStringToPath_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTableStringToPath_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTableStringToPath_emptyHashTable omc_HashTableStringToPath_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableStringToPath_emptyHashTable,2,0) {(void*) boxptr_HashTableStringToPath_emptyHashTable,0}};
#define boxvar_HashTableStringToPath_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTableStringToPath_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

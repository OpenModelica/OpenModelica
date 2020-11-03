#ifndef HashTable5__H
#define HashTable5__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_HashTable5_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTable5_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTable5_emptyHashTableSized,2,0) {(void*) boxptr_HashTable5_emptyHashTableSized,0}};
#define boxvar_HashTable5_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTable5_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTable5_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTable5_emptyHashTable omc_HashTable5_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTable5_emptyHashTable,2,0) {(void*) boxptr_HashTable5_emptyHashTable,0}};
#define boxvar_HashTable5_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTable5_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

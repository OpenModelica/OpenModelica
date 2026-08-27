#ifndef HashTableExpToIndex__H
#define HashTableExpToIndex__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_HashTableExpToIndex_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTableExpToIndex_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableExpToIndex_emptyHashTableSized,2,0) {(void*) boxptr_HashTableExpToIndex_emptyHashTableSized,0}};
#define boxvar_HashTableExpToIndex_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTableExpToIndex_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTableExpToIndex_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTableExpToIndex_emptyHashTable omc_HashTableExpToIndex_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableExpToIndex_emptyHashTable,2,0) {(void*) boxptr_HashTableExpToIndex_emptyHashTable,0}};
#define boxvar_HashTableExpToIndex_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTableExpToIndex_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

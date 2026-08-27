#ifndef HashTable3__H
#define HashTable3__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_HashTable3_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTable3_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTable3_emptyHashTableSized,2,0) {(void*) boxptr_HashTable3_emptyHashTableSized,0}};
#define boxvar_HashTable3_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTable3_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTable3_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTable3_emptyHashTable omc_HashTable3_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTable3_emptyHashTable,2,0) {(void*) boxptr_HashTable3_emptyHashTable,0}};
#define boxvar_HashTable3_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTable3_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

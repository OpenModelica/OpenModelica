#ifndef HashTableCG__H
#define HashTableCG__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_HashTableCG_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTableCG_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCG_emptyHashTableSized,2,0) {(void*) boxptr_HashTableCG_emptyHashTableSized,0}};
#define boxvar_HashTableCG_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTableCG_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTableCG_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTableCG_emptyHashTable omc_HashTableCG_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCG_emptyHashTable,2,0) {(void*) boxptr_HashTableCG_emptyHashTable,0}};
#define boxvar_HashTableCG_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTableCG_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

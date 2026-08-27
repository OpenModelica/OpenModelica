#ifndef HashTableCrToExpOption__H
#define HashTableCrToExpOption__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
#define boxptr_HashTableCrToExpOption_printExpOtionStr omc_HashTableCrToExpOption_printExpOtionStr
DLLExport
modelica_metatype omc_HashTableCrToExpOption_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTableCrToExpOption_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrToExpOption_emptyHashTableSized,2,0) {(void*) boxptr_HashTableCrToExpOption_emptyHashTableSized,0}};
#define boxvar_HashTableCrToExpOption_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrToExpOption_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTableCrToExpOption_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTableCrToExpOption_emptyHashTable omc_HashTableCrToExpOption_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrToExpOption_emptyHashTable,2,0) {(void*) boxptr_HashTableCrToExpOption_emptyHashTable,0}};
#define boxvar_HashTableCrToExpOption_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrToExpOption_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

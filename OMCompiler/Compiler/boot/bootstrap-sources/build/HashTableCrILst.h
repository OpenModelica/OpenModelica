#ifndef HashTableCrILst__H
#define HashTableCrILst__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_string omc_HashTableCrILst_printIntListStr(threadData_t *threadData, modelica_metatype _ilst);
#define boxptr_HashTableCrILst_printIntListStr omc_HashTableCrILst_printIntListStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrILst_printIntListStr,2,0) {(void*) boxptr_HashTableCrILst_printIntListStr,0}};
#define boxvar_HashTableCrILst_printIntListStr MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrILst_printIntListStr)
DLLExport
modelica_metatype omc_HashTableCrILst_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTableCrILst_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrILst_emptyHashTableSized,2,0) {(void*) boxptr_HashTableCrILst_emptyHashTableSized,0}};
#define boxvar_HashTableCrILst_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrILst_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTableCrILst_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTableCrILst_emptyHashTable omc_HashTableCrILst_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrILst_emptyHashTable,2,0) {(void*) boxptr_HashTableCrILst_emptyHashTable,0}};
#define boxvar_HashTableCrILst_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrILst_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

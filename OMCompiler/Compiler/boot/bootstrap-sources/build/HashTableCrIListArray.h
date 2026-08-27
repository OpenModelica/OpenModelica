#ifndef HashTableCrIListArray__H
#define HashTableCrIListArray__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_string omc_HashTableCrIListArray_printIntListArrayStr(threadData_t *threadData, modelica_metatype _iValue);
#define boxptr_HashTableCrIListArray_printIntListArrayStr omc_HashTableCrIListArray_printIntListArrayStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrIListArray_printIntListArrayStr,2,0) {(void*) boxptr_HashTableCrIListArray_printIntListArrayStr,0}};
#define boxvar_HashTableCrIListArray_printIntListArrayStr MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrIListArray_printIntListArrayStr)
DLLExport
modelica_metatype omc_HashTableCrIListArray_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTableCrIListArray_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrIListArray_emptyHashTableSized,2,0) {(void*) boxptr_HashTableCrIListArray_emptyHashTableSized,0}};
#define boxvar_HashTableCrIListArray_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrIListArray_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTableCrIListArray_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTableCrIListArray_emptyHashTable omc_HashTableCrIListArray_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrIListArray_emptyHashTable,2,0) {(void*) boxptr_HashTableCrIListArray_emptyHashTable,0}};
#define boxvar_HashTableCrIListArray_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrIListArray_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

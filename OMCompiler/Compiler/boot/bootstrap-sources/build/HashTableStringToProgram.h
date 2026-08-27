#ifndef HashTableStringToProgram__H
#define HashTableStringToProgram__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
#define boxptr_HashTableStringToProgram_dummyStr omc_HashTableStringToProgram_dummyStr
DLLExport
modelica_metatype omc_HashTableStringToProgram_emptyHashTableSized(threadData_t *threadData, modelica_integer _size);
DLLExport
modelica_metatype boxptr_HashTableStringToProgram_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableStringToProgram_emptyHashTableSized,2,0) {(void*) boxptr_HashTableStringToProgram_emptyHashTableSized,0}};
#define boxvar_HashTableStringToProgram_emptyHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_HashTableStringToProgram_emptyHashTableSized)
DLLExport
modelica_metatype omc_HashTableStringToProgram_emptyHashTable(threadData_t *threadData);
#define boxptr_HashTableStringToProgram_emptyHashTable omc_HashTableStringToProgram_emptyHashTable
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableStringToProgram_emptyHashTable,2,0) {(void*) boxptr_HashTableStringToProgram_emptyHashTable,0}};
#define boxvar_HashTableStringToProgram_emptyHashTable MMC_REFSTRUCTLIT(boxvar_lit_HashTableStringToProgram_emptyHashTable)
#ifdef __cplusplus
}
#endif
#endif

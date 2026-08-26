#ifndef BaseHashSet__H
#define BaseHashSet__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLDirection
modelica_metatype omc_BaseHashSet_valueArrayNth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos);
DLLDirection
modelica_metatype boxptr_BaseHashSet_valueArrayNth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayNth,2,0) {(void*) boxptr_BaseHashSet_valueArrayNth,0}};
#define boxvar_BaseHashSet_valueArrayNth MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayNth)
DLLDirection
modelica_metatype omc_BaseHashSet_valueArrayClearnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos);
DLLDirection
modelica_metatype boxptr_BaseHashSet_valueArrayClearnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayClearnth,2,0) {(void*) boxptr_BaseHashSet_valueArrayClearnth,0}};
#define boxvar_BaseHashSet_valueArrayClearnth MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayClearnth)
DLLDirection
modelica_metatype omc_BaseHashSet_valueArraySetnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype _entry);
DLLDirection
modelica_metatype boxptr_BaseHashSet_valueArraySetnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos, modelica_metatype _entry);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArraySetnth,2,0) {(void*) boxptr_BaseHashSet_valueArraySetnth,0}};
#define boxvar_BaseHashSet_valueArraySetnth MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArraySetnth)
DLLDirection
modelica_metatype omc_BaseHashSet_valueArrayAdd(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _entry);
#define boxptr_BaseHashSet_valueArrayAdd omc_BaseHashSet_valueArrayAdd
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayAdd,2,0) {(void*) boxptr_BaseHashSet_valueArrayAdd,0}};
#define boxvar_BaseHashSet_valueArrayAdd MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayAdd)
DLLDirection
modelica_integer omc_BaseHashSet_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray);
DLLDirection
modelica_metatype boxptr_BaseHashSet_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayLength,2,0) {(void*) boxptr_BaseHashSet_valueArrayLength,0}};
#define boxvar_BaseHashSet_valueArrayLength MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayLength)
DLLDirection
modelica_integer omc_BaseHashSet_currentSize(threadData_t *threadData, modelica_metatype _hashSet);
DLLDirection
modelica_metatype boxptr_BaseHashSet_currentSize(threadData_t *threadData, modelica_metatype _hashSet);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_currentSize,2,0) {(void*) boxptr_BaseHashSet_currentSize,0}};
#define boxvar_BaseHashSet_currentSize MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_currentSize)
DLLDirection
modelica_metatype omc_BaseHashSet_valueArrayList(threadData_t *threadData, modelica_metatype _inValueArray);
#define boxptr_BaseHashSet_valueArrayList omc_BaseHashSet_valueArrayList
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayList,2,0) {(void*) boxptr_BaseHashSet_valueArrayList,0}};
#define boxvar_BaseHashSet_valueArrayList MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayList)
DLLDirection
modelica_metatype omc_BaseHashSet_hashSetList(threadData_t *threadData, modelica_metatype _hashSet);
#define boxptr_BaseHashSet_hashSetList omc_BaseHashSet_hashSetList
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_hashSetList,2,0) {(void*) boxptr_BaseHashSet_hashSetList,0}};
#define boxvar_BaseHashSet_hashSetList MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_hashSetList)
DLLDirection
void omc_BaseHashSet_dumpHashSet(threadData_t *threadData, modelica_metatype _hashSet);
#define boxptr_BaseHashSet_dumpHashSet omc_BaseHashSet_dumpHashSet
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_dumpHashSet,2,0) {(void*) boxptr_BaseHashSet_dumpHashSet,0}};
#define boxvar_BaseHashSet_dumpHashSet MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_dumpHashSet)
DLLDirection
void omc_BaseHashSet_printHashSet(threadData_t *threadData, modelica_metatype _hashSet);
#define boxptr_BaseHashSet_printHashSet omc_BaseHashSet_printHashSet
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_printHashSet,2,0) {(void*) boxptr_BaseHashSet_printHashSet,0}};
#define boxvar_BaseHashSet_printHashSet MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_printHashSet)
DLLDirection
modelica_metatype omc_BaseHashSet_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet);
#define boxptr_BaseHashSet_get omc_BaseHashSet_get
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_get,2,0) {(void*) boxptr_BaseHashSet_get,0}};
#define boxvar_BaseHashSet_get MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_get)
DLLDirection
modelica_boolean omc_BaseHashSet_hasAll(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _hashSet);
DLLDirection
modelica_metatype boxptr_BaseHashSet_hasAll(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _hashSet);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_hasAll,2,0) {(void*) boxptr_BaseHashSet_hasAll,0}};
#define boxvar_BaseHashSet_hasAll MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_hasAll)
DLLDirection
modelica_boolean omc_BaseHashSet_has(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet);
DLLDirection
modelica_metatype boxptr_BaseHashSet_has(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_has,2,0) {(void*) boxptr_BaseHashSet_has,0}};
#define boxvar_BaseHashSet_has MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_has)
DLLDirection
modelica_metatype omc_BaseHashSet_delete(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet);
#define boxptr_BaseHashSet_delete omc_BaseHashSet_delete
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_delete,2,0) {(void*) boxptr_BaseHashSet_delete,0}};
#define boxvar_BaseHashSet_delete MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_delete)
DLLDirection
modelica_metatype omc_BaseHashSet_addUnique(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet);
#define boxptr_BaseHashSet_addUnique omc_BaseHashSet_addUnique
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_addUnique,2,0) {(void*) boxptr_BaseHashSet_addUnique,0}};
#define boxvar_BaseHashSet_addUnique MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_addUnique)
DLLDirection
modelica_metatype omc_BaseHashSet_addNoUpdCheck(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashSet);
#define boxptr_BaseHashSet_addNoUpdCheck omc_BaseHashSet_addNoUpdCheck
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_addNoUpdCheck,2,0) {(void*) boxptr_BaseHashSet_addNoUpdCheck,0}};
#define boxvar_BaseHashSet_addNoUpdCheck MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_addNoUpdCheck)
DLLDirection
modelica_metatype omc_BaseHashSet_add(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashSet);
#define boxptr_BaseHashSet_add omc_BaseHashSet_add
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_add,2,0) {(void*) boxptr_BaseHashSet_add,0}};
#define boxvar_BaseHashSet_add MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_add)
DLLDirection
modelica_metatype omc_BaseHashSet_emptyHashSetWork(threadData_t *threadData, modelica_integer _szBucket, modelica_metatype _fntpl);
DLLDirection
modelica_metatype boxptr_BaseHashSet_emptyHashSetWork(threadData_t *threadData, modelica_metatype _szBucket, modelica_metatype _fntpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_emptyHashSetWork,2,0) {(void*) boxptr_BaseHashSet_emptyHashSetWork,0}};
#define boxvar_BaseHashSet_emptyHashSetWork MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_emptyHashSetWork)
DLLDirection
modelica_integer omc_BaseHashSet_bucketToValuesSize(threadData_t *threadData, modelica_integer _szBucket);
DLLDirection
modelica_metatype boxptr_BaseHashSet_bucketToValuesSize(threadData_t *threadData, modelica_metatype _szBucket);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_bucketToValuesSize,2,0) {(void*) boxptr_BaseHashSet_bucketToValuesSize,0}};
#define boxvar_BaseHashSet_bucketToValuesSize MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_bucketToValuesSize)
#ifdef __cplusplus
}
#endif
#endif

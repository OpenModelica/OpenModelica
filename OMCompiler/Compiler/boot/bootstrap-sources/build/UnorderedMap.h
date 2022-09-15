#ifndef UnorderedMap__H
#define UnorderedMap__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description IOStream_IOStreamType_LIST__desc;
extern struct record_description UnorderedMap_UNORDERED__MAP__desc;
DLLExport
modelica_string omc_UnorderedMap_toJSON(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _keyStringFn, modelica_fnptr _valueStringFn);
#define boxptr_UnorderedMap_toJSON omc_UnorderedMap_toJSON
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_toJSON,2,0) {(void*) boxptr_UnorderedMap_toJSON,0}};
#define boxvar_UnorderedMap_toJSON MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_toJSON)
DLLExport
modelica_string omc_UnorderedMap_toString(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _keyStringFn, modelica_fnptr _valueStringFn, modelica_string _delimiter);
#define boxptr_UnorderedMap_toString omc_UnorderedMap_toString
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_toString,2,0) {(void*) boxptr_UnorderedMap_toString,0}};
#define boxvar_UnorderedMap_toString MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_toString)
DLLExport
void omc_UnorderedMap_rehash(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_rehash omc_UnorderedMap_rehash
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_rehash,2,0) {(void*) boxptr_UnorderedMap_rehash,0}};
#define boxvar_UnorderedMap_rehash MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_rehash)
DLLExport
modelica_real omc_UnorderedMap_loadFactor(threadData_t *threadData, modelica_metatype _map);
DLLExport
modelica_metatype boxptr_UnorderedMap_loadFactor(threadData_t *threadData, modelica_metatype _map);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_loadFactor,2,0) {(void*) boxptr_UnorderedMap_loadFactor,0}};
#define boxvar_UnorderedMap_loadFactor MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_loadFactor)
DLLExport
modelica_integer omc_UnorderedMap_bucketCount(threadData_t *threadData, modelica_metatype _map);
DLLExport
modelica_metatype boxptr_UnorderedMap_bucketCount(threadData_t *threadData, modelica_metatype _map);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_bucketCount,2,0) {(void*) boxptr_UnorderedMap_bucketCount,0}};
#define boxvar_UnorderedMap_bucketCount MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_bucketCount)
DLLExport
modelica_boolean omc_UnorderedMap_isEmpty(threadData_t *threadData, modelica_metatype _map);
DLLExport
modelica_metatype boxptr_UnorderedMap_isEmpty(threadData_t *threadData, modelica_metatype _map);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_isEmpty,2,0) {(void*) boxptr_UnorderedMap_isEmpty,0}};
#define boxvar_UnorderedMap_isEmpty MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_isEmpty)
DLLExport
modelica_integer omc_UnorderedMap_size(threadData_t *threadData, modelica_metatype _map);
DLLExport
modelica_metatype boxptr_UnorderedMap_size(threadData_t *threadData, modelica_metatype _map);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_size,2,0) {(void*) boxptr_UnorderedMap_size,0}};
#define boxvar_UnorderedMap_size MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_size)
DLLExport
modelica_boolean omc_UnorderedMap_none(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
DLLExport
modelica_metatype boxptr_UnorderedMap_none(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_none,2,0) {(void*) boxptr_UnorderedMap_none,0}};
#define boxvar_UnorderedMap_none MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_none)
DLLExport
modelica_boolean omc_UnorderedMap_any(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
DLLExport
modelica_metatype boxptr_UnorderedMap_any(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_any,2,0) {(void*) boxptr_UnorderedMap_any,0}};
#define boxvar_UnorderedMap_any MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_any)
DLLExport
modelica_boolean omc_UnorderedMap_all(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
DLLExport
modelica_metatype boxptr_UnorderedMap_all(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_all,2,0) {(void*) boxptr_UnorderedMap_all,0}};
#define boxvar_UnorderedMap_all MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_all)
DLLExport
void omc_UnorderedMap_apply(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
#define boxptr_UnorderedMap_apply omc_UnorderedMap_apply
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_apply,2,0) {(void*) boxptr_UnorderedMap_apply,0}};
#define boxvar_UnorderedMap_apply MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_apply)
DLLExport
modelica_metatype omc_UnorderedMap_map(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
#define boxptr_UnorderedMap_map omc_UnorderedMap_map
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_map,2,0) {(void*) boxptr_UnorderedMap_map,0}};
#define boxvar_UnorderedMap_map MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_map)
DLLExport
modelica_metatype omc_UnorderedMap_fold(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn, modelica_metatype __omcQ_24in_5Farg);
#define boxptr_UnorderedMap_fold omc_UnorderedMap_fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_fold,2,0) {(void*) boxptr_UnorderedMap_fold,0}};
#define boxvar_UnorderedMap_fold MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_fold)
DLLExport
modelica_metatype omc_UnorderedMap_valueVector(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_valueVector omc_UnorderedMap_valueVector
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_valueVector,2,0) {(void*) boxptr_UnorderedMap_valueVector,0}};
#define boxvar_UnorderedMap_valueVector MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_valueVector)
DLLExport
modelica_metatype omc_UnorderedMap_keyVector(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_keyVector omc_UnorderedMap_keyVector
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_keyVector,2,0) {(void*) boxptr_UnorderedMap_keyVector,0}};
#define boxvar_UnorderedMap_keyVector MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_keyVector)
DLLExport
modelica_metatype omc_UnorderedMap_toVector(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_toVector omc_UnorderedMap_toVector
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_toVector,2,0) {(void*) boxptr_UnorderedMap_toVector,0}};
#define boxvar_UnorderedMap_toVector MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_toVector)
DLLExport
modelica_metatype omc_UnorderedMap_valueArray(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_valueArray omc_UnorderedMap_valueArray
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_valueArray,2,0) {(void*) boxptr_UnorderedMap_valueArray,0}};
#define boxvar_UnorderedMap_valueArray MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_valueArray)
DLLExport
modelica_metatype omc_UnorderedMap_keyArray(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_keyArray omc_UnorderedMap_keyArray
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_keyArray,2,0) {(void*) boxptr_UnorderedMap_keyArray,0}};
#define boxvar_UnorderedMap_keyArray MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_keyArray)
DLLExport
modelica_metatype omc_UnorderedMap_toArray(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_toArray omc_UnorderedMap_toArray
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_toArray,2,0) {(void*) boxptr_UnorderedMap_toArray,0}};
#define boxvar_UnorderedMap_toArray MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_toArray)
DLLExport
modelica_metatype omc_UnorderedMap_valueList(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_valueList omc_UnorderedMap_valueList
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_valueList,2,0) {(void*) boxptr_UnorderedMap_valueList,0}};
#define boxvar_UnorderedMap_valueList MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_valueList)
DLLExport
modelica_metatype omc_UnorderedMap_keyList(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_keyList omc_UnorderedMap_keyList
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_keyList,2,0) {(void*) boxptr_UnorderedMap_keyList,0}};
#define boxvar_UnorderedMap_keyList MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_keyList)
DLLExport
modelica_metatype omc_UnorderedMap_toList(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_toList omc_UnorderedMap_toList
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_toList,2,0) {(void*) boxptr_UnorderedMap_toList,0}};
#define boxvar_UnorderedMap_toList MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_toList)
DLLExport
modelica_metatype omc_UnorderedMap_valueAt(threadData_t *threadData, modelica_metatype _map, modelica_integer _index);
DLLExport
modelica_metatype boxptr_UnorderedMap_valueAt(threadData_t *threadData, modelica_metatype _map, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_valueAt,2,0) {(void*) boxptr_UnorderedMap_valueAt,0}};
#define boxvar_UnorderedMap_valueAt MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_valueAt)
DLLExport
modelica_metatype omc_UnorderedMap_keyAt(threadData_t *threadData, modelica_metatype _map, modelica_integer _index);
DLLExport
modelica_metatype boxptr_UnorderedMap_keyAt(threadData_t *threadData, modelica_metatype _map, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_keyAt,2,0) {(void*) boxptr_UnorderedMap_keyAt,0}};
#define boxvar_UnorderedMap_keyAt MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_keyAt)
DLLExport
modelica_metatype omc_UnorderedMap_firstKey(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_firstKey omc_UnorderedMap_firstKey
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_firstKey,2,0) {(void*) boxptr_UnorderedMap_firstKey,0}};
#define boxvar_UnorderedMap_firstKey MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_firstKey)
DLLExport
modelica_metatype omc_UnorderedMap_first(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_first omc_UnorderedMap_first
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_first,2,0) {(void*) boxptr_UnorderedMap_first,0}};
#define boxvar_UnorderedMap_first MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_first)
DLLExport
modelica_boolean omc_UnorderedMap_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map);
DLLExport
modelica_metatype boxptr_UnorderedMap_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_contains,2,0) {(void*) boxptr_UnorderedMap_contains,0}};
#define boxvar_UnorderedMap_contains MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_contains)
DLLExport
modelica_metatype omc_UnorderedMap_getKey(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map);
#define boxptr_UnorderedMap_getKey omc_UnorderedMap_getKey
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_getKey,2,0) {(void*) boxptr_UnorderedMap_getKey,0}};
#define boxvar_UnorderedMap_getKey MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_getKey)
DLLExport
modelica_metatype omc_UnorderedMap_getOrDefault(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map, modelica_metatype _default);
#define boxptr_UnorderedMap_getOrDefault omc_UnorderedMap_getOrDefault
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_getOrDefault,2,0) {(void*) boxptr_UnorderedMap_getOrDefault,0}};
#define boxvar_UnorderedMap_getOrDefault MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_getOrDefault)
DLLExport
modelica_metatype omc_UnorderedMap_getOrFail(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map);
#define boxptr_UnorderedMap_getOrFail omc_UnorderedMap_getOrFail
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_getOrFail,2,0) {(void*) boxptr_UnorderedMap_getOrFail,0}};
#define boxvar_UnorderedMap_getOrFail MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_getOrFail)
DLLExport
modelica_metatype omc_UnorderedMap_getSafe(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map, modelica_metatype _info);
#define boxptr_UnorderedMap_getSafe omc_UnorderedMap_getSafe
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_getSafe,2,0) {(void*) boxptr_UnorderedMap_getSafe,0}};
#define boxvar_UnorderedMap_getSafe MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_getSafe)
DLLExport
modelica_metatype omc_UnorderedMap_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map);
#define boxptr_UnorderedMap_get omc_UnorderedMap_get
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_get,2,0) {(void*) boxptr_UnorderedMap_get,0}};
#define boxvar_UnorderedMap_get MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_get)
DLLExport
void omc_UnorderedMap_clear(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_clear omc_UnorderedMap_clear
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_clear,2,0) {(void*) boxptr_UnorderedMap_clear,0}};
#define boxvar_UnorderedMap_clear MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_clear)
DLLExport
modelica_boolean omc_UnorderedMap_remove(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map);
DLLExport
modelica_metatype boxptr_UnorderedMap_remove(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_remove,2,0) {(void*) boxptr_UnorderedMap_remove,0}};
#define boxvar_UnorderedMap_remove MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_remove)
DLLExport
modelica_metatype omc_UnorderedMap_addUpdate(threadData_t *threadData, modelica_metatype _key, modelica_fnptr _fn, modelica_metatype _map);
#define boxptr_UnorderedMap_addUpdate omc_UnorderedMap_addUpdate
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_addUpdate,2,0) {(void*) boxptr_UnorderedMap_addUpdate,0}};
#define boxvar_UnorderedMap_addUpdate MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_addUpdate)
DLLExport
modelica_metatype omc_UnorderedMap_tryAdd(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _map);
#define boxptr_UnorderedMap_tryAdd omc_UnorderedMap_tryAdd
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_tryAdd,2,0) {(void*) boxptr_UnorderedMap_tryAdd,0}};
#define boxvar_UnorderedMap_tryAdd MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_tryAdd)
DLLExport
void omc_UnorderedMap_addUnique(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _map);
#define boxptr_UnorderedMap_addUnique omc_UnorderedMap_addUnique
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_addUnique,2,0) {(void*) boxptr_UnorderedMap_addUnique,0}};
#define boxvar_UnorderedMap_addUnique MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_addUnique)
DLLExport
void omc_UnorderedMap_addNew(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _map);
#define boxptr_UnorderedMap_addNew omc_UnorderedMap_addNew
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_addNew,2,0) {(void*) boxptr_UnorderedMap_addNew,0}};
#define boxvar_UnorderedMap_addNew MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_addNew)
DLLExport
void omc_UnorderedMap_add(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _map);
#define boxptr_UnorderedMap_add omc_UnorderedMap_add
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_add,2,0) {(void*) boxptr_UnorderedMap_add,0}};
#define boxvar_UnorderedMap_add MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_add)
DLLExport
modelica_metatype omc_UnorderedMap_deepCopy(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn);
#define boxptr_UnorderedMap_deepCopy omc_UnorderedMap_deepCopy
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_deepCopy,2,0) {(void*) boxptr_UnorderedMap_deepCopy,0}};
#define boxvar_UnorderedMap_deepCopy MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_deepCopy)
DLLExport
modelica_metatype omc_UnorderedMap_copy(threadData_t *threadData, modelica_metatype _map);
#define boxptr_UnorderedMap_copy omc_UnorderedMap_copy
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_copy,2,0) {(void*) boxptr_UnorderedMap_copy,0}};
#define boxvar_UnorderedMap_copy MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_copy)
DLLExport
modelica_metatype omc_UnorderedMap_fromLists(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _values, modelica_fnptr _hash, modelica_fnptr _keyEq);
#define boxptr_UnorderedMap_fromLists omc_UnorderedMap_fromLists
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_fromLists,2,0) {(void*) boxptr_UnorderedMap_fromLists,0}};
#define boxvar_UnorderedMap_fromLists MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_fromLists)
DLLExport
modelica_metatype omc_UnorderedMap_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_integer _bucketCount);
DLLExport
modelica_metatype boxptr_UnorderedMap_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_metatype _bucketCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_new,2,0) {(void*) boxptr_UnorderedMap_new,0}};
#define boxvar_UnorderedMap_new MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_new)
#ifdef __cplusplus
}
#endif
#endif

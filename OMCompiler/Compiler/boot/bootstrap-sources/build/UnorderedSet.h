#ifndef UnorderedSet__H
#define UnorderedSet__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description UnorderedSet_UNORDERED__SET__desc;
#define boxptr_UnorderedSet_extractFromLst omc_UnorderedSet_extractFromLst
DLLDirection
modelica_boolean omc_UnorderedSet_isDisjoint(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2);
DLLDirection
modelica_metatype boxptr_UnorderedSet_isDisjoint(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_isDisjoint,2,0) {(void*) boxptr_UnorderedSet_isDisjoint,0}};
#define boxvar_UnorderedSet_isDisjoint MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_isDisjoint)
DLLDirection
modelica_metatype omc_UnorderedSet_sym__difference(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2);
#define boxptr_UnorderedSet_sym__difference omc_UnorderedSet_sym__difference
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_sym__difference,2,0) {(void*) boxptr_UnorderedSet_sym__difference,0}};
#define boxvar_UnorderedSet_sym__difference MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_sym__difference)
DLLDirection
modelica_metatype omc_UnorderedSet_difference(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2);
#define boxptr_UnorderedSet_difference omc_UnorderedSet_difference
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_difference,2,0) {(void*) boxptr_UnorderedSet_difference,0}};
#define boxvar_UnorderedSet_difference MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_difference)
DLLDirection
modelica_boolean omc_UnorderedSet_equal__list(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc);
DLLDirection
modelica_metatype boxptr_UnorderedSet_equal__list(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_equal__list,2,0) {(void*) boxptr_UnorderedSet_equal__list,0}};
#define boxvar_UnorderedSet_equal__list MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_equal__list)
DLLDirection
modelica_metatype omc_UnorderedSet_difference__list(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc);
#define boxptr_UnorderedSet_difference__list omc_UnorderedSet_difference__list
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_difference__list,2,0) {(void*) boxptr_UnorderedSet_difference__list,0}};
#define boxvar_UnorderedSet_difference__list MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_difference__list)
DLLDirection
modelica_metatype omc_UnorderedSet_intersection__list(threadData_t *threadData, modelica_metatype _set_lst, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc);
#define boxptr_UnorderedSet_intersection__list omc_UnorderedSet_intersection__list
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_intersection__list,2,0) {(void*) boxptr_UnorderedSet_intersection__list,0}};
#define boxvar_UnorderedSet_intersection__list MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_intersection__list)
DLLDirection
modelica_metatype omc_UnorderedSet_intersection(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2);
#define boxptr_UnorderedSet_intersection omc_UnorderedSet_intersection
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_intersection,2,0) {(void*) boxptr_UnorderedSet_intersection,0}};
#define boxvar_UnorderedSet_intersection MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_intersection)
DLLDirection
modelica_metatype omc_UnorderedSet_merge(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fset1, modelica_metatype _set2);
#define boxptr_UnorderedSet_merge omc_UnorderedSet_merge
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_merge,2,0) {(void*) boxptr_UnorderedSet_merge,0}};
#define boxvar_UnorderedSet_merge MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_merge)
DLLDirection
modelica_metatype omc_UnorderedSet_union__list(threadData_t *threadData, modelica_metatype _set_lst, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc);
#define boxptr_UnorderedSet_union__list omc_UnorderedSet_union__list
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_union__list,2,0) {(void*) boxptr_UnorderedSet_union__list,0}};
#define boxvar_UnorderedSet_union__list MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_union__list)
DLLDirection
modelica_metatype omc_UnorderedSet_union(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2);
#define boxptr_UnorderedSet_union omc_UnorderedSet_union
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_union,2,0) {(void*) boxptr_UnorderedSet_union,0}};
#define boxvar_UnorderedSet_union MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_union)
DLLDirection
modelica_metatype omc_UnorderedSet_unique__list(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc);
#define boxptr_UnorderedSet_unique__list omc_UnorderedSet_unique__list
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_unique__list,2,0) {(void*) boxptr_UnorderedSet_unique__list,0}};
#define boxvar_UnorderedSet_unique__list MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_unique__list)
DLLDirection
void omc_UnorderedSet_dump(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _stringFn);
#define boxptr_UnorderedSet_dump omc_UnorderedSet_dump
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_dump,2,0) {(void*) boxptr_UnorderedSet_dump,0}};
#define boxvar_UnorderedSet_dump MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_dump)
DLLDirection
modelica_string omc_UnorderedSet_toString(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _stringFn, modelica_string _delimiter);
#define boxptr_UnorderedSet_toString omc_UnorderedSet_toString
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_toString,2,0) {(void*) boxptr_UnorderedSet_toString,0}};
#define boxvar_UnorderedSet_toString MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_toString)
DLLDirection
void omc_UnorderedSet_rehash(threadData_t *threadData, modelica_metatype _set);
#define boxptr_UnorderedSet_rehash omc_UnorderedSet_rehash
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_rehash,2,0) {(void*) boxptr_UnorderedSet_rehash,0}};
#define boxvar_UnorderedSet_rehash MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_rehash)
DLLDirection
modelica_real omc_UnorderedSet_loadFactor(threadData_t *threadData, modelica_metatype _set);
DLLDirection
modelica_metatype boxptr_UnorderedSet_loadFactor(threadData_t *threadData, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_loadFactor,2,0) {(void*) boxptr_UnorderedSet_loadFactor,0}};
#define boxvar_UnorderedSet_loadFactor MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_loadFactor)
DLLDirection
modelica_integer omc_UnorderedSet_bucketCount(threadData_t *threadData, modelica_metatype _set);
DLLDirection
modelica_metatype boxptr_UnorderedSet_bucketCount(threadData_t *threadData, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_bucketCount,2,0) {(void*) boxptr_UnorderedSet_bucketCount,0}};
#define boxvar_UnorderedSet_bucketCount MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_bucketCount)
DLLDirection
modelica_boolean omc_UnorderedSet_isEmpty(threadData_t *threadData, modelica_metatype _set);
DLLDirection
modelica_metatype boxptr_UnorderedSet_isEmpty(threadData_t *threadData, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_isEmpty,2,0) {(void*) boxptr_UnorderedSet_isEmpty,0}};
#define boxvar_UnorderedSet_isEmpty MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_isEmpty)
DLLDirection
modelica_integer omc_UnorderedSet_size(threadData_t *threadData, modelica_metatype _set);
DLLDirection
modelica_metatype boxptr_UnorderedSet_size(threadData_t *threadData, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_size,2,0) {(void*) boxptr_UnorderedSet_size,0}};
#define boxvar_UnorderedSet_size MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_size)
DLLDirection
modelica_metatype omc_UnorderedSet_splitOnTrue(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn, modelica_metatype *out_falseSet);
#define boxptr_UnorderedSet_splitOnTrue omc_UnorderedSet_splitOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_splitOnTrue,2,0) {(void*) boxptr_UnorderedSet_splitOnTrue,0}};
#define boxvar_UnorderedSet_splitOnTrue MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_splitOnTrue)
DLLDirection
modelica_metatype omc_UnorderedSet_filterOnFalse(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
#define boxptr_UnorderedSet_filterOnFalse omc_UnorderedSet_filterOnFalse
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_filterOnFalse,2,0) {(void*) boxptr_UnorderedSet_filterOnFalse,0}};
#define boxvar_UnorderedSet_filterOnFalse MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_filterOnFalse)
DLLDirection
modelica_boolean omc_UnorderedSet_none(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
DLLDirection
modelica_metatype boxptr_UnorderedSet_none(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_none,2,0) {(void*) boxptr_UnorderedSet_none,0}};
#define boxvar_UnorderedSet_none MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_none)
DLLDirection
modelica_boolean omc_UnorderedSet_any(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
DLLDirection
modelica_metatype boxptr_UnorderedSet_any(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_any,2,0) {(void*) boxptr_UnorderedSet_any,0}};
#define boxvar_UnorderedSet_any MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_any)
DLLDirection
modelica_boolean omc_UnorderedSet_all(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
DLLDirection
modelica_metatype boxptr_UnorderedSet_all(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_all,2,0) {(void*) boxptr_UnorderedSet_all,0}};
#define boxvar_UnorderedSet_all MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_all)
DLLDirection
void omc_UnorderedSet_apply(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
#define boxptr_UnorderedSet_apply omc_UnorderedSet_apply
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_apply,2,0) {(void*) boxptr_UnorderedSet_apply,0}};
#define boxvar_UnorderedSet_apply MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_apply)
DLLDirection
modelica_metatype omc_UnorderedSet_selfMap(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn);
#define boxptr_UnorderedSet_selfMap omc_UnorderedSet_selfMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_selfMap,2,0) {(void*) boxptr_UnorderedSet_selfMap,0}};
#define boxvar_UnorderedSet_selfMap MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_selfMap)
DLLDirection
modelica_metatype omc_UnorderedSet_fold(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn, modelica_metatype _startValue);
#define boxptr_UnorderedSet_fold omc_UnorderedSet_fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_fold,2,0) {(void*) boxptr_UnorderedSet_fold,0}};
#define boxvar_UnorderedSet_fold MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_fold)
DLLDirection
modelica_metatype omc_UnorderedSet_toArray(threadData_t *threadData, modelica_metatype _set);
#define boxptr_UnorderedSet_toArray omc_UnorderedSet_toArray
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_toArray,2,0) {(void*) boxptr_UnorderedSet_toArray,0}};
#define boxvar_UnorderedSet_toArray MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_toArray)
DLLDirection
modelica_metatype omc_UnorderedSet_toList(threadData_t *threadData, modelica_metatype _set);
#define boxptr_UnorderedSet_toList omc_UnorderedSet_toList
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_toList,2,0) {(void*) boxptr_UnorderedSet_toList,0}};
#define boxvar_UnorderedSet_toList MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_toList)
DLLDirection
modelica_boolean omc_UnorderedSet_isEqual(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2);
DLLDirection
modelica_metatype boxptr_UnorderedSet_isEqual(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_isEqual,2,0) {(void*) boxptr_UnorderedSet_isEqual,0}};
#define boxvar_UnorderedSet_isEqual MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_isEqual)
DLLDirection
modelica_metatype omc_UnorderedSet_first(threadData_t *threadData, modelica_metatype _set);
#define boxptr_UnorderedSet_first omc_UnorderedSet_first
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_first,2,0) {(void*) boxptr_UnorderedSet_first,0}};
#define boxvar_UnorderedSet_first MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_first)
DLLDirection
modelica_boolean omc_UnorderedSet_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
DLLDirection
modelica_metatype boxptr_UnorderedSet_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_contains,2,0) {(void*) boxptr_UnorderedSet_contains,0}};
#define boxvar_UnorderedSet_contains MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_contains)
DLLDirection
modelica_metatype omc_UnorderedSet_getOrFail(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
#define boxptr_UnorderedSet_getOrFail omc_UnorderedSet_getOrFail
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_getOrFail,2,0) {(void*) boxptr_UnorderedSet_getOrFail,0}};
#define boxvar_UnorderedSet_getOrFail MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_getOrFail)
DLLDirection
modelica_metatype omc_UnorderedSet_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
#define boxptr_UnorderedSet_get omc_UnorderedSet_get
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_get,2,0) {(void*) boxptr_UnorderedSet_get,0}};
#define boxvar_UnorderedSet_get MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_get)
DLLDirection
modelica_boolean omc_UnorderedSet_remove(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
DLLDirection
modelica_metatype boxptr_UnorderedSet_remove(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_remove,2,0) {(void*) boxptr_UnorderedSet_remove,0}};
#define boxvar_UnorderedSet_remove MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_remove)
DLLDirection
void omc_UnorderedSet_addUnique(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
#define boxptr_UnorderedSet_addUnique omc_UnorderedSet_addUnique
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_addUnique,2,0) {(void*) boxptr_UnorderedSet_addUnique,0}};
#define boxvar_UnorderedSet_addUnique MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_addUnique)
DLLDirection
void omc_UnorderedSet_addNew(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
#define boxptr_UnorderedSet_addNew omc_UnorderedSet_addNew
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_addNew,2,0) {(void*) boxptr_UnorderedSet_addNew,0}};
#define boxvar_UnorderedSet_addNew MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_addNew)
DLLDirection
modelica_boolean omc_UnorderedSet_add(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
DLLDirection
modelica_metatype boxptr_UnorderedSet_add(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_add,2,0) {(void*) boxptr_UnorderedSet_add,0}};
#define boxvar_UnorderedSet_add MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_add)
DLLDirection
modelica_metatype omc_UnorderedSet_copy(threadData_t *threadData, modelica_metatype _set);
#define boxptr_UnorderedSet_copy omc_UnorderedSet_copy
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_copy,2,0) {(void*) boxptr_UnorderedSet_copy,0}};
#define boxvar_UnorderedSet_copy MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_copy)
DLLDirection
modelica_metatype omc_UnorderedSet_fromList(threadData_t *threadData, modelica_metatype _elements, modelica_fnptr _hash, modelica_fnptr _keyEq);
#define boxptr_UnorderedSet_fromList omc_UnorderedSet_fromList
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_fromList,2,0) {(void*) boxptr_UnorderedSet_fromList,0}};
#define boxvar_UnorderedSet_fromList MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_fromList)
DLLDirection
modelica_metatype omc_UnorderedSet_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_integer _bucketCount);
DLLDirection
modelica_metatype boxptr_UnorderedSet_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_metatype _bucketCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_new,2,0) {(void*) boxptr_UnorderedSet_new,0}};
#define boxvar_UnorderedSet_new MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_new)
#ifdef __cplusplus
}
#endif
#endif

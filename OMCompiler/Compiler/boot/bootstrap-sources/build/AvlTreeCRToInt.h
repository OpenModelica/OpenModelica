#ifndef AvlTreeCRToInt__H
#define AvlTreeCRToInt__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description AvlTreeCRToInt_Tree_EMPTY__desc;
extern struct record_description AvlTreeCRToInt_Tree_LEAF__desc;
extern struct record_description AvlTreeCRToInt_Tree_NODE__desc;
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_add(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey, modelica_integer _inValue, modelica_fnptr _conflictFunc);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_add(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey, modelica_metatype _inValue, modelica_fnptr _conflictFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_add,2,0) {(void*) boxptr_AvlTreeCRToInt_add,0}};
#define boxvar_AvlTreeCRToInt_add MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_add)
DLLDirection
modelica_integer omc_AvlTreeCRToInt_addConflictDefault(threadData_t *threadData, modelica_integer _newValue, modelica_integer _oldValue, modelica_metatype _key);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_addConflictDefault(threadData_t *threadData, modelica_metatype _newValue, modelica_metatype _oldValue, modelica_metatype _key);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addConflictDefault,2,0) {(void*) boxptr_AvlTreeCRToInt_addConflictDefault,0}};
#define boxvar_AvlTreeCRToInt_addConflictDefault MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addConflictDefault)
DLLDirection
modelica_integer omc_AvlTreeCRToInt_addConflictFail(threadData_t *threadData, modelica_integer _newValue, modelica_integer _oldValue, modelica_metatype _key);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_addConflictFail(threadData_t *threadData, modelica_metatype _newValue, modelica_metatype _oldValue, modelica_metatype _key);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addConflictFail,2,0) {(void*) boxptr_AvlTreeCRToInt_addConflictFail,0}};
#define boxvar_AvlTreeCRToInt_addConflictFail MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addConflictFail)
DLLDirection
modelica_integer omc_AvlTreeCRToInt_addConflictKeep(threadData_t *threadData, modelica_integer _newValue, modelica_integer _oldValue, modelica_metatype _key);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_addConflictKeep(threadData_t *threadData, modelica_metatype _newValue, modelica_metatype _oldValue, modelica_metatype _key);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addConflictKeep,2,0) {(void*) boxptr_AvlTreeCRToInt_addConflictKeep,0}};
#define boxvar_AvlTreeCRToInt_addConflictKeep MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addConflictKeep)
DLLDirection
modelica_integer omc_AvlTreeCRToInt_addConflictReplace(threadData_t *threadData, modelica_integer _newValue, modelica_integer _oldValue, modelica_metatype _key);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_addConflictReplace(threadData_t *threadData, modelica_metatype _newValue, modelica_metatype _oldValue, modelica_metatype _key);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addConflictReplace,2,0) {(void*) boxptr_AvlTreeCRToInt_addConflictReplace,0}};
#define boxvar_AvlTreeCRToInt_addConflictReplace MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addConflictReplace)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_addList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _inValues, modelica_fnptr _conflictFunc);
#define boxptr_AvlTreeCRToInt_addList omc_AvlTreeCRToInt_addList
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addList,2,0) {(void*) boxptr_AvlTreeCRToInt_addList,0}};
#define boxvar_AvlTreeCRToInt_addList MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addList)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_addUpdate(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _key, modelica_fnptr _fn);
#define boxptr_AvlTreeCRToInt_addUpdate omc_AvlTreeCRToInt_addUpdate
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addUpdate,2,0) {(void*) boxptr_AvlTreeCRToInt_addUpdate,0}};
#define boxvar_AvlTreeCRToInt_addUpdate MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_addUpdate)
#define boxptr_AvlTreeCRToInt_balance omc_AvlTreeCRToInt_balance
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_fold(threadData_t *threadData, modelica_metatype _inTree, modelica_fnptr _inFunc, modelica_metatype _inStartValue);
#define boxptr_AvlTreeCRToInt_fold omc_AvlTreeCRToInt_fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_fold,2,0) {(void*) boxptr_AvlTreeCRToInt_fold,0}};
#define boxvar_AvlTreeCRToInt_fold MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_fold)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_foldCond(threadData_t *threadData, modelica_metatype _tree, modelica_fnptr _foldFunc, modelica_metatype __omcQ_24in_5Fvalue);
#define boxptr_AvlTreeCRToInt_foldCond omc_AvlTreeCRToInt_foldCond
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_foldCond,2,0) {(void*) boxptr_AvlTreeCRToInt_foldCond,0}};
#define boxvar_AvlTreeCRToInt_foldCond MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_foldCond)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_fold__2(threadData_t *threadData, modelica_metatype _tree, modelica_fnptr _foldFunc, modelica_metatype __omcQ_24in_5FfoldArg1, modelica_metatype __omcQ_24in_5FfoldArg2, modelica_metatype *out_foldArg2);
#define boxptr_AvlTreeCRToInt_fold__2 omc_AvlTreeCRToInt_fold__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_fold__2,2,0) {(void*) boxptr_AvlTreeCRToInt_fold__2,0}};
#define boxvar_AvlTreeCRToInt_fold__2 MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_fold__2)
DLLDirection
void omc_AvlTreeCRToInt_forEach(threadData_t *threadData, modelica_metatype _tree, modelica_fnptr _func);
#define boxptr_AvlTreeCRToInt_forEach omc_AvlTreeCRToInt_forEach
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_forEach,2,0) {(void*) boxptr_AvlTreeCRToInt_forEach,0}};
#define boxvar_AvlTreeCRToInt_forEach MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_forEach)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_fromList(threadData_t *threadData, modelica_metatype _inValues, modelica_fnptr _conflictFunc);
#define boxptr_AvlTreeCRToInt_fromList omc_AvlTreeCRToInt_fromList
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_fromList,2,0) {(void*) boxptr_AvlTreeCRToInt_fromList,0}};
#define boxvar_AvlTreeCRToInt_fromList MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_fromList)
DLLDirection
modelica_integer omc_AvlTreeCRToInt_get(threadData_t *threadData, modelica_metatype _tree, modelica_metatype _key);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_get(threadData_t *threadData, modelica_metatype _tree, modelica_metatype _key);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_get,2,0) {(void*) boxptr_AvlTreeCRToInt_get,0}};
#define boxvar_AvlTreeCRToInt_get MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_get)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_getOpt(threadData_t *threadData, modelica_metatype _tree, modelica_metatype _key);
#define boxptr_AvlTreeCRToInt_getOpt omc_AvlTreeCRToInt_getOpt
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_getOpt,2,0) {(void*) boxptr_AvlTreeCRToInt_getOpt,0}};
#define boxvar_AvlTreeCRToInt_getOpt MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_getOpt)
DLLDirection
modelica_boolean omc_AvlTreeCRToInt_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_hasKey,2,0) {(void*) boxptr_AvlTreeCRToInt_hasKey,0}};
#define boxvar_AvlTreeCRToInt_hasKey MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_hasKey)
DLLDirection
void omc_AvlTreeCRToInt_intersection(threadData_t *threadData);
#define boxptr_AvlTreeCRToInt_intersection omc_AvlTreeCRToInt_intersection
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_intersection,2,0) {(void*) boxptr_AvlTreeCRToInt_intersection,0}};
#define boxvar_AvlTreeCRToInt_intersection MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_intersection)
DLLDirection
modelica_boolean omc_AvlTreeCRToInt_isEmpty(threadData_t *threadData, modelica_metatype _tree);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_isEmpty(threadData_t *threadData, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_isEmpty,2,0) {(void*) boxptr_AvlTreeCRToInt_isEmpty,0}};
#define boxvar_AvlTreeCRToInt_isEmpty MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_isEmpty)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_join(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _treeToJoin, modelica_fnptr _conflictFunc);
#define boxptr_AvlTreeCRToInt_join omc_AvlTreeCRToInt_join
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_join,2,0) {(void*) boxptr_AvlTreeCRToInt_join,0}};
#define boxvar_AvlTreeCRToInt_join MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_join)
DLLDirection
modelica_integer omc_AvlTreeCRToInt_keyCompare(threadData_t *threadData, modelica_metatype _inKey1, modelica_metatype _inKey2);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_keyCompare(threadData_t *threadData, modelica_metatype _inKey1, modelica_metatype _inKey2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_keyCompare,2,0) {(void*) boxptr_AvlTreeCRToInt_keyCompare,0}};
#define boxvar_AvlTreeCRToInt_keyCompare MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_keyCompare)
DLLDirection
modelica_string omc_AvlTreeCRToInt_keyStr(threadData_t *threadData, modelica_metatype _inKey);
#define boxptr_AvlTreeCRToInt_keyStr omc_AvlTreeCRToInt_keyStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_keyStr,2,0) {(void*) boxptr_AvlTreeCRToInt_keyStr,0}};
#define boxvar_AvlTreeCRToInt_keyStr MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_keyStr)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_listKeys(threadData_t *threadData, modelica_metatype _tree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlTreeCRToInt_listKeys omc_AvlTreeCRToInt_listKeys
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_listKeys,2,0) {(void*) boxptr_AvlTreeCRToInt_listKeys,0}};
#define boxvar_AvlTreeCRToInt_listKeys MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_listKeys)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_listKeysReverse(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlTreeCRToInt_listKeysReverse omc_AvlTreeCRToInt_listKeysReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_listKeysReverse,2,0) {(void*) boxptr_AvlTreeCRToInt_listKeysReverse,0}};
#define boxvar_AvlTreeCRToInt_listKeysReverse MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_listKeysReverse)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_listValues(threadData_t *threadData, modelica_metatype _tree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlTreeCRToInt_listValues omc_AvlTreeCRToInt_listValues
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_listValues,2,0) {(void*) boxptr_AvlTreeCRToInt_listValues,0}};
#define boxvar_AvlTreeCRToInt_listValues MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_listValues)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_map(threadData_t *threadData, modelica_metatype _inTree, modelica_fnptr _inFunc);
#define boxptr_AvlTreeCRToInt_map omc_AvlTreeCRToInt_map
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_map,2,0) {(void*) boxptr_AvlTreeCRToInt_map,0}};
#define boxvar_AvlTreeCRToInt_map MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_map)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_mapFold(threadData_t *threadData, modelica_metatype _inTree, modelica_fnptr _inFunc, modelica_metatype _inStartValue, modelica_metatype *out_outResult);
#define boxptr_AvlTreeCRToInt_mapFold omc_AvlTreeCRToInt_mapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_mapFold,2,0) {(void*) boxptr_AvlTreeCRToInt_mapFold,0}};
#define boxvar_AvlTreeCRToInt_mapFold MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_mapFold)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_new(threadData_t *threadData);
#define boxptr_AvlTreeCRToInt_new omc_AvlTreeCRToInt_new
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_new,2,0) {(void*) boxptr_AvlTreeCRToInt_new,0}};
#define boxvar_AvlTreeCRToInt_new MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_new)
DLLDirection
modelica_string omc_AvlTreeCRToInt_printNodeStr(threadData_t *threadData, modelica_metatype _inNode);
#define boxptr_AvlTreeCRToInt_printNodeStr omc_AvlTreeCRToInt_printNodeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_printNodeStr,2,0) {(void*) boxptr_AvlTreeCRToInt_printNodeStr,0}};
#define boxvar_AvlTreeCRToInt_printNodeStr MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_printNodeStr)
DLLDirection
modelica_string omc_AvlTreeCRToInt_printTreeStr(threadData_t *threadData, modelica_metatype _inTree);
#define boxptr_AvlTreeCRToInt_printTreeStr omc_AvlTreeCRToInt_printTreeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_printTreeStr,2,0) {(void*) boxptr_AvlTreeCRToInt_printTreeStr,0}};
#define boxvar_AvlTreeCRToInt_printTreeStr MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_printTreeStr)
#define boxptr_AvlTreeCRToInt_rotateLeft omc_AvlTreeCRToInt_rotateLeft
#define boxptr_AvlTreeCRToInt_rotateRight omc_AvlTreeCRToInt_rotateRight
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_setTreeLeftRight(threadData_t *threadData, modelica_metatype _orig, modelica_metatype _left, modelica_metatype _right);
#define boxptr_AvlTreeCRToInt_setTreeLeftRight omc_AvlTreeCRToInt_setTreeLeftRight
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_setTreeLeftRight,2,0) {(void*) boxptr_AvlTreeCRToInt_setTreeLeftRight,0}};
#define boxvar_AvlTreeCRToInt_setTreeLeftRight MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_setTreeLeftRight)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_smallestKey(threadData_t *threadData, modelica_metatype _tree);
#define boxptr_AvlTreeCRToInt_smallestKey omc_AvlTreeCRToInt_smallestKey
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_smallestKey,2,0) {(void*) boxptr_AvlTreeCRToInt_smallestKey,0}};
#define boxvar_AvlTreeCRToInt_smallestKey MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_smallestKey)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_toList(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlTreeCRToInt_toList omc_AvlTreeCRToInt_toList
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_toList,2,0) {(void*) boxptr_AvlTreeCRToInt_toList,0}};
#define boxvar_AvlTreeCRToInt_toList MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_toList)
DLLDirection
modelica_metatype omc_AvlTreeCRToInt_update(threadData_t *threadData, modelica_metatype _tree, modelica_metatype _key, modelica_integer _value);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_update(threadData_t *threadData, modelica_metatype _tree, modelica_metatype _key, modelica_metatype _value);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_update,2,0) {(void*) boxptr_AvlTreeCRToInt_update,0}};
#define boxvar_AvlTreeCRToInt_update MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_update)
DLLDirection
modelica_string omc_AvlTreeCRToInt_valueStr(threadData_t *threadData, modelica_integer _inValue);
DLLDirection
modelica_metatype boxptr_AvlTreeCRToInt_valueStr(threadData_t *threadData, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_valueStr,2,0) {(void*) boxptr_AvlTreeCRToInt_valueStr,0}};
#define boxvar_AvlTreeCRToInt_valueStr MMC_REFSTRUCTLIT(boxvar_lit_AvlTreeCRToInt_valueStr)
#ifdef __cplusplus
}
#endif
#endif

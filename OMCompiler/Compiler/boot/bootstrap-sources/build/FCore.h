#ifndef FCore__H
#define FCore__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Absyn_Path_IDENT__desc;
extern struct record_description AvlSetCR_Tree_EMPTY__desc;
extern struct record_description DAE_AvlTreePathFunction_Tree_EMPTY__desc;
extern struct record_description FCore_Cache_CACHE__desc;
extern struct record_description FCore_Cache_NO__CACHE__desc;
extern struct record_description FCore_RefTree_Tree_EMPTY__desc;
extern struct record_description FCore_RefTree_Tree_LEAF__desc;
extern struct record_description FCore_RefTree_Tree_NODE__desc;
DLLExport
modelica_metatype omc_FCore_getRecordConstructorPath(threadData_t *threadData, modelica_metatype _inPath);
#define boxptr_FCore_getRecordConstructorPath omc_FCore_getRecordConstructorPath
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_getRecordConstructorPath,2,0) {(void*) boxptr_FCore_getRecordConstructorPath,0}};
#define boxvar_FCore_getRecordConstructorPath MMC_REFSTRUCTLIT(boxvar_lit_FCore_getRecordConstructorPath)
DLLExport
modelica_string omc_FCore_getRecordConstructorName(threadData_t *threadData, modelica_string _inName);
#define boxptr_FCore_getRecordConstructorName omc_FCore_getRecordConstructorName
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_getRecordConstructorName,2,0) {(void*) boxptr_FCore_getRecordConstructorName,0}};
#define boxvar_FCore_getRecordConstructorName MMC_REFSTRUCTLIT(boxvar_lit_FCore_getRecordConstructorName)
DLLExport
modelica_metatype omc_FCore_setCachedInitialGraph(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcache, modelica_metatype _g);
#define boxptr_FCore_setCachedInitialGraph omc_FCore_setCachedInitialGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_setCachedInitialGraph,2,0) {(void*) boxptr_FCore_setCachedInitialGraph,0}};
#define boxvar_FCore_setCachedInitialGraph MMC_REFSTRUCTLIT(boxvar_lit_FCore_setCachedInitialGraph)
DLLExport
modelica_metatype omc_FCore_getCachedInitialGraph(threadData_t *threadData, modelica_metatype _cache);
#define boxptr_FCore_getCachedInitialGraph omc_FCore_getCachedInitialGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_getCachedInitialGraph,2,0) {(void*) boxptr_FCore_getCachedInitialGraph,0}};
#define boxvar_FCore_getCachedInitialGraph MMC_REFSTRUCTLIT(boxvar_lit_FCore_getCachedInitialGraph)
DLLExport
modelica_boolean omc_FCore_isDeletedComp(threadData_t *threadData, modelica_metatype _status);
DLLExport
modelica_metatype boxptr_FCore_isDeletedComp(threadData_t *threadData, modelica_metatype _status);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_isDeletedComp,2,0) {(void*) boxptr_FCore_isDeletedComp,0}};
#define boxvar_FCore_isDeletedComp MMC_REFSTRUCTLIT(boxvar_lit_FCore_isDeletedComp)
DLLExport
modelica_boolean omc_FCore_isTyped(threadData_t *threadData, modelica_metatype _is);
DLLExport
modelica_metatype boxptr_FCore_isTyped(threadData_t *threadData, modelica_metatype _is);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_isTyped,2,0) {(void*) boxptr_FCore_isTyped,0}};
#define boxvar_FCore_isTyped MMC_REFSTRUCTLIT(boxvar_lit_FCore_isTyped)
DLLExport
void omc_FCore_setCachedFunctionTree(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inFunctions);
#define boxptr_FCore_setCachedFunctionTree omc_FCore_setCachedFunctionTree
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_setCachedFunctionTree,2,0) {(void*) boxptr_FCore_setCachedFunctionTree,0}};
#define boxvar_FCore_setCachedFunctionTree MMC_REFSTRUCTLIT(boxvar_lit_FCore_setCachedFunctionTree)
DLLExport
modelica_metatype omc_FCore_addDaeExtFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _funcs);
#define boxptr_FCore_addDaeExtFunction omc_FCore_addDaeExtFunction
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_addDaeExtFunction,2,0) {(void*) boxptr_FCore_addDaeExtFunction,0}};
#define boxvar_FCore_addDaeExtFunction MMC_REFSTRUCTLIT(boxvar_lit_FCore_addDaeExtFunction)
DLLExport
modelica_metatype omc_FCore_addDaeFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _funcs);
#define boxptr_FCore_addDaeFunction omc_FCore_addDaeFunction
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_addDaeFunction,2,0) {(void*) boxptr_FCore_addDaeFunction,0}};
#define boxvar_FCore_addDaeFunction MMC_REFSTRUCTLIT(boxvar_lit_FCore_addDaeFunction)
DLLExport
modelica_metatype omc_FCore_addCachedInstFuncGuard(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _func);
#define boxptr_FCore_addCachedInstFuncGuard omc_FCore_addCachedInstFuncGuard
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_addCachedInstFuncGuard,2,0) {(void*) boxptr_FCore_addCachedInstFuncGuard,0}};
#define boxvar_FCore_addCachedInstFuncGuard MMC_REFSTRUCTLIT(boxvar_lit_FCore_addCachedInstFuncGuard)
DLLExport
modelica_metatype omc_FCore_getFunctionTree(threadData_t *threadData, modelica_metatype _cache);
#define boxptr_FCore_getFunctionTree omc_FCore_getFunctionTree
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_getFunctionTree,2,0) {(void*) boxptr_FCore_getFunctionTree,0}};
#define boxvar_FCore_getFunctionTree MMC_REFSTRUCTLIT(boxvar_lit_FCore_getFunctionTree)
DLLExport
void omc_FCore_checkCachedInstFuncGuard(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _path);
#define boxptr_FCore_checkCachedInstFuncGuard omc_FCore_checkCachedInstFuncGuard
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_checkCachedInstFuncGuard,2,0) {(void*) boxptr_FCore_checkCachedInstFuncGuard,0}};
#define boxvar_FCore_checkCachedInstFuncGuard MMC_REFSTRUCTLIT(boxvar_lit_FCore_checkCachedInstFuncGuard)
DLLExport
modelica_metatype omc_FCore_getCachedInstFunc(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _path);
#define boxptr_FCore_getCachedInstFunc omc_FCore_getCachedInstFunc
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_getCachedInstFunc,2,0) {(void*) boxptr_FCore_getCachedInstFunc,0}};
#define boxvar_FCore_getCachedInstFunc MMC_REFSTRUCTLIT(boxvar_lit_FCore_getCachedInstFunc)
DLLExport
modelica_boolean omc_FCore_isImplicitScope(threadData_t *threadData, modelica_string _inName);
DLLExport
modelica_metatype boxptr_FCore_isImplicitScope(threadData_t *threadData, modelica_metatype _inName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_isImplicitScope,2,0) {(void*) boxptr_FCore_isImplicitScope,0}};
#define boxvar_FCore_isImplicitScope MMC_REFSTRUCTLIT(boxvar_lit_FCore_isImplicitScope)
DLLExport
modelica_metatype omc_FCore_setCacheClassName(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _p);
#define boxptr_FCore_setCacheClassName omc_FCore_setCacheClassName
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_setCacheClassName,2,0) {(void*) boxptr_FCore_setCacheClassName,0}};
#define boxvar_FCore_setCacheClassName MMC_REFSTRUCTLIT(boxvar_lit_FCore_setCacheClassName)
DLLExport
void omc_FCore_printNumStructuralParameters(threadData_t *threadData, modelica_metatype _cache);
#define boxptr_FCore_printNumStructuralParameters omc_FCore_printNumStructuralParameters
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_printNumStructuralParameters,2,0) {(void*) boxptr_FCore_printNumStructuralParameters,0}};
#define boxvar_FCore_printNumStructuralParameters MMC_REFSTRUCTLIT(boxvar_lit_FCore_printNumStructuralParameters)
DLLExport
modelica_metatype omc_FCore_getEvaluatedParams(threadData_t *threadData, modelica_metatype _cache);
#define boxptr_FCore_getEvaluatedParams omc_FCore_getEvaluatedParams
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_getEvaluatedParams,2,0) {(void*) boxptr_FCore_getEvaluatedParams,0}};
#define boxvar_FCore_getEvaluatedParams MMC_REFSTRUCTLIT(boxvar_lit_FCore_getEvaluatedParams)
DLLExport
modelica_metatype omc_FCore_addEvaluatedCref(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _var, modelica_metatype _cr);
#define boxptr_FCore_addEvaluatedCref omc_FCore_addEvaluatedCref
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_addEvaluatedCref,2,0) {(void*) boxptr_FCore_addEvaluatedCref,0}};
#define boxvar_FCore_addEvaluatedCref MMC_REFSTRUCTLIT(boxvar_lit_FCore_addEvaluatedCref)
DLLExport
modelica_metatype omc_FCore_noCache(threadData_t *threadData);
#define boxptr_FCore_noCache omc_FCore_noCache
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_noCache,2,0) {(void*) boxptr_FCore_noCache,0}};
#define boxvar_FCore_noCache MMC_REFSTRUCTLIT(boxvar_lit_FCore_noCache)
DLLExport
modelica_metatype omc_FCore_emptyCache(threadData_t *threadData);
#define boxptr_FCore_emptyCache omc_FCore_emptyCache
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_emptyCache,2,0) {(void*) boxptr_FCore_emptyCache,0}};
#define boxvar_FCore_emptyCache MMC_REFSTRUCTLIT(boxvar_lit_FCore_emptyCache)
DLLExport
modelica_integer omc_FCore_next(threadData_t *threadData, modelica_integer _inext);
DLLExport
modelica_metatype boxptr_FCore_next(threadData_t *threadData, modelica_metatype _inext);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_next,2,0) {(void*) boxptr_FCore_next,0}};
#define boxvar_FCore_next MMC_REFSTRUCTLIT(boxvar_lit_FCore_next)
DLLExport
modelica_metatype omc_FCore_RefTree_add(threadData_t *threadData, modelica_metatype _inTree, modelica_string _inKey, modelica_metatype _inValue, modelica_fnptr _conflictFunc);
#define boxptr_FCore_RefTree_add omc_FCore_RefTree_add
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_add,2,0) {(void*) boxptr_FCore_RefTree_add,0}};
#define boxvar_FCore_RefTree_add MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_add)
DLLExport
modelica_metatype omc_FCore_RefTree_addConflictDefault(threadData_t *threadData, modelica_metatype _newValue, modelica_metatype _oldValue, modelica_string _key);
#define boxptr_FCore_RefTree_addConflictDefault omc_FCore_RefTree_addConflictDefault
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_addConflictDefault,2,0) {(void*) boxptr_FCore_RefTree_addConflictDefault,0}};
#define boxvar_FCore_RefTree_addConflictDefault MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_addConflictDefault)
DLLExport
modelica_metatype omc_FCore_RefTree_addConflictFail(threadData_t *threadData, modelica_metatype _newValue, modelica_metatype _oldValue, modelica_string _key);
#define boxptr_FCore_RefTree_addConflictFail omc_FCore_RefTree_addConflictFail
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_addConflictFail,2,0) {(void*) boxptr_FCore_RefTree_addConflictFail,0}};
#define boxvar_FCore_RefTree_addConflictFail MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_addConflictFail)
DLLExport
modelica_metatype omc_FCore_RefTree_addConflictKeep(threadData_t *threadData, modelica_metatype _newValue, modelica_metatype _oldValue, modelica_string _key);
#define boxptr_FCore_RefTree_addConflictKeep omc_FCore_RefTree_addConflictKeep
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_addConflictKeep,2,0) {(void*) boxptr_FCore_RefTree_addConflictKeep,0}};
#define boxvar_FCore_RefTree_addConflictKeep MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_addConflictKeep)
DLLExport
modelica_metatype omc_FCore_RefTree_addConflictReplace(threadData_t *threadData, modelica_metatype _newValue, modelica_metatype _oldValue, modelica_string _key);
#define boxptr_FCore_RefTree_addConflictReplace omc_FCore_RefTree_addConflictReplace
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_addConflictReplace,2,0) {(void*) boxptr_FCore_RefTree_addConflictReplace,0}};
#define boxvar_FCore_RefTree_addConflictReplace MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_addConflictReplace)
DLLExport
modelica_metatype omc_FCore_RefTree_addList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _inValues, modelica_fnptr _conflictFunc);
#define boxptr_FCore_RefTree_addList omc_FCore_RefTree_addList
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_addList,2,0) {(void*) boxptr_FCore_RefTree_addList,0}};
#define boxvar_FCore_RefTree_addList MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_addList)
#define boxptr_FCore_RefTree_balance omc_FCore_RefTree_balance
DLLExport
modelica_metatype omc_FCore_RefTree_fold(threadData_t *threadData, modelica_metatype _inTree, modelica_fnptr _inFunc, modelica_metatype _inStartValue);
#define boxptr_FCore_RefTree_fold omc_FCore_RefTree_fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_fold,2,0) {(void*) boxptr_FCore_RefTree_fold,0}};
#define boxvar_FCore_RefTree_fold MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_fold)
DLLExport
modelica_metatype omc_FCore_RefTree_foldCond(threadData_t *threadData, modelica_metatype _tree, modelica_fnptr _foldFunc, modelica_metatype __omcQ_24in_5Fvalue);
#define boxptr_FCore_RefTree_foldCond omc_FCore_RefTree_foldCond
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_foldCond,2,0) {(void*) boxptr_FCore_RefTree_foldCond,0}};
#define boxvar_FCore_RefTree_foldCond MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_foldCond)
DLLExport
modelica_metatype omc_FCore_RefTree_fold__2(threadData_t *threadData, modelica_metatype _tree, modelica_fnptr _foldFunc, modelica_metatype __omcQ_24in_5FfoldArg1, modelica_metatype __omcQ_24in_5FfoldArg2, modelica_metatype *out_foldArg2);
#define boxptr_FCore_RefTree_fold__2 omc_FCore_RefTree_fold__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_fold__2,2,0) {(void*) boxptr_FCore_RefTree_fold__2,0}};
#define boxvar_FCore_RefTree_fold__2 MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_fold__2)
DLLExport
void omc_FCore_RefTree_forEach(threadData_t *threadData, modelica_metatype _tree, modelica_fnptr _func);
#define boxptr_FCore_RefTree_forEach omc_FCore_RefTree_forEach
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_forEach,2,0) {(void*) boxptr_FCore_RefTree_forEach,0}};
#define boxvar_FCore_RefTree_forEach MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_forEach)
DLLExport
modelica_metatype omc_FCore_RefTree_fromList(threadData_t *threadData, modelica_metatype _inValues, modelica_fnptr _conflictFunc);
#define boxptr_FCore_RefTree_fromList omc_FCore_RefTree_fromList
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_fromList,2,0) {(void*) boxptr_FCore_RefTree_fromList,0}};
#define boxvar_FCore_RefTree_fromList MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_fromList)
DLLExport
modelica_metatype omc_FCore_RefTree_get(threadData_t *threadData, modelica_metatype _tree, modelica_string _key);
#define boxptr_FCore_RefTree_get omc_FCore_RefTree_get
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_get,2,0) {(void*) boxptr_FCore_RefTree_get,0}};
#define boxvar_FCore_RefTree_get MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_get)
DLLExport
modelica_metatype omc_FCore_RefTree_getOpt(threadData_t *threadData, modelica_metatype _tree, modelica_string _key);
#define boxptr_FCore_RefTree_getOpt omc_FCore_RefTree_getOpt
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_getOpt,2,0) {(void*) boxptr_FCore_RefTree_getOpt,0}};
#define boxvar_FCore_RefTree_getOpt MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_getOpt)
DLLExport
modelica_boolean omc_FCore_RefTree_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_string _inKey);
DLLExport
modelica_metatype boxptr_FCore_RefTree_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_hasKey,2,0) {(void*) boxptr_FCore_RefTree_hasKey,0}};
#define boxvar_FCore_RefTree_hasKey MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_hasKey)
DLLExport
void omc_FCore_RefTree_intersection(threadData_t *threadData);
#define boxptr_FCore_RefTree_intersection omc_FCore_RefTree_intersection
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_intersection,2,0) {(void*) boxptr_FCore_RefTree_intersection,0}};
#define boxvar_FCore_RefTree_intersection MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_intersection)
DLLExport
modelica_boolean omc_FCore_RefTree_isEmpty(threadData_t *threadData, modelica_metatype _tree);
DLLExport
modelica_metatype boxptr_FCore_RefTree_isEmpty(threadData_t *threadData, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_isEmpty,2,0) {(void*) boxptr_FCore_RefTree_isEmpty,0}};
#define boxvar_FCore_RefTree_isEmpty MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_isEmpty)
DLLExport
modelica_metatype omc_FCore_RefTree_join(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _treeToJoin, modelica_fnptr _conflictFunc);
#define boxptr_FCore_RefTree_join omc_FCore_RefTree_join
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_join,2,0) {(void*) boxptr_FCore_RefTree_join,0}};
#define boxvar_FCore_RefTree_join MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_join)
DLLExport
modelica_integer omc_FCore_RefTree_keyCompare(threadData_t *threadData, modelica_string _inKey1, modelica_string _inKey2);
DLLExport
modelica_metatype boxptr_FCore_RefTree_keyCompare(threadData_t *threadData, modelica_metatype _inKey1, modelica_metatype _inKey2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_keyCompare,2,0) {(void*) boxptr_FCore_RefTree_keyCompare,0}};
#define boxvar_FCore_RefTree_keyCompare MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_keyCompare)
DLLExport
modelica_string omc_FCore_RefTree_keyStr(threadData_t *threadData, modelica_string _inKey);
#define boxptr_FCore_RefTree_keyStr omc_FCore_RefTree_keyStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_keyStr,2,0) {(void*) boxptr_FCore_RefTree_keyStr,0}};
#define boxvar_FCore_RefTree_keyStr MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_keyStr)
DLLExport
modelica_metatype omc_FCore_RefTree_listKeys(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_FCore_RefTree_listKeys omc_FCore_RefTree_listKeys
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_listKeys,2,0) {(void*) boxptr_FCore_RefTree_listKeys,0}};
#define boxvar_FCore_RefTree_listKeys MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_listKeys)
DLLExport
modelica_metatype omc_FCore_RefTree_listKeysReverse(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_FCore_RefTree_listKeysReverse omc_FCore_RefTree_listKeysReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_listKeysReverse,2,0) {(void*) boxptr_FCore_RefTree_listKeysReverse,0}};
#define boxvar_FCore_RefTree_listKeysReverse MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_listKeysReverse)
DLLExport
modelica_metatype omc_FCore_RefTree_listValues(threadData_t *threadData, modelica_metatype _tree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_FCore_RefTree_listValues omc_FCore_RefTree_listValues
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_listValues,2,0) {(void*) boxptr_FCore_RefTree_listValues,0}};
#define boxvar_FCore_RefTree_listValues MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_listValues)
DLLExport
modelica_metatype omc_FCore_RefTree_map(threadData_t *threadData, modelica_metatype _inTree, modelica_fnptr _inFunc);
#define boxptr_FCore_RefTree_map omc_FCore_RefTree_map
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_map,2,0) {(void*) boxptr_FCore_RefTree_map,0}};
#define boxvar_FCore_RefTree_map MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_map)
DLLExport
modelica_metatype omc_FCore_RefTree_mapFold(threadData_t *threadData, modelica_metatype _inTree, modelica_fnptr _inFunc, modelica_metatype _inStartValue, modelica_metatype *out_outResult);
#define boxptr_FCore_RefTree_mapFold omc_FCore_RefTree_mapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_mapFold,2,0) {(void*) boxptr_FCore_RefTree_mapFold,0}};
#define boxvar_FCore_RefTree_mapFold MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_mapFold)
DLLExport
modelica_metatype omc_FCore_RefTree_new(threadData_t *threadData);
#define boxptr_FCore_RefTree_new omc_FCore_RefTree_new
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_new,2,0) {(void*) boxptr_FCore_RefTree_new,0}};
#define boxvar_FCore_RefTree_new MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_new)
DLLExport
modelica_string omc_FCore_RefTree_printNodeStr(threadData_t *threadData, modelica_metatype _inNode);
#define boxptr_FCore_RefTree_printNodeStr omc_FCore_RefTree_printNodeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_printNodeStr,2,0) {(void*) boxptr_FCore_RefTree_printNodeStr,0}};
#define boxvar_FCore_RefTree_printNodeStr MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_printNodeStr)
DLLExport
modelica_string omc_FCore_RefTree_printTreeStr(threadData_t *threadData, modelica_metatype _inTree);
#define boxptr_FCore_RefTree_printTreeStr omc_FCore_RefTree_printTreeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_printTreeStr,2,0) {(void*) boxptr_FCore_RefTree_printTreeStr,0}};
#define boxvar_FCore_RefTree_printTreeStr MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_printTreeStr)
#define boxptr_FCore_RefTree_rotateLeft omc_FCore_RefTree_rotateLeft
#define boxptr_FCore_RefTree_rotateRight omc_FCore_RefTree_rotateRight
DLLExport
modelica_metatype omc_FCore_RefTree_setTreeLeftRight(threadData_t *threadData, modelica_metatype _orig, modelica_metatype _left, modelica_metatype _right);
#define boxptr_FCore_RefTree_setTreeLeftRight omc_FCore_RefTree_setTreeLeftRight
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_setTreeLeftRight,2,0) {(void*) boxptr_FCore_RefTree_setTreeLeftRight,0}};
#define boxvar_FCore_RefTree_setTreeLeftRight MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_setTreeLeftRight)
DLLExport
modelica_metatype omc_FCore_RefTree_toList(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_FCore_RefTree_toList omc_FCore_RefTree_toList
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_toList,2,0) {(void*) boxptr_FCore_RefTree_toList,0}};
#define boxvar_FCore_RefTree_toList MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_toList)
DLLExport
modelica_metatype omc_FCore_RefTree_update(threadData_t *threadData, modelica_metatype _tree, modelica_string _key, modelica_metatype _value);
#define boxptr_FCore_RefTree_update omc_FCore_RefTree_update
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_update,2,0) {(void*) boxptr_FCore_RefTree_update,0}};
#define boxvar_FCore_RefTree_update MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_update)
DLLExport
modelica_string omc_FCore_RefTree_valueStr(threadData_t *threadData, modelica_metatype _inValue);
#define boxptr_FCore_RefTree_valueStr omc_FCore_RefTree_valueStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FCore_RefTree_valueStr,2,0) {(void*) boxptr_FCore_RefTree_valueStr,0}};
#define boxvar_FCore_RefTree_valueStr MMC_REFSTRUCTLIT(boxvar_lit_FCore_RefTree_valueStr)
#ifdef __cplusplus
}
#endif
#endif

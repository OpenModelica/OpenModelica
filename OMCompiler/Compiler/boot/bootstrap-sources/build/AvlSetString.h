#ifndef AvlSetString__H
#define AvlSetString__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description AvlSetString_Tree_EMPTY__desc;
extern struct record_description AvlSetString_Tree_LEAF__desc;
extern struct record_description AvlSetString_Tree_NODE__desc;
DLLExport
modelica_metatype omc_AvlSetString_add(threadData_t *threadData, modelica_metatype _inTree, modelica_string _inKey);
#define boxptr_AvlSetString_add omc_AvlSetString_add
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_add,2,0) {(void*) boxptr_AvlSetString_add,0}};
#define boxvar_AvlSetString_add MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_add)
DLLExport
modelica_metatype omc_AvlSetString_addList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _inValues);
#define boxptr_AvlSetString_addList omc_AvlSetString_addList
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_addList,2,0) {(void*) boxptr_AvlSetString_addList,0}};
#define boxvar_AvlSetString_addList MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_addList)
#define boxptr_AvlSetString_balance omc_AvlSetString_balance
DLLExport
modelica_boolean omc_AvlSetString_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_string _inKey);
DLLExport
modelica_metatype boxptr_AvlSetString_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_hasKey,2,0) {(void*) boxptr_AvlSetString_hasKey,0}};
#define boxvar_AvlSetString_hasKey MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_hasKey)
DLLExport
modelica_metatype omc_AvlSetString_intersection(threadData_t *threadData, modelica_metatype _tree1, modelica_metatype _tree2, modelica_metatype *out_rest1, modelica_metatype *out_rest2);
#define boxptr_AvlSetString_intersection omc_AvlSetString_intersection
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_intersection,2,0) {(void*) boxptr_AvlSetString_intersection,0}};
#define boxvar_AvlSetString_intersection MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_intersection)
DLLExport
modelica_boolean omc_AvlSetString_isEmpty(threadData_t *threadData, modelica_metatype _tree);
DLLExport
modelica_metatype boxptr_AvlSetString_isEmpty(threadData_t *threadData, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_isEmpty,2,0) {(void*) boxptr_AvlSetString_isEmpty,0}};
#define boxvar_AvlSetString_isEmpty MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_isEmpty)
DLLExport
modelica_metatype omc_AvlSetString_join(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _treeToJoin);
#define boxptr_AvlSetString_join omc_AvlSetString_join
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_join,2,0) {(void*) boxptr_AvlSetString_join,0}};
#define boxvar_AvlSetString_join MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_join)
DLLExport
modelica_integer omc_AvlSetString_keyCompare(threadData_t *threadData, modelica_string _inKey1, modelica_string _inKey2);
DLLExport
modelica_metatype boxptr_AvlSetString_keyCompare(threadData_t *threadData, modelica_metatype _inKey1, modelica_metatype _inKey2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_keyCompare,2,0) {(void*) boxptr_AvlSetString_keyCompare,0}};
#define boxvar_AvlSetString_keyCompare MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_keyCompare)
DLLExport
modelica_string omc_AvlSetString_keyStr(threadData_t *threadData, modelica_string _inKey);
#define boxptr_AvlSetString_keyStr omc_AvlSetString_keyStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_keyStr,2,0) {(void*) boxptr_AvlSetString_keyStr,0}};
#define boxvar_AvlSetString_keyStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_keyStr)
DLLExport
modelica_metatype omc_AvlSetString_listKeys(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlSetString_listKeys omc_AvlSetString_listKeys
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_listKeys,2,0) {(void*) boxptr_AvlSetString_listKeys,0}};
#define boxvar_AvlSetString_listKeys MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_listKeys)
DLLExport
modelica_metatype omc_AvlSetString_listKeysReverse(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlSetString_listKeysReverse omc_AvlSetString_listKeysReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_listKeysReverse,2,0) {(void*) boxptr_AvlSetString_listKeysReverse,0}};
#define boxvar_AvlSetString_listKeysReverse MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_listKeysReverse)
DLLExport
modelica_metatype omc_AvlSetString_new(threadData_t *threadData);
#define boxptr_AvlSetString_new omc_AvlSetString_new
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_new,2,0) {(void*) boxptr_AvlSetString_new,0}};
#define boxvar_AvlSetString_new MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_new)
DLLExport
modelica_string omc_AvlSetString_printNodeStr(threadData_t *threadData, modelica_metatype _inNode);
#define boxptr_AvlSetString_printNodeStr omc_AvlSetString_printNodeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_printNodeStr,2,0) {(void*) boxptr_AvlSetString_printNodeStr,0}};
#define boxvar_AvlSetString_printNodeStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_printNodeStr)
DLLExport
modelica_string omc_AvlSetString_printTreeStr(threadData_t *threadData, modelica_metatype _inTree);
#define boxptr_AvlSetString_printTreeStr omc_AvlSetString_printTreeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_printTreeStr,2,0) {(void*) boxptr_AvlSetString_printTreeStr,0}};
#define boxvar_AvlSetString_printTreeStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_printTreeStr)
#define boxptr_AvlSetString_rotateLeft omc_AvlSetString_rotateLeft
#define boxptr_AvlSetString_rotateRight omc_AvlSetString_rotateRight
DLLExport
modelica_metatype omc_AvlSetString_setTreeLeftRight(threadData_t *threadData, modelica_metatype _orig, modelica_metatype _left, modelica_metatype _right);
#define boxptr_AvlSetString_setTreeLeftRight omc_AvlSetString_setTreeLeftRight
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetString_setTreeLeftRight,2,0) {(void*) boxptr_AvlSetString_setTreeLeftRight,0}};
#define boxvar_AvlSetString_setTreeLeftRight MMC_REFSTRUCTLIT(boxvar_lit_AvlSetString_setTreeLeftRight)
#ifdef __cplusplus
}
#endif
#endif

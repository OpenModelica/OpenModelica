#ifndef AvlSetCR__H
#define AvlSetCR__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description AvlSetCR_Tree_EMPTY__desc;
extern struct record_description AvlSetCR_Tree_LEAF__desc;
extern struct record_description AvlSetCR_Tree_NODE__desc;
DLLExport
modelica_metatype omc_AvlSetCR_add(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
#define boxptr_AvlSetCR_add omc_AvlSetCR_add
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_add,2,0) {(void*) boxptr_AvlSetCR_add,0}};
#define boxvar_AvlSetCR_add MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_add)
DLLExport
modelica_metatype omc_AvlSetCR_addList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _inValues);
#define boxptr_AvlSetCR_addList omc_AvlSetCR_addList
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_addList,2,0) {(void*) boxptr_AvlSetCR_addList,0}};
#define boxvar_AvlSetCR_addList MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_addList)
#define boxptr_AvlSetCR_balance omc_AvlSetCR_balance
DLLExport
modelica_boolean omc_AvlSetCR_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
DLLExport
modelica_metatype boxptr_AvlSetCR_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_hasKey,2,0) {(void*) boxptr_AvlSetCR_hasKey,0}};
#define boxvar_AvlSetCR_hasKey MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_hasKey)
DLLExport
modelica_metatype omc_AvlSetCR_intersection(threadData_t *threadData, modelica_metatype _tree1, modelica_metatype _tree2, modelica_metatype *out_rest1, modelica_metatype *out_rest2);
#define boxptr_AvlSetCR_intersection omc_AvlSetCR_intersection
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_intersection,2,0) {(void*) boxptr_AvlSetCR_intersection,0}};
#define boxvar_AvlSetCR_intersection MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_intersection)
DLLExport
modelica_boolean omc_AvlSetCR_isEmpty(threadData_t *threadData, modelica_metatype _tree);
DLLExport
modelica_metatype boxptr_AvlSetCR_isEmpty(threadData_t *threadData, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_isEmpty,2,0) {(void*) boxptr_AvlSetCR_isEmpty,0}};
#define boxvar_AvlSetCR_isEmpty MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_isEmpty)
DLLExport
modelica_metatype omc_AvlSetCR_join(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _treeToJoin);
#define boxptr_AvlSetCR_join omc_AvlSetCR_join
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_join,2,0) {(void*) boxptr_AvlSetCR_join,0}};
#define boxvar_AvlSetCR_join MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_join)
DLLExport
modelica_integer omc_AvlSetCR_keyCompare(threadData_t *threadData, modelica_metatype _inKey1, modelica_metatype _inKey2);
DLLExport
modelica_metatype boxptr_AvlSetCR_keyCompare(threadData_t *threadData, modelica_metatype _inKey1, modelica_metatype _inKey2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_keyCompare,2,0) {(void*) boxptr_AvlSetCR_keyCompare,0}};
#define boxvar_AvlSetCR_keyCompare MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_keyCompare)
DLLExport
modelica_string omc_AvlSetCR_keyStr(threadData_t *threadData, modelica_metatype _inKey);
#define boxptr_AvlSetCR_keyStr omc_AvlSetCR_keyStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_keyStr,2,0) {(void*) boxptr_AvlSetCR_keyStr,0}};
#define boxvar_AvlSetCR_keyStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_keyStr)
DLLExport
modelica_metatype omc_AvlSetCR_listKeys(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlSetCR_listKeys omc_AvlSetCR_listKeys
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_listKeys,2,0) {(void*) boxptr_AvlSetCR_listKeys,0}};
#define boxvar_AvlSetCR_listKeys MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_listKeys)
DLLExport
modelica_metatype omc_AvlSetCR_listKeysReverse(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlSetCR_listKeysReverse omc_AvlSetCR_listKeysReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_listKeysReverse,2,0) {(void*) boxptr_AvlSetCR_listKeysReverse,0}};
#define boxvar_AvlSetCR_listKeysReverse MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_listKeysReverse)
DLLExport
modelica_metatype omc_AvlSetCR_new(threadData_t *threadData);
#define boxptr_AvlSetCR_new omc_AvlSetCR_new
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_new,2,0) {(void*) boxptr_AvlSetCR_new,0}};
#define boxvar_AvlSetCR_new MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_new)
DLLExport
modelica_string omc_AvlSetCR_printNodeStr(threadData_t *threadData, modelica_metatype _inNode);
#define boxptr_AvlSetCR_printNodeStr omc_AvlSetCR_printNodeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_printNodeStr,2,0) {(void*) boxptr_AvlSetCR_printNodeStr,0}};
#define boxvar_AvlSetCR_printNodeStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_printNodeStr)
DLLExport
modelica_string omc_AvlSetCR_printTreeStr(threadData_t *threadData, modelica_metatype _inTree);
#define boxptr_AvlSetCR_printTreeStr omc_AvlSetCR_printTreeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_printTreeStr,2,0) {(void*) boxptr_AvlSetCR_printTreeStr,0}};
#define boxvar_AvlSetCR_printTreeStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_printTreeStr)
#define boxptr_AvlSetCR_rotateLeft omc_AvlSetCR_rotateLeft
#define boxptr_AvlSetCR_rotateRight omc_AvlSetCR_rotateRight
DLLExport
modelica_metatype omc_AvlSetCR_setTreeLeftRight(threadData_t *threadData, modelica_metatype _orig, modelica_metatype _left, modelica_metatype _right);
#define boxptr_AvlSetCR_setTreeLeftRight omc_AvlSetCR_setTreeLeftRight
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetCR_setTreeLeftRight,2,0) {(void*) boxptr_AvlSetCR_setTreeLeftRight,0}};
#define boxvar_AvlSetCR_setTreeLeftRight MMC_REFSTRUCTLIT(boxvar_lit_AvlSetCR_setTreeLeftRight)
#ifdef __cplusplus
}
#endif
#endif

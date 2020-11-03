#ifndef AvlSetPath__H
#define AvlSetPath__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description AvlSetPath_Tree_EMPTY__desc;
extern struct record_description AvlSetPath_Tree_LEAF__desc;
extern struct record_description AvlSetPath_Tree_NODE__desc;
DLLExport
modelica_metatype omc_AvlSetPath_add(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
#define boxptr_AvlSetPath_add omc_AvlSetPath_add
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_add,2,0) {(void*) boxptr_AvlSetPath_add,0}};
#define boxvar_AvlSetPath_add MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_add)
DLLExport
modelica_metatype omc_AvlSetPath_addList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _inValues);
#define boxptr_AvlSetPath_addList omc_AvlSetPath_addList
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_addList,2,0) {(void*) boxptr_AvlSetPath_addList,0}};
#define boxvar_AvlSetPath_addList MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_addList)
#define boxptr_AvlSetPath_balance omc_AvlSetPath_balance
DLLExport
modelica_boolean omc_AvlSetPath_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
DLLExport
modelica_metatype boxptr_AvlSetPath_hasKey(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype _inKey);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_hasKey,2,0) {(void*) boxptr_AvlSetPath_hasKey,0}};
#define boxvar_AvlSetPath_hasKey MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_hasKey)
DLLExport
modelica_metatype omc_AvlSetPath_intersection(threadData_t *threadData, modelica_metatype _tree1, modelica_metatype _tree2, modelica_metatype *out_rest1, modelica_metatype *out_rest2);
#define boxptr_AvlSetPath_intersection omc_AvlSetPath_intersection
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_intersection,2,0) {(void*) boxptr_AvlSetPath_intersection,0}};
#define boxvar_AvlSetPath_intersection MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_intersection)
DLLExport
modelica_boolean omc_AvlSetPath_isEmpty(threadData_t *threadData, modelica_metatype _tree);
DLLExport
modelica_metatype boxptr_AvlSetPath_isEmpty(threadData_t *threadData, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_isEmpty,2,0) {(void*) boxptr_AvlSetPath_isEmpty,0}};
#define boxvar_AvlSetPath_isEmpty MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_isEmpty)
DLLExport
modelica_metatype omc_AvlSetPath_join(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ftree, modelica_metatype _treeToJoin);
#define boxptr_AvlSetPath_join omc_AvlSetPath_join
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_join,2,0) {(void*) boxptr_AvlSetPath_join,0}};
#define boxvar_AvlSetPath_join MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_join)
DLLExport
modelica_integer omc_AvlSetPath_keyCompare(threadData_t *threadData, modelica_metatype _inKey1, modelica_metatype _inKey2);
DLLExport
modelica_metatype boxptr_AvlSetPath_keyCompare(threadData_t *threadData, modelica_metatype _inKey1, modelica_metatype _inKey2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_keyCompare,2,0) {(void*) boxptr_AvlSetPath_keyCompare,0}};
#define boxvar_AvlSetPath_keyCompare MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_keyCompare)
DLLExport
modelica_string omc_AvlSetPath_keyStr(threadData_t *threadData, modelica_metatype _inKey);
#define boxptr_AvlSetPath_keyStr omc_AvlSetPath_keyStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_keyStr,2,0) {(void*) boxptr_AvlSetPath_keyStr,0}};
#define boxvar_AvlSetPath_keyStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_keyStr)
DLLExport
modelica_metatype omc_AvlSetPath_listKeys(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlSetPath_listKeys omc_AvlSetPath_listKeys
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_listKeys,2,0) {(void*) boxptr_AvlSetPath_listKeys,0}};
#define boxvar_AvlSetPath_listKeys MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_listKeys)
DLLExport
modelica_metatype omc_AvlSetPath_listKeysReverse(threadData_t *threadData, modelica_metatype _inTree, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_AvlSetPath_listKeysReverse omc_AvlSetPath_listKeysReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_listKeysReverse,2,0) {(void*) boxptr_AvlSetPath_listKeysReverse,0}};
#define boxvar_AvlSetPath_listKeysReverse MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_listKeysReverse)
DLLExport
modelica_metatype omc_AvlSetPath_new(threadData_t *threadData);
#define boxptr_AvlSetPath_new omc_AvlSetPath_new
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_new,2,0) {(void*) boxptr_AvlSetPath_new,0}};
#define boxvar_AvlSetPath_new MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_new)
DLLExport
modelica_string omc_AvlSetPath_printNodeStr(threadData_t *threadData, modelica_metatype _inNode);
#define boxptr_AvlSetPath_printNodeStr omc_AvlSetPath_printNodeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_printNodeStr,2,0) {(void*) boxptr_AvlSetPath_printNodeStr,0}};
#define boxvar_AvlSetPath_printNodeStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_printNodeStr)
DLLExport
modelica_string omc_AvlSetPath_printTreeStr(threadData_t *threadData, modelica_metatype _inTree);
#define boxptr_AvlSetPath_printTreeStr omc_AvlSetPath_printTreeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_printTreeStr,2,0) {(void*) boxptr_AvlSetPath_printTreeStr,0}};
#define boxvar_AvlSetPath_printTreeStr MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_printTreeStr)
#define boxptr_AvlSetPath_rotateLeft omc_AvlSetPath_rotateLeft
#define boxptr_AvlSetPath_rotateRight omc_AvlSetPath_rotateRight
DLLExport
modelica_metatype omc_AvlSetPath_setTreeLeftRight(threadData_t *threadData, modelica_metatype _orig, modelica_metatype _left, modelica_metatype _right);
#define boxptr_AvlSetPath_setTreeLeftRight omc_AvlSetPath_setTreeLeftRight
static const MMC_DEFSTRUCTLIT(boxvar_lit_AvlSetPath_setTreeLeftRight,2,0) {(void*) boxptr_AvlSetPath_setTreeLeftRight,0}};
#define boxvar_AvlSetPath_setTreeLeftRight MMC_REFSTRUCTLIT(boxvar_lit_AvlSetPath_setTreeLeftRight)
#ifdef __cplusplus
}
#endif
#endif

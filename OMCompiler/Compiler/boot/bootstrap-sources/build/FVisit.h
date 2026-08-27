#ifndef FVisit__H
#define FVisit__H
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
extern struct record_description FCore_VAvlTree_VAVLTREENODE__desc;
extern struct record_description FCore_VAvlTreeValue_VAVLTREEVALUE__desc;
extern struct record_description FCore_Visit_VN__desc;
extern struct record_description FCore_Visited_V__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
DLLExport
modelica_metatype omc_FVisit_getAvlValue(threadData_t *threadData, modelica_metatype _inValue);
#define boxptr_FVisit_getAvlValue omc_FVisit_getAvlValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_getAvlValue,2,0) {(void*) boxptr_FVisit_getAvlValue,0}};
#define boxvar_FVisit_getAvlValue MMC_REFSTRUCTLIT(boxvar_lit_FVisit_getAvlValue)
DLLExport
modelica_metatype omc_FVisit_getAvlTreeValues(threadData_t *threadData, modelica_metatype _tree, modelica_metatype _acc);
#define boxptr_FVisit_getAvlTreeValues omc_FVisit_getAvlTreeValues
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_getAvlTreeValues,2,0) {(void*) boxptr_FVisit_getAvlTreeValues,0}};
#define boxvar_FVisit_getAvlTreeValues MMC_REFSTRUCTLIT(boxvar_lit_FVisit_getAvlTreeValues)
DLLExport
modelica_metatype omc_FVisit_avlTreeReplace(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _inKey, modelica_metatype _inValue);
DLLExport
modelica_metatype boxptr_FVisit_avlTreeReplace(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _inKey, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_avlTreeReplace,2,0) {(void*) boxptr_FVisit_avlTreeReplace,0}};
#define boxvar_FVisit_avlTreeReplace MMC_REFSTRUCTLIT(boxvar_lit_FVisit_avlTreeReplace)
#define boxptr_FVisit_printAvlTreeStrPP2 omc_FVisit_printAvlTreeStrPP2
DLLExport
modelica_string omc_FVisit_printAvlTreeStrPP(threadData_t *threadData, modelica_metatype _inTree);
#define boxptr_FVisit_printAvlTreeStrPP omc_FVisit_printAvlTreeStrPP
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_printAvlTreeStrPP,2,0) {(void*) boxptr_FVisit_printAvlTreeStrPP,0}};
#define boxvar_FVisit_printAvlTreeStrPP MMC_REFSTRUCTLIT(boxvar_lit_FVisit_printAvlTreeStrPP)
#define boxptr_FVisit_computeHeight omc_FVisit_computeHeight
#define boxptr_FVisit_printAvlTreeStr omc_FVisit_printAvlTreeStr
#define boxptr_FVisit_getOptionStr omc_FVisit_getOptionStr
DLLExport
modelica_metatype omc_FVisit_avlTreeGet(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _inKey);
DLLExport
modelica_metatype boxptr_FVisit_avlTreeGet(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _inKey);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_avlTreeGet,2,0) {(void*) boxptr_FVisit_avlTreeGet,0}};
#define boxvar_FVisit_avlTreeGet MMC_REFSTRUCTLIT(boxvar_lit_FVisit_avlTreeGet)
#define boxptr_FVisit_rotateRight omc_FVisit_rotateRight
#define boxptr_FVisit_getOption omc_FVisit_getOption
#define boxptr_FVisit_rotateLeft omc_FVisit_rotateLeft
#define boxptr_FVisit_exchangeRight omc_FVisit_exchangeRight
#define boxptr_FVisit_exchangeLeft omc_FVisit_exchangeLeft
#define boxptr_FVisit_rightNode omc_FVisit_rightNode
#define boxptr_FVisit_leftNode omc_FVisit_leftNode
#define boxptr_FVisit_setLeft omc_FVisit_setLeft
#define boxptr_FVisit_setRight omc_FVisit_setRight
#define boxptr_FVisit_doBalance4 omc_FVisit_doBalance4
#define boxptr_FVisit_doBalance3 omc_FVisit_doBalance3
#define boxptr_FVisit_balance omc_FVisit_balance
#define boxptr_FVisit_nodeValue omc_FVisit_nodeValue
#define boxptr_FVisit_createEmptyAvlIfNone omc_FVisit_createEmptyAvlIfNone
DLLExport
modelica_metatype omc_FVisit_avlTreeAdd2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _keyComp, modelica_integer _inKey, modelica_metatype _inValue);
DLLExport
modelica_metatype boxptr_FVisit_avlTreeAdd2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _keyComp, modelica_metatype _inKey, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_avlTreeAdd2,2,0) {(void*) boxptr_FVisit_avlTreeAdd2,0}};
#define boxvar_FVisit_avlTreeAdd2 MMC_REFSTRUCTLIT(boxvar_lit_FVisit_avlTreeAdd2)
DLLExport
modelica_metatype omc_FVisit_avlTreeAdd(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _inKey, modelica_metatype _inValue);
DLLExport
modelica_metatype boxptr_FVisit_avlTreeAdd(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _inKey, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_avlTreeAdd,2,0) {(void*) boxptr_FVisit_avlTreeAdd,0}};
#define boxvar_FVisit_avlTreeAdd MMC_REFSTRUCTLIT(boxvar_lit_FVisit_avlTreeAdd)
DLLExport
modelica_metatype omc_FVisit_avlTreeNew(threadData_t *threadData);
#define boxptr_FVisit_avlTreeNew omc_FVisit_avlTreeNew
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_avlTreeNew,2,0) {(void*) boxptr_FVisit_avlTreeNew,0}};
#define boxvar_FVisit_avlTreeNew MMC_REFSTRUCTLIT(boxvar_lit_FVisit_avlTreeNew)
DLLExport
modelica_string omc_FVisit_valueStr(threadData_t *threadData, modelica_metatype _v);
#define boxptr_FVisit_valueStr omc_FVisit_valueStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_valueStr,2,0) {(void*) boxptr_FVisit_valueStr,0}};
#define boxvar_FVisit_valueStr MMC_REFSTRUCTLIT(boxvar_lit_FVisit_valueStr)
DLLExport
modelica_string omc_FVisit_keyStr(threadData_t *threadData, modelica_integer _k);
DLLExport
modelica_metatype boxptr_FVisit_keyStr(threadData_t *threadData, modelica_metatype _k);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_keyStr,2,0) {(void*) boxptr_FVisit_keyStr,0}};
#define boxvar_FVisit_keyStr MMC_REFSTRUCTLIT(boxvar_lit_FVisit_keyStr)
DLLExport
modelica_integer omc_FVisit_keyCompare(threadData_t *threadData, modelica_integer _k1, modelica_integer _k2);
DLLExport
modelica_metatype boxptr_FVisit_keyCompare(threadData_t *threadData, modelica_metatype _k1, modelica_metatype _k2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_keyCompare,2,0) {(void*) boxptr_FVisit_keyCompare,0}};
#define boxvar_FVisit_keyCompare MMC_REFSTRUCTLIT(boxvar_lit_FVisit_keyCompare)
DLLExport
modelica_metatype omc_FVisit_visit(threadData_t *threadData, modelica_metatype _inVisited, modelica_metatype _inRef);
#define boxptr_FVisit_visit omc_FVisit_visit
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_visit,2,0) {(void*) boxptr_FVisit_visit,0}};
#define boxvar_FVisit_visit MMC_REFSTRUCTLIT(boxvar_lit_FVisit_visit)
DLLExport
modelica_metatype omc_FVisit_tree(threadData_t *threadData, modelica_metatype _v);
#define boxptr_FVisit_tree omc_FVisit_tree
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_tree,2,0) {(void*) boxptr_FVisit_tree,0}};
#define boxvar_FVisit_tree MMC_REFSTRUCTLIT(boxvar_lit_FVisit_tree)
DLLExport
modelica_metatype omc_FVisit_ref(threadData_t *threadData, modelica_metatype _v);
#define boxptr_FVisit_ref omc_FVisit_ref
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_ref,2,0) {(void*) boxptr_FVisit_ref,0}};
#define boxvar_FVisit_ref MMC_REFSTRUCTLIT(boxvar_lit_FVisit_ref)
DLLExport
modelica_integer omc_FVisit_seq(threadData_t *threadData, modelica_metatype _v);
DLLExport
modelica_metatype boxptr_FVisit_seq(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_seq,2,0) {(void*) boxptr_FVisit_seq,0}};
#define boxvar_FVisit_seq MMC_REFSTRUCTLIT(boxvar_lit_FVisit_seq)
DLLExport
modelica_boolean omc_FVisit_visited(threadData_t *threadData, modelica_metatype _inVisited, modelica_metatype _inRef);
DLLExport
modelica_metatype boxptr_FVisit_visited(threadData_t *threadData, modelica_metatype _inVisited, modelica_metatype _inRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_visited,2,0) {(void*) boxptr_FVisit_visited,0}};
#define boxvar_FVisit_visited MMC_REFSTRUCTLIT(boxvar_lit_FVisit_visited)
DLLExport
modelica_metatype omc_FVisit_next(threadData_t *threadData, modelica_metatype _inVisited, modelica_integer *out_next);
DLLExport
modelica_metatype boxptr_FVisit_next(threadData_t *threadData, modelica_metatype _inVisited, modelica_metatype *out_next);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_next,2,0) {(void*) boxptr_FVisit_next,0}};
#define boxvar_FVisit_next MMC_REFSTRUCTLIT(boxvar_lit_FVisit_next)
DLLExport
modelica_metatype omc_FVisit_reset(threadData_t *threadData, modelica_metatype _inVisited);
#define boxptr_FVisit_reset omc_FVisit_reset
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_reset,2,0) {(void*) boxptr_FVisit_reset,0}};
#define boxvar_FVisit_reset MMC_REFSTRUCTLIT(boxvar_lit_FVisit_reset)
DLLExport
modelica_metatype omc_FVisit_new(threadData_t *threadData);
#define boxptr_FVisit_new omc_FVisit_new
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_new,2,0) {(void*) boxptr_FVisit_new,0}};
#define boxvar_FVisit_new MMC_REFSTRUCTLIT(boxvar_lit_FVisit_new)
#ifdef __cplusplus
}
#endif
#endif

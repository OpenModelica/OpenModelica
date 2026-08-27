#ifndef Array__H
#define Array__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_Array_maxElement(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _lessFn);
#define boxptr_Array_maxElement omc_Array_maxElement
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_maxElement,2,0) {(void*) boxptr_Array_maxElement,0}};
#define boxvar_Array_maxElement MMC_REFSTRUCTLIT(boxvar_lit_Array_maxElement)
DLLExport
modelica_metatype omc_Array_minElement(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _lessFn);
#define boxptr_Array_minElement omc_Array_minElement
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_minElement,2,0) {(void*) boxptr_Array_minElement,0}};
#define boxvar_Array_minElement MMC_REFSTRUCTLIT(boxvar_lit_Array_minElement)
DLLExport
modelica_boolean omc_Array_all(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _fn);
DLLExport
modelica_metatype boxptr_Array_all(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _fn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_all,2,0) {(void*) boxptr_Array_all,0}};
#define boxvar_Array_all MMC_REFSTRUCTLIT(boxvar_lit_Array_all)
DLLExport
modelica_metatype omc_Array_remove(threadData_t *threadData, modelica_metatype _arr, modelica_integer _index);
DLLExport
modelica_metatype boxptr_Array_remove(threadData_t *threadData, modelica_metatype _arr, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_remove,2,0) {(void*) boxptr_Array_remove,0}};
#define boxvar_Array_remove MMC_REFSTRUCTLIT(boxvar_lit_Array_remove)
DLLExport
modelica_metatype omc_Array_insertList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farr, modelica_metatype _lst, modelica_integer _startPos);
DLLExport
modelica_metatype boxptr_Array_insertList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farr, modelica_metatype _lst, modelica_metatype _startPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_insertList,2,0) {(void*) boxptr_Array_insertList,0}};
#define boxvar_Array_insertList MMC_REFSTRUCTLIT(boxvar_lit_Array_insertList)
DLLExport
modelica_boolean omc_Array_exist(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _pred);
DLLExport
modelica_metatype boxptr_Array_exist(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _pred);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_exist,2,0) {(void*) boxptr_Array_exist,0}};
#define boxvar_Array_exist MMC_REFSTRUCTLIT(boxvar_lit_Array_exist)
DLLExport
modelica_boolean omc_Array_isLess(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _lessFn);
DLLExport
modelica_metatype boxptr_Array_isLess(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _lessFn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_isLess,2,0) {(void*) boxptr_Array_isLess,0}};
#define boxvar_Array_isLess MMC_REFSTRUCTLIT(boxvar_lit_Array_isLess)
DLLExport
modelica_boolean omc_Array_isEqualOnTrue(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _pred);
DLLExport
modelica_metatype boxptr_Array_isEqualOnTrue(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _pred);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_isEqualOnTrue,2,0) {(void*) boxptr_Array_isEqualOnTrue,0}};
#define boxvar_Array_isEqualOnTrue MMC_REFSTRUCTLIT(boxvar_lit_Array_isEqualOnTrue)
DLLExport
modelica_boolean omc_Array_isEqual(threadData_t *threadData, modelica_metatype _inArr1, modelica_metatype _inArr2);
DLLExport
modelica_metatype boxptr_Array_isEqual(threadData_t *threadData, modelica_metatype _inArr1, modelica_metatype _inArr2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_isEqual,2,0) {(void*) boxptr_Array_isEqual,0}};
#define boxvar_Array_isEqual MMC_REFSTRUCTLIT(boxvar_lit_Array_isEqual)
DLLExport
modelica_boolean omc_Array_arrayListsEmpty1(threadData_t *threadData, modelica_metatype _lst, modelica_boolean _isEmptyIn);
DLLExport
modelica_metatype boxptr_Array_arrayListsEmpty1(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _isEmptyIn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_arrayListsEmpty1,2,0) {(void*) boxptr_Array_arrayListsEmpty1,0}};
#define boxvar_Array_arrayListsEmpty1 MMC_REFSTRUCTLIT(boxvar_lit_Array_arrayListsEmpty1)
DLLExport
modelica_boolean omc_Array_arrayListsEmpty(threadData_t *threadData, modelica_metatype _arr);
DLLExport
modelica_metatype boxptr_Array_arrayListsEmpty(threadData_t *threadData, modelica_metatype _arr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_arrayListsEmpty,2,0) {(void*) boxptr_Array_arrayListsEmpty,0}};
#define boxvar_Array_arrayListsEmpty MMC_REFSTRUCTLIT(boxvar_lit_Array_arrayListsEmpty)
DLLExport
modelica_metatype omc_Array_reverse(threadData_t *threadData, modelica_metatype _inArray);
#define boxptr_Array_reverse omc_Array_reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_reverse,2,0) {(void*) boxptr_Array_reverse,0}};
#define boxvar_Array_reverse MMC_REFSTRUCTLIT(boxvar_lit_Array_reverse)
DLLExport
modelica_metatype omc_Array_getMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inArray, modelica_fnptr _inCompFunc, modelica_integer *out_outIndex);
DLLExport
modelica_metatype boxptr_Array_getMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inArray, modelica_fnptr _inCompFunc, modelica_metatype *out_outIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_getMemberOnTrue,2,0) {(void*) boxptr_Array_getMemberOnTrue,0}};
#define boxvar_Array_getMemberOnTrue MMC_REFSTRUCTLIT(boxvar_lit_Array_getMemberOnTrue)
DLLExport
modelica_integer omc_Array_position(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inElement, modelica_integer _inFilledSize);
DLLExport
modelica_metatype boxptr_Array_position(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inElement, modelica_metatype _inFilledSize);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_position,2,0) {(void*) boxptr_Array_position,0}};
#define boxvar_Array_position MMC_REFSTRUCTLIT(boxvar_lit_Array_position)
DLLExport
modelica_metatype omc_Array_getRange(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inEnd, modelica_metatype _inArray);
DLLExport
modelica_metatype boxptr_Array_getRange(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inEnd, modelica_metatype _inArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_getRange,2,0) {(void*) boxptr_Array_getRange,0}};
#define boxvar_Array_getRange MMC_REFSTRUCTLIT(boxvar_lit_Array_getRange)
DLLExport
modelica_metatype omc_Array_setRange(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inEnd, modelica_metatype _inArray, modelica_metatype _inValue);
DLLExport
modelica_metatype boxptr_Array_setRange(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inEnd, modelica_metatype _inArray, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_setRange,2,0) {(void*) boxptr_Array_setRange,0}};
#define boxvar_Array_setRange MMC_REFSTRUCTLIT(boxvar_lit_Array_setRange)
DLLExport
modelica_metatype omc_Array_createIntRange(threadData_t *threadData, modelica_integer _inLen);
DLLExport
modelica_metatype boxptr_Array_createIntRange(threadData_t *threadData, modelica_metatype _inLen);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_createIntRange,2,0) {(void*) boxptr_Array_createIntRange,0}};
#define boxvar_Array_createIntRange MMC_REFSTRUCTLIT(boxvar_lit_Array_createIntRange)
DLLExport
void omc_Array_copyRange(threadData_t *threadData, modelica_metatype _srcArray, modelica_metatype _dstArray, modelica_integer _srcFirst, modelica_integer _srcLast, modelica_integer _dstPos);
DLLExport
void boxptr_Array_copyRange(threadData_t *threadData, modelica_metatype _srcArray, modelica_metatype _dstArray, modelica_metatype _srcFirst, modelica_metatype _srcLast, modelica_metatype _dstPos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_copyRange,2,0) {(void*) boxptr_Array_copyRange,0}};
#define boxvar_Array_copyRange MMC_REFSTRUCTLIT(boxvar_lit_Array_copyRange)
DLLExport
modelica_metatype omc_Array_copyN(threadData_t *threadData, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest, modelica_integer _inN, modelica_integer _srcOffset, modelica_integer _dstOffset);
DLLExport
modelica_metatype boxptr_Array_copyN(threadData_t *threadData, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest, modelica_metatype _inN, modelica_metatype _srcOffset, modelica_metatype _dstOffset);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_copyN,2,0) {(void*) boxptr_Array_copyN,0}};
#define boxvar_Array_copyN MMC_REFSTRUCTLIT(boxvar_lit_Array_copyN)
DLLExport
modelica_metatype omc_Array_copy(threadData_t *threadData, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest);
#define boxptr_Array_copy omc_Array_copy
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_copy,2,0) {(void*) boxptr_Array_copy,0}};
#define boxvar_Array_copy MMC_REFSTRUCTLIT(boxvar_lit_Array_copy)
DLLExport
modelica_metatype omc_Array_join(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2);
#define boxptr_Array_join omc_Array_join
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_join,2,0) {(void*) boxptr_Array_join,0}};
#define boxvar_Array_join MMC_REFSTRUCTLIT(boxvar_lit_Array_join)
DLLExport
modelica_metatype omc_Array_appendList(threadData_t *threadData, modelica_metatype _arr, modelica_metatype _lst);
#define boxptr_Array_appendList omc_Array_appendList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_appendList,2,0) {(void*) boxptr_Array_appendList,0}};
#define boxvar_Array_appendList MMC_REFSTRUCTLIT(boxvar_lit_Array_appendList)
DLLExport
modelica_metatype omc_Array_appendToElement(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inElements, modelica_metatype _inArray);
DLLExport
modelica_metatype boxptr_Array_appendToElement(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inElements, modelica_metatype _inArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_appendToElement,2,0) {(void*) boxptr_Array_appendToElement,0}};
#define boxvar_Array_appendToElement MMC_REFSTRUCTLIT(boxvar_lit_Array_appendToElement)
DLLExport
modelica_metatype omc_Array_consToElement(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inElement, modelica_metatype _inArray);
DLLExport
modelica_metatype boxptr_Array_consToElement(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inElement, modelica_metatype _inArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_consToElement,2,0) {(void*) boxptr_Array_consToElement,0}};
#define boxvar_Array_consToElement MMC_REFSTRUCTLIT(boxvar_lit_Array_consToElement)
DLLExport
modelica_metatype omc_Array_expandOnDemand(threadData_t *threadData, modelica_integer _inNewSize, modelica_metatype _inArray, modelica_real _inExpansionFactor, modelica_metatype _inFillValue);
DLLExport
modelica_metatype boxptr_Array_expandOnDemand(threadData_t *threadData, modelica_metatype _inNewSize, modelica_metatype _inArray, modelica_metatype _inExpansionFactor, modelica_metatype _inFillValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_expandOnDemand,2,0) {(void*) boxptr_Array_expandOnDemand,0}};
#define boxvar_Array_expandOnDemand MMC_REFSTRUCTLIT(boxvar_lit_Array_expandOnDemand)
DLLExport
modelica_metatype omc_Array_expand(threadData_t *threadData, modelica_integer _inN, modelica_metatype _inArray, modelica_metatype _inFill);
DLLExport
modelica_metatype boxptr_Array_expand(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inArray, modelica_metatype _inFill);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_expand,2,0) {(void*) boxptr_Array_expand,0}};
#define boxvar_Array_expand MMC_REFSTRUCTLIT(boxvar_lit_Array_expand)
DLLExport
modelica_metatype omc_Array_expandToSize(threadData_t *threadData, modelica_integer _inNewSize, modelica_metatype _inArray, modelica_metatype _inFill);
DLLExport
modelica_metatype boxptr_Array_expandToSize(threadData_t *threadData, modelica_metatype _inNewSize, modelica_metatype _inArray, modelica_metatype _inFill);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_expandToSize,2,0) {(void*) boxptr_Array_expandToSize,0}};
#define boxvar_Array_expandToSize MMC_REFSTRUCTLIT(boxvar_lit_Array_expandToSize)
DLLExport
modelica_metatype omc_Array_replaceAtWithFill(threadData_t *threadData, modelica_integer _inPos, modelica_metatype _inTypeReplace, modelica_metatype _inTypeFill, modelica_metatype _inArray);
DLLExport
modelica_metatype boxptr_Array_replaceAtWithFill(threadData_t *threadData, modelica_metatype _inPos, modelica_metatype _inTypeReplace, modelica_metatype _inTypeFill, modelica_metatype _inArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_replaceAtWithFill,2,0) {(void*) boxptr_Array_replaceAtWithFill,0}};
#define boxvar_Array_replaceAtWithFill MMC_REFSTRUCTLIT(boxvar_lit_Array_replaceAtWithFill)
DLLExport
void omc_Array_updateElementListAppend(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inValue, modelica_metatype _inArray);
DLLExport
void boxptr_Array_updateElementListAppend(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inValue, modelica_metatype _inArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_updateElementListAppend,2,0) {(void*) boxptr_Array_updateElementListAppend,0}};
#define boxvar_Array_updateElementListAppend MMC_REFSTRUCTLIT(boxvar_lit_Array_updateElementListAppend)
DLLExport
void omc_Array_updatewithListIndexFirst(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inStartIndex, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest);
DLLExport
void boxptr_Array_updatewithListIndexFirst(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inStartIndex, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_updatewithListIndexFirst,2,0) {(void*) boxptr_Array_updatewithListIndexFirst,0}};
#define boxvar_Array_updatewithListIndexFirst MMC_REFSTRUCTLIT(boxvar_lit_Array_updatewithListIndexFirst)
DLLExport
void omc_Array_updatewithArrayIndexFirst(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest);
DLLExport
void boxptr_Array_updatewithArrayIndexFirst(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_updatewithArrayIndexFirst,2,0) {(void*) boxptr_Array_updatewithArrayIndexFirst,0}};
#define boxvar_Array_updatewithArrayIndexFirst MMC_REFSTRUCTLIT(boxvar_lit_Array_updatewithArrayIndexFirst)
DLLExport
modelica_metatype omc_Array_getIndexFirst(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inArray);
DLLExport
modelica_metatype boxptr_Array_getIndexFirst(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_getIndexFirst,2,0) {(void*) boxptr_Array_getIndexFirst,0}};
#define boxvar_Array_getIndexFirst MMC_REFSTRUCTLIT(boxvar_lit_Array_getIndexFirst)
DLLExport
void omc_Array_updateIndexFirst(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inValue, modelica_metatype _inArray);
DLLExport
void boxptr_Array_updateIndexFirst(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inValue, modelica_metatype _inArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_updateIndexFirst,2,0) {(void*) boxptr_Array_updateIndexFirst,0}};
#define boxvar_Array_updateIndexFirst MMC_REFSTRUCTLIT(boxvar_lit_Array_updateIndexFirst)
DLLExport
modelica_metatype omc_Array_reduce(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inReduceFunc);
#define boxptr_Array_reduce omc_Array_reduce
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_reduce,2,0) {(void*) boxptr_Array_reduce,0}};
#define boxvar_Array_reduce MMC_REFSTRUCTLIT(boxvar_lit_Array_reduce)
DLLExport
modelica_metatype omc_Array_foldIndex(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
#define boxptr_Array_foldIndex omc_Array_foldIndex
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_foldIndex,2,0) {(void*) boxptr_Array_foldIndex,0}};
#define boxvar_Array_foldIndex MMC_REFSTRUCTLIT(boxvar_lit_Array_foldIndex)
DLLExport
modelica_metatype omc_Array_fold6(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inArg6, modelica_metatype _inStartValue);
#define boxptr_Array_fold6 omc_Array_fold6
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_fold6,2,0) {(void*) boxptr_Array_fold6,0}};
#define boxvar_Array_fold6 MMC_REFSTRUCTLIT(boxvar_lit_Array_fold6)
DLLExport
modelica_metatype omc_Array_fold5(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inStartValue);
#define boxptr_Array_fold5 omc_Array_fold5
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_fold5,2,0) {(void*) boxptr_Array_fold5,0}};
#define boxvar_Array_fold5 MMC_REFSTRUCTLIT(boxvar_lit_Array_fold5)
DLLExport
modelica_metatype omc_Array_fold4(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inStartValue);
#define boxptr_Array_fold4 omc_Array_fold4
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_fold4,2,0) {(void*) boxptr_Array_fold4,0}};
#define boxvar_Array_fold4 MMC_REFSTRUCTLIT(boxvar_lit_Array_fold4)
DLLExport
modelica_metatype omc_Array_fold3(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inStartValue);
#define boxptr_Array_fold3 omc_Array_fold3
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_fold3,2,0) {(void*) boxptr_Array_fold3,0}};
#define boxvar_Array_fold3 MMC_REFSTRUCTLIT(boxvar_lit_Array_fold3)
DLLExport
modelica_metatype omc_Array_fold2(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inStartValue);
#define boxptr_Array_fold2 omc_Array_fold2
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_fold2,2,0) {(void*) boxptr_Array_fold2,0}};
#define boxvar_Array_fold2 MMC_REFSTRUCTLIT(boxvar_lit_Array_fold2)
DLLExport
modelica_metatype omc_Array_fold1(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg, modelica_metatype _inStartValue);
#define boxptr_Array_fold1 omc_Array_fold1
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_fold1,2,0) {(void*) boxptr_Array_fold1,0}};
#define boxvar_Array_fold1 MMC_REFSTRUCTLIT(boxvar_lit_Array_fold1)
DLLExport
modelica_metatype omc_Array_fold(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
#define boxptr_Array_fold omc_Array_fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_fold,2,0) {(void*) boxptr_Array_fold,0}};
#define boxvar_Array_fold MMC_REFSTRUCTLIT(boxvar_lit_Array_fold)
DLLExport
modelica_metatype omc_Array_mapList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_Array_mapList omc_Array_mapList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_mapList,2,0) {(void*) boxptr_Array_mapList,0}};
#define boxvar_Array_mapList MMC_REFSTRUCTLIT(boxvar_lit_Array_mapList)
DLLExport
void omc_Array_map0(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc);
#define boxptr_Array_map0 omc_Array_map0
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_map0,2,0) {(void*) boxptr_Array_map0,0}};
#define boxvar_Array_map0 MMC_REFSTRUCTLIT(boxvar_lit_Array_map0)
DLLExport
modelica_metatype omc_Array_map1Ind(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg);
#define boxptr_Array_map1Ind omc_Array_map1Ind
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_map1Ind,2,0) {(void*) boxptr_Array_map1Ind,0}};
#define boxvar_Array_map1Ind MMC_REFSTRUCTLIT(boxvar_lit_Array_map1Ind)
DLLExport
modelica_metatype omc_Array_map1(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg);
#define boxptr_Array_map1 omc_Array_map1
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_map1,2,0) {(void*) boxptr_Array_map1,0}};
#define boxvar_Array_map1 MMC_REFSTRUCTLIT(boxvar_lit_Array_map1)
DLLExport
modelica_metatype omc_Array_map(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc);
#define boxptr_Array_map omc_Array_map
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_map,2,0) {(void*) boxptr_Array_map,0}};
#define boxvar_Array_map MMC_REFSTRUCTLIT(boxvar_lit_Array_map)
DLLExport
modelica_metatype omc_Array_select(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inIndices);
#define boxptr_Array_select omc_Array_select
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_select,2,0) {(void*) boxptr_Array_select,0}};
#define boxvar_Array_select MMC_REFSTRUCTLIT(boxvar_lit_Array_select)
DLLExport
modelica_metatype omc_Array_findFirstOnTrueWithIdx(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPredicate, modelica_integer *out_idxOut);
DLLExport
modelica_metatype boxptr_Array_findFirstOnTrueWithIdx(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPredicate, modelica_metatype *out_idxOut);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_findFirstOnTrueWithIdx,2,0) {(void*) boxptr_Array_findFirstOnTrueWithIdx,0}};
#define boxvar_Array_findFirstOnTrueWithIdx MMC_REFSTRUCTLIT(boxvar_lit_Array_findFirstOnTrueWithIdx)
DLLExport
modelica_metatype omc_Array_findFirstOnTrue(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPredicate);
#define boxptr_Array_findFirstOnTrue omc_Array_findFirstOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_findFirstOnTrue,2,0) {(void*) boxptr_Array_findFirstOnTrue,0}};
#define boxvar_Array_findFirstOnTrue MMC_REFSTRUCTLIT(boxvar_lit_Array_findFirstOnTrue)
DLLExport
modelica_metatype omc_Array_heapSort(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinArray);
#define boxptr_Array_heapSort omc_Array_heapSort
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_heapSort,2,0) {(void*) boxptr_Array_heapSort,0}};
#define boxvar_Array_heapSort MMC_REFSTRUCTLIT(boxvar_lit_Array_heapSort)
DLLExport
modelica_metatype omc_Array_mapNoCopy__1(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_Array_mapNoCopy__1 omc_Array_mapNoCopy__1
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_mapNoCopy__1,2,0) {(void*) boxptr_Array_mapNoCopy__1,0}};
#define boxvar_Array_mapNoCopy__1 MMC_REFSTRUCTLIT(boxvar_lit_Array_mapNoCopy__1)
DLLExport
modelica_metatype omc_Array_mapNoCopy(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc);
#define boxptr_Array_mapNoCopy omc_Array_mapNoCopy
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_mapNoCopy,2,0) {(void*) boxptr_Array_mapNoCopy,0}};
#define boxvar_Array_mapNoCopy MMC_REFSTRUCTLIT(boxvar_lit_Array_mapNoCopy)
#ifdef __cplusplus
}
#endif
#endif

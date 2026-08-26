#ifndef List__H
#define List__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLDirection
void omc_List_apply(threadData_t *threadData, modelica_metatype _lst, modelica_fnptr _fn);
#define boxptr_List_apply omc_List_apply
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_apply,2,0) {(void*) boxptr_List_apply,0}};
#define boxvar_List_apply MMC_REFSTRUCTLIT(boxvar_lit_List_apply)
DLLDirection
modelica_metatype omc_List_trim(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fl, modelica_fnptr _fn);
#define boxptr_List_trim omc_List_trim
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_trim,2,0) {(void*) boxptr_List_trim,0}};
#define boxvar_List_trim MMC_REFSTRUCTLIT(boxvar_lit_List_trim)
DLLDirection
modelica_metatype omc_List_maxElement(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _lessFn);
#define boxptr_List_maxElement omc_List_maxElement
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_maxElement,2,0) {(void*) boxptr_List_maxElement,0}};
#define boxvar_List_maxElement MMC_REFSTRUCTLIT(boxvar_lit_List_maxElement)
DLLDirection
modelica_metatype omc_List_minElement(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _lessFn);
#define boxptr_List_minElement omc_List_minElement
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_minElement,2,0) {(void*) boxptr_List_minElement,0}};
#define boxvar_List_minElement MMC_REFSTRUCTLIT(boxvar_lit_List_minElement)
DLLDirection
modelica_boolean omc_List_contains(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _elem, modelica_fnptr _eqFunc);
DLLDirection
modelica_metatype boxptr_List_contains(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _elem, modelica_fnptr _eqFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_contains,2,0) {(void*) boxptr_List_contains,0}};
#define boxvar_List_contains MMC_REFSTRUCTLIT(boxvar_lit_List_contains)
#define boxptr_List_allCombinations4 omc_List_allCombinations4
#define boxptr_List_allCombinations3 omc_List_allCombinations3
#define boxptr_List_allCombinations2 omc_List_allCombinations2
DLLDirection
modelica_metatype omc_List_allCombinations(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _maxTotalSize, modelica_metatype _info);
#define boxptr_List_allCombinations omc_List_allCombinations
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_allCombinations,2,0) {(void*) boxptr_List_allCombinations,0}};
#define boxvar_List_allCombinations MMC_REFSTRUCTLIT(boxvar_lit_List_allCombinations)
DLLDirection
modelica_metatype omc_List_mapIndices(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _indices, modelica_fnptr _func);
#define boxptr_List_mapIndices omc_List_mapIndices
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapIndices,2,0) {(void*) boxptr_List_mapIndices,0}};
#define boxvar_List_mapIndices MMC_REFSTRUCTLIT(boxvar_lit_List_mapIndices)
DLLDirection
modelica_metatype omc_List_separate1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1, modelica_metatype *out_outListFalse);
#define boxptr_List_separate1OnTrue omc_List_separate1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_separate1OnTrue,2,0) {(void*) boxptr_List_separate1OnTrue,0}};
#define boxvar_List_separate1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_separate1OnTrue)
DLLDirection
modelica_metatype omc_List_separateOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype *out_outListFalse);
#define boxptr_List_separateOnTrue omc_List_separateOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_separateOnTrue,2,0) {(void*) boxptr_List_separateOnTrue,0}};
#define boxvar_List_separateOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_separateOnTrue)
DLLDirection
modelica_integer omc_List_count(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
DLLDirection
modelica_metatype boxptr_List_count(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_count,2,0) {(void*) boxptr_List_count,0}};
#define boxvar_List_count MMC_REFSTRUCTLIT(boxvar_lit_List_count)
DLLDirection
modelica_boolean omc_List_any(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
DLLDirection
modelica_metatype boxptr_List_any(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_any,2,0) {(void*) boxptr_List_any,0}};
#define boxvar_List_any MMC_REFSTRUCTLIT(boxvar_lit_List_any)
DLLDirection
modelica_boolean omc_List_none(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
DLLDirection
modelica_metatype boxptr_List_none(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_none,2,0) {(void*) boxptr_List_none,0}};
#define boxvar_List_none MMC_REFSTRUCTLIT(boxvar_lit_List_none)
DLLDirection
modelica_boolean omc_List_all(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
DLLDirection
modelica_metatype boxptr_List_all(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_all,2,0) {(void*) boxptr_List_all,0}};
#define boxvar_List_all MMC_REFSTRUCTLIT(boxvar_lit_List_all)
DLLDirection
modelica_metatype omc_List_mkOption(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_mkOption omc_List_mkOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mkOption,2,0) {(void*) boxptr_List_mkOption,0}};
#define boxvar_List_mkOption MMC_REFSTRUCTLIT(boxvar_lit_List_mkOption)
DLLDirection
modelica_metatype omc_List_toListWithPositions(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_toListWithPositions omc_List_toListWithPositions
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_toListWithPositions,2,0) {(void*) boxptr_List_toListWithPositions,0}};
#define boxvar_List_toListWithPositions MMC_REFSTRUCTLIT(boxvar_lit_List_toListWithPositions)
DLLDirection
modelica_boolean omc_List_listIsLonger(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
DLLDirection
modelica_metatype boxptr_List_listIsLonger(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_listIsLonger,2,0) {(void*) boxptr_List_listIsLonger,0}};
#define boxvar_List_listIsLonger MMC_REFSTRUCTLIT(boxvar_lit_List_listIsLonger)
DLLDirection
modelica_boolean omc_List_allReferenceEq(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
DLLDirection
modelica_metatype boxptr_List_allReferenceEq(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_allReferenceEq,2,0) {(void*) boxptr_List_allReferenceEq,0}};
#define boxvar_List_allReferenceEq MMC_REFSTRUCTLIT(boxvar_lit_List_allReferenceEq)
#define boxptr_List_combinationMap__tail omc_List_combinationMap__tail
DLLDirection
modelica_metatype omc_List_combinationMap(threadData_t *threadData, modelica_metatype _inElements, modelica_fnptr _inMapFunc);
#define boxptr_List_combinationMap omc_List_combinationMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_combinationMap,2,0) {(void*) boxptr_List_combinationMap,0}};
#define boxvar_List_combinationMap MMC_REFSTRUCTLIT(boxvar_lit_List_combinationMap)
#define boxptr_List_combination__tail omc_List_combination__tail
DLLDirection
modelica_metatype omc_List_combination(threadData_t *threadData, modelica_metatype _inElements);
#define boxptr_List_combination omc_List_combination
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_combination,2,0) {(void*) boxptr_List_combination,0}};
#define boxvar_List_combination MMC_REFSTRUCTLIT(boxvar_lit_List_combination)
DLLDirection
modelica_metatype omc_List_splitEqualPrefix(threadData_t *threadData, modelica_metatype _inFullList, modelica_metatype _inPrefixList, modelica_fnptr _inEqFunc, modelica_metatype _inAccum, modelica_metatype *out_outRest);
#define boxptr_List_splitEqualPrefix omc_List_splitEqualPrefix
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitEqualPrefix,2,0) {(void*) boxptr_List_splitEqualPrefix,0}};
#define boxvar_List_splitEqualPrefix MMC_REFSTRUCTLIT(boxvar_lit_List_splitEqualPrefix)
DLLDirection
modelica_metatype omc_List_findSome(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_findSome omc_List_findSome
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findSome,2,0) {(void*) boxptr_List_findSome,0}};
#define boxvar_List_findSome MMC_REFSTRUCTLIT(boxvar_lit_List_findSome)
DLLDirection
modelica_metatype omc_List_findAndMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _pred, modelica_fnptr _func, modelica_boolean *out_found);
DLLDirection
modelica_metatype boxptr_List_findAndMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _pred, modelica_fnptr _func, modelica_metatype *out_found);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findAndMap,2,0) {(void*) boxptr_List_findAndMap,0}};
#define boxvar_List_findAndMap MMC_REFSTRUCTLIT(boxvar_lit_List_findAndMap)
DLLDirection
modelica_metatype omc_List_findMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_boolean *out_outFound);
DLLDirection
modelica_metatype boxptr_List_findMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outFound);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findMap,2,0) {(void*) boxptr_List_findMap,0}};
#define boxvar_List_findMap MMC_REFSTRUCTLIT(boxvar_lit_List_findMap)
DLLDirection
modelica_metatype omc_List_accumulateMapAccum(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc);
#define boxptr_List_accumulateMapAccum omc_List_accumulateMapAccum
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_accumulateMapAccum,2,0) {(void*) boxptr_List_accumulateMapAccum,0}};
#define boxvar_List_accumulateMapAccum MMC_REFSTRUCTLIT(boxvar_lit_List_accumulateMapAccum)
DLLDirection
modelica_integer omc_List_lengthListElements(threadData_t *threadData, modelica_metatype _inListList);
DLLDirection
modelica_metatype boxptr_List_lengthListElements(threadData_t *threadData, modelica_metatype _inListList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_lengthListElements,2,0) {(void*) boxptr_List_lengthListElements,0}};
#define boxvar_List_lengthListElements MMC_REFSTRUCTLIT(boxvar_lit_List_lengthListElements)
DLLDirection
modelica_boolean omc_List_hasSeveralElements(threadData_t *threadData, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_hasSeveralElements(threadData_t *threadData, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_hasSeveralElements,2,0) {(void*) boxptr_List_hasSeveralElements,0}};
#define boxvar_List_hasSeveralElements MMC_REFSTRUCTLIT(boxvar_lit_List_hasSeveralElements)
DLLDirection
modelica_boolean omc_List_hasOneElement(threadData_t *threadData, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_hasOneElement(threadData_t *threadData, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_hasOneElement,2,0) {(void*) boxptr_List_hasOneElement,0}};
#define boxvar_List_hasOneElement MMC_REFSTRUCTLIT(boxvar_lit_List_hasOneElement)
DLLDirection
modelica_string omc_List_toStringCustom(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPrintFunc, modelica_string _inNameStr, modelica_string _inBeginStr, modelica_string _inDelimitStr, modelica_string _inEndStr, modelica_boolean _inPrintEmpty, modelica_integer _maxLength);
DLLDirection
modelica_metatype boxptr_List_toStringCustom(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPrintFunc, modelica_metatype _inNameStr, modelica_metatype _inBeginStr, modelica_metatype _inDelimitStr, modelica_metatype _inEndStr, modelica_metatype _inPrintEmpty, modelica_metatype _maxLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_toStringCustom,2,0) {(void*) boxptr_List_toStringCustom,0}};
#define boxvar_List_toStringCustom MMC_REFSTRUCTLIT(boxvar_lit_List_toStringCustom)
DLLDirection
modelica_string omc_List_toString(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPrintFunc, modelica_integer _style);
DLLDirection
modelica_metatype boxptr_List_toString(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPrintFunc, modelica_metatype _style);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_toString,2,0) {(void*) boxptr_List_toString,0}};
#define boxvar_List_toString MMC_REFSTRUCTLIT(boxvar_lit_List_toString)
DLLDirection
modelica_metatype omc_List_replaceAtWithList(threadData_t *threadData, modelica_metatype _inReplacementList, modelica_integer _inPosition, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_replaceAtWithList(threadData_t *threadData, modelica_metatype _inReplacementList, modelica_metatype _inPosition, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceAtWithList,2,0) {(void*) boxptr_List_replaceAtWithList,0}};
#define boxvar_List_replaceAtWithList MMC_REFSTRUCTLIT(boxvar_lit_List_replaceAtWithList)
DLLDirection
modelica_metatype omc_List_replaceAtIndexFirst(threadData_t *threadData, modelica_integer _inPosition, modelica_metatype _inElement, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_replaceAtIndexFirst(threadData_t *threadData, modelica_metatype _inPosition, modelica_metatype _inElement, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceAtIndexFirst,2,0) {(void*) boxptr_List_replaceAtIndexFirst,0}};
#define boxvar_List_replaceAtIndexFirst MMC_REFSTRUCTLIT(boxvar_lit_List_replaceAtIndexFirst)
DLLDirection
modelica_metatype omc_List_replaceOnTrue(threadData_t *threadData, modelica_metatype _inReplacement, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_boolean *out_outReplaced);
DLLDirection
modelica_metatype boxptr_List_replaceOnTrue(threadData_t *threadData, modelica_metatype _inReplacement, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outReplaced);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceOnTrue,2,0) {(void*) boxptr_List_replaceOnTrue,0}};
#define boxvar_List_replaceOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_replaceOnTrue)
DLLDirection
modelica_metatype omc_List_replaceAt(threadData_t *threadData, modelica_metatype _inElement, modelica_integer _inPosition, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_replaceAt(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inPosition, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceAt,2,0) {(void*) boxptr_List_replaceAt,0}};
#define boxvar_List_replaceAt MMC_REFSTRUCTLIT(boxvar_lit_List_replaceAt)
DLLDirection
modelica_metatype omc_List_keepPositionsSorted(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions, modelica_boolean _zeroBased);
DLLDirection
modelica_metatype boxptr_List_keepPositionsSorted(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions, modelica_metatype _zeroBased);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_keepPositionsSorted,2,0) {(void*) boxptr_List_keepPositionsSorted,0}};
#define boxvar_List_keepPositionsSorted MMC_REFSTRUCTLIT(boxvar_lit_List_keepPositionsSorted)
DLLDirection
modelica_metatype omc_List_keepPositions(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions, modelica_boolean _zeroBased);
DLLDirection
modelica_metatype boxptr_List_keepPositions(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions, modelica_metatype _zeroBased);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_keepPositions,2,0) {(void*) boxptr_List_keepPositions,0}};
#define boxvar_List_keepPositions MMC_REFSTRUCTLIT(boxvar_lit_List_keepPositions)
DLLDirection
modelica_metatype omc_List_deletePositionsSorted(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions, modelica_boolean _zeroBased);
DLLDirection
modelica_metatype boxptr_List_deletePositionsSorted(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions, modelica_metatype _zeroBased);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_deletePositionsSorted,2,0) {(void*) boxptr_List_deletePositionsSorted,0}};
#define boxvar_List_deletePositionsSorted MMC_REFSTRUCTLIT(boxvar_lit_List_deletePositionsSorted)
DLLDirection
modelica_metatype omc_List_deletePositions(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions, modelica_boolean _zeroBased);
DLLDirection
modelica_metatype boxptr_List_deletePositions(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions, modelica_metatype _zeroBased);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_deletePositions,2,0) {(void*) boxptr_List_deletePositions,0}};
#define boxvar_List_deletePositions MMC_REFSTRUCTLIT(boxvar_lit_List_deletePositions)
DLLDirection
modelica_metatype omc_List_deleteMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inList, modelica_fnptr _inCompareFunc, modelica_metatype *out_outDeletedElement);
#define boxptr_List_deleteMemberOnTrue omc_List_deleteMemberOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_deleteMemberOnTrue,2,0) {(void*) boxptr_List_deleteMemberOnTrue,0}};
#define boxvar_List_deleteMemberOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_deleteMemberOnTrue)
DLLDirection
modelica_metatype omc_List_findBoolList(threadData_t *threadData, modelica_metatype _inBooleans, modelica_metatype _inList, modelica_metatype _inFalseValue);
#define boxptr_List_findBoolList omc_List_findBoolList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findBoolList,2,0) {(void*) boxptr_List_findBoolList,0}};
#define boxvar_List_findBoolList MMC_REFSTRUCTLIT(boxvar_lit_List_findBoolList)
DLLDirection
modelica_metatype omc_List_findAndRemove1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _arg1, modelica_metatype *out_rest);
#define boxptr_List_findAndRemove1 omc_List_findAndRemove1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findAndRemove1,2,0) {(void*) boxptr_List_findAndRemove1,0}};
#define boxvar_List_findAndRemove1 MMC_REFSTRUCTLIT(boxvar_lit_List_findAndRemove1)
DLLDirection
modelica_metatype omc_List_findAndRemove(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_rest);
#define boxptr_List_findAndRemove omc_List_findAndRemove
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findAndRemove,2,0) {(void*) boxptr_List_findAndRemove,0}};
#define boxvar_List_findAndRemove MMC_REFSTRUCTLIT(boxvar_lit_List_findAndRemove)
DLLDirection
modelica_metatype omc_List_find1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _arg1);
#define boxptr_List_find1 omc_List_find1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_find1,2,0) {(void*) boxptr_List_find1,0}};
#define boxvar_List_find1 MMC_REFSTRUCTLIT(boxvar_lit_List_find1)
DLLDirection
modelica_metatype omc_List_findOption(threadData_t *threadData, modelica_metatype _lst, modelica_fnptr _fn);
#define boxptr_List_findOption omc_List_findOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findOption,2,0) {(void*) boxptr_List_findOption,0}};
#define boxvar_List_findOption MMC_REFSTRUCTLIT(boxvar_lit_List_findOption)
DLLDirection
modelica_metatype omc_List_find(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_find omc_List_find
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_find,2,0) {(void*) boxptr_List_find,0}};
#define boxvar_List_find MMC_REFSTRUCTLIT(boxvar_lit_List_find)
DLLDirection
modelica_metatype omc_List_select2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_select2 omc_List_select2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_select2,2,0) {(void*) boxptr_List_select2,0}};
#define boxvar_List_select2 MMC_REFSTRUCTLIT(boxvar_lit_List_select2)
DLLDirection
modelica_metatype omc_List_select1r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_select1r omc_List_select1r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_select1r,2,0) {(void*) boxptr_List_select1r,0}};
#define boxvar_List_select1r MMC_REFSTRUCTLIT(boxvar_lit_List_select1r)
DLLDirection
modelica_metatype omc_List_select1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_select1 omc_List_select1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_select1,2,0) {(void*) boxptr_List_select1,0}};
#define boxvar_List_select1 MMC_REFSTRUCTLIT(boxvar_lit_List_select1)
DLLDirection
modelica_metatype omc_List_select(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_select omc_List_select
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_select,2,0) {(void*) boxptr_List_select,0}};
#define boxvar_List_select MMC_REFSTRUCTLIT(boxvar_lit_List_select)
DLLDirection
modelica_metatype omc_List_filterCons(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _fn, modelica_metatype __omcQ_24in_5FaccumList);
#define boxptr_List_filterCons omc_List_filterCons
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterCons,2,0) {(void*) boxptr_List_filterCons,0}};
#define boxvar_List_filterCons MMC_REFSTRUCTLIT(boxvar_lit_List_filterCons)
DLLDirection
modelica_metatype omc_List_removeOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_fnptr _inCompFunc, modelica_metatype _inList);
#define boxptr_List_removeOnTrue omc_List_removeOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_removeOnTrue,2,0) {(void*) boxptr_List_removeOnTrue,0}};
#define boxvar_List_removeOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_removeOnTrue)
DLLDirection
modelica_metatype omc_List_filter2OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_filter2OnTrue omc_List_filter2OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter2OnTrue,2,0) {(void*) boxptr_List_filter2OnTrue,0}};
#define boxvar_List_filter2OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_filter2OnTrue)
DLLDirection
modelica_metatype omc_List_filter1rOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_filter1rOnTrue omc_List_filter1rOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1rOnTrue,2,0) {(void*) boxptr_List_filter1rOnTrue,0}};
#define boxvar_List_filter1rOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_filter1rOnTrue)
DLLDirection
modelica_metatype omc_List_filter1OnTrueAndUpdate(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_fnptr _inUpdateFunc, modelica_metatype _inArg1);
#define boxptr_List_filter1OnTrueAndUpdate omc_List_filter1OnTrueAndUpdate
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1OnTrueAndUpdate,2,0) {(void*) boxptr_List_filter1OnTrueAndUpdate,0}};
#define boxvar_List_filter1OnTrueAndUpdate MMC_REFSTRUCTLIT(boxvar_lit_List_filter1OnTrueAndUpdate)
DLLDirection
modelica_metatype omc_List_filter1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_filter1OnTrue omc_List_filter1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1OnTrue,2,0) {(void*) boxptr_List_filter1OnTrue,0}};
#define boxvar_List_filter1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_filter1OnTrue)
DLLDirection
modelica_metatype omc_List_filter1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_filter1 omc_List_filter1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1,2,0) {(void*) boxptr_List_filter1,0}};
#define boxvar_List_filter1 MMC_REFSTRUCTLIT(boxvar_lit_List_filter1)
DLLDirection
modelica_metatype omc_List_filterOnTrueSync(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inSyncList, modelica_metatype *out_outList_b);
#define boxptr_List_filterOnTrueSync omc_List_filterOnTrueSync
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterOnTrueSync,2,0) {(void*) boxptr_List_filterOnTrueSync,0}};
#define boxvar_List_filterOnTrueSync MMC_REFSTRUCTLIT(boxvar_lit_List_filterOnTrueSync)
DLLDirection
modelica_metatype omc_List_filter1OnTrueSync(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1, modelica_metatype _inSyncList, modelica_metatype *out_outList_b);
#define boxptr_List_filter1OnTrueSync omc_List_filter1OnTrueSync
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1OnTrueSync,2,0) {(void*) boxptr_List_filter1OnTrueSync,0}};
#define boxvar_List_filter1OnTrueSync MMC_REFSTRUCTLIT(boxvar_lit_List_filter1OnTrueSync)
DLLDirection
modelica_metatype omc_List_filterOnFalse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_filterOnFalse omc_List_filterOnFalse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterOnFalse,2,0) {(void*) boxptr_List_filterOnFalse,0}};
#define boxvar_List_filterOnFalse MMC_REFSTRUCTLIT(boxvar_lit_List_filterOnFalse)
DLLDirection
modelica_metatype omc_List_filterOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_filterOnTrue omc_List_filterOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterOnTrue,2,0) {(void*) boxptr_List_filterOnTrue,0}};
#define boxvar_List_filterOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_filterOnTrue)
DLLDirection
modelica_metatype omc_List_filterMap1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterMapFunc, modelica_metatype _inExtraArg);
#define boxptr_List_filterMap1 omc_List_filterMap1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterMap1,2,0) {(void*) boxptr_List_filterMap1,0}};
#define boxvar_List_filterMap1 MMC_REFSTRUCTLIT(boxvar_lit_List_filterMap1)
DLLDirection
modelica_metatype omc_List_filterMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterMapFunc);
#define boxptr_List_filterMap omc_List_filterMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterMap,2,0) {(void*) boxptr_List_filterMap,0}};
#define boxvar_List_filterMap MMC_REFSTRUCTLIT(boxvar_lit_List_filterMap)
DLLDirection
modelica_metatype omc_List_filter(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_filter omc_List_filter
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter,2,0) {(void*) boxptr_List_filter,0}};
#define boxvar_List_filter MMC_REFSTRUCTLIT(boxvar_lit_List_filter)
DLLDirection
modelica_metatype omc_List_extract1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg, modelica_metatype *out_outRemainingList);
#define boxptr_List_extract1OnTrue omc_List_extract1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_extract1OnTrue,2,0) {(void*) boxptr_List_extract1OnTrue,0}};
#define boxvar_List_extract1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_extract1OnTrue)
DLLDirection
modelica_metatype omc_List_extractOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype *out_outRemainingList);
#define boxptr_List_extractOnTrue omc_List_extractOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_extractOnTrue,2,0) {(void*) boxptr_List_extractOnTrue,0}};
#define boxvar_List_extractOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_extractOnTrue)
DLLDirection
modelica_boolean omc_List_exist1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFindFunc, modelica_metatype _inExtraArg);
DLLDirection
modelica_metatype boxptr_List_exist1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFindFunc, modelica_metatype _inExtraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_exist1,2,0) {(void*) boxptr_List_exist1,0}};
#define boxvar_List_exist1 MMC_REFSTRUCTLIT(boxvar_lit_List_exist1)
DLLDirection
modelica_boolean omc_List_isMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inList, modelica_fnptr _inCompFunc);
DLLDirection
modelica_metatype boxptr_List_isMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inList, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isMemberOnTrue,2,0) {(void*) boxptr_List_isMemberOnTrue,0}};
#define boxvar_List_isMemberOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_isMemberOnTrue)
DLLDirection
modelica_boolean omc_List_notMember(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_notMember(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_notMember,2,0) {(void*) boxptr_List_notMember,0}};
#define boxvar_List_notMember MMC_REFSTRUCTLIT(boxvar_lit_List_notMember)
DLLDirection
modelica_metatype omc_List_getMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_getMemberOnTrue omc_List_getMemberOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_getMemberOnTrue,2,0) {(void*) boxptr_List_getMemberOnTrue,0}};
#define boxvar_List_getMemberOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_getMemberOnTrue)
DLLDirection
modelica_metatype omc_List_getMember(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
#define boxptr_List_getMember omc_List_getMember
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_getMember,2,0) {(void*) boxptr_List_getMember,0}};
#define boxvar_List_getMember MMC_REFSTRUCTLIT(boxvar_lit_List_getMember)
DLLDirection
modelica_integer omc_List_position1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPredFunc, modelica_metatype _inArg);
DLLDirection
modelica_metatype boxptr_List_position1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPredFunc, modelica_metatype _inArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_position1OnTrue,2,0) {(void*) boxptr_List_position1OnTrue,0}};
#define boxvar_List_position1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_position1OnTrue)
DLLDirection
modelica_integer omc_List_positionOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPredFunc);
DLLDirection
modelica_metatype boxptr_List_positionOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPredFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_positionOnTrue,2,0) {(void*) boxptr_List_positionOnTrue,0}};
#define boxvar_List_positionOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_positionOnTrue)
DLLDirection
modelica_integer omc_List_position(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_position(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_position,2,0) {(void*) boxptr_List_position,0}};
#define boxvar_List_position MMC_REFSTRUCTLIT(boxvar_lit_List_position)
DLLDirection
modelica_metatype omc_List_threadMapFold(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_threadMapFold omc_List_threadMapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMapFold,2,0) {(void*) boxptr_List_threadMapFold,0}};
#define boxvar_List_threadMapFold MMC_REFSTRUCTLIT(boxvar_lit_List_threadMapFold)
DLLDirection
modelica_metatype omc_List_threadFold(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold omc_List_threadFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold,2,0) {(void*) boxptr_List_threadFold,0}};
#define boxvar_List_threadFold MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold)
DLLDirection
modelica_metatype omc_List_threadFold3(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold3 omc_List_threadFold3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold3,2,0) {(void*) boxptr_List_threadFold3,0}};
#define boxvar_List_threadFold3 MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold3)
DLLDirection
modelica_metatype omc_List_threadFold2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold2 omc_List_threadFold2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold2,2,0) {(void*) boxptr_List_threadFold2,0}};
#define boxvar_List_threadFold2 MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold2)
DLLDirection
modelica_metatype omc_List_threadFold1(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold1 omc_List_threadFold1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold1,2,0) {(void*) boxptr_List_threadFold1,0}};
#define boxvar_List_threadFold1 MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold1)
DLLDirection
modelica_metatype omc_List_thread3MapFold(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inList3, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_thread3MapFold omc_List_thread3MapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread3MapFold,2,0) {(void*) boxptr_List_thread3MapFold,0}};
#define boxvar_List_thread3MapFold MMC_REFSTRUCTLIT(boxvar_lit_List_thread3MapFold)
DLLDirection
modelica_metatype omc_List_thread3Map(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inList3, modelica_fnptr _inFunc);
#define boxptr_List_thread3Map omc_List_thread3Map
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread3Map,2,0) {(void*) boxptr_List_thread3Map,0}};
#define boxvar_List_thread3Map MMC_REFSTRUCTLIT(boxvar_lit_List_thread3Map)
DLLDirection
modelica_metatype omc_List_threadMap2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_threadMap2 omc_List_threadMap2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap2,2,0) {(void*) boxptr_List_threadMap2,0}};
#define boxvar_List_threadMap2 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap2)
DLLDirection
void omc_List_threadMap1__0(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_threadMap1__0 omc_List_threadMap1__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap1__0,2,0) {(void*) boxptr_List_threadMap1__0,0}};
#define boxvar_List_threadMap1__0 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap1__0)
DLLDirection
modelica_metatype omc_List_threadMap1(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_threadMap1 omc_List_threadMap1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap1,2,0) {(void*) boxptr_List_threadMap1,0}};
#define boxvar_List_threadMap1 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap1)
DLLDirection
modelica_metatype omc_List_threadMapList__2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype *out_outList2);
#define boxptr_List_threadMapList__2 omc_List_threadMapList__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMapList__2,2,0) {(void*) boxptr_List_threadMapList__2,0}};
#define boxvar_List_threadMapList__2 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMapList__2)
DLLDirection
modelica_metatype omc_List_threadMapList(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc);
#define boxptr_List_threadMapList omc_List_threadMapList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMapList,2,0) {(void*) boxptr_List_threadMapList,0}};
#define boxvar_List_threadMapList MMC_REFSTRUCTLIT(boxvar_lit_List_threadMapList)
DLLDirection
modelica_metatype omc_List_threadMap__2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype *out_outList2);
#define boxptr_List_threadMap__2 omc_List_threadMap__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap__2,2,0) {(void*) boxptr_List_threadMap__2,0}};
#define boxvar_List_threadMap__2 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap__2)
DLLDirection
modelica_metatype omc_List_threadMap(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc);
#define boxptr_List_threadMap omc_List_threadMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap,2,0) {(void*) boxptr_List_threadMap,0}};
#define boxvar_List_threadMap MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap)
DLLDirection
modelica_metatype omc_List_unzipSecond(threadData_t *threadData, modelica_metatype _inTuples);
#define boxptr_List_unzipSecond omc_List_unzipSecond
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unzipSecond,2,0) {(void*) boxptr_List_unzipSecond,0}};
#define boxvar_List_unzipSecond MMC_REFSTRUCTLIT(boxvar_lit_List_unzipSecond)
DLLDirection
modelica_metatype omc_List_unzip3(threadData_t *threadData, modelica_metatype _tuples, modelica_metatype *out_l2, modelica_metatype *out_l3);
#define boxptr_List_unzip3 omc_List_unzip3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unzip3,2,0) {(void*) boxptr_List_unzip3,0}};
#define boxvar_List_unzip3 MMC_REFSTRUCTLIT(boxvar_lit_List_unzip3)
DLLDirection
modelica_metatype omc_List_unzip(threadData_t *threadData, modelica_metatype _inTuples, modelica_metatype *out_outList2);
#define boxptr_List_unzip omc_List_unzip
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unzip,2,0) {(void*) boxptr_List_unzip,0}};
#define boxvar_List_unzip MMC_REFSTRUCTLIT(boxvar_lit_List_unzip)
DLLDirection
modelica_metatype omc_List_zip3(threadData_t *threadData, modelica_metatype _l1, modelica_metatype _l2, modelica_metatype _l3);
#define boxptr_List_zip3 omc_List_zip3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_zip3,2,0) {(void*) boxptr_List_zip3,0}};
#define boxvar_List_zip3 MMC_REFSTRUCTLIT(boxvar_lit_List_zip3)
DLLDirection
modelica_metatype omc_List_zip(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_zip omc_List_zip
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_zip,2,0) {(void*) boxptr_List_zip,0}};
#define boxvar_List_zip MMC_REFSTRUCTLIT(boxvar_lit_List_zip)
DLLDirection
modelica_metatype omc_List_thread(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inAccum);
#define boxptr_List_thread omc_List_thread
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread,2,0) {(void*) boxptr_List_thread,0}};
#define boxvar_List_thread MMC_REFSTRUCTLIT(boxvar_lit_List_thread)
DLLDirection
modelica_metatype omc_List_flattenReverse(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_flattenReverse omc_List_flattenReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_flattenReverse,2,0) {(void*) boxptr_List_flattenReverse,0}};
#define boxvar_List_flattenReverse MMC_REFSTRUCTLIT(boxvar_lit_List_flattenReverse)
DLLDirection
modelica_metatype omc_List_flatten(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_flatten omc_List_flatten
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_flatten,2,0) {(void*) boxptr_List_flatten,0}};
#define boxvar_List_flatten MMC_REFSTRUCTLIT(boxvar_lit_List_flatten)
DLLDirection
modelica_metatype omc_List_reduce(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inReduceFunc);
#define boxptr_List_reduce omc_List_reduce
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_reduce,2,0) {(void*) boxptr_List_reduce,0}};
#define boxvar_List_reduce MMC_REFSTRUCTLIT(boxvar_lit_List_reduce)
DLLDirection
modelica_metatype omc_List_mapFoldList(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_mapFoldList omc_List_mapFoldList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFoldList,2,0) {(void*) boxptr_List_mapFoldList,0}};
#define boxvar_List_mapFoldList MMC_REFSTRUCTLIT(boxvar_lit_List_mapFoldList)
DLLDirection
modelica_metatype omc_List_map3Fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inConstArg2, modelica_metatype _inConstArg3, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_map3Fold omc_List_map3Fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map3Fold,2,0) {(void*) boxptr_List_map3Fold,0}};
#define boxvar_List_map3Fold MMC_REFSTRUCTLIT(boxvar_lit_List_map3Fold)
DLLDirection
modelica_metatype omc_List_map2FoldCheckReferenceEq(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inConstArg2, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_map2FoldCheckReferenceEq omc_List_map2FoldCheckReferenceEq
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2FoldCheckReferenceEq,2,0) {(void*) boxptr_List_map2FoldCheckReferenceEq,0}};
#define boxvar_List_map2FoldCheckReferenceEq MMC_REFSTRUCTLIT(boxvar_lit_List_map2FoldCheckReferenceEq)
DLLDirection
modelica_metatype omc_List_map2Fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inConstArg2, modelica_metatype _inArg, modelica_metatype _inAccum, modelica_metatype *out_outArg);
#define boxptr_List_map2Fold omc_List_map2Fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2Fold,2,0) {(void*) boxptr_List_map2Fold,0}};
#define boxvar_List_map2Fold MMC_REFSTRUCTLIT(boxvar_lit_List_map2Fold)
DLLDirection
modelica_metatype omc_List_map1Fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_map1Fold omc_List_map1Fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1Fold,2,0) {(void*) boxptr_List_map1Fold,0}};
#define boxvar_List_map1Fold MMC_REFSTRUCTLIT(boxvar_lit_List_map1Fold)
DLLDirection
modelica_metatype omc_List_mapFold5(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype __omcQ_24in_5FinArg1, modelica_metatype __omcQ_24in_5FinArg2, modelica_metatype __omcQ_24in_5FinArg3, modelica_metatype __omcQ_24in_5FinArg4, modelica_metatype __omcQ_24in_5FinArg5, modelica_metatype *out_inArg1, modelica_metatype *out_inArg2, modelica_metatype *out_inArg3, modelica_metatype *out_inArg4, modelica_metatype *out_inArg5);
#define boxptr_List_mapFold5 omc_List_mapFold5
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold5,2,0) {(void*) boxptr_List_mapFold5,0}};
#define boxvar_List_mapFold5 MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold5)
DLLDirection
modelica_metatype omc_List_mapFold3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype __omcQ_24in_5FinArg1, modelica_metatype __omcQ_24in_5FinArg2, modelica_metatype __omcQ_24in_5FinArg3, modelica_metatype *out_inArg1, modelica_metatype *out_inArg2, modelica_metatype *out_inArg3);
#define boxptr_List_mapFold3 omc_List_mapFold3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold3,2,0) {(void*) boxptr_List_mapFold3,0}};
#define boxvar_List_mapFold3 MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold3)
DLLDirection
modelica_metatype omc_List_mapFold2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype *out_outArg1, modelica_metatype *out_outArg2);
#define boxptr_List_mapFold2 omc_List_mapFold2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold2,2,0) {(void*) boxptr_List_mapFold2,0}};
#define boxvar_List_mapFold2 MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold2)
DLLDirection
modelica_metatype omc_List_mapFold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_mapFold omc_List_mapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold,2,0) {(void*) boxptr_List_mapFold,0}};
#define boxvar_List_mapFold MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold)
DLLDirection
modelica_metatype omc_List_fold31(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype _inStartValue3, modelica_metatype *out_outResult2, modelica_metatype *out_outResult3);
#define boxptr_List_fold31 omc_List_fold31
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold31,2,0) {(void*) boxptr_List_fold31,0}};
#define boxvar_List_fold31 MMC_REFSTRUCTLIT(boxvar_lit_List_fold31)
DLLDirection
modelica_metatype omc_List_fold21(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype *out_outResult2);
#define boxptr_List_fold21 omc_List_fold21
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold21,2,0) {(void*) boxptr_List_fold21,0}};
#define boxvar_List_fold21 MMC_REFSTRUCTLIT(boxvar_lit_List_fold21)
DLLDirection
modelica_metatype omc_List_fold20(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype *out_outResult2);
#define boxptr_List_fold20 omc_List_fold20
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold20,2,0) {(void*) boxptr_List_fold20,0}};
#define boxvar_List_fold20 MMC_REFSTRUCTLIT(boxvar_lit_List_fold20)
DLLDirection
modelica_metatype omc_List_fold4(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inExtraArg3, modelica_metatype _inExtraArg4, modelica_metatype _inStartValue);
#define boxptr_List_fold4 omc_List_fold4
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold4,2,0) {(void*) boxptr_List_fold4,0}};
#define boxvar_List_fold4 MMC_REFSTRUCTLIT(boxvar_lit_List_fold4)
DLLDirection
modelica_metatype omc_List_fold3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inExtraArg3, modelica_metatype _inStartValue);
#define boxptr_List_fold3 omc_List_fold3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold3,2,0) {(void*) boxptr_List_fold3,0}};
#define boxvar_List_fold3 MMC_REFSTRUCTLIT(boxvar_lit_List_fold3)
DLLDirection
modelica_metatype omc_List_fold2r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inStartValue);
#define boxptr_List_fold2r omc_List_fold2r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold2r,2,0) {(void*) boxptr_List_fold2r,0}};
#define boxvar_List_fold2r MMC_REFSTRUCTLIT(boxvar_lit_List_fold2r)
DLLDirection
modelica_metatype omc_List_foldList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
#define boxptr_List_foldList omc_List_foldList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_foldList,2,0) {(void*) boxptr_List_foldList,0}};
#define boxvar_List_foldList MMC_REFSTRUCTLIT(boxvar_lit_List_foldList)
DLLDirection
modelica_metatype omc_List_fold22(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype *out_outResult2);
#define boxptr_List_fold22 omc_List_fold22
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold22,2,0) {(void*) boxptr_List_fold22,0}};
#define boxvar_List_fold22 MMC_REFSTRUCTLIT(boxvar_lit_List_fold22)
DLLDirection
modelica_metatype omc_List_fold2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inStartValue);
#define boxptr_List_fold2 omc_List_fold2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold2,2,0) {(void*) boxptr_List_fold2,0}};
#define boxvar_List_fold2 MMC_REFSTRUCTLIT(boxvar_lit_List_fold2)
DLLDirection
modelica_metatype omc_List_fold1r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg, modelica_metatype _inStartValue);
#define boxptr_List_fold1r omc_List_fold1r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold1r,2,0) {(void*) boxptr_List_fold1r,0}};
#define boxvar_List_fold1r MMC_REFSTRUCTLIT(boxvar_lit_List_fold1r)
DLLDirection
modelica_metatype omc_List_fold1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg, modelica_metatype _inStartValue);
#define boxptr_List_fold1 omc_List_fold1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold1,2,0) {(void*) boxptr_List_fold1,0}};
#define boxvar_List_fold1 MMC_REFSTRUCTLIT(boxvar_lit_List_fold1)
DLLDirection
modelica_metatype omc_List_foldr(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
#define boxptr_List_foldr omc_List_foldr
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_foldr,2,0) {(void*) boxptr_List_foldr,0}};
#define boxvar_List_foldr MMC_REFSTRUCTLIT(boxvar_lit_List_foldr)
DLLDirection
modelica_metatype omc_List_fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
#define boxptr_List_fold omc_List_fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold,2,0) {(void*) boxptr_List_fold,0}};
#define boxvar_List_fold MMC_REFSTRUCTLIT(boxvar_lit_List_fold)
DLLDirection
modelica_metatype omc_List_map2List(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2List omc_List_map2List
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2List,2,0) {(void*) boxptr_List_map2List,0}};
#define boxvar_List_map2List MMC_REFSTRUCTLIT(boxvar_lit_List_map2List)
DLLDirection
modelica_metatype omc_List_map1List(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_map1List omc_List_map1List
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1List,2,0) {(void*) boxptr_List_map1List,0}};
#define boxvar_List_map1List MMC_REFSTRUCTLIT(boxvar_lit_List_map1List)
DLLDirection
modelica_metatype omc_List_mapListReverse(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc);
#define boxptr_List_mapListReverse omc_List_mapListReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapListReverse,2,0) {(void*) boxptr_List_mapListReverse,0}};
#define boxvar_List_mapListReverse MMC_REFSTRUCTLIT(boxvar_lit_List_mapListReverse)
DLLDirection
modelica_metatype omc_List_mapList(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc);
#define boxptr_List_mapList omc_List_mapList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapList,2,0) {(void*) boxptr_List_mapList,0}};
#define boxvar_List_mapList MMC_REFSTRUCTLIT(boxvar_lit_List_mapList)
DLLDirection
modelica_boolean omc_List_mapMapBoolAnd(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_fnptr _inBFunc);
DLLDirection
modelica_metatype boxptr_List_mapMapBoolAnd(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_fnptr _inBFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapMapBoolAnd,2,0) {(void*) boxptr_List_mapMapBoolAnd,0}};
#define boxvar_List_mapMapBoolAnd MMC_REFSTRUCTLIT(boxvar_lit_List_mapMapBoolAnd)
DLLDirection
modelica_metatype omc_List_applyAndFold1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_fnptr _inApplyFunc, modelica_metatype _inExtraArg, modelica_metatype _inFoldArg);
#define boxptr_List_applyAndFold1 omc_List_applyAndFold1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_applyAndFold1,2,0) {(void*) boxptr_List_applyAndFold1,0}};
#define boxvar_List_applyAndFold1 MMC_REFSTRUCTLIT(boxvar_lit_List_applyAndFold1)
DLLDirection
modelica_metatype omc_List_applyAndFold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_fnptr _inApplyFunc, modelica_metatype _inFoldArg);
#define boxptr_List_applyAndFold omc_List_applyAndFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_applyAndFold,2,0) {(void*) boxptr_List_applyAndFold,0}};
#define boxvar_List_applyAndFold MMC_REFSTRUCTLIT(boxvar_lit_List_applyAndFold)
DLLDirection
void omc_List_foldAllValue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1);
#define boxptr_List_foldAllValue omc_List_foldAllValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_foldAllValue,2,0) {(void*) boxptr_List_foldAllValue,0}};
#define boxvar_List_foldAllValue MMC_REFSTRUCTLIT(boxvar_lit_List_foldAllValue)
DLLDirection
modelica_metatype omc_List_mapMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc1, modelica_fnptr _inMapFunc2);
#define boxptr_List_mapMap omc_List_mapMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapMap,2,0) {(void*) boxptr_List_mapMap,0}};
#define boxvar_List_mapMap MMC_REFSTRUCTLIT(boxvar_lit_List_mapMap)
DLLDirection
modelica_metatype omc_List_mapFlatReverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc);
#define boxptr_List_mapFlatReverse omc_List_mapFlatReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFlatReverse,2,0) {(void*) boxptr_List_mapFlatReverse,0}};
#define boxvar_List_mapFlatReverse MMC_REFSTRUCTLIT(boxvar_lit_List_mapFlatReverse)
DLLDirection
modelica_metatype omc_List_mapFlat(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc);
#define boxptr_List_mapFlat omc_List_mapFlat
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFlat,2,0) {(void*) boxptr_List_mapFlat,0}};
#define boxvar_List_mapFlat MMC_REFSTRUCTLIT(boxvar_lit_List_mapFlat)
DLLDirection
modelica_metatype omc_List_map6(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inArg6);
#define boxptr_List_map6 omc_List_map6
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map6,2,0) {(void*) boxptr_List_map6,0}};
#define boxvar_List_map6 MMC_REFSTRUCTLIT(boxvar_lit_List_map6)
DLLDirection
modelica_metatype omc_List_map5(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5);
#define boxptr_List_map5 omc_List_map5
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map5,2,0) {(void*) boxptr_List_map5,0}};
#define boxvar_List_map5 MMC_REFSTRUCTLIT(boxvar_lit_List_map5)
DLLDirection
void omc_List_map4__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4);
#define boxptr_List_map4__0 omc_List_map4__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map4__0,2,0) {(void*) boxptr_List_map4__0,0}};
#define boxvar_List_map4__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map4__0)
DLLDirection
modelica_metatype omc_List_map4(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4);
#define boxptr_List_map4 omc_List_map4
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map4,2,0) {(void*) boxptr_List_map4,0}};
#define boxvar_List_map4 MMC_REFSTRUCTLIT(boxvar_lit_List_map4)
DLLDirection
modelica_metatype omc_List_map3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3);
#define boxptr_List_map3 omc_List_map3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map3,2,0) {(void*) boxptr_List_map3,0}};
#define boxvar_List_map3 MMC_REFSTRUCTLIT(boxvar_lit_List_map3)
DLLDirection
modelica_metatype omc_List_map2__2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype *out_outList2);
#define boxptr_List_map2__2 omc_List_map2__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2__2,2,0) {(void*) boxptr_List_map2__2,0}};
#define boxvar_List_map2__2 MMC_REFSTRUCTLIT(boxvar_lit_List_map2__2)
DLLDirection
void omc_List_map2__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2__0 omc_List_map2__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2__0,2,0) {(void*) boxptr_List_map2__0,0}};
#define boxvar_List_map2__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map2__0)
DLLDirection
modelica_metatype omc_List_map2Reverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2Reverse omc_List_map2Reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2Reverse,2,0) {(void*) boxptr_List_map2Reverse,0}};
#define boxvar_List_map2Reverse MMC_REFSTRUCTLIT(boxvar_lit_List_map2Reverse)
DLLDirection
modelica_metatype omc_List_map2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2 omc_List_map2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2,2,0) {(void*) boxptr_List_map2,0}};
#define boxvar_List_map2 MMC_REFSTRUCTLIT(boxvar_lit_List_map2)
DLLDirection
modelica_metatype omc_List_map1__2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype *out_outList2);
#define boxptr_List_map1__2 omc_List_map1__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1__2,2,0) {(void*) boxptr_List_map1__2,0}};
#define boxvar_List_map1__2 MMC_REFSTRUCTLIT(boxvar_lit_List_map1__2)
DLLDirection
void omc_List_map1__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_map1__0 omc_List_map1__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1__0,2,0) {(void*) boxptr_List_map1__0,0}};
#define boxvar_List_map1__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map1__0)
DLLDirection
modelica_metatype omc_List_map1r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_map1r omc_List_map1r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1r,2,0) {(void*) boxptr_List_map1r,0}};
#define boxvar_List_map1r MMC_REFSTRUCTLIT(boxvar_lit_List_map1r)
DLLDirection
modelica_metatype omc_List_map1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_map1 omc_List_map1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1,2,0) {(void*) boxptr_List_map1,0}};
#define boxvar_List_map1 MMC_REFSTRUCTLIT(boxvar_lit_List_map1)
DLLDirection
void omc_List_map__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_map__0 omc_List_map__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map__0,2,0) {(void*) boxptr_List_map__0,0}};
#define boxvar_List_map__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map__0)
DLLDirection
modelica_metatype omc_List_map2Option(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2Option omc_List_map2Option
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2Option,2,0) {(void*) boxptr_List_map2Option,0}};
#define boxvar_List_map2Option MMC_REFSTRUCTLIT(boxvar_lit_List_map2Option)
DLLDirection
modelica_metatype omc_List_map1Option(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_map1Option omc_List_map1Option
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1Option,2,0) {(void*) boxptr_List_map1Option,0}};
#define boxvar_List_map1Option MMC_REFSTRUCTLIT(boxvar_lit_List_map1Option)
DLLDirection
modelica_metatype omc_List_mapOption(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_mapOption omc_List_mapOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapOption,2,0) {(void*) boxptr_List_mapOption,0}};
#define boxvar_List_mapOption MMC_REFSTRUCTLIT(boxvar_lit_List_mapOption)
DLLDirection
modelica_metatype omc_List_map__3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outList2, modelica_metatype *out_outList3);
#define boxptr_List_map__3 omc_List_map__3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map__3,2,0) {(void*) boxptr_List_map__3,0}};
#define boxvar_List_map__3 MMC_REFSTRUCTLIT(boxvar_lit_List_map__3)
DLLDirection
modelica_metatype omc_List_map__2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outList2);
#define boxptr_List_map__2 omc_List_map__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map__2,2,0) {(void*) boxptr_List_map__2,0}};
#define boxvar_List_map__2 MMC_REFSTRUCTLIT(boxvar_lit_List_map__2)
DLLDirection
modelica_metatype omc_List_mapReverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_mapReverse omc_List_mapReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapReverse,2,0) {(void*) boxptr_List_mapReverse,0}};
#define boxvar_List_mapReverse MMC_REFSTRUCTLIT(boxvar_lit_List_mapReverse)
DLLDirection
modelica_metatype omc_List_mapCheckReferenceEq(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_mapCheckReferenceEq omc_List_mapCheckReferenceEq
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapCheckReferenceEq,2,0) {(void*) boxptr_List_mapCheckReferenceEq,0}};
#define boxvar_List_mapCheckReferenceEq MMC_REFSTRUCTLIT(boxvar_lit_List_mapCheckReferenceEq)
DLLDirection
modelica_metatype omc_List_mapArray(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc);
#define boxptr_List_mapArray omc_List_mapArray
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapArray,2,0) {(void*) boxptr_List_mapArray,0}};
#define boxvar_List_mapArray MMC_REFSTRUCTLIT(boxvar_lit_List_mapArray)
DLLDirection
modelica_metatype omc_List_map(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_map omc_List_map
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map,2,0) {(void*) boxptr_List_map,0}};
#define boxvar_List_map MMC_REFSTRUCTLIT(boxvar_lit_List_map)
DLLDirection
modelica_metatype omc_List_unionOnTrueList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_unionOnTrueList omc_List_unionOnTrueList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionOnTrueList,2,0) {(void*) boxptr_List_unionOnTrueList,0}};
#define boxvar_List_unionOnTrueList MMC_REFSTRUCTLIT(boxvar_lit_List_unionOnTrueList)
DLLDirection
modelica_metatype omc_List_unionList(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_unionList omc_List_unionList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionList,2,0) {(void*) boxptr_List_unionList,0}};
#define boxvar_List_unionList MMC_REFSTRUCTLIT(boxvar_lit_List_unionList)
DLLDirection
modelica_metatype omc_List_unionAppendListOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inUnion, modelica_fnptr _inCompFunc);
#define boxptr_List_unionAppendListOnTrue omc_List_unionAppendListOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionAppendListOnTrue,2,0) {(void*) boxptr_List_unionAppendListOnTrue,0}};
#define boxvar_List_unionAppendListOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_unionAppendListOnTrue)
DLLDirection
modelica_metatype omc_List_unionOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_unionOnTrue omc_List_unionOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionOnTrue,2,0) {(void*) boxptr_List_unionOnTrue,0}};
#define boxvar_List_unionOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_unionOnTrue)
DLLDirection
modelica_metatype omc_List_union(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_union omc_List_union
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_union,2,0) {(void*) boxptr_List_union,0}};
#define boxvar_List_union MMC_REFSTRUCTLIT(boxvar_lit_List_union)
DLLDirection
modelica_metatype omc_List_unionEltOnTrue(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_unionEltOnTrue omc_List_unionEltOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionEltOnTrue,2,0) {(void*) boxptr_List_unionEltOnTrue,0}};
#define boxvar_List_unionEltOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_unionEltOnTrue)
DLLDirection
modelica_metatype omc_List_unionElt(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
#define boxptr_List_unionElt omc_List_unionElt
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionElt,2,0) {(void*) boxptr_List_unionElt,0}};
#define boxvar_List_unionElt MMC_REFSTRUCTLIT(boxvar_lit_List_unionElt)
DLLDirection
modelica_metatype omc_List_unionIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_integer _inN);
DLLDirection
modelica_metatype boxptr_List_unionIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionIntN,2,0) {(void*) boxptr_List_unionIntN,0}};
#define boxvar_List_unionIntN MMC_REFSTRUCTLIT(boxvar_lit_List_unionIntN)
DLLDirection
modelica_metatype omc_List_setDifference(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_setDifference omc_List_setDifference
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_setDifference,2,0) {(void*) boxptr_List_setDifference,0}};
#define boxvar_List_setDifference MMC_REFSTRUCTLIT(boxvar_lit_List_setDifference)
DLLDirection
modelica_metatype omc_List_setDifferenceOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_setDifferenceOnTrue omc_List_setDifferenceOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_setDifferenceOnTrue,2,0) {(void*) boxptr_List_setDifferenceOnTrue,0}};
#define boxvar_List_setDifferenceOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_setDifferenceOnTrue)
DLLDirection
modelica_metatype omc_List_setDifferenceIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_integer _inN);
DLLDirection
modelica_metatype boxptr_List_setDifferenceIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_setDifferenceIntN,2,0) {(void*) boxptr_List_setDifferenceIntN,0}};
#define boxvar_List_setDifferenceIntN MMC_REFSTRUCTLIT(boxvar_lit_List_setDifferenceIntN)
DLLDirection
modelica_metatype omc_List_intersection1OnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc, modelica_metatype *out_outList1Rest, modelica_metatype *out_outList2Rest);
#define boxptr_List_intersection1OnTrue omc_List_intersection1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intersection1OnTrue,2,0) {(void*) boxptr_List_intersection1OnTrue,0}};
#define boxvar_List_intersection1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_intersection1OnTrue)
DLLDirection
modelica_metatype omc_List_intersectionOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_intersectionOnTrue omc_List_intersectionOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intersectionOnTrue,2,0) {(void*) boxptr_List_intersectionOnTrue,0}};
#define boxvar_List_intersectionOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_intersectionOnTrue)
DLLDirection
modelica_boolean omc_List_setEqualOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
DLLDirection
modelica_metatype boxptr_List_setEqualOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_setEqualOnTrue,2,0) {(void*) boxptr_List_setEqualOnTrue,0}};
#define boxvar_List_setEqualOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_setEqualOnTrue)
DLLDirection
modelica_metatype omc_List_listArrayReverse(threadData_t *threadData, modelica_metatype _inLst);
#define boxptr_List_listArrayReverse omc_List_listArrayReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_listArrayReverse,2,0) {(void*) boxptr_List_listArrayReverse,0}};
#define boxvar_List_listArrayReverse MMC_REFSTRUCTLIT(boxvar_lit_List_listArrayReverse)
DLLDirection
modelica_metatype omc_List_transposeList(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_transposeList omc_List_transposeList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_transposeList,2,0) {(void*) boxptr_List_transposeList,0}};
#define boxvar_List_transposeList MMC_REFSTRUCTLIT(boxvar_lit_List_transposeList)
DLLDirection
modelica_metatype omc_List_sublist(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inOffset, modelica_integer _inLength);
DLLDirection
modelica_metatype boxptr_List_sublist(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inOffset, modelica_metatype _inLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sublist,2,0) {(void*) boxptr_List_sublist,0}};
#define boxvar_List_sublist MMC_REFSTRUCTLIT(boxvar_lit_List_sublist)
DLLDirection
modelica_metatype omc_List_balancedPartition(threadData_t *threadData, modelica_metatype _lst, modelica_integer _maxLength);
DLLDirection
modelica_metatype boxptr_List_balancedPartition(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _maxLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_balancedPartition,2,0) {(void*) boxptr_List_balancedPartition,0}};
#define boxvar_List_balancedPartition MMC_REFSTRUCTLIT(boxvar_lit_List_balancedPartition)
DLLDirection
modelica_metatype omc_List_partition(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inPartitionLength);
DLLDirection
modelica_metatype boxptr_List_partition(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPartitionLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_partition,2,0) {(void*) boxptr_List_partition,0}};
#define boxvar_List_partition MMC_REFSTRUCTLIT(boxvar_lit_List_partition)
DLLDirection
modelica_metatype omc_List_splitOnBoolList(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inBools, modelica_metatype *out_outFalseList);
#define boxptr_List_splitOnBoolList omc_List_splitOnBoolList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitOnBoolList,2,0) {(void*) boxptr_List_splitOnBoolList,0}};
#define boxvar_List_splitOnBoolList MMC_REFSTRUCTLIT(boxvar_lit_List_splitOnBoolList)
DLLDirection
modelica_metatype omc_List_splitEqualParts(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inParts);
DLLDirection
modelica_metatype boxptr_List_splitEqualParts(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inParts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitEqualParts,2,0) {(void*) boxptr_List_splitEqualParts,0}};
#define boxvar_List_splitEqualParts MMC_REFSTRUCTLIT(boxvar_lit_List_splitEqualParts)
DLLDirection
modelica_metatype omc_List_splitLast(threadData_t *threadData, modelica_metatype _inList, modelica_metatype *out_outRest);
#define boxptr_List_splitLast omc_List_splitLast
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitLast,2,0) {(void*) boxptr_List_splitLast,0}};
#define boxvar_List_splitLast MMC_REFSTRUCTLIT(boxvar_lit_List_splitLast)
DLLDirection
modelica_metatype omc_List_splitOnFirstMatch(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outList2);
#define boxptr_List_splitOnFirstMatch omc_List_splitOnFirstMatch
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitOnFirstMatch,2,0) {(void*) boxptr_List_splitOnFirstMatch,0}};
#define boxvar_List_splitOnFirstMatch MMC_REFSTRUCTLIT(boxvar_lit_List_splitOnFirstMatch)
DLLDirection
modelica_metatype omc_List_split2OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype *out_outFalseList);
#define boxptr_List_split2OnTrue omc_List_split2OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_split2OnTrue,2,0) {(void*) boxptr_List_split2OnTrue,0}};
#define boxvar_List_split2OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_split2OnTrue)
DLLDirection
modelica_metatype omc_List_split1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype *out_outFalseList);
#define boxptr_List_split1OnTrue omc_List_split1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_split1OnTrue,2,0) {(void*) boxptr_List_split1OnTrue,0}};
#define boxvar_List_split1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_split1OnTrue)
DLLDirection
modelica_metatype omc_List_splitOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outFalseList);
#define boxptr_List_splitOnTrue omc_List_splitOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitOnTrue,2,0) {(void*) boxptr_List_splitOnTrue,0}};
#define boxvar_List_splitOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_splitOnTrue)
DLLDirection
modelica_metatype omc_List_splitr(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inPosition, modelica_metatype *out_outList2);
DLLDirection
modelica_metatype boxptr_List_splitr(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPosition, modelica_metatype *out_outList2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitr,2,0) {(void*) boxptr_List_splitr,0}};
#define boxvar_List_splitr MMC_REFSTRUCTLIT(boxvar_lit_List_splitr)
DLLDirection
modelica_metatype omc_List_split(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inPosition, modelica_metatype *out_outList2);
DLLDirection
modelica_metatype boxptr_List_split(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPosition, modelica_metatype *out_outList2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_split,2,0) {(void*) boxptr_List_split,0}};
#define boxvar_List_split MMC_REFSTRUCTLIT(boxvar_lit_List_split)
DLLDirection
modelica_metatype omc_List_uniqueOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_uniqueOnTrue omc_List_uniqueOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_uniqueOnTrue,2,0) {(void*) boxptr_List_uniqueOnTrue,0}};
#define boxvar_List_uniqueOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_uniqueOnTrue)
DLLDirection
modelica_metatype omc_List_uniqueIntN(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN);
DLLDirection
modelica_metatype boxptr_List_uniqueIntN(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_uniqueIntN,2,0) {(void*) boxptr_List_uniqueIntN,0}};
#define boxvar_List_uniqueIntN MMC_REFSTRUCTLIT(boxvar_lit_List_uniqueIntN)
DLLDirection
modelica_metatype omc_List_unique(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_unique omc_List_unique
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unique,2,0) {(void*) boxptr_List_unique,0}};
#define boxvar_List_unique MMC_REFSTRUCTLIT(boxvar_lit_List_unique)
DLLDirection
modelica_metatype omc_List_countingSort(threadData_t *threadData, modelica_metatype _inList, modelica_integer _N);
DLLDirection
modelica_metatype boxptr_List_countingSort(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _N);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_countingSort,2,0) {(void*) boxptr_List_countingSort,0}};
#define boxvar_List_countingSort MMC_REFSTRUCTLIT(boxvar_lit_List_countingSort)
DLLDirection
modelica_metatype omc_List_mergeSorted(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_mergeSorted omc_List_mergeSorted
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mergeSorted,2,0) {(void*) boxptr_List_mergeSorted,0}};
#define boxvar_List_mergeSorted MMC_REFSTRUCTLIT(boxvar_lit_List_mergeSorted)
#define boxptr_List_merge omc_List_merge
DLLDirection
modelica_metatype omc_List_sortedUniqueOnlyDuplicates(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_sortedUniqueOnlyDuplicates omc_List_sortedUniqueOnlyDuplicates
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedUniqueOnlyDuplicates,2,0) {(void*) boxptr_List_sortedUniqueOnlyDuplicates,0}};
#define boxvar_List_sortedUniqueOnlyDuplicates MMC_REFSTRUCTLIT(boxvar_lit_List_sortedUniqueOnlyDuplicates)
DLLDirection
modelica_metatype omc_List_sortedUniqueAndDuplicates(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc, modelica_metatype *out_outDuplicateElements);
#define boxptr_List_sortedUniqueAndDuplicates omc_List_sortedUniqueAndDuplicates
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedUniqueAndDuplicates,2,0) {(void*) boxptr_List_sortedUniqueAndDuplicates,0}};
#define boxvar_List_sortedUniqueAndDuplicates MMC_REFSTRUCTLIT(boxvar_lit_List_sortedUniqueAndDuplicates)
DLLDirection
modelica_metatype omc_List_sortedUnique(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_sortedUnique omc_List_sortedUnique
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedUnique,2,0) {(void*) boxptr_List_sortedUnique,0}};
#define boxvar_List_sortedUnique MMC_REFSTRUCTLIT(boxvar_lit_List_sortedUnique)
DLLDirection
modelica_boolean omc_List_sortedListAllUnique(threadData_t *threadData, modelica_metatype _lst, modelica_fnptr _compareFn);
DLLDirection
modelica_metatype boxptr_List_sortedListAllUnique(threadData_t *threadData, modelica_metatype _lst, modelica_fnptr _compareFn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedListAllUnique,2,0) {(void*) boxptr_List_sortedListAllUnique,0}};
#define boxvar_List_sortedListAllUnique MMC_REFSTRUCTLIT(boxvar_lit_List_sortedListAllUnique)
DLLDirection
modelica_metatype omc_List_sortedDuplicates(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_sortedDuplicates omc_List_sortedDuplicates
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedDuplicates,2,0) {(void*) boxptr_List_sortedDuplicates,0}};
#define boxvar_List_sortedDuplicates MMC_REFSTRUCTLIT(boxvar_lit_List_sortedDuplicates)
DLLDirection
modelica_metatype omc_List_sort(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_sort omc_List_sort
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sort,2,0) {(void*) boxptr_List_sort,0}};
#define boxvar_List_sort MMC_REFSTRUCTLIT(boxvar_lit_List_sort)
DLLDirection
modelica_metatype omc_List_heapSortIntList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_List_heapSortIntList omc_List_heapSortIntList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_heapSortIntList,2,0) {(void*) boxptr_List_heapSortIntList,0}};
#define boxvar_List_heapSortIntList MMC_REFSTRUCTLIT(boxvar_lit_List_heapSortIntList)
DLLDirection
modelica_metatype omc_List_stripN(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN);
DLLDirection
modelica_metatype boxptr_List_stripN(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_stripN,2,0) {(void*) boxptr_List_stripN,0}};
#define boxvar_List_stripN MMC_REFSTRUCTLIT(boxvar_lit_List_stripN)
DLLDirection
modelica_metatype omc_List_stripLast(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_stripLast omc_List_stripLast
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_stripLast,2,0) {(void*) boxptr_List_stripLast,0}};
#define boxvar_List_stripLast MMC_REFSTRUCTLIT(boxvar_lit_List_stripLast)
DLLDirection
modelica_metatype omc_List_firstN__reverse(threadData_t *threadData, modelica_metatype _inList, modelica_integer _N);
DLLDirection
modelica_metatype boxptr_List_firstN__reverse(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _N);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_firstN__reverse,2,0) {(void*) boxptr_List_firstN__reverse,0}};
#define boxvar_List_firstN__reverse MMC_REFSTRUCTLIT(boxvar_lit_List_firstN__reverse)
DLLDirection
modelica_metatype omc_List_firstN(threadData_t *threadData, modelica_metatype _inList, modelica_integer _N);
DLLDirection
modelica_metatype boxptr_List_firstN(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _N);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_firstN,2,0) {(void*) boxptr_List_firstN,0}};
#define boxvar_List_firstN MMC_REFSTRUCTLIT(boxvar_lit_List_firstN)
DLLDirection
modelica_metatype omc_List_getAtIndexLst(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _positions, modelica_boolean _zeroBased);
DLLDirection
modelica_metatype boxptr_List_getAtIndexLst(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _positions, modelica_metatype _zeroBased);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_getAtIndexLst,2,0) {(void*) boxptr_List_getAtIndexLst,0}};
#define boxvar_List_getAtIndexLst MMC_REFSTRUCTLIT(boxvar_lit_List_getAtIndexLst)
DLLDirection
modelica_metatype omc_List_getIndexFirst(threadData_t *threadData, modelica_integer _index, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_getIndexFirst(threadData_t *threadData, modelica_metatype _index, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_getIndexFirst,2,0) {(void*) boxptr_List_getIndexFirst,0}};
#define boxvar_List_getIndexFirst MMC_REFSTRUCTLIT(boxvar_lit_List_getIndexFirst)
DLLDirection
modelica_metatype omc_List_restOrEmpty(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_restOrEmpty omc_List_restOrEmpty
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_restOrEmpty,2,0) {(void*) boxptr_List_restOrEmpty,0}};
#define boxvar_List_restOrEmpty MMC_REFSTRUCTLIT(boxvar_lit_List_restOrEmpty)
DLLDirection
modelica_metatype omc_List_trimToLength(threadData_t *threadData, modelica_metatype __omcQ_24in_5Flst, modelica_integer _n);
DLLDirection
modelica_metatype boxptr_List_trimToLength(threadData_t *threadData, modelica_metatype __omcQ_24in_5Flst, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_trimToLength,2,0) {(void*) boxptr_List_trimToLength,0}};
#define boxvar_List_trimToLength MMC_REFSTRUCTLIT(boxvar_lit_List_trimToLength)
DLLDirection
modelica_metatype omc_List_lastN(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN);
DLLDirection
modelica_metatype boxptr_List_lastN(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_lastN,2,0) {(void*) boxptr_List_lastN,0}};
#define boxvar_List_lastN MMC_REFSTRUCTLIT(boxvar_lit_List_lastN)
DLLDirection
modelica_metatype omc_List_lastListOrEmpty(threadData_t *threadData, modelica_metatype _inListList);
#define boxptr_List_lastListOrEmpty omc_List_lastListOrEmpty
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_lastListOrEmpty,2,0) {(void*) boxptr_List_lastListOrEmpty,0}};
#define boxvar_List_lastListOrEmpty MMC_REFSTRUCTLIT(boxvar_lit_List_lastListOrEmpty)
DLLDirection
modelica_metatype omc_List_last(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_last omc_List_last
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_last,2,0) {(void*) boxptr_List_last,0}};
#define boxvar_List_last MMC_REFSTRUCTLIT(boxvar_lit_List_last)
DLLDirection
modelica_metatype omc_List_second(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_second omc_List_second
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_second,2,0) {(void*) boxptr_List_second,0}};
#define boxvar_List_second MMC_REFSTRUCTLIT(boxvar_lit_List_second)
DLLDirection
modelica_metatype omc_List_firstOrEmpty(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_firstOrEmpty omc_List_firstOrEmpty
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_firstOrEmpty,2,0) {(void*) boxptr_List_firstOrEmpty,0}};
#define boxvar_List_firstOrEmpty MMC_REFSTRUCTLIT(boxvar_lit_List_firstOrEmpty)
DLLDirection
modelica_metatype omc_List_set(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN, modelica_metatype _inElement);
DLLDirection
modelica_metatype boxptr_List_set(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_set,2,0) {(void*) boxptr_List_set,0}};
#define boxvar_List_set MMC_REFSTRUCTLIT(boxvar_lit_List_set)
#define boxptr_List_insertListSorted1 omc_List_insertListSorted1
DLLDirection
modelica_metatype omc_List_insertListSorted(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_insertListSorted omc_List_insertListSorted
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_insertListSorted,2,0) {(void*) boxptr_List_insertListSorted,0}};
#define boxvar_List_insertListSorted MMC_REFSTRUCTLIT(boxvar_lit_List_insertListSorted)
DLLDirection
modelica_metatype omc_List_insert(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN, modelica_metatype _inElement);
DLLDirection
modelica_metatype boxptr_List_insert(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_insert,2,0) {(void*) boxptr_List_insert,0}};
#define boxvar_List_insert MMC_REFSTRUCTLIT(boxvar_lit_List_insert)
DLLDirection
modelica_metatype omc_List_appendLastList(threadData_t *threadData, modelica_metatype _inListList, modelica_metatype _inList);
#define boxptr_List_appendLastList omc_List_appendLastList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_appendLastList,2,0) {(void*) boxptr_List_appendLastList,0}};
#define boxvar_List_appendLastList MMC_REFSTRUCTLIT(boxvar_lit_List_appendLastList)
DLLDirection
modelica_metatype omc_List_appendElt(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
#define boxptr_List_appendElt omc_List_appendElt
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_appendElt,2,0) {(void*) boxptr_List_appendElt,0}};
#define boxvar_List_appendElt MMC_REFSTRUCTLIT(boxvar_lit_List_appendElt)
DLLDirection
modelica_metatype omc_List_append__reverse(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_append__reverse omc_List_append__reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_append__reverse,2,0) {(void*) boxptr_List_append__reverse,0}};
#define boxvar_List_append__reverse MMC_REFSTRUCTLIT(boxvar_lit_List_append__reverse)
DLLDirection
modelica_metatype omc_List_consN(threadData_t *threadData, modelica_integer _size, modelica_metatype _inElement, modelica_metatype __omcQ_24in_5FinList);
DLLDirection
modelica_metatype boxptr_List_consN(threadData_t *threadData, modelica_metatype _size, modelica_metatype _inElement, modelica_metatype __omcQ_24in_5FinList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consN,2,0) {(void*) boxptr_List_consN,0}};
#define boxvar_List_consN MMC_REFSTRUCTLIT(boxvar_lit_List_consN)
DLLDirection
modelica_metatype omc_List_consOption(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
#define boxptr_List_consOption omc_List_consOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consOption,2,0) {(void*) boxptr_List_consOption,0}};
#define boxvar_List_consOption MMC_REFSTRUCTLIT(boxvar_lit_List_consOption)
DLLDirection
modelica_metatype omc_List_consOnTrue(threadData_t *threadData, modelica_boolean _inCondition, modelica_metatype _inElement, modelica_metatype _inList);
DLLDirection
modelica_metatype boxptr_List_consOnTrue(threadData_t *threadData, modelica_metatype _inCondition, modelica_metatype _inElement, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consOnTrue,2,0) {(void*) boxptr_List_consOnTrue,0}};
#define boxvar_List_consOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_consOnTrue)
DLLDirection
modelica_metatype omc_List_consr(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inElement);
#define boxptr_List_consr omc_List_consr
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consr,2,0) {(void*) boxptr_List_consr,0}};
#define boxvar_List_consr MMC_REFSTRUCTLIT(boxvar_lit_List_consr)
DLLDirection
modelica_boolean omc_List_isPrefixOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
DLLDirection
modelica_metatype boxptr_List_isPrefixOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isPrefixOnTrue,2,0) {(void*) boxptr_List_isPrefixOnTrue,0}};
#define boxvar_List_isPrefixOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_isPrefixOnTrue)
DLLDirection
modelica_integer omc_List_compare(threadData_t *threadData, modelica_metatype _list1, modelica_metatype _list2, modelica_fnptr _compareFn);
DLLDirection
modelica_metatype boxptr_List_compare(threadData_t *threadData, modelica_metatype _list1, modelica_metatype _list2, modelica_fnptr _compareFn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_compare,2,0) {(void*) boxptr_List_compare,0}};
#define boxvar_List_compare MMC_REFSTRUCTLIT(boxvar_lit_List_compare)
DLLDirection
modelica_integer omc_List_compareLength(threadData_t *threadData, modelica_metatype _list1, modelica_metatype _list2);
DLLDirection
modelica_metatype boxptr_List_compareLength(threadData_t *threadData, modelica_metatype _list1, modelica_metatype _list2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_compareLength,2,0) {(void*) boxptr_List_compareLength,0}};
#define boxvar_List_compareLength MMC_REFSTRUCTLIT(boxvar_lit_List_compareLength)
DLLDirection
modelica_boolean omc_List_allEqual(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
DLLDirection
modelica_metatype boxptr_List_allEqual(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_allEqual,2,0) {(void*) boxptr_List_allEqual,0}};
#define boxvar_List_allEqual MMC_REFSTRUCTLIT(boxvar_lit_List_allEqual)
DLLDirection
modelica_boolean omc_List_isEqualOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
DLLDirection
modelica_metatype boxptr_List_isEqualOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isEqualOnTrue,2,0) {(void*) boxptr_List_isEqualOnTrue,0}};
#define boxvar_List_isEqualOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_isEqualOnTrue)
DLLDirection
modelica_boolean omc_List_isEqual(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_boolean _inEqualLength);
DLLDirection
modelica_metatype boxptr_List_isEqual(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inEqualLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isEqual,2,0) {(void*) boxptr_List_isEqual,0}};
#define boxvar_List_isEqual MMC_REFSTRUCTLIT(boxvar_lit_List_isEqual)
DLLDirection
modelica_metatype omc_List_fromOption(threadData_t *threadData, modelica_metatype _inElement);
#define boxptr_List_fromOption omc_List_fromOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fromOption,2,0) {(void*) boxptr_List_fromOption,0}};
#define boxvar_List_fromOption MMC_REFSTRUCTLIT(boxvar_lit_List_fromOption)
DLLDirection
modelica_metatype omc_List_intRange3(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inStep, modelica_integer _inStop);
DLLDirection
modelica_metatype boxptr_List_intRange3(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStep, modelica_metatype _inStop);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intRange3,2,0) {(void*) boxptr_List_intRange3,0}};
#define boxvar_List_intRange3 MMC_REFSTRUCTLIT(boxvar_lit_List_intRange3)
DLLDirection
modelica_metatype omc_List_intRange2(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inStop);
DLLDirection
modelica_metatype boxptr_List_intRange2(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStop);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intRange2,2,0) {(void*) boxptr_List_intRange2,0}};
#define boxvar_List_intRange2 MMC_REFSTRUCTLIT(boxvar_lit_List_intRange2)
DLLDirection
modelica_metatype omc_List_intRange(threadData_t *threadData, modelica_integer _inStop);
DLLDirection
modelica_metatype boxptr_List_intRange(threadData_t *threadData, modelica_metatype _inStop);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intRange,2,0) {(void*) boxptr_List_intRange,0}};
#define boxvar_List_intRange MMC_REFSTRUCTLIT(boxvar_lit_List_intRange)
DLLDirection
modelica_metatype omc_List_repeat(threadData_t *threadData, modelica_metatype _inElement, modelica_integer _inCount);
DLLDirection
modelica_metatype boxptr_List_repeat(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_repeat,2,0) {(void*) boxptr_List_repeat,0}};
#define boxvar_List_repeat MMC_REFSTRUCTLIT(boxvar_lit_List_repeat)
DLLDirection
modelica_metatype omc_List_fill(threadData_t *threadData, modelica_metatype _inElement, modelica_integer _inCount);
DLLDirection
modelica_metatype boxptr_List_fill(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fill,2,0) {(void*) boxptr_List_fill,0}};
#define boxvar_List_fill MMC_REFSTRUCTLIT(boxvar_lit_List_fill)
DLLDirection
modelica_metatype omc_List_create(threadData_t *threadData, modelica_metatype _inElement);
#define boxptr_List_create omc_List_create
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_create,2,0) {(void*) boxptr_List_create,0}};
#define boxvar_List_create MMC_REFSTRUCTLIT(boxvar_lit_List_create)
#ifdef __cplusplus
}
#endif
#endif

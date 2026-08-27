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
DLLExport
modelica_metatype omc_List_trim(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fl, modelica_fnptr _fn);
#define boxptr_List_trim omc_List_trim
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_trim,2,0) {(void*) boxptr_List_trim,0}};
#define boxvar_List_trim MMC_REFSTRUCTLIT(boxvar_lit_List_trim)
DLLExport
modelica_metatype omc_List_maxElement(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _lessFn);
#define boxptr_List_maxElement omc_List_maxElement
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_maxElement,2,0) {(void*) boxptr_List_maxElement,0}};
#define boxvar_List_maxElement MMC_REFSTRUCTLIT(boxvar_lit_List_maxElement)
DLLExport
modelica_metatype omc_List_minElement(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _lessFn);
#define boxptr_List_minElement omc_List_minElement
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_minElement,2,0) {(void*) boxptr_List_minElement,0}};
#define boxvar_List_minElement MMC_REFSTRUCTLIT(boxvar_lit_List_minElement)
DLLExport
modelica_boolean omc_List_contains(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _elem, modelica_fnptr _eqFunc);
DLLExport
modelica_metatype boxptr_List_contains(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _elem, modelica_fnptr _eqFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_contains,2,0) {(void*) boxptr_List_contains,0}};
#define boxvar_List_contains MMC_REFSTRUCTLIT(boxvar_lit_List_contains)
#define boxptr_List_allCombinations4 omc_List_allCombinations4
#define boxptr_List_allCombinations3 omc_List_allCombinations3
#define boxptr_List_allCombinations2 omc_List_allCombinations2
DLLExport
modelica_metatype omc_List_allCombinations(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _maxTotalSize, modelica_metatype _info);
#define boxptr_List_allCombinations omc_List_allCombinations
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_allCombinations,2,0) {(void*) boxptr_List_allCombinations,0}};
#define boxvar_List_allCombinations MMC_REFSTRUCTLIT(boxvar_lit_List_allCombinations)
DLLExport
modelica_metatype omc_List_mapIndices(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _indices, modelica_fnptr _func);
#define boxptr_List_mapIndices omc_List_mapIndices
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapIndices,2,0) {(void*) boxptr_List_mapIndices,0}};
#define boxvar_List_mapIndices MMC_REFSTRUCTLIT(boxvar_lit_List_mapIndices)
DLLExport
modelica_boolean omc_List_isSorted(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
DLLExport
modelica_metatype boxptr_List_isSorted(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isSorted,2,0) {(void*) boxptr_List_isSorted,0}};
#define boxvar_List_isSorted MMC_REFSTRUCTLIT(boxvar_lit_List_isSorted)
DLLExport
modelica_metatype omc_List_mapFirst(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_mapFirst omc_List_mapFirst
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFirst,2,0) {(void*) boxptr_List_mapFirst,0}};
#define boxvar_List_mapFirst MMC_REFSTRUCTLIT(boxvar_lit_List_mapFirst)
DLLExport
modelica_metatype omc_List_separate1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1, modelica_metatype *out_outListFalse);
#define boxptr_List_separate1OnTrue omc_List_separate1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_separate1OnTrue,2,0) {(void*) boxptr_List_separate1OnTrue,0}};
#define boxvar_List_separate1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_separate1OnTrue)
DLLExport
modelica_metatype omc_List_separateOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype *out_outListFalse);
#define boxptr_List_separateOnTrue omc_List_separateOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_separateOnTrue,2,0) {(void*) boxptr_List_separateOnTrue,0}};
#define boxvar_List_separateOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_separateOnTrue)
DLLExport
modelica_boolean omc_List_all(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
DLLExport
modelica_metatype boxptr_List_all(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_all,2,0) {(void*) boxptr_List_all,0}};
#define boxvar_List_all MMC_REFSTRUCTLIT(boxvar_lit_List_all)
DLLExport
modelica_metatype omc_List_mkOption(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_mkOption omc_List_mkOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mkOption,2,0) {(void*) boxptr_List_mkOption,0}};
#define boxvar_List_mkOption MMC_REFSTRUCTLIT(boxvar_lit_List_mkOption)
DLLExport
modelica_metatype omc_List_toListWithPositions(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_toListWithPositions omc_List_toListWithPositions
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_toListWithPositions,2,0) {(void*) boxptr_List_toListWithPositions,0}};
#define boxvar_List_toListWithPositions MMC_REFSTRUCTLIT(boxvar_lit_List_toListWithPositions)
DLLExport
modelica_boolean omc_List_listIsLonger(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
DLLExport
modelica_metatype boxptr_List_listIsLonger(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_listIsLonger,2,0) {(void*) boxptr_List_listIsLonger,0}};
#define boxvar_List_listIsLonger MMC_REFSTRUCTLIT(boxvar_lit_List_listIsLonger)
DLLExport
modelica_metatype omc_List_removeEqualPrefix(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc, modelica_metatype *out_outList2);
#define boxptr_List_removeEqualPrefix omc_List_removeEqualPrefix
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_removeEqualPrefix,2,0) {(void*) boxptr_List_removeEqualPrefix,0}};
#define boxvar_List_removeEqualPrefix MMC_REFSTRUCTLIT(boxvar_lit_List_removeEqualPrefix)
DLLExport
modelica_boolean omc_List_allReferenceEq(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
DLLExport
modelica_metatype boxptr_List_allReferenceEq(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_allReferenceEq,2,0) {(void*) boxptr_List_allReferenceEq,0}};
#define boxvar_List_allReferenceEq MMC_REFSTRUCTLIT(boxvar_lit_List_allReferenceEq)
#define boxptr_List_combinationMap1__tail2 omc_List_combinationMap1__tail2
#define boxptr_List_combinationMap1__tail omc_List_combinationMap1__tail
DLLExport
modelica_metatype omc_List_combinationMap1(threadData_t *threadData, modelica_metatype _inElements, modelica_fnptr _inMapFunc, modelica_metatype _inArg);
#define boxptr_List_combinationMap1 omc_List_combinationMap1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_combinationMap1,2,0) {(void*) boxptr_List_combinationMap1,0}};
#define boxvar_List_combinationMap1 MMC_REFSTRUCTLIT(boxvar_lit_List_combinationMap1)
#define boxptr_List_combinationMap__tail omc_List_combinationMap__tail
DLLExport
modelica_metatype omc_List_combinationMap(threadData_t *threadData, modelica_metatype _inElements, modelica_fnptr _inMapFunc);
#define boxptr_List_combinationMap omc_List_combinationMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_combinationMap,2,0) {(void*) boxptr_List_combinationMap,0}};
#define boxvar_List_combinationMap MMC_REFSTRUCTLIT(boxvar_lit_List_combinationMap)
#define boxptr_List_combination__tail omc_List_combination__tail
DLLExport
modelica_metatype omc_List_combination(threadData_t *threadData, modelica_metatype _inElements);
#define boxptr_List_combination omc_List_combination
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_combination,2,0) {(void*) boxptr_List_combination,0}};
#define boxvar_List_combination MMC_REFSTRUCTLIT(boxvar_lit_List_combination)
DLLExport
modelica_metatype omc_List_splitEqualPrefix(threadData_t *threadData, modelica_metatype _inFullList, modelica_metatype _inPrefixList, modelica_fnptr _inEqFunc, modelica_metatype _inAccum, modelica_metatype *out_outRest);
#define boxptr_List_splitEqualPrefix omc_List_splitEqualPrefix
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitEqualPrefix,2,0) {(void*) boxptr_List_splitEqualPrefix,0}};
#define boxvar_List_splitEqualPrefix MMC_REFSTRUCTLIT(boxvar_lit_List_splitEqualPrefix)
DLLExport
modelica_metatype omc_List_findSome1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg);
#define boxptr_List_findSome1 omc_List_findSome1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findSome1,2,0) {(void*) boxptr_List_findSome1,0}};
#define boxvar_List_findSome1 MMC_REFSTRUCTLIT(boxvar_lit_List_findSome1)
DLLExport
modelica_metatype omc_List_findSome(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_findSome omc_List_findSome
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findSome,2,0) {(void*) boxptr_List_findSome,0}};
#define boxvar_List_findSome MMC_REFSTRUCTLIT(boxvar_lit_List_findSome)
DLLExport
modelica_metatype omc_List_findMap3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_boolean *out_outFound);
DLLExport
modelica_metatype boxptr_List_findMap3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype *out_outFound);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findMap3,2,0) {(void*) boxptr_List_findMap3,0}};
#define boxvar_List_findMap3 MMC_REFSTRUCTLIT(boxvar_lit_List_findMap3)
DLLExport
modelica_metatype omc_List_findMap2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_boolean *out_outFound);
DLLExport
modelica_metatype boxptr_List_findMap2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype *out_outFound);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findMap2,2,0) {(void*) boxptr_List_findMap2,0}};
#define boxvar_List_findMap2 MMC_REFSTRUCTLIT(boxvar_lit_List_findMap2)
DLLExport
modelica_metatype omc_List_findMap1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_boolean *out_outFound);
DLLExport
modelica_metatype boxptr_List_findMap1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype *out_outFound);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findMap1,2,0) {(void*) boxptr_List_findMap1,0}};
#define boxvar_List_findMap1 MMC_REFSTRUCTLIT(boxvar_lit_List_findMap1)
DLLExport
modelica_metatype omc_List_findMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_boolean *out_outFound);
DLLExport
modelica_metatype boxptr_List_findMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outFound);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findMap,2,0) {(void*) boxptr_List_findMap,0}};
#define boxvar_List_findMap MMC_REFSTRUCTLIT(boxvar_lit_List_findMap)
DLLExport
modelica_metatype omc_List_accumulateMapFoldAccum(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inFoldArg, modelica_metatype *out_outFoldArg);
#define boxptr_List_accumulateMapFoldAccum omc_List_accumulateMapFoldAccum
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_accumulateMapFoldAccum,2,0) {(void*) boxptr_List_accumulateMapFoldAccum,0}};
#define boxvar_List_accumulateMapFoldAccum MMC_REFSTRUCTLIT(boxvar_lit_List_accumulateMapFoldAccum)
DLLExport
modelica_metatype omc_List_accumulateMapFold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inFoldArg, modelica_metatype *out_outFoldArg);
#define boxptr_List_accumulateMapFold omc_List_accumulateMapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_accumulateMapFold,2,0) {(void*) boxptr_List_accumulateMapFold,0}};
#define boxvar_List_accumulateMapFold MMC_REFSTRUCTLIT(boxvar_lit_List_accumulateMapFold)
DLLExport
modelica_metatype omc_List_accumulateMapAccum1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inArg);
#define boxptr_List_accumulateMapAccum1 omc_List_accumulateMapAccum1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_accumulateMapAccum1,2,0) {(void*) boxptr_List_accumulateMapAccum1,0}};
#define boxvar_List_accumulateMapAccum1 MMC_REFSTRUCTLIT(boxvar_lit_List_accumulateMapAccum1)
DLLExport
modelica_metatype omc_List_accumulateMapAccum(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc);
#define boxptr_List_accumulateMapAccum omc_List_accumulateMapAccum
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_accumulateMapAccum,2,0) {(void*) boxptr_List_accumulateMapAccum,0}};
#define boxvar_List_accumulateMapAccum MMC_REFSTRUCTLIT(boxvar_lit_List_accumulateMapAccum)
DLLExport
modelica_metatype omc_List_accumulateMapReverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc);
#define boxptr_List_accumulateMapReverse omc_List_accumulateMapReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_accumulateMapReverse,2,0) {(void*) boxptr_List_accumulateMapReverse,0}};
#define boxvar_List_accumulateMapReverse MMC_REFSTRUCTLIT(boxvar_lit_List_accumulateMapReverse)
DLLExport
modelica_metatype omc_List_accumulateMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc);
#define boxptr_List_accumulateMap omc_List_accumulateMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_accumulateMap,2,0) {(void*) boxptr_List_accumulateMap,0}};
#define boxvar_List_accumulateMap MMC_REFSTRUCTLIT(boxvar_lit_List_accumulateMap)
DLLExport
modelica_metatype omc_List_map1FoldSplit(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_fnptr _inFoldFunc, modelica_metatype _inConstArg, modelica_metatype _inStartValue, modelica_metatype *out_outResult);
#define boxptr_List_map1FoldSplit omc_List_map1FoldSplit
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1FoldSplit,2,0) {(void*) boxptr_List_map1FoldSplit,0}};
#define boxvar_List_map1FoldSplit MMC_REFSTRUCTLIT(boxvar_lit_List_map1FoldSplit)
DLLExport
modelica_metatype omc_List_mapFoldSplit(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue, modelica_metatype *out_outResult);
#define boxptr_List_mapFoldSplit omc_List_mapFoldSplit
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFoldSplit,2,0) {(void*) boxptr_List_mapFoldSplit,0}};
#define boxvar_List_mapFoldSplit MMC_REFSTRUCTLIT(boxvar_lit_List_mapFoldSplit)
DLLExport
modelica_metatype omc_List_generateReverse(threadData_t *threadData, modelica_metatype _inArg, modelica_fnptr _inFunc);
#define boxptr_List_generateReverse omc_List_generateReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_generateReverse,2,0) {(void*) boxptr_List_generateReverse,0}};
#define boxvar_List_generateReverse MMC_REFSTRUCTLIT(boxvar_lit_List_generateReverse)
DLLExport
modelica_metatype omc_List_generate(threadData_t *threadData, modelica_metatype _inArg, modelica_fnptr _inFunc);
#define boxptr_List_generate omc_List_generate
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_generate,2,0) {(void*) boxptr_List_generate,0}};
#define boxvar_List_generate MMC_REFSTRUCTLIT(boxvar_lit_List_generate)
DLLExport
modelica_integer omc_List_lengthListElements(threadData_t *threadData, modelica_metatype _inListList);
DLLExport
modelica_metatype boxptr_List_lengthListElements(threadData_t *threadData, modelica_metatype _inListList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_lengthListElements,2,0) {(void*) boxptr_List_lengthListElements,0}};
#define boxvar_List_lengthListElements MMC_REFSTRUCTLIT(boxvar_lit_List_lengthListElements)
DLLExport
modelica_boolean omc_List_hasSeveralElements(threadData_t *threadData, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_hasSeveralElements(threadData_t *threadData, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_hasSeveralElements,2,0) {(void*) boxptr_List_hasSeveralElements,0}};
#define boxvar_List_hasSeveralElements MMC_REFSTRUCTLIT(boxvar_lit_List_hasSeveralElements)
DLLExport
modelica_boolean omc_List_hasOneElement(threadData_t *threadData, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_hasOneElement(threadData_t *threadData, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_hasOneElement,2,0) {(void*) boxptr_List_hasOneElement,0}};
#define boxvar_List_hasOneElement MMC_REFSTRUCTLIT(boxvar_lit_List_hasOneElement)
DLLExport
modelica_string omc_List_toString(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPrintFunc, modelica_string _inListNameStr, modelica_string _inBeginStr, modelica_string _inDelimitStr, modelica_string _inEndStr, modelica_boolean _inPrintEmpty);
DLLExport
modelica_metatype boxptr_List_toString(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPrintFunc, modelica_metatype _inListNameStr, modelica_metatype _inBeginStr, modelica_metatype _inDelimitStr, modelica_metatype _inEndStr, modelica_metatype _inPrintEmpty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_toString,2,0) {(void*) boxptr_List_toString,0}};
#define boxvar_List_toString MMC_REFSTRUCTLIT(boxvar_lit_List_toString)
DLLExport
modelica_metatype omc_List_replaceAtWithFill(threadData_t *threadData, modelica_metatype _inElement, modelica_integer _inPosition, modelica_metatype _inList, modelica_metatype _inFillValue);
DLLExport
modelica_metatype boxptr_List_replaceAtWithFill(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inPosition, modelica_metatype _inList, modelica_metatype _inFillValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceAtWithFill,2,0) {(void*) boxptr_List_replaceAtWithFill,0}};
#define boxvar_List_replaceAtWithFill MMC_REFSTRUCTLIT(boxvar_lit_List_replaceAtWithFill)
DLLExport
modelica_metatype omc_List_replaceAtWithList(threadData_t *threadData, modelica_metatype _inReplacementList, modelica_integer _inPosition, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_replaceAtWithList(threadData_t *threadData, modelica_metatype _inReplacementList, modelica_metatype _inPosition, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceAtWithList,2,0) {(void*) boxptr_List_replaceAtWithList,0}};
#define boxvar_List_replaceAtWithList MMC_REFSTRUCTLIT(boxvar_lit_List_replaceAtWithList)
DLLExport
modelica_metatype omc_List_replaceAtIndexFirst(threadData_t *threadData, modelica_integer _inPosition, modelica_metatype _inElement, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_replaceAtIndexFirst(threadData_t *threadData, modelica_metatype _inPosition, modelica_metatype _inElement, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceAtIndexFirst,2,0) {(void*) boxptr_List_replaceAtIndexFirst,0}};
#define boxvar_List_replaceAtIndexFirst MMC_REFSTRUCTLIT(boxvar_lit_List_replaceAtIndexFirst)
DLLExport
modelica_metatype omc_List_replaceOnTrue(threadData_t *threadData, modelica_metatype _inReplacement, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_boolean *out_outReplaced);
DLLExport
modelica_metatype boxptr_List_replaceOnTrue(threadData_t *threadData, modelica_metatype _inReplacement, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outReplaced);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceOnTrue,2,0) {(void*) boxptr_List_replaceOnTrue,0}};
#define boxvar_List_replaceOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_replaceOnTrue)
DLLExport
modelica_metatype omc_List_replaceAt(threadData_t *threadData, modelica_metatype _inElement, modelica_integer _inPosition, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_replaceAt(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inPosition, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_replaceAt,2,0) {(void*) boxptr_List_replaceAt,0}};
#define boxvar_List_replaceAt MMC_REFSTRUCTLIT(boxvar_lit_List_replaceAt)
DLLExport
modelica_metatype omc_List_removeMatchesFirst(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_List_removeMatchesFirst(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_removeMatchesFirst,2,0) {(void*) boxptr_List_removeMatchesFirst,0}};
#define boxvar_List_removeMatchesFirst MMC_REFSTRUCTLIT(boxvar_lit_List_removeMatchesFirst)
DLLExport
modelica_metatype omc_List_deletePositionsSorted(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions);
#define boxptr_List_deletePositionsSorted omc_List_deletePositionsSorted
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_deletePositionsSorted,2,0) {(void*) boxptr_List_deletePositionsSorted,0}};
#define boxvar_List_deletePositionsSorted MMC_REFSTRUCTLIT(boxvar_lit_List_deletePositionsSorted)
DLLExport
modelica_metatype omc_List_deletePositions(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPositions);
#define boxptr_List_deletePositions omc_List_deletePositions
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_deletePositions,2,0) {(void*) boxptr_List_deletePositions,0}};
#define boxvar_List_deletePositions MMC_REFSTRUCTLIT(boxvar_lit_List_deletePositions)
DLLExport
modelica_metatype omc_List_deleteMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inList, modelica_fnptr _inCompareFunc, modelica_metatype *out_outDeletedElement);
#define boxptr_List_deleteMemberOnTrue omc_List_deleteMemberOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_deleteMemberOnTrue,2,0) {(void*) boxptr_List_deleteMemberOnTrue,0}};
#define boxvar_List_deleteMemberOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_deleteMemberOnTrue)
DLLExport
modelica_metatype omc_List_deleteMemberF(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inElement);
#define boxptr_List_deleteMemberF omc_List_deleteMemberF
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_deleteMemberF,2,0) {(void*) boxptr_List_deleteMemberF,0}};
#define boxvar_List_deleteMemberF MMC_REFSTRUCTLIT(boxvar_lit_List_deleteMemberF)
DLLExport
modelica_metatype omc_List_deleteMember(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inElement);
#define boxptr_List_deleteMember omc_List_deleteMember
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_deleteMember,2,0) {(void*) boxptr_List_deleteMember,0}};
#define boxvar_List_deleteMember MMC_REFSTRUCTLIT(boxvar_lit_List_deleteMember)
DLLExport
modelica_metatype omc_List_findBoolList(threadData_t *threadData, modelica_metatype _inBooleans, modelica_metatype _inList, modelica_metatype _inFalseValue);
#define boxptr_List_findBoolList omc_List_findBoolList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findBoolList,2,0) {(void*) boxptr_List_findBoolList,0}};
#define boxvar_List_findBoolList MMC_REFSTRUCTLIT(boxvar_lit_List_findBoolList)
DLLExport
modelica_metatype omc_List_findAndRemove1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _arg1, modelica_metatype *out_rest);
#define boxptr_List_findAndRemove1 omc_List_findAndRemove1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findAndRemove1,2,0) {(void*) boxptr_List_findAndRemove1,0}};
#define boxvar_List_findAndRemove1 MMC_REFSTRUCTLIT(boxvar_lit_List_findAndRemove1)
DLLExport
modelica_metatype omc_List_findAndRemove(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_rest);
#define boxptr_List_findAndRemove omc_List_findAndRemove
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_findAndRemove,2,0) {(void*) boxptr_List_findAndRemove,0}};
#define boxvar_List_findAndRemove MMC_REFSTRUCTLIT(boxvar_lit_List_findAndRemove)
DLLExport
modelica_metatype omc_List_find1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _arg1);
#define boxptr_List_find1 omc_List_find1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_find1,2,0) {(void*) boxptr_List_find1,0}};
#define boxvar_List_find1 MMC_REFSTRUCTLIT(boxvar_lit_List_find1)
DLLExport
modelica_metatype omc_List_find(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_find omc_List_find
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_find,2,0) {(void*) boxptr_List_find,0}};
#define boxvar_List_find MMC_REFSTRUCTLIT(boxvar_lit_List_find)
DLLExport
modelica_metatype omc_List_select2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_select2 omc_List_select2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_select2,2,0) {(void*) boxptr_List_select2,0}};
#define boxvar_List_select2 MMC_REFSTRUCTLIT(boxvar_lit_List_select2)
DLLExport
modelica_metatype omc_List_select1r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_select1r omc_List_select1r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_select1r,2,0) {(void*) boxptr_List_select1r,0}};
#define boxvar_List_select1r MMC_REFSTRUCTLIT(boxvar_lit_List_select1r)
DLLExport
modelica_metatype omc_List_select1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_select1 omc_List_select1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_select1,2,0) {(void*) boxptr_List_select1,0}};
#define boxvar_List_select1 MMC_REFSTRUCTLIT(boxvar_lit_List_select1)
DLLExport
modelica_metatype omc_List_select(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_select omc_List_select
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_select,2,0) {(void*) boxptr_List_select,0}};
#define boxvar_List_select MMC_REFSTRUCTLIT(boxvar_lit_List_select)
DLLExport
modelica_metatype omc_List_filterCons(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _fn, modelica_metatype __omcQ_24in_5FaccumList);
#define boxptr_List_filterCons omc_List_filterCons
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterCons,2,0) {(void*) boxptr_List_filterCons,0}};
#define boxvar_List_filterCons MMC_REFSTRUCTLIT(boxvar_lit_List_filterCons)
DLLExport
modelica_metatype omc_List_removeOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_fnptr _inCompFunc, modelica_metatype _inList);
#define boxptr_List_removeOnTrue omc_List_removeOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_removeOnTrue,2,0) {(void*) boxptr_List_removeOnTrue,0}};
#define boxvar_List_removeOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_removeOnTrue)
DLLExport
modelica_metatype omc_List_filter2OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_filter2OnTrue omc_List_filter2OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter2OnTrue,2,0) {(void*) boxptr_List_filter2OnTrue,0}};
#define boxvar_List_filter2OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_filter2OnTrue)
DLLExport
modelica_metatype omc_List_filter1rOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_filter1rOnTrue omc_List_filter1rOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1rOnTrue,2,0) {(void*) boxptr_List_filter1rOnTrue,0}};
#define boxvar_List_filter1rOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_filter1rOnTrue)
DLLExport
modelica_metatype omc_List_filter1OnTrueAndUpdate(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_fnptr _inUpdateFunc, modelica_metatype _inArg1);
#define boxptr_List_filter1OnTrueAndUpdate omc_List_filter1OnTrueAndUpdate
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1OnTrueAndUpdate,2,0) {(void*) boxptr_List_filter1OnTrueAndUpdate,0}};
#define boxvar_List_filter1OnTrueAndUpdate MMC_REFSTRUCTLIT(boxvar_lit_List_filter1OnTrueAndUpdate)
DLLExport
modelica_metatype omc_List_filter1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_filter1OnTrue omc_List_filter1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1OnTrue,2,0) {(void*) boxptr_List_filter1OnTrue,0}};
#define boxvar_List_filter1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_filter1OnTrue)
DLLExport
modelica_metatype omc_List_filter1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1);
#define boxptr_List_filter1 omc_List_filter1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1,2,0) {(void*) boxptr_List_filter1,0}};
#define boxvar_List_filter1 MMC_REFSTRUCTLIT(boxvar_lit_List_filter1)
DLLExport
modelica_metatype omc_List_filterOnTrueReverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_filterOnTrueReverse omc_List_filterOnTrueReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterOnTrueReverse,2,0) {(void*) boxptr_List_filterOnTrueReverse,0}};
#define boxvar_List_filterOnTrueReverse MMC_REFSTRUCTLIT(boxvar_lit_List_filterOnTrueReverse)
DLLExport
modelica_metatype omc_List_filterOnTrueSync(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inSyncList, modelica_metatype *out_outList_b);
#define boxptr_List_filterOnTrueSync omc_List_filterOnTrueSync
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterOnTrueSync,2,0) {(void*) boxptr_List_filterOnTrueSync,0}};
#define boxvar_List_filterOnTrueSync MMC_REFSTRUCTLIT(boxvar_lit_List_filterOnTrueSync)
DLLExport
modelica_metatype omc_List_filter1OnTrueSync(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg1, modelica_metatype _inSyncList, modelica_metatype *out_outList_b);
#define boxptr_List_filter1OnTrueSync omc_List_filter1OnTrueSync
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter1OnTrueSync,2,0) {(void*) boxptr_List_filter1OnTrueSync,0}};
#define boxvar_List_filter1OnTrueSync MMC_REFSTRUCTLIT(boxvar_lit_List_filter1OnTrueSync)
DLLExport
modelica_metatype omc_List_filterOnFalse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_filterOnFalse omc_List_filterOnFalse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterOnFalse,2,0) {(void*) boxptr_List_filterOnFalse,0}};
#define boxvar_List_filterOnFalse MMC_REFSTRUCTLIT(boxvar_lit_List_filterOnFalse)
DLLExport
modelica_metatype omc_List_filterOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_filterOnTrue omc_List_filterOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterOnTrue,2,0) {(void*) boxptr_List_filterOnTrue,0}};
#define boxvar_List_filterOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_filterOnTrue)
DLLExport
modelica_metatype omc_List_filterMap1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterMapFunc, modelica_metatype _inExtraArg);
#define boxptr_List_filterMap1 omc_List_filterMap1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterMap1,2,0) {(void*) boxptr_List_filterMap1,0}};
#define boxvar_List_filterMap1 MMC_REFSTRUCTLIT(boxvar_lit_List_filterMap1)
DLLExport
modelica_metatype omc_List_filterMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterMapFunc);
#define boxptr_List_filterMap omc_List_filterMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filterMap,2,0) {(void*) boxptr_List_filterMap,0}};
#define boxvar_List_filterMap MMC_REFSTRUCTLIT(boxvar_lit_List_filterMap)
DLLExport
modelica_metatype omc_List_filter(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc);
#define boxptr_List_filter omc_List_filter
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_filter,2,0) {(void*) boxptr_List_filter,0}};
#define boxvar_List_filter MMC_REFSTRUCTLIT(boxvar_lit_List_filter)
DLLExport
modelica_metatype omc_List_extract1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype _inArg, modelica_metatype *out_outRemainingList);
#define boxptr_List_extract1OnTrue omc_List_extract1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_extract1OnTrue,2,0) {(void*) boxptr_List_extract1OnTrue,0}};
#define boxvar_List_extract1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_extract1OnTrue)
DLLExport
modelica_metatype omc_List_extractOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFilterFunc, modelica_metatype *out_outRemainingList);
#define boxptr_List_extractOnTrue omc_List_extractOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_extractOnTrue,2,0) {(void*) boxptr_List_extractOnTrue,0}};
#define boxvar_List_extractOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_extractOnTrue)
DLLExport
modelica_boolean omc_List_exist2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFindFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2);
DLLExport
modelica_metatype boxptr_List_exist2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFindFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_exist2,2,0) {(void*) boxptr_List_exist2,0}};
#define boxvar_List_exist2 MMC_REFSTRUCTLIT(boxvar_lit_List_exist2)
DLLExport
modelica_boolean omc_List_exist1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFindFunc, modelica_metatype _inExtraArg);
DLLExport
modelica_metatype boxptr_List_exist1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFindFunc, modelica_metatype _inExtraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_exist1,2,0) {(void*) boxptr_List_exist1,0}};
#define boxvar_List_exist1 MMC_REFSTRUCTLIT(boxvar_lit_List_exist1)
DLLExport
modelica_boolean omc_List_exist(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFindFunc);
DLLExport
modelica_metatype boxptr_List_exist(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFindFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_exist,2,0) {(void*) boxptr_List_exist,0}};
#define boxvar_List_exist MMC_REFSTRUCTLIT(boxvar_lit_List_exist)
DLLExport
modelica_boolean omc_List_isMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inList, modelica_fnptr _inCompFunc);
DLLExport
modelica_metatype boxptr_List_isMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inList, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isMemberOnTrue,2,0) {(void*) boxptr_List_isMemberOnTrue,0}};
#define boxvar_List_isMemberOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_isMemberOnTrue)
DLLExport
modelica_boolean omc_List_notMember(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_notMember(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_notMember,2,0) {(void*) boxptr_List_notMember,0}};
#define boxvar_List_notMember MMC_REFSTRUCTLIT(boxvar_lit_List_notMember)
DLLExport
modelica_metatype omc_List_getMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_getMemberOnTrue omc_List_getMemberOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_getMemberOnTrue,2,0) {(void*) boxptr_List_getMemberOnTrue,0}};
#define boxvar_List_getMemberOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_getMemberOnTrue)
DLLExport
modelica_metatype omc_List_getMember(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
#define boxptr_List_getMember omc_List_getMember
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_getMember,2,0) {(void*) boxptr_List_getMember,0}};
#define boxvar_List_getMember MMC_REFSTRUCTLIT(boxvar_lit_List_getMember)
DLLExport
modelica_integer omc_List_positionList(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList, modelica_integer *out_outPosition);
DLLExport
modelica_metatype boxptr_List_positionList(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList, modelica_metatype *out_outPosition);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_positionList,2,0) {(void*) boxptr_List_positionList,0}};
#define boxvar_List_positionList MMC_REFSTRUCTLIT(boxvar_lit_List_positionList)
DLLExport
modelica_integer omc_List_position1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPredFunc, modelica_metatype _inArg);
DLLExport
modelica_metatype boxptr_List_position1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPredFunc, modelica_metatype _inArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_position1OnTrue,2,0) {(void*) boxptr_List_position1OnTrue,0}};
#define boxvar_List_position1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_position1OnTrue)
DLLExport
modelica_integer omc_List_positionOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPredFunc);
DLLExport
modelica_metatype boxptr_List_positionOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inPredFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_positionOnTrue,2,0) {(void*) boxptr_List_positionOnTrue,0}};
#define boxvar_List_positionOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_positionOnTrue)
DLLExport
modelica_integer omc_List_position(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_position(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_position,2,0) {(void*) boxptr_List_position,0}};
#define boxvar_List_position MMC_REFSTRUCTLIT(boxvar_lit_List_position)
DLLExport
modelica_metatype omc_List_threadMapFold(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_threadMapFold omc_List_threadMapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMapFold,2,0) {(void*) boxptr_List_threadMapFold,0}};
#define boxvar_List_threadMapFold MMC_REFSTRUCTLIT(boxvar_lit_List_threadMapFold)
DLLExport
modelica_metatype omc_List_threadFold(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold omc_List_threadFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold,2,0) {(void*) boxptr_List_threadFold,0}};
#define boxvar_List_threadFold MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold)
DLLExport
modelica_metatype omc_List_threadFold4(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold4 omc_List_threadFold4
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold4,2,0) {(void*) boxptr_List_threadFold4,0}};
#define boxvar_List_threadFold4 MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold4)
DLLExport
modelica_metatype omc_List_threadFold3(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold3 omc_List_threadFold3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold3,2,0) {(void*) boxptr_List_threadFold3,0}};
#define boxvar_List_threadFold3 MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold3)
DLLExport
modelica_metatype omc_List_threadFold2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold2 omc_List_threadFold2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold2,2,0) {(void*) boxptr_List_threadFold2,0}};
#define boxvar_List_threadFold2 MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold2)
DLLExport
modelica_metatype omc_List_threadFold1(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inFoldArg);
#define boxptr_List_threadFold1 omc_List_threadFold1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadFold1,2,0) {(void*) boxptr_List_threadFold1,0}};
#define boxvar_List_threadFold1 MMC_REFSTRUCTLIT(boxvar_lit_List_threadFold1)
DLLExport
modelica_metatype omc_List_thread3Map3(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inList3, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3);
#define boxptr_List_thread3Map3 omc_List_thread3Map3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread3Map3,2,0) {(void*) boxptr_List_thread3Map3,0}};
#define boxvar_List_thread3Map3 MMC_REFSTRUCTLIT(boxvar_lit_List_thread3Map3)
DLLExport
modelica_metatype omc_List_thread3MapFold(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inList3, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_thread3MapFold omc_List_thread3MapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread3MapFold,2,0) {(void*) boxptr_List_thread3MapFold,0}};
#define boxvar_List_thread3MapFold MMC_REFSTRUCTLIT(boxvar_lit_List_thread3MapFold)
DLLExport
modelica_metatype omc_List_thread3Map__2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inList3, modelica_fnptr _inFunc, modelica_metatype *out_outList2);
#define boxptr_List_thread3Map__2 omc_List_thread3Map__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread3Map__2,2,0) {(void*) boxptr_List_thread3Map__2,0}};
#define boxvar_List_thread3Map__2 MMC_REFSTRUCTLIT(boxvar_lit_List_thread3Map__2)
DLLExport
modelica_metatype omc_List_threadMap3ReverseFold(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inFoldArg, modelica_metatype _inAccum, modelica_metatype *out_outFoldArg);
#define boxptr_List_threadMap3ReverseFold omc_List_threadMap3ReverseFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap3ReverseFold,2,0) {(void*) boxptr_List_threadMap3ReverseFold,0}};
#define boxvar_List_threadMap3ReverseFold MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap3ReverseFold)
DLLExport
modelica_metatype omc_List_thread3Map(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inList3, modelica_fnptr _inFunc);
#define boxptr_List_thread3Map omc_List_thread3Map
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread3Map,2,0) {(void*) boxptr_List_thread3Map,0}};
#define boxvar_List_thread3Map MMC_REFSTRUCTLIT(boxvar_lit_List_thread3Map)
DLLExport
modelica_metatype omc_List_threadMap3Reverse(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3);
#define boxptr_List_threadMap3Reverse omc_List_threadMap3Reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap3Reverse,2,0) {(void*) boxptr_List_threadMap3Reverse,0}};
#define boxvar_List_threadMap3Reverse MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap3Reverse)
DLLExport
modelica_metatype omc_List_threadMap3(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3);
#define boxptr_List_threadMap3 omc_List_threadMap3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap3,2,0) {(void*) boxptr_List_threadMap3,0}};
#define boxvar_List_threadMap3 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap3)
DLLExport
modelica_metatype omc_List_threadMap2ReverseFold(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inFoldArg, modelica_metatype _inAccum, modelica_metatype *out_outFoldArg);
#define boxptr_List_threadMap2ReverseFold omc_List_threadMap2ReverseFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap2ReverseFold,2,0) {(void*) boxptr_List_threadMap2ReverseFold,0}};
#define boxvar_List_threadMap2ReverseFold MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap2ReverseFold)
DLLExport
modelica_metatype omc_List_threadMap2Reverse(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_threadMap2Reverse omc_List_threadMap2Reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap2Reverse,2,0) {(void*) boxptr_List_threadMap2Reverse,0}};
#define boxvar_List_threadMap2Reverse MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap2Reverse)
DLLExport
modelica_metatype omc_List_threadMap2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_threadMap2 omc_List_threadMap2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap2,2,0) {(void*) boxptr_List_threadMap2,0}};
#define boxvar_List_threadMap2 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap2)
DLLExport
void omc_List_threadMap1__0(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_threadMap1__0 omc_List_threadMap1__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap1__0,2,0) {(void*) boxptr_List_threadMap1__0,0}};
#define boxvar_List_threadMap1__0 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap1__0)
DLLExport
modelica_metatype omc_List_threadMap1Reverse(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_threadMap1Reverse omc_List_threadMap1Reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap1Reverse,2,0) {(void*) boxptr_List_threadMap1Reverse,0}};
#define boxvar_List_threadMap1Reverse MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap1Reverse)
DLLExport
modelica_metatype omc_List_threadMap1(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_threadMap1 omc_List_threadMap1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap1,2,0) {(void*) boxptr_List_threadMap1,0}};
#define boxvar_List_threadMap1 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap1)
DLLExport
void omc_List_threadMapAllValue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype _inValue);
#define boxptr_List_threadMapAllValue omc_List_threadMapAllValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMapAllValue,2,0) {(void*) boxptr_List_threadMapAllValue,0}};
#define boxvar_List_threadMapAllValue MMC_REFSTRUCTLIT(boxvar_lit_List_threadMapAllValue)
DLLExport
modelica_metatype omc_List_threadMapList__2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype *out_outList2);
#define boxptr_List_threadMapList__2 omc_List_threadMapList__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMapList__2,2,0) {(void*) boxptr_List_threadMapList__2,0}};
#define boxvar_List_threadMapList__2 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMapList__2)
DLLExport
modelica_metatype omc_List_threadMapList(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc);
#define boxptr_List_threadMapList omc_List_threadMapList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMapList,2,0) {(void*) boxptr_List_threadMapList,0}};
#define boxvar_List_threadMapList MMC_REFSTRUCTLIT(boxvar_lit_List_threadMapList)
DLLExport
modelica_metatype omc_List_threadMap__2(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc, modelica_metatype *out_outList2);
#define boxptr_List_threadMap__2 omc_List_threadMap__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap__2,2,0) {(void*) boxptr_List_threadMap__2,0}};
#define boxvar_List_threadMap__2 MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap__2)
DLLExport
modelica_metatype omc_List_threadMapReverse(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc);
#define boxptr_List_threadMapReverse omc_List_threadMapReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMapReverse,2,0) {(void*) boxptr_List_threadMapReverse,0}};
#define boxvar_List_threadMapReverse MMC_REFSTRUCTLIT(boxvar_lit_List_threadMapReverse)
DLLExport
modelica_metatype omc_List_threadMap(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc);
#define boxptr_List_threadMap omc_List_threadMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_threadMap,2,0) {(void*) boxptr_List_threadMap,0}};
#define boxvar_List_threadMap MMC_REFSTRUCTLIT(boxvar_lit_List_threadMap)
DLLExport
modelica_metatype omc_List_unzipSecond(threadData_t *threadData, modelica_metatype _inTuples);
#define boxptr_List_unzipSecond omc_List_unzipSecond
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unzipSecond,2,0) {(void*) boxptr_List_unzipSecond,0}};
#define boxvar_List_unzipSecond MMC_REFSTRUCTLIT(boxvar_lit_List_unzipSecond)
DLLExport
modelica_metatype omc_List_unzipFirst(threadData_t *threadData, modelica_metatype _inTuples);
#define boxptr_List_unzipFirst omc_List_unzipFirst
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unzipFirst,2,0) {(void*) boxptr_List_unzipFirst,0}};
#define boxvar_List_unzipFirst MMC_REFSTRUCTLIT(boxvar_lit_List_unzipFirst)
DLLExport
modelica_metatype omc_List_unzipReverse(threadData_t *threadData, modelica_metatype _inTuples, modelica_metatype *out_outList2);
#define boxptr_List_unzipReverse omc_List_unzipReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unzipReverse,2,0) {(void*) boxptr_List_unzipReverse,0}};
#define boxvar_List_unzipReverse MMC_REFSTRUCTLIT(boxvar_lit_List_unzipReverse)
DLLExport
modelica_metatype omc_List_unzip3(threadData_t *threadData, modelica_metatype _tuples, modelica_metatype *out_l2, modelica_metatype *out_l3);
#define boxptr_List_unzip3 omc_List_unzip3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unzip3,2,0) {(void*) boxptr_List_unzip3,0}};
#define boxvar_List_unzip3 MMC_REFSTRUCTLIT(boxvar_lit_List_unzip3)
DLLExport
modelica_metatype omc_List_unzip(threadData_t *threadData, modelica_metatype _inTuples, modelica_metatype *out_outList2);
#define boxptr_List_unzip omc_List_unzip
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unzip,2,0) {(void*) boxptr_List_unzip,0}};
#define boxvar_List_unzip MMC_REFSTRUCTLIT(boxvar_lit_List_unzip)
DLLExport
modelica_metatype omc_List_zip3(threadData_t *threadData, modelica_metatype _l1, modelica_metatype _l2, modelica_metatype _l3);
#define boxptr_List_zip3 omc_List_zip3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_zip3,2,0) {(void*) boxptr_List_zip3,0}};
#define boxvar_List_zip3 MMC_REFSTRUCTLIT(boxvar_lit_List_zip3)
DLLExport
modelica_metatype omc_List_zip(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_zip omc_List_zip
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_zip,2,0) {(void*) boxptr_List_zip,0}};
#define boxvar_List_zip MMC_REFSTRUCTLIT(boxvar_lit_List_zip)
DLLExport
modelica_metatype omc_List_thread3(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inList3);
#define boxptr_List_thread3 omc_List_thread3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread3,2,0) {(void*) boxptr_List_thread3,0}};
#define boxvar_List_thread3 MMC_REFSTRUCTLIT(boxvar_lit_List_thread3)
DLLExport
modelica_metatype omc_List_thread(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inAccum);
#define boxptr_List_thread omc_List_thread
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_thread,2,0) {(void*) boxptr_List_thread,0}};
#define boxvar_List_thread MMC_REFSTRUCTLIT(boxvar_lit_List_thread)
DLLExport
modelica_metatype omc_List_flattenReverse(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_flattenReverse omc_List_flattenReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_flattenReverse,2,0) {(void*) boxptr_List_flattenReverse,0}};
#define boxvar_List_flattenReverse MMC_REFSTRUCTLIT(boxvar_lit_List_flattenReverse)
DLLExport
modelica_metatype omc_List_flatten(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_flatten omc_List_flatten
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_flatten,2,0) {(void*) boxptr_List_flatten,0}};
#define boxvar_List_flatten MMC_REFSTRUCTLIT(boxvar_lit_List_flatten)
DLLExport
modelica_metatype omc_List_reduce1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inReduceFunc, modelica_metatype _inExtraArg1);
#define boxptr_List_reduce1 omc_List_reduce1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_reduce1,2,0) {(void*) boxptr_List_reduce1,0}};
#define boxvar_List_reduce1 MMC_REFSTRUCTLIT(boxvar_lit_List_reduce1)
DLLExport
modelica_metatype omc_List_reduce(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inReduceFunc);
#define boxptr_List_reduce omc_List_reduce
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_reduce,2,0) {(void*) boxptr_List_reduce,0}};
#define boxvar_List_reduce MMC_REFSTRUCTLIT(boxvar_lit_List_reduce)
DLLExport
modelica_metatype omc_List_map3FoldList(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inConstArg1, modelica_metatype _inConstArg2, modelica_metatype _inConstArg3, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_map3FoldList omc_List_map3FoldList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map3FoldList,2,0) {(void*) boxptr_List_map3FoldList,0}};
#define boxvar_List_map3FoldList MMC_REFSTRUCTLIT(boxvar_lit_List_map3FoldList)
DLLExport
modelica_metatype omc_List_mapFoldList(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_mapFoldList omc_List_mapFoldList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFoldList,2,0) {(void*) boxptr_List_mapFoldList,0}};
#define boxvar_List_mapFoldList MMC_REFSTRUCTLIT(boxvar_lit_List_mapFoldList)
DLLExport
modelica_metatype omc_List_map4Fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inConstArg2, modelica_metatype _inConstArg3, modelica_metatype _inConstArg4, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_map4Fold omc_List_map4Fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map4Fold,2,0) {(void*) boxptr_List_map4Fold,0}};
#define boxvar_List_map4Fold MMC_REFSTRUCTLIT(boxvar_lit_List_map4Fold)
DLLExport
modelica_metatype omc_List_map3Fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inConstArg2, modelica_metatype _inConstArg3, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_map3Fold omc_List_map3Fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map3Fold,2,0) {(void*) boxptr_List_map3Fold,0}};
#define boxvar_List_map3Fold MMC_REFSTRUCTLIT(boxvar_lit_List_map3Fold)
DLLExport
modelica_metatype omc_List_map2FoldCheckReferenceEq(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inConstArg2, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_map2FoldCheckReferenceEq omc_List_map2FoldCheckReferenceEq
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2FoldCheckReferenceEq,2,0) {(void*) boxptr_List_map2FoldCheckReferenceEq,0}};
#define boxvar_List_map2FoldCheckReferenceEq MMC_REFSTRUCTLIT(boxvar_lit_List_map2FoldCheckReferenceEq)
DLLExport
modelica_metatype omc_List_map2Fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inConstArg2, modelica_metatype _inArg, modelica_metatype _inAccum, modelica_metatype *out_outArg);
#define boxptr_List_map2Fold omc_List_map2Fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2Fold,2,0) {(void*) boxptr_List_map2Fold,0}};
#define boxvar_List_map2Fold MMC_REFSTRUCTLIT(boxvar_lit_List_map2Fold)
DLLExport
modelica_metatype omc_List_map1Fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inConstArg, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_map1Fold omc_List_map1Fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1Fold,2,0) {(void*) boxptr_List_map1Fold,0}};
#define boxvar_List_map1Fold MMC_REFSTRUCTLIT(boxvar_lit_List_map1Fold)
DLLExport
modelica_metatype omc_List_mapFold5(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype __omcQ_24in_5FinArg1, modelica_metatype __omcQ_24in_5FinArg2, modelica_metatype __omcQ_24in_5FinArg3, modelica_metatype __omcQ_24in_5FinArg4, modelica_metatype __omcQ_24in_5FinArg5, modelica_metatype *out_inArg1, modelica_metatype *out_inArg2, modelica_metatype *out_inArg3, modelica_metatype *out_inArg4, modelica_metatype *out_inArg5);
#define boxptr_List_mapFold5 omc_List_mapFold5
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold5,2,0) {(void*) boxptr_List_mapFold5,0}};
#define boxvar_List_mapFold5 MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold5)
DLLExport
modelica_metatype omc_List_mapFold4(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype __omcQ_24in_5FinArg1, modelica_metatype __omcQ_24in_5FinArg2, modelica_metatype __omcQ_24in_5FinArg3, modelica_metatype __omcQ_24in_5FinArg4, modelica_metatype *out_inArg1, modelica_metatype *out_inArg2, modelica_metatype *out_inArg3, modelica_metatype *out_inArg4);
#define boxptr_List_mapFold4 omc_List_mapFold4
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold4,2,0) {(void*) boxptr_List_mapFold4,0}};
#define boxvar_List_mapFold4 MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold4)
DLLExport
modelica_metatype omc_List_mapFold3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype __omcQ_24in_5FinArg1, modelica_metatype __omcQ_24in_5FinArg2, modelica_metatype __omcQ_24in_5FinArg3, modelica_metatype *out_inArg1, modelica_metatype *out_inArg2, modelica_metatype *out_inArg3);
#define boxptr_List_mapFold3 omc_List_mapFold3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold3,2,0) {(void*) boxptr_List_mapFold3,0}};
#define boxvar_List_mapFold3 MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold3)
DLLExport
modelica_metatype omc_List_mapFold2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype *out_outArg1, modelica_metatype *out_outArg2);
#define boxptr_List_mapFold2 omc_List_mapFold2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold2,2,0) {(void*) boxptr_List_mapFold2,0}};
#define boxvar_List_mapFold2 MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold2)
DLLExport
modelica_metatype omc_List_mapFold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
#define boxptr_List_mapFold omc_List_mapFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFold,2,0) {(void*) boxptr_List_mapFold,0}};
#define boxvar_List_mapFold MMC_REFSTRUCTLIT(boxvar_lit_List_mapFold)
DLLExport
modelica_metatype omc_List_fold6(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inExtraArg3, modelica_metatype _inExtraArg4, modelica_metatype _inExtraArg5, modelica_metatype _inExtraArg6, modelica_metatype _inStartValue);
#define boxptr_List_fold6 omc_List_fold6
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold6,2,0) {(void*) boxptr_List_fold6,0}};
#define boxvar_List_fold6 MMC_REFSTRUCTLIT(boxvar_lit_List_fold6)
DLLExport
modelica_metatype omc_List_fold5(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inExtraArg3, modelica_metatype _inExtraArg4, modelica_metatype _inExtraArg5, modelica_metatype _inStartValue);
#define boxptr_List_fold5 omc_List_fold5
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold5,2,0) {(void*) boxptr_List_fold5,0}};
#define boxvar_List_fold5 MMC_REFSTRUCTLIT(boxvar_lit_List_fold5)
DLLExport
modelica_metatype omc_List_fold31(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype _inStartValue3, modelica_metatype *out_outResult2, modelica_metatype *out_outResult3);
#define boxptr_List_fold31 omc_List_fold31
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold31,2,0) {(void*) boxptr_List_fold31,0}};
#define boxvar_List_fold31 MMC_REFSTRUCTLIT(boxvar_lit_List_fold31)
DLLExport
modelica_metatype omc_List_fold21(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype *out_outResult2);
#define boxptr_List_fold21 omc_List_fold21
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold21,2,0) {(void*) boxptr_List_fold21,0}};
#define boxvar_List_fold21 MMC_REFSTRUCTLIT(boxvar_lit_List_fold21)
DLLExport
modelica_metatype omc_List_fold30(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype _inStartValue3, modelica_metatype *out_outResult2, modelica_metatype *out_outResult3);
#define boxptr_List_fold30 omc_List_fold30
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold30,2,0) {(void*) boxptr_List_fold30,0}};
#define boxvar_List_fold30 MMC_REFSTRUCTLIT(boxvar_lit_List_fold30)
DLLExport
modelica_metatype omc_List_fold20(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype *out_outResult2);
#define boxptr_List_fold20 omc_List_fold20
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold20,2,0) {(void*) boxptr_List_fold20,0}};
#define boxvar_List_fold20 MMC_REFSTRUCTLIT(boxvar_lit_List_fold20)
DLLExport
modelica_metatype omc_List_fold43(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inExtraArg3, modelica_metatype _inExtraArg4, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype _inStartValue3, modelica_metatype *out_outResult2, modelica_metatype *out_outResult3);
#define boxptr_List_fold43 omc_List_fold43
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold43,2,0) {(void*) boxptr_List_fold43,0}};
#define boxvar_List_fold43 MMC_REFSTRUCTLIT(boxvar_lit_List_fold43)
DLLExport
modelica_metatype omc_List_fold4(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inExtraArg3, modelica_metatype _inExtraArg4, modelica_metatype _inStartValue);
#define boxptr_List_fold4 omc_List_fold4
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold4,2,0) {(void*) boxptr_List_fold4,0}};
#define boxvar_List_fold4 MMC_REFSTRUCTLIT(boxvar_lit_List_fold4)
DLLExport
modelica_metatype omc_List_fold3r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inExtraArg3, modelica_metatype _inStartValue);
#define boxptr_List_fold3r omc_List_fold3r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold3r,2,0) {(void*) boxptr_List_fold3r,0}};
#define boxvar_List_fold3r MMC_REFSTRUCTLIT(boxvar_lit_List_fold3r)
DLLExport
modelica_metatype omc_List_fold3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inExtraArg3, modelica_metatype _inStartValue);
#define boxptr_List_fold3 omc_List_fold3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold3,2,0) {(void*) boxptr_List_fold3,0}};
#define boxvar_List_fold3 MMC_REFSTRUCTLIT(boxvar_lit_List_fold3)
DLLExport
modelica_metatype omc_List_fold2r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inStartValue);
#define boxptr_List_fold2r omc_List_fold2r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold2r,2,0) {(void*) boxptr_List_fold2r,0}};
#define boxvar_List_fold2r MMC_REFSTRUCTLIT(boxvar_lit_List_fold2r)
DLLExport
modelica_metatype omc_List_foldList2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inStartValue);
#define boxptr_List_foldList2 omc_List_foldList2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_foldList2,2,0) {(void*) boxptr_List_foldList2,0}};
#define boxvar_List_foldList2 MMC_REFSTRUCTLIT(boxvar_lit_List_foldList2)
DLLExport
modelica_metatype omc_List_foldList1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inStartValue);
#define boxptr_List_foldList1 omc_List_foldList1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_foldList1,2,0) {(void*) boxptr_List_foldList1,0}};
#define boxvar_List_foldList1 MMC_REFSTRUCTLIT(boxvar_lit_List_foldList1)
DLLExport
modelica_metatype omc_List_foldList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
#define boxptr_List_foldList omc_List_foldList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_foldList,2,0) {(void*) boxptr_List_foldList,0}};
#define boxvar_List_foldList MMC_REFSTRUCTLIT(boxvar_lit_List_foldList)
DLLExport
modelica_metatype omc_List_fold22(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inStartValue1, modelica_metatype _inStartValue2, modelica_metatype *out_outResult2);
#define boxptr_List_fold22 omc_List_fold22
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold22,2,0) {(void*) boxptr_List_fold22,0}};
#define boxvar_List_fold22 MMC_REFSTRUCTLIT(boxvar_lit_List_fold22)
DLLExport
modelica_metatype omc_List_fold2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg1, modelica_metatype _inExtraArg2, modelica_metatype _inStartValue);
#define boxptr_List_fold2 omc_List_fold2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold2,2,0) {(void*) boxptr_List_fold2,0}};
#define boxvar_List_fold2 MMC_REFSTRUCTLIT(boxvar_lit_List_fold2)
DLLExport
modelica_metatype omc_List_fold1r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg, modelica_metatype _inStartValue);
#define boxptr_List_fold1r omc_List_fold1r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold1r,2,0) {(void*) boxptr_List_fold1r,0}};
#define boxvar_List_fold1r MMC_REFSTRUCTLIT(boxvar_lit_List_fold1r)
DLLExport
modelica_metatype omc_List_fold1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inExtraArg, modelica_metatype _inStartValue);
#define boxptr_List_fold1 omc_List_fold1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold1,2,0) {(void*) boxptr_List_fold1,0}};
#define boxvar_List_fold1 MMC_REFSTRUCTLIT(boxvar_lit_List_fold1)
DLLExport
modelica_metatype omc_List_foldr(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
#define boxptr_List_foldr omc_List_foldr
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_foldr,2,0) {(void*) boxptr_List_foldr,0}};
#define boxvar_List_foldr MMC_REFSTRUCTLIT(boxvar_lit_List_foldr)
DLLExport
modelica_metatype omc_List_fold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue);
#define boxptr_List_fold omc_List_fold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fold,2,0) {(void*) boxptr_List_fold,0}};
#define boxvar_List_fold MMC_REFSTRUCTLIT(boxvar_lit_List_fold)
DLLExport
modelica_metatype omc_List_map2List(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2List omc_List_map2List
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2List,2,0) {(void*) boxptr_List_map2List,0}};
#define boxvar_List_map2List MMC_REFSTRUCTLIT(boxvar_lit_List_map2List)
DLLExport
modelica_metatype omc_List_map1List(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_map1List omc_List_map1List
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1List,2,0) {(void*) boxptr_List_map1List,0}};
#define boxvar_List_map1List MMC_REFSTRUCTLIT(boxvar_lit_List_map1List)
DLLExport
modelica_metatype omc_List_mapListReverse(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc);
#define boxptr_List_mapListReverse omc_List_mapListReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapListReverse,2,0) {(void*) boxptr_List_mapListReverse,0}};
#define boxvar_List_mapListReverse MMC_REFSTRUCTLIT(boxvar_lit_List_mapListReverse)
DLLExport
modelica_metatype omc_List_mapList1__1(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_mapList1__1 omc_List_mapList1__1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapList1__1,2,0) {(void*) boxptr_List_mapList1__1,0}};
#define boxvar_List_mapList1__1 MMC_REFSTRUCTLIT(boxvar_lit_List_mapList1__1)
DLLExport
void omc_List_mapList2__0(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_mapList2__0 omc_List_mapList2__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapList2__0,2,0) {(void*) boxptr_List_mapList2__0,0}};
#define boxvar_List_mapList2__0 MMC_REFSTRUCTLIT(boxvar_lit_List_mapList2__0)
DLLExport
void omc_List_mapList1__0(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_mapList1__0 omc_List_mapList1__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapList1__0,2,0) {(void*) boxptr_List_mapList1__0,0}};
#define boxvar_List_mapList1__0 MMC_REFSTRUCTLIT(boxvar_lit_List_mapList1__0)
DLLExport
void omc_List_mapList0(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc);
#define boxptr_List_mapList0 omc_List_mapList0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapList0,2,0) {(void*) boxptr_List_mapList0,0}};
#define boxvar_List_mapList0 MMC_REFSTRUCTLIT(boxvar_lit_List_mapList0)
DLLExport
modelica_metatype omc_List_mapList(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc);
#define boxptr_List_mapList omc_List_mapList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapList,2,0) {(void*) boxptr_List_mapList,0}};
#define boxvar_List_mapList MMC_REFSTRUCTLIT(boxvar_lit_List_mapList)
DLLExport
modelica_boolean omc_List_map1ListBoolOr(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
DLLExport
modelica_metatype boxptr_List_map1ListBoolOr(threadData_t *threadData, modelica_metatype _inListList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1ListBoolOr,2,0) {(void*) boxptr_List_map1ListBoolOr,0}};
#define boxvar_List_map1ListBoolOr MMC_REFSTRUCTLIT(boxvar_lit_List_map1ListBoolOr)
DLLExport
modelica_boolean omc_List_map1BoolAnd(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
DLLExport
modelica_metatype boxptr_List_map1BoolAnd(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1BoolAnd,2,0) {(void*) boxptr_List_map1BoolAnd,0}};
#define boxvar_List_map1BoolAnd MMC_REFSTRUCTLIT(boxvar_lit_List_map1BoolAnd)
DLLExport
modelica_boolean omc_List_map1BoolOr(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
DLLExport
modelica_metatype boxptr_List_map1BoolOr(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1BoolOr,2,0) {(void*) boxptr_List_map1BoolOr,0}};
#define boxvar_List_map1BoolOr MMC_REFSTRUCTLIT(boxvar_lit_List_map1BoolOr)
DLLExport
modelica_boolean omc_List_mapMapBoolAnd(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_fnptr _inBFunc);
DLLExport
modelica_metatype boxptr_List_mapMapBoolAnd(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_fnptr _inBFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapMapBoolAnd,2,0) {(void*) boxptr_List_mapMapBoolAnd,0}};
#define boxvar_List_mapMapBoolAnd MMC_REFSTRUCTLIT(boxvar_lit_List_mapMapBoolAnd)
DLLExport
modelica_boolean omc_List_mapBoolAnd(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
DLLExport
modelica_metatype boxptr_List_mapBoolAnd(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapBoolAnd,2,0) {(void*) boxptr_List_mapBoolAnd,0}};
#define boxvar_List_mapBoolAnd MMC_REFSTRUCTLIT(boxvar_lit_List_mapBoolAnd)
DLLExport
modelica_boolean omc_List_mapBoolOr(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
DLLExport
modelica_metatype boxptr_List_mapBoolOr(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapBoolOr,2,0) {(void*) boxptr_List_mapBoolOr,0}};
#define boxvar_List_mapBoolOr MMC_REFSTRUCTLIT(boxvar_lit_List_mapBoolOr)
DLLExport
modelica_metatype omc_List_applyAndFold1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_fnptr _inApplyFunc, modelica_metatype _inExtraArg, modelica_metatype _inFoldArg);
#define boxptr_List_applyAndFold1 omc_List_applyAndFold1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_applyAndFold1,2,0) {(void*) boxptr_List_applyAndFold1,0}};
#define boxvar_List_applyAndFold1 MMC_REFSTRUCTLIT(boxvar_lit_List_applyAndFold1)
DLLExport
modelica_metatype omc_List_applyAndFold(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFoldFunc, modelica_fnptr _inApplyFunc, modelica_metatype _inFoldArg);
#define boxptr_List_applyAndFold omc_List_applyAndFold
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_applyAndFold,2,0) {(void*) boxptr_List_applyAndFold,0}};
#define boxvar_List_applyAndFold MMC_REFSTRUCTLIT(boxvar_lit_List_applyAndFold)
DLLExport
void omc_List_foldAllValue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1);
#define boxptr_List_foldAllValue omc_List_foldAllValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_foldAllValue,2,0) {(void*) boxptr_List_foldAllValue,0}};
#define boxvar_List_foldAllValue MMC_REFSTRUCTLIT(boxvar_lit_List_foldAllValue)
DLLExport
modelica_boolean omc_List_map1ListAllValueBool(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1);
DLLExport
modelica_metatype boxptr_List_map1ListAllValueBool(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1ListAllValueBool,2,0) {(void*) boxptr_List_map1ListAllValueBool,0}};
#define boxvar_List_map1ListAllValueBool MMC_REFSTRUCTLIT(boxvar_lit_List_map1ListAllValueBool)
DLLExport
modelica_boolean omc_List_mapListAllValueBool(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue);
DLLExport
modelica_metatype boxptr_List_mapListAllValueBool(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapListAllValueBool,2,0) {(void*) boxptr_List_mapListAllValueBool,0}};
#define boxvar_List_mapListAllValueBool MMC_REFSTRUCTLIT(boxvar_lit_List_mapListAllValueBool)
DLLExport
void omc_List_map2AllValue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2AllValue omc_List_map2AllValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2AllValue,2,0) {(void*) boxptr_List_map2AllValue,0}};
#define boxvar_List_map2AllValue MMC_REFSTRUCTLIT(boxvar_lit_List_map2AllValue)
DLLExport
void omc_List_map1rAllValue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1);
#define boxptr_List_map1rAllValue omc_List_map1rAllValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1rAllValue,2,0) {(void*) boxptr_List_map1rAllValue,0}};
#define boxvar_List_map1rAllValue MMC_REFSTRUCTLIT(boxvar_lit_List_map1rAllValue)
DLLExport
void omc_List_map1AllValue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1);
#define boxptr_List_map1AllValue omc_List_map1AllValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1AllValue,2,0) {(void*) boxptr_List_map1AllValue,0}};
#define boxvar_List_map1AllValue MMC_REFSTRUCTLIT(boxvar_lit_List_map1AllValue)
DLLExport
modelica_boolean omc_List_map1AllValueBool(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1);
DLLExport
modelica_metatype boxptr_List_map1AllValueBool(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue, modelica_metatype _inArg1);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1AllValueBool,2,0) {(void*) boxptr_List_map1AllValueBool,0}};
#define boxvar_List_map1AllValueBool MMC_REFSTRUCTLIT(boxvar_lit_List_map1AllValueBool)
DLLExport
modelica_boolean omc_List_mapAllValueBool(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue);
DLLExport
modelica_metatype boxptr_List_mapAllValueBool(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapAllValueBool,2,0) {(void*) boxptr_List_mapAllValueBool,0}};
#define boxvar_List_mapAllValueBool MMC_REFSTRUCTLIT(boxvar_lit_List_mapAllValueBool)
DLLExport
void omc_List_mapAllValue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inValue);
#define boxptr_List_mapAllValue omc_List_mapAllValue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapAllValue,2,0) {(void*) boxptr_List_mapAllValue,0}};
#define boxvar_List_mapAllValue MMC_REFSTRUCTLIT(boxvar_lit_List_mapAllValue)
DLLExport
void omc_List_mapMap__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc1, modelica_fnptr _inMapFunc2);
#define boxptr_List_mapMap__0 omc_List_mapMap__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapMap__0,2,0) {(void*) boxptr_List_mapMap__0,0}};
#define boxvar_List_mapMap__0 MMC_REFSTRUCTLIT(boxvar_lit_List_mapMap__0)
DLLExport
modelica_metatype omc_List_mapMap(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc1, modelica_fnptr _inMapFunc2);
#define boxptr_List_mapMap omc_List_mapMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapMap,2,0) {(void*) boxptr_List_mapMap,0}};
#define boxvar_List_mapMap MMC_REFSTRUCTLIT(boxvar_lit_List_mapMap)
DLLExport
modelica_metatype omc_List_map2Flat(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2Flat omc_List_map2Flat
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2Flat,2,0) {(void*) boxptr_List_map2Flat,0}};
#define boxvar_List_map2Flat MMC_REFSTRUCTLIT(boxvar_lit_List_map2Flat)
DLLExport
modelica_metatype omc_List_map1Flat(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_map1Flat omc_List_map1Flat
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1Flat,2,0) {(void*) boxptr_List_map1Flat,0}};
#define boxvar_List_map1Flat MMC_REFSTRUCTLIT(boxvar_lit_List_map1Flat)
DLLExport
modelica_metatype omc_List_mapFlatReverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc);
#define boxptr_List_mapFlatReverse omc_List_mapFlatReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFlatReverse,2,0) {(void*) boxptr_List_mapFlatReverse,0}};
#define boxvar_List_mapFlatReverse MMC_REFSTRUCTLIT(boxvar_lit_List_mapFlatReverse)
DLLExport
modelica_metatype omc_List_mapFlat(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc);
#define boxptr_List_mapFlat omc_List_mapFlat
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapFlat,2,0) {(void*) boxptr_List_mapFlat,0}};
#define boxvar_List_mapFlat MMC_REFSTRUCTLIT(boxvar_lit_List_mapFlat)
DLLExport
modelica_metatype omc_List_map9(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inArg6, modelica_metatype _inArg7, modelica_metatype _inArg8, modelica_metatype _inArg9);
#define boxptr_List_map9 omc_List_map9
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map9,2,0) {(void*) boxptr_List_map9,0}};
#define boxvar_List_map9 MMC_REFSTRUCTLIT(boxvar_lit_List_map9)
DLLExport
modelica_metatype omc_List_map8(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inArg6, modelica_metatype _inArg7, modelica_metatype _inArg8);
#define boxptr_List_map8 omc_List_map8
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map8,2,0) {(void*) boxptr_List_map8,0}};
#define boxvar_List_map8 MMC_REFSTRUCTLIT(boxvar_lit_List_map8)
DLLExport
modelica_metatype omc_List_map7(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inArg6, modelica_metatype _inArg7);
#define boxptr_List_map7 omc_List_map7
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map7,2,0) {(void*) boxptr_List_map7,0}};
#define boxvar_List_map7 MMC_REFSTRUCTLIT(boxvar_lit_List_map7)
DLLExport
modelica_metatype omc_List_map6(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inArg6);
#define boxptr_List_map6 omc_List_map6
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map6,2,0) {(void*) boxptr_List_map6,0}};
#define boxvar_List_map6 MMC_REFSTRUCTLIT(boxvar_lit_List_map6)
DLLExport
modelica_metatype omc_List_map5(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5);
#define boxptr_List_map5 omc_List_map5
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map5,2,0) {(void*) boxptr_List_map5,0}};
#define boxvar_List_map5 MMC_REFSTRUCTLIT(boxvar_lit_List_map5)
DLLExport
modelica_metatype omc_List_map4__2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype *out_outList2);
#define boxptr_List_map4__2 omc_List_map4__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map4__2,2,0) {(void*) boxptr_List_map4__2,0}};
#define boxvar_List_map4__2 MMC_REFSTRUCTLIT(boxvar_lit_List_map4__2)
DLLExport
void omc_List_map4__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4);
#define boxptr_List_map4__0 omc_List_map4__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map4__0,2,0) {(void*) boxptr_List_map4__0,0}};
#define boxvar_List_map4__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map4__0)
DLLExport
modelica_metatype omc_List_map4(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4);
#define boxptr_List_map4 omc_List_map4
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map4,2,0) {(void*) boxptr_List_map4,0}};
#define boxvar_List_map4 MMC_REFSTRUCTLIT(boxvar_lit_List_map4)
DLLExport
modelica_metatype omc_List_map3__2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype *out_outList2);
#define boxptr_List_map3__2 omc_List_map3__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map3__2,2,0) {(void*) boxptr_List_map3__2,0}};
#define boxvar_List_map3__2 MMC_REFSTRUCTLIT(boxvar_lit_List_map3__2)
DLLExport
void omc_List_map3__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3);
#define boxptr_List_map3__0 omc_List_map3__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map3__0,2,0) {(void*) boxptr_List_map3__0,0}};
#define boxvar_List_map3__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map3__0)
DLLExport
modelica_metatype omc_List_map3r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3);
#define boxptr_List_map3r omc_List_map3r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map3r,2,0) {(void*) boxptr_List_map3r,0}};
#define boxvar_List_map3r MMC_REFSTRUCTLIT(boxvar_lit_List_map3r)
DLLExport
modelica_metatype omc_List_map3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3);
#define boxptr_List_map3 omc_List_map3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map3,2,0) {(void*) boxptr_List_map3,0}};
#define boxvar_List_map3 MMC_REFSTRUCTLIT(boxvar_lit_List_map3)
DLLExport
modelica_metatype omc_List_map2__3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype *out_outList2, modelica_metatype *out_outList3);
#define boxptr_List_map2__3 omc_List_map2__3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2__3,2,0) {(void*) boxptr_List_map2__3,0}};
#define boxvar_List_map2__3 MMC_REFSTRUCTLIT(boxvar_lit_List_map2__3)
DLLExport
modelica_metatype omc_List_map2__2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype *out_outList2);
#define boxptr_List_map2__2 omc_List_map2__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2__2,2,0) {(void*) boxptr_List_map2__2,0}};
#define boxvar_List_map2__2 MMC_REFSTRUCTLIT(boxvar_lit_List_map2__2)
DLLExport
void omc_List_map2__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2__0 omc_List_map2__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2__0,2,0) {(void*) boxptr_List_map2__0,0}};
#define boxvar_List_map2__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map2__0)
DLLExport
modelica_metatype omc_List_map2r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2r omc_List_map2r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2r,2,0) {(void*) boxptr_List_map2r,0}};
#define boxvar_List_map2r MMC_REFSTRUCTLIT(boxvar_lit_List_map2r)
DLLExport
modelica_metatype omc_List_map2rm(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2rm omc_List_map2rm
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2rm,2,0) {(void*) boxptr_List_map2rm,0}};
#define boxvar_List_map2rm MMC_REFSTRUCTLIT(boxvar_lit_List_map2rm)
DLLExport
modelica_metatype omc_List_map2Reverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2Reverse omc_List_map2Reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2Reverse,2,0) {(void*) boxptr_List_map2Reverse,0}};
#define boxvar_List_map2Reverse MMC_REFSTRUCTLIT(boxvar_lit_List_map2Reverse)
DLLExport
modelica_metatype omc_List_map2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2 omc_List_map2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2,2,0) {(void*) boxptr_List_map2,0}};
#define boxvar_List_map2 MMC_REFSTRUCTLIT(boxvar_lit_List_map2)
DLLExport
modelica_metatype omc_List_map1__3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype *out_outList2, modelica_metatype *out_outList3);
#define boxptr_List_map1__3 omc_List_map1__3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1__3,2,0) {(void*) boxptr_List_map1__3,0}};
#define boxvar_List_map1__3 MMC_REFSTRUCTLIT(boxvar_lit_List_map1__3)
DLLExport
modelica_metatype omc_List_map1__2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype *out_outList2);
#define boxptr_List_map1__2 omc_List_map1__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1__2,2,0) {(void*) boxptr_List_map1__2,0}};
#define boxvar_List_map1__2 MMC_REFSTRUCTLIT(boxvar_lit_List_map1__2)
DLLExport
void omc_List_map1__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_map1__0 omc_List_map1__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1__0,2,0) {(void*) boxptr_List_map1__0,0}};
#define boxvar_List_map1__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map1__0)
DLLExport
modelica_metatype omc_List_map1r(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_map1r omc_List_map1r
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1r,2,0) {(void*) boxptr_List_map1r,0}};
#define boxvar_List_map1r MMC_REFSTRUCTLIT(boxvar_lit_List_map1r)
DLLExport
modelica_metatype omc_List_map1Reverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_map1Reverse omc_List_map1Reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1Reverse,2,0) {(void*) boxptr_List_map1Reverse,0}};
#define boxvar_List_map1Reverse MMC_REFSTRUCTLIT(boxvar_lit_List_map1Reverse)
DLLExport
modelica_metatype omc_List_map1(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inMapFunc, modelica_metatype _inArg1);
#define boxptr_List_map1 omc_List_map1
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1,2,0) {(void*) boxptr_List_map1,0}};
#define boxvar_List_map1 MMC_REFSTRUCTLIT(boxvar_lit_List_map1)
DLLExport
void omc_List_map__0(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_map__0 omc_List_map__0
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map__0,2,0) {(void*) boxptr_List_map__0,0}};
#define boxvar_List_map__0 MMC_REFSTRUCTLIT(boxvar_lit_List_map__0)
DLLExport
modelica_metatype omc_List_map2Option(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2);
#define boxptr_List_map2Option omc_List_map2Option
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map2Option,2,0) {(void*) boxptr_List_map2Option,0}};
#define boxvar_List_map2Option MMC_REFSTRUCTLIT(boxvar_lit_List_map2Option)
DLLExport
modelica_metatype omc_List_map1Option(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1);
#define boxptr_List_map1Option omc_List_map1Option
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map1Option,2,0) {(void*) boxptr_List_map1Option,0}};
#define boxvar_List_map1Option MMC_REFSTRUCTLIT(boxvar_lit_List_map1Option)
DLLExport
modelica_metatype omc_List_mapOption(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_mapOption omc_List_mapOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapOption,2,0) {(void*) boxptr_List_mapOption,0}};
#define boxvar_List_mapOption MMC_REFSTRUCTLIT(boxvar_lit_List_mapOption)
DLLExport
modelica_metatype omc_List_map__3(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outList2, modelica_metatype *out_outList3);
#define boxptr_List_map__3 omc_List_map__3
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map__3,2,0) {(void*) boxptr_List_map__3,0}};
#define boxvar_List_map__3 MMC_REFSTRUCTLIT(boxvar_lit_List_map__3)
DLLExport
modelica_metatype omc_List_map__2(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outList2);
#define boxptr_List_map__2 omc_List_map__2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map__2,2,0) {(void*) boxptr_List_map__2,0}};
#define boxvar_List_map__2 MMC_REFSTRUCTLIT(boxvar_lit_List_map__2)
DLLExport
modelica_metatype omc_List_mapReverse(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_mapReverse omc_List_mapReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapReverse,2,0) {(void*) boxptr_List_mapReverse,0}};
#define boxvar_List_mapReverse MMC_REFSTRUCTLIT(boxvar_lit_List_mapReverse)
DLLExport
modelica_metatype omc_List_mapCheckReferenceEq(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_mapCheckReferenceEq omc_List_mapCheckReferenceEq
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mapCheckReferenceEq,2,0) {(void*) boxptr_List_mapCheckReferenceEq,0}};
#define boxvar_List_mapCheckReferenceEq MMC_REFSTRUCTLIT(boxvar_lit_List_mapCheckReferenceEq)
DLLExport
modelica_metatype omc_List_map(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc);
#define boxptr_List_map omc_List_map
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_map,2,0) {(void*) boxptr_List_map,0}};
#define boxvar_List_map MMC_REFSTRUCTLIT(boxvar_lit_List_map)
DLLExport
modelica_metatype omc_List_unionOnTrueList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_unionOnTrueList omc_List_unionOnTrueList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionOnTrueList,2,0) {(void*) boxptr_List_unionOnTrueList,0}};
#define boxvar_List_unionOnTrueList MMC_REFSTRUCTLIT(boxvar_lit_List_unionOnTrueList)
DLLExport
modelica_metatype omc_List_unionList(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_unionList omc_List_unionList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionList,2,0) {(void*) boxptr_List_unionList,0}};
#define boxvar_List_unionList MMC_REFSTRUCTLIT(boxvar_lit_List_unionList)
DLLExport
modelica_metatype omc_List_unionAppendListOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inUnion, modelica_fnptr _inCompFunc);
#define boxptr_List_unionAppendListOnTrue omc_List_unionAppendListOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionAppendListOnTrue,2,0) {(void*) boxptr_List_unionAppendListOnTrue,0}};
#define boxvar_List_unionAppendListOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_unionAppendListOnTrue)
DLLExport
modelica_metatype omc_List_unionOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_unionOnTrue omc_List_unionOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionOnTrue,2,0) {(void*) boxptr_List_unionOnTrue,0}};
#define boxvar_List_unionOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_unionOnTrue)
DLLExport
modelica_metatype omc_List_unionAppendonUnion(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_unionAppendonUnion omc_List_unionAppendonUnion
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionAppendonUnion,2,0) {(void*) boxptr_List_unionAppendonUnion,0}};
#define boxvar_List_unionAppendonUnion MMC_REFSTRUCTLIT(boxvar_lit_List_unionAppendonUnion)
DLLExport
modelica_metatype omc_List_union(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_union omc_List_union
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_union,2,0) {(void*) boxptr_List_union,0}};
#define boxvar_List_union MMC_REFSTRUCTLIT(boxvar_lit_List_union)
DLLExport
modelica_metatype omc_List_unionEltOnTrue(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_unionEltOnTrue omc_List_unionEltOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionEltOnTrue,2,0) {(void*) boxptr_List_unionEltOnTrue,0}};
#define boxvar_List_unionEltOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_unionEltOnTrue)
DLLExport
modelica_metatype omc_List_unionElt(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
#define boxptr_List_unionElt omc_List_unionElt
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionElt,2,0) {(void*) boxptr_List_unionElt,0}};
#define boxvar_List_unionElt MMC_REFSTRUCTLIT(boxvar_lit_List_unionElt)
DLLExport
modelica_metatype omc_List_unionIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_List_unionIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unionIntN,2,0) {(void*) boxptr_List_unionIntN,0}};
#define boxvar_List_unionIntN MMC_REFSTRUCTLIT(boxvar_lit_List_unionIntN)
DLLExport
modelica_metatype omc_List_setDifference(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_setDifference omc_List_setDifference
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_setDifference,2,0) {(void*) boxptr_List_setDifference,0}};
#define boxvar_List_setDifference MMC_REFSTRUCTLIT(boxvar_lit_List_setDifference)
DLLExport
modelica_metatype omc_List_setDifferenceOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_setDifferenceOnTrue omc_List_setDifferenceOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_setDifferenceOnTrue,2,0) {(void*) boxptr_List_setDifferenceOnTrue,0}};
#define boxvar_List_setDifferenceOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_setDifferenceOnTrue)
DLLExport
modelica_metatype omc_List_setDifferenceIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_List_setDifferenceIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_setDifferenceIntN,2,0) {(void*) boxptr_List_setDifferenceIntN,0}};
#define boxvar_List_setDifferenceIntN MMC_REFSTRUCTLIT(boxvar_lit_List_setDifferenceIntN)
DLLExport
modelica_metatype omc_List_intersection1OnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc, modelica_metatype *out_outList1Rest, modelica_metatype *out_outList2Rest);
#define boxptr_List_intersection1OnTrue omc_List_intersection1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intersection1OnTrue,2,0) {(void*) boxptr_List_intersection1OnTrue,0}};
#define boxvar_List_intersection1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_intersection1OnTrue)
DLLExport
modelica_metatype omc_List_intersectionOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_intersectionOnTrue omc_List_intersectionOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intersectionOnTrue,2,0) {(void*) boxptr_List_intersectionOnTrue,0}};
#define boxvar_List_intersectionOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_intersectionOnTrue)
#define boxptr_List_intersectionIntVec omc_List_intersectionIntVec
DLLExport
modelica_metatype omc_List_intersectionIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_List_intersectionIntN(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intersectionIntN,2,0) {(void*) boxptr_List_intersectionIntN,0}};
#define boxvar_List_intersectionIntN MMC_REFSTRUCTLIT(boxvar_lit_List_intersectionIntN)
DLLExport
modelica_metatype omc_List_intersectionIntSorted(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_intersectionIntSorted omc_List_intersectionIntSorted
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intersectionIntSorted,2,0) {(void*) boxptr_List_intersectionIntSorted,0}};
#define boxvar_List_intersectionIntSorted MMC_REFSTRUCTLIT(boxvar_lit_List_intersectionIntSorted)
DLLExport
modelica_boolean omc_List_setEqualOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
DLLExport
modelica_metatype boxptr_List_setEqualOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_setEqualOnTrue,2,0) {(void*) boxptr_List_setEqualOnTrue,0}};
#define boxvar_List_setEqualOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_setEqualOnTrue)
DLLExport
modelica_metatype omc_List_listArrayReverse(threadData_t *threadData, modelica_metatype _inLst);
#define boxptr_List_listArrayReverse omc_List_listArrayReverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_listArrayReverse,2,0) {(void*) boxptr_List_listArrayReverse,0}};
#define boxvar_List_listArrayReverse MMC_REFSTRUCTLIT(boxvar_lit_List_listArrayReverse)
DLLExport
modelica_metatype omc_List_transposeList(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_transposeList omc_List_transposeList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_transposeList,2,0) {(void*) boxptr_List_transposeList,0}};
#define boxvar_List_transposeList MMC_REFSTRUCTLIT(boxvar_lit_List_transposeList)
DLLExport
modelica_metatype omc_List_product(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_product omc_List_product
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_product,2,0) {(void*) boxptr_List_product,0}};
#define boxvar_List_product MMC_REFSTRUCTLIT(boxvar_lit_List_product)
DLLExport
modelica_metatype omc_List_productMap(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inMapFunc);
#define boxptr_List_productMap omc_List_productMap
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_productMap,2,0) {(void*) boxptr_List_productMap,0}};
#define boxvar_List_productMap MMC_REFSTRUCTLIT(boxvar_lit_List_productMap)
DLLExport
modelica_metatype omc_List_sublist(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inOffset, modelica_integer _inLength);
DLLExport
modelica_metatype boxptr_List_sublist(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inOffset, modelica_metatype _inLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sublist,2,0) {(void*) boxptr_List_sublist,0}};
#define boxvar_List_sublist MMC_REFSTRUCTLIT(boxvar_lit_List_sublist)
DLLExport
modelica_metatype omc_List_balancedPartition(threadData_t *threadData, modelica_metatype _lst, modelica_integer _maxLength);
DLLExport
modelica_metatype boxptr_List_balancedPartition(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _maxLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_balancedPartition,2,0) {(void*) boxptr_List_balancedPartition,0}};
#define boxvar_List_balancedPartition MMC_REFSTRUCTLIT(boxvar_lit_List_balancedPartition)
DLLExport
modelica_metatype omc_List_partition(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inPartitionLength);
DLLExport
modelica_metatype boxptr_List_partition(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPartitionLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_partition,2,0) {(void*) boxptr_List_partition,0}};
#define boxvar_List_partition MMC_REFSTRUCTLIT(boxvar_lit_List_partition)
DLLExport
modelica_metatype omc_List_splitOnBoolList(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inBools, modelica_metatype *out_outFalseList);
#define boxptr_List_splitOnBoolList omc_List_splitOnBoolList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitOnBoolList,2,0) {(void*) boxptr_List_splitOnBoolList,0}};
#define boxvar_List_splitOnBoolList MMC_REFSTRUCTLIT(boxvar_lit_List_splitOnBoolList)
DLLExport
modelica_metatype omc_List_splitEqualParts(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inParts);
DLLExport
modelica_metatype boxptr_List_splitEqualParts(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inParts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitEqualParts,2,0) {(void*) boxptr_List_splitEqualParts,0}};
#define boxvar_List_splitEqualParts MMC_REFSTRUCTLIT(boxvar_lit_List_splitEqualParts)
DLLExport
modelica_metatype omc_List_splitLast(threadData_t *threadData, modelica_metatype _inList, modelica_metatype *out_outRest);
#define boxptr_List_splitLast omc_List_splitLast
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitLast,2,0) {(void*) boxptr_List_splitLast,0}};
#define boxvar_List_splitLast MMC_REFSTRUCTLIT(boxvar_lit_List_splitLast)
DLLExport
modelica_metatype omc_List_splitFirstOption(threadData_t *threadData, modelica_metatype _inList, modelica_metatype *out_outRest);
#define boxptr_List_splitFirstOption omc_List_splitFirstOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitFirstOption,2,0) {(void*) boxptr_List_splitFirstOption,0}};
#define boxvar_List_splitFirstOption MMC_REFSTRUCTLIT(boxvar_lit_List_splitFirstOption)
DLLExport
modelica_metatype omc_List_splitFirst(threadData_t *threadData, modelica_metatype _inList, modelica_metatype *out_outRest);
#define boxptr_List_splitFirst omc_List_splitFirst
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitFirst,2,0) {(void*) boxptr_List_splitFirst,0}};
#define boxvar_List_splitFirst MMC_REFSTRUCTLIT(boxvar_lit_List_splitFirst)
DLLExport
modelica_metatype omc_List_splitOnFirstMatch(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outList2);
#define boxptr_List_splitOnFirstMatch omc_List_splitOnFirstMatch
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitOnFirstMatch,2,0) {(void*) boxptr_List_splitOnFirstMatch,0}};
#define boxvar_List_splitOnFirstMatch MMC_REFSTRUCTLIT(boxvar_lit_List_splitOnFirstMatch)
DLLExport
modelica_metatype omc_List_split2OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype *out_outFalseList);
#define boxptr_List_split2OnTrue omc_List_split2OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_split2OnTrue,2,0) {(void*) boxptr_List_split2OnTrue,0}};
#define boxvar_List_split2OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_split2OnTrue)
DLLExport
modelica_metatype omc_List_split1OnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype _inArg1, modelica_metatype *out_outFalseList);
#define boxptr_List_split1OnTrue omc_List_split1OnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_split1OnTrue,2,0) {(void*) boxptr_List_split1OnTrue,0}};
#define boxvar_List_split1OnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_split1OnTrue)
DLLExport
modelica_metatype omc_List_splitOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outFalseList);
#define boxptr_List_splitOnTrue omc_List_splitOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitOnTrue,2,0) {(void*) boxptr_List_splitOnTrue,0}};
#define boxvar_List_splitOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_splitOnTrue)
DLLExport
modelica_metatype omc_List_splitr(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inPosition, modelica_metatype *out_outList2);
DLLExport
modelica_metatype boxptr_List_splitr(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPosition, modelica_metatype *out_outList2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_splitr,2,0) {(void*) boxptr_List_splitr,0}};
#define boxvar_List_splitr MMC_REFSTRUCTLIT(boxvar_lit_List_splitr)
DLLExport
modelica_metatype omc_List_split(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inPosition, modelica_metatype *out_outList2);
DLLExport
modelica_metatype boxptr_List_split(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inPosition, modelica_metatype *out_outList2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_split,2,0) {(void*) boxptr_List_split,0}};
#define boxvar_List_split MMC_REFSTRUCTLIT(boxvar_lit_List_split)
DLLExport
modelica_metatype omc_List_reverseList(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_reverseList omc_List_reverseList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_reverseList,2,0) {(void*) boxptr_List_reverseList,0}};
#define boxvar_List_reverseList MMC_REFSTRUCTLIT(boxvar_lit_List_reverseList)
DLLExport
modelica_metatype omc_List_uniqueOnTrue(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_uniqueOnTrue omc_List_uniqueOnTrue
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_uniqueOnTrue,2,0) {(void*) boxptr_List_uniqueOnTrue,0}};
#define boxvar_List_uniqueOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_uniqueOnTrue)
DLLExport
modelica_metatype omc_List_uniqueIntNArr(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inMarkArray, modelica_metatype _inAccum);
#define boxptr_List_uniqueIntNArr omc_List_uniqueIntNArr
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_uniqueIntNArr,2,0) {(void*) boxptr_List_uniqueIntNArr,0}};
#define boxvar_List_uniqueIntNArr MMC_REFSTRUCTLIT(boxvar_lit_List_uniqueIntNArr)
DLLExport
modelica_metatype omc_List_uniqueIntN(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_List_uniqueIntN(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_uniqueIntN,2,0) {(void*) boxptr_List_uniqueIntN,0}};
#define boxvar_List_uniqueIntN MMC_REFSTRUCTLIT(boxvar_lit_List_uniqueIntN)
DLLExport
modelica_metatype omc_List_unique(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_unique omc_List_unique
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_unique,2,0) {(void*) boxptr_List_unique,0}};
#define boxvar_List_unique MMC_REFSTRUCTLIT(boxvar_lit_List_unique)
DLLExport
modelica_metatype omc_List_countingSort(threadData_t *threadData, modelica_metatype _inList, modelica_integer _N);
DLLExport
modelica_metatype boxptr_List_countingSort(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _N);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_countingSort,2,0) {(void*) boxptr_List_countingSort,0}};
#define boxvar_List_countingSort MMC_REFSTRUCTLIT(boxvar_lit_List_countingSort)
DLLExport
modelica_metatype omc_List_mergeSorted(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_mergeSorted omc_List_mergeSorted
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_mergeSorted,2,0) {(void*) boxptr_List_mergeSorted,0}};
#define boxvar_List_mergeSorted MMC_REFSTRUCTLIT(boxvar_lit_List_mergeSorted)
#define boxptr_List_merge omc_List_merge
DLLExport
modelica_metatype omc_List_sortedUniqueOnlyDuplicates(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_sortedUniqueOnlyDuplicates omc_List_sortedUniqueOnlyDuplicates
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedUniqueOnlyDuplicates,2,0) {(void*) boxptr_List_sortedUniqueOnlyDuplicates,0}};
#define boxvar_List_sortedUniqueOnlyDuplicates MMC_REFSTRUCTLIT(boxvar_lit_List_sortedUniqueOnlyDuplicates)
DLLExport
modelica_metatype omc_List_sortedUniqueAndDuplicates(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc, modelica_metatype *out_outDuplicateElements);
#define boxptr_List_sortedUniqueAndDuplicates omc_List_sortedUniqueAndDuplicates
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedUniqueAndDuplicates,2,0) {(void*) boxptr_List_sortedUniqueAndDuplicates,0}};
#define boxvar_List_sortedUniqueAndDuplicates MMC_REFSTRUCTLIT(boxvar_lit_List_sortedUniqueAndDuplicates)
DLLExport
modelica_metatype omc_List_sortedUnique(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_sortedUnique omc_List_sortedUnique
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedUnique,2,0) {(void*) boxptr_List_sortedUnique,0}};
#define boxvar_List_sortedUnique MMC_REFSTRUCTLIT(boxvar_lit_List_sortedUnique)
DLLExport
modelica_boolean omc_List_sortedListAllUnique(threadData_t *threadData, modelica_metatype _lst, modelica_fnptr _compareFn);
DLLExport
modelica_metatype boxptr_List_sortedListAllUnique(threadData_t *threadData, modelica_metatype _lst, modelica_fnptr _compareFn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedListAllUnique,2,0) {(void*) boxptr_List_sortedListAllUnique,0}};
#define boxvar_List_sortedListAllUnique MMC_REFSTRUCTLIT(boxvar_lit_List_sortedListAllUnique)
DLLExport
modelica_metatype omc_List_sortedDuplicates(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_sortedDuplicates omc_List_sortedDuplicates
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sortedDuplicates,2,0) {(void*) boxptr_List_sortedDuplicates,0}};
#define boxvar_List_sortedDuplicates MMC_REFSTRUCTLIT(boxvar_lit_List_sortedDuplicates)
DLLExport
modelica_metatype omc_List_sort(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inCompFunc);
#define boxptr_List_sort omc_List_sort
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_sort,2,0) {(void*) boxptr_List_sort,0}};
#define boxvar_List_sort MMC_REFSTRUCTLIT(boxvar_lit_List_sort)
DLLExport
modelica_metatype omc_List_heapSortIntList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Flst);
#define boxptr_List_heapSortIntList omc_List_heapSortIntList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_heapSortIntList,2,0) {(void*) boxptr_List_heapSortIntList,0}};
#define boxvar_List_heapSortIntList MMC_REFSTRUCTLIT(boxvar_lit_List_heapSortIntList)
DLLExport
modelica_metatype omc_List_stripN(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_List_stripN(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_stripN,2,0) {(void*) boxptr_List_stripN,0}};
#define boxvar_List_stripN MMC_REFSTRUCTLIT(boxvar_lit_List_stripN)
DLLExport
modelica_metatype omc_List_stripLast(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_stripLast omc_List_stripLast
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_stripLast,2,0) {(void*) boxptr_List_stripLast,0}};
#define boxvar_List_stripLast MMC_REFSTRUCTLIT(boxvar_lit_List_stripLast)
DLLExport
modelica_metatype omc_List_stripFirst(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_stripFirst omc_List_stripFirst
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_stripFirst,2,0) {(void*) boxptr_List_stripFirst,0}};
#define boxvar_List_stripFirst MMC_REFSTRUCTLIT(boxvar_lit_List_stripFirst)
DLLExport
modelica_metatype omc_List_firstN__reverse(threadData_t *threadData, modelica_metatype _inList, modelica_integer _N);
DLLExport
modelica_metatype boxptr_List_firstN__reverse(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _N);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_firstN__reverse,2,0) {(void*) boxptr_List_firstN__reverse,0}};
#define boxvar_List_firstN__reverse MMC_REFSTRUCTLIT(boxvar_lit_List_firstN__reverse)
DLLExport
modelica_metatype omc_List_firstN(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_List_firstN(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_firstN,2,0) {(void*) boxptr_List_firstN,0}};
#define boxvar_List_firstN MMC_REFSTRUCTLIT(boxvar_lit_List_firstN)
DLLExport
modelica_metatype omc_List_getIndexFirst(threadData_t *threadData, modelica_integer _index, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_getIndexFirst(threadData_t *threadData, modelica_metatype _index, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_getIndexFirst,2,0) {(void*) boxptr_List_getIndexFirst,0}};
#define boxvar_List_getIndexFirst MMC_REFSTRUCTLIT(boxvar_lit_List_getIndexFirst)
DLLExport
modelica_metatype omc_List_restOrEmpty(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_restOrEmpty omc_List_restOrEmpty
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_restOrEmpty,2,0) {(void*) boxptr_List_restOrEmpty,0}};
#define boxvar_List_restOrEmpty MMC_REFSTRUCTLIT(boxvar_lit_List_restOrEmpty)
DLLExport
modelica_metatype omc_List_restCond(threadData_t *threadData, modelica_boolean _cond, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_restCond(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_restCond,2,0) {(void*) boxptr_List_restCond,0}};
#define boxvar_List_restCond MMC_REFSTRUCTLIT(boxvar_lit_List_restCond)
DLLExport
modelica_metatype omc_List_rest(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_rest omc_List_rest
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_rest,2,0) {(void*) boxptr_List_rest,0}};
#define boxvar_List_rest MMC_REFSTRUCTLIT(boxvar_lit_List_rest)
DLLExport
modelica_metatype omc_List_lastN(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN);
DLLExport
modelica_metatype boxptr_List_lastN(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_lastN,2,0) {(void*) boxptr_List_lastN,0}};
#define boxvar_List_lastN MMC_REFSTRUCTLIT(boxvar_lit_List_lastN)
DLLExport
modelica_metatype omc_List_secondLast(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_secondLast omc_List_secondLast
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_secondLast,2,0) {(void*) boxptr_List_secondLast,0}};
#define boxvar_List_secondLast MMC_REFSTRUCTLIT(boxvar_lit_List_secondLast)
DLLExport
modelica_metatype omc_List_lastListOrEmpty(threadData_t *threadData, modelica_metatype _inListList);
#define boxptr_List_lastListOrEmpty omc_List_lastListOrEmpty
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_lastListOrEmpty,2,0) {(void*) boxptr_List_lastListOrEmpty,0}};
#define boxvar_List_lastListOrEmpty MMC_REFSTRUCTLIT(boxvar_lit_List_lastListOrEmpty)
DLLExport
modelica_metatype omc_List_lastElement(threadData_t *threadData, modelica_metatype _inList, modelica_integer *out_listLength);
DLLExport
modelica_metatype boxptr_List_lastElement(threadData_t *threadData, modelica_metatype _inList, modelica_metatype *out_listLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_lastElement,2,0) {(void*) boxptr_List_lastElement,0}};
#define boxvar_List_lastElement MMC_REFSTRUCTLIT(boxvar_lit_List_lastElement)
DLLExport
modelica_metatype omc_List_last(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_last omc_List_last
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_last,2,0) {(void*) boxptr_List_last,0}};
#define boxvar_List_last MMC_REFSTRUCTLIT(boxvar_lit_List_last)
DLLExport
modelica_metatype omc_List_second(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_second omc_List_second
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_second,2,0) {(void*) boxptr_List_second,0}};
#define boxvar_List_second MMC_REFSTRUCTLIT(boxvar_lit_List_second)
DLLExport
modelica_metatype omc_List_firstOrEmpty(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_firstOrEmpty omc_List_firstOrEmpty
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_firstOrEmpty,2,0) {(void*) boxptr_List_firstOrEmpty,0}};
#define boxvar_List_firstOrEmpty MMC_REFSTRUCTLIT(boxvar_lit_List_firstOrEmpty)
DLLExport
modelica_metatype omc_List_first(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_first omc_List_first
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_first,2,0) {(void*) boxptr_List_first,0}};
#define boxvar_List_first MMC_REFSTRUCTLIT(boxvar_lit_List_first)
DLLExport
modelica_metatype omc_List_set(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN, modelica_metatype _inElement);
DLLExport
modelica_metatype boxptr_List_set(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_set,2,0) {(void*) boxptr_List_set,0}};
#define boxvar_List_set MMC_REFSTRUCTLIT(boxvar_lit_List_set)
#define boxptr_List_insertListSorted1 omc_List_insertListSorted1
DLLExport
modelica_metatype omc_List_insertListSorted(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
#define boxptr_List_insertListSorted omc_List_insertListSorted
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_insertListSorted,2,0) {(void*) boxptr_List_insertListSorted,0}};
#define boxvar_List_insertListSorted MMC_REFSTRUCTLIT(boxvar_lit_List_insertListSorted)
DLLExport
modelica_metatype omc_List_insert(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inN, modelica_metatype _inElement);
DLLExport
modelica_metatype boxptr_List_insert(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inN, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_insert,2,0) {(void*) boxptr_List_insert,0}};
#define boxvar_List_insert MMC_REFSTRUCTLIT(boxvar_lit_List_insert)
DLLExport
modelica_metatype omc_List_appendLastList(threadData_t *threadData, modelica_metatype _inListList, modelica_metatype _inList);
#define boxptr_List_appendLastList omc_List_appendLastList
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_appendLastList,2,0) {(void*) boxptr_List_appendLastList,0}};
#define boxvar_List_appendLastList MMC_REFSTRUCTLIT(boxvar_lit_List_appendLastList)
DLLExport
modelica_metatype omc_List_appendElt(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
#define boxptr_List_appendElt omc_List_appendElt
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_appendElt,2,0) {(void*) boxptr_List_appendElt,0}};
#define boxvar_List_appendElt MMC_REFSTRUCTLIT(boxvar_lit_List_appendElt)
DLLExport
modelica_metatype omc_List_appendr(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_appendr omc_List_appendr
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_appendr,2,0) {(void*) boxptr_List_appendr,0}};
#define boxvar_List_appendr MMC_REFSTRUCTLIT(boxvar_lit_List_appendr)
DLLExport
modelica_metatype omc_List_append__reverser(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_append__reverser omc_List_append__reverser
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_append__reverser,2,0) {(void*) boxptr_List_append__reverser,0}};
#define boxvar_List_append__reverser MMC_REFSTRUCTLIT(boxvar_lit_List_append__reverser)
DLLExport
modelica_metatype omc_List_append__reverse(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2);
#define boxptr_List_append__reverse omc_List_append__reverse
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_append__reverse,2,0) {(void*) boxptr_List_append__reverse,0}};
#define boxvar_List_append__reverse MMC_REFSTRUCTLIT(boxvar_lit_List_append__reverse)
DLLExport
modelica_metatype omc_List_consN(threadData_t *threadData, modelica_integer _size, modelica_metatype _inElement, modelica_metatype __omcQ_24in_5FinList);
DLLExport
modelica_metatype boxptr_List_consN(threadData_t *threadData, modelica_metatype _size, modelica_metatype _inElement, modelica_metatype __omcQ_24in_5FinList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consN,2,0) {(void*) boxptr_List_consN,0}};
#define boxvar_List_consN MMC_REFSTRUCTLIT(boxvar_lit_List_consN)
DLLExport
modelica_metatype omc_List_consOnBool(threadData_t *threadData, modelica_boolean _inValue, modelica_metatype _inElement, modelica_metatype __omcQ_24in_5FtrueList, modelica_metatype __omcQ_24in_5FfalseList, modelica_metatype *out_falseList);
DLLExport
modelica_metatype boxptr_List_consOnBool(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inElement, modelica_metatype __omcQ_24in_5FtrueList, modelica_metatype __omcQ_24in_5FfalseList, modelica_metatype *out_falseList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consOnBool,2,0) {(void*) boxptr_List_consOnBool,0}};
#define boxvar_List_consOnBool MMC_REFSTRUCTLIT(boxvar_lit_List_consOnBool)
DLLExport
modelica_metatype omc_List_consOption(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList);
#define boxptr_List_consOption omc_List_consOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consOption,2,0) {(void*) boxptr_List_consOption,0}};
#define boxvar_List_consOption MMC_REFSTRUCTLIT(boxvar_lit_List_consOption)
DLLExport
modelica_metatype omc_List_consOnSuccess(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inList, modelica_fnptr _inPredicate);
#define boxptr_List_consOnSuccess omc_List_consOnSuccess
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consOnSuccess,2,0) {(void*) boxptr_List_consOnSuccess,0}};
#define boxvar_List_consOnSuccess MMC_REFSTRUCTLIT(boxvar_lit_List_consOnSuccess)
DLLExport
modelica_metatype omc_List_consOnTrue(threadData_t *threadData, modelica_boolean _inCondition, modelica_metatype _inElement, modelica_metatype _inList);
DLLExport
modelica_metatype boxptr_List_consOnTrue(threadData_t *threadData, modelica_metatype _inCondition, modelica_metatype _inElement, modelica_metatype _inList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consOnTrue,2,0) {(void*) boxptr_List_consOnTrue,0}};
#define boxvar_List_consOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_consOnTrue)
DLLExport
modelica_metatype omc_List_consr(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inElement);
#define boxptr_List_consr omc_List_consr
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_consr,2,0) {(void*) boxptr_List_consr,0}};
#define boxvar_List_consr MMC_REFSTRUCTLIT(boxvar_lit_List_consr)
DLLExport
modelica_boolean omc_List_isPrefixOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
DLLExport
modelica_metatype boxptr_List_isPrefixOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isPrefixOnTrue,2,0) {(void*) boxptr_List_isPrefixOnTrue,0}};
#define boxvar_List_isPrefixOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_isPrefixOnTrue)
DLLExport
modelica_integer omc_List_compare(threadData_t *threadData, modelica_metatype _list1, modelica_metatype _list2, modelica_fnptr _compareFn);
DLLExport
modelica_metatype boxptr_List_compare(threadData_t *threadData, modelica_metatype _list1, modelica_metatype _list2, modelica_fnptr _compareFn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_compare,2,0) {(void*) boxptr_List_compare,0}};
#define boxvar_List_compare MMC_REFSTRUCTLIT(boxvar_lit_List_compare)
DLLExport
modelica_boolean omc_List_isEqualOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
DLLExport
modelica_metatype boxptr_List_isEqualOnTrue(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _inCompFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isEqualOnTrue,2,0) {(void*) boxptr_List_isEqualOnTrue,0}};
#define boxvar_List_isEqualOnTrue MMC_REFSTRUCTLIT(boxvar_lit_List_isEqualOnTrue)
DLLExport
modelica_boolean omc_List_isEqual(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_boolean _inEqualLength);
DLLExport
modelica_metatype boxptr_List_isEqual(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_metatype _inEqualLength);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_isEqual,2,0) {(void*) boxptr_List_isEqual,0}};
#define boxvar_List_isEqual MMC_REFSTRUCTLIT(boxvar_lit_List_isEqual)
DLLExport
void omc_List_assertIsEmpty(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_assertIsEmpty omc_List_assertIsEmpty
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_assertIsEmpty,2,0) {(void*) boxptr_List_assertIsEmpty,0}};
#define boxvar_List_assertIsEmpty MMC_REFSTRUCTLIT(boxvar_lit_List_assertIsEmpty)
DLLExport
modelica_metatype omc_List_fromOption(threadData_t *threadData, modelica_metatype _inElement);
#define boxptr_List_fromOption omc_List_fromOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fromOption,2,0) {(void*) boxptr_List_fromOption,0}};
#define boxvar_List_fromOption MMC_REFSTRUCTLIT(boxvar_lit_List_fromOption)
DLLExport
modelica_metatype omc_List_toOption(threadData_t *threadData, modelica_metatype _inList);
#define boxptr_List_toOption omc_List_toOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_toOption,2,0) {(void*) boxptr_List_toOption,0}};
#define boxvar_List_toOption MMC_REFSTRUCTLIT(boxvar_lit_List_toOption)
DLLExport
modelica_metatype omc_List_intRange3(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inStep, modelica_integer _inStop);
DLLExport
modelica_metatype boxptr_List_intRange3(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStep, modelica_metatype _inStop);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intRange3,2,0) {(void*) boxptr_List_intRange3,0}};
#define boxvar_List_intRange3 MMC_REFSTRUCTLIT(boxvar_lit_List_intRange3)
DLLExport
modelica_metatype omc_List_intRange2(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inStop);
DLLExport
modelica_metatype boxptr_List_intRange2(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStop);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intRange2,2,0) {(void*) boxptr_List_intRange2,0}};
#define boxvar_List_intRange2 MMC_REFSTRUCTLIT(boxvar_lit_List_intRange2)
DLLExport
modelica_metatype omc_List_intRange(threadData_t *threadData, modelica_integer _inStop);
DLLExport
modelica_metatype boxptr_List_intRange(threadData_t *threadData, modelica_metatype _inStop);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_intRange,2,0) {(void*) boxptr_List_intRange,0}};
#define boxvar_List_intRange MMC_REFSTRUCTLIT(boxvar_lit_List_intRange)
DLLExport
modelica_metatype omc_List_fill(threadData_t *threadData, modelica_metatype _inElement, modelica_integer _inCount);
DLLExport
modelica_metatype boxptr_List_fill(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_fill,2,0) {(void*) boxptr_List_fill,0}};
#define boxvar_List_fill MMC_REFSTRUCTLIT(boxvar_lit_List_fill)
DLLExport
modelica_metatype omc_List_create2(threadData_t *threadData, modelica_metatype _inElement1, modelica_metatype _inElement2);
#define boxptr_List_create2 omc_List_create2
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_create2,2,0) {(void*) boxptr_List_create2,0}};
#define boxvar_List_create2 MMC_REFSTRUCTLIT(boxvar_lit_List_create2)
DLLExport
modelica_metatype omc_List_create(threadData_t *threadData, modelica_metatype _inElement);
#define boxptr_List_create omc_List_create
static const MMC_DEFSTRUCTLIT(boxvar_lit_List_create,2,0) {(void*) boxptr_List_create,0}};
#define boxvar_List_create MMC_REFSTRUCTLIT(boxvar_lit_List_create)
#ifdef __cplusplus
}
#endif
#endif

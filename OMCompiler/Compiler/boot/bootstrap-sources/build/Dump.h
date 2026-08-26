#ifndef Dump__H
#define Dump__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Absyn_Program_PROGRAM__desc;
extern struct record_description Absyn_Within_TOP__desc;
extern struct record_description Dump_DumpOptions_DUMPOPTIONS__desc;
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_FlagData_BOOL__FLAG__desc;
extern struct record_description Flags_FlagVisibility_EXTERNAL__desc;
DLLDirection
void omc_Dump_writePath(threadData_t *threadData, modelica_complex _file, modelica_metatype _path, modelica_integer _escape, modelica_string _delimiter, modelica_boolean _initialDot);
DLLDirection
void boxptr_Dump_writePath(threadData_t *threadData, modelica_metatype _file, modelica_metatype _path, modelica_metatype _escape, modelica_metatype _delimiter, modelica_metatype _initialDot);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_writePath,2,0) {(void*) boxptr_Dump_writePath,0}};
#define boxvar_Dump_writePath MMC_REFSTRUCTLIT(boxvar_lit_Dump_writePath)
DLLDirection
void omc_Dump_stdout(threadData_t *threadData);
#define boxptr_Dump_stdout omc_Dump_stdout
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_stdout,2,0) {(void*) boxptr_Dump_stdout,0}};
#define boxvar_Dump_stdout MMC_REFSTRUCTLIT(boxvar_lit_Dump_stdout)
DLLDirection
void omc_Dump_printTypeSpec(threadData_t *threadData, modelica_metatype _typeSpec);
#define boxptr_Dump_printTypeSpec omc_Dump_printTypeSpec
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printTypeSpec,2,0) {(void*) boxptr_Dump_printTypeSpec,0}};
#define boxvar_Dump_printTypeSpec MMC_REFSTRUCTLIT(boxvar_lit_Dump_printTypeSpec)
DLLDirection
modelica_string omc_Dump_unparseTypeSpec(threadData_t *threadData, modelica_metatype _inTypeSpec);
#define boxptr_Dump_unparseTypeSpec omc_Dump_unparseTypeSpec
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseTypeSpec,2,0) {(void*) boxptr_Dump_unparseTypeSpec,0}};
#define boxvar_Dump_unparseTypeSpec MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseTypeSpec)
#define boxptr_Dump_printStringCommentOption omc_Dump_printStringCommentOption
DLLDirection
void omc_Dump_printList(threadData_t *threadData, modelica_metatype _inTypeALst, modelica_fnptr _inFuncTypeTypeATo, modelica_string _inString);
#define boxptr_Dump_printList omc_Dump_printList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printList,2,0) {(void*) boxptr_Dump_printList,0}};
#define boxvar_Dump_printList MMC_REFSTRUCTLIT(boxvar_lit_Dump_printList)
DLLDirection
void omc_Dump_printOption(threadData_t *threadData, modelica_metatype _inTypeAOption, modelica_fnptr _inFuncTypeTypeATo);
#define boxptr_Dump_printOption omc_Dump_printOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printOption,2,0) {(void*) boxptr_Dump_printOption,0}};
#define boxvar_Dump_printOption MMC_REFSTRUCTLIT(boxvar_lit_Dump_printOption)
DLLDirection
modelica_string omc_Dump_opSymbolCompact(threadData_t *threadData, modelica_metatype _inOperator);
#define boxptr_Dump_opSymbolCompact omc_Dump_opSymbolCompact
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_opSymbolCompact,2,0) {(void*) boxptr_Dump_opSymbolCompact,0}};
#define boxvar_Dump_opSymbolCompact MMC_REFSTRUCTLIT(boxvar_lit_Dump_opSymbolCompact)
DLLDirection
modelica_string omc_Dump_opSymbol(threadData_t *threadData, modelica_metatype _inOperator);
#define boxptr_Dump_opSymbol omc_Dump_opSymbol
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_opSymbol,2,0) {(void*) boxptr_Dump_opSymbol,0}};
#define boxvar_Dump_opSymbol MMC_REFSTRUCTLIT(boxvar_lit_Dump_opSymbol)
#define boxptr_Dump_printListStr omc_Dump_printListStr
DLLDirection
modelica_string omc_Dump_printCodeStr(threadData_t *threadData, modelica_metatype _inCode);
#define boxptr_Dump_printCodeStr omc_Dump_printCodeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printCodeStr,2,0) {(void*) boxptr_Dump_printCodeStr,0}};
#define boxvar_Dump_printCodeStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printCodeStr)
DLLDirection
modelica_string omc_Dump_printExpStr(threadData_t *threadData, modelica_metatype _inExp);
#define boxptr_Dump_printExpStr omc_Dump_printExpStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printExpStr,2,0) {(void*) boxptr_Dump_printExpStr,0}};
#define boxvar_Dump_printExpStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printExpStr)
DLLDirection
modelica_string omc_Dump_printExpLstStr(threadData_t *threadData, modelica_metatype _expl);
#define boxptr_Dump_printExpLstStr omc_Dump_printExpLstStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printExpLstStr,2,0) {(void*) boxptr_Dump_printExpLstStr,0}};
#define boxvar_Dump_printExpLstStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printExpLstStr)
DLLDirection
modelica_integer omc_Dump_expPriority(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean _inLhs);
DLLDirection
modelica_metatype boxptr_Dump_expPriority(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inLhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_expPriority,2,0) {(void*) boxptr_Dump_expPriority,0}};
#define boxvar_Dump_expPriority MMC_REFSTRUCTLIT(boxvar_lit_Dump_expPriority)
DLLDirection
modelica_boolean omc_Dump_shouldParenthesize(threadData_t *threadData, modelica_metatype _inOperand, modelica_metatype _inOperator, modelica_boolean _inLhs);
DLLDirection
modelica_metatype boxptr_Dump_shouldParenthesize(threadData_t *threadData, modelica_metatype _inOperand, modelica_metatype _inOperator, modelica_metatype _inLhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_shouldParenthesize,2,0) {(void*) boxptr_Dump_shouldParenthesize,0}};
#define boxvar_Dump_shouldParenthesize MMC_REFSTRUCTLIT(boxvar_lit_Dump_shouldParenthesize)
DLLDirection
modelica_string omc_Dump_printNamedArgValueStr(threadData_t *threadData, modelica_metatype _inNamedArg);
#define boxptr_Dump_printNamedArgValueStr omc_Dump_printNamedArgValueStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printNamedArgValueStr,2,0) {(void*) boxptr_Dump_printNamedArgValueStr,0}};
#define boxvar_Dump_printNamedArgValueStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printNamedArgValueStr)
DLLDirection
modelica_string omc_Dump_printNamedArgStr(threadData_t *threadData, modelica_metatype _inNamedArg);
#define boxptr_Dump_printNamedArgStr omc_Dump_printNamedArgStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printNamedArgStr,2,0) {(void*) boxptr_Dump_printNamedArgStr,0}};
#define boxvar_Dump_printNamedArgStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printNamedArgStr)
DLLDirection
modelica_string omc_Dump_printIteratorsStr(threadData_t *threadData, modelica_metatype _iterators);
#define boxptr_Dump_printIteratorsStr omc_Dump_printIteratorsStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printIteratorsStr,2,0) {(void*) boxptr_Dump_printIteratorsStr,0}};
#define boxvar_Dump_printIteratorsStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printIteratorsStr)
DLLDirection
modelica_string omc_Dump_printFunctionArgsStr(threadData_t *threadData, modelica_metatype _inFunctionArgs);
#define boxptr_Dump_printFunctionArgsStr omc_Dump_printFunctionArgsStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printFunctionArgsStr,2,0) {(void*) boxptr_Dump_printFunctionArgsStr,0}};
#define boxvar_Dump_printFunctionArgsStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printFunctionArgsStr)
DLLDirection
modelica_string omc_Dump_printSubscriptsStr(threadData_t *threadData, modelica_metatype _inAbsynSubscriptLst);
#define boxptr_Dump_printSubscriptsStr omc_Dump_printSubscriptsStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printSubscriptsStr,2,0) {(void*) boxptr_Dump_printSubscriptsStr,0}};
#define boxvar_Dump_printSubscriptsStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printSubscriptsStr)
DLLDirection
modelica_string omc_Dump_printComponentRefStr(threadData_t *threadData, modelica_metatype _inComponentRef);
#define boxptr_Dump_printComponentRefStr omc_Dump_printComponentRefStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printComponentRefStr,2,0) {(void*) boxptr_Dump_printComponentRefStr,0}};
#define boxvar_Dump_printComponentRefStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printComponentRefStr)
DLLDirection
modelica_string omc_Dump_unparseAlgorithmStr(threadData_t *threadData, modelica_metatype _inAlgorithmItem);
#define boxptr_Dump_unparseAlgorithmStr omc_Dump_unparseAlgorithmStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseAlgorithmStr,2,0) {(void*) boxptr_Dump_unparseAlgorithmStr,0}};
#define boxvar_Dump_unparseAlgorithmStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseAlgorithmStr)
DLLDirection
modelica_string omc_Dump_unparseAlgorithmStrLst(threadData_t *threadData, modelica_metatype _inAlgorithmItems, modelica_string _inSeparator);
#define boxptr_Dump_unparseAlgorithmStrLst omc_Dump_unparseAlgorithmStrLst
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseAlgorithmStrLst,2,0) {(void*) boxptr_Dump_unparseAlgorithmStrLst,0}};
#define boxvar_Dump_unparseAlgorithmStrLst MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseAlgorithmStrLst)
DLLDirection
modelica_string omc_Dump_unparseEquationItemStrLst(threadData_t *threadData, modelica_metatype _inEquationItems, modelica_string _inSeparator);
#define boxptr_Dump_unparseEquationItemStrLst omc_Dump_unparseEquationItemStrLst
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseEquationItemStrLst,2,0) {(void*) boxptr_Dump_unparseEquationItemStrLst,0}};
#define boxvar_Dump_unparseEquationItemStrLst MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseEquationItemStrLst)
DLLDirection
modelica_string omc_Dump_unparseEquationItemStr(threadData_t *threadData, modelica_metatype _inEquation);
#define boxptr_Dump_unparseEquationItemStr omc_Dump_unparseEquationItemStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseEquationItemStr,2,0) {(void*) boxptr_Dump_unparseEquationItemStr,0}};
#define boxvar_Dump_unparseEquationItemStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseEquationItemStr)
DLLDirection
modelica_string omc_Dump_unparseEquationStr(threadData_t *threadData, modelica_metatype _inEquation);
#define boxptr_Dump_unparseEquationStr omc_Dump_unparseEquationStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseEquationStr,2,0) {(void*) boxptr_Dump_unparseEquationStr,0}};
#define boxvar_Dump_unparseEquationStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseEquationStr)
DLLDirection
modelica_string omc_Dump_unparseClassPart(threadData_t *threadData, modelica_metatype _classPart);
#define boxptr_Dump_unparseClassPart omc_Dump_unparseClassPart
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseClassPart,2,0) {(void*) boxptr_Dump_unparseClassPart,0}};
#define boxvar_Dump_unparseClassPart MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseClassPart)
DLLDirection
modelica_string omc_Dump_equationName(threadData_t *threadData, modelica_metatype _eq);
#define boxptr_Dump_equationName omc_Dump_equationName
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_equationName,2,0) {(void*) boxptr_Dump_equationName,0}};
#define boxvar_Dump_equationName MMC_REFSTRUCTLIT(boxvar_lit_Dump_equationName)
DLLDirection
modelica_string omc_Dump_unparseModificationStr(threadData_t *threadData, modelica_metatype _inModification);
#define boxptr_Dump_unparseModificationStr omc_Dump_unparseModificationStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseModificationStr,2,0) {(void*) boxptr_Dump_unparseModificationStr,0}};
#define boxvar_Dump_unparseModificationStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseModificationStr)
DLLDirection
modelica_string omc_Dump_printSubscriptStr(threadData_t *threadData, modelica_metatype _inSubscript);
#define boxptr_Dump_printSubscriptStr omc_Dump_printSubscriptStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printSubscriptStr,2,0) {(void*) boxptr_Dump_printSubscriptStr,0}};
#define boxvar_Dump_printSubscriptStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printSubscriptStr)
DLLDirection
modelica_string omc_Dump_printArraydimStr(threadData_t *threadData, modelica_metatype _s);
#define boxptr_Dump_printArraydimStr omc_Dump_printArraydimStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_printArraydimStr,2,0) {(void*) boxptr_Dump_printArraydimStr,0}};
#define boxvar_Dump_printArraydimStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_printArraydimStr)
DLLDirection
modelica_string omc_Dump_unparseComponentCondition(threadData_t *threadData, modelica_metatype _inComponentCondition);
#define boxptr_Dump_unparseComponentCondition omc_Dump_unparseComponentCondition
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseComponentCondition,2,0) {(void*) boxptr_Dump_unparseComponentCondition,0}};
#define boxvar_Dump_unparseComponentCondition MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseComponentCondition)
DLLDirection
modelica_string omc_Dump_unparseParallelismSymbolStr(threadData_t *threadData, modelica_metatype _inParallelism);
#define boxptr_Dump_unparseParallelismSymbolStr omc_Dump_unparseParallelismSymbolStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseParallelismSymbolStr,2,0) {(void*) boxptr_Dump_unparseParallelismSymbolStr,0}};
#define boxvar_Dump_unparseParallelismSymbolStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseParallelismSymbolStr)
DLLDirection
modelica_string omc_Dump_directionSymbol(threadData_t *threadData, modelica_metatype _inDirection);
#define boxptr_Dump_directionSymbol omc_Dump_directionSymbol
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_directionSymbol,2,0) {(void*) boxptr_Dump_directionSymbol,0}};
#define boxvar_Dump_directionSymbol MMC_REFSTRUCTLIT(boxvar_lit_Dump_directionSymbol)
DLLDirection
modelica_string omc_Dump_unparseDirectionSymbolStr(threadData_t *threadData, modelica_metatype _inDirection);
#define boxptr_Dump_unparseDirectionSymbolStr omc_Dump_unparseDirectionSymbolStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseDirectionSymbolStr,2,0) {(void*) boxptr_Dump_unparseDirectionSymbolStr,0}};
#define boxvar_Dump_unparseDirectionSymbolStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseDirectionSymbolStr)
#define boxptr_Dump_unparseVariabilitySymbolStr omc_Dump_unparseVariabilitySymbolStr
DLLDirection
modelica_string omc_Dump_unparseImportStr(threadData_t *threadData, modelica_metatype _inImport);
#define boxptr_Dump_unparseImportStr omc_Dump_unparseImportStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseImportStr,2,0) {(void*) boxptr_Dump_unparseImportStr,0}};
#define boxvar_Dump_unparseImportStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseImportStr)
#define boxptr_Dump_unparseGroupImport omc_Dump_unparseGroupImport
DLLDirection
modelica_string omc_Dump_unparseInnerOuterStr(threadData_t *threadData, modelica_metatype _inInnerOuter);
#define boxptr_Dump_unparseInnerOuterStr omc_Dump_unparseInnerOuterStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseInnerOuterStr,2,0) {(void*) boxptr_Dump_unparseInnerOuterStr,0}};
#define boxvar_Dump_unparseInnerOuterStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseInnerOuterStr)
DLLDirection
modelica_string omc_Dump_unparseAnnotationOption(threadData_t *threadData, modelica_metatype _inAbsynAnnotation);
#define boxptr_Dump_unparseAnnotationOption omc_Dump_unparseAnnotationOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseAnnotationOption,2,0) {(void*) boxptr_Dump_unparseAnnotationOption,0}};
#define boxvar_Dump_unparseAnnotationOption MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseAnnotationOption)
DLLDirection
modelica_string omc_Dump_unparseAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation);
#define boxptr_Dump_unparseAnnotation omc_Dump_unparseAnnotation
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseAnnotation,2,0) {(void*) boxptr_Dump_unparseAnnotation,0}};
#define boxvar_Dump_unparseAnnotation MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseAnnotation)
DLLDirection
modelica_string omc_Dump_unparseElementItemStr(threadData_t *threadData, modelica_metatype _inElementItem);
#define boxptr_Dump_unparseElementItemStr omc_Dump_unparseElementItemStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseElementItemStr,2,0) {(void*) boxptr_Dump_unparseElementItemStr,0}};
#define boxvar_Dump_unparseElementItemStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseElementItemStr)
DLLDirection
modelica_metatype omc_Dump_shouldSeparateAfterElementArg(threadData_t *threadData, modelica_metatype _args);
#define boxptr_Dump_shouldSeparateAfterElementArg omc_Dump_shouldSeparateAfterElementArg
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_shouldSeparateAfterElementArg,2,0) {(void*) boxptr_Dump_shouldSeparateAfterElementArg,0}};
#define boxvar_Dump_shouldSeparateAfterElementArg MMC_REFSTRUCTLIT(boxvar_lit_Dump_shouldSeparateAfterElementArg)
DLLDirection
modelica_string omc_Dump_unparseElementArgStr(threadData_t *threadData, modelica_metatype _inElementArg);
#define boxptr_Dump_unparseElementArgStr omc_Dump_unparseElementArgStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseElementArgStr,2,0) {(void*) boxptr_Dump_unparseElementArgStr,0}};
#define boxvar_Dump_unparseElementArgStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseElementArgStr)
DLLDirection
modelica_string omc_Dump_unparseEachStr(threadData_t *threadData, modelica_metatype _inEach);
#define boxptr_Dump_unparseEachStr omc_Dump_unparseEachStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseEachStr,2,0) {(void*) boxptr_Dump_unparseEachStr,0}};
#define boxvar_Dump_unparseEachStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseEachStr)
DLLDirection
modelica_string omc_Dump_unparseRestrictionStr(threadData_t *threadData, modelica_metatype _inRestriction);
#define boxptr_Dump_unparseRestrictionStr omc_Dump_unparseRestrictionStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseRestrictionStr,2,0) {(void*) boxptr_Dump_unparseRestrictionStr,0}};
#define boxvar_Dump_unparseRestrictionStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseRestrictionStr)
DLLDirection
modelica_string omc_Dump_unparseCommentOption(threadData_t *threadData, modelica_metatype _inComment);
#define boxptr_Dump_unparseCommentOption omc_Dump_unparseCommentOption
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseCommentOption,2,0) {(void*) boxptr_Dump_unparseCommentOption,0}};
#define boxvar_Dump_unparseCommentOption MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseCommentOption)
DLLDirection
modelica_string omc_Dump_unparseClassAttributesStr(threadData_t *threadData, modelica_metatype _inClass);
#define boxptr_Dump_unparseClassAttributesStr omc_Dump_unparseClassAttributesStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseClassAttributesStr,2,0) {(void*) boxptr_Dump_unparseClassAttributesStr,0}};
#define boxvar_Dump_unparseClassAttributesStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseClassAttributesStr)
DLLDirection
modelica_string omc_Dump_unparseWithin(threadData_t *threadData, modelica_metatype _inWithin);
#define boxptr_Dump_unparseWithin omc_Dump_unparseWithin
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseWithin,2,0) {(void*) boxptr_Dump_unparseWithin,0}};
#define boxvar_Dump_unparseWithin MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseWithin)
DLLDirection
modelica_string omc_Dump_unparseClassStr(threadData_t *threadData, modelica_metatype _inClass);
#define boxptr_Dump_unparseClassStr omc_Dump_unparseClassStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseClassStr,2,0) {(void*) boxptr_Dump_unparseClassStr,0}};
#define boxvar_Dump_unparseClassStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseClassStr)
DLLDirection
modelica_string omc_Dump_unparseClassList(threadData_t *threadData, modelica_metatype _inClasses);
#define boxptr_Dump_unparseClassList omc_Dump_unparseClassList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseClassList,2,0) {(void*) boxptr_Dump_unparseClassList,0}};
#define boxvar_Dump_unparseClassList MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseClassList)
DLLDirection
modelica_string omc_Dump_unparseStr(threadData_t *threadData, modelica_metatype _inProgram, modelica_boolean _markup, modelica_metatype _options);
DLLDirection
modelica_metatype boxptr_Dump_unparseStr(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _markup, modelica_metatype _options);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_unparseStr,2,0) {(void*) boxptr_Dump_unparseStr,0}};
#define boxvar_Dump_unparseStr MMC_REFSTRUCTLIT(boxvar_lit_Dump_unparseStr)
DLLDirection
modelica_boolean omc_Dump_boolUnparseFileFromInfo(threadData_t *threadData, modelica_metatype _info, modelica_metatype _options);
DLLDirection
modelica_metatype boxptr_Dump_boolUnparseFileFromInfo(threadData_t *threadData, modelica_metatype _info, modelica_metatype _options);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Dump_boolUnparseFileFromInfo,2,0) {(void*) boxptr_Dump_boolUnparseFileFromInfo,0}};
#define boxvar_Dump_boolUnparseFileFromInfo MMC_REFSTRUCTLIT(boxvar_lit_Dump_boolUnparseFileFromInfo)
#ifdef __cplusplus
}
#endif
#endif
